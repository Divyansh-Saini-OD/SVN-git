CREATE OR REPLACE PACKAGE BODY XX_AR_MT_WC_PKG
AS
   -- global variables declaration
   gc_fr_date    VARCHAR2 (25);
   gc_to_date    VARCHAR2 (25);
   gd_fr_date    DATE;
   gd_to_date    DATE;
   gn_ret_code   NUMBER        := 0;

   /*+===================================================================================+
   | Name       : GET_DATE_RANGE                                                         |
   | Description: This procedure is used to fetch from and to date                       |
   |                                                                                     |
   | Parameters : p_debug                                                                |
   |              p_msg                                                                  |
   |                                                                                     |
   | Returns    : none                                                                   |
   +===================================================================================+*/
   PROCEDURE get_date_range
   IS
   BEGIN
      xx_ar_wc_pkg.from_to_date (gc_fr_date, gc_to_date, gn_ret_code);
      gd_fr_date := fnd_date.canonical_to_date (gc_fr_date);
      gd_to_date := fnd_date.canonical_to_date (gc_to_date);
   END get_date_range;

   /*+===================================================================================+
   | Name       : WRITE_LOG                                                              |
   | Description: This procedure is used to display detailed messages to log file     |
   |                                                                                     |
   | Parameters : p_debug                                                                |
   |              p_msg                                                                  |
   |                                                                                     |
   | Returns    : none                                                                   |
   +===================================================================================+*/
   PROCEDURE write_log (
      p_debug   VARCHAR2
     ,p_msg     VARCHAR2
   )
   IS
   BEGIN
      IF p_debug = 'Y'
      THEN
         fnd_file.put_line (fnd_file.LOG, p_msg);
      END IF;
   END write_log;

   /*==============================================================================+
   | Name       : compute_stats                                                    |
   |                                                                               |
   | Description: This procedure is used to to display detailed                    |
   |                     messages to log file                                      |
   |                                                                               |
   | Parameters : p_compute_stats                                                  |
   |              p_schema                                                         |
   |              p_tablename                                                      |
   | Returns    : none                                                             |
   +===============================================================================*/
   PROCEDURE compute_stat (
      p_compute_stats   VARCHAR2
     ,p_ownname         VARCHAR2
     ,p_tabname         VARCHAR2
   )
   IS
   BEGIN
      IF p_compute_stats = 'Y'
      THEN
         fnd_stats.gather_table_stats (ownname => p_ownname, tabname => p_tabname);
      END IF;
   END compute_stat;

   --+=================================================================================================+
   --Procedure for Tramsactions which will submit the Full or Incremental Program using Multi threading
   --+=================================================================================================+
   PROCEDURE txn_mt (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_action_type     IN       VARCHAR2
     ,p_last_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
     ,p_debug           IN       VARCHAR2
   )
   AS
      CURSOR lcu_cust_accts_txn (
         ln_no_of_threads   IN   NUMBER
      )
      IS
         SELECT   MIN (X.cust_account_id) "from_cust_account_id"
                 ,MAX (X.cust_account_id) "to_cust_account_id"
                 ,X.thread_num
             FROM xx_crm_wcelg_cust ELG_CUST
                 , (SELECT cust_account_id
                          ,NTILE (ln_no_of_threads) OVER (ORDER BY cust_account_id ASC) AS thread_num
                      FROM xx_crm_wcelg_cust
                     WHERE ar_trans_ext = 'N') X
            WHERE ELG_CUST.cust_account_id = X.cust_account_id
         GROUP BY X.thread_num
         ORDER BY X.thread_num;

      CURSOR lcu_cust_accts_txn_in (
         ln_no_of_threads   IN   NUMBER
        ,p_from_date        IN   DATE
        ,p_to_date          IN   DATE
      )
      IS
         SELECT   MIN (X.customer_trx_id)
                 ,MAX (X.customer_trx_id)
                 ,X.thread_num
             FROM SYS.DUAL
                 , (SELECT RCT.customer_trx_id
                          ,NTILE (ln_no_of_threads) OVER (ORDER BY customer_trx_id ASC) AS thread_num
                      FROM xx_crm_wcelg_cust CE
                          ,ra_customer_trx_all RCT
                     WHERE RCT.last_update_date BETWEEN p_from_date AND p_to_date AND RCT.bill_to_customer_id = CE.cust_account_id) X
         GROUP BY X.thread_num
         ORDER BY X.thread_num;

      ln_parent_cp_id           NUMBER;
      ln_parent_request_id      NUMBER                                                         := fnd_global.conc_request_id;
      ln_child_cp_id            NUMBER;
      lc_child_prog_name        fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
      ln_conc_req_id            NUMBER;
      ln_ext_wc_s               NUMBER;
      ln_threads                NUMBER;
      lc_dev_phase              VARCHAR2 (200);                                                                      --fnd_lookup_values.meaning%TYPE;
      lc_dev_status             VARCHAR2 (200);                                                                      --fnd_lookup_values.meaning%TYPE;
      lc_phase                  VARCHAR2 (200);                                                                      --fnd_lookup_values.meaning%TYPE;
      lc_status                 VARCHAR2 (200);                                                                      --fnd_lookup_values.meaning%TYPE;
      lc_message                VARCHAR2 (2000);
      lc_error_debug            VARCHAR2 (1000);
      ln_from_cust_account_id   hz_cust_accounts.cust_account_id%TYPE;
      ln_to_cust_account_id     hz_cust_accounts.cust_account_id%TYPE;
      ln_from_cust_trx_id       ra_customer_trx_all.customer_trx_id%TYPE;
      ln_to_cust_trx_id         ra_customer_trx_all.customer_trx_id%TYPE;
      ln_thread_num             NUMBER;
      ln_no_of_threads          NUMBER;
      ln_req_id                 req_id;
      ln_idx                    NUMBER                                                         := 1;
      lc_compute_stats          VARCHAR2 (1);
      lc_debug_flag             VARCHAR2 (1);
      ld_from_date              DATE;
      ld_to_date                DATE;
      ld_last_run_date          DATE;
      lc_last_run_date          VARCHAR2 (20);
      ln_retcode                NUMBER                                                         := 0;
      ln_count                  NUMBER                                                         := 0;
      le_run_cust_first         EXCEPTION;
   BEGIN
      get_date_range;

      IF gn_ret_code > 0
      THEN
         RAISE le_run_cust_first;
      END IF;

      FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************ENTERED PARAMETERS FOR AR TRANSACTIONS*******************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Action Type        :' || p_action_type);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Last Run Date      :' || p_last_run_date);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Last To Date       :' || p_to_run_date);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Compute Statistics :' || p_compute_stats);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag         :' || p_debug);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************************************************************');
      FND_GLOBAL.APPS_INITIALIZE (gn_user_id, gn_resp_id, gn_appl_id);

      SELECT XX_AR_MT_WC_S.NEXTVAL
        INTO ln_ext_wc_s
        FROM DUAL;

      BEGIN
         SELECT concurrent_program_id
           INTO ln_parent_cp_id
           FROM fnd_concurrent_requests fcr
          WHERE fcr.request_id = ln_parent_request_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG, 'Parent id ' || ln_parent_cp_id);
            ln_parent_cp_id := NULL;
      END;

      write_log (p_debug, 'Parent Request ID :' || ln_parent_request_id || ',' || 'Parent Concurrent Program ID :' || ln_parent_cp_id);

      BEGIN
         SELECT XFTV.target_value3
               ,XFTV.target_value6
           INTO ln_threads
               ,lc_compute_stats
           FROM xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
          WHERE XFTV.translate_id = XFTD.translate_id
            AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND XFTV.source_value1 = 'AR_TRANS'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line (fnd_file.LOG, 'For Transalation Definition is not defined for AR_TRANS');
      END;

      FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************DERIVED PARAMETERS*******************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parent Request ID    :' || ln_parent_request_id);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parent Concurrent ID :' || ln_parent_cp_id);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Threads              :' || ln_threads);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Compute Statistics   :' || lc_compute_stats);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************');
      write_log (p_debug, 'No. of Threads :' || ln_threads || ' Compute Stats :' || lc_compute_stats);

      -----------------------------------------------------------
      --Submit the Program for the Transactions  Daily Conversion
      -----------------------------------------------------------
      IF p_action_type = 'F'
      THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Truncating the Staging table');

         EXECUTE IMMEDIATE 'TRUNCATE TABLE  xxfin.xx_ar_trans_wc_stg';

         BEGIN
            SELECT fcp.concurrent_program_id
                  ,fcp.user_concurrent_program_name
              INTO ln_child_cp_id
                  ,lc_child_prog_name
              FROM fnd_concurrent_programs_vl fcp
             WHERE fcp.concurrent_program_name = 'XXARFTXNWC';
         EXCEPTION
            WHEN OTHERS
            THEN
               FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child id :' || ln_child_cp_id || ',' || 'Child Program :' || lc_child_prog_name);
               ln_child_cp_id := 0;
         END;

         write_log (p_debug, 'Child id :' || ln_child_cp_id || ',' || 'Child Program :' || lc_child_prog_name);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Daily conversion(Full)');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Before the Loop-Daily conversion(Full)');

         OPEN lcu_cust_accts_txn (ln_threads);

         LOOP
            FETCH lcu_cust_accts_txn
             INTO ln_from_cust_account_id
                 ,ln_to_cust_account_id
                 ,ln_thread_num;

            EXIT WHEN lcu_cust_accts_txn%NOTFOUND;
            ln_conc_req_id :=
               fnd_request.submit_request (application      => 'XXFIN'
                                          ,program          => 'XXARFTXNWC'
                                          ,description      => ln_thread_num || ':'
                                          ,start_time       => SYSDATE
                                          ,sub_request      => FALSE
                                          ,argument1        => ln_from_cust_account_id
                                          ,argument2        => ln_to_cust_account_id
                                          ,argument3        => 'N'
                                          ,argument4        => p_debug
                                          ,argument5        => ln_thread_num
                                          );

            IF ln_conc_req_id = 0
            THEN
               FND_FILE.PUT_LINE (FND_FILE.LOG, 'AR Transaction Child Program is not submitted');
               p_retcode := 2;
            ELSE
               ln_req_id (ln_idx) := ln_conc_req_id;
               ln_idx := ln_idx + 1;
            END IF;

            write_log (p_debug, 'Child Concurrent Request Id :' || ln_conc_req_id);

            INSERT INTO XX_AR_MT_WC_DETAILS
                        (mt_seq
                        ,parent_program_id
                        ,parent_request_id
                        ,thread_num
                        ,child_program_name
                        ,child_program_id
                        ,child_request_id
                        ,from_cust_account_id
                        ,to_cust_account_id
                        ,from_run_date
                        ,to_run_date
                        ,last_updated_by
                        ,creation_date
                        ,created_by
                        ,last_update_date
                        )
                 VALUES (ln_ext_wc_s
                        ,ln_parent_cp_id
                        ,ln_parent_request_id
                        ,ln_thread_num
                        ,lc_child_prog_name
                        ,ln_child_cp_id
                        ,ln_conc_req_id
                        ,ln_from_cust_account_id
                        ,ln_to_cust_account_id
                        ,p_last_run_date
                        ,p_to_run_date
                        ,gn_user_id
                        ,SYSDATE
                        ,gn_user_id
                        ,SYSDATE
                        );

            COMMIT;
         END LOOP;

         FND_FILE.PUT_LINE (FND_FILE.LOG, 'After the Loop-Daily conversion(Full)');

         CLOSE lcu_cust_accts_txn;
      ELSE
      -----------------------------------------------------
      --Submit the Program for the Transactions Daily Delta
      -----------------------------------------------------
         BEGIN
            SELECT fcp.concurrent_program_id
                  ,fcp.user_concurrent_program_name
              INTO ln_child_cp_id
                  ,lc_child_prog_name
              FROM fnd_concurrent_programs_vl fcp
             WHERE fcp.concurrent_program_name = 'XXARDTXNWC';
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Child id :' || ln_child_cp_id || 'Child Program :' || lc_child_prog_name);
               ln_child_cp_id := NULL;
         END;

         write_log (p_debug, 'Child id :' || ln_child_cp_id || 'Child Program :' || lc_child_prog_name);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Daily Delta(Incremental)');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Before the Loop-Daily Delta(Incremental)');

         OPEN lcu_cust_accts_txn_in (ln_threads, gd_fr_date, gd_to_date);

         LOOP
            FETCH lcu_cust_accts_txn_in
             INTO ln_from_cust_trx_id
                 ,ln_to_cust_trx_id
                 ,ln_thread_num;

            EXIT WHEN lcu_cust_accts_txn_in%NOTFOUND;
            ln_conc_req_id :=
               fnd_request.submit_request (application      => 'XXFIN'
                                          ,program          => 'XXARDTXNWC'
                                          ,description      => ln_thread_num || ':'
                                          ,start_time       => SYSDATE
                                          ,sub_request      => FALSE
                                          ,argument1        => gc_fr_date
                                          ,argument2        => gc_to_date
                                          ,argument3        => ln_from_cust_trx_id
                                          ,argument4        => ln_to_cust_trx_id
                                          ,argument5        => 'N'
                                          ,argument6        => p_debug
                                          ,argument7        => ln_thread_num
                                          );

            IF ln_conc_req_id = 0
            THEN
               fnd_file.put_line (fnd_file.LOG, 'AR Transactions Child Program is not submitted');
               p_retcode := 2;
            ELSE
               ln_req_id (ln_idx) := ln_conc_req_id;
               ln_idx := ln_idx + 1;
            END IF;

            write_log (p_debug, 'Child Concurrent Request Id :' || ln_conc_req_id);

            INSERT INTO XX_AR_MT_WC_DETAILS
                        (mt_seq
                        ,parent_program_id
                        ,parent_request_id
                        ,thread_num
                        ,child_program_name
                        ,child_program_id
                        ,child_request_id
                        ,from_cust_account_id
                        ,to_cust_account_id
                        ,from_run_date
                        ,to_run_date
                        ,last_updated_by
                        ,creation_date
                        ,created_by
                        ,last_update_date
                        )
                 VALUES (ln_ext_wc_s
                        ,ln_parent_cp_id
                        ,ln_parent_request_id
                        ,ln_thread_num
                        ,lc_child_prog_name
                        ,ln_child_cp_id
                        ,ln_conc_req_id
                        ,ln_from_cust_account_id
                        ,ln_to_cust_account_id
                        ,gd_fr_date
                        ,gd_to_date
                        ,gn_user_id
                        ,SYSDATE
                        ,gn_user_id
                        ,SYSDATE
                        );

            COMMIT;
         END LOOP;

         FND_FILE.PUT_LINE (FND_FILE.LOG, 'After the Loop-Daily Delta(Incremental)');

         CLOSE lcu_cust_accts_txn_in;
      END IF;

      IF ln_req_id.COUNT > 0
      THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, '1');

         FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
         LOOP
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'inside for loop');

            IF apps.fnd_concurrent.wait_for_request (ln_req_id (i), 30, 0, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message)
            THEN
               IF UPPER (lc_status) = 'ERROR'
               THEN
                  FND_FILE.PUT_LINE (FND_FILE.LOG, 'Thread ' || i || ' completed with error');
                  p_retcode := 2;
               ELSIF UPPER (lc_status) = 'WARNING'
               THEN
                  FND_FILE.PUT_LINE (FND_FILE.LOG, 'Thread ' || i || ' completed with warning');
                  p_retcode := 1;
               ELSE
                  FND_FILE.PUT_LINE (FND_FILE.LOG, 'Thread ' || i || ' completed normal');
               END IF;

               SELECT GREATEST (p_retcode, ln_retcode)
                 INTO ln_retcode
                 FROM DUAL;
            END IF;
         END LOOP;
      END IF;

      p_retcode := ln_retcode;

      SELECT COUNT (*)
        INTO ln_count
        FROM XX_AR_TRANS_WC_STG;

      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Total Records in the Transaction Staging Table :' || ln_count);
      compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_TRANS_WC_STG');
      compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_MT_WC_DETAILS');
   EXCEPTION
      WHEN le_run_cust_first
      THEN
         lc_error_debug := 'Customer Eligibility Program should run first.';
         FND_FILE.PUT_LINE (FND_FILE.LOG, lc_error_debug);
         p_retcode := 2;
      WHEN NO_DATA_FOUND
      THEN
         lc_error_debug := ' No data found ' || SQLERRM;
         FND_FILE.PUT_LINE (FND_FILE.LOG, lc_error_debug);
         p_retcode := 2;
      WHEN OTHERS
      THEN
         lc_error_debug := ' Exception is raised in Transactions-Multi Threading-' || SQLERRM;
         FND_FILE.PUT_LINE (FND_FILE.LOG, lc_error_debug);
         p_retcode := 2;
   END txn_mt;

   --+=================================================================================================+
   ---Procedure for Cash Receipt which will submit the Full or Incremental Program using Multi threading
   --+=================================================================================================+

   PROCEDURE cr_mt (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_action_type     IN       VARCHAR2
     ,p_last_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
     ,p_debug           IN       VARCHAR2
   )
   AS
      CURSOR lcu_cust_accts_cr (
         ln_no_of_threads   IN   NUMBER
      )
      IS
         SELECT   MIN (X.cust_account_id) "from_cust_account_id"
                 ,MAX (X.cust_account_id) "to_cust_account_id"
                 ,X.thread_num
             FROM xx_crm_wcelg_cust ELG_CUST
                 , (SELECT cust_account_id
                          ,NTILE (ln_no_of_threads) OVER (ORDER BY cust_account_id ASC) AS thread_num
                      FROM xx_crm_wcelg_cust
                     WHERE cash_rec_ext = 'N') X
            WHERE ELG_CUST.cust_account_id = X.cust_account_id
         GROUP BY X.thread_num
         ORDER BY X.thread_num;

      CURSOR lcu_cust_accts_cr_in (
         ln_no_of_threads   IN   NUMBER
        ,p_from_date        IN   DATE
        ,p_to_date          IN   DATE
      )
      IS
         SELECT   MIN (X.cash_receipt_id)
                 ,MAX (X.cash_receipt_id)
                 ,X.thread_num
             FROM SYS.DUAL
                 , (SELECT CR.cash_receipt_id
                          ,NTILE (ln_no_of_threads) OVER (ORDER BY cash_receipt_id ASC) AS thread_num
                      FROM XX_CRM_WCELG_CUST CE
                          ,ar_cash_receipts_all CR
                     WHERE CR.last_update_date BETWEEN p_from_date AND p_to_date AND CE.cust_account_id = CR.pay_from_customer) X
         GROUP BY X.thread_num
         ORDER BY X.thread_num;

      ln_parent_cp_id           NUMBER;
      ln_parent_request_id      NUMBER                                                         := fnd_global.conc_request_id;
      ln_child_cp_id            NUMBER;
      lc_child_prog_name        fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
      ln_conc_req_id            NUMBER;
      ln_ext_wc_s               NUMBER;
      ln_threads                NUMBER;
      lc_dev_phase              fnd_lookup_values.meaning%TYPE;
      lc_dev_status             fnd_lookup_values.meaning%TYPE;
      lc_phase                  fnd_lookup_values.meaning%TYPE;
      lc_status                 fnd_lookup_values.meaning%TYPE;
      lc_message                VARCHAR2 (2000);
      lc_error_debug            VARCHAR2 (1000);
      ln_from_cust_account_id   hz_cust_accounts.cust_account_id%TYPE;
      ln_to_cust_account_id     hz_cust_accounts.cust_account_id%TYPE;
      ln_from_cash_rcpt_id      ar_cash_receipts_all.cash_receipt_id%TYPE;
      ln_to_cash_rcpt_id        ar_cash_receipts_all.cash_receipt_id%TYPE;
      ln_thread_num             NUMBER;
      ln_no_of_threads          NUMBER;
      ln_req_id                 req_id;
      ln_idx                    NUMBER                                                         := 1;
      lc_compute_stats          VARCHAR2 (1);
      lc_debug_flag             VARCHAR2 (1);
      ld_from_date              DATE;
      ld_to_date                DATE;
      ld_last_run_date          DATE;
      lc_last_run_date          VARCHAR2 (20);
      ln_retcode                NUMBER                                                         := 0;
      ln_count                  NUMBER                                                         := 0;
      le_run_cust_first         EXCEPTION;
   BEGIN
      get_date_range;

      IF gn_ret_code > 0
      THEN
         RAISE le_run_cust_first;
      END IF;

      FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************ENTERED PARAMETERS FOR CASH RECEIPT**********************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Action Type        :' || p_action_type);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Last Run Date      :' || p_last_run_date);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Last To Date       :' || p_to_run_date);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Compute Statistics :' || p_compute_stats);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag         :' || p_debug);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************************************************************');
      FND_GLOBAL.APPS_INITIALIZE (gn_user_id, gn_resp_id, gn_appl_id);

      SELECT XX_AR_MT_WC_S.NEXTVAL
        INTO ln_ext_wc_s
        FROM DUAL;

      BEGIN
         SELECT concurrent_program_id
           INTO ln_parent_cp_id
           FROM fnd_concurrent_requests fcr
          WHERE fcr.request_id = ln_parent_request_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parent id ' || ln_parent_cp_id);
            ln_parent_cp_id := NULL;
      END;

      write_log (p_debug, 'Parent Request ID :' || ln_parent_request_id || ',' || 'Parent Concurrent Program ID :' || ln_parent_cp_id);

      BEGIN
         SELECT xftv.target_value3
               ,xftv.target_value6
           INTO ln_threads
               ,lc_compute_stats
           FROM xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
          WHERE XFTV.translate_id = XFTD.translate_id
            AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND XFTV.source_value1 = 'AR_CASH_RECEIPTS'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'For Transalation Definition is not defined for AR_CASH_RECEIPTS');
      END;

      FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************DERIVED PARAMETERS*******************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parent Request ID    :' || ln_parent_request_id);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parent Concurrent ID :' || ln_parent_cp_id);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Threads              :' || ln_threads);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Compute Statistics   :' || lc_compute_stats);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************');
      write_log (p_debug, 'No. of Threads :' || ln_threads || ' Compute Stats :' || lc_compute_stats);

      IF p_debug IS NOT NULL
      THEN
         lc_debug_flag := p_debug;
      END IF;

      IF p_compute_stats IS NOT NULL
      THEN
         lc_compute_stats := p_compute_stats;
      END IF;

      -----------------------------------------------------------
      --Submit the Program for the Cash Receipts Daily Conversion
      -----------------------------------------------------------
      IF p_action_type = 'F'
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Daily conversion(Full)');

         EXECUTE IMMEDIATE 'TRUNCATE TABLE  xxfin.xx_ar_cr_wc_stg';

         BEGIN
            SELECT fcp.concurrent_program_id
                  ,fcp.user_concurrent_program_name
              INTO ln_child_cp_id
                  ,lc_child_prog_name
              FROM fnd_concurrent_programs_vl fcp
             WHERE fcp.concurrent_program_name = 'XXARFCRWC';
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Child id :' || ln_child_cp_id || ',' || 'Child Program :' || lc_child_prog_name);
               ln_child_cp_id := 0;
         END;

         write_log (p_debug, 'Child id :' || ln_child_cp_id || ',' || 'Child Program :' || lc_child_prog_name);
         fnd_file.put_line (fnd_file.LOG, 'Before the Loop-Daily conversion(Full)');

         OPEN lcu_cust_accts_cr (ln_threads);

         LOOP
            FETCH lcu_cust_accts_cr
             INTO ln_from_cust_account_id
                 ,ln_to_cust_account_id
                 ,ln_thread_num;

            EXIT WHEN lcu_cust_accts_cr%NOTFOUND;
            ln_conc_req_id :=
               fnd_request.submit_request (application      => 'XXFIN'
                                          ,program          => 'XXARFCRWC'
                                          ,description      => ln_thread_num || ':'
                                          ,start_time       => SYSDATE
                                          ,sub_request      => FALSE
                                          ,argument1        => ln_from_cust_account_id
                                          ,argument2        => ln_to_cust_account_id
                                          ,argument3        => 'N'
                                          ,argument4        => p_debug
                                          ,argument5        => ln_thread_num
                                          );

            IF ln_conc_req_id = 0
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Cash Receipt Child Program is not submitted');
               p_retcode := 2;
            ELSE
               ln_req_id (ln_idx) := ln_conc_req_id;
               ln_idx := ln_idx + 1;
            END IF;

            write_log (p_debug, 'Child Concurrent Request Id :' || ln_conc_req_id);

            INSERT INTO XX_AR_MT_WC_DETAILS
                        (mt_seq
                        ,parent_program_id
                        ,parent_request_id
                        ,thread_num
                        ,child_program_name
                        ,child_program_id
                        ,child_request_id
                        ,from_cust_account_id
                        ,to_cust_account_id
                        ,from_run_date
                        ,to_run_date
                        ,last_updated_by
                        ,creation_date
                        ,created_by
                        ,last_update_date
                        )
                 VALUES (ln_ext_wc_s
                        ,ln_parent_cp_id
                        ,ln_parent_request_id
                        ,ln_thread_num
                        ,lc_child_prog_name
                        ,ln_child_cp_id
                        ,ln_conc_req_id
                        ,ln_from_cust_account_id
                        ,ln_to_cust_account_id
                        ,p_last_run_date
                        ,p_to_run_date
                        ,gn_user_id
                        ,SYSDATE
                        ,gn_user_id
                        ,SYSDATE
                        );

            COMMIT;
         END LOOP;

         fnd_file.put_line (fnd_file.LOG, 'After the Loop-Daily conversion(Full)');

         CLOSE lcu_cust_accts_cr;
      ELSE
         ------------------------------------------------------
         --Submit the Program for the Cash Receipts Daily Delta
         ------------------------------------------------------
         write_log (p_debug, 'Child id :' || ln_child_cp_id || ',' || 'Child Program :' || lc_child_prog_name);
         fnd_file.put_line (fnd_file.LOG, 'Daily Delta(Incremental)');
         fnd_file.put_line (fnd_file.LOG, 'Before the Loop-Daily Delta(Incremental)');

         OPEN lcu_cust_accts_cr_in (ln_threads, gd_fr_date, gd_to_date);

         LOOP
            FETCH lcu_cust_accts_cr_in
             INTO ln_from_cash_rcpt_id
                 ,ln_to_cash_rcpt_id
                 ,ln_thread_num;

            EXIT WHEN lcu_cust_accts_cr_in%NOTFOUND;
            ln_conc_req_id :=
               fnd_request.submit_request (application      => 'XXFIN'
                                          ,program          => 'XXARDCRWC'
                                          ,description      => ln_thread_num || ':'
                                          ,start_time       => SYSDATE
                                          ,sub_request      => FALSE
                                          ,argument1        => gc_fr_date
                                          ,argument2        => gc_to_date
                                          ,argument3        => ln_from_cash_rcpt_id
                                          ,argument4        => ln_to_cash_rcpt_id
                                          ,argument5        => 'N'
                                          ,argument6        => p_debug
                                          ,argument7        => ln_thread_num
                                          );

            IF ln_conc_req_id = 0
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Cash Receipt Child Program is not submitted');
               p_retcode := 2;
            ELSE
               ln_req_id (ln_idx) := ln_conc_req_id;
               ln_idx := ln_idx + 1;
            END IF;

            write_log (p_debug, 'Child Concurrent Request Id :' || ln_conc_req_id);

            INSERT INTO XX_AR_MT_WC_DETAILS
                        (mt_seq
                        ,parent_program_id
                        ,parent_request_id
                        ,thread_num
                        ,child_program_name
                        ,child_program_id
                        ,child_request_id
                        ,from_cust_account_id
                        ,to_cust_account_id
                        ,from_run_date
                        ,to_run_date
                        ,last_updated_by
                        ,creation_date
                        ,created_by
                        ,last_update_date
                        )
                 VALUES (ln_ext_wc_s
                        ,ln_parent_cp_id
                        ,ln_parent_request_id
                        ,ln_thread_num
                        ,lc_child_prog_name
                        ,ln_child_cp_id
                        ,ln_conc_req_id
                        ,ln_from_cust_account_id
                        ,ln_to_cust_account_id
                        ,gd_fr_date
                        ,gd_to_date
                        ,gn_user_id
                        ,SYSDATE
                        ,gn_user_id
                        ,SYSDATE
                        );

            COMMIT;
         END LOOP;

         fnd_file.put_line (fnd_file.LOG, 'After the Loop-Daily Delta(Incremental)');

         CLOSE lcu_cust_accts_cr_in;
      END IF;

      IF ln_req_id.COUNT > 0
      THEN
         FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
         LOOP
            IF apps.fnd_concurrent.wait_for_request (ln_req_id (i), 30, 0, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message)
            THEN
               IF UPPER (lc_status) = 'ERROR'
               THEN
                  fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed with error');
                  p_retcode := 2;
               ELSIF UPPER (lc_status) = 'WARNING'
               THEN
                  fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed with warning');
                  p_retcode := 1;
               ELSE
                  fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed normal');
               END IF;

               SELECT GREATEST (p_retcode, ln_retcode)
                 INTO ln_retcode
                 FROM DUAL;
            END IF;
         END LOOP;
      END IF;

      p_retcode := ln_retcode;

      SELECT COUNT (*)
        INTO ln_count
        FROM XX_AR_CR_WC_STG;

      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Total Records in the Cash Receipt Staging Table :' || ln_count);
      compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_CR_WC_STG');
      compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_MT_WC_DETAILS');
   EXCEPTION
      WHEN le_run_cust_first
      THEN
         lc_error_debug := 'Customer Eligibility Program should run first.';
         FND_FILE.PUT_LINE (FND_FILE.LOG, lc_error_debug);
         p_retcode := 2;
      WHEN NO_DATA_FOUND
      THEN
         lc_error_debug := ' No data found ' || 'Error' || SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, lc_error_debug);
         p_retcode := 2;
      WHEN OTHERS
      THEN
         lc_error_debug := ' Exception is raised in Cash Receipt-Multi Threading' || 'Error' || SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, lc_error_debug);
         p_retcode := 2;
   END cr_mt;

   --+=================================================================================================+
   ---Procedure for Adjustments which will submit the Full or Incremental Program using Multi threading
   --+=================================================================================================+
   PROCEDURE adj_mt (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_action_type     IN       VARCHAR2
     ,p_last_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
     ,p_debug           IN       VARCHAR2
   )
   AS
      CURSOR lcu_cust_accts_adj (
         ln_no_of_threads   IN   NUMBER
      )
      IS
         SELECT   MIN (X.cust_account_id) "from_cust_account_id"
                 ,MAX (X.cust_account_id) "to_cust_account_id"
                 ,X.thread_num
             FROM xx_crm_wcelg_cust ELG_CUST
                 , (SELECT cust_account_id
                          ,NTILE (ln_no_of_threads) OVER (ORDER BY cust_account_id ASC) AS thread_num
                      FROM xx_crm_wcelg_cust
                     WHERE adj_ext = 'N') X
            WHERE ELG_CUST.cust_account_id = X.cust_account_id
         GROUP BY X.thread_num
         ORDER BY X.thread_num;

      CURSOR lcu_cust_accts_adj_in (
         ln_no_of_threads   IN   NUMBER
        ,p_from_date        IN   DATE
        ,p_to_date          IN   DATE
      )
      IS
         SELECT   MIN (X.adjustment_id)
                 ,MAX (X.adjustment_id)
                 ,X.thread_num
             FROM SYS.DUAL
                 , (SELECT adj.adjustment_id
                          ,NTILE (ln_no_of_threads) OVER (ORDER BY adj.adjustment_id ASC) AS thread_num
                      FROM XX_CRM_WCELG_CUST XC
                          ,ra_customer_trx_all RCT
                          ,ar_adjustments_all ADJ
                     WHERE ADJ.last_update_date BETWEEN p_from_date AND p_to_date
                       AND RCT.bill_to_customer_id = XC.cust_account_id
                       AND ADJ.customer_trx_id = RCT.customer_trx_id) X
         GROUP BY X.thread_num
         ORDER BY X.thread_num;

      ln_parent_cp_id           NUMBER;
      ln_parent_request_id      NUMBER                                                         := fnd_global.conc_request_id;
      ln_child_cp_id            NUMBER;
      lc_child_prog_name        fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
      ln_conc_req_id            NUMBER;
      ln_ext_wc_s               NUMBER;
      ln_threads                NUMBER;
      lc_dev_phase              fnd_lookup_values.meaning%TYPE;
      lc_dev_status             fnd_lookup_values.meaning%TYPE;
      lc_phase                  fnd_lookup_values.meaning%TYPE;
      lc_status                 fnd_lookup_values.meaning%TYPE;
      lc_message                VARCHAR2 (2000);
      lc_error_debug            VARCHAR2 (1000);
      ln_from_cust_account_id   hz_cust_accounts.cust_account_id%TYPE;
      ln_to_cust_account_id     hz_cust_accounts.cust_account_id%TYPE;
      ln_from_adj_id            ar_adjustments_all.adjustment_id%TYPE;
      ln_to_adj_id              ar_adjustments_all.adjustment_id%TYPE;
      ln_thread_num             NUMBER;
      ln_no_of_threads          NUMBER;
      ln_req_id                 req_id;
      ln_idx                    NUMBER                                                         := 1;
      lc_compute_stats          VARCHAR2 (1);
      lc_debug_flag             VARCHAR2 (1);
      ld_from_date              DATE;
      ld_to_date                DATE;
      ld_last_run_date          DATE;
      lc_last_run_date          VARCHAR2 (20);
      ln_retcode                NUMBER                                                         := 0;
      ln_count                  NUMBER                                                         := 0;
      ROWCOUNT                  NUMBER;
      le_run_cust_first         EXCEPTION;
   BEGIN
      get_date_range;

      IF gn_ret_code > 0
      THEN
         RAISE le_run_cust_first;
      END IF;

      FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************ENTERED PARAMETERS FOR ADJUSTMENTS**********************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Action Type        :' || p_action_type);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Last Run Date      :' || p_last_run_date);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Last To Date       :' || p_to_run_date);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Compute Statistics :' || p_compute_stats);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag         :' || p_debug);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************************************************************');
      FND_GLOBAL.APPS_INITIALIZE (gn_user_id, gn_resp_id, gn_appl_id);

      SELECT XX_AR_MT_WC_S.NEXTVAL
        INTO ln_ext_wc_s
        FROM DUAL;

      BEGIN
         SELECT concurrent_program_id
           INTO ln_parent_cp_id
           FROM fnd_concurrent_requests fcr
          WHERE fcr.request_id = ln_parent_request_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG, 'Parent id ' || ln_parent_cp_id);
            ln_parent_cp_id := NULL;
      END;

      write_log (p_debug, 'Parent Request ID :' || ln_parent_request_id || ',' || 'Parent Concurrent Program ID :' || ln_parent_cp_id);

      BEGIN
         SELECT xftv.target_value3
               ,xftv.target_value6
           INTO ln_threads
               ,lc_compute_stats
           FROM xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
          WHERE XFTV.translate_id = XFTD.translate_id
            AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND XFTV.source_value1 = 'AR_ADJUSTMENTS'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line (fnd_file.LOG, 'For Transalation Definition is not defined for AR_ADJUSTMENTS');
      END;

      FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************DERIVED PARAMETERS*******************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parent Request ID    :' || ln_parent_request_id);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parent Concurrent ID :' || ln_parent_cp_id);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Threads              :' || ln_threads);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Compute Statistics   :' || lc_compute_stats);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************');
      write_log (p_debug, 'No. of Threads :' || ln_threads || ' Compute Stats :' || lc_compute_stats);

      IF p_debug IS NOT NULL
      THEN
         lc_debug_flag := p_debug;
      END IF;

      IF p_compute_stats IS NOT NULL
      THEN
         lc_compute_stats := p_compute_stats;
      END IF;

      ----------------------------------------------------------
      --Submit the Program for the Adjustments  Daily Conversion
      ----------------------------------------------------------
      IF p_action_type = 'F'
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Daily conversion(Full)');

         EXECUTE IMMEDIATE 'TRUNCATE TABLE  xxfin.xx_ar_adj_wc_stg';

         BEGIN
            SELECT fcp.concurrent_program_id
                  ,fcp.user_concurrent_program_name
              INTO ln_child_cp_id
                  ,lc_child_prog_name
              FROM fnd_concurrent_programs_vl fcp
             WHERE fcp.concurrent_program_name = 'XXARFADJWC';
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Child id :' || ln_child_cp_id || ',' || 'Child Program :' || lc_child_prog_name);
               ln_child_cp_id := 0;
         END;

         write_log (p_debug, 'Child id :' || ln_child_cp_id || ',' || 'Child Program :' || lc_child_prog_name);
         fnd_file.put_line (fnd_file.LOG, 'Before the Loop-Daily conversion(Full)');

         OPEN lcu_cust_accts_adj (10);

         LOOP
            FETCH lcu_cust_accts_adj
             INTO ln_from_cust_account_id
                 ,ln_to_cust_account_id
                 ,ln_thread_num;

            EXIT WHEN lcu_cust_accts_adj%NOTFOUND;
            ln_conc_req_id :=
               fnd_request.submit_request (application      => 'XXFIN'
                                          ,program          => 'XXARFADJWC'
                                          ,description      => ln_thread_num || ':'
                                          ,start_time       => SYSDATE
                                          ,sub_request      => FALSE
                                          ,argument1        => ln_from_cust_account_id
                                          ,argument2        => ln_to_cust_account_id
                                          ,argument3        => 'N'
                                          ,argument4        => p_debug
                                          ,argument5        => ln_thread_num
                                          );
            fnd_file.put_line (fnd_file.LOG, ln_from_cust_account_id || '-' || ln_to_cust_account_id || '-' || ln_thread_num);

            IF ln_conc_req_id = 0
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Adjustment Child Program is not submitted');
               p_retcode := 2;
            ELSE
               ln_req_id (ln_idx) := ln_conc_req_id;
               ln_idx := ln_idx + 1;
            END IF;

            write_log (p_debug, 'Child Concurrent Request Id :' || ln_conc_req_id);

            INSERT INTO XX_AR_MT_WC_DETAILS
                        (mt_seq
                        ,parent_program_id
                        ,parent_request_id
                        ,thread_num
                        ,child_program_name
                        ,child_program_id
                        ,child_request_id
                        ,from_cust_account_id
                        ,to_cust_account_id
                        ,from_run_date
                        ,to_run_date
                        ,last_updated_by
                        ,creation_date
                        ,created_by
                        ,last_update_date
                        )
                 VALUES (ln_ext_wc_s
                        ,ln_parent_cp_id
                        ,ln_parent_request_id
                        ,ln_thread_num
                        ,lc_child_prog_name
                        ,ln_child_cp_id
                        ,ln_conc_req_id
                        ,ln_from_cust_account_id
                        ,ln_to_cust_account_id
                        ,p_last_run_date
                        ,p_to_run_date
                        ,gn_user_id
                        ,SYSDATE
                        ,gn_user_id
                        ,SYSDATE
                        );

            COMMIT;
         END LOOP;

         fnd_file.put_line (fnd_file.LOG, 'After the Loop-Daily conversion(Full)');

         CLOSE lcu_cust_accts_adj;
      ELSE
         ----------------------------------------------------
         --Submit the Program for the Adjustments Daily Delta
         ----------------------------------------------------
         write_log (p_debug, 'Child id :' || ln_child_cp_id || ',' || 'Child Program :' || lc_child_prog_name);
         fnd_file.put_line (fnd_file.LOG, 'Daily Delta(Incremental)');
         fnd_file.put_line (fnd_file.LOG, 'Before the Loop-Daily Delta(Incremental)');

         OPEN lcu_cust_accts_adj_in (ln_threads, gd_fr_date, gd_to_date);

         LOOP
            FETCH lcu_cust_accts_adj_in
             INTO ln_from_adj_id
                 ,ln_to_adj_id
                 ,ln_thread_num;

            EXIT WHEN lcu_cust_accts_adj_in%NOTFOUND;
            ln_conc_req_id :=
               fnd_request.submit_request (application      => 'XXFIN'
                                          ,program          => 'XXARDADJWC'
                                          ,description      => ln_thread_num || ':'
                                          ,start_time       => SYSDATE
                                          ,sub_request      => FALSE
                                          ,argument1        => gc_fr_date
                                          ,argument2        => gc_to_date
                                          ,argument3        => ln_from_adj_id
                                          ,argument4        => ln_to_adj_id
                                          ,argument5        => 'N'
                                          ,argument6        => p_debug
                                          ,argument7        => ln_thread_num
                                          );

            IF ln_conc_req_id = 0
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Adjustment Child Program is not submitted');
               p_retcode := 2;
            ELSE
               ln_req_id (ln_idx) := ln_conc_req_id;
               ln_idx := ln_idx + 1;
            END IF;

            write_log (p_debug, 'Child Concurrent Request Id :' || ln_conc_req_id);

            INSERT INTO XX_AR_MT_WC_DETAILS
                        (mt_seq
                        ,parent_program_id
                        ,parent_request_id
                        ,thread_num
                        ,child_program_name
                        ,child_program_id
                        ,child_request_id
                        ,from_cust_account_id
                        ,to_cust_account_id
                        ,from_run_date
                        ,to_run_date
                        ,last_updated_by
                        ,creation_date
                        ,created_by
                        ,last_update_date
                        )
                 VALUES (ln_ext_wc_s
                        ,ln_parent_cp_id
                        ,ln_parent_request_id
                        ,ln_thread_num
                        ,lc_child_prog_name
                        ,ln_child_cp_id
                        ,ln_conc_req_id
                        ,ln_from_cust_account_id
                        ,ln_to_cust_account_id
                        ,gd_fr_date
                        ,gd_to_date
                        ,gn_user_id
                        ,SYSDATE
                        ,gn_user_id
                        ,SYSDATE
                        );

            COMMIT;
         END LOOP;

         fnd_file.put_line (fnd_file.LOG, 'After the Loop-Daily Delta(Incremental)');

         CLOSE lcu_cust_accts_adj_in;
      END IF;

      IF ln_req_id.COUNT > 0
      THEN
         FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
         LOOP
            IF apps.fnd_concurrent.wait_for_request (ln_req_id (i), 30, 0, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message)
            THEN
               IF UPPER (lc_status) = 'ERROR'
               THEN
                  fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed with error');
                  p_retcode := 2;
               ELSIF UPPER (lc_status) = 'WARNING'
               THEN
                  fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed with warning');
                  p_retcode := 1;
               ELSE
                  fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed normal');
               END IF;

               SELECT GREATEST (p_retcode, ln_retcode)
                 INTO ln_retcode
                 FROM DUAL;
            END IF;
         END LOOP;
      END IF;

      p_retcode := ln_retcode;

      SELECT COUNT (*)
        INTO ln_count
        FROM XX_AR_ADJ_WC_STG;

      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Total Records in the Adjustments Staging Table :' || ln_count);
      compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_ADJ_WC_STG');
      compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_MT_WC_DETAILS');
   EXCEPTION
      WHEN le_run_cust_first
      THEN
         lc_error_debug := 'Customer Eligibility Program should run first.';
         FND_FILE.PUT_LINE (FND_FILE.LOG, lc_error_debug);
         p_retcode := 2;
      WHEN NO_DATA_FOUND
      THEN
         lc_error_debug := ' No data found ' || 'Error' || SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, lc_error_debug);
         p_retcode := 2;
      WHEN OTHERS
      THEN
         lc_error_debug := ' Exception is raised in Adjustments-Multi Threading' || 'Error' || SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, lc_error_debug);
         p_retcode := 2;
   END adj_mt;

   --+======================================================================================================+
   ---Procedure for Payment Schedules which will submit the Full or Incremental Program using Multi threading
   --+======================================================================================================+
   PROCEDURE ps_mt (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_action_type     IN       VARCHAR2
     ,p_last_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
     ,p_debug           IN       VARCHAR2
   )
   AS
      CURSOR lcu_cust_accts_ps (
         ln_no_of_threads   IN   NUMBER
      )
      IS
         SELECT   MIN (X.cust_account_id) "from_cust_account_id"
                 ,MAX (X.cust_account_id) "to_cust_account_id"
                 ,X.thread_num
             FROM xx_crm_wcelg_cust ELG_CUST
                 , (SELECT cust_account_id
                          ,NTILE (ln_no_of_threads) OVER (ORDER BY cust_account_id ASC) AS thread_num
                      FROM xx_crm_wcelg_cust
                     WHERE ps_ext = 'N') X
            WHERE ELG_CUST.cust_account_id = X.cust_account_id
         GROUP BY X.thread_num
         ORDER BY X.thread_num;

      CURSOR lcu_cust_accts_ps_in (
         ln_no_of_threads   IN   NUMBER
        ,p_from_date        IN   DATE
        ,p_to_date          IN   DATE
      )
      IS
         SELECT   MIN (X.payment_schedule_id)
                 ,MAX (X.payment_schedule_id)
                 ,X.thread_num
             FROM SYS.DUAL
                 , (SELECT ps.payment_schedule_id
                          ,NTILE (ln_no_of_threads) OVER (ORDER BY payment_schedule_id ASC) AS thread_num
                      FROM xx_crm_wcelg_cust XC
                          ,ar_payment_schedules_all PS
                     WHERE ps.last_update_date BETWEEN p_from_date AND p_to_date AND xc.cust_account_id = ps.customer_id) X
         GROUP BY X.thread_num
         ORDER BY X.thread_num;

      ln_parent_cp_id           NUMBER;
      ln_parent_request_id      NUMBER                                                         := fnd_global.conc_request_id;
      ln_child_cp_id            NUMBER;
      lc_child_prog_name        fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
      ln_conc_req_id            NUMBER;
      ln_ext_wc_s               NUMBER;
      ln_threads                NUMBER;
      lc_dev_phase              fnd_lookup_values.meaning%TYPE;
      lc_dev_status             fnd_lookup_values.meaning%TYPE;
      lc_phase                  fnd_lookup_values.meaning%TYPE;
      lc_status                 fnd_lookup_values.meaning%TYPE;
      lc_message                VARCHAR2 (2000);
      lc_error_debug            VARCHAR2 (1000);
      ln_from_cust_account_id   hz_cust_accounts.cust_account_id%TYPE;
      ln_to_cust_account_id     hz_cust_accounts.cust_account_id%TYPE;
      ln_from_ps_id             ar_payment_schedules_all.payment_schedule_id%TYPE;
      ln_to_ps_id               ar_payment_schedules_all.payment_schedule_id%TYPE;
      ln_thread_num             NUMBER;
      ln_no_of_threads          NUMBER;
      ln_req_id                 req_id;
      ln_idx                    NUMBER                                                         := 1;
      lc_compute_stats          VARCHAR2 (1);
      lc_debug_flag             VARCHAR2 (1);
      ld_from_date              DATE;
      ld_to_date                DATE;
      ld_last_run_date          DATE;
      lc_last_run_date          VARCHAR2 (20);
      ln_retcode                NUMBER                                                         := 0;
      ln_count                  NUMBER                                                         := 0;
      le_run_cust_first         EXCEPTION;
   BEGIN
      get_date_range;

      IF gn_ret_code > 0
      THEN
         RAISE le_run_cust_first;
      END IF;

      FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************ENTERED PARAMETERS FOR PAYMENT SCHEDULES*****************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Action Type        :' || p_action_type);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Last Run Date      :' || p_last_run_date);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Last To Date       :' || p_to_run_date);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Compute Statistics :' || p_compute_stats);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag         :' || p_debug);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************************************************************');
      FND_GLOBAL.APPS_INITIALIZE (gn_user_id, gn_resp_id, gn_appl_id);

      SELECT XX_AR_MT_WC_S.NEXTVAL
        INTO ln_ext_wc_s
        FROM DUAL;

      BEGIN
         SELECT concurrent_program_id
           INTO ln_parent_cp_id
           FROM fnd_concurrent_requests fcr
          WHERE fcr.request_id = ln_parent_request_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG, 'Parent id ' || ln_parent_cp_id);
            ln_parent_cp_id := NULL;
      END;

      write_log (p_debug, 'Parent Request ID :' || ln_parent_request_id || ',' || 'Parent Concurrent Program ID :' || ln_parent_cp_id);

      BEGIN
         SELECT xftv.target_value3
               ,xftv.target_value6
           INTO ln_threads
               ,lc_compute_stats
           FROM xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
          WHERE XFTV.translate_id = XFTD.translate_id
            AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND XFTV.source_value1 = 'AR_PAYMENT_SCHEDULE'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line (fnd_file.LOG, 'For Transalation Definition is not defined for AR_PAYMENT_SCHEDULE');
      END;

      FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************DERIVED PARAMETERS*******************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parent Request ID    :' || ln_parent_request_id);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parent Concurrent ID :' || ln_parent_cp_id);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Threads              :' || ln_threads);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Compute Statistics   :' || lc_compute_stats);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************');
      write_log (p_debug, 'No. of Threads :' || ln_threads || ' Compute Stats :' || lc_compute_stats);

      IF p_debug IS NOT NULL
      THEN
         lc_debug_flag := p_debug;
      END IF;

      IF p_compute_stats IS NOT NULL
      THEN
         lc_compute_stats := p_compute_stats;
      END IF;

      ---------------------------------------------------------------
      --Submit the Program for the Payment Schedules Daily Conversion
      ---------------------------------------------------------------
      IF p_action_type = 'F'
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Daily conversion(Full)');

         EXECUTE IMMEDIATE 'TRUNCATE TABLE  xxfin.xx_ar_ps_wc_stg';

         BEGIN
            SELECT fcp.concurrent_program_id
                  ,fcp.user_concurrent_program_name
              INTO ln_child_cp_id
                  ,lc_child_prog_name
              FROM fnd_concurrent_programs_vl fcp
             WHERE fcp.concurrent_program_name = 'XXARFPSWC';
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Child id :' || ln_child_cp_id || ',' || 'Child Program :' || lc_child_prog_name);
               ln_child_cp_id := 0;
         END;

         write_log (p_debug, 'Child id :' || ln_child_cp_id || ',' || 'Child Program :' || lc_child_prog_name);
         fnd_file.put_line (fnd_file.LOG, 'Before the Loop-Daily conversion(Full)');

         OPEN lcu_cust_accts_ps (ln_threads);

         LOOP
            FETCH lcu_cust_accts_ps
             INTO ln_from_cust_account_id
                 ,ln_to_cust_account_id
                 ,ln_thread_num;

            EXIT WHEN lcu_cust_accts_ps%NOTFOUND;
            ln_conc_req_id :=
               fnd_request.submit_request (application      => 'XXFIN'
                                          ,program          => 'XXARFPSWC'
                                          ,description      => ln_thread_num || ':'
                                          ,start_time       => SYSDATE
                                          ,sub_request      => FALSE
                                          ,argument1        => ln_from_cust_account_id
                                          ,argument2        => ln_to_cust_account_id
                                          ,argument3        => 'N'
                                          ,argument4        => p_debug
                                          ,argument5        => ln_thread_num
                                          );

            IF ln_conc_req_id = 0
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Payment Schedule Child Program is not submitted');
               p_retcode := 2;
            ELSE
               ln_req_id (ln_idx) := ln_conc_req_id;
               ln_idx := ln_idx + 1;
            END IF;

            write_log (p_debug, 'Child Concurrent Request Id :' || ln_conc_req_id);

            INSERT INTO XX_AR_MT_WC_DETAILS
                        (mt_seq
                        ,parent_program_id
                        ,parent_request_id
                        ,thread_num
                        ,child_program_name
                        ,child_program_id
                        ,child_request_id
                        ,from_cust_account_id
                        ,to_cust_account_id
                        ,from_run_date
                        ,to_run_date
                        ,last_updated_by
                        ,creation_date
                        ,created_by
                        ,last_update_date
                        )
                 VALUES (ln_ext_wc_s
                        ,ln_parent_cp_id
                        ,ln_parent_request_id
                        ,ln_thread_num
                        ,lc_child_prog_name
                        ,ln_child_cp_id
                        ,ln_conc_req_id
                        ,ln_from_cust_account_id
                        ,ln_to_cust_account_id
                        ,p_last_run_date
                        ,p_to_run_date
                        ,gn_user_id
                        ,SYSDATE
                        ,gn_user_id
                        ,SYSDATE
                        );

            COMMIT;
         END LOOP;

         fnd_file.put_line (fnd_file.LOG, 'After the Loop-Daily conversion(Full)');

         CLOSE lcu_cust_accts_ps;
      ELSE
         ----------------------------------------------------------
         --Submit the Program for the Payment Schedules Daily Delta
         ----------------------------------------------------------
         write_log (p_debug, 'Child id :' || ln_child_cp_id || ',' || 'Child Program :' || lc_child_prog_name);
         fnd_file.put_line (fnd_file.LOG, 'Daily Delta(Incremental)');
         fnd_file.put_line (fnd_file.LOG, 'Before the Loop-Daily Delta(Incremental)');

         OPEN lcu_cust_accts_ps_in (ln_threads, gd_fr_date, gd_to_date);

         LOOP
            FETCH lcu_cust_accts_ps_in
             INTO ln_from_ps_id
                 ,ln_to_ps_id
                 ,ln_thread_num;

            EXIT WHEN lcu_cust_accts_ps_in%NOTFOUND;
            ln_conc_req_id :=
               fnd_request.submit_request (application      => 'XXFIN'
                                          ,program          => 'XXARDPSWC'
                                          ,description      => ln_thread_num || ':'
                                          ,start_time       => SYSDATE
                                          ,sub_request      => FALSE
                                          ,argument1        => gc_fr_date
                                          ,argument2        => gc_to_date
                                          ,argument3        => ln_from_ps_id
                                          ,argument4        => ln_to_ps_id
                                          ,argument5        => 'N'
                                          ,argument6        => p_debug
                                          ,argument7        => ln_thread_num
                                          );

            IF ln_conc_req_id = 0
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Payment Schedule Child Program is not submitted');
               p_retcode := 2;
            ELSE
               ln_req_id (ln_idx) := ln_conc_req_id;
               ln_idx := ln_idx + 1;
            END IF;

            write_log (p_debug, 'Child Concurrent Request Id :' || ln_conc_req_id);

            INSERT INTO XX_AR_MT_WC_DETAILS
                        (mt_seq
                        ,parent_program_id
                        ,parent_request_id
                        ,thread_num
                        ,child_program_name
                        ,child_program_id
                        ,child_request_id
                        ,from_cust_account_id
                        ,to_cust_account_id
                        ,from_run_date
                        ,to_run_date
                        ,last_updated_by
                        ,creation_date
                        ,created_by
                        ,last_update_date
                        )
                 VALUES (ln_ext_wc_s
                        ,ln_parent_cp_id
                        ,ln_parent_request_id
                        ,ln_thread_num
                        ,lc_child_prog_name
                        ,ln_child_cp_id
                        ,ln_conc_req_id
                        ,ln_from_cust_account_id
                        ,ln_to_cust_account_id
                        ,gd_fr_date
                        ,gd_to_date
                        ,gn_user_id
                        ,SYSDATE
                        ,gn_user_id
                        ,SYSDATE
                        );

            COMMIT;
         END LOOP;

         fnd_file.put_line (fnd_file.LOG, 'After the Loop-Daily Delta(Incremental)');

         CLOSE lcu_cust_accts_ps_in;
      END IF;

      IF ln_req_id.COUNT > 0
      THEN
         FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
         LOOP
            IF apps.fnd_concurrent.wait_for_request (ln_req_id (i), 30, 0, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message)
            THEN
               IF UPPER (lc_status) = 'ERROR'
               THEN
                  fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed with error');
                  p_retcode := 2;
               ELSIF UPPER (lc_status) = 'WARNING'
               THEN
                  fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed with warning');
                  p_retcode := 1;
               ELSE
                  fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed normal');
               END IF;

               SELECT GREATEST (p_retcode, ln_retcode)
                 INTO ln_retcode
                 FROM DUAL;
            END IF;
         END LOOP;
      END IF;

      p_retcode := ln_retcode;

      SELECT COUNT (*)
        INTO ln_count
        FROM XX_AR_PS_WC_STG;

      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Total Records in the Payment Schedule Staging Table :' || ln_count);
      compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_PS_WC_STG');
      compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_MT_WC_DETAILS');
   EXCEPTION
      WHEN le_run_cust_first
      THEN
         lc_error_debug := 'Customer Eligibility Program should run first.';
         FND_FILE.PUT_LINE (FND_FILE.LOG, lc_error_debug);
         p_retcode := 2;
      WHEN NO_DATA_FOUND
      THEN
         lc_error_debug := ' No data found ' || 'Error' || SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, lc_error_debug);
         p_retcode := 2;
      WHEN OTHERS
      THEN
         lc_error_debug := ' Exception is raised in Payment Schedules-Multi Threading' || 'Error' || SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, lc_error_debug);
         p_retcode := 2;
   END ps_mt;

   --+=============================================================================================================+
   ---Procedure for Receivable Applications which will submit the Full or Incremental Program using Multi threading
   --+=============================================================================================================+
   PROCEDURE recappl_mt (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_action_type     IN       VARCHAR2
     ,p_last_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
     ,p_debug           IN       VARCHAR2
   )
   AS
      CURSOR lcu_cust_accts_ra (
         ln_no_of_threads   IN   NUMBER
      )
      IS
         SELECT   MIN (X.cust_account_id) "from_cust_account_id"
                 ,MAX (X.cust_account_id) "to_cust_account_id"
                 ,X.thread_num
             FROM xx_crm_wcelg_cust ELG_CUST
                 , (SELECT cust_account_id
                          ,NTILE (ln_no_of_threads) OVER (ORDER BY cust_account_id ASC) AS thread_num
                      FROM xx_crm_wcelg_cust
                     WHERE rec_app_ext = 'N') X
            WHERE ELG_CUST.cust_account_id = X.cust_account_id
         GROUP BY X.thread_num
         ORDER BY X.thread_num;

      CURSOR lcu_cust_accts_ra_in (
         ln_no_of_threads   IN   NUMBER
        ,p_from_date        IN   DATE
        ,p_to_date          IN   DATE
      )
      IS
          SELECT   MIN (X.receivable_application_id)
	                  ,MAX (X.receivable_application_id)
	                  ,X.thread_num
	              FROM SYS.DUAL
	                  , (SELECT receivable_application_id
	                           ,NTILE (ln_no_of_threads) OVER (ORDER BY receivable_application_id ASC) AS thread_num
	                       FROM XX_CRM_WCELG_CUST XC
	                           ,ar_payment_schedules_all PS
	                           ,ar_receivable_applications_all RA
	                      WHERE RA.last_update_date BETWEEN p_from_date AND p_to_date
	                        AND XC.cust_account_id = PS.customer_id
	                        AND PS.payment_schedule_id = RA.payment_schedule_id) X
	          GROUP BY X.thread_num
         ORDER BY X.thread_num;

      ln_parent_cp_id           NUMBER;
      ln_parent_request_id      NUMBER                                                          := fnd_global.conc_request_id;
      ln_child_cp_id            NUMBER;
      lc_child_prog_name        fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
      ln_conc_req_id            NUMBER;
      ln_ext_wc_s               NUMBER;
      ln_threads                NUMBER;
      lc_dev_phase              fnd_lookup_values.meaning%TYPE;
      lc_dev_status             fnd_lookup_values.meaning%TYPE;
      lc_phase                  fnd_lookup_values.meaning%TYPE;
      lc_status                 fnd_lookup_values.meaning%TYPE;
      lc_message                VARCHAR2 (2000);
      lc_error_debug            VARCHAR2 (1000);
      ln_from_cust_account_id   hz_cust_accounts.cust_account_id%TYPE;
      ln_to_cust_account_id     hz_cust_accounts.cust_account_id%TYPE;
      ln_from_recappl_id        ar_receivable_applications_all.receivable_application_id%TYPE;
      ln_to_recappl_id          ar_receivable_applications_all.receivable_application_id%TYPE;
      ln_thread_num             NUMBER;
      ln_no_of_threads          NUMBER;
      ln_req_id                 req_id;
      ln_idx                    NUMBER                                                          := 1;
      lc_compute_stats          VARCHAR2 (1);
      lc_debug_flag             VARCHAR2 (1);
      ld_from_date              DATE;
      ld_to_date                DATE;
      ld_last_run_date          DATE;
      lc_last_run_date          VARCHAR2 (20);
      ln_retcode                NUMBER                                                          := 0;
      ln_count                  NUMBER                                                          := 0;
      le_run_cust_first         EXCEPTION;
   BEGIN
      get_date_range;

      IF gn_ret_code > 0
      THEN
         RAISE le_run_cust_first;
      END IF;

      FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************ENTERED PARAMETERS FOR REC APPLICATIONS*****************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Action Type        :' || p_action_type);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Last Run Date      :' || p_last_run_date);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Last To Date       :' || p_to_run_date);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Compute Statistics :' || p_compute_stats);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag         :' || p_debug);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************************************************************');
      FND_GLOBAL.APPS_INITIALIZE (gn_user_id, gn_resp_id, gn_appl_id);

      SELECT XX_AR_MT_WC_S.NEXTVAL
        INTO ln_ext_wc_s
        FROM DUAL;

      BEGIN
         SELECT concurrent_program_id
           INTO ln_parent_cp_id
           FROM fnd_concurrent_requests fcr
          WHERE fcr.request_id = ln_parent_request_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG, 'Parent id ' || ln_parent_cp_id);
            ln_parent_cp_id := NULL;
      END;

      write_log (p_debug, 'Parent Request ID :' || ln_parent_request_id || ',' || 'Parent Concurrent Program ID :' || ln_parent_cp_id);

      BEGIN
         SELECT xftv.target_value3
               ,xftv.target_value6
           INTO ln_threads
               ,lc_compute_stats
           FROM xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
          WHERE XFTV.translate_id = XFTD.translate_id
            AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND XFTV.source_value1 = 'AR_RECEIVABLE_APP'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line (fnd_file.LOG, 'For Transalation Definition is not defined for AR_RECEIVABLE_APP');
      END;

      FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************DERIVED PARAMETERS*******************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parent Request ID    :' || ln_parent_request_id);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parent Concurrent ID :' || ln_parent_cp_id);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Threads              :' || ln_threads);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Compute Statistics   :' || lc_compute_stats);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************');
      write_log (p_debug, 'No. of Threads :' || ln_threads || ' Compute Stats :' || lc_compute_stats);

      IF p_debug IS NOT NULL
      THEN
         lc_debug_flag := p_debug;
      END IF;

      IF p_compute_stats IS NOT NULL
      THEN
         lc_compute_stats := p_compute_stats;
      END IF;

      --------------------------------------------------------------------
      --Submit the Program for the Receivable Applications Daily Conversion
      ----------------------------------------------------------------------
      IF p_action_type = 'F'
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Daily conversion(Full)');

         EXECUTE IMMEDIATE 'TRUNCATE TABLE  xxfin.xx_ar_recappl_wc_stg';

         BEGIN
            SELECT fcp.concurrent_program_id
                  ,fcp.user_concurrent_program_name
              INTO ln_child_cp_id
                  ,lc_child_prog_name
              FROM fnd_concurrent_programs_vl fcp
             WHERE fcp.concurrent_program_name = 'XXARFRAWC';
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Child id :' || ln_child_cp_id || ',' || 'Child Program :' || lc_child_prog_name);
               ln_child_cp_id := 0;
         END;

         write_log (p_debug, 'Child id :' || ln_child_cp_id || ',' || 'Child Program :' || lc_child_prog_name);
         fnd_file.put_line (fnd_file.LOG, 'Before the Loop-Daily conversion(Full)');

         OPEN lcu_cust_accts_ra (ln_threads);

         LOOP
            FETCH lcu_cust_accts_ra
             INTO ln_from_cust_account_id
                 ,ln_to_cust_account_id
                 ,ln_thread_num;

            EXIT WHEN lcu_cust_accts_ra%NOTFOUND;
            ln_conc_req_id :=
               fnd_request.submit_request (application      => 'XXFIN'
                                          ,program          => 'XXARFRAWC'
                                          ,description      => ln_thread_num || ':'
                                          ,start_time       => SYSDATE
                                          ,sub_request      => FALSE
                                          ,argument1        => ln_from_cust_account_id
                                          ,argument2        => ln_to_cust_account_id
                                          ,argument3        => 'N'
                                          ,argument4        => p_debug
                                          ,argument5        => ln_thread_num
                                          );

            IF ln_conc_req_id = 0
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Rec Applications Child Program is not submitted');
               p_retcode := 2;
            ELSE
               ln_req_id (ln_idx) := ln_conc_req_id;
               ln_idx := ln_idx + 1;
            END IF;

            write_log (p_debug, 'Child Concurrent Request Id :' || ln_conc_req_id);

            INSERT INTO XX_AR_MT_WC_DETAILS
                        (mt_seq
                        ,parent_program_id
                        ,parent_request_id
                        ,thread_num
                        ,child_program_name
                        ,child_program_id
                        ,child_request_id
                        ,from_cust_account_id
                        ,to_cust_account_id
                        ,from_run_date
                        ,to_run_date
                        ,last_updated_by
                        ,creation_date
                        ,created_by
                        ,last_update_date
                        )
                 VALUES (ln_ext_wc_s
                        ,ln_parent_cp_id
                        ,ln_parent_request_id
                        ,ln_thread_num
                        ,lc_child_prog_name
                        ,ln_child_cp_id
                        ,ln_conc_req_id
                        ,ln_from_cust_account_id
                        ,ln_to_cust_account_id
                        ,p_last_run_date
                        ,p_to_run_date
                        ,gn_user_id
                        ,SYSDATE
                        ,gn_user_id
                        ,SYSDATE
                        );

            COMMIT;
         END LOOP;

         fnd_file.put_line (fnd_file.LOG, 'After the Loop-Daily conversion(Full)');

         CLOSE lcu_cust_accts_ra;
      ELSE
         --------------------------------------------------------------------
         --Submit the Program for the Receivable Applications Daily Delta
         ----------------------------------------------------------------------
         BEGIN
            SELECT fcp.concurrent_program_id
                  ,fcp.user_concurrent_program_name
              INTO ln_child_cp_id
                  ,lc_child_prog_name
              FROM fnd_concurrent_programs_vl fcp
             WHERE fcp.concurrent_program_name = 'XXARDRAWC';
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Child id :' || ln_child_cp_id || ',' || 'Child Program :' || lc_child_prog_name);
               ln_child_cp_id := 0;
         END;

         write_log (p_debug, 'Child id :' || ln_child_cp_id || ',' || 'Child Program :' || lc_child_prog_name);
         fnd_file.put_line (fnd_file.LOG, 'Daily Delta(Incremental)');
         fnd_file.put_line (fnd_file.LOG, 'Before the Loop-Daily Delta(Incremental)');

         OPEN lcu_cust_accts_ra_in (ln_threads, gd_fr_date, gd_to_date);

         LOOP
            FETCH lcu_cust_accts_ra_in
             INTO ln_from_recappl_id
                 ,ln_to_recappl_id
                 ,ln_thread_num;

            EXIT WHEN lcu_cust_accts_ra_in%NOTFOUND;
            ln_conc_req_id :=	
               fnd_request.submit_request (application      => 'XXFIN'
                                          ,program          => 'XXARDRAWC'
                                          ,description      => ln_thread_num || ':'
                                          ,start_time       => SYSDATE
                                          ,sub_request      => FALSE
                                          ,argument1        => gc_fr_date
                                          ,argument2        => gc_to_date
                                          ,argument3        => ln_from_recappl_id
                                          ,argument4        => ln_to_recappl_id
                                          ,argument5        => 'N'
                                          ,argument6        => p_debug
                                          ,argument7        => ln_thread_num
                                          );

            IF ln_conc_req_id = 0
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Rec Applications Child Program is not submitted');
               p_retcode := 2;
            ELSE
               ln_req_id (ln_idx) := ln_conc_req_id;
               ln_idx := ln_idx + 1;
            END IF;

            write_log (p_debug, 'Child Concurrent Request Id :' || ln_conc_req_id);

            INSERT INTO XX_AR_MT_WC_DETAILS
                        (mt_seq
                        ,parent_program_id
                        ,parent_request_id
                        ,thread_num
                        ,child_program_name
                        ,child_program_id
                        ,child_request_id
                        ,from_cust_account_id
                        ,to_cust_account_id
                        ,from_run_date
                        ,to_run_date
                        ,last_updated_by
                        ,creation_date
                        ,created_by
                        ,last_update_date
                        )
                 VALUES (ln_ext_wc_s
                        ,ln_parent_cp_id
                        ,ln_parent_request_id
                        ,ln_thread_num
                        ,lc_child_prog_name
                        ,ln_child_cp_id
                        ,ln_conc_req_id
                        ,ln_from_cust_account_id
                        ,ln_to_cust_account_id
                        ,gd_fr_date
                        ,gd_to_date
                        ,gn_user_id
                        ,SYSDATE
                        ,gn_user_id
                        ,SYSDATE
                        );

            COMMIT;
         END LOOP;

         fnd_file.put_line (fnd_file.LOG, 'After the Loop-Daily Delta(Incremental)');

         CLOSE lcu_cust_accts_ra_in;
      END IF;

      IF ln_req_id.COUNT > 0
      THEN
         FOR i IN ln_req_id.FIRST .. ln_req_id.LAST
         LOOP
            IF apps.fnd_concurrent.wait_for_request (ln_req_id (i), 30, 0, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message)
            THEN
               IF UPPER (lc_status) = 'ERROR'
               THEN
                  fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed with error');
                  p_retcode := 2;
               ELSIF UPPER (lc_status) = 'WARNING'
               THEN
                  fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed with warning');
                  p_retcode := 1;
               ELSE
                  fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed normal');
               END IF;

               SELECT GREATEST (p_retcode, ln_retcode)
                 INTO ln_retcode
                 FROM DUAL;
            END IF;
         END LOOP;
      END IF;

      p_retcode := ln_retcode;

      SELECT COUNT (*)
        INTO ln_count
        FROM XX_AR_RECAPPL_WC_STG;

      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Total Records in the Receivable Applications Staging Table :' || ln_count);
      compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_RECAPPL_WC_STG');
      compute_stat (p_compute_stats, 'XXFIN', 'XX_AR_MT_WC_DETAILS');
   EXCEPTION
      WHEN le_run_cust_first
      THEN
         lc_error_debug := 'Customer Eligibility Program should run first.';
         FND_FILE.PUT_LINE (FND_FILE.LOG, lc_error_debug);
         p_retcode := 2;
      WHEN NO_DATA_FOUND
      THEN
         lc_error_debug := ' No data found ' || 'Error' || SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, lc_error_debug);
         p_retcode := 2;
      WHEN OTHERS
      THEN
         lc_error_debug := ' Exception is raised in Receivable Applications-Multi Threading' || 'Error' || SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, lc_error_debug);
         p_retcode := 2;
   END recappl_mt;
END XX_AR_MT_WC_PKG;
/

SHOW ERRORS
