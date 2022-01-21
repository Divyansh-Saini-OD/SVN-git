SET VERIFY OFF
SET ECHO OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT Creating PACKAGE  BODY XX_GL_BAL_ARCS_RC_OB_PKG
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE

create or replace 
PACKAGE BODY XX_GL_BAL_ARCS_RC_OB_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_GL_BAL_ARCS_OB_PKG                                                       |
-- |  RICE ID 	 :  GL Balances Outbound Interface to ARCS   	                                |
-- |  Description:         								        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         03-OCT-18    Priyam       Jira -63426 GL ARCS modified for Reporting currency               |
-- +============================================================================================+
  gc_debug VARCHAR2(2) := 'N';
  gn_request_id fnd_concurrent_requests.request_id%TYPE;
  gn_user_id fnd_concurrent_requests.requested_by%TYPE;
  gn_login_id NUMBER;
  /*********************************************************************
  * Procedure used to log based on gb_debug value or if p_force is TRUE.
  * Will log to dbms_output if request id is not set,
  * else will log to concurrent program log file.  Will prepend
  * timestamp to each message logged.  This is useful for determining
  * elapse times.
  *********************************************************************/
PROCEDURE print_debug_msg(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT FALSE)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  IF (gc_debug  = 'Y' OR p_force) THEN
    lc_Message := P_Message;
    fnd_file.put_line (fnd_file.log, lc_Message);
    IF ( fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
      dbms_output.put_line (lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_debug_msg;
/*********************************************************************
* Procedure used to out the text to the concurrent program.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program output file.
*********************************************************************/
PROCEDURE print_out_msg(
    p_message IN VARCHAR2)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  lc_message := p_message;
  fnd_file.put_line (fnd_file.output, lc_message);
  IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
    dbms_output.put_line (lc_message);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_out_msg;
-- +============================================================================================+
-- |  Name   : populate_gl_out_file                                                         |
-- |  Description: This procedure retrieves data from table an d writes data to the outbound file|
-- =============================================================================================|
PROCEDURE populate_gl_out_file(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT NUMBER ,
    p_period_name IN VARCHAR2 ,
    p_debug       IN VARCHAR2)
IS
  CURSOR c_get_gl_data(c_period_name VARCHAR2) 
	IS
   SELECT gcc.segment1 Company,
      gcc.segment2 cost_center,
      gcc.segment3 Account,
      gcc.segment4 Location,
      gcc.segment5 Intercompany,
      gcc.segment6 LOB,
      gcc.segment7 future,
      SUM (NVL (gb.begin_balance_dr, 0) - NVL (gb.begin_balance_cr, 0) ) ytd_beginning_bal,
      SUM (NVL (gb.period_net_dr, 0) ) ptd_net_dr,
      SUM (NVL (gb.period_net_cr, 0) ) ptd_net_cr,
      SUM((NVL(gb.period_net_dr, 0) + NVL(gb.begin_balance_dr, 0))) - SUM( NVL( gb.period_net_cr, 0) + NVL(gb.begin_balance_cr, 0)) ytd_balance,
      gb.currency_code,
      gld.ledger_id,
      gb.period_name,
      gcc.code_combination_id,
      gb.actual_flag balance_type,
      (SELECT REPLACE(fvv.description, ',', '_')
      FROM FND_FLEX_VALUE_SETS fvs,
        FND_FLEX_VALUES_VL fvv
      WHERE FLEX_VALUE_SET_NAME = 'OD_GL_GLOBAL_ACCOUNT'
      AND FVS.FLEX_VALUE_SET_ID = FVV.FLEX_VALUE_SET_ID
      AND fvv.FLEX_VALUE        =gcc.segment3
      ) account_description
  FROM GL_LOOKUPS GLLookups,
    gl_ledger_config_details glcd,
    gl_code_combinations gcc,
    GL_BALANCES GB,
     gl_ledgers gld
  where 1 = 1
  and Gld.SHORT_NAME in ('CA_CAD_P','US_USD_P','UK_GBP_P')
  AND gb.ledger_id           =gld.ledger_id
  and GB.PERIOD_NAME          = C_PERIOD_NAME
 -- and gb.ledger_id in (6002,7004,6003) 
  and gb.currency_code='USD'
  AND gb.actual_flag          = 'A'
  and GB.TEMPLATE_ID         is null
 -- and  (gb.TRANSLATED_FLAG != 'R' OR gb.TRANSLATED_FLAG IS NULL)
  and  NVL(gb.TRANSLATED_FLAG,'Z') not in ('R')
 --- AND gld.currency_code       = gb.currency_code
  AND gcc.code_combination_id = gb.code_combination_id
  AND gcc.account_type       IN
    (SELECT vals.target_value1
    FROM xx_fin_translatevalues vals,
      xx_fin_translatedefinition defn
    WHERE defn.translate_id   = vals.translate_id
    AND defn.translation_name = 'OD_ARCS_GL_ACCOUNT_TYPE'
    AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
    AND SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
    AND vals.enabled_flag = 'Y'
    AND defn.enabled_flag = 'Y'
    )
  ---AND gcc.enabled_flag         ='Y' Code Commented for NAIT-59916
  AND gcc.summary_flag         = 'N'
  AND gcc.chart_of_accounts_id = gld.chart_of_accounts_id
  AND gld.configuration_id     = glcd.configuration_id
  AND glcd.object_type_code    = 'PRIMARY'
  AND glcd.setup_step_code     = 'NONE'
  AND GLLookups.lookup_type    = 'GL_ASF_LEDGER_CATEGORY'
  AND GLLookups.lookup_code    = gld.ledger_category_code
  GROUP BY gld.NAME,
    gcc.segment1,
    gcc.segment2,
    gcc.segment3,
    gcc.segment4,
    gcc.segment5,
    gcc.segment6,
    gcc.segment7,
    gld.ledger_id,
    gb.currency_code,
    gb.period_name,
    gcc.code_combination_id,
    gb.translated_flag,
    gb.template_id,
    gb.actual_flag,
    GLLookups.meaning,
    glcd.object_name;
TYPE LC_GL_DATA_TAB
IS
  TABLE OF c_get_gl_data%ROWTYPE INDEX BY PLS_INTEGER;
  LC_GL_DATA LC_GL_DATA_TAB;
  lc_file_handle UTL_FILE.file_type;
  lv_line_count NUMBER;
  l_file_path   VARCHAR(200);
  l_file_name   VARCHAR2(100);
  lv_col_title  VARCHAR2(1000);
  lc_errormsg   VARCHAR2(1000);
  lv_account_type xx_fin_translatevalues.target_value1%TYPE;
  lv_ob_dba_dir xx_fin_translatevalues.target_value1%TYPE;
  lv_ob_arch_dba_dir xx_fin_translatevalues.target_value1%TYPE;
  ln_conc_file_copy_request_id NUMBER;
  lc_dest_file_name            VARCHAR2(200);
  lc_source_file_name          VARCHAR2(200);
  lc_instance_name             VARCHAR2(30);
  lb_complete                  BOOLEAN;
  lc_phase                     VARCHAR2(100);
  lc_status                    VARCHAR2(100);
  lc_dev_phase                 VARCHAR2(100);
  lc_dev_status                VARCHAR2(100);
  lc_message                   VARCHAR2(100);
BEGIN
  print_debug_msg('Begin - populate_glbalances_file', TRUE);
  gc_debug      := p_debug;
  gn_request_id := fnd_global.conc_request_id;
  gn_user_id    := fnd_global.user_id;
  gn_login_id   := fnd_global.login_id;
  lv_line_count := 0;
  BEGIN
    SELECT directory_path
    INTO l_file_path
    FROM dba_directories
    WHERE directory_name = 'XXFIN_OUTBOUND';
  EXCEPTION
  WHEN OTHERS THEN
    l_file_path := NULL;
  END;
  SELECT SUBSTR(LOWER(SYS_CONTEXT('USERENV', 'INSTANCE_NAME') ), 1, 8)
  INTO lc_instance_name
  FROM DUAL;
  l_file_name    := 'ARCS_EBSUS_' || p_period_name || '.txt';
  lc_file_handle := UTL_FILE.fopen('XXFIN_OUTBOUND', l_file_name, 'W', 32767);
  print_out_msg('');
  print_debug_msg ('File Name : '||l_file_name, TRUE);
  print_debug_msg ('Outbound File Path : '||l_file_path, TRUE);
  lv_col_title := 'COMPANY' || ','|| 'COST_CENTER' || ','|| 'ACCOUNT' || ','|| 'LOCATION' || ','|| 'INTERCOMPANY' || ','|| 'LOB' || ','|| 'FUTURE' || ','|| 'YTD_BEGINNING_BAL' || ','|| 'PTD_NET_DR' || ','|| 'PTD_NET_CR' || ','|| 'YTD_BALANCE' || ','|| 'CURRENCY_CODE' || ','|| 'LEDGER_ID' || ','|| 'PERIOD_NAME' || ','|| 'CODE_COMBINATION_ID' || ','|| 'BALANCE_TYPE' || ','|| 'ACCOUNT_DESCRIPTION';
  UTL_FILE.put_line(lc_file_handle,lv_col_title);
  --print_debug_msg (lv_col_title, TRUE);
  OPEN c_get_gl_data(p_period_name);
  FETCH c_get_gl_data BULK COLLECT INTO LC_GL_DATA;
  CLOSE c_get_gl_data;
  IF LC_GL_DATA.COUNT > 0 THEN
    FOR l_rec IN LC_GL_DATA.FIRST..LC_GL_DATA.LAST
    LOOP
	 if LC_GL_DATA(l_rec).YTD_BEGINNING_BAL<>0 or LC_GL_DATA(l_rec).PTD_NET_DR<>0 or LC_GL_DATA(l_rec).PTD_NET_CR<>0 or LC_GL_DATA(l_rec).YTD_BALANCE <>0 then
			  UTL_FILE.put_line(lc_file_handle,
					     LC_GL_DATA(l_rec).COMPANY||','|| 
                                             LC_GL_DATA(l_rec).COST_CENTER||','|| 
                                             LC_GL_DATA(l_rec).ACCOUNT||','|| 
                                             LC_GL_DATA(l_rec).LOCATION||','|| 
                                             LC_GL_DATA(l_rec).INTERCOMPANY||','|| 
                                             LC_GL_DATA(l_rec).LOB||','|| 
                                             LC_GL_DATA(l_rec).FUTURE||','|| 
                                             LC_GL_DATA(l_rec).YTD_BEGINNING_BAL||','||
                                             ''||','||
                                             ''||','||
                                             LC_GL_DATA(l_rec).YTD_BALANCE||','||
                                             LC_GL_DATA(l_rec).CURRENCY_CODE||','||
                                             LC_GL_DATA(l_rec).LEDGER_ID||','||
                                             LC_GL_DATA(l_rec).PERIOD_NAME||','||
                                             LC_GL_DATA(l_rec).CODE_COMBINATION_ID||','||
                                             LC_GL_DATA(l_rec).BALANCE_TYPE||','||
                                             LC_GL_DATA(l_rec).ACCOUNT_DESCRIPTION                                             
                                            );
											
			end if;
	END LOOP;
    UTL_FILE.fclose(lc_file_handle);
    -- Archive the file
    print_debug_msg('Calling the Common File Copy Program to archive this OutBound file to Archive folder',TRUE);
    lc_dest_file_name            := '/app/ebs/ct' || lc_instance_name || '/xxfin/ftp/out/ARCS/' || l_file_name;
    lc_source_file_name          := l_file_path||'/' ||l_file_name;
    ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN', 'XXCOMFILCOPY', '', '', FALSE, lc_source_file_name, --Source File Name
    lc_dest_file_name,                                                                                                      --Dest File Name
    '', '', 'N'                                                                                                             --Deleting the Source File
    );
    IF ln_conc_file_copy_request_id > 0 THEN
      COMMIT;
      -- wait for request to finish
      lb_complete := fnd_concurrent.wait_for_request(request_id => ln_conc_file_copy_request_id, INTERVAL => 10, max_wait => 0, phase => lc_phase, status => lc_status, dev_phase => lc_dev_phase, dev_status => lc_dev_status, MESSAGE => lc_message);
    END IF;
    print_debug_msg('Request Id of Common Copy , to archive, is '||ln_conc_file_copy_request_id,TRUE);
    print_out_msg('File Extracted in Outbound Directory :'|| lc_source_file_name);
    print_out_msg('File Copied to MFT Directory         :'|| lc_dest_file_name);
    print_debug_msg('File Extracted in Outbound Directory :'|| lc_source_file_name);
    print_debug_msg('File Copied to MFT Directory         :'|| lc_dest_file_name);
  END IF;
  print_debug_msg('End of Procedure - populate_glbalances_file', TRUE);
EXCEPTION
when UTL_FILE.ACCESS_DENIED then
  lc_errormsg := ( 'ARCS GL Balances Reporting Currency Outbound Program Errored :- ' || ' access_denied :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
  UTL_FILE.fclose(lc_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
when UTL_FILE.DELETE_FAILED then
  lc_errormsg := ( 'ARCS GL Balances Reporting Currency Outbound Program Errored :- ' || ' delete_failed :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
  UTL_FILE.fclose(lc_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
when UTL_FILE.FILE_OPEN then
  lc_errormsg := ( 'ARCS GL Balances Reporting Currency Outbound Program Errored :- ' || ' file_open :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
  UTL_FILE.fclose(lc_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
when UTL_FILE.INTERNAL_ERROR then
  lc_errormsg := ( 'ARCS GL Balances Reporting Currency Outbound Program Errored :- ' || ' internal_error :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
  UTL_FILE.fclose(lc_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
when UTL_FILE.INVALID_FILEHANDLE then
  lc_errormsg := ( 'ARCS GL Balances Reporting Currency Outbound Program Errored :- ' || ' invalid_filehandle :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
  UTL_FILE.fclose(lc_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
when UTL_FILE.INVALID_FILENAME then
  lc_errormsg := ( 'ARCS GL Balances Reporting Currency Outbound Program Errored :- ' || ' invalid_filename :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
  UTL_FILE.fclose(lc_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
when UTL_FILE.INVALID_MAXLINESIZE then
  lc_errormsg := ( 'ARCS GL Balances Reporting Currency Outbound Program Errored :- ' || ' invalid_maxlinesize :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
  UTL_FILE.fclose(lc_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.invalid_mode THEN
  lc_errormsg := ( 'ARCS GL Balances Outbound Program Errored :- ' || ' invalid_mode :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
  UTL_FILE.fclose(lc_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.invalid_offset THEN
  lc_errormsg := ( 'ARCS GL Balances Outbound Program Errored :- ' || ' invalid_offset :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
  UTL_FILE.fclose(lc_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.invalid_operation THEN
  lc_errormsg := ( 'ARCS GL Balances Outbound Program Errored :- ' || ' invalid_operation :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
  UTL_FILE.fclose(lc_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.invalid_path THEN
  lc_errormsg := ( 'ARCS GL Balances Outbound Program Errored :- ' || ' invalid_path :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
  UTL_FILE.fclose(lc_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.read_error THEN
  lc_errormsg := ( 'ARCS GL Balances Outbound Program Errored :- ' || ' read_error :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
  UTL_FILE.fclose(lc_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.rename_failed THEN
  lc_errormsg := ( 'ARCS GL Balances Outbound Program Errored :- ' || ' rename_failed :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
  UTL_FILE.fclose(lc_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN UTL_FILE.write_error THEN
  lc_errormsg := ( 'ARCS GL Balances Outbound Program Errored :- ' || ' write_error :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg (lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
  UTL_FILE.fclose(lc_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
WHEN OTHERS THEN
  lc_errormsg := ( 'ARCS GL Balances Outbound Program Errored :- ' || ' OTHERS :: ' || SUBSTR (SQLERRM, 1, 3800) || SQLCODE );
  print_debug_msg ('End - populate_gl_out_file - '||lc_errormsg, TRUE);
  UTL_FILE.fclose_all;
  lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
  UTL_FILE.fclose(lc_file_handle);
  p_errbuf  := SUBSTR (SQLERRM, 1, 150);
  p_retcode := 2;
END populate_gl_out_file;
-- +============================================================================================+
-- |  Name   : process_gl_balances_ob                                                           |
-- |  Description: This procedure generates the GL Balances Outbound file for ARCS              |
-- |                                                                                            |
-- |               Invokes from "OD: GL Balances Outbound for ARCS"                             |
-- =============================================================================================|
PROCEDURE process_gl_balances_ob(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT NUMBER ,
    p_period_name IN VARCHAR2 ,
    p_debug       IN VARCHAR2)
AS
  lc_error_msg            VARCHAR2(1000) := NULL;
  lc_error_loc            VARCHAR2(100)  := 'XX_GL_BAL_ARCS_RC_OB_PKG.process_gl_balances_ob';
  ln_retry_hdr_count      NUMBER;
  ln_retry_lin_count      NUMBER;
  lc_retcode              VARCHAR2(3) := NULL;
  ln_iretcode             NUMBER;
  lc_uretcode             VARCHAR2(3) := NULL;
  lc_req_data             VARCHAR2(30);
  ln_child_request_status VARCHAR2(1) := NULL;
  lc_continue             VARCHAR2(1) := 'Y';
  ln_batch_id             NUMBER;
  data_exception          EXCEPTION;
  lv_period_name          VARCHAR2(30);
BEGIN
  gc_debug      := p_debug;
  gn_request_id := fnd_global.conc_request_id;
  gn_user_id    := fnd_global.user_id;
  gn_login_id   := fnd_global.login_id;
  PRINT_DEBUG_MSG('Program Start Time Stamp'|| TO_CHAR(sysdate,'DD-MON-RR HH24:MI:SS'), true);
  print_out_msg('                                                  OD: GL Balances ARCS Extract Reporting Currency');
  print_out_msg('                                                 -------------------------------');
  print_out_msg('');
  print_out_msg('');
  print_out_msg('Parameters:');
  print_out_msg('-------------:');
  print_out_msg('Period Name                          :'||p_period_name);
  print_out_msg('Debug Flag                           :'||p_debug);
  print_out_msg('Concurrent Request ID                :'||gn_request_id);
  IF p_period_name IS NULL THEN
    print_debug_msg('Period Name is Mandatory', TRUE);
    lc_error_msg := 'Period Name is Mandatory';
    raise data_exception;
  END IF;
  IF p_period_name IS NOT NULL THEN
    BEGIN
      SELECT DISTINCT period_name
      INTO lv_period_name
      FROM gl_periods
      WHERE period_name  =p_period_name
      AND period_set_name='OD 445 CALENDAR';
    EXCEPTION
    WHEN too_many_rows THEN
      NULL;
    WHEN OTHERS THEN
      print_debug_msg('Period Name entered is Invalid, Please enter a valid Period Name', TRUE);
      raise data_exception;
    END;
  END IF;
  lc_continue := 'Y';
  -- 1. Invoke populate_gl_out_file
  populate_gl_out_file(p_errbuf => lc_error_msg ,p_retcode => ln_iretcode ,p_period_name => p_period_name ,p_debug => p_debug);
  IF ln_iretcode <> 0 THEN
    lc_continue  := 'N';
  END IF;
  IF ln_iretcode = 0 THEN
    commit; -- IF populate_gl_out_file completes successfully.
    PRINT_DEBUG_MSG('Completed GL Balances to ARCS Outbound Interface for Reporting Currency......:: '||TO_CHAR(sysdate,'MM-DD-YYYY HH:Mi:SS'), true);
  ELSIF ln_iretcode = 1 THEN
    p_retcode      := 1;
    P_ERRBUF       := LC_ERROR_MSG;
    print_debug_msg('In Warning, GL Balances to ARCS Outbound Interface for Reporting Currency......:: '||lc_error_msg, TRUE);
  ELSIF ln_iretcode = 2 THEN
    p_retcode      := 2;
    P_ERRBUF       := LC_ERROR_MSG;
    print_debug_msg('In Error, GL Balances to ARCS Outbound Interface for Reporting Currency......:: '||lc_error_msg, TRUE);
  END IF;
  print_debug_msg('Program Completion Time Stamp'|| TO_CHAR(sysdate,'DD-MON-RR HH24:MI:SS'), TRUE);
EXCEPTION
WHEN data_exception THEN
  p_retcode := 2;
  p_errbuf  := lc_error_msg;
WHEN OTHERS THEN
  lc_error_msg := SUBSTR(sqlerrm,1,250);
  print_debug_msg ('ERROR process_gl_balances_ob - '||lc_error_msg, TRUE);
  p_retcode := 2;
  p_errbuf  := lc_error_msg;
end PROCESS_GL_BALANCES_OB;
END XX_GL_BAL_ARCS_RC_OB_PKG;
/