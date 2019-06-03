SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY APPS.XX_PA_TASK_MGR_ALLOC_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_TASK_MGR_ALLOC_PKG.pkb                       |
-- | Description :  OD PB PA Task Manager Allocation                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       14-Sep-2009 Paddy Sanjeevi     Initial version           |
-- |1.1       08-Apr-2010 Paddy Sanjeevi     Replace attribute9 with 1 |
-- |1.2          23-Sep-2010 Paddy Sanjeevi     Modified for GSO       |
-- |1.3       27-Sep-2010 Rama Dwibhashyam   Modified the email part   |
-- |1.4       17-Oct-2010 Rama Dwibhashyam   Mod the Resource part     |
-- |1.5       11-Feb-2011 Rama Dwibhashyam   Mod the task status check |
-- +===================================================================+
AS

------------------------------------------------------------------------------------------------
--Declaring xx_pa_task_mgr_alloc
------------------------------------------------------------------------------------------------

PROCEDURE SEND_NOTIFICATION( p_subject IN VARCHAR2
                ,p_email_list IN VARCHAR2
                ,p_cc_email_list IN VARCHAR2
                ,p_text IN VARCHAR2 )
IS
  lc_mailhost    VARCHAR2(64) := FND_PROFILE.VALUE('XX_PA_PB_MAIL_HOST');
  lc_database    VARCHAR2(64) := FND_PROFILE.VALUE('APPS_DATABASE_ID');
  lc_from        VARCHAR2(64) := lc_database||'-'||'Workflow-Mailer@officedepot.com';
  l_mail_conn    UTL_SMTP.connection;
  lc_to          VARCHAR2(2000);
  lc_cc          VARCHAR2(2000);
  lc_to_all      VARCHAR2(2000) := p_email_list ;
  lc_cc_all      VARCHAR2(2000) := p_cc_email_list ;
  i              BINARY_INTEGER;
  j              BINARY_INTEGER;
  TYPE T_V100 IS TABLE OF VARCHAR2(100)  INDEX BY BINARY_INTEGER;
  lc_to_tbl      T_V100;
  lc_cc_tbl      T_V100;
  
  
  crlf VARCHAR2 (10) := UTL_TCP.crlf; 
BEGIN
  -- If setup data is missing then return

  IF lc_mailhost IS NULL OR lc_to_all IS NULL THEN
      RETURN;
  END IF;

  l_mail_conn := UTL_SMTP.open_connection(lc_mailhost, 25);
  UTL_SMTP.helo(l_mail_conn, lc_mailhost);
  UTL_SMTP.mail(l_mail_conn, lc_from);

  -- Check how many recipients are present in lc_to_all

  i := 1;
  LOOP
      lc_to := SUBSTR(lc_to_all,1,INSTR(lc_to_all,':') - 1);
      IF lc_to IS NULL OR i = 20 THEN
          lc_to_tbl(i) := lc_to_all;
          UTL_SMTP.rcpt(l_mail_conn, lc_to_all);
          EXIT;
      END IF;
      lc_to_tbl(i) := lc_to;
      UTL_SMTP.rcpt(l_mail_conn, lc_to);
      lc_to_all := SUBSTR(lc_to_all,INSTR(lc_to_all,':') + 1);
      i := i + 1;
  END LOOP;

 IF lc_cc_all IS NOT NULL
 THEN
 
  j := 1;
  LOOP
      lc_cc := SUBSTR(lc_cc_all,1,INSTR(lc_cc_all,':') - 1);
      IF lc_cc IS NULL OR j = 20 THEN
          lc_cc_tbl(i) := lc_cc_all;
          UTL_SMTP.rcpt(l_mail_conn, lc_cc_all);
          EXIT;
      END IF;
      lc_cc_tbl(i) := lc_cc;
      UTL_SMTP.rcpt(l_mail_conn, lc_cc);
      lc_cc_all := SUBSTR(lc_cc_all,INSTR(lc_cc_all,':') + 1);
      i := i + 1;
  END LOOP;

 END IF;


  UTL_SMTP.open_data(l_mail_conn);

  UTL_SMTP.write_data(l_mail_conn, 'Date: '    || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'From: '    || lc_from || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'Subject: ' || p_subject || Chr(13));

  --UTL_SMTP.write_data(l_mail_conn, Chr(13));

  -- Checl all recipients

  FOR i IN 1..lc_to_tbl.COUNT LOOP

      UTL_SMTP.write_data(l_mail_conn, 'To: '      || lc_to_tbl(i) || Chr(13));

  END LOOP;
  
 IF lc_cc_all IS NOT NULL
 THEN
  FOR j IN 1..lc_cc_tbl.COUNT LOOP

      UTL_SMTP.write_data(l_mail_conn, 'Cc: '      || lc_cc_tbl(i) || Chr(13));

  END LOOP;
 END IF;
  UTL_SMTP.write_data (l_mail_conn, ' ' || crlf); 
  UTL_SMTP.write_data(l_mail_conn, p_text||crlf);
  UTL_SMTP.write_data (l_mail_conn, ' ' || crlf); 
  UTL_SMTP.close_data(l_mail_conn);
  UTL_SMTP.quit(l_mail_conn);
EXCEPTION
    WHEN OTHERS THEN
    NULL;
END SEND_NOTIFICATION;

FUNCTION get_resource_id (p_proj_id NUMBER,p_user_name IN VARCHAR2) RETURN NUMBER
IS
v_resource_id NUMBER;
BEGIN
  SELECT resource_source_id
    INTO v_resource_id
    FROM apps.pa_project_parties_V
   WHERE user_name=p_user_name
     AND project_id = p_proj_id
     AND rownum = 1 ;
   RETURN(v_resource_id);
EXCEPTION
  WHEN others THEN
    v_resource_id:=NULL;
    RETURN(v_resource_id);
END get_resource_id;


PROCEDURE xx_pa_task_mgr_alloc(  x_errbuf               OUT NOCOPY VARCHAR2
                                ,x_retcode              OUT NOCOPY VARCHAR2
                                ,p_project_no            IN  VARCHAR2
                                ,p_agent        IN  VARCHAR2
                                ,p_dept            IN  VARCHAR2
                                ,p_US_COMPLIANCE    IN  NUMBER
                                ,p_US_CREATIVE        IN  NUMBER
                                ,p_US_DUTY_TARIFF     IN  NUMBER
                                ,p_US_FINAL_COMP    IN  NUMBER
                                ,p_US_PROD_DEV        IN  NUMBER
                                ,p_US_PROD_SUPP     IN  NUMBER
                                ,p_US_QA        IN  NUMBER
                                ,p_GSO_COMP        IN  NUMBER
                                ,p_GSO_MO        IN  NUMBER
                                ,p_GSO_PE        IN  NUMBER
                                ,p_GSO_PKG        IN  NUMBER
                                ,p_GSO_QA        IN  NUMBER
                                ,p_GSO_SPD        IN  NUMBER
                            )
IS




v_proj_mgr    VARCHAR2(240);
v_proj_id    NUMBER;
v_dlv_task_id   NUMBER;
v_proj_mgr_id    NUMBER;
v_task_started  VARCHAR2(1);
v_email_list    VARCHAR2(3000);
v_cc_email_list    VARCHAR2(3000);
v_text        VARCHAR2(3000);
v_sdate        Date;
v_proj_no    VARCHAR2(25);
v_proj_name     vARCHAR2(30);
v_subject    VARCHAR2(3000);


v_OD_PB_GSO_COMP_NO        VARCHAR2(15);
v_OD_PB_GSO_MO_NO        VARCHAR2(15);
v_OD_PB_GSO_PE_NO        VARCHAR2(15);
v_OD_PB_GSO_PKG_NO        VARCHAR2(15);
v_OD_PB_GSO_QA_NO        VARCHAR2(15);
v_OD_PB_GSO_SPD_NO        VARCHAR2(15);
v_OD_PB_US_COMPLIANCE_NO    VARCHAR2(15);    
v_OD_PB_US_CREATIVE_DEPT_NO    VARCHAR2(15);
v_OD_PB_US_DUTY_TARIFF_NO    VARCHAR2(15);
v_OD_PB_US_FINAL_COMP_NO    VARCHAR2(15);
v_OD_PB_US_PROD_DEV_NO        VARCHAR2(15);
v_OD_PB_US_PROD_SUPP_NO        VARCHAR2(15);
v_OD_PB_US_QA_NO        VARCHAR2(15);


v_OD_PB_GSO_COMP_ID        NUMBER;
v_OD_PB_GSO_MO_ID        NUMBER;
v_OD_PB_GSO_PE_ID        NUMBER;
v_OD_PB_GSO_PKG_ID        NUMBER;
v_OD_PB_GSO_QA_ID        NUMBER;
v_OD_PB_GSO_SPD_ID        NUMBER;
v_OD_PB_US_COMPLIANCE_ID    NUMBER;    
v_OD_PB_US_CREATIVE_DEPT_ID    NUMBER;
v_OD_PB_US_DUTY_TARIFF_ID    NUMBER;
v_OD_PB_US_FINAL_COMP_ID    NUMBER;
v_OD_PB_US_PROD_DEV_ID        NUMBER;
v_OD_PB_US_PROD_SUPP_ID        NUMBER;
v_OD_PB_US_QA_ID        NUMBER;


CURSOR C1(p_proj_id NUMBER) IS
SELECT DISTINCT attribute10 task_group
  FROM apps.pa_tasks
 WHERE project_id=p_proj_id;

CURSOR C2(p_proj_id NUMBER,p_task_grp VARCHAR2) IS
SELECT  a.rowid drowid,a.proj_element_id
  FROM  apps.pa_proj_elements a
       ,apps.pa_tasks b
       ,apps.pa_project_statuses pps
 WHERE b.project_id=p_proj_id
   AND b.attribute10=p_task_grp
   AND a.proj_element_id=b.task_id
   AND a.status_code = pps.project_status_code
   and pps.status_type = 'TASK'
   AND pps.project_status_name = 'Not Started'
   AND a.object_type='PA_TASKS'
   AND b.task_manager_person_id iS NOT NULL;

CURSOR C3 IS
SELECT distinct email_address
  FROM apps.pa_project_parties_v
 WHERE resource_source_id IN (v_OD_PB_GSO_COMP_ID,v_OD_PB_GSO_MO_ID,v_OD_PB_GSO_PE_ID,
                  v_OD_PB_GSO_PKG_ID,v_OD_PB_GSO_QA_ID,v_OD_PB_GSO_SPD_ID,
                  v_OD_PB_US_COMPLIANCE_ID,v_OD_PB_US_CREATIVE_DEPT_ID,
                  v_OD_PB_US_DUTY_TARIFF_ID,v_OD_PB_US_FINAL_COMP_ID,
                  v_OD_PB_US_PROD_DEV_ID,v_OD_PB_US_PROD_SUPP_ID,
                  v_OD_PB_US_QA_ID);
BEGIN
 
  BEGIN
    SELECT project_id,name,segment1,scheduled_start_date
      INTO v_proj_id,v_proj_name,v_proj_no,v_sdate
      FROM apps.pa_projects_all
     WHERE segment1=p_project_no;
  EXCEPTION
    WHEN others THEN
      v_proj_id:=NULL;
      x_errbuf  := 'Unexpected error in getting Project Id - '||SQLERRM;
      x_retcode := 2;
  END;


  IF v_proj_id IS NOT NULL THEN
     BEGIN
       SELECT d.employee_number,d.person_id
         INTO v_proj_mgr,v_proj_mgr_id
         FROM apps.fnd_user e,
              apps.per_all_people_f d,
              apps.pa_project_role_types_vl c,
              apps.pa_project_parties b,
              apps.pa_projects_all a
        WHERE a.project_id=v_proj_id
          AND b.project_id=a.project_id
          AND c.project_role_id=b.project_role_id
          AND c.project_role_type='PROJECT MANAGER'
          AND trunc(sysdate) between d.effective_start_date and d.effective_end_date
          AND d.person_id=b.resource_source_id
          AND e.employee_id=d.person_id;
    EXCEPTION
      WHEN others THEN
        v_proj_mgr:=NULL;
        x_errbuf  := 'Unexpected error in getting Project Manager - '||SQLERRM;
        x_retcode := 2;
    END;
  END IF;


--  BEGIN
--    SELECT 'Y'
--      INTO v_task_started
--      FROM dual
--     WHERE EXISTS (SELECT 'x' 
--             FROM apps.PA_STRUCTURES_TASKS_V
--            WHERE project_id=v_proj_id
--              AND task_status_meaning IN ('In Progress','Completed')
--              AND object_type = 'PA_TASKS');

--    IF v_task_started='Y' THEN
--        v_proj_mgr:=NULL;
--        x_errbuf  := 'We cannot modify the Task Managers, some tasks are already started';
--        x_retcode := 2;
--    END IF;
--  EXCEPTION
--    WHEN others THEN
--      v_task_started:=NULL;
--  END;

 -- IF (v_proj_mgr IS NOT NULL AND v_task_started IS NULL ) THEN
  
  IF v_proj_mgr IS NOT NULL  THEN

       BEGIN    
         SELECT    OD_PB_GSO_COMP,
        OD_PB_GSO_MO,
        OD_PB_GSO_PE,
        OD_PB_GSO_PKG,
        OD_PB_GSO_QA,
        OD_PB_GSO_SPD,
        OD_PB_US_COMPLIANCE,
        OD_PB_US_CREATIVE_DEPT,
        OD_PB_US_DUTY_TARIFF,
        OD_PB_US_FINAL_COMP,
        OD_PB_US_PROD_DEV,
        OD_PB_US_PROD_SUPP,
        OD_PB_US_QA
           INTO v_OD_PB_GSO_COMP_NO,
        v_OD_PB_GSO_MO_NO,
        v_OD_PB_GSO_PE_NO,
        v_OD_PB_GSO_PKG_NO,
        v_OD_PB_GSO_QA_NO,
        v_OD_PB_GSO_SPD_NO,
        v_OD_PB_US_COMPLIANCE_NO,
        v_OD_PB_US_CREATIVE_DEPT_NO,
        v_OD_PB_US_DUTY_TARIFF_NO,
        v_OD_PB_US_FINAL_COMP_NO,
        v_OD_PB_US_PROD_DEV_NO    ,
        v_OD_PB_US_PROD_SUPP_NO    ,
        v_OD_PB_US_QA_NO    
       FROM apps.Q_OD_PB_RESOURCE_ALLOCATION_V
      WHERE od_pb_sourcing_agent=p_agent
        AND od_pb_sc_dept_num=p_dept
        AND od_pb_di_proj_manager=v_proj_mgr;
       EXCEPTION
     WHEN others THEN
           x_errbuf  := 'Unexpected error in getting task manager set up - '||SQLERRM;
           x_retcode := 2;
       END;

    v_OD_PB_GSO_COMP_ID         :=get_resource_id(v_proj_id,v_OD_PB_GSO_COMP_NO);
    v_OD_PB_GSO_MO_ID        :=get_resource_id(v_proj_id,v_OD_PB_GSO_MO_NO);
    v_OD_PB_GSO_PE_ID        :=get_resource_id(v_proj_id,v_OD_PB_GSO_PE_NO);
    v_OD_PB_GSO_PKG_ID        :=get_resource_id(v_proj_id,v_OD_PB_GSO_PKG_NO);
    v_OD_PB_GSO_QA_ID        :=get_resource_id(v_proj_id,v_OD_PB_GSO_QA_NO);
    v_OD_PB_GSO_SPD_ID        :=get_resource_id(v_proj_id,v_OD_PB_GSO_SPD_NO);
    v_OD_PB_US_COMPLIANCE_ID    :=get_resource_id(v_proj_id,v_OD_PB_US_COMPLIANCE_NO);
    v_OD_PB_US_CREATIVE_DEPT_ID    :=get_resource_id(v_proj_id,v_OD_PB_US_CREATIVE_DEPT_NO);
    v_OD_PB_US_DUTY_TARIFF_ID    :=get_resource_id(v_proj_id,v_OD_PB_US_DUTY_TARIFF_NO);
    v_OD_PB_US_FINAL_COMP_ID    :=get_resource_id(v_proj_id,v_OD_PB_US_FINAL_COMP_NO);
    v_OD_PB_US_PROD_DEV_ID        :=get_resource_id(v_proj_id,v_OD_PB_US_PROD_DEV_NO);
    v_OD_PB_US_PROD_SUPP_ID        :=get_resource_id(v_proj_id,v_OD_PB_US_PROD_SUPP_NO);
    v_OD_PB_US_QA_ID        :=get_resource_id(v_proj_id,v_OD_PB_US_QA_NO);


    IF p_US_COMPLIANCE IS NOT NULL THEN
       v_OD_PB_US_COMPLIANCE_ID:=p_US_COMPLIANCE;
    END IF;

    IF p_US_CREATIVE IS NOT NULL THEN
       v_OD_PB_US_CREATIVE_DEPT_ID:=p_US_CREATIVE;    
    END IF;

    IF p_US_DUTY_TARIFF IS NOT NULL THEN
           v_OD_PB_US_DUTY_TARIFF_ID:=p_US_DUTY_TARIFF;
    END IF;

    IF p_US_FINAL_COMP IS NOT NULL THEN
       v_OD_PB_US_FINAL_COMP_ID:=p_US_FINAL_COMP;    
    END IF;

    IF p_US_PROD_DEV IS NOT NULL THEN
       v_OD_PB_US_PROD_DEV_ID:=p_US_PROD_DEV;
    END IF;

    IF p_US_PROD_SUPP IS NOT NULL THEN
           v_OD_PB_US_PROD_SUPP_ID:=p_US_PROD_SUPP;
    END IF;

    IF p_US_QA IS NOT NULL THEN
       v_OD_PB_US_QA_ID:=p_US_QA;
    END IF;


    IF p_GSO_COMP IS NOT NULL THEN
           v_OD_PB_GSO_COMP_ID:=p_GSO_COMP;
    END IF;

    IF p_GSO_MO IS NOT NULL THEN
       v_OD_PB_GSO_MO_ID:=p_GSO_MO;
    END IF;

    IF p_GSO_PE IS NOT NULL THEN
       v_OD_PB_GSO_PE_ID:=p_GSO_PE;
    END IF;

    IF p_GSO_PKG IS NOT NULL THEN
       v_OD_PB_GSO_PKG_ID:=p_GSO_PKG;
    END IF;

    IF p_GSO_QA IS NOT NULL THEN
           v_OD_PB_GSO_QA_ID:=p_GSO_QA;
    END IF;

    IF p_GSO_SPD IS NOT NULL THEN
       v_OD_PB_GSO_SPD_ID:=p_GSO_SPD;
    END IF;

     IF (v_OD_PB_GSO_COMP_ID IS NOT NULL 
       AND v_OD_PB_GSO_MO_ID IS NOT NULL 
       AND v_OD_PB_GSO_PE_ID IS NOT NULL 
       AND v_OD_PB_GSO_PKG_ID IS NOT NULL
       AND v_OD_PB_GSO_QA_ID IS NOT NULL 
       AND v_OD_PB_GSO_SPD_ID IS NOT NULL
       AND v_OD_PB_US_COMPLIANCE_ID IS NOT NULL 
       AND v_OD_PB_US_CREATIVE_DEPT_ID IS NOT NULL
       AND v_OD_PB_US_DUTY_TARIFF_ID IS NOT NULL 
       AND v_OD_PB_US_FINAL_COMP_ID IS NOT NULL
       AND v_OD_PB_US_PROD_DEV_ID IS NOT NULL 
       AND v_OD_PB_US_PROD_SUPP_ID IS NOT NULL
       AND v_OD_PB_US_QA_ID IS NOT NULL
        ) THEN

        FOR c IN C1(v_proj_id) LOOP
 
          FOR cur IN c2(v_proj_id,c.task_group) LOOP

          v_dlv_task_id:=-1; 

            UPDATE apps.pa_proj_elements
               SET  wf_item_type='XXPATNOT'
                   ,wf_process='XX_PA_PB_TASK_EXEC_FLOW'
                   ,enable_wf_flag='Y'
                   ,wf_start_lead_days=0
                   ,manager_person_id=DECODE(c.task_group,
                                            'OD_PB_GSO_COMP',v_OD_PB_GSO_COMP_ID,
                                            'OD_PB_GSO_MO',v_OD_PB_GSO_MO_ID,
                                            'OD_PB_GSO_PE',v_OD_PB_GSO_PE_ID,
                                            'OD_PB_GSO_PKG',v_OD_PB_GSO_PKG_ID,
                                            'OD_PB_GSO_QA',v_OD_PB_GSO_QA_ID,
                                            'OD_PB_GSO_SPD',v_OD_PB_GSO_SPD_ID,
                                            'OD_PB_US_COMPLIANCE',v_OD_PB_US_COMPLIANCE_ID,
                                            'OD_PB_US_CREATIVE_DEPT',v_OD_PB_US_CREATIVE_DEPT_ID,
                                            'OD_PB_US_DUTY_TARIFF',v_OD_PB_US_DUTY_TARIFF_ID,
                                            'OD_PB_US_FINAL_COMP',v_OD_PB_US_FINAL_COMP_ID,
                                            'OD_PB_US_PROD_DEV',v_OD_PB_US_PROD_DEV_ID,
                                            'OD_PB_US_PROD_SUPP',v_OD_PB_US_PROD_SUPP_ID,
                                            'OD_PB_US_QA',v_OD_PB_US_QA_ID,
                                            'OD_PB_US_PROJ_MANAGER',v_proj_mgr_id,
                                            manager_person_id
                                             )
          WHERE rowid=cur.drowid;

         UPDATE apps.pa_tasks
            SET task_manager_person_id=DECODE(c.task_group,
                                'OD_PB_GSO_COMP',v_OD_PB_GSO_COMP_ID,
                                'OD_PB_GSO_MO',v_OD_PB_GSO_MO_ID,
                                'OD_PB_GSO_PE',v_OD_PB_GSO_PE_ID,
                                'OD_PB_GSO_PKG',v_OD_PB_GSO_PKG_ID,
                                'OD_PB_GSO_QA',v_OD_PB_GSO_QA_ID,
                                'OD_PB_GSO_SPD',v_OD_PB_GSO_SPD_ID,
                                'OD_PB_US_COMPLIANCE',v_OD_PB_US_COMPLIANCE_ID,
                                'OD_PB_US_CREATIVE_DEPT',v_OD_PB_US_CREATIVE_DEPT_ID,
                                'OD_PB_US_DUTY_TARIFF',v_OD_PB_US_DUTY_TARIFF_ID,
                                'OD_PB_US_FINAL_COMP',v_OD_PB_US_FINAL_COMP_ID,
                                'OD_PB_US_PROD_DEV',v_OD_PB_US_PROD_DEV_ID,
                                'OD_PB_US_PROD_SUPP',v_OD_PB_US_PROD_SUPP_ID,
                                'OD_PB_US_QA',v_OD_PB_US_QA_ID,
                                'OD_PB_US_PROJ_MANAGER',v_proj_mgr_id,
                                task_manager_person_id
                             )
              WHERE task_id=cur.proj_element_id;

         BEGIN
           SELECT  ppe.proj_element_id
             INTO  v_dlv_task_id
             FROM  apps.PA_PROJ_ELEMENTS ppe ,
                   apps.PA_OBJECT_RELATIONSHIPS obj
            WHERE  ppe.object_type='PA_DELIVERABLES'
              AND  ppe.proj_element_id = OBJ.object_id_to2
              AND  OBJ.object_id_from2 =cur.proj_element_id
              AND  OBJ.object_type_to = 'PA_DELIVERABLES'
              AND  OBJ.object_type_from = 'PA_TASKS'
              AND  OBJ.relationship_type = 'A'
              AND  OBJ.relationship_subtype = 'TASK_TO_DELIVERABLE';
    
           IF v_dlv_task_id > 0 THEN
              UPDATE apps.pa_proj_elements
                 SET manager_person_id=DECODE(c.task_group,
                                'OD_PB_GSO_COMP',v_OD_PB_GSO_COMP_ID,
                                'OD_PB_GSO_MO',v_OD_PB_GSO_MO_ID,
                                'OD_PB_GSO_PE',v_OD_PB_GSO_PE_ID,
                                'OD_PB_GSO_PKG',v_OD_PB_GSO_PKG_ID,
                                'OD_PB_GSO_QA',v_OD_PB_GSO_QA_ID,
                                'OD_PB_GSO_SPD',v_OD_PB_GSO_SPD_ID,
                                'OD_PB_US_COMPLIANCE',v_OD_PB_US_COMPLIANCE_ID,
                                'OD_PB_US_CREATIVE_DEPT',v_OD_PB_US_CREATIVE_DEPT_ID,
                                'OD_PB_US_DUTY_TARIFF',v_OD_PB_US_DUTY_TARIFF_ID,
                                'OD_PB_US_FINAL_COMP',v_OD_PB_US_FINAL_COMP_ID,
                                'OD_PB_US_PROD_DEV',v_OD_PB_US_PROD_DEV_ID,
                                'OD_PB_US_PROD_SUPP',v_OD_PB_US_PROD_SUPP_ID,
                                'OD_PB_US_QA',v_OD_PB_US_QA_ID,
                                'OD_PB_US_PROJ_MANAGER',v_proj_mgr_id,
                                manager_person_id
                                     )
               WHERE proj_element_id=v_dlv_task_id;
           END IF;
         EXCEPTION
           WHEN others THEN
         NULL;      
         END;
          END LOOP;

        END LOOP;

     ELSE
          x_errbuf  := 'Task manager has not been set up ';
          x_retcode := 2;
     END IF;

     FOR cur IN C3 LOOP
       IF v_email_list IS NOT NULL THEN
          v_email_list:=v_email_list||':';
       END IF;
       v_email_list:=v_email_list||cur.email_address;
     END LOOP;


     v_text:= 'The Project '||v_proj_no||'/'||v_proj_name||' has been created with the Scheduled start date '||to_char(v_sdate);


     v_subject:='Project '||v_proj_no||'/'||v_proj_name||' creation notification';


     xx_pa_task_mgr_alloc_pkg.send_notification(v_subject,v_email_list,v_cc_email_list,v_text);


--     IF v_proj_no LIKE 'PB%' THEN
--        APPS.XX_PA_PB_TSKFLOW_PKG.start_xxpatnot(v_proj_id);
--        COMMIT;
--     END IF;

  END IF;  -- IF v_proj_mgr IS NOT NULL THEN
  COMMIT;
EXCEPTION
  WHEN others THEN
    x_errbuf  := 'Unexpected error in Task Manager allocation - '||SQLERRM;
    x_retcode := 2;
END xx_pa_task_mgr_alloc;

END XX_PA_TASK_MGR_ALLOC_PKG;
/