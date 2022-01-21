create or replace
PACKAGE BODY XX_PO_REQ_AME_PKG AS

  FUNCTION GET_MESSAGE (
     p_message_name   IN VARCHAR2
    ,p_token1_name    IN VARCHAR2 := NULL
    ,p_token1_value   IN VARCHAR2 := NULL
  ) RETURN VARCHAR2
  IS
  BEGIN
    FND_MESSAGE.CLEAR;
    FND_MESSAGE.SET_NAME('XXFIN',p_message_name);
    IF p_token1_name IS NOT NULL THEN
      FND_MESSAGE.SET_TOKEN(p_token1_name,p_token1_value);
    END IF;
    RETURN FND_MESSAGE.GET();
  END;

  PROCEDURE LOG_LINE (
     p_error_location  VARCHAR2
    ,p_message         VARCHAR2
  )
  IS
  BEGIN
    XX_COM_ERROR_LOG_PUB.LOG_ERROR(
      p_program_type           => 'WORKFLOW-AME'
     ,p_program_name           => 'REQAPPRV-PURCHASE_REQ'
     ,p_module_name            => 'iPROC'
     ,p_error_location         => p_error_location
     ,p_error_message          => p_message
     ,p_error_message_severity => 'ERROR'
     ,p_notify_flag            => 'N'
    );
  END LOG_LINE;



FUNCTION NONBUYERMANAGER(
   p_Requestor      IN NUMBER
  ,p_MinApprAuth    IN NUMBER
) RETURN po_tbl_varchar100 PIPELINED AS
   ln_employee           NUMBER(10);
   lc_job_name           VARCHAR2(700);
   ln_supervisor         NUMBER(10);
   ln_agent_id           NUMBER(10);
   lc_supervisors        VARCHAR2(700) := '';
   ln_approval_authority NUMBER(38);
   ln_depth              NUMBER; -- prevent endless loop if circular supervisor reference exists
   lc_err_message        VARCHAR2(2000);
BEGIN
   GETEMPLOYEEATTRIBUTES(p_Requestor, lc_job_name, ln_approval_authority, ln_supervisor, ln_agent_id);
   ln_depth:=0;
   LOOP
     ln_employee := ln_supervisor;
     GETEMPLOYEEATTRIBUTES(ln_employee, lc_job_name, ln_approval_authority, ln_supervisor, ln_agent_id);
     PIPE ROW('PER:' || ln_employee);
     ln_depth := ln_depth+1;
     IF ln_depth>30 THEN
       -- Circular supervisor reference detected for person_id
       lc_err_message := GET_MESSAGE('XX_PO_REQ_AME_0000_CIRC_REF','PERSON_ID',p_Requestor);
       LOG_LINE('XX_PO_REQ_AME_PKG.NONBUYERMANAGER',lc_err_message);
       RAISE_APPLICATION_ERROR(-20010,lc_err_message);
     END IF;
--     EXIT WHEN (ln_approval_authority >= p_MinApprAuth) AND (UPPER(lc_job_name) NOT LIKE '%BUYER%'); -- job names no longer have this convention
     EXIT WHEN ln_approval_authority >= 140 OR -- VPs level allowed to approve both POs and Reqs
              (ln_approval_authority >= p_MinApprAuth AND ln_agent_id IS NULL);
   END LOOP;
   RETURN;
END NONBUYERMANAGER;


PROCEDURE GETEMPLOYEEATTRIBUTES(
   p_Employee           IN NUMBER
  ,x_JobName            IN OUT VARCHAR2
  ,x_ApprovalAuthority 	IN OUT NUMBER
  ,x_Supervisor         IN OUT NUMBER
  ,x_AgentId            IN OUT NUMBER
) IS
  ld_sysdate                   DATE := TRUNC(SYSDATE);
  lc_err_message               VARCHAR2(2000);
BEGIN
   SELECT J.name, J.approval_authority, A.supervisor_id, B.agent_id
   INTO   x_JobName, x_ApprovalAuthority, x_Supervisor, x_AgentId
   FROM   PER_ALL_PEOPLE_F P, PER_ALL_ASSIGNMENTS_F A, PER_JOBS J, PO_AGENTS B
   WHERE  P.person_id=p_Employee
   AND    P.person_id=A.person_id
   AND    A.PRIMARY_FLAG = 'Y'
   AND    ld_sysdate BETWEEN P.effective_start_date AND P.effective_end_date
   AND    ld_sysdate BETWEEN A.effective_start_date AND A.effective_end_date
   AND    J.job_id=A.job_id
   AND    ld_sysdate BETWEEN B.start_date_active (+) AND NVL(B.end_date_active (+),SYSDATE)
   AND    P.person_id=B.agent_id (+);
  EXCEPTION
    WHEN OTHERS THEN
       -- Supervisor with sufficient approval_authority not found for person_id
       lc_err_message := GET_MESSAGE('XX_PO_REQ_AME_0001_APP_NT_FND','PERSON_ID',p_Employee);
       LOG_LINE('XX_PO_REQ_AME_PKG.GETEMPLOYEEATTRIBUTES',lc_err_message);
       RAISE_APPLICATION_ERROR(-20011,lc_err_message);

END GETEMPLOYEEATTRIBUTES;


END XX_PO_REQ_AME_PKG;


/
