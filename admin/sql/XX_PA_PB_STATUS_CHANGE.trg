-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_PB_STATUS_CHANGE                             |
-- | Description :  OD PB PA Status Change Notification                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       28-Sep-2009 Paddy Sanjeevi     Initial version           |
-- |1.1       19-Jan-2010 Paddy Sanjeevi     Added Approved Notification|
-- |1.2       08-Apr-2010 Paddy Sanjeevi     Trigged for only PB projects|
-- |1.3       21-Apr-2010 Paddy Sanjeevi     Added Project Number      |
--|1.4        18-Oct-2010 Rama Dwibhashyam   Added the Supervisor Logic|
-- +===================================================================+
CREATE OR REPLACE TRIGGER APPS.XX_PA_PB_STATUS_CHANGE
AFTER INSERT
ON pa_obj_status_changes
FOR EACH ROW
WHEN (
new.object_type='PA_PROJECTS' and new.status_type='PROJECT'
      )
DECLARE
v_status varchar2(80);
v_email_list    VARCHAR2(2000);
v_text        VARCHAR2(2000);
v_subject    VARCHAR2(3000);
v_name          VARCHAR2(30);
v_adhoc_email_list    VARCHAR2(2000);
v_segment1    VARCHAR2(25);
v_cc_email_list varchar2(2000);

CURSOR C3 IS
SELECT  distinct c.email_address
  FROM  apps.per_all_people_f c
       ,apps.pa_proj_elements a
       ,apps.pa_tasks b
 WHERE b.project_id=:new.object_id
   AND b.attribute10 IS NOT NULL
   AND a.project_id=b.project_id
   AND a.proj_element_id=b.task_id
   AND trunc(sysdate) between c.effective_start_date and c.effective_end_date
   AND c.person_id=a.manager_person_id;
   
   
CURSOR C2 IS
SELECT fu1.email_address||':'||fu2.email_address email_address
  FROM apps.fnd_user fu1,
       apps.fnd_user fu2,
       apps.fnd_flex_values_vl fvl,
       apps.fnd_flex_value_sets fv,
       apps.pa_projects_all ppa,
       apps.pa_project_parties_v ppp,
       apps.pa_project_role_types_vl ppr
 WHERE fv.flex_value_set_name= 'XX_PA_PB_SUPERVISOR_INFO'
   AND fvl.flex_value_set_id= fv.flex_value_set_id
   AND fu1.user_name= fvl.attribute1                        
   AND fu2.user_name= fvl.attribute2
   AND ppa.project_id=:new.object_id
   AND ppa.project_id= ppp.project_id
   AND ppp.project_role_id= ppr.project_role_id
   AND ppr.project_role_type= 'PROJECT MANAGER'
   AND ppp.user_name = fvl.flex_value ;   
   
CURSOR C1 IS
SELECT DISTINCT per.email_address
  FROM apps.per_all_people_f per,
       apps.fnd_flex_values_vl fvl
      ,apps.fnd_flex_value_sets fv
 WHERE fv.flex_value_set_name='OD_PA_PROJ_STATUS_EMAIL_LIST'
   AND fvl.flex_value_set_id=fv.flex_value_set_id
   AND per.person_id=TO_NUMBER(fvl.attribute1)
   AND fvl.enabled_flag='Y';
BEGIN
  BEGIN
    SELECT segment1,name
      INTO v_segment1,v_name
      FROM apps.pa_projects_all
     WHERE project_id=:new.object_id;
  EXCEPTION
    WHEN others THEN
     v_segment1:='NOTEXISTS';
       v_name:=NULL;
  END;
  IF v_segment1 LIKE 'PB%' THEN
     BEGIN
       SELECT project_status_name
         INTO v_status
         FROM pa_project_statuses
        WHERE status_type='PROJECT' AND project_status_code=:NEW.new_project_status_code;
     EXCEPTION
       WHEN others THEN
         v_status:=NULL;
     END;
     FOR cur IN C3 LOOP
       IF v_email_list IS NOT NULL THEN
          v_email_list:=v_email_list||':';
       END IF;
       v_email_list:=v_email_list||cur.email_address;
     END LOOP;
     
     FOR cur2 IN C2 LOOP
       IF v_email_list IS NOT NULL THEN
          v_email_list:=v_email_list||':';
       END IF;
       v_email_list:=v_email_list||cur2.email_address;
     END LOOP;
     
     v_subject:='Project Status Change notification : '||v_segment1||'/'||v_name||' is '||v_status;
     v_text:= 'Project '||v_segment1||'/'||v_name||' is '||v_status;
     xx_pa_task_mgr_alloc_pkg.send_notification(v_subject,v_email_list,v_cc_email_list,v_text);
     IF v_status IN ('Rejected','Approved') THEN
        FOR cur1 IN C1 LOOP
          IF v_adhoc_email_list IS NOT NULL THEN
             v_adhoc_email_list:=v_adhoc_email_list||':';
          END IF;
          v_adhoc_email_list:=v_adhoc_email_list||cur1.email_address;
        END LOOP;
        xx_pa_task_mgr_alloc_pkg.send_notification(v_subject,v_adhoc_email_list,v_cc_email_list,v_text);
     END IF;
  END IF;
EXCEPTION
 WHEN others THEN
 raise ;  
END;
/
