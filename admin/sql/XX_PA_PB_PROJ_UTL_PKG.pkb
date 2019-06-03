CREATE OR REPLACE PACKAGE BODY APPS.XX_PA_PB_PROJ_UTL_PKG 
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PA_PB_PROJ_UTL_PKG.pks                                     |
-- | Description      : Package spec for CR853 PLM Enhancement Utility Package               |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========       =============    ========================                    |
-- |1.0        13-Sep-2010      Rama Dwibhashyam  Initial draft version                      |
-- +=========================================================================================+

AS

PROCEDURE proj_task_status_update(p_vendor_id varchar2
                      ,p_vendor_name varchar2
                      ,p_factory_id varchar2
                      ,p_factory_name varchar2
                      ,p_task_type varchar2
                      )
IS                           

p_project_number varchar2(100) := 'PB_D13_002' ;
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
l_task_status_code              VARCHAR2(100);
        
    CURSOR cur_proj_info IS
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
       AND eag.attr_group_name = 'PB_VENDOR_INFO'
       AND (ppe.c_ext_attr5 = p_vendor_id or ppe.c_ext_attr6 = p_vendor_name)
       AND (ppe.c_ext_attr7 = p_factory_id or ppe.c_ext_attr8 = p_factory_name) ;
       
       
    CURSOR cur_task_prog (p_project_id number,p_task_type varchar2)IS
    SELECT pat1.project_id,pat1.task_id,ppe1.proj_element_id,ppevs1.element_version_id,pat1.task_number,
           pat1.task_name,ppe1.name,pev1.display_sequence,ppe1.status_code old_status_code,
           ppe1.status_code new_status_code,
           ppf.full_name,ppf.employee_number,
           ppf.person_id,ppe1.closed_date,
           ppe1.baseline_start_date,ppe1.baseline_finish_date,ppe1.baseline_duration,
           pat1.start_date,pat1.completion_date,
           ppevs1.actual_start_date,ppevs1.actual_finish_date,
           ppevs1.duration,
           ppevs1.actual_duration,ppevs1.estimated_duration,
           ppevs1.early_start_date,ppevs1.early_finish_date,
           ppevs1.late_start_date,ppevs1.late_finish_date,
           ppevs1.scheduled_start_date,ppevs1.scheduled_finish_date
      FROM apps.pa_tasks pat1,
           apps.pa_proj_element_versions pev1,
           apps.pa_proj_elem_ver_schedule ppevs1,
           apps.pa_proj_elements ppe1,
           apps.per_all_people_f ppf
     WHERE 1=1
       and trunc(sysdate) between ppf.effective_start_date and ppf.effective_end_date
       and pat1.project_id = p_project_id
       and pat1.task_id = pev1.proj_element_id
       and pev1.proj_element_id = ppe1.proj_element_id
       and pev1.object_type = 'PA_TASKS'
       and pev1.proj_element_id = ppevs1.proj_element_id
       and pev1.project_id      = ppevs1.project_id
       and ppe1.manager_person_id = ppf.person_id
       and pev1.wbs_number = decode(p_task_type,'PRE AUDIT','5.1','FQA','5.2','VENDOR SETUP',
                                '5.3','FINAL AUDIT','5.4','CAP','5.5')
       AND not exists (select 'x' 
                         from apps.pa_percent_completes ppc1
                        where ppc1.project_id = pat1.project_id
                          and ppc1.task_id = pat1.task_id
                          and ppc1.object_version_id = ppevs1.element_version_id);       
                          
                          
       CURSOR sc_ven_info (p_vendor_name varchar2, p_factory_name varchar2,p_extension_id number) IS
       select character1 vendor_number
             ,character2 vendor_name
             ,character4 vendor_status
             ,character44 audit_request  --- Audit Request 
             ,character58 pre_audit_status
             ,character69 str_audit_results
             ,to_date(character68,'YYYY/MM/DD') next_required_audit_date
             ,character78 final_social_audit_passed   --STR_CAP_Approved_by_US
             ,character9 FQA_approval_date
         from QA_RESULTS_V 
        where name = 'OD_PB_SC_VENDOR_MASTER'
          and character2 = p_vendor_name
          and character17 = p_factory_name;                          
       


Begin
--------
              -- User Login  Info
--                BEGIN

--                   FND_FILE.PUT_LINE(FND_FILE.LOG,'USER ID:'||g_user_id||'RESP ID:'||
--                   g_resp_id||'RESP APPL ID:'||g_resp_appl_id||'PROFILE ORG ID:'||g_profile_org_id);
--                   DBMS_OUTPUT.put_line('USER ID:'||l_user_id||'RESP ID:'||
--                   g_resp_id||'RESP APPL ID:'||g_resp_appl_id||'PROFILE ORG ID:'||g_profile_org_id);

--                    FND_GLOBAL.apps_initialize
--                             (
--                              user_id        => g_user_id,  --29446,  
--                              resp_id        => g_resp_id,  --50339,  
--                              resp_appl_id   => g_resp_appl_id --275  
--                             );

--                    PA_INTERFACE_UTILS_PUB.set_global_info
--                            (
--                             p_api_version_number    => 1.0,
--                             p_responsibility_id     => g_resp_id,  --50339,  
--                             p_user_id               => g_user_id,  --29446,  
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

--                                      DBMS_OUTPUT.put_line('User and Responsibility:'||l_error_data||':'||sqlerrm);
--                                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Users and Responsibility Error:'||l_error_data);
--                                 END LOOP;
--                            END IF;
--                END;




-------
    
    FOR pa_proj_rec IN cur_proj_info LOOP
    
        
        -----------
        FOR pa_prog_rec IN cur_task_prog (pa_proj_rec.project_id,p_task_type)
        LOOP
        
            select project_status_code
              into l_task_status_code
              from pa_project_statuses
             where status_type = 'TASK'
               and project_status_name = 'Completed' ;
        
              --if pa_prog_rec.progress_status_code is null
              --then
                  l_progress_status_code := 'PROGRESS_STAT_ON_TRACK' ; --pa_prog_rec.eff_rollup_prog_stat_code ;
              --else
                -- l_progress_status_code := pa_prog_rec.progress_status_code ;
             -- end if ;
        
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
             ,p_object_type                   => 'PA_TASKS'  --pa_prog_rec.object_type
             ,p_as_of_date                    => trunc(sysdate)  --pa_prog_rec.as_of_date
             ,p_percent_complete              => 100   --pa_prog_rec.completed_percentage
             ,p_progress_status_code          => l_progress_status_code  --pa_prog_rec.progress_status_code
             ,p_progress_comment              => 'Task Status update based on the Vendor Master Collection Plan'
             ,p_brief_overview                => 'Task Status Update by Social Compliance Team'
             ,p_actual_start_date             => pa_prog_rec.actual_start_date
             ,p_actual_finish_date            => pa_prog_rec.actual_finish_date
             --,p_estimated_start_date          => pa_prog_rec.estimated_start_date
             --,p_estimated_finish_date         => pa_prog_rec.estimated_finish_date
             ,p_scheduled_start_date          => pa_prog_rec.scheduled_start_date
             ,p_scheduled_finish_date         => pa_prog_rec.scheduled_finish_date
             ,p_record_version_number         => 1   --pa_prog_rec.record_version_number
             ,p_task_status                   => l_task_status_code
             --,p_est_remaining_effort          => pa_prog_rec.estimated_remaining_effort
             --,p_actual_work_quantity          => null  --pa_prog_rec.actual_work_quantity
             --,p_pm_product_code               => 'WORKPLAN'  --p_pm_product_code
             ,p_structure_type                => 'WORKPLAN'               
             --,p_actual_effort                 => null  --pa_prog_rec.actual_effort
             --,p_actual_effort_this_period     => null   --pa_prog_rec.actual_effort_this_period
             ,p_prog_fom_wp_flag              => 'N'                            
             --,p_planned_cost                  => null  --pa_prog_rec.planned_cost
             --,p_planned_effort                => null   --pa_prog_rec.planned_effort
             --,p_structure_version_id          => pa_prog_rec.structure_version_id
             --,p_eff_rollup_percent_complete   => pa_prog_rec.eff_rollup_percent_comp
             ,x_resource_list_member_id       => l_resource_list_member_id
             ,x_return_status                 => l_return_status
             ,x_msg_count                     => l_msg_count
             ,x_msg_data                      => l_msg_data)            ;

           --DBMS_OUTPUT.put_line('Task Update API Error:'||l_error_data||':'||sqlerrm);
           --DBMS_OUTPUT.put_line('Task Update API member id :'||l_resource_list_member_id||':'||sqlerrm);
           --DBMS_OUTPUT.put_line('Task Update API return status :'||l_return_status||':'||sqlerrm);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Task Update API Return Status for Task:'||pa_prog_rec.proj_element_id||':'||l_return_status);


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
----------

     IF p_task_type = 'CAP' 
     THEN
             
       FOR ven_rec IN sc_ven_info (p_vendor_name, p_factory_name,pa_proj_rec.extension_id) LOOP
     
        update apps.pa_projects_erp_ext_b
           set c_ext_attr21 = ven_rec.vendor_status  --'Vendor Status'
              ,c_ext_attr22 = ven_rec.audit_request   --'Audit Request'
              ,c_ext_attr23 = ven_rec.pre_audit_status  --'Pre-Social Audit Passed'
              --,c_ext_attr24 = 'Final Social Audit Type'
              ,c_ext_attr25 = ven_rec.str_audit_results   --'Last Audit Results'
              ,d_ext_attr1 =  ven_rec.next_required_audit_date  --sysdate  --'Next Audit Date'
              ,c_ext_attr27 = ven_rec.final_social_audit_passed   --'Final Social Audit Passed'
              ,c_ext_attr28 = ven_rec.fqa_approval_date   --'FQA'
              --,c_ext_attr29 = 'Re-Audit Process Requirement Days'
         where extension_id = pa_proj_rec.extension_id ;
         
         update apps.pa_projects_erp_ext_tl
           set tl_ext_attr21 = ven_rec.vendor_status  --'Vendor Status'
              ,tl_ext_attr22 = ven_rec.audit_request   --'Audit Request'
              ,tl_ext_attr23 = ven_rec.pre_audit_status  --'Pre-Social Audit Passed'
              --,c_ext_attr24 = 'Final Social Audit Type'
              ,tl_ext_attr25 = ven_rec.str_audit_results   --'Last Audit Results'
              --,d_ext_attr1 =  ven_rec.next_required_audit_date  --sysdate  --'Next Audit Date'
              ,tl_ext_attr27 = ven_rec.final_social_audit_passed   --'Final Social Audit Passed'
              ,tl_ext_attr28 = ven_rec.fqa_approval_date   --'FQA'
              --,c_ext_attr29 = 'Re-Audit Process Requirement Days'
         where extension_id = pa_proj_rec.extension_id ;
         
         commit;

      END LOOP;
        
     END IF;   
    
    END LOOP;


commit;

exception 
when others then

--DBMS_OUTPUT.put_line('Create Project API Other Error:'||sqlerrm);
FND_FILE.PUT_LINE(FND_FILE.LOG,'Create Project API Other Error:'||sqlerrm);

END proj_task_status_update;


   

PROCEDURE get_vendor_info(projectId IN NUMBER
                         ,x_error_msg OUT USER_FUNC_ERROR_ARRAY
                           ) 
IS


       CURSOR proj_ven_info IS
       SELECT ppa.segment1,ppa.project_id,eag.attr_group_id,
           eag.attr_group_type,eag.attr_group_name,eag.attr_group_disp_name,
           ppe.extension_id,
           ppe.c_ext_attr5 vendor_num,
           ppe.c_ext_attr6 vendor_name,
           ppe.c_ext_attr7 factory_num,
           ppe.c_ext_attr8 factory_name
      FROM apps.pa_projects_all ppa,
           apps.pa_projects_erp_ext_b ppe,
           apps.ego_attr_groups_v eag
     WHERE ppa.project_id = ppe.project_id
       AND ppe.attr_group_id = eag.attr_group_id
       AND eag.attr_group_type = 'PA_PROJ_ATTR_GROUP_TYPE'
       AND eag.application_id = 275
       AND eag.attr_group_name = 'PB_VENDOR_INFO'
       AND ppa.project_id = projectId ;
       
       --AND (ppe.c_ext_attr5 = p_vendor_id OR ppe.c_ext_attr6 = p_vendor_name)
       --AND (ppe.c_ext_attr7 = p_factory_id OR ppe.c_ext_attr8 = p_factory_name) ;
       
       CURSOR sc_ven_info (p_vendor_name varchar2, p_factory_name varchar2) IS
       select character1 vendor_number
             ,character2 vendor_name
             ,character4 vendor_status
             ,character10 sourcing_agent
             ,character11 vendor_contact_name
             ,character12 vendor_phone
             ,character13 vendor_fax
             ,character14 vendor_email
             ,character15 vendor_address
             ,character16 factory_number
             ,character17 factory_name
             ,character18 factory_contact_name
             ,character19 factory_email
             ,character20 factory_address
             ,character21 factory_phone
             ,character22 factory_fax
             ,character44 audit_request  --- Audit Request 
             ,character58 pre_audit_status
             ,character69 str_audit_results
             ,to_date(character68,'YYYY/MM/DD') next_required_audit_date
             ,character78 final_social_audit_passed   --STR_CAP_Approved_by_US
             ,character9 FQA_approval_date
             ,character50 country_of_origin
             ,character48 region
         from QA_RESULTS_V 
        where name = 'OD_PB_SC_VENDOR_MASTER'
          and character2 = p_vendor_name
          and character17 = p_factory_name;
       
  l_project_id number ;

BEGIN

    l_project_id := projectId ;
    
    
    FOR ven_info_rec IN proj_ven_info LOOP
    
    
     FOR ven_rec IN sc_ven_info (ven_info_rec.vendor_name, ven_info_rec.factory_name) LOOP
     
        update apps.pa_projects_erp_ext_b
           set c_ext_attr2 = ven_rec.country_of_origin  --'Country of Origin'
              ,c_ext_attr3 = ven_rec.sourcing_agent  --'Sourcing Agent'
              ,c_ext_attr4 = ven_rec.region  --'Region'
              ,c_ext_attr5 = ven_rec.vendor_number  --'vendor number'
              ,c_ext_attr7 = ven_rec.factory_number  --'factory number'
              ,c_ext_attr9 = ven_rec.vendor_address  --'Vendor Address'
              ,c_ext_attr10 = ven_rec.factory_address  --'Factory Address'
              --,c_ext_attr11 = 'Vendor City State'
              --,c_ext_attr12 = 'Factory City State'
              --,c_ext_attr13 = 'Vendor Country'
              --,c_ext_attr14 = 'Factory Country'
              ,c_ext_attr15 = ven_rec.vendor_contact_name  --'Vendor Contact'
              ,c_ext_attr16 = ven_rec.factory_contact_name  --'Factory Contact'
              ,c_ext_attr17 = ven_rec.vendor_email  --'Vendor Email'
              ,c_ext_attr18 = ven_rec.factory_email  --'Factory Email'
              ,c_ext_attr19 = ven_rec.vendor_phone  --'Vendor Phone'
              ,c_ext_attr20 = ven_rec.factory_phone  --'Factory Phone'
              ,c_ext_attr21 = ven_rec.vendor_status  --'Vendor Status'
              ,c_ext_attr22 = ven_rec.audit_request   --'Audit Request'
              ,c_ext_attr23 = ven_rec.pre_audit_status  --'Pre-Social Audit Passed'
              --,c_ext_attr24 = 'Final Social Audit Type'
              ,c_ext_attr25 = ven_rec.str_audit_results   --'Last Audit Results'
              ,d_ext_attr1 =  ven_rec.next_required_audit_date  --sysdate  --'Next Audit Date'
              ,c_ext_attr27 = ven_rec.final_social_audit_passed   --'Final Social Audit Passed'
              ,c_ext_attr28 = ven_rec.fqa_approval_date   --'FQA'
              --,c_ext_attr29 = 'Re-Audit Process Requirement Days'
         where extension_id = ven_info_rec.extension_id ;
         
         update apps.pa_projects_erp_ext_tl
           set tl_ext_attr2 = ven_rec.country_of_origin  --'Country of Origin'
              ,tl_ext_attr3 = ven_rec.sourcing_agent  --'Sourcing Agent'
              ,tl_ext_attr4 = ven_rec.region  --'Region'
              ,tl_ext_attr5 = ven_rec.vendor_number  --'vendor number'
              ,tl_ext_attr7 = ven_rec.factory_number  --'factory number'
              ,tl_ext_attr9 = ven_rec.vendor_address  --'Vendor Address'
              ,tl_ext_attr10 = ven_rec.factory_address  --'Factory Address'
              --,tl_ext_attr11 = 'Vendor City State'
              --,tl_ext_attr12 = 'Factory City State'
              --,tl_ext_attr13 = 'Vendor Country'
              --,tl_ext_attr14 = 'Factory Country'
              ,tl_ext_attr15 = ven_rec.vendor_contact_name  --'Vendor Contact'
              ,tl_ext_attr16 = ven_rec.factory_contact_name  --'Factory Contact'
              ,tl_ext_attr17 = ven_rec.vendor_email  --'Vendor Email'
              ,tl_ext_attr18 = ven_rec.factory_email  --'Factory Email'
              ,tl_ext_attr19 = ven_rec.vendor_phone  --'Vendor Phone'
              ,tl_ext_attr20 = ven_rec.factory_phone  --'Factory Phone'
              ,tl_ext_attr21 = ven_rec.vendor_status  --'Vendor Status'
              ,tl_ext_attr22 = ven_rec.audit_request   --'Audit Request'
              ,tl_ext_attr23 = ven_rec.pre_audit_status  --'Pre-Social Audit Passed'
              --,c_ext_attr24 = 'Final Social Audit Type'
              ,tl_ext_attr25 = ven_rec.str_audit_results   --'Last Audit Results'
              --,d_ext_attr1 =  ven_rec.next_required_audit_date  --sysdate  --'Next Audit Date'
              ,tl_ext_attr27 = ven_rec.final_social_audit_passed   --'Final Social Audit Passed'
              ,tl_ext_attr28 = ven_rec.fqa_approval_date   --'FQA'
              --,c_ext_attr29 = 'Re-Audit Process Requirement Days'
         where extension_id = ven_info_rec.extension_id ;
        
         commit;

      END LOOP;
      
    END LOOP;
    
--    x_error_msg := USER_FUNC_ERROR_ARRAY('Success in getting vendor info project'||projectId) ;
    
 commit;        

exception 
when others then
   x_error_msg := USER_FUNC_ERROR_ARRAY('Error in getting the vendor Info'||sqlerrm) ;
--DBMS_OUTPUT.put_line('Create Project API Other Error:'||sqlerrm);
FND_FILE.PUT_LINE(FND_FILE.LOG,'Get Vendor Info Other Error:'||sqlerrm);

END get_vendor_info ;                         
                           
                            

End XX_PA_PB_PROJ_UTL_PKG;
/