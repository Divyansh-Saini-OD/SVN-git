create or replace
PACKAGE BODY XXCRM_CUST_ASSIGNMENTS_LOAD
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name             :  xxcrm_CUST_ASSIGNMENTS_LOAD                   |
-- | Description      :  This package contains functions which are     |
-- |                     used to load assignments from the table       |
-- |                     xxcrm.xxcrm_overlay_assignments.               |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version  Date        Author              Remarks                   |
-- |=======  ==========  ==================  ==========================|
-- |1.0      05-11-2009 Mohan Kalyanasundaram Created the package body |
-- +===================================================================+
AS
  -- +====================================================================+
  PROCEDURE start_process(x_errmsg  OUT NOCOPY VARCHAR2,
                        x_retcode OUT NUMBER
                    )           
  AS
  ----------------------------------------------------------------------------
--------  Cursor to select all assignments from xxcrm.xxcrm_overlay_assignments table
  TYPE request_ids_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  v_request_ids_tab request_ids_tab;
    lv_phase               VARCHAR2(50);
    lv_status              VARCHAR2(50);
    lv_dev_phase           VARCHAR2(15);
    lv_dev_status          VARCHAR2(15);
    lv_wait                BOOLEAN;
    lv_message             VARCHAR2(4000);
    CURSOR assign_cur
    IS
      SELECT
       RS_OVERLAY_ASGNMT_ID
      FROM
       xxcrm.xxcrm_rs_overlay_assignments where processed_flag IN ('N','E')
       order by rs_overlay_asgnmt_id;
       v_tot_assignments_processed NUMBER := 0;
       lc_tot_concreq_spooled NUMBER := 0;
       lc_tot_assignments_processed NUMBER := 0;
       v_tot_assignments_error NUMBER := 0;
       lc_rs_overlay_assignment_id NUMBER := -1;
       v_rs_overlay_assignment_id NUMBER := 0;
       v_ret_msg VARCHAR2(1000) := NULL;
       lc_request_id number;
       lc_startseq NUMBER := -1;
       lc_endseq NUMBER := -1;
  BEGIN

        log_exception (
          p_program_name             => NULL
          ,p_error_location           => 'start_process'
          ,p_error_status             => 'INFO'
          ,p_oracle_error_code        => NULL
          ,p_oracle_error_msg         => '*** START of Customer Assignment Load Process ***'||SYSTIMESTAMP
          ,p_error_message_severity   => 'INFO'
          ,p_attribute1               => NULL);

        log_exception (
          p_program_name             => NULL
          ,p_error_location           => 'start_process'
          ,p_error_status             => 'INFO'
          ,p_oracle_error_code        => NULL
          ,p_oracle_error_msg         => 'Selecting Reps from xxcrm.xxcrm_overlay_assignments START '||SYSTIMESTAMP
          ,p_error_message_severity   => 'INFO'
          ,p_attribute1               => NULL);

      OPEN assign_cur;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'--> Selecting Reps from xxcrm.xxcrm_overlay_assignments END '||SYSTIMESTAMP);
          log_exception (
            p_program_name             => NULL
            ,p_error_location           => 'start_process'
            ,p_error_status             => 'INFO'
            ,p_oracle_error_code        => NULL
            ,p_oracle_error_msg         => 'Selecting Reps from xxcrm.xxcrm_overlay_assignments END '||SYSTIMESTAMP
            ,p_error_message_severity   => 'INFO'
            ,p_attribute1               => NULL);
      LOOP
        FETCH assign_cur INTO v_rs_overlay_assignment_id;
        EXIT WHEN assign_cur%NOTFOUND;
        BEGIN
        lc_rs_overlay_assignment_id := v_rs_overlay_assignment_id;
        v_tot_assignments_processed := v_tot_assignments_processed + 1;
        lc_tot_assignments_processed := lc_tot_assignments_processed + 1;
        if (v_tot_assignments_processed = 1) THEN
          lc_startseq := v_rs_overlay_assignment_id;
        END IF;
        if (v_tot_assignments_processed = 5000000) THEN
          lc_tot_concreq_spooled := lc_tot_concreq_spooled + 1;
          lc_endseq := v_rs_overlay_assignment_id;
          v_tot_assignments_processed := 0;
          lc_request_id := APPS.FND_REQUEST.SUBMIT_REQUEST('XXCRM','XXCRMCUSTASSIGNMENTSLOAD',lc_tot_concreq_spooled,'',FALSE,lc_startseq,lc_endseq);
          v_request_ids_tab(lc_tot_concreq_spooled) := lc_request_id;
          COMMIT;
            log_exception (
              p_program_name             => NULL
              ,p_error_location           => 'start_process'
              ,p_error_status             => 'INFO'
              ,p_oracle_error_code        => NULL
              ,p_oracle_error_msg         => 'Concurrent RequestID: '||lc_request_id||' Start Overlay AssignmentID#: '||lc_startseq||' End Overlay Assignment#: '||lc_endseq||' ***Created Concurrent Request***  '||SYSTIMESTAMP
              ,p_error_message_severity   => 'INFO'
              ,p_attribute1               => NULL);
          lc_startseq := -1;
          lc_endseq := -1;
        END IF;
        EXCEPTION
        WHEN OTHERS THEN
            lc_startseq := -1;
            log_exception (
              p_program_name             => NULL
              ,p_error_location           => 'start_process'
              ,p_error_status             => 'ERROR'
              ,p_oracle_error_code        => NULL
              ,p_oracle_error_msg         => '***Error Creating Concurrent Request Process Abandoned*** Concurrent RequestID: '||lc_request_id||' Start Overlay AssignmentID#: '||lc_startseq||' End Overlay Assignment#: '||lc_endseq||' SQL Error Code: '||SQLCODE||' '||SUBSTR(SQLERRM,1,100)
              ,p_error_message_severity   => 'MAJOR'
              ,p_attribute1               => ' ***TOTAL Assignments Processed: '||lc_tot_assignments_processed||' Total Concurrent Requests spawned: '||lc_tot_concreq_spooled||' '||SYSTIMESTAMP);
        END;
      END LOOP;
        if (lc_startseq > 0) THEN
          lc_tot_concreq_spooled := lc_tot_concreq_spooled + 1;
          lc_endseq := lc_rs_overlay_assignment_id;
          v_tot_assignments_processed := 0;
          lc_request_id := APPS.FND_REQUEST.SUBMIT_REQUEST('XXCRM','XXCRMCUSTASSIGNMENTSLOAD','','',FALSE,lc_startseq,lc_endseq);
          v_request_ids_tab(lc_tot_concreq_spooled) := lc_request_id;
          COMMIT;
            log_exception (
              p_program_name             => NULL
              ,p_error_location           => 'start_process'
              ,p_error_status             => 'INFO'
              ,p_oracle_error_code        => NULL
              ,p_oracle_error_msg         => 'Concurrent RequestID: '||lc_request_id||' Start Overlay AssignmentID#: '||lc_startseq||' End Overlay Assignment#: '||lc_endseq||' ***Created Concurrent Request***  '||SYSTIMESTAMP
              ,p_error_message_severity   => 'INFO'
              ,p_attribute1               => NULL);
          lc_startseq := -1;
          lc_endseq := -1;
        END IF;
      CLOSE assign_cur;
        FOR i in 1..lc_tot_concreq_spooled LOOP
          lv_phase      := NULL;
            lv_status     := NULL;
            lv_dev_phase  := NULL;
            lv_dev_status := NULL;
            lv_message    := NULL;
            lv_wait       := FND_CONCURRENT.WAIT_FOR_REQUEST( request_id => v_request_ids_tab(i)
                                                             ,INTERVAL   => 10
                                                             ,phase      => lv_phase
                                                             ,status     => lv_status
                                                             ,dev_phase  => lv_dev_phase
                                                             ,dev_status => lv_dev_status
                                                             ,message    => lv_message
                                                            );
      FND_FILE.PUT_LINE(FND_FILE.LOG,'*** RequestId: '||v_request_ids_tab(i)||' '||lv_phase||' '||lv_status||' '||lv_dev_phase||' '||lv_dev_status||' '||lv_message||SYSTIMESTAMP);
          log_exception (
            p_program_name             => NULL
            ,p_error_location           => 'start_process'
            ,p_error_status             => 'INFO'
            ,p_oracle_error_code        => NULL
            ,p_oracle_error_msg         => '*** RequestId: '||v_request_ids_tab(i)||' '||lv_phase||' '||lv_status||' '||lv_dev_phase||' '||lv_dev_status||' '||lv_message||SYSTIMESTAMP
            ,p_error_message_severity   => 'INFO'
            ,p_attribute1               => NULL);

        END LOOP;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'--> End of Customer Assignment Load Start Process '||SYSTIMESTAMP);
          log_exception (
            p_program_name             => NULL
            ,p_error_location           => 'start_process'
            ,p_error_status             => 'INFO'
            ,p_oracle_error_code        => NULL
            ,p_oracle_error_msg         => '*** End of Customer Assignment Load Start Process ***'||' ***TOTAL Assignments Processed: '||lc_tot_assignments_processed||' Total Concurrent Requests spawned: '||lc_tot_concreq_spooled||' '||SYSTIMESTAMP
            ,p_error_message_severity   => 'INFO'
            ,p_attribute1               => NULL);

END start_process;



  PROCEDURE main_process(x_errmsg  OUT NOCOPY VARCHAR2,
                        x_retcode OUT NUMBER,
                        p_startseq NUMBER,
                        p_endseq NUMBER
                    )           
  AS
  ----------------------------------------------------------------------------
--------  Cursor to select all assignments from xxcrm.xxcrm_overlay_assignments table
    CURSOR assign_cur
    IS
      SELECT
       RS_OVERLAY_ASGNMT_ID, rep_id, customer_number, ship_to
      FROM
       xxcrm.xxcrm_rs_overlay_assignments where processed_flag IN ('N','E')
       and rs_overlay_asgnmt_id >= p_startseq and rs_overlay_asgnmt_id <= p_endseq;
       v_tot_assignments_processed NUMBER := 0;
       v_tot_assignments_error NUMBER := 0;
       v_rep_id VARCHAR2(7) := NULL;
       v_customer_number NUMBER := 0;
       v_ship_to NUMBER := 0;
       v_rs_overlay_assignment_id NUMBER := 0;
       v_ret_msg VARCHAR2(1000) := NULL;
  BEGIN

        log_exception (
          p_program_name             => NULL
          ,p_error_location           => 'main_process'
          ,p_error_status             => 'INFO'
          ,p_oracle_error_code        => NULL
          ,p_oracle_error_msg         => '*** START of Customer Assignment Load Process ***'||SYSTIMESTAMP
          ,p_error_message_severity   => 'INFO'
          ,p_attribute1               => NULL);

        log_exception (
          p_program_name             => NULL
          ,p_error_location           => 'main_process'
          ,p_error_status             => 'INFO'
          ,p_oracle_error_code        => NULL
          ,p_oracle_error_msg         => 'Selecting Reps from xxcrm.xxcrm_overlay_assignments START '||SYSTIMESTAMP
          ,p_error_message_severity   => 'INFO'
          ,p_attribute1               => NULL);

      OPEN assign_cur;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'--> Selecting Reps from xxcrm.xxcrm_overlay_assignments END '||SYSTIMESTAMP);
          log_exception (
            p_program_name             => NULL
            ,p_error_location           => 'main_process'
            ,p_error_status             => 'INFO'
            ,p_oracle_error_code        => NULL
            ,p_oracle_error_msg         => 'Selecting Reps from xxcrm.xxcrm_overlay_assignments END '||SYSTIMESTAMP
            ,p_error_message_severity   => 'INFO'
            ,p_attribute1               => NULL);
      LOOP
        FETCH assign_cur INTO v_rs_overlay_assignment_id, v_rep_id, v_customer_number, v_ship_to;
        EXIT WHEN assign_cur%NOTFOUND;
        BEGIN
        v_tot_assignments_processed := v_tot_assignments_processed + 1;
      v_ret_msg := XXTPS_CUSTASSIGNMENT_LOAD (v_customer_number,v_ship_to,v_rep_id);
      IF (v_ret_msg = 'TRUE') THEN
        UPDATE xxcrm.xxcrm_rs_overlay_assignments
          SET processed_flag = 'P',
          processed_remark = 'SUCCESSFULLY LOADED'
          where RS_OVERLAY_ASGNMT_ID = v_rs_overlay_assignment_id;
      ELSE
        v_tot_assignments_error := v_tot_assignments_error + 1;
        UPDATE xxcrm.xxcrm_rs_overlay_assignments
          SET processed_flag = 'E',
          processed_remark = v_ret_msg
          where RS_OVERLAY_ASGNMT_ID = v_rs_overlay_assignment_id; 
            log_exception (
              p_program_name             => NULL
              ,p_error_location           => 'main_process'
              ,p_error_status             => 'ERROR'
              ,p_oracle_error_code        => NULL
              ,p_oracle_error_msg         => 'RepID: '||v_rep_id||' Customer#: '||v_customer_number||' ShipTO: '||v_ship_to||' OverlayAssignmentID: '||v_rs_overlay_assignment_id||' Return Message: '||v_ret_msg
              ,p_error_message_severity   => 'MAJOR'
              ,p_attribute1               => 'RepID: '||v_rep_id||' Customer#: '||v_customer_number||' ShipTO: '||v_ship_to||' OverlayAssignmentID: '||v_rs_overlay_assignment_id);
      END IF;
        EXCEPTION
        WHEN OTHERS THEN
            log_exception (
              p_program_name             => NULL
              ,p_error_location           => 'main_process'
              ,p_error_status             => 'ERROR'
              ,p_oracle_error_code        => NULL
              ,p_oracle_error_msg         => 'RepID: '||v_rep_id||' Customer#: '||v_customer_number||' ShipTO: '||v_ship_to||' OverlayAssignmentID: '||v_rs_overlay_assignment_id||' SQL Error Code: '||SQLCODE||' '||SUBSTR(SQLERRM,1,100)
              ,p_error_message_severity   => 'MAJOR'
              ,p_attribute1               => 'RepID: '||v_rep_id||' Customer#: '||v_customer_number||' ShipTO: '||v_ship_to||' OverlayAssignmentID: '||v_rs_overlay_assignment_id);
        END;
      IF MOD(v_tot_assignments_processed, 10000) = 0
      THEN
		COMMIT;
            log_exception (
              p_program_name             => NULL
              ,p_error_location           => 'main_process'
              ,p_error_status             => 'ERROR'
              ,p_oracle_error_code        => NULL
              ,p_oracle_error_msg         => ' ***TOTAL Assignments Processed: '||v_tot_assignments_processed||' Total Error records: '||v_tot_assignments_error||' '||SYSTIMESTAMP
              ,p_error_message_severity   => 'INFO'
              ,p_attribute1               => 'RepID: '||v_rep_id||' Customer#: '||v_customer_number||' ShipTO: '||v_ship_to||' OverlayAssignmentID: '||v_rs_overlay_assignment_id);

      END IF;
      END LOOP;
      CLOSE assign_cur;
	COMMIT;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'--> End of Customer Assignment Load Process '||SYSTIMESTAMP);
          log_exception (
            p_program_name             => NULL
            ,p_error_location           => 'main_process'
            ,p_error_status             => 'INFO'
            ,p_oracle_error_code        => NULL
            ,p_oracle_error_msg         => '*** End of Customer Assignment Load Process ***'||' ***TOTAL Assignments Processed: '||v_tot_assignments_processed||' Total Error records: '||v_tot_assignments_error||' '||SYSTIMESTAMP
            ,p_error_message_severity   => 'INFO'
            ,p_attribute1               => NULL);

END main_process;
------------------------------------------------------------------------------------------------------------
FUNCTION XXTPS_CUSTASSIGNMENT_LOAD (
      p_customer_number       VARCHAR2,
      p_ship_to_id      VARCHAR2,
      p_rep_id  VARCHAR2)
    RETURN VARCHAR2
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name             :  XXTPS_CUSTASSIGNMENT_LOAD                 |
-- | Description      :  This function is used to validate the data    |
-- |                     which has to be inserted into                 |
-- |                     XXTPS_SITE_REQUESTS table. If there is any    |
-- |                     error, this function returns the error        |
-- |                     message.                                      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version  Date        Author              Remarks                   |
-- |=======  ==========  ==================  ==========================|
-- |1.0      18-JUN-2008 Mohan Kalyanasundaram Initial version         |
-- |                     Office Depot                                  |
-- +===================================================================+
IS

  EX_ERROR_IN_PROC  EXCEPTION;
  lc_error_str        VARCHAR2(1000) := NULL;
  lc_party_site_id    NUMBER;
  lc_shipto_id        VARCHAR2(5);
  lc_resource_id      NUMBER;
  lc_role_id          NUMBER;
  lc_group_id         NUMBER;
  lc_division         VARCHAR2(150);
  lc_job_title        VARCHAR2(150);
  lc_assigned_division         VARCHAR2(240);
  lc_assigned_job_title        VARCHAR2(240);
  lc_assigned_resource_id      NUMBER;
  lc_orig_sys_ref     VARCHAR2(17);
  lc_api_err_code      VARCHAR2(10);
  lc_api_err_msg       VARCHAR2(4000);

BEGIN
  IF p_customer_number IS NULL THEN
    lc_error_str := 'Customer number is missing';
    raise EX_ERROR_IN_PROC;
  END IF;
  IF length(p_customer_number) !=8 THEN
    lc_error_str := 'Customer number should be 8 characters';
    raise EX_ERROR_IN_PROC;
  END IF;
  IF p_ship_to_id IS NULL THEN
    lc_error_str := 'ShipTo sequence is missing';
    raise EX_ERROR_IN_PROC;
  END IF;
  IF length(p_ship_to_id) > 5 THEN
    lc_error_str := 'ShipTo sequence should be 5 characters';
    raise EX_ERROR_IN_PROC;
  END IF;
  lc_shipto_id := lpad(p_ship_to_id, 5, '0');
  IF p_rep_id IS NULL THEN
    lc_error_str := 'RepId is missing';
    raise EX_ERROR_IN_PROC;
  END IF;
  BEGIN
    lc_orig_sys_ref := p_customer_number||'-'||lc_shipto_id||'-A0';
    select owner_table_id INTO lc_party_site_id
      from hz_orig_sys_references where owner_table_name ='HZ_PARTY_SITES'
      and orig_system_reference = lc_orig_sys_ref
      and status = 'A';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    lc_error_str := 'FALSE_' ||' CustomerNumber/ShipTO: '||lc_orig_sys_ref||' Not found';
    RETURN lc_error_str;
  WHEN OTHERS THEN
    lc_error_str := 'FALSE_' ||' CustomerNumber/ShipTO: '||lc_orig_sys_ref||' Error: '|| SQLERRM;
    RETURN lc_error_str;
  END;
  BEGIN
    SELECT mem.resource_id
           ,mem.group_id
           ,rrl.role_id
           ,rr.attribute14
           ,rr.attribute15
    INTO   lc_resource_id
           ,lc_group_id
           ,lc_role_id
           ,lc_division
           ,lc_job_title
    FROM   jtf_rs_group_members mem
           ,jtf_rs_role_relations rrl
           ,jtf_rs_roles_b rr
    WHERE  mem.group_member_id = rrl.role_resource_id
    AND    NVL(rrl.delete_flag, 'N') <> 'Y'
    AND    NVL(mem.delete_flag, 'N') <> 'Y'
    AND    rrl.role_resource_type = 'RS_GROUP_MEMBER'
    AND    sysdate BETWEEN start_date_active AND NVL(end_date_active, sysdate + 1)
    AND    rrl.role_id = rr.role_id
    AND    rrl.attribute15 = p_rep_id;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    lc_error_str := 'FALSE_' || 'Invalid REP_ID: '||p_rep_id;
    RETURN lc_error_str;
  WHEN TOO_MANY_ROWS THEN
    lc_error_str := 'FALSE_' || 'Legacy REP_ID: '||p_rep_id||' fetches more than one combination of Resource, Role and Group';
    RETURN lc_error_str;
  WHEN OTHERS THEN
    lc_error_str := 'FALSE_' || 'Legacy REP_ID: '||p_rep_id||' Error: ' || SQLERRM;
    RETURN lc_error_str;
  END;
  BEGIN
    lc_assigned_resource_id := null;
    lc_assigned_division := null;
    lc_assigned_job_title := null;
    select rr.attribute14, rr.attribute15, rd.resource_id
      INTO lc_assigned_division, lc_assigned_job_title, lc_assigned_resource_id
      from XX_TM_NAM_TERR_RSC_DTLS rd, XX_TM_NAM_TERR_ENTITY_DTLS ed, jtf_rs_roles_b rr
      where rd.resource_role_id = rr.role_id
      AND  sysdate BETWEEN rd.start_date_active AND NVL(rd.end_date_active, sysdate + 1)
      AND rd.named_acct_terr_id = ed.named_acct_terr_id
      AND ed.entity_type = 'PARTY_SITE'
      AND ed.entity_id = lc_party_site_id
      AND sysdate BETWEEN ed.start_date_active AND NVL(ed.end_date_active, sysdate + 1)
      AND rr.attribute15 = lc_job_title;
    lc_error_str := 'FALSE_' ||' CustomerNumber/ShipTO: '||lc_orig_sys_ref|| 'Party SiteID: '||lc_party_site_id||
    ' has an assignment with the same Job Title ('||lc_job_title||')';
    RETURN lc_error_str;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN TOO_MANY_ROWS THEN
    lc_error_str := 'FALSE_' ||' CustomerNumber/ShipTO: '||lc_orig_sys_ref|| 'Party SiteID: '||lc_party_site_id||
    ' has an assignment with the same Job Title ('||lc_job_title||')';
    RETURN lc_error_str;
  WHEN OTHERS THEN
    lc_error_str := 'FALSE_' ||' CustomerNumber/ShipTO: '||lc_orig_sys_ref|| 'Party SiteID: '||lc_party_site_id||' Error: ' || SQLERRM;
    RETURN lc_error_str;
  END;

  BEGIN
    lc_api_err_code := null;
    lc_api_err_msg  := null;
    xx_jtf_rs_named_acc_terr_pub.create_territory
        ( p_api_version_number   => 1.0
          ,p_named_acct_terr_id   => NULL
          ,p_named_acct_terr_name => NULL
          ,p_named_acct_terr_desc => NULL
          ,p_status               => 'A'
          ,p_start_date_active    => SYSDATE
          ,p_end_date_active      => NULL
          ,p_full_access_flag     => NULL
          ,p_source_terr_id       => NULL
          ,p_resource_id          => lc_resource_id
          ,p_role_id              => lc_role_id
          ,p_group_id             => lc_group_id
          ,p_entity_type          => 'PARTY_SITE'
          ,p_entity_id            => lc_party_site_id
          ,p_source_entity_id     => NULL
          ,p_source_system        => 'MANUAL'
          ,x_error_code           => lc_api_err_code
          ,x_error_message        => lc_api_err_msg
        );

    IF upper(lc_api_err_code) = 'E'
    THEN
      lc_error_str := 'FALSE_' || lc_api_err_msg;
      RETURN lc_error_str;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    lc_error_str := 'FALSE_' || 'Legacy REP_ID: '||p_rep_id||' Error: ' || SQLERRM;
    RETURN lc_error_str;
  END;

  IF lc_error_str IS NULL THEN
    lc_error_str := 'TRUE';
  ELSE
    lc_error_str := 'FALSE_' || lc_error_str;
  END IF;
  RETURN lc_error_str;
EXCEPTION
WHEN EX_ERROR_IN_PROC THEN
  lc_error_str := 'FALSE_' || lc_error_str;
  RETURN lc_error_str;
WHEN OTHERS THEN
  lc_error_str := 'FALSE_' || SQLERRM;
  RETURN lc_error_str;
END XXTPS_CUSTASSIGNMENT_LOAD;

-- +====================================================================+
-- | Name        : log_exception                                        |
-- | Description : This procedure is used for logging exceptions into   |
-- |               conversion common elements tables.                   |
-- |                                                                    |
-- | Parameters  : p_program_name,p_procedure_name,p_error_location     |
-- |               p_error_status,p_oracle_error_code,p_oracle_error_msg|
-- +====================================================================+

  PROCEDURE log_exception
    (p_program_name IN VARCHAR2,
    p_error_location IN VARCHAR2,
    p_error_status IN VARCHAR2,
    p_oracle_error_code IN VARCHAR2,
    p_oracle_error_msg IN VARCHAR2,
    p_error_message_severity IN VARCHAR2,
    p_attribute1 IN VARCHAR2)

 AS

-- ============================================================================
-- Local Variables.
-- ============================================================================
  l_return_code VARCHAR2(1) := 'E';
  l_program_name VARCHAR2(50);
  l_object_type constant VARCHAR2(35) := 'xxcrm_cust_assignments_load';
  l_notify_flag constant VARCHAR2(1) := 'Y';
  l_program_type VARCHAR2(35) := 'CONCURRENT PROGRAM';

  BEGIN
    l_program_name := p_program_name;
    IF l_program_name IS NULL THEN
      l_program_name := 'OD: XXCRM Load Customer Assignments';
    END IF;
    -- ============================================================================
    -- Call to custom error routine.
    -- ============================================================================
    xx_com_error_log_pub.log_error_crm(p_return_code => l_return_code,
      p_program_type => l_program_type,
      p_program_name => l_program_name,
      p_error_location => p_error_location,
      p_error_message_code => p_oracle_error_code,
      p_error_message => p_oracle_error_msg,
      p_error_message_severity => p_error_message_severity,
      p_error_status => p_error_status,
      p_notify_flag => l_notify_flag,
      p_object_type => l_object_type,
      p_attribute1 => p_attribute1);
  EXCEPTION
  WHEN others THEN
  fnd_file.PUT_LINE(fnd_file.LOG,   ': Error in logging exception :' || sqlerrm);

  END log_exception;


END XXCRM_CUST_ASSIGNMENTS_LOAD;
/