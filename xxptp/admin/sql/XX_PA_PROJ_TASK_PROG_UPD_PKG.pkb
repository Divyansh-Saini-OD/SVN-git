SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_PA_PROJ_TASK_PROG_UPD_PKG 
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PA_PROJ_TASK_PROG_UPD_PKG.pks                                     |
-- | Description      : Package spec for CR816 PLM Projects Task Progress Update             |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========       =============    ========================                    |
-- |1.0        13-Sep-2010      Rama Dwibhashyam  Initial draft version                      |
-- +=========================================================================================+

AS

PROCEDURE Process_Main(
                            x_message_data  OUT VARCHAR2
                           ,x_message_code  OUT NUMBER
                           ,p_project_number IN  VARCHAR2 
                           )
IS                           

--p_project_number varchar2(100) := 'PB_D13_002' ;
l_api_version_num               NUMBER            := 1.0;
l_commit                        VARCHAR2(10)      := 'T';
l_init_msg_list                 VARCHAR2(10)      := 'T';
l_msg_count                     NUMBER;
l_msg_data                      VARCHAR2(4000);
l_return_status                 VARCHAR2(1);
l_error_data                    VARCHAR2(4000);
l_msg_index_out                 VARCHAR2(1000);
l_user_name                     fnd_user.user_name%TYPE;
l_resp_name                     pa_user_resp_v.responsibility_name%TYPE;
l_user_id                       NUMBER;
l_resp_id                       NUMBER;
l_resp_appl_id                  NUMBER;
l_profile_org_id                NUMBER;
l_resource_list_member_id       NUMBER;
l_progress_status_code          VARCHAR2(100);
        
CURSOR cur_proj_info IS
 SELECT ppl.project_id cur_project_id,pps1.project_status_code cur_project_status_code,
        ppa.project_id old_project_id, ppa.scheduled_start_date,ppa.scheduled_finish_date
          FROM apps.pa_projects_all ppl,
               apps.pa_projects_all @GSIPRD01.NA.ODCORP.NET ppa,
               apps.pa_project_statuses@GSIPRD01.NA.ODCORP.NET pps,
               apps.pa_project_statuses pps1
         WHERE ppl.segment1 = ppa.segment1
           AND ppa.project_status_code = pps.project_status_code
           AND pps.status_type = 'PROJECT'
           and pps.project_status_name = pps1.project_status_name
           and pps1.status_type = 'PROJECT'
           AND ppa.segment1 = nvl(p_project_number,ppa.segment1)  
           AND not exists (select 'x'
                             from apps.pa_percent_completes ppc1
                            where ppc1.project_id = ppl.project_id) 
           AND rownum <= 25 ;


CURSOR cur_task_info (p_cur_project_id number, p_old_project_id number)IS
SELECT pat1.task_id,ppe1.proj_element_id,
           pat1.task_number,
           pat1.task_name,ppe1.name,
           pat.task_number old_task_number,
           pat.task_name old_task_name,ppe.name old_element_name,
           pev.display_sequence,
           ppe.status_code old_status_code,
           ppe1.status_code new_status_code,
           ppf.full_name,ppf.employee_number,
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
       and pat1.project_id = p_cur_project_id
       and pat1.task_id = pev1.proj_element_id
       and pev1.proj_element_id = ppe1.proj_element_id
       and pev1.object_type = 'PA_TASKS'
       and pat1.task_number = pat.task_number 
       and pat1.task_number = '1004'  ;


CURSOR cur_elem_info (p_cur_project_id number) IS
  select ppevs.*
    from apps.pa_proj_elements ppe,
         apps.pa_proj_element_versions ppev,
         apps.pa_proj_elem_ver_schedule ppevs
   where ppe.project_id = p_cur_project_id
     and ppe.proj_element_id = ppev.proj_element_id
     and ppe.project_id = ppev.project_id
     and ppev.element_version_id = ppevs.element_version_id
     and ppe.proj_element_id = ppevs.proj_element_id
     and ppe.project_id = ppevs.project_id
     and ppev.object_type = 'PA_STRUCTURES'
     and ppev.wbs_number = '0' ;
     
     
    CURSOR cur_task_prog (p_cur_project_id number, p_old_project_id number)IS
SELECT  pat1.project_id,pat1.task_id,ppe1.proj_element_id,ppevs1.element_version_id,pat1.task_number,
           pat1.task_name,ppe1.name,pev.display_sequence,ppe.status_code old_status_code,
           ppe1.status_code new_status_code,
           ppf.full_name,ppf.employee_number,
           ppf.person_id,ppe.closed_date,
           ppe.baseline_start_date,ppe.baseline_finish_date,ppe.baseline_duration,
           pat.start_date,pat.completion_date,
           ppevs.actual_start_date,ppevs.actual_finish_date,
           ppevs.duration,
           ppevs.actual_duration,ppevs.estimated_duration,
           ppevs.early_start_date,ppevs.early_finish_date,
           ppevs.late_start_date,ppevs.late_finish_date,
           ppevs.scheduled_start_date,ppevs.scheduled_finish_date,
           ppc.date_computed,
           ppc.description,
           ppc.percent_complete_id,
           ppr.object_id old_object_id,
           ppr.object_version_id old_object_version_id,
           ppr.object_type,
           ppc.status_code,
           ppr.progress_status_code,
           ppc.estimated_start_date,
           ppc.estimated_finish_date,
           ppc.published_flag,
           ppc.published_by_party_id,
           ppc.progress_comment,
           ppc.history_flag,
           ppc.structure_type,
           ppr.progress_rollup_id,
           ppr.as_of_date,
           ppr.base_percent_complete,
           ppr.eff_rollup_percent_comp,
           ppr.completed_percentage,
           ppr.estimated_remaining_effort,
           ppr.record_version_number,
           ppr.base_progress_status_code,
           ppr.eff_rollup_prog_stat_code,
           ppr.task_wt_basis_code,
           ppr.current_flag,
           ppr.prog_gl_period_name           
      FROM apps.pa_tasks@GSIPRD01.NA.ODCORP.NET pat,
           apps.pa_proj_element_versions@GSIPRD01.NA.ODCORP.NET pev,
           apps.pa_proj_elements@GSIPRD01.NA.ODCORP.NET ppe,
           apps.pa_proj_elem_ver_schedule@gsiprd01.na.odcorp.net ppevs,
           apps.pa_tasks pat1,
           apps.pa_proj_element_versions pev1,
           apps.pa_proj_elem_ver_schedule ppevs1,
           apps.pa_proj_elements ppe1,
           apps.per_all_people_f ppf,
           apps.per_all_people_f@GSIPRD01.NA.ODCORP.NET ppf1,
           apps.pa_percent_completes@GSIPRD01.NA.ODCORP.NET ppc,
           apps.pa_progress_rollup@GSIPRD01.NA.ODCORP.NET ppr
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
       and pat1.project_id = p_cur_project_id
       and pat1.task_id = pev1.proj_element_id
       and pev1.proj_element_id = ppe1.proj_element_id
       and pev1.object_type = 'PA_TASKS'
       and pat1.task_number = pat.task_number 
       and pev1.proj_element_id = ppevs1.proj_element_id
       and pev1.project_id      = ppevs1.project_id
       and ppe.proj_element_id = ppc.task_id
       and ppc.project_id = pev.project_id
       and ppc.object_id = pev.proj_element_id
       and ppc.object_version_id = pev.element_version_id
       and ppc.object_type = 'PA_TASKS'
       and ppr.project_id = ppc.project_id
       and ppr.object_id = ppc.object_id
       and ppr.object_version_id = ppc.object_version_id
       and ppr.proj_element_id = ppe.proj_element_id
       AND ppr.structure_type = 'WORKPLAN'
       and ppc.date_computed = ppr.as_of_date
       AND ppr.structure_version_id is null
       AND not exists (select 'x' 
                         from apps.pa_percent_completes ppc1
                        where ppc1.project_id = pat1.project_id
                          and ppc1.task_id = pat1.task_id
                          and ppc1.object_version_id = ppevs1.element_version_id)
UNION ALL
  SELECT  pat1.project_id,pat1.task_id,ppe1.proj_element_id,ppevs1.element_version_id,pat1.task_number,
           pat1.task_name,ppe1.name,pev.display_sequence,ppe.status_code old_status_code,
           ppe1.status_code new_status_code,
           ppf.full_name,ppf.employee_number,
           ppf.person_id,ppe.closed_date,
           ppe.baseline_start_date,ppe.baseline_finish_date,ppe.baseline_duration,
           pat.start_date,pat.completion_date,
           ppevs.actual_start_date,ppevs.actual_finish_date,
           ppevs.duration,
           ppevs.actual_duration,ppevs.estimated_duration,
           ppevs.early_start_date,ppevs.early_finish_date,
           ppevs.late_start_date,ppevs.late_finish_date,
           ppevs.scheduled_start_date,ppevs.scheduled_finish_date,
           null date_computed,
           null description,
           null percent_complete_id,
           ppr.object_id old_object_id,
           ppr.object_version_id old_object_version_id,
           ppr.object_type,
           null status_code,
           ppr.progress_status_code,
           null estimated_start_date,
           null estimated_finish_date,
           null published_flag,
           null published_by_party_id,
           null progress_comment,
           null history_flag,
           null structure_type,
           ppr.progress_rollup_id,
           ppr.as_of_date,
           ppr.base_percent_complete,
           ppr.eff_rollup_percent_comp,
           ppr.completed_percentage,
           ppr.estimated_remaining_effort,
           ppr.record_version_number,
           ppr.base_progress_status_code,
           ppr.eff_rollup_prog_stat_code,
           ppr.task_wt_basis_code,
           ppr.current_flag,
           ppr.prog_gl_period_name           
      FROM apps.pa_tasks@GSIPRD01.NA.ODCORP.NET pat,
           apps.pa_proj_element_versions@GSIPRD01.NA.ODCORP.NET pev,
           apps.pa_proj_elements@GSIPRD01.NA.ODCORP.NET ppe,
           apps.pa_proj_elem_ver_schedule@gsiprd01.na.odcorp.net ppevs,
           apps.pa_tasks pat1,
           apps.pa_proj_element_versions pev1,
           apps.pa_proj_elem_ver_schedule ppevs1,
           apps.pa_proj_elements ppe1,
           apps.per_all_people_f ppf,
           apps.per_all_people_f@GSIPRD01.NA.ODCORP.NET ppf1,
           --apps.pa_percent_completes@GSIPRD01.NA.ODCORP.NET ppc,
           apps.pa_progress_rollup@GSIPRD01.NA.ODCORP.NET ppr
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
       and pat1.project_id = p_cur_project_id
       and pat1.task_id = pev1.proj_element_id
       and pev1.proj_element_id = ppe1.proj_element_id
       and pev1.object_type = 'PA_TASKS'
       and pat1.task_number = pat.task_number 
       and pev1.proj_element_id = ppevs1.proj_element_id
       and pev1.project_id      = ppevs1.project_id
       and ppr.proj_element_id = ppe.proj_element_id
       AND ppr.structure_type = 'WORKPLAN'
       AND ppr.structure_version_id is null
       and ppr.percent_complete_id is null
       and ppr.current_flag = 'Y'
       AND not exists (select 'x' 
                         from apps.pa_progress_rollup ppc1
                        where ppc1.project_id = pat1.project_id
                          and ppc1.object_id = pat1.task_id
                          and ppc1.object_version_id = ppevs1.element_version_id) ;
                          
                          
       CURSOR cur_proj_ext IS
       SELECT ppa.segment1,ppa.project_id,eag.attr_group_id,
           eag.attr_group_type,eag.attr_group_name,eag.attr_group_disp_name,
           ppe.extension_id
      FROM apps.pa_projects_all ppa,
           apps.pa_projects_erp_ext_b ppe,
           apps.ego_attr_groups_v eag
     WHERE ppa.project_id = ppe.project_id
       AND ppe.attr_group_id = eag.attr_group_id
       AND eag.attr_group_type = 'PA_PROJ_ATTR_GROUP_TYPE'
       AND eag.application_id = 275
       AND eag.attr_group_name = 'QA'
       AND ppe.extension_id > 100000;

Begin
--------
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

                                      DBMS_OUTPUT.put_line('User and Responsibility:'||l_error_data||':'||sqlerrm);
                                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Users and Responsibility Error:'||l_error_data);
                                 END LOOP;
                            END IF;
                END;




-------
    
    FOR pa_proj_rec IN cur_proj_info LOOP
    
        FOR pa_task_rec IN cur_task_info (pa_proj_rec.cur_project_id,pa_proj_rec.old_project_id)
        LOOP
        
         update pa_proj_elements
            set element_number = pa_task_rec.old_element_name,
                name           = pa_task_rec.old_element_name,
                description    = pa_task_rec.old_element_name
          where proj_element_id = pa_task_rec.task_id 
            and project_id = pa_proj_rec.cur_project_id;   
            
         update pa_tasks
            set task_name = pa_task_rec.old_task_name,
                long_task_name = pa_task_rec.old_task_name
          where task_id = pa_task_rec.task_id 
            and project_id = pa_proj_rec.cur_project_id;
            
        END LOOP;
        
        
        -------------
        FOR pa_prog_rec IN cur_task_prog (pa_proj_rec.cur_project_id,pa_proj_rec.old_project_id)
        LOOP
        
              if pa_prog_rec.progress_status_code is null
              then
                  l_progress_status_code := pa_prog_rec.eff_rollup_prog_stat_code ;
              else
                 l_progress_status_code := pa_prog_rec.progress_status_code ;
              end if ;
        
            APPS.PA_PROGRESS_PUB.UPDATE_TASK_PROGRESS(
              p_api_version                   => l_api_version_num        
             ,p_init_msg_list                 => l_init_msg_list            
             ,p_commit                        => l_commit            
             ,p_validate_only                 => FND_API.G_TRUE            
             ,p_validation_level              => FND_API.G_VALID_LEVEL_FULL 
             ,p_calling_module                => 'SELF_SERVICE'             
             ,p_calling_mode                  => null                    
             ,p_debug_mode                    => 'N'                     
             ,p_max_msg_count                 => PA_INTERFACE_UTILS_PUB.G_PA_MISS_NUM 
             ,p_action                        => 'PUBLISH'  --'SAVE'                          ,
             ,p_bulk_load_flag                => 'Y' --'N'                             ,
             ,p_progress_mode                 => 'FUTURE'              
             ,p_percent_complete_id           => null  --p_percent_complete_id
             ,p_project_id                    => pa_prog_rec.project_id
             ,p_object_id                     => pa_prog_rec.proj_element_id
             ,p_object_version_id             => pa_prog_rec.element_version_id
             ,p_object_type                   => pa_prog_rec.object_type
             ,p_as_of_date                    => trunc(sysdate)  --pa_prog_rec.as_of_date
             ,p_percent_complete              => pa_prog_rec.completed_percentage
             ,p_progress_status_code          => l_progress_status_code  --pa_prog_rec.progress_status_code
             ,p_progress_comment              => 'History As of Date '||pa_prog_rec.as_of_date||'  -  '||pa_prog_rec.progress_comment
             ,p_brief_overview                => pa_prog_rec.description
             ,p_actual_start_date             => pa_prog_rec.actual_start_date
             ,p_actual_finish_date            => pa_prog_rec.actual_finish_date
             ,p_estimated_start_date          => pa_prog_rec.estimated_start_date
             ,p_estimated_finish_date         => pa_prog_rec.estimated_finish_date
             ,p_scheduled_start_date          => pa_prog_rec.scheduled_start_date
             ,p_scheduled_finish_date         => pa_prog_rec.scheduled_finish_date
             ,p_record_version_number         => pa_prog_rec.record_version_number
             ,p_task_status                   => pa_prog_rec.old_status_code
             ,p_est_remaining_effort          => pa_prog_rec.estimated_remaining_effort
             --,p_actual_work_quantity          => null  --pa_prog_rec.actual_work_quantity
             --,p_pm_product_code               => 'WORKPLAN'  --p_pm_product_code
             ,p_structure_type                => 'WORKPLAN'               
             --,p_actual_effort                 => null  --pa_prog_rec.actual_effort
             --,p_actual_effort_this_period     => null   --pa_prog_rec.actual_effort_this_period
             ,p_prog_fom_wp_flag              => 'N'                            
             --,p_planned_cost                  => null  --pa_prog_rec.planned_cost
             --,p_planned_effort                => null   --pa_prog_rec.planned_effort
             --,p_structure_version_id          => pa_prog_rec.structure_version_id
             ,p_eff_rollup_percent_complete   => pa_prog_rec.eff_rollup_percent_comp
             ,x_resource_list_member_id       => l_resource_list_member_id
             ,x_return_status                 => l_return_status
             ,x_msg_count                     => l_msg_count
             ,x_msg_data                      => l_msg_data)            ;

           --DBMS_OUTPUT.put_line('Task Update API Error:'||l_error_data||':'||sqlerrm);
           --DBMS_OUTPUT.put_line('Task Update API member id :'||l_resource_list_member_id||':'||sqlerrm);
           --DBMS_OUTPUT.put_line('Task Update API return status :'||l_return_status||':'||sqlerrm);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Task Update API Return Status for Task:'||pa_prog_rec.proj_element_id||':'||l_return_status);
           
--           
--           begin
--           
--                update apps.pa_progress_rollup
--                   set as_of_date = pa_prog_rec.as_of_date
--                 where project_id = pa_prog_rec.project_id
--                   and object_id = pa_prog_rec.proj_element_id
--                   and object_version_id = pa_prog_rec.element_version_id ;
--           
--           end ;

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
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'Create Project API Error:'||l_error_data||':'||sqlerrm);
                         END LOOP;
                    END IF;

        END LOOP;
---------------        
  
        
        
        
        FOR pa_elem_rec IN cur_elem_info (pa_proj_rec.cur_project_id)
        LOOP
        
            update apps.pa_proj_elem_ver_schedule
               set scheduled_start_date = pa_proj_rec.scheduled_start_date,
                   scheduled_finish_date = pa_proj_rec.scheduled_finish_date
             where pev_schedule_id = pa_elem_rec.pev_schedule_id
               and element_version_id = pa_elem_rec.element_version_id
               and proj_element_id = pa_elem_rec.proj_element_id
               and project_id = pa_elem_rec.project_id ;
        
        END LOOP;
    commit;
    
    END LOOP;
    
    FOR pa_proj_ext_rec IN cur_proj_ext
    LOOP
    
        delete from apps.pa_projects_erp_ext_b
              where extension_id = pa_proj_ext_rec.extension_id ;
              
         delete from apps.pa_projects_erp_ext_tl
              where extension_id = pa_proj_ext_rec.extension_id ;
              
    
    END LOOP;

commit;

exception 
when others then

--DBMS_OUTPUT.put_line('Create Project API Other Error:'||sqlerrm);
FND_FILE.PUT_LINE(FND_FILE.LOG,'Create Project API Other Error:'||sqlerrm);

END Process_main;

End XX_PA_PROJ_TASK_PROG_UPD_PKG;
/
SHOW ERRORS;

EXIT ;