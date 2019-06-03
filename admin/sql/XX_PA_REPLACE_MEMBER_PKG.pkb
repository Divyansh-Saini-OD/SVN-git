CREATE OR REPLACE PACKAGE BODY XX_PA_REPLACE_MEMBER_PKG IS
/**********************************************************************************
 Program Name: XX_PA_REPLACE_MEMBER_PKG
 Purpose:      To Replace the Team members in  Oracle Projects.

 REVISIONS:
-- Version Date        Author                               Description
-- ------- ----------- ----------------------               ---------------------
-- 1.0     15-NOV-2007 Siva Boya, Clearpath.         Created base version.
--
**********************************************************************************/
PROCEDURE XXOD_REPLACE_MEMBER ( retcode        OUT VARCHAR2,
                             errbuf OUT VARCHAR2,
                             p_replace_name IN VARCHAR2 ,
                             p_replace_with IN VARCHAR2,
                             p_department IN VARCHAR2                           
                             ) IS
    
    l_new_person_id                 NUMBER;
    l_old_person_id                 NUMBER;
    l_role_type                     pa_project_players.PROJECT_ROLE_TYPE%TYPE;
    l_role_meaning                  PA_PROJECT_ROLE_TYPES_TL.MEANING%TYPE;
    l_user_name                     fnd_user.user_name%TYPE;
    l_resp_name                     pa_user_resp_v.responsibility_name%TYPE;
    l_user_id                       NUMBER; 
    l_resp_id                       NUMBER; 
    l_resp_appl_id                  NUMBER; 
    l_profile_org_id                NUMBER;
    l_task_manager_id               NUMBER;
    l_new_party_id                  NUMBER;

CURSOR proj IS 

SELECT DISTINCT pa.project_id, pa.segment1, pa.NAME,
                pp.resource_source_id person_id, pf.full_name,
                pa.carrying_out_organization_id, pa.pm_project_reference,
                pa.pm_product_code, pa.project_status_code,
                pa.public_sector_flag,pf.PARTY_ID
           FROM pa_projects_all pa,
                pa_project_statuses ps,
                pa_project_parties pp,
                per_all_people_f pf,
                pa_projects_erp_ext_b eeb1,
                ego_fnd_dsc_flx_ctx_ext fnd1
          WHERE pa.project_id = pp.project_id
            AND pp.resource_source_id = pf.person_id
            AND pa.project_id = eeb1.project_id
            AND eeb1.attr_group_id = fnd1.attr_group_id
            AND fnd1.descriptive_flex_context_code = 'PB_GEN_INFO'
            AND pa.project_status_code = ps.project_status_code
            AND ps.project_status_name !='Completed'
            AND eeb1.c_ext_attr1 =p_department--'24 OFFICE ACCESSORIES' -- Department
            AND pf.full_name =p_replace_name 
       ORDER BY pa.project_id;  
    
    BEGIN
                         
            BEGIN 
                l_new_person_id :=NULL;
               
                SELECT pf.person_id,pf.PARTY_ID
                  INTO l_new_person_id,l_new_party_id
                  FROM per_all_people_f pf
                 WHERE pf.full_name = p_replace_with; 
             EXCEPTION
                  WHEN NO_DATA_FOUND 
                  THEN
             DBMS_OUTPUT.put_line('New Person not Found:'||p_replace_with);
             FND_FILE.PUT_LINE(FND_FILE.LOG,'New Person not Found:'||p_replace_with);  
           END; 
           
           FND_FILE.PUT_LINE(FND_FILE.LOG,'REPLACE PERSON:'||p_replace_name );
           FND_FILE.PUT_LINE(FND_FILE.LOG,'REPLACE PERSON WITH:'||p_replace_with);       
    FOR proj_rec IN proj 
    LOOP
                      
           DBMS_OUTPUT.put_line('PROJECT NUMBER:'||proj_rec.segment1);    
           FND_FILE.PUT_LINE(FND_FILE.LOG,'PROJECT NUMBER:'||proj_rec.segment1); 
           
            /* Update the Project Manager/Team Members   */   
              
            BEGIN
                     UPDATE pa_project_parties
                        SET resource_source_id=l_new_person_id, 
                            last_update_date = SYSDATE,
                            last_updated_by=FND_PROFILE.value('USER_ID')
                      WHERE project_id = proj_rec.project_id
                        AND resource_source_id = proj_rec.person_id;
                         EXCEPTION
                         WHEN OTHERS THEN
             DBMS_OUTPUT.put_line('Error Updating Project Manager/Team Member,Project Number :'||proj_rec.segment1||SQLERRM);
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Updating Project Manager/Team Member,Project Number :'||proj_rec.segment1||SQLERRM);
                 
            END;
            
           BEGIN
                l_task_manager_id := NULL;
             
               SELECT DISTINCT pt.task_manager_person_id
                         INTO l_task_manager_id
                         FROM pa_tasks pt
                        WHERE pt.project_id = proj_rec.project_id
                          AND pt.task_manager_person_id = proj_rec.person_id;
                    EXCEPTION
                         WHEN NO_DATA_FOUND 
                         THEN
                  DBMS_OUTPUT.put_line('NO TASKS Found to Replace  :'||p_replace_name);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'NO TASKS Found to Replace  :'||p_replace_name);
                  l_task_manager_id :=NULL;  
                 
           END;
          
         
         IF l_task_manager_id IS NOT NULL
         THEN
          
          BEGIN 
            UPDATE pa_tasks
            set TASK_MANAGER_PERSON_ID=l_new_person_id, 
                last_update_date = SYSDATE,
                last_updated_by=FND_PROFILE.value('USER_ID')
            WHERE project_id = proj_rec.project_id
            AND TASK_MANAGER_PERSON_ID=proj_rec.person_id;
            EXCEPTION
                WHEN OTHERS THEN            
                DBMS_OUTPUT.put_line('Error Updating  Task Manager:'||SQLERRM);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Updating  Task Manager:'||SQLERRM); 
           END;
           
         END IF; 
            
            /*  Replace Deliverables  */
            BEGIN
                update pa_proj_elements
                set manager_person_id=l_new_person_id, 
                    last_update_date = SYSDATE,
                    last_updated_by=FND_PROFILE.value('USER_ID')
                where project_id=proj_rec.project_id
                and manager_person_id=proj_rec.person_id;
                EXCEPTION
                WHEN NO_DATA_FOUND 
                THEN
                  DBMS_OUTPUT.put_line('NO Deliverables Found to Replace  :'||p_replace_name);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Deliverables Found to Replace  :'||p_replace_name); 
            END;
        
            /* Replace Issue Owner */
            BEGIN
                
                UPDATE pa_control_items
                   SET owner_id = l_new_party_id
                 WHERE project_id = proj_rec.project_id AND owner_id = proj_rec.party_id;
                EXCEPTION
                         WHEN NO_DATA_FOUND 
                         THEN
                  DBMS_OUTPUT.put_line('NO ISSUES Found to Replace  :'||p_replace_name);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'NO ISSUES Found to Replace  :'||p_replace_name);
            END;
          
    
   END LOOP;
 COMMIT;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN            
    DBMS_OUTPUT.put_line('No data Found');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'No data Found');  
    WHEN OTHERS THEN
    DBMS_OUTPUT.put_line('Unhandled exception Found:'||SQLERRM);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Unhandled exception Found:'||SQLERRM);                
 END;  
      
END   XX_PA_REPLACE_MEMBER_PKG; 
/
EXIT;
