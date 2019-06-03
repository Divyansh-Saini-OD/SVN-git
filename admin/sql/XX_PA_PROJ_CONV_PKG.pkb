CREATE OR REPLACE PACKAGE BODY APPS.XX_PA_PROJ_CONV_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_PROJ_CONV_PKG.pkb                            |
-- | Description :  the objective of this API is to convert projects   |
-- |                 from PRD01 to PRDGB PA system.                    |
-- |               All detail information will be converted.           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       13-Mar-2010 Rama Dwibhashyam     Initial version         |
-- +===================================================================+
--
FUNCTION get_attr_group_id (p_attr_group_name IN VARCHAR2 ) RETURN NUMBER IS
   
   CURSOR cur_attr_group
   IS
   SELECT attr_group_id
     FROM ego_attr_groups_v 
    WHERE application_id = 275 
      AND attr_group_type = 'PA_PROJ_ATTR_GROUP_TYPE'
      AND attr_group_disp_name = p_attr_group_name ;

   l_attr_group_id  NUMBER;
   
BEGIN
   OPEN cur_attr_group;
   FETCH cur_attr_group INTO l_attr_group_id;
   IF cur_attr_group%NOTFOUND
   THEN
      l_attr_group_id := 0 ;
      CLOSE cur_attr_group;
   END IF;
   CLOSE cur_attr_group;
   RETURN ( l_attr_group_id );
END get_attr_group_id ;

--
--
FUNCTION get_project_id (p_project_name IN VARCHAR2, p_template_flag IN VARCHAR2) RETURN NUMBER IS
   
   CURSOR cur_proj_id
   IS
   SELECT project_id
     FROM pa_projects_all 
    WHERE 1=1 
      AND name  = p_project_name
      AND template_flag = p_template_flag ;

   l_project_id  NUMBER;
   
BEGIN
   OPEN cur_proj_id;
   FETCH cur_proj_id INTO l_project_id;
   IF cur_proj_id%NOTFOUND
   THEN
      l_project_id := 0 ;
      CLOSE cur_proj_id;
   END IF;
   CLOSE cur_proj_id;
   RETURN ( l_project_id );
END get_project_id ;

--
FUNCTION get_organization_id (p_org_name IN VARCHAR2) RETURN NUMBER IS
   
   CURSOR cur_org_id
   IS
   SELECT organization_id
     FROM hr_all_organization_units 
    WHERE 1=1 
      AND name  = p_org_name ;

   l_org_id  NUMBER;
   
BEGIN
   OPEN cur_org_id;
   FETCH cur_org_id INTO l_org_id;
   IF cur_org_id%NOTFOUND
   THEN
      l_org_id := 0 ;
      CLOSE cur_org_id;
   END IF;
   CLOSE cur_org_id;
   RETURN ( l_org_id );
END get_organization_id ;
--
PROCEDURE CREATE_ATTR_INFO (
                               x_msg_data          OUT NOCOPY VARCHAR2
                             , x_return_status     OUT NOCOPY VARCHAR2
                             , p_old_project_id     IN  NUMBER
                             , p_new_project_id     IN  NUMBER                             
                             , p_old_attr_group_id  IN  NUMBER
                             , p_new_attr_group_id  IN  NUMBER
                             , p_old_extension_id   IN  NUMBER
                             )
IS                             

  l_new_extension_id      Number ;

BEGIN

                SELECT EGO_ATTRS_S.NEXTVAL INTO l_new_extension_id FROM DUAL;


                INSERT INTO PA_PROJECTS_ERP_EXT_B
                (
                   EXTENSION_ID       
                  ,PROJECT_ID         
                  ,PROJ_ELEMENT_ID    
                  ,ATTR_GROUP_ID      
                  ,C_EXT_ATTR1        
                  ,C_EXT_ATTR2        
                  ,C_EXT_ATTR3        
                  ,C_EXT_ATTR4        
                  ,C_EXT_ATTR5        
                  ,C_EXT_ATTR6        
                  ,C_EXT_ATTR7        
                  ,C_EXT_ATTR8        
                  ,C_EXT_ATTR9        
                  ,C_EXT_ATTR10       
                  ,C_EXT_ATTR11       
                  ,C_EXT_ATTR12       
                  ,C_EXT_ATTR13       
                  ,C_EXT_ATTR14       
                  ,C_EXT_ATTR15       
                  ,C_EXT_ATTR16       
                  ,C_EXT_ATTR17       
                  ,C_EXT_ATTR18       
                  ,C_EXT_ATTR19       
                  ,C_EXT_ATTR20       
                  ,C_EXT_ATTR21       
                  ,C_EXT_ATTR22       
                  ,C_EXT_ATTR23       
                  ,C_EXT_ATTR24       
                  ,C_EXT_ATTR25       
                  ,C_EXT_ATTR26       
                  ,C_EXT_ATTR27       
                  ,C_EXT_ATTR28       
                  ,C_EXT_ATTR29       
                  ,C_EXT_ATTR30       
                  ,C_EXT_ATTR31       
                  ,C_EXT_ATTR32       
                  ,C_EXT_ATTR33       
                  ,C_EXT_ATTR34       
                  ,C_EXT_ATTR35       
                  ,C_EXT_ATTR36       
                  ,C_EXT_ATTR37       
                  ,C_EXT_ATTR38       
                  ,C_EXT_ATTR39       
                  ,C_EXT_ATTR40     
                  ,N_EXT_ATTR1        
                  ,N_EXT_ATTR2        
                  ,N_EXT_ATTR3        
                  ,N_EXT_ATTR4        
                  ,N_EXT_ATTR5        
                  ,N_EXT_ATTR6        
                  ,N_EXT_ATTR7        
                  ,N_EXT_ATTR8        
                  ,N_EXT_ATTR9        
                  ,N_EXT_ATTR10
                  ,N_EXT_ATTR11       
                  ,N_EXT_ATTR12       
                  ,N_EXT_ATTR13       
                  ,N_EXT_ATTR14       
                  ,N_EXT_ATTR15       
                  ,N_EXT_ATTR16       
                  ,N_EXT_ATTR17       
                  ,N_EXT_ATTR18       
                  ,N_EXT_ATTR19       
                  ,N_EXT_ATTR20       
                  ,D_EXT_ATTR1        
                  ,D_EXT_ATTR2        
                  ,D_EXT_ATTR3        
                  ,D_EXT_ATTR4        
                  ,D_EXT_ATTR5
                  ,D_EXT_ATTR6        
                  ,D_EXT_ATTR7        
                  ,D_EXT_ATTR8        
                  ,D_EXT_ATTR9        
                  ,D_EXT_ATTR10          
                  ,CREATED_BY         
                  ,CREATION_DATE      
                  ,LAST_UPDATED_BY    
                  ,LAST_UPDATE_DATE   
                  ,LAST_UPDATE_LOGIN  
                )
                 SELECT
                   l_new_extension_id  --EXTENSION_ID       
                  ,p_new_project_id    --PROJECT_ID         
                  ,PROJ_ELEMENT_ID    
                  ,p_new_attr_group_id  --ATTR_GROUP_ID      
                  ,C_EXT_ATTR1        
                  ,C_EXT_ATTR2        
                  ,C_EXT_ATTR3        
                  ,C_EXT_ATTR4        
                  ,C_EXT_ATTR5        
                  ,C_EXT_ATTR6        
                  ,C_EXT_ATTR7        
                  ,C_EXT_ATTR8        
                  ,C_EXT_ATTR9        
                  ,C_EXT_ATTR10       
                  ,C_EXT_ATTR11       
                  ,C_EXT_ATTR12       
                  ,C_EXT_ATTR13       
                  ,C_EXT_ATTR14       
                  ,C_EXT_ATTR15       
                  ,C_EXT_ATTR16       
                  ,C_EXT_ATTR17       
                  ,C_EXT_ATTR18       
                  ,C_EXT_ATTR19       
                  ,C_EXT_ATTR20       
                  ,C_EXT_ATTR21       
                  ,C_EXT_ATTR22       
                  ,C_EXT_ATTR23       
                  ,C_EXT_ATTR24       
                  ,C_EXT_ATTR25       
                  ,C_EXT_ATTR26       
                  ,C_EXT_ATTR27       
                  ,C_EXT_ATTR28       
                  ,C_EXT_ATTR29       
                  ,C_EXT_ATTR30       
                  ,C_EXT_ATTR31       
                  ,C_EXT_ATTR32       
                  ,C_EXT_ATTR33       
                  ,C_EXT_ATTR34       
                  ,C_EXT_ATTR35       
                  ,C_EXT_ATTR36       
                  ,C_EXT_ATTR37       
                  ,C_EXT_ATTR38       
                  ,C_EXT_ATTR39       
                  ,C_EXT_ATTR40     
                  ,N_EXT_ATTR1        
                  ,N_EXT_ATTR2        
                  ,N_EXT_ATTR3        
                  ,N_EXT_ATTR4        
                  ,N_EXT_ATTR5        
                  ,N_EXT_ATTR6        
                  ,N_EXT_ATTR7        
                  ,N_EXT_ATTR8        
                  ,N_EXT_ATTR9        
                  ,N_EXT_ATTR10
                  ,N_EXT_ATTR11       
                  ,N_EXT_ATTR12       
                  ,N_EXT_ATTR13       
                  ,N_EXT_ATTR14       
                  ,N_EXT_ATTR15       
                  ,N_EXT_ATTR16       
                  ,N_EXT_ATTR17       
                  ,N_EXT_ATTR18       
                  ,N_EXT_ATTR19       
                  ,N_EXT_ATTR20       
                  ,D_EXT_ATTR1        
                  ,D_EXT_ATTR2        
                  ,D_EXT_ATTR3        
                  ,D_EXT_ATTR4        
                  ,D_EXT_ATTR5
                  ,D_EXT_ATTR6        
                  ,D_EXT_ATTR7        
                  ,D_EXT_ATTR8        
                  ,D_EXT_ATTR9        
                  ,D_EXT_ATTR10          
                  ,g_user_id         
                  ,g_run_date      
                  ,g_user_id    
                  ,g_run_date   
                  ,g_login_id  
                 FROM apps.pa_projects_erp_ext_b@GSIPRD01.NA.ODCORP.NET
                WHERE project_id = p_old_project_id
                  AND attr_group_id = p_old_attr_group_id 
                  AND extension_id  = p_old_extension_id; 


                --
                INSERT INTO PA_PROJECTS_ERP_EXT_TL
                (
                   EXTENSION_ID       
                  ,PROJECT_ID         
                  ,PROJ_ELEMENT_ID    
                  ,ATTR_GROUP_ID      
                  ,SOURCE_LANG        
                  ,LANGUAGE           
                  ,TL_EXT_ATTR1       
                  ,TL_EXT_ATTR2       
                  ,TL_EXT_ATTR3       
                  ,TL_EXT_ATTR4       
                  ,TL_EXT_ATTR5       
                  ,TL_EXT_ATTR6       
                  ,TL_EXT_ATTR7       
                  ,TL_EXT_ATTR8       
                  ,TL_EXT_ATTR9       
                  ,TL_EXT_ATTR10      
                  ,TL_EXT_ATTR11      
                  ,TL_EXT_ATTR12      
                  ,TL_EXT_ATTR13      
                  ,TL_EXT_ATTR14      
                  ,TL_EXT_ATTR15      
                  ,TL_EXT_ATTR16      
                  ,TL_EXT_ATTR17      
                  ,TL_EXT_ATTR18      
                  ,TL_EXT_ATTR19      
                  ,TL_EXT_ATTR20      
                  ,TL_EXT_ATTR21      
                  ,TL_EXT_ATTR22      
                  ,TL_EXT_ATTR23      
                  ,TL_EXT_ATTR24      
                  ,TL_EXT_ATTR25      
                  ,TL_EXT_ATTR26      
                  ,TL_EXT_ATTR27      
                  ,TL_EXT_ATTR28      
                  ,TL_EXT_ATTR29      
                  ,TL_EXT_ATTR30      
                  ,TL_EXT_ATTR31      
                  ,TL_EXT_ATTR32      
                  ,TL_EXT_ATTR33      
                  ,TL_EXT_ATTR34      
                  ,TL_EXT_ATTR35      
                  ,TL_EXT_ATTR36      
                  ,TL_EXT_ATTR37      
                  ,TL_EXT_ATTR38      
                  ,TL_EXT_ATTR39      
                  ,TL_EXT_ATTR40      
                  ,CREATED_BY         
                  ,CREATION_DATE      
                  ,LAST_UPDATED_BY    
                  ,LAST_UPDATE_DATE   
                  ,LAST_UPDATE_LOGIN    
                )
                SELECT
                   l_new_extension_id   --EXTENSION_ID       
                  ,p_new_project_id     --PROJECT_ID         
                  ,PROJ_ELEMENT_ID    
                  ,p_new_attr_group_id  --ATTR_GROUP_ID      
                  ,SOURCE_LANG        
                  ,LANGUAGE           
                  ,TL_EXT_ATTR1       
                  ,TL_EXT_ATTR2       
                  ,TL_EXT_ATTR3       
                  ,TL_EXT_ATTR4       
                  ,TL_EXT_ATTR5       
                  ,TL_EXT_ATTR6       
                  ,TL_EXT_ATTR7       
                  ,TL_EXT_ATTR8       
                  ,TL_EXT_ATTR9       
                  ,TL_EXT_ATTR10      
                  ,TL_EXT_ATTR11      
                  ,TL_EXT_ATTR12      
                  ,TL_EXT_ATTR13      
                  ,TL_EXT_ATTR14      
                  ,TL_EXT_ATTR15      
                  ,TL_EXT_ATTR16      
                  ,TL_EXT_ATTR17      
                  ,TL_EXT_ATTR18      
                  ,TL_EXT_ATTR19      
                  ,TL_EXT_ATTR20      
                  ,TL_EXT_ATTR21      
                  ,TL_EXT_ATTR22      
                  ,TL_EXT_ATTR23      
                  ,TL_EXT_ATTR24      
                  ,TL_EXT_ATTR25      
                  ,TL_EXT_ATTR26      
                  ,TL_EXT_ATTR27      
                  ,TL_EXT_ATTR28      
                  ,TL_EXT_ATTR29      
                  ,TL_EXT_ATTR30      
                  ,TL_EXT_ATTR31      
                  ,TL_EXT_ATTR32      
                  ,TL_EXT_ATTR33      
                  ,TL_EXT_ATTR34      
                  ,TL_EXT_ATTR35      
                  ,TL_EXT_ATTR36      
                  ,TL_EXT_ATTR37      
                  ,TL_EXT_ATTR38      
                  ,TL_EXT_ATTR39      
                  ,TL_EXT_ATTR40     
                  ,g_user_id         
                  ,g_run_date      
                  ,g_user_id    
                  ,g_run_date   
                  ,g_login_id  
                FROM apps.pa_projects_erp_ext_tl@GSIPRD01.NA.ODCORP.NET
                WHERE project_id = p_old_project_id
                  AND attr_group_id = p_old_attr_group_id
                  AND extension_id  = p_old_extension_id ;

EXCEPTION
 WHEN OTHERS THEN
          --FND_FILE.PUT_LINE(FND_FILE.LOG,'Undefined Err Msg: ' ||SQLERRM);
         dbms_output.PUT_LINE('Undefined Err Msg in crate attr info: ' ||SQLERRM);
 
END ;

-------
PROCEDURE  CREATE_FINPLAN ( retcode      OUT VARCHAR2
                           ,errbuf       OUT VARCHAR2
                           ,p_cur_project_id IN pa_projects_all.project_id%TYPE) IS

    l_api_version_num                   NUMBER            := 1.0;
    l_commit                            VARCHAR2(10)      := 'T';
    l_init_msg_list                     VARCHAR2(10)      := 'T';
    l_msg_count                         NUMBER;
    l_msg_data                          VARCHAR2(4000);
    l_return_status                     VARCHAR2(1);
    l_initial_launch_date               DATE;
    l_sch_finish_date                   DATE;
    l_pm_product_code                   pa_budget_versions.pm_product_code%TYPE   := 'PLM_PROJECT';
    l_pa_project_id                     pa_projects_all.project_id%TYPE;
    l_fin_plan_type_id                  pa_budget_versions.FIN_PLAN_TYPE_ID%TYPE;
    l_version_type                      pa_budget_versions.VERSION_TYPE%TYPE;
    l_time_phased_code                  pa_proj_fp_options.cost_time_phased_code%TYPE;
    l_fin_plan_level_code               pa_proj_fp_options.cost_fin_plan_level_code%TYPE ;
    l_plan_in_multi_curr_flag           pa_proj_fp_options.PLAN_IN_MULTI_CURR_FLAG%TYPE;
    l_budget_version_name               pa_budget_versions.VERSION_NAME%TYPE;
    l_create_new_curr_working_flag      VARCHAR2(1) :='Y';
    l_error_data                        VARCHAR2(4000);
    l_msg_index_out                     VARCHAR2(1000);
    l_out_finplan_version_id            NUMBER;
    l_finplan_trans_tab                 pa_budget_pub.FinPlan_Trans_Tab;
    l_task_id                           pa_tasks.TASK_ID%TYPE;
    l_record_pos                        NUMBER(10) := 1;
    l_pm_project_reference              VARCHAR2(100);
    l_user_name                         fnd_user.user_name%TYPE;
    l_resp_name                         pa_user_resp_v.responsibility_name%TYPE;
    l_user_id                           NUMBER;
    l_resp_id                           NUMBER;
    l_resp_appl_id                      NUMBER;
    l_profile_org_id                    NUMBER;
    l_raw_cost_flag                     pa_fin_plan_amount_sets.RAW_COST_FLAG%TYPE;
    l_burdened_cost_flag                pa_fin_plan_amount_sets.BURDENED_COST_FLAG%TYPE ;
    l_revenue_flag                      pa_fin_plan_amount_sets.REVENUE_FLAG%TYPE;
    l_cost_qty_flag                     pa_fin_plan_amount_sets.COST_QTY_FLAG%TYPE;
    l_revenue_qty_flag                  pa_fin_plan_amount_sets.REVENUE_QTY_FLAG%TYPE;
    l_all_qty_flag                      pa_fin_plan_amount_sets.ALL_QTY_FLAG%TYPE;
    l_resource_list_name                pa_resource_lists_tl.NAME%TYPE;
    l_resource_list_id                  pa_resource_lists_tl.RESOURCE_LIST_ID%TYPE;
    l_using_resource_list_flag          VARCHAR2(1);
    l_description                       pa_budget_versions.DESCRIPTION%TYPE;
    l_base_quantity                     pa_budget_lines.QUANTITY%TYPE;
    l_base_revenue                      pa_budget_lines.REVENUE%TYPE;
    l_project_revenue                   pa_budget_lines.PROJECT_REVENUE%TYPE;
    l_txn_revenue                       pa_budget_lines.TXN_REVENUE%TYPE;
    l_temp_line_id                      VARCHAR2(50) :=1 ;
    l_new_temp_id                       VARCHAR2(50) :=1;
    l_project_id                        pa_projects_all.project_id%TYPE;
    l_msg_count_base                    NUMBER;
    l_return_status_base                VARCHAR2(1);
    l_msg_data_base                     VARCHAR2(4000);
    l_work_flow_started                 VARCHAR2(1);
    ln_count                            NUMBER;
    lm_count                            NUMBER;
    l_project_number                    VARCHAR2(30);


  /* Cursor to get all the projects */
            CURSOR proj_id (p_project_id number)  IS
            select ppa1.segment1,ppa1.project_id,ppa1.carrying_out_organization_id,
                   pbv.version_number,pbv.version_name,
                   pbv.revenue,pbv.description,
                   pbv.version_type,pbv.total_project_revenue,pbv.current_planning_period,
                   pfpt1.fin_plan_type_id,pfpt.name,
                   ppfo.revenue_time_phased_code,ppfo.plan_in_multi_curr_flag,
                   fpas.revenue_flag,fpas.revenue_qty_flag,
                   ppf1.person_id,ppf1.full_name
            from apps.pa_budget_versions@gsiprd01.na.odcorp.net pbv
                ,apps.pa_projects_all@gsiprd01.na.odcorp.net ppa
                ,apps.pa_fin_plan_types_vl@gsiprd01.na.odcorp.net pfpt
                ,apps.per_all_people_f@gsiprd01.na.odcorp.net ppf
                ,apps.per_all_people_f ppf1
                ,apps.pa_fin_plan_types_vl pfpt1
                ,apps.pa_projects_all ppa1
                ,apps.pa_proj_fp_options ppfo
                ,apps.pa_fin_plan_amount_sets fpas
            where 1=1
              and pbv.project_id = ppa.project_id
              and pbv.fin_plan_type_id = pfpt.fin_plan_type_id
              and upper(pfpt.name)  = upper(pfpt1.name)
              and ppa.segment1 = ppa1.segment1
              and ppa1.project_id = ppfo.project_id
              and pfpt1.fin_plan_type_id = ppfo.fin_plan_type_id
              AND ppfo.revenue_amount_set_id = fpas.fin_plan_amount_set_id
              and pbv.baselined_by_person_id = ppf.person_id
              and ppf.employee_number    = ppf1.employee_number
              and trunc(sysdate) between ppf1.effective_start_date and ppf1.effective_end_date
              AND pbv.budget_status_code = 'B'
              AND pbv.current_flag = 'Y'
              and ppa1.project_id  = p_project_id 
            order by 1 ;
              

    /* Cursor to get the Base line task Info */

         CURSOR res(p_project_id  pa_projects_all.project_id%TYPE) IS
            select ppa1.project_id,pt1.task_id,ppa1.carrying_out_organization_id,
                   pbv.version_number,pbv.version_name,
                   pbv.revenue,pbv.description,rlm1.resource_list_member_id,
                   pbv.version_type,pbv.total_project_revenue,pbv.current_planning_period,
                   pbl.start_date,pbl.end_date,pbl.revenue Line_revenue,pbl.project_revenue,
                   pra.resource_assignment_type,pra.planning_start_date,pra.planning_end_date,
                   pra.expenditure_type,pra.schedule_start_date,pra.schedule_end_date,
                   rlm1.alias,pra.total_plan_revenue,pra.unit_of_measure       
            from apps.pa_budget_versions@gsiprd01.na.odcorp.net pbv
                ,apps.pa_budget_lines@gsiprd01.na.odcorp.net pbl
                ,apps.pa_projects_all@gsiprd01.na.odcorp.net ppa
                ,apps.pa_tasks@gsiprd01.na.odcorp.net pt
                ,apps.pa_resource_assignments@gsiprd01.na.odcorp.net pra
                ,apps.pa_resource_list_members@gsiprd01.na.odcorp.net rlm
                ,apps.pa_resource_list_members rlm1
                ,apps.pa_projects_all ppa1
                ,apps.pa_tasks pt1
            where pbv.budget_version_id = pbl.budget_version_id
              and pbv.project_id = ppa.project_id
              and ppa.project_id = pt.project_id
              and pt.task_id     = pra.task_id
              AND pbv.budget_version_id = pra.budget_version_id
              AND pra.resource_list_member_id = rlm.resource_list_member_id  
              and pra.resource_assignment_id = pbl.resource_assignment_id
              and rlm.expenditure_type = rlm1.expenditure_type
              and rlm.alias    = rlm1.alias
              and rlm1.object_id = ppa1.project_id
              and ppa1.project_id = pt1.project_id
              and pt.task_number  = pt1.task_number
              and pt.task_name    = pt1.task_name
              and ppa.segment1 = ppa1.segment1
              AND pbv.budget_status_code = 'B'
              AND pbv.current_flag = 'Y'
              and ppa1.project_id = p_project_id
            order by 1  ;

     /* Cursor to select the resource for base line ver */
            CURSOR base_res(p_project_id  pa_projects_all.project_id%TYPE) IS

                    SELECT DISTINCT pra.resource_list_member_id
                      FROM pa_projects_all pa,
                           pa_budget_versions pbv,
                           pa_resource_assignments pra,
                           pa_resource_list_members rlm
                     WHERE pa.project_id = pbv.project_id
                       AND pbv.budget_version_id = pra.budget_version_id
                       AND pra.resource_list_member_id = rlm.resource_list_member_id
                       AND pa.project_id = p_project_id
                       AND pbv.budget_status_code = 'B'
                       --AND PBV.ORIGINAL_FLAG='Y'
                       AND pbv.current_flag = 'Y'
                  ORDER BY pra.resource_list_member_id;

     /* Cursor To get the base line Task Line Info  */

        CURSOR base_line_info(p_project_id  pa_projects_all.project_id%TYPE,
                              p_resource_member_id pa_resource_assignments.resource_list_member_id%TYPE ) IS

                SELECT   pra.resource_list_member_id, rlm.alias, pbl.budget_line_id,
                         pbl.budget_version_id, pbl.period_name, pbl.quantity, pbl.revenue,
                         pbl.project_revenue, pbl.txn_revenue, pbl.resource_assignment_id,
                         pbl.start_date,pa.project_id
                    FROM pa_projects_all pa,
                         pa_budget_versions pbv,
                         pa_resource_assignments pra,
                         pa_resource_list_members rlm,
                         pa_budget_lines pbl
                   WHERE pa.project_id = pbv.project_id
                     AND pbv.budget_version_id = pra.budget_version_id
                     AND pra.resource_list_member_id = rlm.resource_list_member_id
                     AND pra.resource_assignment_id = pbl.resource_assignment_id
                     AND pa.project_id = p_project_id
                     AND pra.resource_list_member_id=p_resource_member_id
                     AND pbv.budget_status_code = 'B'
                    -- AND pbv.original_flag = 'Y'
                     AND pbv.current_flag = 'Y'
                ORDER BY pbl.resource_assignment_id, pbl.start_date;


    /* Cursor to get the resource for new ver */
            CURSOR new_res (p_new_budget_ver_id    pa_budget_versions.budget_version_id%TYPE,
                            p_project_id           pa_projects_all.project_id%TYPE) IS
                     SELECT DISTINCT pra.resource_list_member_id
                      FROM pa_projects_all pa,
                           pa_budget_versions pbv,
                           pa_resource_assignments pra,
                           pa_resource_list_members rlm
                     WHERE pa.project_id = pbv.project_id
                       AND pbv.budget_version_id = pra.budget_version_id
                       AND pra.resource_list_member_id = rlm.resource_list_member_id
                       AND pa.project_id =p_project_id
                       AND pbv.BUDGET_VERSION_ID=p_new_budget_ver_id
                  ORDER BY pra.resource_list_member_id;

    /* Cursor To get the NEW VERSION info  */


 BEGIN

 

       FOR proj_id_rec IN proj_id (p_cur_project_id) LOOP
            l_project_id := proj_id_rec.project_id ;
            l_project_number :=proj_id_rec.segment1;

           FND_FILE.PUT_LINE(FND_FILE.LOG,'Project Number: '||proj_id_rec.segment1);

          -- TO GET THE INITIAL LAUNCH DATE FOR A PROJECT

                       /*  Table of Records for API  */

                 FOR res_rec IN res(proj_id_rec.project_id) LOOP
                  -- FND_FILE.PUT_LINE(FND_FILE.LOG,'TASK ID  : '||res_rec.task_id);
                     l_finplan_trans_tab(l_record_pos).pm_product_code          := 'PLM-PROJECT';
                     l_finplan_trans_tab(l_record_pos).TASK_ID                  := res_rec.task_id;
                     l_finplan_trans_tab(l_record_pos).START_DATE               := res_rec.start_date;
                     l_finplan_trans_tab(l_record_pos).END_DATE                 := res_rec.end_date;
                     l_finplan_trans_tab(l_record_pos).REVENUE                  := res_rec.TOTAL_PLAN_REVENUE;
                     l_finplan_trans_tab(l_record_pos).CURRENCY_CODE            :='USD';
                     l_finplan_trans_tab(l_record_pos).UNIT_OF_MEASURE_CODE     := res_rec.UNIT_OF_MEASURE;
                     l_finplan_trans_tab(l_record_pos).RESOURCE_LIST_MEMBER_ID  := res_rec.RESOURCE_LIST_MEMBER_ID;
                     l_finplan_trans_tab(l_record_pos).RESOURCE_ALIAS           := res_rec.ALIAS;
                     l_record_pos   :=l_record_pos+1;

                 END LOOP;
                  l_record_pos :=1;

                     l_using_resource_list_flag       :='Y';
                     l_fin_plan_level_code            :='T';
                     l_pa_project_id                  := proj_id_rec.project_id ;
                     l_fin_plan_type_id               := proj_id_rec.fin_plan_type_id ;
                     l_version_type                   := proj_id_rec.version_type ;
                     l_time_phased_code               := proj_id_rec.revenue_time_phased_code ;
                     l_plan_in_multi_curr_flag        := proj_id_rec.plan_in_multi_curr_flag ;
                     l_budget_version_name            := proj_id_rec.version_name ;
                     l_description                    := proj_id_rec.description ;
                     l_revenue_flag                   := proj_id_rec.revenue_flag ;
                     l_revenue_qty_flag               := proj_id_rec.revenue_qty_flag ;
            /* Call the API to Create the New Forecast Version */

            PA_BUDGET_PUB.CREATE_DRAFT_FINPLAN
                        (p_api_version_number           => l_api_version_num
                        ,p_commit                       => l_commit
                        ,p_init_msg_list                => l_init_msg_list
                        ,p_pm_product_code              => l_pm_product_code
                        ,p_pm_project_reference         => l_pm_project_reference
                        ,p_pa_project_id                => l_pa_project_id
                        ,p_fin_plan_type_id             => l_fin_plan_type_id
                        ,p_version_type                 => l_version_type
                        ,p_time_phased_code             => l_time_phased_code
                        --,p_resource_list_name         => l_resource_list_name
                        ---,p_resource_list_id          => l_resource_list_id
                        ,p_fin_plan_level_code          => l_fin_plan_level_code
                        ,p_plan_in_multi_curr_flag      => l_plan_in_multi_curr_flag
                        ,p_budget_version_name          => l_budget_version_name
                        ,p_description                  => l_description
                        ,p_revenue_flag                 => l_revenue_flag
                        ,p_revenue_qty_flag             => l_revenue_qty_flag
                        ,p_create_new_curr_working_flag => l_create_new_curr_working_flag
                        ,p_using_resource_lists_flag    => l_using_resource_list_flag
                        ,p_finplan_trans_tab            => l_finplan_trans_tab
                        ,x_finplan_version_id           => l_out_finplan_version_id
                        ,x_return_status                => l_return_status
                        ,x_msg_count                    => l_msg_count
                        ,x_msg_data                     => l_msg_data
                        );
                        
 
                 IF l_return_status != 'S'
                            THEN
                        FOR i IN 1.. NVL(l_msg_count,0)
                        LOOP
                                PA_INTERFACE_UTILS_PUB.get_messages (p_encoded       =>  'F',
                                                            p_msg_count     =>  l_msg_count,
                                                            p_msg_index     =>  i,
                                                            p_msg_data      =>  l_msg_data,
                                                            p_data          =>  l_error_data,
                                                            p_msg_index_out =>  l_msg_index_out);
                                    DBMS_OUTPUT.put_line('Error Data:'||l_error_data);
                                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Data:'||l_error_data);
                        END LOOP;
                 ELSE
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'NEW VERSION CREATED SUCCESSFULLY');
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'NEW FIN PLAN VERSION ID:'||l_out_finplan_version_id );
                 DBMS_OUTPUT.put_line('NEW FIN PLAN VERSION ID:'||l_out_finplan_version_id );
                 END IF;
            

              BEGIN

                    IF   l_return_status='S' THEN


                           /* Make New version values to NULL */

                            BEGIN

                                UPDATE pa_budget_versions
                                   SET baselined_by_person_id = proj_id_rec.person_id
                                 WHERE budget_version_id = l_out_finplan_version_id;
                                 
                                 COMMIT;
                             EXCEPTION
                                  WHEN OTHERS THEN
                                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception While updating budget version person_id:' ||l_out_finplan_version_id);
                                  FND_FILE.PUT_LINE(FND_FILE.LOG,substr(SQLERRM,1,200));

                            END;

                          /* Update the Base line Current values into New version lines */
--                           BEGIN
--                                FOR update_lines_rec IN update_lines(l_out_finplan_version_id)
--                               LOOP

--                                    UPDATE pa_budget_lines
--                                       SET quantity = update_lines_rec.quantity,
--                                           revenue = update_lines_rec.revenue,
--                                           project_revenue = update_lines_rec.project_revenue,
--                                           txn_revenue = update_lines_rec.txn_revenue
--                                     WHERE budget_line_id = update_lines_rec.budget_line_id;

--                               END LOOP;
--                            EXCEPTION
--                                 WHEN OTHERS THEN
--                                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception While Updating the Base line qty to New version lines: ' ||l_out_finplan_version_id);
--                                 FND_FILE.PUT_LINE(FND_FILE.LOG,substr(SQLERRM,1,200));
--                           END;

--                       COMMIT;

                      /* Call the API  to make New version into Current Approved version  */
                      BEGIN
                         PA_BUDGET_PUB.BASELINE_BUDGET
                                      (
                                       p_api_version_number      => l_api_version_num
                                      ,p_commit                  => l_commit
                                      ,p_init_msg_list           => l_init_msg_list
                                      ,p_msg_count               => l_msg_count_base
                                      ,p_msg_data                => l_msg_data_base
                                      ,p_return_status           => l_return_status_base
                                      ,p_workflow_started        => l_work_flow_started
                                      ,p_pm_product_code         => l_pm_product_code
                                      ,p_pa_project_id           => l_pa_project_id
                                      ,p_fin_plan_type_id        => l_fin_plan_type_id
                                      );

                                        IF l_return_status_base != 'S'
                                         THEN
                                             FOR i IN 1.. NVL(l_msg_count_base,0)
                                             LOOP
                                                 PA_INTERFACE_UTILS_PUB.get_messages (p_encoded =>  'F',
                                                            p_msg_count     =>  l_msg_count_base,
                                                            p_msg_index     =>  i,
                                                            p_msg_data      =>  l_msg_data_base,
                                                            p_data          =>  l_error_data,
                                                            p_msg_index_out =>  l_msg_index_out);

                                                  DBMS_OUTPUT.put_line('Forecast Approval Error Data:'||l_error_data||':'||sqlerrm);
                                                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error While making New Version as Current and  Approved Version:'||sqlerrm);
                                                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error:'||l_error_data);
                                             END LOOP;
                                             ELSE
                                                  FND_FILE.PUT_LINE(FND_FILE.LOG,'New Version got Approved and it is Current Working  Version');
                                       END IF;
                        END;

                      END IF;


              END;

    END LOOP; -- PROJ_ID CURSOR LOOP

 EXCEPTION
        WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Undefind Err Msg: ' ||SQLERRM);
 END create_finplan;

-------
---
PROCEDURE update_project_info ( x_errbuf           OUT NOCOPY VARCHAR2
                             , x_retcode           OUT NOCOPY VARCHAR2
                             , p_upd_project_id     IN  NUMBER
                             )
IS



lr_project_in_null_rec          pa_project_pub.project_in_rec_type;
lr_project_in_rec               pa_project_pub.project_in_rec_type;
lr_structure_in_rec             pa_project_pub.structure_in_rec_type;
lr_key_members_in_tbl           pa_project_pub.project_role_tbl_type;
lr_key_members_in_rec           pa_project_pub.project_role_rec_type;
lr_class_categories_in_tbl      pa_project_pub.class_category_tbl_type;
lr_tasks_in_tbl                 pa_project_pub.task_in_tbl_type;
lr_task_in_rec_type             pa_project_pub.task_in_rec_type;
lr_org_roles_in_tbl             pa_project_pub.project_role_tbl_type;
lr_ext_attr_in_tbl              pa_project_pub.PA_EXT_ATTR_TABLE_TYPE;
lr_ext_attr_rec_type            pa_project_pub.PA_EXT_ATTR_ROW_TYPE ;
lr_key_members_tbl_count        NUMBER:=0;
lr_class_categories_tbl_count   NUMBER:=0;
lr_tasks_tbl_count              NUMBER:=0;
lr_org_roles_tbl_count          NUMBER:=0;
lr_ext_attr_tbl_count           NUMBER := 0;
lr_project_out_null_rec         pa_project_pub.project_out_rec_type;
lr_project_out_rec              pa_project_pub.project_out_rec_type;
lr_tasks_out_tbl                pa_project_pub.task_out_tbl_type;
lr_structure_out_rec            pa_project_pub.structure_out_rec_type;
lr_deliverables_in_tbl          pa_project_pub.deliverable_in_tbl_type     ;
lr_deliv_rec_type               pa_project_pub.deliverable_in_rec_type ;
lr_deliverables_out_tbl         pa_project_pub.deliverable_out_tbl_type    ;
lr_deliverable_actions_in_tbl   pa_project_pub.action_in_tbl_type  ;
lr_deliverable_actions_out_tbl  pa_project_pub.action_out_tbl_type ;
lr_deliv_tbl_count              NUMBER := 0;
lr_dlvr_actions_in_tbl_count    NUMBER := 0;
lr_customers_in_tbl             pa_project_pub.customer_tbl_type; 
l_pm_product_code               pa_budget_versions.pm_product_code%TYPE   := 'WORKPLAN';
l_pm_project_reference          VARCHAR2(100);
l_user_name                     fnd_user.user_name%TYPE;
l_resp_name                     pa_user_resp_v.responsibility_name%TYPE;
l_user_id                       NUMBER;
l_resp_id                       NUMBER;
l_resp_appl_id                  NUMBER;
l_profile_org_id                NUMBER;
l_api_version_num               NUMBER            := 1.0;
l_commit                        VARCHAR2(10)      := 'T';
l_init_msg_list                 VARCHAR2(10)      := 'T';
l_msg_count                     NUMBER;
l_msg_data                      VARCHAR2(4000);
l_return_status                 VARCHAR2(1);
l_error_data                    VARCHAR2(4000);
l_msg_index_out                 VARCHAR2(1000);
l_workflow_started              VARCHAR2(10);
i                               NUMBER    := 0; --counter
j                               NUMBER    := 0; --counter
l_delta                         VARCHAR2(10) ;
l_new_attr_group_id             NUMBER ;
l_object_relationship_id        NUMBER ;

v_project_id                    NUMBER := p_upd_project_id ;


    CURSOR cur_proj_info (p_project_id number) IS
         SELECT ppl.project_id cur_project_id,pps1.project_status_code cur_project_status_code,ppa.*
          FROM apps.pa_projects_all ppl,
               apps.pa_projects_all @GSIPRD01.NA.ODCORP.NET ppa,
               apps.pa_project_statuses@GSIPRD01.NA.ODCORP.NET pps,
               apps.pa_project_statuses pps1
         WHERE ppl.segment1 = ppa.segment1
           AND ppa.project_status_code = pps.project_status_code
           AND pps.status_type = 'PROJECT'
           and pps.project_status_name = pps1.project_status_name
           and pps1.status_type = 'PROJECT'
           AND ppl.project_id = p_project_id     ;

    CURSOR cur_pa_key_mem (p_project_id number) IS
    SELECT ppr.project_role_type,ppp.* 
      FROM pa_project_parties ppp,
           pa_project_role_types_b ppr
     WHERE ppp.project_id = p_project_id      
       AND ppr.project_role_type = 'PROJECT MANAGER'  -- NOT IN ('PROJECT MANAGER','CUSTOMER ORG')
       AND ppp.project_role_id = ppr.project_role_id ;
       
      CURSOR cur_pa_dep (p_project_id number,p_old_project_id number) IS 
               SELECT ppev1.element_version_id src_task_ver_id,
               ppev3.element_version_id dest_task_ver_id,
               por.object_type_from,por.relationship_type,
               por.relationship_subtype,por.lag_day,por.weighting_percentage,
               por.comments,por.status_code
          FROM apps.pa_object_relationships@GSIPRD01.NA.ODCORP.NET por,
               apps.pa_proj_elements@GSIPRD01.NA.ODCORP.NET ppe,
               apps.pa_proj_element_versions@GSIPRD01.NA.ODCORP.NET ppev,
               apps.pa_proj_elements@GSIPRD01.NA.ODCORP.NET ppe2,
               apps.pa_proj_element_versions@GSIPRD01.NA.ODCORP.NET ppev2,
               apps.pa_proj_elements ppe1,
               apps.pa_proj_element_versions ppev1,
               apps.pa_proj_elements ppe3,
               apps.pa_proj_element_versions ppev3     
         WHERE por.object_id_from2 = p_old_project_id
           AND por.object_id_from1 = ppev.element_version_id
           AND ppe.proj_element_id = ppev.proj_element_id
           AND por.object_id_to1   = ppev2.element_version_id
           AND ppe2.proj_element_id = ppev2.proj_element_id  
           AND ppe.element_number = ppe1.element_number
           AND ppe.name           = ppe1.name
           AND ppe1.project_id    = p_project_id
           AND ppe1.proj_element_id = ppev1.proj_element_id
           AND ppe2.element_number = ppe3.element_number
           AND ppe2.name           = ppe3.name
           AND ppe3.project_id    = p_project_id
           AND ppe3.proj_element_id = ppev3.proj_element_id ;
       

    CURSOR cur_pa_tasks (p_project_id number,p_old_project_id number) IS
     SELECT pat1.task_id,ppe1.proj_element_id,pat1.task_number,
           pat1.task_name,ppe1.name,pev.display_sequence,ppe.status_code,ppf.full_name,ppf.employee_number,
           ppf.person_id,ppe.closed_date,
           ppe.baseline_start_date,ppe.baseline_finish_date,ppe.baseline_duration,
           pat.start_date,pat.completion_date,
           ppevs.actual_start_date,ppevs.actual_finish_date,ppevs.duration,
           ppevs.actual_duration,ppevs.estimated_duration,
           ppevs.early_start_date,ppevs.early_finish_date,
           ppevs.late_start_date,ppevs.late_finish_date,
           ppevs.scheduled_start_date,ppevs.scheduled_finish_date
      FROM apps.pa_tasks@GSIPRD01.NA.ODCORP.NET pat,
           apps.pa_proj_element_versions@GSIPRD01.NA.ODCORP.NET pev,
           apps.pa_proj_elements@GSIPRD01.NA.ODCORP.NET ppe,
           apps.pa_proj_elem_ver_schedule@gsiprd01.na.odcorp.net ppevs,
           apps.pa_tasks pat1,
           apps.pa_proj_element_versions pev1,
           apps.pa_proj_elements ppe1,
           apps.per_all_people_f ppf,
           apps.per_all_people_f@GSIPRD01.NA.ODCORP.NET ppf1
     WHERE 1=1
       and pat.project_id = p_old_project_id
       and pat.task_id = pev.proj_element_id
       and pev.proj_element_id = ppe.proj_element_id
       and pev.proj_element_id = ppevs.proj_element_id
       and pev.project_id      = ppevs.project_id
       and pev.object_type = 'PA_TASKS'
       and ppf1.employee_number = ppf.employee_number
       and trunc(sysdate) between ppf.effective_start_date and ppf.effective_end_date
       and ppe.manager_person_id = ppf1.person_id
       and pat1.project_id = p_project_id
       and pat1.task_id = pev1.proj_element_id
       and pev1.proj_element_id = ppe1.proj_element_id
       and pev1.object_type = 'PA_TASKS'
       and pat1.task_number = pat.task_number
      order by 1                  ;
     
    CURSOR cur_pa_dlvr (p_project_id number,p_old_project_id number) IS
    SELECT pad.proj_element_id cur_proj_element_id,paf.person_id cur_person_id,paf.full_name cur_full_name,paf.employee_number cur_employee_number
          ,pad1.*
      FROM apps.PA_DELIVERABLES_V pad,
           apps.PA_DELIVERABLES_V@GSIPRD01.NA.ODCORP.NET pad1,
           apps.per_all_people_f@GSIPRD01.NA.ODCORP.NET paf1,
           apps.per_all_people_f paf
     WHERE pad.project_id = p_project_id 
       AND pad.element_number = pad1.element_number
       and pad1.project_id = p_old_project_id
       AND pad1.manager_person_id = paf1.person_id
       AND paf1.employee_number = paf.employee_number
       AND trunc(sysdate) between paf.effective_start_date and paf.effective_end_date;
     


begin

--               BEGIN
--                           l_user_name      := '499103' ;  --g_user_name ;
--                           l_resp_name      := 'Project Super User' ;  --g_resp_name ;
--                           l_resp_appl_id   := 275 ;  --g_resp_appl_id ;
--                           l_user_id        := 28709 ;  --g_user_id ;
--                           l_resp_id        := 22593  ;  --g_resp_id ;
--                           l_profile_org_id := 404 ;  --g_org_id ;

--                   FND_FILE.PUT_LINE(FND_FILE.LOG,'USER ID:'||l_user_id||'RESP ID:'||
--                   l_resp_id||'RESP APPL ID:'||l_resp_appl_id||'PROFILE ORG ID:'||l_profile_org_id);
--                   DBMS_OUTPUT.put_line('USER ID:'||l_user_id||'RESP ID:'||
--                   l_resp_id||'RESP APPL ID:'||l_resp_appl_id||'PROFILE ORG ID:'||l_profile_org_id);

--                    FND_GLOBAL.apps_initialize
--                             (
--                              user_id        => l_user_id,  --29446,  
--                              resp_id        => l_resp_id,  --50339,  
--                              resp_appl_id   => l_resp_appl_id --275  
--                             );

--                    PA_INTERFACE_UTILS_PUB.set_global_info
--                            (
--                             p_api_version_number    => 1.0,
--                             p_responsibility_id     => l_resp_id,  --50339,  
--                             p_user_id               => l_user_id,  --29446,  
--                             p_msg_count             => l_msg_count,
--                             p_msg_data              => l_msg_data,
--                             p_return_status         => l_return_status
--                            );

--                            IF l_return_status != 'S'
--                             THEN
--                                 FOR i IN 1.. NVL(l_msg_count,0)
--                                 LOOP
--                                     PA_INTERFACE_UTILS_PUB.get_messages (p_encoded =>  'F',
--                                                p_msg_count     =>  l_msg_count,
--                                                p_msg_index     =>  i,
--                                                p_msg_data      =>  l_msg_data,
--                                                p_data          =>  l_error_data,
--                                                p_msg_index_out =>  l_msg_index_out);

--                                      --DBMS_OUTPUT.put_line('User and Responsibility:'||l_error_data||':'||sqlerrm);
--                                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Users and Responsibility Error:'||l_error_data);
--                                 END LOOP;
--                            END IF;
--                END;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Update Project ID: '||v_project_id);
      --FND_FILE.PUT_LINE(FND_FILE.LOG,'Project Type: '||p_project_type);
      --FND_FILE.PUT_LINE(FND_FILE.LOG,'Template Flag: '||p_template_flag);


--

  FOR proj_info_rec IN cur_proj_info(v_project_id)
  LOOP

     lr_project_in_rec.pm_project_reference      := proj_info_rec.segment1 ;
     lr_project_in_rec.pa_project_id             := proj_info_rec.cur_project_id ;
     lr_project_in_rec.project_status_code       := proj_info_rec.cur_project_status_code ;
     lr_project_in_rec.start_date                := proj_info_rec.start_date ;
     lr_project_in_rec.completion_date           := proj_info_rec.closed_date ;
     lr_project_in_rec.actual_start_date         := proj_info_rec.start_date ;
     lr_project_in_rec.actual_finish_date        := proj_info_rec.closed_date ;
     lr_project_in_rec.scheduled_start_date      := proj_info_rec.scheduled_start_date ;
     lr_project_in_rec.scheduled_finish_date     := proj_info_rec.scheduled_finish_date ;
     
          
               update pa_projects_all
                  set baseline_start_date     = proj_info_rec.baseline_start_date
                     ,baseline_finish_date    = proj_info_rec.baseline_finish_date
                     ,scheduled_as_of_date    = proj_info_rec.scheduled_as_of_date
                     ,baseline_as_of_date     = proj_info_rec.baseline_as_of_date
                     ,scheduled_duration      = proj_info_rec.scheduled_duration
                     ,baseline_duration       = proj_info_rec.baseline_duration
                where project_id              = proj_info_rec.cur_project_id ;

----
             FOR pa_dep_rec IN cur_pa_dep(proj_info_rec.cur_project_id,proj_info_rec.project_id)
             LOOP

                APPS.PA_RELATIONSHIP_PVT.Create_dependency
                              (
                                p_api_version                       => 1.0
                               ,p_init_msg_list                     => l_init_msg_list
                               ,p_commit                            => l_commit
                               ,p_validate_only                     => 'Y'
                               ,p_validation_level                  => 100
                               ,p_calling_module                    => 'BATCH'  --'SELF_SERVICE'
                               ,p_debug_mode                        => 'N'
                               ,p_max_msg_count                     => 100
                               ,p_src_proj_id                       => proj_info_rec.cur_project_id
                               ,p_src_task_ver_id                   => pa_dep_rec.src_task_ver_id
                               ,p_dest_proj_id                      => proj_info_rec.cur_project_id
                               ,p_dest_task_ver_id                  => pa_dep_rec.dest_task_ver_id
                               ,p_type                              => pa_dep_rec.relationship_subtype
                               ,p_lag_days                          => pa_dep_rec.lag_day
                               ,p_comments                          => null
                               ,x_return_status                     => l_return_status
                               ,x_msg_count                         => l_msg_count
                               ,x_msg_data                          => l_msg_data
                              );
                              
                 
                    IF l_return_status != 'S'
                     THEN
                         FOR i IN 1.. NVL(l_msg_count,0)
                         LOOP
                             PA_INTERFACE_UTILS_PUB.get_messages (p_encoded =>  'F',
                                        p_msg_count     =>  l_msg_count,
                                        p_msg_index     =>  i,
                                        p_msg_data      =>  l_msg_data,
                                        p_data          =>  l_error_data,
                                        p_msg_index_out =>  l_msg_index_out);

                              --DBMS_OUTPUT.put_line('Create Dependency API Error:'||l_error_data||':'||sqlerrm);
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'Create Dependency API Error:'||l_error_data);
                         END LOOP;
                    END IF;         
                              
              END LOOP ;
                              
 
----
          -- If Valid Template was found. Get Task details from Template
          --
          IF NVL (lr_project_in_rec.pa_project_id, 0) > 0
          THEN
             --
             lr_tasks_tbl_count := 0;
             --
             FOR pa_tasks_rec IN cur_pa_tasks(proj_info_rec.cur_project_id,proj_info_rec.project_id)
             LOOP

                lr_tasks_tbl_count                           := lr_tasks_tbl_count+1;
                lr_task_in_rec_type.pa_task_id               := pa_tasks_rec.task_id ;
                --lr_task_in_rec_type.task_name                := pa_tasks_rec.task_name;
                lr_task_in_rec_type.task_start_date          := pa_tasks_rec.start_date;
                lr_task_in_rec_type.task_completion_date     := pa_tasks_rec.completion_date ;
                lr_task_in_rec_type.actual_start_date        := pa_tasks_rec.actual_start_date ;   
                lr_task_in_rec_type.actual_finish_date       := pa_tasks_rec.actual_finish_date ;
                lr_task_in_rec_type.early_start_date         := pa_tasks_rec.early_start_date ;
                lr_task_in_rec_type.early_finish_date        := pa_tasks_rec.early_finish_date ;
                lr_task_in_rec_type.late_start_date          := pa_tasks_rec.late_start_date ;       
                lr_task_in_rec_type.late_finish_date         := pa_tasks_rec.late_finish_date ;        

                --lr_task_in_rec_type.pm_parent_task_reference := pa_tasks_rec.parent_task_id;  --pa_tasks_rec.pm_parent_task_reference;  
                --lr_task_in_rec_type.pa_parent_task_id        := pa_tasks_rec.parent_task_id;
                lr_task_in_rec_type.task_manager_person_id   := pa_tasks_rec.person_id;   
                lr_task_in_rec_type.scheduled_start_date     := pa_tasks_rec.baseline_start_date;   
                lr_task_in_rec_type.scheduled_finish_date    := pa_tasks_rec.baseline_finish_date;   
                lr_task_in_rec_type.BASELINE_START_DATE      := pa_tasks_rec.baseline_start_date;
                lr_task_in_rec_type.BASELINE_FINISH_DATE     := pa_tasks_rec.baseline_finish_date;
                lr_task_in_rec_type.CLOSED_DATE              := pa_tasks_rec.closed_date;
                lr_task_in_rec_type.status_code              := pa_tasks_rec.status_code;
               
                lr_tasks_in_tbl(lr_tasks_tbl_count)          := lr_task_in_rec_type;        
                
                  
                     update pa_proj_elements
                        set manager_person_id  = pa_tasks_rec.person_id
                           ,baseline_start_date = pa_tasks_rec.baseline_start_date
                           ,baseline_finish_date = pa_tasks_rec.baseline_finish_date
                           ,wf_item_type         = 'XXPATNOT'
                           ,wf_process           = 'XX_PA_PB_TASK_EXEC_FLOW'
                           ,enable_wf_flag       = 'Y'
                           ,wf_start_lead_days   = 0
                      where proj_element_id = pa_tasks_rec.task_id ;   
                      
                      
                      update pa_proj_elem_ver_schedule
                         set scheduled_start_date   = pa_tasks_rec.scheduled_start_date
                            ,scheduled_finish_date  = pa_tasks_rec.scheduled_finish_date
                            ,actual_start_date      = pa_tasks_rec.actual_start_date
                            ,actual_finish_date     = pa_tasks_rec.actual_finish_date
                            ,duration               = pa_tasks_rec.duration
                            ,early_start_date       = pa_tasks_rec.early_start_date
                            ,early_finish_date      = pa_tasks_rec.early_finish_date
                            ,late_start_date        = pa_tasks_rec.late_start_date
                            ,late_finish_date       = pa_tasks_rec.late_finish_date
                            ,actual_duration        = pa_tasks_rec.actual_duration
                            ,estimated_duration     = pa_tasks_rec.estimated_duration
                       where proj_element_id        = pa_tasks_rec.task_id ; 
                      

             END LOOP;
             
             
            lr_deliv_tbl_count := 0;
                         --
            FOR pa_dlvr_rec IN cur_pa_dlvr(proj_info_rec.cur_project_id,proj_info_rec.project_id)
            LOOP

            lr_deliv_tbl_count                         := lr_deliv_tbl_count+1;

            lr_deliv_rec_type.deliverable_short_name   := pa_dlvr_rec.element_number ;
            --lr_deliv_rec_type.deliverable_name         := pa_dlvr_rec.element_name;
            --lr_deliv_rec_type.description              := pa_dlvr_rec.element_name;
            lr_deliv_rec_type.deliverable_owner_id     := pa_dlvr_rec.cur_person_id;
            lr_deliv_rec_type.status_code              := pa_dlvr_rec.status_code;
            lr_deliv_rec_type.due_date                 := pa_dlvr_rec.due_date;
            lr_deliv_rec_type.completion_date          := pa_dlvr_rec.completion_date;
            --lr_deliv_rec_type.pm_source_code           := pa_dlvr_rec.pm_source_code;
            --lr_deliv_rec_type.pm_deliverable_reference := pa_dlvr_rec.proj_element_id;
            lr_deliv_rec_type.deliverable_id           := pa_dlvr_rec.cur_proj_element_id;
            --lr_deliv_rec_type.task_id                  := pa_dlvr_rec.task_id;
            --lr_deliv_rec_type.task_source_reference    := pa_dlvr_rec.task_source_reference;
            lr_deliverables_in_tbl(lr_deliv_tbl_count) := lr_deliv_rec_type; 

            END LOOP;
            
          

          END IF;
--    
        
                    
--                    
                    
                      Pa_Project_Pub.update_project
                                ( p_api_version_number      => l_api_version_num
                                 ,p_commit                  => l_commit
                                 ,p_init_msg_list           => l_init_msg_list
                                 ,p_msg_count               => l_msg_count
                                 ,p_msg_data                => l_msg_data
                                 ,p_return_status           => l_return_status
                                 ,p_workflow_started        => l_workflow_started
                                 ,p_pm_product_code         => l_pm_product_code
                                 ,p_op_validate_flag        => 'Y' 
                                 ,p_project_in              => lr_project_in_rec
                                 ,p_project_out             => lr_project_out_rec
                                 --,p_customers_in            => lr_customers_in_tbl
                                 --,p_key_members             => lr_key_members_in_tbl
                                 --,p_class_categories        => lr_class_categories_in_tbl
                                 ,p_tasks_in                => lr_tasks_in_tbl
                                 ,p_tasks_out               => lr_tasks_out_tbl
                                 --,p_org_roles               => lr_org_roles_in_tbl
                                 ,p_structure_in            => lr_structure_in_rec
                                 --,p_ext_attr_tbl_in         => lr_ext_attr_in_tbl
                                 ,p_pass_entire_structure   => 'Y'  
                                 ,p_deliverables_in         => lr_deliverables_in_tbl
                                 ,p_deliverable_actions_in  => lr_deliverable_actions_in_tbl
                                 ,p_update_mode             => 'PA_UPD_WBS_ATTR' 
                                );                  
                                
                                
                 --dbms_output.put_line('updated Project ID :'||lr_project_out_rec.pa_project_id) ;
                 --dbms_output.put_line('Updated Project return status :'||lr_project_out_rec.return_status) ;  

                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated Project ID :'||lr_project_out_rec.pa_project_id);
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated Project return status :'||lr_project_out_rec.return_status);                          

                 

                 
                    IF l_return_status != 'S'
                     THEN
                         x_retcode := 'F' ;
                         FOR i IN 1.. NVL(l_msg_count,0)
                         LOOP
                             PA_INTERFACE_UTILS_PUB.get_messages (p_encoded =>  'F',
                                        p_msg_count     =>  l_msg_count,
                                        p_msg_index     =>  i,
                                        p_msg_data      =>  l_msg_data,
                                        p_data          =>  l_error_data,
                                        p_msg_index_out =>  l_msg_index_out);

                              --DBMS_OUTPUT.put_line('Update Project API Error:'||l_error_data||':'||sqlerrm);
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'Update Project API Error:'||l_error_data);
                         END LOOP;
                    END IF;                        
                    
                    x_retcode := 'S' ;    
                                  
  END LOOP;                    
-- 
 commit;
EXCEPTION
 WHEN OTHERS THEN
         --FND_FILE.PUT_LINE(FND_FILE.LOG,'Undefined Err Msg: ' ||SQLERRM);
         dbms_output.PUT_LINE('Undefined Err Msg: ' ||SQLERRM);
         
END update_project_info;

---
--
PROCEDURE create_project_info ( x_errbuf           OUT NOCOPY VARCHAR2
                             , x_retcode           OUT NOCOPY VARCHAR2
                             , p_project_number     IN  VARCHAR2
                             , p_template_number    IN  VARCHAR2
                             )
IS



lr_project_in_null_rec          pa_project_pub.project_in_rec_type;
lr_project_in_rec               pa_project_pub.project_in_rec_type;
lr_structure_in_rec             pa_project_pub.structure_in_rec_type;
lr_key_members_in_tbl           pa_project_pub.project_role_tbl_type;
lr_key_members_in_rec           pa_project_pub.project_role_rec_type;
lr_class_categories_in_tbl      pa_project_pub.class_category_tbl_type;
lr_tasks_in_tbl                 pa_project_pub.task_in_tbl_type;
lr_task_in_rec_type             pa_project_pub.task_in_rec_type;
lr_org_roles_in_tbl             pa_project_pub.project_role_tbl_type;
lr_ext_attr_in_tbl              pa_project_pub.PA_EXT_ATTR_TABLE_TYPE;
lr_ext_attr_rec_type            pa_project_pub.PA_EXT_ATTR_ROW_TYPE ;
lr_key_members_tbl_count        NUMBER:=0;
lr_class_categories_tbl_count   NUMBER:=0;
lr_tasks_tbl_count              NUMBER:=0;
lr_org_roles_tbl_count          NUMBER:=0;
lr_ext_attr_tbl_count           NUMBER := 0;
lr_project_out_null_rec         pa_project_pub.project_out_rec_type;
lr_project_out_rec              pa_project_pub.project_out_rec_type;
lr_tasks_out_tbl                pa_project_pub.task_out_tbl_type;
lr_structure_out_rec            pa_project_pub.structure_out_rec_type;
lr_deliverables_in_tbl          pa_project_pub.deliverable_in_tbl_type     ;
lr_deliv_rec_type               pa_project_pub.deliverable_in_rec_type ;
lr_deliverables_out_tbl         pa_project_pub.deliverable_out_tbl_type    ;
lr_deliverable_actions_in_tbl   pa_project_pub.action_in_tbl_type  ;
lr_action_in_rec_type           pa_project_pub.action_in_rec_type ;
lr_deliverable_actions_out_tbl  pa_project_pub.action_out_tbl_type ;
lr_deliv_tbl_count              NUMBER := 0;
lr_dlvr_actions_in_tbl_count    NUMBER := 0;
lr_customers_in_tbl             pa_project_pub.customer_tbl_type; 
l_pm_product_code               pa_budget_versions.pm_product_code%TYPE   := 'WORKPLAN';
l_pm_project_reference          VARCHAR2(100);
l_user_name                     fnd_user.user_name%TYPE;
l_resp_name                     pa_user_resp_v.responsibility_name%TYPE;
l_user_id                       NUMBER;
l_resp_id                       NUMBER;
l_resp_appl_id                  NUMBER;
l_profile_org_id                NUMBER;
l_api_version_num               NUMBER            := 1.0;
l_commit                        VARCHAR2(10)      := 'T';
l_init_msg_list                 VARCHAR2(10)      := 'T';
l_msg_count                     NUMBER;
l_msg_data                      VARCHAR2(4000);
l_return_status                 VARCHAR2(1);
l_error_data                    VARCHAR2(4000);
l_msg_index_out                 VARCHAR2(1000);
l_workflow_started              VARCHAR2(10);
i                               NUMBER    := 0; --counter
j                               NUMBER    := 0; --counter
l_delta                         VARCHAR2(10) ;
l_new_attr_group_id             NUMBER ;
l_errbuf                        VARCHAR2(150);
l_retcode                       VARCHAR2(150);

    CURSOR cur_proj_info IS
      SELECT ppa.segment1 template_number,ppa.name template_name,hou.name org_name,
               ppa1.*
        FROM apps.pa_projects_all@GSIPRD01.NA.ODCORP.NET  ppa,
             apps.pa_projects_all@GSIPRD01.NA.ODCORP.NET  ppa1,
             apps.hr_all_organization_units@GSIPRD01.NA.ODCORP.NET hou
        WHERE ppa.project_id = ppa1.created_from_project_id
          AND ppa1.template_flag = 'N'     
          AND ppa1.carrying_out_organization_id = hou.organization_id
          AND ppa.segment1 = NVL(p_template_number,ppa.segment1)
          AND ppa1.segment1 = NVL(p_project_number,ppa1.segment1)
          AND NOT EXISTS (SELECT 'x'
                            FROM apps.pa_projects_all pp
                           WHERE pp.segment1 = ppa1.segment1) 
          AND rownum <= 15;

    CURSOR cur_pa_key_mem (p_project_id number) IS
          SELECT ppf1.full_name cur_full_name,ppf1.person_id cur_person_id,ppr.project_role_type,ppp.* 
      FROM apps.pa_project_parties@GSIPRD01.NA.ODCORP.NET ppp,
           apps.pa_project_role_types_b@GSIPRD01.NA.ODCORP.NET ppr,
           apps.per_all_people_f@GSIPRD01.NA.ODCORP.NET ppf,
           apps.per_all_people_f ppf1
     WHERE ppp.project_id = p_project_id      
       AND ppr.project_role_type = 'PROJECT MANAGER'  
       AND ppp.project_role_id = ppr.project_role_id 
       AND ppp.resource_source_id = ppf.person_id
       AND ppf.employee_number    = ppf1.employee_number
       AND trunc(sysdate) between ppf1.effective_start_date and ppf1.effective_end_date;

    CURSOR cur_pa_tasks (p_project_id number) IS
    SELECT pev.display_sequence,ppe.closed_date,
           ppe.baseline_start_date,ppe.baseline_finish_date,ppe.baseline_duration,pat.*
      FROM pa_tasks pat,
           pa_proj_elements ppe,
           pa_proj_element_versions pev,
           pa_proj_elem_ver_schedule ppevs
     WHERE pat.project_id = p_project_id
       and pat.task_id = ppe.proj_element_id
       and pat.task_id = pev.proj_element_id
       and ppe.proj_element_id = ppevs.proj_element_id
       and ppe.project_id = ppevs.project_id
       and pev.object_type = 'PA_TASKS'
      order by 1        ;
     
    CURSOR cur_pa_dlvr (p_project_id number) IS
    SELECT pao.object_id_from2 src_task_id,pad.*
      FROM PA_DELIVERABLES_V pad,
           PA_OBJECT_RELATIONSHIPS pao
     where pad.project_id = p_project_id 
       and pad.proj_element_id = pao.object_id_to2
       and pao.object_type_to = 'PA_DELIVERABLES'
       and pao.relationship_type = 'A'
       and pao.object_type_from = 'PA_TASKS'
       and pao.relationship_subtype = 'TASK_TO_DELIVERABLE' ;
     
    CURSOR cur_pa_ext_attr (p_project_id number) IS
    SELECT ppa.segment1,ppa.project_id,eag.attr_group_id,
           eag.attr_group_type,eag.attr_group_name,eag.attr_group_disp_name,
           ppe.extension_id
      FROM apps.pa_projects_all@GSIPRD01.NA.ODCORP.NET ppa,
           apps.pa_projects_erp_ext_b@GSIPRD01.NA.ODCORP.NET ppe,
           apps.ego_attr_groups_v@GSIPRD01.NA.ODCORP.NET eag
     WHERE ppa.project_id = ppe.project_id
       AND ppe.attr_group_id = eag.attr_group_id
       AND eag.attr_group_type = 'PA_PROJ_ATTR_GROUP_TYPE'
       AND eag.application_id = g_application_id
       AND ppa.project_id = p_project_id ;

begin

--

              -- User Login  Info
                BEGIN
                           l_user_name      := g_user_name ;
                           l_resp_name      := g_resp_name ;
                           l_resp_appl_id   := g_resp_appl_id ;
                           l_user_id        := g_user_id ;
                           l_resp_id        := g_resp_id ;
                           l_profile_org_id := g_org_id ;

                   FND_FILE.PUT_LINE(FND_FILE.LOG,'USER ID:'||l_user_id||'RESP ID:'||
                   l_resp_id||'RESP APPL ID:'||l_resp_appl_id||'PROFILE ORG ID:'||l_profile_org_id);
                   DBMS_OUTPUT.put_line('USER ID:'||l_user_id||'RESP ID:'||
                   l_resp_id||'RESP APPL ID:'||l_resp_appl_id||'PROFILE ORG ID:'||l_profile_org_id);

                    FND_GLOBAL.apps_initialize
                             (
                              user_id        => l_user_id,  --29446,  
                              resp_id        => l_resp_id,  --50339,  
                              resp_appl_id   => l_resp_appl_id --275  
                             );

                    PA_INTERFACE_UTILS_PUB.set_global_info
                            (
                             p_api_version_number    => 1.0,
                             p_responsibility_id     => l_resp_id,  --50339,  
                             p_user_id               => l_user_id,  --29446,  
                             p_msg_count             => l_msg_count,
                             p_msg_data              => l_msg_data,
                             p_return_status         => l_return_status
                            );

                            IF l_return_status != 'S'
                             THEN
                                 FOR i IN 1.. NVL(l_msg_count,0)
                                 LOOP
                                     PA_INTERFACE_UTILS_PUB.get_messages (p_encoded =>  'F',
                                                p_msg_count     =>  l_msg_count,
                                                p_msg_index     =>  i,
                                                p_msg_data      =>  l_msg_data,
                                                p_data          =>  l_error_data,
                                                p_msg_index_out =>  l_msg_index_out);

                                      --DBMS_OUTPUT.put_line('User and Responsibility:'||l_error_data||':'||sqlerrm);
                                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Users and Responsibility Error:'||l_error_data);
                                 END LOOP;
                            END IF;
                END;

      --FND_FILE.PUT_LINE(FND_FILE.LOG,'Project Number: '||p_project_number);
      --FND_FILE.PUT_LINE(FND_FILE.LOG,'Project Type: '||p_project_type);
      --FND_FILE.PUT_LINE(FND_FILE.LOG,'Template Flag: '||p_template_flag);

--

  FOR proj_info_rec IN cur_proj_info
  LOOP

   lr_project_in_rec.pa_project_number  := proj_info_rec.segment1 ;  
   lr_project_in_rec.project_name       := proj_info_rec.name ;
   lr_project_in_rec.long_name          := proj_info_rec.long_name ;
   lr_project_in_rec.created_from_project_id := get_project_id(proj_info_rec.template_name,'Y') ;
   lr_project_in_rec.carrying_out_organization_id := get_organization_id(proj_info_rec.org_name) ;
   lr_project_in_rec.public_sector_flag     :='N' ;
   lr_project_in_rec.project_status_code    := 'UNAPPROVED'  ;  --proj_info_rec.project_status_code ;
   lr_project_in_rec.description            := proj_info_rec.description ;
   lr_project_in_rec.start_date             := proj_info_rec.start_date ;
   lr_project_in_rec.pm_project_reference   := proj_info_rec.segment1 ;


--    i := lr_key_members_in_tbl.first;

--    IF lr_key_members_in_tbl.exists(i)
--    THEN
--    WHILE i IS NOT NULL LOOP
--        lr_key_members_in_tbl(i).person_id := 841;
--        lr_key_members_in_tbl(i).project_role_type := 'PROJECT MANAGER';
--        lr_key_members_in_tbl(i).start_date := NULL;

--    i := lr_key_members_in_tbl.next(i);

--    END LOOP;           
--    END IF;
    
                 lr_key_members_tbl_count := 0;
             --
             FOR pa_key_mem_rec IN cur_pa_key_mem(proj_info_rec.project_id)
             LOOP
             
                lr_key_members_tbl_count                := lr_key_members_tbl_count + 1 ;
                lr_key_members_in_rec.person_id         := pa_key_mem_rec.cur_person_id ;
                lr_key_members_in_rec.project_role_type := pa_key_mem_rec.project_role_type ;
                lr_key_members_in_rec.start_date        := proj_info_rec.scheduled_start_date ;
                lr_key_members_in_tbl(lr_key_members_tbl_count) := lr_key_members_in_rec ;
             END LOOP;
    
--
          -- If Valid Template was found. Get Task details from Template
          --
          IF NVL (lr_project_in_rec.created_from_project_id, 0) > 0
          THEN
             --
             lr_tasks_tbl_count := 0;
             --
             FOR pa_tasks_rec IN cur_pa_tasks(lr_project_in_rec.created_from_project_id)
             LOOP

                lr_tasks_tbl_count                           := lr_tasks_tbl_count+1;
                lr_task_in_rec_type.pm_task_reference        := pa_tasks_rec.task_id ; --NVL(pa_tasks_rec.pm_task_reference,pa_tasks_rec.task_name);
                lr_task_in_rec_type.task_name                := pa_tasks_rec.task_name;
                lr_task_in_rec_type.pa_task_number           := pa_tasks_rec.task_number;
                lr_task_in_rec_type.task_description         := pa_tasks_rec.description;
                lr_task_in_rec_type.task_start_date          := lr_project_in_rec.start_date;
                lr_task_in_rec_type.task_completion_date     := lr_project_in_rec.completion_date;
                lr_task_in_rec_type.actual_start_date        := pa_tasks_rec.actual_start_date ;   
                lr_task_in_rec_type.actual_finish_date       := pa_tasks_rec.actual_finish_date ;                
                lr_task_in_rec_type.service_type_code        := pa_tasks_rec.service_type_code;
                --lr_task_in_rec_type.pa_task_id               := pa_tasks_rec.task_id ;
                lr_task_in_rec_type.long_task_name           := pa_tasks_rec.long_task_name;
                lr_task_in_rec_type.pm_parent_task_reference := pa_tasks_rec.parent_task_id;  --pa_tasks_rec.pm_parent_task_reference;  
                --lr_task_in_rec_type.pa_parent_task_id        := pa_tasks_rec.parent_task_id;
                lr_task_in_rec_type.task_manager_person_id   := pa_tasks_rec.task_manager_person_id;   
                lr_task_in_rec_type.scheduled_start_date     := pa_tasks_rec.baseline_start_date;   
                lr_task_in_rec_type.scheduled_finish_date    := pa_tasks_rec.baseline_finish_date;   
                lr_task_in_rec_type.BASELINE_START_DATE      := pa_tasks_rec.baseline_start_date;
                lr_task_in_rec_type.BASELINE_FINISH_DATE     := pa_tasks_rec.baseline_finish_date;
                lr_task_in_rec_type.CLOSED_DATE              := pa_tasks_rec.closed_date;
                lr_task_in_rec_type.attribute_category       := pa_tasks_rec.attribute_category;   
                lr_task_in_rec_type.attribute1               := pa_tasks_rec.attribute1;
                lr_task_in_rec_type.attribute2               := pa_tasks_rec.attribute2;
                lr_task_in_rec_type.attribute3               := pa_tasks_rec.attribute3;
                lr_task_in_rec_type.attribute4               := pa_tasks_rec.attribute4;
                lr_task_in_rec_type.attribute5               := pa_tasks_rec.attribute5;
                lr_task_in_rec_type.attribute6               := pa_tasks_rec.attribute6;
                lr_task_in_rec_type.attribute7               := pa_tasks_rec.attribute7;
                lr_task_in_rec_type.attribute8               := pa_tasks_rec.attribute8;
                lr_task_in_rec_type.attribute9               := pa_tasks_rec.attribute9;
                lr_task_in_rec_type.attribute10              := pa_tasks_rec.attribute10;
                --lr_task_in_rec_type.mapped_task_id           := pa_tasks_rec.mapped_task_id;  
                --lr_task_in_rec_type.mapped_task_reference    := pa_tasks_rec.mapped_task_reference;                
                lr_task_in_rec_type.display_sequence         := pa_tasks_rec.display_sequence;
                lr_task_in_rec_type.wbs_level                := pa_tasks_rec.wbs_level ;   
                
                lr_tasks_in_tbl(lr_tasks_tbl_count)          := lr_task_in_rec_type;              
                

             END LOOP;
             
             
            lr_deliv_tbl_count := 0;
                         --
            FOR pa_dlvr_rec IN cur_pa_dlvr(lr_project_in_rec.created_from_project_id)
            LOOP

            lr_deliv_tbl_count                         := lr_deliv_tbl_count+1;

            lr_deliv_rec_type.deliverable_short_name   := pa_dlvr_rec.element_name ;
            lr_deliv_rec_type.deliverable_name         := pa_dlvr_rec.element_name;
            lr_deliv_rec_type.description              := pa_dlvr_rec.element_name;
            lr_deliv_rec_type.deliverable_owner_id     := pa_dlvr_rec.manager_person_id;
            lr_deliv_rec_type.status_code              := pa_dlvr_rec.status_code;
            lr_deliv_rec_type.deliverable_type_id      := pa_dlvr_rec.dlvr_type_id;
            lr_deliv_rec_type.progress_weight          := pa_dlvr_rec.progress_weight;
            lr_deliv_rec_type.due_date                 := pa_dlvr_rec.due_date;
            lr_deliv_rec_type.completion_date          := pa_dlvr_rec.completion_date;
            --lr_deliv_rec_type.pm_source_code           := pa_dlvr_rec.pm_source_code;
            lr_deliv_rec_type.pm_deliverable_reference := pa_dlvr_rec.proj_element_id;
            --lr_deliv_rec_type.deliverable_id           := pa_dlvr_rec.deliverable_id;
            --lr_deliv_rec_type.task_id                  := pa_dlvr_rec.task_id;
            lr_deliv_rec_type.task_source_reference    := pa_dlvr_rec.src_task_id;
            lr_deliverables_in_tbl(lr_deliv_tbl_count) := lr_deliv_rec_type; 

            END LOOP;
            
           

          END IF;
--    

        Pa_Project_Pub.Create_Project
                (
                  p_api_version_number          => l_api_version_num
                 ,p_commit                      => l_commit
                 ,p_init_msg_list               => l_init_msg_list
                 ,p_msg_count                   => l_msg_count
                 ,p_msg_data                    => l_msg_data
                 ,p_return_status               => l_return_status
                 ,p_workflow_started            => l_workflow_started
                 ,p_pm_product_code             => l_pm_product_code
                 ,p_op_validate_flag            => 'Y' 
                 ,p_project_in                  => lr_project_in_rec
                 ,p_project_out                 => lr_project_out_rec 
                 ,p_customers_in                => lr_customers_in_tbl
                 ,p_key_members                 => lr_key_members_in_tbl
                 ,p_class_categories            => lr_class_categories_in_tbl
                 ,p_tasks_in                    => lr_tasks_in_tbl
                 ,p_tasks_out                   => lr_tasks_out_tbl 
                 ,p_org_roles                   => lr_org_roles_in_tbl
                 ,p_structure_in                => lr_structure_in_rec
                 ,p_ext_attr_tbl_in             => lr_ext_attr_in_tbl 
                 ,p_deliverables_in             => lr_deliverables_in_tbl 
                 ,p_deliverable_actions_in      => lr_deliverable_actions_in_tbl 
                 );

                 --dbms_output.put_line('New Project ID :'||lr_project_out_rec.pa_project_id) ;
                 --dbms_output.put_line('New Project return status :'||lr_project_out_rec.return_status) ;                            
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'New Project ID :'||lr_project_out_rec.pa_project_id);
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'New Project return status :'||lr_project_out_rec.return_status);
                 

                 
                    IF l_return_status != 'S'
                     THEN
                         FOR i IN 1.. NVL(l_msg_count,0)
                         LOOP
                             PA_INTERFACE_UTILS_PUB.get_messages (p_encoded =>  'F',
                                        p_msg_count     =>  l_msg_count,
                                        p_msg_index     =>  i,
                                        p_msg_data      =>  l_msg_data,
                                        p_data          =>  l_error_data,
                                        p_msg_index_out =>  l_msg_index_out);

                              --DBMS_OUTPUT.put_line('Create Project API Error:'||l_error_data||':'||sqlerrm);
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'Create Project API Error:'||l_error_data);
                         END LOOP;
                    END IF;
                    
                    
--
            FOR pa_attr_rec IN cur_pa_ext_attr(proj_info_rec.project_id)
            LOOP

                    l_new_attr_group_id := get_attr_group_id(pa_attr_rec.attr_group_disp_name) ;
               
               CREATE_ATTR_INFO (
                               x_msg_data           => l_msg_data
                             , x_return_status      => l_return_status
                             , p_old_project_id     => proj_info_rec.project_id
                             , p_new_project_id     => lr_project_out_rec.pa_project_id                             
                             , p_old_attr_group_id  => pa_attr_rec.attr_group_id
                             , p_new_attr_group_id  => l_new_attr_group_id
                             , p_old_extension_id   => pa_attr_rec.extension_id
                             ) ;
                             
                             
                     IF l_return_status != 'S'
                     THEN
                         FOR i IN 1.. NVL(l_msg_count,0)
                         LOOP
                             PA_INTERFACE_UTILS_PUB.get_messages (p_encoded =>  'F',
                                        p_msg_count     =>  l_msg_count,
                                        p_msg_index     =>  i,
                                        p_msg_data      =>  l_msg_data,
                                        p_data          =>  l_error_data,
                                        p_msg_index_out =>  l_msg_index_out);

                              --DBMS_OUTPUT.put_line('Create Project API Error:'||l_error_data||':'||sqlerrm);
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'Create Attr API Error:'||l_error_data);
                         END LOOP;
                    END IF;
   
            END LOOP;

--                    
-- Call Update project API  

                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Before update Project API');
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'update Project API project id :'||lr_project_out_rec.pa_project_id);

                    update_project_info ( x_errbuf             => l_errbuf
                                         ,x_retcode            => l_retcode
                                         ,p_upd_project_id     => lr_project_out_rec.pa_project_id
                                        ) ;
                                        
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'After update Project API');
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Update Project API ret code:'||l_retcode);
                    
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Before Budget Project API');
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Budget Project API project id :'||lr_project_out_rec.pa_project_id);
                    
                    
                    CREATE_FINPLAN ( retcode          => l_errbuf
                                    ,errbuf           => l_retcode
                                    ,p_cur_project_id => lr_project_out_rec.pa_project_id) ;
                            
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'After Budget Project API');
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Budget Project API ret code:'||l_retcode);
                                  
  END LOOP;                    
-- 
 commit;
EXCEPTION
 WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Undefined Err Msg: ' ||SQLERRM);
         --dbms_output.PUT_LINE('Undefined Err Msg: ' ||SQLERRM);
         
END ;
         
end XX_PA_PROJ_CONV_PKG;
/