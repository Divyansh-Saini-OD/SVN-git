-- This query will display the last environment a package line was migrated to.
--
-- The query requires a parameter
--      Package Number
--
-- The query actually requires 2 queries, one to locate the most recent date
-- the object was migrated(the sub-query) and main query to select the package
-- line and the details of the object where it was the last migrated. 
--
-- The sub-query, based on the environment, locates the last step
-- transaction for an package line where it was applied to the environment. Using the 
-- object name and last update date the match will be made with the appropriate 
-- package line in the main query. The caveat to the sub-query is the possibility
-- that a destination group was used. This group is made up of multiple
-- environments which complicates the query, hence the union
--
CREATE OR REPLACE FORCE VIEW xx_od_pkg_line_last_env_v (
     package_number
    ,description
    ,project_code
    ,status_code
    ,package_id
    ,package_line_seq
    ,object_name
    ,object_revision
    ,object_type
    ,environment_name)
AS
SELECT
     p.package_number
    ,p.description
    ,p.project_code
    ,p.status_code
    ,p.package_id
    ,oe.seq
    ,oe.object_name|| DECODE(oe.parameter2,
                        'prog','.'||oe.parameter2,
                        'java','.'||oe.parameter2,
                        'sql','.'||oe.parameter2,
                        'fmb','.'||oe.parameter2,
                        'pks','.'||oe.parameter2,
                        'pkb','.'||oe.parameter2,
                        'pls','.'||oe.parameter2,
                        'tbl','.'||oe.parameter2,
                        'rdt','.'||oe.parameter2,
                        'rdf','.'||oe.parameter2,
                        'rtf','.'||oe.parameter2,
                        'ldt','.'||oe.parameter2,
                        'grt','.'||oe.parameter2,
                        'seq','.'||oe.parameter2,
                        'xml','.'||oe.parameter2,
                        'prc','.'||oe.parameter2,
                        'syn','.'||oe.parameter2,
                        'trg','.'||oe.parameter2,
                        'idx','.'||oe.parameter2,
                        'vw','.' ||oe.parameter2,
                        'fnc','.'||oe.parameter2,
                        'ctl','.'||oe.parameter2,
                        NULL) Object_Name
    ,oe.object_revision
    ,oe.object_type_name
    ,e.environment_name
FROM
     mitg.kdlv_packages p
    ,(  SELECT              -- for a package,object,object type get the max date
             objt.object_type_name
            ,reql.object_type_id
            ,reql.object_name
            ,reql.package_id
            ,reql.package_line_id
            ,reql.seq
            ,reql.object_revision
            ,reql.parameter2
           ,max(cst.last_update_date) status_date
        from
             mitg.kwfl_step_transactions cst
            ,mitg.kwfl_workflow_instances cwi
            ,mitg.kwfl_workflow_instance_steps cwis
            ,mitg.kdlv_package_lines reql
            ,mitg.kwfl_workflow_steps wfls
            ,mitg.kenv_environments denv
            ,mitg.kdlv_object_types objt
        where
                denv.environment_id = wfls.dest_environment_id
            AND wfls.workflow_step_id = cwis.workflow_step_id
            AND objt.object_type_id (+) = reql.object_type_id
            AND cwi.workflow_instance_id = cwis.workflow_instance_id
            AND reql.package_line_id  = cwi.instance_source_id
            AND wfls.step_type_code = 'EXECUTION'
            AND cst.step_transaction_id = cwis.current_step_transaction_id
            AND cst.status = 'COMPLETE'
            AND cst.result_value = 'SUCCESS'
        group by
             objt.object_type_name
            ,reql.object_type_id
            ,reql.object_name
            ,reql.package_id
            ,reql.package_line_id  
            ,reql.seq
            ,reql.object_revision
            ,reql.parameter2
     ) oe
    ,mitg.kwfl_workflow_instances wi
    ,mitg.kwfl_workflow_instance_steps wis
    ,mitg.kwfl_step_transactions st
    ,mitg.kwfl_workflow_steps ws
    ,mitg.kenv_environments e
WHERE
        oe.package_id =  p.package_id 
    AND e.environment_id = ws.dest_environment_id
    AND ws.workflow_step_id = wis.workflow_step_id
    AND wi.workflow_instance_id = wis.workflow_instance_id
    AND oe.package_line_id  = wi.instance_source_id
    AND ws.step_type_code = 'EXECUTION'
    AND st.step_transaction_id = wis.current_step_transaction_id
    AND st.status = 'COMPLETE'
    AND st.result_value = 'SUCCESS'
    AND st.last_update_date = oe.status_date
--    AND p.package_number = :P_PACKAGE
UNION ALL
SELECT
     p1.package_number
    ,p1.description
    ,p1.project_code
    ,p1.status_code
    ,p1.package_id
    ,oe1.seq
    ,oe1.object_name|| DECODE(oe1.parameter2,
                        'prog','.'||oe1.parameter2,
                        'java','.'||oe1.parameter2,
                        'sql','.'||oe1.parameter2,
                        'fmb','.'||oe1.parameter2,
                        'pks','.'||oe1.parameter2,
                        'pkb','.'||oe1.parameter2,
                        'pls','.'||oe1.parameter2,
                        'tbl','.'||oe1.parameter2,
                        'rdt','.'||oe1.parameter2,
                        'rdf','.'||oe1.parameter2,
                        'rtf','.'||oe1.parameter2,
                        'ldt','.'||oe1.parameter2,
                        'grt','.'||oe1.parameter2,
                        'seq','.'||oe1.parameter2,
                        'xml','.'||oe1.parameter2,
                        'prc','.'||oe1.parameter2,
                        'syn','.'||oe1.parameter2,
                        'trg','.'||oe1.parameter2,
                        'idx','.'||oe1.parameter2,
                        'vw','.' ||oe1.parameter2,
                        'fnc','.'||oe1.parameter2,
                        'ctl','.'||oe1.parameter2,
                        NULL) Object_Name
    ,oe1.object_revision
    ,oe1.object_type_name
    ,de.environment_name
FROM
     mitg.kdlv_packages p1
    ,(  SELECT              -- for a package,object,object type get the max date
             ot.object_type_name
            ,pl.object_type_id
            ,pl.object_name
            ,pl.package_id
            ,pl.package_line_id
            ,pl.seq
            ,pl.object_revision
            ,pl.parameter2
           ,max(st.last_update_date) status_date
        from
             mitg.kwfl_step_transactions st
            ,mitg.kwfl_workflow_instances wi
            ,mitg.kwfl_workflow_instance_steps wis
            ,mitg.kdlv_package_lines pl
            ,mitg.kwfl_workflow_steps ws
            ,mitg.kenv_env_groups eg1
            ,mitg.kenv_env_group_envs ge1
            ,mitg.kenv_environments de1
            ,mitg.kdlv_object_types ot
        where
                eg1.env_group_id = ws.dest_env_group_id
            AND ge1.env_group_id = eg1.env_group_id
            AND ge1.environment_id = de1.environment_id
            AND ws.workflow_step_id = wis.workflow_step_id
            AND ot.object_type_id (+) = pl.object_type_id
            AND wi.workflow_instance_id = wis.workflow_instance_id
            AND pl.package_line_id  = wi.instance_source_id
            AND ws.step_type_code = 'EXECUTION'
            AND st.step_transaction_id = wis.current_step_transaction_id
            AND st.status = 'COMPLETE'
            AND st.result_value = 'SUCCESS'
        group by
             ot.object_type_name
            ,pl.object_type_id
            ,pl.object_name
            ,pl.package_id
            ,pl.package_line_id  
            ,pl.seq
            ,pl.object_revision
            ,pl.parameter2
     ) oe1
    ,mitg.kwfl_workflow_instances wi1
    ,mitg.kwfl_workflow_instance_steps wis1
    ,mitg.kwfl_step_transactions st1
    ,mitg.kwfl_workflow_steps ws1
    ,mitg.kenv_env_groups eg
    ,mitg.kenv_env_group_envs ge
    ,mitg.kenv_environments de
WHERE
        oe1.package_id =  p1.package_id
    AND eg.env_group_id = ws1.dest_env_group_id
    AND ge.env_group_id = eg.env_group_id
    AND ge.environment_id = de.environment_id
    AND ws1.workflow_step_id = wis1.workflow_step_id
    AND wi1.workflow_instance_id = wis1.workflow_instance_id
    AND oe1.package_line_id  = wi1.instance_source_id
    AND ws1.step_type_code = 'EXECUTION'
    AND st1.step_transaction_id = wis1.current_step_transaction_id
    AND st1.status = 'COMPLETE'
    AND st1.result_value = 'SUCCESS'
    AND st1.last_update_date = oe1.status_date ;
