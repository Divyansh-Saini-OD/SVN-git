CREATE OR REPLACE PACKAGE BODY APPS.XX_PA_PROJ_INFO_PURGE_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_PROJ_INFO_PURGE_PKG.pkb                      |
-- | Description :  his objective of this API is to delete projects    |
-- |                 from the PA system.                               |
-- |               All detail information will be deleted.             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       23-Oct-2009 Rama Dwibhashyam     Initial version           |
-- +===================================================================+
--
PROCEDURE purge_project_info ( x_errbuf            OUT NOCOPY VARCHAR2
                             , x_retcode           OUT NOCOPY VARCHAR2
                             , p_project_number     IN  VARCHAR2
                             , p_project_type       IN  VARCHAR2  
                             , p_template_flag      IN  VARCHAR2
                             , p_process_errors     IN  VARCHAR2
                             )
IS

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
    l_budget_type_code                  VARCHAR2(100);
    l_budget_status_code                VARCHAR2(100);
    l_fin_plan_type_name                VARCHAR2(100);
    l_version_number                    VARCHAR2(100);
    l_pa_task_id                        NUMBER;
    l_budget_version_id                 NUMBER;
    l_validation_mode                   VARCHAR2(1) ;
    l_err_code                          NUMBER;
    l_err_stage                         VARCHAR2(630);
    l_err_stack                         VARCHAR2(630);
    l_validate_flag                     VARCHAR2(1);
    l_bulk_flag                         VARCHAR2(1); 
    
    --select * from pa_projects_all

  /* Cursor to get all the projects */
             CURSOR proj_id IS
                   SELECT PA.PROJECT_ID ,PA.SEGMENT1
                     FROM PA_PROJECTS_ALL PA
                    WHERE PA.PROJECT_TYPE = NVL(P_PROJECT_TYPE,PA.PROJECT_TYPE)
                      AND PA.TEMPLATE_FLAG = P_TEMPLATE_FLAG
                      AND PA.SEGMENT1 = NVL(P_PROJECT_NUMBER,PA.SEGMENT1) 
                      AND ROWNUM <= 50;
       

    /* Cursor to get the budget info  */
            CURSOR budget_id (p_project_id           pa_projects_all.project_id%TYPE) IS
                     SELECT  pbv.*  --DISTINCT pra.resource_list_member_id
                      FROM pa_projects_all pa,
                           pa_budget_versions pbv
                     WHERE pa.project_id = pbv.project_id 
                       AND pa.project_id = p_project_id ;

 BEGIN

              -- User Login  Info
                BEGIN
                           l_user_name      := FND_PROFILE.value('USERNAME');
                           l_resp_name      := FND_PROFILE.value('RESP_NAME');
                           l_resp_appl_id   := FND_PROFILE.value('RESP_APPL_ID');
                           l_user_id        := FND_PROFILE.value('USER_ID');
                           l_resp_id        := FND_PROFILE.value('RESP_ID');
                           l_profile_org_id := FND_PROFILE.value('ORG_ID');

 FND_FILE.PUT_LINE(FND_FILE.LOG,'USER ID:'||l_user_id||'RESP ID:'||
                   l_resp_id||'RESP APPL ID:'||l_resp_appl_id||'PROFILE ORG ID:'||l_profile_org_id);
 --DBMS_OUTPUT.put_line('USER ID:'||l_user_id||'RESP ID:'||
 --                  l_resp_id||'RESP APPL ID:'||l_resp_appl_id||'PROFILE ORG ID:'||l_profile_org_id);

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

                                      DBMS_OUTPUT.put_line('User and Responsibility:'||l_error_data||':'||sqlerrm);
                                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Users and Responsibility Error:'||l_error_data);
                                 END LOOP;
                            END IF;
                END;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Project Number: '||p_project_number);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Project Type: '||p_project_type);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Template Flag: '||p_template_flag);
      
      
   IF  p_process_errors   = 'N' THEN
   

       FOR proj_id_rec IN proj_id LOOP
            l_project_id := proj_id_rec.project_id ;
            l_project_number :=proj_id_rec.segment1;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Project Number: '||proj_id_rec.segment1);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Project Id: '||proj_id_rec.project_id);
            --DBMS_OUTPUT.PUT_LINE('Project Number: '||proj_id_rec.segment1);
            --DBMS_OUTPUT.PUT_LINE('Project Project ID: '||proj_id_rec.project_id);

          l_pa_project_id := l_project_id ; 
          
        update pa_proj_elem_ver_structure
           set lock_status_code = NULL,
               locked_by_person_id = null,
               locked_date = null,
               status_code = null,
               current_working_flag = null
         where project_id = l_pa_project_id
           and locked_by_person_id is not null ;

       BEGIN
             

           FOR budget_id_rec IN budget_id(proj_id_rec.project_id) LOOP
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Before Calling Budget version Delete API :');  
            --dbms_output.put_line('Before Calling Budget version Delete API :');
            
                            l_pa_project_id := proj_id_rec.project_id ;
                            l_budget_type_code := budget_id_rec.budget_type_code;
                            l_budget_version_id := budget_id_rec.budget_version_id;
                            l_version_number   := budget_id_rec.version_number ;
                            l_fin_plan_type_id := budget_id_rec.fin_plan_type_id ;
                            l_version_type     := budget_id_rec.version_type ;
                            l_budget_status_code := budget_id_rec.budget_status_code;
                            
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Budget Version Type:'||l_version_type);  
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Budget Status Code :'||l_budget_status_code);       
                   --dbms_output.put_line('Budget Version Type:'||l_version_type);
                   --dbms_output.put_line('Budget Status Code :'||l_budget_status_code);
                            --l_pa_task_id       := 
                            
                    IF (l_version_type = 'REVENUE' AND l_budget_status_code = 'B') THEN
                    
                        PA_BUDGET_UTILS.delete_draft( x_budget_version_id   => l_budget_version_id
                                         ,x_err_code            => l_err_code
                                         ,x_err_stage           => l_err_stage
                                         ,x_err_stack           => l_err_stack  );
                                         
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Budget Delete Draft Error Code :'||l_err_code );
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Budget Delete Draft Error Stage :'||l_err_stage);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Budget Delete Draft Error Stack :'||l_err_stack);               
                         --DBMS_OUTPUT.put_line('Budget Delete version Error Code :'||l_err_code );
                         --DBMS_OUTPUT.put_line('Budget Delete version Error Stage :'||l_err_stage );
                         --DBMS_OUTPUT.put_line('Budget Delete version Error Stack :'||l_err_stack );
                        
                   END IF;


                    IF (l_version_type = 'REVENUE' AND l_budget_status_code = 'S') THEN
                    
                        PA_BUDGET_UTILS.delete_draft( x_budget_version_id   => l_budget_version_id
                                         ,x_err_code            => l_err_code
                                         ,x_err_stage           => l_err_stage
                                         ,x_err_stack           => l_err_stack  );
                                         
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Budget Delete Draft Error Code :'||l_err_code );
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Budget Delete Draft Error Stage :'||l_err_stage);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Budget Delete Draft Error Stack :'||l_err_stack);               
                         --DBMS_OUTPUT.put_line('Budget Delete version Error Code :'||l_err_code );
                         --DBMS_OUTPUT.put_line('Budget Delete version Error Stage :'||l_err_stage );
                         --DBMS_OUTPUT.put_line('Budget Delete version Error Stack :'||l_err_stack );
                        
                   END IF;
                   
                   IF (l_version_type = 'REVENUE' AND l_budget_status_code = 'W') THEN

                            pa_fin_plan_pub.Delete_Version
                                (p_project_id                   => l_pa_project_id
                                ,p_budget_version_id            => l_budget_version_id
                                ,p_record_version_number        => l_version_number 
                                ,p_context                      => 'BUDGET' 
                                ,x_return_status                => l_return_status
                                ,x_msg_count                    => l_msg_count
                                ,x_msg_data                     => l_msg_data);
                                
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Version API return Status :'||l_return_status );
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete VersionAPI Message Count :'||l_msg_count);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete VersionAPI Message Data :'||l_msg_data);                          
                               -- dbms_output.put_line('After  Calling Budget version Delete API :');             
                               -- dbms_output.put_line('API return Status :'||l_return_status); 
                               -- dbms_output.put_line('API Message Count :'||l_msg_count);
                               -- dbms_output.put_line('API Message Data :'||l_msg_data);          
                        
                         IF l_return_status != 'S'
                         THEN
                                FOR i IN 1.. NVL(l_msg_count,1)
                                LOOP
                                        PA_INTERFACE_UTILS_PUB.get_messages (p_encoded       =>  'F',
                                                                    p_msg_count     =>  l_msg_count,
                                                                    p_msg_index     =>  i,
                                                                    p_msg_data      =>  l_msg_data,
                                                                    p_data          =>  l_error_data,
                                                                    p_msg_index_out =>  l_msg_index_out);
                                  --DBMS_OUTPUT.put_line('Error Data during delete budget API:'||l_error_data);
                                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Data:'||l_error_data);
                                END LOOP;
                         ELSE
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Project Budget Delete status:'||l_return_status );
                         --DBMS_OUTPUT.put_line('Project Budget Delete status:'||l_return_status );
                         END IF;    
                       END IF;
                       
                   IF (l_version_type != 'REVENUE' AND l_budget_status_code in ('B','W')) THEN
                            pa_fin_plan_pub.Delete_Version
                                (p_project_id                   => l_pa_project_id
                                ,p_budget_version_id            => l_budget_version_id
                                ,p_record_version_number        => l_version_number 
                                ,p_context                      => 'WORKPLAN' 
                                ,x_return_status                => l_return_status
                                ,x_msg_count                    => l_msg_count
                                ,x_msg_data                     => l_msg_data);
                                
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Version API return Status :'||l_return_status );
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete VersionAPI Message Count :'||l_msg_count);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete VersionAPI Message Data :'||l_msg_data); 
                               -- dbms_output.put_line('After  Calling Budget version Delete API :');             
                               -- dbms_output.put_line('API return Status :'||l_return_status); 
                               -- dbms_output.put_line('API Message Count :'||l_msg_count);
                               -- dbms_output.put_line('API Message Data :'||l_msg_data);          
                        
                         IF l_return_status != 'S'
                                    THEN
                                FOR i IN 1.. NVL(l_msg_count,1)
                                LOOP
                                        PA_INTERFACE_UTILS_PUB.get_messages (p_encoded       =>  'F',
                                                                    p_msg_count     =>  l_msg_count,
                                                                    p_msg_index     =>  i,
                                                                    p_msg_data      =>  l_msg_data,
                                                                    p_data          =>  l_error_data,
                                                                    p_msg_index_out =>  l_msg_index_out);
                                            --DBMS_OUTPUT.put_line('Error Data during delete budget API:'||l_error_data);
                                            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Data:'||l_error_data);
                                END LOOP;
                         ELSE
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Project Budget Delete status:'||l_return_status );
                         --FND_FILE.PUT_LINE(FND_FILE.LOG,'NEW FIN PLAN VERSION ID:'||l_out_finplan_version_id );
                         --DBMS_OUTPUT.put_line('Project Budget Delete status:'||l_return_status );
                         END IF;                                           
                          
                  
                   END IF;
             
           END LOOP;
           
               -- dbms_output.put_line('Before Calling Delete Control Items API :');           
             FOR ci_rec IN( SELECT ci_id, record_version_number
                FROM pa_control_items
                WHERE project_id = l_pa_project_id  ) LOOP

                 --- delete all actions
                       pa_ci_actions_pvt.delete_all_actions(p_validate_only => 'F',
                                                        p_init_msg_list => 'F',
                                                        p_ci_id         => ci_rec.ci_id,
                                                        x_return_status => l_return_status,
                                                        x_msg_count     => l_msg_count,
                                                        x_msg_data      => l_msg_data);
                       --- delete all impacts
                       pa_ci_impacts_util.delete_All_impacts(p_validate_only  => 'F',
                                                        p_init_msg_list => 'F',
                                                        p_ci_id         => ci_rec.ci_id,
                                                        x_return_status => l_return_status,
                                                        x_msg_count     => l_msg_count,
                                                        x_msg_data      => l_msg_data);

                       ---  change status for any included 'CR' to 'APPROVED'
                       ---  call procedure change_included_cr_status
                       pa_control_items_pvt.change_included_cr_status(p_ci_id         => ci_rec.ci_id
                                                ,x_return_status => l_return_status
                                                ,x_msg_count     => l_msg_count
                                                ,x_msg_data      => l_msg_data);

                       ---  delete all related items
                       pa_control_items_pvt.delete_all_related_items (p_validate_only => 'F',
                                                 p_init_msg_list => 'F',
                                                 p_ci_id         => ci_rec.ci_id,
                                                 x_return_status => l_return_status,
                                                 x_msg_count     => l_msg_count,
                                                 x_msg_data      => l_msg_data);

                       ---  delete all included crs
                       pa_control_items_pvt.delete_all_included_crs (p_validate_only => 'F',
                                                p_init_msg_list => 'F',
                                                p_ci_id         => ci_rec.ci_id,
                                                x_return_status => l_return_status,
                                                x_msg_count     => l_msg_count,
                                                x_msg_data      => l_msg_data);

                       ---  delete doc attachments
                       pa_ci_doc_attach_pkg.delete_all_attachments (p_validate_only => 'F',
                                                        p_init_msg_list => 'F',
                                                        p_ci_id         => ci_rec.ci_id,
                                                        x_return_status => l_return_status,
                                                        x_msg_count     => l_msg_count,
                                                        x_msg_data      => l_msg_data);

                       --- delete control_item
                       PA_CONTROL_ITEMS_PKG.DELETE_ROW(
                         ci_rec.ci_id
                        ,ci_rec.record_version_number
                        ,l_return_status
                        ,l_msg_count
                        ,l_msg_data
                       );
                IF l_return_status != 'S'
                            THEN
                        FOR i IN 1.. NVL(l_msg_count,1)
                        LOOP
                                PA_INTERFACE_UTILS_PUB.get_messages (p_encoded       =>  'F',
                                                            p_msg_count     =>  l_msg_count,
                                                            p_msg_index     =>  i,
                                                            p_msg_data      =>  l_msg_data,
                                                            p_data          =>  l_error_data,
                                                            p_msg_index_out =>  l_msg_index_out);
                                    --DBMS_OUTPUT.put_line('Error Data:'||l_error_data);
                                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Control items Error Data:'||l_error_data);
                        END LOOP;
                 ELSE
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Project Control Items Delete status:'||l_return_status);
                 --FND_FILE.PUT_LINE(FND_FILE.LOG,'NEW FIN PLAN VERSION ID:'||l_out_finplan_version_id );
                 --DBMS_OUTPUT.put_line('Project Control Items Delete status:'||l_return_status );
                 END IF;    

                    EXIT WHEN l_return_status <> FND_API.g_ret_sts_success;
             END LOOP;

               
                --dbms_output.put_line('After Calling Delete Control Items API :');
                --dbms_output.put_line('Delete Control Items API Status:'||l_return_status);
                -- dbms_output.put_line('Before Delete Progress :');

                Delete from pa_percent_completes where project_id = l_pa_project_id ;

                Delete from pa_proj_progress_attr where project_id = l_pa_project_id ;

                Delete from pa_progress_rollup where project_id = l_pa_project_id ;
                
                --dbms_output.put_line('After Delete Progress :');                      
                
                   for task_rec in (select t.task_id
                         from   pa_tasks t
                         where  t.project_id = l_pa_project_id
                         and    t.task_id = t.top_task_id) loop

                            l_err_stack := NULL;
                            l_validate_flag := 'Y' ;
                            l_bulk_flag     := 'Y' ;
                              --  dbms_output.put_line('Before Calling Delete task API :');
                            pa_project_core.delete_task(
                                                        x_task_id             => task_rec.task_id,
                                                        x_validation_mode     => l_validation_mode,
                                                        x_validate_flag       => l_validate_flag,
                                                        x_bulk_flag           => l_bulk_flag, 
                                                        x_err_code            => l_err_code,
                                                        x_err_stage           => l_err_stage,
                                                        x_err_stack           => l_err_stack);
                                
                           --     dbms_output.put_line('After Calling Delete task API :');


                        if (l_err_code <> 0) then
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Task API Error Code :'||l_err_code );
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Task API Error Stage :'||l_err_stage);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Task API Error Stack :'||l_err_stack);                            
                                --dbms_output.put_line('Delete Task API Error Code:'||l_err_code);
                                --dbms_output.put_line('Delete Task API Error Stage:'||l_err_stage);
                                --dbms_output.put_line('Delete Task API Error Stack:'||l_err_stack);
                        end if;
                   end loop;
                
            
                
                delete from pa_fp_txn_currencies 
                 where project_id = l_pa_project_id ;
                 
                delete from pa_proj_fp_options 
                 where project_id = l_pa_project_id ;
                 
-----------------

      pa_project_utils.check_delete_project_ok
                         (x_project_id        => l_pa_project_id,
                          x_err_code          => l_err_code,
                          x_err_stage         => l_err_stage,
                          x_err_stack         => l_err_stack);
                          
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project OK API Error Code :'||l_err_code );
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project OK API Error Stage :'||l_err_stage);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project OK API Error Stack :'||l_err_stack);   
                                                 
             --dbms_output.put_line('Check Delete Project OK API Error Code:'||l_err_code);
             --dbms_output.put_line('Check Delete Project OK API Error Stage:'||l_err_stage);
             --dbms_output.put_line('Check Delete Project OK API Error Stack:'||l_err_stack);                          

               IF l_err_code <> 0 THEN

                    IF l_err_code > 0 THEN
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project OK API Error Code :'||l_err_code );
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project OK API Error Stage :'||l_err_stage);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project OK API Error Stack :'||l_err_stack);                    
                     --dbms_output.put_line('Check Delete Project OK API Error Code:'||l_err_code);
                     --dbms_output.put_line('Check Delete Project OK API Error Stage:'||l_err_stage);
                     --dbms_output.put_line('Check Delete Project OK API Error Stack:'||l_err_stack);

                    ELSIF l_err_code < 0 THEN
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project OK API Error Code :'||l_err_code );
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project OK API Error Stage :'||l_err_stage);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project OK API Error Stack :'||l_err_stack);                    
                     --dbms_output.put_line('Check Delete Project OK API Error Code:'||l_err_code);
                     --dbms_output.put_line('Check Delete Project OK API Error Stage:'||l_err_stage);
                     --dbms_output.put_line('Check Delete Project OK API Unexpected Error:'||l_err_stack);

                    END IF;

               END IF;


       IF l_err_code = 0 THEN
       
       --dbms_output.put_line('Before calling delete project API');
       --dbms_output.put_line('Project ID :'||l_pa_project_id);
---------------                 
            APPS.PA_PROJECT_PUB.delete_project
                        ( p_api_version_number  => l_api_version_num
                         ,p_commit              => l_commit
                         ,p_init_msg_list       => l_init_msg_list
                         ,p_msg_count           => l_msg_count
                         ,p_msg_data            => l_msg_data
                         ,p_return_status       => l_return_status
                         ,p_pm_product_code     => l_pm_product_code
                         ,p_pm_project_reference => l_pm_project_reference
                         ,p_pa_project_id       => l_pa_project_id    );
                         
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project API return Status :'||l_return_status );
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project API Message Count :'||l_msg_count);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project API Message Data :'||l_msg_data); 
                                                   
            --dbms_output.put_line('After  Calling Delete API :');             
            --dbms_output.put_line('API return Status :'||l_return_status); 
            --dbms_output.put_line('API Message Count :'||l_msg_count);
            --dbms_output.put_line('API Message Data :'||l_msg_data);
                       
                 IF l_return_status != 'S'
                            THEN
                        FOR i IN 1.. NVL(l_msg_count,1)
                        LOOP
                                PA_INTERFACE_UTILS_PUB.get_messages (p_encoded       =>  'F',
                                                            p_msg_count     =>  l_msg_count,
                                                            p_msg_index     =>  i,
                                                            p_msg_data      =>  l_msg_data,
                                                            p_data          =>  l_error_data,
                                                            p_msg_index_out =>  l_msg_index_out);
                                    --DBMS_OUTPUT.put_line('Error Data:'||l_error_data);
                                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project Error Data:'||l_error_data);
                        END LOOP;
                        
                        ROLLBACK;
                 ELSE
                 
                        FOR i IN 1.. NVL(l_msg_count,1)
                        LOOP
                                PA_INTERFACE_UTILS_PUB.get_messages (p_encoded       =>  'F',
                                                            p_msg_count     =>  l_msg_count,
                                                            p_msg_index     =>  i,
                                                            p_msg_data      =>  l_msg_data,
                                                            p_data          =>  l_error_data,
                                                            p_msg_index_out =>  l_msg_index_out);
                                    --DBMS_OUTPUT.put_line('Error Data:'||l_error_data);
                                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project Error Data:'||l_error_data);
                        END LOOP;
                        
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project API return Status :'||l_return_status );
                         -- FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project API Message Count :'||l_msg_count);
                         -- FND_FILE.PUT_LINE(FND_FILE.LOG,'Delete Project API Message Data :'||l_msg_data); 
                 COMMIT;
                --DBMS_OUTPUT.put_line('Project Delete Msg:'||l_msg_data );
                --DBMS_OUTPUT.put_line('Project Delete Error data:'||l_error_data );
                 --DBMS_OUTPUT.put_line('Project Delete status:'||l_return_status );
                 END IF;                         
                 
        END IF;

       END;

              
    END LOOP; -- PROJ_ID CURSOR LOOP
    
    
  ELSE
  
          delete from pa_projects_all
           where project_type = p_project_type
             and template_flag = p_template_flag
             and project_id not in (select project_id
                                   from pa_proj_elements) ;
          commit;

  END IF;

 EXCEPTION
        WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Undefined Err Msg: ' ||SQLERRM);
 END;
 
END XX_PA_PROJ_INFO_PURGE_PKG ;
/
