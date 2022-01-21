SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT CREATING PACKAGE XX_AP_PAYMENT_BATCH_PKG

PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE
PACKAGE BODY XX_AP_PAYMENT_BATCH_PKG AS
  -- +======================================================================================================================+
  -- |                  Office Depot - Project Simplify                                                                     |
  -- |                            Providge                                                                                  |
  -- +======================================================================================================================+
  -- | Name             :    XX_AP_PAYMENT_BATCH_PKG                                                                        |
  -- | Description      :    Package for AP Payment batch Process                                                           |
  -- |                                                                                                                      |
  -- |                                                                                                                      |
  -- |                                                                                                                      |
  -- |Change Record:                                                                                                        |
  -- |===============                                                                                                       |
  -- |Version   Date         Author              Remarks                                                                    |
  -- |=======   ===========  ================    ===========================================================================|
  -- |1.0       02-APR-2007  Sarat Uppalapati    Initial version                                                            |
  -- | 1.0      25-JUN-2007  Sarat Uppalapati    Added Parameters                                                           |
  -- | 1.0      26-JUN-2007  Sarat Uppalapati    removed set Org Context                                                    |
  -- | 1.0      26-JUN-2007  Sarat Uppalapati    Modified Period Name                                                       |
  -- | 1.0      27-JUN-2007  Sarat Uppalapati    Updated Distribution Mail                                                  |
  -- | 1.0      03-JUl-2007  Sarat Uppalapati    Added Error Handling                                                       |
  -- | 1.0      06-SEP-2007  Sarat Uppalapati    Added additional Parameters                                                |
  -- |                                           based on "CR 223"                                                          |
  -- | 1.0      19-JUl-2007  Sarat Uppalapati    Added SCR Logic                                                            |
  -- | 1.0      17-SEP-2007  Sarat Uppalapati    Chnaged P_CONFIRM_NOW ='Y'                                                 |
  -- |                                           for "ACH                                                                   |
  -- |                                           Removed SCR Code                                                           |
  -- | 1.0      18-SEP-2007  Sarat Uppalapati    Added fnd_request.add_layout                                               |
  -- |                       for resolve the     issue for viewing the output                                               |
  -- | 1.0      18-SEP-2007  Sarat Uppalapati    Changed XXODROEMAILER to                                                   |
  -- |                                           "XXODXMLEMAIL"                                                             |
  -- | 1.0      19-SEP-2007  Sarat Uppalapati    Chnaged P_CONFIRM_NOW ='N'                                                 |
  -- |                                           for "EFT"                                                                  |
  -- | 1.0      24-SEP-2007  Sarat Uppalapati    Added additional code for                                                  |
  -- |                                           CR 221                                                                     |
  -- | 1.0      09-OCT-2007  Sarat Uppalapati    Added additional Prameter                                                  |
  -- |                                           For Payment Activity Report                                                |
  -- | 1.0      09-OCT-2007  Sarat Uppalapati    Removed code for calling                                                   |
  -- |                                           Cash Forecast Report                                                       |
  -- | 1.1      21-NOV-2007  Sandeep Pandhare    Correct spelling for "attachment"                                          |
  -- |                                           Defect 2766/2767                                                           |
  -- | 1.2      18-FEB-2008  Sandeep Pandhare    Defect 4687                                                                |
  -- | 1.3      27-FEB-2008  Greg Dill           Added conditions to EFT                                                    |
  -- |                                           processing for Defect 3614                                                 |
  -- | 1.4      06-MAR-2008  Sarat Uppalapati    Defect 5224                                                                |
  -- | 1.5      08-JUL-2008  Sarat Uppalapati    Defect 8841                                                                |
  -- | 1.6      11-JUL-2008  Sandeep Pandhare    Defect 8932                                                                |
  -- | 1.7      14-JUL-2008  Sandeep Pandhare    Defect 8945                                                                |
  -- | 1.8      14-JUL-2008  Peter Marco         Defect 8906                                                                |
  -- | 1.9      05-AUG-2008  Sandeep Pandhare    Defect 9428                                                                |
  -- | 1.10     07-AUG-2008  Sandeep Pandhare    Defect 9638                                                                |
  -- | 1.11     13-AUG-2008  Sandeep Pandhare    Defect 9428                                                                |
  -- | 1.12     17-SEP-2008  Sandeep Pandhare    Defect 11271 Change Paygroup to US_OD_EFT_SPEC_TERMS                       |
  -- | 1.13     24-SEP-2008  Joe Klein           Defect 11495 Add FND_REQUEST.SET_PRINT_OPTIONS, setting printer = XPTR     |
  -- |                                           and copies = 1 before spawning programs XXAPEFTNME, XXAPEFTNMT, XXAPEFTPAR.|
  -- | 1.14     16-OCT-2008  Sandeep Pandhare    Defect 11961                                                               |
  -- | 1.15     21-OCT-2008  Peter Marco         Defect 12065 updated invoice                                               |
  -- |                                           range amounts                                                              |
  -- |                                           XXAPEFTNMT           -24999.99 to 24999.99                                 |
  -- |                                           XXAPEFTNME           -10000.00 to 10000.00                                 |
  -- | 1.16     09-ARP-2009  Joe Klein           Defect 13800                                                               |
  -- |                                           Changed so that pay_group 'US_OD_EFT_SPEC_TERMS' will trigger trade report |
  -- |                                           XXAPEFTNMT instead of expense report XXAPEFTNME.                           |
  -- | 1.17     18-AUG-2009  Defect 2078         Correct multi-rows from being returned on Sub-query                        |
  -- | 1.18     29-SEP-2009  Gokila Tamilselvam  Added XXAPDMREP procedure to the package to submit the APDM                |
  -- |                                           reports. Defect# 1431 R1.1                                                 |
  -- | 1.19     06-Jul-2010  Priyanka Nagesh     Added AP_TDM_FORMAT Procedure to Submit the                                |
  -- |                                           OD: AP Format APDM Report for TDM for the APDM Reports                     |
  -- |                                           for R1.4 CR 542 defect 3327                                                |
  -- | 1.20     24-Jun-2011  Abdul Khan          Modified the character length of lc_checkrun_name variable in              |
  -- |                                           cancel_payment_batc procedure. QC Defect # 12233                           |
  -- +======================================================================================================================+
  PROCEDURE batch_process(p_errbuf IN OUT VARCHAR2,   p_retcode IN OUT NUMBER,   p_batch_name VARCHAR2,   p_bank_name VARCHAR2,   p_bank_branch VARCHAR2,   p_bank_account_name VARCHAR2,   p_document VARCHAR2,   p_pay_method VARCHAR2,   p_doc_order VARCHAR2,   p_pay_group VARCHAR2,   p_pay_thu_dt VARCHAR2 -- CR 223
  ,   p_check_date VARCHAR2 -- CR 223
  ,   p_batch_skip VARCHAR2 -- CR 223
  /* Begin new parameters */,   p_select_invoices VARCHAR2,   p_build_payments VARCHAR2,   p_format_payments VARCHAR2,   p_format_program_name VARCHAR2,   p_confirm_payment_batch VARCHAR2,   p_email_id VARCHAR2,   p_output_format VARCHAR2
   /* End  new parameters */) --PROCEDURE PAYMENT_BATCH (p_pay_group  VARCHAR2)
  IS
   /* Define Variables */ lc_event constant VARCHAR2(30) := 'BATCH_PROCESS';
  ld_when DATE := sysdate;
  ln_who NUMBER := to_number(fnd_profile.VALUE('USER_ID'));
  ln_last_update_login NUMBER := to_number(fnd_profile.VALUE('LOGIN_ID'));
  ld_creation_date DATE := ld_when;
  ln_created_by NUMBER := ln_who;
  ld_last_update_date DATE := ld_when;
  ln_last_updated_by NUMBER := ln_who;
  ld_check_date DATE;
  ld_pay_thru_date DATE;
  ln_hi_payment_priority NUMBER := 1;
  ln_low_payment_priority NUMBER := 99;
  lc_period_name VARCHAR2(200) := to_char(sysdate,   'MON-RR');
  lc_status VARCHAR2(200) := 'UNSTARTED';
  lc_currency_code VARCHAR2(200) := 'USD';
  lc_pay_only_when_due_flag VARCHAR2(200) := 'N';
  lc_audit_required_flag VARCHAR2(200) := 'N';
  lc_zero_amounts_allowed VARCHAR2(200) := 'N';
  lc_future_dated_payment_flag VARCHAR2(200) := 'N';
  lc_template_flag VARCHAR2(200) := 'N';
  lc_check_stock_name ap_check_stocks.name%TYPE;
  lc_payment_method_lookup_code VARCHAR2(200);
  lc_bank_account_name VARCHAR2(200);
  lc_document_order_lookup_code VARCHAR2(200);
  lc_checkrun_name VARCHAR2(200);
  ln_org_id NUMBER;
  lc_rowid VARCHAR2(200);
  lc_vendor_pay_group VARCHAR2(200);
  ln_max_payment_amount NUMBER;
  ln_min_check_amount NUMBER;
  ln_max_outlay NUMBER;
  ln_check_stock_id NUMBER;
  ln_exchange_rate NUMBER;
  lc_exchange_rate_type VARCHAR2(200);
  ld_exchange_date DATE;
  ln_interval NUMBER;
  lc_volume_serial_number VARCHAR2(200);
  lc_attribute_category VARCHAR2(200);
  lc_attribute1 VARCHAR2(200);
  lc_attribute2 VARCHAR2(200);
  lc_attribute3 VARCHAR2(200);
  lc_attribute4 VARCHAR2(200);
  lc_attribute5 VARCHAR2(200);
  lc_attribute6 VARCHAR2(200);
  lc_attribute7 VARCHAR2(200);
  lc_attribute8 VARCHAR2(200);
  lc_attribute9 VARCHAR2(200);
  lc_attribute10 VARCHAR2(200);
  lc_attribute11 VARCHAR2(200);
  lc_attribute12 VARCHAR2(200);
  lc_attribute13 VARCHAR2(200);
  lc_attribute14 VARCHAR2(200);
  lc_attribute15 VARCHAR2(200);
  lc_ussgl_transaction_code VARCHAR2(200);
  lc_ussgl_trv_code_context VARCHAR2(200);
  ln_start_print_document NUMBER;
  ln_end_print_document NUMBER;
  ln_first_voucher_number NUMBER;
  ln_first_available_document NUMBER;
  lc_zero_invoices_allowed VARCHAR2(200);
  ln_checkrun_id NUMBER;
  lc_batch_identifier VARCHAR2(200);
  ln_bank_account_id NUMBER := 10000;
  lc_transfer_priority VARCHAR2(200);
  ld_anticipated_value_date DATE;
  ln_invoice_batch_id NUMBER;
  ln_vendor_id NUMBER;
  lc_calling_sequence VARCHAR2(200);
  lc_errbuf VARCHAR2(2000);
  ln_retcode NUMBER;
  lc_bank_name VARCHAR2(80);
  lb_return boolean;
  lc_canonical_dt_mask VARCHAR2(26) := 'YYYY/MM/DD HH24:MI:SS';
  lc_remittance_program_name VARCHAR2(45);
  lc_build_confirm_now VARCHAR2(32);
  lc_error_flag VARCHAR2(1) := 'N';
  -- defect 9638
  ln_req_id NUMBER;
  ln_req_id1 NUMBER;
  ln_req_id2 NUMBER;
  ln_req_id3 NUMBER;
  ln_req_id11 NUMBER;
  ln_req_id22 NUMBER;
  ln_req_id33 NUMBER;
  lc_phase VARCHAR2(50);
  lc_reqstatus VARCHAR2(50);
  lc_devphase VARCHAR2(50);
  lc_devstatus VARCHAR2(50);
  lc_message VARCHAR2(50);
  lc_req_status boolean;
  lc_error_loc VARCHAR2(2000) := NULL;
  lc_err_msg VARCHAR2(250);
  lc_program_name VARCHAR2(2000) := NULL;
  lc_shor_name VARCHAR2(250);
  ln_doc_name_found NUMBER;
  lb_temp boolean;
  -- Defect 8906
  document_found_exp
   EXCEPTION;
  lc_checkrun_nm apps.ap_inv_selection_criteria_v.checkrun_name%TYPE;
  BEGIN
    --Printing the Parameters
    fnd_file.PUT_LINE(fnd_file.LOG,   'Parameters');
    fnd_file.PUT_LINE(fnd_file.LOG,   '------------------------------------------');
    fnd_file.PUT_LINE(fnd_file.LOG,   '            Batch Name: ' || p_batch_name);
    fnd_file.PUT_LINE(fnd_file.LOG,   '             Bank Name: ' || p_bank_name);
    fnd_file.PUT_LINE(fnd_file.LOG,   '      Bank Branch Name: ' || p_bank_branch);
    fnd_file.PUT_LINE(fnd_file.LOG,   '     Bank Account Name: ' || p_bank_account_name);
    fnd_file.PUT_LINE(fnd_file.LOG,   '         Document Name: ' || p_document);
    fnd_file.PUT_LINE(fnd_file.LOG,   '   Payment Method Name: ' || p_pay_method);
    fnd_file.PUT_LINE(fnd_file.LOG,   '        Document Order: ' || p_doc_order);
    fnd_file.PUT_LINE(fnd_file.LOG,   '             Pay Group: ' || p_pay_group);
    fnd_file.PUT_LINE(fnd_file.LOG,   '      Pay Through Date: ' || p_pay_thu_dt);
    fnd_file.PUT_LINE(fnd_file.LOG,   '            Check Date: ' || p_check_date);
    fnd_file.PUT_LINE(fnd_file.LOG,   '            Batch Skip: ' || p_batch_skip);
    fnd_file.PUT_LINE(fnd_file.LOG,   '       Select Invoices: ' || p_select_invoices);
    fnd_file.PUT_LINE(fnd_file.LOG,   '        Build Payments: ' || p_build_payments);
    fnd_file.PUT_LINE(fnd_file.LOG,   '       Format Payments: ' || p_format_payments);
    fnd_file.PUT_LINE(fnd_file.LOG,   '   Format Program Name: ' || p_format_program_name);
    fnd_file.PUT_LINE(fnd_file.LOG,   ' Confirm Payment Batch: ' || p_confirm_payment_batch);
    fnd_file.PUT_LINE(fnd_file.LOG,   '              Email ID: ' || p_email_id);
    fnd_file.PUT_LINE(fnd_file.LOG,   '         Output Format: ' || p_output_format);
    fnd_file.PUT_LINE(fnd_file.LOG,   '------------------------------------------');
    ---------------------------------------------------------------------------------------------
    -- Defect 8906 Program needs to fail if document type is exisits on ap_inv_selection_criteria
    ---------------------------------------------------------------------------------------------
    BEGIN
      fnd_file.PUT_LINE(fnd_file.LOG,   'Document test Started!');
      lc_checkrun_nm := NULL;
      SELECT checkrun_name
      INTO lc_checkrun_nm
      FROM ap_inv_selection_criteria_v
      WHERE status NOT IN('CANCELED',   'CONFIRMED')
       AND document_name = p_document
       AND rownum = 1
      GROUP BY checkrun_name;
      IF lc_checkrun_nm IS NOT NULL THEN
        RAISE document_found_exp;
      END IF;
    EXCEPTION
    WHEN no_data_found THEN
      fnd_file.PUT_LINE(fnd_file.LOG,   'Document test completed!');
    END;
    ln_org_id := fnd_profile.VALUE('ORG_ID');
    /* Get the Checkrun ID */
    SELECT ap_inv_selection_criteria_s.nextval
    INTO ln_checkrun_id
    FROM dual;
    IF UPPER(p_batch_skip) IN('N',   'NO') THEN
      lc_checkrun_name := p_batch_name;
      lc_bank_name := p_bank_name;
      lc_check_stock_name := p_document;
      lc_payment_method_lookup_code := p_pay_method;
      lc_document_order_lookup_code := p_doc_order;
      lc_vendor_pay_group := p_pay_group;
      ld_pay_thru_date := fnd_conc_date.string_to_date(p_pay_thu_dt);
      ld_check_date := fnd_conc_date.string_to_date(p_check_date);
      /* Assign the Concurrent Program and Short Name */
      IF UPPER(p_pay_group) = 'US_OD_ACH' THEN
        lc_program_name := 'OD: AP ACH Payment Batch Process';
        lc_shor_name := 'XXAPPBP';
        ELSIF(UPPER(p_pay_group) = 'US_OD_EXP_EFT') THEN
          lc_program_name := 'OD: AP EFT Expense Payment Batch Process';
          lc_shor_name := 'XXAPPBP2';
          ELSIF(UPPER(p_pay_group) = 'US_OD_EXP_SPEC_TERMS') -- defect 8932
          THEN
            lc_program_name := 'OD: AP EFT Expense Spec Terms Payment Batch Process';
            lc_shor_name := 'XXAPPBP4';
            ELSIF(UPPER(p_pay_group) = 'US_OD_TRADE_SPECIAL_TERMS') -- defect 8945
            THEN
              lc_program_name := 'OD: AP EFT Trade Spec Terms Payment Batch Process';
              lc_shor_name := 'XXAPPBP5';
              ELSIF(UPPER(p_pay_group) = 'US_OD_TRADE_EFT') THEN
                lc_program_name := 'OD: AP EFT Trade Payment Batch Process';
                lc_shor_name := 'XXAPPBP1';
                ELSIF(UPPER(p_pay_group) = 'US_OD_SCR') THEN
                  lc_program_name := 'OD: AP SCR Payment Batch Process';
                  lc_shor_name := 'XXAPPBP3';
                END IF;
                /* Get the Check Stock Details */
                BEGIN
                  lc_error_loc := 'Getting the Check Stock ID and Document Num of ' || lc_program_name;
                  --      FND_FILE.PUT_LINE(fnd_file.log, lc_error_loc);
                  SELECT check_stock_id,
                         last_document_num + 1
                    INTO ln_check_stock_id,
                         ln_first_available_document
                    FROM ap_check_stocks
                   WHERE name            = lc_check_stock_name
                     AND bank_account_id =
                                (SELECT bank_account_id
                                   FROM ap_bank_accounts
                                  WHERE bank_account_name = p_bank_account_name
                                    AND bank_branch_id    = (SELECT bank_branch_id                    --added per defect 2078
                                                               FROM  ap_bank_branches                 --added per defect 2078
                                                              WHERE  bank_name =  p_bank_name         --added per defect 2078
                                                                AND  bank_branch_name = p_bank_branch --added per defect 2078
                                                             )                                        --added per defect 2078
                                    AND inactive_date is NULL                                         --added per defect 2078
                                 )
                  -- AND inactive_date is NULL; --defect 4687
                     AND(TRUNC(inactive_date) > TRUNC(sysdate) OR inactive_date IS NULL); --defect 4687
                  EXCEPTION
                  WHEN others THEN
                    fnd_message.set_name('XXFIN',   'XX_AP_0001_ERR');
                    fnd_message.set_token('ERR_LOC',   lc_error_loc);
                    fnd_message.set_token('ERR_ORA',   sqlerrm);
                    lc_err_msg := fnd_message.GET;
                    fnd_file.PUT_LINE(fnd_file.LOG,   lc_err_msg);
                    xx_com_error_log_pub.log_error(p_program_type => 'CONCURRENT PROGRAM',   p_program_name => lc_shor_name,   p_program_id => fnd_global.conc_program_id,   p_module_name => 'AP',   p_error_location => 'Error at ' || lc_error_loc,   p_error_message_count => 1,   p_error_message_code => 'E',   p_error_message => lc_err_msg,   p_error_message_severity => 'Major',   p_notify_flag => 'N',   p_object_type => 'Payment Batch Automation');
                    --  Defect 4687
                    p_errbuf := lc_err_msg;
                    p_retcode := 2;
                    lc_error_flag := 'Y';
                    -- Defect 9638
                  END;
                  IF lc_error_flag = 'N' -- Defect 9638
                  THEN
                    /* Get the Bank Account Details */
                    BEGIN
                      lc_error_loc := 'Getting the Bank Account Name and ID of ' || lc_program_name;
                      --      FND_FILE.PUT_LINE(fnd_file.log, lc_error_loc);
                      SELECT bank_account_name,
                             bank_account_id
                        INTO lc_bank_account_name,
                             ln_bank_account_id
                        FROM ap_bank_accounts aba,
                             ap_bank_branches abb
                       WHERE abb.bank_branch_id = aba.bank_branch_id
                         AND UPPER(abb.bank_name) = UPPER(lc_bank_name)
                         AND aba.bank_account_name = p_bank_account_name
                         AND abb.bank_branch_name = p_bank_branch                            --added per defect 2078
                         AND account_holder_name_alt IS NOT NULL
                         AND org_id = ln_org_id;
                    EXCEPTION
                    WHEN others THEN
                      fnd_message.set_name('XXFIN',   'XX_AP_0001_ERR');
                      fnd_message.set_token('ERR_LOC',   lc_error_loc);
                      fnd_message.set_token('ERR_ORA',   sqlerrm);
                      lc_err_msg := fnd_message.GET;
                      fnd_file.PUT_LINE(fnd_file.LOG,   lc_err_msg);
                      xx_com_error_log_pub.log_error(p_program_type => 'CONCURRENT PROGRAM',   p_program_name => lc_shor_name,   p_program_id => fnd_global.conc_program_id,   p_module_name => 'AP',   p_error_location => 'Error at ' || lc_error_loc,   p_error_message_count => 1,   p_error_message_code => 'E',   p_error_message => lc_err_msg,   p_error_message_severity => 'Major',   p_notify_flag => 'N',   p_object_type => 'Payment Batch Automation');
                      p_errbuf := lc_err_msg;
                      p_retcode := 2;
                      --           RAISE;  Defect 9638
                    END;
                    /* Create the Payment Batch */
                    BEGIN
                      lc_error_loc := 'Unable to Insert Data ' || lc_program_name;
                      ap_inv_selection_criteria_pkg.insert_row(lc_rowid,   lc_checkrun_name,   ld_check_date,   ld_last_update_date,   ln_last_updated_by,   lc_bank_account_name,   lc_period_name,   ld_pay_thru_date,   lc_vendor_pay_group,   ln_hi_payment_priority,   ln_low_payment_priority,   ln_max_payment_amount,   ln_min_check_amount,   ln_max_outlay,   lc_pay_only_when_due_flag,   lc_status,   ln_check_stock_id,   lc_currency_code,   ln_exchange_rate,   lc_exchange_rate_type,   ld_exchange_date,   lc_document_order_lookup_code,   lc_audit_required_flag,   ln_interval,   ln_last_update_login,   ld_creation_date,   ln_created_by,   lc_volume_serial_number,   lc_attribute_category,   lc_attribute1,   lc_attribute2,   lc_attribute3,   lc_attribute4,   lc_attribute5,   lc_attribute6,   lc_attribute7,   lc_attribute8,   lc_attribute9,   lc_attribute10,   lc_attribute11,   lc_attribute12,   lc_attribute13,   lc_attribute14,   lc_attribute15,   lc_ussgl_transaction_code,   lc_ussgl_trv_code_context,   lc_zero_amounts_allowed,   ln_start_print_document,   ln_end_print_document,   ln_first_voucher_number,   ln_first_available_document,   lc_payment_method_lookup_code,   lc_zero_invoices_allowed,   ln_org_id,   ln_checkrun_id,   lc_batch_identifier,   ln_bank_account_id,   lc_template_flag,   lc_transfer_priority,   lc_future_dated_payment_flag,   ld_anticipated_value_date,   ln_invoice_batch_id,   ln_vendor_id,   lc_calling_sequence);
                      COMMIT;
                    EXCEPTION
                    WHEN others THEN
                      fnd_message.set_name('XXFIN',   'XX_AP_0001_ERR');
                      fnd_message.set_token('ERR_LOC',   lc_error_loc);
                      fnd_message.set_token('ERR_ORA',   sqlerrm);
                      lc_err_msg := fnd_message.GET;
                      fnd_file.PUT_LINE(fnd_file.LOG,   lc_err_msg);
                      xx_com_error_log_pub.log_error(p_program_type => 'CONCURRENT PROGRAM',   p_program_name => lc_shor_name,   p_program_id => fnd_global.conc_program_id,   p_module_name => 'AP',   p_error_location => 'Error at ' || lc_error_loc,   p_error_message_count => 1,   p_error_message_code => 'E',   p_error_message => lc_err_msg,   p_error_message_severity => 'Major',   p_notify_flag => 'N',   p_object_type => 'Payment Batch Automation');
                    END;
                    /* Initialize the Payment Batch Process */ ap_payment_processor.initialize(lc_checkrun_name);
                    IF(UPPER(p_select_invoices) IN('Y',   'YES')) THEN
                      ap_payment_processor.append_program('AUTOSELECT');
                      ap_payment_processor.append_parameter('P_PAYMENT_BATCH',   lc_checkrun_name);
                      ap_payment_processor.append_parameter('P_DEBUG_SWITCH',   'N');
                      ap_payment_processor.append_parameter('P_TRACE_SWITCH',   'N');
                    END IF;
                    IF(UPPER(p_build_payments) IN('Y',   'YES')) THEN
                      /* Checking the confirm payment batch flag */
                      IF((UPPER(p_confirm_payment_batch) IN('Y',   'YES'))
                       AND(p_pay_method IN('EFT',   'WIRE',   'CLEARING'))) THEN
                        lc_build_confirm_now := 'Y';
                      ELSE
                        lc_build_confirm_now := 'N';
                      END IF;
                      ap_payment_processor.append_program('BUILD');
                      ap_payment_processor.append_parameter('P_USER_ID',   to_number(fnd_profile.VALUE('USER_ID')));
                      ap_payment_processor.append_parameter('P_LOGIN_ID',   to_number(fnd_profile.VALUE('LOGIN_ID')));
                      ap_payment_processor.append_parameter('P_PAYMENT_BATCH',   lc_checkrun_name);
                      ap_payment_processor.append_parameter('P_CONFIRM_NOW',   lc_build_confirm_now);
                      ap_payment_processor.append_parameter('P_DEBUG_SWITCH',   'N');
                      ap_payment_processor.append_parameter('P_TRACE_SWITCH',   'N');
                    END IF;
                    IF(UPPER(p_format_payments) IN('Y',   'YES')) THEN
                      ap_payment_processor.append_program('FORMAT');
                      ap_payment_processor.append_parameter('P_PAYMENT_BATCH',   lc_checkrun_name);
                      ap_payment_processor.append_parameter('P_FORMAT_PAYMENTS_PROGRAM_NAME',   p_format_program_name);
                    END IF;
                    /*   -- defect 9428 The confirmation is disabled for ACH since it will executed as a
     -- separate process in ESP
     -- Program: OD: AP ACH Payment Batch Process
     -- Program: OD: AP Payment Batch Confirmation    Parameters: EFT, Y
      IF (UPPER(p_confirm_payment_batch) IN ('Y','YES')) THEN
      ap_payment_processor.append_program('CONFIRM');
      ap_payment_processor.append_parameter('CHECKRUN',lc_checkrun_name);
      ap_payment_processor.append_parameter('UPDATE_DATE',to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
      ap_payment_processor.append_parameter('UPDATE_BY',to_char(FND_PROFILE.VALUE('USER_ID')));
      ap_payment_processor.append_parameter('LINES_PER_PG',to_char(FND_PROFILE.VALUE('MAX_PAGE_LENGTH')));
      END IF;
*/
                     ap_payment_processor.submit(errbuf => lc_errbuf,   retcode => ln_retcode,   p_org_id => ln_org_id,   p_event => lc_event,   p_calling_sequence => 'APXPAWKB->PAYMENT_PROCESSOR.Submit_Conc_Program');
                    COMMIT;
                    IF(ln_retcode <> 0) THEN
                      /* Wait for the Sumbit request to complete */ lc_req_status := fnd_concurrent.wait_for_request(ln_retcode -- request_id
                      ,   30 -- interval
                      ,   360000 -- max_wait
                      ,   lc_phase -- phase
                      ,   lc_reqstatus -- status
                      ,   lc_devphase -- dev_phase
                      ,   lc_devstatus -- dev_status
                      ,   lc_message -- message
                      );
                      --        IF (UPPER(p_pay_group) IN ('US_OD_EXP_EFT')) THEN
                      --        For DF 3614 added p_build_payments condition
                      IF(UPPER(p_build_payments) IN('Y',   'YES'))
                       AND(UPPER(p_pay_group) IN('US_OD_EXP_EFT',   'US_OD_EXP_SPEC_TERMS')) THEN
                        -- Defect 11271 defect 8932
                        /* Sumbit request for EFT NonMatch Expense Report */ lb_temp := fnd_request.add_layout('XXFIN',   'XXAPEFTNME',   'en',   'US',   p_output_format);
                        lb_temp := fnd_request.set_print_options('XPTR',   NULL,   '1',   TRUE,   'N');
                        ln_req_id1 := fnd_request.submit_request('XXFIN',   'XXAPEFTNME',   NULL,   NULL,   FALSE,   lc_checkrun_name --p_batch_name
                       -- ,   '-10000' --p_invoice_amount_low Added for 3614 commented out per defect 12065
                       -- ,   '10000' --p_invoice_amount_high Added for 3614 commented out per defect 12065
                        ,'-10000.00' --p_invoice_amount_low Updated per defect 12065
                        ,'10000.00'  --p_invoice_amount_high Updated per defect 12065
                        , CHR(0) --Added for 3614
                        );
                        /* Start the request */
                        COMMIT;
                        IF ln_req_id1 = 0 THEN
                          fnd_file.PUT_LINE(fnd_file.LOG,   'Error submitting request for ''EFT NonMatch Expense Report''.');
                          lc_error_loc := 'Error submitting request for EFT Non Match Expense Report';
                          fnd_message.set_name('XXFIN',   'XX_AP_0001_ERR');
                          fnd_message.set_token('ERR_LOC',   lc_error_loc);
                          fnd_message.set_token('ERR_ORA',   sqlerrm);
                          lc_err_msg := fnd_message.GET;
                          fnd_file.PUT_LINE(fnd_file.LOG,   lc_err_msg);
                          xx_com_error_log_pub.log_error(p_program_type => 'CONCURRENT PROGRAM',   p_program_name => lc_shor_name,   p_program_id => fnd_global.conc_program_id,   p_module_name => 'AP',   p_error_location => 'Error at ' || lc_error_loc,   p_error_message_count => 1,   p_error_message_code => 'E',   p_error_message => lc_err_msg,   p_error_message_severity => 'Major',   p_notify_flag => 'N',   p_object_type => 'Payment Batch Automation');
                        ELSE
                          fnd_file.PUT_LINE(fnd_file.OUTPUT,   'Started ''EFT NonMatch Expense Report'' at ' || to_char(sysdate,   'DD-MON-YYYY HH24:MI:SS'));
                          fnd_file.PUT_LINE(fnd_file.OUTPUT,   ' ');
                          /* Wait for the request to complete */ lc_req_status := fnd_concurrent.wait_for_request(ln_req_id1 -- request_id
                          ,   30 -- interval
                          ,   360000 -- max_wait
                          ,   lc_phase -- phase
                          ,   lc_reqstatus -- status
                          ,   lc_devphase -- dev_phase
                          ,   lc_devstatus -- dev_status
                          ,   lc_message -- message
                          );
                          /* Submit the 'Common Emailer Program' process */ ln_req_id11 := fnd_request.submit_request('xxfin',   'XXODXMLMAILER',   NULL,   NULL,   FALSE,   '',   p_email_id,   'EFT Non-Match Expense Report',   'Please find the attachment of Output File',   'Y',   ln_req_id1,   'XXAPEFTNME');
                          /* Start the request */
                          COMMIT;
                          /* Check that the request submission was OK */
                          IF ln_req_id11 = 0 THEN
                            fnd_file.PUT_LINE(fnd_file.LOG,   'Error submitting request for ''Email Process''.');
                            lc_error_loc := 'Error submitting request for Email Process';
                            fnd_message.set_name('XXFIN',   'XX_AP_0001_ERR');
                            fnd_message.set_token('ERR_LOC',   lc_error_loc);
                            fnd_message.set_token('ERR_ORA',   sqlerrm);
                            lc_err_msg := fnd_message.GET;
                            fnd_file.PUT_LINE(fnd_file.LOG,   lc_err_msg);
                            xx_com_error_log_pub.log_error(p_program_type => 'CONCURRENT PROGRAM',   p_program_name => lc_shor_name,   p_program_id => fnd_global.conc_program_id,   p_module_name => 'AP',   p_error_location => 'Error at ' || lc_error_loc,   p_error_message_count => 1,   p_error_message_code => 'E',   p_error_message => lc_err_msg,   p_error_message_severity => 'Major',   p_notify_flag => 'N',   p_object_type => 'Payment Batch Automation');
                          ELSE
                            fnd_file.PUT_LINE(fnd_file.OUTPUT,   'Started ''Sending Email'' at ' || to_char(sysdate,   'DD-MON-YYYY HH24:MI:SS'));
                            fnd_file.PUT_LINE(fnd_file.OUTPUT,   ' ');
                            /* Sumbit request for EFT Expense Pay Activity Report */ lb_temp := fnd_request.add_layout('XXFIN',   'XXAPEFTPAR',   'en',   'US',   p_output_format);
                            lb_temp := fnd_request.set_print_options('XPTR',   NULL,   '1',   TRUE,   'N');
                            ln_req_id2 := fnd_request.submit_request('XXFIN',   'XXAPEFTPAR',   NULL,   NULL,   FALSE,   lc_checkrun_name,   lc_vendor_pay_group,   p_pay_thu_dt --SYSDATE
                            );
                            /* Start the request */
                            COMMIT;
                            IF ln_req_id2 = 0 THEN
                              fnd_file.PUT_LINE(fnd_file.LOG,   'Error submitting request for ''EFT Expense Pay Activity Report''.');
                              lc_error_loc := 'Error submitting request for EFT Expense Pay Activity Report';
                              fnd_message.set_name('XXFIN',   'XX_AP_0001_ERR');
                              fnd_message.set_token('ERR_LOC',   lc_error_loc);
                              fnd_message.set_token('ERR_ORA',   sqlerrm);
                              lc_err_msg := fnd_message.GET;
                              fnd_file.PUT_LINE(fnd_file.LOG,   lc_err_msg);
                              xx_com_error_log_pub.log_error(p_program_type => 'CONCURRENT PROGRAM',   p_program_name => lc_shor_name,   p_program_id => fnd_global.conc_program_id,   p_module_name => 'AP',   p_error_location => 'Error at ' || lc_error_loc,   p_error_message_count => 1,   p_error_message_code => 'E',   p_error_message => lc_err_msg,   p_error_message_severity => 'Major',   p_notify_flag => 'N',   p_object_type => 'Payment Batch Automation');
                            ELSE
                              fnd_file.PUT_LINE(fnd_file.OUTPUT,   'Started ''EFT Expense Pay Activity Report'' at ' || to_char(sysdate,   'DD-MON-YYYY HH24:MI:SS'));
                              fnd_file.PUT_LINE(fnd_file.OUTPUT,   ' ');
                              lc_req_status := fnd_concurrent.wait_for_request(ln_req_id2 -- request_id
                              ,   30 -- interval
                              ,   360000 -- max_wait
                              ,   lc_phase -- phase
                              ,   lc_reqstatus -- status
                              ,   lc_devphase -- dev_phase
                              ,   lc_devstatus -- dev_status
                              ,   lc_message -- message
                              );
                              /* Submit the 'Common Emailer Program' process */ ln_req_id22 := fnd_request.submit_request('xxfin',   'XXODXMLMAILER',   NULL,   NULL,   FALSE,   '',   p_email_id,   'EFT Expense Pay Activity Report',   'Please find the attachment of Output File',   'Y',   ln_req_id2,   'XXAPEFTPAR');
                              /* Start the request */
                              COMMIT;
                              /* Check that the request submission was OK */
                              IF ln_req_id22 = 0 THEN
                                fnd_file.PUT_LINE(fnd_file.LOG,   'Error submitting request for ''Email Process''.');
                                lc_error_loc := 'Error submitting request for Email Process';
                                fnd_message.set_name('XXFIN',   'XX_AP_0001_ERR');
                                fnd_message.set_token('ERR_LOC',   lc_error_loc);
                                fnd_message.set_token('ERR_ORA',   sqlerrm);
                                lc_err_msg := fnd_message.GET;
                                fnd_file.PUT_LINE(fnd_file.LOG,   lc_err_msg);
                                xx_com_error_log_pub.log_error(p_program_type => 'CONCURRENT PROGRAM',   p_program_name => lc_shor_name,   p_program_id => fnd_global.conc_program_id,   p_module_name => 'AP',   p_error_location => 'Error at ' || lc_error_loc,   p_error_message_count => 1,   p_error_message_code => 'E',   p_error_message => lc_err_msg,   p_error_message_severity => 'Major',   p_notify_flag => 'N',   p_object_type => 'Payment Batch Automation');
                              ELSE
                                fnd_file.PUT_LINE(fnd_file.OUTPUT,   'Started ''Sending Email'' at ' || to_char(sysdate,   'DD-MON-YYYY HH24:MI:SS'));
                                fnd_file.PUT_LINE(fnd_file.OUTPUT,   ' ');
                              END IF;
                            END IF;
                          END IF;
                        END IF;
                        --        ELSIF (UPPER(p_pay_group) IN ('US_OD_TRADE_EFT')) THEN
                        --        For DF 3614 added p_build_payments condition
                        ELSIF(UPPER(p_build_payments) IN('Y',   'YES'))
                         AND(UPPER(p_pay_group) IN('US_OD_TRADE_EFT',   'US_OD_TRADE_SPECIAL_TERMS',   'US_OD_EFT_SPEC_TERMS')) THEN
                          -- defect 8945
                          /* Sumbit request for EFT NonMatch Trade Report */ lb_temp := fnd_request.add_layout('XXFIN',   'XXAPEFTNMT',   'en',   'US',   p_output_format);
                          lb_temp := fnd_request.set_print_options('XPTR',   NULL,   '1',   TRUE,   'N');
                          ln_req_id1 := fnd_request.submit_request('XXFIN',   'XXAPEFTNMT',   NULL,   NULL,   FALSE,   lc_checkrun_name --p_batch_name
                          --,   '99999.99' --p_invoice_amount_low Added for 3614
                          --,   '-99999.99' --p_invoice_amount_high Added for 3614
                          ,'-24999.99' --p_invoice_amount_low Updated per defect 12065
                          ,'24999.99'  --p_invoice_amount_high Update per defect 12065
                          ,   CHR(0) --Added for 3614
                          );
                          /* Start the request */
                          COMMIT;
                          IF ln_req_id1 = 0 THEN
                            fnd_file.PUT_LINE(fnd_file.LOG,   'Error submitting request for ''EFT NonMatch Trade Report''.');
                            lc_error_loc := 'Error submitting request for EFT Non Match Trade Report';
                            fnd_message.set_name('XXFIN',   'XX_AP_0001_ERR');
                            fnd_message.set_token('ERR_LOC',   lc_error_loc);
                            fnd_message.set_token('ERR_ORA',   sqlerrm);
                            lc_err_msg := fnd_message.GET;
                            fnd_file.PUT_LINE(fnd_file.LOG,   lc_err_msg);
                            xx_com_error_log_pub.log_error(p_program_type => 'CONCURRENT PROGRAM',   p_program_name => lc_shor_name,   p_program_id => fnd_global.conc_program_id,   p_module_name => 'AP',   p_error_location => 'Error at ' || lc_error_loc,   p_error_message_count => 1,   p_error_message_code => 'E',   p_error_message => lc_err_msg,   p_error_message_severity => 'Major',   p_notify_flag => 'N',   p_object_type => 'Payment Batch Automation');
                          ELSE
                            fnd_file.PUT_LINE(fnd_file.OUTPUT,   'Started ''EFT NonMatch Trade Report'' at ' || to_char(sysdate,   'DD-MON-YYYY HH24:MI:SS'));
                            fnd_file.PUT_LINE(fnd_file.OUTPUT,   ' ');
                            /* Wait for the request to complete */ lc_req_status := fnd_concurrent.wait_for_request(ln_req_id1 -- request_id
                            ,   30 -- interval
                            ,   360000 -- max_wait
                            ,   lc_phase -- phase
                            ,   lc_reqstatus -- status
                            ,   lc_devphase -- dev_phase
                            ,   lc_devstatus -- dev_status
                            ,   lc_message -- message
                            );
                            /* Submit the 'Common Emailer Program' process */ ln_req_id11 := fnd_request.submit_request('xxfin',   'XXODXMLMAILER',   NULL,   NULL,   FALSE,   '',   p_email_id,   'EFT Non-Match Trade Report',   'Please find the attachment of Output File',   'Y',   ln_req_id1,   'XXAPEFTNMT');
                            /* Start the request */
                            COMMIT;
                            /* Check that the request submission was OK */
                            IF ln_req_id11 = 0 THEN
                              fnd_file.PUT_LINE(fnd_file.LOG,   'Error submitting request for ''Email Process''.');
                              lc_error_loc := 'Error submitting request for Email Process';
                              fnd_message.set_name('XXFIN',   'XX_AP_0001_ERR');
                              fnd_message.set_token('ERR_LOC',   lc_error_loc);
                              fnd_message.set_token('ERR_ORA',   sqlerrm);
                              lc_err_msg := fnd_message.GET;
                              fnd_file.PUT_LINE(fnd_file.LOG,   lc_err_msg);
                              xx_com_error_log_pub.log_error(p_program_type => 'CONCURRENT PROGRAM',   p_program_name => lc_shor_name,   p_program_id => fnd_global.conc_program_id,   p_module_name => 'AP',   p_error_location => 'Error at ' || lc_error_loc,   p_error_message_count => 1,   p_error_message_code => 'E',   p_error_message => lc_err_msg,   p_error_message_severity => 'Major',   p_notify_flag => 'N',   p_object_type => 'Payment Batch Automation');
                            ELSE
                              fnd_file.PUT_LINE(fnd_file.OUTPUT,   'Started ''Sending Email'' at ' || to_char(sysdate,   'DD-MON-YYYY HH24:MI:SS'));
                              fnd_file.PUT_LINE(fnd_file.OUTPUT,   ' ');
                              /* Sumbit request for EFT Trade Pay Activity Report */ lb_temp := fnd_request.add_layout('XXFIN',   'XXAPEFTPAR',   'en',   'US',   p_output_format);
                              lb_temp := fnd_request.set_print_options('XPTR',   NULL,   '1',   TRUE,   'N');
                              ln_req_id2 := fnd_request.submit_request('XXFIN',   'XXAPEFTPAR',   NULL,   NULL,   FALSE,   lc_checkrun_name,   lc_vendor_pay_group,   p_pay_thu_dt --SYSDATE
                              );
                              /* Start the request */
                              COMMIT;
                              IF ln_req_id2 = 0 THEN
                                fnd_file.PUT_LINE(fnd_file.LOG,   'Error submitting request for ''EFT Trade Pay Activity Report''.');
                                lc_error_loc := 'Error submitting request for EFT Trade Pay Activity Report';
                                fnd_message.set_name('XXFIN',   'XX_AP_0001_ERR');
                                fnd_message.set_token('ERR_LOC',   lc_error_loc);
                                fnd_message.set_token('ERR_ORA',   sqlerrm);
                                lc_err_msg := fnd_message.GET;
                                fnd_file.PUT_LINE(fnd_file.LOG,   lc_err_msg);
                                xx_com_error_log_pub.log_error(p_program_type => 'CONCURRENT PROGRAM',   p_program_name => lc_shor_name,   p_program_id => fnd_global.conc_program_id,   p_module_name => 'AP',   p_error_location => 'Error at ' || lc_error_loc,   p_error_message_count => 1,   p_error_message_code => 'E',   p_error_message => lc_err_msg,   p_error_message_severity => 'Major',   p_notify_flag => 'N',   p_object_type => 'Payment Batch Automation');
                              ELSE
                                fnd_file.PUT_LINE(fnd_file.OUTPUT,   'Started ''EFT Trade Pay Activity Report'' at ' || to_char(sysdate,   'DD-MON-YYYY HH24:MI:SS'));
                                fnd_file.PUT_LINE(fnd_file.OUTPUT,   ' ');
                                lc_req_status := fnd_concurrent.wait_for_request(ln_req_id2 -- request_id
                                ,   30 -- interval
                                ,   360000 -- max_wait
                                ,   lc_phase -- phase
                                ,   lc_reqstatus -- status
                                ,   lc_devphase -- dev_phase
                                ,   lc_devstatus -- dev_status
                                ,   lc_message -- message
                                );
                                /* Submit the 'Common Emailer Program' process */ ln_req_id22 := fnd_request.submit_request('xxfin',   'XXODXMLMAILER',   NULL,   NULL,   FALSE,   '',   p_email_id,   'EFT Trade Pay Activity Report',   'Please find the attachment of Output File',   'Y',   ln_req_id2,   'XXAPEFTPAR');
                                /* Start the request */
                                COMMIT;
                                /* Check that the request submission was OK */
                                IF ln_req_id22 = 0 THEN
                                  fnd_file.PUT_LINE(fnd_file.LOG,   'Error submitting request for ''Email Process''.');
                                  lc_error_loc := 'Error submitting request for Email Process';
                                  fnd_message.set_name('XXFIN',   'XX_AP_0001_ERR');
                                  fnd_message.set_token('ERR_LOC',   lc_error_loc);
                                  fnd_message.set_token('ERR_ORA',   sqlerrm);
                                  lc_err_msg := fnd_message.GET;
                                  fnd_file.PUT_LINE(fnd_file.LOG,   lc_err_msg);
                                  xx_com_error_log_pub.log_error(p_program_type => 'CONCURRENT PROGRAM',   p_program_name => lc_shor_name,   p_program_id => fnd_global.conc_program_id,   p_module_name => 'AP',   p_error_location => 'Error at ' || lc_error_loc,   p_error_message_count => 1,   p_error_message_code => 'E',   p_error_message => lc_err_msg,   p_error_message_severity => 'Major',   p_notify_flag => 'N',   p_object_type => 'Payment Batch Automation');
                                ELSE
                                  fnd_file.PUT_LINE(fnd_file.OUTPUT,   'Started ''Sending Email'' at ' || to_char(sysdate,   'DD-MON-YYYY HH24:MI:SS'));
                                  fnd_file.PUT_LINE(fnd_file.OUTPUT,   ' ');
                                END IF;
                              END IF;
                            END IF;
                          END IF;
                        END IF;
                      END IF;
                    END IF;
                  END IF;
                  -- sandeep
                  EXCEPTION
                   -- Defect 8906
                WHEN document_found_exp THEN
                  fnd_file.PUT_LINE(fnd_file.LOG,   '*************************************************' || '************************');
                  fnd_file.PUT_LINE(fnd_file.LOG,   'PROGRAM ERROR!');
                  fnd_file.PUT_LINE(fnd_file.LOG,   'Document "' || p_document || '" is already in use by Batch Name "' || lc_checkrun_nm || '".');
                  fnd_file.PUT_LINE(fnd_file.LOG,   'Please cancel or confirm payment batch "' || lc_checkrun_nm || '" and resubmit program.');
                  fnd_file.PUT_LINE(fnd_file.LOG,   '*************************************************' || '************************');
                  p_retcode := 2;
                WHEN others THEN
                  fnd_file.PUT_LINE(fnd_file.LOG,   'Other Exception' || sqlerrm());
                  p_retcode := 1;
                END batch_process;
                /* CR 221 Begin Coding */
                PROCEDURE confirm_batch_process(p_errbuf IN OUT VARCHAR2,   p_retcode IN OUT NUMBER,   p_payment_method VARCHAR2 -- Defect5224
                ,   p_confirm_payment_batch VARCHAR2) IS
                -- If the payment method is an CHECK we assume that:
                -- 1) If they pass the building stage we assume they must run the
                --    "OD: AP Payment Batch Confirmation" manual or scheduled
                --    which assumes one payment batch at a time.
                -- Rationale: If building does not insert into ap_checkrun_confirmations
                --            then it must be done via the confirm screen.  The only way
                --            build can insert into ap_checkrun_confirmations is if ran
                --            at the same time as the confirm.
                --
                lc_errbuf VARCHAR2(2000);
                ln_retcode NUMBER;
                ln_org_id NUMBER;
                lc_event constant VARCHAR2(30) := 'BATCH_PROCESS';
                lc_debug_info VARCHAR2(100);
                lc_dummy VARCHAR2(10) := '';
                lr_checkrun_cfm ap_checkrun_confirmations % rowtype;
                -- Defect 5224
                CURSOR checkrun_cur IS
                SELECT checkrun_name,
                  start_print_document,
                  end_print_document,
                  org_id
                FROM apps.ap_invoice_selection_criteria aisc
                WHERE UPPER(aisc.payment_method_lookup_code) = p_payment_method
                 AND UPPER(status) = 'FORMATTED';
                BEGIN
                  ln_org_id := fnd_profile.VALUE('ORG_ID');
                  --      Defect 5224
                  --      BEGIN
                  --         SELECT checkrun_name
                  --               ,start_print_document
                  --               ,end_print_document
                  --               ,org_id
                  --         INTO lr_checkrun_cfm.checkrun_name
                  --              ,lr_checkrun_cfm.start_check_number
                  --              ,lr_checkrun_cfm.end_check_number
                  --              ,lr_checkrun_cfm.org_id
                  --         FROM apps.ap_invoice_selection_criteria
                  --        WHERE UPPER(payment_method_lookup_code) = 'CHECK'
                  --          AND UPPER(status) = 'FORMATTED';
                  --      EXCEPTION
                  --           WHEN no_data_found THEN
                  --           FND_MESSAGE.SET_NAME('SQLAP', 'AP_NO_CHECK_BATCH_TO_CONFIRM');
                  --      END;
                  IF checkrun_cur % ISOPEN THEN
                    CLOSE checkrun_cur;
                  END IF;
                  OPEN checkrun_cur;
                  LOOP
                    FETCH checkrun_cur
                    INTO lr_checkrun_cfm.checkrun_name,
                      lr_checkrun_cfm.start_check_number,
                      lr_checkrun_cfm.end_check_number,
                      lr_checkrun_cfm.org_id;
                    EXIT
                  WHEN checkrun_cur % NOTFOUND;
                  --if (lr_checkrun_cfm.checkrun_name IS NOT NULL) then
                  --lr_checkrun_cfm.checkrun_name      := lr_checkrun_cfm.checkrun_name;
                  lr_checkrun_cfm.range_lookup_code := 'PRINTED';
                  lr_checkrun_cfm.processed_flag := 'N';
                  lr_checkrun_cfm.last_update_date := sysdate;
                  lr_checkrun_cfm.last_updated_by := to_number(fnd_profile.VALUE('USER_ID'));
                  lr_checkrun_cfm.last_update_login := to_number(fnd_profile.VALUE('USER_ID'));
                  lr_checkrun_cfm.creation_date := sysdate;
                  lr_checkrun_cfm.created_by := to_number(fnd_profile.VALUE('USER_ID'));
                  BEGIN
                    INSERT
                    INTO apps.ap_checkrun_confirmations
                    VALUES lr_checkrun_cfm;
                    COMMIT;
                  END;
                  ap_payment_processor.initialize(lr_checkrun_cfm.checkrun_name);
                  IF(UPPER(p_confirm_payment_batch) IN('Y',   'YES')) THEN
                    ap_payment_processor.append_program('CONFIRM');
                    ap_payment_processor.append_parameter('CHECKRUN',   lr_checkrun_cfm.checkrun_name);
                    ap_payment_processor.append_parameter('UPDATE_DATE',   to_char(sysdate,   'YYYY/MM/DD HH24:MI:SS'));
                    ap_payment_processor.append_parameter('UPDATE_BY',   to_char(fnd_profile.VALUE('USER_ID')));
                    ap_payment_processor.append_parameter('LINES_PER_PG',   to_char(fnd_profile.VALUE('MAX_PAGE_LENGTH')));
                  END IF;
                  ap_payment_processor.submit(errbuf => lc_errbuf,   retcode => ln_retcode,   p_org_id => ln_org_id,   p_event => lc_event,   p_calling_sequence => 'APXPAWKB->PAYMENT_PROCESSOR.Submit_Conc_Program');
                  COMMIT;
                  --end if;
                  --    EXIT  when checkrun_cur%NOTFOUND;
                    --Start of Defect# 1431 R1.1
                    INSERT INTO XX_AP_CONFIRMED_PAYMENT_BATCH ( payment_batch
                                                               ,last_update_date
                                                               ,last_updated_by
                                                               ,creation_date
                                                               ,created_by
                                                               ,last_update_login
                                                               ,org_id
                                                               )
                    VALUES ( lr_checkrun_cfm.checkrun_name
                            ,SYSDATE
                            ,FND_PROFILE.VALUE ('USER_ID')
                            ,SYSDATE
                            ,FND_PROFILE.VALUE ('USER_ID')
                            ,FND_PROFILE.VALUE ('USER_ID')
                            ,FND_PROFILE.VALUE ('ORG_ID')
                            );
                    COMMIT;
                    --End of Defect# 1431 R1.1
                END LOOP;
                CLOSE checkrun_cur;
              END confirm_batch_process;
              /* CR 221 End Coding */
               
              /* Defect 9428 Begin Coding */ 
               PROCEDURE cancel_payment_batch(p_checkrun_name VARCHAR2) IS
              -- If the Payment Batch has no invoices and ESP has formatted the batch
              -- then Confirmation fails therefore we call this procedure
              -- to cancel the Payment after Formatting
              lc_errbuf VARCHAR2(2000);
              ln_retcode NUMBER;
              ln_org_id NUMBER;
              lc_event constant VARCHAR2(30) := 'BATCH_PROCESS';
              lc_debug_info VARCHAR2(100);
              lc_dummy VARCHAR2(10) := '';
              --lc_checkrun_name VARCHAR2(30); --Commented for QC Defect # 12233
              lc_checkrun_name ap_invoice_selection_criteria.checkrun_name%TYPE; --Added for QC Defect # 12233
              lc_checkrun_status VARCHAR2(25);
              CURSOR checkrun_cur IS
              SELECT checkrun_name,
                status,
                org_id
              FROM apps.ap_invoice_selection_criteria aisc
              WHERE UPPER(aisc.checkrun_name) = UPPER(p_checkrun_name);
              BEGIN
                ln_org_id := fnd_profile.VALUE('ORG_ID');
                IF checkrun_cur % ISOPEN THEN
                  CLOSE checkrun_cur;
                END IF;
                OPEN checkrun_cur;
                LOOP
                  FETCH checkrun_cur
                  INTO lc_checkrun_name,
                    lc_checkrun_status,
                    ln_org_id;
                  EXIT
                WHEN checkrun_cur % NOTFOUND;
                ap_payment_processor.initialize(lc_checkrun_name);
                ap_payment_processor.append_program('CANCEL');
                ap_payment_processor.append_parameter('CHECKRUN',   lc_checkrun_name);
                ap_payment_processor.append_parameter('UPDATE_DATE',   to_char(sysdate,   'YYYY/MM/DD HH24:MI:SS'));
                ap_payment_processor.append_parameter('UPDATE_BY',   to_char(fnd_profile.VALUE('USER_ID')));
                ap_payment_processor.append_parameter('LINES_PER_PG',   to_char(fnd_profile.VALUE('MAX_PAGE_LENGTH')));
                ap_payment_processor.submit(errbuf => lc_errbuf,   retcode => ln_retcode,   p_org_id => ln_org_id,   p_event => lc_event,   p_calling_sequence => 'APXPAWKB->PAYMENT_PROCESSOR.Submit_Conc_Program');
                COMMIT;
              END LOOP;
              CLOSE checkrun_cur;
            END cancel_payment_batch;
            /* Defect 11961 Begin Coding */
            PROCEDURE hold_batch_processes(p_errbuf IN OUT VARCHAR2,   p_retcode IN OUT NUMBER) IS
            lc_errbuf VARCHAR2(2000);
            ln_retcode NUMBER;
            BEGIN
              UPDATE fnd_concurrent_requests a1
              SET a1.hold_flag = 'Y'
              WHERE a1.request_id IN
                (SELECT a2.request_id
                 FROM fnd_concurrent_programs_tl a3,
                   fnd_concurrent_requests a2
                 WHERE a3.user_concurrent_program_name = 'Submit Payment Batch Set'
                 AND a3.concurrent_program_id = a2.concurrent_program_id
                 AND a2.phase_code <> 'C'
                 AND a2.hold_flag = 'N')
              ;
            EXCEPTION
            WHEN others THEN
              fnd_file.PUT_LINE(fnd_file.LOG,   'OD: Updates to SUBMIT PAYMENT BATCH SET process failed.');
            END hold_batch_processes;
            /* Defect 11961 End Coding */
-- The below procedure is added for Defect# 1431 R1.1
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : OD: AP APDM Reports                                                 |
-- | Description : Submit RTV and Chagrgeback APDM report.                             |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |1.0       29-Sep-09    Gokila Tamilselvam   Initial Version                        |
-- |                                            Defect# 1431 R1.1                      |
-- |1.1       06-Jul-10    Priyanka Nagesh      Modified For R1.4 CR 542 Defect 3327   |
-- +===================================================================================+
    PROCEDURE SUBMIT_APDM_REPORTS  ( x_error_buff         OUT VARCHAR2
                                    ,x_ret_code           OUT NUMBER
                                   )
    AS
      CURSOR c_rtv_APDM
      IS
           SELECT  DISTINCT AISCA.checkrun_id
                 ,AISCA.checkrun_name
           FROM    apps.xx_ap_confirmed_payment_batch        XACPB
                  ,ap_inv_selection_criteria_all             AISCA
                  ,ap_checks                                 ACA
                  ,ap_invoices                               AIA
                  ,xx_fin_translatedefinition                XFTD
                  ,xx_fin_translatevalues                    XFTV
                  ,ap_invoice_payments                       AIPA
           WHERE   AISCA.checkrun_name                     = XACPB.payment_batch
           AND     XACPB.RTV                                 IS NULL
           AND     XACPB.ORG_ID                            = FND_PROFILE.VALUE ('ORG_ID')
           AND     AIA.invoice_type_lookup_code            = 'CREDIT'
           AND     XFTV.target_value1                      = AIA.SOURCE
           AND     XFTD.translate_id                       = XFTV.translate_id
           AND     XFTD.translation_name                   = 'AP_INVOICE_SOURCE'
           AND     ACA.checkrun_id                         = AISCA.checkrun_id
           AND     AISCA.status                            = 'CONFIRMED'
           AND     AIPA.check_id                           = ACA.check_id
           AND     AIPA.invoice_id                         = AIA.invoice_id
           AND     AIPA.reversal_inv_pmt_id                  IS NULL
           AND     AIA.invoice_num                           LIKE 'RTV%'
           AND     AIA.SOURCE                                LIKE '%RTV%'
           AND     AIA.voucher_num                           IS NOT NULL;
      CURSOR  c_chargeback_APDM
      IS
           SELECT  DISTINCT AISCA.checkrun_id
                  ,AISCA.checkrun_name
           FROM    apps.xx_ap_confirmed_payment_batch        XACPB
                  ,ap_inv_selection_criteria_all             AISCA
                  ,ap_checks                                 ACA
                  ,ap_invoices                               AIA
                  ,fnd_lookup_values_vl                      FLV
                  ,ap_invoice_payments                       AIPA
           WHERE   AISCA.checkrun_name                     = XACPB.payment_batch
           AND     XACPB.chargeback                          IS NULL
           AND     XACPB.ORG_ID                            = FND_PROFILE.VALUE ('ORG_ID')
           AND     ACA.checkrun_id                         = AISCA.checkrun_id
           AND     AISCA.status                            = 'CONFIRMED'
           AND     AIPA.check_id                           = ACA.check_id
           AND     AIA.attribute12                         = 'Y'
           AND     AIA.invoice_type_lookup_code            = 'STANDARD'
           AND     AIA.voucher_num                           IS NOT NULL
           AND     AIA.pay_group_lookup_code               = FLV.lookup_code
           AND     FLV.lookup_type                         = 'APCHARGEBACK_PAYGROUP'
           AND     TRUNC(NVL(FLV.end_date_active
                           ,SYSDATE+1))                    > TRUNC(SYSDATE)
           AND     AIPA.invoice_id                         = AIA.invoice_id;
       --------Parameters---------
      ln_conc_request_id                   NUMBER          := 0;
      lb_print_option                      BOOLEAN;
      lc_error_loc                         VARCHAR2(4000)  := NULL;
      lc_error_debug                       VARCHAR2(4000)  := NULL;
      lc_req_data                          VARCHAR2(100)   := NULL;
    BEGIN
       lc_req_data                                         := fnd_conc_global.request_data;               -- Added for CR 542 Defect 3327
       x_ret_code                                          := 0;                                          -- Added for CR 542 Defect 3327
       IF lc_req_data IS NULL THEN
            BEGIN
               FOR lcu_rtv_APDM IN c_rtv_APDM
               LOOP
                  lc_error_loc        := 'Setting the Printer for RTV APDM Report';
                  lc_error_debug      := 'Setting the Printer for the Payment Batch : '||lcu_rtv_APDM.checkrun_name;
                  lb_print_option     := fnd_request.set_print_options(
                                                                       printer   => 'XPTR'
                                                                      ,copies    => 1
                                                                      );
                  lc_error_loc        := 'Submitting the RTV APDM Report';
                  lc_error_debug      := 'Submiting the RTV APDM Report : '||lcu_rtv_APDM.checkrun_name||' and Payment Batch ID : '||lcu_rtv_APDM.checkrun_id;
                  ln_conc_request_id  := fnd_request.submit_request   (
                                                                       'xxfin'
                                                                      ,'XXAPRTVAPDM'
                                                                      ,NULL
                                                                      ,NULL
                                                                      ,TRUE
                                                                      ,lcu_rtv_APDM.checkrun_id
                                                                      );
               COMMIT;
                  lc_error_loc        := 'Updating the custom table to F';
                  lc_error_debug      := 'Updating the custom table for the Payment Batch : '||lcu_rtv_APDM.checkrun_name;
               --***********************************************************
               -- Updating RTV to 'F' to indicate Formatting status
               --***********************************************************
               UPDATE xx_ap_confirmed_payment_batch
               SET--rtv                   = 'Y'                                                           --Commented for CR 542 Defect 3327
                     rtv                   = 'F'                                                          --Added for CR 542 Defect 3327
                    ,last_update_date      = SYSDATE
                    ,last_updated_by       = FND_PROFILE.VALUE ('USER_ID')
                    ,last_update_login     = FND_PROFILE.VALUE ('USER_ID')
                    ,checkrun_id           = lcu_rtv_APDM.checkrun_id
                    ,request_id            = ln_conc_request_id
               WHERE payment_batch         = lcu_rtv_APDM.checkrun_name
               AND org_id                  = FND_PROFILE.VALUE ('ORG_ID');
               COMMIT;
               END LOOP;
                  lc_error_loc   := 'Updating the custom table rtv = N';
                  lc_error_debug := '';
               UPDATE xx_ap_confirmed_payment_batch
               SET   rtv                   = 'N'
                    ,last_update_date      = SYSDATE
                    ,last_updated_by       = FND_PROFILE.VALUE ('USER_ID')
                    ,last_update_login     = FND_PROFILE.VALUE ('USER_ID')
                    ,request_id            = ln_conc_request_id
               WHERE  rtv                  IS NULL
               AND org_id                   = FND_PROFILE.VALUE ('ORG_ID');
            EXCEPTION
               WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in '||lc_error_loc || ' - '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in '||lc_error_debug);
                  x_ret_code := 2;
            END;
            BEGIN
               FOR lcu_chargeback_APDM IN c_chargeback_APDM
               LOOP
                  lc_error_loc        := 'Setting the Printer for ChargeBack APDM Report';
                  lc_error_debug      := 'Setting the Printer for the Payment Batch : '||lcu_chargeback_APDM.checkrun_name;
                  lb_print_option     := fnd_request.set_print_options(
                                                                       printer   => 'XPTR'
                                                                      ,copies    => 1
                                                                      );
                  lc_error_loc        := 'Submitting the ChargeBack APDM Report';
                  lc_error_debug      := 'Submitting the ChargeBack APDM Report for the Payment Batch : '||lcu_chargeback_APDM.checkrun_name||' and Payment Batch ID : '||lcu_chargeback_APDM.checkrun_id;
                  ln_conc_request_id  := fnd_request.submit_request   (
                                                                      'xxfin'
                                                                     ,'XXAPCHBKAPDM'
                                                                     ,NULL
                                                                     ,NULL
                                                                     ,TRUE
                                                                     ,lcu_chargeback_APDM.checkrun_id
                                                                      );
               COMMIT;
                  lc_error_loc        := 'Updating the custom table to F';
                  lc_error_debug      := 'Updating the custom table for the Payment Batch : '||lcu_chargeback_APDM.checkrun_name;
               --***********************************************************
               -- Updating Chargeback to 'F' to indicate Formatting status
               --***********************************************************
               UPDATE xx_ap_confirmed_payment_batch
               SET --chargeback               = 'Y'                                                       --Commented for CR 542 Defect 3327
                     chargeback               = 'F'                                                       --Added for CR 542 Defect 3327
                    ,last_update_date         = SYSDATE
                    ,last_updated_by          = FND_PROFILE.VALUE ('USER_ID')
                    ,last_update_login        = FND_PROFILE.VALUE ('USER_ID')
                    ,checkrun_id              = lcu_chargeback_APDM.checkrun_id
                    ,chb_request_id           = ln_conc_request_id
               WHERE payment_batch            = lcu_chargeback_APDM.checkrun_name
               AND org_id                     = FND_PROFILE.VALUE ('ORG_ID');
               COMMIT;
               END LOOP;
                  lc_error_loc   := 'Updating the custom table chargeback = N';
                  lc_error_debug := '';
               UPDATE xx_ap_confirmed_payment_batch
               SET   chargeback               = 'N'
                    ,last_update_date         = SYSDATE
                    ,last_updated_by          = FND_PROFILE.VALUE ('USER_ID')
                    ,last_update_login        = FND_PROFILE.VALUE ('USER_ID')
                    ,chb_request_id           = ln_conc_request_id
               WHERE  chargeback                IS NULL
               AND    org_id                  = FND_PROFILE.VALUE ('ORG_ID');
            EXCEPTION
               WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in '||lc_error_loc || ' - '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in '||lc_error_debug);
                  x_ret_code := 2;
            END;
            IF ln_conc_request_id  <>  0   THEN
                  FND_CONC_GLOBAL.SET_REQ_GLOBALS( conc_status  => 'PAUSED'
                                                  ,request_data => 'Restarting'
                                                 );
            END IF;
       --*****************************************************************
       --            Code added for CR 542 Defect #3327 starts
       --*****************************************************************
       ELSIF lc_req_data = 'Restarting' THEN
       --********************************************************************************************************
       --   Calling the AP_TDM_FORMAT Procedure to submit the "OD: AP Format APDM Report for TDM" for Formatting
       -- *******************************************************************************************************
               AP_TDM_FORMAT  (x_ret_code
                               );
                    IF x_ret_code = 0 THEN
                        FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status  => 'PAUSED'
                                                       ,request_data => 'Completed'
                                                       );
                    END IF;
       --*****************************************************************
       --            Code added for CR 542 Defect #3327 ends
       --*****************************************************************
       END IF;
  END SUBMIT_APDM_REPORTS;
-- The below procedure is added for CR 542
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : OD: AP Format APDM Report for TDM                                   |
-- | Description :  To Format the RTV And Chargeback for TDM file Format               |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |1.0       06-Jul-10    Priyanka Nagesh      Initial Version - R1.4                 |
-- |                                            CR 542  Defect# 3327                   |
-- +===================================================================================+
  PROCEDURE AP_TDM_FORMAT  (x_ret_code           OUT NUMBER
                             )
    AS
        CURSOR lcu_rtv_tdm_format
        IS
          SELECT  request_id
                 ,payment_batch
                 ,checkrun_id
          FROM    apps.xx_ap_confirmed_payment_batch     XACPB
          WHERE   XACPB.RTV            = 'F';
        CURSOR  lcu_chb_tdm_format
        IS
          SELECT  chb_request_id
                 ,payment_batch
                 ,checkrun_id
          FROM    apps.xx_ap_confirmed_payment_batch     XACPB
          WHERE   XACPB.Chargeback     = 'F';
       --**********************
       ----- Parameters--------
       --**********************
        ln_conc_request_id                   NUMBER          := 0;
        lb_print_option                      BOOLEAN;
        lc_error_loc                         VARCHAR2(4000)  := NULL;
        lc_error_debug                       VARCHAR2(4000)  := NULL;
        ln_rtv_app_char                      NUMBER;
        ln_chb_app_char                      NUMBER;
        BEGIN
             BEGIN
                 SELECT  XFTV.target_value5
                 INTO    ln_rtv_app_char
                 FROM    apps.xx_fin_translatedefinition XFTD
                        ,apps.xx_fin_translatevalues XFTV
                 WHERE  XFTD.translate_id                     = XFTV.translate_id
                 AND    XFTD.translation_name                 = 'APDM_ADDRESS_DTLS'
                 AND    UPPER(SUBSTR(XFTV.source_value1,1,3)) = 'RTV'
                 AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                 AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                 AND    XFTV.enabled_flag                     = 'Y'
                 AND    XFTD.enabled_flag                     = 'Y';
                 FOR lcr_RTV_TDM_Format IN lcu_rtv_tdm_format
                 LOOP
                     lc_error_loc   := 'Submiting the OD: AP Format APDM Report for TDM - for RTV to TDM';
                     lc_error_debug := 'Submiting the OD: AP Format APDM Report for TDM - for RTV to TDM for the Payment Batch : '||lcr_RTV_TDM_Format.payment_batch||' and Payment Batch ID : '||lcr_RTV_TDM_Format.checkrun_id;
                     ln_conc_request_id := fnd_request.submit_request(
                                                                    'xxfin'
                                                                   ,'XXAPFORMATAPDM'
                                                                   ,NULL
                                                                   ,NULL
                                                                   ,TRUE
                                                                   ,'RTV'
                                                                   ,ln_rtv_app_char
                                                                   ,lcr_RTV_TDM_Format.request_id
                                                                   );
                 COMMIT;
                     lc_error_loc   := 'Updating the custom table ';
                     lc_error_debug := 'Updating the custom table to Y for the Payment Batch: '||lcr_RTV_TDM_Format.payment_batch;
                 UPDATE xx_ap_confirmed_payment_batch
                 SET   RTV                   = 'Y'
                 WHERE payment_batch         = lcr_RTV_TDM_Format.payment_batch
                 AND   org_id                =  FND_PROFILE.VALUE ('ORG_ID');
                 COMMIT;
                 END LOOP;
              EXCEPTION
                 WHEN OTHERS THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in '||lc_error_loc || ' - '||SQLERRM);
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in '||lc_error_debug);
                     x_ret_code := 2;
              END;
              BEGIN
               --*******************************************************************************
               -- Selecting the number of characters to be appended to have fixed width contents
               --*******************************************************************************
                 SELECT  XFTV.target_value5
                 INTO    ln_chb_app_char
                 FROM    APPS.xx_fin_translatedefinition XFTD
                        ,APPS.xx_fin_translatevalues XFTV
                 WHERE  XFTD.translate_id                     = XFTV.translate_id
                 AND    XFTD.translation_name                 = 'APDM_ADDRESS_DTLS'
                 AND    UPPER(SUBSTR(XFTV.source_value1,1,3)) = 'CHA'
                 AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                 AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                 AND    XFTV.enabled_flag                     = 'Y'
                 AND    XFTD.enabled_flag                     = 'Y';
                 FOR lcr_chb_tdm_Format IN lcu_chb_tdm_format
                 LOOP
                     lc_error_loc   := 'Submiting the OD: AP Format APDM Report for TDM - for CHARGEBACK to TDM';
                     lc_error_debug := 'Submiting the OD: AP Format APDM Report for TDM - for CHARGEBACK to TDM for the Payment Batch : '||lcr_CHB_TDM_Format.payment_batch||' and Payment Batch ID : '||lcr_CHB_TDM_Format.checkrun_id;
                     ln_conc_request_id := fnd_request.submit_request(
                                                                     'xxfin'
                                                                    ,'XXAPFORMATAPDM'
                                                                    ,NULL
                                                                    ,NULL
                                                                    ,TRUE
                                                                    ,'CHARGEBACK'
                                                                    ,ln_chb_app_char
                                                                    ,lcr_CHB_TDM_Format.chb_request_id
                                                                     );
                 COMMIT;
                     lc_error_loc   := 'Updating the custom table ';
                     lc_error_debug := 'Updating the custom table  to Y for the Payment Batch: '||lcr_CHB_TDM_Format.payment_batch;
                 UPDATE xx_ap_confirmed_payment_batch
                 SET   CHARGEBACK           = 'Y'
                 WHERE payment_batch        = lcr_CHB_TDM_Format.payment_batch
                 AND org_id                 = FND_PROFILE.VALUE ('ORG_ID');
                 COMMIT;
                 END LOOP;
              EXCEPTION
                 WHEN OTHERS THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in '||lc_error_loc || ' - '||SQLERRM);
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in '||lc_error_debug);
                     x_ret_code := 2;
              END;
  END AP_TDM_FORMAT;
END XX_AP_PAYMENT_BATCH_PKG;
/

SHOW ERROR

