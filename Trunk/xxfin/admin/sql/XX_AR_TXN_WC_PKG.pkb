CREATE OR REPLACE PACKAGE BODY XX_AR_TXN_WC_PKG
AS
   /*==========================================================================+
   |      Office Depot - Project FIT                                           |
   |   Capgemini/Office Depot/Consulting Organization                          |
   +===========================================================================+
   |Name        :XX_AR_TXN_WC_PKG                                              |
   |RICE        : I2158 AR WebCollect Outbound                                 |
   |Description :This Package is used for insert data into staging             |
   |             table and fetch data from staging table to flat file          |
   |                                                                           |
   |            The STAGING Procedure will perform the following steps         |
   |                                                                           |
   |             1.It will fetch the records into staging table. The           |
   |               data will be either full or incremental                     |
   |                                                                           |
   |            EXTRACT STAGING procedure will perform the following           |
   |                steps                                                      |
   |                                                                           |
   |            1.It will fetch the staging table data to flat file            |
   |                                                                           |
   |Change Record:                                                             |
   |==============                                                             |
   |Version  Date         Author                  Remarks                      |
   |=======  ===========  ======================  =============================|
   |  1.0    21-Sep-2011  Narmatha Purushothaman  Initial Version Defect#16445 |
   |                                                                           |
   |  1.1    16-Jan-2012  Akhilesh                Change in txn_full procedure |
   |                                              for defect# 16264            |
   |                                                                           |
   |  1.2    18-Jan-2012  R.Aldridge              Defect# 16231 - Modify/tune  |
   |                                              cursor lcu_incremental       |
   |                                                                           |
   |  1.3    24-Jan-2012  R.Aldridge              Defect# 16439 - Tuning for   |
   |                                              full INITIAL conversion      |
   |                                                                           |
   |  1.4    25-Jan-2012  R.Aldridge              Defect# 16513 - Added Set    |
   |                                              Print Option function        |
   |                                                                           |
   |  1.5    25-Jan-2012  R.Aldridge              Defect# 16439 - Tuning for   |
   |                                              full INITIAL conversion      |
   |                                                                           |
   |  1.6    02-Feb-2012  R.Aldridge              Defect# 16730 - Modify / tune|
   |                                              full cursors                 |
   |                                                                           |
   |  1.7    02-Feb-2012  R.Aldridge              Defect# 16230 - Tuning for   |
   |                                              full DAILY conversions       |
   |                                              Defect# 16231 - Tuning for   |
   |                                              daily DELTA                  |
   |  1.8    04-FEB-2012  R.Aldridge              Defect 16768 - Create new    | 
   |                                              utility to remove special    |
   |                                              characters                   |
   |                                                                           |   
   |  1.9    28-MAR-2012  R.Aldridge              Defect 17738 - Add query for |
   |                                              inst name for file generation|
   |  2.0    10-May-2012  Jay Gupta               Defect 18387 - Add Request_id|
   |                                              in LOG tables                |
   |  2.1    06-Jul-2012  Jay Gupta               Defect 18389 - WC-TPS Insert |
   |  2.2    17-Mar-2016  Vasu Raparla            Removed Schema References for|
   |                                              for R.12.2                   
   +==========================================================================*/

   -- Variables for Interface Settings
   gn_limit                   NUMBER;
   gn_threads_delta           NUMBER;
   gn_threads_full            NUMBER;
   gn_threads_file            NUMBER;
   gc_conc_short_delta        xx_fin_translatevalues.target_value16%TYPE;
   gc_conc_short_full         xx_fin_translatevalues.target_value17%TYPE;
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
   gb_retrieved_trans         BOOLEAN                                       := FALSE;
   gc_err_msg_trans           VARCHAR2 (100)                                := NULL;
   gc_process_type            xx_ar_mt_wc_details.process_type%TYPE;
   gd_cycle_date              DATE;
   GC_YES                     VARCHAR2 (1)                                  := 'Y';
   gc_error_loc               VARCHAR2 (2000)                               := NULL;
   -- Variables for Cycle Date and Batch Cycle Settings
   gc_action_type             xx_ar_mt_wc_details.action_type%TYPE;
   --  gd_cycle_date            xx_ar_wc_ext_control.cycle_date%TYPE;
   gn_batch_num               xx_ar_wc_ext_control.batch_num%TYPE;
   gb_ready_to_execute        BOOLEAN                                       := FALSE;
   gb_reprocessing_required   BOOLEAN                                       := FALSE;
   gb_retrieved_cntl          BOOLEAN                                       := FALSE;
   gc_err_msg_cntl            VARCHAR2 (100)                                := NULL;
   gc_post_process_status     VARCHAR (1)                                   := 'Y';
   gd_delta_from_date         DATE;
   gd_full_from_date          DATE;
   gd_control_to_date         DATE;
   gc_reprocess_cnt           NUMBER;
   gb_print_option            BOOLEAN;
   -- Custom Exceptions
   EX_NO_CONTROL_RECORD       EXCEPTION;
   EX_CYCLE_COMPLETED         EXCEPTION;
   EX_STAGING_COMPLETED       EXCEPTION;
   EX_INVALID_ACTION_TYPE     EXCEPTION;

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
   | Name       : GET_INTERFACE_SETTINGS                                                 |
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
      print_time_stamp_to_logfile;
   END get_interface_settings;

   /*==================================================================+
    |Name        :TXN_FULL                                             |
    |Description :This procedure is used to fetch the total data       |
    |             from base tables to staging table                    |
    |                                                                  |
    |Parameters : p_from_cust_account_id                               |
    |             p_to_cust_account_id                                 |
    |             p_compute_stats                                      |
    |             p_debug                                              |
    |                                                                  |
    |Returns    : p_errbuf                                             |
    |             p_retcode                                            |
    |                                                                  |
    |                                                                  |
    +==================================================================*/
   PROCEDURE txn_full (p_errbuf                 OUT      VARCHAR2
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
      ln_insert_cnt   NUMBER       := 0;
      ln_insert_tot   NUMBER       := 0;
      --Variable declaration of Table type
      lt_txn_full     txn_tbl_type;
      
      -------------------------------------------------------
      -- Cursor for Full DAILY Conversion of New Customers 
      -------------------------------------------------------
      CURSOR lcu_fulldata (p_full_from_date_f    IN   DATE
                          ,p_control_to_date_f   IN   DATE
                          ,p_total_threads_full  IN   NUMBER) -- Added parameter for Defect# 16264
      IS
         SELECT CT.customer_trx_id          CUSTOMER_TRX_ID
               ,CT.bill_to_customer_id      BILL_TO_CUSTOMER_ID
               ,CT.bill_to_site_use_id      BILL_TO_SITE_USE_ID
               ,CTT.TYPE                    INVOICE_CLASS
               ,CTT.NAME                    INVOICE_TYPE
               ,CT.trx_number               TRX_NUMBER
               ,CB.cons_billing_number      CONSOLIDATED_BILL_NUMBER
               ,CT.trx_date                 TRX_DATE
               ,CT.printing_last_printed    PRINT_DATE
               ,RT.NAME                     TERM_CODE
               ,CT.internal_notes           SPECIAL_INSTRUCTIONS
               ,CT.comments                 COMMENTS
               ,CT.invoice_currency_code    INVOICE_CURRENCY_CODE
               ,CT.attribute9               SEND_REFUND
               ,CT.attribute10              REFUND_STATUS
               ,CT.attribute15              BILLING_EXTENSION
               ,OEH.orig_sys_document_ref   ORIG_SYSTEM_ORDER_REFERENCE
               ,CT.attribute11              DISPUTE_FLAG
               ,CT.primary_salesrep_id      SALES_PERSON
               ,CT.purchase_order           PO
               ,XOHAA.release_number
               ,XOHAA.cost_center_dept
               ,XOHAA.desk_del_addr
               ,CT.attribute13              SALES_ORDER
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,CT.creation_date            TRX_CREATION_DATE
               ,p_action_type               EXT_TYPE
               ,gd_cycle_date               CYCLE_DATE
               ,p_batch_num                 BATCH_NUM
          FROM (SELECT /*+ NO_MERGE */
                       CT.customer_trx_id           CUSTOMER_TRX_ID
                      ,CT.bill_to_customer_id       BILL_TO_CUSTOMER_ID
                      ,CT.bill_to_site_use_id       BILL_TO_SITE_USE_ID
                      ,CT.trx_number                TRX_NUMBER
                      ,CT.trx_date                  TRX_DATE
                      ,CT.printing_last_printed     PRINTING_LAST_PRINTED
                      ,CT.internal_notes            INTERNAL_NOTES
                      ,CT.comments                  COMMENTS
                      ,CT.invoice_currency_code     INVOICE_CURRENCY_CODE
                      ,CT.attribute9                ATTRIBUTE9
                      ,CT.attribute10               ATTRIBUTE10
                      ,CT.attribute15               ATTRIBUTE15
                      ,CT.attribute11               ATTRIBUTE11
                      ,CT.primary_salesrep_id       PRIMARY_SALESREP_ID
                      ,CT.purchase_order            PURCHASE_ORDER
                      ,CT.attribute13               ATTRIBUTE13
                      ,CT.attribute14               ATTRIBUTE14
                      ,CT.term_id                   TERM_ID
                      ,CT.cust_trx_type_id          CUST_TRX_TYPE_ID
                      ,CT.creation_date             CREATION_DATE
                  FROM ra_customer_trx_all CT
                 WHERE NVL(CT.complete_flag, 'N') = 'Y'
                   AND MOD(CT.customer_trx_id,p_total_threads_full) = p_thread_num - 1  -- Added line for Defect 16264
                   AND EXISTS (
                               (SELECT '1'
                                  FROM xx_ar_wc_upd_ps PS_UPD
                                 WHERE PS_UPD.customer_trx_id = CT.CUSTOMER_TRX_ID
                                   AND PS_UPD.class           IN ('INV', 'DM', 'CM')
                                   AND PS_UPD.ext_type         = p_action_type)
                                UNION ALL
                               (SELECT '1'
                                  FROM xx_ar_recon_open_itm OPEN_PS
                                 WHERE OPEN_PS.customer_trx_id = CT.customer_trx_id
                                   AND OPEN_PS.CLASS IN ('INV', 'DM', 'CM') )
                                UNION ALL
                               (SELECT '1'
                                  FROM SYS.DUAL
                                 WHERE CT.last_update_date BETWEEN p_full_from_date_f 
                                                               AND p_control_to_date_f)
                              )
                   -- eligible customers with AR not converted
                   AND EXISTS (SELECT /*+ INDEX(XXEC xx_crm_wcelg_cust_b1) */ '1'
                                 FROM xx_crm_wcelg_cust XXEC
                                WHERE XXEC.cust_account_id   = CT.bill_to_customer_id
                                  AND XXEC.ar_converted_flag  = 'N'
                                  AND XXEC.cust_mast_head_ext = 'Y' )
               ) CT
               ,ra_cust_trx_types_all       CTT
               ,ra_terms                    RT
               ,xx_om_header_attributes_all XOHAA
               ,oe_order_headers_all        OEH
               ,(SELECT CONS_INV.cons_billing_number
                       ,CONS_TRX.customer_trx_id
                   FROM ar_cons_inv_trx_all  CONS_TRX
                       ,ar_cons_inv_all      CONS_INV
                  WHERE CONS_TRX.cons_inv_id      = CONS_INV.cons_inv_id
                    AND CONS_TRX.transaction_type IN ('CREDIT_MEMO', 'INVOICE') ) CB
         WHERE TO_NUMBER(CT.attribute14) = XOHAA.header_id(+)
           AND CT.term_id                = RT.term_id(+)
           AND CT.cust_trx_type_id       = CTT.cust_trx_type_id
           AND CT.customer_trx_id        = CB.customer_trx_id(+)
           AND XOHAA.header_id           = OEH.header_id(+);

      -------------------------------------------------------
      -- Cursor for Full INITIAL Conversion of New Customers 
      --  ext_type is hardcoded to be F since action type of C
      -------------------------------------------------------
      CURSOR lcu_full_conv (p_full_from_date_f    IN   DATE
                           ,p_control_to_date_f   IN   DATE)
      IS
         SELECT /*+use_hash(XOHAA) use_hash(OEH) parallel(XOHAA, 8) parallel(OEH, 8) */
                CT.customer_trx_id          CUSTOMER_TRX_ID
               ,CT.bill_to_customer_id      BILL_TO_CUSTOMER_ID
               ,CT.bill_to_site_use_id      BILL_TO_SITE_USE_ID
               ,CTT.TYPE                    INVOICE_CLASS
               ,CTT.NAME                    INVOICE_TYPE
               ,CT.trx_number               TRX_NUMBER
               ,CB.cons_billing_number      CONSOLIDATED_BILL_NUMBER
               ,CT.trx_date                 TRX_DATE
               ,CT.printing_last_printed    PRINT_DATE
               ,RT.NAME                     TERM_CODE
               ,CT.internal_notes           SPECIAL_INSTRUCTIONS
               ,CT.comments                 COMMENTS
               ,CT.invoice_currency_code    INVOICE_CURRENCY_CODE
               ,CT.attribute9               SEND_REFUND
               ,CT.attribute10              REFUND_STATUS
               ,CT.attribute15              BILLING_EXTENSION
               ,OEH.orig_sys_document_ref   ORIG_SYSTEM_ORDER_REFERENCE
               ,CT.attribute11              DISPUTE_FLAG
               ,CT.primary_salesrep_id      SALES_PERSON
               ,CT.purchase_order           PO
               ,XOHAA.release_number
               ,XOHAA.cost_center_dept
               ,XOHAA.desk_del_addr
               ,CT.attribute13              SALES_ORDER
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,CT.creation_date            TRX_CREATION_DATE
               ,'F'                         EXT_TYPE
               ,gd_cycle_date               CYCLE_DATE
               ,p_batch_num                 BATCH_NUM
          FROM (SELECT /*+ FULL(CT) PARALLEL(CT,4) NO_MERGE */
                       CT.customer_trx_id           CUSTOMER_TRX_ID
                      ,CT.bill_to_customer_id       BILL_TO_CUSTOMER_ID
                      ,CT.bill_to_site_use_id       BILL_TO_SITE_USE_ID
                      ,CT.trx_number                TRX_NUMBER
                      ,CT.trx_date                  TRX_DATE
                      ,CT.printing_last_printed     PRINTING_LAST_PRINTED
                      ,CT.internal_notes            INTERNAL_NOTES
                      ,CT.comments                  COMMENTS
                      ,CT.invoice_currency_code     INVOICE_CURRENCY_CODE
                      ,CT.attribute9                ATTRIBUTE9
                      ,CT.attribute10               ATTRIBUTE10
                      ,CT.attribute15               ATTRIBUTE15
                      ,CT.attribute11               ATTRIBUTE11
                      ,CT.primary_salesrep_id       PRIMARY_SALESREP_ID
                      ,CT.purchase_order            PURCHASE_ORDER
                      ,CT.attribute13               ATTRIBUTE13
                      ,CT.attribute14               ATTRIBUTE14
                      ,CT.term_id                   TERM_ID
                      ,CT.cust_trx_type_id          CUST_TRX_TYPE_ID
                      ,CT.creation_date             CREATION_DATE
                  FROM ra_customer_trx_all CT
                 WHERE NVL(CT.complete_flag, 'N') = 'Y'
                   AND EXISTS (
                               (SELECT '1'
                                  FROM xx_ar_wc_upd_ps PS_UPD
                                 WHERE PS_UPD.customer_trx_id = CT.CUSTOMER_TRX_ID
                                   AND PS_UPD.class           IN ('INV', 'DM', 'CM')
                                   AND PS_UPD.ext_type         = 'F')
                                UNION ALL
                               (SELECT '1'
                                  FROM xx_ar_recon_open_itm OPEN_PS
                                 WHERE OPEN_PS.customer_trx_id = CT.customer_trx_id
                                   AND OPEN_PS.CLASS IN ('INV', 'DM', 'CM') )
                                UNION ALL
                               (SELECT '1'
                                  FROM SYS.DUAL
                                 WHERE CT.last_update_date BETWEEN p_full_from_date_f AND p_control_to_date_f)
                              )
                   -- eligible customers with AR not converted
                   AND EXISTS (SELECT /*+ FULL(XXEC) */ '1'
                                 FROM xx_crm_wcelg_cust XXEC
                                WHERE XXEC.cust_account_id   = CT.bill_to_customer_id
                                  AND XXEC.ar_converted_flag  = 'N'
                                  AND XXEC.cust_mast_head_ext = 'Y' )
               ) CT
               ,ra_cust_trx_types_all       CTT
               ,ra_terms                    RT
               ,xx_om_header_attributes_all XOHAA
               ,oe_order_headers_all        OEH
               ,(SELECT CONS_INV.cons_billing_number
                       ,CONS_TRX.customer_trx_id
                   FROM ar_cons_inv_trx_all  CONS_TRX
                       ,ar_cons_inv_all      CONS_INV
                  WHERE CONS_TRX.cons_inv_id      = CONS_INV.cons_inv_id
                    AND CONS_TRX.transaction_type IN ('CREDIT_MEMO', 'INVOICE') ) CB
         WHERE TO_NUMBER(CT.attribute14) = XOHAA.header_id(+)
           AND CT.term_id                = RT.term_id(+)
           AND CT.cust_trx_type_id       = CTT.cust_trx_type_id
           AND CT.customer_trx_id        = CB.customer_trx_id(+)
           AND XOHAA.header_id           = OEH.header_id(+);

   BEGIN
      --========================================================================
      -- Initialize Processing - FULL
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Initialize Processing');
         gc_process_type := p_process_type;
         gd_cycle_date := fnd_date.canonical_to_date (p_cycle_date);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************ENTERED PARAMETERS FOR AR TRANSACTIONS(FULL)*******************');
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

         IF NOT gb_retrieved_cntl
         THEN
            location_and_log (GC_YES, gc_error_loc || ' Control Record Not Retrieved');
            RAISE EX_NO_CONTROL_RECORD;
         ELSIF gc_post_process_status = 'Y'
         THEN
            location_and_log (GC_YES, gc_error_loc || ' Cycle Date and Batch Number Already Completed.');
            RAISE EX_CYCLE_COMPLETED;
         ELSIF gb_ready_to_execute = FALSE
         THEN
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
            location_and_log (gc_debug, '     Opening cursor lcu_fulldata' || CHR (10));

            OPEN lcu_fulldata (p_full_from_date_f   => gd_full_from_date
                              ,p_control_to_date_f  => gd_control_to_date
                              ,p_total_threads_full => gn_threads_full);

            LOOP
               location_and_log (gc_debug, '     Fetching from lcu_fulldata at ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));

               FETCH lcu_fulldata
               BULK COLLECT INTO lt_txn_full LIMIT gn_limit;

               FORALL i IN 1 .. lt_txn_full.COUNT
                  INSERT INTO xx_ar_trans_wc_stg
                       VALUES lt_txn_full (i);

               IF lt_txn_full.COUNT > 0
               THEN
                  location_and_log (GC_YES, '     lt_txn_full.COUNT = ' || lt_txn_full.COUNT);
                  ln_insert_cnt := SQL%ROWCOUNT;
                  ln_insert_tot := ln_insert_tot + ln_insert_cnt;
               END IF;

               location_and_log (gc_debug, '     Records Inserted into XX_AR_TRANS_WC_STG for ' || ' : ' || ln_insert_cnt);
               location_and_log (gc_debug, '     Full - Issue commit for inserting into XX_AR_TRANS_WC_STG table');
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
            location_and_log (gc_debug, '     Opening cursor lcu_full_conv' || CHR (10));

            OPEN lcu_full_conv (p_full_from_date_f  => gd_full_from_date
                               ,p_control_to_date_f => gd_control_to_date);

            LOOP
               location_and_log (gc_debug, '     Fetching from lcu_full_conv at ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));

               FETCH lcu_full_conv
               BULK COLLECT INTO lt_txn_full LIMIT gn_limit;

               FORALL i IN 1 .. lt_txn_full.COUNT
                  INSERT INTO xx_ar_trans_wc_stg
                       VALUES lt_txn_full (i);

               IF lt_txn_full.COUNT > 0
               THEN
                  location_and_log (GC_YES, '     lt_txn_full.COUNT = ' || lt_txn_full.COUNT);
                  ln_insert_cnt := SQL%ROWCOUNT;
                  ln_insert_tot := ln_insert_tot + ln_insert_cnt;
               END IF;

               location_and_log (gc_debug, '     Records Inserted into XX_AR_TRANS_WC_STG for ' || ' : ' || ln_insert_cnt);
               location_and_log (gc_debug, '     Full - Issue commit for inserting into XX_AR_TRANS_WC_STG table');
               COMMIT;
               EXIT WHEN lcu_full_conv%NOTFOUND;
            END LOOP;

            location_and_log (gc_debug, '     Closed cursor lcu_full_conv');
            CLOSE lcu_full_conv;
 
            location_and_log (gc_debug, '     Update control table');
            UPDATE xx_ar_wc_ext_control
               SET trx_ext_full = 'Y'
             WHERE trx_ext_full = 'C'
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
      location_and_log (GC_YES, '     Total Records Inserted into XX_AR_TRANS_WC_STG: ' || ln_insert_tot);

           -- V2.1, Calling procedure to insert into int log table
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
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Others exception in AR Transactions Program :' || SQLERRM);
         print_time_stamp_to_logfile;
         p_retcode := 2;
   END txn_full;

   /*=================================================================+
   |Name        :TXN_INCR                                             |
   |Description :This procedure is used to fetch the incremental data |
   |              from base tables to staging table                   |
   |                                                                  |
   |                                                                  |
   |Parameters :p_last_run_date                                       |
   |            p_to_run_date                                         |
   |            p_from_cust_trx_id                                    |
   |            p_to_cust_trx_id                                      |
   |            p_compute_stats                                       |
   |            p_debug                                               |
   |                                                                  |
   |                                                                  |
   |Returns    :p_errbuf                                              |
   |            p_retcode                                             |
   |                                                                  |
   +==================================================================*/
   PROCEDURE txn_incr (p_errbuf             OUT      VARCHAR2
                      ,p_retcode            OUT      NUMBER
                      ,p_cycle_date         IN       VARCHAR2
                      ,p_batch_num          IN       NUMBER
                      ,p_from_cust_trx_id   IN       NUMBER
                      ,p_to_cust_trx_id     IN       NUMBER
                      ,p_debug              IN       VARCHAR2
                      ,p_thread_num         IN       NUMBER
                      ,p_process_type       IN       VARCHAR2
                      ,p_action_type        IN       VARCHAR2)
   IS
      -- Declaration of Local Variables
      ln_insert_cnt   NUMBER       := 0;
      ln_insert_tot   NUMBER       := 0;
      --Table type declaration
      lt_txn_incr     txn_tbl_type;

      -------------------------------------------------------
      -- Cursor for DELTA for Eligibile Customers Sent to WC
      -------------------------------------------------------
      CURSOR lcu_incremental (p_delta_from_date_d   IN   DATE
                             ,p_control_to_date_d   IN   DATE)
      IS
         SELECT /*+ leading(CT) no_merge INDEX(CT RA_CUSTOMER_TRX_N14) index(xxec XX_CRM_WCELG_CUST_N1) */ 
                CT.customer_trx_id CUSTOMER_TRX_ID
               ,CT.bill_to_customer_id BILL_TO_CUSTOMER_ID
               ,CT.bill_to_site_use_id BILL_TO_SITE_USE_ID
               ,CTT.TYPE INVOICE_CLASS
               ,CTT.NAME INVOICE_TYPE
               ,CT.trx_number TRX_NUMBER
               ,CB.cons_billing_number CONSOLIDATED_BILL_NUMBER
               ,CT.trx_date TRX_DATE
               ,CT.printing_last_printed PRINT_DATE
               ,RT.NAME TERM_CODE
               ,CT.internal_notes SPECIAL_INSTRUCTIONS
               ,CT.comments COMMENTS
               ,CT.invoice_currency_code INVOICE_CURRENCY_CODE
               ,CT.attribute9 SEND_REFUND
               ,CT.attribute10 REFUND_STATUS
               ,CT.attribute15 BILING_EXTENSION
               ,OEH.orig_sys_document_ref ORIG_SYSTEM_ORDER_REFERENCE
               ,CT.attribute11 DISPUTE_FLAG
               ,CT.primary_salesrep_id SALES_PERSON
               ,CT.purchase_order PO
               ,XOHAA.release_number
               ,XOHAA.cost_center_dept
               ,XOHAA.desk_del_addr
               ,CT.attribute13 SALES_ORDER
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,CT.creation_date TRX_CREATION_DATE
               ,p_action_type EXT_TYPE
               ,gd_cycle_date CYCLE_DATE
               ,p_batch_num BATCH_NUM
           FROM ra_customer_trx_all CT
               ,ra_cust_trx_types_all CTT
               ,ra_terms RT
               ,xx_om_header_attributes_all XOHAA
               ,oe_order_headers_all OEH
               ,(SELECT CONS_INV.cons_billing_number
                       ,CONS_TRX.customer_trx_id
                   FROM ar_cons_inv_trx_all CONS_TRX
                       ,ar_cons_inv_all CONS_INV
                  WHERE CONS_TRX.cons_inv_id = CONS_INV.cons_inv_id
                    AND CONS_TRX.transaction_type IN ('CREDIT_MEMO', 'INVOICE')) CB
               ,xx_crm_wcelg_cust XXEC
          WHERE TO_NUMBER (CT.attribute14) = XOHAA.header_id(+)
            AND CT.term_id = RT.term_id(+)
            AND CT.cust_trx_type_id = CTT.cust_trx_type_id
            AND CT.customer_trx_id = CB.customer_trx_id(+)
            AND NVL (CT.complete_flag, 'N') = 'Y'
            AND XOHAA.header_id = OEH.header_id(+)
            AND CT.last_update_date BETWEEN p_delta_from_date_d
                                        AND p_control_to_date_d
            AND MOD(CT.customer_trx_id,gn_threads_delta) = p_thread_num - 1
            -- eligible customers with AR converted
            AND XXEC.cust_account_id    = CT.bill_to_customer_id
            AND XXEC.ar_converted_flag  = 'Y'
            AND XXEC.cust_mast_head_ext = 'Y'
         UNION ALL
         SELECT /*+ leading(PS_UPD) */ CT.customer_trx_id CUSTOMER_TRX_ID
               ,CT.bill_to_customer_id BILL_TO_CUSTOMER_ID
               ,CT.bill_to_site_use_id BILL_TO_SITE_USE_ID
               ,CTT.TYPE INVOICE_CLASS
               ,CTT.NAME INVOICE_TYPE
               ,CT.trx_number TRX_NUMBER
               ,CB.cons_billing_number CONSOLIDATED_BILL_NUMBER
               ,CT.trx_date TRX_DATE
               ,CT.printing_last_printed PRINT_DATE
               ,RT.NAME TERM_CODE
               ,CT.internal_notes SPECIAL_INSTRUCTIONS
               ,CT.comments COMMENTS
               ,CT.invoice_currency_code INVOICE_CURRENCY_CODE
               ,CT.attribute9 SEND_REFUND
               ,CT.attribute10 REFUND_STATUS
               ,CT.attribute15 BILING_EXTENSION
               ,OEH.orig_sys_document_ref ORIG_SYSTEM_ORDER_REFERENCE
               ,CT.attribute11 DISPUTE_FLAG
               ,CT.primary_salesrep_id SALES_PERSON
               ,CT.purchase_order PO
               ,XOHAA.release_number
               ,XOHAA.cost_center_dept
               ,XOHAA.desk_del_addr
               ,CT.attribute13 SALES_ORDER
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,CT.creation_date TRX_CREATION_DATE
               ,p_action_type EXT_TYPE
               ,gd_cycle_date CYCLE_DATE
               ,p_batch_num BATCH_NUM
           FROM ra_customer_trx_all CT
               ,ra_cust_trx_types_all CTT
               ,ra_terms RT
               ,xx_om_header_attributes_all XOHAA
               ,oe_order_headers_all OEH
               ,xx_ar_wc_upd_ps PS_UPD
               , (SELECT CONS_INV.cons_billing_number
                        ,CONS_TRX.customer_trx_id
                    FROM ar_cons_inv_trx_all CONS_TRX
                        ,ar_cons_inv_all CONS_INV
                   WHERE CONS_TRX.cons_inv_id = CONS_INV.cons_inv_id
                     AND CONS_TRX.transaction_type IN ('CREDIT_MEMO', 'INVOICE')) CB
          WHERE TO_NUMBER (CT.attribute14) = XOHAA.header_id(+)
            AND CT.term_id = RT.term_id(+)
            AND CT.cust_trx_type_id = CTT.cust_trx_type_id
            AND CT.customer_trx_id = CB.customer_trx_id(+)
            AND NVL (CT.complete_flag, 'N') = 'Y'
            AND XOHAA.header_id = OEH.header_id(+)
            AND PS_UPD.customer_trx_id = CT.customer_trx_id
            AND PS_UPD.CLASS IN ('INV', 'DM', 'CM')
            AND PS_UPD.ext_type = p_action_type
            AND MOD(CT.customer_trx_id,gn_threads_delta) = p_thread_num - 1
            AND NOT EXISTS (SELECT /*+ USE_NL(RECTRX) INDEX(RECTRX XX_AR_WC_CNV_REC_TRX_U1) */ 1
                              FROM xx_ar_wc_converted_rec_trx RECTRX
                             WHERE RECTRX.ID = CT.customer_trx_id
                               AND RECTRX.TYPE = 'TRX');

   BEGIN
      --========================================================================
      -- Initialize Processing - DELTA
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Initialize Processing');
         gc_process_type := p_process_type;
         gd_cycle_date := fnd_date.canonical_to_date (p_cycle_date);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************ENTERED PARAMETERS FOR AR TRANSACTIONS(INCR)*******************');
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Cycle Date               :' || p_cycle_date);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Batch number             :' || p_batch_num);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'From Customer Trx ID     :' || p_from_cust_trx_id);
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'To Customer Trx ID       :' || p_to_cust_trx_id);
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
      BEGIN
         location_and_log (GC_YES, 'Retrieve and Stage Data' || CHR (10));
         location_and_log (gc_debug, '     Opening cursor lcu_incremental' || CHR (10));

         OPEN lcu_incremental (p_delta_from_date_d => gd_delta_from_date, p_control_to_date_d => gd_control_to_date);

         LOOP
            location_and_log (gc_debug, '     Fetching from lcu_incremental at ' || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));

            FETCH lcu_incremental
            BULK COLLECT INTO lt_txn_incr LIMIT gn_limit;

            FORALL i IN 1 .. lt_txn_incr.COUNT
               INSERT INTO xx_ar_trans_wc_stg
                    VALUES lt_txn_incr (i);

            IF lt_txn_incr.COUNT > 0
            THEN
               location_and_log (GC_YES, '     lt_txn_incr.COUNT = ' || lt_txn_incr.COUNT);
               ln_insert_cnt := SQL%ROWCOUNT;
               ln_insert_tot := ln_insert_tot + ln_insert_cnt;
            END IF;

            location_and_log (gc_debug, '     Records Inserted into XX_AR_TRANS_WC_STG for ' || ' : ' || ln_insert_cnt);
            location_and_log (gc_debug, '     DELTA - Issue commit for inserting into XX_AR_TRANS_WC_STG table');
            COMMIT;
            EXIT WHEN lcu_incremental%NOTFOUND;
         END LOOP;

         CLOSE lcu_incremental;

         --txn_incr curosr Ended here
         location_and_log (gc_debug, '     Closed cursor lcu_incremental');
      END;

      print_time_stamp_to_logfile;
      --========================================================================
      -- Write Records Processed to Log File
      --========================================================================
      location_and_log (GC_YES, 'Total Records Inserted into XX_AR_TRANS_WC_STG: ' || ln_insert_tot);

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
      WHEN EX_NO_CONTROL_RECORD  THEN
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
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Others exception in AR Transactions Program :' || SQLERRM);
         print_time_stamp_to_logfile;
         p_retcode := 2;
   END txn_incr; --End of txn_full procedure

   /*=================================================================+
   |Name        :TXN_EXTR                                             |
   |Description :This procedure is used to fetch the staging table    |
   |             data to flat file                                    |
   |                                                                  |
   |                                                                  |
   |Parameters : p_debug                                              |
   |                                                                  |
   |                                                                  |
   |Returns    : p_errbuf                                             |
   |             p_retcode                                            |
   |                                                                  |
   +==================================================================*/
   PROCEDURE txn_extr (p_errbuf         OUT      VARCHAR2
                      ,p_retcode        OUT      NUMBER
                      ,p_cycle_date     IN       VARCHAR2
                      ,p_batch_num      IN       NUMBER
                      ,p_debug          IN       VARCHAR2
                      ,p_process_type   IN       VARCHAR2
                      ,p_action_type    IN       VARCHAR2  )
   IS
      lc_filehandle         UTL_FILE.file_type;
      lc_file               VARCHAR2 (100)                := '_' || TO_CHAR (SYSDATE, 'YYYYMMDD_HH24MISS');
      lc_file_name          VARCHAR2 (100);
      lc_message            VARCHAR2 (4000);
      lc_mode               VARCHAR2 (1)                                 := 'W';
      ln_fno                NUMBER                                       := 1;
      ln_cnt                NUMBER                                       := 0;
      ln_count              NUMBER                                       := 0;
      ln_tot_count          NUMBER                                       := 0;
      ln_ftp_request_id     NUMBER;
      lc_source_path_name   xx_fin_translatevalues.target_value11%TYPE;
      ln_idx                NUMBER                                       := 1;
      ln_fn_idx             NUMBER                                       := 1;
      lc_dev_phase          fnd_lookup_values.meaning%TYPE;
      lc_dev_status         fnd_lookup_values.meaning%TYPE;
      lc_phase              fnd_lookup_values.meaning%TYPE;
      lc_status             fnd_lookup_values.meaning%TYPE;
      lc_msg                VARCHAR2 (2000);
      ln_retcode            NUMBER                                       := 0;
      ln_customer_id        NUMBER                                       := 0;
      lc_inst               VARCHAR2(5);

      -- Declaration of Table type and variable
      ar_trx_stg            txn_tbl_type;
      lt_req_id             reqid_tbl_type;
      lt_filename           filename_tbl_type;
      lc_int_filename varchar2(100); --V2.0

      -------------------------------------------------------------------
      --cursor declaration: This is used to fetech the staging table data
      -------------------------------------------------------------------
      CURSOR lcu_ar_trx
      IS
         SELECT   *
             FROM xx_ar_trans_wc_stg
         ORDER BY customer_trx_id ASC
                 ,trx_creation_date DESC;
   BEGIN
      --========================================================================
      -- Initialize Processing
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Initialize Processing');
         gc_process_type := p_process_type;
         gd_cycle_date := fnd_date.canonical_to_date (p_cycle_date);
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
           FROM xx_ar_trans_wc_stg;

         location_and_log (GC_YES, 'Total Records in the Staging table Before Processing: ' || ln_cnt);
      
         location_and_log (GC_YES, CHR (10)||'Capture Instance Name');
         SELECT substr(instance_name,4,5) 
           INTO lc_inst
           FROM v$instance;      
      END;

      location_and_log (GC_YES, '     Generate the nextvalue from xx_crmar_int_log_s ');

      SELECT xx_crmar_int_log_s.NEXTVAL
        INTO gn_nextval
        FROM DUAL;

      location_and_log (GC_YES, 'Nextvalue from xx_crmar_int_log_s                   : ' || gn_nextval || CHR (10));

      --========================================================================
      -- Retrieve Interface Settings from Translation Definition
      --========================================================================
      BEGIN
         location_and_log (GC_YES, 'Retrieving Interface Settings From Translation Definition' || CHR (10));
         get_interface_settings;
         location_and_log (GC_YES, '     Deriving the source directory path');

         BEGIN
            SELECT AD.directory_path
              INTO lc_source_path_name
              FROM all_directories AD
             WHERE AD.directory_name = gc_file_path;

            location_and_log (GC_YES, '     Source Path' || lc_source_path_name);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
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
         -- V2.0 lc_file_name := gc_file_name || '_' || lc_inst || lc_file || '-' || ln_fno || '.dat';
         lc_file_name := gc_file_name || '_' || lc_inst || '_' || p_batch_num || lc_file || '-' || ln_fno || '.dat';
         lt_filename (ln_fn_idx) := lc_file_name;
         ln_fn_idx := ln_fn_idx + 1;
         location_and_log (gc_debug, '      Before Opening the UTL File');
         lc_filehandle := UTL_FILE.fopen (gc_file_path, lc_file_name, lc_mode, gn_line_size);

         IF ln_cnt > 0
         THEN
            location_and_log (gc_debug, '      Before Opening the Data Cursor');

      ------------------------------------
      --AR Transaction cursor started here
      ------------------------------------
            OPEN lcu_ar_trx;

            LOOP
               FETCH lcu_ar_trx
               BULK COLLECT INTO ar_trx_stg LIMIT gn_limit;

               FOR i IN 1 .. ar_trx_stg.COUNT
               LOOP
                  --This IF condition is to avoid duplicates
                  IF ar_trx_stg (i).customer_trx_id <> ln_customer_id
                  THEN
                     lc_message := XX_AR_WC_UTILITY_PKG.remove_special_characters(
                           ar_trx_stg (i).customer_trx_id
                        || gc_delimiter
                        || ar_trx_stg (i).bill_to_customer_id
                        || gc_delimiter
                        || ar_trx_stg (i).bill_to_site_use_id
                        || gc_delimiter
                        || ar_trx_stg (i).invoice_class
                        || gc_delimiter
                        || ar_trx_stg (i).invoice_type
                        || gc_delimiter
                        || ar_trx_stg (i).trx_number
                        || gc_delimiter
                        || ar_trx_stg (i).consolidated_bill_number
                        || gc_delimiter
                        || ar_trx_stg (i).trx_date
                        || gc_delimiter
                        || ar_trx_stg (i).print_date
                        || gc_delimiter
                        || ar_trx_stg (i).term_code
                        || gc_delimiter
                        || ar_trx_stg (i).special_instructions
                        || gc_delimiter
                        || ar_trx_stg (i).comments
                        || gc_delimiter
                        || ar_trx_stg (i).invoice_currency_code
                        || gc_delimiter
                        || ar_trx_stg (i).send_refund
                        || gc_delimiter
                        || ar_trx_stg (i).refund_status
                        || gc_delimiter
                        || ar_trx_stg (i).billing_extension
                        || gc_delimiter
                        || ar_trx_stg (i).orig_system_order_reference
                        || gc_delimiter
                        || ar_trx_stg (i).dispute_flag
                        || gc_delimiter
                        || ar_trx_stg (i).sales_person
                        || gc_delimiter
                        || ar_trx_stg (i).po
                        || gc_delimiter
                        || ar_trx_stg (i).release
                        || gc_delimiter
                        || ar_trx_stg (i).cost_center
                        || gc_delimiter
                        || ar_trx_stg (i).desktop
                        || gc_delimiter
                        || ar_trx_stg (i).sales_order);
                     ln_customer_id := ar_trx_stg (i).customer_trx_id;
                     ln_count := ln_count + 1;
                     UTL_FILE.put_line (lc_filehandle, lc_message);

                     IF ln_count >= gn_num_records
                     THEN
                        UTL_FILE.put_line (lc_filehandle, ' ');
                        UTL_FILE.put_line (lc_filehandle, 'Total number of records extracted:' || ln_count);
                        location_and_log (GC_YES, '      Total number of records extracted:' || ln_count);
                        location_and_log (gc_debug, '      Inserting into xx_crmar_file_log file log table ');

                        INSERT INTO xx_crmar_file_log
                                    (program_id
                                    ,program_name
                                    ,program_run_date
                                    ,filename
                                    ,total_records
                                    ,status
                                    -- V2.0, Added request_id, cycle_date and batch_num
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
                        --V2.0 lc_file_name := gc_file_name || '_' || lc_inst || lc_file || '-' || ln_fno || '.dat';
                        lc_file_name := gc_file_name || '_' || lc_inst || '_' || p_batch_num || lc_file || '-' || ln_fno || '.dat';
                        lt_filename (ln_fn_idx) := lc_file_name;
                        ln_fn_idx := ln_fn_idx + 1;
                        lc_filehandle := UTL_FILE.fopen (gc_file_path, lc_file_name, lc_mode, gn_line_size);
                     END IF;
                  END IF;
               END LOOP;

               EXIT WHEN lcu_ar_trx%NOTFOUND;
            END LOOP;

            CLOSE lcu_ar_trx;

            location_and_log (gc_debug, '      After Closing the Data Cursor');
         ELSE
            p_retcode := 1;
         END IF;

         ln_tot_count := ln_tot_count + ln_count;
         UTL_FILE.put_line (lc_filehandle, ' ');
         UTL_FILE.put_line (lc_filehandle, 'Total number of records extracted:' || ln_count);
         location_and_log (GC_YES, '      Total number of records extracted:' || ln_count);
         location_and_log (GC_YES, '     Closed the file:' || lc_file_name);
         UTL_FILE.fclose (lc_filehandle);
         location_and_log (gc_debug, '     File creation completed ');
      END;  -- Retrieve and Create Files

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
                     -- V2.0, Added request_id, cycle_date and batch_num
                     ,request_id 
                     ,cycle_date
                     ,batch_num                     )
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

         location_and_log (gc_debug, 'Updating the Control Table with the Flag as Y');

         IF p_retcode = 2
         THEN
            UPDATE xx_ar_wc_ext_control
               SET trx_gen_file = 'E'
                  ,last_updated_by = fnd_global.user_id
                  ,last_update_date = SYSDATE
             WHERE cycle_date = TRUNC (gd_cycle_date) AND batch_num = p_batch_num;

            location_and_log (gc_debug, 'Error while creating the files');
         ELSE
            UPDATE xx_ar_wc_ext_control
               SET trx_gen_file = 'Y'
                  ,last_updated_by = fnd_global.user_id
                  ,last_update_date = SYSDATE
             WHERE cycle_date = TRUNC (gd_cycle_date) AND batch_num = p_batch_num;

            location_and_log (gc_debug, 'All the files are successfully created');
         END IF;

         COMMIT;
      END;

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
            location_and_log (p_debug, '     Submit File Copy Program');
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
               fnd_file.put_line (fnd_file.LOG, 'Copy File Program is not submitted');
               ln_retcode := 2;
            ELSE
               lt_req_id (ln_idx) := ln_ftp_request_id;
               ln_idx := ln_idx + 1;
            END IF;
         END LOOP;

         location_and_log (gc_debug, 'Checking the status of File Copy Program');

         FOR i IN lt_req_id.FIRST .. lt_req_id.LAST
         LOOP
            IF fnd_concurrent.wait_for_request (lt_req_id (i), 30, 0, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_msg)
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

         p_retcode := ln_retcode;
         location_and_log (gc_debug, '     End of Copy File Program ');
         location_and_log (gc_debug, '     Before inserting into Log Table ');


         --V2.0
         lc_int_filename := SUBSTR(lc_file_name,1,INSTR(lc_file_name,'-')-1);

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
                     -- V2.0, Added request_id, cycle_date and batch_num
                     ,request_id 
                     ,cycle_date
                     ,batch_num
                     )
              VALUES (gn_nextval
                     ,gc_program_name
                     ,gc_program_short_name
                     ,gc_module_name
                     ,SYSDATE
                     ,lc_int_filename   -- V2.0 gc_file_name || lc_file
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
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Total number of records extracted:' || ln_tot_count);
      END;  -- Copy Files to FTP Directory

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
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || '-' || SQLERRM);
         p_retcode := 2;
      WHEN UTL_FILE.invalid_mode THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || '-' || SQLERRM);
         p_retcode := 2;
      WHEN UTL_FILE.invalid_filehandle THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || '-' || SQLERRM);
         p_retcode := 2;
      WHEN UTL_FILE.invalid_operation THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || '-' || SQLERRM);
         p_retcode := 2;
      WHEN UTL_FILE.read_error THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || '-' || SQLERRM);
         p_retcode := 2;
      WHEN UTL_FILE.write_error THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || '-' || SQLERRM);
         p_retcode := 2;
      WHEN UTL_FILE.internal_error THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || '-' || SQLERRM);
         p_retcode := 2;
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || '-' || SQLERRM);
         p_retcode := 2;
   END txn_extr;

END XX_AR_TXN_WC_PKG;
/

SHOW ERRORS