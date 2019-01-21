CREATE OR REPLACE PACKAGE BODY XX_AR_RECAPPL_WC_PKG
AS
   /*==========================================================================+
   |      Office Depot - Project FIT                                           |
   |   Capgemini/Office Depot/Consulting Organization                          |
   +===========================================================================+
   |Name        :XX_AR_RECAPPL_WC_PKG                                          |
   |RICE        : I2158                                                        |
   |Description :This Package is used for insert data into staging             |
   |             table and fetch data from staging table to flat file          |
   |                                                                           |
   |            The STAGING Procedure will perform the following steps         |
   |                                                                           |
   |             1.It will fetch the records into staging table. The           |
   |               data will be either full or incremental                     |  
   |                                                                           |
   |             EXTRACT STAGING procedure will perform the following          |
   |                steps                                                      |
   |                                                                           |
   |              1.It will fetch the staging table data to flat file          |
   |                                                                           |
   |Change Record:                                                             |
   |==============                                                             |
   |Version  Date         Author                  Remarks                      |
   |=======  ===========  ======================  =============================|
   |  1.0    22-Sep-2011  Narmatha Purushothaman  Initial Version              |
   |                                                                           |
   |  1.1    16-Jan-2012  Akhilesh Agrawal        Change in rappl_full         |
   |                                              procedure for defect# 16264  |
   |                                                                           |
   |  1.2    17-Jan-2012  Akhilesh Agrawal        Change in rappl_extr proc    |
   |                                              for defect# 16328 -          |
   |                                              Grant Total is not correct   |
   |                                                                           |
   |  1.3    18-Jan-2012  R.Aldridge              Defect 16231 - tune cursor   |
   |                                              lcu_incremental for perf     |
   |                                                                           |
   |  1.4    25-Jan-2012  Mahesh                  Defect 16513    Added Set    |
   |                                              Print Option function        |
   |                                                                           |
   |  1.5    25-Jan-2012  R.Aldridge              Defect# 16439 - Tuning for   |
   |                                              full INITIAL conversion      |
   |                                                                           |
   |  1.6    02-Feb-2012  R.Aldridge              Defect# 16730 - Modify full  |
   |                                              cursors to remove data range |
   |                                                                           |
   |  1.7    02-Feb-2012  R.Aldridge              Defect# 16230 - Tuning for   |
   |                                              full DAILY conversions       |
   |                                              Defect# 16231 - Tuning for   |
   |                                              daily DELTA                  |
   |                                                                           |
   |  1.8    04-FEB-2012  R.Aldridge              Defect 16768 - Create new    | 
   |                                              utility to remove special    |
   |                                              characters                   |
   |                                                                           |
   |  1.9    04-FEB-2012  R.Aldridge              Defect 16799 - Modify delta  |
   |                                              cursor to eliminate dups from|
   |                                              being sent to Webcollect     |
   |                                                                           |
   |  2.0    07-MAR-2012  R.Aldridge              Defect 17213 - Changes for   | 
   |                                              customer_id difference       |
   |                                                                           |   
   |  2.1    28-MAR-2012  R.Aldridge              Defect 17738 - Add query for |
   |                                              inst name for file generation|
   |                                                                           |   
   |  2.2    05-ARP-2012  R.Aldridge              Defect 17925 - Add hint to   |
   |                                              try forcing paralle for conv |
   |  2.3    10-May-2012  Jay Gupta               Defect 18387 - Add Request_id|
   |                                              in LOG tables                |
   |  2.4    23-May-2012  Jay Gupta               Defect 17526 - activity name |
   |  2.5    06-Jul-2012  Jay Gupta               Defect 18389 - WC-TPS Insert |
   |  2.6    11-FEB-2016  Vasu Raparla            Removed Schema References for|
   |                                              for R.12.2                   |
   +===========================================================================*/

   -- global variables declaration
   -- Variables for Interface Settings
   gn_limit                      NUMBER;
   gn_threads_delta              NUMBER;
   gn_threads_full               NUMBER;
   gn_threads_file               NUMBER;
   gc_conc_short_delta           xx_fin_translatevalues.target_value16%TYPE;
   gc_conc_short_full            xx_fin_translatevalues.target_value17%TYPE;
   gc_conc_short_file            xx_fin_translatevalues.target_value18%TYPE;
   gc_delimiter                  xx_fin_translatevalues.target_value3%TYPE;
   gc_file_name                  xx_fin_translatevalues.target_value4%TYPE;
   gc_email                      xx_fin_translatevalues.target_value5%TYPE;
   gc_compute_stats              xx_fin_translatevalues.target_value6%TYPE;
   gn_line_size                  NUMBER;
   gc_file_path                  xx_fin_translatevalues.target_value8%TYPE;
   gn_num_records                NUMBER;
   gc_debug                      xx_fin_translatevalues.target_value10%TYPE;
   gc_ftp_file_path              xx_fin_translatevalues.target_value11%TYPE;
   gc_arch_file_path             xx_fin_translatevalues.target_value12%TYPE;
   gn_full_num_days              NUMBER;
   gc_staging_table              xx_fin_translatevalues.target_value19%TYPE;
   gb_retrieved_trans            BOOLEAN := FALSE;
   gc_err_msg_trans              VARCHAR2 (100) := NULL;
   gc_process_type               VARCHAR2 (50) := 'AR_RECEIVABLE_APP';
   gd_cycle_date                 DATE;
   GC_YES                        VARCHAR2 (1) := 'Y';
   gc_error_loc                  VARCHAR2 (2000) := NULL;

   -- Variables for Cycle Date and Batch Cycle Settings
   gc_action_type                xx_ar_mt_wc_details.action_type%TYPE;

   --  gd_cycle_date                 xx_ar_wc_ext_control.cycle_date%TYPE;
   gn_batch_num                  xx_ar_wc_ext_control.batch_num%TYPE;
   gb_ready_to_execute           BOOLEAN := FALSE;
   gb_reprocessing_required      BOOLEAN := FALSE;
   gb_retrieved_cntl             BOOLEAN := FALSE;
   gc_err_msg_cntl               VARCHAR2 (100) := NULL;
   gc_post_process_status        VARCHAR (1) := 'Y';
   gd_delta_from_date            DATE;
   gd_full_from_date             DATE;
   gd_control_to_date            DATE;
   gc_reprocess_cnt              NUMBER;
   gb_print_option               BOOLEAN;
   
   -- Custom Exceptions
   EX_NO_CONTROL_RECORD          EXCEPTION;
   EX_CYCLE_COMPLETED            EXCEPTION;
   EX_STAGING_COMPLETED          EXCEPTION;
   EX_INVALID_ACTION_TYPE        EXCEPTION;

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
   PROCEDURE print_time_stamp_to_logfile
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
      xx_ar_wc_utility_pkg.location_and_log (p_debug, p_msg);
   END location_and_log;

   /*=====================================================================================+
    | Name       : get_interface_settings                                                 |
    | Description: This procedure is used to fetch the transalation definition details    |
    |                                                                                     |
    | Parameters : none                                                                   |
    |                                                                                     |
    | Returns    : none                                                                   |
    +=====================================================================================*/
    PROCEDURE get_interface_settings
    IS
    BEGIN
      --========================================================================
      -- Retrieve Interface Settings from Translation Definition
      --========================================================================
       xx_ar_wc_utility_pkg.get_interface_settings (p_process_type           => gc_process_type
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
                                                   );
       -- Retrieve Interface Settings from Translation Definition
   END get_interface_settings;


    /*=================================================================+
    |Name        :RAPPL_FULL                                           |
    |Description :This procedure is used to fetch the total data       |
    |             from base tables to staging table                    |
    |                                                                  |
    |Parameters : p_from_cust_account_id                               |
    |             p_to_cust_account_id                                 |
    |             p_compute_stats                                      |
    |             p_debug                                              |
    |             p_thread_num                                         |
    |                                                                  |
    |Returns    : p_errbuf                                             |
    |             p_retcode                                            |
    |                                                                  |
    +==================================================================*/
   PROCEDURE rappl_full (p_errbuf                 OUT      VARCHAR2
                        ,p_retcode                OUT      NUMBER
                        ,p_cycle_date             IN       VARCHAR2
                        ,p_batch_num              IN       NUMBER
                        ,p_from_cust_account_id   IN       NUMBER
                        ,p_to_cust_account_id     IN       NUMBER
                        ,p_debug                  IN       VARCHAR2
                        ,p_thread_num             IN       NUMBER
                        ,p_process_type           IN       VARCHAR2
                        ,p_action_type            IN       VARCHAR2)
   IS
      -- Declaration of Local Variables
      ln_insert_cnt                 NUMBER := 0;
      ln_insert_tot                 NUMBER := 0;
      --Variable declaration of Table type
      lt_recappl_full        recappl_tbl_type;

      -------------------------------------------------------
      -- Cursor for Full DAILY Conversion of New Customers 
      -------------------------------------------------------
      CURSOR lcu_fulldata (p_full_from_date_f    IN   DATE
                          ,p_control_to_date_f   IN   DATE
                          ,p_total_threads_full  IN   NUMBER)
      IS
         SELECT /*+ leading (CR1) */
                CR.TYPE                                        RECEIPT_TYPE
               ,RA.receivable_application_id                   RECEIVABLE_APPLICATION_ID
               ,RA.customer_trx_id                             CUSTOMER_TRX_ID
               ,DECODE (RA.application_type
                       ,'CM', CTM.trx_number
                       ,CR.receipt_number)                     TRX_NUMBER
               ,NVL (RA.cash_receipt_id, -1)                   CASH_RECEIPT_ID
               ,NVL (RA.application_type, 'TT')                FROM_CLASS
               ,NVL (DECODE (SIGN (ra.applied_payment_schedule_id)
                            ,-1, NULL
                            ,arl.meaning
                            ), 'TC')                           TO_CLASS
               ,RA.applied_customer_trx_id                     APPLIED_CUSTOMER_TRX_ID
               ,CT.trx_number                                  APPLIED_TRX_NUMBER
               ,RA.apply_date                                  APPLY_DATE
               ,RA.amount_applied                              AMOUNT_APPLIED
               ,TO_NUMBER (DECODE (SIGN (ra.applied_payment_schedule_id)
                                  ,-1, NULL
                                  , NVL (ra.earned_discount_taken, 0) + NVL (ra.unearned_discount_taken, 0)
                                  ))                           DISCOUNT_TAKEN
               ,RA.comments                                    COMMENTS
               ,RA.status
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,RA.creation_date                               RECAPPL_CREATION_DATE
               ,p_action_type                                  EXT_TYPE -- Full
               ,gd_cycle_date                                  CYCLE_DATE
               ,p_batch_num                                    BATCH_NUM
               ,(select name from AR_RECEIVABLES_TRX where RECEIVABLES_TRX_ID = RA.RECEIVABLES_TRX_ID ) activity_name -- V2.4
           FROM ar_receivable_applications_all RA
               ,ar_cash_receipts_all           CR
               ,ar_lookups                     ARL
               ,ra_customer_trx_all            CT
               ,ra_customer_trx_all            CTM
               ,ar_payment_schedules_all       PS
               ,xx_ar_cr_wc_stg                CR1
          WHERE RA.cash_receipt_id         = CR.cash_receipt_id(+)
            AND RA.applied_customer_trx_id = CT.customer_trx_id(+)
            AND RA.customer_trx_id         = CTM.customer_trx_id(+)
            AND ARL.lookup_type            = 'APPLICATION_TYPE'
            AND ARL.lookup_code            = RA.application_type
            AND PS.payment_schedule_id     = RA.payment_schedule_id
            AND ((      RA.applied_customer_trx_id IS NOT NULL
                    OR RA.applied_customer_Trx_id <> -1)
                 OR RA.status = 'ACTIVITY')
            AND RA.cash_receipt_id  = CR1.cash_receipt_id
            AND RA.application_type = 'CASH'
            AND MOD(CR1.cash_receipt_id, p_total_threads_full) = p_thread_num - 1
            AND CR1.ext_type        = p_action_type
            AND CR1.batch_num       = p_batch_num
            AND CR1.cycle_date      = gd_cycle_date
         UNION ALL
         SELECT /*+ leading (CT1) */
                CR.TYPE                                        RECEIPT_TYPE
               ,RA.receivable_application_id                   RECEIVABLE_APPLICATION_ID
               ,RA.customer_trx_id                             CUSTOMER_TRX_ID
               ,DECODE (RA.application_type
                       ,'CM', CTM.trx_number
                       ,CR.receipt_number)                     TRX_NUMBER
               ,NVL (RA.cash_receipt_id, -1)                   CASH_RECEIPT_ID
               ,NVL (RA.application_type, 'TT')                FROM_CLASS
               ,NVL (DECODE (SIGN (ra.applied_payment_schedule_id)
                            ,-1, NULL
                            ,arl.meaning
                            ), 'TC')                           TO_CLASS
               ,RA.applied_customer_trx_id                     APPLIED_CUSTOMER_TRX_ID
               ,CT.trx_number                                  APPLIED_TRX_NUMBER                                                                                                                -- Rama change to get applied trx number
               ,RA.apply_date                                  APPLY_DATE
               ,RA.amount_applied                              AMOUNT_APPLIED
               ,TO_NUMBER (DECODE (SIGN (ra.applied_payment_schedule_id)
                                  ,-1, NULL
                                  , NVL (ra.earned_discount_taken, 0) + NVL (ra.unearned_discount_taken, 0)
                                  ))                           DISCOUNT_TAKEN
               ,RA.comments                                    COMMENTS
               ,RA.status
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,RA.creation_date                               RECAPPL_CREATION_DATE
               ,p_action_type                                  EXT_TYPE -- Full
               ,gd_cycle_date                                  CYCLE_DATE
               ,p_batch_num                                    BATCH_NUM
               ,(select name from AR_RECEIVABLES_TRX where RECEIVABLES_TRX_ID = RA.RECEIVABLES_TRX_ID ) activity_name -- V2.4
           FROM ar_receivable_applications_all RA
               ,ar_cash_receipts_all           CR
               ,ar_lookups                     ARL
               ,ra_customer_trx_all            CT
               ,ra_customer_trx_all            CTM
               ,ar_payment_schedules_all       PS
               ,xx_ar_trans_wc_stg             CT1
          WHERE RA.cash_receipt_id         = CR.cash_receipt_id(+)
            AND RA.applied_customer_trx_id = CT.customer_trx_id(+)
            AND RA.customer_trx_id         = CTM.customer_trx_id(+)
            AND ARL.lookup_type            = 'APPLICATION_TYPE'
            AND ARL.lookup_code            = RA.application_type
            AND PS.payment_schedule_id     = RA.payment_schedule_id
            AND ((      RA.applied_customer_trx_id IS NOT NULL
                    OR RA.applied_customer_Trx_id <> -1)
                 OR RA.status = 'ACTIVITY')
            AND RA.applied_customer_trx_id = CT1.customer_trx_id
            AND RA.application_type        = 'CM'
            AND MOD(CT1.customer_trx_id, p_total_threads_full) = p_thread_num - 1
            AND CT1.ext_type               = p_action_type
            AND CT1.batch_num              = p_batch_num
            AND CT1.cycle_date             = gd_cycle_date;
      
      -------------------------------------------------------
      -- Cursor for Full INITIAL Conversion of New Customers 
      --  ext_type is hardcoded to be F since action type of C
      -------------------------------------------------------
      CURSOR lcu_full_conv (p_full_from_date_f   IN   DATE
                           ,p_control_to_date_f  IN   DATE)
      IS
         SELECT /*+ LEADING(RA PS XXEC) FULL(PS) PARALLEL(PS,8) opt_param('parallel_execution_enabled', 'true') */
                CR.TYPE                                        RECEIPT_TYPE
               ,RA.receivable_application_id                   RECEIVABLE_APPLICATION_ID
               ,RA.customer_trx_id                             CUSTOMER_TRX_ID
               ,DECODE (RA.application_type
                       ,'CM', CTM.trx_number
                       ,CR.receipt_number)                     TRX_NUMBER
               ,NVL (RA.cash_receipt_id, -1)                   CASH_RECEIPT_ID
               ,NVL (RA.application_type, 'TT')                FROM_CLASS
               ,NVL (DECODE (SIGN (ra.applied_payment_schedule_id)
                            ,-1, NULL
                            ,arl.meaning
                            ), 'TC')                           TO_CLASS
               ,RA.applied_customer_trx_id                     APPLIED_CUSTOMER_TRX_ID
               ,CT.trx_number                                  APPLIED_TRX_NUMBER                                                                                                                -- Rama change to get applied trx number
               ,RA.apply_date                                  APPLY_DATE
               ,RA.amount_applied                              AMOUNT_APPLIED
               ,TO_NUMBER (DECODE (SIGN (ra.applied_payment_schedule_id)
                                  ,-1, NULL
                                  , NVL (ra.earned_discount_taken, 0) + NVL (ra.unearned_discount_taken, 0)
                                  ))                           DISCOUNT_TAKEN
               ,RA.comments                                    COMMENTS
               ,RA.status                                      STATUS
               ,gd_creation_date                               CREATION_DATE
               ,gn_created_by                                  CREATED_BY
               ,gn_request_id                                  REQUEST_ID
               ,RA.creation_date                               RECAPPL_CREATION_DATE
               ,'F'                                            EXT_TYPE
               ,gd_cycle_date                                  CYCLE_DATE
               ,p_batch_num                                    BATCH_NUM
               ,(select name from AR_RECEIVABLES_TRX where RECEIVABLES_TRX_ID = RA.RECEIVABLES_TRX_ID ) activity_name -- V2.4
         FROM (SELECT /*+ NO_MERGE PARALLEL(RA,8) */ 
                      RA.receivable_application_id
                     ,RA.customer_trx_id
                     ,RA.application_type
                     ,RA.cash_receipt_id
                     ,RA.applied_payment_schedule_id
                     ,RA.applied_customer_trx_id
                     ,RA.apply_date
                     ,RA.amount_applied
                     ,RA.earned_discount_taken
                     ,RA.unearned_discount_taken
                     ,RA.comments
                     ,RA.status
                     ,RA.creation_date
                     ,RA.payment_schedule_id
                     ,RA.RECEIVABLES_TRX_ID -- V2.4
                 FROM ar_receivable_applications_all RA 
                WHERE ((   RA.applied_customer_trx_id  IS NOT NULL
                        OR RA.applied_customer_trx_id  <> -1)
                        OR RA.status                    = 'ACTIVITY')
                  AND EXISTS (SELECT '1'
                                 FROM xx_ar_cr_wc_stg CR1
                                WHERE RA.cash_receipt_id = CR1.cash_receipt_id
                                  AND RA.application_type  = 'CASH'
                                  AND CR1.ext_type         = 'F'
                                  AND CR1.batch_num        = batch_num
                                  AND CR1.cycle_date       = gd_cycle_date
                              UNION ALL
                              SELECT '1'
                                FROM xx_ar_trans_wc_stg CT1
                               WHERE RA.applied_customer_trx_id = CT1.CUSTOMER_TRX_ID
                                 AND RA.application_type        = 'CM'
                                 AND CT1.ext_type               = 'F' 
                                 AND CT1.batch_num              = batch_num
                                 AND CT1.cycle_date             = gd_cycle_date)
              ) RA
             ,ar_cash_receipts_all     CR
             ,ar_lookups               ARL
             ,ra_customer_trx_all      CT
             ,ra_customer_trx_all      CTM
             ,ar_payment_schedules_all PS
        WHERE RA.cash_receipt_id          = CR.cash_receipt_id(+)
          AND RA.applied_customer_trx_id  = CT.customer_trx_id(+)
          AND RA.customer_trx_id          = CTM.customer_trx_id(+)
          AND ARL.lookup_type             = 'APPLICATION_TYPE'
          AND ARL.Lookup_Code             = RA.application_type
          AND PS.payment_schedule_id      = RA.payment_schedule_id;
          
  BEGIN
      --========================================================================
      -- Initialize Processing - FULL
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Initialize Processing');
         gc_process_type := p_process_type;
         gd_cycle_date   := fnd_date.canonical_to_date (p_cycle_date);

         FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************ENTERED PARAMETERS FOR REC APPLICATIONS (FULL)*******************');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Cycle Date               :' || p_cycle_date);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Batch number             :' || p_batch_num);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'From Customer Account ID :' || p_from_cust_account_id);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'To Customer Account ID   :' || p_to_cust_account_id);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag               :' || p_debug);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Thread Number            :' || p_thread_num);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Process Type             :' || p_process_type);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Action Type              :' || p_action_type);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '**********************************************************************************');
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Retrieve Interface Settings from Translation Definition
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Retrieving Interface Settings From Translation Definition' || CHR (10));
         get_interface_settings;
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Override Debug and Gather Statistics with Parameter Values if NOT NULL
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Determine if parameter value for debug is used' || CHR (10));
         gc_debug := xx_ar_wc_utility_pkg.validate_param_trans_value (p_debug, gc_debug);

         FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** PARAMETER OVERRIDES *****************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag             : ' || gc_debug);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
      END;

      print_time_stamp_to_logfile;

      --==================================================================
      -- Retrieve Cycle Date Information from Control Table
      --==================================================================
      BEGIN
         location_and_log (GC_YES, 'Calling get_control_info to evaluate cucle date information' || CHR (10));
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
      -- Validate Control Information to Determine Processing Required
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Validate Control Information to Determine Processing Required');

         location_and_log (gc_debug, '     Evaluate Control Record Status.' || CHR (10));
         IF NOT gb_retrieved_cntl THEN
            location_and_log (GC_YES, gc_error_loc || ' Control Record Not Retrieved');
            RAISE EX_NO_CONTROL_RECORD;

         ELSIF gc_post_process_status = 'Y' THEN
            location_and_log (GC_YES, gc_error_loc || ' Cycle Date and Batch Number Already Completed.');
            RAISE EX_CYCLE_COMPLETED;

         ELSIF gb_ready_to_execute = FALSE THEN
            location_and_log (GC_YES, gc_error_loc || ' Data has already been staged for this process.');
            RAISE EX_STAGING_COMPLETED;
         END IF;
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Retrieve and Stage Data
      --========================================================================
      IF p_action_type = 'F' THEN

         -----------------------------------
         -- Process Full DAILY Conversions
         -----------------------------------
         BEGIN
            location_and_log (GC_YES, 'Retrieve and Stage Data' || CHR (10));

            location_and_log (gc_debug, '     Opening cursor lcu_fulldata'|| CHR (10));
            OPEN lcu_fulldata (p_full_from_date_f   => gd_full_from_date
                              ,p_control_to_date_f  => gd_control_to_date
                              ,p_total_threads_full => gn_threads_full);

            LOOP
               location_and_log (gc_debug, '     Fetching from lcu_fulldata at '||  TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
               FETCH lcu_fulldata
               BULK COLLECT INTO lt_recappl_full LIMIT gn_limit;

               FORALL i IN 1 .. lt_recappl_full.COUNT
                  INSERT INTO xx_ar_recappl_wc_stg
                       VALUES lt_recappl_full (i);
               IF lt_recappl_full.COUNT > 0
                    THEN
                       location_and_log (GC_YES, '     lt_recappl_full.COUNT = ' || lt_recappl_full.COUNT);
                       ln_insert_cnt := SQL%ROWCOUNT;
                       ln_insert_tot := ln_insert_tot + ln_insert_cnt;
                    END IF;

                    location_and_log (gc_debug, '     Records Inserted into XX_AR_RECAPPL_WC_STG for ' || ' : ' || ln_insert_cnt);
                    location_and_log (gc_debug, '     Full - Issue commit for inserting into XX_AR_RECAPPL_WC_STG table');
               COMMIT;
               EXIT WHEN lcu_fulldata%NOTFOUND;
            END LOOP;

            CLOSE lcu_fulldata;

            --lcu_fulldata curosr Loop ended here
            location_and_log (gc_debug, '     Closed cursor lcu_fulldata');
         END;

      ELSIF p_action_type = 'C' THEN
         -----------------------------------
         -- Process Full INITIAL Conversion
         -----------------------------------
         BEGIN
            location_and_log (GC_YES, 'Retrieve and Stage Data' || CHR (10));

            location_and_log (gc_debug, '     Opening cursor lcu_full_conv'|| CHR (10));
            OPEN lcu_full_conv (p_full_from_date_f  => gd_full_from_date
                               ,p_control_to_date_f => gd_control_to_date);

            LOOP
               location_and_log (gc_debug, '     Fetching from lcu_full_conv at '||  TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
               FETCH lcu_full_conv
               BULK COLLECT INTO lt_recappl_full LIMIT gn_limit;

               FORALL i IN 1 .. lt_recappl_full.COUNT
                  INSERT INTO xx_ar_recappl_wc_stg
                       VALUES lt_recappl_full (i);
               
               IF lt_recappl_full.COUNT > 0
                    THEN
                       location_and_log (GC_YES, '     lt_recappl_full.COUNT = ' || lt_recappl_full.COUNT);
                       ln_insert_cnt := SQL%ROWCOUNT;
                       ln_insert_tot := ln_insert_tot + ln_insert_cnt;
                    END IF;

                    location_and_log (gc_debug, '     Records Inserted into XX_AR_RECAPPL_WC_STG for ' || ' : ' || ln_insert_cnt);
                    location_and_log (gc_debug, '     Full - Issue commit for inserting into XX_AR_RECAPPL_WC_STG table');
               COMMIT;
               EXIT WHEN lcu_full_conv%NOTFOUND;
            END LOOP;

            location_and_log (gc_debug, '     Closed cursor lcu_full_conv');
            CLOSE lcu_full_conv;

            location_and_log (gc_debug, '     Update control table');
            UPDATE xx_ar_wc_ext_control
               SET app_ext_full = 'Y'
             WHERE app_ext_full = 'C'
               AND cycle_date = gd_cycle_date
               AND batch_num  = p_batch_num;
            COMMIT;
         END;
      
      ELSE
         location_and_log (gc_debug, gc_error_loc || ' - Invalid Action Type Parameter Value');
         RAISE EX_INVALID_ACTION_TYPE;
      END IF;      
         
      print_time_stamp_to_logfile;

      --========================================================================
      -- Write Records Processed to Log File
      --========================================================================
     location_and_log (GC_YES, 'Total Records Inserted into XX_AR_RECAPPL_WC_STG: ' || ln_insert_tot);
           
                 -- V2.5, Calling procedure to insert into int log table
         DECLARE
            ln_int_prod_run_id number;
         BEGIN
            SELECT xx_crmar_int_log_s.NEXTVAL
              INTO ln_int_prod_run_id
              FROM DUAL;

		SELECT FCP.CONCURRENT_PROGRAM_NAME,
                   FCP.USER_CONCURRENT_PROGRAM_NAME   
              INTO gc_program_short_name, gc_program_name
              FROM FND_CONCURRENT_PROGRAMS_VL FCP,
                   FND_CONCURRENT_REQUESTS FCR
             WHERE FCP.CONCURRENT_PROGRAM_ID = FCR.CONCURRENT_PROGRAM_ID
                AND FCR.REQUEST_ID = gn_request_id;

            INSERT INTO xx_crmar_int_log
                     (program_run_id
                     ,program_name
                     ,program_short_name
                     ,module_name
                     ,program_run_date
                     ,filename
                     ,total_files
                     ,total_records
                     ,status
                     ,MESSAGE
                     ,request_id 
                     ,cycle_date
                     ,batch_num
                     )
              VALUES (ln_int_prod_run_id
                     ,gc_program_name
                     ,gc_program_short_name
                     ,gc_module_name
                     ,SYSDATE
                     ,null
                     ,null
                     ,ln_insert_cnt
                     ,'SUCCESS'
                     ,null
                     , gn_request_id  
                     , gd_cycle_date
                     , p_batch_num
                     );
             COMMIT;
          EXCEPTION
          WHEN OTHERS THEN
             FND_FILE.PUT_LINE (FND_FILE.LOG, 'Others exception is raised while Inserting records into INT LOG Table '|| SQLERRM);
             print_time_stamp_to_logfile;
             p_retcode := 2;
          END;


   EXCEPTION
      WHEN EX_INVALID_ACTION_TYPE THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_INVALID_ACTION_TYPE at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;
      WHEN EX_NO_CONTROL_RECORD THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_NO_CONTROL_RECORD at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_CYCLE_COMPLETED THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_CYCLE_COMPLETED at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_STAGING_COMPLETED THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_STAGING_COMPLETED at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN OTHERS THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Others exception is raised while fetching full data from Rec Application base tables' || SQLERRM);
         print_time_stamp_to_logfile;
         p_retcode := 2;

   END rappl_full;

    /*=================================================================+
    |Name        :RAPPL_INCR                                           |
    |Description :This procedure is used to fetch the incremental data |
    |              from base tables to staging table                   |
    |                                                                  |
    |Parameters :p_last_run_date                                       |
    |            p_to_run_date                                         |
    |            p_from_recappl_id                                     |
    |            p_to_recappl_id                                       |
    |            p_debug                                               |
    |            p_thread_num                                          |
    |                                                                  |
    |Returns    :p_errbuf                                              |
    |            p_retcode                                             |
    |                                                                  |
    +==================================================================*/
   PROCEDURE rappl_incr (p_errbuf                 OUT      VARCHAR2
                        ,p_retcode                OUT      NUMBER
                        ,p_cycle_date             IN       VARCHAR2
                        ,p_batch_num              IN       NUMBER
                        ,p_from_recappl_id        IN       NUMBER
                        ,p_to_recappl_id          IN       NUMBER
                        ,p_debug                  IN       VARCHAR2
                        ,p_thread_num             IN       NUMBER
                        ,p_process_type           IN       VARCHAR2
                        ,p_action_type            IN       VARCHAR2)
   IS
      -- Declaration of Local Variables
      ln_insert_cnt                 NUMBER := 0;
      ln_insert_tot                 NUMBER := 0;
      --Variable declaration of Table type
      lt_recappl_incr        recappl_tbl_type;

      -------------------------------------------------------
      -- Cursor for DELTA for Eligibile Customers Sent to WC
      -------------------------------------------------------
      CURSOR lcu_incremental (p_delta_from_date_d  DATE
                             ,p_control_to_date_d  DATE)
      IS
         -- Receivable Applications by creation date
         SELECT /*+ LEADING(RA) index(xxec XX_CRM_WCELG_CUST_N1)*/
                CR.TYPE receipt_type
               ,RA.receivable_application_id receivable_application_id
               ,RA.customer_trx_id customer_trx_id
               ,DECODE (RA.application_type
                       ,'CM', CTM.trx_number
                       ,CR.receipt_number
                       ) trx_number                                                                                                                                             --changed per defect 134
               ,NVL (RA.cash_receipt_id, -1) cash_receipt_id
               ,NVL (RA.application_type, 'TT') from_class
               ,NVL (DECODE (SIGN (ra.applied_payment_schedule_id)
                            ,-1, NULL
                            ,arl.meaning
                            ), 'TC') to_class
               ,RA.applied_customer_trx_id applied_customer_trx_id
               ,CT.trx_number applied_trx_number                                                                                                                -- Rama change to get applied trx number
               ,RA.apply_date apply_date
               ,RA.amount_applied amount_applied
               ,TO_NUMBER (DECODE (SIGN (ra.applied_payment_schedule_id)
                                  ,-1, NULL
                                  , NVL (ra.earned_discount_taken, 0) + NVL (ra.unearned_discount_taken, 0)
                                  )) discount_taken
               ,RA.comments comments
               ,RA.status
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,RA.creation_date recappl_creation_date
               ,p_action_type    Delta
               ,gd_cycle_date    cycle_date
               ,p_batch_num      batch_num
               ,(select name from AR_RECEIVABLES_TRX where RECEIVABLES_TRX_ID = RA.RECEIVABLES_TRX_ID ) activity_name -- V2.4
           FROM ar_receivable_applications_all RA
               ,ar_cash_receipts_all           CR
               ,ar_lookups                     ARL
               ,ra_customer_trx_all            CT
               ,ra_customer_trx_all            CTM
               ,ar_payment_schedules_all       PS
               ,xx_crm_wcelg_cust              XXEC
          WHERE RA.cash_receipt_id         = CR.cash_receipt_id(+)
            AND RA.applied_customer_trx_id = CT.customer_trx_id(+)
            AND RA.customer_trx_id         = CTM.customer_trx_id(+)
            AND ARL.lookup_type            = 'APPLICATION_TYPE'
            AND ARL.lookup_code            = RA.application_type
            AND PS.payment_schedule_id     = RA.payment_schedule_id
            AND ((      RA.applied_customer_trx_id IS NOT NULL
                    OR  RA.applied_customer_Trx_id <> -1)
                 OR RA.status = 'ACTIVITY')
            -- eligible receivable applications
            AND RA.creation_date             BETWEEN p_delta_from_date_d
                                                 AND p_control_to_date_d
            AND MOD(RA.receivable_application_id, gn_threads_delta) = p_thread_num - 1
            -- eligible customers with AR converted
            AND XXEC.cust_account_id    = PS.customer_id
            AND XXEC.ar_converted_flag  = 'Y'
            AND XXEC.cust_mast_head_ext = 'Y'
         UNION ALL
         -- Receivable Applications for Staged Transactions
         SELECT CR.TYPE receipt_type
               ,RA.receivable_application_id receivable_application_id
               ,RA.customer_trx_id customer_trx_id
               ,DECODE (RA.application_type
                       ,'CM', CTM.trx_number
                       ,CR.receipt_number
                       ) trx_number                                                                                                                                             --changed per defect 134
               ,NVL (RA.cash_receipt_id, -1) cash_receipt_id
               ,NVL (RA.application_type, 'TT') from_class
               ,NVL (DECODE (SIGN (ra.applied_payment_schedule_id)
                            ,-1, NULL
                            ,arl.meaning
                            ), 'TC') to_class
               ,RA.applied_customer_trx_id applied_customer_trx_id
               ,CT.trx_number applied_trx_number                                                                                                                -- Rama change to get applied trx number
               ,RA.apply_date apply_date
               ,RA.amount_applied amount_applied
               ,TO_NUMBER (DECODE (SIGN (ra.applied_payment_schedule_id)
                                  ,-1, NULL
                                  , NVL (ra.earned_discount_taken, 0) + NVL (ra.unearned_discount_taken, 0)
                                  )) discount_taken
               ,RA.comments comments
               ,RA.status
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,RA.creation_date recappl_creation_date
               ,p_action_type    Delta
               ,gd_cycle_date    cycle_date
               ,p_batch_num      batch_num
               ,(select name from AR_RECEIVABLES_TRX where RECEIVABLES_TRX_ID = RA.RECEIVABLES_TRX_ID ) activity_name -- V2.4
           FROM ar_receivable_applications_all RA
               ,ar_cash_receipts_all           CR
               ,ar_lookups                     ARL
               ,ra_customer_trx_all            CT
               ,ra_customer_trx_all            CTM
               ,ar_payment_schedules_all       PS
               ,xx_ar_trans_wc_stg             XXPS
               ,xx_crm_wcelg_cust              XCWC
          WHERE RA.cash_receipt_id         = CR.cash_receipt_id(+)
            AND RA.applied_customer_trx_id = CT.customer_trx_id(+)
            AND RA.customer_trx_id         = CTM.customer_trx_id(+)
            AND ARL.lookup_type            = 'APPLICATION_TYPE'
            AND ARL.lookup_code            = RA.application_type
            AND PS.payment_schedule_id     = RA.payment_schedule_id
            AND ((      RA.applied_customer_trx_id IS NOT NULL
                    OR  RA.applied_customer_Trx_id <> -1)
                 OR RA.status = 'ACTIVITY')
            -- eligible receivable applications
            AND MOD(RA.receivable_application_id, gn_threads_delta) = p_thread_num - 1
            AND XXPS.trx_creation_date < p_delta_from_date_d
            AND XXPS.ext_type          = p_action_type
            AND XXPS.batch_num         = p_batch_num
            AND XXPS.cycle_date        = gd_cycle_date
            AND XXPS.customer_trx_id   = RA.applied_customer_trx_id
            AND NOT EXISTS (SELECT /*+ USE_NL(RECTRX) INDEX(RECTRX XX_AR_WC_CNV_REC_TRX_U1) */ 1
                              FROM xx_ar_wc_converted_rec_trx RECTRX
                             WHERE RECTRX.id = XXPS.customer_trx_id
                               AND RECTRX.type = 'TRX')
            AND XXPS.bill_to_customer_id = XCWC.cust_account_id
            AND XXPS.trx_creation_date   < XCWC.ar_conv_from_date_full
         UNION ALL
         -- Receivable Applications for Staged Receipts
         SELECT CR.TYPE receipt_type
               ,RA.receivable_application_id receivable_application_id
               ,RA.customer_trx_id customer_trx_id
               ,DECODE (RA.application_type
                       ,'CM', CTM.trx_number
                       ,CR.receipt_number
                       ) trx_number                                                                                                                                             --changed per defect 134
               ,NVL (RA.cash_receipt_id, -1) cash_receipt_id
               ,NVL (RA.application_type, 'TT') from_class
               ,NVL (DECODE (SIGN (ra.applied_payment_schedule_id)
                            ,-1, NULL
                            ,arl.meaning
                            ), 'TC') to_class
               ,RA.applied_customer_trx_id applied_customer_trx_id
               ,CT.trx_number applied_trx_number                                                                                                                -- Rama change to get applied trx number
               ,RA.apply_date apply_date
               ,RA.amount_applied amount_applied
               ,TO_NUMBER (DECODE (SIGN (ra.applied_payment_schedule_id)
                                  ,-1, NULL
                                  , NVL (ra.earned_discount_taken, 0) + NVL (ra.unearned_discount_taken, 0)
                                  )) discount_taken
               ,RA.comments comments
               ,RA.status
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,RA.creation_date recappl_creation_date
               ,p_action_type    Delta
               ,gd_cycle_date    cycle_date
               ,p_batch_num      batch_num
               ,(select name from AR_RECEIVABLES_TRX where RECEIVABLES_TRX_ID = RA.RECEIVABLES_TRX_ID ) activity_name -- V2.4
           FROM ar_receivable_applications_all RA
               ,ar_cash_receipts_all           CR
               ,ar_lookups                     ARL
               ,ra_customer_trx_all            CT
               ,ra_customer_trx_all            CTM
               ,ar_payment_schedules_all       PS
               ,xx_ar_cr_wc_stg                XXPS
               ,xx_crm_wcelg_cust              XCWC
          WHERE RA.cash_receipt_id         = CR.cash_receipt_id(+)
            AND RA.applied_customer_trx_id = CT.customer_trx_id(+)
            AND RA.customer_trx_id         = CTM.customer_trx_id(+)
            AND ARL.lookup_type            = 'APPLICATION_TYPE'
            AND ARL.lookup_code            = RA.application_type
            AND PS.payment_schedule_id     = RA.payment_schedule_id
            AND ((      RA.applied_customer_trx_id IS NOT NULL
                    OR  RA.applied_customer_Trx_id <> -1)
                 OR RA.status = 'ACTIVITY')
            -- eligible receivable applications
            AND MOD(RA.receivable_application_id, gn_threads_delta) = p_thread_num - 1
            AND XXPS.rec_creation_date < p_delta_from_date_d
            AND XXPS.ext_type          = p_action_type
            AND XXPS.batch_num         = p_batch_num
            AND XXPS.cycle_date        = gd_cycle_date
            AND XXPS.cash_receipt_id   = RA.cash_receipt_id
            AND NOT EXISTS (SELECT /*+ USE_NL(RECTRX) INDEX(RECTRX XX_AR_WC_CNV_REC_TRX_U1) */ 1
                              FROM xx_ar_wc_converted_rec_trx RECTRX
                             WHERE RECTRX.id   = XXPS.cash_receipt_id
                               AND RECTRX.type = 'REC')
           AND XXPS.customer_account_id = XCWC.cust_account_id
           AND XXPS.rec_creation_date   < XCWC.ar_conv_from_date_full;

   BEGIN
      --========================================================================
      -- Initialize Processing - DELTA
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Initialize Processing');
         gc_process_type := p_process_type;
         gd_cycle_date   := fnd_date.canonical_to_date (p_cycle_date);

         FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************ENTERED PARAMETERS FOR REC APPLICATIONS(INCREMENTAL)************');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Cycle Date               :' || p_cycle_date);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Batch number             :' || p_batch_num);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'From Receivable APP ID   :' || p_from_recappl_id);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'To Receivable APP ID     :' || p_to_recappl_id);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag               :' || p_debug);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Thread Number            :' || p_thread_num);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Process Type             :' || p_process_type);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Action Type              :' || p_action_type);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '**********************************************************************************');
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Retrieve Interface Settings from Translation Definition
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Retrieving Interface Settings From Translation Definition' || CHR (10));
         get_interface_settings;
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Override Debug and Gather Statistics with Parameter Values if NOT NULL
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Determine if parameter value for debug is used' || CHR (10));
         gc_debug := xx_ar_wc_utility_pkg.validate_param_trans_value (p_debug, gc_debug);

         FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** PARAMETER OVERRIDES *****************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag             : ' || gc_debug);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
      END;

      print_time_stamp_to_logfile;

      --==================================================================
      -- Retrieve Cycle Date Information from Control Table
      --==================================================================
      BEGIN
         location_and_log (GC_YES, 'Calling get_control_info to evaluate cucle date information');
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
      -- Validate Control Information to Determine Processing Required
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Validate Control Information to Determine Processing Required' || CHR (10));

         location_and_log (gc_debug, '     Evaluate Control Record Status.');
         IF NOT gb_retrieved_cntl THEN
            location_and_log (GC_YES, gc_error_loc || ' Control Record Not Retrieved');
            RAISE EX_NO_CONTROL_RECORD;

         ELSIF gc_post_process_status = 'Y' THEN
            location_and_log (GC_YES, gc_error_loc || ' Cycle Date and Batch Number Already Completed.');
            RAISE EX_CYCLE_COMPLETED;

         ELSIF gb_ready_to_execute = FALSE THEN
            location_and_log (GC_YES, gc_error_loc || ' Data has already been staged for this process.');
            RAISE EX_STAGING_COMPLETED;
         END IF;
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Retrieve and Stage Data
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Retrieve and Stage Data' || CHR (10));

         location_and_log (gc_debug, '     Opening cursor lcu_incremental'|| CHR (10));
         OPEN lcu_incremental (p_delta_from_date_d => gd_delta_from_date
                              ,p_control_to_date_d => gd_control_to_date);

         LOOP
            location_and_log (gc_debug, '     Fetching from lcu_incremental at '||  TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
            FETCH lcu_incremental
            BULK COLLECT INTO lt_recappl_incr LIMIT gn_limit;

            FORALL i IN 1 .. lt_recappl_incr.COUNT
               INSERT INTO xx_ar_recappl_wc_stg
                    VALUES lt_recappl_incr (i);
             IF lt_recappl_incr.COUNT > 0
                 THEN
                    location_and_log (GC_YES, '     lt_recappl_incr.COUNT = ' || lt_recappl_incr.COUNT);
                    ln_insert_cnt := SQL%ROWCOUNT;
                    ln_insert_tot := ln_insert_tot + ln_insert_cnt;
                 END IF;

                 location_and_log (gc_debug, '     Records Inserted into XX_AR_RECAPPL_WC_STG for ' || ' : ' || ln_insert_cnt);
                 location_and_log (gc_debug, '     DELTA - Issue commit for inserting into XX_AR_PS_WC_STG table');
            COMMIT;
            EXIT WHEN lcu_incremental%NOTFOUND;
         END LOOP;

         CLOSE lcu_incremental;
         location_and_log (gc_debug, '     Closed cursor lcu_incremental');

      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Write Records Processed to Log File
      --========================================================================
      location_and_log (GC_YES, 'Total Records Inserted into XX_AR_RECAPPL_WC_STG: ' || ln_insert_tot);

            
         -- V2.5, Calling procedure to insert into int log table
         DECLARE
            ln_int_prod_run_id number;
         BEGIN
            SELECT xx_crmar_int_log_s.NEXTVAL
              INTO ln_int_prod_run_id
              FROM DUAL;

		SELECT FCP.CONCURRENT_PROGRAM_NAME,
                   FCP.USER_CONCURRENT_PROGRAM_NAME   
              INTO gc_program_short_name, gc_program_name
              FROM FND_CONCURRENT_PROGRAMS_VL FCP,
                   FND_CONCURRENT_REQUESTS FCR
             WHERE FCP.CONCURRENT_PROGRAM_ID = FCR.CONCURRENT_PROGRAM_ID
                AND FCR.REQUEST_ID = gn_request_id;

            INSERT INTO xx_crmar_int_log
                     (program_run_id
                     ,program_name
                     ,program_short_name
                     ,module_name
                     ,program_run_date
                     ,filename
                     ,total_files
                     ,total_records
                     ,status
                     ,MESSAGE
                     ,request_id 
                     ,cycle_date
                     ,batch_num
                     )
              VALUES (ln_int_prod_run_id
                     ,gc_program_name
                     ,gc_program_short_name
                     ,gc_module_name
                     ,SYSDATE
                     ,null
                     ,null
                     ,ln_insert_cnt
                     ,'SUCCESS'
                     ,null
                     , gn_request_id  
                     , gd_cycle_date
                     , p_batch_num
                     );
             COMMIT;
          EXCEPTION
          WHEN OTHERS THEN
             FND_FILE.PUT_LINE (FND_FILE.LOG, 'Others exception is raised while Inserting records into INT LOG Table '|| SQLERRM);
             print_time_stamp_to_logfile;
             p_retcode := 2;
          END;

   EXCEPTION
      WHEN EX_NO_CONTROL_RECORD THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_NO_CONTROL_RECORD at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_CYCLE_COMPLETED THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_CYCLE_COMPLETED at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_STAGING_COMPLETED THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_STAGING_COMPLETED at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN OTHERS THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Exception raised while fetching full data from Rec Application base tables' || SQLERRM);
         p_retcode := 2;
   END rappl_incr;

    /*=================================================================+
    |Name        :RAPPL_EXTR                                           |
    |Description :This procedure is used to fetch the staging table    |
    |             data to flat file                                    |
    |                                                                  |
    |Parameters : p_debug                                              |
    |                                                                  |
    |Returns    : p_errbuf                                             |
    |             p_retcode                                            |
    |                                                                  |
    +==================================================================*/
   PROCEDURE rappl_extr (p_errbuf         OUT     VARCHAR2
                        ,p_retcode        OUT     NUMBER
                        ,p_cycle_date     IN      VARCHAR2
                        ,p_batch_num      IN      NUMBER
                        ,p_debug          IN      VARCHAR2
                        ,p_process_type   IN      VARCHAR2
                        ,p_action_type    IN      VARCHAR2)
   IS
      lc_filehandle         UTL_FILE.file_type;
      lc_file               VARCHAR2 (100)                               := '_' || TO_CHAR (SYSDATE, 'YYYYMMDD_HH24MISS');
      lc_message            VARCHAR2 (4000);
      lc_file_name          VARCHAR2 (100);
      lc_mode               VARCHAR2 (1)                                 := 'W';
      ln_count              NUMBER                                       := 0;
      ln_cnt                NUMBER                                       := 0;
      ln_fno                NUMBER                                       := 1;
      ln_tot_count          NUMBER                                       := 0;
      lc_flag               VARCHAR2 (1)                                 := 'N';
      --Variable declaration of Table type
      ln_ftp_request_id     NUMBER                                       := 0;
      lc_source_path_name   xx_fin_translatevalues.target_value11%TYPE;
      ln_idx                NUMBER                                       := 1;
      ln_fn_idx             NUMBER                                       := 1;
      lc_dev_phase          fnd_lookup_values.meaning%TYPE;
      lc_dev_status         fnd_lookup_values.meaning%TYPE;
      lc_phase              fnd_lookup_values.meaning%TYPE;
      lc_status             fnd_lookup_values.meaning%TYPE;
      lc_msg                VARCHAR2 (2000);
      ln_recappl_id         NUMBER                                       := 0;
      ln_retcode            NUMBER                                       := 0;
      lc_inst               VARCHAR2(5);

      -- Declaration of Table type and variable
      ar_recappl_stg        recappl_tbl_type;
      lt_req_id             reqid_tbl_type;
      lt_filename           filename_tbl_type;
      lc_int_filename       varchar2(100); -- V2.4

      ---------------------------------------------------------------------
      --cursor declaration: This is used to fetech the staging table data
      ---------------------------------------------------------------------
      CURSOR lcu_recappl
      IS
         SELECT *
           FROM xx_ar_recappl_wc_stg
         ORDER BY receivable_application_id ASC
                 ,app_creation_date         DESC;
   BEGIN
      --========================================================================
      -- Initialize Processing
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Initialize Processing');
         gc_process_type := p_process_type;
         gd_cycle_date   := fnd_date.canonical_to_date (p_cycle_date);

         FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************ENTERED PARAMETERS FOR AR TRANSACTIONS(EXTRACT)*******************');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Cycle Date               :' || p_cycle_date);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Batch number             :' || p_batch_num);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag               :' || p_debug);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Process Type             :' || p_process_type);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Action Type              :' || p_action_type);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '**********************************************************************************');

         print_time_stamp_to_logfile;

         location_and_log (GC_YES, 'Counting the number of records in staging table');
         SELECT COUNT (*)
           INTO ln_cnt
           FROM xx_ar_recappl_wc_stg;
         location_and_log (GC_YES, 'Total Records in the Staging table Before Processing: '||ln_cnt);

         location_and_log (GC_YES, CHR (10)||'Capture Instance Name');
         SELECT substr(instance_name,4,5) 
           INTO lc_inst
           FROM v$instance;
      END;

         location_and_log (GC_YES, '     Generate the nextvalue from xx_crmar_int_log_s ');
         SELECT xx_crmar_int_log_s.NEXTVAL
           INTO gn_nextval
           FROM DUAL;

         location_and_log (GC_YES, 'Nextvalue from xx_crmar_int_log_s                   : '||gn_nextval|| CHR (10));

      --========================================================================
      -- Retrieve Interface Settings from Translation Definition
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Retrieving Interface Settings From Translation Definition' || CHR (10));
         get_interface_settings;

         location_and_log (GC_YES, '     Deriving the source directory path');
         BEGIN
            SELECT ad.directory_path
              INTO lc_source_path_name
              FROM all_directories ad
             WHERE directory_name = gc_file_path;
            location_and_log (GC_YES, '     Source Path'||lc_source_path_name);
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               FND_FILE.PUT_LINE (FND_FILE.LOG, SQLCODE || 'No data found while getting directory path ');
         END;
      END;

      print_time_stamp_to_logfile;

    --========================================================================
    -- Override Debug and Gather Statistics with Parameter Values if NOT NULL
    --========================================================================
    BEGIN
       location_and_log (GC_YES, 'Determine if parameter value for debug is used' || CHR (10));
       gc_debug := xx_ar_wc_utility_pkg.validate_param_trans_value (p_debug, gc_debug);

       FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** PARAMETER OVERRIDES *****************************');
       FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag             : ' || gc_debug);
       FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
      END;

      print_time_stamp_to_logfile;

      --==================================================================
      -- Retrieve Cycle Date Information from Control Table
      --==================================================================
      BEGIN
         location_and_log (GC_YES, 'Calling get_control_info to evaluate cucle date information');
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
      -- Validate Control Information to Determine Processing Required
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Validate Control Information to Determine Processing Required' || CHR (10));
         IF NOT gb_retrieved_cntl THEN
            location_and_log (GC_YES, gc_error_loc || ' Control Record Not Retrieved');
            RAISE EX_NO_CONTROL_RECORD;

         ELSIF gc_post_process_status = 'Y' THEN
            location_and_log (GC_YES, gc_error_loc || ' Cycle Date and Batch Number Already Completed.');
            RAISE EX_CYCLE_COMPLETED;

         ELSIF gb_ready_to_execute = FALSE THEN
            location_and_log (GC_YES, gc_error_loc || ' Data has already been staged for this process.');
            RAISE EX_STAGING_COMPLETED;
         END IF;
      END;

      FND_FILE.PUT_LINE (FND_FILE.LOG, '**************DERIVED PARAMETERS(EXTRACT)***************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Batch Limit       :' || gn_limit);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Delimiter         :' || gc_delimiter);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'File Path         :' || gc_file_path);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'File Name         :' || gc_file_name);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'File Size         :' || gn_line_size);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Source File Path  :' || lc_source_path_name);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Target File Path  :' || gc_ftp_file_path);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Archive File Path :' || gc_arch_file_path);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'No. of Records    :' || gn_num_records);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag        :' || gc_debug);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************');

      print_time_stamp_to_logfile;

      --========================================================================
      -- Retrieve Data and Create Files
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Retrieve Data and Create Files');

         -- V2.3 lc_file_name := gc_file_name || '_' || lc_inst || lc_file || '-' || ln_fno || '.dat';
         lc_file_name := gc_file_name || '_' || lc_inst || '_' || p_batch_num|| lc_file || '-' || ln_fno || '.dat';
         lt_filename (ln_fn_idx) := lc_file_name;
         ln_fn_idx := ln_fn_idx + 1;
         location_and_log (gc_debug, '     Before Opening the UTL File');
         lc_filehandle := UTL_FILE.fopen (gc_file_path
                                         ,lc_file_name
                                         ,lc_mode
                                         ,gn_line_size
                                         );

      IF ln_cnt >0 THEN

         location_and_log (gc_debug, '     Before Opening the Data Cursor');
         OPEN lcu_recappl;

         LOOP
            FETCH lcu_recappl
            BULK COLLECT INTO ar_recappl_stg LIMIT gn_limit;

            FOR i IN 1 .. ar_recappl_stg.COUNT
            LOOP
               --This condition is to avoid duplicates
               IF ar_recappl_stg (i).receivable_application_id <> ln_recappl_id THEN
                  lc_message := XX_AR_WC_UTILITY_PKG.remove_special_characters(
                        ar_recappl_stg (i).receipt_type
                     || gc_delimiter
                     || ar_recappl_stg (i).receivable_application_id
                     || gc_delimiter
                     || ar_recappl_stg (i).customer_trx_id
                     || gc_delimiter
                     || ar_recappl_stg (i).trx_number
                     || gc_delimiter
                     || ar_recappl_stg (i).cash_receipt_id
                     || gc_delimiter
                     || ar_recappl_stg (i).from_class
                     || gc_delimiter
                     || ar_recappl_stg (i).to_class
                     || gc_delimiter
                     || ar_recappl_stg (i).applied_customer_trx_id
                     || gc_delimiter
                     || ar_recappl_stg (i).applied_trx_number
                     || gc_delimiter
                     || ar_recappl_stg (i).apply_date
                     || gc_delimiter
                     || ar_recappl_stg (i).amount_applied
                     || gc_delimiter
                     || ar_recappl_stg (i).discount_taken
                     || gc_delimiter
                     || ar_recappl_stg (i).comments
                     || gc_delimiter
                     || ar_recappl_stg (i).status
                     || gc_delimiter  
                     || ar_recappl_stg (i).activity_name);
                  -- V2.4, added activity_name 

                  ln_recappl_id := ar_recappl_stg (i).receivable_application_id;
                  ln_count := ln_count + 1;
                  UTL_FILE.put_line (lc_filehandle, lc_message);

                  IF ln_count >= gn_num_records THEN
                     UTL_FILE.put_line (lc_filehandle, ' ');
                     UTL_FILE.put_line (lc_filehandle, 'Number of records extracted:' || ln_count);
                     location_and_log (GC_YES, '     Number of records extracted:' || ln_count);
                     location_and_log (gc_debug, '     Inserting into xx_crmar_file_log file log table');

                     INSERT INTO xx_crmar_file_log
                                 (program_id
                                 ,program_name
                                 ,program_run_date
                                 ,filename
                                 ,total_records
                                 ,status
                                 -- V2.3, Added request_id, cycle_date and batch_num
                                 ,request_id 
                                 ,cycle_date
                                 ,batch_num
                                 )
                          VALUES (gn_nextval
                                 ,gc_program_name
                                 ,SYSDATE
                                 ,lc_file_name
                                 ,ln_count
                                 ,'SUCCESS'
                                 , gn_request_id  
                                 , gd_cycle_date
                                 , p_batch_num
                                 );

                     UTL_FILE.fclose (lc_filehandle);
                     location_and_log (GC_YES, '     Closed the file:' || lc_file_name);
                     ln_tot_count := ln_tot_count + ln_count;
                     ln_count := 0;
                     ln_fno := ln_fno + 1;
                     -- V2.3 lc_file_name := gc_file_name || '_' || lc_inst || lc_file || '-' || ln_fno || '.dat';
                     lc_file_name := gc_file_name || '_' || lc_inst || '_' || p_batch_num|| lc_file || '-' || ln_fno || '.dat';
                     lt_filename (ln_fn_idx) := lc_file_name;
                     ln_fn_idx := ln_fn_idx + 1;
                     lc_filehandle := UTL_FILE.fopen (gc_file_path
                                                     ,lc_file_name
                                                     ,lc_mode
                                                     ,gn_line_size
                                                     );

                  END IF;
               END IF;
            END LOOP;

            EXIT WHEN lcu_recappl%NOTFOUND;
         END LOOP;

         CLOSE lcu_recappl;
         location_and_log (gc_debug, '      After Closing the Data Cursor');

      ELSE
	     p_retcode:=1;
      END IF;

         ln_tot_count := ln_tot_count + ln_count;

         UTL_FILE.put_line (lc_filehandle, ' ');
         UTL_FILE.put_line (lc_filehandle, 'Number of records extracted:' || ln_count);
         location_and_log (GC_YES, '     Number of records extracted:' || ln_count);

         UTL_FILE.fclose (lc_filehandle);
         location_and_log (GC_YES, '     Closed the file:' || lc_file_name);
         location_and_log (GC_YES, '     File creation completed ');

        END;   -- Retrieve and Create Files

      print_time_stamp_to_logfile;

      --========================================================================
      -- Validate and Update Status in Control Table
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Validate and Update Status in Control Table');

         location_and_log (gc_debug, '     Inserting into file Log Table after loop');
         INSERT INTO xx_crmar_file_log
                     (program_id
                     ,program_name
                     ,program_run_date
                     ,filename
                     ,total_records
                     ,status
                     -- V2.3, Added request_id, cycle_date and batch_num
                     ,request_id 
                     ,cycle_date
                     ,batch_num
                       )
              VALUES (gn_nextval
                     ,gc_program_name
                     ,SYSDATE
                     ,lc_file_name
                     ,ln_count
                     ,'SUCCESS'
                     , gn_request_id  
                     , gd_cycle_date
                     , p_batch_num
                       );

         location_and_log (gc_debug, '     Updating the control table with the flag s Y');
         IF p_retcode =2 THEN
            UPDATE xx_ar_wc_ext_control
               SET app_gen_file = 'E'
                  ,last_updated_by = fnd_global.user_id
                  ,last_update_date = SYSDATE
             WHERE cycle_date = TRUNC (gd_cycle_date)
               AND batch_num = p_batch_num;
            location_and_log (gc_debug, '     Error while creating the files');
         ELSE
            UPDATE xx_ar_wc_ext_control
               SET app_gen_file = 'Y'
                  ,last_updated_by = fnd_global.user_id
                  ,last_update_date = SYSDATE
             WHERE cycle_date = TRUNC (gd_cycle_date)
               AND batch_num = p_batch_num;

            location_and_log (gc_debug, '     All the files are successfully created');
         END IF;

         COMMIT;
      END;

      print_time_stamp_to_logfile;

      --========================================================================
      -- Copy Files to FTP Directory
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Setting Print Options Before submitting Common File Copy Program');

	 	          gb_print_option := FND_REQUEST.SET_PRINT_OPTIONS (printer => NULL
	                                                                  ,copies  => 0);

         location_and_log (GC_YES, 'Calling the Common File Copy to move the output file to ftp directory');

         FOR i IN lt_filename.FIRST .. lt_filename.LAST
         LOOP
            location_and_log (gc_debug, '     Submit File Copy Program');
            ln_ftp_request_id :=
               fnd_request.submit_request ('XXFIN'
                                          ,'XXCOMFILCOPY'
                                          ,''
                                          ,''
                                          ,FALSE
                                          , lc_source_path_name || '/' || lt_filename (i)
                                          , gc_ftp_file_path || '/' || lt_filename (i)
                                          ,''
                                          ,''
                                          ,'Y'
                                          ,gc_arch_file_path
                                          );
            COMMIT;

            IF ln_ftp_request_id = 0
            THEN
               fnd_file.put_line (fnd_file.LOG, '     Copy File Program is not submitted');
               ln_retcode := 2;
            ELSE
               lt_req_id (ln_idx) := ln_ftp_request_id;
               ln_idx := ln_idx + 1;
            END IF;
         END LOOP;

         location_and_log (gc_debug, '     Checking the status of File Copy Program');

         FOR i IN lt_req_id.FIRST .. lt_req_id.LAST
         LOOP
            IF fnd_concurrent.wait_for_request (lt_req_id (i)
                                                    ,30
                                                    ,0
                                                    ,lc_phase
                                                    ,lc_status
                                                    ,lc_dev_phase
                                                    ,lc_dev_status
                                                    ,lc_msg
                                                    )
             THEN
               IF UPPER (lc_status) = 'ERROR'
               THEN
                  fnd_file.put_line (fnd_file.LOG, '     Thread ' || i || ' completed with error');
                  p_retcode := 2;
               ELSIF UPPER (lc_status) = 'WARNING'
               THEN
                  fnd_file.put_line (fnd_file.LOG, '     Thread ' || i || ' completed with warning');
                  p_retcode := 1;
               ELSE
                  fnd_file.put_line (fnd_file.LOG, '     Thread ' || i || ' completed normal');
               END IF;

               SELECT GREATEST (p_retcode, ln_retcode)
                 INTO ln_retcode
                 FROM DUAL;
            END IF;
         END LOOP;

         p_retcode := ln_retcode;
         location_and_log (gc_debug, '     End of Copy File Program ');
         location_and_log (gc_debug, '     Before inserting into Log Table ');
         -- V2.4
         lc_int_filename := SUBSTR(lc_file_name,1,INSTR(lc_file_name,'-')-1);

         --Summary data inserting into log table
         INSERT INTO xx_crmar_int_log
                     (program_run_id
                     ,program_name
                     ,program_short_name
                     ,module_name
                     ,program_run_date
                     ,filename
                     ,total_files
                     ,total_records
                     ,status
                     ,MESSAGE
                     -- V2.3, Added request_id, cycle_date and batch_num
                     ,request_id 
                     ,cycle_date
                     ,batch_num
                     )
              VALUES (gn_nextval
                     ,gc_program_name
                     ,gc_program_short_name
                     ,gc_module_name
                     ,SYSDATE
                     ,lc_int_filename  -- V2.4 gc_file_name || lc_file
                     ,ln_fno
                     ,ln_tot_count
                     ,'SUCCESS'
                     ,'File generated'
                     , gn_request_id  
                     , gd_cycle_date
                     , p_batch_num
                     );

         COMMIT;
         location_and_log (gc_debug, '     After inserting into Log Table ');
         -- Replaced ln_count with ln_tot_count in below line for defect# 16328
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Total number of records extracted:' || ln_tot_count);
      END; -- Copy Files to FTP Directory
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Program run date:' || SYSDATE);

   EXCEPTION
      WHEN EX_NO_CONTROL_RECORD THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_NO_CONTROL_RECORD at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_CYCLE_COMPLETED THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_CYCLE_COMPLETED at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN EX_STAGING_COMPLETED THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_STAGING_COMPLETED at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         p_retcode := 2;

      WHEN UTL_FILE.invalid_path THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || SQLCODE || '-' || SQLERRM);
         p_retcode := 2;

      WHEN UTL_FILE.invalid_mode THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || SQLCODE || '-' || SQLERRM);
         p_retcode := 2;

      WHEN UTL_FILE.invalid_filehandle THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || SQLCODE || '-' || SQLERRM);
         p_retcode := 2;

      WHEN UTL_FILE.invalid_operation THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || SQLCODE || '-' || SQLERRM);
         p_retcode := 2;

      WHEN UTL_FILE.read_error THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || SQLCODE || '-' || SQLERRM);
         p_retcode := 2;

      WHEN UTL_FILE.write_error THEN
         --FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error Location : ' || gc_error_loc);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || SQLCODE || '-' || SQLERRM);
         p_retcode := 2;

      WHEN UTL_FILE.internal_error THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || SQLCODE || '-' || SQLERRM);
         p_retcode := 2;

      WHEN OTHERS THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || SQLCODE || '-' || SQLERRM);
         p_retcode := 2;
   END rappl_extr;
END xx_ar_recappl_wc_pkg;
/
SHOW ERRORS
