SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE BODY xx_ar_subscr_mft_file_pkg
AS
  -- +=========================================================================
  -- ====================+
  -- |  Office Depot
  -- |
  -- +=========================================================================
  -- ===================+
  -- |  Name:  XX_AR_SUBSCR_MFT_FILE_PKG
  -- |
  -- |
  -- |
  -- |  Description:  This package is to used to update the Receipt Numbers in
  -- the Subscriptions  |
  -- |                table for AB Customers where the receipt_number is NULL
  -- |
  -- |
  -- |
  -- |  Change Record:
  -- |
  -- +=========================================================================
  -- ===================+
  -- | Version     Date         Author           Remarks
  -- |
  -- | =========   ===========  =============    ==============================
  -- =================  |
  -- | 1.0         05-JUN-2019  PUNIT_CG         Initial version  for Defect#
  -- NAIT-95909          |
  -- | 2.0         01-AUG-2019  Deepak_CG        changes in c_get_mft_data
  -- cursor,                |
  -- |                                           initial_auth_attempt_date
  -- clause                 |
  -- | 1.1         17-SEP-19    Priyam P         added wrapper program to be
  -- called from Shell script
  --|  1.2         26-SEP-19     Priyam P        Changed Cursor c_get_mft_data
  -- +=========================================================================
  -- ===================+
  gc_package_name CONSTANT all_objects.object_name%TYPE :=
  'XX_AR_SUBSCR_MFT_FILE_PKG';
  gc_max_log_size   CONSTANT NUMBER := 2000;
  gc_max_print_size CONSTANT NUMBER := 2000;
  gb_debug          BOOLEAN         := FALSE;
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
/*********************************************************************
* Procedure used to log based on gb_debug value or if p_debug is TRUE.
* Will prepend timestamps to each message logged.
* This is useful for determining elapse times.
*********************************************************************/
PROCEDURE logit(
    p_message IN VARCHAR2,
    p_debug   IN BOOLEAN DEFAULT FALSE)
IS
  lc_message VARCHAR2(2000) := NULL;
BEGIN
  IF (gb_debug) THEN
    lc_message := SUBSTR(TO_CHAR(SYSTIMESTAMP, 'MM/DD/YYYY HH24:MI:SS.FF') ||
    ' => ' || p_message, 1, gc_max_log_size);
    IF (fnd_global.conc_request_id > 0) THEN
      fnd_file.put_line(fnd_file.LOG, lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END logit;
/*************************************************************************
* Procedure used to print the output of the program.
* Will display the Invoices and the corresponding Receipt numbers updated.
**************************************************************************/
PROCEDURE printit(
    p_out_message IN VARCHAR2)
IS
  lc_out_message VARCHAR2(2000) := NULL;
BEGIN
  lc_out_message                := SUBSTR(p_out_message,1, gc_max_print_size);
  IF (fnd_global.conc_request_id > 0) THEN
    fnd_file.put_line(fnd_file.output, lc_out_message);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END printit;
/*********************************************************
* Helper procedure to log that the main procedure/function
* has been called. Sets the debug flag and logs the
* procedure name and the tasks done by the procedure.
**********************************************************/
PROCEDURE mft_generate_file(
    p_errbuf OUT VARCHAR2,
    p_retcode OUT VARCHAR2,
    p_debug_flag IN VARCHAR2,
    p_as_of_date IN VARCHAR2)
AS
  CURSOR c_get_mft_data
  IS
    SELECT
      XAS.contract_number,
      XAS.contract_id,
      xas.billing_sequence_number,
      XAS.initial_order_number,
      XAS.contract_name,
      XAC.card_type,
      XAC.card_token,
      TO_CHAR(XAC.card_expiration_date,'YYMM') card_expiration_date,
      XAC.card_encryption_label,
      XAC.card_encryption_hash,
      XAS.authorization_code auth_status,
      NVL(XAS.auth_message,'UNDEFINED') auth_message,
      TO_CHAR(XAS.last_auth_attempt_date,'DDMMYYYY') error_date,
      MAX(xas.contract_line_number)
    FROM
      xx_ar_subscriptions XAS,
      xx_ar_contracts XAC
    WHERE
      XAS.auth_completed_flag        = 'E'
    AND XAC.contract_id              = XAS.contract_id
    AND XAS.billing_sequence_number IN
      (
        SELECT
          MAX(XAS1.billing_sequence_number)
        FROM
          xx_ar_subscriptions XAS1
        WHERE
          XAS1.contract_id = XAS.contract_id
      )
    /* AND XAS.contract_line_number IN
    (
    SELECT
    MAX(XAS2.contract_line_number)
    FROM
    xx_ar_subscriptions XAS2
    WHERE
    XAS2.contract_id = XAS.contract_id
    )*/
  AND TRUNC(XAS.initial_auth_attempt_date) = TRUNC(fnd_date.canonical_to_date(
    NVL(p_as_of_date,SYSDATE)))
  GROUP BY
    XAS.contract_number,
    XAS.contract_id,
    xas.billing_sequence_number,
    XAS.initial_order_number,
    XAS.contract_name,
    XAC.card_type,
    XAC.card_token,
    TO_CHAR(XAC.card_expiration_date,'YYMM'),
    XAC.card_encryption_label,
    XAC.card_encryption_hash,
    XAS.authorization_code,
    NVL(XAS.auth_message,'UNDEFINED'),
    TO_CHAR(XAS.last_auth_attempt_date,'DDMMYYYY');
  
TYPE LC_MFT_DATA_TAB
IS
  TABLE OF c_get_mft_data%ROWTYPE INDEX BY PLS_INTEGER;
  LC_MFT_DATA LC_MFT_DATA_TAB;
  lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' ||
  'mft_generate_file';
  lt_file_handle UTL_FILE.file_type;
  lt_file_name    VARCHAR2(100) := TO_CHAR(NULL);
  lc_file_path    VARCHAR(200);
  ln_max_linesize NUMBER := 32000;
  ln_rec_cnt      NUMBER := 0;
  lc_errormsg     VARCHAR2(1000);
BEGIN
  set_debug(p_debug_flag => p_debug_flag);
  logit(p_message => '---------------------------------------------------',
  p_debug => TRUE);
  logit(p_message => 'Starting MFT File Creation routine. ', p_debug => TRUE);
  logit(p_message => '---------------------------------------------------',
  p_debug => TRUE);
  BEGIN
    SELECT
      directory_path
    INTO
      lc_file_path
    FROM
      dba_directories
    WHERE
      directory_name = 'XXFIN_VANTIV_SBS';
  EXCEPTION
  WHEN OTHERS THEN
    lc_file_path := NULL;
  END;
  lt_file_name := 'ODVANTIV_SBS'||'_'||TO_CHAR (SYSDATE,'DDMONYYYYHH24MISS')||
  '.txt';
  logit(p_message => '---------------------------------------------------',
  p_debug => TRUE);
  logit(p_message => 'File Name is: '||lt_file_name||' and File Path is: '||
  lc_file_path, p_debug => TRUE);
  logit(p_message => '---------------------------------------------------',
  p_debug => TRUE);
  lt_file_handle := UTL_FILE.fopen('XXFIN_VANTIV_SBS',lt_file_name,'W',
  ln_max_linesize);
  OPEN c_get_mft_data;
  FETCH
    c_get_mft_data BULK COLLECT
  INTO
    LC_MFT_DATA;
  CLOSE c_get_mft_data;
  IF LC_MFT_DATA.COUNT > 0 THEN
    FOR l_rec IN LC_MFT_DATA.FIRST..LC_MFT_DATA.LAST
    LOOP
      /************************************************************************
      **************
      * LOOP Through the error data which needs to be inserted in the MFT file
      *************************************************************************
      **************/
      logit(p_message =>
      '--------------------------------------------------------------------------------------------------------------------------------'
      , p_debug => TRUE);
      logit(p_message => 'START of inserting Record for Contract #: ' ||
      LC_MFT_DATA(l_rec).contract_number, p_debug => TRUE);
      logit(p_message =>
      '--------------------------------------------------------------------------------------------------------------------------------'
      , p_debug => TRUE);
      ln_rec_cnt := ln_rec_cnt + 1;
      UTL_FILE.put_line(lt_file_handle, RPAD(SUBSTR(LC_MFT_DATA(l_rec)
      .contract_number,1,8),10)|| RPAD(SUBSTR(LC_MFT_DATA(l_rec).contract_id,1,
      18),20)|| RPAD(SUBSTR(NVL(LC_MFT_DATA(l_rec).initial_order_number,' '),1,
      23),25)|| RPAD(SUBSTR(NVL(LC_MFT_DATA(l_rec).contract_name,' '),1,23),25)
      || RPAD(SUBSTR(NVL(LC_MFT_DATA(l_rec).card_type,' '),1,13),15)|| RPAD(
      SUBSTR(NVL(LC_MFT_DATA(l_rec).card_token,' '),1,53),55)|| RPAD(SUBSTR(NVL
      (LC_MFT_DATA(l_rec).card_expiration_date,' '),1,4),6)|| RPAD(SUBSTR(NVL(
      LC_MFT_DATA(l_rec).card_encryption_label,' '),1,28),30)|| RPAD(SUBSTR(NVL
      (LC_MFT_DATA(l_rec).card_encryption_hash,' '),1,43),45)|| RPAD(SUBSTR(NVL
      (LC_MFT_DATA(l_rec).auth_status,' '),1,8),10)|| RPAD(SUBSTR(NVL(
      LC_MFT_DATA(l_rec).auth_message,' '),1,98),100)|| RPAD(SUBSTR(NVL(
      LC_MFT_DATA(l_rec).error_date,' '),1,8),10) );
    END LOOP;
    UTL_FILE.put_line(lt_file_handle,CHR(10)||'Total Number Of Records : '||
    ln_rec_cnt);
    UTL_FILE.fclose(lt_file_handle);
  END IF;
EXCEPTION
WHEN UTL_FILE.ACCESS_DENIED THEN
  lc_errormsg := ( 'AR Subscription Generate MFT File Program Errored :- ' ||
  ' access_denied :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  logit (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lt_file_handle := UTL_FILE.fopen (lc_file_path, lt_file_name, 'W', 32767);
  UTL_FILE.fclose(lt_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.DELETE_FAILED THEN
  lc_errormsg := ( 'AR Subscription Generate MFT File Program Errored :- ' ||
  ' delete_failed :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  logit (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lt_file_handle := UTL_FILE.fopen (lc_file_path, lt_file_name, 'W', 32767);
  UTL_FILE.fclose(lt_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.FILE_OPEN THEN
  lc_errormsg := ( 'AR Subscription Generate MFT File Program Errored :- ' ||
  ' file_open :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  logit (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lt_file_handle := UTL_FILE.fopen (lc_file_path, lt_file_name, 'W', 32767);
  UTL_FILE.fclose(lt_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.INTERNAL_ERROR THEN
  lc_errormsg := ( 'AR Subscription Generate MFT File Program Errored :- ' ||
  ' internal_error :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  logit (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lt_file_handle := UTL_FILE.fopen (lc_file_path, lt_file_name, 'W', 32767);
  UTL_FILE.fclose(lt_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.INVALID_FILEHANDLE THEN
  lc_errormsg := ( 'AR Subscription Generate MFT File Program Errored :- ' ||
  ' invalid_filehandle :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  logit (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lt_file_handle := UTL_FILE.fopen (lc_file_path, lt_file_name, 'W', 32767);
  UTL_FILE.fclose(lt_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.INVALID_FILENAME THEN
  lc_errormsg := ( 'AR Subscription Generate MFT File Program Errored :- ' ||
  ' invalid_filename :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  logit (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lt_file_handle := UTL_FILE.fopen (lc_file_path, lt_file_name, 'W', 32767);
  UTL_FILE.fclose(lt_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
  lc_errormsg := ( 'AR Subscription Generate MFT File Program Errored :- ' ||
  ' invalid_maxlinesize :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  logit (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lt_file_handle := UTL_FILE.fopen (lc_file_path, lt_file_name, 'W', 32767);
  UTL_FILE.fclose(lt_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.invalid_mode THEN
  lc_errormsg := ( 'AR Subscription Generate MFT File Program Errored :- ' ||
  ' invalid_mode :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  logit (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lt_file_handle := UTL_FILE.fopen (lc_file_path, lt_file_name, 'W', 32767);
  UTL_FILE.fclose(lt_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.invalid_offset THEN
  lc_errormsg := ( 'AR Subscription Generate MFT File Program Errored :- ' ||
  ' invalid_offset :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  logit (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lt_file_handle := UTL_FILE.fopen (lc_file_path, lt_file_name, 'W', 32767);
  UTL_FILE.fclose(lt_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.invalid_operation THEN
  lc_errormsg := ( 'AR Subscription Generate MFT File Program Errored :- ' ||
  ' invalid_operation :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  logit (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lt_file_handle := UTL_FILE.fopen (lc_file_path, lt_file_name, 'W', 32767);
  UTL_FILE.fclose(lt_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.invalid_path THEN
  lc_errormsg := ( 'AR Subscription Generate MFT File Program Errored :- ' ||
  ' invalid_path :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  logit (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lt_file_handle := UTL_FILE.fopen (lc_file_path, lt_file_name, 'W', 32767);
  UTL_FILE.fclose(lt_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.read_error THEN
  lc_errormsg := ( 'AR Subscription Generate MFT File Program Errored :- ' ||
  ' read_error :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  logit (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lt_file_handle := UTL_FILE.fopen (lc_file_path, lt_file_name, 'W', 32767);
  UTL_FILE.fclose(lt_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.rename_failed THEN
  lc_errormsg := ( 'AR Subscription Generate MFT File Program Errored :- ' ||
  ' rename_failed :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  logit (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lt_file_handle := UTL_FILE.fopen (lc_file_path, lt_file_name, 'W', 32767);
  UTL_FILE.fclose(lt_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.write_error THEN
  lc_errormsg := ( 'AR Subscription Generate MFT File Program Errored :- ' ||
  ' write_error :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  logit (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lt_file_handle := UTL_FILE.fopen (lc_file_path, lt_file_name, 'W', 32767);
  UTL_FILE.fclose(lt_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN OTHERS THEN
  lc_errormsg := ( 'AR Subscription Generate MFT File Program Errored :- ' ||
  ' Others Exception :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name ||
  ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
  p_retcode := 2;
  p_errbuf  := lc_errormsg;
END mft_generate_file;
PROCEDURE mft_generate_file_wrapper(
    p_debug_flag IN VARCHAR2,
    p_as_of_date IN VARCHAR2)
IS
  v_err_buf   VARCHAR2(2000);
  v_retcode   NUMBER;
  lc_errormsg VARCHAR2(1000);
BEGIN
  xx_ar_subscr_mft_file_pkg.mft_generate_file(v_err_buf,v_retcode,p_debug_flag,
  p_as_of_date);
EXCEPTION
WHEN OTHERS THEN
  lc_errormsg := (
  'AR Subscription Generate MFT File Wrapper Program Errored :- ' ||
  ' Others Exception :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  v_retcode := 2;
  v_err_buf := lc_errormsg;
END mft_generate_file_wrapper;
END xx_ar_subscr_mft_file_pkg;


/
SHOW ERRORS;
EXIT;