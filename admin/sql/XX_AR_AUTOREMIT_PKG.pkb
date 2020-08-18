create or replace PACKAGE BODY XX_AR_AUTOREMIT_PKG
AS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |                       WIPRO Technologies                                                |
-- +=========================================================================================+
-- | Name :      AR AutoRemittance                                                           |
-- | Description : To run the batches of AutoRemittance in parallel                          |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version   Date          Author              Remarks                                      |
-- |=======   ==========   =============        =============================================|
-- |1.0       18-APR-2008  Anitha Devarajulu,   Initial version                              |
-- |                       Wipro Technologies                                                |
-- |1.1       21-APR-2008  Sambasiva Reddy D    Adding Debug parameters and Batching         |
-- |1.2       02-MAY-2008  Aravind A.           Defect 6645                                  |
-- |1.3       15-MAY-2008  Sambasiva Reddy D    Defect 7021                                  |
-- |1.4       26-MAY-2008  Hemalatha S.         Defect 7376                                  |
-- |1.5       21-JUL-2008  Sambasiva Reddy D    Defect 9064                                  |
-- |1.6       21-AUG-2008  Gowri Shankar        Performance Recommendation                   |
-- |1.7       18-AUG-2008  Hari Mukkoti         Defect 9852                                  |
-- |1.8       16-NOV-2009  Anitha Devarajulu    Defect 3358                                  |
-- |1.9       13-APR-2010  Venkatesh B          Defect 3358                                  |
-- |2.0       09-JUL-2010  Lincy K              Modified the condition in c_err_receipts     |
-- |                                            cursor for CORRECT_ERR_RCPT procedure to     |
-- |                                            submit Auto remittance for specific method   |
-- |                                            - Defect 6794                                |
-- |2.1       14-JUL-2010  Lincy K              Defect 6794 - Added receipt_date  and        |
-- |                                            receipt_number (low/high) as                 |
-- |                                            parameter for CORRECT_ERR_RCPT procedure     |
-- |2.2       28-JUL-2012  Abdul Khan           Defect 17474 - Confirmed receipts because of |
-- |                                            data missing in ORDT. Created a new Procedure|
-- |                                            INSERT_DATA_ORDT to insert data in ORDT      |
-- |2.3       19-OCT-2012  Abdul Khan           Defect 20860 - Added logic to print Error    |
-- |                                            Message in output for Confirmed receipts.    |
-- |2.4       25-Sep-2013  Satyajeet M          Defect 25569 - Fixed issue for bank acount.  |
-- |                                            Ref DEF25569                                 |
-- |2.5       10-OCT-2013  Edson Morales        Added code to run submit offline transaction |
-- |2.6       30-DEC-2013  Edson Morales        Passing batch_count to submit offline        |
-- |                                            Transaction                                  |
-- |2.7       18-MAR-2014  Edson Morales        Fixed GL Date format issue wihtn error correction
-- |                                            program. Defect 29045                        |
-- |2.8       04-APR-2014  Arun Gannarapu       Made changes to remove comment for Submit offline
-- |                                            transactions job Defect 29355
-- |3.0       16-MAY-2014  Arun Gannarapu       Updated per Defect 30015                     |
-- |3.1       30-OCT-2015  Vasu Raparla         Removed Schema References for R12.2          |
-- |3.2       12-AUG-2020  Divyansh Saini       Code changes done for NAIT-129669            |
-- +=========================================================================================+
    gc_rpad_len  NUMBER DEFAULT 20;   -- Added for QC Defect # 20860

    PROCEDURE submit_offline_transaction(
        p_batch_count  IN      NUMBER,
        x_request_id   OUT     NUMBER)
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        le_process_exception  EXCEPTION;
    BEGIN
        x_request_id :=
            fnd_request.submit_request(application =>      'IBY',
                                       program =>          'IBY_FC_SUBMIT_OFFLINE_TRXNS',
                                       description =>      NULL,
                                       start_time =>       NULL,
                                       sub_request =>      TRUE,
                                       --   argument1        => 'IBY_FC_SUBMIT_OFFLINE_TRXNS',
                                       argument1 =>        'CREDITCARD',
                                       argument2 =>        NVL(p_batch_count,
                                                               1) );
        fnd_file.put_line(fnd_file.LOG,
                             'Submit Offline Transaction concurrent request id: '
                          || x_request_id);
        COMMIT;

        IF x_request_id = 0
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Error'
                              || fnd_message.get);
        END IF;
    END submit_offline_transaction;

    PROCEDURE get_translation_value(
        p_translation_name  IN      xx_fin_translatedefinition.translation_name%TYPE,
        p_source_value      IN      xx_fin_translatevalues.source_value1%TYPE,
        x_target_value      OUT     xx_fin_translatevalues.target_value1%TYPE)
    IS
    BEGIN
        SELECT xftv.target_value1
        INTO   x_target_value
        FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
        WHERE  xftd.translate_id = xftv.translate_id
        AND    xftd.translation_name = p_translation_name
        AND    xftv.source_value1 = p_source_value
        AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    xftv.enabled_flag = 'Y'
        AND    xftd.enabled_flag = 'Y';
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            x_target_value := NULL;
    END get_translation_value;

    PROCEDURE get_run_counts(
        p_request_id      IN      NUMBER,
        x_records_passed  OUT     NUMBER,
        x_records_failed  OUT     NUMBER)
    IS
    BEGIN
        SELECT SUM(DECODE(cc_error_flag,
                          NULL, 0,
                          1) ) fails,
               SUM(DECODE(cc_error_flag,
                          NULL, 1,
                          0) ) passes
        INTO   x_records_failed,
               x_records_passed
        FROM   fnd_concurrent_requests fcr, ar_cash_receipts_all acr
        WHERE  fcr.parent_request_id = p_request_id
        AND    fcr.status_code = 'C'
        AND    fcr.phase_code = 'C'
        AND    acr.request_id = fcr.request_id;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            x_records_failed := 0;
            x_records_passed := 0;
    END get_run_counts;

    PROCEDURE get_run_status(
        p_request_id  IN      NUMBER,
        x_ret_code    OUT     NUMBER,
        x_error_buff  OUT     VARCHAR2)
    IS
        ln_records_passed    NUMBER;
        ln_records_failed    NUMBER;
        lc_min_num_records   xx_fin_translatevalues.target_value1%TYPE;
        lc_min_pass_percent  xx_fin_translatevalues.target_value1%TYPE;
        ln_min_num_records   NUMBER;
        ln_min_pass_percent  NUMBER;
    BEGIN
        -- Get number of records that passed and/or failed in this run
        get_run_counts(p_request_id =>          p_request_id,
                       x_records_passed =>      ln_records_passed,
                       x_records_failed =>      ln_records_failed);
        -- Get number of minimum records that need to be processed to determine if minimum pass percentage criteria will be used.
        get_translation_value(p_translation_name =>      'AR_AUTOREMIT_CONFIG',
                              p_source_value =>          'MIN_NUM_RECORDS',
                              x_target_value =>          lc_min_num_records);
        -- Get minimum allowable record passed percentage.
        get_translation_value(p_translation_name =>      'AR_AUTOREMIT_CONFIG',
                              p_source_value =>          'MIN_NUM_PASS_PERCENT',
                              x_target_value =>          lc_min_pass_percent);

        -- Cast from VARCHAR to Number
        IF (lc_min_num_records IS NULL)
        THEN
            ln_min_num_records := 1;
        ELSE
            ln_min_num_records := TO_NUMBER(lc_min_num_records);
        END IF;

        IF (lc_min_pass_percent IS NULL)
        THEN
            ln_min_pass_percent := 0;
        ELSE
            ln_min_pass_percent := TO_NUMBER(lc_min_pass_percent);
        END IF;

        x_error_buff :=    'Total records processed '
                        || (  ln_records_passed
                            + ln_records_failed);

        IF ( (  ln_records_passed
              + ln_records_failed) >= ln_min_num_records)
        THEN
            IF     ln_records_passed = 0
               AND ln_records_failed = 0   -- Beware of division by zero
            THEN
                x_ret_code := 0;
            ELSIF(  ln_records_passed
                  / (  ln_records_passed
                     + ln_records_failed) < ln_min_pass_percent)
            THEN
                x_ret_code := 2;
                x_error_buff :=    'Failed to meet minimum pass percentage '
                                || ln_min_pass_percent
                                || '%'
                                || '.';
            ELSIF ln_records_failed >= 1
            THEN
                x_ret_code := 1;
                x_error_buff :=    'Number of records failed: '
                                || ln_records_failed;
            ELSE
                x_ret_code := 0;
            END IF;
        ELSE
            IF ln_records_failed >= 1
            THEN
                x_ret_code := 1;
                x_error_buff :=    'Number of records failed: '
                                || ln_records_failed;
            ELSE
                x_ret_code := 0;
            END IF;
        END IF;
    END get_run_status;

    --Procedure for Displaying Error Records in Text File.Defect 9852
    PROCEDURE DISPLAY_ERROR(
        p_debug_file  IN      VARCHAR2,
        p_debug       IN      VARCHAR2,
        p_ret_code    OUT     NUMBER)
    IS
        --Local Variable
        ln_parent_request_id  ar_cash_receipts_all.request_id%TYPE      := NULL;
        ln_request_id         ar_cash_receipts_all.request_id%TYPE      := NULL;
        ln_error_cnt          NUMBER                                    := NULL;
        lc_error_text         ar_cash_receipts_all.cc_error_text%TYPE   := NULL;
        lc_cc_error_code      ar_cash_receipts_all.cc_error_code%TYPE   := NULL;
        lc_completion_status  VARCHAR2(200);
        lc_errored_receipts   VARCHAR2(1)                               := 'N';
        lc_errored_autoremit  VARCHAR2(1)                               := 'N';

        CURSOR c_err_receipts(
            p_request_id  IN  NUMBER)
        IS
            SELECT   COUNT(acr.cash_receipt_id) cc_error_cnt,
                     acr.request_id,
                        acr.cc_error_code
                     || ' '
                     || acr.cc_error_text error_msg
            FROM     fnd_concurrent_requests fcr, ar_cash_receipts_all acr
            WHERE    fcr.parent_request_id = p_request_id
            AND      fcr.status_code = 'C'
            AND      fcr.phase_code = 'C'
            AND      acr.request_id = fcr.request_id
            AND      acr.cc_error_flag IS NOT NULL
            GROUP BY acr.request_id,    acr.cc_error_code
                                     || ' '
                                     || acr.cc_error_text;

        CURSOR c_err_autoremittance(
            p_request_id  IN  NUMBER)
        IS
            SELECT fcr.request_id,
                   fcr.status_code
            FROM   fnd_concurrent_requests fcr
            WHERE  fcr.parent_request_id = p_request_id
            AND    fcr.phase_code = 'C'
            AND    (   fcr.status_code = 'E'
                    OR fcr.status_code = 'G');
    BEGIN
        --Assign Conc Request ID
        ln_parent_request_id := fnd_global.conc_request_id;
        fnd_file.put_line(fnd_file.output,
                          '********************************Error Records*********************************');
        fnd_file.put_line(fnd_file.output,
                          '');
        fnd_file.put_line(fnd_file.output,
                             RPAD('Request Id',
                                  20,
                                  ' ')
                          || RPAD('Errored Records Count',
                                  28,
                                  ' ')
                          || 'Error Description');
        fnd_file.put_line(fnd_file.output,
                             RPAD('==========',
                                  20,
                                  ' ')
                          || RPAD('=====================',
                                  28,
                                  ' ')
                          || '=================');

        IF (p_debug = 'Y')
        THEN
            display_log(p_debug_file,
                        '********************************Error Records*********************************');
            display_log(p_debug_file,
                        '');
            display_log(p_debug_file,
                           RPAD('==========',
                                20,
                                ' ')
                        || RPAD('=====================',
                                28,
                                ' ')
                        || '=================');
        END IF;

        --Opening The Cursor, to get the failure receipts
        FOR lcu_err_receipts IN c_err_receipts(ln_parent_request_id)
        LOOP
            p_ret_code := 1;
            lc_errored_receipts := 'Y';
            fnd_file.put_line(fnd_file.output,
                                 RPAD(lcu_err_receipts.request_id,
                                      20,
                                      ' ')
                              || RPAD(lcu_err_receipts.cc_error_cnt,
                                      28,
                                      ' ')
                              || lcu_err_receipts.error_msg);

            IF (p_debug = 'Y')
            THEN
                display_log(p_debug_file,
                               RPAD(lcu_err_receipts.request_id,
                                    20,
                                    ' ')
                            || RPAD(lcu_err_receipts.cc_error_cnt,
                                    28,
                                    ' ')
                            || lcu_err_receipts.error_msg);
            END IF;
        END LOOP;

        IF (lc_errored_receipts = 'N')
        THEN
            fnd_file.put_line(fnd_file.output,
                              '');
            fnd_file.put_line(fnd_file.output,
                              '     ***************************No data Found****************************     ');
        END IF;

        fnd_file.put_line(fnd_file.output,
                          '');
        fnd_file.put_line(fnd_file.output,
                          '********************************Error Records*********************************');

        IF (p_debug = 'Y')
        THEN
            display_log(p_debug_file,
                        '');
            display_log(p_debug_file,
                        '********************************Error Records*********************************');
        END IF;

        fnd_file.put_line(fnd_file.output,
                          '');
        fnd_file.put_line(fnd_file.output,
                          '');
        fnd_file.put_line(fnd_file.output,
                          '*********************Requests Completed in Error or Warning**********************');
        fnd_file.put_line(fnd_file.output,
                          '');
        fnd_file.put_line(fnd_file.output,
                             RPAD('Request Id',
                                  20,
                                  ' ')
                          || 'Status');
        fnd_file.put_line(fnd_file.output,
                             RPAD('==========',
                                  20,
                                  ' ')
                          || '======');

        IF (p_debug = 'Y')
        THEN
            display_log(p_debug_file,
                        '');
            display_log(p_debug_file,
                        '');
            display_log(p_debug_file,
                        '*********************Requests Completed in Error or Warning**********************');
            display_log(p_debug_file,
                        '');
            display_log(p_debug_file,
                           RPAD('Request Id',
                                20,
                                ' ')
                        || 'Status');
            display_log(p_debug_file,
                           RPAD('==========',
                                20,
                                ' ')
                        || '======');
        END IF;

        --Opening The Cursor, to get the Errored out or Warning Requests
        FOR lcu_err_autoremittance IN c_err_autoremittance(ln_parent_request_id)
        LOOP
            lc_errored_autoremit := 'Y';

            IF (lcu_err_autoremittance.status_code = 'E')
            THEN
                lc_completion_status := 'Error';
                p_ret_code := 2;
            ELSIF(lcu_err_autoremittance.status_code = 'G')
            THEN
                lc_completion_status := 'Warning';

                IF (    (p_ret_code IS NULL)
                    OR (p_ret_code <> 2) )
                THEN
                    p_ret_code := 1;
                END IF;
            END IF;

            fnd_file.put_line(fnd_file.output,
                                 RPAD(lcu_err_autoremittance.request_id,
                                      20,
                                      ' ')
                              || lc_completion_status);

            IF (p_debug = 'Y')
            THEN
                display_log(p_debug_file,
                               RPAD(lcu_err_autoremittance.request_id,
                                    20,
                                    ' ')
                            || lc_completion_status);
            END IF;
        END LOOP;

        IF (lc_errored_autoremit = 'N')
        THEN
            fnd_file.put_line(fnd_file.output,
                              '');
            fnd_file.put_line(fnd_file.output,
                              '     ****************************No data Found******************************    ');
        END IF;

        fnd_file.put_line(fnd_file.output,
                          '');
        fnd_file.put_line(fnd_file.output,
                          '*********************Requests Completed in Error or Warning**********************');
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.output,
                                 'Error Code :'
                              || SQLERRM);
    END DISPLAY_ERROR;

    FUNCTION repeat_char(
        p_char  IN  VARCHAR2,
        p_num   IN  NUMBER)
        RETURN VARCHAR2
    AS
        lc_ret_var  VARCHAR2(1000) DEFAULT NULL;
    BEGIN
        FOR i IN 1 .. p_num
        LOOP
            lc_ret_var :=    lc_ret_var
                          || p_char;
        END LOOP;

        RETURN lc_ret_var;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              'Error in REPEAT_CHAR procedure.');
            fnd_file.put_line(fnd_file.LOG,
                                 'Error is '
                              || SQLERRM
                              || ' and error code is '
                              || SQLCODE);
            RETURN NULL;
    END repeat_char;

    PROCEDURE scheduler(
        x_error_buff                 OUT     VARCHAR2,
        x_ret_code                   OUT     NUMBER,
        p_process_type               IN      VARCHAR2,
        p_batch_date                 IN      VARCHAR2,
        p_batch_gl_date              IN      VARCHAR2,
        p_create_flag                IN      VARCHAR2,
        p_approve_flag               IN      VARCHAR2,
        p_format_flag                IN      VARCHAR2,
        p_batch_id                   IN      VARCHAR2,
        p_debug_flag                 IN      VARCHAR2,
        p_batch_currency             IN      VARCHAR2,
        p_exchange_date              IN      VARCHAR2,
        p_exchange_rate              IN      VARCHAR2,
        p_exchange_type              IN      VARCHAR2,
        p_remit_method_code          IN      VARCHAR2,
        p_receipt_class_id           IN      VARCHAR2,
        p_receipt_payment_method_id  IN      VARCHAR2,
        p_media_ref                  IN      VARCHAR2,
        p_remit_bank_branch_id       IN      VARCHAR2,
        p_remit_bank_account_id      IN      VARCHAR2,
        p_remit_deposit_number       IN      VARCHAR2,
        p_comments                   IN      VARCHAR2,
        p_receipt_date_low           IN      VARCHAR2,
        p_receipt_date_high          IN      VARCHAR2,
        p_maturity_date_low          IN      VARCHAR2,
        p_maturity_date_high         IN      VARCHAR2,
        p_receipt_num_low            IN      VARCHAR2,
        p_receipt_num_high           IN      VARCHAR2,
        p_doc_num_low                IN      VARCHAR2,
        p_doc_num_high               IN      VARCHAR2,
        p_cust_num_low               IN      VARCHAR2,
        p_cust_num_high              IN      VARCHAR2,
        p_cust_name_low              IN      VARCHAR2,
        p_cust_name_high             IN      VARCHAR2,
        p_cust_id                    IN      VARCHAR2,
        p_site_low                   IN      VARCHAR2,
        p_site_high                  IN      VARCHAR2,
        p_site_id                    IN      VARCHAR2,
        p_min_amount                 IN      VARCHAR2,
        p_max_amount                 IN      VARCHAR2,
        p_bill_num_low               IN      VARCHAR2,
        p_bill_num_high              IN      VARCHAR2,
        p_bank_act_num_low           IN      VARCHAR2,
        p_bank_act_num_high          IN      VARCHAR2,
        p_batch_type                 IN      VARCHAR2   -- Added for defect 7376
                                                     ,
        p_batch_count                IN      NUMBER   -- Added for defect 7376
                                                   ,
        p_auto_remit_submit          IN      VARCHAR2,
        p_debug                      IN      VARCHAR2,
        p_debug_file                 IN      VARCHAR2)
    AS
        ln_conc_request_id         NUMBER;
        ln_lower                   NUMBER;
        ln_upper                   NUMBER;
        ln_batch_number            NUMBER                                 := 0;
        lc_last_receipt_num        ar_cash_receipts.receipt_number%TYPE;
        lc_first_receipt_num       ar_cash_receipts.receipt_number%TYPE;
        lc_req_data                VARCHAR2(100)                          := NULL;
        ln_total_count             NUMBER                                 := 0;
        ln_batch_size              NUMBER                                 := 0;
        ld_receipt_date_low        DATE;
        ld_receipt_date_high       DATE;
        ld_receipt_date_low1       VARCHAR2(20);
        ld_receipt_date_high1      VARCHAR2(20);
        ln_receipt_index           NUMBER;
        ln_ret_err_code            NUMBER                                 := 0;
        -- Added by Divyansh
        ln_trxn_id                 NUMBER;
        x_transaction_id_out    iby_trxn_summaries_all.TransactionID%TYPE;
        x_transaction_mid_out   iby_trxn_summaries_all.trxnmid%TYPE;
        p_ret_status            VARCHAR2(2000);
        p_ret_error             VARCHAR2(2000);

        TYPE data_buffer_typ IS TABLE OF ar_cash_receipts.receipt_number%TYPE
            INDEX BY PLS_INTEGER;

        lt_data_buffer_recpt_low   data_buffer_typ;
        lt_data_buffer_recpt_high  data_buffer_typ;
        t_receipt_num              data_buffer_typ;
        ln_num_recpt_rows          BINARY_INTEGER                         := 0;

        CURSOR c_count_receipts
        IS
            SELECT   /*+ ordered index(crh AR_CASH_RECEIPT_HISTORY_N6) use_nl(crh cr rm rclass) */
                     cr.receipt_number
            FROM     ar_cash_receipt_history crh,
                     ar_cash_receipts cr,
                     ar_receipt_methods rm,
                     ar_receipt_classes rclass,
                     ce_bank_acct_uses_ou remit_bank
            WHERE    crh.cash_receipt_id = cr.cash_receipt_id
            AND      rm.receipt_method_id = cr.receipt_method_id
            AND      rclass.receipt_class_id = rm.receipt_class_id
            AND      rm.receipt_method_id = NVL(p_receipt_payment_method_id,
                                                rm.receipt_method_id)
            AND      rclass.receipt_class_id = NVL(p_receipt_class_id,
                                                   rclass.receipt_class_id)
            AND      cr.remit_bank_acct_use_id = remit_bank.bank_acct_use_id
            AND      remit_bank.bank_account_id = p_remit_bank_account_id
            AND      cr.selected_remittance_batch_id IS NULL
            AND      cr.cc_error_flag IS NULL
            AND      cr.currency_code = p_batch_currency
            AND      crh.status = 'CONFIRMED'
            AND      crh.current_record_flag = 'Y'
            AND      rclass.remit_method_code = 'STANDARD'
            AND      cr.receipt_date BETWEEN NVL(ld_receipt_date_low,
                                                 cr.receipt_date)
                                         AND NVL(ld_receipt_date_high,
                                                 cr.receipt_date)
            AND      rm.payment_type_code = 'CREDIT_CARD'
            AND      cr.receipt_number BETWEEN NVL(p_receipt_num_low,
                                                   cr.receipt_number)
                                           AND NVL(p_receipt_num_high,
                                                   cr.receipt_number)
            ORDER BY cr.receipt_number ASC;
			
        -- Added cursor for NAIT-129669
		CURSOR c_count_rim_receipts
        IS
            SELECT   /*+ ordered index(crh AR_CASH_RECEIPT_HISTORY_N6) use_nl(crh cr rm rclass) */
                     cr.receipt_number
            FROM     ar_cash_receipt_history crh,
                     ar_cash_receipts cr,
                     ar_receipt_methods rm,
                     ar_receipt_classes rclass,
                     ce_bank_acct_uses_ou remit_bank
            WHERE    crh.cash_receipt_id = cr.cash_receipt_id
            AND      rm.receipt_method_id = cr.receipt_method_id
            AND      rclass.receipt_class_id = rm.receipt_class_id
            AND      rm.receipt_method_id = NVL(p_receipt_payment_method_id,
                                                rm.receipt_method_id)
            AND      rclass.name = 'US_CC IRECEIVABLES_OD'
            AND      cr.remit_bank_acct_use_id = remit_bank.bank_acct_use_id
            AND      remit_bank.bank_account_id = p_remit_bank_account_id
            AND      cr.selected_remittance_batch_id IS NULL
            AND      cr.cc_error_flag IS NULL
            AND      cr.currency_code = p_batch_currency
            AND      crh.status = 'REMITTED'
            AND      crh.current_record_flag = 'Y'
            AND      rclass.remit_method_code = 'STANDARD'
            AND      cr.receipt_date BETWEEN NVL(ld_receipt_date_low,
                                                 cr.receipt_date)
                                         AND NVL(ld_receipt_date_high,
                                                 cr.receipt_date)
            AND      rm.payment_type_code = 'CREDIT_CARD'
            AND      cr.receipt_number BETWEEN NVL(p_receipt_num_low,
                                                   cr.receipt_number)
                                           AND NVL(p_receipt_num_high,
                                                   cr.receipt_number)
            ORDER BY cr.receipt_number ASC;
			
    BEGIN
        fnd_file.put_line(fnd_file.LOG,
                          '*****Parameters******');
        fnd_file.put_line(fnd_file.LOG,
                          '');
        fnd_file.put_line(fnd_file.LOG,
                             'p_batch_currency: '
                          || p_batch_currency);
        fnd_file.put_line(fnd_file.LOG,
                             'p_receipt_payment_method_id: '
                          || p_receipt_payment_method_id);
        fnd_file.put_line(fnd_file.LOG,
                             'p_remit_bank_account_id: '
                          || p_remit_bank_account_id);
        fnd_file.put_line(fnd_file.LOG,
                             'p_remit_method_code: '
                          || p_remit_method_code);
        fnd_file.put_line(fnd_file.LOG,
                             'p_receipt_class_id: '
                          || p_receipt_class_id);
        fnd_file.put_line(fnd_file.LOG,
                             'p_receipt_date_low: '
                          || p_receipt_date_low);
        fnd_file.put_line(fnd_file.LOG,
                             'p_receipt_date_high: '
                          || p_receipt_date_high);
        fnd_file.put_line(fnd_file.LOG,
                             'p_receipt_num_low: '
                          || p_receipt_num_low);
        fnd_file.put_line(fnd_file.LOG,
                             'p_receipt_num_high: '
                          || p_receipt_num_high);
        fnd_file.put_line(fnd_file.LOG,
                             'p_batch_type: '
                          || p_batch_type);
        fnd_file.put_line(fnd_file.LOG,
                             'p_batch_count: '
                          || p_batch_count);
        fnd_file.put_line(fnd_file.LOG,
                             'p_auto_remit_submit: '
                          || p_auto_remit_submit);
        fnd_file.put_line(fnd_file.LOG,
                             'p_debug: '
                          || p_debug);
        fnd_file.put_line(fnd_file.LOG,
                             'p_debug_file: '
                          || p_debug_file);
        fnd_file.put_line(fnd_file.LOG,
                          '');
        fnd_file.put_line(fnd_file.LOG,
                             'request_data : '
                          || fnd_conc_global.request_data);
        fnd_file.put_line(fnd_file.LOG,
                          '*****Parameters******');
        fnd_file.put_line(fnd_file.LOG,
                          '');

        IF (p_debug = 'Y')
        THEN
            display_log(p_debug_file,
                        '*****Parameters******');
            display_log(p_debug_file,
                        '');
            display_log(p_debug_file,
                           'p_batch_currency:            '
                        || p_batch_currency);
            display_log(p_debug_file,
                           'p_receipt_payment_method_id: '
                        || p_receipt_payment_method_id);
            display_log(p_debug_file,
                           'p_remit_bank_account_id:     '
                        || p_remit_bank_account_id);
            display_log(p_debug_file,
                           'p_remit_method_code:         '
                        || p_remit_method_code);
            display_log(p_debug_file,
                           'p_receipt_class_id:          '
                        || p_receipt_class_id);
            display_log(p_debug_file,
                           'p_receipt_date_low:          '
                        || p_receipt_date_low);
            display_log(p_debug_file,
                           'p_receipt_date_high:         '
                        || p_receipt_date_high);
            display_log(p_debug_file,
                           'p_receipt_num_low:           '
                        || p_receipt_num_low);
            display_log(p_debug_file,
                           'p_receipt_num_high:          '
                        || p_receipt_num_high);
            display_log(p_debug_file,
                           'p_batch_type:                '
                        || p_batch_type);
            display_log(p_debug_file,
                           'p_batch_count:               '
                        || p_batch_count);
            display_log(p_debug_file,
                           'p_auto_remit_submit:         '
                        || p_auto_remit_submit);
            display_log(p_debug_file,
                           'p_debug:                     '
                        || p_debug);
            display_log(p_debug_file,
                           'p_debug_file:                '
                        || p_debug_file);
            display_log(p_debug_file,
                        '');
            display_log(p_debug_file,
                        '*****Parameters******');
            display_log(p_debug_file,
                        '');
        END IF;

        IF (p_auto_remit_submit = 'Y')
        THEN
            lc_req_data := fnd_conc_global.request_data;

            IF (lc_req_data = 'OVER')
            THEN
                RETURN;
            END IF;
        END IF;

        IF (NVL(lc_req_data,
                'FIRST') = 'FIRST')
        THEN
            IF p_receipt_date_low IS NOT NULL
            THEN
                ld_receipt_date_low1 :=    TO_DATE(p_receipt_date_low,
                                                   'YYYY/MM/DD HH24:MI:SS')
                                        || ' 00:00:00';
                ld_receipt_date_low := TO_DATE(ld_receipt_date_low1,
                                               'DD-MON-RRRR HH24:MI:SS');
            END IF;

            IF p_receipt_date_high IS NOT NULL
            THEN
                ld_receipt_date_high1 :=    TO_DATE(p_receipt_date_high,
                                                    'YYYY/MM/DD HH24:MI:SS')
                                         || ' 23:59:59';
                ld_receipt_date_high := TO_DATE(ld_receipt_date_high1,
                                                'DD-MON-RRRR HH24:MI:SS');
            END IF;

            --Added for the PERF recommendation
            ln_receipt_index := 1;

            FOR lcu_count_receipts IN c_count_receipts
            LOOP
                t_receipt_num(ln_receipt_index) := lcu_count_receipts.receipt_number;
                ln_receipt_index :=   ln_receipt_index
                                    + 1;
            END LOOP;

            fnd_file.put_line(fnd_file.LOG,
                                 'Total Count: '
                              || t_receipt_num.COUNT);

            IF (p_batch_type = 'BATCH_COUNT')
            THEN
                ln_batch_size := CEIL(  t_receipt_num.COUNT
                                      / p_batch_count);
            ELSIF(p_batch_type = 'BATCH_SIZE')
            THEN
                ln_batch_size := p_batch_count;
            END IF;

            fnd_file.put_line(fnd_file.LOG,
                              '=====================');
            fnd_file.put_line(fnd_file.LOG,
                                 'Batch Size: '
                              || ln_batch_size);
            fnd_file.put_line(fnd_file.LOG,
                              '=====================');
            fnd_file.put_line(fnd_file.LOG,
                              '');

            IF (p_debug = 'Y')
            THEN
                display_log(p_debug_file,
                            '=====================');
                display_log(p_debug_file,
                               'Batch Size: '
                            || ln_batch_size);
                display_log(p_debug_file,
                            '=====================');
                display_log(p_debug_file,
                            '');
            END IF;

            ln_receipt_index := 0;

            IF (     (ln_batch_size > 0)
                AND (t_receipt_num.COUNT > 0) )
            THEN

                <<thread_loop>>
                LOOP
                    ln_receipt_index :=   ln_receipt_index
                                        + 1;
                    ln_batch_number :=   ln_batch_number
                                       + 1;
                    lc_first_receipt_num := t_receipt_num(ln_receipt_index);
                    ln_receipt_index :=   ln_receipt_index
                                        + ln_batch_size
                                        - 1;

                    IF (ln_receipt_index > t_receipt_num.COUNT)
                    THEN
                        ln_receipt_index := t_receipt_num.COUNT;
                    END IF;

                    lc_last_receipt_num := t_receipt_num(ln_receipt_index);
                    fnd_file.put_line(fnd_file.LOG,
                                      '-------------------------------------');
                    fnd_file.put_line(fnd_file.LOG,
                                         'Batch Number: '
                                      || ln_batch_number);
                    fnd_file.put_line(fnd_file.LOG,
                                         'First Receipt: '
                                      || lc_first_receipt_num);
                    fnd_file.put_line(fnd_file.LOG,
                                         'Last Receipt:  '
                                      || lc_last_receipt_num);

                    --Submitting the OD: AR Autoremittance Scheduler
                    IF (p_auto_remit_submit = 'Y')
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                          '===========================================================');
                        fnd_file.put_line(fnd_file.LOG,
                                             'First Receipt: '
                                          || lc_first_receipt_num);
                        fnd_file.put_line(fnd_file.LOG,
                                             'Last Receipt:  '
                                          || lc_last_receipt_num);
                        ln_conc_request_id :=
                            fnd_request.submit_request('AR',
                                                       'AUTOREMAPI',
                                                       '',
                                                       '',
                                                       --FALSE,
                                                       TRUE,
                                                       p_process_type,
                                                       p_batch_date,
                                                       p_batch_gl_date,
                                                       p_create_flag,
                                                       p_approve_flag,
                                                       p_format_flag,
                                                       p_batch_id,
                                                       p_debug_flag,
                                                       p_batch_currency,
                                                       p_exchange_date,
                                                       p_exchange_rate,
                                                       p_exchange_type,
                                                       p_remit_method_code,
                                                       p_receipt_class_id,
                                                       p_receipt_payment_method_id,
                                                       p_media_ref,
                                                       p_remit_bank_branch_id,
                                                       p_remit_bank_account_id,
                                                       p_remit_deposit_number,
                                                       p_comments,
                                                       p_receipt_date_low,
                                                       p_receipt_date_high,
                                                       p_maturity_date_low,
                                                       p_maturity_date_high,
                                                       lc_first_receipt_num,
                                                       lc_last_receipt_num,
                                                       p_doc_num_low,
                                                       p_doc_num_high,
                                                       p_cust_num_low,
                                                       p_cust_num_high,
                                                       p_cust_name_low,
                                                       p_cust_name_high,
                                                       p_cust_id,
                                                       p_site_low,
                                                       p_site_high,
                                                       p_site_id,
                                                       p_min_amount,
                                                       p_max_amount,
                                                       p_bill_num_low,
                                                       p_bill_num_high,
                                                       p_bank_act_num_low,
                                                       p_bank_act_num_high);
                        fnd_file.put_line(fnd_file.LOG,
                                             'Automatic Remittances Creation Program (SRS): '
                                          || ln_conc_request_id);   --Fixed defect 6645
                        COMMIT;
                    END IF;

                    IF ln_conc_request_id = 0
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'Error'
                                          || fnd_message.get);
                    END IF;

                    /*End*/
                    IF (ln_receipt_index >= t_receipt_num.COUNT)
                    THEN
                        EXIT thread_loop;
                    END IF;
                END LOOP;

                IF (p_auto_remit_submit = 'Y')
                THEN
                    fnd_conc_global.set_req_globals(conc_status =>       'PAUSED',
                                                    request_data =>      'SECOND');
                    COMMIT;
                    x_ret_code := 0;
                    RETURN;
                END IF;
            END IF;
        ELSIF(     (lc_req_data = 'SECOND')
              AND (p_auto_remit_submit = 'Y') )
        THEN
            -- removed the comment defect 29355

             submit_offline_transaction(p_batch_count      => 1, -- Updated per defect 30015 p_batch_count,
                                        x_request_id       => ln_conc_request_id);
            
            -- Added for NAIT-129669            
            FOR lcu_count_receipts IN c_count_rim_receipts loop
                fnd_file.put_line(fnd_file.LOG,'processing for '||lcu_count_receipts.receipt_number);
                BEGIN
                    SELECT TRANSACTIONID
                      INTO ln_trxn_id
                      FROM ar_cash_receipts_all acr,
                           iby_fndcpt_tx_operations ifto
                     WHERE acr.payment_trxn_extension_id = ifto.trxn_extension_id
                       AND acr.receipt_number = lcu_count_receipts.receipt_number;
                    
                    fnd_file.put_line(fnd_file.LOG,'processing for ln_trxn_id '||ln_trxn_id);
                    xx_eai_authorization.xx_capture(ln_trxn_id,--p_trxn_id  --    IN  NUMBER,
                                                     x_transaction_id_out,--   OUT iby_trxn_summaries_all.TransactionID%TYPE,
                                                     x_transaction_mid_out  ,--OUT iby_trxn_summaries_all.trxnmid%TYPE,
                                                     p_ret_status ,--          OUT VARCHAR2,
                                                     p_ret_error     --       OUT VARCHAR2);
                     );
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        fnd_file.put_line(fnd_file.LOG,'Trxn Id not found for '||lcu_count_receipts.receipt_number);
                END;
            END LOOP;
            -- Changes done for NAIT-129669

            fnd_conc_global.set_req_globals(conc_status =>       'PAUSED',
                                            request_data =>      'THIRD');
            COMMIT;
            x_ret_code := 0;
            RETURN;
        ELSIF(     (lc_req_data = 'THIRD')
              AND (p_auto_remit_submit = 'Y') )
        THEN
            DISPLAY_ERROR(p_debug_file =>      p_debug_file,
                          p_debug =>           p_debug,
                          p_ret_code =>        ln_ret_err_code);
            get_run_status(p_request_id =>      fnd_global.conc_request_id,
                           x_ret_code =>        x_ret_code,
                           x_error_buff =>      x_error_buff);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Error Code :'
                              || SQLERRM);
            x_ret_code := 2;
    END scheduler;

    PROCEDURE display_log(
        p_debug_file  IN  VARCHAR2,
        p_debug_msg   IN  VARCHAR2)
    IS
        lf_out_file       UTL_FILE.file_type;
        ln_chunk_size     BINARY_INTEGER     := 32767;
        lc_error_loc      VARCHAR2(4000);
        lc_datetimestamp  VARCHAR2(25);
    BEGIN
        lc_error_loc :=    'Opening the UTL FILE : '
                        || p_debug_file;

        SELECT TO_CHAR(SYSDATE,
                       'DD-MON-YYYY:HH24MISS')
        INTO   lc_datetimestamp
        FROM   DUAL;

        lf_out_file := UTL_FILE.fopen('XXFIN_OUTBOUND',
                                      p_debug_file,
                                      'a',
                                      ln_chunk_size);
        UTL_FILE.put_line(lf_out_file,
                             lc_datetimestamp
                          || ' - '
                          || p_debug_msg);
        UTL_FILE.fclose(lf_out_file);
    EXCEPTION
        WHEN OTHERS
        THEN
            xx_com_error_log_pub.log_error(p_program_type =>                'Receipt Remittance- Debug',
                                           p_program_name =>                'DISPLAY_LOG',
                                           p_program_id =>                  NULL,
                                           p_module_name =>                 'IBY',
                                           p_error_message_count =>         1,
                                           p_error_message_code =>          'E',
                                           p_error_message =>                  'Error at : '
                                                                            || lc_error_loc
                                                                            || ' - '
                                                                            || SQLERRM,
                                           p_error_message_severity =>      'Major',
                                           p_notify_flag =>                 'N',
                                           p_object_type =>                 '',
                                           p_object_id =>                   NULL);
    END display_log;

-- Added for QC Defect # 17474 - Start
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name : insert_data_ordt                                                 |
-- | Description : This procedure is called by CORRECT_ERR_RCPT to insert    |
-- |               data in ORDT. Category 3(a) - QC Defect # 17474           |
-- |                                                                  .      |
-- | Parameters :  p_cash_receipt_id   IN NUMBER                             |
-- |               p_receipt_method_id IN NUMBER                             |
-- |                                                                         |
-- |===============                                                          |
-- |Version   Date          Author          Remarks                          |
-- |=======   ===========   =============   =================================|
-- |  1.0     28-JUL-2012   Abdul Khan      Initial version                  |
-- +=========================================================================+
    PROCEDURE insert_data_ordt(
        p_cash_receipt_id    IN  NUMBER,
        p_receipt_method_id  IN  NUMBER)
    AS
        CURSOR lcu_order_receipt_info
        IS
            SELECT oeh.header_id,
                   xod.transaction_number,
                   xold.orig_sys_document_ref,
                   acra.cash_receipt_id,
                   acra.receipt_number,
                   acra.comments,
                   acrh.status,
                   xod.i1025_status,
                   xod.i1025_update_date,
                   xod.i1025_process_id,
                   xod.i1025_message
            FROM   oe_order_headers_all oeh,
                   xx_om_legacy_deposits xod,
                   xx_om_legacy_dep_dtls xold,
                   ar_cash_receipts_all acra,
                   ar_cash_receipt_history_all acrh
            WHERE  oeh.order_number = xold.orig_sys_document_ref
            AND    xod.transaction_number = xold.transaction_number
            AND    xold.orig_sys_document_ref = acra.attribute7
            AND    acra.cash_receipt_id = acrh.cash_receipt_id
            AND    xod.prepaid_amount > 0
            AND    acra.receipt_method_id IN(65051, 65055)   -- US_CC OD ALL_CC and CA_CC OD ALL_CC
            AND    acra.reversal_date IS NULL
            AND    acra.cc_error_flag = 'Y'
            AND    acrh.status = 'CONFIRMED'
            AND    acrh.current_record_flag = 'Y'
            AND    acra.cc_error_text LIKE '%Determine if cash receipt is Miscelleanous type (MISC)%'
            AND    acra.cash_receipt_id = p_cash_receipt_id
            AND    acra.receipt_method_id = p_receipt_method_id
            AND    NOT EXISTS(SELECT cash_receipt_id
                              FROM   xx_ar_order_receipt_dtl
                              WHERE  cash_receipt_id = acra.cash_receipt_id);

        lc_return_status  VARCHAR2(1);
    BEGIN
        FOR r1 IN lcu_order_receipt_info
        LOOP
            -- Setting orig_sys_document_ref = NULL in xx_om_legacy_dep_dtls so that XX_OM_SALES_ACCT_PKG.INSERT_INTO_RECPT_TBL cursor can pick the data
            UPDATE xx_om_legacy_dep_dtls
            SET orig_sys_document_ref = NULL
            WHERE  transaction_number = r1.transaction_number;

            -- Custom API call to insert data in ORDT
            xx_om_sales_acct_pkg.insert_into_recpt_tbl(p_header_id =>          r1.header_id,
                                                       p_batch_id =>           NULL,
                                                       p_mode =>               'NORMAL',
                                                       x_return_status =>      lc_return_status);

            -- Setting orig_sys_document_ref to orignal value in xx_om_legacy_dep_dtls
            UPDATE xx_om_legacy_dep_dtls
            SET orig_sys_document_ref = r1.orig_sys_document_ref
            WHERE  transaction_number = r1.transaction_number;

            -- Usage to below update need to be checked for latest case
            UPDATE xx_om_legacy_deposits
            SET i1025_status = 'COMPLETE',
                i1025_message = NULL,
                i1025_process_id = NULL,
                i1025_update_date = SYSDATE,
                last_updated_by = fnd_global.user_id,
                last_update_date = SYSDATE
            WHERE  transaction_number = r1.transaction_number;

            IF lc_return_status = 'S'
            THEN
                COMMIT;
                fnd_file.put_line(fnd_file.LOG,
                                     'Receipt fixed by Generic Datafix : '
                                  || r1.receipt_number);
            END IF;
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'PROCEDURE insert_data_ordt - Error : '
                              || SQLERRM);
            fnd_file.put_line(fnd_file.LOG,
                              ' ');
    END insert_data_ordt;

    -- Added for QC Defect # 17474 - End

    -- Added for Defect 3358
    PROCEDURE correct_err_rcpt(
        x_error_buff         OUT     VARCHAR2,
        x_ret_code           OUT     NUMBER,
        p_auto_remit_submit  IN      VARCHAR2,
        p_chunk_size         IN      NUMBER,
        p_batch_date         IN      VARCHAR2,
        p_batch_currency     IN      VARCHAR2,
        p_remit_method       IN      VARCHAR2,
        p_rcptclassid        IN      NUMBER,
        p_receipt_method_id  IN      NUMBER,
        p_bank_branch_id     IN      NUMBER,
        p_bank_account_id    IN      NUMBER,
        p_receipt_date_low   IN      VARCHAR2,
        p_receipt_date_high  IN      VARCHAR2,
        p_receipt_num_low    IN      VARCHAR2,
        p_receipt_num_high   IN      VARCHAR2)
    AS
        ln_conc_request_id     NUMBER;
        lc_req_data            VARCHAR2(100)                              := NULL;
        ln_ret_err_code        NUMBER                                     := 0;
        lc_col_hdr_ast         VARCHAR2(250);
        ln_rcptclassid         ar_receipt_methods.receipt_class_id%TYPE;
        lc_process_type        VARCHAR2(100)                              := 'REMIT';
        ln_req_count           NUMBER                                     := 0;
        ln_tot_req_count       NUMBER                                     := 0;
        lb_request_status      BOOLEAN;
        lc_phase               VARCHAR2(1000);
        lc_status              VARCHAR2(1000);
        lc_devphase            VARCHAR2(1000);
        lc_devstatus           VARCHAR2(1000);
        lc_message             VARCHAR2(4000);
        ln_first               NUMBER                                     := 0;
        lv_cur_rcpt_num        ar_cash_receipts.receipt_number%TYPE;
        lv_rcpt_low            ar_cash_receipts.receipt_number%TYPE;
        lv_rcpt_high           ar_cash_receipts.receipt_number%TYPE;
        lv_max_rcpt_num        ar_cash_receipts.receipt_number%TYPE;
        ln_submit_flg          NUMBER                                     := 0;
        lv_temp_rcpt_id        NUMBER                                     := 0;
        lv_temp_rcpt           ar_cash_receipts.receipt_number%TYPE;
        ln_chk_submit          NUMBER                                     := 0;
        ln_update_cnt          NUMBER                                     := 0;
        ln_error_cnt           NUMBER                                     := 0;
        ld_receipt_date_low    DATE;
        ld_receipt_date_high   DATE;
        ld_receipt_date_low1   VARCHAR2(20);
        ld_receipt_date_high1  VARCHAR2(20);
        -- Added by Divyansh
        ln_trxn_id                 NUMBER;
        x_transaction_id_out    iby_trxn_summaries_all.TransactionID%TYPE;
        x_transaction_mid_out   iby_trxn_summaries_all.trxnmid%TYPE;
        p_ret_status            VARCHAR2(2000);
        p_ret_error             VARCHAR2(2000);

        CURSOR c_err_receipts
        IS
            SELECT        acr.receipt_number,
                          acr.receipt_date,
                          acr.amount,
                          acr.org_id,
                          acr.receipt_method_id,
                          acr.cash_receipt_id,
                          acr.cc_error_text
            FROM          ar_cash_receipts acr, ar_cash_receipt_history acrh
            WHERE         acr.cash_receipt_id = acrh.cash_receipt_id
            AND           acr.cc_error_flag = 'Y'
            AND           acrh.status = 'CONFIRMED'
            AND           acrh.current_record_flag = 'Y'
            AND           acr.receipt_method_id = p_receipt_method_id
            AND           acr.receipt_date BETWEEN NVL(ld_receipt_date_low,
                                                       acr.receipt_date)
                                               AND NVL(ld_receipt_date_high,
                                                       acr.receipt_date)
            AND           acr.receipt_number BETWEEN NVL(p_receipt_num_low,
                                                         acr.receipt_number)
                                                 AND NVL(p_receipt_num_high,
                                                         acr.receipt_number)
            AND           NOT EXISTS(
                              SELECT xbt.ixrecptnumber
                              FROM   xx_iby_batch_trxns_history xbt
                              WHERE  acr.receipt_number = xbt.ixrecptnumber
                              AND    acr.cash_receipt_id = TO_NUMBER(xbt.attribute7) )
            ORDER BY      acr.receipt_number
            FOR UPDATE OF acr.receipt_number;

        -- Added for NAIT-129669  
        CURSOR c_err_rim_receipts
        IS
            SELECT        acr.receipt_number,
                          acr.receipt_date,
                          acr.amount,
                          acr.org_id,
                          acr.receipt_method_id,
                          acr.cash_receipt_id,
                          acr.cc_error_text
            FROM          ar_cash_receipts acr, ar_cash_receipt_history acrh,ar_receipt_methods arm
            WHERE         acr.cash_receipt_id = acrh.cash_receipt_id
            AND           acr.cc_error_flag = 'Y'
            AND           acrh.status = 'REMITTED'
            AND           acrh.current_record_flag = 'Y'
            AND           acr.receipt_method_id = arm.receipt_method_id
            AND           arm.name              = 'US_CC IRECEIVABLES_OD'
			AND           acr.receipt_date BETWEEN NVL(ld_receipt_date_low,
                                                       acr.receipt_date)
                                               AND NVL(ld_receipt_date_high,
                                                       acr.receipt_date)
            AND           acr.receipt_number BETWEEN NVL(p_receipt_num_low,
                                                         acr.receipt_number)
                                                 AND NVL(p_receipt_num_high,
                                                         acr.receipt_number)
            AND           NOT EXISTS(
                              SELECT xbt.ixrecptnumber
                              FROM   xx_iby_batch_trxns_history xbt
                              WHERE  acr.receipt_number = xbt.ixrecptnumber
                              AND    acr.cash_receipt_id = TO_NUMBER(xbt.attribute7) )
            ORDER BY      acr.receipt_number
            FOR UPDATE OF acr.receipt_number;

        CURSOR c_conc_req
        IS
            SELECT fcr.request_id
            FROM   fnd_concurrent_requests fcr
            WHERE  fcr.parent_request_id = fnd_global.conc_request_id;

        TYPE lt_err_receipt IS TABLE OF c_err_receipts%ROWTYPE;

        lt_err_rec             lt_err_receipt;
    BEGIN
        IF (p_auto_remit_submit = 'Y')
        THEN
            lc_req_data := fnd_conc_global.request_data;

            IF (lc_req_data = 'OVER')
            THEN
                RETURN;
            END IF;
        END IF;

        lc_col_hdr_ast := repeat_char('*',
                                      210);

        IF p_receipt_date_low IS NOT NULL
        THEN
            ld_receipt_date_low1 :=    TO_DATE(p_receipt_date_low,
                                               'YYYY/MM/DD HH24:MI:SS')
                                    || ' 00:00:00';
            ld_receipt_date_low := TO_DATE(ld_receipt_date_low1,
                                           'DD-MON-RRRR HH24:MI:SS');
        END IF;

        IF p_receipt_date_high IS NOT NULL
        THEN
            ld_receipt_date_high1 :=    TO_DATE(p_receipt_date_high,
                                                'YYYY/MM/DD HH24:MI:SS')
                                     || ' 23:59:59';
            ld_receipt_date_high := TO_DATE(ld_receipt_date_high1,
                                            'DD-MON-RRRR HH24:MI:SS');
        END IF;

        IF (NVL(lc_req_data,
                'FIRST') = 'FIRST')
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'p_auto_remit_submit : '
                              || p_auto_remit_submit);
            fnd_file.put_line(fnd_file.LOG,
                                 'p_chunk_size        : '
                              || p_chunk_size);
            fnd_file.put_line(fnd_file.LOG,
                                 'p_batch_date        : '
                              || p_batch_date);
            fnd_file.put_line(fnd_file.LOG,
                                 'p_batch_currency    : '
                              || p_batch_currency);
            fnd_file.put_line(fnd_file.LOG,
                                 'p_remit_method      : '
                              || p_remit_method);
            fnd_file.put_line(fnd_file.LOG,
                                 'p_rcptclassid       : '
                              || p_rcptclassid);
            fnd_file.put_line(fnd_file.LOG,
                                 'p_receipt_method_id : '
                              || p_receipt_method_id);
            fnd_file.put_line(fnd_file.LOG,
                                 'p_bank_branch_id    : '
                              || p_bank_branch_id);
            fnd_file.put_line(fnd_file.LOG,
                                 'p_bank_account_id   : '
                              || p_bank_account_id);
            fnd_file.put_line(fnd_file.LOG,
                                 'p_receipt_date_low  : '
                              || p_receipt_date_low);
            fnd_file.put_line(fnd_file.LOG,
                                 'p_receipt_date_high : '
                              || p_receipt_date_high);
            fnd_file.put_line(fnd_file.LOG,
                                 'p_receipt_num_low   : '
                              || p_receipt_num_low);
            fnd_file.put_line(fnd_file.LOG,
                                 'p_receipt_num_high  : '
                              || p_receipt_num_high);
            fnd_file.put_line(fnd_file.output,
                                 repeat_char('*',
                                             90)
                              || 'Receipts Before Reprocessing'
                              || repeat_char('*',
                                             92) );
            fnd_file.put_line(fnd_file.output,
                                 RPAD('Receipt Number',
                                      gc_rpad_len)
                              || RPAD('Receipt Amount',
                                      gc_rpad_len)
                              || RPAD('Receipt Date',
                                      gc_rpad_len)
                              || RPAD('Receipt Method Id',
                                      gc_rpad_len)
                              || RPAD('Org Id',
                                      gc_rpad_len)
                              || RPAD('Error Message',
                                      110) );
            fnd_file.put_line(fnd_file.output,
                              lc_col_hdr_ast);

            OPEN c_err_receipts;

            LOOP
                FETCH c_err_receipts
                BULK COLLECT INTO lt_err_rec;

                FOR i IN 1 .. lt_err_rec.COUNT
                LOOP
                    fnd_file.put_line(fnd_file.output,
                                         RPAD(lt_err_rec(i).receipt_number,
                                              gc_rpad_len)
                                      || RPAD(lt_err_rec(i).amount,
                                              gc_rpad_len)
                                      || RPAD(lt_err_rec(i).receipt_date,
                                              gc_rpad_len)
                                      || RPAD(lt_err_rec(i).receipt_method_id,
                                              gc_rpad_len)
                                      || RPAD(lt_err_rec(i).org_id,
                                              gc_rpad_len)
                                      || RPAD(SUBSTR(lt_err_rec(i).cc_error_text,
                                                     1,
                                                     110),
                                              110) );
                    insert_data_ordt(lt_err_rec(i).cash_receipt_id,
                                     lt_err_rec(i).receipt_method_id);

                    IF (p_auto_remit_submit = 'Y')
                    THEN
                        UPDATE ar_cash_receipts acr
                        SET acr.cc_error_flag = NULL,
                            acr.cc_error_text = NULL,
                            acr.cc_error_code = NULL,
                            acr.rec_version_number =   acr.rec_version_number
                                                     + 1
                        WHERE  acr.cash_receipt_id = lt_err_rec(i).cash_receipt_id;
                    END IF;

                    ln_update_cnt :=   ln_update_cnt
                                     + 1;
                END LOOP;

                EXIT WHEN c_err_receipts%NOTFOUND;
            END LOOP;

            COMMIT;

            CLOSE c_err_receipts;

            fnd_file.put_line(fnd_file.LOG,
                              '============================================');
            fnd_file.put_line(fnd_file.LOG,
                                 'No. of Records for Reprocessing : '
                              || ln_update_cnt);
            fnd_file.put_line(fnd_file.LOG,
                              '============================================');
            fnd_file.put_line(fnd_file.LOG,
                              '');
            fnd_file.put_line(fnd_file.output,
                              '');
            fnd_file.put_line(fnd_file.output,
                              '============================================');
            fnd_file.put_line(fnd_file.output,
                                 'No. of Records for Reprocessing : '
                              || ln_update_cnt);
            fnd_file.put_line(fnd_file.output,
                              '============================================');
            fnd_file.put_line(fnd_file.output,
                              '');
            fnd_file.put_line(fnd_file.output,
                              '');

            --Submitting Automatic Remittances Creation Program (SRS)
            IF (    p_auto_remit_submit = 'Y'
                AND ln_update_cnt > 0)
            THEN
                FOR i IN lt_err_rec.FIRST .. lt_err_rec.LAST
                LOOP
                    lv_cur_rcpt_num := lt_err_rec(i).receipt_number;

                    IF (ln_first = 0)
                    THEN
                        lv_rcpt_low := lt_err_rec(i).receipt_number;
                        lv_max_rcpt_num :=   lv_cur_rcpt_num
                                           + p_chunk_size;
                        ln_first := 1;
                    END IF;

                    IF (lv_cur_rcpt_num > lv_max_rcpt_num)
                    THEN
                        ln_submit_flg := 1;
                        lv_rcpt_high := lt_err_rec(  i
                                                   - 1).receipt_number;
                        ln_req_count :=   ln_req_count
                                        + 1;
                    END IF;

                    IF (i = lt_err_rec.COUNT)
                    THEN
                        IF (lv_cur_rcpt_num > lv_max_rcpt_num)
                        THEN
                            lv_temp_rcpt := lt_err_rec(i).receipt_number;
                            ln_chk_submit := 1;
                        ELSE
                            lv_rcpt_high := lt_err_rec(i).receipt_number;
                            ln_submit_flg := 1;
                        END IF;
                    END IF;

                    IF (ln_submit_flg = 1)
                    THEN
                        ln_conc_request_id :=
                            fnd_request.submit_request('AR',
                                                       'AUTOREMAPI',
                                                       '',
                                                       '',
                                                       TRUE,
                                                       lc_process_type,
                                                       p_batch_date,
                                                       TO_CHAR(TRUNC(SYSDATE),
                                                               'YYYY/MM/DD HH24:MI:SS'),
                                                       'Y',
                                                       'Y',
                                                       'N',
                                                       '',
                                                       '',
                                                       p_batch_currency,
                                                       '',
                                                       '',
                                                       '',
                                                       p_remit_method,
                                                       p_rcptclassid,
                                                       p_receipt_method_id,
                                                       '',
                                                       p_bank_branch_id,
                                                       p_bank_account_id,
                                                       '',
                                                       '',
                                                       '',
                                                       '',
                                                       '',
                                                       '',
                                                       lv_rcpt_low,
                                                       lv_rcpt_high,
                                                       '',
                                                       '',
                                                       '',
                                                       '',
                                                       '',
                                                       '',
                                                       '',
                                                       '',
                                                       '',
                                                       '',
                                                       '',
                                                       '',
                                                       '',
                                                       '',
                                                       '',
                                                       '',
                                                       '');
                        COMMIT;
                        fnd_file.put_line(fnd_file.LOG,
                                             'Automatic Remittances Creation Program (SRS) : '
                                          || ln_conc_request_id
                                          || ' submitted for receipt number range from '
                                          || lv_rcpt_low
                                          || ' to '
                                          || lv_rcpt_high);
                        lv_rcpt_low := lt_err_rec(i).receipt_number;
                        lv_max_rcpt_num :=   lv_rcpt_low
                                           + p_chunk_size;
                        ln_submit_flg := 0;
                    END IF;
                END LOOP;

                IF (ln_chk_submit = 1)
                THEN
                    ln_conc_request_id :=
                        fnd_request.submit_request('AR',
                                                   'AUTOREMAPI',
                                                   '',
                                                   '',
                                                   TRUE,
                                                   lc_process_type,
                                                   p_batch_date,
                                                   TO_CHAR(TRUNC(SYSDATE),
                                                           'YYYY/MM/DD HH24:MI:SS'),
                                                   'Y',
                                                   'Y',
                                                   'N',
                                                   '',
                                                   '',
                                                   p_batch_currency,
                                                   '',
                                                   '',
                                                   '',
                                                   p_remit_method,
                                                   p_rcptclassid,
                                                   p_receipt_method_id,
                                                   '',
                                                   p_bank_branch_id,
                                                   p_bank_account_id,
                                                   '',
                                                   '',
                                                   '',
                                                   '',
                                                   '',
                                                   '',
                                                   lv_temp_rcpt,
                                                   lv_temp_rcpt,
                                                   '',
                                                   '',
                                                   '',
                                                   '',
                                                   '',
                                                   '',
                                                   '',
                                                   '',
                                                   '',
                                                   '',
                                                   '',
                                                   '',
                                                   '',
                                                   '',
                                                   '',
                                                   '',
                                                   '');
                    COMMIT;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Automatic Remittances Creation Program (SRS) : '
                                      || ln_conc_request_id
                                      || ' submitted for receipt number range from '
                                      || lv_temp_rcpt
                                      || ' to '
                                      || lv_temp_rcpt);
                    ln_req_count :=   ln_req_count
                                    + 1;
                END IF;

                IF (p_auto_remit_submit = 'Y')
                THEN
                    fnd_conc_global.set_req_globals(conc_status =>       'PAUSED',
                                                    request_data =>      'SECOND');
                    COMMIT;
                    x_ret_code := 0;
                    RETURN;
                END IF;
            ELSE
                fnd_file.put_line(fnd_file.LOG,
                                  'No Records submitted for Processing ');
            END IF;
        ELSIF(     (lc_req_data = 'SECOND')
              AND (p_auto_remit_submit = 'Y') )
        THEN
            submit_offline_transaction(p_batch_count      => 1, -- Updated per defect 30015 p_batch_count,
                                        x_request_id       => ln_conc_request_id);
            
            --
            -- Added for NAIT-129669  
            FOR lcu_count_receipts IN c_err_rim_receipts loop
                fnd_file.put_line(fnd_file.LOG,'processing for '||lcu_count_receipts.receipt_number);
                BEGIN
                    SELECT TRANSACTIONID
                      INTO ln_trxn_id
                      FROM ar_cash_receipts_all acr,
                           iby_fndcpt_tx_operations ifto
                     WHERE acr.payment_trxn_extension_id = ifto.trxn_extension_id
                       AND acr.receipt_number = lcu_count_receipts.receipt_number;
                    
                    fnd_file.put_line(fnd_file.LOG,'processing for ln_trxn_id '||ln_trxn_id);
                    xx_eai_authorization.xx_capture(ln_trxn_id,--p_trxn_id  --    IN  NUMBER,
                                                     x_transaction_id_out,--   OUT iby_trxn_summaries_all.TransactionID%TYPE,
                                                     x_transaction_mid_out  ,--OUT iby_trxn_summaries_all.trxnmid%TYPE,
                                                     p_ret_status ,--          OUT VARCHAR2,
                                                     p_ret_error     --       OUT VARCHAR2);
                     );
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        fnd_file.put_line(fnd_file.LOG,'Trxn Id not found for '||lcu_count_receipts.receipt_number);
                END;
            END LOOP;
            ---- Changes done for NAIT-129669  
            fnd_conc_global.set_req_globals(conc_status =>       'PAUSED',
                                            request_data =>      'THIRD');
            COMMIT;
            x_ret_code := 0;
            RETURN;
        ELSIF(     (lc_req_data = 'THIRD')
              AND (p_auto_remit_submit = 'Y') )
        THEN   -- Count
        
            fnd_file.put_line(fnd_file.output,
                                 repeat_char('*',
                                             90)
                              || ' Error Receipts After Reprocessing'
                              || repeat_char('*',
                                             86) );
            fnd_file.put_line(fnd_file.output,
                                 RPAD('Receipt Number',
                                      gc_rpad_len)
                              || RPAD('Receipt Amount',
                                      gc_rpad_len)
                              || RPAD('Receipt Date',
                                      gc_rpad_len)
                              || RPAD('Receipt Method Id',
                                      gc_rpad_len)
                              || RPAD('Org Id',
                                      gc_rpad_len)
                              || RPAD('Error Message',
                                      110) );
            fnd_file.put_line(fnd_file.output,
                              lc_col_hdr_ast);

            FOR lc_err_receipts IN c_err_receipts
            LOOP
                fnd_file.put_line(fnd_file.output,
                                     RPAD(lc_err_receipts.receipt_number,
                                          gc_rpad_len)
                                  || RPAD(lc_err_receipts.amount,
                                          gc_rpad_len)
                                  || RPAD(lc_err_receipts.receipt_date,
                                          gc_rpad_len)
                                  || RPAD(lc_err_receipts.receipt_method_id,
                                          gc_rpad_len)
                                  || RPAD(lc_err_receipts.org_id,
                                          gc_rpad_len)
                                  || RPAD(SUBSTR(lc_err_receipts.cc_error_text,
                                                 1,
                                                 110),
                                          110) );
                ln_error_cnt :=   ln_error_cnt
                                + 1;
            END LOOP;

            IF (ln_error_cnt > 0)
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  '===============================================================');
                fnd_file.put_line(fnd_file.LOG,
                                     'No. of Records that completed in Error after reprocessing : '
                                  || ln_error_cnt);
                fnd_file.put_line(fnd_file.LOG,
                                  '===============================================================');
                fnd_file.put_line(fnd_file.LOG,
                                  '');
                fnd_file.put_line(fnd_file.output,
                                  '');
                fnd_file.put_line(fnd_file.output,
                                  '============================================');
                fnd_file.put_line(fnd_file.output,
                                     'No. of Records that completed in Error : '
                                  || ln_error_cnt);
                fnd_file.put_line(fnd_file.output,
                                  '============================================');
                fnd_file.put_line(fnd_file.output,
                                  '');
            ELSE
                fnd_file.put_line(fnd_file.LOG,
                                  '============================================');
                fnd_file.put_line(fnd_file.LOG,
                                  'No Data found. ');
                fnd_file.put_line(fnd_file.LOG,
                                  '============================================');
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Error Code : '
                              || SQLERRM);
            x_ret_code := fnd_api.g_ret_sts_error;
    END correct_err_rcpt;
END xx_ar_autoremit_pkg;
/