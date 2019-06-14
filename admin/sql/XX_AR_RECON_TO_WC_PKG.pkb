CREATE OR REPLACE PACKAGE BODY XX_AR_RECON_TO_WC_PKG
AS
   /*+=========================================================================+
   | Office Depot - Project FIT                                                |
   | Capgemini/Office Depot/Consulting Organization                            |
   +===========================================================================+
   |Name        : XX_AR_RECON_TO_WC_PKG                                        |
   |RICE        : I2160                                                        |
   |Description : This Package is used for inserting data into Recon staging   |
   |              table and extract data from staging table to flat file. Then | 
   |              the file will be transferred to Webcollect                   |
   |                                                                           |
   |Change Record:                                                             |
   |==============                                                             |
   |Version    Date         Author                      Remarks                |
   |=========  ===========  ====================  =============================|
   |  1.0      03-OCT-2011  Maheswararao N       Created this package.         |
   |                                                                           |
   |  1.1      19-DEC-2011  Maheswararao N       Modified as per rick comments |
   |                                                                           |
   |  1.2      17-JAN-2012  Maheswararao N       Modified for defect# 16250    |
   |                                                                           |
   |  1.3      23-JAN-2012  Maheswararao N       Modified for defect# 16235    |
   |                                                                           |
   |  1.4      04-FEB-2012  R.Aldridge            Defect 16768 - Create new    | 
   |                                              utility to remove special    |
   |                                              characters                   |
   |                                                                           |
   |  1.5      14-FEB-2012  R.Aldridge            Defect 16235 - AR Recon      | 
   |                                              performance tuning           |
   |                                                                           |
   |  1.6      23-FEB-2012  R.Aldridge            Defect 17150 - Resolve recon | 
   |                                              issue with missing collector |
   |                                                                           |
   |  1.7      07-MAR-2012  R.Aldridge            Defect 17213 - Changes for   | 
   |                                              customer_id difference       |
   |                                                                           |
   |  1.8      28-MAR-2012  R.Aldridge            Defect 17738 - Add query for |
   |                                              inst name for file generation|
   |  1.9      21-May-2012  Jay Gupta             Defect#18336, Filename passed|
   |                                              in INT table is incorrect    |
   |  2.0      21-May-2012  Jay Gupta             Changes for defect 18387     |
   |  2.1     11-FEB-2016   Vasu Raparla          Removed Schema References for|
   |                                              for R.12.2                   |             
   |  2.2      15-Jul-2016	Punita Kumari	     Defect 38057- Removed the hint|
   |                                              to improve performance       |     
   |  2.3      18-Nov-2017	Sreedhar Mohan	     As part of VPS project VPS org|
   |                                             Open invoices to be prevented |     
   |                                             to be inserted into intrim tbl|
   |  2.4      03-JUN-2019 	 Dinesh N        	 Replaced V$database with DB_Name for LNS|
   +=========================================================================+*/
   -- Global Variable Declarations here
   gn_limit                   xx_fin_translatevalues.target_value1%TYPE;
   gc_delimiter               xx_fin_translatevalues.target_value2%TYPE;
   gc_file_name               xx_fin_translatevalues.target_value4%TYPE;
   gc_email                   xx_fin_translatevalues.target_value5%TYPE;
   gc_compute_stats           xx_fin_translatevalues.target_value6%TYPE;
   gn_line_size               xx_fin_translatevalues.target_value7%TYPE;
   gc_file_path               xx_fin_translatevalues.target_value8%TYPE;
   gn_num_records             xx_fin_translatevalues.target_value9%TYPE;
   gc_debug                   xx_fin_translatevalues.target_value10%TYPE;
   gc_ftp_file_path           xx_fin_translatevalues.target_value11%TYPE;
   gc_arch_file_path          xx_fin_translatevalues.target_value12%TYPE;
   gc_staging_table           xx_fin_translatevalues.target_value19%TYPE;
   gc_process_type            xx_ar_mt_wc_details.process_type%TYPE   := 'AR_RECON';
   gn_threads_delta           NUMBER;
   gn_threads_full            NUMBER;
   gn_threads_file            NUMBER;
   gc_conc_short_delta        xx_fin_translatevalues.target_value16%TYPE;
   gc_conc_short_full         xx_fin_translatevalues.target_value17%TYPE;
   gc_conc_short_file         xx_fin_translatevalues.target_value18%TYPE;
   gn_full_num_days           NUMBER;
   gb_retrieved_trans         BOOLEAN                                       := FALSE;
   gc_err_msg_trans           VARCHAR2 (100)                                := NULL;
   gd_cycle_date              DATE;
   GC_YES                     VARCHAR2 (1)                                  := 'Y';
   gc_error_loc               VARCHAR2 (2000)                               := NULL;
   -- Variables for Cycle Date and Batch Cycle Settings
   gc_action_type             xx_ar_mt_wc_details.action_type%TYPE;
   --  gd_cycle_date                 xx_ar_wc_ext_control.cycle_date%TYPE;
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
   -- Custom Exceptions
   EX_NO_CONTROL_RECORD       EXCEPTION;
   EX_CYCLE_COMPLETED         EXCEPTION;
   EX_STAGING_COMPLETED       EXCEPTION;
   GD_CREATION_DATE           DATE                                          := SYSDATE;
   GN_CREATED_BY              NUMBER                                        := fnd_global.USER_ID;
   GN_REQUEST_ID              fnd_concurrent_requests.request_id%TYPE       := fnd_global.conc_request_id;

   /*==========================================================================+
   | Name       : GET_TRANS_SETTINGS                                           |
   | Description: This procedure is used to fetch the transalation definition  | 
   |              details                                                      |
   |                                                                           |
   | Parameters : none                                                         |
   |                                                                           |
   | Returns    : none                                                         |
   +==========================================================================*/
   PROCEDURE get_trans_settings
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
      xx_ar_wc_utility_pkg.print_time_stamp_to_logfile;
   END get_trans_settings;

   /*+=======================================================================+
   | Name : aps_opentrans_dump_tab                                           |
   | Description : Procedure to insert the date in interim table from APS    |
   |                                                                  .      |
   |                                                                         |
   | Parameters :    Errbuf,retcode,p_debug,p_compute_stats                  |
   |===============                                                          |
   |Version   Date          Author              Remarks                      |
   |=======   ==========   =============   ==================================|
   |  1.0     03-OCT-11   Maheswararao N   Initial version                   |
   |  1.1     16-DEC-11   Maheswararao N   Modified as per rick update       |
   |  1.2     17-JAN-12   Maheswararao N   Modified for defect# 16250        |
   +=========================================================================+*/
   PROCEDURE aps_opentrans_dump (p_errbuf          OUT      VARCHAR2
                                ,p_retcode         OUT      NUMBER
                                ,p_debug           IN       VARCHAR2
                                ,p_compute_stats   IN       VARCHAR2)
   IS
      ln_open_trans_count   NUMBER   := 0;
      lc_debug_flag         VARCHAR2 (1);
      lc_comp_stats         VARCHAR2 (1);
   BEGIN
      FND_FILE.PUT_LINE (FND_FILE.LOG, '********Entered Parameters For AR Open Transactions - Repopulate Interim Table Program *******************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, '            Debug Flag               :' || p_debug);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '            Compute Stats Flag       :' || p_compute_stats);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '***********************************************************************************************************');

      fnd_file.put_line (fnd_file.LOG, 'Start of aps_opentrans_dump_tab program at' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
      xx_ar_wc_utility_pkg.print_time_stamp_to_logfile;

      xx_ar_wc_utility_pkg.location_and_log (GC_YES, 'Retrieving Interface Settings From Translation Definition' || CHR (10));
      get_trans_settings;

      xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Determine if parameter value for debug/stats is used' || CHR (10));
      gc_debug := xx_ar_wc_utility_pkg.validate_param_trans_value (p_debug, gc_debug);
      gc_compute_stats := xx_ar_wc_utility_pkg.validate_param_trans_value (p_compute_stats, gc_compute_stats);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************DERIVED PARAMETERS FOR AR RECON MAIN PROGRAM *************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, '                Debug Flag        :' || gc_debug);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '                Compute Stats     :' || gc_compute_stats);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '******************************************************************************');

      xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Truncating the xx_ar_recon_open_itm table');
      EXECUTE IMMEDIATE 'TRUNCATE TABLE  xxfin.xx_ar_recon_open_itm';
      xx_ar_wc_utility_pkg.print_time_stamp_to_logfile;

      BEGIN
         -- Added for defect# 16250
         xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Enabling parallel DML for the session');
         EXECUTE IMMEDIATE  'ALTER SESSION ENABLE PARALLEL DML';

         xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Begin Inserting into interim table xx_ar_recon_open_itm');

         --========================================================================
         -- Insert Interim Table with All OPEN Payment Schedules
         --========================================================================         
         INSERT      /*+ PARALLEL */INTO xx_ar_recon_open_itm
	             (payment_schedule_id
	             ,staged_dunning_level
	             ,dunning_level_override_date
	             ,last_update_date
	             ,last_updated_by
	             ,creation_date
	             ,created_by
	             ,last_update_login
	             ,due_date
	             ,amount_due_original
	             ,amount_due_remaining
	             ,number_of_due_dates
	             ,status
	             ,invoice_currency_code
	             ,CLASS
	             ,cust_trx_type_id
	             ,customer_id
	             ,customer_site_use_id
	             ,customer_trx_id
	             ,cash_receipt_id
	             ,associated_cash_receipt_id
	             ,term_id
	             ,terms_sequence_number
	             ,gl_date_closed
	             ,actual_date_closed
	             ,discount_date
	             ,amount_line_items_original
	             ,amount_line_items_remaining
	             ,amount_applied
	             ,amount_adjusted
	             ,amount_in_dispute
	             ,amount_credited
	             ,receivables_charges_charged
	             ,receivables_charges_remaining
	             ,freight_original
	             ,freight_remaining
	             ,tax_original
	             ,tax_remaining
	             ,discount_original
	             ,discount_remaining
	             ,discount_taken_earned
	             ,discount_taken_unearned
	             ,in_collection
	             ,cash_applied_id_last
	             ,cash_applied_date_last
	             ,cash_applied_amount_last
	             ,cash_applied_status_last
	             ,cash_gl_date_last
	             ,cash_receipt_id_last
	             ,cash_receipt_date_last
	             ,cash_receipt_amount_last
	             ,cash_receipt_status_last
	             ,exchange_rate_type
	             ,exchange_date
	             ,exchange_rate
	             ,adjustment_id_last
	             ,adjustment_date_last
	             ,adjustment_gl_date_last
	             ,adjustment_amount_last
	             ,follow_up_date_last
	             ,follow_up_code_last
	             ,promise_date_last
	             ,promise_amount_last
	             ,collector_last
	             ,call_date_last
	             ,trx_number
	             ,trx_date
	             ,attribute_category
	             ,attribute1
	             ,attribute2
	             ,attribute3
	             ,attribute4
	             ,attribute5
	             ,attribute6
	             ,attribute7
	             ,attribute8
	             ,attribute9
	             ,attribute10
	             ,reversed_cash_receipt_id
	             ,amount_adjusted_pending
	             ,attribute11
	             ,attribute12
	             ,attribute13
	             ,attribute14
	             ,attribute15
	             ,gl_date
	             ,acctd_amount_due_remaining
	             ,program_application_id
	             ,program_id
	             ,program_update_date
	             ,receipt_confirmed_flag
	             ,request_id
	             ,selected_for_receipt_batch_id
	             ,last_charge_date
	             ,second_last_charge_date
	             ,dispute_date
	             ,org_id
	             ,global_attribute1
	             ,global_attribute2
	             ,global_attribute3
	             ,global_attribute4
	             ,global_attribute5
	             ,global_attribute6
	             ,global_attribute7
	             ,global_attribute8
	             ,global_attribute9
	             ,global_attribute10
	             ,global_attribute11
	             ,global_attribute12
	             ,global_attribute13
	             ,global_attribute14
	             ,global_attribute15
	             ,global_attribute16
	             ,global_attribute17
	             ,global_attribute18
	             ,global_attribute19
	             ,global_attribute20
	             ,global_attribute_category
	             ,cons_inv_id
	             ,cons_inv_id_rev
	             ,exclude_from_dunning_flag
	             ,mrc_customer_trx_id
	             ,mrc_exchange_rate_type
	             ,mrc_exchange_date
	             ,mrc_exchange_rate
	             ,mrc_acctd_amount_due_remaining
	             ,br_amount_assigned
	             ,reserved_type
	             ,reserved_value
	             ,active_claim_flag
	             ,exclude_from_cons_bill_flag
	             ,payment_approval
	             ,last_unaccrue_chrg_date
	             ,second_last_unaccrue_chrg_dt
	             ,recon_to_wc
	             )
	    (SELECT /*+ PARALLEL(APS, 8) FULL(APS) */
	            payment_schedule_id
	           ,staged_dunning_level
	           ,dunning_level_override_date
	           ,last_update_date
	           ,last_updated_by
	           ,creation_date
	           ,created_by
	           ,last_update_login
	           ,due_date
	           ,amount_due_original
	           ,amount_due_remaining
	           ,number_of_due_dates
	           ,status
	           ,invoice_currency_code
	           ,CLASS
	           ,cust_trx_type_id
	           ,customer_id
	           ,customer_site_use_id
	           ,customer_trx_id
	           ,cash_receipt_id
	           ,associated_cash_receipt_id
	           ,term_id
	           ,terms_sequence_number
	           ,gl_date_closed
	           ,actual_date_closed
	           ,discount_date
	           ,amount_line_items_original
	           ,amount_line_items_remaining
	           ,amount_applied
	           ,amount_adjusted
	           ,amount_in_dispute
	           ,amount_credited
	           ,receivables_charges_charged
	           ,receivables_charges_remaining
	           ,freight_original
	           ,freight_remaining
	           ,tax_original
	           ,tax_remaining
	           ,discount_original
	           ,discount_remaining
	           ,discount_taken_earned
	           ,discount_taken_unearned
	           ,in_collection
	           ,cash_applied_id_last
	           ,cash_applied_date_last
	           ,cash_applied_amount_last
	           ,cash_applied_status_last
	           ,cash_gl_date_last
	           ,cash_receipt_id_last
	           ,cash_receipt_date_last
	           ,cash_receipt_amount_last
	           ,cash_receipt_status_last
	           ,exchange_rate_type
	           ,exchange_date
	           ,exchange_rate
	           ,adjustment_id_last
	           ,adjustment_date_last
	           ,adjustment_gl_date_last
	           ,adjustment_amount_last
	           ,follow_up_date_last
	           ,follow_up_code_last
	           ,promise_date_last
	           ,promise_amount_last
	           ,collector_last
	           ,call_date_last
	           ,trx_number
	           ,trx_date
	           ,attribute_category
	           ,attribute1
	           ,attribute2
	           ,attribute3
	           ,attribute4
	           ,attribute5
	           ,attribute6
	           ,attribute7
	           ,attribute8
	           ,attribute9
	           ,attribute10
	           ,reversed_cash_receipt_id
	           ,amount_adjusted_pending
	           ,attribute11
	           ,attribute12
	           ,attribute13
	           ,attribute14
	           ,attribute15
	           ,gl_date
	           ,acctd_amount_due_remaining
	           ,program_application_id
	           ,program_id
	           ,program_update_date
	           ,receipt_confirmed_flag
	           ,request_id
	           ,selected_for_receipt_batch_id
	           ,last_charge_date
	           ,second_last_charge_date
	           ,dispute_date
	           ,org_id
	           ,global_attribute1
	           ,global_attribute2
	           ,global_attribute3
	           ,global_attribute4
	           ,global_attribute5
	           ,global_attribute6
	           ,global_attribute7
	           ,global_attribute8
	           ,global_attribute9
	           ,global_attribute10
	           ,global_attribute11
	           ,global_attribute12
	           ,global_attribute13
	           ,global_attribute14
	           ,global_attribute15
	           ,global_attribute16
	           ,global_attribute17
	           ,global_attribute18
	           ,global_attribute19
	           ,global_attribute20
	           ,global_attribute_category
	           ,cons_inv_id
	           ,cons_inv_id_rev
	           ,exclude_from_dunning_flag
	           ,mrc_customer_trx_id
	           ,mrc_exchange_rate_type
	           ,mrc_exchange_date
	           ,mrc_exchange_rate
	           ,mrc_acctd_amount_due_remaining
	           ,br_amount_assigned
	           ,reserved_type
	           ,reserved_value
	           ,active_claim_flag
	           ,exclude_from_cons_bill_flag
	           ,payment_approval
	           ,last_unaccrue_chrg_date
	           ,second_last_unaccrue_chrg_dt
	           ,'N'
	       FROM ar_payment_schedules_all APS
         WHERE status = 'OP'
         AND   org_id in (403,404)
         );

         ln_open_trans_count := SQL%ROWCOUNT;
         xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'End of Inserting into interim table xx_ar_recon_open_itm');
         FND_FILE.PUT_LINE (fnd_file.LOG, '');
         fnd_file.put_line (fnd_file.LOG, ln_open_trans_count || ' records inserted in xx_ar_recon_open_itm table');
         fnd_file.put_line (fnd_file.LOG, '');

         xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Calling compute_stats to gather statistics for XX_AR_RECON_OPEN_ITM ');
         xx_ar_wc_utility_pkg.compute_stat (gc_compute_stats
                                           ,'XXFIN'
                                           ,'XX_AR_RECON_OPEN_ITM'
                                           );
         COMMIT;
         fnd_file.put_line (fnd_file.LOG, 'End of aps_opentrans_dump_tab program at' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
      EXCEPTION 
         WHEN OTHERS THEN
            fnd_file.put_line (fnd_file.LOG, 'Insertion failed in xx_ar_recon_open_itm' || SQLERRM);
            fnd_file.put_line (fnd_file.LOG, '');
            fnd_file.put_line (fnd_file.LOG, gc_error_loc);
            p_retcode := 2;
      END;
   EXCEPTION 
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Others exception in AR Open Item Dump Program :' || SQLERRM);
         xx_ar_wc_utility_pkg.print_time_stamp_to_logfile;
         p_retcode := 2;
   END APS_OPENTRANS_DUMP;

   /*+========================================================================+
   | Name : insert_into_recon_stg                                            |
   | Description : Procedure to insert the values in interim table           |
   |                                                                         |
   |                                                                         |
   | Parameters :    p_batch_limit,p_compute_stats ,p_debug,p_errcode        |
   |===============                                                          |
   |Version   Date          Author              Remarks                      |
   |=======   ==========   =============   ==================================|
   |  1.0     03-OCT-11   Maheswararao N   Initial version                   |
   |  1.3     23-JAN-12   Maheswararao N   Modified for defect# 16235        |
   +=========================================================================+*/
   PROCEDURE INSERT_INTO_RECON_STG (p_debug           IN       VARCHAR2
                                   ,p_batch_limit     IN       NUMBER
                                   ,p_compute_stats   IN       VARCHAR2
                                   ,p_errcode         OUT      NUMBER)
   IS
      --Variable declaration of Table type
      lt_arrecon      recon_tbl_type;

      --cursor declaration: This is used to fetch the total open transactions
      --which include CM,DM,INV and PMT data from AR Base tables
      CURSOR lcu_arrecon
      IS
         SELECT 
                XCWC.account_number             CUSTOMER_NUMBER
	            ,XCWC.cust_account_id
	            ,XAOTI.customer_site_use_id      CUSTOMER_SITE_USE_ID
               ,HP.party_name                   CUSTOMER_NAME
               ,DUN_CONTACT.ap_dunning_contact
               ,AR_COLLECT.collector_id         COLLECTOR_ID
               ,AR_COLLECT.name                 COLLECTOR_NAME
               ,XAOTI.org_id                     
               ,XAOTI.invoice_currency_code     CURRENCY
               ,XAOTI.trx_number                "TRX_NUMBER/RECEIPT_NUMBER"
               ,XAOTI.amount_due_remaining      OPEN_BALANCE
               ,XAOTI.class                     "TYPE"
               ,XAOTI.customer_trx_id 
               ,XAOTI.cash_receipt_id 
               ,gd_creation_date                CREATION_DATE
               ,gn_created_by                   CREATED_BY
               ,gn_request_id                   REQUEST_ID
           FROM xx_crm_wcelg_cust     XCWC
               ,hz_parties            HP
               ,(SELECT HCSU.site_use_id
                       ,SUBSTR(PARTY.person_last_name,1,50) || SUBSTR (PARTY.person_first_name,1,40) AP_DUNNING_CONTACT
                   FROM hz_cust_site_uses_all   HCSU
                       ,hz_cust_account_roles   ACCT_ROLE
                       ,hz_relationships        REL
                       ,hz_parties              PARTY
                       ,hz_role_responsibility  HRR
                  WHERE HCSU.site_use_code     = 'BILL_TO'
                    AND ACCT_ROLE.status       = 'A'
                    AND HRR.primary_flag       = 'Y'
                    AND responsibility_type    = 'DUN'
                    AND REL.subject_type       = 'PERSON'
                    AND HCSU.cust_acct_site_id = ACCT_ROLE.cust_acct_site_id
                    AND ACCT_ROLE.party_id     = REL.party_id
                    AND REL.subject_id         = PARTY.party_id
                    AND ACCT_ROLE.cust_account_role_id = HRR.cust_account_role_id) DUN_CONTACT
               ,(SELECT hcp.site_use_id
                       ,ac.collector_id
                       ,ac.name
                   FROM ar_collectors        AC
                       ,hz_customer_profiles HCP
                  WHERE HCP.collector_id = AC.collector_id) AR_COLLECT
               ,xx_ar_recon_open_itm XAOTI
          WHERE XAOTI.recon_to_wc          = 'N'
            AND XAOTI.class                IN ('PMT','INV','CM','DM')
            AND XAOTI.org_id               IN (403,404)
            AND XAOTI.customer_id          = XCWC.cust_account_id
            AND XCWC.cust_mast_head_ext    = 'Y'
            AND XCWC.party_id              = HP.party_id
            AND XAOTI.customer_site_use_id = AR_COLLECT.site_use_id(+)
            AND XAOTI.customer_site_use_id = DUN_CONTACT.site_use_id(+);

      ln_batchlimit   NUMBER;
   BEGIN
      xx_ar_wc_utility_pkg.location_and_log (p_debug, 'Truncate Starts for xx_ar_recon_trans_stg table ');

      EXECUTE IMMEDIATE 'TRUNCATE TABLE  xxfin.xx_ar_recon_trans_stg';

      xx_ar_wc_utility_pkg.location_and_log (p_debug, 'Truncate Ends for xx_ar_recon_trans_stg table ');
      xx_ar_wc_utility_pkg.print_time_stamp_to_logfile;
      --lcu_arrecon cursor Loop started here
      ln_batchlimit := p_batch_limit;
      xx_ar_wc_utility_pkg.location_and_log (p_debug, 'Before opening the cursor lcu_arrecon ');

      OPEN lcu_arrecon;

      LOOP
         FETCH lcu_arrecon
         BULK COLLECT INTO lt_arrecon LIMIT ln_batchlimit;

         FORALL i IN 1 .. lt_arrecon.COUNT
            INSERT INTO XX_AR_RECON_TRANS_STG
                 VALUES lt_arrecon (i);
         COMMIT;
         EXIT WHEN lcu_arrecon%NOTFOUND;
      END LOOP;

      --lcu_arrecon curosr Loop ended here
      CLOSE lcu_arrecon;

      xx_ar_wc_utility_pkg.location_and_log (p_debug, 'After closing the cursor lcu_arrecon ');
      xx_ar_wc_utility_pkg.location_and_log (p_debug, 'Calling compute_stats to gather statistics for XX_AR_RECON_TRANS_STG ');
      xx_ar_wc_utility_pkg.compute_stat (p_compute_stats
                                        ,'XXFIN'
                                        ,'XX_AR_RECON_TRANS_STG'
                                        );
   EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG, 'Insertion failed in XX_AR_RECON_TRANS_STG' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, '');
         p_errcode := 2;
   END INSERT_INTO_RECON_STG;

   /*+========================================================================+
   | Name : ar_recon_extract_proc                                            |
   | Description : This procedure is used to fetch the staging table         |
   |             data to flat file                                    .      |
   |                                                                         |
   |Parameters : p_path,p_file,p_size,p_delimiter,p_debug,p_batch_limit      |
   |           ,p_num_of_lines, p_target_path,p_archive_path,p_errcode       |
   |===============                                                          |
   |Version   Date          Author              Remarks                      |
   |=======   ==========   =============   ==================================|
   |  1.0     03-OCT-11   Maheswararao N   Initial version                   |
   +=========================================================================+*/
   PROCEDURE AR_RECON_EXTRACT (p_path           IN       VARCHAR2
                              ,p_file           IN       VARCHAR2
                              ,p_size           IN       NUMBER
                              ,p_delimiter      IN       VARCHAR2
                              ,p_debug          IN       VARCHAR2
                              ,p_batch_limit    IN       NUMBER
                              ,p_num_of_lines   IN       NUMBER
                              ,p_target_path    IN       VARCHAR2
                              ,p_archive_path   IN       VARCHAR2
                              ,p_errcode        OUT      NUMBER)
   IS
      lc_filehandle         UTL_FILE.file_type;
      lc_filepath           VARCHAR2 (500)                               := p_path;
      lc_filename           VARCHAR2 (100);
      lc_file               VARCHAR2 (100)                               := '_' || TO_CHAR (SYSDATE, 'YYYYMMDD_HH24MISS');
--      lc_file               VARCHAR2 (100)                               := p_file || '_' || TO_CHAR (SYSDATE, 'YYYYMMDD' || '_' || 'HH24MISS');
      lc_message            VARCHAR2 (2000);
      lc_mode               VARCHAR2 (1)                                 := 'W';
      ln_size               NUMBER                                       := p_size;
      ln_count              NUMBER                                       := 0;
      ln_upd_count          NUMBER                                       := 0;
      ln_tot_lines          NUMBER                                       := p_num_of_lines;
      ln_cnt                NUMBER                                       := 0;
      ln_fno                NUMBER                                       := 1;
      lc_comma              VARCHAR2 (2)                                 := p_delimiter;
      lc_message1           VARCHAR2 (1000);
      ln_program_id         NUMBER;
      ln_batch_size         NUMBER;
      ln_ftp_request_id     NUMBER;
      lc_source_path_name   xx_fin_translatevalues.target_value11%TYPE;
      ln_idx                NUMBER                                       := 1;
      ln_idx2               NUMBER                                       := 1;
      lc_phase              VARCHAR2 (200);
      lc_status             VARCHAR2 (200);
      lc_dev_phase          VARCHAR2 (200);
      lc_dev_status         VARCHAR2 (200);
      lc_message2           VARCHAR2 (200);
      ln_retcode            NUMBER                                       := 0;

      -- V1.7
      lc_int_filename VARCHAR2(200);

      lc_inst               VARCHAR2(5);

      --Variable declaration of Table type
      lt_arrecon1           recon_tbl_type;
      lt_req_number         req_number_tbl_type;
      lt_file_name          file_name_tbl_type;

      --cursor declaration: This is used to fetch the staging table data
      CURSOR lcu_recon_extract
      IS
         SELECT customer_number
               ,cust_account_id
               ,customer_site_use_id
               ,customer_name
               ,ap_dunning_contact
               ,collector_id
               ,collector_name
               ,org_id
               ,currency
               ,trx_number
               ,open_balance
               ,TYPE
               ,cust_trx_id
               ,cash_receipt_id
               ,creation_date
               ,created_by
               ,request_id
           FROM xx_ar_recon_trans_stg;
   BEGIN
      xx_ar_wc_utility_pkg.location_and_log (GC_YES, CHR (10)||'Capture Instance Name');
	  /*
        SELECT substr(instance_name,4,5) 
        INTO lc_inst
        FROM v$instance;
	*/
	
		SELECT SUBSTR(SYS_CONTEXT('USERENV','DB_NAME'),4,8) 		-- Changed from V$instance to DB_NAME
		INTO lc_inst
		FROM dual;

      p_errcode := 0;
      lc_filename := p_file || '_' || lc_inst || lc_file || '-' || ln_fno || '.dat';
      --lc_filename := lc_file || '-' || ln_fno || '.dat';
      ln_batch_size := p_batch_limit;

      BEGIN
         SELECT COUNT (1)
           INTO ln_count
           FROM xx_ar_recon_trans_stg;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line (fnd_file.LOG, SQLCODE || 'NO data found while getting stging table count ');
            fnd_file.put_line (fnd_file.LOG, gc_error_loc);
      END;

      BEGIN
         xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Getting the sequence XX_CRMAR_INT_LOG_S value');

         SELECT XX_CRMAR_INT_LOG_S.NEXTVAL
           INTO ln_program_id
           FROM DUAL;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line (fnd_file.LOG, SQLCODE || 'NO data found while getting sequence next value ');
            fnd_file.put_line (fnd_file.LOG, gc_error_loc);
      END;

      BEGIN
         xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Getting the directory path from all_directories table');

         SELECT ad.directory_path
           INTO lc_source_path_name
           FROM all_directories AD
          WHERE AD.directory_name = lc_filepath;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line (fnd_file.LOG, SQLCODE || 'NO data found while getting directory path ');
            fnd_file.put_line (fnd_file.LOG, gc_error_loc);
      END;

      lt_file_name (ln_idx2) := lc_filename;
      ln_idx2 := ln_idx2 + 1;
      xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Before opening the ' || lc_filename || 'file ');
      lc_filehandle := UTL_FILE.fopen (lc_filepath
                                      ,lc_filename
                                      ,lc_mode
                                      ,ln_size
                                      );

      IF ln_count > 0
      THEN
         --lcu_recon_extract  cursor started here
         xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Before opening the cursor lcu_recon_extract ');

         OPEN lcu_recon_extract;

         LOOP
            FETCH lcu_recon_extract
            BULK COLLECT INTO lt_arrecon1 LIMIT ln_batch_size;

            FOR i IN 1 .. lt_arrecon1.COUNT
            LOOP
               lc_message := XX_AR_WC_UTILITY_PKG.remove_special_characters(
                     lt_arrecon1 (i).customer_number
                  || lc_comma
                  || lt_arrecon1 (i).cust_account_id
                  || lc_comma
                  || lt_arrecon1 (i).customer_site_use_id
                  || lc_comma
                  || lt_arrecon1 (i).customer_name
                  || lc_comma
                  || lt_arrecon1 (i).ap_dunning_contact
                  || lc_comma
                  || lt_arrecon1 (i).collector_id
                  || lc_comma
                  || lt_arrecon1 (i).collector_name
                  || lc_comma
                  || lt_arrecon1 (i).org_id
                  || lc_comma
                  || lt_arrecon1 (i).currency
                  || lc_comma
                  || lt_arrecon1 (i).trx_number
                  || lc_comma
                  || lt_arrecon1 (i).open_balance
                  || lc_comma
                  || lt_arrecon1 (i).TYPE
                  || lc_comma
                  || lt_arrecon1 (i).cust_trx_id
                  || lc_comma
                  || lt_arrecon1 (i).cash_receipt_id);
               UTL_FILE.put_line (lc_filehandle, lc_message);
               --Incrementing count of records in the file and total records fethed on particular file
               ln_cnt := ln_cnt + 1;

               -- Update the Recon_to_wc flag to 'Y' for all extracted records
               IF lt_arrecon1 (i).cust_trx_id IS NOT NULL
               THEN
                  UPDATE xx_ar_recon_open_itm
                     SET recon_to_wc = 'Y'
                   WHERE trx_number = lt_arrecon1 (i).trx_number 
                     AND customer_trx_id = lt_arrecon1 (i).cust_trx_id 
                     AND recon_to_wc = 'N';
               ELSE
                  UPDATE xx_ar_recon_open_itm
                     SET recon_to_wc = 'Y'
                   WHERE trx_number = lt_arrecon1 (i).trx_number 
                     AND cash_receipt_id = lt_arrecon1 (i).cash_receipt_id 
                     AND recon_to_wc = 'N';
               END IF;

               ln_upd_count := ln_upd_count + SQL%ROWCOUNT;

               IF ln_cnt >= ln_tot_lines
               THEN
                  xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Generating a file after reaching the number of records limit per file ');
                  lc_message1 := ' ';
                  UTL_FILE.put_line (lc_filehandle, lc_message1);
                  lc_message1 := 'Total number of Records Fetched on' || SYSDATE || ' is: ' || ln_cnt;
                  xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Inserting into XX_CRMAR_FILE_LOG file log table ');

                  --Insert all file names into custom log table xx_crmar_file_log
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
                       VALUES (ln_program_id
                              ,'OD: AR - Extract WC - Reconciliation '
                              ,SYSDATE
                              ,lc_filename
                              ,ln_cnt
                              ,'SUCCESS'
                              , gn_request_id  
                              , gd_cycle_date
                              , gn_batch_num
                              );

                  UTL_FILE.put_line (lc_filehandle, lc_message1);
                  UTL_FILE.fclose (lc_filehandle);
                  xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Closed the file' || lc_filename || ' at ');
                  ln_cnt := 0;
                  ln_fno := ln_fno + 1;
                  lc_filename := p_file || '_' || lc_inst || lc_file || '-' || ln_fno || '.dat';
--                  lc_filename := lc_file || '-' || ln_fno || '.dat';
                  lt_file_name (ln_idx2) := lc_filename;
                  ln_idx2 := ln_idx2 + 1;
                  lc_filehandle := UTL_FILE.fopen (lc_filepath
                                                  ,lc_filename
                                                  ,lc_mode
                                                  ,ln_size
                                                  );
               END IF;
            END LOOP;

            EXIT WHEN lcu_recon_extract%NOTFOUND;
         END LOOP;

         xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Closing the cursor lcu_recon_extract ');
         xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Updated ' || ln_upd_count || ' Records in xx_ar_recon_open_itm table');

         CLOSE lcu_recon_extract;
      ELSE
         p_errcode := 1;
      END IF;

      --lcu_recon_extract cursor closed here
      lc_message1 := ' ';
      UTL_FILE.put_line (lc_filehandle, lc_message1);
      lc_message1 := 'Total number of Records extracted: ' || ln_cnt;
      UTL_FILE.put_line (lc_filehandle, lc_message1);
      xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Inserting the last file details into xx_crmar_file_log file log table  at ');

      --Insert last file name into custom log table xx_crmar_file_log
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
           VALUES (ln_program_id
                  ,'OD: AR - Extract WC - Reconciliation '
                  ,SYSDATE
                  ,lc_filename
                  ,ln_cnt
                  ,'SUCCESS'
                  , gn_request_id  
                  , gd_cycle_date
                  , gn_batch_num
                  );

      UTL_FILE.fclose (lc_filehandle);
      xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'File creation completed and Calling the Common File Copy program');

      FOR i IN lt_file_name.FIRST .. lt_file_name.LAST
      LOOP
         -- Start of FTP Program
         fnd_file.put_line (fnd_file.LOG, 'Calling the Common File Copy to move the output file to ftp directory');
         ln_ftp_request_id :=
            fnd_request.submit_request ('XXFIN'
                                       ,'XXCOMFILCOPY'
                                       ,''
                                       ,''
                                       ,FALSE
                                       , lc_source_path_name || '/' || lt_file_name (i)                                                                                               --Source File Name
                                       , p_target_path || '/' || lt_file_name (i)                                                                                                       --Dest File Name
                                       ,''
                                       ,''
                                       ,'Y'                                                                                                                                   --Deleting the Source File
                                       ,p_archive_path
                                       );
         COMMIT;

         IF ln_ftp_request_id = 0
         THEN
            fnd_file.put_line (fnd_file.LOG, 'Common File copy Program is not submitted');
            p_errcode := 2;

            SELECT GREATEST (p_errcode, ln_retcode)
              INTO ln_retcode
              FROM DUAL;
         ELSE
            fnd_file.put_line (fnd_file.LOG, 'Request ID ' || ln_ftp_request_id || 'For file ' || lt_file_name (i));
            lt_req_number (ln_idx) := ln_ftp_request_id;
            ln_idx := ln_idx + 1;
         END IF;
      -- End of FTP Program
      END LOOP;

      xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'End of the Common File Copy program and inserting summary data into log file ');


      --V1.9
      lc_int_filename := SUBSTR(lc_filename,1,INSTR(lc_filename,'-')-1);

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
                  -- V2.0, Added request_id, cycle_date and batch_num
                  ,request_id 
                  ,cycle_date
                  ,batch_num
                  )
           VALUES (ln_program_id
                  ,'OD: AR - Extract WC - Reconciliation '
                  ,'XXARCDHRECON'
                  ,'XXFIN'
                  ,SYSDATE
                  ,lc_int_filename -- V1.9, inserting the file name passed in file table -- lc_file
                  ,ln_fno
                  ,ln_count
                  ,'SUCCESS'
                  ,'File generated'
                  , gn_request_id  
                  , gd_cycle_date
                  , gn_batch_num
                  );

      xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'summary data inserted into  XX_CRMAR_INT_LOG table ');
      COMMIT;
      fnd_file.put_line (fnd_file.LOG, 'Total no of records fetched:' || ln_count);
      xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Getting the child request statuses using fnd_concurrent.wait_for_request ');

      --lt_req_number Loop started here
      FOR i IN lt_req_number.FIRST .. lt_req_number.LAST
      LOOP
         IF fnd_concurrent.wait_for_request (lt_req_number (i)
                                                 ,2
                                                 ,0
                                                 ,lc_phase
                                                 ,lc_status
                                                 ,lc_dev_phase
                                                 ,lc_dev_status
                                                 ,lc_message2
                                                 )
         THEN
            IF UPPER (lc_status) = 'ERROR'
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Common File copy program for File ' || i || ' completed with error');
               p_errcode := 2;
            ELSIF UPPER (lc_status) = 'WARNING'
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Common File copy program for File ' || i || ' completed with warning');
               p_errcode := 1;
            ELSE
               fnd_file.put_line (fnd_file.LOG, 'Common File copy program for File ' || i || ' completed normal');
            END IF;

            SELECT GREATEST (p_errcode, ln_retcode)
              INTO ln_retcode
              FROM DUAL;
         END IF;
      END LOOP;

      p_errcode := ln_retcode;
   --ln_req_id Loop Ended here
   EXCEPTION
      WHEN UTL_FILE.invalid_path THEN
         fnd_file.put_line (fnd_file.LOG, 'Error' || SQLCODE || '-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, gc_error_loc);
         p_errcode := 2;
      
      WHEN UTL_FILE.invalid_mode THEN
         fnd_file.put_line (fnd_file.LOG, 'Error' || SQLCODE || '-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, gc_error_loc);
         p_errcode := 2;
      
      WHEN UTL_FILE.invalid_filehandle THEN
         fnd_file.put_line (fnd_file.LOG, 'Error' || SQLCODE || '-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, gc_error_loc);
         p_errcode := 2;
      
      WHEN UTL_FILE.invalid_operation THEN
         fnd_file.put_line (fnd_file.LOG, 'Error' || SQLCODE || '-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, gc_error_loc);
         p_errcode := 2;
      
      WHEN UTL_FILE.read_error THEN
         fnd_file.put_line (fnd_file.LOG, 'Error' || SQLCODE || '-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, gc_error_loc);
         p_errcode := 2;
      
      WHEN UTL_FILE.write_error THEN
         fnd_file.put_line (fnd_file.LOG, 'Error' || SQLCODE || '-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, gc_error_loc);
         p_errcode := 2;
      
      WHEN UTL_FILE.internal_error THEN
         fnd_file.put_line (fnd_file.LOG, 'Error' || SQLCODE || '-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, gc_error_loc);
         p_errcode := 2;
      
      WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG, 'Error' || SQLCODE || '-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, gc_error_loc);
         p_errcode := 2;
   END AR_RECON_EXTRACT;

   /*+========================================================================+
   | Name : ar_recon_main                                                    |
   | Description : This procedure is used to call the above two              |
   |              procedures. while registering concurrent                   |
   |              program this procedure will be used                        |
   |Parameters : p_debug , p_compute_stats                                   |
   |                                                                         |
   |===============                                                          |
   |Version   Date          Author              Remarks                      |
   |=======   ==========   =============   ==================================|
   |  1.0     03-OCT-11   Maheswararao N   Initial version                   |
   +=========================================================================+*/
   --Start of main procedure
   PROCEDURE AR_RECON_MAIN (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_debug           IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
     ,p_process_type    IN       VARCHAR2
   )
   IS
      -- Variable Declaration
      lc_file_path          VARCHAR2 (200);
      lc_filename           VARCHAR2 (100);
      ln_batch_limit        NUMBER;
      ln_line_size          NUMBER;
      lc_delimiter          VARCHAR2 (2);
      lc_debug_flag         VARCHAR2 (1);
      lc_debug              VARCHAR2 (1);
      lc_comp_stats         VARCHAR2 (1);
      lc_comp               VARCHAR2 (1);
      ln_num_of_lines       NUMBER;
      ln_error_code         NUMBER;
      lc_target_filepath    xx_fin_translatevalues.target_value11%TYPE;
      lc_archive_filepath   xx_fin_translatevalues.target_value11%TYPE;
   BEGIN
      fnd_file.put_line (fnd_file.LOG, 'Start of AR_RECON_MAIN program execution at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
      FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************ENTERED PARAMETERS FOR AR RECON MAIN PROGRAM *******************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, '            Process Type             :' || p_process_type);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '            Debug Flag               :' || p_debug);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '            Compute Stats Flag       :' || p_compute_stats);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '************************************************************************************');
      xx_ar_wc_utility_pkg.print_time_stamp_to_logfile;

      xx_ar_wc_utility_pkg.location_and_log (GC_YES, 'Retrieving Interface Settings From Translation Definition' || CHR (10));
      get_trans_settings;

      xx_ar_wc_utility_pkg.location_and_log (gc_debug, 'Determine if parameter value for debug/stats is used' || CHR (10));
      gc_debug := xx_ar_wc_utility_pkg.validate_param_trans_value (p_debug, gc_debug);
      gc_compute_stats := xx_ar_wc_utility_pkg.validate_param_trans_value (p_compute_stats, gc_compute_stats);

      FND_FILE.PUT_LINE (FND_FILE.LOG, '*******************DERIVED PARAMETERS FOR AR RECON MAIN PROGRAM *************');
      FND_FILE.PUT_LINE (FND_FILE.LOG, '                Batch Limit       :' || gn_limit);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '                Delimiter         :' || gc_delimiter);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '                File Path         :' || gc_file_path);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '                File Name         :' || gc_file_name);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '                File Size         :' || gn_line_size);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '                Target File Path  :' || gc_ftp_file_path);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '                Archive File Path :' || gc_arch_file_path);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '                No. of Records    :' || gn_num_records);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '                Debug Flag        :' || gc_debug);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '                Compute Stats     :' || gc_compute_stats);
      FND_FILE.PUT_LINE (FND_FILE.LOG, '******************************************************************************');
      xx_ar_wc_utility_pkg.print_time_stamp_to_logfile;

      fnd_file.put_line (fnd_file.LOG, 'Start of insert_into_recon_stg_tab program execution at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
      insert_into_recon_stg (gc_debug
                            ,gn_limit
                            ,gc_compute_stats
                            ,ln_error_code
                            );

      IF ln_error_code <> 0
      THEN
         p_retcode := ln_error_code;
         fnd_file.put_line (fnd_file.LOG, 'Program completed with status Error(2)/Warning(1)' || ln_error_code);
      ELSE
         fnd_file.put_line (fnd_file.LOG, 'End of insert_into_recon_stg_tab program at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
         FND_FILE.PUT_LINE (fnd_file.LOG, '');
         fnd_file.put_line (fnd_file.LOG, 'Start of ar_recon_extract_proc program execution at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
         ar_recon_extract (gc_file_path
                          ,gc_file_name
                          ,gn_line_size
                          ,gc_delimiter
                          ,gc_debug
                          ,gn_limit
                          ,gn_num_records
                          ,gc_ftp_file_path
                          ,gc_arch_file_path
                          ,ln_error_code
                          );
      END IF;

      IF ln_error_code <> 0
      THEN
         p_retcode := ln_error_code;
         fnd_file.put_line (fnd_file.LOG, 'Program completed with status Error(2)/Warning(1)' || ln_error_code);
      ELSE
         fnd_file.put_line (fnd_file.LOG, 'End of ar_recon_extract_proc program at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
         fnd_file.put_line (fnd_file.LOG, 'End of AR_RECON_MAIN program execution at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG, 'Exception is raised in main procedure' || SQLERRM);
         xx_ar_wc_utility_pkg.print_time_stamp_to_logfile;
         p_retcode := 2;

   END AR_RECON_MAIN;   -- End of the ar_recon_main procedure

END XX_AR_RECON_TO_WC_PKG;
/

SHOW ERRORS;