create or replace PACKAGE BODY XX_AR_EBL_IND_INVOICES_PKG AS

   -- +=====================================================================================+
   -- |                  Office Depot - Project Simplify                                    |
   -- |                          Wipro-Office Depot                                         |
   -- +=====================================================================================+
   -- | Name             :  XX_AR_EBL_INDIVIDUAL_INVOICES  E2059(CR 586)                    |
   -- | Description      :  This Package is used to fetch all the Distinct Customer Ids     |
   -- |                     and assign batch Id for the given Batch size and call the       |
   -- |                     Child Programs                                                  |
   -- |                                                                                     |
   -- |Change Record:                                                                       |
   -- |===============                                                                      |
   -- |Version   Date         Author                             Remarks                    |
   -- |=======   ==========   =============    ============================================ |
   -- |1.0       26-MAY-2010  Ranjith Thangasamy                                            |
   -- |1.1       26-OCT-2010  RamyaPriya M      Commented Taxable Flag                      |
   -- |                                         For Defect #7025                            |
   -- |1.2       28-SEP-2011  Rohit Ranjan      changed the column from amount_due_remaining|
   -- |                                         to difference of original_invoice_amount    |
   -- |                                         and total_gift_card_amount per Defect# 14000|
   -- |1.3       12-MAR-2012  Rajeshkumar M R   Moved department description                |
   -- |                                         to header Defect# 15118                     |
   -- |1.4      15-NOV-13    Arun Gannarapu     Made changes to pass org id to sales        |
   -- |                                         function for R12 --Defect 26440             |
   -- |1.5      17-Aug-2015  Suresh Naragam	    Added bill to location column               |
   -- |                                         (Module 4B Release 2)                       |
   -- |1.6      15-Oct-2015  Suresh Naragam     Removed Schema References                   |
   -- |                                         (R12.2 Global standards)                    |
   -- |1.7      04-DEC-2015  Havish Kasina      Added Cost Center Dept column               |
   -- |                                         (Module 4B Release 3)                       |
   -- |1.8      15-JUN-2016  Suresh Naragam          Added Line Level Tax Amount            |
   -- |                                               (Module 4B Release 4)                 |
   -- |1.9      23-JUN-2016  Havish Kasina      Added for Kitting (Defect 37675)            |
   -- |1.10     12-JUL-2018  Aarthi             Sales person updated to NULL - Defect 45279 |
   -- |1.11	    20-AUG-2018  Aarthi             Wave 5 Adding Tax at SKU level - NAIT 58403 |
   -- |1.12	    21-NOV-2018  Punit CG         Made changes in the Decode Script to fetch the|
   -- |                                       Sales order# for recurring billing invoices   |
   -- |1.13     27-MAY-2020  Divyansh           Added logic for JIRA NAIT-129167            |
   -- +=====================================================================================+

   ----------------------------------------
   -- Global Variable Declaration        --
   ----------------------------------------

   gc_debug_msg VARCHAR2(4000);
   gn_org_id    NUMBER := fnd_profile.VALUE('org_id');
   g_as_of_date DATE;
   PROCEDURE get_cust_details(x_errbuf     OUT VARCHAR2
                             ,x_retcode    OUT VARCHAR2
                             ,p_as_of_date IN VARCHAR2
                             ,p_batch_size IN NUMBER
                             ,p_thread_count IN NUMBER
                             ,p_debug_flag IN VARCHAR2) AS
      -- +===================================================================+
      -- |                  Office Depot - Project Simplify                  |
      -- |                          Wipro-Office Depot                       |
      -- +===================================================================+
      -- | Name             :  GET_CUST_DETAILS                              |
      -- | Description      :  This Procedure is used to Extract all the     |
      -- |                     Customer Ids  and call the Batching and       |
      -- |                     Submit Child Programs                         |
      -- |Change Record:                                                     |
      -- |===============                                                    |
      -- |Version   Date         Author           Remarks                    |
      -- |=======   ==========   =============    ======================     |
      -- |1.0       26-MAY-2010  Ranjith Thangasamy                          |
      -- +===================================================================+

      CURSOR lcu_cust_doc_ids(p_as_of_date DATE, p_org_id NUMBER) IS
         SELECT DISTINCT parent_cust_doc_id
         FROM   xx_ar_invoice_frequency xaif
         WHERE  xaif.doc_delivery_method IN ('ePDF', 'eXLS')
         AND    xx_ar_inv_freq_pkg.compute_effective_date(xaif.billdocs_payment_term
                                                         ,p_as_of_date) = p_as_of_date
         AND    estimated_print_date    <= p_as_of_date
         AND    org_id = p_org_id
         AND    nvl(xaif.status
                   ,'X') <> 'IN PROCESS';

      ---------------------------------
      --   VARIABLE DECLARATION      --
      ---------------------------------

      ln_count             NUMBER := 0;
      ln_batch_id          NUMBER := 0;
      ln_request_id        NUMBER;
      ln_cnt_err_request   NUMBER;
      lc_request_data      VARCHAR2(15);
      ln_parent_request_id NUMBER;
      ld_as_of_date        DATE := fnd_date.canonical_to_date(p_as_of_date);
      ln_org_id            NUMBER := fnd_profile.VALUE('ORG_ID');
      ex_setup_exception EXCEPTION;
      ln_site_attr_id NUMBER;
      ln_thread_count NUMBER := 0;
      ln_total_count NUMBER:=0;
      ln_batch_size NUMBER:=0;


      TYPE batch_id_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;

      lt_batch_id    batch_id_tbl_type;
      ln_curr_req_id NUMBER;
      p_debug        BOOLEAN;

   BEGIN
      IF (p_debug_flag = 'Y') THEN
         p_debug := TRUE;
      ELSE
         p_debug := FALSE;
      END IF;

      lc_request_data := fnd_conc_global.request_data;

      IF (lc_request_data IS NULL) THEN

         gc_debug_msg := ' ';
         xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                               ,TRUE
                                               ,gc_debug_msg);
         gc_debug_msg := ' Parameters : ';
         xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                               ,TRUE
                                               ,gc_debug_msg);
         gc_debug_msg := ' Batch Size : ' || p_batch_size;
         xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                               ,TRUE
                                               ,gc_debug_msg);
         gc_debug_msg := ' ';
         xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                               ,TRUE
                                               ,gc_debug_msg);

         ln_parent_request_id := fnd_global.conc_request_id;

         --  EXECUTE IMMEDIATE 'TRUNCATE TABLE xx_ar_ebl_ind_hdr_main';
         --  EXECUTE IMMEDIATE 'TRUNCATE TABLE xx_ar_ebl_ind_dtl_main';

         --------------------------------------------------
         --   Calling the GET_BATCH_SIZE Procedure  --
         --------------------------------------------------


        IF (p_thread_count IS NOT NULL) THEN

         SELECT COUNT(DISTINCT parent_cust_doc_id)
         INTO ln_total_count
         FROM   xx_ar_invoice_frequency xaif
         WHERE  xaif.doc_delivery_method IN ('ePDF', 'eXLS', 'eTXT')
         AND    xx_ar_inv_freq_pkg.compute_effective_date(xaif.billdocs_payment_term
                                                         ,ld_as_of_date) = ld_as_of_date
         AND    estimated_print_date      <= ld_as_of_date
         AND    org_id = ln_org_id
         AND    nvl(xaif.status
                   ,'X') <> 'IN PROCESS';

         IF (ln_total_count <> 0) THEN
         ln_batch_size := CEIL(ln_total_count/p_thread_count);
         ELSE
         ln_batch_size := -1;
         END IF;
            xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                               ,TRUE
                                               ,'Note: Program Will submit Child programs in Thread Count Mode'||CHR(13)
                                               ||'Total Parent Cust Doc IDs :'||ln_total_count||CHR(13)
                                               ||'Batch size of each thread :'||ln_batch_size);
         ELSE
         ln_batch_size := p_batch_size;
            xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                               ,TRUE
                                               ,'Note: Program Will submit Child programs in Batch Size Mode'||CHR(13)
                                               ||'Batch size of each thread :'||ln_batch_size);
         END IF;

         IF (ln_batch_size <> -1) THEN
         BEGIN
            OPEN lcu_cust_doc_ids(ld_as_of_date
                                 ,ln_org_id);
            LOOP
               FETCH lcu_cust_doc_ids BULK COLLECT
                  INTO lt_batch_id LIMIT nvl(ln_batch_size
                                            ,1000);
               EXIT WHEN lt_batch_id.COUNT = 0;
               SELECT xx_ar_batch_sequence.NEXTVAL
               INTO   ln_batch_id
               FROM   dual;

               FORALL i IN lt_batch_id.FIRST .. lt_batch_id.LAST
                  UPDATE xx_ar_invoice_frequency
                  SET    batch_id   = ln_batch_id
                        ,request_id = ln_parent_request_id
                  WHERE  parent_cust_doc_id = lt_batch_id(i)
                  AND    nvl(status
                            ,'X') <> 'IN PROCESS'
                  AND    org_id = ln_org_id
                  AND    xx_ar_inv_freq_pkg.compute_effective_date( billdocs_payment_term
                                                                   ,ld_as_of_date) = ld_as_of_date
                  AND    estimated_print_date    <= ld_as_of_date;
            END LOOP;
            CLOSE lcu_cust_doc_ids;
         EXCEPTION
            WHEN OTHERS THEN

               gc_debug_msg := ' Exception raised in updaying frequency table ' || SQLERRM;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,TRUE
                                                     ,gc_debug_msg);
               RAISE ex_setup_exception;
         END;
         END IF;
         gc_debug_msg := 'Started Submitting the Child Program : ';
         xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                               ,TRUE
                                               ,gc_debug_msg);

         FOR i IN (SELECT DISTINCT batch_id
                   FROM   xx_ar_invoice_frequency
                   WHERE  request_id = ln_parent_request_id
                   AND    org_id     = ln_org_id
                   )
         LOOP

            ln_thread_count := ln_thread_count + 1;

            ln_curr_req_id := fnd_request.submit_request(application => 'XXFIN'
                                                        ,program     => 'XX_AR_EBL_IND_DATA_EXT_CHILD'
                                                        ,sub_request => TRUE
                                                        ,argument1   => i.batch_id
                                                        ,argument2   => p_as_of_date
                                                        ,argument3   => p_debug_flag);

            COMMIT;

            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,TRUE
                                                  ,'SUBMITTING child for Batch: ' || i.batch_id);

            IF ln_request_id = 0 THEN
               gc_debug_msg := 'Failed to submit Child request : ';
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,TRUE
                                                     ,gc_debug_msg);
               RAISE ex_setup_exception;
            END IF;
         END LOOP;
         IF ln_thread_count > 0 THEN
            fnd_conc_global.set_req_globals(conc_status  => 'PAUSED'
                                           ,request_data => 'COMPLETE');
         END IF;
      ELSE
         -- Calling Zero byte insert
         gc_debug_msg := 'Calling Zero byte insert';
         xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                               ,TRUE
                                               ,gc_debug_msg);
         insert_zero_byte_file;

         -- Calling error record insert
         gc_debug_msg := 'Calling error record insert';
         xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                               ,TRUE
                                               ,gc_debug_msg);
         insert_error_file;

         SELECT COUNT(*)
         INTO   ln_cnt_err_request
         FROM   fnd_concurrent_requests
         WHERE  parent_request_id = ln_parent_request_id
         AND    phase_code = 'C'
         AND    status_code = 'E';

         IF ln_cnt_err_request <> 0 THEN
            gc_debug_msg := ln_cnt_err_request || ' Child Requests are Errored Out.Please, Check the Child Requests LOG for Details';
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,TRUE
                                                  ,gc_debug_msg);
            x_retcode := 2;
         ELSE
            gc_debug_msg := 'All the Child Programs Completed Normal...';
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,TRUE
                                                  ,gc_debug_msg);
         END IF;
      END IF;

   EXCEPTION
      WHEN ex_setup_exception THEN
         x_retcode := 2;
      WHEN OTHERS THEN
         gc_debug_msg := ' Exception raised in GET_CUST_DETAILS procedure ' || SQLERRM;
         xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                               ,TRUE
                                               ,gc_debug_msg);
         x_retcode := 2;
   END get_cust_details;

   PROCEDURE extract_data(x_errbuf     OUT VARCHAR2
                         ,x_retcode    OUT VARCHAR2
                         ,p_batch_id   IN NUMBER
                         ,p_as_of_date IN VARCHAR2
                         ,p_debug_flag IN VARCHAR2) AS

      -- +===================================================================+
      -- |                  Office Depot - Project Simplify                  |
      -- |                          Wipro-Office Depot                       |
      -- +===================================================================+
      -- | Name             :  EXTRACT_DATA                                  |
      -- | Description      :  This Procedure is used to Extract all the     |
      -- |                     Customer Details and insert the  header       |
      -- |                     and line details into the respective tables   |
      -- |                     and archive the data into their respective    |
      -- |                     History tables                                |
      -- |Change Record:                                                     |
      -- |===============                                                    |
      -- |Version   Date         Author           Remarks                    |
      -- |=======   ==========   =============    ======================     |
      -- |1.0       26-MAY-2010  Ranjith Thangasamy                          |
      -- |1.2       15-NOV-13    Arun Gannarapu    Made changes to pass org  |
      -- |                                          id to sales function for |
      -- |                                          R12 --Defect 26440       |
	  -- |1.3		17-Aug-2015	 Suresh Naragam	   Added bill to location    |
	  -- | 										   column(Module4B Release 2)|
	  -- |1.4		04-DEC-2015	 Havish Kasina	   Added Cost Center Dept    |
	  -- | 										   column(Module4B Release 3)|
	  -- |1.5       12-JUL-2018	 Aarthi            Sales person updated to   |
  	  -- |                                         NULL - Defect 45279       |
      -- +===================================================================+

      ---------------------------------
      --   VARIABLE DECLARATION      --
      ---------------------------------
      ------------------------------------------------------
      -- The Cursor Selects the Header Level details      --
      ------------------------------------------------------
      CURSOR lcu_hdr_details(p_batch_id IN NUMBER) IS
         SELECT /*+ LEADING(xaif RCT) */
          xaif.invoice_id                 customer_trx_id
         ,xaif.document_id                mbs_doc_id
         ,xaif.doc_delivery_method        billdocs_delivery_method
         ,xaif.paydoc_flag                document_type
         ,xaif.direct_flag                direct_flag
         ,xaif.customer_document_id       cust_doc_id
         ,xaif.billdocs_payment_term      billing_term
         ,NULL                            bill_from_date
         ,xaif.estimated_print_date       bill_to_date
         ,xaif.mail_to_attention          mail_to_attention
         ,rct.trx_number                  invoice_number
         ,NULL                            original_order_number
         ,xaif.amount_due_original        original_invoice_amount
         ,xaif.amount_due_remaining       amount_due_remaining
         ,0                               gross_sale_amount
         ,0                               tax_rate
         ,NULL                            credit_memo_reason
         ,NULL                            application_type
         ,estimated_print_date            invoice_bill_date
         ,xaif.due_date                   bill_due_date
         ,rct.invoice_currency_code       invoice_currency_code
         ,NULL                            order_date
         ,NULL                            reconcile_date
         ,rct.attribute14                 order_header_id
         ,NULL                            order_level_comment
         ,NULL                            order_level_spc_comment
         ,rct.interface_header_attribute2 order_type
         ,NULL                            order_type_code
         ,NULL                            ordered_by
         ,NULL                            payment_term
         ,NULL                            payment_term_description
         ,NULL                            payment_term_discount
         ,NULL                            payment_term_discount_date
         ,NULL                            payment_term_frequency
         ,NULL                            payment_term_report_day
         ,NULL                            payment_term_string
         ,rct.term_id                     trx_term
         ,0                               total_bulk_amount
         ,0                               total_coupon_amount
         ,0                               total_discount_amount
         ,0                               total_freight_amount
         ,0                               total_gift_card_amount
         ,0                               total_gst_amount
         ,0                               total_hst_amount
         ,0                               total_miscellaneous_amount
         ,0                               total_pst_amount
         ,0                               total_qst_amount
         ,0                               total_tiered_discount_amount
         ,0                               total_us_tax_amount
         ,0                               sku_lines_subtotal
         ,NULL                            sales_person
         ,rct.bill_to_customer_id         cust_account_id
         ,NULL                            oracle_account_number
         ,NULL                            customer_name
         ,NULL                            aops_account_number
         ,0                               cust_acct_site_id
         ,NULL                            cust_site_sequence
         ,rct.customer_reference_date     customer_ref_date
         ,rct.customer_reference          customer_ref_number
         ,NULL                            sold_to_customer_number
         ,rct.sold_to_customer_id         sold_to_customer_id
         ,rbs.NAME                        transaction_source
         ,rctt.NAME                       transaction_type
         ,rctt.TYPE                       transaction_class
         ,rct.trx_date                    transaction_date
         ,NULL                            bill_to_name
         ,NULL                            bill_to_address1
         ,NULL                            bill_to_address2
         ,NULL                            bill_to_address3
         ,NULL                            bill_to_address4
         ,NULL                            bill_to_city
         ,NULL                            bill_to_state
         ,NULL                            bill_to_country
         ,NULL                            bill_to_zip
         ,NULL                            bill_to_contact_name
         ,NULL                            bill_to_contact_phone
         ,NULL                            bill_to_contact_phone_ext
         ,NULL                            bill_to_contact_email
         ,NULL                            carrier
         ,rct.ship_via                    ship_via
         ,NULL                            ship_to_name
         ,NULL                            ship_to_abbreviation
         ,NULL                            ship_to_address1
         ,NULL                            ship_to_address2
         ,NULL                            ship_to_address3
         ,NULL                            ship_to_address4
         ,NULL                            ship_to_city
         ,NULL                            ship_to_state
         ,NULL                            ship_to_country
         ,NULL                            ship_to_zip
         ,NULL                            ship_to_sequence
         ,rct.waybill_number              shipment_ref_number
         ,NULL                            remit_address1
         ,NULL                            remit_address2
         ,NULL                            remit_address3
         ,NULL                            remit_address4
         ,NULL                            remit_city
         ,NULL                            remit_state
         ,NULL                            remit_zip
         ,NULL                            us_federal_id
         ,NULL                            canadian_tax_number
         ,NULL                            contact_point_purpose
         ,NULL                            contact_point_type
         ,NULL                            cost_center_sft_hdr
         ,NULL                            cost_center_desc_hdr--Added for 15118
		     ,NULL                            cost_center_dept -- Added for Defect 36437 (MOD4B Release 3)
         ,NULL                            po_number_sft_hdr
         ,NULL                            release_number_sft_hdr
         ,NULL                            desktop_sft_hdr
         ,NULL                            number_of_lines
         ,NULL                            batch_id
         ,NULL                            file_id
         ,NULL                            transmission_id
         ,NULL                            file_name
         ,NULL                            org_id
         ,rct.bill_to_site_use_id         bill_to_site_use_id
         ,xaif.parent_cust_doc_id         parent_cust_doc_id
         ,NULL                            epdf_doc_level
         ,NULL                            request_id
         ,rct.trx_number                  trx_number
         ,NULL                            desktop_sft_data
         ,rct.purchase_order              po_number_sft_data
         ,NULL                            cost_center_sft_data
         ,NULL                            release_number_sft_data
         ,NULL                            account_contact
         ,NULL                            order_contact
         ,NULL                            applied_trx_num
         ,NULL                            total_delivery_amount
         ,NULL                            total_association_discount
         ,0                            total_pst_qst_tax
          --, NULL tax_id
         ,NULL ship_cust_site_id
         ,NULL remit_to_description
         ,NULL remit_country
         ,NULL ship_cust_site_sequence
         ,rct.reason_code reason_code
         --,rct.primary_salesrep_id sales_person_id -- Commented for ver 1.5 Defect Id: 45279 Updating sales person to null
         ,NULL sales_person_id                      -- Added for ver 1.5 Defect Id: 45279 Updating sales person to null
         ,nvl(xaif.site_use_id
             ,rct.bill_to_site_use_id) site_use_id
         ,rct.ship_to_site_use_id ship_to_site_use_id
         ,rct.bill_to_customer_id customer_id
         ,rct.batch_source_id batch_source_id
         ,rct.remit_to_address_id
         ,decode(rct.interface_header_context
                ,'ORDER ENTRY'
                ,rct.interface_header_attribute1
				,'RECURRING BILLING'
				,rct.interface_header_attribute1)sales_order_number
         ,NULL order_source_code
         FROM   ra_customer_trx         rct
               ,ra_batch_sources        rbs
               ,ra_cust_trx_types       rctt
               ,xx_ar_invoice_frequency xaif
         WHERE  xaif.invoice_id = rct.customer_trx_id
         AND    rctt.cust_trx_type_id = rct.cust_trx_type_id
         AND    rbs.batch_source_id = rct.batch_source_id
         AND    xaif.batch_id = p_batch_id;

      -------------------------------------------------------
      -- The Cursor Selects all the Customer_trx_id values --
      -------------------------------------------------------

      TYPE lcu_header_tab IS TABLE OF lcu_hdr_details%ROWTYPE INDEX BY BINARY_INTEGER;
      trx_tab             lcu_header_tab;
      p_debug             BOOLEAN;
      lc_location         VARCHAR2(2000) := NULL;
      lc_province         hz_locations.province%TYPE := NULL;
      lc_ship_to_name     VARCHAR2(2000) := NULL;
      lc_ship_to_sequence VARCHAR2(2000) := NULL;
      ln_us_tax_rate      NUMBER := 0;
      ln_hdr_tax_rate     NUMBER := 0;
      ln_pst_qst_tax_rate NUMBER := 0;
      ln_gst_tax_rate     NUMBER := 0;
      lc_dummy            VARCHAR2(3000) := NULL;
      lc_reason_code      ar_lookups.meaning%TYPE := NULL;
      lc_orgordnbr        xx_om_line_attributes_all.ret_orig_order_num%TYPE := NULL;
      lc_country          ar_system_parameters.default_country%TYPE := NULL;
      lc_epdf_doc_detail  xx_cdh_mbs_document_master.doc_detail_level%TYPE := NULL;
      lc_sales_person     VARCHAR2(2000) := NULL;
      lc_sold_to_customer hz_cust_accounts_all.account_number%TYPE := NULL;
      ld_as_of_date       DATE := fnd_date.canonical_to_date(p_as_of_date);
      --ln_tax_id  xx_ar_sys_info.tax_id%TYPE;
      ln_organization_id      NUMBER;
      lc_tax_number           VARCHAR2(100);
      ln_request_id           NUMBER := fnd_global.conc_request_id;
      ln_trx_count            NUMBER := 0;
      lc_sales_channel        hz_cust_accounts.attribute18%TYPE;
      lc_ph_no_bill           VARCHAR2(20);
      lc_ph_no_cusrv          VARCHAR2(20);
      ln_spc_order_source_id  NUMBER;
      ln_remit_to_control_id  NUMBER;
      lc_cont_ph_no_cusrv     ar_system_parameters_all.attribute3%TYPE := NULL;
      lc_cont_ph_no_bill      ar_system_parameters_all.attribute4%TYPE := NULL;
      lc_dir_ph_no_cusrv      ar_system_parameters_all.attribute5%TYPE := NULL;
      lc_dir_ph_no_bill       ar_system_parameters_all.attribute6%TYPE := NULL;
      ln_sfthdr_group_id      ego_attr_groups_v.attr_group_id%TYPE := 0;
      lc_err_log              VARCHAR2(4000);
      lc_trx_term_description ra_terms.description%TYPE := NULL;
      ln_item_master_org      org_organization_definitions.organization_id%TYPE;
   BEGIN
      IF (p_debug_flag = 'Y') THEN
         p_debug := TRUE;
      ELSE
         p_debug := FALSE;
      END IF;
      g_as_of_date := ld_as_of_date;
      gc_debug_msg := 'In EXTRACT_DATA Procedure';
      xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                            ,FALSE
                                            ,gc_debug_msg);

      SELECT attr_group_id
      INTO   ln_sfthdr_group_id
      FROM   ego_attr_groups_v
      WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
      AND    attr_group_name = 'REPORTING_SOFTH';
      -- Getting Tax ID and Tax description
      gc_debug_msg := to_char(SYSDATE
                             ,'dd-mon-yyyy HH24:MI:SS') || ' Getting tax details:';
      xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                            ,FALSE
                                            ,gc_debug_msg);
      gc_debug_msg := to_char(SYSDATE
                             ,'DD-MON-YYYY HH24:MI:SS') || ' Get Item Master Organization ID';
      BEGIN
         SELECT odef.organization_id
         INTO   ln_item_master_org
         FROM   org_organization_definitions odef
         WHERE  1 = 1
         AND    odef.organization_name = 'OD_ITEM_MASTER';

         fnd_file.put_line(fnd_file.log
                          ,'Item Master Organization ID :' || ln_item_master_org);
      EXCEPTION
         WHEN no_data_found THEN
            ln_item_master_org := to_number(NULL);
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,TRUE
                                                  ,'In No data found, Item Master Organization ID :' || ln_item_master_org);
         WHEN OTHERS THEN
            ln_item_master_org := to_number(NULL);
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,TRUE
                                                  ,'In Other errors, Item Master Organization ID :' || ln_item_master_org);
      END;

      BEGIN
         SELECT default_country
               ,tax_registration_number
               ,attribute5
               ,attribute3
               ,attribute6
               ,attribute4
         INTO   lc_country
               ,lc_tax_number
               ,lc_cont_ph_no_cusrv
               ,lc_cont_ph_no_bill
               ,lc_dir_ph_no_cusrv
               ,lc_dir_ph_no_bill
         FROM   ar_system_parameters;
      EXCEPTION
         WHEN OTHERS THEN
            lc_country    := NULL;
            lc_tax_number := NULL;
            --  ln_tax_id :=0;
            lc_cont_ph_no_cusrv := NULL;
            lc_cont_ph_no_bill  := NULL;
            lc_dir_ph_no_cusrv  := NULL;
            lc_dir_ph_no_bill   := NULL;

            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,TRUE
                                                  ,'Error at :' || gc_debug_msg || SQLERRM);
      END;
      xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                            ,TRUE
                                            ,'lc_tax_number ' || lc_tax_number || ' ' || lc_country || SQLERRM);
      BEGIN
         SELECT oos.order_source_id
         INTO   ln_spc_order_source_id
         FROM   oe_order_sources oos
         WHERE  oos.NAME = 'SPC';
      EXCEPTION
         WHEN OTHERS THEN
            ln_spc_order_source_id := 0;
      END;

      gc_debug_msg := to_char(SYSDATE
                             ,'dd-mon-yyyy HH24:MI:SS') || ' OPEN lcu_hdr_details for Batch :' || p_batch_id;
      xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                            ,FALSE
                                            ,gc_debug_msg);

      OPEN lcu_hdr_details(p_batch_id);
      FETCH lcu_hdr_details BULK COLLECT
         INTO trx_tab;

      FOR trx_rec IN 1 .. trx_tab.COUNT
      LOOP
         BEGIN
            lc_location             := NULL;
            lc_province             := NULL;
            ln_us_tax_rate          := 0;
            ln_gst_tax_rate         := 0;
            ln_pst_qst_tax_rate     := 0;
            ln_hdr_tax_rate         := 0;
            lc_ph_no_cusrv          := NULL;
            lc_ph_no_bill           := NULL;
            lc_orgordnbr            := NULL;
            lc_reason_code          := NULL;
            lc_sales_person         := NULL;
            lc_sold_to_customer     := NULL;
            lc_trx_term_description := NULL;
            gc_debug_msg            := to_char(SYSDATE
                                              ,'dd-mon-yyyy HH24:MI:SS') || ' In xx_ar_ebl_common_util_pkg.get_amount: ' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || gc_debug_msg);
            SAVEPOINT trx_insert;
            xx_ar_ebl_common_util_pkg.get_amount(trx_tab(trx_rec).transaction_source
                                                ,trx_tab(trx_rec).customer_trx_id
                                                ,trx_tab(trx_rec).transaction_class
                                                ,trx_tab(trx_rec).order_header_id
                                                ,trx_tab(trx_rec).original_invoice_amount
                                                ,trx_tab(trx_rec).sku_lines_subtotal
                                                ,trx_tab(trx_rec).total_delivery_amount
                                                ,trx_tab(trx_rec).total_miscellaneous_amount
                                                ,trx_tab(trx_rec).total_association_discount
                                                ,trx_tab(trx_rec).total_bulk_amount
                                                ,trx_tab(trx_rec).total_coupon_amount
                                                ,trx_tab(trx_rec).total_tiered_discount_amount
                                                ,trx_tab(trx_rec).total_gift_card_amount
                                                ,trx_tab(trx_rec).number_of_lines);
            gc_debug_msg := to_char(SYSDATE
                                   ,'dd-mon-yyyy HH24:MI:SS') || ' In xx_ar_ebl_common_util_pkg.get_address: ' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || gc_debug_msg);
            xx_ar_ebl_common_util_pkg.get_address(trx_tab(trx_rec).site_use_id
                                                 ,trx_tab(trx_rec).bill_to_address1
                                                 ,trx_tab(trx_rec).bill_to_address2
                                                 ,trx_tab(trx_rec).bill_to_address3
                                                 ,trx_tab(trx_rec).bill_to_address4
                                                 ,trx_tab(trx_rec).bill_to_city
                                                 ,trx_tab(trx_rec).bill_to_country
                                                 ,trx_tab(trx_rec).bill_to_state
                                                 ,trx_tab(trx_rec).bill_to_zip
                                                 ,lc_location
                                                 ,trx_tab(trx_rec).bill_to_name
                                                 ,lc_dummy
                                                 ,lc_province
                                                 ,trx_tab(trx_rec).cust_acct_site_id
                                                 ,trx_tab(trx_rec).cust_site_sequence
                                                 ,trx_tab(trx_rec).customer_name);

            gc_debug_msg := to_char(SYSDATE
                                   ,'dd-mon-yyyy HH24:MI:SS') || ' In xx_ar_ebl_common_util_pkg.get_tax_amount: ' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || gc_debug_msg);

            xx_ar_ebl_common_util_pkg.get_tax_amount(trx_tab(trx_rec).customer_trx_id
                                                    ,lc_country
                                                    ,lc_province
                                                    ,trx_tab(trx_rec).total_us_tax_amount
                                                    ,ln_us_tax_rate
                                                    ,trx_tab(trx_rec).total_gst_amount
                                                    ,ln_gst_tax_rate
                                                    ,trx_tab(trx_rec).total_pst_qst_tax
                                                    ,ln_pst_qst_tax_rate);


            gc_debug_msg := to_char(SYSDATE
                                   ,'dd-mon-yyyy HH24:MI:SS') || ' In xx_ar_ebl_common_util_pkg.bill_from_date: ' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || gc_debug_msg);
            BEGIN
               SELECT xx_ar_ebl_common_util_pkg.bill_from_date(trx_tab(trx_rec).billing_term
                                                              ,g_as_of_date)
               INTO   trx_tab(trx_rec) .bill_from_date
               FROM   dual;

            EXCEPTION
               WHEN OTHERS THEN
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,TRUE
                                                        ,to_char(SYSDATE
                                                                ,'dd-mon-yyyy HH24:MI:SS') || 'Getting bill from date error : ' || SQLERRM || ' ' || gc_debug_msg);
            END;

            -- GET Remit to address
            gc_debug_msg := to_char(SYSDATE
                                   ,'dd-mon-yyyy HH24:MI:SS') || ' In xx_ar_ebl_common_util_pkg.get_remit_address: ' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || gc_debug_msg);
            --Deriving original order number for credit memos
            gc_debug_msg := to_char(SYSDATE
                                   ,'dd-mon-yyyy HH24:MI:SS') || ' Deriving Misc Details: ' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || gc_debug_msg);
            xx_ar_ebl_common_util_pkg.get_misc_values(trx_tab(trx_rec).order_header_id
                                                     ,trx_tab(trx_rec).reason_code
                                                     ,trx_tab(trx_rec).sold_to_customer_id
                                                     ,trx_tab(trx_rec).transaction_class
                                                     ,lc_orgordnbr
                                                     ,lc_reason_code
                                                     ,lc_sold_to_customer
                                                     ,trx_tab(trx_rec).reconcile_date);
            IF (trx_tab(trx_rec).remit_to_address_id IS NULL) THEN
               IF (trx_tab(trx_rec).transaction_class = 'CM' AND lc_orgordnbr IS NOT NULL) THEN
                  BEGIN
                     SELECT remit_to_address_id
                     INTO   trx_tab(trx_rec) .remit_to_address_id
                     FROM   ra_customer_trx_all
                     WHERE  trx_number = lc_orgordnbr;
                  EXCEPTION
                     WHEN OTHERS THEN
                        trx_tab(trx_rec).remit_to_address_id := NULL;
                  END;
               END IF;
            END IF;

            IF (trx_tab(trx_rec).remit_to_address_id IS NULL) THEN
               ln_remit_to_control_id := xx_ar_ebl_common_util_pkg.get_remit_addressid(trx_tab(trx_rec).remit_to_address_id
                                                                                      ,p_debug_flag);
            ELSE
               ln_remit_to_control_id := trx_tab(trx_rec).remit_to_address_id;
            END IF;
            xx_ar_ebl_common_util_pkg.get_remit_address(ln_remit_to_control_id
                                                       ,trx_tab(trx_rec).remit_address1
                                                       ,trx_tab(trx_rec).remit_address2
                                                       ,trx_tab(trx_rec).remit_address3
                                                       ,trx_tab(trx_rec).remit_address4
                                                       ,trx_tab(trx_rec).remit_city
                                                       ,trx_tab(trx_rec).remit_state
                                                       ,trx_tab(trx_rec).remit_zip
                                                       ,trx_tab(trx_rec).remit_to_description
                                                       ,trx_tab(trx_rec).remit_country);
            --GET SHIP_TO address
            gc_debug_msg := to_char(SYSDATE
                                   ,'dd-mon-yyyy HH24:MI:SS') || ' In xx_ar_ebl_common_util_pkg.get_address: ' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || gc_debug_msg);
            xx_ar_ebl_common_util_pkg.get_address(trx_tab(trx_rec).ship_to_site_use_id
                                                 ,lc_dummy
                                                 ,lc_dummy
                                                 ,lc_dummy
                                                 ,lc_dummy
                                                 ,lc_dummy
                                                 ,lc_dummy
                                                 ,lc_dummy
                                                 ,lc_dummy
                                                 ,trx_tab(trx_rec).ship_to_abbreviation
                                                 ,trx_tab(trx_rec).ship_to_name
                                                 ,trx_tab(trx_rec).ship_to_sequence
                                                 ,lc_dummy
                                                 ,trx_tab(trx_rec).ship_cust_site_id
                                                 ,trx_tab(trx_rec).ship_cust_site_sequence
                                                 ,lc_dummy);
            -- GET Order header attributes
            gc_debug_msg := to_char(SYSDATE
                                   ,'dd-mon-yyyy HH24:MI:SS') || ' In xx_ar_ebl_common_util_pkg.get_address: ' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || gc_debug_msg);
            xx_ar_ebl_common_util_pkg.get_hdr_attr_details(trx_tab(trx_rec).order_header_id
                                                          ,ln_spc_order_source_id
                                                          ,trx_tab(trx_rec).bill_to_contact_email
                                                          ,trx_tab(trx_rec).bill_to_contact_name
                                                          ,trx_tab(trx_rec).bill_to_contact_phone
                                                          ,trx_tab(trx_rec).bill_to_contact_phone_ext
                                                          ,trx_tab(trx_rec).order_level_comment
                                                          ,trx_tab(trx_rec).order_type_code
                                                          ,trx_tab(trx_rec).order_source_code
                                                          ,trx_tab(trx_rec).ordered_by
                                                          ,trx_tab(trx_rec).order_date
                                                          ,trx_tab(trx_rec).order_level_spc_comment
                                                          ,trx_tab(trx_rec).cost_center_sft_data
                                                          ,trx_tab(trx_rec).release_number_sft_data
                                                          ,trx_tab(trx_rec).desktop_sft_data
                                                          ,trx_tab(trx_rec).ship_to_address1
                                                          ,trx_tab(trx_rec).ship_to_address2
                                                          ,trx_tab(trx_rec).ship_to_city
                                                          ,trx_tab(trx_rec).ship_to_state
                                                          ,trx_tab(trx_rec).ship_to_country
                                                          ,trx_tab(trx_rec).ship_to_zip
                                                          ,ln_hdr_tax_rate);
            IF lc_country = 'CA' THEN
               IF trx_tab(trx_rec).ship_to_state IN ('QC', 'PQ') THEN
                  trx_tab(trx_rec).total_qst_amount := trx_tab(trx_rec).total_pst_qst_tax;
               ELSE
                  trx_tab(trx_rec).total_pst_amount := trx_tab(trx_rec).total_pst_qst_tax;
               END IF;

            END IF;
            -- Getting customer Details
            gc_debug_msg := to_char(SYSDATE
                                   ,'dd-mon-yyyy HH24:MI:SS') || ' Getting customer Details: ' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || gc_debug_msg);
            BEGIN
               SELECT substr(orig_system_reference
                            ,1
                            ,8)
                     ,account_number
                     ,attribute18
               INTO   trx_tab(trx_rec) .aops_account_number
                     ,trx_tab(trx_rec) .oracle_account_number
                     ,lc_sales_channel
               FROM   hz_cust_accounts
               WHERE  cust_account_id = trx_tab(trx_rec).customer_id;
            EXCEPTION
               WHEN OTHERS THEN
                  trx_tab(trx_rec).aops_account_number := 0;
                  trx_tab(trx_rec).oracle_account_number := 0;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,TRUE
                                                        ,'Error at :' || gc_debug_msg || SQLERRM);
            END;

            BEGIN
               IF upper(lc_sales_channel) = 'CONTRACT' THEN
                  lc_ph_no_cusrv := lc_cont_ph_no_cusrv;
                  lc_ph_no_bill  := lc_cont_ph_no_bill;
               ELSE
                  lc_ph_no_cusrv := lc_dir_ph_no_cusrv;
                  lc_ph_no_bill  := lc_dir_ph_no_bill;
               END IF;
            EXCEPTION
               WHEN OTHERS THEN
                  lc_ph_no_cusrv := NULL;
                  lc_ph_no_bill  := NULL;
            END;

            -- Getting Term Description
            gc_debug_msg := to_char(SYSDATE
                                   ,'dd-mon-yyyy HH24:MI:SS') || ' getting payment term details: ' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || gc_debug_msg);

            xx_ar_ebl_common_util_pkg.get_term_details(trx_tab(trx_rec).billing_term
                                                      ,trx_tab(trx_rec).payment_term
                                                      ,trx_tab(trx_rec).payment_term_description
                                                      ,trx_tab(trx_rec).payment_term_discount
                                                      ,trx_tab(trx_rec).payment_term_frequency
                                                      ,trx_tab(trx_rec).payment_term_report_day);
            BEGIN
               SELECT description
               INTO   lc_trx_term_description
               FROM   ra_terms
               WHERE  term_id = trx_tab(trx_rec).trx_term;
            EXCEPTION
               WHEN no_data_found THEN
                  lc_trx_term_description := NULL;
            END;
            --GET soft header detail
            gc_debug_msg := to_char(SYSDATE
                                   ,'dd-mon-yyyy HH24:MI:SS') || ' getting soft header details: ' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || gc_debug_msg);
            xx_ar_ebl_common_util_pkg.get_soft_header(trx_tab(trx_rec).customer_id
                                                     ,ln_sfthdr_group_id
                                                     ,trx_tab(trx_rec).cost_center_sft_hdr
                                                     ,trx_tab(trx_rec).desktop_sft_hdr
                                                     ,trx_tab(trx_rec).release_number_sft_hdr
                                                     ,trx_tab(trx_rec).po_number_sft_hdr);
            oe_profile.get('SO_ORGANIZATION_ID'
                          ,ln_organization_id);

                          --Added for defect 15118
            BEGIN
                SELECT CUST_DEPT_DESCRIPTION,
                       COST_CENTER_DEPT --Added for Defect 36437 (MOD4B Release 3)
                INTO  trx_tab(trx_rec).cost_center_desc_hdr,
				              trx_tab(trx_rec).cost_center_dept --Added for Defect 36437 (MOD4B Release 3)
                FROM XX_OM_HEADER_ATTRIBUTES_ALL XOHA,
                     RA_CUSTOMER_TRX_ALL RCT
                WHERE RCT.CUSTOMER_TRX_ID =trx_tab(trx_rec).customer_trx_id
                AND RCT.ATTRIBUTE14= XOHA.HEADER_ID
               AND    rownum < 2;
            EXCEPTION
               WHEN no_data_found THEN
                  trx_tab(trx_rec).cost_center_desc_hdr := NULL;
				          trx_tab(trx_rec).cost_center_dept := NULL; --Added for Defect 36437 (MOD4B Release 3)
            END;
---added for defect 15118
            BEGIN
               SELECT description
               INTO   trx_tab(trx_rec) .carrier
               FROM   org_freight orf
               WHERE  orf.freight_code = trx_tab(trx_rec).ship_via
               AND    orf.organization_id = ln_organization_id
               AND    rownum < 2;
            EXCEPTION
               WHEN no_data_found THEN
                  trx_tab(trx_rec).carrier := NULL;
            END;

            gc_debug_msg := to_char(SYSDATE
                                   ,'dd-mon-yyyy HH24:MI:SS') || ' Deriving sales person name: ' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || gc_debug_msg);
            BEGIN
               /* Begin Modification  for ver 1.5 Defect Id: 45279 Updating sales person to null
               lc_sales_person := arpt_sql_func_util.get_salesrep_name_number(trx_tab(trx_rec).sales_person_id
                                                                             ,'NAME'
                                                                             , fnd_profile.VALUE('ORG_ID') );  -- defect 26440 */
	           lc_sales_person := NULL;
	           /* End Modification  for ver 1.5 Defect Id: 45279 Updating sales person to null */

            EXCEPTION
               WHEN no_data_found THEN
                  lc_sales_person := NULL;
            END;

            gc_debug_msg := to_char(SYSDATE
                                   ,'dd-mon-yyyy HH24:MI:SS') || ' Inserting header record: ' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || gc_debug_msg);

            INSERT INTO xx_ar_ebl_ind_hdr_main
               (customer_trx_id
               ,cust_doc_id
               ,mbs_doc_id
               ,billdocs_delivery_method
               ,document_type
               ,direct_flag
               ,bill_from_date
               ,bill_to_date
               ,mail_to_attention
               ,invoice_number
               ,original_order_number
               ,original_invoice_amount
               ,amount_due_remaining
               ,gross_sale_amount
               ,tax_rate
               ,credit_memo_reason
               ,invoice_bill_date
               ,bill_due_date
               ,invoice_currency_code
               ,order_date
               ,reconcile_date
               ,order_header_id
               ,order_level_comment
               ,order_level_spc_comment
               ,order_type
               ,order_type_code
               ,order_source_code
               ,ordered_by
               ,payment_term
               ,payment_term_description
               ,payment_term_discount
               ,payment_term_discount_date
               ,payment_term_frequency
               ,payment_term_report_day
               ,payment_term_string
               ,total_bulk_amount
               ,total_coupon_amount
               ,total_discount_amount
               ,total_freight_amount
               ,total_gift_card_amount
               ,total_gst_amount
               ,total_hst_amount
               ,total_miscellaneous_amount
               ,total_association_discount
               ,total_pst_amount
               ,total_qst_amount
               ,total_tiered_discount_amount
               ,total_us_tax_amount
               ,sku_lines_subtotal
               ,sales_person
               ,cust_account_id
               ,oracle_account_number
               ,customer_name
               ,aops_account_number
               ,cust_acct_site_id
               ,cust_site_sequence
               ,customer_ref_date
               ,customer_ref_number
               ,sold_to_customer_number
               ,transaction_source
               ,transaction_type
               ,transaction_class
               ,transaction_date
               ,bill_to_name
               ,bill_to_address1
               ,bill_to_address2
               ,bill_to_address3
               ,bill_to_address4
               ,bill_to_city
               ,bill_to_state
               ,bill_to_country
               ,bill_to_zip
               ,bill_to_contact_name
               ,bill_to_contact_phone
               ,bill_to_contact_phone_ext
               ,bill_to_contact_email
               ,bill_to_abbreviation
               ,carrier
               ,ship_to_name
               ,ship_to_abbreviation
               ,ship_to_address1
               ,ship_to_address2
               ,ship_to_address3
               ,ship_to_address4
               ,ship_to_city
               ,ship_to_state
               ,ship_to_country
               ,ship_to_zip
               ,ship_to_sequence
               ,shipment_ref_number
               ,remit_address1
               ,remit_address2
               ,remit_address3
               ,remit_address4
               ,remit_city
               ,remit_state
               ,remit_zip
               ,remit_country
               ,us_federal_id
               ,canadian_tax_number
               ,cost_center_sft_hdr
               ,dept_desc--defect 15118
               ,dept_code -- Added for Defect 36437 (MOD4B Release 3)
               ,po_number_sft_hdr
               ,release_number_sft_hdr
               ,desktop_sft_hdr
               ,number_of_lines
               ,last_updated_by
               ,last_updated_date
               ,created_by
               ,creation_date
               ,last_updated_login
               ,extract_batch_id
               ,file_id
               ,transmission_id
               ,file_name
               ,org_id
               ,bill_to_site_use_id
               ,parent_cust_doc_id
               ,epdf_doc_level
               ,request_id
               ,trx_number
               ,desktop_sft_data
               ,po_number_sft_data
               ,cost_center_sft_data
               ,release_number_sft_data
               ,account_contact
               ,order_contact
               ,total_delivery_amount
               ,sales_order_number
               ,batch_source_id
               ,trx_term_description)
            VALUES
               (trx_tab(trx_rec).customer_trx_id
               ,trx_tab(trx_rec).cust_doc_id
               ,trx_tab(trx_rec).mbs_doc_id
               ,trx_tab(trx_rec).billdocs_delivery_method
               ,decode(trx_tab(trx_rec).document_type
                      ,'Y'
                      ,'Paydoc'
                      ,'N'
                      ,'Infocopy')
               ,decode(trx_tab(trx_rec).direct_flag
                      ,'Y'
                      ,'D'
                      ,'N'
                      ,'I')
               ,to_date(trx_tab(trx_rec).bill_from_date) + 1
               ,trx_tab(trx_rec).bill_to_date
               ,trx_tab(trx_rec).mail_to_attention
               ,trx_tab(trx_rec).invoice_number
               ,lc_orgordnbr
               ,trx_tab(trx_rec).original_invoice_amount
               ,trx_tab(trx_rec).amount_due_remaining
               ,trx_tab(trx_rec).original_invoice_amount - (trx_tab(trx_rec).total_us_tax_amount + trx_tab(trx_rec).total_gst_amount + trx_tab(trx_rec).total_pst_qst_tax)
               ,DECODE((trx_tab(trx_rec).total_gst_amount +trx_tab(trx_rec).total_pst_qst_tax + trx_tab(trx_rec).total_us_tax_amount),0,0,ln_hdr_tax_rate)
               ,lc_reason_code
               ,trx_tab(trx_rec).bill_to_date
               ,decode(trx_tab(trx_rec).transaction_class , 'CM' , NULL ,trx_tab(trx_rec).bill_due_date)
               ,trx_tab(trx_rec).invoice_currency_code
               ,trx_tab(trx_rec).order_date
               ,trx_tab(trx_rec).reconcile_date
               ,trx_tab(trx_rec).order_header_id
               ,trx_tab(trx_rec).order_level_comment
               ,trx_tab(trx_rec).order_level_spc_comment
               ,trx_tab(trx_rec).order_type
               ,trx_tab(trx_rec).order_type_code
               ,trx_tab(trx_rec).order_source_code
               ,trx_tab(trx_rec).ordered_by
               ,trx_tab(trx_rec).payment_term
               ,trx_tab(trx_rec).payment_term_description
               ,trx_tab(trx_rec).payment_term_discount
               ,xx_ar_ebl_common_util_pkg.get_discount_date(trx_tab(trx_rec).customer_trx_id)
               ,trx_tab(trx_rec).payment_term_frequency
               ,trx_tab(trx_rec).payment_term_report_day
               ,trx_tab(trx_rec).billing_term
               ,trx_tab(trx_rec).total_bulk_amount
               ,trx_tab(trx_rec).total_coupon_amount
               ,trx_tab(trx_rec).total_bulk_amount + trx_tab(trx_rec).total_tiered_discount_amount + trx_tab(trx_rec).total_association_discount
               ,trx_tab(trx_rec).total_delivery_amount
               ,trx_tab(trx_rec).total_gift_card_amount
               ,trx_tab(trx_rec).total_gst_amount
               ,trx_tab(trx_rec).total_gst_amount + trx_tab(trx_rec).total_pst_qst_tax
               ,trx_tab(trx_rec).total_miscellaneous_amount
               ,trx_tab(trx_rec).total_association_discount ---- *********** ADDED COLUMN HERE
               ,trx_tab(trx_rec).total_pst_amount
               ,trx_tab(trx_rec).total_qst_amount
               ,trx_tab(trx_rec).total_tiered_discount_amount
               ,trx_tab(trx_rec).total_us_tax_amount
               ,trx_tab(trx_rec).sku_lines_subtotal
               ,lc_sales_person
               ,trx_tab(trx_rec).cust_account_id
               ,trx_tab(trx_rec).oracle_account_number
               ,trx_tab(trx_rec).customer_name
               ,trx_tab(trx_rec).aops_account_number
               ,trx_tab(trx_rec).cust_acct_site_id
               ,trx_tab(trx_rec).cust_site_sequence
               ,trx_tab(trx_rec).customer_ref_date
               ,trx_tab(trx_rec).customer_ref_number
               ,lc_sold_to_customer
               ,trx_tab(trx_rec).transaction_source
               ,trx_tab(trx_rec).transaction_type
               ,decode(trx_tab(trx_rec).transaction_class
                      ,'CM'
                      ,'Credit Memo'
                      ,'DM'
                      ,'Debit Memo'
                      ,'INV'
                      ,'Invoice')
               ,trx_tab(trx_rec).transaction_date
               ,trx_tab(trx_rec).bill_to_name
               ,trx_tab(trx_rec).bill_to_address1
               ,trx_tab(trx_rec).bill_to_address2
               ,trx_tab(trx_rec).bill_to_address3
               ,trx_tab(trx_rec).bill_to_address4
               ,trx_tab(trx_rec).bill_to_city
               ,decode(trx_tab(trx_rec).bill_to_country
                      ,'US'
                      ,trx_tab(trx_rec).bill_to_state
                      ,lc_province)
               ,trx_tab(trx_rec).bill_to_country
               ,trx_tab(trx_rec).bill_to_zip
               ,trx_tab(trx_rec).bill_to_contact_name
               ,trx_tab(trx_rec).bill_to_contact_phone
               ,trx_tab(trx_rec).bill_to_contact_phone_ext
               ,trx_tab(trx_rec).bill_to_contact_email
               ,lc_location
               ,trx_tab(trx_rec).carrier
               ,trx_tab(trx_rec).ship_to_name
               ,trx_tab(trx_rec).ship_to_abbreviation
               ,trx_tab(trx_rec).ship_to_address1
               ,trx_tab(trx_rec).ship_to_address2
               ,trx_tab(trx_rec).ship_to_address3
               ,trx_tab(trx_rec).ship_to_address4
               ,trx_tab(trx_rec).ship_to_city
               ,trx_tab(trx_rec).ship_to_state
               ,trx_tab(trx_rec).ship_to_country
               ,trx_tab(trx_rec).ship_to_zip
               ,trx_tab(trx_rec).ship_to_sequence
               ,trx_tab(trx_rec).shipment_ref_number
               ,trx_tab(trx_rec).remit_address1
               ,trx_tab(trx_rec).remit_address2
               ,trx_tab(trx_rec).remit_address3
               ,trx_tab(trx_rec).remit_address4
               ,trx_tab(trx_rec).remit_city
               ,trx_tab(trx_rec).remit_state
               ,trx_tab(trx_rec).remit_zip
               ,trx_tab(trx_rec).remit_country
               ,decode(lc_country
                      ,'US'
                      ,lc_tax_number
                      ,NULL)
               ,decode(lc_country
                      ,'CA'
                      ,lc_tax_number
                      ,NULL)
               ,upper(nvl(trx_tab(trx_rec).cost_center_sft_hdr
                         ,'COST CENTER'))
                --,upper(nvl(trx_tab(trx_rec).cost_center_desc_hdr
                  --       ,'COST CENTER DESCRIPTION'))--Defect 15118
                ,trx_tab(trx_rec).cost_center_desc_hdr--Defect 22582
                ,trx_tab(trx_rec).cost_center_dept -- Added for Defect 36437 (MOD4B Release 3)
               ,upper(nvl(trx_tab(trx_rec).po_number_sft_hdr
                         ,'PURCHASE ORDER'))
               ,upper(nvl(trx_tab(trx_rec).release_number_sft_hdr
                         ,'RELEASE'))
               ,upper(nvl(trx_tab(trx_rec).desktop_sft_hdr
                         ,'DESKTOP'))
               ,trx_tab(trx_rec).number_of_lines
               ,fnd_global.user_id
               ,SYSDATE
               ,fnd_global.user_id
               ,SYSDATE
               ,fnd_global.login_id
               ,p_batch_id
               ,NULL
               ,NULL
               ,NULL
               ,fnd_profile.VALUE('ORG_ID')
               ,trx_tab(trx_rec).site_use_id
               ,trx_tab(trx_rec).parent_cust_doc_id
               ,lc_epdf_doc_detail
               ,ln_request_id
               ,trx_tab(trx_rec).invoice_number
               ,trx_tab(trx_rec).desktop_sft_data
               ,trx_tab(trx_rec).po_number_sft_data
               ,trx_tab(trx_rec).cost_center_sft_data
               ,trx_tab(trx_rec).release_number_sft_data
               ,lc_ph_no_cusrv
               ,lc_ph_no_bill
               ,trx_tab(trx_rec).total_delivery_amount
               ,trx_tab(trx_rec).sales_order_number
               ,trx_tab(trx_rec).batch_source_id
               ,lc_trx_term_description);

            ln_trx_count := ln_trx_count + 1;

            -- Calling Insert_lines
            gc_debug_msg := to_char(SYSDATE
                                   ,'dd-mon-yyyy HH24:MI:SS') || ' Insert Lines' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || gc_debug_msg);
            gc_debug_msg := to_char(SYSDATE
                                   ,'dd-mon-yyyy HH24:MI:SS') || ' Calling Insert Lines for' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id || ' custdoc id: ' || trx_tab(trx_rec).cust_doc_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || '          ' || gc_debug_msg);
            insert_lines(trx_tab(trx_rec).customer_trx_id
                        ,trx_tab(trx_rec).transaction_class
                        ,trx_tab(trx_rec).cust_doc_id
                        ,trx_tab(trx_rec).parent_cust_doc_id
                        ,trx_tab(trx_rec).cost_center_sft_hdr
                        ,p_batch_id
                        ,ln_item_master_org
                        ,trx_tab(trx_rec).order_source_code);
            gc_debug_msg := to_char(SYSDATE
                                   ,'dd-mon-yyyy HH24:MI:SS') || ' UPDATE frequency for' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id || ' custdoc id: ' || trx_tab(trx_rec).cust_doc_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || gc_debug_msg);
            UPDATE xx_ar_invoice_frequency xaif
            SET    xaif.status = 'IN PROCESS'
            WHERE  xaif.customer_document_id = trx_tab(trx_rec).cust_doc_id
            AND    xaif.invoice_id = trx_tab(trx_rec).customer_trx_id;

            gc_debug_msg := to_char(SYSDATE
                                   ,'dd-mon-yyyy HH24:MI:SS') || ' EXTRACT_DATA Procedure Complete' || ' TRX ID :' || trx_tab(trx_rec).customer_trx_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'          ' || gc_debug_msg);

         EXCEPTION
            WHEN OTHERS THEN
               lc_err_log := 'Error At :' || gc_debug_msg || ' ' || SQLERRM;
               xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                                     ,TRUE
                                                     ,'Error At :' || gc_debug_msg);

               gc_debug_msg := ' Exception raised in EXTRACT_DATA procedure for customer trx id : ' || trx_tab(trx_rec).customer_trx_id || ' Cust Doc ID :' || trx_tab(trx_rec).parent_cust_doc_id || ' Error :' || SQLERRM;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,TRUE
                                                     ,gc_debug_msg);
               ROLLBACK TO trx_insert;
               INSERT INTO xx_ar_ebl_error_bills
                  (org_id
                  ,cust_doc_id
                  ,document_type
                  ,aopscustomer_number
                  ,oracle_customer_number
                  ,delivery_method
                  ,frequency
                  ,cons_bill_number
                  ,trx_number
                  ,customer_trx_id
                  ,error_message
                  ,last_updated_by
                  ,last_updated_date
                  ,created_by
                  ,creation_date
                  ,last_updated_login
                  ,as_of_date)
               VALUES
                  (fnd_profile.VALUE('ORG_ID')
                  ,trx_tab(trx_rec).parent_cust_doc_id
                  ,decode(trx_tab(trx_rec).document_type
                         ,'Y'
                         ,'Paydoc'
                         ,'N'
                         ,'Infocopy')
                  ,trx_tab(trx_rec).aops_account_number
                  ,trx_tab(trx_rec).oracle_account_number
                  ,trx_tab(trx_rec).billdocs_delivery_method
                  ,trx_tab(trx_rec).billing_term
                  ,NULL
                  ,trx_tab(trx_rec).trx_number
                  ,trx_tab(trx_rec).customer_trx_id
                  ,lc_err_log
                  ,fnd_global.user_id
                  ,SYSDATE
                  ,fnd_global.user_id
                  ,SYSDATE
                  ,fnd_global.login_id
                  ,g_as_of_date);

               x_retcode := 1;
         END;
      END LOOP;

      gc_debug_msg := '******* Number of Transactions Inserted:' || ln_trx_count || ' *******';
      xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                            ,TRUE
                                            ,gc_debug_msg);

      gc_debug_msg := 'Calling populate_trans_details';

      xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                            ,TRUE
                                            ,gc_debug_msg);
      populate_trans_details(p_batch_id);
      gc_debug_msg := 'Calling populate_file_name';

      xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                            ,TRUE
                                            ,gc_debug_msg);

      populate_file_name(p_batch_id);
      gc_debug_msg := 'Calling insert_transmission_details';

      xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                            ,TRUE
                                            ,gc_debug_msg);

      insert_transmission_details(p_batch_id);

   EXCEPTION
      WHEN OTHERS THEN

         xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                               ,TRUE
                                               ,'Error At :' || gc_debug_msg);
         gc_debug_msg := ' Exception raised in EXTRACT_DATA procedure - When others. Error: ' || SQLERRM;
         xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                               ,TRUE
                                               ,gc_debug_msg);
         x_retcode := 2;

   END extract_data;

   PROCEDURE insert_lines(p_cust_trx_id        IN NUMBER
                         ,p_trx_type           IN VARCHAR2
                         ,p_cust_doc_id        IN NUMBER
                         ,p_parent_cust_doc_id IN NUMBER
                         ,p_dept_code          VARCHAR2
                         ,p_batch_id           NUMBER
                         ,p_organization_id    IN NUMBER
                         ,p_order_source_code  IN VARCHAR2) IS
      -- +===================================================================+
      -- |                  Office Depot - Project Simplify                  |
      -- |                          Wipro-Office Depot                       |
      -- +===================================================================+
      -- | Name             :  insert_lines                                  |                                   |
      -- | Description      :  This Procedure is used to Extract all the line|
      -- |                     Level Data                                    |
      -- |Change Record:                                                     |
      -- |===============                                                    |
      -- |Version   Date         Author             Remarks                  |
      -- |=======   ==========   =============      ======================   |
      -- |1.0       26-MAY-2010  Ranjith Thangasamy                          |
	  -- |2.0       04-DEC-2015  Havish Kasina      Added Cost Center Dept   |
	  -- |                                          (Module 4B Release 3)    |
      -- |3.0       15-JUN-2016  Suresh Naragam     Added Line Level Tax     |
      -- |                                          Amount(Module 4B Rel 4   |
	  -- |                                          Defect#2282)             |
	  -- |4.0       23-JUN-2016  Havish Kasina      Added for Kitting        |
	  -- |                                          (Defect 37675)           |
      -- +===================================================================+

      CURSOR lcu_inv_lines IS
         SELECT rctl1.attribute9 contract_plan_id
               ,rctl1.attribute10 contract_seq_number
               ,nvl(rctl1.extended_amount
                   ,rctl1.gross_extended_amount) ext_price
               ,rctl1.extended_amount extended_amount
               ,msi.segment1 inventory_item_number
               ,rctl1.description item_description
               ,xola.line_comments line_level_comment
               ,xola.backordered_qty quantity_back_ordered
               ,decode(p_trx_type
                      ,'CM'
                      ,rctl1.quantity_credited
                      ,nvl(rctl1.quantity_ordered
                          ,rctl1.quantity_invoiced)) quantity_ordered
               ,nvl(rctl1.quantity_invoiced
                   ,rctl1.quantity_credited) quantity_shipped
               ,muom.uom_code unit_of_measure
               ,nvl(xola.vendor_product_code
                   ,xola.wholesaler_item) vendor_product_code
               ,rctl1.amount_includes_tax_flag amount_includes_tax_flag
               ,rctl1.customer_trx_id customer_trx_id
               ,rctl1.customer_trx_line_id customer_trx_line_id
               ,msi.item_type item_type
               --,rctl1.line_number line_number
               ,XX_AR_EBL_COMMON_UTIL_PKG.get_fee_line_number(rctl1.customer_trx_id,rctl1.description,p_organization_id,rctl1.line_number) line_number  -- change 1.13
               ,rctl1.link_to_cust_trx_line_id link_to_cust_trx_line_id
               ,ool.line_id order_line_id
               ,ool.line_number order_line_number
               ,rctl1.sales_order sales_order
               ,rctl1.sales_order_date sales_order_date
               ,rctl1.sales_tax_id sales_tax_id
               ,rctl1.tax_exemption_id tax_exemption_id
               ,rctl1.tax_precedence tax_precedence
               ,rctl1.unit_selling_price unit_selling_pric
               ,rctl1.line_type line_type
               ,rctl1.inventory_item_id inventory_item_id
               ,rctl1.translated_description translated_description
               ,rctl1.quantity_credited quantity_credited
               ,rctl1.quantity_invoiced quantity_invoiced
               ,rctl1.unit_selling_price unit_price
               ,rctl1.translated_description cust_product_code
               --,xola.taxable_flag detail_rec_taxable_flag   --Commented for Defect #7025
               ,NULL   detail_rec_taxable_flag                --Added for Defect #7025
               ,xola.wholesaler_item wholesaler_item
               ,rctl1.interface_line_context interface_line_context
               ,rctl1.interface_line_attribute11 oe_price_adjustment_id
               ,xola.gsa_flag
               ,DECODE(Q_fee.Fee_item,'Y',null,nvl(to_char(to_number(ool.customer_line_number))
                   ,decode(substr(ool.orig_sys_line_ref
                                 ,1
                                 ,1)
                          ,'0'
                          ,ltrim(ool.orig_sys_line_ref
                                ,'0')
                          ,substr(ool.orig_sys_line_ref
                                 ,1
                                 ,9)))) po_line_number
               ,rctl1.translated_description productcdentered
               ,TRIM(xola.cust_dept_description) dept_description
			   ,TRIM(xola.cost_center_dept) cost_center_dept -- Added for Defect 36437 (MOD4B Release 3)
			   ,rctl1.attribute3                  -- Added for Kitting, Defect# 37675
			   ,rctl1.attribute4                  -- Added for Kitting, Defect# 37675
			   ,rctl1.warehouse_id whse_id        -- Added for Kitting, Defect# 37675
			   ,nvl(xola.tax_amount,0) tax_amount -- Added for SKU level Tax changes NAIT 58403
         FROM   ra_customer_trx_lines     rctl1
               ,oe_order_lines            ool
               ,xx_om_line_attributes_all xola
               ,mtl_units_of_measure      muom
               ,mtl_system_items          msi
               ,(select 'Y' Fee_item, attribute6,attribute7
                                       FROM fnd_lookup_values flv
                                      WHERE lookup_type =  'OD_FEES_ITEMS'
                                        AND flv.LANGUAGE='US'
                                        AND FLV.enabled_flag = 'Y'                                   
                                        AND SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE) AND NVL(FLV.end_date_active,SYSDATE+1)  
                                        AND FLV.attribute7 NOT IN ('DELIVERY','MISCELLANEOUS')  ) Q_fee
         WHERE  rctl1.customer_trx_id = p_cust_trx_id
         AND    rctl1.uom_code = muom.uom_code(+)
         AND    rctl1.inventory_item_id = msi.inventory_item_id(+)
         AND    rctl1.inventory_item_id = Q_fee.attribute6(+)
         AND    ool.line_id = xola.line_id(+)
         AND    rctl1.interface_line_attribute6 = ool.line_id(+)
         AND    msi.organization_id = p_organization_id
         AND    NOT EXISTS (SELECT attribute6
                 FROM   fnd_lookup_values
                 WHERE  lookup_type = 'OD_FEES_ITEMS'
                 AND    attribute7 = 'DELIVERY'
                 AND    nvl(attribute6
                           ,0) = rctl1.inventory_item_id)
         AND    NOT EXISTS (SELECT 1
                 FROM   oe_price_adjustments oea
                       ,fnd_lookup_values   flv
                 WHERE  oea.price_adjustment_id = nvl(rctl1.interface_line_attribute11
                                                     ,0)
                 AND    oea.attribute8 = flv.lookup_code
                 AND    flv.lookup_type = 'OD_DISCOUNT_ITEMS'
                 AND    flv.meaning IN ('Tiered Discount', 'Association Discount'))
		 AND    DECODE(rctl1.attribute3,'K',DECODE(rctl1.attribute5,'Y','1','2'),'1') = '1' -- Added for Kitting, Defect# 37675
         AND    rctl1.line_type = 'LINE';

      TYPE inv_lines_tab IS TABLE OF lcu_inv_lines%ROWTYPE INDEX BY BINARY_INTEGER;
      inv_line           inv_lines_tab;
      ln_organization_id NUMBER;
      lc_gsa_comments    VARCHAR2(1000);
      lc_line_type       oe_price_adjustments.attribute8%TYPE;
      ln_seq_number      NUMBER;
      ln_line_tax_amt    NUMBER :=0;
	  ln_kit_extended_amt   NUMBER;          -- Added for Kitting, Defect# 37675
	  ln_kit_unit_price     NUMBER;          -- Added for Kitting, Defect# 37675
	  lc_kit_sku_desc       VARCHAR2(240);   -- Added for Kitting, Defect# 37675
      lv_dept_type          VARCHAR2(240);   -- Added for 1.13
   BEGIN
      -- Open Detail Cursor
      ln_seq_number := 0;
      OPEN lcu_inv_lines;
      FETCH lcu_inv_lines BULK COLLECT
         INTO inv_line;
      --    lc_error_loc   :='Inside lcu_inv_lines cursor' ;
      --    lc_error_debug := NULL;
      FOR j IN 1 .. inv_line.COUNT
      LOOP
         lc_gsa_comments := xx_ar_ebl_common_util_pkg.gsa_comments(inv_line(j).gsa_flag);
         IF (inv_line(j).oe_price_adjustment_id > 0) THEN
            SELECT oea.attribute8
            INTO   lc_line_type
            FROM   oe_price_adjustments oea
            WHERE  oea.price_adjustment_id = nvl(inv_line(j).oe_price_adjustment_id
                                                ,0);
         ELSE
            lc_line_type  := 'ITEM';
            ln_seq_number := ln_seq_number + 1;
         END IF;

		-- Adding the changes for Kitting, Defect# 37675
		 IF inv_line(j).attribute3 = 'K'
			THEN
				 ln_kit_extended_amt := NULL;
				 ln_kit_unit_price   := NULL;
				 XX_AR_EBL_COMMON_UTIL_PKG.get_kit_extended_amount( p_customer_trx_id      => inv_line(j).customer_trx_id,
																	p_sales_order_line_id  => inv_line(j).order_line_id,
																	p_kit_quantity         => inv_line(j).quantity_shipped,
																	x_kit_extended_amt     => ln_kit_extended_amt,
																	x_kit_unit_price       => ln_kit_unit_price
																  );

				 inv_line(j).unit_price         := ln_kit_unit_price;
				 inv_line(j).extended_amount    := ln_kit_extended_amt;

		 END IF;

		 lc_kit_sku_desc := NULL;
		 IF inv_line(j).attribute4 IS NOT NULL AND inv_line(j).attribute3 = 'D'
			THEN
			  BEGIN
				SELECT TRIM(description)
				  INTO lc_kit_sku_desc
				  FROM mtl_system_items_b
				 WHERE segment1 = inv_line(j).attribute4
				   AND organization_id = inv_line(j).whse_id
				   ;
			  EXCEPTION
				WHEN OTHERS
				THEN
				  lc_kit_sku_desc := NULL;
			  END;
		 END IF;
	 -- End of Kitting Changes, Defect# 37675

         BEGIN
           SELECT NVL(SUM(rctl.extended_amount),0)
           INTO ln_line_tax_amt
           FROM  ra_customer_trx_lines_all rctl
           WHERE rctl.customer_trx_id = p_cust_trx_id
           AND rctl.link_to_cust_trx_line_id = inv_line(j).customer_trx_line_id
           AND rctl.line_type = 'TAX';
         EXCEPTION WHEN NO_DATA_FOUND THEN
           ln_line_tax_amt := 0;
         WHEN OTHERS THEN
           ln_line_tax_amt := 0;
         END;
         -- Added code change for 1.13
         BEGIN
           SELECT UPPER(hca.ATTRIBUTE9)
             INTO lv_dept_type
             FROM hz_cust_accounts hca,ra_customer_trx
           WHERE cust_account_id = bill_to_customer_id 
             AND customer_trx_id = p_cust_trx_id;
         EXCEPTION WHEN NO_DATA_FOUND THEN
           lv_dept_type := NULL;
         WHEN OTHERS THEN
           lv_dept_type := NULL;
         END;
         -- End code change for 1.13

         INSERT INTO xx_ar_ebl_ind_dtl_main
            (customer_trx_id
            ,cust_doc_id
            ,parent_cust_doc_id
            ,customer_trx_line_id
            ,trx_line_number
            ,trx_line_type
            ,item_description
            ,inventory_item_id
            ,inventory_item_number
            ,translated_description
            ,order_line_id
            ,po_line_number
            ,quantity_back_ordered
            ,quantity_credited
            ,quantity_invoiced
            ,quantity_ordered
            ,quantity_shipped
            ,unit_of_measure
            ,unit_price
            ,ext_price
            ,contract_plan_id
            ,contract_seq_number
            ,entered_product_code
            ,vendor_product_code
            ,customer_product_code
            ,discount_code
            ,elec_detail_seq_number
            ,elec_record_type
            ,wholesaler_item
            ,detail_rec_taxable_flag
            ,gsa_comments
            ,interface_line_context
            ,price_adjustment_id
            ,last_updated_by
            ,last_updated_date
            ,created_by
            ,creation_date
            ,last_updated_login
            ,extract_batch_id
            ,org_id
            ,line_level_comment
            ,dept_desc
            ,dept_sft_hdr
            ,dept_code
            ,line_tax_amt
			,kit_sku -- Added for Kitting, Defect# 37675
			,kit_sku_desc -- Added for Kitting, Defect# 37675
			,sku_level_tax   -- Added for SKU level Tax changes NAIT 58403
			,sku_level_total -- Added for SKU level Tax changes NAIT 58403
			)
         VALUES
            (p_cust_trx_id
            ,p_cust_doc_id
            ,p_parent_cust_doc_id
            ,inv_line(j).customer_trx_line_id
            ,inv_line(j).line_number
            ,lc_line_type
            ,inv_line(j).item_description
            ,inv_line(j).inventory_item_id
            ,inv_line(j).inventory_item_number
            ,inv_line(j).translated_description
            ,inv_line(j).order_line_id
            ,inv_line(j).po_line_number
            ,inv_line(j).quantity_back_ordered
            ,inv_line(j).quantity_credited
            ,inv_line(j).quantity_invoiced
            ,inv_line(j).quantity_ordered
            ,inv_line(j).quantity_shipped
            ,inv_line(j).unit_of_measure
            ,inv_line(j).unit_price
            ,inv_line(j).extended_amount
            ,inv_line(j).contract_plan_id
            ,inv_line(j).contract_seq_number
            ,inv_line(j).productcdentered
            ,inv_line(j).vendor_product_code
            ,inv_line(j).cust_product_code
            ,NULL
            ,ln_seq_number
            ,NULL
            ,inv_line(j).wholesaler_item
            ,inv_line(j).detail_rec_taxable_flag
            ,lc_gsa_comments
            ,inv_line(j).interface_line_context
            ,inv_line(j).oe_price_adjustment_id
            ,fnd_global.user_id
            ,SYSDATE
            ,fnd_global.user_id
            ,SYSDATE
            ,fnd_global.login_id
            ,p_batch_id
            ,fnd_profile.VALUE('ORG_ID')
            ,(CASE WHEN( p_order_source_code IN ('B','E','X')) THEN inv_line(j).line_level_comment ELSE NULL END)
            ,DECODE (lv_dept_type,'LINE',inv_line(j).dept_description)
            ,decode(inv_line(j).dept_description
                   ,NULL
                   ,NULL
                   ,nvl(p_dept_code
                       ,'Department'))
            ,inv_line(j).cost_center_dept  -- Added for Defect 36437 (MOD4B Release 3)
            ,ln_line_tax_amt
			,inv_line(j).attribute4  -- Added for Kitting, Defect# 37675
			,lc_kit_sku_desc   -- Added for Kitting, Defect# 37675
			,inv_line(j).tax_amount                                      -- Added for SKU level Tax changes NAIT 58403
			,nvl(inv_line(j).tax_amount+ inv_line(j).extended_amount,0)  -- Added for SKU level Tax changes NAIT 58403
			);
      END LOOP; -- End of Line cursor
   EXCEPTION
      WHEN OTHERS THEN
         xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                               ,TRUE
                                               ,to_char(SYSDATE
                                                       ,'dd-mon-yyyy HH24:MI:SS') || 'ERROR IN INSERT lINE ' || SQLERRM);
         CLOSE lcu_inv_lines;
         RAISE;
   END insert_lines;

   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                          Wipro-Office Depot                       |
   -- +===================================================================+
   -- | Name             :  populate_trans_details                        |
   -- | Description      :  This Procedure is used to populate file and   |
   -- |                     transmission Data                             |
   -- |Change Record:                                                     |
   -- |===============                                                    |
   -- |Version   Date         Author           Remarks                    |
   -- |=======   ==========   =============    ======================     |
   -- |1.0       26-MAY-2010  Ranjith Thangasamy                          |
   -- +===================================================================+
   PROCEDURE populate_trans_details(p_batch_id NUMBER) IS
      CURSOR lcu_cust_doc_ids IS
         SELECT DISTINCT hdr.parent_cust_doc_id
                        ,hdr.billdocs_delivery_method
                        ,xcem.ebill_transmission_type
                        ,xcem.file_processing_method
                        ,hdr.direct_flag
         FROM   xx_ar_ebl_ind_hdr_main hdr
               ,xx_cdh_ebl_main        xcem
         WHERE  xcem.cust_doc_id = hdr.parent_cust_doc_id
         AND    hdr.extract_batch_id = p_batch_id;
      ln_file_id             NUMBER;
      ln_transmission_id     NUMBER;
      lc_file_split_criteria VARCHAR2(100);
      lc_split_value         VARCHAR2(100);
      lc_null_loc_email      VARCHAR2(3000);
      lc_email_address       VARCHAR2(3000);
   BEGIN
      BEGIN
         FOR cust_doc_id_rec IN lcu_cust_doc_ids
         LOOP
           lc_null_loc_email :=NULL;
           IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
              lc_null_loc_email      := xx_ar_ebl_common_util_pkg.get_email_details(cust_doc_id_rec.parent_cust_doc_id
                                                                                ,NULL);
           END IF;
           lc_email_address  := NULL;

            IF (cust_doc_id_rec.billdocs_delivery_method = 'ePDF') THEN
               IF (cust_doc_id_rec.file_processing_method = '01') THEN

                  UPDATE xx_ar_ebl_ind_hdr_main
                  SET    file_id         = xx_ebl_file_seq.NEXTVAL
                        ,transmission_id = xx_ebl_trans_seq.NEXTVAL
                  WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                  AND    extract_batch_id = p_batch_id;
                  IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
                     FOR trx_rec IN (SELECT DISTINCT cust_acct_site_id
                                     FROM   xx_ar_ebl_ind_hdr_main
                                     WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                     AND    extract_batch_id = p_batch_id)
                     LOOP
                        lc_email_address := xx_ar_ebl_common_util_pkg.get_email_details(cust_doc_id_rec.parent_cust_doc_id
                                                                                       ,trx_rec.cust_acct_site_id);
                        UPDATE xx_ar_ebl_ind_hdr_main hdr
                        SET    email_address = nvl(lc_email_address
                                                  ,lc_null_loc_email)
                        WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                        AND    hdr.cust_acct_site_id = trx_rec.cust_acct_site_id
                        AND    extract_batch_id = p_batch_id;
                     END LOOP;
                  END IF;
               ELSIF (cust_doc_id_rec.file_processing_method = '02') THEN
             /*     IF (cust_doc_id_rec.ebill_transmission_type <> 'EMAIL') THEN
                     SELECT xx_ebl_trans_seq.NEXTVAL
                     INTO   ln_transmission_id
                     FROM   dual;
                  END IF;*/ --ranjith commented for mod
                  -- Update one trx with one file id
                  UPDATE xx_ar_ebl_ind_hdr_main
                  SET    file_id = xx_ebl_file_seq.NEXTVAL
                  WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                  AND    extract_batch_id = p_batch_id;
                  -- Update email address

                  IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
                     FOR trx_rec IN (SELECT DISTINCT cust_acct_site_id
                                     FROM   xx_ar_ebl_ind_hdr_main
                                     WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                     AND    extract_batch_id = p_batch_id)
                     LOOP
                        lc_email_address := xx_ar_ebl_common_util_pkg.get_email_details(cust_doc_id_rec.parent_cust_doc_id
                                                                                       ,trx_rec.cust_acct_site_id);
                        UPDATE xx_ar_ebl_ind_hdr_main hdr
                        SET    email_address = nvl(lc_email_address
                                                  ,lc_null_loc_email)
                        WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                        AND    hdr.cust_acct_site_id = trx_rec.cust_acct_site_id
                        AND    extract_batch_id = p_batch_id;
                     END LOOP;
                  END IF;
                  --- For every distinct email address list update one Transmission
                  FOR email_ids_rec IN (SELECT DISTINCT email_address
                                        FROM   xx_ar_ebl_ind_hdr_main
                                        WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                        AND    extract_batch_id = p_batch_id)
                  LOOP
                --     IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
                        SELECT xx_ebl_trans_seq.NEXTVAL
                        INTO   ln_transmission_id
                        FROM   dual;
                --     END IF;   -- ranjith commented for mod
                     UPDATE xx_ar_ebl_ind_hdr_main
                     SET    transmission_id = ln_transmission_id
                     WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                     AND    nvl(email_address
                               ,'XX') = nvl(email_ids_rec.email_address
                                            ,'XX')
                     AND    extract_batch_id = p_batch_id;
                  END LOOP;
               ELSIF (cust_doc_id_rec.file_processing_method = '03') THEN
              /*    IF (cust_doc_id_rec.ebill_transmission_type <> 'EMAIL') THEN
                     SELECT xx_ebl_file_seq.NEXTVAL
                     INTO   ln_file_id
                     FROM   dual;
                     SELECT xx_ebl_trans_seq.NEXTVAL
                     INTO   ln_transmission_id
                     FROM   dual;
                  END IF; */ --ranjith removed for mod
                  IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN  -- added
                  FOR trx_rec IN (SELECT DISTINCT cust_acct_site_id
                                  FROM   xx_ar_ebl_ind_hdr_main
                                  WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                  AND    extract_batch_id = p_batch_id)
                  LOOP
                  --   IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
                        lc_email_address := xx_ar_ebl_common_util_pkg.get_email_details(cust_doc_id_rec.parent_cust_doc_id
                                                                                       ,trx_rec.cust_acct_site_id);
                  --   END IF;
                  --   SELECT xx_ebl_file_seq.NEXTVAL
                  --   INTO   ln_file_id
                  --  FROM   dual;  -- removed for mod

                     UPDATE xx_ar_ebl_ind_hdr_main hdr
                     SET  --  hdr.file_id   = ln_file_id  -- removed for mod
                           email_address = nvl(lc_email_address
                                               ,lc_null_loc_email)
                     WHERE  hdr.cust_acct_site_id = trx_rec.cust_acct_site_id
                     AND    extract_batch_id = p_batch_id
                     AND    parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id;
                  END LOOP;
               END IF;  -- added
                  FOR file_ids_rec IN (SELECT --- DISTINCT DISTINCT file_id
                                             DISTINCT email_address ,DECODE(cust_doc_id_rec.direct_flag,'I',cust_acct_site_id,NULL) cust_acct_site_id
                                       FROM xx_ar_ebl_ind_hdr_main
                                       WHERE parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                       AND    extract_batch_id = p_batch_id
                                )
                  LOOP
               --      IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
                        SELECT xx_ebl_file_seq.nextval
                        INTO  ln_file_id
                        FROM   dual;
               --      END IF;

                     UPDATE xx_ar_ebl_ind_hdr_main
                     SET    file_id = ln_file_id -- added
                     WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                     AND NVL(email_address,'X') = NVL(file_ids_rec.email_address,'X')
                     AND cust_acct_site_id = NVL(file_ids_rec.cust_acct_site_id,cust_acct_site_id)
                     AND    extract_batch_id = p_batch_id;
                  END LOOP;
                  FOR trans_ids_rec IN (SELECT  DISTINCT file_id
                                       FROM xx_ar_ebl_ind_hdr_main
                                       WHERE parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                       AND    extract_batch_id = p_batch_id
                                )
                  LOOP
               --      IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
                        SELECT xx_ebl_trans_seq.NEXTVAL
                        INTO   ln_transmission_id
                        FROM   dual;
               --      END IF;

                     UPDATE xx_ar_ebl_ind_hdr_main
                     SET    transmission_id = ln_transmission_id
                    --      , file_id = ln_file_id -- added
                     WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                     AND file_id = trans_ids_rec.file_id
                     AND    extract_batch_id = p_batch_id;
                  END LOOP;
               END IF;
            ELSE
               -- Getting file Split Criteria
               BEGIN
                  SELECT file_split_criteria
                        ,file_split_value
                  INTO   lc_file_split_criteria
                        ,lc_split_value
                  FROM   xx_cdh_ebl_templ_header
                  WHERE  cust_doc_id = cust_doc_id_rec.parent_cust_doc_id;
               EXCEPTION
                  WHEN no_data_found THEN
                     lc_file_split_criteria := NULL;
                     lc_split_value         := NULL;
               END;

               IF (lc_file_split_criteria IS NOT NULL) THEN
                  IF lc_file_split_criteria = 'CRDR' THEN
                     UPDATE xx_ar_ebl_ind_hdr_main hdr
                     SET    split_identifier = (CASE WHEN(amount_due_remaining < 0) THEN 'CR' ELSE 'DR' END)
                     WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                     AND    extract_batch_id = p_batch_id;
                  ELSIF lc_file_split_criteria = 'PONPO' THEN
                     UPDATE xx_ar_ebl_ind_hdr_main hdr
                     SET    split_identifier = (CASE WHEN(po_number_sft_data IS NOT NULL) THEN 'PO' ELSE 'NPO' END)
                     WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                     AND    extract_batch_id = p_batch_id;
                  ELSIF lc_file_split_criteria = 'INVAMTABS' THEN
                     UPDATE xx_ar_ebl_ind_hdr_main hdr
                     SET    split_identifier = (CASE WHEN(abs(amount_due_remaining) < lc_split_value) THEN 'UNDER' ELSE 'OVER' END)
                     WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                     AND    extract_batch_id = p_batch_id;
                  ELSIF lc_file_split_criteria = 'INVAMT' THEN
                     UPDATE xx_ar_ebl_ind_hdr_main hdr
                     SET    split_identifier = (CASE WHEN(amount_due_remaining) < lc_split_value THEN 'UNDER' ELSE 'OVER' END)
                     WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                     AND    extract_batch_id = p_batch_id;
                  ELSE
                     UPDATE xx_ar_ebl_ind_hdr_main hdr
                     SET    split_identifier = 'NA'
                     WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                     AND    extract_batch_id = p_batch_id;
                  END IF;
               END IF;
               IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN

                  --- UPDATE EMAIL ADDRESS for each site
                  FOR trx_rec IN (SELECT DISTINCT cust_acct_site_id
                                  FROM   xx_ar_ebl_ind_hdr_main
                                  WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                  AND    extract_batch_id = p_batch_id)
                  LOOP
                     lc_email_address := xx_ar_ebl_common_util_pkg.get_email_details(cust_doc_id_rec.parent_cust_doc_id
                                                                                    ,trx_rec.cust_acct_site_id);
                     UPDATE xx_ar_ebl_ind_hdr_main hdr
                     SET    email_address = nvl(lc_email_address
                                               ,lc_null_loc_email)
                     WHERE  hdr.parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                     AND    hdr.cust_acct_site_id = trx_rec.cust_acct_site_id
                     AND    extract_batch_id = p_batch_id;
                  END LOOP;
               END IF;
                  FOR file_ids IN (SELECT DISTINCT split_identifier,email_address,DECODE(cust_doc_id_rec.direct_flag,'I',cust_acct_site_id,NULL) cust_acct_site_id
                                FROM xx_ar_ebl_ind_hdr_main
                                WHERE parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                AND    extract_batch_id = p_batch_id
                                )
                  LOOP
                     SELECT xx_ebl_file_seq.NEXTVAL
                     INTO   ln_file_id
                     FROM   dual;

                     UPDATE xx_ar_ebl_ind_hdr_main
                     SET    file_id = ln_file_id
                     WHERE  nvl(split_identifier
                               ,'XX') = nvl(file_ids.split_identifier
                                           ,'XX')
                     AND NVL(email_address,'XX') = NVL(file_ids.email_address,'XX')
                     AND    cust_acct_site_id = NVL(file_ids.cust_acct_site_id,cust_acct_site_id)
                     AND    parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                     AND    extract_batch_id = p_batch_id;
                  END LOOP;
                  FOR trans_ids_rec IN (SELECT --- DISTINCT DISTINCT file_id
                                             DISTINCT email_address
                                       FROM xx_ar_ebl_ind_hdr_main
                                       WHERE parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                       AND    extract_batch_id = p_batch_id
                                )
                  LOOP
               --      IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
                        SELECT xx_ebl_trans_seq.NEXTVAL
                        INTO   ln_transmission_id
                        FROM   dual;
               --      END IF;

                     UPDATE xx_ar_ebl_ind_hdr_main
                     SET    transmission_id = ln_transmission_id
                    --      , file_id = ln_file_id -- added
                     WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                     AND NVL(email_address,'X') = NVL(trans_ids_rec.email_address,'X')
                     AND    extract_batch_id = p_batch_id;
                  END LOOP;

           END IF;
         END LOOP;
      EXCEPTION
         WHEN OTHERS THEN
            xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                                  ,TRUE
                                                  ,'Error in POPULATE_TRANS_DETAILS : ' || SQLERRM);
      END;
   END populate_trans_details;

   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                          Wipro-Office Depot                       |
   -- +===================================================================+
   -- | Name             :  populate_file_name                            |
   -- | Description      :  This Procedure is used to populate file names |
   -- |Change Record:                                                     |
   -- |===============                                                    |
   -- |Version   Date         Author           Remarks                    |
   -- |=======   ==========   =============    ======================     |
   -- |1.0       26-MAY-2010  Ranjith Thangasamy                          |
   -- +===================================================================+
   PROCEDURE populate_file_name(p_batch_id IN NUMBER) IS
      CURSOR cust_doc_details IS
         SELECT DISTINCT hdr.file_id
                        ,hdr.transmission_id
                        ,hdr.split_identifier
                        ,xcem.cust_account_id customer_id
                        ,hdr.email_address
                        ,xcem.ebill_transmission_type
                        ,hdr.parent_cust_doc_id
                        ,hdr.document_type
                        ,hdr.billdocs_delivery_method
                        ,file_name_ext
                        ,zip_required
                        ,zip_file_name_ext
         FROM   xx_ar_ebl_ind_hdr_main hdr
               ,xx_cdh_ebl_main        xcem
         WHERE  extract_batch_id = p_batch_id
         AND    xcem.cust_doc_id = hdr.parent_cust_doc_id;

      CURSOR lcu_file_name(p_cust_doc_id IN NUMBER) IS
         SELECT val.source_value1 field_id
               ,val.source_value4 "MAP"
                ,val.source_value2 TYPE
                ,xcefn.default_if_null
                ,xcefn.constant_value
         FROM   xx_cdh_ebl_file_name_dtl   xcefn
               ,xx_fin_translatedefinition def
               ,xx_fin_translatevalues     val
         WHERE  def.translate_id = val.translate_id
         AND    xcefn.field_id = to_number(val.source_value1)
         AND    def.translation_name = 'XX_CDH_EBILLING_FIELDS'
         AND    val.enabled_flag = 'Y'
         AND    xcefn.cust_doc_id = p_cust_doc_id
         ORDER  BY file_name_order_seq;

      lc_file_string VARCHAR2(1000) := NULL;
      lc_val         VARCHAR2(1000) := NULL;

      lc_table                    VARCHAR2(100);
      lc_select                   VARCHAR2(1000);
      lc_final_file_string        VARCHAR2(1000);
      lc_email_address            VARCHAR2(2000);
      lc_contact_name             VARCHAR2(2000);
      ln_count                    NUMBER;
      ln_file_next_seq_number     NUMBER;
      ld_file_seq_reset_date      DATE;
      ln_file_name_max_seq_number NUMBER;
      lc_file_name_seq_reset      VARCHAR2(2000);
      lc_insert_status            VARCHAR2(2000);
      lc_account_number hz_cust_Accounts_all.account_number%TYPE;
      lc_aops_acct_number hz_cust_Accounts_all.orig_system_reference%TYPE;
      lc_customer_name  hz_parties.party_name%TYPE;
   BEGIN
      FOR doc_detail_rec IN cust_doc_details
      LOOP
         lc_file_string := NULL;
         lc_account_number := NULL;
         lc_aops_acct_number :=NULL;
         lc_customer_name :=NULL;
         XX_AR_EBL_COMMON_UTIL_PKG.get_parent_details(doc_detail_rec.customer_id
                                                     ,lc_account_number
                                                     ,lc_aops_acct_number
                                                     ,lc_customer_name
                                                     );
         FOR fields_rec IN lcu_file_name(doc_detail_rec.parent_cust_doc_id)
         LOOP
            lc_val := NULL;
            IF (fields_rec.TYPE = 'Constant') THEN
               lc_val := fields_rec.constant_value;
            ELSIF (fields_rec.TYPE = 'Sequence') THEN
               BEGIN
                  SELECT file_next_seq_number
                        ,file_seq_reset_date
                        ,file_name_max_seq_number
                        ,file_name_seq_reset
                  INTO   ln_file_next_seq_number
                        ,ld_file_seq_reset_date
                        ,ln_file_name_max_seq_number
                        ,lc_file_name_seq_reset
                  FROM   xx_cdh_ebl_main
                  WHERE  cust_doc_id = doc_detail_rec.parent_cust_doc_id;
               EXCEPTION
                  WHEN OTHERS THEN
                     ln_file_next_seq_number     := NULL;
                     ld_file_seq_reset_date      := NULL;
                     ln_file_name_max_seq_number := NULL;
                     lc_file_name_seq_reset      := NULL;
                     fnd_file.put_line(fnd_file.log
                                      ,'error at 1 : ' || SQLERRM);
               END;
               IF ((lc_file_name_seq_reset = 'D') AND (ld_file_seq_reset_date <> g_as_of_date)) THEN
                  xx_cdh_ebl_main_pkg.upd_file_naming_seq_dtls(doc_detail_rec.parent_cust_doc_id
                                                              ,1
                                                              ,g_as_of_date --g_as_of_date
                                                              ,lc_insert_status);
                  ln_file_next_seq_number := 1;
               END IF;

               IF (ln_file_next_seq_number = ln_file_name_max_seq_number) THEN
                  xx_cdh_ebl_main_pkg.upd_file_naming_seq_dtls(doc_detail_rec.parent_cust_doc_id
                                                              ,1
                                                              ,g_as_of_date
                                                              ,lc_insert_status);
               ELSE
                  xx_cdh_ebl_main_pkg.upd_file_naming_seq_dtls(doc_detail_rec.parent_cust_doc_id
                                                              ,to_number(ln_file_next_seq_number) + 1
                                                              ,g_as_of_date --g_as_of_date
                                                              ,lc_insert_status);
               END IF;

               lc_val := ln_file_next_seq_number;

            ELSE
               IF (UPPER(fields_rec.MAP) = 'CUST_ACCOUNT_ID') THEN
                  lc_val := doc_detail_rec.customer_id;
               ELSIF (UPPER(fields_rec.MAP) = 'ORACLE_ACCOUNT_NUMBER') THEN
                  lc_val :=lc_account_number;
               ELSIF (UPPER(fields_rec.MAP) = 'CUSTOMER_NAME') THEN
                  lc_val :=lc_customer_name;
               ELSIF  (UPPER(fields_rec.MAP) = 'AOPS_ACCOUNT_NUMBER') THEN
                  lc_val :=lc_aops_Acct_number;
               ELSE
                  lc_table  := 'XX_AR_EBL_IND_HDR_MAIN';
                  lc_select := 'SELECT to_char(' || fields_rec.MAP || ') FROM ' || lc_table || ' WHERE file_id = ' || doc_detail_rec.file_id || ' AND rownum<2';
                  BEGIN
                     EXECUTE IMMEDIATE lc_select
                        INTO lc_val;
                  EXCEPTION
                     WHEN OTHERS THEN
                        lc_val := fields_rec.default_if_null;
                  END;
               END IF;
            END IF;
            lc_file_string := lc_file_string || '_' || lc_val;
         END LOOP;
         lc_file_string := REGEXP_REPLACE(lc_file_string,'[^A-Za-z0-9_-]','');

         IF nvl(doc_detail_rec.split_identifier
               ,'NA') <> 'NA' THEN
            lc_final_file_string := lc_file_string || '_' || doc_detail_rec.split_identifier || '.' || doc_detail_rec.file_name_ext;
         ELSE
            lc_final_file_string := lc_file_string || '.' || doc_detail_rec.file_name_ext;
         END IF;
         UPDATE xx_ar_ebl_ind_hdr_main
         SET    file_name = REPLACE(substr(lc_final_file_string
                                          ,2)
                                   ,' '
                                   ,'')
         WHERE  parent_cust_doc_id = doc_detail_rec.parent_cust_doc_id
         AND    file_id = doc_detail_rec.file_id
         AND    nvl(split_identifier
                   ,'x') = nvl(doc_detail_rec.split_identifier
                               ,'x')
         AND    extract_batch_id = p_batch_id;
      END LOOP;
   EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line(fnd_file.log
                          ,'when others - Populate file name ' || SQLERRM);
   END populate_file_name;
   -- +=================================================================================+
   -- |                  Office Depot - Project Simplify                                |
   -- |                          Wipro-Office Depot                                     |
   -- +=================================================================================+
   -- | Name             :  INSERT_TRANSMISSION_DETAILS                                 |
   -- | Description      :  This Procedure is used to insert transmission               |
   -- |                     Details                                                     |
   -- |Change Record:                                                                   |
   -- |===============                                                                  |
   -- |Version   Date         Author                Remarks                             |
   -- |=======   ==========   =============         ======================              |
   -- |1.0       26-MAY-2010  Ranjith Thangasamy                                        |
   -- |1.1       22-Jun-2015  Suresh Naragam        Done Changes to get the additional  |
   -- |                                             Columns data (Module 4B Release 1)  |
   -- |1.2       04-Sep-2018  Thilak CG             Added for the defect NAIT-27146     |
   -- |                                             Indirect merge docs transmission    |
   -- +=================================================================================+

   PROCEDURE insert_transmission_details(p_batch_id IN NUMBER) IS
      CURSOR trans_details IS
         SELECT DISTINCT hdr.transmission_id
                        ,xcem.cust_account_id customer_id
                        ,hdr.email_address
                        ,hdr.document_type
                        ,xcem.ebill_transmission_type
                        ,xcem.ebill_associate
                        ,hdr.parent_cust_doc_id
                        ,hdr.billdocs_delivery_method
                        ,zip_required
                        ,file_name_ext
                        ,zip_file_name_ext
                        ,MIN(hdr.bill_from_date) bill_from_date
                        ,MAX(hdr.bill_to_date) bill_to_date
                        ,MAX(hdr.bill_due_date) bill_due_date
                        ,hdr.payment_term_description payment_term
         FROM   xx_ar_ebl_ind_hdr_main hdr
               ,xx_cdh_ebl_main        xcem
         WHERE  xcem.cust_doc_id = hdr.parent_cust_doc_id
         AND    hdr.extract_batch_id = p_batch_id
         GROUP  BY hdr.transmission_id
                  ,xcem.cust_account_id
                  ,hdr.email_address
                  ,hdr.document_type
                  ,xcem.ebill_transmission_type
                  ,xcem.ebill_associate
                  ,hdr.parent_cust_doc_id
                  ,hdr.billdocs_delivery_method
                  ,zip_required
                  ,file_name_ext
                  ,zip_file_name_ext
                  ,hdr.payment_term_description;

      ld_due_date       DATE;
      ln_total_due      NUMBER;
      ln_file_id        NUMBER;
      lc_file_name      xx_ar_ebl_ind_hdr_main.file_name%TYPE;
      ln_site_use_id    NUMBER;
	  ln_cust_acct_site_id  NUMBER;
      gc_debug_msg      VARCHAR2(4000);
      lc_account_number hz_cust_Accounts_all.account_number%TYPE;
      lc_aops_acct_number hz_cust_Accounts_all.orig_system_reference%TYPE;
      lc_customer_name  hz_parties.party_name%TYPE;
  	  lc_payment_terms 	VARCHAR2(250) := NULL;
	  ld_payment_term_disc_date	DATE := NULL;
	  ln_total_merchandise_amt 	NUMBER := 0;
	  ln_total_misc_amt 		NUMBER := 0;
	  ln_total_gift_card_amt 	NUMBER := 0;
	  ln_total_salestax_amt 	NUMBER := 0;
   BEGIN
      FOR trans_id IN trans_details
      LOOP
         BEGIN
            SAVEPOINT trans_insert;
            lc_account_number := NULL;
            lc_aops_acct_number :=NULL;
            lc_customer_name :=NULL;
			ln_site_use_id :=NULL;
			ln_cust_acct_site_id :=NULL;
            XX_AR_EBL_COMMON_UTIL_PKG.get_parent_details(trans_id.customer_id
                                                        ,lc_account_number
                                                        ,lc_aops_acct_number
                                                        ,lc_customer_name
                                                        );

            gc_debug_msg := 'Fetching site_use_id and cust_acct_site_id for transmission_id = ' || trans_id.transmission_id;

            BEGIN
               SELECT DISTINCT bill_to_site_use_id, cust_acct_site_id --Added cust_acct_site_id for Defect#NAIT-27146 by Thilak CG on 04-SEP-2018
               INTO   ln_site_use_id, ln_cust_acct_site_id
               FROM   xx_ar_ebl_ind_hdr_main hdr
               WHERE  hdr.transmission_id = trans_id.transmission_id;
            EXCEPTION
               WHEN too_many_rows THEN
                  ln_site_use_id       := NULL;
				  ln_cust_acct_site_id := NULL;
            END;

            gc_debug_msg := 'INSERT INTO xx_ar_ebl_transmission for transmission_id = ' || trans_id.transmission_id || ' and parent doc ID = ' || trans_id.parent_cust_doc_id;
            INSERT INTO xx_ar_ebl_transmission
               (transmission_id
               ,customer_id
               ,customer_doc_id
               ,site_use_id
			   ,cust_acct_site_id  --Added cust_acct_site_id for Defect#NAIT-27146 by Thilak CG on 04-SEP-2018
               ,transmission_type
               ,status
               ,dest_email_addr
               ,billing_dt_from
               ,billing_dt
               ,pay_terms
               ,bill_due_dt
               ,created_by
               ,creation_date
               ,last_updated_by
               ,last_update_date
               ,last_update_login
               ,org_id
               ,account_number)
            VALUES
               (trans_id.transmission_id
               ,trans_id.customer_id
               ,trans_id.parent_cust_doc_id
               ,ln_site_use_id
			   ,ln_cust_acct_site_id  --Added cust_acct_site_id for Defect#NAIT-27146 by Thilak CG on 04-SEP-2018
               ,trans_id.ebill_transmission_type
               ,'SEND'
               ,trans_id.email_address
               ,trans_id.bill_from_date
               ,trans_id.bill_to_date
               ,trans_id.payment_term
               ,trans_id.bill_due_date
               ,fnd_global.user_id
               ,SYSDATE
               ,fnd_global.user_id
               ,SYSDATE
               ,fnd_global.login_id
               ,fnd_profile.VALUE('ORG_ID')
               ,lc_account_number);

            gc_debug_msg := 'File records fetch for transmission_id= ' || trans_id.transmission_id || ' and parent doc ID = ' || trans_id.parent_cust_doc_id;
            FOR file_rec IN (SELECT DISTINCT file_id
                                            ,file_name
                                            ,lc_aops_acct_number aops_account_number
                                            ,lc_account_number account_number
                                            ,lc_customer_name customer_name
                                            ,trans_id.customer_id customer_id
                             FROM   xx_ar_ebl_ind_hdr_main
                             WHERE  parent_cust_doc_id = trans_id.parent_cust_doc_id
                             AND    transmission_id = trans_id.transmission_id
                             AND    extract_batch_id = p_batch_id)
            LOOP
               gc_debug_msg := 'File records feched for = ' || trans_id.transmission_id || ' File ID =;' || file_rec.file_id || ' and parent doc ID = ' || trans_id.parent_cust_doc_id;
               ln_total_due := 0;
               --Module 4B Release 1 Start
               ld_due_date  := NULL;
               ld_payment_term_disc_date := NULL;
               ln_total_merchandise_amt := 0;
               ln_total_misc_amt := 0;
               ln_total_gift_card_amt := 0;
               ln_total_salestax_amt := 0;
              --Module 4B Release 1 End
               BEGIN
        /*changed the column from the amount_due_remaining to the difference of original_invoice_amount and total_gift_card_amount as per Defect# 14000*/
                  SELECT SUM(original_invoice_amount-total_gift_card_amount),
                    SUM(gross_sale_amount - total_coupon_amount - total_freight_amount - total_discount_amount),
                    SUM(total_coupon_amount + total_freight_amount + total_discount_amount),
                    SUM(total_gift_card_amount),
                    SUM(total_gst_amount + total_pst_amount + total_us_tax_amount)    --Module 4B Release 1
                  INTO   ln_total_due,
                    ln_total_merchandise_amt,
                    ln_total_misc_amt,
                    ln_total_gift_card_amt,
                    ln_total_salestax_amt           --Module 4B Release 1
                  FROM   xx_ar_ebl_ind_hdr_main hdr
                  WHERE  hdr.file_id = file_rec.file_id;
               EXCEPTION
                  WHEN OTHERS THEN
                     ln_total_due := 0;
                     ln_total_merchandise_amt := 0;
                     ln_total_misc_amt := 0;
                     ln_total_gift_card_amt := 0;
                     ln_total_salestax_amt := 0;
               END;
               BEGIN
                  SELECT MAX(bill_due_date),
                  MAX(payment_term_discount_date)  --Module 4B Release 1
                  INTO   ld_due_date,
                  ld_payment_term_disc_date        --Module 4B Release 1
                  FROM   xx_ar_ebl_ind_hdr_main hdr
                  WHERE  hdr.file_id = file_rec.file_id;
               EXCEPTION
                  WHEN OTHERS THEN
                     ld_due_date := NULL;
                     ld_payment_term_disc_date := NULL;
               END;
               gc_debug_msg := 'Insert into FILE tables for transmissio id = ' || trans_id.transmission_id || ' File ID =;' || file_rec.file_id;

               INSERT INTO xx_ar_ebl_file
                  (file_id
                  ,transmission_id
                  ,file_type
                  ,file_name
                  ,status
                  ,total_due
                  ,description
                  ,bill_due_dt
                  ,account_number
                  ,aops_customer_number
                  ,cust_doc_id
                  ,billing_associate_name
                  ,paydoc_flag
                  ,invoice_type
                  ,extract_status
                  ,customer_name
                  ,org_id
                  ,cust_account_id
                  ,created_by
                  ,creation_date
                  ,last_updated_by
                  ,last_update_date
                  ,last_update_login
                  ,billing_dt
                  ,payment_terms            --Module 4B Release 1
                  ,discount_due_date        --Module 4B Release 1
                  ,total_merchandise_amt    --Module 4B Release 1
                  ,total_sales_tax_amt      --Module 4B Release 1
                  ,total_misc_amt           --Module 4B Release 1
                  ,total_gift_card_amt)     --Module 4B Release 1
               VALUES
                  (file_rec.file_id
                  ,trans_id.transmission_id
                  ,decode(trans_id.billdocs_delivery_method
                         ,'eXLS'
                         ,'XLS'
                         ,'ePDF'
                         ,'PDF'
                         ,'eTXT'
                         ,'TXT')
                  ,file_rec.file_name
                  ,decode(trans_id.billdocs_delivery_method
                         ,'eXLS'
                         ,'MANIP_READY'
                         ,'ePDF'
                         ,'RENDER'
                         ,'eTXT'
                         ,'RENDER')
                  ,ln_total_due
                  ,decode(trans_id.document_type
                         ,'Paydoc'
                         ,'ORIGINAL BILL'
                         ,'Infocopy'
                         ,'INFORMATIONAL COPY OF BILL')
                  ,ld_due_date
                  ,file_rec.account_number
                  ,file_rec.aops_account_number
                  ,trans_id.parent_cust_doc_id
                  ,xx_ar_ebl_common_util_pkg.get_billing_associate_name(trans_id.ebill_associate)
                  ,decode(trans_id.document_type
                         ,'Paydoc'
                         ,'Y'
                         ,'N')
                  ,'IND'
                  ,xx_ar_ebl_common_util_pkg.get_extract_status(g_as_of_date
                                                               ,trans_id.parent_cust_doc_id)
                  ,file_rec.customer_name
                  ,gn_org_id
                  ,file_rec.customer_id
                  ,fnd_global.user_id
                  ,SYSDATE
                  ,fnd_global.user_id
                  ,SYSDATE
                  ,fnd_global.login_id
                  ,g_as_of_date
                  ,lc_payment_terms             --Module 4B Release 1
                  ,ld_payment_term_disc_date    --Module 4B Release 1
                  ,ln_total_merchandise_amt     --Module 4B Release 1
                  ,ln_total_salestax_amt        --Module 4B Release 1
                  ,ln_total_misc_amt            --Module 4B Release 1
                  ,(-1) * ln_total_gift_card_amt);  --Module 4B Release 1
               UPDATE xx_ar_ebl_ind_hdr_main
               SET    status = 'TRANSMISSION DETAILS INSERTED'
               WHERE  file_id = file_rec.file_id;
            END LOOP;
            IF (trans_id.zip_required = 'Y') THEN
               BEGIN
                  SELECT DISTINCT (file_name)
                  INTO   lc_file_name
                  FROM   xx_ar_ebl_ind_hdr_main hdr
                  WHERE  hdr.transmission_id = trans_id.transmission_id;
                  gc_debug_msg := 'Insert into ZIP FILE  for transmission id = ' || trans_id.transmission_id;
                  INSERT INTO xx_ar_ebl_file
                     (file_id
                     ,transmission_id
                     ,file_type
                     ,file_name
                     ,status
                     ,extract_status
                     ,cust_account_id
                     ,org_id
                     ,created_by
                     ,creation_date
                     ,last_updated_by
                     ,last_update_date
                     ,last_update_login
                     ,billing_dt)
                  VALUES
                     (xx_ebl_file_seq.NEXTVAL
                     ,trans_id.transmission_id
                     ,'ZIP'
                     ,substr(lc_file_name
                            ,1
                            ,instr(lc_file_name
                                  ,'.'
                                  ,-1)) || trans_id.zip_file_name_ext
                     ,'RENDER'
                     ,xx_ar_ebl_common_util_pkg.get_extract_status(g_as_of_date
                                                                  ,trans_id.parent_cust_doc_id)
                     ,trans_id.customer_id
                     ,gn_org_id
                     ,fnd_global.user_id
                     ,SYSDATE
                     ,fnd_global.user_id
                     ,SYSDATE
                     ,fnd_global.login_id
                     ,g_as_of_Date);
               EXCEPTION
                  WHEN too_many_rows THEN
                     gc_debug_msg := 'Insert into ZIP FILE  for transmission id = ' || trans_id.transmission_id;
                     INSERT INTO xx_ar_ebl_file
                        (file_id
                        ,transmission_id
                        ,file_type
                        ,file_name
                        ,status
                        ,extract_status
                        ,cust_account_id
                        ,org_id
                        ,created_by
                        ,creation_date
                        ,last_updated_by
                        ,last_update_date
                        ,last_update_login
                        ,billing_dt)
                     VALUES
                        (xx_ebl_file_seq.NEXTVAL
                        ,trans_id.transmission_id
                        ,'ZIP'
                        ,lc_account_number || '_' || trans_id.parent_cust_doc_id || '_' || trans_id.transmission_id || '.' || trans_id.zip_file_name_ext
                        ,'RENDER'
                        ,xx_ar_ebl_common_util_pkg.get_extract_status(g_as_of_date
                                                                     ,trans_id.parent_cust_doc_id)
                        ,trans_id.customer_id
                        ,gn_org_id
                        ,fnd_global.user_id
                        ,SYSDATE
                        ,fnd_global.user_id
                        ,SYSDATE
                        ,fnd_global.login_id
                        ,g_as_of_date);
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS THEN
               xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                                     ,TRUE
                                                     ,'Exception in inserting transmission details : ' || SQLERRM || chr(13) || ' Transmission id :' || trans_id.transmission_id);
               gc_debug_msg := 'Error ' || SQLERRM || ' at ' || gc_debug_msg;
               ROLLBACK TO trans_insert;
               INSERT INTO xx_ar_ebl_file
                  (file_id
                  ,transmission_id
                  ,status_detail
                  ,status
                  ,file_type
                  ,file_name
                  ,cust_account_id
                  ,org_id
                  ,cust_doc_id
                  ,created_by
                  ,creation_date
                  ,last_updated_by
                  ,last_update_date
                  ,last_update_login
                  ,billing_dt)
               VALUES
                  (xx_ebl_file_seq.NEXTVAL
                  ,nvl(trans_id.transmission_id
                      ,-1)
                  ,gc_debug_msg
                  ,'FILE INSERT FAILED'
                  ,decode(trans_id.billdocs_delivery_method
                         ,'eXLS'
                         ,'XLS'
                         ,'ePDF'
                         ,'PDF'
                         ,'eTXT'
                         ,'TXT')
                  ,'ERROR_FILE'
                  ,trans_id.customer_id
                  ,gn_org_id
                  ,trans_id.parent_cust_doc_id
                  ,fnd_global.user_id
                  ,SYSDATE
                  ,fnd_global.user_id
                  ,SYSDATE
                  ,fnd_global.login_id
                  ,g_as_of_date);
         END;
      END LOOP;
   END insert_transmission_details;
   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                          Wipro-Office Depot                       |
   -- +===================================================================+
   -- | Name             :  INSERT_ZERO_BYTE_FILE                         |
   -- | Description      :  This Procedure is used to insert zero byte    |
   -- |                     transmission  Details                         |
   -- |Change Record:                                                     |
   -- |===============                                                    |
   -- |Version   Date         Author           Remarks                    |
   -- |=======   ==========   =============    ======================     |
   -- |1.0       26-MAY-2010  Ranjith Thangasamy                          |
   -- +===================================================================+

   PROCEDURE insert_zero_byte_file AS
      CURSOR zero_byte_files IS
         SELECT xx_ebl_file_seq.NEXTVAL file_id
               ,xx_ebl_trans_seq.NEXTVAL transmission_id
               ,decode(xaifm.billdocs_delivery_meth
                      ,'eXLS'
                      ,'XLS'
                      ,'ePDF'
                      ,'PDF'
                      ,'eTXT'
                      ,'TXT') file_type
               ,decode(xaifm.billdocs_delivery_meth
                      ,'eXLS'
                      ,'MANIP_READY'
                      ,'ePDF'
                      ,'RENDER'
                      ,'eTXT'
                      ,'RENDER') status
               ,decode(xaifm.billdocs_paydoc_ind
                      ,'Y'
                      ,'ORIGINAL BILL'
                      ,'N'
                      ,'INFORMATIONAL COPY OF BILL') doc_description
               ,hza.account_number acct_number
               ,substr(hza.orig_system_reference
                      ,1
                      ,8) aops_acct_number
               ,xaifm.parent_cust_doc_id
               ,xaifm.billdocs_paydoc_ind paydoc_flag
               ,xaifm.parent_cust_acct_id
               ,xcem.ebill_transmission_type
               ,xaifm.billdocs_payment_term
         FROM   xx_ar_inv_freq_master       xaifm
               ,xx_cdh_ebl_transmission_dtl xctd
               ,hz_cust_accounts            hza
               ,xx_cdh_ebl_main             xcem
         WHERE  xaifm.parent_cust_doc_id = xctd.cust_doc_id
         AND    xcem.cust_doc_id = xaifm.parent_cust_doc_id
         AND    xctd.ftp_send_zero_byte_file = 'Y'
         AND    xcem.ebill_transmission_type = 'FTP'
         AND    xaifm.billdocs_delivery_meth = 'eTXT'
         AND    xaifm.org_id = gn_org_id
         AND    hza.cust_account_id = xaifm.parent_cust_acct_id
         AND    NOT EXISTS (SELECT 1
                 FROM   xx_ar_ebl_ind_hdr_main hdr
                 WHERE  hdr.parent_cust_doc_id = xctd.cust_doc_id)
         AND    NOT EXISTS (SELECT 1
                 FROM   xx_ar_ebl_error_bills err
                 WHERE  err.cust_doc_id = xctd.cust_doc_id
                 AND    err.as_of_date = g_as_of_date);
      lc_zero_bute_files zero_byte_files%ROWTYPE;
   BEGIN

      FOR lcu_zero_byte_files IN zero_byte_files
      LOOP
         INSERT INTO xx_ar_ebl_file
            (file_id
            ,transmission_id
            ,file_type
            ,file_name
            ,status
            ,description
            ,account_number
            ,aops_customer_number
            ,cust_doc_id
            ,paydoc_flag
            ,org_id
            ,created_by
            ,zero_byte_flag
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
            ,billing_dt)
         VALUES
            (lcu_zero_byte_files.file_id
            ,lcu_zero_byte_files.transmission_id
            ,lcu_zero_byte_files.file_type
            ,'ZERO_BYTE'
            ,lcu_zero_byte_files.status
            ,lcu_zero_byte_files.doc_description
            ,lcu_zero_byte_files.acct_number
            ,lcu_zero_byte_files.aops_acct_number
            ,lcu_zero_byte_files.parent_cust_doc_id
            ,lcu_zero_byte_files.paydoc_flag
            ,gn_org_id
            ,fnd_global.user_id
            ,'Y'
            ,SYSDATE
            ,fnd_global.user_id
            ,SYSDATE
            ,fnd_global.login_id
            ,g_as_of_date);
         INSERT INTO xx_ar_ebl_transmission
            (transmission_id
            ,customer_id
            ,customer_doc_id
            ,transmission_type
            ,status
            ,pay_terms
            ,zero_byte_flag
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login)
         VALUES
            (lcu_zero_byte_files.transmission_id
            ,lcu_zero_byte_files.parent_cust_acct_id
            ,lcu_zero_byte_files.parent_cust_doc_id
            ,lcu_zero_byte_files.ebill_transmission_type
            ,'SEND'
            ,lcu_zero_byte_files.billdocs_payment_term
            ,'Y'
            ,fnd_global.user_id
            ,SYSDATE
            ,fnd_global.user_id
            ,SYSDATE
            ,fnd_global.login_id);
      END LOOP;
   END insert_zero_byte_file;
   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                          Wipro-Office Depot                       |
   -- +===================================================================+
   -- | Name             :  INSERT_ERROR_FILE                             |
   -- | Description      :  This Procedure is used to insert erro file    |
   -- |                     Details                                       |
   -- |Change Record:                                                     |
   -- |===============                                                    |
   -- |Version   Date         Author           Remarks                    |
   -- |=======   ==========   =============    ======================     |
   -- |1.0       26-MAY-2010  Ranjith Thangasamy                          |
   -- +===================================================================+
   PROCEDURE insert_error_file AS
      CURSOR error_files IS
         SELECT xx_ebl_file_seq.NEXTVAL file_id
               ,xx_ebl_trans_seq.NEXTVAL transmission_id
               ,decode(xaifm.billdocs_delivery_meth
                      ,'eXLS'
                      ,'XLS'
                      ,'ePDF'
                      ,'PDF'
                      ,'eTXT'
                      ,'TXT') file_type
               ,'DATAEXTRACT_FAILED' status
               ,decode(xaifm.billdocs_paydoc_ind
                      ,'Y'
                      ,'ORIGINAL BILL'
                      ,'N'
                      ,'INFORMATIONAL COPY OF BILL') doc_description
               ,hza.account_number acct_number
               ,substr(hza.orig_system_reference
                      ,1
                      ,8) aops_acct_number
               ,xaifm.parent_cust_doc_id
               ,xaifm.billdocs_paydoc_ind paydoc_flag
               ,xaifm.parent_cust_acct_id
               ,xcem.ebill_transmission_type
               ,xaifm.billdocs_payment_term
               ,xcem.ebill_associate
         FROM   xx_ar_inv_freq_master       xaifm
               ,xx_cdh_ebl_transmission_dtl xctd
               ,hz_cust_accounts            hza
               ,xx_cdh_ebl_main             xcem
         WHERE  xaifm.parent_cust_doc_id = xctd.cust_doc_id
         AND    xcem.cust_doc_id = xaifm.parent_cust_doc_id
         AND    xaifm.org_id = gn_org_id
         AND    hza.cust_account_id = xaifm.parent_cust_acct_id
         AND    NOT EXISTS (SELECT 1
                 FROM   xx_ar_ebl_ind_hdr_main hdr
                 WHERE  hdr.parent_cust_doc_id = xctd.cust_doc_id)
         AND    EXISTS (SELECT 1
                 FROM   xx_ar_ebl_error_bills err
                 WHERE  err.cust_doc_id = xctd.cust_doc_id
                 AND    err.as_of_date = g_as_of_date);
   BEGIN

      FOR lcu_error_files IN error_files
      LOOP
         INSERT INTO xx_ar_ebl_file
            (file_id
            ,transmission_id
            ,file_type
            ,file_name
            ,status
            ,extract_status
            ,description
            ,account_number
            ,aops_customer_number
            ,cust_doc_id
            ,paydoc_flag
            ,org_id
            ,billing_associate_name
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
            ,billing_dt)
         VALUES
            (lcu_error_files.file_id
            ,lcu_error_files.transmission_id
            ,lcu_error_files.file_type
            ,'ERROR_FILE'
            ,lcu_error_files.status
            ,'COMPLETE DOCUMENT FAILED'
            ,lcu_error_files.doc_description
            ,lcu_error_files.acct_number
            ,lcu_error_files.aops_acct_number
            ,lcu_error_files.parent_cust_doc_id
            ,lcu_error_files.paydoc_flag
            ,gn_org_id
            ,xx_ar_ebl_common_util_pkg.get_billing_associate_name(lcu_error_files.ebill_associate)
            ,fnd_global.user_id
            ,SYSDATE
            ,fnd_global.user_id
            ,SYSDATE
            ,fnd_global.login_id
            ,g_as_of_date);
         /*    INSERT INTO XX_AR_EBL_TRANSMISSION(transmission_id
         ,customer_id
         ,customer_doc_id
         ,transmission_type
         ,status
         ,pay_terms
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
         )
         VALUES (lcu_error_files.transmission_id
         ,lcu_error_files.parent_cust_acct_id
         ,lcu_error_files.parent_cust_doc_id
         ,lcu_error_files.ebill_transmission_type
         ,'SEND'
         ,lcu_error_files.billdocs_payment_term
         ,FND_GLOBAL.USER_ID
         ,sysdate
         ,FND_GLOBAL.USER_ID
         ,sysdate
         ,FND_GLOBAL.LOGIN_ID
         );*/
      END LOOP;
   END insert_error_file;
   -- +===================================================================================+
   -- |                  Office Depot - Project Simplify                                  |
   -- |                       WIPRO Technologies                                          |
   -- +===================================================================================+
   -- | Name        : get_cust_id                                                         |
   -- | Description : returns the cust_acct_id for the given cust_doc_id                  |
   -- |Parameters   :                                                                     |
   -- |                                                                                   |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version   Date          Author                 Remarks                             |
   -- |=======   ==========   =============           ====================================|
   -- |DRAFT 1.0              Ranjith Prabu           Initial draft version               |
   -- +===================================================================================+
   FUNCTION get_cust_id(p_cust_doc_id NUMBER) RETURN NUMBER IS
      lc_cust_acct_id NUMBER;
   BEGIN
      SELECT cust_account_id
      INTO   lc_cust_acct_id
      FROM   xx_cdh_ebl_main
      WHERE  cust_doc_id = p_cust_doc_id;

      RETURN lc_cust_acct_id;
   EXCEPTION
      WHEN OTHERS THEN
         xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                               ,TRUE
                                               ,'Error in getting parent cust doc id for cust doc id:' || p_cust_doc_id);
         lc_cust_acct_id := 0;
         RETURN lc_cust_acct_id;
   END;
END xx_ar_ebl_ind_invoices_pkg;
/