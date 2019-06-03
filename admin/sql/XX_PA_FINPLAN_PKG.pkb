CREATE OR REPLACE PACKAGE BODY XX_PA_FINPLAN_PKG IS
/**********************************************************************************
 Program Name: XX_PA_FINPLAN_PKG
 Purpose:      To Create New Revenue Forecast Version.

 REVISIONS:
-- Version Date        Author                               Description
-- ------- ----------- ----------------------               ---------------------
-- 1.0     27-SEP-2007 Siva Boya, Clearpath.         Created base version.
-- 1.1     09-NOV-2007 Siva Boya, Clearpath.         Updated program to run all the projects.
**********************************************************************************/
PROCEDURE XXOD_CREATE_FINPLAN (
                               retcode        OUT VARCHAR2
                              ,errbuf OUT VARCHAR2
                              ,p_project_number IN pa_projects_all.segment1%TYPE) IS

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
 CURSOR proj_id IS   
       SELECT DISTINCT pevs.PROJECT_ID ,PA.SEGMENT1
                  FROM pa_projects_all pa,
                       pa_tasks pt,
                       pa_task_types pty,
                       pa_proj_elements ppe,
                       pa_proj_element_versions pev,
                       pa_proj_elem_ver_schedule pevs
                 WHERE pa.project_id = pt.project_id
                   AND pt.task_id = ppe.proj_element_id
                   AND pa.project_id = ppe.project_id
                   AND ppe.type_id = pty.task_type_id
                   AND ppe.proj_element_id = pev.proj_element_id
                   AND pev.element_version_id = pevs.element_version_id
                   AND pty.task_type = 'LAUNCH'
                   AND pev.TASK_UNPUB_VER_STATUS_CODE='PUBLISHED'
                   AND (TRUNC(pevs.LAST_UPDATE_DATE)=TRUNC(SYSDATE) OR pa.SEGMENT1= NVL(UPPER (p_project_number),NULL))
              ORDER BY pevs.PROJECT_ID ;      
    
    /* Cursor to get the Base line task Info */    
       
         CURSOR res(p_project_id  pa_projects_all.project_id%TYPE) IS 
             
                SELECT pra.resource_list_member_id, rlm.alias, rlm.unit_of_measure,
                       pra.task_id, pra.total_plan_revenue
                  FROM pa_projects_all pa,
                       pa_budget_versions pbv,
                       pa_resource_assignments pra,
                       pa_resource_list_members rlm
                 WHERE pa.project_id = pbv.project_id
                   AND pbv.budget_version_id = pra.budget_version_id
                   AND pra.resource_list_member_id = rlm.resource_list_member_id
                   --AND pa.segment1 = UPPER (p_project_number)                     
                   AND pa.PROJECT_ID=p_project_id
                   AND pbv.budget_status_code = 'B'
                   AND pbv.current_flag = 'Y';
                   --AND pbv.ORIGINAL_FLAG='Y';
    
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
        
        CURSOR new_ver_line_info(p_new_budget_ver_id    pa_budget_versions.budget_version_id%TYPE,
                                 p_new_res_member_id pa_resource_assignments.resource_list_member_id%TYPE,
                                 p_project_id           pa_projects_all.project_id%TYPE) IS
              
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
                     AND pbv.budget_version_id=p_new_budget_ver_id
                     AND pra.resource_list_member_id=p_new_res_member_id
                ORDER BY pbl.resource_assignment_id, pbl.start_date;         
              
    /* Cursor to UPDATE the Line info to New Version lines  */              
        CURSOR update_lines ( p_new_budget_ver_id  pa_budget_versions.budget_version_id%TYPE) IS   
               
               SELECT    a.quantity, a.revenue, a.project_revenue, a.txn_revenue,
                         b.budget_line_id
                    FROM xx_pa_base_line_data_temp a, xx_pa_new_ver_data_temp b
                   WHERE a.resource_list_member_id = b.resource_list_member_id
                     AND a.temp_line_id = b.temp_line_id
                     AND b.new_ver_id = p_new_budget_ver_id
                ORDER BY a.resource_assignment_id, a.start_date;            
               
 BEGIN
            
              -- User Login  Info                         
                BEGIN
                           l_user_name      := FND_PROFILE.value('USERNAME');
                           l_resp_name      := FND_PROFILE.value('RESP_NAME');
                           l_resp_appl_id   := FND_PROFILE.value('RESP_APPL_ID');
                           l_user_id        := FND_PROFILE.value('USER_ID');
                           l_resp_id        := FND_PROFILE.value('RESP_ID');
                           l_profile_org_id := FND_PROFILE.value('ORG_ID');                   
                        
 DBMS_OUTPUT.put_line('USER ID:'||l_user_id||'RESP ID:'||l_resp_id||'RESP APPL ID:'||l_resp_appl_id||'PROFILE ORG ID:'||l_profile_org_id);
                   
                    FND_GLOBAL.apps_initialize
                             (
                              user_id        => l_user_id,
                              resp_id        => l_resp_id,
                              resp_appl_id   => l_resp_appl_id
                             );
                   
                    PA_INTERFACE_UTILS_PUB.set_global_info
                            (
                             p_api_version_number    => 1.0,
                             p_responsibility_id     => l_resp_id,
                             p_user_id               => l_user_id,
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
                                                        
                                                  DBMS_OUTPUT.put_line('User and Responsibility:'||l_error_data||':'||sqlerrm);
                                                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Users and Responsibility Error:'||l_error_data);
                                             END LOOP;              
                            END IF;
                END;
            
       FOR proj_id_rec IN proj_id LOOP  
            l_project_id := proj_id_rec.project_id ; 
            l_project_number :=proj_id_rec.segment1;
            /*  
                  -- Validating  the project Number parameter   
                         BEGIN
                            
                            SELECT project_id
                              INTO l_project_id
                              FROM pa_projects
                             WHERE segment1 =NVL(UPPER (p_project_number),NULL); --NVL(UPPER (p_project_number),proj_id_rec.SEGMENT1);
                         EXCEPTION
                              WHEN NO_DATA_FOUND 
                              THEN
                            DBMS_OUTPUT.put_line('Invalid Project Number'||p_project_number);
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Project Number: '||p_project_number);
                         l_project_id := proj_id_rec.project_id ;  
                        END;      
                   */
                
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Project Number: '||proj_id_rec.segment1);       
          
          -- TO GET THE INITIAL LAUNCH DATE FOR A PROJECT  
         
          BEGIN
            
            DBMS_OUTPUT.put_line ('Before select initial launch date');

                SELECT pee.d_ext_attr1 initial_launch_date
                  INTO l_initial_launch_date
                  FROM pa_projects_all pa,
                       pa_projects_erp_ext_b pee,
                       ego_fnd_dsc_flx_ctx_ext efd
                 WHERE pa.project_id = pee.project_id
                   AND pee.attr_group_id = efd.attr_group_id
                   AND efd.descriptive_flex_context_code = 'PB_GEN_INFO'
                   AND pa.project_id = proj_id_rec.project_id;
             EXCEPTION
                  WHEN NO_DATA_FOUND 
                  THEN
                   DBMS_OUTPUT.put_line('No Initial Launch date found for project:'||l_project_number);
                   FND_FILE.PUT_LINE(FND_FILE.LOG,' There is No  Initial Launch date for the Project : '||l_project_number);  
          END;
               
        /* TO GET THE  SCHEDULE FINISH DATE    */
          BEGIN
           
                SELECT max(pevs.scheduled_finish_date)
                  INTO l_sch_finish_date
                  FROM pa_projects_all pa,
                       pa_tasks pt,
                       pa_task_types pty,
                       pa_proj_elements ppe,
                       pa_proj_element_versions pev,
                       pa_proj_elem_ver_schedule pevs
                 WHERE pa.project_id = pt.project_id
                   AND pt.task_id = ppe.proj_element_id
                   AND pa.project_id = ppe.project_id
                   AND ppe.type_id = pty.task_type_id
                   AND ppe.proj_element_id = pev.proj_element_id
                   AND pev.element_version_id = pevs.element_version_id
                   AND pty.task_type = 'LAUNCH'
                   AND pa.project_id = proj_id_rec.project_id
                   AND pev.TASK_UNPUB_VER_STATUS_CODE='PUBLISHED';
                   
             EXCEPTION
                  WHEN NO_DATA_FOUND 
                  THEN
                 DBMS_OUTPUT.put_line('Scheduled finish date not  found : '||l_project_number);
                FND_FILE.PUT_LINE(FND_FILE.LOG,' There is No  Scheduled finish date for the Project : '||l_project_number);
          END;
                
       IF l_initial_launch_date <> l_sch_finish_date 
       THEN
           BEGIN
                 /* Get the Base line header info to create new version */ 
                 BEGIN   
                    
                      SELECT pbv.description, pbv.fin_plan_type_id, pbv.project_id,
                             pbv.version_name, pbv.version_type, pbv.resource_list_id,
                             pa.pm_project_reference, pfp.revenue_time_phased_code,
                             pfp.plan_in_multi_curr_flag, fpas.revenue_flag, fpas.revenue_qty_flag
                        INTO l_description, l_fin_plan_type_id, l_pa_project_id,
                             l_budget_version_name, l_version_type, l_resource_list_id,
                             l_pm_project_reference, l_time_phased_code,
                             l_plan_in_multi_curr_flag, l_revenue_flag, l_revenue_qty_flag
                        FROM pa_budget_versions pbv,
                             pa_projects_all pa,
                             pa_proj_fp_options pfp,
                             pa_fin_plan_amount_sets fpas
                       WHERE pbv.project_id = pa.project_id
                         AND pbv.budget_version_id = pfp.fin_plan_version_id
                         AND pfp.revenue_amount_set_id = fpas.fin_plan_amount_set_id
                         AND pa.project_id = proj_id_rec.project_id
                         AND pbv.budget_status_code = 'B'
                         AND pbv.original_flag = 'Y';
                 END;
                       /*  Table of Records for API  */                           
                                                     
                 FOR res_rec IN res(proj_id_rec.project_id) LOOP
                  -- FND_FILE.PUT_LINE(FND_FILE.LOG,'TASK ID  : '||res_rec.task_id);       
                     l_finplan_trans_tab(l_record_pos).pm_product_code          := 'PLM-PROJECT';
                     l_finplan_trans_tab(l_record_pos).TASK_ID                  :=res_rec.task_id;
                     l_finplan_trans_tab(l_record_pos).START_DATE               := trunc(l_sch_finish_date);
                     l_finplan_trans_tab(l_record_pos).END_DATE                 := ADD_MONTHS(TRUNC(l_sch_finish_date),11);
                     l_finplan_trans_tab(l_record_pos).REVENUE                  :=res_rec.TOTAL_PLAN_REVENUE;
                     l_finplan_trans_tab(l_record_pos).CURRENCY_CODE            :='USD';  
                     l_finplan_trans_tab(l_record_pos).UNIT_OF_MEASURE_CODE     :=res_rec.UNIT_OF_MEASURE;
                     l_finplan_trans_tab(l_record_pos).RESOURCE_LIST_MEMBER_ID  :=res_rec.RESOURCE_LIST_MEMBER_ID;
                     l_finplan_trans_tab(l_record_pos).RESOURCE_ALIAS           :=res_rec.ALIAS;
                     l_record_pos   :=l_record_pos+1;    
                  
                 END LOOP;
                  l_record_pos :=1;
                                        
                     l_using_resource_list_flag       :='Y';
                     l_fin_plan_level_code            :='T';
            
            /* Call the API to Create the New Forecast Version */
            
            PA_BUDGET_PUB.CREATE_DRAFT_FINPLAN 
                        ( p_api_version_number          => l_api_version_num          
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
            END;                                                           
         
              BEGIN 
                    
                    IF   l_return_status='S' THEN
                       
                                /* Insert base line values into Temp Table  */ 
                      BEGIN
                      
                        FOR base_res_rec IN base_res(proj_id_rec.project_id)
                        LOOP
                            ln_count := 1;
                                                       
                            FOR  base_line_info_rec IN  base_line_info(proj_id_rec.project_id,
                                                                    base_res_rec.resource_list_member_id)
                            LOOP
                                                                        
                             INSERT INTO xx_pa_base_line_data_temp
                                       (base_line_ver_id,
                                        budget_line_id,
                                        quantity,
                                        revenue, 
                                        period_name,
                                        project_revenue,
                                        txn_revenue, 
                                        temp_line_id,
                                        resource_assignment_id,start_date,
                                        resource_list_member_id, alias,project_id,
                                        last_updated_by, last_update_date,
                                        created_by, creation_date
                                       )
                                VALUES (base_line_info_rec.budget_version_id,
                                        base_line_info_rec.budget_line_id, base_line_info_rec.quantity,
                                        base_line_info_rec.revenue, base_line_info_rec.period_name,
                                        base_line_info_rec.project_revenue,
                                        base_line_info_rec.txn_revenue,
                                        base_line_info_rec.resource_list_member_id||'-'||ln_count,--l_temp_line_id||'-'||ln_count,
                                        base_line_info_rec.resource_assignment_id,base_line_info_rec.start_date,
                                        base_line_info_rec.resource_list_member_id,base_line_info_rec.alias,
                                        base_line_info_rec.project_id,
                                        l_user_id , sysdate,
                                        l_user_id, sysdate
                                       );
                              
                                        ln_count := ln_count+1;
                                                                                
                           END LOOP;
                           ln_Count := 1;
                                       
                         END LOOP;     
                            EXCEPTION
	 	                         WHEN OTHERS THEN
	 		                FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception IN Inserting XX_PA_BASE_LINE_DATA_TEMP Table'||sqlerrm);
                            
                      END;
                        
                                    /* Insert New version line values into Temp Table  */
                       BEGIN
                           
                            FOR new_res_rec IN new_res(l_out_finplan_version_id,proj_id_rec.project_id)
                            LOOP
                            lm_count := 1;
                          
                          FOR  new_ver_line_info_rec IN  new_ver_line_info(l_out_finplan_version_id,
                                                          new_res_rec.resource_list_member_id,proj_id_rec.project_id)
                         LOOP
                                
                               INSERT INTO xx_pa_new_ver_data_temp
                                          (new_ver_id,
                                           budget_line_id,
                                           quantity, revenue,
                                           period_name,
                                           project_revenue,
                                           txn_revenue, temp_line_id,
                                           resource_assignment_id,start_date,
                                           resource_list_member_id, alias,project_id,
                                           last_updated_by, last_update_date,
                                           created_by, creation_date
                                          )
                                   VALUES (new_ver_line_info_rec.budget_version_id,
                                           new_ver_line_info_rec.budget_line_id,
                                           new_ver_line_info_rec.quantity, new_ver_line_info_rec.revenue,
                                           new_ver_line_info_rec.period_name,
                                           new_ver_line_info_rec.project_revenue,
                                           new_ver_line_info_rec.txn_revenue,new_ver_line_info_rec.resource_list_member_id||'-'||lm_Count,
                                           new_ver_line_info_rec.resource_assignment_id,new_ver_line_info_rec.start_date,
                                           new_ver_line_info_rec.resource_list_member_id,new_ver_line_info_rec.alias,
                                           new_ver_line_info_rec.project_id,
                                           l_user_id , sysdate,
                                           l_user_id, sysdate
                                          );
                                            lm_Count :=lm_Count+1;
                            
                         END LOOP; 
                                           lm_Count := 1;
                        END LOOP;
                            EXCEPTION
	 	                         WHEN OTHERS THEN
	 		                FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception IN Inserting XX_PA_NEW_VER_DATA_TEMP Table'||sqlerrm);
                       END;   
                           
                           /* Make New version values to NULL */
                           
                            BEGIN
                                
                                UPDATE pa_budget_lines
                                   SET quantity = NULL,
                                       revenue = NULL,
                                       project_revenue = NULL,
                                       txn_revenue = NULL
                                 WHERE budget_version_id = l_out_finplan_version_id;
                             EXCEPTION
			                      WHEN OTHERS THEN
			                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception While making New lines to NULL(Version ID):' ||l_out_finplan_version_id);
				                  FND_FILE.PUT_LINE(FND_FILE.LOG,substr(SQLERRM,1,200));
                             
                            END;
                          
                          /* Update the Base line Current values into New version lines */      
                           BEGIN 
                                FOR update_lines_rec IN update_lines(l_out_finplan_version_id)
                               LOOP
                                    
                                    UPDATE pa_budget_lines
                                       SET quantity = update_lines_rec.quantity,
                                           revenue = update_lines_rec.revenue,
                                           project_revenue = update_lines_rec.project_revenue,
                                           txn_revenue = update_lines_rec.txn_revenue
                                     WHERE budget_line_id = update_lines_rec.budget_line_id;
                                
                               END LOOP;
                            EXCEPTION
			                     WHEN OTHERS THEN
			                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception While Updating the Base line qty to New version lines: ' ||l_out_finplan_version_id);
				                 FND_FILE.PUT_LINE(FND_FILE.LOG,substr(SQLERRM,1,200));
                           END;
                             
                       COMMIT;
                     
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
                                BEGIN
                                    
                                    DELETE XX_PA_BASE_LINE_DATA_TEMP;

                                    DELETE XX_PA_NEW_VER_DATA_TEMP ;
                                    
                                    COMMIT;
                                END;
                                   
                       
              END;      
         ELSE
            FND_FILE.PUT_LINE(FND_FILE.LOG,'New Version not created');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'MESSAGE :Initial Launch Date and Current Launch Dates are same (OR) Dates are not Found');
       END IF;                                     
    END LOOP; -- PROJ_ID CURSOR LOOP
       
   EXCEPTION
        WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Undefind Err Msg: ' ||SQLERRM);
 END;
END XX_PA_FINPLAN_PKG; 
/
EXIT;
