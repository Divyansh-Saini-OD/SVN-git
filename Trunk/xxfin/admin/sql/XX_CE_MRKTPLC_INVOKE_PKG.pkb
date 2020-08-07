SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE BODY XX_CE_MRKTPLC_INVOKE_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_CE_MRKTPLC_INVOKE_PKG                                                          |
  -- |                                                                                            |
  -- |  Description: This package body is for Settlement and Reconciliation for MarketPlaces      |
  -- |  RICE ID   :  I3123_CM MarketPlaces Settlement and Reconciliation-Redesign                                      |
  -- |  Description:  Insert from MRKPLC HDR and DTL into XX_CE_AJB996,XX_CE_AJB998,        |
  -- |                                                                        XX_CE_AJB999        |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         05/23/2018   M K Pramod Kumar     Initial version                              |
  -- +============================================================================================+
  gc_package_name      CONSTANT all_objects.object_name%TYPE := 'XX_CE_MRKTPLC_INVOKE_PKG';
  gc_ret_success       CONSTANT VARCHAR2(20)                 := 'SUCCESS';
  gc_ret_no_data_found CONSTANT VARCHAR2(20)                 := 'NO_DATA_FOUND';
  gc_ret_too_many_rows CONSTANT VARCHAR2(20)                 := 'TOO_MANY_ROWS';
  gc_ret_api           CONSTANT VARCHAR2(20)                 := 'API';
  gc_ret_others        CONSTANT VARCHAR2(20)                 := 'OTHERS';
  gc_max_err_size      CONSTANT NUMBER                       := 2000;
  gc_max_sub_err_size  CONSTANT NUMBER                       := 256;
  gc_max_log_size      CONSTANT NUMBER                       := 2000;
  gc_max_err_buf_size  CONSTANT NUMBER                       := 250;
  gb_debug             BOOLEAN                               := FALSE;
TYPE gt_input_parameters
IS
  TABLE OF VARCHAR2(32000) INDEX BY VARCHAR2(255);
TYPE gt_translation_values
IS
  TABLE OF xx_fin_translatevalues%ROWTYPE INDEX BY VARCHAR2(30);
  /*********************************************************************
  * Procedure used to log based on gb_debug value or if p_force is TRUE.
  * Will log to dbms_output if request id is not set,
  * else will log to concurrent program log file.  Will prepend
  * timestamp to each message logged.  This is useful for determining
  * elapse times.
  *********************************************************************/
PROCEDURE logit(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT FALSE)
IS
  lc_message VARCHAR2(2000) := NULL;
BEGIN
  --if debug is on (defaults to true)
  IF (gb_debug OR p_force) THEN
    lc_message := SUBSTR(TO_CHAR(SYSTIMESTAMP, 'MM/DD/YYYY HH24:MI:SS.FF') || ' => ' || p_message, 1, gc_max_log_size);
    -- if in concurrent program, print to log file
    IF (fnd_global.conc_request_id > 0) THEN
      fnd_file.put_line(fnd_file.LOG, lc_message);
      -- else print to DBMS_OUTPUT
    ELSE
      DBMS_OUTPUT.put_line(lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END logit;
/****************************************************************
* Helper procedure to log the exiting of a subprocedure.
* This is useful for debugging and for tracking how long a given
* procedure is taking.
****************************************************************/
PROCEDURE exiting_sub(
    p_procedure_name IN VARCHAR2,
    p_exception_flag IN BOOLEAN DEFAULT FALSE)
AS
BEGIN
  IF gb_debug THEN
    IF p_exception_flag THEN
      logit(p_message => 'Exiting Exception: ' || p_procedure_name);
      logit(p_message => 'Date Time Stamp: '||TO_CHAR(sysdate,'DD-MON-RR HH24:MI:SS'));
    ELSE
      logit(p_message => 'Exiting: ' || p_procedure_name);
      logit(p_message => 'Date Time Stamp: '||TO_CHAR(sysdate,'DD-MON-RR HH24:MI:SS'));
    END IF;
    logit(p_message => '-----------------------------------------------');
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END exiting_sub;
/***********************************************
*  Setter procedure for gb_debug global variable
*  used for controlling debugging
***********************************************/
PROCEDURE set_debug(
    p_debug_flag IN VARCHAR2)
IS
BEGIN
  IF (UPPER(p_debug_flag) IN('Y', 'YES', 'T', 'TRUE')) THEN
    gb_debug := TRUE;
  END IF;
END set_debug;
/**********************************************************************
* Helper procedure to log the sub procedure/function name that has been
* called and logs the input parameters passed to it.
***********************************************************************/
PROCEDURE entering_sub(
    p_procedure_name IN VARCHAR2,
    p_parameters     IN gt_input_parameters)
AS
  ln_counter           NUMBER          := 0;
  lc_current_parameter VARCHAR2(32000) := NULL;
BEGIN
  IF gb_debug THEN
    logit(p_message => '-----------------------------------------------');
    logit(p_message => 'Entering: ' || p_procedure_name);
    logit(p_message => 'Date Time Stamp: '||TO_CHAR(sysdate,'DD-MON-RR HH24:MI:SS'));
    lc_current_parameter := p_parameters.FIRST;
    IF p_parameters.COUNT > 0 THEN
      logit(p_message => 'Input parameters:');
      LOOP
        EXIT
      WHEN lc_current_parameter IS NULL;
        ln_counter              := ln_counter + 1;
        logit(p_message => ln_counter || '. ' || lc_current_parameter || ' => ' || p_parameters(lc_current_parameter));
        lc_current_parameter := p_parameters.NEXT(lc_current_parameter);
      END LOOP;
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END entering_sub;
/******************************************************************
* Helper procedure to log that the main procedure/function has been
* called. Sets the debug flag and calls entering_sub so that
* it logs the procedure name and the input parameters passed in.
******************************************************************/
PROCEDURE entering_main(
    p_procedure_name  IN VARCHAR2,
    p_rice_identifier IN VARCHAR2,
    p_debug_flag      IN VARCHAR2,
    p_parameters      IN gt_input_parameters)
AS
BEGIN
  set_debug(p_debug_flag => p_debug_flag);
  IF gb_debug THEN
    IF p_rice_identifier IS NOT NULL THEN
      logit(p_message => '-----------------------------------------------');
      logit(p_message => '-----------------------------------------------');
      logit(p_message => 'RICE ID: ' || p_rice_identifier);
      logit(p_message => '-----------------------------------------------');
      logit(p_message => '-----------------------------------------------');
    END IF;
    entering_sub(p_procedure_name => p_procedure_name, p_parameters => p_parameters);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END entering_main;
/**********************************************************************************
* Procedure to process  MPL at different levels.
* This procedure is called by MAIN_MPL_INVOKE_PROC.
***********************************************************************************/
PROCEDURE PROCESS_MPL_INVOKE_PROC(
    p_process_name IN VARCHAR2,
    p_debug_flag   IN VARCHAR2)
IS
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'PROCESS_MPL_INVOKE_PROC';
  lt_parameters gt_input_parameters;
  lc_action      VARCHAR2(1000);
  lc_conc_req_id NUMBER;
  lc_wait_flag   BOOLEAN;
  lc_phase       VARCHAR2(100);
  lc_status      VARCHAR2(100);
  lc_dev_phase   VARCHAR2(100);
  lc_dev_status  VARCHAR2(100);
  lc_message     VARCHAR2(100);
BEGIN
  lt_parameters('p_process_name') := p_process_name;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);
  lc_action := 'Submitting MPL Data Load Program';
  BEGIN
    lc_conc_req_id := fnd_request.submit_request ( application => 'XXFIN' , program => 'XXCEMRKTPLCLOAD' , description => NULL , start_time => sysdate , sub_request => false , argument1=>p_process_name);---argument1 => i.file_name );
    COMMIT;
    IF lc_conc_req_id = 0 THEN
      logit(p_message =>'Conc. Program  failed to submit OD CE Market Places Load Settlement Program');
    ELSE
      lc_action              := 'Waiting for concurrent request OD CE Market Places Load Settlement Program to complete';
      lc_wait_flag           := fnd_concurrent.wait_for_request(request_id => lc_conc_req_id, phase => lc_phase, status => lc_status, dev_phase => lc_dev_phase, dev_status => lc_dev_status, MESSAGE => lc_message);
      IF UPPER(lc_dev_status) = 'NORMAL' AND UPPER(lc_dev_phase) = 'COMPLETE' THEN
        logit(p_message =>'OD CE Market Places Load Settlement Program successful for the Request Id: ' || lc_conc_req_id );
      ELSE
        logit(p_message =>'OD CE Market Places Load Settlement Program did not complete normally. ');
      END IF;
    END IF;
  END;
  BEGIN
    lc_action      := 'Submitting OD CE Market Places Process Settlement Program.';
    lc_conc_req_id := fnd_request.submit_request ( application => 'XXFIN' , program => 'XXCEMRKTPLCPROC' , description => NULL , start_time => sysdate , sub_request => false , argument1=>p_process_name, argument2=>p_debug_flag);
    COMMIT;
    IF lc_conc_req_id = 0 THEN
      logit(p_message =>'Conc. Program  failed to submit OD CE Market Places Process Settlement Program');
    ELSE
      lc_action              := 'Waiting for concurrent request OD CE Market Places Process Settlement Program to complete';
      lc_wait_flag           := fnd_concurrent.wait_for_request(request_id => lc_conc_req_id, phase => lc_phase, status => lc_status, dev_phase => lc_dev_phase, dev_status => lc_dev_status, MESSAGE => lc_message);
      IF UPPER(lc_dev_status) = 'NORMAL' AND UPPER(lc_dev_phase) = 'COMPLETE' THEN
        logit(p_message =>'OD CE Market Places Process Settlement Program completed successful for the Request Id: ' || lc_conc_req_id );
      ELSE
        logit(p_message =>'OD CE Market Places Process Settlement Program did not complete normally. ');
      END IF;
    END IF;
    exiting_sub(p_procedure_name => lc_procedure_name);
  END;
EXCEPTION
WHEN OTHERS THEN
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
END PROCESS_MPL_INVOKE_PROC;
/**********************************************************************
* Main Procedure to Process MarketPlaces Transactions.
* this procedure calls individual MarketPlace procedures to process them.
***********************************************************************/
PROCEDURE MAIN_MPL_INVOKE_PROC(
    errbuff OUT VARCHAR2,
    retcode OUT NUMBER,
    p_market_place IN VARCHAR2,
    p_debug_flag   IN VARCHAR2 DEFAULT 'N' )
IS
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'MAIN_MPL_INVOKE_PROC';
  lt_parameters gt_input_parameters;
  lt_program_setups gt_translation_values;
  lc_action VARCHAR2(1000);
BEGIN
  lt_parameters('p_market_place') := p_market_place;
  lt_parameters('p_debug_flag')   := p_debug_flag;
  entering_main(p_procedure_name => lc_procedure_name, p_rice_identifier => 'I3123', p_debug_flag => p_debug_flag, p_parameters => lt_parameters);
  /******************************
  * Call MPL Settlement Process.
  ******************************/
  lc_action := 'Invoke Load and Process MarketPlace Settlement Programs';

    PROCESS_MPL_INVOKE_PROC (p_market_place,p_debug_flag);
EXCEPTION
WHEN OTHERS THEN
  logit(p_message => 'ERROR  Action: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM, p_force => TRUE);
  retcode := 2;
  errbuff := 'Error encountered. Please check logs';
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
END MAIN_MPL_INVOKE_PROC;
END XX_CE_MRKTPLC_INVOKE_PKG;
/
show errors;