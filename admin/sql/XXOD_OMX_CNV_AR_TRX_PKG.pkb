CREATE OR REPLACE
PACKAGE BODY XXOD_OMX_CNV_AR_TRX_PKG
AS
  gn_ledger_id NUMBER;
  /*********************************************************************
  * Procedure used to log based on gb_debug value or if p_force is TRUE.
  * Will log to dbms_output if request id is not set,
  * else will log to concurrent program log file.  Will prepend
  * timestamp to each message logged.  This is useful for determining
  * elapse times.
  *********************************************************************/
PROCEDURE Print_Debug_Msg(
    p_message IN VARCHAR2)
IS
  lc_message VARCHAR2(4000) := NULL;
BEGIN
  Fnd_File.Put_Line(Fnd_File.log,p_message);
  IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
    DBMS_OUTPUT.put_line(p_message);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END Print_Debug_Msg;
/*********************************************************************
* Procedure used to out the text to the concurrent program.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program output file.
*********************************************************************/
PROCEDURE Print_Out_Msg(
    P_Message IN VARCHAR2)
IS
  lc_message VARCHAR2(4000) := NULL;
BEGIN
  Fnd_File.Put_Line(Fnd_File.output,p_message);
  IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
    DBMS_OUTPUT.put_line(p_message);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END Print_Out_Msg;
-- +============================================================================+
-- | Procedure Name : Log_Error                                              |
-- |                                                                            |
-- | Description    : This procedure inserts error into the staging tables      |
-- |                                                                            |
-- |                                                                            |
-- | Parameters     : p_program_step             IN       VARCHAR2              |
-- |                  p_primary_key              IN       VARCHAR2              |
-- |                  p_error_code               IN       VARCHAR2              |
-- |                  p_error_message            IN       VARCHAR2              |
-- |                  p_stage_col1               IN       VARCHAR2              |
-- |                  p_stage_val1               IN       VARCHAR2              |
-- |                  p_stage_col2               IN       VARCHAR2              |
-- |                  p_stage_val2               IN       VARCHAR2              |
-- |                  p_stage_col3               IN       VARCHAR2              |
-- |                  p_stage_val3               IN       VARCHAR2              |
-- |                  p_stage_col4               IN       VARCHAR2              |
-- |                  p_stage_val4               IN       VARCHAR2              |
-- |                  p_stage_col5               IN       VARCHAR2              |
-- |                  p_stage_val5               IN       VARCHAR2              |
-- |                  p_table_name               IN       VARCHAR2              |
-- |                                                                            |
-- | Returns        : N/A                                                       |
-- |                                                                            |
-- +============================================================================+
PROCEDURE Log_Error(
    p_program_step  IN VARCHAR2 ,
    p_primary_key   IN VARCHAR2 DEFAULT NULL ,
    p_error_code    IN VARCHAR2 ,
    p_error_message IN VARCHAR2 DEFAULT NULL ,
    p_stage_col1    IN VARCHAR2 ,
    p_stage_val1    IN VARCHAR2 ,
    p_all_error_messages OUT NOCOPY VARCHAR2)
IS
BEGIN
  --g_error_cnt := g_error_cnt + 1;
  --gc_error_msg := gc_error_msg||' '||p_stage_col1||':'||p_stage_val1||':'||p_error_code||';';
  p_all_error_messages := p_all_error_messages||' '||p_stage_col1||':'||p_stage_val1||':'||p_error_code||';';
EXCEPTION
WHEN OTHERS THEN
  Print_Debug_Msg ('Error in Log_Error: ' || SQLCODE||' - '||SUBSTR(SQLERRM, 1, 3500));
END Log_Error;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        : OD North AR Invoice Conversion                      |
-- | Description : To convert the Receivables transactions having the  |
-- |              non-zero outstanding balanced from OD North to       |
-- |              ORACLE AR System                                     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author          Remarks                    |
-- |=======   ==========   =============    ===========================|
-- |1.0      07-JUN-2017   Madhu Bolli   Initial version               |
-- |1.1      06-MAR-2018   Punit Gupta   Defect#21481-Querying PO# from|
-- |                                     "Transactions Find" screen    |
-- |1.2      08-MAR-2018   Punit Gupta   Defect#21481-ODN is sending   |
-- |                                     Invoice Amt+Tax Amt in File   |
-- |1.3      12-MAR-2018   Punit Gupta   Defect#21481-Unable to process|
-- |                                     refunds on some of the invoice|
-- +===================================================================+
-- | Name : Master                                                     |
-- | Description : To create the batches of AR transactions from the   |
-- |      custom staging table XXOD_OMX_CNV_AR_TRX_STG based on the    |
-- |      transaction type name. It will call the "OD: OMX AR          |
-- |   Transactions Conversion Child Program" for each  batch.     |
-- |      This procedure will be the executable of Concurrent          |
-- |      program "OD: ODN AR Transactions Conversion Master Program"  |
-- | Parameters : x_error_buff, x_ret_code,p_validate_only_flag        |
-- |             ,p_reset_status_flag,p_thread_size                    |
-- | Returns    : Error Message,Return Code                            |
-- +===================================================================+
PROCEDURE Master(
    x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER ,
    p_validate_only_flag IN VARCHAR2 ,
    p_reset_status_flag  IN VARCHAR2 ,
    p_thread_size        IN NUMBER )
AS
  --Cursor to create the bacthes
  CURSOR lcu_batch_group
  IS
    SELECT batchId,
      MIN(record_id) minId,
      MAX(record_id) maxId
    FROM
      (SELECT record_id,
        NTILE(p_thread_size) OVER (ORDER BY record_id) batchId
      FROM xxod_omx_cnv_ar_trx_stg
      )
  GROUP BY batchId
  ORDER BY batchId;
  CURSOR lcu_invoice_dup
  IS
    SELECT *
    FROM xxod_omx_cnv_ar_trx_stg XSTG
    WHERE XSTG.inv_no IN
      (SELECT TRIM(XSTG1.inv_no)
      FROM xxod_omx_cnv_ar_trx_stg XSTG1
      WHERE XSTG1.inv_no = XSTG.inv_no
      GROUP BY TRIM(XSTG1.inv_no)
      HAVING COUNT(TRIM(XSTG1.inv_no))>= 2
      )
  ORDER BY record_id;
  CURSOR lcu_ind_inv_dup(p_inv_no IN VARCHAR2)
  IS
    SELECT *
    FROM xxod_omx_cnv_ar_trx_stg XSTG_MAIN
    WHERE inv_no = p_inv_no
      /*AND ROWID NOT IN
      (SELECT MIN(ROWID)
      FROM xxod_omx_cnv_ar_trx_stg stg2
      WHERE stg2.inv_no = xstg_main.inv_no
      )*/
    ORDER BY record_id;
  --- Added by Punit on 08-MAR-2018 to derive the Actual Invoice Amount
  CURSOR lcu_upd_act_inv_amt
  IS
    SELECT *
    FROM xxod_omx_cnv_ar_trx_stg XSTG
    WHERE inv_amt IS NOT NULL
    ORDER BY record_id;
  --- End of Added by Punit on 08-MAR-2018 to derive the Actual Invoice Amount
  ln_invno_count NUMBER := 0;
  ln_conc_request_id fnd_concurrent_requests.request_id%TYPE;
  ln_batch_id      NUMBER := 0;
  ln_batch_tot     NUMBER := 0;
  ln_all_batch_tot NUMBER := 0;
  lc_error_loc     VARCHAR2(2000);
  lc_error_message VARCHAR2(4000);
  lc_error_debug   VARCHAR2(2000);
  ln_org_id hr_all_organization_units.organization_id%TYPE;
  ln_request_id NUMBER;
  lc_message    VARCHAR2(50);
  ln_upd_cnt    NUMBER;
  lc_period_set_name gl_ledgers.period_set_name%TYPE;
  ln_not_open_Period_cnt NUMBER;
BEGIN
  --Printing the Parameters
  Print_Debug_Msg('Parameters');
  Print_Debug_Msg('-----------------------------------');
  Print_Debug_Msg('Validate Only Flag    : '||p_validate_only_flag);
  Print_Debug_Msg('Reset Status Flag     : '||p_reset_status_flag);
  Print_Debug_Msg('Thread Size            : '||p_thread_size);
  --If Reset flag = 'Y'  -- Commented by Punit on 30-JAN-2018
  IF (p_reset_status_flag = 'Y') THEN
    UPDATE xxod_omx_cnv_ar_trx_stg
    SET process_flag    ='1',
      conv_error_flag   = 'Y',
      conv_error_msg    = NULL
    WHERE process_flag IN ('2','3','4','5','6');
    COMMIT;
  END IF;
  lc_error_loc   := 'Updating the Process flag from 1 to 2';
  lc_error_debug := '';
  UPDATE xxod_omx_cnv_ar_trx_stg SET process_flag ='2' WHERE process_flag = '1';
  COMMIT;
  SELECT ledger_id,
    period_set_name
  INTO gn_ledger_id,
    lc_period_set_name
  FROM gl_ledgers gll
  WHERE gll.short_name = 'US_USD_P';
  Print_Debug_Msg('gn_ledger_id is '||gn_ledger_id);
  Print_Debug_Msg('lc_period_set_name is '||lc_period_set_name);
  ln_not_open_Period_cnt := 0;
  SELECT COUNT(1)
  INTO ln_not_open_Period_cnt
  FROM gl_period_statuses gps,
    gl_periods gp
  WHERE TRUNC(sysdate) BETWEEN gp.start_date AND gp.end_date
  AND gp.period_set_name    = lc_period_set_name
  AND gps.period_name       = gp.period_name
  AND gps.application_id   IN (101, 222)
  AND gps.set_of_books_id   = gn_ledger_id
  AND gps.closing_status   <> 'O';
  IF ln_not_open_Period_cnt > 0 THEN
    lc_error_message       := 'Either GL or Receivables period is not opened for the date : '||TO_CHAR(sysdate, 'DD-MM-YY')||'.';
    Print_Out_Msg (lc_error_message);
    Print_Out_Msg (lc_error_message||' Please open the period and rerun with reset_flag as Y');
  END IF;
  ln_upd_cnt := 0;
  UPDATE xxod_omx_cnv_ar_trx_stg XOMXSTG
  SET XOMXSTG.conv_error_flag = 'Y',
    XOMXSTG.conv_error_msg    = 'GLDate is Not Opened'
  WHERE 1                    <=
    (SELECT COUNT(1)
    FROM gl_period_statuses gps,
      gl_periods gp
    WHERE TRUNC(sysdate) BETWEEN gp.start_date AND gp.end_date
    AND gp.period_set_name  = lc_period_set_name
    AND gps.period_name     = gp.period_name
    AND gps.application_id IN (101, 222)
    AND gps.set_of_books_id = gn_ledger_id
    AND gps.closing_status <> 'O'
    );
  ln_upd_cnt := SQL%ROWCOUNT;
  COMMIT;
  lc_error_message := 'Updated all records as GL date is Not Opened either for GL or Receivable modules : '||ln_upd_cnt;
  Print_Debug_Msg (lc_error_message);
  ln_upd_cnt := 0;
  UPDATE xxod_omx_cnv_ar_trx_stg xomxstg
  SET xomxstg.conv_error_flag = 'Y',
    xomxstg.conv_error_msg    = 'Mandatory column value is NULL'
  WHERE 1                     =1
  AND (acct_no               IS NULL
  OR pay_due_date            IS NULL
  OR inv_no                  IS NULL
  OR inv_seq_no              IS NULL
  OR inv_creation_date       IS NULL
  OR inv_amt                 IS NULL );
  ln_upd_cnt                 := SQL%ROWCOUNT;
  COMMIT;
  -- Divide all records into batches using NTILE and update
  /**
  MERGE INTO XXOD_OMX_CNV_AR_TRX_STG stg
  USING (SELECT record_id, NTILE(p_thread_size) OVER (ORDER BY RECORD_ID) batchId FROM XXOD_OMX_CNV_AR_TRX_STG WHERe process_flag = '2') comp
  ON (stg.record_id = comp.record_id)
  WHEN MATCHED THEN UPDATE SET stg.batch_id=comp.batchId
  WHERE process_flag = '2';
  COMMIT;
  **/
  --- Added by Punit on 15-FEB-18 to update the Duplicate invoices
  FOR rec_invoice_dup IN lcu_invoice_dup
  LOOP
    ln_invno_count := 1;
    FOR rec_ind_inv_dup IN lcu_ind_inv_dup(rec_invoice_dup.inv_no)
    LOOP
      UPDATE xxod_omx_cnv_ar_trx_stg STG
      SET inv_no = inv_no
        ||'-'
        ||ln_invno_count
      WHERE inv_no    = rec_ind_inv_dup.inv_no
      AND record_id   = rec_ind_inv_dup.record_id;
      ln_invno_count := ln_invno_count + 1;
    END LOOP;
  END LOOP;
  --- Added by Punit on 08-MAR-2018 to derive the Actual Invoice Amount
  FOR rec_upd_act_inv_amt IN lcu_upd_act_inv_amt
  LOOP
    IF rec_upd_act_inv_amt.inv_amt = rec_upd_act_inv_amt.tax_amt THEN
      UPDATE xxod_omx_cnv_ar_trx_stg STG
      SET STG.actual_inv_amt           = 0.00
      WHERE STG.inv_no                 = rec_upd_act_inv_amt.inv_no
      AND STG.record_id                = rec_upd_act_inv_amt.record_id;
    ELSIF rec_upd_act_inv_amt.inv_amt <> rec_upd_act_inv_amt.tax_amt THEN
      UPDATE xxod_omx_cnv_ar_trx_stg STG
      SET STG.actual_inv_amt = rec_upd_act_inv_amt.inv_amt - rec_upd_act_inv_amt.tax_amt
      WHERE STG.inv_no       = rec_upd_act_inv_amt.inv_no
      AND STG.record_id      = rec_upd_act_inv_amt.record_id;
    END IF;
  END LOOP;
  FOR lcu_batch IN lcu_batch_group
  LOOP
    UPDATE xxod_omx_cnv_ar_trx_stg
    SET batch_id = lcu_batch.batchId
    WHERE record_id BETWEEN lcu_batch.minId AND lcu_batch.maxId
    AND process_flag = '2';
    ln_batch_tot    := SQL%ROWCOUNT;
    Print_Debug_Msg('Total Number of Records for the Batch '||lcu_batch.batchId||'  are : ' || ln_batch_tot);
    ln_batch_id := lcu_batch.batchId;
    COMMIT;
    IF ln_batch_tot > 0 THEN
      BEGIN
        ln_all_batch_tot := ln_all_batch_tot + ln_batch_tot;
        ln_request_id    := fnd_request.submit_request (application => 'XXFIN' ,program => 'XXODOMXCNVARTRXCHLD' ,description => '' ,start_time => SYSDATE ,sub_request => FALSE ,argument1 => p_validate_only_flag ,argument2 => p_reset_status_flag ,argument3 => lcu_batch.batchId);
        COMMIT;
        Print_Debug_Msg('Submitted the request '||ln_request_id||' for the batch '||lcu_batch.batchId);
      EXCEPTION
      WHEN OTHERS THEN
        Print_Debug_Msg('Exception raised while submitting batch '||SQLCODE||' - '||SUBSTR(SQLERRM,1,3500));
      END;
    ELSE
      Print_Debug_Msg('No records with PROCESS FLAG = 2 for this batch');
      Print_Debug_Msg('');
    END IF;
  END LOOP;
  Print_Debug_Msg('Total Number of Records for all the Batches are : ' || ln_all_batch_tot);
  Print_Out_Msg('Total Number of Records for all the Batches are : ' || ln_all_batch_tot);
  IF NVL (ln_batch_id, 0) = 0 THEN
    Print_Debug_Msg('No records to process in staging table XXOD_OMX_CNV_AR_TRX_STG with PROCESS FLAG = 1');
    Print_Out_Msg('No records to process in staging table XXOD_OMX_CNV_AR_TRX_STG with PROCESS FLAG = 1');
    --ELSE
  END IF;
EXCEPTION
WHEN OTHERS THEN
  lc_error_message := 'Error ';
  x_ret_code       := 2;
  x_error_buff     := lc_error_message || ' at ' || lc_error_loc || lc_error_debug||SQLCODE||' - '||SUBSTR(SQLERRM,1,3500);
  Print_Debug_Msg(p_message => 'x_errbuf  '||x_error_buff);
END Master;
-- +===================================================================+
-- | Name        : Valid_Load_Child                                    |
-- | Description : To perform translation, validations, Import of AR   |
-- |              transactions from OMX to AR systems for each batch.  |
-- |              This procedure will be the executable of Concurrent  |
-- | Program      "OD: OMX AR Transactions Conversion Child Program"   |
-- | Parameters : x_error_buff, x_ret_code,             |
-- |              ,p_validate_only_flag,p_reset_status_flag,p_batch_id |
-- | Returns    : Error Message,Return Code                            |
-- +===================================================================+
PROCEDURE Valid_Load_Child(
    x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER ,
    p_validate_only_flag IN VARCHAR2 ,
    p_reset_status_flag  IN VARCHAR2 ,
    p_batch_id           IN NUMBER )
AS
  --Cursor to get the transaction of the Particular batch
TYPE invoice_bulk_tbl_type
IS
  TABLE OF xxod_omx_cnv_ar_trx_stg%ROWTYPE;
  lcu_process_lines invoice_bulk_tbl_type;
  CURSOR lcu_process_lines_bulk
  IS
    SELECT XXINT.*
    FROM xxod_omx_cnv_ar_trx_stg XXINT
    WHERE XXINT.batch_id = p_batch_id;
  CURSOR lcu_ar_inv_cnv_stats
  IS
    SELECT SUM(DECODE(process_flag,2,1,0)) -- Eligible to Validate and Load
      ,
      SUM(DECODE(process_flag,4,1,0)) -- Successfully Validated and Loaded
      ,
      SUM(DECODE(process_flag,3,1,0)) -- Validated and Errored out
      ,
      SUM(DECODE(process_flag,1,1,0)) -- Ready for Process
    FROM xxod_omx_cnv_ar_trx_stg
    WHERE batch_id = p_batch_id;
  ln_cust_count NUMBER;
  lc_transaction_type_class ra_cust_trx_types_all.type%TYPE;
  lc_transaction_type ra_cust_trx_types_all.name%TYPE;
  ln_transaction_type_id ra_cust_trx_types_all.cust_trx_type_id%TYPE;
  lc_payment_term ra_terms_tl.name%TYPE;
  ln_org_id hr_all_organization_units.organization_id%TYPE := '404';
  ln_interface_line_id NUMBER                              := NULL;
  ln_conc_request_id fnd_concurrent_requests.request_id%TYPE;
  lc_error_flag_val VARCHAR2(1) := 'N';
  lc_error_message  VARCHAR2(2000);
  -- ln_failed_val_count  NUMBER := 0;
  -- ln_failed_proc_count NUMBER := 0;
  -- ln_tot_batch_count   NUMBER := 0;
  -- ln_success_count     NUMBER := 0;
  lc_error_loc   VARCHAR2(2000);
  lc_error_debug VARCHAR2(2000);
  ln_cust_acct_id hz_cust_accounts_all.cust_account_id%TYPE;
  lc_phase                  VARCHAR2(50);
  lc_status                 VARCHAR2(50);
  lc_devphase               VARCHAR2(50);
  lc_devstatus              VARCHAR2(50);
  lc_message                VARCHAR2(50);
  lc_req_status             BOOLEAN;
  lc_orig_bill_customer_ref VARCHAR2(200);
  lc_orig_ship_customer_ref VARCHAR2(200);
  lc_orig_bill_address_ref  VARCHAR2(200);
  lc_orig_ship_address_ref  VARCHAR2(200);
  lv_shipto_location        VARCHAR2(100);
  lv_billto_location        VARCHAR2(100);
  lc_trx_number ra_interface_lines_all.trx_number%TYPE;
  lc_tax_code ar_vat_tax_all.tax_code%TYPE;
  ln_user_id       VARCHAR2 (25) := fnd_global.user_id;
  ld_date          DATE          := SYSDATE;
  ln_login_id      VARCHAR2 (25) := fnd_global.login_id;
  lc_currency_code VARCHAR2(10)  := 'USD';
  lc_inv_amt_sign  VARCHAR2(2)   := NULL;
  lc_tax_amt_sign  VARCHAR2(2)   := NULL;
TYPE segments_t
IS
  TABLE OF VARCHAR2(20) INDEX BY PLS_INTEGER;
TYPE transtype_t
IS
  TABLE OF segments_t INDEX BY VARCHAR2(20);
  l_trans_type_segs transtype_t;
TYPE stg_tbl_type
IS
  TABLE OF NUMBER INDEX BY PLS_INTEGER;
  lt_stg stg_tbl_type;
TYPE stg_err_tbl_type
IS
  TABLE OF VARCHAR2(2000) INDEX BY PLS_INTEGER;
  lt_stg_err stg_err_tbl_type;
  ln_count              NUMBER := 1;
  lc_seg_company        VARCHAR2(25);
  lc_seg_costcenter     VARCHAR2(25);
  lc_seg_account        VARCHAR2(25);
  lc_seg_location       VARCHAR2(25);
  lc_seg_intercompany   VARCHAR2(25);
  lc_seg_lob            VARCHAR2(25);
  lc_seg_future         VARCHAR2(25);
  lc_unique_number      VARCHAR2(50);
  lc_adj_code           VARCHAR2(10);
  lc_description        VARCHAR2(4000);
  lc_attribute6         VARCHAR2(1)   := 'Y';
  lc_account_class      VARCHAR2(100) := 'REV';
  lv_all_error_messages VARCHAR2(4000);
  lc_is_credit_memo     VARCHAR2(1);
  lc_po_no ra_interface_lines_all.interface_line_attribute1%TYPE;
  lc_order_no ra_interface_lines_all.interface_line_attribute2%TYPE;
  lc_tax_rate_code   VARCHAR2(100) := 'SALES';
  ln_link_to_line_id NUMBER;
  lc_link_to_context ra_interface_lines_all.link_to_line_context%TYPE;
  lc_link_to_line_attribute1 ra_interface_lines_all.link_to_line_attribute1%TYPE;
  lc_link_to_line_attribute2 ra_interface_lines_all.link_to_line_attribute2%TYPE;
  lc_link_to_line_attribute3 ra_interface_lines_all.link_to_line_attribute3%TYPE;
  ln_inv_still_eligible_cnt NUMBER := 0;
  ln_inv_val_load_cnt       NUMBER := 0;
  ln_inv_error_cnt          NUMBER := 0;
  ln_inv_ready_process      NUMBER := 0;
  ln_bill_cust_acct_site_id NUMBER;
  ln_ship_cust_acct_site_id NUMBER;
BEGIN
  --Printing the Parameters
  Print_Debug_Msg('Parameters: ');
  Print_Debug_Msg('----------');
  Print_Debug_Msg('Validate Only Flag: '||p_validate_only_flag);
  Print_Debug_Msg('Reset Status Flag: '||p_reset_status_flag);
  Print_Debug_Msg('Batch ID: '||p_batch_id);
  Print_Debug_Msg('----------');
  -- FOR lcu_process_lines IN lcu_process_lines_bulk()
  OPEN lcu_process_lines_bulk;
  LOOP
    FETCH lcu_process_lines_bulk BULK COLLECT INTO lcu_process_lines LIMIT 2000;
    EXIT
  WHEN lcu_process_lines.COUNT = 0;
    FOR indx IN 1 .. lcu_process_lines.COUNT
    LOOP
      --Initialization for each transactions
      lc_error_flag_val         := 'N';
      lc_error_message          := NULL;
      ln_interface_line_id      := NULL;
      ln_cust_acct_id           := NULL;
      lc_orig_bill_customer_ref := NULL;
      lc_orig_bill_address_ref  := NULL;
      lc_orig_ship_customer_ref := NULL;
      lc_orig_ship_address_ref  := NULL;
      lc_unique_number          := lcu_process_lines(indx).inv_no; --lcu_process_lines(indx).inv_seq_no;  -- Changed by Punit on 10-JAN-2018
      lc_trx_number             := lcu_process_lines(indx).inv_no; -- lcu_process_lines(indx).inv_no; --Changed by Punit on 10-JAN-2018
      --Initializing the below variables to null
      ln_transaction_type_id    := NULL;
      lc_transaction_type_class := NULL;
      lc_payment_term           := NULL;
      lc_tax_code               := NULL;
      lc_adj_code               := NULL;
      gc_error_msg              := NULL;
      lc_transaction_type       := NULL;
      lv_all_error_messages     := NULL;
      lc_is_credit_memo         := 'N';
      lc_seg_company            := NULL;
      lc_seg_costcenter         := NULL;
      lc_seg_account            := NULL;
      lc_seg_location           := NULL;
      lc_seg_intercompany       := NULL;
      lc_seg_lob                := NULL;
      lc_seg_future             := NULL;
      lv_shipto_location        := NULL;
      lv_billto_location        := NULL;
      lc_inv_amt_sign           := NULL;
      lc_tax_amt_sign           := NULL;
      -- Translation of Transaction Type
      -- Print_Debug_Msg ('Before Transaction TYpe Check');
      BEGIN
        IF lcu_process_lines(indx).ACCT_NO IS NULL THEN
          lc_error_flag_val                := 'Y';
          lc_error_message                 := 'ACCT_NO_IS_NULL';
          Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'ACCT_NO_IS_NULL' ,p_error_message => lc_error_message ,p_stage_col1 => 'ACCT_NO' ,p_stage_val1 => lcu_process_lines(indx).acct_no ,p_all_error_messages => lv_all_error_messages);
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        lc_error_flag_val := 'Y';
        lc_error_message  := 'XXODN_CNV_ACCTNO_EXCEPTION'||lcu_process_lines(indx).acct_no;
        Print_Debug_Msg ( lc_unique_number||' - XXODN_CNV_ACCTNO_EXCEPTION for acct_no '||lcu_process_lines(indx).acct_no|| ' is '|| SQLCODE||' - '||SUBSTR(SQLERRM,1,3500));
        Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'XXODN_CNV_ACCTNO_EXCEPTION' ,p_error_message => lc_error_message ,p_stage_col1 => 'ACCT_NO' ,p_stage_val1 => lcu_process_lines(indx).acct_no ,p_all_error_messages => lv_all_error_messages);
        x_ret_code := 1;
      END;
      -- Commented by Punit on 15-FEB-2018
      /*BEGIN
      IF lcu_process_lines(indx).adj_code  IS NOT NULL THEN
      IF lcu_process_lines(indx).adj_code = 'UC' THEN
      lc_adj_code                      := 'UC  - ADJ';
      ELSE
      lc_adj_code := '- ADJ';
      END IF;
      END IF;
      EXCEPTION
      WHEN OTHERS THEN
      lc_error_flag_val := 'Y';
      lc_error_message  := 'Adjustment Code '||lcu_process_lines(indx).adj_code||'-'||lc_adj_code || ' is not defined in Translation';
      Print_Debug_Msg ( lc_unique_number||' - XXODN_CNV_ADJ_EXCEPTION: ' || SQLCODE||' - '||SUBSTR(SQLERRM,1,3500));
      Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'XXODN_CNV_TRXTYPE_EXCEPTION' ,p_error_message => lc_error_message ,p_stage_col1 => 'ADJ_CODE' ,p_stage_val1 => lcu_process_lines(indx).adj_code ,p_all_error_messages => lv_all_error_messages);
      x_ret_code := 1;
      END; */
      -- End of Commented by Punit on 15-FEB-2018
      BEGIN
        -- Added by Punit on 14-FEB-2018 to change the Transaction Type Logic
        lc_error_loc := 'Deriving the Transaction Type ';
        -- Added by Punit on 08-MAR-2018 for invoices having both invoice and tax amount equal
        IF (lcu_process_lines(indx).actual_inv_amt = 0 AND lcu_process_lines(indx).actual_inv_amt <> lcu_process_lines(indx).tax_amt) THEN
          BEGIN
            ---SELECT DECODE(SIGN(lcu_process_lines(indx).inv_amt),'1','+','-1','-','')
            SELECT DECODE(SIGN(lcu_process_lines(indx).tax_AMT),'1','+','-1','-','') -- Commented and Changed by Punit on 08-MAR-2018
            INTO lc_tax_amt_sign
            FROM DUAL;
          EXCEPTION
          WHEN OTHERS THEN
            lc_tax_amt_sign := NULL;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while deriving the sign of invoice amount '||SQLCODE||SQLERRM);
            Print_Debug_Msg ( lc_unique_number||' - Error while deriving the sign of invoice amount: ' || SQLCODE||' - '||SUBSTR(SQLERRM,1,3500));
          END;
          IF (lc_tax_amt_sign                        = '+') THEN
            IF lcu_process_lines(indx).adj_code     IS NULL THEN
              lc_transaction_type                   := 'OMX INV_OD';
            ELSIF (lcu_process_lines(indx).adj_code IS NOT NULL AND lcu_process_lines(indx).adj_code <> 'UC')THEN
              lc_transaction_type                   := 'OMX DMCHB_OD';
            ELSIF (lcu_process_lines(indx).adj_code IS NOT NULL AND lcu_process_lines(indx).adj_code = 'UC') THEN
              lc_transaction_type                   := 'OMX PAY_OD';
            END IF;
          ELSIF (lc_tax_amt_sign                     = '-') THEN
            IF lcu_process_lines(indx).adj_code     IS NULL THEN
              lc_transaction_type                   := 'OMX CM_OD';
            ELSIF (lcu_process_lines(indx).adj_code IS NOT NULL AND lcu_process_lines(indx).adj_code <> 'UC') THEN
              lc_transaction_type                   := 'OMX NEGINV_OD';
            ELSIF (lcu_process_lines(indx).adj_code IS NOT NULL AND lcu_process_lines(indx).adj_code = 'UC') THEN
              lc_transaction_type                   := 'OMX PAY_OD';
            END IF;
          END IF;
          -- End of Added by Punit on 08-MAR-2018 for invoices having both invoice and tax amount equal
        ELSIF (lcu_process_lines(indx).actual_inv_amt <> 0 AND lcu_process_lines(indx).actual_inv_amt <> lcu_process_lines(indx).tax_amt) THEN
          BEGIN
            ---SELECT DECODE(SIGN(lcu_process_lines(indx).inv_amt),'1','+','-1','-','')
            SELECT DECODE(SIGN(lcu_process_lines(indx).ACTUAL_INV_AMT),'1','+','-1','-','') -- Commented and Changed by Punit on 08-MAR-2018
            INTO lc_inv_amt_sign
            FROM DUAL;
          EXCEPTION
          WHEN OTHERS THEN
            lc_inv_amt_sign := NULL;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while deriving the sign of invoice amount '||SQLCODE||SQLERRM);
            Print_Debug_Msg ( lc_unique_number||' - Error while deriving the sign of invoice amount: ' || SQLCODE||' - '||SUBSTR(SQLERRM,1,3500));
          END;
          IF (lc_inv_amt_sign                        = '+') THEN
            IF lcu_process_lines(indx).adj_code     IS NULL THEN
              lc_transaction_type                   := 'OMX INV_OD';
            ELSIF (lcu_process_lines(indx).adj_code IS NOT NULL AND lcu_process_lines(indx).adj_code <> 'UC')THEN
              lc_transaction_type                   := 'OMX DMCHB_OD';
            ELSIF (lcu_process_lines(indx).adj_code IS NOT NULL AND lcu_process_lines(indx).adj_code = 'UC') THEN
              lc_transaction_type                   := 'OMX PAY_OD';
            END IF;
          ELSIF (lc_inv_amt_sign                     = '-') THEN
            IF lcu_process_lines(indx).adj_code     IS NULL THEN
              lc_transaction_type                   := 'OMX CM_OD';
            ELSIF (lcu_process_lines(indx).adj_code IS NOT NULL AND lcu_process_lines(indx).adj_code <> 'UC') THEN
              lc_transaction_type                   := 'OMX NEGINV_OD';
            ELSIF (lcu_process_lines(indx).adj_code IS NOT NULL AND lcu_process_lines(indx).adj_code = 'UC') THEN
              lc_transaction_type                   := 'OMX PAY_OD';
            END IF;
          END IF;
          -- Added by Punit on 19-JAN-2018 to consider the Puerto Rico Transaction Types
        END IF ; -- Added by Punit on 08-MAR-2018 for invoices having both invoice and tax amount equal
        IF lcu_process_lines(indx).SHIP_TO_LOC = '96' THEN
          lc_transaction_type                 := lc_transaction_type||'_PR';
        END IF;
        -- End of Added by Punit on 19-JAN-2018 to consider the Puerto Rico Transaction Types
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lc_error_flag_val := 'Y';
        lc_error_message  := 'Error ';
        Print_Debug_Msg ( lc_unique_number||' Translation Value doesnt exist for transaction type '||lcu_process_lines(indx).tran_type||' and adjustment code '||lcu_process_lines(indx).adj_code||' derived adj_code as '||lc_adj_code);
        Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'OMX_TRXTYPE_TRANSLATION_NOTFOUND' ,p_error_message => lc_error_message ,p_stage_col1 => 'TRAN_TYPE' ,p_stage_val1 => lcu_process_lines(indx).tran_type||'-'||lcu_process_lines(indx).adj_code , p_all_error_messages => lv_all_error_messages);
        x_ret_code := 1;
      WHEN OTHERS THEN
        lc_error_flag_val := 'Y';
        lc_error_message  := 'Transaction Type '|| lcu_process_lines(indx).tran_type||'-'||lc_adj_code || ' is not defined in Translation';
        Print_Debug_Msg ( lc_unique_number||' - XXODN_CNV_TRXTYPE_EXCEPTION: ' || SQLCODE||' - '||SUBSTR(SQLERRM,1,3500));
        Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'XXODN_CNV_TRXTYPE_EXCEPTION' ,p_error_message => lc_error_message ,p_stage_col1 => 'TRANS_TYPE' ,p_stage_val1 => lcu_process_lines(indx).tran_type||'-'||lcu_process_lines(indx).adj_code, p_all_error_messages => lv_all_error_messages );
        x_ret_code := 1;
      END;
      -- Validation of Transaction Type
      IF lc_transaction_type IS NOT NULL THEN
        BEGIN
          lc_error_loc   := 'Validating Transaction Type ';
          lc_error_debug := 'Transaction Type: ' || lc_transaction_type;
          SELECT cust_trx_type_id ,
            type
          INTO ln_transaction_type_id ,
            lc_transaction_type_class
          FROM ra_cust_trx_types_all
          WHERE org_id                = ln_org_id
          AND name                    = lc_transaction_type
          AND NVL(end_date,SYSDATE+1) > SYSDATE; -- Added by Punit on 18-JAN-2018
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lc_error_flag_val := 'Y';
          lc_error_message  := 'Transaction Type ' || lc_transaction_type || ' is not defined in Oracle EBS System';
          Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'XXODN_CNV_INVALID_TRXTYPE_EBS' ,p_error_message => lc_error_message ,p_stage_col1 => 'TRANS_TYPE' ,p_stage_val1 => lcu_process_lines(indx).tran_type||'-'||lc_adj_code , p_all_error_messages => lv_all_error_messages);
          x_ret_code := 1;
        WHEN OTHERS THEN
          lc_error_flag_val := 'Y';
          lc_error_message  := 'Error ';
          Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'XXODN_CNV_TRXTYPE_EBS_EXCEPTION' ,p_error_message => lc_error_message ,p_stage_col1 => 'TRANS_TYPE' ,p_stage_val1 => lcu_process_lines(indx).tran_type||'-'||lc_adj_code , p_all_error_messages => lv_all_error_messages );
          Print_Debug_Msg ( lc_unique_number||' - XXODN_CNV_TRXTYPE_EBS_EXCEPTION: ' || SQLCODE||' - '||SUBSTR(SQLERRM,1,3500));
          x_ret_code := 1;
        END;
      END IF;
      BEGIN
        IF ln_transaction_type_id IS NOT NULL THEN
          IF NOT (l_trans_type_segs.EXISTS(lc_transaction_type)) THEN
            SELECT GCC.segment1,
              GCC.segment2,
              GCC.segment3,
              GCC.segment4,
              GCC.segment5,
              GCC.segment6,
              GCC.segment7
            INTO l_trans_type_segs(lc_transaction_type)(1),
              l_trans_type_segs(lc_transaction_type)(2),
              l_trans_type_segs(lc_transaction_type)(3),
              l_trans_type_segs(lc_transaction_type)(4),
              l_trans_type_segs(lc_transaction_type)(5),
              l_trans_type_segs(lc_transaction_type)(6),
              l_trans_type_segs(lc_transaction_type)(7)
            FROM ra_cust_trx_types_all RCTA ,
              gl_code_combinations GCC
            WHERE RCTA.org_id                  = ln_org_id
            AND RCTA.name                      = lc_transaction_type
            AND RCTA.gl_id_rev                 = GCC.code_combination_id
            AND NVL(RCTA.end_date,SYSDATE + 1) > SYSDATE; -- Added by Punit on 18-JAN-2018;
          END IF;
        END IF;
        lc_seg_company      := l_trans_type_segs(lc_transaction_type)(1);
        lc_seg_costcenter   := l_trans_type_segs(lc_transaction_type)(2);
        lc_seg_account      := l_trans_type_segs(lc_transaction_type)(3);
        lc_seg_location     := l_trans_type_segs(lc_transaction_type)(4);
        lc_seg_intercompany := l_trans_type_segs(lc_transaction_type)(5);
        lc_seg_lob          := l_trans_type_segs(lc_transaction_type)(6);
        lc_seg_future       := l_trans_type_segs(lc_transaction_type)(7);
        -- For Puerotico the company segment should be changed
        IF lcu_process_lines(indx).SHIP_TO_LOC = '96' THEN
          lc_seg_company                      := gc_puertorico_comp_segment;
          lc_seg_account                      := gc_puertorico_account_segment;
        END IF;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lc_error_flag_val := 'Y';
        lc_error_message  := 'Transaction Type ' || lc_transaction_type || ' is not defined in Oracle EBS System';
        Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'XXODN_CNV_INVALID_TRXTYPE_EBS' ,p_error_message => lc_error_message ,p_stage_col1 => 'TRANS_TYPE' ,p_stage_val1 => lcu_process_lines(indx).tran_type||'-'||lc_adj_code , p_all_error_messages => lv_all_error_messages);
        x_ret_code := 1;
      WHEN OTHERS THEN
        lc_error_flag_val := 'Y';
        lc_error_message  := 'Error ';
        Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'XXODN_CNV_TRXTYPE_EBS_EXCEPTION' ,p_error_message => lc_error_message ,p_stage_col1 => 'TRANS_TYPE' ,p_stage_val1 => lcu_process_lines(indx).tran_type||'-'||lc_adj_code , p_all_error_messages => lv_all_error_messages );
        Print_Debug_Msg ( lc_unique_number||' - XXODN_CNV_TRXTYPE_EBS_EXCEPTION: ' || SQLCODE||' - '||SUBSTR(SQLERRM,1,3500));
        x_ret_code := 1;
      END;
      BEGIN
        SELECT hca.orig_system_reference,
          hca.orig_system_reference,
          hca.cust_account_id
        INTO lc_orig_bill_customer_ref,
          lc_orig_ship_customer_ref,
          ln_cust_acct_id
        FROM hz_cust_accounts_all hca
        WHERE hca.orig_system_reference = lcu_process_lines(indx).acct_no
          ||'-CONV' -- Changed by Punit on 23-JAN-2018
          --hca.orig_system_reference like lcu_process_lines(indx).acct_no||'%-CONV%'
        AND hca.STATUS = 'A';
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lc_error_flag_val := 'Y';
        lc_error_message  := 'ACCT_NO : ' || lcu_process_lines(indx).acct_no || ' is not defined in Oracle EBS System';
        Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'XXODN_CNV_INVALID_ACCTNO_EBS' ,p_error_message => lc_error_message ,p_stage_col1 => 'ACCT_NO' ,p_stage_val1 => lcu_process_lines(indx).acct_no, p_all_error_messages => lv_all_error_messages);
        Print_Debug_Msg (lc_error_message);
        x_ret_code := 1;
      WHEN OTHERS THEN
        lc_error_flag_val := 'Y';
        lc_error_message  := 'Error ';
        Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'XXODN_CNV_ACCTNO_EBS_EXCEPTION' ,p_error_message => lc_error_message ,p_stage_col1 => 'ACCT_NO' ,p_stage_val1 => lcu_process_lines(indx).acct_no, p_all_error_messages => lv_all_error_messages);
        Print_Debug_Msg ( lc_unique_number||' - XXODN_CNV_BILLCNSGNO_EBS_EXCEPTION: ' || SQLCODE||' - '||SUBSTR(SQLERRM,1,3500));
        x_ret_code := 1;
      END;
      IF ln_cust_acct_id IS NOT NULL THEN
        BEGIN
          IF lcu_process_lines(indx).bill_cnsg_no IS NOT NULL THEN
            lv_billto_location                    := lcu_process_lines(indx).bill_cnsg_no;
          ELSE
            lv_billto_location := 'MAIN_ACCT';
          END IF;
          SELECT HCAS.orig_system_reference
          INTO lc_orig_bill_address_ref
          FROM hz_cust_acct_sites_all HCAS
          WHERE EXISTS
            (SELECT 1
            FROM hz_cust_site_uses_all HCSU
            WHERE 1                    =1
            AND HCSU.location          = lv_billto_location
            AND HCSU.site_use_code     = 'BILL_TO'
            AND HCSU.STATUS            = 'A'
            AND HCSU.ORG_ID            = ln_org_id
            AND HCSU.cust_acct_site_id = HCAS.cust_acct_site_id
            )
          AND HCAS.status = 'A'
            --AND HCAS.BILL_TO_FLAG     IN ('P','Y')
          AND HCAS.cust_account_id = ln_cust_acct_id;
          /*SELECT HCAS1.orig_system_reference
          INTO lc_orig_bill_address_ref
          FROM hz_cust_acct_sites_all HCAS1
          WHERE EXISTS
          (SELECT 1
          FROM hz_cust_acct_sites_all HCAS ,
          hz_cust_site_uses_all HCSU
          WHERE HCAS.cust_account_id = ln_cust_acct_id
          AND HCAS.status            = 'A'
          AND HCAS.BILL_TO_FLAG     IN ('P','Y')
          AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
          AND HCSU.location          = lv_billto_location
          AND HCSU.site_use_code     = 'BILL_TO'
          AND HCSU.STATUS            = 'A'
          AND HCSU.ORG_ID            = ln_org_id
          AND HCAS.cust_acct_site_id = HCAS1.cust_acct_site_id
          );
          */
          /*SELECT HCAS1.orig_system_reference --HPS.orig_system_reference  -- Commented and Changed by Punit on 21-DEC-2017
          INTO lc_orig_bill_address_ref
          FROM hz_cust_acct_sites_all HCAS1
          WHERE EXISTS
          (SELECT 1
          FROM hz_party_sites HPS ,
          hz_cust_acct_sites_all HCAS ,
          hz_cust_site_uses_all HCSU
          WHERE HPS.party_site_id    = HCAS.party_site_id
          AND HPS.status             = 'A'
          AND HCAS.cust_account_id   = ln_cust_acct_id
          AND HCAS.status            = 'A'
          AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
          AND HCSU.location          = lv_billto_location
          AND HCSU.site_use_code     = 'BILL_TO'
          AND HCSU.STATUS            = 'A'
          AND HCSU.ORG_ID            = ln_org_id
          AND HCAS.cust_acct_site_id = HCAS1.cust_acct_site_id
          );
          */
          /*SELECT HCAS.orig_system_reference   --HPS.orig_system_reference  -- Commented and Changed by Punit on 21-DEC-2017
          INTO lc_orig_bill_address_ref
          FROM hz_party_sites HPS
          ,hz_cust_acct_sites_all HCAS
          ,hz_cust_site_uses_all HCSU
          WHERE HPS.party_site_id = HCAS.party_site_id
          AND HPS.status = 'A'
          AND HCAS.cust_account_id = ln_cust_acct_id
          AND HCAS.status = 'A'
          AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
          AND (HCSU.location = lcu_process_lines(indx).bill_cnsg_no
          OR (lcu_process_lines(indx).bill_cnsg_no is NULL
          and HCSU.location = 'MAIN_ACCT')  --- and HCSU.location = 'BILL_TO' -- Changed by Punit on 19-JAN-2018
          --and HCSU.primary_flag = 'Y')   -- Commented by Punit on 16-JAN-2018
          )
          AND HCSU.site_use_code  = 'BILL_TO'
          AND HCSU.STATUS = 'A'
          AND HCSU.ORG_ID = ln_org_id;*/
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lc_error_flag_val := 'Y';
          lc_error_message  := lc_unique_number||' - XXODN_CNV_INVALID_BILLCNSGNO_EBS for Bill Consignment : '||lcu_process_lines(indx).bill_cnsg_no||' is not defined in Oracle EBS System';
          Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'XXODN_CNV_INVALID_BILLCNSGNO_EBS' ,p_error_message => lc_error_message ,p_stage_col1 => 'BILL_CNSG_NO' ,p_stage_val1 => lcu_process_lines(indx).bill_cnsg_no, p_all_error_messages => lv_all_error_messages);
          Print_Debug_Msg (lc_error_message);
          x_ret_code := 1;
        WHEN OTHERS THEN
          lc_error_flag_val := 'Y';
          lc_error_message  := 'Error ';
          Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'XXODN_CNV_BILLCNSGNO_EBS_EXCEPTION' ,p_error_message => lc_error_message ,p_stage_col1 => 'BILL_CNSG_NO' ,p_stage_val1 => lcu_process_lines(indx).bill_cnsg_no, p_all_error_messages => lv_all_error_messages);
          Print_Debug_Msg ( lc_unique_number||' - XXODN_CNV_BILLCNSGNO_EBS_EXCEPTION: ' || SQLCODE||' - '||SUBSTR(SQLERRM,1,3500));
          x_ret_code := 1;
        END;
        BEGIN
          IF lcu_process_lines(indx).cnsg_no IS NOT NULL THEN
            lv_shipto_location               := lcu_process_lines(indx).cnsg_no;
          ELSE
            lv_shipto_location := 'MAIN_ACCT';
          END IF;
          SELECT HCAS.orig_system_reference
          INTO lc_orig_ship_address_ref
          FROM hz_cust_acct_sites_all HCAS
          WHERE EXISTS
            (SELECT 1
            FROM hz_cust_site_uses_all HCSU
            WHERE 1                    =1
            AND HCSU.location          = lv_shipto_location
            AND HCSU.site_use_code     = 'SHIP_TO'
            AND HCSU.STATUS            = 'A'
            AND HCSU.ORG_ID            = ln_org_id
            AND HCSU.cust_acct_site_id = HCAS.cust_acct_site_id
            )
          AND HCAS.status = 'A'
            -- AND HCAS.SHIP_TO_FLAG     IN ('P','Y')
          AND HCAS.cust_account_id = ln_cust_acct_id;
          /*SELECT HCAS1.orig_system_reference
          INTO lc_orig_ship_address_ref
          FROM hz_cust_acct_sites_all HCAS1
          WHERE EXISTS
          (SELECT 1
          FROM hz_cust_acct_sites_all HCAS ,
          hz_cust_site_uses_all HCSU
          WHERE HCAS.cust_account_id = ln_cust_acct_id
          AND HCAS.status            = 'A'
          AND HCAS.SHIP_TO_FLAG     IN ('P','Y')
          AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
          AND HCSU.location          = lv_shipto_location
          AND HCSU.site_use_code     = 'SHIP_TO'
          AND HCSU.STATUS            = 'A'
          AND HCSU.ORG_ID            = ln_org_id
          AND HCAS.cust_acct_site_id = HCAS1.cust_acct_site_id
          );
          */
          /*SELECT HCAS1.orig_system_reference --HPS.orig_system_reference  -- Commented and Changed by Punit on 21-DEC-2017
          INTO lc_orig_ship_address_ref
          FROM hz_cust_acct_sites_all HCAS1
          WHERE EXISTS
          (SELECT 1
          FROM hz_party_sites HPS ,
          hz_cust_acct_sites_all HCAS ,
          hz_cust_site_uses_all HCSU
          WHERE HPS.party_site_id    = HCAS.party_site_id
          AND HPS.status             = 'A'
          AND HCAS.cust_account_id   = ln_cust_acct_id
          AND HCAS.status            = 'A'
          AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
          AND HCSU.location          = lv_shipto_location
          AND HCSU.site_use_code     = 'SHIP_TO'
          AND HCSU.STATUS            = 'A'
          AND HCSU.ORG_ID            = ln_org_id
          AND HCAS.cust_acct_site_id = HCAS1.cust_acct_site_id
          ); */
          /*SELECT HCAS.orig_system_reference   --HPS.orig_system_reference  -- Commented and Changed by Punit on 21-DEC-2017
          INTO lc_orig_ship_address_ref
          FROM hz_party_sites HPS
          ,hz_cust_acct_sites_all HCAS
          ,hz_cust_site_uses_all HCSU
          WHERE HPS.party_site_id = HCAS.party_site_id
          AND HPS.status = 'A'
          AND HCAS.cust_account_id = ln_cust_acct_id
          AND HCAS.status = 'A'
          AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
          AND (HCSU.location = lcu_process_lines(indx).cnsg_no
          OR (lcu_process_lines(indx).cnsg_no is NULL
          and HCSU.location = 'MAIN_ACCT') -- and HCSU.location = 'SHIP_TO'   -- Changed by Punit on 19-JAN-2018
          --and HCSU.primary_flag = 'Y') -- Commented by Punit on 16-JAN-2018
          )
          AND HCSU.site_use_code  = 'SHIP_TO'
          AND HCSU.STATUS = 'A'
          AND HCSU.ORG_ID = ln_org_id;*/
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lc_error_flag_val := 'Y';
          lc_error_message  := lc_unique_number||' - XXODN_CNV_INVALID_CNSGNO_EBS for Consignment : '||lcu_process_lines(indx).cnsg_no||' is not defined in Oracle EBS System';
          Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'XXODN_CNV_INVALID_CNSGNO_EBS' ,p_error_message => lc_error_message ,p_stage_col1 => 'CNSG_NO' ,p_stage_val1 => lcu_process_lines(indx).cnsg_no, p_all_error_messages => lv_all_error_messages);
          Print_Debug_Msg (lc_error_message);
          x_ret_code := 1;
        WHEN OTHERS THEN
          lc_error_flag_val := 'Y';
          lc_error_message  := 'Error ';
          Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'XXODN_CNV_CNSGNO_EBS_EXCEPTION' ,p_error_message => lc_error_message ,p_stage_col1 => 'CNSG_NO' ,p_stage_val1 => lcu_process_lines(indx).cnsg_no, p_all_error_messages => lv_all_error_messages);
          Print_Debug_Msg ( lc_unique_number||' - XXODN_CNV_CNSGNO_EBS_EXCEPTION: ' || SQLCODE||' - '||SUBSTR(SQLERRM,1,3500));
          x_ret_code := 1;
        END;
      END IF; -- IF ln_cust_acct_id is NOT NULL THEN
      lc_payment_term := gc_payment_term;
      -- lc_orig_bill_customer_ref   := '89352385-00001-A0';
      -- lc_orig_bill_address_ref    := lcu_process_lines(indx).bill_cnsg_no;
      -- lc_orig_ship_customer_ref   := lc_orig_bill_customer_ref;  --'89352385-00001-A0';
      -- lc_orig_ship_address_ref    := lcu_process_lines(indx).cnsg_no;
      lc_description := lcu_process_lines(indx).sum_cycle||':'||lcu_process_lines(indx).tier1_ind||':'||'OMX-'||lcu_process_lines(indx).description;
      -- The column ra_interface_lines_all.comments length is 1760.
      IF (LENGTH(lc_description) > 1760) THEN
        lc_error_flag_val       := 'Y';
        lc_error_message        := lc_unique_number||' - XXODN_CNV_INVALID_LENGTH_DESCRIPTION : '||lcu_process_lines(indx).description||' length is more thatn 1760';
        Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'XXODN_CNV_INVALID_LENGTH_DESCRIPTION' ,p_error_message => lc_error_message ,p_stage_col1 => 'DESCRIPTION' ,p_stage_val1 => 'Description length more than 1760 when joined with value of sumCycle:tier1_ind:OMX - ', p_all_error_messages => lv_all_error_messages);
        Print_Debug_Msg (lc_error_message);
      END IF;
      IF ( lc_error_flag_val  = 'Y' ) THEN
        lt_stg(ln_count)     := lcu_process_lines(indx).record_id;
        lt_stg_err(ln_count) := lv_all_error_messages; -- gc_error_msg;
        ln_count             := ln_count +1;
        -- ln_failed_val_count := ln_failed_val_count + 1;
      END IF;
      IF lcu_process_lines(indx).PO_NO IS NULL THEN
        lc_po_no                       := '-1';
      ELSE
        lc_po_no := lcu_process_lines(indx).PO_NO;
      END IF;
      IF lcu_process_lines(indx).ORD_NO IS NULL THEN
        lc_order_no                     := '-1';
      ELSE
        lc_order_no := lcu_process_lines(indx).ORD_NO;
      END IF;
      SAVEPOINT S_RA_INTERFACE;
      IF (p_validate_only_flag = 'N' AND lc_error_flag_val = 'N') THEN
        --Sequence generation for the INTERFACE_LINE_ID
        lc_unique_number := lcu_process_lines(indx).inv_no; ---||'-'||XX_AR_INVNUM_SEQ.nextval; -- Added by Punit on 29-JAN-2018
        lc_trx_number    := lcu_process_lines(indx).inv_no; ---||'-'||XX_AR_INVNUM_SEQ.currval; --Added by Punit on 29-JAN-2018
        -- Added by Punit on 29-JAN-2018 to insert the dynamic invoice number value in staging table
        BEGIN
          UPDATE xxod_omx_cnv_ar_trx_stg
          SET inv_no      = lc_unique_number
          WHERE record_id = lcu_process_lines(indx).record_id;
        EXCEPTION
        WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while updating the staging table with dynamic invoice number '||SQLCODE||SQLERRM);
          x_ret_code := 1;
        END;
        -- End of Added by Punit on 29-JAN-2018 to insert the dynamic invoice number value in staging table
        BEGIN
          INSERT INTO xxod_omx_cnv_ar_trx_stg_hist
          SELECT *
          FROM xxod_omx_cnv_ar_trx_stg
          WHERE record_id = lcu_process_lines(indx).record_id;
        EXCEPTION
        WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while inserting into History Table'||SQLCODE||SQLERRM);
          x_ret_code := 1;
        END;
        SELECT ra_customer_trx_lines_s.NEXTVAL
        INTO ln_interface_line_id
        FROM SYS.DUAL;
        BEGIN
          --Inserting into RA_INTERFACE_LINES_ALL
          lc_error_loc   := 'Inserting Into Table RA_INTERFACE_LINES_ALL';
          lc_error_debug := 'Batch id: '|| p_batch_id;
          INSERT
          INTO ra_interface_lines_all
            (
              interface_line_id ,
              interface_line_context ,
              interface_line_attribute1 ,
              interface_line_attribute2 ,
              interface_line_attribute3 ,
              interface_line_attribute14 -- Added by Punit on 09-JAN-2018 to display the  Due Date value in Reference Field of Invoice Header.
              ,
              currency_code ,
              amount ,
              cust_trx_type_name ,
              term_name ,
              orig_system_bill_customer_ref ,
              orig_system_bill_address_ref ,
              orig_system_ship_customer_ref ,
              orig_system_ship_address_ref ,
              trx_number ,
              trx_date ,
              ship_date_actual ,
              gl_date ,
              quantity ,
              unit_selling_price ,
              org_id ,
              set_of_books_id ,
              batch_source_name ,
              line_type ,
              description ,
              comments ,
              conversion_type ,
              created_by ,
              creation_date ,
              last_updated_by ,
              last_update_date ,
              last_update_login ,
              SALES_ORDER --- Added by Punit on 06-MAR-2018 to display Sales order
              ,
              PURCHASE_ORDER --- Added by Punit on 06-MAR-2018 to display Purchase order
            )
            VALUES
            (
              ln_interface_line_id ,
              'CONVERSION' ,
              lc_po_no ,
              lc_order_no ,
              lc_unique_number ,
              lcu_process_lines(indx).pay_due_date -- Added by Punit on 09-JAN-2018 to display the  Due Date value in Reference Field of Invoice Header.
              ,
              lc_currency_code ,
              --lcu_process_lines(indx).inv_amt ,
              lcu_process_lines(indx).ACTUAL_INV_AMT, -- Commented and Modified by Punit on 08-MAR-2018
              lc_transaction_type ,
              DECODE(lc_transaction_type_class, 'CM', NULL, lc_payment_term) ,
              lc_orig_bill_customer_ref ,
              lc_orig_bill_address_ref ,
              lc_orig_ship_customer_ref ,
              lc_orig_ship_address_ref ,
              lc_unique_number ,
              lcu_process_lines(indx).inv_creation_date ,
              lcu_process_lines(indx).pay_due_date ,
              sysdate ,
              '1' ,
              --lcu_process_lines(indx).inv_amt ,
              lcu_process_lines(indx).ACTUAL_INV_AMT, -- Commented and Modified by Punit on 08-MAR-2018
              ln_org_id ,
              gn_ledger_id ,
              'MERGER_OMX_OD' --'CONVERSION_OD' --  Changed by Punit on 9-JAN-2018
              ,
              'LINE' ,
              'OMX Conv Line' --'OMX AR Transaction Type Conversion' -- Changed by Punit on 10-JAN-2018
              ,
              TRIM(lc_description), -- Trim added by Punit on 12-MAR-2018
              'Corporate' ,
              ln_user_id ,
              ld_date ,
              ln_user_id ,
              ld_date ,
              ln_login_id ,
              lc_order_no --- Added by Punit on 06-MAR-2018 to display Sales order
              ,
              lc_po_no --- Added by Punit on 06-MAR-2018 to display Purchase order
            );
        EXCEPTION
        WHEN OTHERS THEN
          lc_error_flag_val := 'Y';
          lc_error_message  := 'Error '||SQLCODE;
          Print_Debug_Msg ( 'Batch Id : '||p_batch_id||' and Trx Number : '||lc_unique_number||' - OMX_INTERFACE_LINE_INSERTION_FAIL: ' || SQLCODE||' - '||SUBSTR(SQLERRM,1,3500));
          x_ret_code := 1;
          Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'OMX_INTERFACE_LINE_INSERTION_FAIL' ,p_error_message => lc_error_message ,p_stage_col1 => 'INV_NO' ,p_stage_val1 => lc_unique_number, p_all_error_messages => lv_all_error_messages);
        END;
        ln_link_to_line_id  := ln_interface_line_id;
        IF lc_error_flag_val = 'N' THEN
          lc_error_loc      := 'Inserting into RA_INTERFACE_DISTRIBUTIONS_ALL REC';
          lc_error_debug    := 'Interface Line id: ' || ln_interface_line_id;
          -- If Puerto Rico then add the Receivable distribution line for 'REC' a/c class.
          -- For other OMX NA, the 'REC' distribution line takes from 'Auto Accounting'
          IF lcu_process_lines(indx).SHIP_TO_LOC = '96' THEN
            BEGIN
              INSERT
              INTO ra_interface_distributions_all
                (
                  interface_line_id ,
                  interface_line_context ,
                  interface_line_attribute1 ,
                  interface_line_attribute2 ,
                  interface_line_attribute3 ,
                  interface_line_attribute14 -- Added by Punit on 09-JAN-2018 to display the  Due Date value in Reference Field of Invoice Header.
                  ,
                  attribute6 ,
                  account_class ,
                  segment1 ,
                  segment2 ,
                  segment3 ,
                  segment4 ,
                  segment5 ,
                  segment6 ,
                  segment7 ,
                  org_id ,
                  percent ,
                  created_by ,
                  creation_date ,
                  last_updated_by ,
                  last_update_date ,
                  last_update_login
                )
                VALUES
                (
                  ln_interface_line_id ,
                  'CONVERSION' ,
                  lc_po_no ,
                  lc_order_no ,
                  lc_unique_number ,
                  lcu_process_lines(indx).pay_due_date -- Added by Punit on 09-JAN-2018 to display the  Due Date value in Reference Field of Invoice Header.
                  ,
                  lc_attribute6 ,
                  'REC' ,
                  gc_rec_seg_company ,
                  gc_rec_seg_costcenter ,
                  gc_rec_seg_account ,
                  gc_rec_seg_location ,
                  gc_rec_seg_intercompany ,
                  gc_rec_seg_lob ,
                  gc_rec_seg_future ,
                  ln_org_id ,
                  100 ,
                  ln_user_id ,
                  ld_date ,
                  ln_user_id ,
                  ld_date ,
                  ln_login_id
                );
            EXCEPTION
            WHEN OTHERS THEN
              lc_error_flag_val := 'Y';
              lc_error_message  := 'Batch Id : '||p_batch_id||' and Trx Number : '||lc_unique_number||' - OMX_INTERFACE_REC_LINE_DISTRIBUTIONS_INSERTION_FAIL: ' || SQLCODE||' - '||SUBSTR(SQLERRM,1,3500);
              Print_Debug_Msg (lc_error_message);
              Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'OMX_INTERFACE_REC_LINE_DISTRIBUTIONS_INSERTION_FAIL' ,p_error_message => lc_error_message ,p_stage_col1 => 'INV_NO' ,p_stage_val1 => lc_unique_number ,p_all_error_messages => lv_all_error_messages);
              x_ret_code := 1;
            END;
          END IF;
          BEGIN
            lc_error_loc   := 'Inserting into RA_INTERFACE_DISTRIBUTIONS_ALL REV';
            lc_error_debug := 'Interface Line id: ' || ln_interface_line_id;
            INSERT
            INTO ra_interface_distributions_all
              (
                interface_line_id ,
                interface_line_context ,
                interface_line_attribute1 ,
                interface_line_attribute2 ,
                interface_line_attribute3 ,
                interface_line_attribute14 -- Added by Punit on 09-JAN-2018 to display the  Due Date value in Reference Field of Invoice Header.
                ,
                attribute6 ,
                account_class ,
                segment1 ,
                segment2 ,
                segment3 ,
                segment4 ,
                segment5 ,
                segment6 ,
                segment7 ,
                org_id ,
                percent ,
                created_by ,
                creation_date ,
                last_updated_by ,
                last_update_date ,
                last_update_login
              )
              VALUES
              (
                ln_interface_line_id ,
                'CONVERSION' ,
                lc_po_no ,
                lc_order_no ,
                lc_unique_number ,
                lcu_process_lines(indx).pay_due_date -- Added by Punit on 09-JAN-2018 to display the  Due Date value in Reference Field of Invoice Header.
                ,
                lc_attribute6 ,
                lc_account_class ,
                lc_seg_company ,
                lc_seg_costcenter ,
                lc_seg_account ,
                lc_seg_location ,
                lc_seg_intercompany ,
                lc_seg_lob ,
                lc_seg_future ,
                ln_org_id ,
                100 ,
                ln_user_id ,
                ld_date ,
                ln_user_id ,
                ld_date ,
                ln_login_id
              );
          EXCEPTION
          WHEN OTHERS THEN
            lc_error_flag_val := 'Y';
            lc_error_message  := 'Batch Id : '||p_batch_id||' and Trx Number : '||lc_unique_number||' - OMX_INTERFACE_LINE_DISTRIBUTIONS_INSERTION_FAIL: ' || SQLCODE||' - '||SUBSTR(SQLERRM,1,3500);
            Print_Debug_Msg (lc_error_message);
            Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'OMX_INTERFACE_LINE_DISTRIBUTIONS_INSERTION_FAIL' ,p_error_message => lc_error_message ,p_stage_col1 => 'INV_NO' ,p_stage_val1 => lc_unique_number ,p_all_error_messages => lv_all_error_messages);
            x_ret_code := 1;
          END;
        END IF; -- Distributions IF lc_error_flag_val = 'N'
        IF lc_error_flag_val                  = 'N' THEN
          IF lcu_process_lines(indx).tax_amt <> 0.00 THEN -- lcu_process_lines(indx).tax_amt > 0 -- Changed by Punit on 25-FEB-2018
            BEGIN
              lc_link_to_context         := 'CONVERSION' ;
              lc_link_to_line_attribute1 := lc_po_no; -- lcu_process_lines(indx).pay_due_date;
              lc_link_to_line_attribute2 := lc_order_no;
              lc_link_to_line_attribute3 := lc_unique_number;
              --Sequence generation for the Tax INTERFACE_LINE_ID
              SELECT ra_customer_trx_lines_s.NEXTVAL
              INTO ln_interface_line_id
              FROM SYS.DUAL;
              --Inserting into RA_INTERFACE_LINES_ALL
              lc_error_loc   := 'Inserting Into Table RA_INTERFACE_LINES_ALL for Tax line';
              lc_error_debug := 'Batch id: '|| p_batch_id;
              INSERT
              INTO ra_interface_lines_all
                (
                  interface_line_id ,
                  interface_line_context ,
                  interface_line_attribute1 ,
                  interface_line_attribute2 ,
                  interface_line_attribute3 ,
                  interface_line_attribute9 ,
                  interface_line_attribute14 -- Added by Punit on 09-JAN-2018 to display the  Due Date value in Reference Field of Invoice Header.
                  ,
                  currency_code ,
                  amount ,
                  cust_trx_type_name ,
                  term_name
                  --   ,orig_system_bill_customer_ref
                  --   ,orig_system_bill_address_ref
                  --   ,orig_system_ship_customer_ref
                  --   ,orig_system_ship_address_ref
                  ,
                  trx_number ,
                  trx_date ,
                  ship_date_actual ,
                  gl_date
                  --   ,quantity
                  --   ,unit_selling_price
                  ,
                  org_id ,
                  set_of_books_id ,
                  batch_source_name ,
                  line_type ,
                  description ,
                  comments ,
                  conversion_type ,
                  tax_code ,
                  tax_rate_code ,
                  link_to_line_id ,
                  link_to_line_context ,
                  link_to_line_attribute1 ,
                  link_to_line_attribute2 ,
                  link_to_line_attribute3 ,
                  created_by ,
                  creation_date ,
                  last_updated_by ,
                  last_update_date ,
                  last_update_login ,
                  SALES_ORDER --- Added by Punit on 06-MAR-2018 to display Sales order
                  ,
                  PURCHASE_ORDER --- Added by Punit on 06-MAR-2018 to display Purchase order
                )
                VALUES
                (
                  ln_interface_line_id ,
                  'CONVERSION' ,
                  lc_po_no
                  ||'-TAX' ,
                  lc_order_no
                  ||'-TAX' ,
                  lc_unique_number
                  ||'-TAX' ,
                  'TAX' ,
                  lcu_process_lines(indx).pay_due_date -- Added by Punit on 09-JAN-2018 to display the  Due Date value in Reference Field of Invoice Header.
                  ,
                  lc_currency_code ,
                  lcu_process_lines(indx).tax_amt ,
                  lc_transaction_type ,
                  DECODE(lc_transaction_type_class, 'CM', NULL, lc_payment_term)
                  -- ,lc_orig_bill_customer_ref
                  -- ,lc_orig_bill_address_ref
                  -- ,lc_orig_ship_customer_ref
                  -- ,lc_orig_ship_address_ref
                  ,
                  lc_trx_number ,
                  lcu_process_lines(indx).inv_creation_date ,
                  lcu_process_lines(indx).pay_due_date ,
                  sysdate
                  -- ,'1'
                  -- ,lcu_process_lines(indx).tax_amt
                  ,
                  ln_org_id ,
                  gn_ledger_id ,
                  'MERGER_OMX_OD' -- 'CONVERSION_OD' -- Changed by Punit on 9-JAN-2018
                  ,
                  'TAX' ,
                  'Tax value for OMX Conversion' ,
                  TRIM(lc_description) , -- Trim added by Punit on 12-MAR-2018
                  'Corporate' ,
                  lc_tax_code ,
                  lc_tax_rate_code ,
                  ln_link_to_line_id ,
                  lc_link_to_context ,
                  lc_link_to_line_attribute1 ,
                  lc_link_to_line_attribute2 ,
                  lc_link_to_line_attribute3 ,
                  ln_user_id ,
                  ld_date ,
                  ln_user_id ,
                  ld_date ,
                  ln_login_id ,
                  lc_order_no --- Added by Punit on 06-MAR-2018 to display Sales order
                  ,
                  lc_po_no --- Added by Punit on 06-MAR-2018 to display Purchase order
                );
            EXCEPTION
            WHEN OTHERS THEN
              lc_error_flag_val := 'Y';
              lc_error_message  := 'Error '||SQLCODE;
              Print_Debug_Msg ( 'Batch Id : '||p_batch_id||' and Trx Number : '||lc_unique_number||' - OMX_INTERFACE_TAX_LINE_INSERTION_FAIL: ' || SQLCODE||' - '||SUBSTR(SQLERRM,1,3500));
              Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'OMX_INTERFACE_TAX_LINE_INSERTION_FAIL' ,p_error_message => lc_error_message ,p_stage_col1 => 'INV_NO' ,p_stage_val1 => lc_unique_number , p_all_error_messages => lv_all_error_messages);
              x_ret_code := 1;
            END;
            -- Distributions for Tax Line
            IF lc_error_flag_val = 'N' THEN
              BEGIN
                lc_error_loc   := 'Inserting into RA_INTERFACE_DISTRIBUTIONS_ALL REC for TAX LINE';
                lc_error_debug := 'Interface Line id: ' || ln_interface_line_id;
                INSERT
                INTO ra_interface_distributions_all
                  (
                    interface_line_id ,
                    interface_line_context ,
                    interface_line_attribute1 ,
                    interface_line_attribute2 ,
                    interface_line_attribute3 ,
                    interface_line_attribute14 -- Added by Punit on 09-JAN-2018 to display the  Due Date value in Reference Field of Invoice Header.
                    ,
                    attribute6 ,
                    account_class ,
                    segment1 ,
                    segment2 ,
                    segment3 ,
                    segment4 ,
                    segment5 ,
                    segment6 ,
                    segment7 ,
                    org_id ,
                    percent ,
                    created_by ,
                    creation_date ,
                    last_updated_by ,
                    last_update_date ,
                    last_update_login
                  )
                  VALUES
                  (
                    ln_interface_line_id ,
                    'CONVERSION' ,
                    lc_po_no
                    ||'-TAX' ,
                    lc_order_no
                    ||'-TAX' ,
                    lc_unique_number
                    ||'-TAX' ,
                    lcu_process_lines(indx).pay_due_date -- Added by Punit on 09-JAN-2018 to display the  Due Date value in Reference Field of Invoice Header.
                    ,
                    lc_attribute6 ,
                    'TAX' ,
                    lc_seg_company ,
                    lc_seg_costcenter ,
                    lc_seg_account ,
                    lc_seg_location ,
                    lc_seg_intercompany ,
                    lc_seg_lob ,
                    lc_seg_future ,
                    ln_org_id ,
                    100 ,
                    ln_user_id ,
                    ld_date ,
                    ln_user_id ,
                    ld_date ,
                    ln_login_id
                  );
              EXCEPTION
              WHEN OTHERS THEN
                lc_error_flag_val := 'Y';
                lc_error_message  := 'Batch Id : '||p_batch_id||' and Trx Number : '||lc_unique_number||' - OMX_INTERFACE_TAX_LINE_DISTRIBUTIONS_INSERTION_FAIL: ' || SQLCODE||' - '||SUBSTR(SQLERRM,1,3500);
                Print_Debug_Msg (lc_error_message);
                Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'OMX_INTERFACE_TAX_LINE_DISTRIBUTIONS_INSERTION_FAIL' ,p_error_message => lc_error_message ,p_stage_col1 => 'INV_NO' ,p_stage_val1 => lc_unique_number , p_all_error_messages => lv_all_error_messages);
                x_ret_code := 1;
              END;
            END IF;
          END IF; -- IF lcu_process_lines(indx).tax_amt > 0
        END IF;   -- IF lc_error_flag_val = 'N'
        IF (lc_error_flag_val   = 'Y') THEN
          lt_stg(ln_count)     := lcu_process_lines(indx).record_id;
          lt_stg_err(ln_count) := lv_all_error_messages; --gc_error_msg;
          ln_count             := ln_count +1;
          -- ln_failed_val_count := ln_failed_val_count + 1;
          ROLLBACK TO SAVEPOINT S_RA_INTERFACE;
        END IF;
      END IF; -- p_validate_only_flag = 'N'
    END LOOP; -- indx IN 1 .. lcu_process_lines(indx).COUNT
  END LOOP;   -- Bulk Cursor OPEN cur_process_lines
  --END LOOP; --End of RA_LINES Loop
  COMMIT;
  -- Updating all the Batch/AllBatches errors as process_flag = 3
  BEGIN
    UPDATE xxod_omx_cnv_ar_trx_stg
    SET process_flag      = 3
    WHERE conv_error_flag = 'Y'
    AND conv_error_msg   IS NOT NULL --- Added by Punit on 29-JAN-2018
    AND batch_id          = p_batch_id;
    COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    lc_error_flag_val := 'Y';
    lc_error_message  := 'Exception when updating Summary Level Validations - Batch or ALL Batches : - ' || SQLCODE||' - '||SUBSTR(SQLERRM,1,3500);
    Print_Debug_Msg (lc_error_message);
    x_ret_code := 1;
  END;
  -- Updating the Process_Flag to 3 and 4
  BEGIN
    lc_error_loc   := 'Updation of Process Flag 3 and 4';
    lc_error_debug := 'Batch id: '|| p_batch_id;
    FORALL ln_count IN 1..lt_stg.LAST
    UPDATE xxod_omx_cnv_ar_trx_stg
    SET process_flag = 3,
      conv_error_msg = conv_error_msg
      ||';'
      ||lt_stg_err(ln_count)
    WHERE record_id = lt_stg(ln_count)
    AND batch_id    = p_batch_id;
    COMMIT;
    UPDATE xxod_omx_cnv_ar_trx_stg
    SET process_flag   = 4
    WHERE process_flag = 2
    AND batch_id       = p_batch_id;
    COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    lc_error_flag_val := 'Y';
    lc_error_message  := 'Process Flag 3,4 Updation Failed - XXODN_CNV_UPD_3_4_EBS_EXCEPTION: ' || SQLCODE||' - '||SUBSTR(SQLERRM,1,3500);
    Print_Debug_Msg (lc_error_message);
    x_ret_code := 1;
  END;
  --counting No: of Sucessfully processed records
  --  ln_success_count := ln_tot_batch_count - ln_failed_val_count - ln_failed_proc_count;
  COMMIT;
  OPEN lcu_ar_inv_cnv_stats;
  FETCH lcu_ar_inv_cnv_stats
  INTO ln_inv_still_eligible_cnt,
    ln_inv_val_load_cnt,
    ln_inv_error_cnt,
    ln_inv_ready_process;
  CLOSE lcu_ar_inv_cnv_stats;
  --Printing the Summary info on the log file
  Print_Debug_Msg(p_message => '--------------------Conversion Invoices for batch_id: '||p_batch_id||'---------------------------');
  Print_Debug_Msg(p_message => 'Records Successfully Validated are '|| (ln_inv_val_load_cnt+ln_inv_error_cnt));
  Print_Debug_Msg(p_message => 'Records Validated and Errored are '|| ln_inv_error_cnt);
  Print_Debug_Msg(p_message => 'Records Eligible for Validation but Untouched  are '|| ln_inv_still_eligible_cnt);
  --Printing the Summary info on the out file
  Print_Out_Msg(p_message => '--------------------Conversion Invoices for batch_id: '||p_batch_id||'---------------------------');
  Print_Out_Msg(p_message => 'Records Successfully Validated are '|| (ln_inv_val_load_cnt+ln_inv_error_cnt));
  Print_Out_Msg(p_message => 'Records Validated and Errored are '|| ln_inv_error_cnt);
  Print_Out_Msg(p_message => 'Records Eligible for Validation but Untouched  are '|| ln_inv_still_eligible_cnt);
EXCEPTION
WHEN OTHERS THEN
  lc_error_message := 'Child Program - Batch Id: '||p_batch_id||' Exception is '||SQLCODE||' - '||SQLERRM;
  Log_Error (p_program_step => lc_error_loc ,p_primary_key => lc_unique_number ,p_error_code => 'XXODN_CNV_CHILD_PROG_EXCEPTION' ,p_error_message => lc_error_message ,p_stage_col1 => 'PROCESS_FLAG' ,p_stage_val1 => '3' ,p_all_error_messages => lv_all_error_messages );
  Print_Debug_Msg (lc_error_message);
  x_ret_code := 1;
END Valid_Load_Child;
END XXOD_OMX_CNV_AR_TRX_PKG;
/