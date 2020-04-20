CREATE OR REPLACE PACKAGE BODY APPS.XX_CE_MRKTPLC_RECON_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_CE_MRKTPLC_RECON_PKG                                                            |
  -- |                                                                                            |
  -- |  Description: This package body is for Settlement and Reconciliation for MarketPlaces      |
  -- |  RICE ID   :  I3123_CM MarketPlaces Settlement and Reconciliation-Redesign                 |
  -- |  Description:  Insert from MRKPLC HDR and DTL into XX_CE_AJB996,XX_CE_AJB998,              |
  -- |                                                                        XX_CE_AJB999        |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         06/04/2018   M K Pramod Kumar     Initial version                              |
  -- | 1.1         06/27/2018   M K Pramod Kumar     Modified to remove mpl_header_id condition   |
  -- | 1.2         07/27/2018   M K Pramod Kumar     Modified to fix AJB999 duplicate record issue|
  -- | 2.0         07/11/2018   M K Pramod Kumar     Added to process Walmart Marketplace Transactions|
  -- | 2.1         07/11/2018   M K Pramod Kumar     Modified to add Summarization Logic for Walmart MPL|
  -- | 2.2         07/11/2018   M K Pramod Kumar     Modified to handle same Order ID scenario for Sale and Refund Transaction Type.|
  -- | 2.3         08/23/2018   M K Pramod Kumar     Added to process Rakuten Marketplace Transactions|
  -- | 2.4         08/23/2018   M K Pramod Kumar     Modified Ebay MPL code to derive Amounts from CA Transactions|
  -- | 2.5         10/03/2018   M K Pramod Kumar     Modified to handle same Order ID scenario for Order and Refund transaction |
  -- | 2.6         11/20/2018   Sripal Reddy M       Modifed  for Defect NAIT-71529 Time zone issue |
  -- | 2.7         11/26/2018   M K Pramod Kumar     Modifed  for Defect NAIT-72064 Refund Transaction Mapping, Load into AJB998 table if ORDT information
  -- |             is missing,change deposit date
  -- | 2.8         11/26/2018   M K Pramod Kumar     Modified to derive Bank Rec ID for EBAY MPL for partial transactinos.
  -- | 2.8.1       11/26/2018   M K Pramod Kumar     Modified to Include only Not null Order Id for RAKUTEN MPL
  -- | 2.9         04/01/2019   M K Pramod Kumar     Modified to fix Ebay Tax Issue for Multiple SKU scenario -NAIT-87324
  -- | 2.9.1       02/24/2020   M K Pramod Kumar     Modified to process NEWEGG Marketplace Transactions|
  -- | 2.9.2       02/24/2020   M K Pramod Kumar     Commented Bank Deposit Date Logic for Rakuten and Walmart MPL|
  -- | 2.9.3       02/24/2020   M K Pramod Kumar     Modified to fix NEWEGG Marketplace Transactions processing issue|
  -- | 3.0		   03/20/2020	Amit Kumar			 NAIT-102710: Modified to include Google MPL
  -- +============================================================================================+
  gc_package_name      CONSTANT all_objects.object_name%TYPE := 'XX_CE_MRKTPLC_RECON_PKG';
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
  gc_success_count     NUMBER                                :=0;
  gc_failure_count     NUMBER                                :=0;
TYPE gt_input_parameters
IS
  TABLE OF VARCHAR2(32000) INDEX BY VARCHAR2(255);
TYPE gt_translation_values
IS
  TABLE OF xx_fin_translatevalues%ROWTYPE INDEX BY VARCHAR2(30);
Type gt_typ_output_DETAILS
IS
  record
  (
    REC_SEQUENCE NUMBER,
    Message1     VARCHAR2(200),
    Message2     VARCHAR2(200),
    Message3     VARCHAR2(200) );
TYPE gt_tbl_output_DETAILS
IS
  TABLE OF gt_typ_output_DETAILS INDEX BY BINARY_INTEGER;
  gt_rec_output_DETAILS gt_tbl_output_DETAILS;
  gt_rec_counter NUMBER:=0;
  lt_translation_info xx_fin_translatevalues%ROWTYPE;
  /*********************************************************************
  * Procedure used to print output based on if p_force is TRUE.
  * Will log to dbms_output if request id is not set,
  * else will log to concurrent program output file.  Will prepend
  *********************************************************************/
PROCEDURE print_output(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT True)
IS
  lc_message VARCHAR2(2000) := NULL;
BEGIN
  --if debug is on (defaults to true)
  IF p_force THEN
    lc_message                    := SUBSTR(p_message, 1, gc_max_log_size);
    IF (fnd_global.conc_request_id > 0) THEN
      fnd_file.put_line(fnd_file.output, lc_message);
    ELSE
      DBMS_OUTPUT.put_line(lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_output;
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
/************************************************
* Helper procedure to get translation information
************************************************/
PROCEDURE get_translation_info(
    p_translation_name  IN xx_fin_translatedefinition.translation_name%TYPE,
    px_translation_info IN OUT NOCOPY xx_fin_translatevalues%ROWTYPE)
IS
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_translation_info';
  lt_parameters gt_input_parameters;
  lr_translation_info xx_fin_translatevalues%ROWTYPE;
BEGIN
  lt_parameters('p_transalation_name')               := p_translation_name;
  lt_parameters('px_translation_info.source_value1') := px_translation_info.source_value1;
  lt_parameters('px_translation_info.source_value2') := px_translation_info.source_value2;
  lt_parameters('px_translation_info.source_value3') := px_translation_info.source_value3;
  lt_parameters('px_translation_info.source_value4') := px_translation_info.source_value4;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);
  SELECT vals.*
  INTO lr_translation_info
  FROM xx_fin_translatevalues vals,
    xx_fin_translatedefinition defn
  WHERE 1                           =1
  AND defn.translation_name         = p_translation_name
  AND defn.translate_id             = vals.translate_id
  AND NVL(vals.source_value1, '-X') = NVL(px_translation_info.source_value1, NVL(vals.source_value1, '-X'))
  AND NVL(vals.source_value2, '-X') = NVL(px_translation_info.source_value2, NVL(vals.source_value2, '-X'))
  AND NVL(vals.source_value3, '-X') = NVL(px_translation_info.source_value3, NVL(vals.source_value3, '-X'))
  AND NVL(vals.source_value4, '-X') = NVL(px_translation_info.source_value4, NVL(vals.source_value4, '-X'))
  AND NVL(vals.source_value5, '-X') = NVL(px_translation_info.source_value5, NVL(vals.source_value5, '-X'))
  AND NVL(vals.source_value6, '-X') = NVL(px_translation_info.source_value6, NVL(vals.source_value6, '-X'))
  AND NVL(vals.source_value7, '-X') = NVL(px_translation_info.source_value7, NVL(vals.source_value7, '-X'))
  AND NVL(vals.source_value8, '-X') = NVL(px_translation_info.source_value8, NVL(vals.source_value8, '-X'))
  AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
  AND SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
  AND vals.enabled_flag = 'Y'
  AND defn.enabled_flag = 'Y';
  px_translation_info  := lr_translation_info;
  logit(p_message => 'RESULT Source_value1: ' || px_translation_info.Source_value1);
  exiting_sub(p_procedure_name => lc_procedure_name);
EXCEPTION
WHEN OTHERS THEN
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
END get_translation_info;
/************************************************
* Helper Function to derive the Transaction codes
************************************************/
FUNCTION mapping_tcodes_ebay(
    p_process_name VARCHAR2,
    p_tcodes       VARCHAR2,
    p_value        VARCHAR2)
  RETURN VARCHAR2
IS
  lc_trx_type xx_fin_translatevalues.target_value3%type;
  lc_sign xx_fin_translatevalues.target_value4%type;
BEGIN
  BEGIN
    SELECT xftv.target_value3,
      xftv.target_value4
    INTO lc_trx_type,
      lc_sign
    FROM xx_fin_translatedefinition xftd,
      xx_fin_translatevalues xftv
    WHERE xftd.translation_name ='OD_EBAY_TCODE'
    AND xftv.source_value1      = p_process_name
    AND xftv.target_value2      =p_tcodes
    AND xftd.translate_id       =xftv.translate_id;
  EXCEPTION
  WHEN OTHERS THEN
    lc_trx_type:='Order';
    lc_sign    :='1';
  END;
  IF p_value ='T' THEN
    RETURN lc_trx_type;
  ELSE
    RETURN lc_sign;
  END IF;
END mapping_tcodes_ebay;
/**********************************************************************************
* Helper procedure to get all the program setups.
* This procedure calls get_translation_info procedure to derive translation values.
***********************************************************************************/
PROCEDURE get_program_setups(
    x_program_setups OUT NOCOPY gt_translation_values)
IS
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_program_setups';
  lt_parameters gt_input_parameters;
  lc_action VARCHAR2(1000);
  lc_current_value xx_fin_translatevalues.target_value1%TYPE;
  lt_translation_info xx_fin_translatevalues%ROWTYPE;
BEGIN
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);
  --Place holder procedure to define all program setups.
  lc_action                         := 'Calling get_translation_info for EBAY_MPL';
  lt_translation_info               := NULL;
  lt_translation_info.source_value1 := 'EBAY_MPL';
  get_translation_info(p_translation_name => 'OD_SETTLEMENT_PROCESSES', px_translation_info => lt_translation_info);
EXCEPTION
WHEN OTHERS THEN
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
END get_program_setups;
/************************************************
* Helper Function to check if Transaction is Duplicate
************************************************/
FUNCTION dup_check_transaction(
    p_market_place   VARCHAR2,
    p_transaction_id VARCHAR2 )
  RETURN VARCHAR2
IS
  l_process_flag VARCHAR2(1):='N';
BEGIN
  BEGIN
    SELECT 'Y'
    INTO l_process_flag
    FROM XX_CE_MPL_SETTLEMENT_DTL
    WHERE attribute1    = p_transaction_id
    AND marketplace_name=p_market_place
    AND rownum          =1;
  EXCEPTION
  WHEN OTHERS THEN
    l_process_flag:='N';
  END;
  RETURN l_process_flag;
END dup_check_transaction;
/************************************************
* Helper Function to check if Transaction type and Transaction is Duplicate
************************************************/
FUNCTION dup_check_transaction_type(
    p_market_place     VARCHAR2,
    p_transaction_id   VARCHAR2,
    p_transaction_type VARCHAR2)
  RETURN VARCHAR2
IS
  l_process_flag VARCHAR2(1):='N';
BEGIN
  BEGIN
    SELECT 'Y'
    INTO l_process_flag
    FROM XX_CE_MPL_SETTLEMENT_HDR HDR
    WHERE hdr.order_id      =p_transaction_id
    AND hdr.marketplace_name=p_market_place
    AND hdr.transaction_type=p_transaction_type
    AND rownum              =1;
  EXCEPTION
  WHEN OTHERS THEN
    l_process_flag:='N';
  END;
  RETURN l_process_flag;
END dup_check_transaction_type;


/**********************************************************************************
* Procedure to trigger AJB Preprocessor Program for distinct unprocessed MPL Filenames.
* This procedure is called by MAIN_MPL_SETTLEMENT_PROCESS.
***********************************************************************************/
PROCEDURE INVOKE_AJBPREPROCESSOR_PROG(
    p_process_name IN VARCHAR2)
IS
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'INVOKE_AJBPREPROCESSOR_PROG';
  lt_parameters gt_input_parameters;
  lc_action      VARCHAR2(1000);
  lc_conc_req_id NUMBER;
  lc_wait_flag   BOOLEAN;
  lc_phase       VARCHAR2(100);
  lc_status      VARCHAR2(100);
  lc_dev_phase   VARCHAR2(100);
  lc_dev_status  VARCHAR2(100);
  lc_message     VARCHAR2(100);
  CURSOR cur_XX_CE_MPL_filenames
  IS
    SELECT DISTINCT ajb_file_name
    FROM XX_CE_MPL_SETTLEMENT_HDR
    WHERE record_status                 ='P'
    AND record_status_stage             ='999_DONE'
    AND marketplace_name                =p_process_name;
  lc_998_filetype CONSTANT VARCHAR2(10):='998';
  lc_999_filetype CONSTANT VARCHAR2(10):='999';
  lc_batch_size   CONSTANT NUMBER      :=1000;
TYPE lc_ajbfile_output_type
IS
  RECORD
  (
    SNo NUMBER,
    ajb_file_name XX_CE_MPL_SETTLEMENT_HDR.ajb_file_name%type,
    File_type  VARCHAR2(10),
    Request_id NUMBER );
TYPE lc_ajbfile_output_tab
IS
  TABLE OF lc_ajbfile_output_type INDEX BY BINARY_INTEGER;
  lc_ajbfile_output lc_ajbfile_output_tab;
  lc_count NUMBER:=0;
BEGIN
  lt_parameters('p_process_name') := p_process_name;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);
  lc_action := 'Submitting AJB Preprocessor Program for MPL Unprocessed Files';
  FOR Rec IN cur_XX_CE_MPL_filenames
  LOOP
    lc_count:=lc_count+1;
    BEGIN
      lc_conc_req_id := fnd_request.submit_request ( application => 'XXFIN' , program => 'XXCEAJBPRE' , description => NULL , start_time => sysdate , sub_request => false , argument1=>lc_998_filetype,argument2=>rec.ajb_file_name,argument3=>lc_batch_size);
      COMMIT;
      IF lc_conc_req_id = 0 THEN
        logit(p_message =>'Conc. Program  failed to submit OD: CE Pre-Process AJB Files');
      ELSE
        lc_action              := 'Waiting for concurrent request OD: CE Pre-Process AJB Files to complete';
        lc_wait_flag           := fnd_concurrent.wait_for_request(request_id => lc_conc_req_id, phase => lc_phase, status => lc_status, dev_phase => lc_dev_phase, dev_status => lc_dev_status, MESSAGE => lc_message);
        IF UPPER(lc_dev_status) = 'NORMAL' AND UPPER(lc_dev_phase) = 'COMPLETE' THEN
          logit(p_message =>'OD: CE Pre-Process AJB Files Program completed successful for the Request Id: ' || lc_conc_req_id );
        ELSE
          logit(p_message =>'OD: CE Pre-Process AJB Files Program did not complete normally for the Request Id: ' || lc_conc_req_id );
        END IF;
        lc_ajbfile_output(lc_count).SNo          :=lc_count;
        lc_ajbfile_output(lc_count).ajb_file_name:=Rec.ajb_file_name;
        lc_ajbfile_output(lc_count).File_type    :=lc_998_filetype;
        lc_ajbfile_output(lc_count).Request_id   :=lc_conc_req_id;
      END IF;
    END;
    BEGIN
      lc_count       :=lc_count+1;
      lc_conc_req_id := fnd_request.submit_request ( application => 'XXFIN' , program => 'XXCEAJBPRE' , description => NULL , start_time => sysdate , sub_request => false , argument1=>lc_999_filetype,argument2=>rec.ajb_file_name,argument3=>lc_batch_size);
      COMMIT;
      IF lc_conc_req_id = 0 THEN
        logit(p_message =>'Conc. Program  failed to submit OD: CE Pre-Process AJB Files');
      ELSE
        lc_action              := 'Waiting for concurrent request OD: CE Pre-Process AJB Files to complete';
        lc_wait_flag           := fnd_concurrent.wait_for_request(request_id => lc_conc_req_id, phase => lc_phase, status => lc_status, dev_phase => lc_dev_phase, dev_status => lc_dev_status, MESSAGE => lc_message);
        IF UPPER(lc_dev_status) = 'NORMAL' AND UPPER(lc_dev_phase) = 'COMPLETE' THEN
          logit(p_message =>'OD: CE Pre-Process AJB Files Program completed successful for the Request Id: ' || lc_conc_req_id );
        ELSE
          logit(p_message =>'OD: CE Pre-Process AJB Files Program did not complete normally for the Request Id: ' || lc_conc_req_id );
        END IF;
        lc_ajbfile_output(lc_count).SNo          :=lc_count;
        lc_ajbfile_output(lc_count).ajb_file_name:=Rec.ajb_file_name;
        lc_ajbfile_output(lc_count).File_type    :=lc_999_filetype;
        lc_ajbfile_output(lc_count).Request_id   :=lc_conc_req_id;
      END IF;
    END;
    UPDATE XX_CE_MPL_SETTLEMENT_HDR
    SET record_status      ='P',
      record_status_stage  ='PROCESSED',
      error_description    =NULL,
      request_id           =NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
      last_update_date     = sysdate,
      last_updated_by      = NVL(Fnd_Global.User_Id, -1),
      last_update_login    = NVL(Fnd_Global.User_Id, -1)
    WHERE 1                =1
    AND record_status      ='P'
    AND record_status_stage='999_DONE'
    AND ajb_file_name      = rec.ajb_file_name
    AND marketplace_name   =p_process_name;
    gc_success_count      :=gc_success_count+SQL%ROWCOUNT;
    COMMIT;
  END LOOP;
  IF lc_ajbfile_output.count>0 THEN
    print_output('/*Submit AJB Preprocessor Program for MPL:*/');
    print_output('--------------------------------------------:');
    print_output(rpad('S.No',8,' ')||rpad('AJB File Name',50,' ')||rpad('File Type',13,' ')||rpad('Request Id',12,' '));
    print_output(rpad('----',8,' ')||rpad('-------------',50,' ')||rpad('---------',13,' ')||rpad('----------',12,' '));
    FOR rec IN lc_ajbfile_output.first..lc_ajbfile_output.last
    LOOP
      print_output(rpad(lc_ajbfile_output(rec).SNo,8,' ')||rpad(lc_ajbfile_output(rec).ajb_file_name,50,' ')||rpad(lc_ajbfile_output(rec).File_type,13,' ')||rpad(lc_ajbfile_output(rec).request_id,12,' '));
    END LOOP ;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
END INVOKE_AJBPREPROCESSOR_PROG;
/**********************************************************************************
* Procedure to Derive Bank Deposit Date based on OD_SETTLEMENT_PROCESSES translation setup.
* This procedure is called by Walmart and RAkuten Prestage processing Procedures.
***********************************************************************************/
PROCEDURE DERIVE_BANK_DEPOSIT_DATE(
    p_process_name IN VARCHAR2,
    P_TRANS_DATE   IN DATE,
    P_DEPOSIT_DATE OUT DATE)
IS
  CURSOR cr_bank_deposit_line_desc(p_provider_type VARCHAR2)
  IS
    SELECT *
    FROM xx_ce_recon_glact_hdr
    WHERE provider_code=p_provider_type
    AND sysdate BETWEEN NVL(effective_from_date,sysdate) AND NVL(effective_to_date,sysdate+1)
    AND rownum=1;
  CURSOR cr_bank_stmt_date(p_transdate DATE,p_trx_text VARCHAR2,p_bank_Account_id NUMBER)
  IS
    SELECT MAX(csh.statement_date) statement_date
    FROM ce_statement_lines csl,
      ce_Statement_headers csh
    WHERE 1=1
    AND csh.statement_date BETWEEN (to_date(p_transdate,'DD-MON-YY')-5) AND (to_date(p_transdate,'DD-MON-YY')+5)
    AND csh.bank_account_id     =p_bank_Account_id
    AND csh.statement_header_id =csl.statement_header_id
    AND csl.status              ='UNRECONCILED'
    AND csl.trx_text LIKE p_trx_text;
BEGIN
  P_DEPOSIT_DATE                        :=NULL;
  IF lt_translation_info.target_value14 IS NULL THEN
    P_DEPOSIT_DATE                      :=P_TRANS_DATE;
  ELSE
    FOR deposit_line IN cr_bank_deposit_line_desc(lt_translation_info.target_value14)
    LOOP
      FOR stmt_date IN cr_bank_stmt_date(P_TRANS_DATE,deposit_line.bank_deposit_line_descr,deposit_line.bank_account_id)
      LOOP
        IF stmt_date.statement_date                       IS NOT NULL THEN
          IF to_Date(stmt_date.statement_date,'DD-MON-YY')>=to_date(P_TRANS_DATE,'DD-MON-YY') THEN
            logit(p_message => 'If statement date >= Transaction date ');
            logit(p_message => 'If statement date >= Transaction date '||to_Date(stmt_date.statement_date,'DD-MON-YY') ||'& '||to_date(P_TRANS_DATE,'DD-MON-YY') );
            P_DEPOSIT_DATE:=to_date(P_TRANS_DATE,'DD-MON-YY');
          ELSE
            P_DEPOSIT_DATE:=to_Date(stmt_date.statement_date,'DD-MON-YY')-1;
            logit(p_message => 'If statement date < Transaction date ');
            logit(p_message => 'If statement date >= Transaction date '||to_Date(stmt_date.statement_date,'DD-MON-YY') ||'& '||to_date(P_TRANS_DATE,'DD-MON-YY') );
          END IF;
        ELSE
          P_DEPOSIT_DATE:=to_date(P_TRANS_DATE,'DD-MON-YYYY');
          logit(p_message => 'If statement date is null ');
        END IF;
      END LOOP;
    END LOOP;
    IF P_DEPOSIT_DATE IS NULL THEN
      P_DEPOSIT_DATE  :=P_TRANS_DATE;
    END IF;
  END IF;
END DERIVE_BANK_DEPOSIT_DATE;
/**********************************************************************************
* Procedure to Derive Bank Rec Id based on OD_SETTLEMENT_PROCESSES translation setup.
* This procedure is called by PROCESS_MPL_999 and PROCESS_MPL_998 procedures.
***********************************************************************************/
PROCEDURE DERIVE_BANK_REC_ID(
    p_process_name IN VARCHAR2,
    P_DEPOSIT_DATE IN VARCHAR2,
    P_BANK_REC_ID OUT VARCHAR2)
IS
  CURSOR cr_bank_Rec_prov_type( p_process_name VARCHAR2 )
  IS
    SELECT DISTINCT vals.target_value1 provider_short_name
    FROM xx_fin_translatevalues vals,
      xx_fin_translatedefinition defn
    WHERE 1                   =1
    AND defn.translate_id     = vals.translate_id
    AND defn.translation_name = 'OD_CE_BANK_REC_PROV_TYPE'
    AND vals.source_value1    =p_process_name
    AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
    AND SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
    AND vals.enabled_flag = 'Y'
    AND defn.enabled_flag = 'Y';
  lv_bank_Rec_id_Derived xx_Ce_ajb998.bank_rec_id%type;
  lv_bank_Rec_id xx_Ce_ajb998.bank_rec_id%type;
  lv_provider_type_code VARCHAR2(10);
  lv_bank_rec_count     NUMBER:=0;
  CURSOR cr_ce_999_int_check(p_processor_id IN VARCHAR2,P_BANK_REC_ID IN VARCHAR2)
  IS
	select 1 from dual
where 1=1
and exists (select 1 from xx_Ce_ajb998 where bank_rec_id=P_BANK_REC_ID
and processor_id=p_processor_id);

type type_ce_999_int_check
IS
  TABLE OF cr_ce_999_int_check%rowtype INDEX BY pls_integer;
  l_ce_999_int_check type_ce_999_int_check;
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'DERIVE_BANK_REC_ID';
  lv_rec_count      NUMBER                :=0;
BEGIN
  IF lt_translation_info.target_value25 IS NULL THEN
    P_BANK_REC_ID                       :=P_DEPOSIT_DATE;
  ELSE
    OPEN cr_bank_Rec_prov_type(lt_translation_info.target_value14);
    FETCH cr_bank_Rec_prov_type INTO lv_provider_type_code;
    CLOSE cr_bank_Rec_prov_type;
    LOOP
      BEGIN
        lv_rec_count        :=lv_rec_count+1;
        IF lv_rec_count      =1 THEN
          lv_bank_rec_count := to_number(lt_translation_info.target_value25);
        ELSE
          lv_bank_rec_count:=lv_bank_rec_count+1;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        lv_bank_rec_count:= lv_bank_rec_count+1;
      END;
      lv_bank_Rec_id_Derived:=P_DEPOSIT_DATE||lpad(lv_bank_rec_count,3,'0')||'-MP-'||lv_provider_type_code||'-'||'US';
      lv_bank_Rec_id        :=P_DEPOSIT_DATE||lpad(lv_bank_rec_count,3,'0');
      OPEN cr_ce_999_int_check(lt_translation_info.target_value14,lv_bank_Rec_id_Derived);
      FETCH cr_ce_999_int_check bulk collect INTO l_ce_999_int_check;
      CLOSE cr_ce_999_int_check;
      IF l_ce_999_int_check.count = 0 THEN
        EXIT;
      END IF;
    END LOOP;
    P_BANK_REC_ID:=lv_bank_Rec_id;
  END IF;
END DERIVE_BANK_REC_ID;
/**********************************************************************************
* Procedure to process EBAY MP at different levels.
*this procedure is main procedure for EBAY MP and calls all sub procedures.
* This procedure is called by process_EBAY_MP.
***********************************************************************************/
PROCEDURE PROCESS_MPL_999(
    p_process_name IN VARCHAR2)
IS
  lc_action VARCHAR2(1000);
  lt_parameters gt_input_parameters;
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'PROCESS_MPL_999';
  CURSOR cur_ajb_file_name
  IS
    SELECT ajb_file_name,
      deposit_date
    FROM XX_CE_MPL_SETTLEMENT_HDR hdr
    WHERE record_status   IN ('V','E')
    AND record_status_stage='998_DONE'
    AND marketplace_name   = p_process_name
    GROUP BY ajb_file_name,
      deposit_Date;
  CURSOR cur_XX_CE_MPL_SETTLEMENT_HDR(p_ajb_file_name VARCHAR2)
  IS
    SELECT marketplace_name,
      settlement_id,
      deposit_date,
      ajb_file_name,
      SUM(NVL(ajb_999_amount,0)) total_settlement_amount
    FROM XX_CE_MPL_SETTLEMENT_HDR hdr
    WHERE ajb_file_name    =p_ajb_file_name
    AND record_status     IN ('V','E')
    AND record_status_stage='998_DONE'
    AND marketplace_name   = p_process_name
    GROUP BY marketplace_name,
      settlement_id,
      ajb_file_name,
      deposit_date;
type tbl_XX_CE_MPL_SETTLEMENT_HDR
IS
  TABLE OF cur_XX_CE_MPL_SETTLEMENT_HDR%rowtype INDEX BY pls_integer;
  lc_stlmt_hdr_tab tbl_XX_CE_MPL_SETTLEMENT_HDR;
  CURSOR cur_XX_CE_MPL_SETTLEMENT_dtl(p_settlement_id NUMBER,p_marketplace_name VARCHAR2 )
  IS
    SELECT dtl.settlement_id,
      dtl.store_number,
      dtl.marketplace_name,
      SUM(
      CASE
        WHEN price_type IN('Principal','Shipping','ShippingTax','Tax')
        THEN to_number(price_amount)
        ELSE 0
      END) net_sales,
      SUM(
      CASE
        WHEN item_related_fee_type IN('Commission','SalesTaxServiceFee','ShippingHB','RefundCommission')
        THEN to_number(item_related_fee_amount)
        ELSE 0
      END) item_fees
    FROM XX_CE_MPL_SETTLEMENT_DTL dtl
    WHERE dtl.settlement_id    =p_settlement_id
    AND dtl.marketplace_name   =p_marketplace_name
    AND record_status          ='V'
    GROUP BY dtl.settlement_id,
      dtl.store_number,
      dtl.marketplace_name ;
  lc_ce_ajb999 xx_ce_ajb999%ROWTYPE;
  lc_batch_size NUMBER        := 1000;
  lc_err_msg    VARCHAR2(1000):=NULL;
  lv_bank_Rec_id xx_Ce_ajb999.bank_rec_id%type;
BEGIN
  lt_parameters('p_process_name') := p_process_name;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);
  lc_action := 'Deriving Translation Details for EBAY MPL';
  lc_action := 'Processing Valid MPL Headers';
  FOR rec_ajb_file IN cur_ajb_file_name
  LOOP
    --Derive Bank Rec ID
    BEGIN
      DERIVE_BANK_REC_ID(p_process_name,TO_CHAR(rec_ajb_file.deposit_date,'YYYYMMDD'),lv_bank_Rec_id);
    EXCEPTION
    WHEN OTHERS THEN
      lv_bank_Rec_id:=TO_CHAR(rec_ajb_file.deposit_date,'YYYYMMDD');
      logit(p_message => 'Error Occured in PROCEDURE to derive Bank Rec ID-' ||lc_procedure_name|| ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
    END ;
    OPEN cur_XX_CE_MPL_SETTLEMENT_HDR(rec_ajb_file.ajb_file_name);
    LOOP
      FETCH cur_XX_CE_MPL_SETTLEMENT_HDR bulk collect
      INTO lc_stlmt_hdr_tab limit lc_batch_size;
      EXIT
    WHEN lc_stlmt_hdr_tab.count = 0;
      FOR indx IN lc_stlmt_hdr_tab.first..lc_stlmt_hdr_tab.last
      LOOP
        BEGIN
          lc_err_msg:=NULL;
          FOR rec_dtl IN cur_XX_CE_MPL_SETTLEMENT_dtl(lc_stlmt_hdr_tab(indx).settlement_id,lc_stlmt_hdr_tab(indx).marketplace_name)
          LOOP
            lc_ce_ajb999.record_type     :='999';
            lc_ce_ajb999.store_num       :=rec_dtl.store_number;
            lc_ce_ajb999.provider_type   :=lt_translation_info.target_value14;
            lc_ce_ajb999.submission_date :=lc_stlmt_hdr_tab(indx).deposit_date;
            lc_ce_ajb999.country_code    :='840';
            lc_ce_ajb999.currency_code   :='840';
            lc_ce_ajb999.processor_id    :=lt_translation_info.target_value13;
            lc_ce_ajb999.bank_rec_id     :=lv_bank_Rec_id;
            lc_ce_ajb999.cardtype        :=lt_translation_info.target_value15;
            lc_ce_ajb999.net_sales       :=rec_dtl.net_sales;
            lc_ce_ajb999.cost_funds_amt  :=ROUND(rec_dtl.item_fees,2);
            lc_ce_ajb999.status_1310     :='NEW';
            lc_ce_ajb999.sequence_id_999 :=xx_ce_ajb999_s.nextval;
            lc_ce_ajb999.ajb_file_name   :=lc_stlmt_hdr_tab(indx).ajb_file_name;
            lc_ce_ajb999.creation_date   :=sysdate;
            lc_ce_ajb999.created_by      :=NVL(fnd_global.user_id,-1);
            lc_ce_ajb999.last_update_date:=sysdate;
            lc_ce_ajb999.last_updated_by :=NVL(fnd_global.user_id,-1);
            lc_ce_ajb999.org_id          :=404;
            lc_ce_ajb999.recon_date      :=lc_stlmt_hdr_tab(indx).deposit_date;
            lc_ce_ajb999.territory_code  :='US';
            lc_ce_ajb999.currency        :='USD';
            lc_ce_ajb999.status          :='NEW';
            INSERT INTO XX_CE_ajb999 VALUES lc_ce_ajb999;
            UPDATE XX_CE_MPL_SETTLEMENT_HDR
            SET record_status      ='P',
              record_status_stage  ='999_DONE',
              error_description    =NULL,
              request_id           =NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
              last_update_date     = sysdate,
              last_updated_by      = NVL(Fnd_Global.User_Id, -1),
              last_update_login    = NVL(Fnd_Global.User_Id, -1)
            WHERE 1                =1
            AND settlement_id      = lc_stlmt_hdr_tab(indx).settlement_id
            AND marketplace_name   =lc_stlmt_hdr_tab(indx).marketplace_name
            AND record_status      ='V'
            AND record_status_stage='998_DONE';
            UPDATE XX_CE_MPL_SETTLEMENT_DTL
            SET record_status    ='P',
              request_id         =NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
              last_update_date   = sysdate,
              last_updated_by    = NVL(Fnd_Global.User_Id, -1),
              last_update_login  = NVL(Fnd_Global.User_Id, -1)
            WHERE 1              =1
            AND settlement_id    = lc_stlmt_hdr_tab(indx).settlement_id
            AND marketplace_name =lc_stlmt_hdr_tab(indx).marketplace_name
            AND record_status    ='V';
            gc_success_count    :=gc_success_count+1;
            COMMIT;
          END LOOP;
        EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          gc_failure_count:=gc_failure_count+1;
          lc_err_msg      :=SUBSTR('ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' ||sqlerrm,1,1000);
          UPDATE XX_CE_MPL_SETTLEMENT_HDR
          SET record_status      ='E',
            error_description    =lc_err_msg,
            request_id           =NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
            last_update_date     = sysdate,
            last_updated_by      = NVL(Fnd_Global.User_Id, -1),
            last_update_login    = NVL(Fnd_Global.User_Id, -1)
          WHERE 1                =1
          AND marketplace_name   =lc_stlmt_hdr_tab(indx).marketplace_name
          AND settlement_id      = lc_stlmt_hdr_tab(indx).settlement_id
          AND record_status      ='V'
          AND record_status_stage='998_DONE';
          COMMIT;
        END;
      END LOOP;
    END LOOP;
    CLOSE cur_XX_CE_MPL_SETTLEMENT_HDR;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name|| ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
END PROCESS_MPL_999;
/**********************************************************************************
* Procedure to process EBAY MP at different levels.
*this procedure is main procedure for EBAY MP and calls all sub procedures.
* This procedure is called by process_EBAY_MP.
***********************************************************************************/
PROCEDURE PROCESS_MPL_998(
    p_process_name IN VARCHAR2)
IS
  lc_action VARCHAR2(1000);
  lt_parameters gt_input_parameters;
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'PROCESS_MPL_998';
  CURSOR cur_ajb_file_name
  IS
    SELECT ajb_file_name,
      deposit_date
    FROM XX_CE_MPL_SETTLEMENT_HDR hdr
    WHERE record_status   IN ('V','E')
    AND record_status_stage='VALID'
    AND marketplace_name   = p_process_name
    GROUP BY ajb_file_name,
      deposit_Date;
  CURSOR cur_XX_CE_MPL_SETTLEMENT_HDR(p_ajb_file_name VARCHAR2)
  IS
    SELECT marketplace_name,
      order_id,
      mpl_header_id,
      settlement_id,
      DECODE(transaction_type,'Order','SALE','REFUND') transaction_type,
      provider_type,
      deposit_date,
      ajb_file_name,
      CAST(to_timestamp_tz(MAX(hdr.posted_date), 'yyyy-mm-dd""T""hh24:mi:ss TZH:TZM') at TIME zone dbtimezone AS DATE) posted_date
    FROM XX_CE_MPL_SETTLEMENT_HDR hdr
    WHERE ajb_file_name    =p_ajb_file_name
    AND record_status     IN ('V','E')
    AND record_status_stage='VALID'
    AND marketplace_name   = p_process_name
    GROUP BY marketplace_name,
      order_id,
      mpl_header_id,
      settlement_id,
      transaction_type,
      posted_date,
      provider_type,
      ajb_file_name,
      deposit_date;
type tbl_XX_CE_MPL_SETTLEMENT_HDR
IS
  TABLE OF cur_XX_CE_MPL_SETTLEMENT_HDR%rowtype INDEX BY pls_integer;
  lc_stlmt_hdr_tab tbl_XX_CE_MPL_SETTLEMENT_HDR;
  CURSOR cur_XX_CE_MPL_SETTLEMENT_dtl(p_order_id XX_CE_MPL_SETTLEMENT_HDR.order_id%type,p_market_place XX_CE_MPL_SETTLEMENT_HDR.marketplace_name%type ,p_mpl_header_id XX_CE_MPL_SETTLEMENT_HDR.mpl_header_id%type )
  IS
    SELECT dtl.settlement_id,
      dtl.mpl_header_id,
      dtl.order_id,
      dtl.store_number,
      dtl.aops_order_number,
      SUM(
      CASE
        WHEN dtl.price_type IN('Principal','Shipping','ShippingTax','Tax')
        THEN to_number(dtl.price_amount)
        ELSE 0
      END) transaction_amt,
      SUM(
      CASE
        WHEN item_related_fee_type IN('Commission','SalesTaxServiceFee','ShippingHB','RefundCommission')
        THEN to_number(item_related_fee_amount)
        ELSE 0
      END) item_fees
    FROM XX_CE_MPL_SETTLEMENT_DTL dtl
    WHERE dtl.order_id       =p_order_id
    AND dtl.mpl_header_id    =p_mpl_header_id
    AND dtl.marketplace_name =p_market_place
    AND record_status        ='V'
    GROUP BY dtl.settlement_id,
      dtl.mpl_header_id,
      dtl.order_id,
      dtl.store_number,
      dtl.aops_order_number;
  lc_ce_ajb998 xx_ce_ajb998%ROWTYPE;
  lc_batch_size NUMBER        := 1000;
  lc_err_msg    VARCHAR2(1000):=NULL;
  lv_bank_Rec_id xx_Ce_ajb999.bank_rec_id%type;
BEGIN
  lt_parameters('p_process_name') := p_process_name;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);
  lc_action := 'Deriving Translation Details for EBAY MPL';
  lc_action := 'Processing Valid MPL Headers';
  FOR rec_ajb_file IN cur_ajb_file_name
  LOOP
    BEGIN --Derive Bank Rec ID
      DERIVE_BANK_REC_ID(p_process_name,TO_CHAR(rec_ajb_file.deposit_date,'YYYYMMDD'),lv_bank_Rec_id);
    EXCEPTION
    WHEN OTHERS THEN
      lv_bank_Rec_id:=TO_CHAR(rec_ajb_file.deposit_date,'YYYYMMDD');
      logit(p_message => 'Error Occured in PROCEDURE to derive Bank Rec ID-' ||lc_procedure_name|| ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
    END;
    OPEN cur_XX_CE_MPL_SETTLEMENT_HDR(rec_ajb_file.ajb_file_name);
    LOOP
      FETCH cur_XX_CE_MPL_SETTLEMENT_HDR bulk collect
      INTO lc_stlmt_hdr_tab limit lc_batch_size;
      EXIT
    WHEN lc_stlmt_hdr_tab.count = 0;
      FOR indx IN lc_stlmt_hdr_tab.first..lc_stlmt_hdr_tab.last
      LOOP
        BEGIN
          lc_err_msg:=NULL;
          FOR rec_dtl IN cur_XX_CE_MPL_SETTLEMENT_dtl(lc_stlmt_hdr_tab(indx).order_id,lc_stlmt_hdr_tab(indx).marketplace_name,lc_stlmt_hdr_tab(indx).mpl_header_id)
          LOOP
            lc_ce_ajb998.RECORD_TYPE      :='998';
            lc_ce_ajb998.ACTION_CODE      :=0;
            lc_ce_ajb998.PROVIDER_TYPE    :=lt_translation_info.target_value14;
            lc_ce_ajb998.STORE_NUM        :=rec_dtl.store_number;
            lc_ce_ajb998.TRX_TYPE         := lc_stlmt_hdr_tab(indx).transaction_type;
            lc_ce_ajb998.TRX_AMOUNT       :=rec_dtl.transaction_amt;
            lc_ce_ajb998.INVOICE_NUM      :=rec_dtl.aops_order_number;
            lc_ce_ajb998.COUNTRY_CODE     :='840';
            lc_ce_ajb998.CURRENCY_CODE    :='840';
            lc_ce_ajb998.RECEIPT_NUM      :=lc_stlmt_hdr_tab(indx).order_id;
            lc_ce_ajb998.BANK_REC_ID      :=lv_bank_Rec_id;
            lc_ce_ajb998.TRX_DATE         := lc_stlmt_hdr_tab(indx).posted_date;
            lc_ce_ajb998.PROCESSOR_ID     :=lt_translation_info.target_value13;
            lc_ce_ajb998.CREATION_DATE    :=sysdate;
            lc_ce_ajb998.CREATED_BY       :=NVL(fnd_global.user_id,-1);
            lc_ce_ajb998.LAST_UPDATE_DATE :=sysdate;
            lc_ce_ajb998.LAST_UPDATED_BY  :=NVL(fnd_global.user_id,-1);
            lc_ce_ajb998.STATUS           :='NEW';
            lc_ce_ajb998.STATUS_1310      :='NEW';
            lc_ce_ajb998.SEQUENCE_ID_998  :=xx_ce_ajb998_s.nextval;
            lc_ce_ajb998.ORG_ID           :=404;
            lc_ce_ajb998.AJB_FILE_NAME    :=lc_stlmt_hdr_tab(indx).ajb_file_name;
            lc_ce_ajb998.RECON_DATE       :=lc_stlmt_hdr_tab(indx).deposit_date;
            lc_ce_ajb998.TERRITORY_CODE   :='US';
            lc_ce_ajb998.CURRENCY         :='USD';
            lc_ce_ajb998.CARD_TYPE        :=lt_translation_info.target_value15;
            INSERT INTO XX_CE_ajb998 VALUES lc_ce_ajb998;
            UPDATE XX_CE_MPL_SETTLEMENT_HDR
            SET record_status     ='V',
              record_status_stage ='998_DONE',
              ajb_998_amount      =rec_dtl.transaction_amt,
              ajb_999_amount      =rec_dtl.item_fees,
              total_amount        =rec_dtl.transaction_amt-rec_dtl.item_fees,
              error_description   =NULL,
              request_id          =NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
              last_update_date    = sysdate,
              last_updated_by     = NVL(Fnd_Global.User_Id, -1),
              last_update_login   = NVL(Fnd_Global.User_Id, -1)
            WHERE 1               =1
            AND order_id          = lc_stlmt_hdr_tab(indx).order_id
            AND marketplace_name  =lc_stlmt_hdr_tab(indx).marketplace_name
            AND mpl_header_id     =lc_stlmt_hdr_tab(indx).mpl_header_id;
            gc_success_count     :=gc_success_count+1;
          END LOOP;
          COMMIT;
        EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          gc_failure_count:=gc_failure_count+1;
          lc_err_msg      :=SUBSTR('ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' ||sqlerrm,1,1000);
          UPDATE XX_CE_MPL_SETTLEMENT_HDR
          SET record_status    ='E',
            error_description  =lc_err_msg,
            request_id         =NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
            last_update_date   = sysdate,
            last_updated_by    = NVL(Fnd_Global.User_Id, -1),
            last_update_login  = NVL(Fnd_Global.User_Id, -1)
          WHERE 1              =1
          AND order_id         = lc_stlmt_hdr_tab(indx).order_id
          AND marketplace_name =lc_stlmt_hdr_tab(indx).marketplace_name
          AND mpl_header_id    =lc_stlmt_hdr_tab(indx).mpl_header_id;
          COMMIT;
        END;
      END LOOP;
    END LOOP;
    CLOSE cur_XX_CE_MPL_SETTLEMENT_HDR;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name|| ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
END PROCESS_MPL_998;
/**********************************************************************************
* Procedure to derive EBS Order Infromation for all the EBAY MP Transactions.
* This procedure is called by MAIN_MPL_SETTLEMENT_PROCESS.
***********************************************************************************/
PROCEDURE DERIVE_MPL_ORDER_INFO(
    p_process_name IN VARCHAR2)
IS
  lc_action VARCHAR2(1000);
  lt_parameters gt_input_parameters;
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'DERIVE_MPL_ORDER_INFO';
  lc_err_msg        VARCHAR2(1000)        :=NULL;
  lc_success_flag   VARCHAR2(1)           :='N';
  CURSOR cur_XX_CE_MPL_SETTLEMENT_HDR
  IS
    SELECT marketplace_name,
      order_id,
      mpl_header_id,
      settlement_id,
      transaction_type,
      provider_type
    FROM XX_CE_MPL_SETTLEMENT_HDR
    WHERE record_status   IN ('N','E')
    AND record_status_stage='NEW'
    AND marketplace_name   = p_process_name
    GROUP BY marketplace_name,
      order_id,
      mpl_header_id,
      settlement_id,
      transaction_type,
      provider_type;
  CURSOR cur_XX_CE_MPL_SETTLEMENT_dtl(p_order_id XX_CE_MPL_SETTLEMENT_HDR.order_id%type,p_header_id XX_CE_MPL_SETTLEMENT_HDR.mpl_header_id%type,p_market_place VARCHAR2 )
  IS
    SELECT DISTINCT dtl.settlement_id,
      dtl.mpl_header_id,
      dtl.order_id,
      dtl.merchant_order_item_id
    FROM XX_CE_MPL_SETTLEMENT_DTL dtl
    WHERE dtl.order_id    =p_order_id
    AND dtl.mpl_header_id =p_header_id
    AND marketplace_name  =p_market_place;
type tbl_XX_CE_MPL_SETTLEMENT_HDR
IS
  TABLE OF cur_XX_CE_MPL_SETTLEMENT_HDR%rowtype INDEX BY pls_integer;
  lc_stlmt_hdr_tab tbl_XX_CE_MPL_SETTLEMENT_HDR;
  CURSOR ordt_cur(p_order_id VARCHAR2,p_trx_type VARCHAR2,p_provider_type VARCHAR2)
  IS
    SELECT xordt.order_payment_id,
      xordt.store_number,
      xordt.orig_sys_document_ref
    FROM xx_ar_order_receipt_dtl xordt
    WHERE xordt.mpl_order_id  = p_order_id
    AND xordt.sale_type       = p_trx_type
    AND xordt.order_source   IN ('MPL')
    AND xordt.credit_card_code=p_provider_type;
type ordt
IS
  TABLE OF ordt_cur%rowtype INDEX BY pls_integer;
  l_ordt_tab ordt;
  CURSOR ordt1_cur(p_order_id VARCHAR2,p_trx_type VARCHAR2,p_provider_type VARCHAR2,p_merchant_order_item_id VARCHAR2)
  IS
    SELECT xordt.order_payment_id,
      xordt.store_number,
      xordt.orig_sys_document_ref
    FROM xx_ar_order_receipt_dtl xordt
    WHERE xordt.mpl_order_id  = p_order_id
    AND xordt.sale_type       = p_trx_type
    AND xordt.credit_card_code=p_provider_type
    AND xordt.order_source   IN ('MPL')
    AND EXISTS
      (SELECT 'x'
      FROM oe_order_headers_all oeh,
        oe_order_lines_all oel
      WHERE oeh.order_number =xordt.order_number
      AND oel.header_id      =oeh.header_id
      AND oel.ordered_item   = ltrim(p_merchant_order_item_id,'0')
      );
type ordt1
IS
  TABLE OF ordt1_cur%rowtype INDEX BY pls_integer;
  l_ordt1_tab ordt1;
  lc_batch_size   NUMBER := 1000;
  lc_trx_type     VARCHAR2(50);
  lc_store_number VARCHAR2(30);
  lc_split_order XX_CE_MPL_SETTLEMENT_HDR.split_order%type;
  lc_aops_order_number XX_CE_MPL_SETTLEMENT_DTL.aops_order_number%type;
  lc_order_payment_id XX_CE_MPL_SETTLEMENT_DTL.order_payment_id%type;
  Lc_def_store_number VARCHAR2(10);
BEGIN
  lt_parameters('p_process_name') := p_process_name;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);
  lc_action := 'Deriving Unprocessed MPL Header Information from HDR table';
  BEGIN
    SELECT vals.target_value3
    INTO Lc_def_store_number
    FROM xx_fin_translatevalues vals,
      xx_fin_translatedefinition defn
    WHERE 1                   =1
    AND defn.translation_name = 'OD_EXT_MARKETPLACE_SETUPS'
    AND vals.translate_id     =defn.translate_id
    AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
    AND SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
    AND vals.enabled_flag = 'Y'
    AND defn.enabled_flag = 'Y'
    AND rownum            =1;
    Lc_def_store_number  :=lpad(Lc_def_store_number,6,'0');
  EXCEPTION
  WHEN OTHERS THEN
    Lc_def_store_number:='005910';
  END;
  OPEN cur_XX_CE_MPL_SETTLEMENT_HDR;
  LOOP
    FETCH cur_XX_CE_MPL_SETTLEMENT_HDR bulk collect
    INTO lc_stlmt_hdr_tab limit lc_batch_size;
    EXIT
  WHEN lc_stlmt_hdr_tab.count = 0;
    FOR indx IN lc_stlmt_hdr_tab.first..lc_stlmt_hdr_tab.last
    LOOP
      BEGIN
        lc_err_msg                                :=NULL;
        lc_success_flag                           :='N';
        IF lc_stlmt_hdr_tab(indx).transaction_type = 'Order' THEN
          lc_trx_type                             := 'SALE';
        ELSE
          lc_trx_type := 'REFUND';
        END IF;
        lc_store_number      := NULL;
        lc_split_order       := 'N';
        lc_aops_order_number := NULL;
        lc_action            := 'Deriving EBS Order Info for Unprocessed MPL Order';
        OPEN ordt_cur(lc_stlmt_hdr_tab(indx).order_id,lc_trx_type,lc_stlmt_hdr_tab(indx).provider_type);
        FETCH ordt_cur bulk collect INTO l_ordt_tab;
        CLOSE ordt_cur;
        IF l_ordt_tab.count     = 0 THEN
          lc_store_number      := Lc_def_store_number;--'010000';
          lc_aops_order_number := NULL;
          lc_order_payment_id  :=NULL;
          lc_success_flag      :='Y';
          --gc_failure_count     :=gc_failure_count+1;
        END IF;
        IF l_ordt_tab.count     = 1 THEN
          lc_store_number      := l_ordt_tab(1).store_number;
          lc_aops_order_number := l_ordt_tab(1).orig_sys_document_ref;
          lc_order_payment_id  :=l_ordt_tab(1).order_payment_id;
          lc_success_flag      :='Y';
          --gc_success_count     :=gc_success_count+1;
        END IF;
        IF l_ordt_tab.count IN (0,1) THEN
          UPDATE XX_CE_MPL_SETTLEMENT_HDR
          SET split_order       = lc_split_order,
            record_status       ='V',
            record_status_stage ='VALID',
            error_description   =NULL,
            request_id          =NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
            last_update_date    = sysdate,
            last_updated_by     = NVL(Fnd_Global.User_Id, -1),
            last_update_login   = NVL(Fnd_Global.User_Id, -1)
          WHERE 1               =1
          AND order_id          = lc_stlmt_hdr_tab(indx).order_id
          AND marketplace_name  =lc_stlmt_hdr_tab(indx).marketplace_name
          AND mpl_header_id     =lc_stlmt_hdr_tab(indx).mpl_header_id;
          UPDATE XX_CE_MPL_SETTLEMENT_DTL
          SET record_status    ='V',
            order_payment_id   =lc_order_payment_id,
            store_number       =lc_store_number,
            aops_order_number  =lc_aops_order_number,
            error_description  =NULL,
            request_id         =NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
            last_update_date   = sysdate,
            last_updated_by    = NVL(Fnd_Global.User_Id, -1),
            last_update_login  = NVL(Fnd_Global.User_Id, -1)
          WHERE 1              =1
          AND order_id         = lc_stlmt_hdr_tab(indx).order_id
          AND marketplace_name =lc_stlmt_hdr_tab(indx).marketplace_name
          AND mpl_header_id    =lc_stlmt_hdr_tab(indx).mpl_header_id;
        END IF;
        IF l_ordt_tab.count > 1 THEN
          lc_split_order   := 'Y';
          FOR rec_dtl IN cur_XX_CE_MPL_SETTLEMENT_dtl(lc_stlmt_hdr_tab(indx).order_id,lc_stlmt_hdr_tab(indx).mpl_header_id,lc_stlmt_hdr_tab(indx).marketplace_name)
          LOOP
            lc_store_number      := NULL;
            lc_aops_order_number := NULL;
            OPEN ordt1_cur(lc_stlmt_hdr_tab(indx).order_id,lc_trx_type,lc_stlmt_hdr_tab(indx).provider_type,rec_dtl.merchant_order_item_id);
            FETCH ordt1_cur bulk collect INTO l_ordt1_tab;
            CLOSE ordt1_cur;
            IF l_ordt1_tab.count = 0 THEN
              --If no record found in ORDT then default to store 010000
              lc_store_number      := Lc_def_store_number;--'010000';
              lc_aops_order_number := NULL;
              lc_order_payment_id  :=NULL;
              -- gc_failure_count     :=gc_failure_count+1;
              UPDATE XX_CE_MPL_SETTLEMENT_HDR
              SET split_order       = lc_split_order,
                record_status       ='V',
                record_status_stage ='VALID',
                error_description   =NULL,
                request_id          =NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
                last_update_date    = sysdate,
                last_updated_by     = NVL(Fnd_Global.User_Id, -1),
                last_update_login   = NVL(Fnd_Global.User_Id, -1)
              WHERE 1               =1
              AND order_id          = lc_stlmt_hdr_tab(indx).order_id
              AND marketplace_name  =lc_stlmt_hdr_tab(indx).marketplace_name
              AND mpl_header_id     =lc_stlmt_hdr_tab(indx).mpl_header_id;
              UPDATE XX_CE_MPL_SETTLEMENT_DTL
              SET record_status         ='V',
                order_payment_id        =lc_order_payment_id,
                store_number            =lc_store_number,
                aops_order_number       =lc_aops_order_number,
                error_description       =NULL,
                request_id              =NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
                last_update_date        = sysdate,
                last_updated_by         = NVL(Fnd_Global.User_Id, -1),
                last_update_login       = NVL(Fnd_Global.User_Id, -1)
              WHERE 1                   =1
              AND order_id              = lc_stlmt_hdr_tab(indx).order_id
              AND marketplace_name      =lc_stlmt_hdr_tab(indx).marketplace_name
              AND mpl_header_id         =lc_stlmt_hdr_tab(indx).mpl_header_id
              AND merchant_order_item_id=rec_dtl.merchant_order_item_id ;
            END IF;
            IF l_ordt1_tab.count = 1 THEN
              lc_success_flag   :='Y';
              -- gc_success_count     :=gc_success_count+1;
              lc_store_number      := l_ordt1_tab(1).store_number;
              lc_aops_order_number := l_ordt1_tab(1).orig_sys_document_ref;
              lc_order_payment_id  :=l_ordt1_tab(1).order_payment_id;
              UPDATE XX_CE_MPL_SETTLEMENT_HDR
              SET split_order       = lc_split_order,
                record_status       ='V',
                record_status_stage ='VALID',
                error_description   =NULL,
                request_id          =NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
                last_update_date    = sysdate,
                last_updated_by     = NVL(Fnd_Global.User_Id, -1),
                last_update_login   = NVL(Fnd_Global.User_Id, -1)
              WHERE 1               =1
              AND order_id          = lc_stlmt_hdr_tab(indx).order_id
              AND marketplace_name  =lc_stlmt_hdr_tab(indx).marketplace_name
              AND mpl_header_id     =lc_stlmt_hdr_tab(indx).mpl_header_id;
              UPDATE XX_CE_MPL_SETTLEMENT_DTL
              SET record_status         ='V',
                order_payment_id        =lc_order_payment_id,
                store_number            =lc_store_number,
                aops_order_number       =lc_aops_order_number,
                error_description       =NULL,
                request_id              =NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
                last_update_date        = sysdate,
                last_updated_by         = NVL(Fnd_Global.User_Id, -1),
                last_update_login       = NVL(Fnd_Global.User_Id, -1)
              WHERE 1                   =1
              AND order_id              = lc_stlmt_hdr_tab(indx).order_id
              AND marketplace_name      =lc_stlmt_hdr_tab(indx).marketplace_name
              AND mpl_header_id         =lc_stlmt_hdr_tab(indx).mpl_header_id
              AND merchant_order_item_id=rec_dtl.merchant_order_item_id ;
            END IF;
          END LOOP;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        lc_err_msg :=SUBSTR('ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' ||sqlerrm,1,1000);
        UPDATE XX_CE_MPL_SETTLEMENT_HDR
        SET split_order = lc_split_order,
          record_status ='E',
          --record_status_stage ='ERROR',
          error_description  =lc_err_msg,
          request_id         =NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
          last_update_date   = sysdate,
          last_updated_by    = NVL(Fnd_Global.User_Id, -1),
          last_update_login  = NVL(Fnd_Global.User_Id, -1)
        WHERE 1              =1
        AND order_id         = lc_stlmt_hdr_tab(indx).order_id
        AND marketplace_name =lc_stlmt_hdr_tab(indx).marketplace_name
        AND mpl_header_id    =lc_stlmt_hdr_tab(indx).mpl_header_id ;
        UPDATE XX_CE_MPL_SETTLEMENT_DTL
        SET record_status    ='E',
          error_description  =lc_err_msg,
          settlement_id      =NULL,
          request_id         =NVL(FND_GLOBAL.CONC_REQUEST_ID, -1),
          last_update_date   = sysdate,
          last_updated_by    = NVL(Fnd_Global.User_Id, -1),
          last_update_login  = NVL(Fnd_Global.User_Id, -1)
        WHERE 1              =1
        AND order_id         = lc_stlmt_hdr_tab(indx).order_id
        AND marketplace_name =lc_stlmt_hdr_tab(indx).marketplace_name
        AND mpl_header_id    =lc_stlmt_hdr_tab(indx).mpl_header_id;
        COMMIT;
      END;
      COMMIT;
      IF lc_success_flag  ='Y' THEN
        gc_success_count :=gc_success_count+1;
      ELSE
        gc_failure_count:=gc_failure_count+1;
      END IF;
    END LOOP;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
END DERIVE_MPL_ORDER_INFO;

/**********************************************************************************
* Procedure to process NEWEGG MP at different levels.
*this procedure is main procedure for  NEWEGG MP and calls all sub procedures.
* This procedure is called by Main Procedure.
***********************************************************************************/
PROCEDURE PROCESS_NEWEGG_PRESTG_DATA(
    p_process_name IN VARCHAR2 )
IS
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'PROCESS_NEWEGG_PRESTG_DATA';
  lt_parameters gt_input_parameters;
  lc_action VARCHAR2(1000);
  lc_settlement_end_date xx_ce_mpl_settlement_hdr.settlement_end_date%TYPE;
  lc_ce_mpl_settlement_dtl xx_ce_mpl_settlement_dtl%rowtype;
  lc_ce_mpl_settlement_hdr xx_ce_mpl_settlement_hdr%rowtype;
  lc_settlement_start_date xx_ce_mpl_settlement_hdr.settlement_start_date%TYPE;
  lc_currency VARCHAR2(15);
  lc_start_date xx_ce_mpl_settlement_hdr.settlement_start_date%TYPE;
  lc_end_date xx_ce_mpl_settlement_hdr.settlement_start_date%TYPE;
  lc_settlement_id xx_ce_mpl_settlement_dtl.settlement_id%TYPE;
  lc_quantity_purchased      VARCHAR2(25);
  lc_unit_price              NUMBER;
  lc_price_type              VARCHAR2(50);
  l_price_amount             VARCHAR2(25);
  lc_item_related_fee_type   VARCHAR2(50);
  lc_item_related_fee_amount VARCHAR2(25);
  l_rec_cnt                  NUMBER := 0;
  lc_mpl_header_id xx_ce_mpl_settlement_dtl.mpl_header_id%TYPE;
  lc_error_flag VARCHAR2(1)                      := 'N';
  lc_err_msg xx_ce_ebay_trx_dtl_stg.err_msg%TYPE := NULL;
  lc_transaction_type xx_ce_mpl_settlement_hdr.transaction_type%TYPE;
  lv_deposit_date       DATE;
  lv_newegg_file_status VARCHAR2(1) := 'N';
  CURSOR cur_newegg_settlement_files
  IS
    SELECT filename,
      settlement_id_neggs,
      TO_DATE( SUBSTR( settlement_date, 1, 10 ), 'MM/DD/YYYY' ) settlement_date,
      TO_DATE( SUBSTR( settlement_date_from, 1, 10 ), 'MM/DD/YYYY' ) settlement_date_from
    FROM xx_ce_newegg_sum_pre_stg_v negg
    WHERE 1                = 1
    AND negg.process_flag IN ( 'N','E' )
    GROUP BY filename,
      settlement_id_neggs,
      settlement_date,
      settlement_date_from;
  CURSOR cur_settlement_pre_stage_hdr ( p_filename VARCHAR2, p_newegg_settlmnt_id VARCHAR2 )
  IS
    SELECT DISTINCT order_id orderid,
      transaction_type transaction_type
    FROM xx_ce_newegg_tran_pre_stg_v hdr,
      xx_ce_newegg_sum_pre_stg_v sttl
    WHERE 1                      = 1
    AND sttl.filename            = p_filename
    AND sttl.settlement_id_neggs = p_newegg_settlmnt_id
    AND hdr.settlement_id_negg   = sttl.settlement_id_neggs
    AND sttl.process_flag       IN ( 'N','E' )
    AND hdr.process_flag        IN ( 'N','E' )
    AND transaction_type        IN ( 'Order','Refund' );
  CURSOR dup_check_cur ( lc_settlement_id NUMBER )
  IS
    SELECT settlement_id
    FROM xx_ce_mpl_settlement_hdr
    WHERE settlement_id = lc_settlement_id
    AND ROWNUM          < 2;
  CURSOR cur_settlement_pre_stage_dtl ( p_newegg_orderid VARCHAR2, p_transaction_type VARCHAR2,  p_newegg_settlmnt_id VARCHAR2 )
  IS
    SELECT tdr.*
    FROM xx_ce_newegg_tran_pre_stg_v tdr
    WHERE 1                     = 1
    AND tdr.order_id            = p_newegg_orderid
    AND tdr.transaction_type   IN ( p_transaction_type,'Sales Tax' )
    AND tdr.process_flag       IN ( 'N','E' )
    AND tdr.settlement_id_negg  = p_newegg_settlmnt_id;
  lv_line_tax_flag VARCHAR2(1) := 'N';
BEGIN
  lt_parameters('p_process_name') := p_process_name;
  entering_sub( p_procedure_name => lc_procedure_name, p_parameters => lt_parameters );
  lc_action := 'Deriving Translation Details for NEWEGG MPL';
  FOR rec_file IN cur_newegg_settlement_files
  LOOP
    logit( p_message => 'Processing NEWEGG MPL Settlement File-' || rec_file.filename );
    lc_action                := 'Deriving Settlement Start Date and Settlement End Date';
    lc_settlement_start_date := rec_file.settlement_date_from;
    lc_settlement_end_date   := rec_file.settlement_date;
    logit( p_message => 'Settlement Start Date Derived for FileNanme-' || rec_file.filename || 'is ' || lc_settlement_start_date );
    logit( p_message => 'Settlement End Date Derived for FileNanme-' || rec_file.filename || 'is ' || lc_settlement_end_date );
    lc_action             := 'Deriving Settlement Id';
    lv_newegg_file_status := 'N';
    SELECT xx_ce_mpl_settlement_id_s.NEXTVAL INTO lc_settlement_id FROM dual;
    lc_action := 'Validating Duplicate Settlement Id';
    FOR j IN dup_check_cur(lc_settlement_id)
    LOOP
      l_rec_cnt := l_rec_cnt + 1;
    END LOOP;
    IF l_rec_cnt > 0 THEN
      exiting_sub( p_procedure_name => lc_procedure_name, p_exception_flag => true );
      logit( p_message => 'Settlement Can not be processed ,Duplicate Settlement id found in staging table-XX_CE_MPL_SETTLEMENT_HDR ' || lc_settlement_id );
      raise_application_error( -20101, 'ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || sqlerrm );
    END IF;
    FOR rec_hdr IN cur_settlement_pre_stage_hdr( rec_file.filename, rec_file.settlement_id_neggs )
    LOOP
      BEGIN
        logit( p_message => 'Processing NEWEGG Order Id-' || rec_hdr.orderid || ' -Transaction_type-' || rec_hdr.transaction_type );
        lc_action                  := 'Processing NEWEGG PreStage Header Data for OrderID#' || rec_hdr.orderid;
        lc_err_msg                 := NULL;
        lc_transaction_type        := NULL;
        lv_line_tax_flag           := 'N';
        IF rec_hdr.transaction_type = 'Order' THEN
          lc_transaction_type      := 'Order';
        ELSE
          lc_transaction_type := 'Adjustment';
        END IF;
        SELECT xx_ce_mpl_header_id_seq.NEXTVAL INTO lc_mpl_header_id FROM dual;
        IF dup_check_transaction_type( p_process_name, rec_hdr.orderid, lc_transaction_type ) = 'N' THEN

          FOR rec_dtl IN cur_settlement_pre_stage_dtl( rec_hdr.orderid, rec_hdr.transaction_type,  rec_file.settlement_id_neggs )
          LOOP
            lc_action := 'Processing NEWEGG PreStage Detail Data';
            BEGIN
              lc_ce_mpl_settlement_dtl                              := NULL;
              lc_ce_mpl_settlement_dtl.mpl_header_id                := lc_mpl_header_id;
              lc_ce_mpl_settlement_dtl.marketplace_name             := p_process_name;
              lc_ce_mpl_settlement_dtl.order_id                     := rec_dtl.order_id;
              lc_ce_mpl_settlement_dtl.settlement_id                := lc_settlement_id;
              lc_ce_mpl_settlement_dtl.transaction_id               := rec_dtl.invoice_id;
              lc_ce_mpl_settlement_dtl.adjustment_id                := NULL;
              lc_ce_mpl_settlement_dtl.shipment_id                  := NULL;
              lc_ce_mpl_settlement_dtl.shipment_fee_type            := NULL;
              lc_ce_mpl_settlement_dtl.shipment_fee_amount          := NULL;
              lc_ce_mpl_settlement_dtl.order_fee_type               := NULL;
              lc_ce_mpl_settlement_dtl.order_fee_amount             := NULL;
              lc_ce_mpl_settlement_dtl.aops_order_number            := NULL;
              lc_ce_mpl_settlement_dtl.fulfillment_id               := NULL;
              lc_ce_mpl_settlement_dtl.order_item_code              := rec_dtl.seller_part_number;
              lc_ce_mpl_settlement_dtl.merchant_order_item_id       := rec_dtl.seller_part_number;
              lc_ce_mpl_settlement_dtl.merchant_adjustment_item_id  := NULL;
              lc_ce_mpl_settlement_dtl.sku                          := rec_dtl.newegg_item_number;
              lc_ce_mpl_settlement_dtl.misc_fee_amount              := NULL;
              lc_ce_mpl_settlement_dtl.other_fee_amount             := NULL;
              lc_ce_mpl_settlement_dtl.other_fee_reason_description := NULL;
              lc_ce_mpl_settlement_dtl.promotion_id                 := NULL;
              lc_ce_mpl_settlement_dtl.promotion_type               := NULL;
              lc_ce_mpl_settlement_dtl.promotion_amount             := NULL;
              lc_ce_mpl_settlement_dtl.direct_payment_type          := NULL;
              lc_ce_mpl_settlement_dtl.direct_payment_amount        := NULL;
              lc_ce_mpl_settlement_dtl.other_amount                 := NULL;
              lc_ce_mpl_settlement_dtl.store_number                 := NULL;
              lc_ce_mpl_settlement_dtl.record_status                := 'N';
              lc_ce_mpl_settlement_dtl.error_description            := NULL;
              lc_ce_mpl_settlement_dtl.request_id                   := NVL( fnd_global.conc_request_id, -1 );
              lc_ce_mpl_settlement_dtl.created_by                   := NVL( fnd_global.user_id,         -1 );
              lc_ce_mpl_settlement_dtl.creation_date                := SYSDATE;
              lc_ce_mpl_settlement_dtl.last_updated_by              := NVL( fnd_global.user_id, -1 );
              lc_ce_mpl_settlement_dtl.last_update_date             := SYSDATE;
              lc_ce_mpl_settlement_dtl.last_update_login            := NVL( fnd_global.user_id, -1 );
              lc_ce_mpl_settlement_dtl.attribute1                   := rec_dtl.order_id;

			  if rec_dtl.transaction_type != 'Sales Tax' then
              FOR j IN 1..3
              LOOP
                lc_action                  := 'Generate  NEWEGG Record into Multiple Transactions';
                lc_quantity_purchased      := NULL;
                lc_unit_price              := NULL;
                lc_price_type              := NULL;
                l_price_amount             := NULL;
                lc_item_related_fee_type   := NULL;
                lc_item_related_fee_amount := NULL;

                IF j                          = 1 THEN
                  lc_action      := 'Generate NEWEGG Record for Principal Price Type';
                  lc_price_type  := 'Principal';
                  l_price_amount := NVL(rec_dtl.amount,0);
                END IF;
                IF j                          = 2 THEN
                  lc_action                   := 'Generate NEWEGG Record for Shipping Price Type';
                  lc_price_type               := 'Shipping';
				  l_price_amount := NVL(rec_dtl.shipping,0);

                END IF;
                IF j                          =3 THEN
                  lc_action                  := 'Generate NEWEGG Record for Sales,Tax,Service Fee Price Type';
                  lc_item_related_fee_type   := 'Commission';
                  lc_item_related_fee_amount := NVL( rec_dtl.commission_fee, 0 ) *-1;
                END IF;

                lc_ce_mpl_settlement_dtl.quantity_purchased      := lc_quantity_purchased;
                lc_ce_mpl_settlement_dtl.unit_price              := lc_unit_price;
                lc_ce_mpl_settlement_dtl.price_type              := lc_price_type;
                lc_ce_mpl_settlement_dtl.price_amount            := l_price_amount;
                lc_ce_mpl_settlement_dtl.item_related_fee_type   := lc_item_related_fee_type;
                lc_ce_mpl_settlement_dtl.item_related_fee_amount := lc_item_related_fee_amount;
                INSERT INTO xx_ce_mpl_settlement_dtl VALUES lc_ce_mpl_settlement_dtl;

              END LOOP;

			  end if;

			  if rec_dtl.transaction_type = 'Sales Tax' THEN
			    lc_quantity_purchased      := NULL;
                lc_unit_price              := NULL;
                lc_price_type              := NULL;
                l_price_amount             := NULL;
                lc_item_related_fee_type   := NULL;
                lc_item_related_fee_amount := NULL;
				lc_action      := 'Generate NEWEGG Record for Tax Type';
                lc_price_type  := 'Tax';
                l_price_amount := NVL(rec_dtl.amount,0);
                lc_ce_mpl_settlement_dtl.quantity_purchased      := lc_quantity_purchased;
                lc_ce_mpl_settlement_dtl.unit_price              := lc_unit_price;
                lc_ce_mpl_settlement_dtl.price_type              := lc_price_type;
                lc_ce_mpl_settlement_dtl.price_amount            := l_price_amount;
                lc_ce_mpl_settlement_dtl.item_related_fee_type   := lc_item_related_fee_type;
                lc_ce_mpl_settlement_dtl.item_related_fee_amount := lc_item_related_fee_amount;
                INSERT INTO xx_ce_mpl_settlement_dtl VALUES lc_ce_mpl_settlement_dtl;
			  end if;



            EXCEPTION
            WHEN OTHERS THEN
              raise_application_error( -20101, 'PROCEDURE: ' || lc_procedure_name || ' ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || sqlerrm );
            END;
          END LOOP; --DTL Cursor
          lc_action                                      := 'Insert into XX_CE_MPL_SETTLEMENT_HDR Table for NEWEGG OrderId#-' || rec_hdr.orderid;
          lc_ce_mpl_settlement_hdr                       := NULL;
          lc_ce_mpl_settlement_hdr.mpl_header_id         := lc_mpl_header_id;
          lc_ce_mpl_settlement_hdr.provider_type         := lt_translation_info.target_value14;
          lc_ce_mpl_settlement_hdr.settlement_id         := lc_settlement_id;
          lc_ce_mpl_settlement_hdr.settlement_start_date := TO_DATE( TO_CHAR( lc_settlement_start_date, 'YYYY-MM-DD' ), 'YYYY-MM-DD' );
          lc_ce_mpl_settlement_hdr.settlement_end_date   := TO_DATE( TO_CHAR( lc_settlement_end_date, 'YYYY-MM-DD' ), 'YYYY-MM-DD' );
          lc_ce_mpl_settlement_hdr.total_amount          := NULL;
          lc_ce_mpl_settlement_hdr.order_id              := rec_hdr.orderid;
          lc_ce_mpl_settlement_hdr.merchant_order_id     := rec_hdr.orderid;
          lc_ce_mpl_settlement_hdr.deposit_date          := TO_DATE( TO_CHAR( TO_DATE( lc_settlement_end_date, 'DD-MM-YY' ), 'DD-MM-YYYY' ), 'DD-MM-YYYY' );
          lc_ce_mpl_settlement_hdr.currency              := NULL;
          IF rec_hdr.transaction_type                     = 'Order' THEN
            lc_ce_mpl_settlement_hdr.transaction_type    := 'Order';
          ELSE
            lc_ce_mpl_settlement_hdr.transaction_type := 'Adjustment';
          END IF;
          lc_ce_mpl_settlement_hdr.marketplace_name    := p_process_name;
          lc_ce_mpl_settlement_hdr.split_order         := NULL;
          lc_ce_mpl_settlement_hdr.processor_id        := lt_translation_info.target_value13;
          lc_ce_mpl_settlement_hdr.posted_date         := TO_CHAR( lc_settlement_end_date, 'YYYY-MM-DD' );
          lc_ce_mpl_settlement_hdr.ajb_998_amount      := NULL;
          lc_ce_mpl_settlement_hdr.ajb_999_amount      := NULL;
          lc_ce_mpl_settlement_hdr.ajb_996_amount      := NULL;
          lc_ce_mpl_settlement_hdr.terminal_number     := NULL;
          lc_ce_mpl_settlement_hdr.card_number         := NULL;
          lc_ce_mpl_settlement_hdr.auth_number         := NULL;
          lc_ce_mpl_settlement_hdr.action              := NULL;
          lc_ce_mpl_settlement_hdr.record_status       := 'N';
          lc_ce_mpl_settlement_hdr.record_status_stage := 'NEW';
          lc_ce_mpl_settlement_hdr.error_description   := NULL;
          lc_ce_mpl_settlement_hdr.request_id          := NVL( fnd_global.conc_request_id, -1 );
          lc_ce_mpl_settlement_hdr.created_by          := NVL( fnd_global.user_id,         -1 );
          lc_ce_mpl_settlement_hdr.creation_date       := SYSDATE;
          lc_ce_mpl_settlement_hdr.last_updated_by     := NVL( fnd_global.user_id, -1 );
          lc_ce_mpl_settlement_hdr.last_update_date    := SYSDATE;
          lc_ce_mpl_settlement_hdr.last_update_login   := NVL( fnd_global.user_id, -1 );
          lc_ce_mpl_settlement_hdr.ajb_file_name       := rec_file.filename || '_' || rec_file.settlement_id_neggs || '_' || lc_settlement_id;
          INSERT INTO xx_ce_mpl_settlement_hdr VALUES lc_ce_mpl_settlement_hdr;
          UPDATE xx_ce_newegg_tran_pre_stg_v a
          SET a.process_flag       = 'P',
            a.err_msg              = NULL
          WHERE a.order_id         = rec_hdr.orderid
          AND a.process_flag      IN ( 'N','E' )
          AND a.transaction_type  IN ( rec_hdr.transaction_type,'Sales Tax' )
          AND a.settlement_id_negg = rec_file.settlement_id_neggs;
          gc_success_count        := gc_success_count + 1;
        ELSE
          lv_newegg_file_status := 'Y';
          UPDATE xx_ce_newegg_tran_pre_stg_v a
          SET a.process_flag       = 'E',
            a.err_msg              = 'Duplicate record found for NEWEGG OrderID#'
          WHERE a.order_id         = rec_hdr.orderid
          AND a.process_flag      IN ( 'N','E' )
          AND a.transaction_type  IN ( rec_hdr.transaction_type,'Sales Tax' )
          AND a.settlement_id_negg = rec_file.settlement_id_neggs;
          gc_failure_count        := gc_failure_count + 1;
        END IF;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        gc_failure_count      := gc_failure_count + 1;
        lv_newegg_file_status := 'Y';
        lc_err_msg            := SUBSTR( 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || sqlerrm, 1, 1000 );
        UPDATE xx_ce_newegg_tran_pre_stg_v a
        SET a.process_flag       = 'E',
          a.err_msg              = lc_err_msg
        WHERE a.order_id         = rec_hdr.orderid
        AND a.process_flag      IN ( 'N','E' )
        AND a.transaction_type   = rec_hdr.transaction_type
        AND a.settlement_id_negg = rec_file.settlement_id_neggs;
        COMMIT;
      END;
    END LOOP; --HDR Cursor
    IF lv_newegg_file_status = 'Y' THEN
      UPDATE xx_ce_newegg_sum_pre_stg_v a
      SET a.process_flag        = 'E',
        a.err_msg               = 'Few of the transactions failed processing for this Settlement.'
      WHERE settlement_id_neggs = rec_file.settlement_id_neggs
      AND filename              = rec_file.filename;
      COMMIT;
    ELSE
      UPDATE xx_ce_newegg_sum_pre_stg_v a
      SET a.process_flag        = 'P',
        a.err_msg               = NULL
      WHERE settlement_id_neggs = rec_file.settlement_id_neggs
      AND filename              = rec_file.filename;
      COMMIT;
    END IF;
  END LOOP;
  exiting_sub( p_procedure_name => lc_procedure_name, p_exception_flag => true );
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  raise_application_error( -20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || sqlerrm );
END PROCESS_NEWEGG_PRESTG_DATA;


/**********************************************************************************
* Procedure to process Rakuten MP at different levels.
*this procedure is main procedure for Rakuten MP and calls all sub procedures.
* This procedure is called by Main Procedure.
***********************************************************************************/
PROCEDURE PROCESS_RAKUTEN_PRESTG_DATA(
    p_process_name IN VARCHAR2)
IS
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'PROCESS_RAKUTEN_PRESTG_DATA';
  lt_parameters gt_input_parameters;
  lc_action VARCHAR2(1000);
  lc_ce_mpl_settlement_dtl XX_CE_MPL_SETTLEMENT_DTL%ROWTYPE;
  lc_ce_mpl_settlement_hdr XX_CE_MPL_SETTLEMENT_HDR%ROWTYPE;
  lc_settlement_start_date XX_CE_MPL_SETTLEMENT_HDR.settlement_start_date%type ;
  lc_settlement_end_date XX_CE_MPL_SETTLEMENT_HDR.settlement_end_date%type ;
  lc_currency VARCHAR2(15);
  lc_start_date XX_CE_MPL_SETTLEMENT_HDR.settlement_start_date%type ;
  lc_end_date XX_CE_MPL_SETTLEMENT_HDR.settlement_start_date%type ;
  lc_settlement_id XX_CE_MPL_SETTLEMENT_DTL.settlement_id%type;
  lc_quantity_purchased      VARCHAR2(25);
  lc_unit_price              NUMBER;
  lc_price_type              VARCHAR2(50);
  l_price_amount             VARCHAR2(25);
  lc_item_related_fee_type   VARCHAR2(50);
  lc_item_related_fee_amount VARCHAR2(25);
  l_rec_cnt                  NUMBER := 0;
  lc_mpl_header_id XX_CE_MPL_SETTLEMENT_DTL.mpl_header_id%type;
  lc_error_flag VARCHAR2(1)                     :='N';
  lc_err_msg xx_ce_ebay_trx_dtl_stg.err_msg%type:=NULL;
  lc_transaction_type XX_CE_MPL_SETTLEMENT_HDR.transaction_type%type;
  lv_deposit_date DATE;
  CURSOR cur_rakuten_settlement_files
  IS
    SELECT DISTINCT filename,
      to_date(TO_CHAR(MIN(to_date(trandate,'MM/DD/YYYY HH:MI:SS AM')),'MM/DD/YYYY'),'MM/DD/YYYY') transaction_start_date,
      to_date(TO_CHAR(MAX(to_date(trandate,'MM/DD/YYYY HH:MI:SS AM')),'MM/DD/YYYY'),'MM/DD/YYYY') transaction_end_date
    FROM xx_ce_rakuten_pre_stg_v rakv
    WHERE 1                =1
    AND rakv.process_flag IN ('N','E')
    GROUP BY filename;
  CURSOR cur_settlement_pre_stage_hdr(p_filename VARCHAR2)
  IS
    SELECT DISTINCT orderid,
      trantype transaction_type
    FROM xx_ce_rakuten_pre_stg_v hdr
    WHERE 1               =1
    AND hdr.filename      =p_filename
    AND hdr.process_flag IN ('N','E')
	and orderid is not null;
  CURSOR dup_check_cur(lc_settlement_id NUMBER)
  IS
    SELECT settlement_id
    FROM XX_CE_MPL_SETTLEMENT_HDR
    WHERE settlement_id = lc_settlement_id
    AND rownum          < 2 ;
  CURSOR cur_settlement_pre_stage_dtl(p_rakuten_orderid VARCHAR2,p_transaction_type VARCHAR2 )
  IS
    SELECT *
    FROM xx_ce_rakuten_pre_stg_v tdr
    WHERE 1               =1
    AND tdr.orderid       =p_rakuten_orderid
    AND tdr.trantype      =p_transaction_type
    AND tdr.process_flag IN ('N','E') ;
BEGIN
  lt_parameters('p_process_name') := p_process_name;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);
  lc_action := 'Deriving Translation Details for Rakuten MPL';
  FOR rec_file IN cur_rakuten_settlement_files
  LOOP
    logit(p_message => 'Processing Rakuten MPL TRR File-' ||rec_file.filename);
    lc_action               := 'Deriving Settlement Start Date and Settlement End Date';
    lc_settlement_start_date:=rec_file.transaction_start_date;
    lc_settlement_end_date  :=rec_file.transaction_end_date;
    logit(p_message => 'Settlement Start Date Derived for FileNanme-' ||rec_file.filename||'is '||lc_settlement_start_date);
    logit(p_message => 'Settlement End Date Derived for FileNanme-' ||rec_file.filename||'is '||lc_settlement_end_date);
    lc_action := 'Deriving Settlement Id';
   /* BEGIN --Derive Bank Rec ID
      logit(p_message => 'Deposit Date before procedure call '||lc_settlement_end_date);
      DERIVE_BANK_DEPOSIT_DATE(p_process_name,lc_settlement_end_date,lv_deposit_date);
      logit(p_message => 'Deposit Date after procedure call '||lv_deposit_date);
    EXCEPTION
    WHEN OTHERS THEN
      lv_deposit_date:=lc_settlement_end_date;
      logit(p_message => 'Error Occured in PROCEDURE to derive Bank Deposit Date-' ||lc_procedure_name|| ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
    END; */
    SELECT xx_ce_mpl_settlement_id_s.nextval INTO lc_settlement_id FROM dual;
    Lc_Action := 'Validating Duplicate Settlement Id';
    FOR j IN dup_check_cur(lc_settlement_id)
    LOOP
      l_rec_cnt := l_rec_cnt + 1;
    END LOOP;
    IF L_Rec_Cnt > 0 THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      logit(p_message => 'Settlement Can not be processed , Duplicate Settlement id found in staging table-XX_CE_MPL_SETTLEMENT_HDR '||lc_settlement_id);
      RAISE_APPLICATION_ERROR(-20101, 'ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
    END IF;
    FOR rec_hdr IN cur_settlement_pre_stage_hdr(rec_file.filename)
    LOOP
      BEGIN
        lc_action                 := 'Processing Rakuten PreStage Header Data for OrderID#'||rec_hdr.orderid;
        lc_err_msg                :=NULL;
        lc_transaction_type       :=NULL;
        IF rec_hdr.transaction_type='Payment' THEN
          lc_transaction_type     :='Order';
        ELSE
          lc_transaction_type:='Adjustment';
        END IF;
        SELECT XX_CE_MPL_HEADER_ID_SEQ.nextval INTO lc_mpl_header_id FROM dual;
        IF dup_check_transaction_type(p_process_name,rec_hdr.orderid,lc_transaction_type)='N' THEN
          FOR rec_dtl IN cur_settlement_pre_stage_dtl(rec_hdr.orderid,rec_hdr.transaction_type )
          LOOP
            lc_action := 'Processing Rakuten PreStage Detail Data';
            BEGIN
              lc_ce_mpl_settlement_dtl                              :=NULL;
              lc_ce_mpl_settlement_dtl.mpl_header_id                := lc_mpl_header_id;
              lc_ce_mpl_settlement_dtl.marketplace_name             :=p_process_name;
              lc_ce_mpl_settlement_dtl.order_id                     := rec_dtl.orderid ;
              lc_ce_mpl_settlement_dtl.settlement_id                := lc_settlement_id ;
              lc_ce_mpl_settlement_dtl.transaction_id               := rec_dtl.invoiceid;
              lc_ce_mpl_settlement_dtl.adjustment_id                := NULL;
              lc_ce_mpl_settlement_dtl.shipment_id                  := NULL ;
              lc_ce_mpl_settlement_dtl.shipment_fee_type            := NULL;
              lc_ce_mpl_settlement_dtl.shipment_fee_amount          := NULL;
              lc_ce_mpl_settlement_dtl.order_fee_type               := NULL;
              lc_ce_mpl_settlement_dtl.order_fee_amount             := NULL;
              lc_ce_mpl_settlement_dtl.aops_order_number            :=NULL ;
              lc_ce_mpl_settlement_dtl.fulfillment_id               := NULL ;
              lc_ce_mpl_settlement_dtl.order_item_code              := rec_dtl.referenceid ;
              lc_ce_mpl_settlement_dtl.merchant_order_item_id       := rec_dtl.referenceid;
              lc_ce_mpl_settlement_dtl.merchant_adjustment_item_id  := NULL;
              lc_ce_mpl_settlement_dtl.sku                          := rec_dtl.referenceid;
              lc_ce_mpl_settlement_dtl.misc_fee_amount              := NULL;
              lc_ce_mpl_settlement_dtl.other_fee_amount             := NULL;
              lc_ce_mpl_settlement_dtl.other_fee_reason_description := NULL;
              lc_ce_mpl_settlement_dtl.promotion_id                 := NULL;
              lc_ce_mpl_settlement_dtl.promotion_type               := NULL;
              lc_ce_mpl_settlement_dtl.promotion_amount             := NULL;
              lc_ce_mpl_settlement_dtl.direct_payment_type          := NULL;
              lc_ce_mpl_settlement_dtl.direct_payment_amount        := NULL;
              lc_ce_mpl_settlement_dtl.other_amount                 := NULL;
              lc_ce_mpl_settlement_dtl.store_number                 := NULL;
              lc_ce_mpl_settlement_dtl.record_status                := 'N';
              lc_ce_mpl_settlement_dtl.error_description            := NULL;
              lc_ce_mpl_settlement_dtl.request_id                   :=NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);
              lc_ce_mpl_settlement_dtl.created_by                   := NVL(FND_GLOBAL.USER_ID,        -1);
              lc_ce_mpl_settlement_dtl.creation_date                := SYSDATE;
              lc_ce_mpl_settlement_dtl.last_updated_by              := NVL(FND_GLOBAL.USER_ID, -1);
              lc_ce_mpl_settlement_dtl.last_update_date             := SYSDATE;
              lc_ce_mpl_settlement_dtl.last_update_login            := NVL(FND_GLOBAL.USER_ID, -1);
              lc_ce_mpl_settlement_dtl.attribute1                   := rec_dtl.orderid;
              FOR j IN 1..4
              LOOP
                lc_action                 := 'Generate Rakuten Record into Multiple Transactions';
                lc_quantity_purchased     :=NULL;
                lc_unit_price             :=NULL;
                lc_price_type             :=NULL;
                l_price_amount            :=NULL;
                lc_item_related_fee_type  :=NULL;
                lc_item_related_fee_amount:=NULL;
                ---l_total_amount:=null;
                ---l_currency:=null;
                IF j         =1 THEN
                  lc_action := 'Generate Rakuten Record for Item';
                  --  logit(rec_dtl.qtyshipped);
                  lc_quantity_purchased :=NVL(rec_dtl.qtyshipped,0);
                  IF rec_dtl.qtyshipped  =0 THEN
                    lc_unit_price       :=0;
                  ELSE
                    lc_unit_price:=ROUND((rec_dtl.buyerpaid+rec_dtl.recyclefee)/rec_dtl.qtyshipped,2);
                  END IF;
                END IF;
                IF j              =2 THEN
                  lc_action      := 'Generate Rakuten Record for Principal Price Type';
                  lc_price_type  :='Principal';
                  l_price_amount :=rec_dtl.buyerpaid+rec_dtl.recyclefee;
                END IF;
                IF j              =3 THEN
                  lc_action      := 'Generate Rakuten Record for Sales Tax Service Price Type';
                  lc_price_type  :='Tax';
                  l_price_amount :=NVL(rec_dtl.SalesTax,0) ;
                END IF;
                IF j                          =4 THEN
                  lc_action                  := 'Generate Rakuten Record for Sales,Tax,Service Fee Price Type';
                  lc_item_related_fee_type   :='SalesTaxServiceFee';
                  lc_item_related_fee_amount :=NVL(rec_dtl.FeeTotal,0) ;
                END IF;
                lc_ce_mpl_settlement_dtl.quantity_purchased      := lc_quantity_purchased;
                lc_ce_mpl_settlement_dtl.unit_price              := lc_unit_price;
                lc_ce_mpl_settlement_dtl.price_type              := lc_price_type;
                lc_ce_mpl_settlement_dtl.price_amount            := l_price_amount;
                lc_ce_mpl_settlement_dtl.item_related_fee_type   := lc_item_related_fee_type;
                lc_ce_mpl_settlement_dtl.item_related_fee_amount := lc_item_related_fee_amount;
                INSERT INTO XX_CE_MPL_SETTLEMENT_DTL VALUES lc_ce_mpl_settlement_dtl;
              END LOOP;
            EXCEPTION
            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
            END;
          END LOOP; --DTL Cursor
          lc_action                                      := 'Insert into XX_CE_MPL_SETTLEMENT_HDR Table for Rakuten OrderId#-'||rec_hdr.orderid;
          Lc_Ce_Mpl_Settlement_Hdr                       :=NULL;
          lc_ce_mpl_settlement_hdr.mpl_header_id         :=lc_mpl_header_id;
          lc_ce_mpl_settlement_hdr.PROVIDER_TYPE         :=lt_translation_info.target_value14 ;
          lc_ce_mpl_settlement_hdr.settlement_id         :=lc_settlement_id ;
          lc_ce_mpl_settlement_hdr.settlement_start_date :=to_date(TO_CHAR(lc_settlement_start_date,'YYYY-MM-DD'),'YYYY-MM-DD') ;
          lc_ce_mpl_settlement_hdr.settlement_end_date   :=to_date(TO_CHAR(lc_settlement_end_date,'YYYY-MM-DD'),'YYYY-MM-DD') ;
          lc_ce_mpl_settlement_hdr.order_id              :=rec_hdr.orderid ;
          lc_ce_mpl_settlement_hdr.merchant_order_id     :=rec_hdr.orderid ;
          lc_ce_mpl_settlement_hdr.deposit_date          :=to_date(TO_CHAR(to_Date(lc_settlement_end_date,'DD-MM-YY'),'DD-MM-YYYY'),'DD-MM-YYYY');
          lc_ce_mpl_settlement_hdr.total_amount          :=NULL;
          lc_ce_mpl_settlement_hdr.currency              :=NULL;
          IF rec_hdr.transaction_type                     ='Payment' THEN
            lc_ce_mpl_settlement_hdr.transaction_type    :='Order';
          ELSE
            lc_ce_mpl_settlement_hdr.transaction_type :='Adjustment';
          END IF;
          lc_ce_mpl_settlement_hdr.marketplace_name    :=p_process_name;
          lc_ce_mpl_settlement_hdr.split_order         :=NULL;
          lc_ce_mpl_settlement_hdr.PROCESSOR_ID        := lt_translation_info.target_value13 ;
          lc_ce_mpl_settlement_hdr.posted_date         :=TO_CHAR(lc_settlement_end_date,'YYYY-MM-DD');
          lc_ce_mpl_settlement_hdr.ajb_998_amount      :=NULL;
          lc_ce_mpl_settlement_hdr.ajb_999_amount      :=NULL;
          lc_ce_mpl_settlement_hdr.ajb_996_amount      :=NULL;
          lc_ce_mpl_settlement_hdr.terminal_number     :=NULL;
          lc_ce_mpl_settlement_hdr.card_number         :=NULL;
          lc_ce_mpl_settlement_hdr.auth_number         :=NULL;
          lc_ce_mpl_settlement_hdr.action              :=NULL;
          lc_ce_mpl_settlement_hdr.record_status       :='N';
          lc_ce_mpl_settlement_hdr.record_status_stage :='NEW';
          lc_ce_mpl_settlement_hdr.error_description   :=NULL;
          lc_ce_mpl_settlement_hdr.request_id          :=NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);
          Lc_Ce_Mpl_Settlement_Hdr.Created_By          :=NVL(Fnd_Global.User_Id,         -1);
          Lc_Ce_Mpl_Settlement_Hdr.Creation_Date       :=Sysdate;
          Lc_Ce_Mpl_Settlement_Hdr.Last_Updated_By     :=NVL(Fnd_Global.User_Id, -1);
          lc_ce_mpl_settlement_hdr.last_update_date    :=SYSDATE;
          Lc_Ce_Mpl_Settlement_Hdr.Last_Update_Login   :=NVL(Fnd_Global.User_Id, -1);
          Lc_Ce_Mpl_Settlement_Hdr.ajb_file_name       :=rec_file.filename||lc_settlement_id;
          INSERT INTO XX_CE_MPL_SETTLEMENT_HDR VALUES lc_ce_mpl_settlement_hdr;
          UPDATE xx_ce_rakuten_pre_stg_v a
          SET a.process_flag  ='P',
            A.Err_Msg         =NULL
          WHERE A.orderid     =Rec_hdr.orderid
          AND a.process_flag IN ('N','E')
          AND a.trantype      =Rec_hdr.transaction_type;
          gc_success_count   :=gc_success_count+1;
        ELSE
          UPDATE xx_ce_rakuten_pre_stg_v a
          SET a.process_flag  ='E',
            A.Err_Msg         ='Duplicate record found for Rakuten OrderID#'
          WHERE A.orderid     =Rec_hdr.orderid
          AND a.process_flag IN ('N','E')
          AND a.trantype      =Rec_hdr.transaction_type;
          gc_failure_count   :=gc_failure_count+1;
        END IF;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        gc_failure_count:=gc_failure_count+1;
        lc_err_msg      :=SUBSTR('PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' ||sqlerrm,1,1000);
        UPDATE xx_ce_rakuten_pre_stg_v a
        SET a.process_flag  ='E' ,
          a.err_msg         =lc_err_msg
        WHERE a.orderid     =rec_hdr.orderid
        AND a.process_flag IN ('N','E')
        AND a.trantype      =Rec_hdr.transaction_type;
        COMMIT;
      END;
    END LOOP; --HDR Cursor
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
END PROCESS_RAKUTEN_PRESTG_DATA;
/**********************************************************************************
* Procedure to process Walmart MP at different levels.
*this procedure is main procedure for Walmart MP and calls all sub procedures.
* This procedure is called by MAIN_MPL_SETTLEMENT_PROCESS.
***********************************************************************************/
PROCEDURE PROCESS_WALMART_PRESTG_DATA(
    p_process_name IN VARCHAR2)
IS
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'PROCESS_WALMART_PRESTG_DATA';
  lt_parameters gt_input_parameters;
  lc_action VARCHAR2(1000);
  lc_ce_mpl_settlement_dtl XX_CE_MPL_SETTLEMENT_DTL%ROWTYPE;
  lc_ce_mpl_settlement_hdr XX_CE_MPL_SETTLEMENT_HDR%ROWTYPE;
  lc_settlement_start_date XX_CE_MPL_SETTLEMENT_HDR.settlement_start_date%type ;
  lc_settlement_end_date XX_CE_MPL_SETTLEMENT_HDR.settlement_end_date%type ;
  lc_currency VARCHAR2(15);
  lc_start_date XX_CE_MPL_SETTLEMENT_HDR.settlement_start_date%type ;
  lc_end_date XX_CE_MPL_SETTLEMENT_HDR.settlement_start_date%type ;
  lc_settlement_id XX_CE_MPL_SETTLEMENT_DTL.settlement_id%type;
  lc_quantity_purchased      VARCHAR2(25);
  lc_unit_price              NUMBER;
  lc_price_type              VARCHAR2(50);
  l_price_amount             VARCHAR2(25);
  lc_item_related_fee_type   VARCHAR2(50);
  lc_item_related_fee_amount VARCHAR2(25);
  l_rec_cnt                  NUMBER := 0;
  lc_mpl_header_id XX_CE_MPL_SETTLEMENT_DTL.mpl_header_id%type;
  lc_error_flag VARCHAR2(1)                     :='N';
  lc_err_msg xx_ce_ebay_trx_dtl_stg.err_msg%type:=NULL;
  lc_transaction_type XX_CE_MPL_SETTLEMENT_HDR.transaction_type%type;
  CURSOR cur_walmart_settlement_files
  IS
    SELECT DISTINCT filename,
      MIN(to_date(SUBSTR(transaction_Date_time,1,10),'MM/DD/YYYY')) transaction_start_date,
      MAX(to_date(SUBSTR(transaction_Date_time,1,10),'MM/DD/YYYY')) transaction_end_date,
      CAST(to_date(MAX(to_date(SUBSTR(transaction_Date_time,1,10),'MM/DD/YYYY')),'YYYY-MM-DD') AS DATE) posted_date
    FROM XX_CE_WALMART_PRE_STG_V wlmv
    WHERE 1                =1
    AND wlmv.process_flag IN ('N','E')
    GROUP BY filename;
  CURSOR cur_settlement_pre_stage_hdr(p_filename VARCHAR2)
  IS
    SELECT DISTINCT walmart_po,
      transaction_type
    FROM XX_CE_WALMART_PRE_STG_V hdr
    WHERE 1               =1
    AND hdr.filename      =p_filename
    AND hdr.process_flag IN ('N','E');
  CURSOR dup_check_cur(lc_settlement_id NUMBER)
  IS
    SELECT settlement_id
    FROM XX_CE_MPL_SETTLEMENT_HDR
    WHERE settlement_id = lc_settlement_id
    AND rownum          < 2;
  CURSOR cur_settlement_pre_stage_dtl(p_walmart_po VARCHAR2,p_transaction_type VARCHAR2 )
  IS
    SELECT tdr.WALMART_PO,
      tdr.WALMART_ORDER,
      tdr.transaction_type,
      tdr.PARTNER_ITEM_ID,
      SUM(NVL(SHIPPED_QTY,0)) SHIPPED_QTY,
      SUM(NVL(TOTAL_TENDER_CUSTOMER,0)) TOTAL_TENDER_CUSTOMER,
      SUM(NVL(COMMISSION_FROM_SALE,0)) COMMISSION_FROM_SALE
    FROM XX_CE_WALMART_PRE_STG_V tdr
    WHERE 1                 =1
    AND tdr.walmart_po      =p_walmart_po
    AND tdr.transaction_type=p_transaction_type
    AND tdr.process_flag   IN ('N','E')
    GROUP BY tdr.WALMART_PO,
      tdr.WALMART_ORDER,
      tdr.transaction_type,
      tdr.PARTNER_ITEM_ID;
  lv_deposit_date DATE;
BEGIN
  lt_parameters('p_process_name') := p_process_name;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);
  lc_action := 'Deriving Translation Details for Walmart MPL';
  FOR rec_file IN cur_walmart_settlement_files
  LOOP
    logit(p_message => 'Processing Walmart MPL Transaction File-' ||rec_file.filename);
    lc_settlement_start_date:=rec_file.transaction_start_date;
    lc_settlement_end_date  :=rec_file.transaction_end_date;
    lc_action               := 'Deriving Settlement Start Date and Settlement End Date';
    logit(p_message => 'RESULT Settlement Start_date: ' || TO_CHAR(lc_settlement_start_date,'YYYY-MM-DD'));
    logit(p_message => 'RESULT Settlement End_Date: ' || TO_CHAR(lc_settlement_end_date,'YYYY-MM-DD'));
    lc_action := 'Deriving Settlement Id';
   /* BEGIN --Derive Bank Rec ID
      DERIVE_BANK_DEPOSIT_DATE(p_process_name,lc_settlement_end_date,lv_deposit_date);
    EXCEPTION
    WHEN OTHERS THEN
      lv_deposit_date:=lc_settlement_end_date;
      logit(p_message => 'Error Occured in PROCEDURE to derive Bank Deposit Date-' ||lc_procedure_name|| ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
    END;*/
    SELECT xx_ce_mpl_settlement_id_s.nextval INTO lc_settlement_id FROM dual;
    Lc_Action := 'Validating Duplicate Settlement Id';
    FOR j IN dup_check_cur(lc_settlement_id)
    LOOP
      l_rec_cnt := l_rec_cnt + 1;
    END LOOP;
    IF L_Rec_Cnt > 0 THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      logit(p_message => 'Settlement Can not be processed , Duplicate Settlement id found in staging table-XX_CE_MPL_SETTLEMENT_HDR '||lc_settlement_id);
      RAISE_APPLICATION_ERROR(-20101, 'ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
    END IF;
    FOR rec_hdr IN cur_settlement_pre_stage_hdr(rec_file.filename)
    LOOP
      BEGIN
        lc_action                 := 'Processing Walmart PreStage Header Data for PO#'||rec_hdr.walmart_po;
        lc_err_msg                :=NULL;
        lc_transaction_type       :=NULL;
        IF rec_hdr.transaction_type='SALE' THEN
          lc_transaction_type     :='Order';
        ELSE
          lc_transaction_type:='Adjustment';
        END IF;
        SELECT XX_CE_MPL_HEADER_ID_SEQ.nextval INTO lc_mpl_header_id FROM dual;
        IF dup_check_transaction_type(p_process_name,rec_hdr.walmart_po,lc_transaction_type)='N' THEN
          FOR rec_dtl IN cur_settlement_pre_stage_dtl(rec_hdr.walmart_po,rec_hdr.transaction_type )
          LOOP
            lc_action := 'Processing Walmart PreStage Detail Data';
            BEGIN
              lc_ce_mpl_settlement_dtl                              :=NULL;
              lc_ce_mpl_settlement_dtl.mpl_header_id                := lc_mpl_header_id;
              lc_ce_mpl_settlement_dtl.marketplace_name             :=p_process_name;
              lc_ce_mpl_settlement_dtl.order_id                     := rec_dtl.WALMART_PO ;
              lc_ce_mpl_settlement_dtl.settlement_id                := lc_settlement_id ;
              lc_ce_mpl_settlement_dtl.transaction_id               := rec_dtl.WALMART_ORDER;
              lc_ce_mpl_settlement_dtl.adjustment_id                := NULL;
              lc_ce_mpl_settlement_dtl.shipment_id                  := NULL ;
              lc_ce_mpl_settlement_dtl.shipment_fee_type            := NULL;
              lc_ce_mpl_settlement_dtl.shipment_fee_amount          := NULL;
              lc_ce_mpl_settlement_dtl.order_fee_type               := NULL;
              lc_ce_mpl_settlement_dtl.order_fee_amount             := NULL;
              lc_ce_mpl_settlement_dtl.aops_order_number            :=NULL ;
              lc_ce_mpl_settlement_dtl.fulfillment_id               := NULL ;
              lc_ce_mpl_settlement_dtl.order_item_code              := rec_dtl.PARTNER_ITEM_ID ;
              lc_ce_mpl_settlement_dtl.merchant_order_item_id       := rec_dtl.PARTNER_ITEM_ID;
              lc_ce_mpl_settlement_dtl.merchant_adjustment_item_id  := NULL;
              lc_ce_mpl_settlement_dtl.sku                          := rec_dtl.PARTNER_ITEM_ID;
              lc_ce_mpl_settlement_dtl.misc_fee_amount              := NULL;
              lc_ce_mpl_settlement_dtl.other_fee_amount             := NULL;
              lc_ce_mpl_settlement_dtl.other_fee_reason_description := NULL;
              lc_ce_mpl_settlement_dtl.promotion_id                 := NULL;
              lc_ce_mpl_settlement_dtl.promotion_type               := NULL;
              lc_ce_mpl_settlement_dtl.promotion_amount             := NULL;
              lc_ce_mpl_settlement_dtl.direct_payment_type          := NULL;
              lc_ce_mpl_settlement_dtl.direct_payment_amount        := NULL;
              lc_ce_mpl_settlement_dtl.other_amount                 := NULL;
              lc_ce_mpl_settlement_dtl.store_number                 := NULL;
              lc_ce_mpl_settlement_dtl.record_status                := 'N';
              lc_ce_mpl_settlement_dtl.error_description            := NULL;
              lc_ce_mpl_settlement_dtl.request_id                   :=NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);
              lc_ce_mpl_settlement_dtl.created_by                   := NVL(FND_GLOBAL.USER_ID,        -1);
              lc_ce_mpl_settlement_dtl.creation_date                := SYSDATE;
              lc_ce_mpl_settlement_dtl.last_updated_by              := NVL(FND_GLOBAL.USER_ID, -1);
              lc_ce_mpl_settlement_dtl.last_update_date             := SYSDATE;
              lc_ce_mpl_settlement_dtl.last_update_login            := NVL(FND_GLOBAL.USER_ID, -1);
              lc_ce_mpl_settlement_dtl.attribute1                   := rec_dtl.WALMART_PO;
              FOR j IN 1..3
              LOOP
                lc_action                 := 'Generate Walmart Record into Multiple Transactions';
                lc_quantity_purchased     :=NULL;
                lc_unit_price             :=NULL;
                lc_price_type             :=NULL;
                l_price_amount            :=NULL;
                lc_item_related_fee_type  :=NULL;
                lc_item_related_fee_amount:=NULL;
                ---l_total_amount:=null;
                ---l_currency:=null;
                IF j                     =1 THEN
                  lc_action             := 'Generate Walmart Record for Item';
                  lc_quantity_purchased :=NVL(rec_dtl.SHIPPED_QTY,0);
                  IF rec_dtl.SHIPPED_QTY =0 THEN
                    lc_unit_price       :=0;
                  ELSE
                    lc_unit_price:=ROUND((rec_dtl.TOTAL_TENDER_CUSTOMER)/rec_dtl.SHIPPED_QTY,2);
                  END IF;
                END IF;
                IF j              =2 THEN
                  lc_action      := 'Generate Walmart Record for Principal Price Type';
                  lc_price_type  :='Principal';
                  l_price_amount :=rec_dtl.TOTAL_TENDER_CUSTOMER;
                END IF;
                IF j                          =3 THEN
                  lc_action                  := 'Generate Walmart Record for Sales Tax Service Price Type';
                  lc_item_related_fee_type   :='SalesTaxServiceFee';
                  lc_item_related_fee_amount :=NVL(rec_dtl.COMMISSION_FROM_SALE,0) ;
                END IF;
                lc_ce_mpl_settlement_dtl.quantity_purchased      := lc_quantity_purchased;
                lc_ce_mpl_settlement_dtl.unit_price              := lc_unit_price;
                lc_ce_mpl_settlement_dtl.price_type              := lc_price_type;
                lc_ce_mpl_settlement_dtl.price_amount            := l_price_amount;
                lc_ce_mpl_settlement_dtl.item_related_fee_type   := lc_item_related_fee_type;
                lc_ce_mpl_settlement_dtl.item_related_fee_amount := lc_item_related_fee_amount;
                INSERT INTO XX_CE_MPL_SETTLEMENT_DTL VALUES lc_ce_mpl_settlement_dtl;
              END LOOP;
            EXCEPTION
            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
            END;
          END LOOP; --DTL Cursor
          lc_action                                      := 'Insert into XX_CE_MPL_SETTLEMENT_HDR Table for Walmart PO#-'||rec_hdr.WALMART_PO;
          Lc_Ce_Mpl_Settlement_Hdr                       :=NULL;
          lc_ce_mpl_settlement_hdr.mpl_header_id         :=lc_mpl_header_id;
          lc_ce_mpl_settlement_hdr.PROVIDER_TYPE         :=lt_translation_info.target_value14 ;
          lc_ce_mpl_settlement_hdr.settlement_id         :=lc_settlement_id ;
          lc_ce_mpl_settlement_hdr.settlement_start_date :=to_date(TO_CHAR(lc_settlement_start_date,'YYYY-MM-DD'),'YYYY-MM-DD') ;
          lc_ce_mpl_settlement_hdr.settlement_end_date   :=to_date(TO_CHAR(lc_settlement_end_date,'YYYY-MM-DD'),'YYYY-MM-DD') ;
          lc_ce_mpl_settlement_hdr.order_id              :=rec_hdr.WALMART_PO ;
          lc_ce_mpl_settlement_hdr.merchant_order_id     :=rec_hdr.WALMART_PO ;
          lc_ce_mpl_settlement_hdr.deposit_date          :=to_date(TO_CHAR(to_Date(lc_settlement_end_date,'DD-MM-YY'),'DD-MM-YYYY'),'DD-MM-YYYY');
          lc_ce_mpl_settlement_hdr.total_amount          :=NULL;
          lc_ce_mpl_settlement_hdr.currency              :=NULL;
          IF rec_hdr.transaction_type                     ='SALE' THEN
            lc_ce_mpl_settlement_hdr.transaction_type    :='Order';
          ELSE
            lc_ce_mpl_settlement_hdr.transaction_type :='Adjustment';
          END IF;
          lc_ce_mpl_settlement_hdr.marketplace_name    :=p_process_name;
          lc_ce_mpl_settlement_hdr.split_order         :=NULL;
          lc_ce_mpl_settlement_hdr.PROCESSOR_ID        := lt_translation_info.target_value13 ;
          lc_ce_mpl_settlement_hdr.posted_date         :=rec_file.posted_date ;
          lc_ce_mpl_settlement_hdr.ajb_998_amount      :=NULL;
          lc_ce_mpl_settlement_hdr.ajb_999_amount      :=NULL;
          lc_ce_mpl_settlement_hdr.ajb_996_amount      :=NULL;
          lc_ce_mpl_settlement_hdr.terminal_number     :=NULL;
          lc_ce_mpl_settlement_hdr.card_number         :=NULL;
          lc_ce_mpl_settlement_hdr.auth_number         :=NULL;
          lc_ce_mpl_settlement_hdr.action              :=NULL;
          lc_ce_mpl_settlement_hdr.record_status       :='N';
          lc_ce_mpl_settlement_hdr.record_status_stage :='NEW';
          lc_ce_mpl_settlement_hdr.error_description   :=NULL;
          lc_ce_mpl_settlement_hdr.request_id          :=NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);
          Lc_Ce_Mpl_Settlement_Hdr.Created_By          :=NVL(Fnd_Global.User_Id,         -1);
          Lc_Ce_Mpl_Settlement_Hdr.Creation_Date       :=Sysdate;
          Lc_Ce_Mpl_Settlement_Hdr.Last_Updated_By     :=NVL(Fnd_Global.User_Id, -1);
          lc_ce_mpl_settlement_hdr.last_update_date    :=SYSDATE;
          Lc_Ce_Mpl_Settlement_Hdr.Last_Update_Login   :=NVL(Fnd_Global.User_Id, -1);
          Lc_Ce_Mpl_Settlement_Hdr.ajb_file_name       :=rec_file.filename||lc_settlement_id;
          INSERT INTO XX_CE_MPL_SETTLEMENT_HDR VALUES lc_ce_mpl_settlement_hdr;
          UPDATE XX_CE_WALMART_PRE_STG_V a
          SET a.process_flag    ='P',
            A.Err_Msg           =NULL
          WHERE A.WALMART_PO    =Rec_hdr.WALMART_PO
          AND a.process_flag   IN ('N','E')
          AND a.transaction_type=Rec_hdr.transaction_type;
          gc_success_count     :=gc_success_count+1;
        ELSE
          UPDATE XX_CE_WALMART_PRE_STG_V a
          SET a.process_flag    ='E',
            A.Err_Msg           ='Duplicate record found for Walmart PO#'
          WHERE A.WALMART_PO    =Rec_hdr.WALMART_PO
          AND a.process_flag   IN ('N','E')
          AND a.transaction_type=Rec_hdr.transaction_type;
          gc_failure_count     :=gc_failure_count+1;
        END IF;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        gc_failure_count:=gc_failure_count+1;
        lc_err_msg      :=SUBSTR('PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' ||sqlerrm,1,1000);
        UPDATE XX_CE_WALMART_PRE_STG_V a
        SET a.process_flag    ='E' ,
          a.err_msg           =lc_err_msg
        WHERE a.WALMART_PO    =rec_hdr.WALMART_PO
        AND a.process_flag   IN ('N','E')
        AND a.transaction_type=Rec_hdr.transaction_type;
        COMMIT;
      END;
    END LOOP; --HDR Cursor
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
END PROCESS_WALMART_PRESTG_DATA;
/**********************************************************************************
* Procedure to process EBAY MP at different levels.
*this procedure is main procedure for EBAY MP and calls all sub procedures.
* This procedure is called by process_EBAY_MP.
***********************************************************************************/
PROCEDURE PROCESS_EBAY_PRESTG_DATA(
    p_process_name IN VARCHAR2)
IS
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'PROCESS_EBAY_PRESTG_DATA';
  lt_parameters gt_input_parameters;
  lc_action VARCHAR2(1000);
  lc_ce_mpl_settlement_dtl XX_CE_MPL_SETTLEMENT_DTL%ROWTYPE;
  lc_ce_mpl_settlement_hdr XX_CE_MPL_SETTLEMENT_HDR%ROWTYPE;
  lc_settlement_start_date xx_ce_ebay_trx_dtl_stg.transaction_initiation_date%type ;
  lc_settlement_end_date xx_ce_ebay_trx_dtl_stg.transaction_completion_date%type ;
  lc_currency xx_ce_ebay_trx_dtl_stg.gross_transaction_currency%type;
  lc_start_date xx_ce_ebay_trx_dtl_stg.transaction_initiation_date%type ;
  lc_end_date xx_ce_ebay_trx_dtl_stg.transaction_completion_date%type ;
  lc_settlement_id XX_CE_MPL_SETTLEMENT_DTL.settlement_id%type;
  lc_quantity_purchased      VARCHAR2(25);
  lc_unit_price              NUMBER;
  lc_price_type              VARCHAR2(50);
  l_price_amount             VARCHAR2(25);
  lc_item_related_fee_type   VARCHAR2(50);
  lc_item_related_fee_amount VARCHAR2(25);
  l_rec_cnt                  NUMBER := 0;
  lc_mpl_header_id XX_CE_MPL_SETTLEMENT_DTL.mpl_header_id%type;
  lc_error_flag VARCHAR2(1)                     :='N';
  lc_err_msg xx_ce_ebay_trx_dtl_stg.err_msg%type:=NULL;
  lc_hdr_dtl_count NUMBER                       :=0;
  CURSOR cur_settlement_files
  IS
    SELECT DISTINCT filename,
      tdr.gross_transaction_currency,
      MIN(transaction_initiation_date) transaction_initiation_date,
      MAX(transaction_completion_date) transaction_completion_date
    FROM xx_ce_ebay_trx_dtl_stg tdr
    WHERE 1                     =1
    AND tdr.process_flag       IN ('N','E')
    AND tdr.transactionAL_status='S'
    GROUP BY filename,
      tdr.gross_transaction_currency;
  CURSOR cur_settlement_pre_stage_hdr(p_filename VARCHAR2)
  IS
    SELECT DISTINCT tdr.transaction_id transaction_id,
      ca.channel_advisor_order_id order_id,
      tdr.auction_site marketplace_name,
      tdr.filename,
      ca.seller_order_id merchant_order_id,
      ( TO_CHAR(to_date(SUBSTR(tdr.transaction_completion_date,1,10),'YYYY-MM-DD'),'YYYY-MM-DD')
      ||'T'
      || REPLACE (SUBSTR(tdr.transaction_completion_date,12,12),' ','')
      ||':'
      --||SUBSTR(tdr.transaction_completion_date,23,2)) posted_date,--commentd by Sripal For NAIT-71529
      ||SUBSTR(tdr.transaction_completion_date,24,2)) posted_date, ---added for Defect NAIT-71529
      --to_Char(to_date(Substr(tdr.transaction_completion_date,1,19),'yyyy/mm/dd hh24:mi:ss'),'yyyy/mm/dd hh24:mi:ss') posted_date,
      --to_date(Substr(tdr.transaction_completion_date,1,19),'YYYY-MM-DD hh24:mi:ss') posted_date,
      DECODE(transaction_debitorcredit,'DR','Adjustment','Order') transaction_type
    FROM xx_ce_ebay_ca_dtl_stg ca,
      xx_ce_ebay_trx_dtl_stg tdr
    WHERE 1                         =1
    AND tdr.filename                =p_filename
    AND tdr.process_flag           IN ('N','E')
    AND ca.merchant_reference_number=DECODE(tdr.transaction_event_code,'T1107',tdr.pay_pal_Reference_id,tdr.transaction_id)
    AND tdr.transactionAL_status    ='S'
    AND EXISTS
      (SELECT 1
      FROM xx_fin_translatevalues vals,
        xx_fin_translatedefinition defn
      WHERE 1                   =1
      AND defn.translation_name = 'OD_EBAY_TCODE'
      AND defn.translate_id     = vals.translate_id
      AND vals.target_value2    =tdr.transaction_event_code
      AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
      AND SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
      AND vals.enabled_flag = 'Y'
      AND defn.enabled_flag = 'Y'
      );
  CURSOR dup_check_cur(lc_settlement_id NUMBER)
  IS
    SELECT settlement_id
    FROM XX_CE_MPL_SETTLEMENT_HDR
    WHERE settlement_id = lc_settlement_id
    AND rownum          < 2 ;
  CURSOR cur_settlement_pre_stage_dtl(p_transaction_id xx_ce_ebay_trx_dtl_stg.transaction_id%type)
  IS
    SELECT DECODE(tdr.transaction_event_code,'T1107',tdr.pay_pal_reference_id,tdr.transaction_id) tdr_transaction_id,
      --(NVL(DECODE(tdr.transaction_debitorcredit,'DR',(-1*tdr.gross_transaction_amount),tdr.gross_transaction_amount),0))/100 tdr_gross_total_amount,
      (NVL(DECODE(tdr.transaction_debitorcredit,'DR',(-1*tdr.fee_amount),tdr.fee_amount),0))/100 tdr_fee_amount,
      DECODE(transaction_debitorcredit,'DR','Adjustment','Order') transaction_type,
      tdr.gross_transaction_currency tdr_transaction_currency ,
      -- ( NVL(DECODE(tdr.transaction_debitorcredit,'DR',(-1*tdr.SHIPPING_AMOUNT),tdr.SHIPPING_AMOUNT),0))/100 tdr_SHIPPING_AMOUNT,
      -- (NVL(DECODE(tdr.transaction_debitorcredit,'DR',( -1*tdr.Sales_Tax_Amount),tdr.Sales_Tax_Amount),0))/100 tdr_Sales_Tax_AMOUNT,
      tdr.auction_site tdr_marketplace_name,
      (NVL(DECODE(tdr.transaction_debitorcredit,'DR',(-1*tdr.insurance_amount),tdr.insurance_amount),0))/100 tdr_insurance_amount,
      /*( TO_CHAR(to_date(SUBSTR(tdr.transaction_completion_date,1,10),'YYYY-MM-DD'),'YYYY-MM-DD')
      ||'T'
      || REPLACE (SUBSTR(tdr.transaction_completion_date,12,12),' ','')
      ||':'
      --||SUBSTR(tdr.transaction_completion_date,23,2)) tdr_posted_date, --commentd by Sripal For NAIT-71529
      ||SUBSTR(tdr.transaction_completion_date,24,2)) tdr_posted_date */
      -----added for Defect NAIT-71529
      TO_CHAR(to_date(SUBSTR(tdr.transaction_completion_date,1,19),'yyyy/mm/dd hh24:mi:ss'),'yyyy/mm/dd hh24:mi:ss') tdr_posted_date,
      ca.channel_advisor_order_id ca_order_id,
      ca.seller_order_id ca_merchant_order_id,
      ca.shipping_status ca_fulfillment_id,---changes as per new mapping
      '' order_item_code,
      ca.sku sku ,
      NVL(ca.quantity,0) ca_quantity_purchased,
      NVL(ca.unit_price,0) ca_unit_price,
      '' price_type,
      DECODE(tdr.transaction_debitorcredit,'DR', -1*(NVL(ca.unit_price,0)*NVL(ca.quantity,0)),NVL(ca.unit_price,0)*NVL(ca.quantity,0)) ca_price_amount,
	  DECODE(tdr.transaction_debitorcredit,'DR', -1*(NVL(ca.item_tax,0)+NVL(ca.item_shipping_tax,0)),NVL(ca.item_tax,0)+NVL(ca.item_shipping_tax,0)) ca_total_tax_price,
      DECODE(tdr.transaction_debitorcredit,'DR', -1*(NVL(ca.item_shipping_price,0)),NVL(ca.item_shipping_price,0)) ca_total_shipping_price,
      '' item_related_fee_type
    FROM xx_ce_ebay_ca_dtl_stg ca,
      xx_ce_ebay_trx_dtl_stg tdr
    WHERE tdr.transaction_id        =p_transaction_id
    AND ca.merchant_reference_number=DECODE(tdr.transaction_event_code,'T1107',tdr.pay_pal_Reference_id,tdr.transaction_id);
BEGIN
  lt_parameters('p_process_name') := p_process_name;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);
  lc_action := 'Deriving Translation Details for EBAY MPL';
  FOR rec_file IN cur_settlement_files
  LOOP
    logit(p_message => 'Processing Ebay MPL TRR File-' ||rec_file.filename);
    lc_action               := 'Deriving Settlement Start Date and Settlement End Date';
    lc_settlement_start_date:=TO_CHAR(to_date(SUBSTR(rec_file.transaction_initiation_date,1,10),'YYYY-MM-DD'),'YYYY-MM-DD');
    lc_settlement_end_date  :=TO_CHAR(to_date(SUBSTR(rec_file.transaction_completion_date,1,10),'YYYY-MM-DD'),'YYYY-MM-DD');
    logit(p_message => 'Settlement Start Date Derived for FileNanme-' ||rec_file.filename||'is '||lc_settlement_start_date);
    logit(p_message => 'Settlement End Date Derived for FileNanme-' ||rec_file.filename||'is '||lc_settlement_end_date);
    lc_action := 'Deriving Settlement Id';
    SELECT xx_ce_mpl_settlement_id_s.nextval INTO lc_settlement_id FROM dual;
    Lc_Action := 'Validating Duplicate Settlement Id';
    logit(p_message => 'Settlement ID-'||lc_settlement_id||' derived for Processing Ebay MPL TRR File-' ||rec_file.filename);
    FOR j IN dup_check_cur(lc_settlement_id)
    LOOP
      l_rec_cnt := l_rec_cnt + 1;
    END LOOP;
    IF L_Rec_Cnt > 0 THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      logit(p_message => 'Settlement Can not be processed , Duplicate Settlement id found in staging table-XX_CE_MPL_SETTLEMENT_HDR '||lc_settlement_id);
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
    END IF;
    FOR rec_hdr IN cur_settlement_pre_stage_hdr(rec_file.filename)
    LOOP
      BEGIN
        lc_hdr_dtl_count:=0;
        lc_action       := 'Processing eBAY PreStage Data';
        lc_err_msg      :=NULL;
        lc_action       := 'Processing eBAY PreStage Header Data';
        SELECT XX_CE_MPL_HEADER_ID_SEQ.nextval INTO lc_mpl_header_id FROM dual;
       -- IF dup_check_transaction(rec_hdr.marketplace_name,rec_hdr.transaction_id)='N' THEN
		IF dup_check_transaction_type(p_process_name,rec_hdr.transaction_id,rec_hdr.transaction_type)='N' THEN
          FOR rec_dtl IN cur_settlement_pre_stage_dtl(rec_hdr.transaction_id)
          LOOP
            lc_action       := 'Processing eBAY PreStage Detail Data';
            lc_hdr_dtl_count:=lc_hdr_dtl_count+1;
            BEGIN
              lc_ce_mpl_settlement_dtl                              :=NULL;
              lc_ce_mpl_settlement_dtl.mpl_header_id                := lc_mpl_header_id;
              lc_ce_mpl_settlement_dtl.marketplace_name             :=p_process_name;
              lc_ce_mpl_settlement_dtl.order_id                     := rec_dtl.ca_order_id ;
              lc_ce_mpl_settlement_dtl.settlement_id                := lc_settlement_id ;
              lc_ce_mpl_settlement_dtl.transaction_id               := rec_hdr.transaction_id;
              lc_ce_mpl_settlement_dtl.adjustment_id                := NULL;
              lc_ce_mpl_settlement_dtl.shipment_id                  := NULL ;
              lc_ce_mpl_settlement_dtl.shipment_fee_type            := NULL;
              lc_ce_mpl_settlement_dtl.shipment_fee_amount          := NULL;
              lc_ce_mpl_settlement_dtl.order_fee_type               := NULL;
              lc_ce_mpl_settlement_dtl.order_fee_amount             := NULL;
              lc_ce_mpl_settlement_dtl.aops_order_number            :=NULL ;
              lc_ce_mpl_settlement_dtl.fulfillment_id               := rec_dtl.ca_fulfillment_id ;
              lc_ce_mpl_settlement_dtl.order_item_code              := rec_dtl.order_item_code ;
              lc_ce_mpl_settlement_dtl.merchant_order_item_id       := rec_dtl.sku;
              lc_ce_mpl_settlement_dtl.merchant_adjustment_item_id  := NULL;
              lc_ce_mpl_settlement_dtl.sku                          := rec_dtl.sku;
              lc_ce_mpl_settlement_dtl.misc_fee_amount              := NULL;
              lc_ce_mpl_settlement_dtl.other_fee_amount             := NULL;
              lc_ce_mpl_settlement_dtl.other_fee_reason_description := NULL;
              lc_ce_mpl_settlement_dtl.promotion_id                 := NULL;
              lc_ce_mpl_settlement_dtl.promotion_type               := NULL;
              lc_ce_mpl_settlement_dtl.promotion_amount             := NULL;
              lc_ce_mpl_settlement_dtl.direct_payment_type          := NULL;
              lc_ce_mpl_settlement_dtl.direct_payment_amount        := NULL;
              lc_ce_mpl_settlement_dtl.other_amount                 := NULL;
              lc_ce_mpl_settlement_dtl.store_number                 := NULL;
              lc_ce_mpl_settlement_dtl.record_status                := 'N';
              lc_ce_mpl_settlement_dtl.error_description            := NULL;
              lc_ce_mpl_settlement_dtl.request_id                   :=NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);
              lc_ce_mpl_settlement_dtl.created_by                   := NVL(FND_GLOBAL.USER_ID,        -1);
              lc_ce_mpl_settlement_dtl.creation_date                := SYSDATE;
              lc_ce_mpl_settlement_dtl.last_updated_by              := NVL(FND_GLOBAL.USER_ID, -1);
              lc_ce_mpl_settlement_dtl.last_update_date             := SYSDATE;
              lc_ce_mpl_settlement_dtl.last_update_login            := NVL(FND_GLOBAL.USER_ID, -1);
              lc_ce_mpl_settlement_dtl.attribute1                   := rec_hdr.transaction_id;
              FOR j IN 1..5
              LOOP
                lc_action                 := 'Generate eBAY Record into Multiple Transactions';
                lc_quantity_purchased     :=NULL;
                lc_unit_price             :=NULL;
                lc_price_type             :=NULL;
                l_price_amount            :=NULL;
                lc_item_related_fee_type  :=NULL;
                lc_item_related_fee_amount:=NULL;
                ---l_total_amount:=null;
                ---l_currency:=null;
                IF j                     =1 THEN
                  lc_action             := 'Generate eBAY Record for Item';
                  lc_quantity_purchased :=rec_dtl.ca_quantity_purchased;
                  lc_unit_price         :=rec_dtl.ca_unit_price;
                END IF;
                IF j             =2 THEN
                  lc_action     := 'Generate eBAY Record for Principal Price Type';
                  lc_price_type :='Principal';
                  --l_price_amount :=rec_dtl.tdr_gross_total_amount-(rec_dtl.tdr_SHIPPING_AMOUNT+rec_dtl.tdr_Sales_Tax_AMOUNT);
                  l_price_amount :=rec_dtl.ca_price_amount;
                END IF;
                IF j             =3 THEN
                  lc_action     := 'Generate eBAY Record for Shipping Price Type';
                  lc_price_type :='Shipping';
                  --l_price_amount :=rec_dtl.tdr_SHIPPING_AMOUNT;
                  l_price_amount:=rec_dtl.ca_total_shipping_price;
                END IF;
                IF j             =4 THEN
                  lc_action     := 'Generate eBAY Record for Tax Price Type';
                  lc_price_type :='Tax';
                  --l_price_amount :=rec_dtl.tdr_Sales_Tax_AMOUNT;
                  l_price_amount :=rec_dtl.ca_total_tax_price;
                END IF;
                IF j                            =5 THEN
                  lc_action                    := 'Generate eBAY Record for Sales Tax Service Price Type';
                  lc_item_related_fee_type     :='SalesTaxServiceFee';
                  IF lc_hdr_dtl_count           =1 THEN
                    lc_item_related_fee_amount :=rec_dtl.tdr_fee_amount+rec_dtl.tdr_insurance_amount;
                  ELSE
                    lc_item_related_fee_amount :=0;
                  END IF;
                END IF;
                lc_ce_mpl_settlement_dtl.quantity_purchased      := lc_quantity_purchased;
                lc_ce_mpl_settlement_dtl.unit_price              := lc_unit_price;
                lc_ce_mpl_settlement_dtl.price_type              := lc_price_type;
                lc_ce_mpl_settlement_dtl.price_amount            := l_price_amount;
                lc_ce_mpl_settlement_dtl.item_related_fee_type   := lc_item_related_fee_type;
                lc_ce_mpl_settlement_dtl.item_related_fee_amount := lc_item_related_fee_amount;
                INSERT INTO XX_CE_MPL_SETTLEMENT_DTL VALUES lc_ce_mpl_settlement_dtl;
              END LOOP;
            EXCEPTION
            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
            END;
          END LOOP; --DTL Cursor
          lc_action                                      := 'Insert into XX_CE_MPL_SETTLEMENT_HDR Table for Transaction ID-'||rec_hdr.transaction_id;
          Lc_Ce_Mpl_Settlement_Hdr                       :=NULL;
          lc_ce_mpl_settlement_hdr.mpl_header_id         :=lc_mpl_header_id;
          lc_ce_mpl_settlement_hdr.PROVIDER_TYPE         :=lt_translation_info.target_value14 ;
          lc_ce_mpl_settlement_hdr.settlement_id         :=lc_settlement_id ;
          lc_ce_mpl_settlement_hdr.settlement_start_date :=to_date(lc_settlement_start_date,'YYYY-MM-DD') ;
          lc_ce_mpl_settlement_hdr.settlement_end_date   :=to_date(lc_settlement_end_date,'YYYY-MM-DD') ;
          lc_ce_mpl_settlement_hdr.order_id              :=rec_hdr.order_id ;
          lc_ce_mpl_settlement_hdr.merchant_order_id     :=rec_hdr.merchant_order_id ;
          lc_ce_mpl_settlement_hdr.deposit_date          :=to_date(lc_settlement_end_date,'YYYY-MM-DD') ;
          --lc_ce_mpl_settlement_hdr.deposit_date          :=to_Date(TO_CHAR(to_date(SUBSTR(rec_file.transaction_completion_date,1,10),'YYYY-MM-DD'),'DD-MM-YYYY'),'DD-MM-YYYY') ;
          lc_ce_mpl_settlement_hdr.total_amount        :=NULL;
          lc_ce_mpl_settlement_hdr.currency            :=NULL;
          lc_ce_mpl_settlement_hdr.transaction_type    :=rec_hdr.transaction_type;
          lc_ce_mpl_settlement_hdr.marketplace_name    :=p_process_name;
          lc_ce_mpl_settlement_hdr.split_order         :=NULL;
          lc_ce_mpl_settlement_hdr.PROCESSOR_ID        := lt_translation_info.target_value13 ;
          lc_ce_mpl_settlement_hdr.posted_date         :=rec_hdr.posted_date;
          lc_ce_mpl_settlement_hdr.ajb_998_amount      :=NULL;
          lc_ce_mpl_settlement_hdr.ajb_999_amount      :=NULL;
          lc_ce_mpl_settlement_hdr.ajb_996_amount      :=NULL;
          lc_ce_mpl_settlement_hdr.terminal_number     :=NULL;
          lc_ce_mpl_settlement_hdr.card_number         :=NULL;
          lc_ce_mpl_settlement_hdr.auth_number         :=NULL;
          lc_ce_mpl_settlement_hdr.action              :=NULL;
          lc_ce_mpl_settlement_hdr.record_status       :='N';
          lc_ce_mpl_settlement_hdr.record_status_stage :='NEW';
          lc_ce_mpl_settlement_hdr.error_description   :=NULL;
          lc_ce_mpl_settlement_hdr.request_id          :=NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);
          Lc_Ce_Mpl_Settlement_Hdr.Created_By          :=NVL(Fnd_Global.User_Id,         -1);
          Lc_Ce_Mpl_Settlement_Hdr.Creation_Date       :=Sysdate;
          Lc_Ce_Mpl_Settlement_Hdr.Last_Updated_By     :=NVL(Fnd_Global.User_Id, -1);
          lc_ce_mpl_settlement_hdr.last_update_date    :=SYSDATE;
          Lc_Ce_Mpl_Settlement_Hdr.Last_Update_Login   :=NVL(Fnd_Global.User_Id, -1);
          Lc_Ce_Mpl_Settlement_Hdr.ajb_file_name       :=rec_hdr.filename||lc_settlement_id;
          INSERT INTO XX_CE_MPL_SETTLEMENT_HDR VALUES lc_ce_mpl_settlement_hdr;
          UPDATE xx_ce_ebay_trx_dtl_stg a
          SET a.process_flag    ='P',
            a.err_msg           =NULL
          WHERE a.transaction_id=rec_hdr.transaction_id
          AND a.process_flag   IN ('N','E');
          UPDATE xx_ce_ebay_ca_dtl_stg b
          SET b.process_flag               ='P',
            b.err_msg                      =NULL
          WHERE b.merchant_reference_number=rec_hdr.transaction_id
          AND b.process_flag                               IN ('N','E');
          gc_success_count                :=gc_success_count+1;
        ELSE
          UPDATE xx_ce_ebay_trx_dtl_stg a
          SET a.process_flag    ='E',
            a.err_msg           ='Duplicate record found for Transaction Id'
          WHERE a.transaction_id=rec_hdr.transaction_id
          AND a.process_flag   IN ('N','E');
          UPDATE xx_ce_ebay_ca_dtl_stg b
          SET b.process_flag               ='E',
            B.Err_Msg                      ='Duplicate record found for Transaction Id'
          WHERE b.merchant_reference_number=rec_hdr.transaction_id
          AND b.process_flag                               IN ('N','E');
          gc_failure_count                :=gc_failure_count+1;
        END IF;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        gc_failure_count:=gc_failure_count+1;
        lc_err_msg      :=SUBSTR('PROCEDURE: ' || lc_procedure_name || ' ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' ||sqlerrm,1,1000);
        UPDATE xx_ce_ebay_trx_dtl_stg a
        SET a.process_flag    ='E' ,
          a.err_msg           =lc_err_msg
        WHERE a.transaction_id=rec_hdr.transaction_id
        AND a.process_flag   IN ('N','E');
        UPDATE xx_ce_ebay_ca_dtl_stg b
        SET b.process_flag               ='E',
          B.Err_Msg                      =lc_err_msg
        WHERE b.merchant_reference_number=rec_hdr.transaction_id
        AND b.process_flag              IN ('N','E');
        COMMIT;
      END;
    END LOOP; --HDR Cursor
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
END PROCESS_EBAY_PRESTG_DATA;

/**********************************************************************************
* Procedure to process Google MP at different levels.
* This procedure is main procedure for Google MP and calls all sub procedures.
* This procedure is called by MAIN_MPL_GOOGLE_PROCESS.
***********************************************************************************/
PROCEDURE PROCESS_GOOGLE_PRESTG_DATA(
    p_process_name IN VARCHAR2)
IS
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'PROCESS_GOOGLE_PRESTG_DATA';
  lt_parameters gt_input_parameters;
  lc_action VARCHAR2(1000);
  lc_ce_mpl_settlement_dtl XX_CE_MPL_SETTLEMENT_DTL%ROWTYPE;
  lc_ce_mpl_settlement_hdr XX_CE_MPL_SETTLEMENT_HDR%ROWTYPE;
  lc_settlement_start_date XX_CE_MPL_SETTLEMENT_HDR.settlement_start_date%type ;
  lc_settlement_end_date XX_CE_MPL_SETTLEMENT_HDR.settlement_end_date%type ;
  lc_currency VARCHAR2(15);
  lc_start_date XX_CE_MPL_SETTLEMENT_HDR.settlement_start_date%type ;
  lc_end_date XX_CE_MPL_SETTLEMENT_HDR.settlement_start_date%type ;
  lc_settlement_id XX_CE_MPL_SETTLEMENT_DTL.settlement_id%type;
  lc_quantity_purchased      VARCHAR2(25);
  lc_unit_price              NUMBER;
  lc_price_type              VARCHAR2(50);
  l_price_amount             VARCHAR2(25);
  lc_item_related_fee_type   VARCHAR2(50);
  lc_item_related_fee_amount VARCHAR2(25);
  l_rec_cnt                  NUMBER := 0;
  lc_mpl_header_id XX_CE_MPL_SETTLEMENT_DTL.mpl_header_id%type;
  lc_error_flag VARCHAR2(1)                     :='N';
  lc_err_msg xx_ce_ebay_trx_dtl_stg.err_msg%type:=NULL;
  lc_transaction_type XX_CE_MPL_SETTLEMENT_HDR.transaction_type%type;
  CURSOR cur_google_settlement_files
  IS
    SELECT DISTINCT filename,
      to_date(TO_CHAR(MIN(to_date(SUBSTR(post_date,1,10),'YYYY-MM-DD')),'MM/DD/YYYY'),'MM/DD/YYYY') transaction_start_date,
      to_date(TO_CHAR(MAX(to_date(SUBSTR(post_date,1,10),'YYYY-MM-DD')),'MM/DD/YYYY'),'MM/DD/YYYY')transaction_end_date,
      CAST(to_date(MAX(to_date(SUBSTR(post_datetime,1,10),'YYYY-MM-DD')),'YYYY-MM-DD') AS DATE) posted_date
	  FROM xx_ce_google_pre_stg_v glv
    WHERE 1               =1
    AND glv.process_flag IN ('N','E')
    AND timezone          ='America/Los_Angeles'
	AND order_id is not null
    GROUP BY filename;
	
  CURSOR cur_settlement_pre_stage_hdr(p_filename VARCHAR2)
  IS
    SELECT DISTINCT order_id google_po,
      transaction_type
    FROM xx_ce_google_pre_stg_v hdr
    WHERE 1               =1
    AND hdr.filename      =p_filename
    AND hdr.process_flag IN ('N','E')
	and hdr.order_id is not null
	order by hdr.TRANSACTION_TYPE, hdr.ORDER_ID;
	
  CURSOR dup_check_cur(lc_settlement_id NUMBER)
  IS
    SELECT settlement_id
    FROM XX_CE_MPL_SETTLEMENT_HDR
    WHERE settlement_id = lc_settlement_id
    AND rownum          < 2;
	
  CURSOR cur_settlement_pre_stage_dtl(p_google_po VARCHAR2,p_transaction_type VARCHAR2 )
  IS
    SELECT TDR.ORDER_ID GOOGLE_PO,
      TDR.MERCHANT_ORDER_ID GOOGLE_ORDER,
      TDR.TRANSACTION_TYPE,
      TDR.ORDER_ITEM_ID PARTNER_ITEM_ID,
      TDR.AMOUNT_TYPE ,
      TDR.AMOUNT_DESCRIPTION ,
      TDR.COMMISSION_CATEGORY_RATE ,
      TDR.AMOUNT UNIT_PRICE,
      COUNT(TDR.ORDER_ITEM_ID) ITEM_QTY,
      SUM(AMOUNT) LINE_AMOUNT
    FROM XX_CE_GOOGLE_PRE_STG_V tdr
    WHERE 1                 =1
    AND tdr.ORDER_ID        = p_google_po
    AND tdr.transaction_type= p_transaction_type
    AND tdr.process_flag   IN ('N','E')
    GROUP BY tdr.ORDER_ID,
      tdr.MERCHANT_ORDER_ID,
      tdr.transaction_type,
      tdr.ORDER_ITEM_ID,
      tdr.amount_type ,
      amount_description ,
      commission_Category_rate ,
      amount
    ORDER BY tdr.ORDER_ID,
      tdr.ORDER_ITEM_ID,
      tdr.AMOUNT_DESCRIPTION;
  lv_deposit_date DATE;
BEGIN
  lt_parameters('p_process_name') := p_process_name;
  entering_sub(p_procedure_name => lc_procedure_name, p_parameters => lt_parameters);
  lc_action := 'Deriving Translation Details for GOOGLE MPL';
  
  FOR rec_file IN cur_google_settlement_files
  LOOP
    logit(p_message => 'Processing GOOGLE MPL Transaction File-' ||rec_file.filename);
    lc_settlement_start_date:=rec_file.transaction_start_date;
    lc_settlement_end_date  :=rec_file.transaction_end_date;
    lc_action               := 'Deriving Settlement Start Date and Settlement End Date';
    logit(p_message => 'RESULT Settlement Start_date: ' || TO_CHAR(lc_settlement_start_date,'YYYY-MM-DD'));
    logit(p_message => 'RESULT Settlement End_Date: ' || TO_CHAR(lc_settlement_end_date,'YYYY-MM-DD'));
    lc_action := 'Deriving Settlement Id';
 
    BEGIN --Derive Bank Rec ID
      DERIVE_BANK_DEPOSIT_DATE(p_process_name,lc_settlement_end_date,lv_deposit_date);
    EXCEPTION
    WHEN OTHERS THEN
      lv_deposit_date:=lc_settlement_end_date;
      logit(p_message => 'Error Occured in PROCEDURE to derive Bank Deposit Date-' ||lc_procedure_name|| ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
    END;
    SELECT xx_ce_mpl_settlement_id_s.nextval INTO lc_settlement_id FROM dual;
    Lc_Action := 'Validating Duplicate Settlement Id';

    FOR j IN dup_check_cur(lc_settlement_id)
    LOOP
      l_rec_cnt := l_rec_cnt + 1;
    END LOOP;
    IF L_Rec_Cnt > 0 THEN
      exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
      logit(p_message => 'Settlement Can not be processed , Duplicate Settlement id found in staging table-XX_CE_MPL_SETTLEMENT_HDR '||lc_settlement_id);
      RAISE_APPLICATION_ERROR(-20101, 'ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
    END IF;
    FOR rec_hdr IN cur_settlement_pre_stage_hdr(rec_file.filename)
    LOOP
      BEGIN
        lc_action           := 'Processing Google PreStage Header Data for PO#'||rec_hdr.google_po;
        lc_err_msg          :=NULL;
        lc_transaction_type :=NULL;
 
        SELECT XX_CE_MPL_HEADER_ID_SEQ.nextval INTO lc_mpl_header_id FROM dual;
        IF dup_check_transaction_type(p_process_name,rec_hdr.google_po,rec_hdr.transaction_type)='N' THEN
          FOR rec_dtl IN cur_settlement_pre_stage_dtl(rec_hdr.google_po,rec_hdr.transaction_type )
          LOOP
            lc_action := 'Processing Google PreStage Detail Data';
         
			
            BEGIN
              lc_ce_mpl_settlement_dtl                              :=NULL;
              lc_ce_mpl_settlement_dtl.mpl_header_id                := lc_mpl_header_id;
              lc_ce_mpl_settlement_dtl.marketplace_name             :=p_process_name;
              lc_ce_mpl_settlement_dtl.order_id                     := rec_dtl.google_po ;
              lc_ce_mpl_settlement_dtl.settlement_id                := lc_settlement_id ;
              lc_ce_mpl_settlement_dtl.transaction_id               := rec_dtl.GOOGLE_ORDER;
              lc_ce_mpl_settlement_dtl.adjustment_id                := NULL;
              lc_ce_mpl_settlement_dtl.shipment_id                  := NULL ;
              lc_ce_mpl_settlement_dtl.shipment_fee_type            := NULL;
              lc_ce_mpl_settlement_dtl.shipment_fee_amount          := NULL;
              lc_ce_mpl_settlement_dtl.order_fee_type               := NULL;
              lc_ce_mpl_settlement_dtl.order_fee_amount             := NULL;
              lc_ce_mpl_settlement_dtl.aops_order_number            :=NULL ;
              lc_ce_mpl_settlement_dtl.fulfillment_id               := NULL ;
              lc_ce_mpl_settlement_dtl.order_item_code              := rec_dtl.PARTNER_ITEM_ID ;
              lc_ce_mpl_settlement_dtl.merchant_order_item_id       := rec_dtl.PARTNER_ITEM_ID;
              lc_ce_mpl_settlement_dtl.merchant_adjustment_item_id  := NULL;
              lc_ce_mpl_settlement_dtl.sku                          := rec_dtl.PARTNER_ITEM_ID;
              lc_ce_mpl_settlement_dtl.misc_fee_amount              := NULL;
              lc_ce_mpl_settlement_dtl.other_fee_amount             := NULL;
              lc_ce_mpl_settlement_dtl.other_fee_reason_description := NULL;
              lc_ce_mpl_settlement_dtl.promotion_id                 := NULL;
              lc_ce_mpl_settlement_dtl.promotion_type               := NULL;
              lc_ce_mpl_settlement_dtl.promotion_amount             := NULL;
              lc_ce_mpl_settlement_dtl.direct_payment_type          := NULL;
              lc_ce_mpl_settlement_dtl.direct_payment_amount        := NULL;
              lc_ce_mpl_settlement_dtl.other_amount                 := NULL;
              lc_ce_mpl_settlement_dtl.store_number                 := NULL;
              lc_ce_mpl_settlement_dtl.record_status                := 'N';
              lc_ce_mpl_settlement_dtl.error_description            := NULL;
              lc_ce_mpl_settlement_dtl.request_id                   :=NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);
              lc_ce_mpl_settlement_dtl.created_by                   := NVL(FND_GLOBAL.USER_ID,        -1);
              lc_ce_mpl_settlement_dtl.creation_date                := SYSDATE;
              lc_ce_mpl_settlement_dtl.last_updated_by              := NVL(FND_GLOBAL.USER_ID, -1);
              lc_ce_mpl_settlement_dtl.last_update_date             := SYSDATE;
              lc_ce_mpl_settlement_dtl.last_update_login            := NVL(FND_GLOBAL.USER_ID, -1);
              lc_ce_mpl_settlement_dtl.attribute1                   := rec_dtl.GOOGLE_PO;
			  --SALE
              IF upper(rec_dtl.TRANSACTION_TYPE )                           ='ORDER'  THEN
                FOR j IN 1..3
                LOOP
                  lc_action             := 'Generate Google Record into Multiple Transactions';
                  lc_quantity_purchased :=NULL;
                  lc_unit_price         :=NULL;
                  lc_price_type         :=NULL;
                  l_price_amount        :=NULL;
            
                  IF j         =1 THEN
                    lc_action := 'Generate Google Record for Item';
                  
                    lc_quantity_purchased :=NVL(rec_dtl.Item_QTY,0);
                    lc_unit_price         :=ROUND(rec_dtl.unit_price,2);
                  END IF;
                  IF j         =2  AND rec_dtl.amount_description='Principal' THEN
                    lc_action := 'Generate Google Record for Principal Price Type';
                   
                    lc_price_type  :='Principal';
                    l_price_amount :=NVL(rec_dtl.Line_amount,0);
                  END IF;
				  IF j        =3  AND  upper(rec_dtl.amount_description) like '%MERCHANT%REMITTED%SALES%TAX%' THEN
                  lc_action      := 'Generate Google Record for Sales Tax Service Price Type';
                  lc_price_type  :='Tax';
                  l_price_amount :=NVL(rec_dtl.Line_amount,0) ;
				  END IF;
                  lc_ce_mpl_settlement_dtl.quantity_purchased      := lc_quantity_purchased;
                  lc_ce_mpl_settlement_dtl.unit_price              := lc_unit_price;
                  lc_ce_mpl_settlement_dtl.price_type              := lc_price_type;
                  lc_ce_mpl_settlement_dtl.price_amount            := l_price_amount;
                  INSERT INTO XX_CE_MPL_SETTLEMENT_DTL VALUES lc_ce_mpl_settlement_dtl;
                END LOOP;
				 
			  ELSIF upper(rec_dtl.TRANSACTION_TYPE)   like '%ORDER%REFUND%' 
				AND upper(rec_dtl.amount_description) like  ('%PRINCIPAL%')
			  THEN
                lc_action                                        := 'Generate Google Record for Principal Refund/Adjustment Price Type';
                 lc_price_type  :='Principal';
                  l_price_amount :=NVL(rec_dtl.Line_amount,0) ;
				
                INSERT INTO XX_CE_MPL_SETTLEMENT_DTL VALUES lc_ce_mpl_settlement_dtl;
			   
			  ELSIF upper(rec_dtl.TRANSACTION_TYPE)   like '%ORDER%REFUND%' 
				AND upper(rec_dtl.amount_description) like  ('%PRINCIPAL%TAX%')
			  THEN
                lc_action                                        := 'Generate Google Record for Sales Tax Refund Price Type';
                 lc_price_type  :='Tax';
                  l_price_amount :=NVL(rec_dtl.Line_amount,0) ;
				
                INSERT INTO XX_CE_MPL_SETTLEMENT_DTL VALUES lc_ce_mpl_settlement_dtl;
			   
              ELSIF upper(rec_dtl.TRANSACTION_TYPE)          like '%ISSUE%RELATED%REFUND%AND%REPLACEMENT%' THEN
                lc_action                                        := 'Generate Google Record for issue_related_refund_and_replacement';
                 lc_price_type  :='REFUND';
                  l_price_amount :=NVL(rec_dtl.Line_amount,0) ;
				
                INSERT INTO XX_CE_MPL_SETTLEMENT_DTL VALUES lc_ce_mpl_settlement_dtl;
			   
              ELSIF rec_dtl.TRANSACTION_TYPE                      ='Reversal' AND upper(rec_dtl.amount_description) like '%COMMISSION%' THEN
                lc_action                                        := 'Generate Google Record for Sales Tax Service Price Type';
                lc_item_related_fee_type                         := 'Commission'; --'Item commission';
                lc_ce_mpl_settlement_dtl.item_related_fee_type   := lc_item_related_fee_type;
                lc_ce_mpl_settlement_dtl.item_related_fee_amount := rec_dtl.Line_amount;
                
                INSERT INTO XX_CE_MPL_SETTLEMENT_DTL VALUES lc_ce_mpl_settlement_dtl;
			  
              ELSIF upper(rec_dtl.TRANSACTION_TYPE   )            like '%RETURN%SHIPPING%FEE%TRANSACTION%' THEN
                lc_action                                        := 'Generate Google Record for Return shipping Fee';
                lc_item_related_fee_type                         := 'Shipping';
                lc_ce_mpl_settlement_dtl.item_related_fee_type   := lc_item_related_fee_type;
                lc_ce_mpl_settlement_dtl.item_related_fee_amount := rec_dtl.Line_amount;
        
                INSERT INTO XX_CE_MPL_SETTLEMENT_DTL VALUES lc_ce_mpl_settlement_dtl;
              END IF;
            EXCEPTION
            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' ACTION: ' || lc_action || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
            END;
          END LOOP; --DTL Cursor
          lc_action                                      := 'Insert into XX_CE_MPL_SETTLEMENT_HDR Table for Google PO#-'||rec_hdr.google_po;
          Lc_Ce_Mpl_Settlement_Hdr                       :=NULL;
          lc_ce_mpl_settlement_hdr.mpl_header_id         :=lc_mpl_header_id;
          lc_ce_mpl_settlement_hdr.PROVIDER_TYPE         :=lt_translation_info.target_value14 ;
          lc_ce_mpl_settlement_hdr.settlement_id         :=lc_settlement_id ;
          lc_ce_mpl_settlement_hdr.settlement_start_date :=to_date(TO_CHAR(lc_settlement_start_date,'YYYY-MM-DD'),'YYYY-MM-DD') ;
          lc_ce_mpl_settlement_hdr.settlement_end_date   :=to_date(TO_CHAR(lc_settlement_end_date,'YYYY-MM-DD'),'YYYY-MM-DD') ;
          lc_ce_mpl_settlement_hdr.order_id              :=rec_hdr.google_po ;
          lc_ce_mpl_settlement_hdr.merchant_order_id     :=rec_hdr.google_po ;
          lc_ce_mpl_settlement_hdr.deposit_date          :=to_date(TO_CHAR(to_Date(lv_deposit_date,'DD-MM-YY'),'DD-MM-YYYY'),'DD-MM-YYYY');
          lc_ce_mpl_settlement_hdr.total_amount          :=NULL;
          lc_ce_mpl_settlement_hdr.currency              :=NULL;
          IF rec_hdr.transaction_type                     ='Order' THEN
            lc_ce_mpl_settlement_hdr.transaction_type    :=rec_hdr.transaction_type;
          ELSE
            lc_ce_mpl_settlement_hdr.transaction_type :='Adjustment';
          END IF;
          lc_ce_mpl_settlement_hdr.marketplace_name    :=p_process_name;
          lc_ce_mpl_settlement_hdr.split_order         :=NULL;
          lc_ce_mpl_settlement_hdr.PROCESSOR_ID        :=lt_translation_info.target_value13 ;
          lc_ce_mpl_settlement_hdr.posted_date         :=rec_file.posted_date ;
          lc_ce_mpl_settlement_hdr.ajb_998_amount      :=NULL;
          lc_ce_mpl_settlement_hdr.ajb_999_amount      :=NULL;
          lc_ce_mpl_settlement_hdr.ajb_996_amount      :=NULL;
          lc_ce_mpl_settlement_hdr.terminal_number     :=NULL;
          lc_ce_mpl_settlement_hdr.card_number         :=NULL;
          lc_ce_mpl_settlement_hdr.auth_number         :=NULL;
          lc_ce_mpl_settlement_hdr.action              :=NULL;
          lc_ce_mpl_settlement_hdr.record_status       :='N';
          lc_ce_mpl_settlement_hdr.record_status_stage :='NEW';
          lc_ce_mpl_settlement_hdr.error_description   :=NULL;
          lc_ce_mpl_settlement_hdr.request_id          :=NVL(FND_GLOBAL.CONC_REQUEST_ID, -1);
          Lc_Ce_Mpl_Settlement_Hdr.Created_By          :=NVL(Fnd_Global.User_Id,         -1);
          Lc_Ce_Mpl_Settlement_Hdr.Creation_Date       :=Sysdate;
          Lc_Ce_Mpl_Settlement_Hdr.Last_Updated_By     :=NVL(Fnd_Global.User_Id, -1);
          lc_ce_mpl_settlement_hdr.last_update_date    :=SYSDATE;
          Lc_Ce_Mpl_Settlement_Hdr.Last_Update_Login   :=NVL(Fnd_Global.User_Id, -1);
          Lc_Ce_Mpl_Settlement_Hdr.ajb_file_name       :=rec_file.filename||lc_settlement_id;
          INSERT INTO XX_CE_MPL_SETTLEMENT_HDR VALUES lc_ce_mpl_settlement_hdr;
          UPDATE XX_CE_GOOGLE_PRE_STG_V a
          SET a.process_flag    ='P',
            A.Err_Msg           =NULL
          WHERE A.order_id      =Rec_hdr.google_po
          AND a.process_flag   IN ('N','E')
          AND a.transaction_type=Rec_hdr.transaction_type;
          gc_success_count     :=gc_success_count+1;
        ELSE
          UPDATE XX_CE_GOOGLE_PRE_STG_V a
          SET a.process_flag    ='E',
            A.Err_Msg           ='Duplicate record found for Google PO#'
          WHERE A.order_id      =Rec_hdr.google_po
          AND a.process_flag   IN ('N','E')
          AND a.transaction_type=Rec_hdr.transaction_type;
          gc_failure_count     :=gc_failure_count+1;
        END IF;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        gc_failure_count:=gc_failure_count+1;
        lc_err_msg      :=SUBSTR('PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' ||sqlerrm,1,1000);
        UPDATE XX_CE_GOOGLE_PRE_STG_V a
        SET a.process_flag    ='E' ,
          a.err_msg           =lc_err_msg
        WHERE a.order_id      =rec_hdr.google_po
        AND a.process_flag   IN ('N','E')
        AND a.transaction_type=Rec_hdr.transaction_type;
        COMMIT;
      END;
    END LOOP; --HDR Cursor
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
  RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
END PROCESS_GOOGLE_PRESTG_DATA;
/**********************************************************************
* Main Procedure to Process MarketPlaces Transactions.
* this procedure calls individual MarketPlace procedures to process them.
***********************************************************************/
PROCEDURE MAIN_MPL_SETTLEMENT_PROCESS(
    errbuff OUT VARCHAR2,
    retcode OUT NUMBER,
    p_market_place IN VARCHAR2,
    p_debug_flag   IN VARCHAR2 DEFAULT 'N' )
IS
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'MAIN_MPL_SETTLEMENT_PROCESS';
  lt_parameters gt_input_parameters;
  lt_program_setups gt_translation_values;
  lc_action VARCHAR2(1000);
BEGIN
  lt_parameters('p_market_place') := p_market_place;
  lt_parameters('p_debug_flag')   := p_debug_flag;
  entering_main(p_procedure_name => lc_procedure_name, p_rice_identifier => 'I3123', p_debug_flag => p_debug_flag, p_parameters => lt_parameters);
  /******************************
  * Initialize program variables.
  ******************************/
  /* retcode   := 0;
  lc_action := 'Deriving Program Setups';
  get_program_setups(x_program_setups => lt_program_setups); */
  lt_translation_info               := NULL;
  lt_translation_info.source_value1 :=p_market_place ;
  get_translation_info(p_translation_name => 'OD_SETTLEMENT_PROCESSES', px_translation_info => lt_translation_info);
  print_output('                                             OD CE Market Places Process Settlement Program');
  print_output('                                            --------------------------------------------------');
  print_output('');
  print_output('');
  print_output('Parameters:');
  print_output('-------------:');
  print_output('Market Place Name                    :'||p_market_place);
  print_output('Debug Flag                           :'||p_debug_flag);
  print_output('Concurrent Request ID                :'||fnd_global.conc_request_id);
  print_output('');
  print_output('');
  /******************************
  * Call EBAY Process.
  ******************************/
  lc_action := 'Process EBAY MarketPlace';
  IF p_market_place IN ('EBAY_MPL') THEN
    PROCESS_EBAY_PRESTG_DATA (p_market_place);
  END IF;
  /******************************
  * Call Walmart Process.
  ******************************/
  lc_action := 'Process Walmart MarketPlace';
  IF p_market_place IN ('WALMART_MPL') THEN
    PROCESS_WALMART_PRESTG_DATA (p_market_place);
  END IF;
  /******************************
  * Call Google Process. --NAIT-102710
  ******************************/
  lc_action := 'Process Google MarketPlace';
  IF p_market_place IN ('GOOGLE_MPL') THEN
    PROCESS_GOOGLE_PRESTG_DATA (p_market_place);
  END IF;
  /******************************
  * Call Rakuten Process.
  ******************************/
  lc_action := 'Process Rakuten MarketPlace';
  IF p_market_place IN ('RAKUTEN_MPL') THEN
    PROCESS_RAKUTEN_PRESTG_DATA (p_market_place);
  END IF;

   /******************************
  * Call NEWEGG Process.
  ******************************/
  lc_action := 'Process NEWEGG MarketPlace';
  IF p_market_place IN ('NEWEGG_MPL') THEN
    PROCESS_NEWEGG_PRESTG_DATA (p_market_place);
  END IF;

  print_output('Processing Details by Stage:');
  print_output('----------------------------:');
  print_output('/*Load Prestaging Data:*/');
  print_output('-------------------------:');
  print_output('Total Record Count        :'||(gc_success_count+gc_failure_count));
  print_output('Success Record Count      :'||gc_success_count);
  print_output('Failure Record Count      :'||gc_failure_count);
  gc_success_count:=0;
  gc_failure_count:=0;
  lc_action       := 'Derive Oracle EBS Order Information for Unprocessed MPL Orders';
  DERIVE_MPL_ORDER_INFO(p_market_place);
  print_output('');
  print_output('/*Validation Stage:*/');
  print_output('--------------------:');
  print_output('Total Record Count        :'||(gc_success_count+gc_failure_count));
  print_output('Success Record Count      :'||gc_success_count);
  print_output('Failure Record Count      :'||gc_failure_count);
  gc_success_count:=0;
  gc_failure_count:=0;
  lc_action       := 'Process validated MPL Orders to AJB998 ';
  process_mpl_998(p_market_place);
  print_output('');
  print_output('/*Process AJB998 Stage:*/');
  print_output('-------------------------:');
  print_output('Total Record Count        :'||(gc_success_count+gc_failure_count));
  print_output('Success Record Count      :'||gc_success_count);
  print_output('Failure Record Count      :'||gc_failure_count);
  gc_success_count:=0;
  gc_failure_count:=0;
  lc_action       := 'Process validated MPL Orders to AJB999 ';
  print_output('');
  process_mpl_999(p_market_place);
  print_output('/*Process AJB999 Stage:*/');
  print_output('-------------------------:');
  print_output('Total Record Count        :'||(gc_success_count+gc_failure_count));
  print_output('Success Record Count      :'||gc_success_count);
  print_output('Failure Record Count      :'||gc_failure_count);
  gc_success_count:=0;
  gc_failure_count:=0;
  lc_action       := 'Submit AJB Preprocessor Program';
  print_output('');
  INVOKE_AJBPREPROCESSOR_PROG(p_market_place);
EXCEPTION
WHEN OTHERS THEN
  logit(p_message => 'ERROR-SQLCODE:'|| SQLCODE || ' SQLERRM: ' || SQLERRM, p_force => TRUE);
  retcode := 2;
  errbuff := 'Error encountered. Please check logs';
  exiting_sub(p_procedure_name => lc_procedure_name, p_exception_flag => TRUE);
END MAIN_MPL_SETTLEMENT_PROCESS;
END XX_CE_MRKTPLC_RECON_PKG;
/
