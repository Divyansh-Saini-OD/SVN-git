-- This query will display the most current version and package for all objects    
-- that have been applied to a specified environment(aka DB instance)
--
-- The query requires a parameter
--      Environment(DB Instance)
--
-- To view the Environments run the following query
--      SELECT environment_name from mitg.kenv_environments
--
-- The query actually requires 2 queries, one to locate the most recent date
-- the object was migrated(the sub-query) and main query to select the package
-- and line and the details of the object where it was the last migrated. 
--
-- The sub-query, based on the environment, locates the last step
-- transaction for an object where it was applied to the environment. Using the 
-- object name and last update date the match will be made with the appropriate 
-- package line in the main query. The caveat to the sub-query is the possibility
-- that a destination group was used. This group is made up of multiple
-- environments which complicates the query, hence the union
--
CREATE OR REPLACE FORCE VIEW xx_od_env_last_obj_pkg_line_v (
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
    ,pl.package_id
    ,pl.seq
    ,pl.object_name|| DECODE(pl.parameter2,
                        'prog','.'||pl.parameter2,
                        'java','.'||pl.parameter2,
                        'sql','.'||pl.parameter2,
                        'fmb','.'||pl.parameter2,
                        'pks','.'||pl.parameter2,
                        'pkb','.'||pl.parameter2,
                        'pls','.'||pl.parameter2,
                        'tbl','.'||pl.parameter2,
                        'rdt','.'||pl.parameter2,
                        'rdf','.'||pl.parameter2,
                        'rtf','.'||pl.parameter2,
                        'ldt','.'||pl.parameter2,
                        'grt','.'||pl.parameter2,
                        'seq','.'||pl.parameter2,
                        'xml','.'||pl.parameter2,
                        'prc','.'||pl.parameter2,
                        'syn','.'||pl.parameter2,
                        'trg','.'||pl.parameter2,
                        'idx','.'||pl.parameter2,
                        'vw','.' ||pl.parameter2,
                        'fnc','.'||pl.parameter2,
                        'ctl','.'||pl.parameter2,
                        NULL) Object_Name
    ,pl.object_revision
    ,oe.object_type_name
    ,e.environment_name
FROM
     mitg.kdlv_packages p
    ,mitg.kdlv_package_lines pl
    ,(  SELECT
                 xx.object_type_name
                ,xx.object_type_id
                ,xx.object_name
                ,xx.dest_environment_id dest_environment_id
                ,max(xx.status_date) status_date

        FROM
            (SELECT
                 objt.object_type_name
                ,reql.object_type_id
                ,reql.object_name
                ,denv.environment_id dest_environment_id
                ,cst.last_update_date status_date
            FROM
                 mitg.kwfl_step_transactions cst
                ,mitg.kwfl_workflow_instances cwi
                ,mitg.kwfl_workflow_instance_steps cwis
                ,mitg.kdlv_package_lines reql
                ,mitg.kwfl_workflow_steps wfls
                ,mitg.kenv_environments denv
                ,mitg.kdlv_object_types objt
            WHERE
                    denv.environment_id = wfls.dest_environment_id
                AND wfls.workflow_step_id = cwis.workflow_step_id
                AND objt.object_type_id (+) = reql.object_type_id
                AND cwi.workflow_instance_id = cwis.workflow_instance_id
                AND reql.package_line_id  = cwi.instance_source_id
                AND wfls.step_type_code = 'EXECUTION'
                AND cst.step_transaction_id = cwis.current_step_transaction_id
                AND cst.status = 'COMPLETE'
                AND cst.result_value = 'SUCCESS'
            UNION all
            SELECT
                 ot1.object_type_name
                ,pl1.object_type_id
                ,pl1.object_name
                ,de1.environment_id dest_environment_id
                ,st1.last_update_date status_date
            FROM
                 mitg.kwfl_step_transactions st1
                ,mitg.kwfl_workflow_instances wi1
                ,mitg.kwfl_workflow_instance_steps wis1
                ,mitg.kdlv_package_lines pl1
                ,mitg.kwfl_workflow_steps ws1
                ,mitg.kenv_env_groups eg
                ,mitg.kenv_env_group_envs ge
                ,mitg.kenv_environments de1
                ,mitg.kdlv_object_types ot1
            WHERE
                    de1.environment_id = ge.environment_id
                AND ge.env_group_id = eg.env_group_id
                AND ws1.dest_env_group_id = eg.env_group_id
                AND ws1.workflow_step_id = wis1.workflow_step_id
                AND ot1.object_type_id (+) = pl1.object_type_id
                AND wi1.workflow_instance_id = wis1.workflow_instance_id
                AND pl1.package_line_id  = wi1.instance_source_id
                AND ws1.step_type_code = 'EXECUTION'
                AND st1.step_transaction_id = wis1.current_step_transaction_id
                AND st1.status = 'COMPLETE'
                AND st1.result_value = 'SUCCESS' ) xx
        GROUP BY
             xx.object_type_name
            ,xx.object_type_id
            ,xx.object_name
            ,xx.dest_environment_id
            ) oe
    ,mitg.kwfl_workflow_instances wi
    ,mitg.kwfl_workflow_instance_steps wis
    ,mitg.kwfl_step_transactions st
    ,mitg.kwfl_workflow_steps ws
    ,mitg.kenv_environments e
WHERE
        p.package_id = pl.package_id
    AND oe.dest_environment_id = ws.dest_environment_id
    AND ws.workflow_step_id = wis.workflow_step_id
    AND wi.workflow_instance_id = wis.workflow_instance_id
    AND pl.package_line_id  = wi.instance_source_id
    AND ws.step_type_code = 'EXECUTION'
    AND st.step_transaction_id = wis.current_step_transaction_id
    AND st.status = 'COMPLETE'
    AND st.result_value = 'SUCCESS'
    AND st.last_update_date = oe.status_date
    AND pl.object_name = oe.object_name
    AND oe.dest_environment_id = e.environment_id ;
