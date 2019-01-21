create or replace PACKAGE BODY XX_AR_WC_MASTER_PKG
AS
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                        Office Depot Organization                          |
-- +===========================================================================+
-- | Name         : XX_AR_WC_MASTER_PKG                                        |
-- |                                                                           |
-- | RICE#        : I2158                                                      |
-- |                                                                           |
-- | Description  : This package will call the AR Extract child program        |
-- |                after determine the appropriate range of values            |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date         Author                   Remarks                     |
-- |=======  ===========  ======================  =============================|
-- |  1.0    15-Dec-2011  Rick Aldridge           Initial version              |
-- |                                                                           |
-- |  1.1    16-Jan-2012  Akhilesh                Change in master_ext         |
-- |                                              procedure                    |
-- |                                              for defect# 16264            |
-- |                                                                           |
-- |  1.2    17-Jan-2012  Akhilesh                Change in master_ext         | 
-- |                                              procedure                    |
-- |                                              for defect# 16326 Master     |
-- |                                              Program                      |
-- |                                              Re-submitted Completed Child |
-- |                                                                           |
-- |  1.3    18-Jan-2012  R.Aldridge              Defect 16231 - Modify/tune   |
-- |                                              cursors:                     |
-- |                                                                           |
-- |  1.4    02-Feb-2012  R.Aldridge              Defect# 16230 - Tuning for   |
-- |                                              full DAILY conversions       |
-- |                                              Defect# 16231 - Tuning for   |
-- |                                              daily DELTA                  |
-- |                                                                           |
-- +===========================================================================+

   -- global variables declaration
   gn_ret_code                NUMBER             := 0;
   gc_error_loc               VARCHAR2(2000)     := NULL;
   gc_req_data                VARCHAR2(240)      := NULL;
   gb_print_option            BOOLEAN            := FALSE;

   gc_reprocess_cnt           NUMBER;
   gn_parent_request_id       NUMBER(15)         := FND_GLOBAL.CONC_REQUEST_ID;
   gn_parent_cp_id            NUMBER;
   gn_child_cp_id             NUMBER;
   gc_child_prog_name         fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
   gn_ext_wc_s                NUMBER;

   -- Global Constants
   GC_YES                     VARCHAR2(1)         := 'Y';

   -- Variables for Interface Settings
   gn_limit                   NUMBER;
   gn_threads_delta           NUMBER;
   gn_threads_full            NUMBER;
   gn_threads_file            NUMBER;
   gc_conc_short_delta        xx_fin_translatevalues.target_value16%TYPE;
   gc_conc_short_full         xx_fin_translatevalues.target_value17%TYPE;
   gc_conc_short_name         xx_fin_translatevalues.target_value17%TYPE;
   gc_conc_short_file         xx_fin_translatevalues.target_value18%TYPE;
   gc_delimiter               xx_fin_translatevalues.target_value3%TYPE;
   gc_file_name               xx_fin_translatevalues.target_value4%TYPE;
   gc_email                   xx_fin_translatevalues.target_value5%TYPE;
   gc_compute_stats           xx_fin_translatevalues.target_value6%TYPE;
   gn_line_size               NUMBER;
   gc_file_path               xx_fin_translatevalues.target_value8%TYPE;
   gn_num_records             NUMBER;
   gc_debug                   xx_fin_translatevalues.target_value10%TYPE;
   gc_ftp_file_path           xx_fin_translatevalues.target_value11%TYPE;
   gc_arch_file_path          xx_fin_translatevalues.target_value12%TYPE;
   gn_full_num_days           NUMBER;
   gc_staging_table           xx_fin_translatevalues.target_value19%TYPE;
   gb_retrieved_trans         BOOLEAN             := FALSE;
   gc_err_msg_trans           VARCHAR2(100)       := NULL;

   -- Variables for Cycle Date and Batch Cycle Settings
   gc_process_type            xx_ar_mt_wc_details.process_type%TYPE;
   gc_action_type             xx_ar_mt_wc_details.action_type%TYPE;
   gd_cycle_date              xx_ar_wc_ext_control.cycle_date%TYPE;
   gn_batch_num               xx_ar_wc_ext_control.batch_num%TYPE;
   gb_ready_to_execute        BOOLEAN             := FALSE;
   gb_reprocessing_required   BOOLEAN             := FALSE;
   gb_retrieved_cntl          BOOLEAN             := FALSE;
   gc_err_msg_cntl            VARCHAR2(100)       := NULL;
   gc_post_process_status     VARCHAR(1)          := 'Y';
   gd_delta_from_date         DATE;
   gd_full_from_date          DATE;
   gd_control_to_date         DATE;

   -- Exceptions
   EX_NO_CONTROL_RECORD         EXCEPTION;
   EX_CYCLE_COMPLETED           EXCEPTION;
   EX_UNABLE_TO_STAGE           EXCEPTION;
   EX_REQUEST_NOT_SUBMITTED     EXCEPTION;
   EX_PROGRAM_INFO              EXCEPTION;
   EX_INVALID_PROCESS_TYPE      EXCEPTION;
   EX_INVALID_STATUS            EXCEPTION;
   EX_INVALID_ACTION_TYPE       EXCEPTION;
   EX_DELTA_THREADING_ERROR     EXCEPTION;
   EX_NO_SUB_REQUESTS           EXCEPTION;
   EX_INVALID_THREAD_CNT        EXCEPTION;
   EX_NO_CHILD_THREADS_WARNING  EXCEPTION;

   -- +====================================================================+
   -- | Name       : PRINT_TIME_STAMP_TO_LOGFILE                           |
   -- |                                                                    |
   -- | Description: This private procedure is used to print the time to   |
   -- |              the log                                               |
   -- |                                                                    |
   -- | Parameters : none                                                  |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE PRINT_TIME_STAMP_TO_LOGFILE
   IS
   BEGIN
      xx_ar_wc_utility_pkg.PRINT_TIME_STAMP_TO_LOGFILE;
   END;

   -- +====================================================================+
   -- | Name       : LOCATION_AND_LOG                                      |
   -- |                                                                    |
   -- | Description: This procedure is used to display detailed messages   |
   -- |               to log file                                          |
   -- |                                                                    |
   -- | Parameters : p_debug                                               |
   -- |              p_msg                                                 |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE location_and_log (p_debug   VARCHAR2
                              ,p_msg     VARCHAR2)
   IS
   BEGIN
      xx_ar_wc_utility_pkg.LOCATION_AND_LOG (p_debug, p_msg);
   END location_and_log;

   -- +====================================================================+
   -- | Name       : MASTER_EXT                                            |
   -- |                                                                    |
   -- | Description: This procedure is the executable for all of the       |
   -- |              multithreading programs for FULL and INCREMENTAL      |
   -- |                                                                    |
   -- | Parameters : p_cycle_date      IN                                  |
   -- |              p_batch_num       IN                                  |
   -- |              p_action_type     IN                                  |
   -- |              p_compute_stats   IN                                  |
   -- |              p_debug           IN                                  |
   -- |              p_process_type    IN                                  |
   -- |              p_errbuf          OUT                                 |
   -- |              p_retcode         OUT                                 |
   -- |                                                                    |
   -- | Returns    : none                                                  |
   -- +====================================================================+
   PROCEDURE master_ext (p_errbuf          OUT      VARCHAR2
                        ,p_retcode         OUT      NUMBER
                        ,p_cycle_date      IN       VARCHAR2
                        ,p_batch_num       IN       NUMBER
                        ,p_compute_stats   IN       VARCHAR2
                        ,p_debug           IN       VARCHAR2
                        ,p_process_type    IN       VARCHAR2
                        ,p_action_type     IN       VARCHAR2)
   AS
      -- Declaration of Local Variables
      ln_from_id                    NUMBER;
      ln_to_id                      NUMBER;
      ln_conc_req_id                NUMBER;
      ln_ext_wc_s                   NUMBER;
      lc_dev_phase                  VARCHAR2(200);
      lc_dev_status                 VARCHAR2(200);
      lc_phase                      VARCHAR2(200);
      lc_status                     VARCHAR2(20);
      lc_message                    VARCHAR2(2000);

      ltab_child_requests           FND_CONCURRENT.REQUESTS_TAB_TYPE;

      lc_error_debug                VARCHAR2(1000);
      ln_from_cust_account_id       hz_cust_accounts.cust_account_id%TYPE;
      ln_to_cust_account_id         hz_cust_accounts.cust_account_id%TYPE;
      ln_from_cust_trx_id           ra_customer_trx_all.customer_trx_id%TYPE;
      ln_to_cust_trx_id             ra_customer_trx_all.customer_trx_id%TYPE;
      ln_thread_num                 NUMBER;
      ln_req_id                     req_id;
      ln_idx                        NUMBER              := 1;
      lc_compute_stats              VARCHAR2(1);
      lc_debug_flag                 VARCHAR2(1);
      ld_to_date                    DATE;
      ld_last_run_date              DATE;
      lc_last_run_date              VARCHAR2(20);
      ln_retcode                    NUMBER             := 0;
      ln_count                      NUMBER             := 0;
      ln_delta_ret_code             NUMBER             := 0;
      lc_print_to_log               VARCHAR2(1)        := 'Y';

      ln_success_cnt                NUMBER             := 0;
      ln_error_cnt                  NUMBER             := 0;

      ln_thread_cnt                 NUMBER             := 0;

      CURSOR lcu_incomplete_threads
      IS
         --Start change for Defect# 16326
         SELECT WCD.mt_seq
               ,WCD.parent_program_id
               ,WCD.parent_request_id
               ,WCD.child_program_id
               ,WCD.child_request_id
               ,WCD.thread_num
               ,WCD.from_date
               ,WCD.TO_DATE
               ,WCD.from_id
               ,WCD.to_id
               ,FCR.status_code
           FROM xx_ar_mt_wc_details WCD
               ,fnd_concurrent_requests FCR
          WHERE cycle_date = gd_cycle_date
            AND batch_num = gn_batch_num
            AND process_type = gc_process_type
            AND action_type = gc_action_type
            AND WCD.child_request_id = FCR.request_id
            AND WCD.status <> 'Y'
            AND FCR.status_code IN ('E','X','D');

      ltab_incomplete_threads_rec   lcu_incomplete_threads%ROWTYPE;
   BEGIN
      --========================================================================
      -- Initialize Processing
      --========================================================================
      BEGIN
         gc_req_data := FND_CONC_GLOBAL.REQUEST_DATA;

         IF gc_req_data IS NULL THEN
            location_and_log(GC_YES,'Initialize Processing.'||chr(10));
            -------------------------------------------------
            -- Select Next Sequence
            -------------------------------------------------
            BEGIN
               location_and_log (p_debug, '     Select Next Master Sequence Number.');

               SELECT xx_ar_mt_wc_s.NEXTVAL
                 INTO gn_ext_wc_s
                 FROM DUAL;
            END;
         ELSE
            location_and_log(GC_YES,'Initialize Processing for Restart.'||chr(10));
         END IF;

         gd_cycle_date        := FND_DATE.CANONICAL_TO_DATE (p_cycle_date);
         gn_batch_num         := p_batch_num;
         gc_process_type      := p_process_type;
         gc_action_type       := p_action_type;

         -------------------------------------------------
         -- Print Parameter Names and Values to Log File
         -------------------------------------------------
         IF gc_req_data IS NULL THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** ENTERED PARAMETERS ******************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Cycle Date             : ' || gd_cycle_date);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Batch Number           : ' || p_batch_num);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Gather Statistics      : ' || p_compute_stats);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag             : ' || p_debug);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Process Type           : ' || p_process_type);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Action Type            : ' || p_action_type);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request ID             : ' || gn_parent_request_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
         END IF;
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Retrieve Interface Settings from Translation Definition
      --========================================================================
      BEGIN
         ---------------------------------------------
         -- Check Print Interface Settings to Log File
         ---------------------------------------------
         IF gc_req_data IS NOT NULL THEN
            lc_print_to_log := 'N';   -- RESTART will not print all of the control table variables
         END IF;

         location_and_log (GC_YES, 'Retrieving Interface Settings From Translation Definition' || CHR (10));
         xx_ar_wc_utility_pkg.get_interface_settings (p_process_type           => p_process_type
                                                     ,p_bulk_limit             => gn_limit
                                                     ,p_delimiter              => gc_delimiter
                                                     ,p_num_threads_delta      => gn_threads_delta
                                                     ,p_file_name              => gc_file_name
                                                     ,p_email                  => gc_email
                                                     ,p_gather_stats           => gc_compute_stats
                                                     ,p_line_size              => gn_line_size
                                                     ,p_file_path              => gc_file_path
                                                     ,p_num_records            => gn_num_records
                                                     ,p_debug                  => gc_debug
                                                     ,p_ftp_file_path          => gc_ftp_file_path
                                                     ,p_arch_file_path         => gc_arch_file_path
                                                     ,p_full_num_days          => gn_full_num_days
                                                     ,p_num_threads_full       => gn_threads_full
                                                     ,p_num_threads_file       => gn_threads_file
                                                     ,p_child_conc_delta       => gc_conc_short_delta
                                                     ,p_child_conc_full        => gc_conc_short_full
                                                     ,p_child_conc_file        => gc_conc_short_file
                                                     ,p_staging_table          => gc_staging_table
                                                     ,p_retrieved              => gb_retrieved_trans
                                                     ,p_error_message          => gc_err_msg_trans
                                                     ,p_print_to_req_log       => lc_print_to_log);
      END;  -- Retrieve Interface Settings from Translation Definition

      print_time_stamp_to_logfile;

      --========================================================================
      -- Override Debug and Gather Statistics with Parameter Values if NOT NULL
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Determine if parameter value for debug/stats is used' || CHR (10));
         gc_debug := xx_ar_wc_utility_pkg.validate_param_trans_value (p_debug, gc_debug);
         gc_compute_stats := xx_ar_wc_utility_pkg.validate_param_trans_value (p_compute_stats, gc_compute_stats);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** PARAMETER OVERRIDES *****************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag             : ' || gc_debug);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Gather Statistics      : ' || gc_compute_stats);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Checking Request Data to Determine if 1st Time or Restarting
      --========================================================================
      IF gc_req_data IS NULL THEN
         -- This is NOT a restart
         --========================================================================
         -- Retrieve Cycle Date Information from Control Table
         --========================================================================
         BEGIN
            location_and_log (GC_YES, 'Retrieve Cycle Date Information from Control Table' || CHR (10));
            location_and_log (p_debug, '     gd_cycle_date :' || gd_cycle_date);
            xx_ar_wc_utility_pkg.get_control_info (p_cycle_date                 => gd_cycle_date
                                                  ,p_batch_num                  => p_batch_num
                                                  ,p_process_type               => p_process_type
                                                  ,p_action_type                => p_action_type
                                                  ,p_delta_from_date            => gd_delta_from_date
                                                  ,p_full_from_date             => gd_full_from_date
                                                  ,p_control_to_date            => gd_control_to_date
                                                  ,p_post_process_status        => gc_post_process_status
                                                  ,p_ready_to_execute           => gb_ready_to_execute
                                                  ,p_reprocessing_required      => gb_reprocessing_required
                                                  ,p_reprocess_cnt              => gc_reprocess_cnt
                                                  ,p_retrieved                  => gb_retrieved_cntl
                                                  ,p_error_message              => gc_err_msg_cntl
                                                  );
         END;

         print_time_stamp_to_logfile;

         --========================================================================
         -- Verify Action Type and Set Concurrent Program Short Name
         --========================================================================
         BEGIN
            location_and_log (GC_YES, '     Verify Action Type and Set Concurrent Program Short Name' || CHR (10));

            IF gc_action_type = 'I'
            THEN
               gc_conc_short_name := gc_conc_short_delta;
            ELSIF gc_action_type = 'F'
            THEN
               gc_conc_short_name := gc_conc_short_full;
            ELSE
               RAISE EX_INVALID_ACTION_TYPE;
            END IF;  -- verify action type
         END;  

         print_time_stamp_to_logfile;

         --========================================================================
         -- Retrieve and Print Program Information to Log File
         --========================================================================
         location_and_log (GC_YES, 'Retrieve Program IDs for Master and Child.' || CHR (10));

         BEGIN
            location_and_log (gc_debug, '     Retrieve Program ID for Master');

            SELECT concurrent_program_id
              INTO gn_parent_cp_id
              FROM fnd_concurrent_requests fcr
             WHERE fcr.request_id = gn_parent_request_id;

            location_and_log (gc_debug, '     Retrieve Program Info for Child');

            SELECT fcp.concurrent_program_id
                  ,fcp.user_concurrent_program_name
              INTO gn_child_cp_id
                  ,gc_child_prog_name
              FROM fnd_concurrent_programs_vl fcp
             WHERE fcp.concurrent_program_name = gc_conc_short_name;

            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '***************************** PROGRAM INFORMATION ******************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parent Program ID      : ' || gn_parent_cp_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Program ID       : ' || gn_child_cp_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Program Name     : ' || gc_child_prog_name);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
         EXCEPTION
            WHEN OTHERS
            THEN
               RAISE EX_PROGRAM_INFO;
         END;  -- print program information

         print_time_stamp_to_logfile;

         --========================================================================
         -- Validate Control Information to Determine Processing Required
         --========================================================================
         BEGIN
            location_and_log (GC_YES, 'Validate Control Information to Determine Processing Required' || CHR (10));

            IF NOT gb_retrieved_cntl THEN
               location_and_log (gc_debug, '     Control Record Not Retrieved');
               RAISE EX_NO_CONTROL_RECORD;

            ELSIF gc_post_process_status = 'Y' THEN
               location_and_log (gc_debug, '     Cycle Date and Batch Number Already Completed.');
               RAISE EX_CYCLE_COMPLETED;

            ELSIF gb_ready_to_execute = FALSE THEN
               location_and_log (gc_debug, '     Unable to stage.  Data has already been staged or pre-requisites not met.');
               RAISE EX_UNABLE_TO_STAGE;

            ELSIF (p_action_type            = 'F'   AND
                   gb_ready_to_execute      = TRUE  AND
                   gb_reprocessing_required = FALSE    ) THEN
               --=====================================================================
               -- Processing - New FULL Conversion
               --=====================================================================
               BEGIN
                  location_and_log (GC_YES, 'Processing for a New FULL Conversion' || CHR (10));

                  -------------------------------------
                  -- Derive Child Thread Ranges - FULL
                  -------------------------------------
                  location_and_log (gc_debug, '     FULL - Before the Loop-Daily conversion');

                  LOOP

                    location_and_log(p_debug,'     Increment thread counter');
                    ln_thread_cnt := ln_thread_cnt + 1;

                     ---------------------------------------------------------
                     -- Submit Child Requests - FULL
                     ---------------------------------------------------------
                     location_and_log(p_debug,'     Set Print Options');
                     gb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(printer => NULL
                                                                     ,copies  => 0);

                     location_and_log (gc_debug, '     FULL - Submitting Child Request');
                     ln_conc_req_id :=
                        fnd_request.submit_request (application      => 'XXFIN'
                                                   ,program          => gc_conc_short_name
                                                   ,description      => ''
                                                   ,start_time       => ''
                                                   ,sub_request      => TRUE
                                                   ,argument1        => FND_DATE.DATE_TO_CANONICAL(gd_cycle_date)
                                                   ,argument2        => p_batch_num
                                                   ,argument3        => NULL --ln_from_cust_account_id  -- Changed code as for Defect# 16264
                                                   ,argument4        => NULL --ln_to_cust_account_id    -- Changed code as for Defect# 16264
                                                   ,argument5        => gc_debug
                                                   ,argument6        => ln_thread_cnt
                                                   ,argument7        => gc_process_type
                                                   ,argument8        => gc_action_type
                                                   );

                     FND_FILE.PUT_LINE (FND_FILE.LOG, '     Thread Number    : ' || ln_thread_cnt);
                     FND_FILE.PUT_LINE (FND_FILE.LOG, '     Request ID       : ' || ln_conc_req_id);
                     FND_FILE.PUT_LINE (FND_FILE.LOG, '     Cust Acct ID From: ' || ln_from_cust_account_id);
                     FND_FILE.PUT_LINE (FND_FILE.LOG, '     Cust Acct ID To  : ' || ln_to_cust_account_id);

                     ---------------------------------------------------------
                     -- Insert MT Details Table for Child Request - FULL
                     ---------------------------------------------------------
                     IF ln_conc_req_id = 0
                     THEN
                        location_and_log (gc_debug, '     FULL - AR Transaction Child Program is not submitted');
                        p_retcode := 2;
                        RAISE EX_REQUEST_NOT_SUBMITTED;
                     ELSE
                        location_and_log (gc_debug, '     FULL - Capture Child Request ID for Stats Checking');
                        ln_req_id (ln_idx) := ln_conc_req_id;
                        ln_idx := ln_idx + 1;
                        location_and_log (gc_debug, '     FULL - Insert Details for Child Request');

                        INSERT INTO xx_ar_mt_wc_details
                                    (mt_seq
                                    ,cycle_date
                                    ,batch_num
                                    ,parent_program_id
                                    ,parent_request_id
                                    ,thread_num
                                    ,status
                                    ,action_type
                                    ,process_type
                                    ,child_program_id
                                    ,child_request_id
                                    ,from_date
                                    ,TO_DATE
                                    ,from_id
                                    ,to_id
                                    ,created_by
                                    ,creation_date
                                    ,last_updated_by
                                    ,last_update_date
                                    ,prior_parent_req_id
                                    ,prior_child_req_id
                                    )
                             VALUES (gn_ext_wc_s
                                    ,gd_cycle_date
                                    ,p_batch_num
                                    ,gn_parent_cp_id
                                    ,gn_parent_request_id
                                    ,ln_thread_cnt
                                    ,'P'
                                    ,gc_action_type
                                    ,p_process_type
                                    ,gn_child_cp_id
                                    ,ln_conc_req_id
                                    ,gd_full_from_date
                                    ,gd_control_to_date        
                                    ,ln_from_cust_account_id
                                    ,ln_to_cust_account_id
                                    ,gn_user_id
                                    ,SYSDATE
                                    ,gn_user_id
                                    ,SYSDATE
                                    ,-1
                                    ,-1
                                    );
                     END IF;
                     EXIT WHEN (ln_thread_cnt = gn_threads_full); -- Added code as for Defect# 16264
                  END LOOP;

                  location_and_log (gc_debug, '     FULL - After the Loop-Daily conversion');

                  --CLOSE lcu_cust_accts_txn;   -- Commented code as for Defect# 16264

                  ---------------------------------------------------------
                  -- Update Control and Commit to Submit Requests
                  ---------------------------------------------------------
                  location_and_log (GC_YES, '     Update Control and Commit to Submit Requests.');
                  BEGIN
                     IF p_process_type = 'AR_TRANS' THEN
                        location_and_log (GC_YES, '     Evaluating Thread Count for AR_TRANS.');
                        IF ln_thread_cnt > 0 THEN
                           location_and_log (GC_YES, '     Update status flag to P to indicate staging in-progress');
                           UPDATE xx_ar_wc_ext_control
                              SET trx_ext_full = 'P'                  -- staging in-progress
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by = gn_user_id
                            WHERE cycle_date   = gd_cycle_date
                              AND batch_num    = p_batch_num;

                        ELSIF ln_thread_cnt = 0 THEN
                           location_and_log (GC_YES, '     Update status flag to Y - NO child requests where submitted since there was no NEW conversions');
                           UPDATE xx_ar_wc_ext_control
                              SET trx_ext_full = 'Y'                 -- Completed
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by = gn_user_id
                            WHERE cycle_date   = gd_cycle_date
                              AND batch_num    = p_batch_num;
                           COMMIT;
                           RAISE EX_NO_CHILD_THREADS_WARNING;
                        ELSE
                           location_and_log (GC_YES, '     Negative thread count');
                           RAISE EX_INVALID_THREAD_CNT;
                        END IF;

                     ELSIF p_process_type = 'AR_CASH_RECEIPTS' THEN
                        location_and_log (GC_YES, '     Evaluating Thread Count for AR_CASH_RECEIPTS.');
                        IF ln_thread_cnt > 0 THEN
                           location_and_log (GC_YES, '     Update status flag to P to indicate staging in-progress');
                           UPDATE xx_ar_wc_ext_control
                              SET rec_ext_full = 'P'                  -- staging in-progress
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by = gn_user_id
                            WHERE cycle_date   = gd_cycle_date
                              AND batch_num    = p_batch_num;

                        ELSIF ln_thread_cnt = 0 THEN
                           location_and_log (GC_YES, '     Update status flag to Y - NO child requests where submitted since there was no NEW conversions');
                           UPDATE xx_ar_wc_ext_control
                              SET rec_ext_full = 'Y'                  -- completed
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by = gn_user_id
                            WHERE cycle_date   = gd_cycle_date
                              AND batch_num    = p_batch_num;
                           COMMIT;
                           RAISE EX_NO_CHILD_THREADS_WARNING;
                        ELSE
                           location_and_log (GC_YES, '     Negative thread count');
                           RAISE EX_INVALID_THREAD_CNT;
                        END IF;

                     ELSIF p_process_type = 'AR_ADJUSTMENTS' THEN
                        location_and_log (GC_YES, '     Evaluating Thread Count for AR_ADJUSTMENTS.');
                        IF ln_thread_cnt > 0 THEN
                           location_and_log (GC_YES, '     Update status flag to P to indicate staging in-progress');
                           UPDATE xx_ar_wc_ext_control
                              SET adj_ext_full = 'P'                    -- staging in-progress
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by = gn_user_id
                            WHERE cycle_date   = gd_cycle_date
                              AND batch_num    = p_batch_num;

                        ELSIF ln_thread_cnt = 0 THEN
                           location_and_log (GC_YES, '     Update status flag to Y - NO child requests where submitted since there was no NEW conversions');
                           UPDATE xx_ar_wc_ext_control
                              SET adj_ext_full = 'Y'                    -- completed
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by = gn_user_id
                            WHERE cycle_date   = gd_cycle_date
                              AND batch_num    = p_batch_num;
                           COMMIT;
                           RAISE EX_NO_CHILD_THREADS_WARNING;
                        ELSE
                           location_and_log (GC_YES, '     Negative thread count');
                           RAISE EX_INVALID_THREAD_CNT;
                        END IF;

                     ELSIF p_process_type = 'AR_PAYMENT_SCHEDULE' THEN
                        location_and_log (GC_YES, '     Evaluating Thread Count for AR_PAYMENT_SCHEDULE.');
                        IF ln_thread_cnt > 0 THEN
                           location_and_log (GC_YES, '     Update status flag to P to indicate staging in-progress');
                           UPDATE xx_ar_wc_ext_control
                              SET pmt_ext_full = 'P'                  -- staging in-progress
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by = gn_user_id
                            WHERE cycle_date   = gd_cycle_date
                              AND batch_num    = p_batch_num;

                        ELSIF ln_thread_cnt = 0 THEN
                           location_and_log (GC_YES, '     Update status flag to Y - NO child requests where submitted since there was no NEW conversions');
                           UPDATE xx_ar_wc_ext_control
                              SET pmt_ext_full = 'Y'                  -- completed
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by = gn_user_id
                            WHERE cycle_date   = gd_cycle_date
                              AND batch_num    = p_batch_num;
                           COMMIT;
                           RAISE EX_NO_CHILD_THREADS_WARNING;
                        ELSE
                           location_and_log (GC_YES, '     Nnegative thread count');
                           RAISE EX_INVALID_THREAD_CNT;
                        END IF;

                     ELSIF p_process_type = 'AR_RECEIVABLE_APP' THEN
                        location_and_log (GC_YES, '     Evaluating Thread Count for AR_RECEIVABLE_APP.');
                        IF ln_thread_cnt > 0 THEN
                           location_and_log (GC_YES, '     Update status flag to P to indicate staging in-progress');
                           UPDATE xx_ar_wc_ext_control
                              SET app_ext_full = 'P'                  -- staging in-progress
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by = gn_user_id
                            WHERE cycle_date   = gd_cycle_date
                              AND batch_num    = p_batch_num;

                        ELSIF ln_thread_cnt = 0 THEN
                           location_and_log (GC_YES, '     Update status flag to Y - NO child requests where submitted since there was no NEW conversions');
                           UPDATE xx_ar_wc_ext_control
                              SET app_ext_full = 'Y'                  -- completed
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by = gn_user_id
                            WHERE cycle_date   = gd_cycle_date
                              AND batch_num    = p_batch_num;
                           COMMIT;
                           RAISE EX_NO_CHILD_THREADS_WARNING;
                        ELSE
                           location_and_log (GC_YES, '     Negative thread count');
                           RAISE EX_INVALID_THREAD_CNT;
                        END IF;

                     ELSE
                        location_and_log (gc_debug, '     Unable to update status for process type of ' || p_process_type);
                        RAISE EX_INVALID_PROCESS_TYPE;

                     END IF;

                     location_and_log (GC_YES, '     Issue commit for submitting child RIDs, insert MT details, and updating control');
                     COMMIT;
                  END; -- Update Control and Commit to Submit Requests

               END; -- New FULL Conversion

            ELSIF (p_action_type           = 'F'  AND
                  gb_ready_to_execute      = TRUE AND
                  gb_reprocessing_required = TRUE    ) THEN
               --=====================================================================
               -- Reprocessing - Existing FULL Conversion
               --=====================================================================
               BEGIN
                  location_and_log (GC_YES, 'Reprocessing an existing FULL Converion' || CHR (10));

                  -------------------------------------
                  -- Derive Child Thread Ranges
                  -------------------------------------
                  OPEN lcu_incomplete_threads;

                  LOOP
                     FETCH lcu_incomplete_threads
                      INTO ltab_incomplete_threads_rec;

                     EXIT WHEN lcu_incomplete_threads%NOTFOUND;

                     ---------------------------------------------------------
                     -- Submit Child Requests - FULL
                     ---------------------------------------------------------
                     location_and_log(p_debug,'     Set Print Options');
                     gb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(printer => NULL
                                                                     ,copies  => 0);
                     --Start change for defect# 16326. Following IF condition added
                     IF ltab_incomplete_threads_rec.status_code NOT IN ('E','X','D') --<> 'E'
                     THEN
                        UPDATE xx_ar_mt_wc_details
                           SET status = 'Y'
                         WHERE mt_seq = ltab_incomplete_threads_rec.mt_seq
                           AND child_request_id = ltab_incomplete_threads_rec.child_request_id;

                         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Status is updated to Y for child request_id : ' || ltab_incomplete_threads_rec.child_request_id);

                     ELSE
                     --End change for defect# 16326
                     
                         location_and_log (gc_debug, '     FULL - Submitting Child Request');
                         ln_conc_req_id :=
                            fnd_request.submit_request (application      => 'XXFIN'
                                                       ,program          => gc_conc_short_name
                                                       ,description      => '' 
                                                       ,start_time       => ''
                                                       ,sub_request      => TRUE
                                                       ,argument1        => FND_DATE.DATE_TO_CANONICAL(gd_cycle_date)
                                                       ,argument2        => p_batch_num
                                                       ,argument3        => ltab_incomplete_threads_rec.from_id
                                                       ,argument4        => ltab_incomplete_threads_rec.to_id
                                                       ,argument5        => gc_debug
                                                       ,argument6        => ltab_incomplete_threads_rec.thread_num
                                                       ,argument7        => gc_process_type
                                                       ,argument8        => gc_action_type
                                                       );

                         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Thread Number    : ' || ltab_incomplete_threads_rec.thread_num);
                         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Request ID       : ' || ln_conc_req_id);
                         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Cust Acct ID From: ' || ltab_incomplete_threads_rec.from_id);
                         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Cust Acct ID To  : ' || ltab_incomplete_threads_rec.to_id);

                         ---------------------------------------------------------
                         -- Update existing MT Details Table for Child Request - FULL
                         ---------------------------------------------------------
                         location_and_log (gc_debug,'      FULL - Checking if child request was submitted');

                         IF ln_conc_req_id = 0
                         THEN
                            location_and_log (gc_debug,'      FULL - AR Transaction Child Program is not submitted');
                            p_retcode := 2;
                            RAISE EX_REQUEST_NOT_SUBMITTED;
                         ELSE
                            location_and_log (gc_debug,'      FULL - Capture Child Request ID for Stats Checking');
                            ln_req_id (ln_idx) := ln_conc_req_id;
                            ln_idx := ln_idx + 1;
                            location_and_log (gc_debug,'      FULL - Update Details for Child Request');

                            UPDATE xx_ar_mt_wc_details
                               SET parent_request_id = gn_parent_request_id
                                  ,child_request_id = ln_conc_req_id
                                  ,prior_parent_req_id = ltab_incomplete_threads_rec.parent_request_id
                                  ,prior_child_req_id = ltab_incomplete_threads_rec.child_request_id
                             WHERE cycle_date = gd_cycle_date
                               AND batch_num = gn_batch_num
                               AND process_type = gc_process_type
                               AND action_type = gc_action_type
                               AND thread_num = ltab_incomplete_threads_rec.thread_num
                               AND parent_request_id = ltab_incomplete_threads_rec.parent_request_id
                               AND child_request_id = ltab_incomplete_threads_rec.child_request_id
                               AND status <> 'Y';
                         END IF;
                     END IF;
                  END LOOP;

                  CLOSE lcu_incomplete_threads;

                  location_and_log (GC_YES, '     Issue commit for submitting child RIDs and update MT details table');
                  COMMIT;
               END;   -- Reprocessing an Existing FULL Conversion

            ELSIF (p_action_type            = 'I'   AND
                   gb_ready_to_execute      = TRUE  AND
                   gb_reprocessing_required = FALSE    ) THEN
               --=====================================================================
               -- Processing - New INCREMENTAL (or Delta)
               --=====================================================================
               BEGIN
                  location_and_log (GC_YES, 'Processing for a New DELTA Conversion' || CHR (10));

                  -------------------------------------
                  -- Derive Child Thread Ranges - DELTA
                  -------------------------------------
                  location_and_log (gc_debug, '     DELTA - Before the Loop-Daily conversion');

                  LOOP

                    location_and_log(p_debug,'     Increment thread counter');
                    ln_thread_cnt := ln_thread_cnt + 1;

                     ---------------------------------------------------------
                     -- Submit Child Requests - DELTA
                     ---------------------------------------------------------
                     location_and_log(p_debug,'     Set Print Options');
                     gb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(printer => NULL
                                                                     ,copies  => 0);

                     location_and_log (gc_debug, '     DELTA - Submitting Child Request');
                     ln_conc_req_id :=
                        fnd_request.submit_request (application      => 'XXFIN'
                                                   ,program          => gc_conc_short_name
                                                   ,description      => ''
                                                   ,start_time       => ''
                                                   ,sub_request      => TRUE
                                                   ,argument1        => FND_DATE.DATE_TO_CANONICAL(gd_cycle_date)
                                                   ,argument2        => p_batch_num
                                                   ,argument3        => NULL --ln_from_cust_account_id  -- Changed code as for Defect# 16264
                                                   ,argument4        => NULL --ln_to_cust_account_id    -- Changed code as for Defect# 16264
                                                   ,argument5        => gc_debug
                                                   ,argument6        => ln_thread_cnt
                                                   ,argument7        => gc_process_type
                                                   ,argument8        => gc_action_type
                                                   );

                     FND_FILE.PUT_LINE (FND_FILE.LOG, '     Thread Number    : ' || ln_thread_cnt);
                     FND_FILE.PUT_LINE (FND_FILE.LOG, '     Request ID       : ' || ln_conc_req_id);
                     FND_FILE.PUT_LINE (FND_FILE.LOG, '     Cust Acct ID From: ' || ln_from_cust_account_id);
                     FND_FILE.PUT_LINE (FND_FILE.LOG, '     Cust Acct ID To  : ' || ln_to_cust_account_id);

                     ---------------------------------------------------------
                     -- Insert MT Details Table for Child Request - DELTA
                     ---------------------------------------------------------
                     IF ln_conc_req_id = 0
                     THEN
                        location_and_log (gc_debug, '     DELTA - AR Transaction Child Program is not submitted');
                        p_retcode := 2;
                        RAISE EX_REQUEST_NOT_SUBMITTED;
                     ELSE
                        location_and_log (gc_debug, '     DELTA - Capture Child Request ID for Stats Checking');
                        ln_req_id (ln_idx) := ln_conc_req_id;
                        ln_idx := ln_idx + 1;
                        location_and_log (gc_debug, '     DELTA - Insert Details for Child Request');

                        INSERT INTO xx_ar_mt_wc_details
                                    (mt_seq
                                    ,cycle_date
                                    ,batch_num
                                    ,parent_program_id
                                    ,parent_request_id
                                    ,thread_num
                                    ,status
                                    ,action_type
                                    ,process_type
                                    ,child_program_id
                                    ,child_request_id
                                    ,from_date
                                    ,to_date
                                    ,from_id
                                    ,to_id
                                    ,created_by
                                    ,creation_date
                                    ,last_updated_by
                                    ,last_update_date
                                    ,prior_parent_req_id
                                    ,prior_child_req_id
                                    )
                             VALUES (gn_ext_wc_s
                                    ,gd_cycle_date
                                    ,p_batch_num
                                    ,gn_parent_cp_id
                                    ,gn_parent_request_id
                                    ,ln_thread_cnt
                                    ,'P'
                                    ,gc_action_type
                                    ,p_process_type
                                    ,gn_child_cp_id
                                    ,ln_conc_req_id
                                    ,gd_delta_from_date
                                    ,gd_control_to_date        
                                    ,ln_from_cust_account_id
                                    ,ln_to_cust_account_id
                                    ,gn_user_id
                                    ,SYSDATE
                                    ,gn_user_id
                                    ,SYSDATE
                                    ,-1
                                    ,-1
                                    );
                     END IF;
                     EXIT WHEN (ln_thread_cnt = gn_threads_delta); 
                  END LOOP;

                  location_and_log (gc_debug, '     DELTA - After the Loop-Daily conversion');

                  --CLOSE lcu_cust_accts_txn;   -- Commented code as for Defect# 16264

                  ---------------------------------------------------------
                  -- Update Control and Commit to Submit Requests
                  ---------------------------------------------------------
                  location_and_log (GC_YES, '     Update Control and Commit to Submit Requests.');
                  BEGIN
                     IF p_process_type = 'AR_TRANS' THEN
                        location_and_log (GC_YES, '     Evaluating Thread Count for AR_TRANS.');
                        IF ln_thread_cnt > 0 THEN
                           location_and_log (GC_YES, '     Update status flag to P to indicate staging in-progress');
                           UPDATE xx_ar_wc_ext_control
                              SET trx_ext_delta = 'P'                  -- staging in-progress
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by  = gn_user_id
                            WHERE cycle_date       = gd_cycle_date
                              AND batch_num        = p_batch_num;

                        ELSIF ln_thread_cnt = 0 THEN
                           location_and_log (GC_YES, '     Update status flag to Y - NO child requests where submitted since there was no NEW conversions');
                           UPDATE xx_ar_wc_ext_control
                              SET trx_ext_delta = 'Y'                 -- Completed
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by  = gn_user_id
                            WHERE cycle_date       = gd_cycle_date
                              AND batch_num        = p_batch_num;
                           COMMIT;
                           RAISE EX_NO_CHILD_THREADS_WARNING;
                        ELSE
                           location_and_log (GC_YES, '     Negative thread count');
                           RAISE EX_INVALID_THREAD_CNT;
                        END IF;

                     ELSIF p_process_type = 'AR_CASH_RECEIPTS' THEN
                        location_and_log (GC_YES, '     Evaluating Thread Count for AR_CASH_RECEIPTS.');
                        IF ln_thread_cnt > 0 THEN
                           location_and_log (GC_YES, '     Update status flag to P to indicate staging in-progress');
                           UPDATE xx_ar_wc_ext_control
                              SET rec_ext_delta = 'P'                  -- staging in-progress
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by  = gn_user_id
                            WHERE cycle_date       = gd_cycle_date
                              AND batch_num        = p_batch_num;

                        ELSIF ln_thread_cnt = 0 THEN
                           location_and_log (GC_YES, '     Update status flag to Y - NO child requests where submitted since there was no NEW conversions');
                           UPDATE xx_ar_wc_ext_control
                              SET rec_ext_delta = 'Y'                  -- completed
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by  = gn_user_id
                            WHERE cycle_date       = gd_cycle_date
                              AND batch_num        = p_batch_num;
                           COMMIT;
                           RAISE EX_NO_CHILD_THREADS_WARNING;
                        ELSE
                           location_and_log (GC_YES, '     Negative thread count');
                           RAISE EX_INVALID_THREAD_CNT;
                        END IF;

                     ELSIF p_process_type = 'AR_ADJUSTMENTS' THEN
                        location_and_log (GC_YES, '     Evaluating Thread Count for AR_ADJUSTMENTS.');
                        IF ln_thread_cnt > 0 THEN
                           location_and_log (GC_YES, '     Update status flag to P to indicate staging in-progress');
                           UPDATE xx_ar_wc_ext_control
                              SET adj_ext_delta = 'P'                    -- staging in-progress
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by  = gn_user_id
                            WHERE cycle_date       = gd_cycle_date
                              AND batch_num        = p_batch_num;

                        ELSIF ln_thread_cnt = 0 THEN
                           location_and_log (GC_YES, '     Update status flag to Y - NO child requests where submitted since there was no NEW conversions');
                           UPDATE xx_ar_wc_ext_control
                              SET adj_ext_delta = 'Y'                    -- completed
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by  = gn_user_id
                            WHERE cycle_date       = gd_cycle_date
                              AND batch_num        = p_batch_num;
                           COMMIT;
                           RAISE EX_NO_CHILD_THREADS_WARNING;
                        ELSE
                           location_and_log (GC_YES, '     Negative thread count');
                           RAISE EX_INVALID_THREAD_CNT;
                        END IF;

                     ELSIF p_process_type = 'AR_PAYMENT_SCHEDULE' THEN
                        location_and_log (GC_YES, '     Evaluating Thread Count for AR_PAYMENT_SCHEDULE.');
                        IF ln_thread_cnt > 0 THEN
                           location_and_log (GC_YES, '     Update status flag to P to indicate staging in-progress');
                           UPDATE xx_ar_wc_ext_control
                              SET pmt_ext_delta = 'P'                  -- staging in-progress
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by  = gn_user_id
                            WHERE cycle_date       = gd_cycle_date
                              AND batch_num        = p_batch_num;

                        ELSIF ln_thread_cnt = 0 THEN
                           location_and_log (GC_YES, '     Update status flag to Y - NO child requests where submitted since there was no NEW conversions');
                           UPDATE xx_ar_wc_ext_control
                              SET pmt_ext_delta = 'Y'                  -- completed
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by  = gn_user_id
                            WHERE cycle_date       = gd_cycle_date
                              AND batch_num        = p_batch_num;
                           COMMIT;
                           RAISE EX_NO_CHILD_THREADS_WARNING;
                        ELSE
                           location_and_log (GC_YES, '     Nnegative thread count');
                           RAISE EX_INVALID_THREAD_CNT;
                        END IF;

                     ELSIF p_process_type = 'AR_RECEIVABLE_APP' THEN
                        location_and_log (GC_YES, '     Evaluating Thread Count for AR_RECEIVABLE_APP.');
                        IF ln_thread_cnt > 0 THEN
                           location_and_log (GC_YES, '     Update status flag to P to indicate staging in-progress');
                           UPDATE xx_ar_wc_ext_control
                              SET app_ext_delta = 'P'                  -- staging in-progress
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by  = gn_user_id
                            WHERE cycle_date       = gd_cycle_date
                              AND batch_num        = p_batch_num;

                        ELSIF ln_thread_cnt = 0 THEN
                           location_and_log (GC_YES, '     Update status flag to Y - NO child requests where submitted since there was no NEW conversions');
                           UPDATE xx_ar_wc_ext_control
                              SET app_ext_delta = 'Y'                  -- completed
                                 ,last_update_date = SYSDATE
                                 ,last_updated_by = gn_user_id
                            WHERE cycle_date      = gd_cycle_date
                              AND batch_num       = p_batch_num;
                           COMMIT;
                           RAISE EX_NO_CHILD_THREADS_WARNING;
                        ELSE
                           location_and_log (GC_YES, '     Negative thread count');
                           RAISE EX_INVALID_THREAD_CNT;
                        END IF;

                     ELSE
                        location_and_log (gc_debug, '     Unable to update status for process type of ' || p_process_type);
                        RAISE EX_INVALID_PROCESS_TYPE;

                     END IF;

                     location_and_log (GC_YES, '     Issue commit for submitting child RIDs, insert MT details, and updating control');
                     COMMIT;
                  END; -- Update Control and Commit to Submit Requests

               END; -- New DELTA Conversion

            ELSIF (p_action_type            = 'I'   AND
                   gb_ready_to_execute      = TRUE  AND
                   gb_reprocessing_required = TRUE     ) THEN
               --=====================================================================
               -- Reprocessing - Existing INCREMENTAL (or Delta)
               --=====================================================================
               BEGIN
                  location_and_log (GC_YES, 'Reprocessing an existing INCREMENTAL' || CHR (10));

                  -------------------------------------
                  -- Derive Child Thread Ranges
                  -------------------------------------
                  location_and_log (gc_debug, '     Opening lcu_incomplete_threads.');

                  OPEN lcu_incomplete_threads;

                  LOOP
                     FETCH lcu_incomplete_threads
                      INTO ltab_incomplete_threads_rec;

                     EXIT WHEN lcu_incomplete_threads%NOTFOUND;

                     ---------------------------------------------------------
                     -- Submit Child Requests - DELTA
                     ---------------------------------------------------------
                     location_and_log(p_debug,'     Set Print Options');
                     gb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(printer => NULL
                                                                     ,copies  => 0);
                     --Start change for defect# 16326. Following IF condition added
                     IF ltab_incomplete_threads_rec.status_code NOT IN ('E','X','D') --<> 'E'
                     THEN
                        UPDATE xx_ar_mt_wc_details
                           SET status = 'Y'
                         WHERE mt_seq = ltab_incomplete_threads_rec.mt_seq
                           AND child_request_id = ltab_incomplete_threads_rec.child_request_id;

                         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Status is updated to Y for child request_id : ' || ltab_incomplete_threads_rec.child_request_id);

                     ELSE
                     --End change for defect# 16326.
                        location_and_log (gc_debug, '     DELTA - Submitting Child Request');
                        ln_conc_req_id :=
                            fnd_request.submit_request (application      => 'XXFIN'
                                                                ,program          => gc_conc_short_name
                                                                ,description      => ''    
                                                                ,start_time       => ''
                                                                ,sub_request      => TRUE
                                                                ,argument1        => FND_DATE.DATE_TO_CANONICAL(gd_cycle_date)
                                                                ,argument2        => p_batch_num
                                                                ,argument3        => ltab_incomplete_threads_rec.from_id
                                                                ,argument4        => ltab_incomplete_threads_rec.to_id
                                                                ,argument5        => gc_debug
                                                                ,argument6        => ltab_incomplete_threads_rec.thread_num
                                                                ,argument7        => gc_process_type
                                                                ,argument8        => gc_action_type
                                                                );

                        FND_FILE.PUT_LINE (FND_FILE.LOG, '     Thread Number    : ' || ltab_incomplete_threads_rec.thread_num);
                        FND_FILE.PUT_LINE (FND_FILE.LOG, '     Request ID       : ' || ln_conc_req_id);
                        FND_FILE.PUT_LINE (FND_FILE.LOG, '     Cust Acct ID From: ' || ltab_incomplete_threads_rec.from_id);
                        FND_FILE.PUT_LINE (FND_FILE.LOG, '     Cust Acct ID To  : ' || ltab_incomplete_threads_rec.to_id);

                        ---------------------------------------
                        -- Insert MT Details Table DELTA child
                        ---------------------------------------
                        location_and_log (gc_debug,'     DELTA - Checking if child request was submitted');

                        IF ln_conc_req_id = 0
                        THEN
                            location_and_log (gc_debug,'     DELTA - AR Transaction Child Program is not submitted');
                            p_retcode := 2;
                            RAISE EX_REQUEST_NOT_SUBMITTED;
                        ELSE
                            location_and_log (gc_debug,'     DELTA - Capture Child Request ID for Stats Checking');
                            ln_req_id (ln_idx) := ln_conc_req_id;
                            ln_idx := ln_idx + 1;
                            location_and_log (gc_debug,'      DELTA - Update Details for Child Request');

                            UPDATE xx_ar_mt_wc_details
                                SET parent_request_id = gn_parent_request_id
                                    ,child_request_id = ln_conc_req_id
                                    ,prior_parent_req_id = ltab_incomplete_threads_rec.parent_request_id
                                    ,prior_child_req_id = ltab_incomplete_threads_rec.child_request_id
                             WHERE cycle_date = gd_cycle_date
                                AND batch_num = gn_batch_num
                                AND process_type = gc_process_type
                                AND action_type = gc_action_type
                                AND thread_num = ltab_incomplete_threads_rec.thread_num
                                AND parent_request_id = ltab_incomplete_threads_rec.parent_request_id
                                AND child_request_id = ltab_incomplete_threads_rec.child_request_id
                                AND status <> 'Y';
                        END IF;
                     END IF;
                  END LOOP;

                  CLOSE lcu_incomplete_threads;

                  location_and_log (gc_debug, '     Closed lcu_incomplete_threads.');
                  location_and_log (GC_YES, '      DELTA - Issue commit to submit children and update MT detail table.');
                  COMMIT;
               END; -- Processing an Existing INCREMENTAL
            ELSE
               location_and_log (gc_debug, 'Invalid processing type or control record status.');
               RAISE EX_INVALID_STATUS;
            END IF;
         END;   -- Validate Control Information to Determine Processing Required

         print_time_stamp_to_logfile;

        location_and_log(GC_YES, '     Pausing MASTER_EXT......'||chr(10));
        FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status  => 'PAUSED',
                                        request_data => 'CHILD_REQUESTS');

      ELSE
         location_and_log(GC_YES, '     Restarting after CHILD_REQUESTS Completed');
         location_and_log(gc_debug,'     Checking Child Requests');
         --========================================================================
         -- Post-Processing for Child Requests (INCREMENTAL and FULL)
         --========================================================================
         BEGIN
            location_and_log (GC_DEBUG, 'Post-processing for Child Requests' || CHR (10));

            ltab_child_requests := FND_CONCURRENT.GET_SUB_REQUESTS(gn_parent_request_id);

            location_and_log(GC_YES,'     Checking Child Requests');
            IF ltab_child_requests.count > 0 THEN
               FOR i IN ltab_child_requests.FIRST .. ltab_child_requests.LAST
               LOOP

                  location_and_log(GC_YES,CHR (10)||'     ltab_child_requests(i).request_id : '||ltab_child_requests(i).request_id);
                  location_and_log(GC_YES,          '     ltab_child_requests(i).dev_phase  : '||ltab_child_requests(i).dev_phase);
                  location_and_log(GC_YES,          '     ltab_child_requests(i).dev_status : '||ltab_child_requests(i).dev_status);

                  ---------------------------------------------------------
                  -- Update Multithread Detail Table Status
                  ---------------------------------------------------------
                  IF ltab_child_requests(i).dev_phase  = 'COMPLETE' AND
                     ltab_child_requests(i).dev_status IN ('NORMAL','WARNING')
                  THEN
                     location_and_log (GC_YES, '     Updating Detail Table to Completed for completion status of '||ltab_child_requests(i).dev_status);
                     ln_success_cnt := ln_success_cnt + 1;
                     p_retcode      := 0;

                     UPDATE xx_ar_mt_wc_details
                        SET status = 'Y'
                      WHERE parent_request_id = gn_parent_request_id
                        AND child_request_id  = ltab_child_requests(i).request_id;

                  ELSE
                     location_and_log (GC_YES, '     Updating Detail Table to Completed for completion status of '||ltab_child_requests(i).dev_status);
                     ln_error_cnt := ln_error_cnt + 1;
                     p_retcode    := 2;

                     UPDATE xx_ar_mt_wc_details
                        SET status = 'E'
                      WHERE parent_request_id = gn_parent_request_id
                        AND child_request_id  = ltab_child_requests(i).request_id;

                  END IF;

                  SELECT GREATEST (p_retcode, ln_retcode)
                    INTO ln_retcode
                    FROM DUAL;

               END LOOP; -- Checking Child Requests

            ELSE
               RAISE EX_NO_SUB_REQUESTS;
            END IF; -- retrieve child requests

            location_and_log (gc_debug, '     Captured Return Code for Master and Control Table Status');
            p_retcode := ln_retcode;

         END;  -- post processing for child requests

         print_time_stamp_to_logfile;

         --========================================================================
         -- Update Control Table Based on Success of Children
         --========================================================================
         BEGIN
            location_and_log (GC_YES, 'Updating control table based on status of all child threads for ' || p_process_type || CHR (10));
            IF p_action_type = 'F' AND p_process_type = 'AR_TRANS'
            THEN
               location_and_log (gc_debug, '     Determine value of retcode');

               IF p_retcode = 2
               THEN
                  location_and_log (GC_YES, '     Updating trx_ext_full column to E (ERROR) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET trx_ext_full = 'E'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               ELSE
                  location_and_log (GC_YES, '     Updating trx_ext_full column to Y (SUCCESS) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET trx_ext_full = 'Y'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               END IF;

            ELSIF p_action_type = 'I' AND p_process_type = 'AR_TRANS'
            THEN
               location_and_log (gc_debug, '     Determine value of retcode');

               IF p_retcode = 2
               THEN
                  location_and_log (GC_YES, '     Updating trx_ext_delta column to E (ERROR) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET trx_ext_delta = 'E'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               ELSE
                  location_and_log (GC_YES, '     Updating trx_ext_delta column to Y (SUCCESS) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET trx_ext_delta = 'Y'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               END IF;

            ELSIF p_action_type = 'F' AND p_process_type = 'AR_CASH_RECEIPTS'
            THEN
               location_and_log (gc_debug, '     Determine value of retcode');

               IF p_retcode = 2
               THEN
                  location_and_log (GC_YES, '     Updating rec_ext_full column to E (ERROR) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET rec_ext_full = 'E'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               ELSE
                  location_and_log (GC_YES, '     Updating rec_ext_full column to Y (SUCCESS) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET rec_ext_full = 'Y'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               END IF;

            ELSIF p_action_type = 'I' AND p_process_type = 'AR_CASH_RECEIPTS'
            THEN
               location_and_log (gc_debug, '     Determine value of retcode');

               IF p_retcode = 2
               THEN
                  location_and_log (GC_YES, '     Updating rec_ext_delta column to E (ERROR) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET rec_ext_delta = 'E'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               ELSE
                  location_and_log (GC_YES, '     Updating rec_ext_delta column to Y (SUCCESS) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET rec_ext_delta = 'Y'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               END IF;

            ELSIF p_action_type = 'F' AND p_process_type = 'AR_ADJUSTMENTS'
            THEN
               location_and_log (gc_debug, '     Determine value of retcode');

               IF p_retcode = 2
               THEN
                  location_and_log (GC_YES, '     Updating adj_ext_full column to E (ERROR) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET adj_ext_full = 'E'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               ELSE
                  location_and_log (GC_YES, '     Updating adj_ext_full column to Y (SUCCESS) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET adj_ext_full = 'Y'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               END IF;

            ELSIF p_action_type = 'I' AND p_process_type = 'AR_ADJUSTMENTS'
            THEN
               location_and_log (gc_debug, '     Determine value of retcode');

               IF p_retcode = 2
               THEN
                  location_and_log (GC_YES, '     Updating adj_ext_delta column to E (ERROR) in control table.');
                   UPDATE xx_ar_wc_ext_control
                     SET adj_ext_delta = 'E'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               ELSE
                  location_and_log (GC_YES, '     Updating adj_ext_delta column to Y (SUCCESS) in control table.');
                   UPDATE xx_ar_wc_ext_control
                     SET adj_ext_delta = 'Y'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               END IF;

            ELSIF p_action_type = 'F' AND p_process_type = 'AR_PAYMENT_SCHEDULE'
            THEN
               location_and_log (gc_debug, '     Determine value of retcode');

               IF p_retcode = 2
               THEN
                  location_and_log (GC_YES, '     Updating pmt_ext_full column to E (ERROR) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET pmt_ext_full = 'E'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               ELSE
                  location_and_log (GC_YES, '     Updating pmt_ext_full column to Y (SUCCESS) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET pmt_ext_full = 'Y'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               END IF;

            ELSIF p_action_type = 'I' AND p_process_type = 'AR_PAYMENT_SCHEDULE'
            THEN
               location_and_log (gc_debug, '     Determine value of retcode');

               IF p_retcode = 2
               THEN
                  location_and_log (GC_YES, '     Updating pmt_ext_delta column to E (ERROR) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET pmt_ext_delta = 'E'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               ELSE
                  location_and_log (GC_YES, '     Updating pmt_ext_delta column to Y (SUCCESS) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET pmt_ext_delta = 'Y'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               END IF;

            ELSIF p_action_type = 'F' AND p_process_type = 'AR_RECEIVABLE_APP'
            THEN
               location_and_log (gc_debug, '     Determine value of retcode');

               IF p_retcode = 2
               THEN
                  location_and_log (GC_YES, '     Updating app_ext_full column to E (ERROR) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET app_ext_full = 'E'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;

               ELSE
                  location_and_log (GC_YES, '     Updating app_ext_full column to Y (SUCCESS) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET app_ext_full = 'Y'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;

               END IF;

            ELSIF p_action_type = 'I' AND p_process_type = 'AR_RECEIVABLE_APP'
            THEN
               location_and_log (gc_debug, '     Determine value of retcode');

               IF p_retcode = 2
               THEN
                  location_and_log (GC_YES, '     Updating app_ext_delta column to E (ERROR) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET app_ext_delta = 'E'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;

               ELSE
                  location_and_log (GC_YES, '     Updating app_ext_delta column to Y (SUCCESS) in control table.');
                  UPDATE xx_ar_wc_ext_control
                     SET app_ext_delta = 'Y'
                        ,last_update_date = SYSDATE
                        ,last_updated_by = gn_user_id
                   WHERE cycle_date = gd_cycle_date
                     AND batch_num  = p_batch_num;
               END IF;

            ELSE
               location_and_log (gc_debug, '     Action Type = ' || p_process_type);
               location_and_log (gc_debug, '     Process Type = ' || p_process_type);
               location_and_log (gc_debug, '     Unable to update control table.');
               RAISE EX_INVALID_PROCESS_TYPE;
            END IF;

            location_and_log (GC_YES, '     Issue COMMIT for MT details table and control table updates');
            COMMIT;
         END;   -- end update status on contol table

         print_time_stamp_to_logfile;

         --========================================================================
         -- Gather Stats on Staging Table
         --========================================================================
         BEGIN
            location_and_log (GC_YES, 'Determine if gathering stats' || CHR (10));

            IF gc_compute_stats = 'Y'
            THEN
               xx_ar_wc_utility_pkg.compute_stat (gc_compute_stats, 'XXFIN', gc_staging_table);
               location_and_log (GC_YES, '     Gather Stats completed');
            ELSE
               location_and_log (GC_YES, '     Gather Stats was not executed');
            END IF;

            print_time_stamp_to_logfile;
         END;                                                                                                                         -- end gather stats

      END IF;   -- request_data check

   EXCEPTION
      WHEN EX_NO_CONTROL_RECORD THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_NO_CONTROL_RECORD at: ' || gc_error_loc);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '     No control record exists in the control table for cycle date and batch number');
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_UNABLE_TO_STAGE THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_UNABLE_TO_STAGE at: ' || gc_error_loc);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Unable to stage due to already completed or pre-requisities already met');
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_CYCLE_COMPLETED THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_CYCLE_COMPLETED at: ' || gc_error_loc);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Interface already completed for cycle date and batch number');
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_REQUEST_NOT_SUBMITTED THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_REQUEST_NOT_SUBMITTED at: ' || gc_error_loc);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Enable to submit child request.');
         ROLLBACK;
         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Rollback completed.');
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_INVALID_PROCESS_TYPE THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_INVALID_PROCESS_TYPE at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_INVALID_ACTION_TYPE THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_INVALID_ACTION_TYPE at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_PROGRAM_INFO THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_PROGRAM_INFO at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_INVALID_STATUS THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_INVALID_STATUS at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_DELTA_THREADING_ERROR THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_DELTA_THREADING_ERROR at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_NO_SUB_REQUESTS THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_NO_SUB_REQUESTS at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_INVALID_THREAD_CNT THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_INVALID_THREAD_CNT at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_NO_CHILD_THREADS_WARNING THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_NO_CHILD_THREADS_WARNING at: ' || gc_error_loc);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Setting master to WARNING status since no delta data available to extract/stage.');
         print_time_stamp_to_logfile;
         p_retcode := 1;

      WHEN NO_DATA_FOUND THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'NO_DATA_FOUND at: ' || gc_error_loc || ' .' || SQLERRM);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN OTHERS THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'WHEN OTHERS at: ' || gc_error_loc || ' .' || SQLERRM);
         print_time_stamp_to_logfile;
         p_retcode := 2;

   END master_ext;

END XX_AR_WC_MASTER_PKG;
/
show error
