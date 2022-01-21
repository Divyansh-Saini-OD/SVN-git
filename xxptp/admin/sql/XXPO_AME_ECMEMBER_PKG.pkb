create or replace 
PACKAGE BODY XXPO_AME_ECMEMBER_PKG IS
/******************************************************************************************************/
--- Name: XXPO_AME_ECMEMBER_PKG
--- Description: This package will identify if EC Member is in the Hierarchy
--- 
--- Change Records
--- Version              Author              Date
--- 1.0              Elangovan, Arun      02-NOV-2017
/********************************************************************************************************/
FUNCTION xxod_get_req_approver_id (p_transaction_id IN NUMBER)
RETURN VARCHAR2 IS 
CURSOR C1(cp_transaction_id NUMBER) IS 
SELECT 
      paaf.person_id, pecx.full_name,pj.APPROVAL_AUTHORITY,pj.name
FROM FND_USER fndu,
  per_employees_current_x pecx,
  per_all_assignments_f paaf,
  per_jobs pj,
  (   SELECT level order_no,PERA.SUPERVISOR_ID 
    FROM PER_ASSIGNMENTS_F PERA 
    WHERE EXISTS
   (SELECT '1'
     FROM PER_PEOPLE_F PERF,
       PER_ASSIGNMENTS_F PERA1
     WHERE TRUNC(SYSDATE) BETWEEN PERF.EFFECTIVE_START_DATE AND PERF.EFFECTIVE_END_DATE
     AND PERF.PERSON_ID  = PERA.SUPERVISOR_ID
     AND PERA1.PERSON_ID = PERF.PERSON_ID
     AND TRUNC(SYSDATE) BETWEEN PERA1.EFFECTIVE_START_DATE AND PERA1.EFFECTIVE_END_DATE
     AND PERA1.PRIMARY_FLAG    = 'Y'
     AND PERA1.ASSIGNMENT_TYPE = 'E'
     AND EXISTS
       (SELECT '1'
       FROM PER_PERSON_TYPES PPT
       WHERE PPT.SYSTEM_PERSON_TYPE IN ('EMP', 'EMP_APL')
       AND PPT.PERSON_TYPE_ID        = PERF.PERSON_TYPE_ID
       )
   )
   START WITH PERA.PERSON_ID =
   (SELECT NVL(preparer_id,0)
		FROM po_requisition_headers_all
		WHERE requisition_header_id = po_ame_setup_pvt.get_new_req_header_id(cp_transaction_id)
   )
    AND TRUNC(SYSDATE) BETWEEN PERA.EFFECTIVE_START_DATE AND PERA.EFFECTIVE_END_DATE
    AND PERA.PRIMARY_FLAG                 = 'Y'
    AND PERA.ASSIGNMENT_TYPE              = 'E'
   CONNECT BY PRIOR PERA.SUPERVISOR_ID = PERA.PERSON_ID
    AND TRUNC(SYSDATE) BETWEEN PERA.EFFECTIVE_START_DATE AND PERA.EFFECTIVE_END_DATE
    AND PERA.PRIMARY_FLAG    = 'Y'
    AND PERA.ASSIGNMENT_TYPE = 'E'
  ) c
WHERE fndu.employee_id = c.supervisor_id
AND pecx.employee_id   = c.supervisor_id
AND paaf.person_id = c.supervisor_id
AND TRUNC(SYSDATE) BETWEEN paaf.EFFECTIVE_START_DATE AND paaf.EFFECTIVE_END_DATE
AND paaf.PRIMARY_FLAG    = 'Y'
AND paaf.ASSIGNMENT_TYPE = 'E'
AND paaf.JOB_ID = pj.JOB_ID
AND pj.APPROVAL_AUTHORITY <= (select APPROVAL_AUTHORITY
                              from apps.per_jobs
                              where name=fnd_profile.value('XXOD_AME_EC_ROLE_NAME'))
ORDER BY APPROVAL_AUTHORITY ASC;                              
lc_flag VARCHAR2(10) :='N';
ln_person_id1 NUMBER;
BEGIN
FOR i IN C1(p_transaction_id) LOOP
IF i.APPROVAL_AUTHORITY ='170' THEN
  lc_flag :='Y';
END IF;
END LOOP;
RETURN lc_flag;
EXCEPTION
 WHEN others THEN
 RETURN lc_flag;
END xxod_get_req_approver_id;
END XXPO_AME_ECMEMBER_PKG;
/