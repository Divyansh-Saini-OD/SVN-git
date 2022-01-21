create or replace PACKAGE BODY XX_AR_EBL_CONS_INVOICES AS
   g_as_of_date DATE;
   gn_org_id    NUMBER := fnd_profile.VALUE('ORG_ID');
   -- +===================================================================================+
   -- |                  Office Depot - Project Simplify                                  |
   -- |                       WIPRO Technologies                                          |
   -- +===================================================================================+
   -- | Name        : xx_ar_ebl_cons_invoices                                             |
   -- | Description : Package for consolidated data extraction engine                  -- |                                                                                   |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version   Date          Author                 Remarks                             |
   -- |=======   ==========   =============           ====================================|
   -- |DRAFT 1.0              Ranjith Prabu           Initial draft version               |
   -- +===================================================================================+
   -- +===================================================================================+
   -- |                  Office Depot - Project Simplify                                  |
   -- |                       WIPRO Technologies                                          |
   -- +===================================================================================+
   -- | Name        : cons_data_extract_main                                              |
   -- | Description : Batching program to submit multiple data extraction threads         |
   -- |Parameters   :                                                                     |
   -- |                                                                                   |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version   Date          Author                 Remarks                             |
   -- |=======   ==========   =============           ====================================|
   -- |DRAFT 1.0              Ranjith Prabu           Initial draft version               |
   -- |1.1       26-OCT-10    RamyaPriya M            Commented Taxable Flag              |
   -- |                                               For Defect #7025                    |
   -- |1.2       12-MAR-13    Rajeshkumar M R         Moved department description        |
   -- |                                               to header Defect# 15118             |
   -- |1.3       15-NOV-13    Arun Gannarapu          Made changes to pass org id to sales|
   -- |                                                function for R12 --Defect 26440    |
   -- |1.4       19-NOV-13    Arun Gannarapu          Made changes to change the status   |
   -- |                                               from "ACCEPT" to "FINAL"            |
   -- |1.5       04-DEC-13    Arun Gannarapu          Made changes to change the status   |
   -- |                                               from "ACCEPT" to "FINAL" -- 26795   |
   -- |1.6       17-Aug-2015  Suresh Naragam          Added bill to location column       |
   -- |                                               (Module 4B Release 2)               |
   -- |1.7       15-Oct-2015  Suresh Naragam          Removed Schema References           |
   -- |                                               (R12.2 Global standards)            |
   -- |1.8       08-DEC-2015  Havish Kasina           Added Cost Center Dept column       |
   -- |                                               (Module 4B Release 3)               |
   -- |1.9       15-JUN-2016  Suresh Naragam          Added Line Level Tax Amount         |
   -- |                                               (Module 4B Release 4)               |
   -- |1.10      23-JUN-2016  Havish Kasina           Kitting Changes (Defect 37675)      |
   -- |1.11      28-Feb-2018  Aniket Jadhav CG        Wave 3 UAT Defect   NAIT-29918      |
   -- |1.12      12-JUL-2018  Aarthi                  Sales person updated to NULL for    |
   -- |                                               Defect 45279                        |
   -- |1.13		 20-AUG-2018  Aarthi                  Wave 5 Adding Tax at SKU level for  |
   -- |                                               NAIT - 58403                        |
   -- |1.14      09-SEP-2018  Atul Khard			  NAIT-63607 SKU Not Populating for   |
   -- |                                               SPC Invoices in eXLS Bills. Changed |
   -- |                                               logic to populate 'productcdentered'|
   -- |1.15		 11-OCT-2018  Dinesh Nagapuri         Made Changes for Bill Complete      |
   -- |                                               NAIT-61963                          |
   -- |1.16      25-JUL-2019  Abhishek Kumar          Made changes for NAIT - 79913 for   |
   -- |                                               remit page issue                    |
   -- |1.17     27-MAY-2020  Divyansh           Added logic for JIRA NAIT-129167          |
   -- +===================================================================================+
   PROCEDURE cons_data_extract_main(x_errbuff     OUT VARCHAR2
                                   ,x_retcode     OUT NUMBER
                                   ,pn_batch_size IN NUMBER
                                   ,pn_thread_count IN NUMBER
                                   ,pc_as_of_date IN VARCHAR2
                                   ,p_debug_flag  IN VARCHAR2) IS
      lc_error_loc     VARCHAR2(1500) := NULL;
      lc_error_debug   VARCHAR2(1000) := NULL;
      lc_request_data  VARCHAR2(800) := NULL;
      ln_attr_group_id NUMBER;
      ln_request_id    NUMBER;
      ld_as_of_date    DATE;
      ln_batch_id      NUMBER;
      ln_curr_req_id   NUMBER;
      p_debug          BOOLEAN;
      ln_org_id        NUMBER := fnd_profile.VALUE('ORG_ID');
      ln_thread_count  NUMBER;
      TYPE cust_acct_id_table_type IS TABLE OF NUMBER;
      lt_cust_acct_id      cust_acct_id_table_type;
      ln_parent_request_id NUMBER;
      ln_cnt_err_request   NUMBER;
      ln_total_count NUMBER:=0;
      ln_batch_size  NUMBER:=0;
      CURSOR lcu_cust_acct_ids IS
         SELECT DISTINCT parent_cust_acct_id
         FROM   xx_ar_ebl_cons_bills_stg
         WHERE  org_id = gn_org_id;
   BEGIN
      lc_request_data      := fnd_conc_global.request_data;
      ln_parent_request_id := fnd_global.conc_request_id;
      IF (lc_request_data IS NULL) THEN

         IF (p_debug_flag = 'Y') THEN
            p_debug := TRUE;
         ELSE
            p_debug := FALSE;
         END IF;
         lc_error_loc   := 'Inside cons_data_extract_main Procedure';
         lc_error_debug := NULL;
         lc_error_loc   := 'Truncate staging table XX_AR_EBL_CONS_BILLS_STG';
         lc_error_debug := NULL;
         BEGIN
            EXECUTE IMMEDIATE 'ALTER TABLE XXFIN.XX_AR_EBL_CONS_BILLS_STG TRUNCATE PARTITION XX_AR_EBL_CONS_BILLS_STG_' || to_char(gn_org_id);
         END;
         ld_as_of_date := trunc(fnd_conc_date.string_to_date(pc_as_of_date));
         g_as_of_date  := ld_as_of_date;
         ln_request_id := fnd_global.conc_request_id;
         xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                               ,TRUE
                                               ,'Current Request ID :' || ln_request_id);
         xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                               ,TRUE
                                               ,'FND Conc Global Request Data is :' || lc_request_data);
         xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                               ,TRUE
                                               ,'As of date  :' || g_as_of_date);
         -- To get the attribute group id for the group name 'BILLDOCS' and type 'XX_CDH_CUST_ACCOUNT'
         BEGIN
            SELECT attr_group_id
            INTO   ln_attr_group_id
            FROM   ego_attr_groups_v
            WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
            AND    attr_group_name = 'BILLDOCS';
         EXCEPTION
            WHEN OTHERS THEN
               xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                                     ,TRUE
                                                     ,'Exception occured while retriving the attribute group id for the group name BILLDOCS and type XX_CDH_CUST_ACCOUNT : ' || SQLERRM);
               RAISE;
         END;
         xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                               ,FALSE
                                               ,to_char(SYSDATE
                                                       ,'DD-MON-YYYY HH24:MI:SS') || ' ' || 'Inserting into staging table XX_AR_EBL_CONS_BILLS_STG ........');
         lc_error_loc   := 'Inserting into staging table XX_AR_EBL_CONS_BILLS_STG';
         lc_error_debug := NULL;

         BEGIN
            INSERT INTO xx_ar_ebl_cons_bills_stg
               (cust_account_id
               ,parent_cust_acct_id
               ,extension_id
               ,cust_doc_id
               ,document_id
               ,billdocs_paydoc_ind
               ,total_copies
               ,delivery_method
               ,billing_term
               ,billing_detail
               ,direct_flag
               ,effective_from_date
               ,effective_to_date
               ,parent_cust_doc_id
               ,mail_to_attention
               ,org_id)
               (SELECT cust_account_id
                      ,decode(n_ext_attr15
                             ,NULL
                             ,cust_account_id
                             ,get_cust_id(n_ext_attr15,ln_attr_group_id))
                      ,extension_id
                      ,n_ext_attr2 -- cust doc id
                      ,n_ext_attr1
                      ,c_ext_attr2
                      ,n_ext_attr3
                      ,c_ext_attr3
                      ,c_ext_attr14
                      ,c_ext_attr1
                      ,c_ext_attr7
                      ,d_ext_attr1
                      ,d_ext_attr2
                      ,nvl(n_ext_attr15
                          ,n_ext_attr2) -- parent_cust_doc_id
                      ,c_ext_attr15 -- mail to attention
                      ,ln_org_id
                FROM   xx_cdh_cust_acct_ext_b
                WHERE  c_ext_attr1 = 'Consolidated Bill' -- Individual / Consolidated Indicator
                AND    c_ext_attr3 IN ('eXLS', 'ePDF', 'eTXT') -- Delivery Method
                AND    attr_group_id = ln_attr_group_id
                AND    xx_ar_inv_freq_pkg.compute_effective_date(c_ext_attr14
                                                                ,ld_as_of_date) = ld_as_of_date
                AND    d_ext_attr1 <= ld_as_of_date -- Effective From Date
                AND    nvl(d_ext_attr2
                          ,ld_as_of_date) >= ld_as_of_date
                AND    c_ext_attr16 = 'COMPLETE'); -- Effective To Date
         EXCEPTION
            WHEN OTHERS THEN
               xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                                     ,TRUE
                                                     ,' Exception occured while inserting records into staging table XX_AR_EBL_CONS_BILLS_STG  : ' || SQLERRM);
               RAISE;
         END;

          FND_FILE.PUT_LINE (FND_FILE.LOG,'Gathering table Stats -- > START :'||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS'));
       DBMS_STATS.GATHER_TABLE_STATS('XXFIN','XX_AR_EBL_CONS_BILLS_STG',CASCADE=> TRUE ,partname=> 'XX_AR_EBL_CONS_BILLS_STG_' || to_char(gn_org_id));
        FND_FILE.PUT_LINE (FND_FILE.LOG,'Gathering table Stats -- > END :'||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS'));

         lc_error_loc   := 'Opening lcu_cust_acct_ids cursor';
         lc_error_debug := NULL;
         IF (pn_thread_count IS  NOT NULL) THEN
            SELECT COUNT(DISTINCT parent_cust_acct_id)
            INTO ln_total_count
            FROM   xx_ar_ebl_cons_bills_stg
            WHERE  org_id = gn_org_id;

            IF (ln_total_count <> 0) THEN
            ln_batch_size := CEIL(ln_total_count/pn_thread_count);
            ELSE
            ln_batch_size := -1;
            END IF;
            xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                               ,TRUE
                                               ,CHR(13)||'Note: Program Will submit Child programs in Thread Count Mode'||CHR(13)
                                               ||'Total Parent Cust Acct IDs :'||ln_total_count||CHR(13)
                                               ||'Batch size of each thread :'||ln_batch_size);
         ELSE
            ln_batch_size := pn_batch_size;
            xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                               ,TRUE
                                               ,'Note: Program Will submit Child programs in Batch Size Mode'||CHR(13)
                                               ||'Batch size of each thread :'||ln_batch_size);
         END IF;
         IF (ln_batch_size <> -1) THEN
         OPEN lcu_cust_acct_ids;
         LOOP
            FETCH lcu_cust_acct_ids BULK COLLECT
               INTO lt_cust_acct_id LIMIT ln_batch_size;
            lc_error_loc   := 'Inside lcu_cust_acct_ids cursor';
            lc_error_debug := NULL;
            EXIT WHEN lt_cust_acct_id .COUNT = 0;
            SELECT xx_ar_batch_sequence.NEXTVAL
            INTO   ln_batch_id
            FROM   dual;
            FORALL i IN lt_cust_acct_id.FIRST .. lt_cust_acct_id.LAST
               UPDATE xx_ar_ebl_cons_bills_stg
               SET    batch_id = ln_batch_id
               WHERE  parent_cust_acct_id = lt_cust_acct_id(i)
               AND    org_id = ln_org_id;
         END LOOP;
         END IF;

         ln_thread_count := 0;
         FOR rec IN (SELECT DISTINCT batch_id
                     FROM   xx_ar_ebl_cons_bills_stg
                     WHERE  org_id = gn_org_id)
         LOOP
            -- Child program should be called here
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,TRUE
                                                  ,'Submitting Child for Batch ID:' || rec.batch_id);
            ln_thread_count := ln_thread_count + 1;
            ln_curr_req_id  := fnd_request.submit_request(application => 'XXFIN'
                                                         ,program     => 'XX_AR_EBL_EXTRACT_CONS_DATA'
                                                         ,sub_request => TRUE
                                                         ,argument1   => rec.batch_id
                                                         ,argument2   => ld_as_of_date
                                                         ,argument3   => p_debug_flag);

         END LOOP;
         IF (ln_thread_count > 0) THEN

            fnd_conc_global.set_req_globals(conc_status  => 'PAUSED'
                                           ,request_data => 'COMPLETE');
         END IF;

      ELSE
         -- Calling Zero byte insert
         lc_error_loc := 'Calling Zero byte insert';
         xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                               ,TRUE
                                               ,lc_error_loc);
         insert_zero_byte_file;

         -- Calling error record insert
         lc_error_loc := 'Calling error record insert';
         xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                               ,TRUE
                                               ,lc_error_loc);
         insert_error_file;

         SELECT COUNT(*)
         INTO   ln_cnt_err_request
         FROM   fnd_concurrent_requests
         WHERE  parent_request_id = ln_parent_request_id
         AND    phase_code = 'C'
         AND    status_code = 'E';

         IF ln_cnt_err_request <> 0 THEN
            lc_error_loc := ln_cnt_err_request || ' Child Requests are Errored Out.Please, Check the Child Requests LOG for Details';
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,TRUE
                                                  ,lc_error_loc);
            x_retcode := 2;
         ELSE
            lc_error_loc := 'All the Child Programs Completed Normal...';
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,TRUE
                                                  ,lc_error_loc);
         END IF;
      END IF;

   END cons_data_extract_main;
   -- +===================================================================================+
   -- |                  Office Depot - Project Simplify                                  |
   -- |                       WIPRO Technologies                                          |
   -- +===================================================================================+
   -- | Name        : extract_cons_data                                                   |
   -- | Description : Procedure to extract data and populate the staging tables           |
   -- |Parameters   :                                                                     |
   -- |                                                                                   |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version   Date          Author                 Remarks                             |
   -- |=======   ==========   =============           ====================================|
   -- |DRAFT 1.0              Ranjith Prabu           Initial draft version               |
   -- |1.1      15-NOV-13     Arun Gannarapu          Made changes to pass org id to sales|
   -- |                                                function for R12 --Defect 26440    |
   -- |1.2      17-Aug-2015   Suresh Naragam          Added bill to location column       |
   -- |                                               (Module 4B Release 2)               |
   -- |1.3		08-DEC-2015	  Havish Kasina	          Added Cost Center Dept              |
   -- | 										       column(Module4B Release 3)         |
   -- |1.4      12-JUL-2018	  Aarthi                  Sales person updated to             |
   -- |                                                NULL - Defect 45279                |
   -- +===================================================================================+
   PROCEDURE extract_cons_data(errbuff      OUT VARCHAR2
                              ,retcode      OUT NUMBER
                              ,p_batch_id   NUMBER
                              ,p_as_of_date VARCHAR2
                              ,p_debug_flag VARCHAR2) IS
      CURSOR lcu_cons_paydocs(p_batch_id NUMBER, p_org_id NUMBER) IS
         SELECT arci.cons_inv_id cons_inv_id
               ,to_date(arci.attribute1) - 1 print_date
               ,to_date(arci.attribute1) - 1 cut_off_date
               ,arci.customer_id customer_id
               ,xaecbs.cust_doc_id cust_doc_id
               ,xaecbs.document_id mbs_doc_id
               ,xaecbs.billdocs_paydoc_ind document_type
               ,xaecbs.total_copies total_copies
               ,xaecbs.delivery_method billdocs_delivery_method
               ,xaecbs.billing_term billing_term
               ,xaecbs.extension_id extension_id
               ,xaecbs.direct_flag direct_flag
               ,xaecbs.parent_cust_doc_id
               ,xaecbs.mail_to_attention
               ,arci.cons_billing_number cons_bill_num
               ,arci.site_use_id site_use_id
               ,'PAYDOC' infocopy_tag
               ,arci.currency_code currency
               ,arci.cons_billing_number cons_billing_number
               ,arci.due_date due_date
               ,NULL aops_account_number
               ,NULL bill_to_zip
               ,NULL bill_from_date
               ,NULL bill_to_address1
               ,NULL bill_to_address2
               ,NULL bill_to_address3
               ,NULL bill_to_address4
               ,NULL bill_to_city
               ,NULL bill_to_country
               ,NULL bill_to_name
               ,to_date(arci.attribute1) - 1 bill_to_date
               ,NULL bill_to_state
               ,NULL canadian_tax_number
               ,arci.cons_billing_number consolidated_bill_number
               ,NULL cost_center_sft_hdr
               ,NULL cost_center_desc_hdr--defect 15118
			   ,NULL cost_center_dept -- Added for Defect 36437 (MOD4B Release 3)
               ,NULL po_number_sft_hdr
               ,NULL release_number_sft_hdr
               ,NULL desktop_sft_hdr
               ,NULL customer_name
               ,0 oracle_account_number
               ,NULL us_federal_id
               ,NULL county -- from HL
               ,NULL email_address
               ,NULL cust_acct_site_id
               ,NULL contact_number
               ,NULL account_contact
               ,NULL payment_term
               ,NULL payment_term_description
               ,NULL payment_term_discount
               ,NULL payment_term_frequency
               ,NULL payment_term_report_day
               ,NULL remit_address1
               ,NULL remit_address2
               ,NULL remit_address3
               ,NULL remit_address4
               ,NULL remit_city
               ,NULL remit_state
               ,NULL remit_zip
               ,NULL remit_country
               ,NULL remit_to_description
               ,NULL cust_site_sequence
         FROM   ar_cons_inv              arci
               ,xx_ar_ebl_cons_bills_stg xaecbs
         WHERE  xaecbs.batch_id = p_batch_id
         AND    xaecbs.org_id = p_org_id
         AND    arci.customer_id = xaecbs.cust_account_id
         AND    (arci.attribute2 IS NULL AND arci.attribute4 IS NULL AND arci.attribute10 IS NULL AND arci.attribute15 IS NULL)
         AND    nvl(arci.attribute11
                   ,'X') <> 'IN PROCESS'
         AND    EXISTS (SELECT 1
                 FROM   ar_cons_inv_trx_lines arcl
                 WHERE  arcl.cons_inv_id = arci.cons_inv_id)
         AND    arci.status IN ('FINAL' ,'ACCEPTED')
         AND    xaecbs.billdocs_paydoc_ind = 'Y';

      CURSOR lcu_trx_details(p_cons_inv_id NUMBER) IS
         SELECT rct.invoice_currency_code
               ,rct.trx_date trx_date
               ,rct.bill_to_customer_id bill_to_customer_id
               ,rct.bill_to_site_use_id bill_to_site_use_id
               ,rct.customer_trx_id customer_trx_id
               ,rct.ship_to_site_use_id ship_to_site_use_id
               ,rct.attribute14 rct_header_id
               ,rct.trx_number invoice_number
               ,rct.purchase_order purchase_order
               ,NULL cost_center_sft_data
               ,NULL cost_center_desc_hdr--defect 15118
			   ,NULL cost_center_dept -- Added for Defect 36437 (MOD4B Release 3)
               ,NULL release_number_sft_data
               ,NULL desktop_sft_data
               ,NULL order_date
               ,rct.primary_salesrep_id
               ,aps.discount_date payment_term_discount_date
               ,aps.amount_due_original amount_due_original
               ,aps.amount_due_remaining amount_due_remaining
               ,rbs.NAME transaction_source
               ,rctt.TYPE transaction_class
               ,rctt.NAME transaction_type
               ,NULL order_level_comment
               ,NULL order_level_spc_comment
               ,NULL bill_to_contact_email
               ,NULL bill_to_contact_name
               ,NULL bill_to_contact_phone
               ,NULL bill_to_contact_phone_ext
               ,0 total_pst_qst_tax
               ,NULL carrier
               ,rct.reason_code reason_code
               ,rct.primary_salesrep_id sales_person_id
               ,NULL ship_to_abbreviation
               ,NULL ship_to_address1
               ,NULL ship_to_address2
               ,NULL ship_to_address3
               ,NULL ship_to_address4
               ,NULL ship_to_city
               ,NULL ship_to_country
               ,NULL ship_to_name
               ,NULL ship_to_sequence
               ,NULL ship_to_state
               ,NULL ship_to_zip
               ,rct.ship_via ship_via
               ,rct.waybill_number shipment_ref_number
               ,NULL sku_lines_subtotal
               ,rct.sold_to_customer_id
               ,0 tax_rate
               ,0 total_bulk_amount
               ,0 total_coupon_amount
               ,0 total_discount_amount
               ,0 total_association_discount
               ,0 total_delivery_amount
               ,0 total_freight_amount
               ,0 total_gift_card_amount
               ,0 total_gst_amount
               ,0 total_hst_amount
               ,0 total_miscellaneous_amount
               ,0 total_pst_amount
               ,0 total_qst_amount
               ,0 total_tiered_discount_amount
               ,0 total_us_tax_amount
               ,NULL cust_account_id
               ,NULL ship_cust_site_id
               ,NULL ship_cust_site_sequence
               ,rct.customer_reference_date customer_ref_date
               ,rct.customer_reference customer_ref_number
               ,0 gross_sale_amount
               ,0 invoice_bill_date
               ,0 number_of_lines
               ,NULL ordered_by
               ,NULL order_type_code
               ,NULL original_invoice_amount
               ,NULL original_order_number
               ,NULL reconcile_date
               ,rct.attribute14 order_header_id
               ,NULL order_source_id
               ,NULL order_source_name
               ,rct.batch_source_id
               ,rct.interface_header_attribute2 order_type
               ,NULL order_source_code
         FROM   ra_customer_trx      rct
               ,ar_cons_inv_trx      arct
               ,ar_payment_schedules aps
               ,ra_batch_sources     rbs
               ,ra_cust_trx_types    rctt
         WHERE  arct.cons_inv_id = p_cons_inv_id
         AND    arct.customer_trx_id = rct.customer_trx_id
         AND    aps.customer_trx_id = rct.customer_trx_id
         AND    rbs.batch_source_id = rct.batch_source_id
         AND    rctt.cust_trx_type_id = rct.cust_trx_type_id;
      CURSOR lcu_cons_paydoc_ic(p_batch_id NUMBER, p_org_id NUMBER) IS
         SELECT arci.cons_inv_id cons_inv_id
               ,to_date(arci.attribute1) - 1 print_date
               ,to_date(arci.attribute1) - 1 cut_off_date
               ,arci.customer_id customer_id
               ,xaecbs.cust_doc_id cust_doc_id
               ,arci.term_id
               ,xaecbs.document_id mbs_doc_id
               ,xaecbs.billdocs_paydoc_ind document_type
               ,xaecbs.total_copies total_copies
               ,xaecbs.delivery_method billdocs_delivery_method
               ,xaecbs.billing_term billing_term
               ,xaecbs.extension_id extension_id
               ,xaecbs.direct_flag direct_flag
               ,xaecbs.parent_cust_doc_id
               ,xaecbs.mail_to_attention
               ,arci.cons_billing_number cons_bill_num
               ,arci.site_use_id site_use_id
               ,'PAYDOC_IC' infocopy_tag
               ,arci.currency_code currency
               ,arci.cons_billing_number cons_billing_number
               ,arci.due_date due_date
               ,NULL aops_account_number
               ,to_date(arci.attribute1) - 1 bill_to_date
               ,NULL canadian_tax_number
               ,arci.cons_billing_number consolidated_bill_number
               ,NULL cost_center_sft_hdr
               ,NULL cost_center_desc_hdr--defect 15118
			   ,NULL cost_center_dept -- Added for Defect 36437 (MOD4B Release 3)
               ,NULL po_number_sft_hdr
               ,NULL release_number_sft_hdr
               ,NULL desktop_sft_hdr
               ,0 oracle_account_number
               ,NULL us_federal_id
               ,NULL county -- from HL
               ,NULL email_address

               ,NULL contact_number
               ,NULL account_contact
               ,NULL payment_term
               ,NULL payment_term_description
               ,NULL payment_term_discount
               ,NULL payment_term_frequency
               ,NULL payment_term_report_day
               ,NULL remit_address1
               ,NULL remit_address2
               ,NULL remit_address3
               ,NULL remit_address4
               ,NULL remit_city
               ,NULL remit_state
               ,NULL remit_zip
               ,NULL remit_country
               ,NULL remit_to_description
               ,NULL bill_from_date
         FROM   ar_cons_inv              arci
               ,xx_ar_ebl_cons_bills_stg xaecbs
         WHERE  xaecbs.batch_id = p_batch_id
         AND    xaecbs.org_id = p_org_id
         AND    arci.customer_id = xaecbs.cust_account_id
         AND    NOT EXISTS (SELECT 1
                 FROM   xx_ar_ebl_cons_hdr_hist hist
                 WHERE  1 = 1
                 AND    hist.cons_inv_id = arci.cons_inv_id
                 AND    hist.cust_doc_id = xaecbs.cust_doc_id
                 UNION ALL
                 SELECT 1
                 FROM   xx_ar_ebl_cons_hdr_main hdr
                 WHERE  1 = 1
                 AND    hdr.cons_inv_id = arci.cons_inv_id
                 AND    hdr.cust_doc_id = xaecbs.cust_doc_id)
         AND    EXISTS (SELECT 1
                 FROM   ar_cons_inv_trx_lines arcl
                 WHERE  arcl.cons_inv_id = arci.cons_inv_id)
         AND    xx_ar_infocopy_handling(arci.attribute2 || arci.attribute4 || arci.attribute10 || arci.attribute15
                                       ,xaecbs.billing_term
                                       ,to_date(arci.attribute1) - 1
                                       ,xaecbs.effective_from_date
                                       ,p_as_of_date) = 'Y'
         AND    arci.status IN ('FINAL' ,'ACCEPTED')
         AND    xaecbs.billdocs_paydoc_ind = 'N';

      CURSOR lcu_info_trx_details(p_cons_inv_id NUMBER) IS
         SELECT rct.invoice_currency_code
               ,rct.trx_date trx_date
               ,rct.bill_to_customer_id bill_to_customer_id
               ,rct.bill_to_site_use_id bill_to_site_use_id
               ,rct.customer_trx_id customer_trx_id
               ,rct.ship_to_site_use_id ship_to_site_use_id
               ,rct.attribute14 rct_header_id
               ,rct.trx_number invoice_number
               ,rct.purchase_order purchase_order
               ,NULL customer_name
               ,NULL cost_center_sft_data
               ,NULL cost_center_desc_hdr--defect 15118
			   ,NULL cost_center_dept -- Added for Defect 36437 (MOD4B Release 3)
               ,NULL release_number_sft_data
               ,NULL desktop_sft_data
               ,NULL order_date
               ,NULL bill_to_state
               ,rct.primary_salesrep_id
               ,aps.discount_date payment_term_discount_date
               ,aps.amount_due_original amount_due_original
               ,aps.amount_due_remaining amount_due_remaining
               ,rbs.NAME transaction_source
               ,rctt.TYPE transaction_class
               ,rctt.NAME transaction_type
               ,NULL order_level_comment
               ,NULL order_level_spc_comment
               ,NULL bill_to_contact_email
               ,NULL bill_to_contact_name
               ,NULL bill_to_contact_phone
               ,NULL bill_to_contact_phone_ext
               ,0 total_pst_qst_tax
               ,NULL carrier
               ,rct.reason_code reason_code
               ,rct.primary_salesrep_id sales_person_id
               ,NULL bill_to_zip
               ,NULL bill_to_address1
               ,NULL bill_to_address2
               ,NULL bill_to_address3
               ,NULL bill_to_address4
               ,NULL bill_to_city
               ,NULL bill_to_country
               ,NULL bill_to_name
               ,NULL cust_acct_site_id
               ,NULL cust_site_sequence
               ,NULL ship_to_abbreviation
               ,NULL ship_to_address1
               ,NULL ship_to_address2
               ,NULL ship_to_address3
               ,NULL ship_to_address4
               ,NULL ship_to_city
               ,NULL ship_to_country
               ,NULL ship_to_name
               ,NULL ship_to_sequence
               ,NULL ship_to_state
               ,NULL ship_to_zip
               ,rct.ship_via ship_via
               ,rct.waybill_number shipment_ref_number
               ,NULL sku_lines_subtotal
               ,rct.sold_to_customer_id
               ,0 tax_rate
               ,0 total_bulk_amount
               ,0 total_coupon_amount
               ,0 total_discount_amount
               ,0 total_association_discount
               ,0 total_delivery_amount
               ,0 total_freight_amount
               ,0 total_gift_card_amount
               ,0 total_gst_amount
               ,0 total_hst_amount
               ,0 total_miscellaneous_amount
               ,0 total_pst_amount
               ,0 total_qst_amount
               ,0 total_tiered_discount_amount
               ,0 total_us_tax_amount
               ,NULL cust_account_id
               ,NULL ship_cust_site_id
               ,NULL ship_cust_site_sequence
               ,rct.customer_reference_date customer_ref_date
               ,rct.customer_reference customer_ref_number
               ,0 gross_sale_amount
               ,0 invoice_bill_date
               ,0 number_of_lines
               ,NULL ordered_by
               ,NULL order_type_code
               ,NULL original_invoice_amount
               ,NULL original_order_number
               ,NULL reconcile_date
               ,rct.attribute14 order_header_id
               ,NULL order_source_id
               ,NULL order_source_name
               ,rct.batch_source_id
               ,rct.interface_header_attribute2 order_type
               ,NULL order_source_code
         FROM   ra_customer_trx      rct
               ,ar_cons_inv_trx      arct
               ,ar_payment_schedules aps
               ,ra_batch_sources     rbs
               ,ra_cust_trx_types    rctt
         WHERE  arct.cons_inv_id = p_cons_inv_id
         AND    arct.customer_trx_id = rct.customer_trx_id
         AND    aps.customer_trx_id = rct.customer_trx_id
         AND    rbs.batch_source_id = rct.batch_source_id
         AND    rctt.cust_trx_type_id = rct.cust_trx_type_id;

      CURSOR lcu_cons_header_inv_ic(p_batch_id NUMBER, p_site_attr_group_id NUMBER, p_org_id NUMBER) IS
         SELECT NULL cons_inv_id
               ,g_as_of_date print_date
               ,g_as_of_date cut_off_date
               ,rct.bill_to_customer_id customer_id
               ,xaecbs.cust_doc_id cust_doc_id
               ,xaecbs.document_id mbs_doc_id
               ,xaecbs.billdocs_paydoc_ind document_type
               ,xaecbs.total_copies total_copies
               ,xaecbs.delivery_method billdocs_delivery_method
               ,xaecbs.billing_term billing_term
               ,xaecbs.extension_id extension_id
               ,xaecbs.direct_flag direct_flag
               ,xaecbs.parent_cust_doc_id
               ,xaecbs.mail_to_attention
               ,NULL cons_bill_num
               ,rct.bill_to_site_use_id site_use_id
               ,'INV_IC' infocopy_tag
               ,rct.invoice_currency_code currency
               ,rct.invoice_currency_code
               ,rct.trx_date trx_date
               ,rct.bill_to_customer_id bill_to_customer_id
               ,xx_ar_ebl_common_util_pkg.addr_excp_handling(rct.bill_to_customer_id
                                                            ,xaecbs.cust_doc_id
                                                            ,rct.ship_to_site_use_id
                                                            ,xaecbs.direct_flag
                                                            ,p_site_attr_group_id) bill_to_site_use_id
               ,rct.customer_trx_id customer_trx_id
               ,rct.ship_to_site_use_id ship_to_site_use_id
               ,rct.attribute14 rct_header_id
               ,rct.trx_number invoice_number
               ,rct.purchase_order purchase_order
               ,rct.primary_salesrep_id
               ,NULL cons_billing_number
               ,aps.due_date due_date
               ,aps.discount_date payment_term_discount_date
               ,aps.amount_due_original amount_due_original
               ,aps.amount_due_remaining amount_due_remaining
               ,rbs.NAME transaction_source
               ,rctt.TYPE transaction_class
               ,rctt.NAME transaction_type
               ,NULL cost_center_sft_hdr
               ,NULL cost_center_desc_hdr--defect 15118
			   ,NULL cost_center_dept -- Added for Defect 36437 (MOD4B Release 3)
               ,NULL po_number_sft_hdr
               ,NULL release_number_sft_hdr
               ,NULL desktop_sft_hdr
               ,NULL aops_account_number
               ,NULL bill_to_zip
               ,NULL bill_from_date
               ,NULL bill_to_address1
               ,NULL bill_to_address2
               ,NULL bill_to_address3
               ,NULL bill_to_address4
               ,NULL bill_to_city
               ,NULL bill_to_contact_email
               ,NULL bill_to_contact_name
               ,NULL bill_to_contact_phone
               ,NULL bill_to_contact_phone_ext
               ,NULL bill_to_country
               ,NULL bill_to_date
               ,NULL bill_to_name
               ,NULL bill_to_state
               ,NULL canadian_tax_number
               ,0 total_pst_qst_tax
               ,NULL carrier
               ,NULL consolidated_bill_number
               ,rct.reason_code reason_code
               ,NULL customer_name
               ,rct.customer_reference_date customer_ref_date
               ,rct.customer_reference customer_ref_number
               ,0 gross_sale_amount
               ,NULL invoice_bill_date
               ,NULL number_of_lines
               ,NULL oracle_account_number
               ,NULL order_date
               ,NULL order_level_comment
               ,NULL order_level_spc_comment
               ,rct.interface_header_attribute2 order_type
               ,NULL order_type_code
               ,NULL ordered_by
               ,NULL original_invoice_amount
               ,NULL original_order_number
               ,NULL reconcile_date
               ,NULL remit_address1
               ,NULL remit_address2
               ,NULL remit_address3
               ,NULL remit_address4
               ,NULL remit_city
               ,NULL remit_state
               ,NULL remit_zip
               ,NULL remit_country
               ,NULL remit_to_description
               ,rct.primary_salesrep_id sales_person_id
               ,NULL ship_to_abbreviation
               ,NULL ship_to_address1
               ,NULL ship_to_address2
               ,NULL ship_to_address3
               ,NULL ship_to_address4
               ,NULL ship_to_city
               ,NULL ship_to_country
               ,NULL ship_to_name
               ,NULL ship_to_sequence
               ,NULL ship_to_state
               ,NULL ship_to_zip
               ,rct.ship_via ship_via
               ,rct.waybill_number shipment_ref_number
               ,NULL sku_lines_subtotal
               ,rct.sold_to_customer_id
               ,0 tax_rate
               ,0 total_bulk_amount
               ,0 total_coupon_amount
               ,0 total_discount_amount
               ,0 total_association_discount
               ,0 total_delivery_amount
               ,0 total_freight_amount
               ,0 total_gift_card_amount
               ,0 total_gst_amount
               ,0 total_hst_amount
               ,0 total_miscellaneous_amount
               ,0 total_pst_amount
               ,0 total_qst_amount
               ,0 total_tiered_discount_amount
               ,0 total_us_tax_amount
               ,NULL us_federal_id
               ,NULL county -- from HL
               ,NULL credit_amount -- from xola
               ,NULL cust_account_id
               ,NULL cust_site_sequence
               ,NULL email_address
               ,NULL inventory_item_id
               ,NULL location_id
               ,rct.attribute14 order_header_id
               ,NULL order_source_id
               ,NULL order_source_name
               ,NULL owner_table_id
               ,NULL payment_amount
               ,NULL site_use_code
               ,NULL cust_acct_site_id
               ,NULL ship_cust_site_id
               ,NULL ship_cust_site_sequence
               ,NULL cost_center_sft_data
               ,NULL release_number_sft_data
               ,NULL desktop_sft_data
               ,NULL contact_number
               ,NULL account_contact
               ,NULL payment_term
               ,NULL payment_term_description
               ,NULL payment_term_discount
               ,NULL payment_term_frequency
               ,NULL payment_term_report_day
               ,rct.batch_source_id
               ,NULL order_source_code
         FROM   xx_ar_ebl_cons_bills_stg xaecbs
               ,ra_customer_trx          rct
               ,ar_payment_schedules     aps
               ,ra_batch_sources         rbs
               ,ra_cust_trx_types        rctt
         WHERE  xaecbs.batch_id = p_batch_id
         AND    xaecbs.org_id = p_org_id
         AND    rct.bill_to_customer_id = xaecbs.cust_account_id
         AND    aps.customer_trx_id = rct.customer_trx_id
        -- AND    rct.bill_to_customer_id = aps.customer_id
         AND    rbs.batch_source_id = rct.batch_source_id
         AND    rctt.cust_trx_type_id = rct.cust_trx_type_id
               --AND rt.term_id =rct.term_id
         AND    inv_ic_check(rct.customer_trx_id
                            ,xaecbs.cust_doc_id
                            ,xaecbs.parent_cust_doc_id) = 'Y'
         AND    aps.cons_inv_id IS NULL
         AND    EXISTS (SELECT 1
                 FROM   xx_ar_invoice_freq_history xaif
                 WHERE  1 = 1
                 AND    xaif.invoice_id = rct.customer_trx_id
                 AND    xaif.paydoc_flag = 'Y'
                 AND    xx_ar_inv_freq_pkg.compute_effective_date(xaecbs.billing_term
                                                                 ,xaif.estimated_print_date) >= xaecbs.effective_from_date
                 UNION ALL
                 SELECT 1
                 FROM   xx_ar_ebl_ind_hdr_hist hist
                 WHERE  1 = 1
                 AND    hist.customer_trx_id = rct.customer_trx_id
                 AND    hist.document_type = 'Paydoc'
                 AND    xx_ar_inv_freq_pkg.compute_effective_date(xaecbs.billing_term
                                                                 ,hist.bill_to_date) >= xaecbs.effective_from_date)
         AND    xaecbs.billdocs_paydoc_ind = 'N'
         ORDER  BY customer_id
                  ,cust_doc_id
                  ,bill_to_site_use_id;
      TYPE cbi_paydoc_tab IS TABLE OF lcu_trx_details%ROWTYPE INDEX BY BINARY_INTEGER;
      paydoc_tab cbi_paydoc_tab;
      TYPE cons_paydoc_tab IS TABLE OF lcu_cons_paydocs%ROWTYPE INDEX BY BINARY_INTEGER;
      cons_paydoc cons_paydoc_tab;

      TYPE cons_paydoc_ic_tab IS TABLE OF lcu_cons_paydoc_ic%ROWTYPE;
      cons_paydoc_ic cons_paydoc_ic_tab;

      --  TYPE trx_details_tab IS TABLE OF lcu_trx_details%ROWTYPE
      --  INDEX BY BINARY_INTEGER;
      --  trx_details trx_details_tab;

      TYPE cbi_paydoc_ic_tab IS TABLE OF lcu_info_trx_details%ROWTYPE INDEX BY BINARY_INTEGER;
      paydoc_ic_tab cbi_paydoc_ic_tab;
      TYPE cbi_inv_ic_tab IS TABLE OF lcu_cons_header_inv_ic%ROWTYPE INDEX BY BINARY_INTEGER;
      inv_ic_tab              cbi_inv_ic_tab;
      lc_country              ar_system_parameters.default_country%TYPE := NULL;
      ln_us_tax_rate          NUMBER := 0;
      ln_pst_qst_tax_rate     NUMBER := 0;
      ln_hdr_tax_rate      NUMBER := 0;
      ln_gst_tax_rate         NUMBER := 0;
      ln_site_attr_id         NUMBER := 0;
      lc_location             VARCHAR2(2000) := NULL;
      lc_ship_to_name         VARCHAR2(2000) := NULL;
      lc_ship_to_sequence     VARCHAR2(2000) := NULL;
      lc_error_loc            VARCHAR2(2000) := NULL;
      lc_error_debug          VARCHAR2(2000) := NULL;
      lc_pay_term_description ra_terms.description%TYPE := NULL;
      lc_province             hz_locations.province%TYPE := NULL;
      ln_prev_document_id     NUMBER := 0;
      ln_prev_site_use_id     NUMBER := 0;
      lc_dummy                VARCHAR2(2000) := NULL;
      ln_prev_cons_bill_id    NUMBER := 0;
      lc_orgordnbr            xx_om_line_attributes_all.ret_orig_order_num%TYPE;
      lc_reason_code          ar_lookups.meaning%TYPE;
      lc_sales_person         VARCHAR2(1000) := NULL;
      lc_sold_to_customer     hz_cust_accounts_all.account_number%TYPE := NULL;
	  lc_bill_comp_flag		  VARCHAR2(1) := NULL;										-- Added By Dinesh For Separate Bill Test for Bill Complete and Non-BillComplete
      ln_attr_group_id        ego_attr_groups_v.attr_group_id%TYPE;
      p_debug                 BOOLEAN;
      lc_epdf_doc_detail      VARCHAR2(50) := NULL;
      ln_org_id               NUMBER := fnd_profile.VALUE('ORG_ID');
      ln_attr_id              NUMBER := 0;
      lc_mail_to_attention    VARCHAR2(1000) := NULL;
      ln_request_id           NUMBER := fnd_global.conc_request_id;
      ln_organization_id      NUMBER := 0;
      lc_tax_number           VARCHAR2(100) := NULL;
      gc_debug_msg            VARCHAR2(2000) := NULL;
      lc_ph_no_bill           VARCHAR2(20) := NULL;
      lc_ph_no_cusrv          VARCHAR2(20) := NULL;
      ln_spc_order_source_id  NUMBER := 0;
      lc_cont_ph_no_cusrv     ar_system_parameters_all.attribute3%TYPE := NULL;
      lc_cont_ph_no_bill      ar_system_parameters_all.attribute4%TYPE := NULL;
      lc_dir_ph_no_cusrv      ar_system_parameters_all.attribute5%TYPE := NULL;
      lc_dir_ph_no_bill       ar_system_parameters_all.attribute6%TYPE := NULL;
      lc_sales_channel        hz_cust_accounts.attribute18%TYPE;
      ln_sfthdr_group_id      NUMBER;
      lc_error_log            VARCHAR2(2000);
      ln_item_master_org      org_organization_definitions.organization_id%TYPE;
      lc_process              VARCHAR2(1) := NULL;
      ln_trx_count            NUMBER:=0;
   BEGIN
      -- Opening the Main header Query for paydocs
      -- calculating billdocs attr group id
      gc_debug_msg := 'In EXTRACT_DATA Procedure';
      xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                            ,FALSE
                                            ,gc_debug_msg);
      IF (p_debug_flag = 'Y') THEN
         p_debug := TRUE;
      ELSE
         p_debug := FALSE;
      END IF;
      lc_error_loc   := 'Fetching billdocs attribute group id';
      lc_error_debug := NULL;
      BEGIN
         SELECT attr_group_id
         INTO   ln_attr_group_id
         FROM   ego_attr_groups_v
         WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
         AND    attr_group_name = 'BILLDOCS';

         SELECT attr_group_id
         INTO   ln_site_attr_id
         FROM   ego_attr_groups_v
         WHERE  attr_group_type = 'XX_CDH_CUST_ACCT_SITE'
         AND    attr_group_name = 'BILLDOCS';

         SELECT attr_group_id
         INTO   ln_sfthdr_group_id
         FROM   ego_attr_groups_v
         WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
         AND    attr_group_name = 'REPORTING_SOFTH';
      EXCEPTION
         WHEN no_data_found THEN
            ln_attr_group_id   := 0;
            ln_site_attr_id    := 0;
            ln_sfthdr_group_id := 0;
            RAISE;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,TRUE
                                                  ,'No data found while getting the attr group id from ego_attr_groups_v');
         WHEN OTHERS THEN
            RAISE;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,TRUE
                                                  ,'When Others while getting the attr group id from ego_attr_groups_v');
      END;
      -- Setting the as_of_date global variable
      g_as_of_date := to_date(p_as_of_date);
      -- ================================
      -- Get Item Master Organization ID
      -- ================================
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
      gc_debug_msg := to_char(SYSDATE
                             ,'DD-MON-YYYY HH24:MI:SS') || ' Getting tax details:';
      xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                            ,FALSE
                                            ,gc_debug_msg);

      gc_debug_msg := to_char(SYSDATE
                             ,'DD-MON-YYYY HH24:MI:SS') || ' As of Date: ' || p_as_of_date;
      xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                            ,FALSE
                                            ,gc_debug_msg);
      -- Getting Tax ID and Tax description
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
      BEGIN
         SELECT oos.order_source_id
         INTO   ln_spc_order_source_id
         FROM   oe_order_sources oos
         WHERE  oos.NAME = 'SPC';
      EXCEPTION
         WHEN OTHERS THEN
            ln_spc_order_source_id := 0;
      END;

      lc_error_loc   := 'Inside lcu_cons_header cursor';
      lc_error_debug := NULL;
      gc_debug_msg   := to_char(SYSDATE
                               ,'DD-MON-YYYY HH24:MI:SS') || ' paydoc_tab.count =' || paydoc_tab.COUNT;
      xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                            ,FALSE
                                            ,gc_debug_msg);

      OPEN lcu_cons_paydocs(p_batch_id
                           ,ln_org_id);
      FETCH lcu_cons_paydocs BULK COLLECT
         INTO cons_paydoc;
      FOR cons_rec IN 1 .. cons_paydoc.COUNT
      LOOP
         BEGIN
            SAVEPOINT paydoc_insert;
            lc_location        := NULL;
            lc_province        := NULL;
            lc_epdf_doc_detail := NULL;
            lc_sales_channel   := NULL;

            SELECT doc_detail_level
            INTO   lc_epdf_doc_detail
            FROM   xx_cdh_mbs_document_master
            WHERE  document_id = cons_paydoc(cons_rec).mbs_doc_id;

            gc_debug_msg := to_char(SYSDATE
                                   ,'DD-MON-YYYY HH24:MI:SS') || 'deriving XX_AR_EBL_COMMON_UTIL_PKG.GET_AMOUNT - PAYDOC - CONS ID:' || cons_paydoc(cons_rec).cons_inv_id || 'site use ID : ' || cons_paydoc(cons_rec).site_use_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'    ' || gc_debug_msg);

            xx_ar_ebl_common_util_pkg.get_address(cons_paydoc(cons_rec).site_use_id
                                                 ,cons_paydoc(cons_rec).bill_to_address1
                                                 ,cons_paydoc(cons_rec).bill_to_address2
                                                 ,cons_paydoc(cons_rec).bill_to_address3
                                                 ,cons_paydoc(cons_rec).bill_to_address4
                                                 ,cons_paydoc(cons_rec).bill_to_city
                                                 ,cons_paydoc(cons_rec).bill_to_country
                                                 ,cons_paydoc(cons_rec).bill_to_state
                                                 ,cons_paydoc(cons_rec).bill_to_zip
                                                 ,lc_location
                                                 ,cons_paydoc(cons_rec).bill_to_name
                                                 ,lc_dummy
                                                 ,lc_province
                                                 ,cons_paydoc(cons_rec).cust_acct_site_id
                                                 ,cons_paydoc(cons_rec).cust_site_sequence
                                                 ,cons_paydoc(cons_rec).customer_name);
            -- GET Remit to address
            gc_debug_msg := to_char(SYSDATE
                                   ,'DD-MON-YYYY HH24:MI:SS') || ' deriving GET Remit to Address - PAYDOC - CONS ID:' || cons_paydoc(cons_rec).cons_inv_id || 'TRX ID : ' || cons_paydoc(cons_rec).site_use_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'    ' || gc_debug_msg);
            xx_ar_ebl_common_util_pkg.get_remit_address(xx_ar_ebl_common_util_pkg.get_remit_addressid(cons_paydoc(cons_rec).site_use_id
                                                                                                     ,p_debug_flag)
                                                       ,cons_paydoc(cons_rec).remit_address1
                                                       ,cons_paydoc(cons_rec).remit_address2
                                                       ,cons_paydoc(cons_rec).remit_address3
                                                       ,cons_paydoc(cons_rec).remit_address4
                                                       ,cons_paydoc(cons_rec).remit_city
                                                       ,cons_paydoc(cons_rec).remit_state
                                                       ,cons_paydoc(cons_rec).remit_zip
                                                       ,cons_paydoc(cons_rec).remit_to_description
                                                       ,cons_paydoc(cons_rec).remit_country);
            -- Getting Term Description
            gc_debug_msg := to_char(SYSDATE
                                   ,'DD-MON-YYYY HH24:MI:SS') || 'get payment term Details - PAYDOC - CONS ID:' || cons_paydoc(cons_rec).cons_inv_id || 'billing term : ' || cons_paydoc(cons_rec).billing_term;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'    ' || gc_debug_msg);

            xx_ar_ebl_common_util_pkg.get_term_details(cons_paydoc(cons_rec).billing_term
                                                      ,cons_paydoc(cons_rec).payment_term
                                                      ,cons_paydoc(cons_rec).payment_term_description
                                                      ,cons_paydoc(cons_rec).payment_term_discount
                                                      ,cons_paydoc(cons_rec).payment_term_frequency
                                                      ,cons_paydoc(cons_rec).payment_term_report_day);
            --GET soft header detail
            gc_debug_msg := to_char(SYSDATE
                                   ,'DD-MON-YYYY HH24:MI:SS') || ' getting soft header details: ' || ' TRX ID :' || cons_paydoc(cons_rec).customer_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'    ' || gc_debug_msg);
            xx_ar_ebl_common_util_pkg.get_soft_header(cons_paydoc(cons_rec).customer_id
                                                     ,ln_sfthdr_group_id
                                                     ,cons_paydoc(cons_rec).cost_center_sft_hdr
                                                     ,cons_paydoc(cons_rec).desktop_sft_hdr
                                                     ,cons_paydoc(cons_rec).release_number_sft_hdr
                                                     ,cons_paydoc(cons_rec).po_number_sft_hdr);
            -- Getting customer Details
            gc_debug_msg := to_char(SYSDATE
                                   ,'DD-MON-YYYY HH24:MI:SS') || ' Get Account Number - PAYDOC - CONS ID:' || cons_paydoc(cons_rec).cons_inv_id || 'Account Number : ' || cons_paydoc(cons_rec).aops_account_number;

            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'    ' || gc_debug_msg);
            SELECT substr(orig_system_reference
                         ,1
                         ,8)
                  ,account_number
                  ,attribute18
            INTO   cons_paydoc(cons_rec) .aops_account_number
                  ,cons_paydoc(cons_rec) .oracle_account_number
                  ,lc_sales_channel
            FROM   hz_cust_accounts
            WHERE  cust_account_id = cons_paydoc(cons_rec).customer_id;
            -- Get Bill From Date
            gc_debug_msg := to_char(SYSDATE
                                   ,'DD-MON-YYYY HH24:MI:SS') || 'deriving XX_AR_EBL_COMMON_UTIL_PKG.BILL_FROM_DATE - PAYDOC - CONS ID:' || cons_paydoc(cons_rec).cons_inv_id;

            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'    ' || gc_debug_msg);

            BEGIN
               SELECT xx_ar_ebl_common_util_pkg.bill_from_date(cons_paydoc(cons_rec).billing_term
                                                              ,cons_paydoc(cons_rec).cut_off_date)
               INTO   cons_paydoc(cons_rec) .bill_from_date
               FROM   dual;

            EXCEPTION
               WHEN OTHERS THEN
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,TRUE
                                                        ,to_char(SYSDATE
                                                                ,'DD-MON-YYYY HH24:MI:SS') || 'Getting bill from date error :' || SQLERRM);
            END;
            IF (lcu_trx_details%ISOPEN) THEN
               CLOSE lcu_trx_details;
            END IF;
            OPEN lcu_trx_details(cons_paydoc(cons_rec).cons_inv_id);
            FETCH lcu_trx_details BULK COLLECT
               INTO paydoc_tab;
            FOR pay_rec IN 1 .. paydoc_tab.COUNT
            LOOP
               BEGIN

                  ln_us_tax_rate      := 0;
                  ln_gst_tax_rate     := 0;
                  ln_hdr_tax_rate     := 0;
                  ln_pst_qst_tax_rate := 0;
                  lc_ph_no_cusrv      := NULL;
                  lc_ph_no_bill       := NULL;
                  lc_orgordnbr        := NULL;
                  lc_reason_code      := NULL;
                  lc_sales_person     := NULL;
                  lc_sold_to_customer := NULL;
				  lc_bill_comp_flag	  := NULL;			-- Added By Dinesh For Separate Bill Test for Bill Complete and Non-BillComplete

                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'deriving XX_AR_EBL_COMMON_UTIL_PKG.GET_AMOUNT - PAYDOC - CONS ID:' || cons_paydoc(cons_rec).cons_inv_id || 'TRX ID : ' || paydoc_tab(pay_rec).customer_trx_id;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'   ' || '    ' || gc_debug_msg);
                  xx_ar_ebl_common_util_pkg.get_amount(paydoc_tab(pay_rec).transaction_source
                                                      ,paydoc_tab(pay_rec).customer_trx_id
                                                      ,paydoc_tab(pay_rec).transaction_class
                                                      ,paydoc_tab(pay_rec).rct_header_id
                                                      ,paydoc_tab(pay_rec).amount_due_original
                                                      ,paydoc_tab(pay_rec).sku_lines_subtotal
                                                      ,paydoc_tab(pay_rec).total_delivery_amount
                                                      ,paydoc_tab(pay_rec).total_miscellaneous_amount
                                                      ,paydoc_tab(pay_rec).total_association_discount
                                                      ,paydoc_tab(pay_rec).total_bulk_amount
                                                      ,paydoc_tab(pay_rec).total_coupon_amount
                                                      ,paydoc_tab(pay_rec).total_tiered_discount_amount
                                                      ,paydoc_tab(pay_rec).total_gift_card_amount
                                                      ,paydoc_tab(pay_rec).number_of_lines);

                  -- Deriving the various tax amounts
                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'deriving XX_AR_EBL_COMMON_UTIL_PKG.GET_TAX_AMOUNT - PAYDOC - CONS ID:' || cons_paydoc(cons_rec).cons_inv_id || 'TRX ID : ' || paydoc_tab(pay_rec).customer_trx_id;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'    ' || '    ' || gc_debug_msg);

                  xx_ar_ebl_common_util_pkg.get_tax_amount(paydoc_tab(pay_rec).customer_trx_id
                                                          ,lc_country
                                                          ,lc_province
                                                          ,paydoc_tab(pay_rec).total_us_tax_amount
                                                          ,ln_us_tax_rate
                                                          ,paydoc_tab(pay_rec).total_gst_amount
                                                          ,ln_gst_tax_rate
                                                          ,paydoc_tab(pay_rec).total_pst_qst_tax
                                                          ,ln_pst_qst_tax_rate);
                  IF lc_country = 'CA' THEN
                     IF lc_province IN ('QC', 'PQ') THEN
                        paydoc_tab(pay_rec).total_qst_amount := paydoc_tab(pay_rec).total_pst_qst_tax;
                     ELSE
                        paydoc_tab(pay_rec).total_pst_amount := paydoc_tab(pay_rec).total_pst_qst_tax;
                     END IF;
                  END IF;

                  --GET SHIP_TO address
                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || ' GET ship to address - PAYDOC - CONS ID:' || cons_paydoc(cons_rec).cons_inv_id || 'TRX ID : ' || paydoc_tab(pay_rec).customer_trx_id;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'   ' || '    ' || gc_debug_msg);
                  xx_ar_ebl_common_util_pkg.get_address(paydoc_tab(pay_rec).ship_to_site_use_id
                                                       ,lc_dummy
                                                       ,lc_dummy
                                                       ,paydoc_tab(pay_rec).ship_to_address3
                                                       ,paydoc_tab(pay_rec).ship_to_address4
                                                       ,lc_dummy
                                                       ,lc_dummy
                                                       ,lc_dummy
                                                       ,lc_dummy
                                                       ,paydoc_tab(pay_rec).ship_to_abbreviation
                                                       ,paydoc_tab(pay_rec).ship_to_name
                                                       ,paydoc_tab(pay_rec).ship_to_sequence
                                                       ,lc_dummy
                                                       ,paydoc_tab(pay_rec).ship_cust_site_id
                                                       ,paydoc_tab(pay_rec).ship_cust_site_sequence
                                                       ,lc_dummy);
                  -- GET Order header attributes
                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || ' Order header attributes - PAYDOC - CONS ID:' || cons_paydoc(cons_rec).cons_inv_id || 'TRX ID : ' || paydoc_tab(pay_rec).customer_trx_id;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'   ' || '    ' || gc_debug_msg);
                  xx_ar_ebl_common_util_pkg.get_hdr_attr_details(paydoc_tab(pay_rec).order_header_id
                                                                ,ln_spc_order_source_id
                                                                ,paydoc_tab(pay_rec).bill_to_contact_email
                                                                ,paydoc_tab(pay_rec).bill_to_contact_name
                                                                ,paydoc_tab(pay_rec).bill_to_contact_phone
                                                                ,paydoc_tab(pay_rec).bill_to_contact_phone_ext
                                                                ,paydoc_tab(pay_rec).order_level_comment
                                                                ,paydoc_tab(pay_rec).order_type_code
                                                                ,paydoc_tab(pay_rec).order_source_code
                                                                ,paydoc_tab(pay_rec).ordered_by
                                                                ,paydoc_tab(pay_rec).order_date
                                                                ,paydoc_tab(pay_rec).order_level_spc_comment
                                                                ,paydoc_tab(pay_rec).cost_center_sft_data
                                                                ,paydoc_tab(pay_rec).release_number_sft_data
                                                                ,paydoc_tab(pay_rec).desktop_sft_data
                                                                ,paydoc_tab(pay_rec).ship_to_address1
                                                                ,paydoc_tab(pay_rec).ship_to_address2
                                                                ,paydoc_tab(pay_rec).ship_to_city
                                                                ,paydoc_tab(pay_rec).ship_to_state
                                                                ,paydoc_tab(pay_rec).ship_to_country
                                                                ,paydoc_tab(pay_rec).ship_to_zip
                                                                ,ln_hdr_tax_rate
                                                                );

                  IF upper(lc_sales_channel) = 'CONTRACT' THEN
                     lc_ph_no_cusrv := lc_cont_ph_no_cusrv;
                     lc_ph_no_bill  := lc_cont_ph_no_bill;
                  ELSE
                     lc_ph_no_cusrv := lc_dir_ph_no_cusrv;
                     lc_ph_no_bill  := lc_dir_ph_no_bill;
                  END IF;
--defect 15118
                  BEGIN

                SELECT CUST_DEPT_DESCRIPTION,
                       COST_CENTER_DEPT, --Added for Defect 36437 (MOD4B Release 3)
					   DECODE(BILL_COMP_FLAG,'B','Y','Y','Y',NULL)
                INTO  paydoc_tab(pay_rec).cost_center_desc_hdr,
				      paydoc_tab(pay_rec).cost_center_dept, --Added for Defect 36437 (MOD4B Release 3)
					  lc_bill_comp_flag							-- Added By Dinesh For Separate Bill Test for Bill Complete and Non-BillComplete
                FROM XX_OM_HEADER_ATTRIBUTES_ALL XOHA,
                     RA_CUSTOMER_TRX_ALL RCT
                WHERE RCT.CUSTOMER_TRX_ID =paydoc_tab(pay_rec).customer_trx_id
                AND RCT.ATTRIBUTE14= XOHA.HEADER_ID
               AND    rownum < 2;
            EXCEPTION
               WHEN no_data_found THEN
                  paydoc_tab(pay_rec).cost_center_desc_hdr := NULL;
				  paydoc_tab(pay_rec).cost_center_dept := NULL; --Added for Defect 36437 (MOD4B Release 3)
                  END;
                  --defect 15118
                  --GET soft header detail
                  --Deriving original order number for credit memos

                  oe_profile.get('SO_ORGANIZATION_ID'
                                ,ln_organization_id);

                  BEGIN
                     SELECT description
                     INTO   paydoc_tab(pay_rec) .carrier
                     FROM   org_freight orf
                     WHERE  orf.freight_code = paydoc_tab(pay_rec).ship_via
                     AND    orf.organization_id = ln_organization_id
                     AND    rownum < 2;
                  EXCEPTION
                     WHEN no_data_found THEN
                        paydoc_tab(pay_rec).carrier := NULL;
                  END;
                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'XX_AR_EBL_COMMON_UTIL_PKG.get_misc_values - PAYDOC - CONS ID:' || cons_paydoc(cons_rec).cons_inv_id || 'TRX ID : ' || paydoc_tab(pay_rec).customer_trx_id;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'   ' || '    ' || gc_debug_msg);
                  xx_ar_ebl_common_util_pkg.get_misc_values(paydoc_tab(pay_rec).order_header_id
                                                           ,paydoc_tab(pay_rec).reason_code
                                                           ,paydoc_tab(pay_rec).sold_to_customer_id
                                                           ,paydoc_tab(pay_rec).transaction_class
                                                           ,lc_orgordnbr
                                                           ,lc_reason_code
                                                           ,lc_sold_to_customer
                                                           ,paydoc_tab(pay_rec).reconcile_date);
                  BEGIN
                     gc_debug_msg := to_char(SYSDATE
                                            ,'DD-MON-YYYY HH24:MI:SS') || 'Get Sales Person - PAYDOC - CONS ID:' || cons_paydoc(cons_rec).cons_inv_id || 'TRX ID : ' || paydoc_tab(pay_rec).customer_trx_id;
                     xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                           ,FALSE
                                                           ,'   ' || '    ' || gc_debug_msg);
                     /* Begin Modification  for ver 1.4 Defect Id: 45279 Updating sales person to null
                     lc_sales_person := arpt_sql_func_util.get_salesrep_name_number(paydoc_tab(pay_rec).sales_person_id
                                                                                   ,'NAME'
                                                                                   , gn_org_id); -- defect 26440*/
                     lc_sales_person := NULL;
	                 /* End Modification  for ver 1.4 Defect Id: 45279 Updating sales person to null */

                  EXCEPTION
                     WHEN no_data_found THEN
                        lc_sales_person := NULL;
                  END;

                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'Insert Header - PAYDOC - CONS ID:' || cons_paydoc(cons_rec).cons_inv_id || 'TRX ID : ' || paydoc_tab(pay_rec).customer_trx_id;

                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'   ' || '    ' || gc_debug_msg);
                  INSERT INTO xx_ar_ebl_cons_hdr_main
                     (cons_inv_id
                     ,customer_trx_id
                     ,mbs_doc_id
                     ,consolidated_bill_number
                     ,billdocs_delivery_method
                     ,document_type
                     ,direct_flag
                     ,cust_doc_id
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
                     ,dept_desc
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
                     ,infocopy_tag
                     ,batch_source_id
					 ,c_ext_attr1)
                  VALUES
                     (cons_paydoc(cons_rec).cons_inv_id
                     ,paydoc_tab(pay_rec).customer_trx_id
                     ,cons_paydoc(cons_rec).mbs_doc_id
                     ,cons_paydoc(cons_rec).cons_bill_num
                     ,cons_paydoc(cons_rec).billdocs_delivery_method
                     ,decode(cons_paydoc(cons_rec).document_type
                            ,'Y'
                            ,'Paydoc'
                            ,'N'
                            ,'Infocopy')
                     ,decode(cons_paydoc(cons_rec).direct_flag
                            ,'Y'
                            ,'D'
                            ,'N'
                            ,'I')
                     ,cons_paydoc(cons_rec).cust_doc_id
                     ,to_date(cons_paydoc(cons_rec).bill_from_date) + 1
                     ,cons_paydoc(cons_rec).cut_off_date
                     ,nvl(decode(cons_paydoc(cons_rec).mail_to_attention
                                ,NULL
                                ,NULL
                                ,'ATTN: ' || cons_paydoc(cons_rec).mail_to_attention)
                         ,'ATTN: ACCTS PAYABLE')
                     ,paydoc_tab(pay_rec).invoice_number
                     ,lc_orgordnbr
                     ,paydoc_tab(pay_rec).amount_due_original
                     ,paydoc_tab(pay_rec).amount_due_remaining
                     ,paydoc_tab(pay_rec).amount_due_original - (paydoc_tab(pay_rec).total_us_tax_amount + paydoc_tab(pay_rec).total_gst_amount + paydoc_tab(pay_rec).total_pst_qst_tax)
                     ,DECODE((paydoc_tab(pay_rec).total_gst_amount + paydoc_tab(pay_rec).total_pst_qst_tax + paydoc_tab(pay_rec).total_us_tax_amount),0,0,ln_hdr_tax_rate)
                     ,lc_reason_code
                     ,cons_paydoc(cons_rec).bill_to_date
                     ,DECODE(cons_paydoc(cons_rec).billdocs_delivery_method
                            ,'eXLS',decode(paydoc_tab(pay_rec).transaction_class,'CM',NULL,cons_paydoc(cons_rec).due_date)
                            ,cons_paydoc(cons_rec).due_date)
                     ,cons_paydoc(cons_rec).currency
                     ,paydoc_tab(pay_rec).order_date
                     ,paydoc_tab(pay_rec).reconcile_date
                     ,paydoc_tab(pay_rec).rct_header_id
                     ,paydoc_tab(pay_rec).order_level_comment
                     ,paydoc_tab(pay_rec).order_level_spc_comment
                     ,paydoc_tab(pay_rec).order_type
                     ,paydoc_tab(pay_rec).order_type_code
                     ,paydoc_tab(pay_rec).order_source_code
                     ,paydoc_tab(pay_rec).ordered_by
                     ,cons_paydoc(cons_rec).payment_term
                     ,cons_paydoc(cons_rec).payment_term_description
                     ,cons_paydoc(cons_rec).payment_term_discount
                     ,xx_ar_ebl_common_util_pkg.get_discount_date(paydoc_tab(pay_rec).customer_trx_id)
                     ,cons_paydoc(cons_rec).payment_term_frequency
                     ,cons_paydoc(cons_rec).payment_term_report_day
                     ,cons_paydoc(cons_rec).billing_term
                     ,paydoc_tab(pay_rec).total_bulk_amount
                     ,paydoc_tab(pay_rec).total_coupon_amount
                     ,paydoc_tab(pay_rec).total_bulk_amount + paydoc_tab(pay_rec).total_tiered_discount_amount +paydoc_tab(pay_rec).total_association_discount
                     ,paydoc_tab(pay_rec).total_delivery_amount
                     ,paydoc_tab(pay_rec).total_gift_card_amount
                     ,paydoc_tab(pay_rec).total_gst_amount
                     ,paydoc_tab(pay_rec).total_gst_amount + paydoc_tab(pay_rec).total_pst_qst_tax
                     ,paydoc_tab(pay_rec).total_miscellaneous_amount
                     ,paydoc_tab(pay_rec).total_association_discount
                     ,paydoc_tab(pay_rec).total_pst_amount
                     ,paydoc_tab(pay_rec).total_qst_amount
                     ,paydoc_tab(pay_rec).total_tiered_discount_amount
                     ,paydoc_tab(pay_rec).total_us_tax_amount
                     ,paydoc_tab(pay_rec).sku_lines_subtotal
                     ,lc_sales_person
                     ,cons_paydoc(cons_rec).customer_id
                     ,cons_paydoc(cons_rec).oracle_account_number
                     ,cons_paydoc(cons_rec).customer_name
                     ,cons_paydoc(cons_rec).aops_account_number
                     ,cons_paydoc(cons_rec).cust_acct_site_id
                     ,cons_paydoc(cons_rec).cust_site_sequence
                     ,paydoc_tab(pay_rec).customer_ref_date --to fetch
                     ,paydoc_tab(pay_rec).customer_ref_number
                     ,lc_sold_to_customer
                     ,paydoc_tab(pay_rec).transaction_source
                     ,paydoc_tab(pay_rec).transaction_type
                     ,decode(paydoc_tab(pay_rec).transaction_class
                            ,'CM'
                            ,'Credit Memo'
                            ,'DM'
                            ,'Debit Memo'
                            ,'INV'
                            ,'Invoice')
                     ,paydoc_tab(pay_rec).trx_date
                     ,cons_paydoc(cons_rec).bill_to_name
                     ,cons_paydoc(cons_rec).bill_to_address1
                     ,cons_paydoc(cons_rec).bill_to_address2
                     ,cons_paydoc(cons_rec).bill_to_address3
                     ,cons_paydoc(cons_rec).bill_to_address4
                     ,cons_paydoc(cons_rec).bill_to_city
                     ,decode(cons_paydoc(cons_rec).bill_to_country
                            ,'US'
                            ,cons_paydoc(cons_rec).bill_to_state
                            ,lc_province)
                     ,cons_paydoc(cons_rec).bill_to_country
                     ,cons_paydoc(cons_rec).bill_to_zip
                     ,paydoc_tab(pay_rec).bill_to_contact_name
                     ,paydoc_tab(pay_rec).bill_to_contact_phone
                     ,paydoc_tab(pay_rec).bill_to_contact_phone_ext
                     ,paydoc_tab(pay_rec).bill_to_contact_email
                     ,lc_location
                     ,paydoc_tab(pay_rec).carrier
                     ,paydoc_tab(pay_rec).ship_to_name
                     ,paydoc_tab(pay_rec).ship_to_abbreviation
                     ,paydoc_tab(pay_rec).ship_to_address1
                     ,paydoc_tab(pay_rec).ship_to_address2
                     ,paydoc_tab(pay_rec).ship_to_address3
                     ,paydoc_tab(pay_rec).ship_to_address4
                     ,paydoc_tab(pay_rec).ship_to_city
                     ,paydoc_tab(pay_rec).ship_to_state
                     ,paydoc_tab(pay_rec).ship_to_country
                     ,paydoc_tab(pay_rec).ship_to_zip
                     ,paydoc_tab(pay_rec).ship_to_sequence
                     ,paydoc_tab(pay_rec).shipment_ref_number
                     ,cons_paydoc(cons_rec).remit_address1
                     ,cons_paydoc(cons_rec).remit_address2
                     ,cons_paydoc(cons_rec).remit_address3
                     ,cons_paydoc(cons_rec).remit_address4
                     ,cons_paydoc(cons_rec).remit_city
                     ,cons_paydoc(cons_rec).remit_state
                     ,cons_paydoc(cons_rec).remit_zip
                     ,cons_paydoc(cons_rec).remit_country
                     ,decode(lc_country
                            ,'US'
                            ,lc_tax_number
                            ,NULL)
                     ,decode(lc_country
                            ,'CA'
                            ,lc_tax_number
                            ,NULL)
                     ,upper(nvl(cons_paydoc(cons_rec).cost_center_sft_hdr
                               ,'COST CENTER'))
                    -- ,upper(nvl(cons_paydoc(cons_rec).cost_center_desc_hdr
                    --          ,'COST CENTER DESCRIPTION'))--defect 15118
                    ,paydoc_tab(pay_rec).cost_center_desc_hdr--defect 22582
					,paydoc_tab(pay_rec).cost_center_dept -- Added for Defect 36437 (MOD4B Release 3)
                    ,upper(nvl(cons_paydoc(cons_rec).po_number_sft_hdr
                               ,'PURCHASE ORDER'))
                     ,upper(nvl(cons_paydoc(cons_rec).release_number_sft_hdr
                               ,'RELEASE'))
                     ,upper(nvl(cons_paydoc(cons_rec).desktop_sft_hdr
                               ,'DESKTOP'))
                     ,paydoc_tab(pay_rec).number_of_lines
                     ,fnd_global.user_id
                     ,SYSDATE
                     ,fnd_global.user_id
                     ,SYSDATE
                     ,fnd_global.login_id
                     ,p_batch_id
                     ,gn_org_id
                     ,paydoc_tab(pay_rec).bill_to_site_use_id
                     ,cons_paydoc(cons_rec).parent_cust_doc_id
                     ,lc_epdf_doc_detail
                     ,ln_request_id
                     ,paydoc_tab(pay_rec).invoice_number
                     ,paydoc_tab(pay_rec).desktop_sft_data
                     ,paydoc_tab(pay_rec).purchase_order
                     ,paydoc_tab(pay_rec).cost_center_sft_data
                     ,paydoc_tab(pay_rec).release_number_sft_data
                     ,lc_ph_no_cusrv
                     ,lc_ph_no_bill
                     ,cons_paydoc(cons_rec).infocopy_tag
                     ,paydoc_tab(pay_rec).batch_source_id
					 ,lc_bill_comp_flag);					-- Added By Dinesh For Separate Bill Test for Bill Complete and Non-BillComplete
                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'Insert Lines - PAYDOC - CONS ID:' || cons_paydoc(cons_rec).cons_inv_id || 'TRX ID : ' || paydoc_tab(pay_rec).customer_trx_id;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'   ' || '    ' || gc_debug_msg);
                  ln_trx_count := ln_trx_count+1;
                  -- Calling Insert_lines
                  insert_lines(paydoc_tab(pay_rec).customer_trx_id
                              ,paydoc_tab(pay_rec).transaction_class
                              ,cons_paydoc(cons_rec).cons_inv_id
                              ,cons_paydoc(cons_rec).cust_doc_id
                              ,cons_paydoc(cons_rec).parent_cust_doc_id
                              ,cons_paydoc(cons_rec).cost_center_sft_hdr
                              ,p_batch_id
                              ,ln_item_master_org
                              ,paydoc_tab(pay_rec).order_source_code);
               EXCEPTION
                  WHEN OTHERS THEN
                     lc_error_log := 'Error at : ' || gc_debug_msg || ' ' || SQLERRM;
                     xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                           ,TRUE
                                                           ,'Error at : ' || gc_debug_msg);
                     gc_debug_msg := 'Exception for Parent_cust_doc_id :' || cons_paydoc(cons_rec).parent_cust_doc_id || ' Customer_trx_id = ' || paydoc_tab(pay_rec).customer_trx_id;
                     xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                           ,TRUE
                                                           ,gc_debug_msg);
                     xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                           ,TRUE
                                                           ,'Error :' || SQLERRM);
                     gc_debug_msg := 'Inserting Error records for Parent_cust_doc_id :' || cons_paydoc(cons_rec).parent_cust_doc_id || ' Customer_trx_id = ' || paydoc_tab(pay_rec).customer_trx_id;
                     xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                           ,TRUE
                                                           ,gc_debug_msg);
                     ROLLBACK TO paydoc_insert;
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
                        ,last_updated_by
                        ,last_updated_date
                        ,created_by
                        ,creation_date
                        ,last_updated_login
                        ,as_of_date
                        ,error_message)
                     VALUES
                        (fnd_profile.VALUE('ORG_ID')
                        ,cons_paydoc(cons_rec).parent_cust_doc_id
                        ,decode(cons_paydoc(cons_rec).document_type
                               ,'Y'
                               ,'Paydoc'
                               ,'N'
                               ,'Infocopy')
                        ,cons_paydoc(cons_rec).aops_account_number
                        ,cons_paydoc(cons_rec).oracle_account_number
                        ,cons_paydoc(cons_rec).billdocs_delivery_method
                        ,cons_paydoc(cons_rec).billing_term
                        ,cons_paydoc(cons_rec).cons_inv_id
                        ,paydoc_tab(pay_rec).invoice_number
                        ,paydoc_tab(pay_rec).customer_trx_id
                        ,fnd_global.user_id
                        ,SYSDATE
                        ,fnd_global.user_id
                        ,SYSDATE
                        ,fnd_global.login_id
                        ,g_as_of_date
                        ,lc_error_log);
                     --   COMMIT;
                     retcode := 1;
                     RAISE;
               END;
               gc_debug_msg := to_char(SYSDATE
                                      ,'DD-MON-YYYY HH24:MI:SS') || 'Update Records to IN PROCESS - PAYDOC - CONS ID:' || cons_paydoc(cons_rec).cons_inv_id || ' Cons inv ID = ' || cons_paydoc(cons_rec).cons_inv_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,FALSE
                                                     ,'   ' || '    ' || gc_debug_msg);

            END LOOP; -- End of header Cursor for PAYDOC
            UPDATE ar_cons_inv_all aci
            SET    aci.attribute11 = 'IN PROCESS'
            WHERE  aci.cons_inv_id = cons_paydoc(cons_rec).cons_inv_id;
         EXCEPTION
            WHEN OTHERS THEN
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,TRUE
                                                     ,gc_debug_msg);
               gc_debug_msg := 'Exception for Parent_cust_doc_id :' || cons_paydoc(cons_rec).parent_cust_doc_id || ' Cons inv ID = ' || cons_paydoc(cons_rec).cons_inv_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,TRUE
                                                     ,gc_debug_msg);
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,TRUE
                                                     ,'Error :' || SQLERRM);

         END;

      END LOOP;
      --  END IF;
      xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                            ,FALSE
                                            ,to_char(SYSDATE
                                                    ,'DD-MON-YYYY HH24:MI:SS') ||CHR(13)
                                                    ||'Number of PAYDOC transaction inserted : '||ln_trx_count);
      ln_trx_count:=0;
      ---------------------------------------------------------------
      ---------------------------------------------------------------
      ---Opening PAYDOC_IC Cusrsor
      ---------------------------------------------------------------
      ---------------------------------------------------------------
      -- Opening the Main header Query for paydoc_ic

      xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                            ,FALSE
                                            ,to_char(SYSDATE
                                                    ,'DD-MON-YYYY HH24:MI:SS') || 'paydoc_ic_tab OPEN');

      OPEN lcu_cons_paydoc_ic(p_batch_id
                             ,ln_org_id);
      FETCH lcu_cons_paydoc_ic BULK COLLECT
         INTO cons_paydoc_ic;

      FOR info_rec IN 1 .. cons_paydoc_ic.COUNT
      LOOP
         BEGIN
            SAVEPOINT paydoc_ic_insert;
            lc_epdf_doc_detail := NULL;
            lc_sales_channel   := NULL;
            gc_debug_msg       := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'deriving epdf_doc_detail - PAYDOCIC - CONS ID:' || cons_paydoc_ic(info_rec).cons_inv_id || ' mbs_Doc_id : ' || cons_paydoc_ic(info_rec).mbs_doc_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'    ' || gc_debug_msg);
            --        FND_FILE.PUT_LINE(FND_FILE.LOG,'location  : inside begin');
            SELECT doc_detail_level
            INTO   lc_epdf_doc_detail
            FROM   xx_cdh_mbs_document_master
            WHERE  document_id = cons_paydoc_ic(info_rec).mbs_doc_id;
            -- Get Bill From Date
            gc_debug_msg := to_char(SYSDATE
                                   ,'DD-MON-YYYY HH24:MI:SS') || 'deriving bill_from_date  - PAYDOCIC - CONS ID:' || cons_paydoc_ic(info_rec).cons_inv_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'    ' || gc_debug_msg);

            SELECT xx_ar_ebl_common_util_pkg.bill_from_date(rt.NAME
                                                           ,cons_paydoc_ic(info_rec).cut_off_date)
            INTO   cons_paydoc_ic(info_rec) .bill_from_date
            FROM   ra_terms rt
            WHERE  rt.term_id = cons_paydoc_ic(info_rec).term_id;

            gc_debug_msg := to_char(SYSDATE
                                   ,'DD-MON-YYYY HH24:MI:SS') || 'deriving get_remit_address  - PAYDOCIC - CONS ID:' || cons_paydoc_ic(info_rec).cons_inv_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'    ' || gc_debug_msg);
            -- GET Remit to address
            xx_ar_ebl_common_util_pkg.get_remit_address(xx_ar_ebl_common_util_pkg.get_remit_addressid(cons_paydoc_ic(info_rec).site_use_id
                                                                                                     ,p_debug_flag)
                                                       ,cons_paydoc_ic(info_rec).remit_address1
                                                       ,cons_paydoc_ic(info_rec).remit_address2
                                                       ,cons_paydoc_ic(info_rec).remit_address3
                                                       ,cons_paydoc_ic(info_rec).remit_address4
                                                       ,cons_paydoc_ic(info_rec).remit_city
                                                       ,cons_paydoc_ic(info_rec).remit_state
                                                       ,cons_paydoc_ic(info_rec).remit_zip
                                                       ,cons_paydoc_ic(info_rec).remit_to_description
                                                       ,cons_paydoc_ic(info_rec).remit_country);
            --GET soft header detail
            gc_debug_msg := to_char(SYSDATE
                                   ,'DD-MON-YYYY HH24:MI:SS') || ' getting soft header details: ' || ' Customer ID :' || cons_paydoc_ic(info_rec).customer_id;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'  ' || gc_debug_msg);
            xx_ar_ebl_common_util_pkg.get_soft_header(cons_paydoc_ic(info_rec).customer_id
                                                     ,ln_sfthdr_group_id
                                                     ,cons_paydoc_ic(info_rec).cost_center_sft_hdr
                                                     ,cons_paydoc_ic(info_rec).desktop_sft_hdr
                                                     ,cons_paydoc_ic(info_rec).release_number_sft_hdr
                                                     ,cons_paydoc_ic(info_rec).po_number_sft_hdr);
            -- Getting customer Details
            --defect 15118
        /*    BEGIN
                SELECT CUST_DEPT_DESCRIPTION
                INTO  cons_paydoc_ic(info_rec).cost_center_desc_hdr
                FROM XX_OM_HEADER_ATTRIBUTES_ALL XOHA,
                     RA_CUSTOMER_TRX_ALL RCT
                WHERE RCT.CUSTOMER_TRX_ID =cons_paydoc_ic(info_rec).customer_trx_id
                AND RCT.ATTRIBUTE14= XOHA.HEADER_ID
               AND    rownum < 2;
            EXCEPTION
               WHEN no_data_found THEN
                  cons_paydoc_ic(info_rec).cost_center_desc_hdr := NULL;
            END;*/
            --defect 15118
            SELECT substr(orig_system_reference
                         ,1
                         ,8)
                  ,account_number
                  ,attribute18
            INTO   cons_paydoc_ic(info_rec) .aops_account_number
                  ,cons_paydoc_ic(info_rec) .oracle_account_number
                  ,lc_sales_channel
            FROM   hz_cust_accounts
            WHERE  cust_account_id = cons_paydoc_ic(info_rec).customer_id;
            gc_debug_msg := to_char(SYSDATE
                                   ,'DD-MON-YYYY HH24:MI:SS') || 'deriving term_details - SHIP T0  - PAYDOCIC - CONS ID:' || cons_paydoc_ic(info_rec).cons_inv_id || ' Term : ' || cons_paydoc_ic(info_rec).billing_term;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,FALSE
                                                  ,'    ' || gc_debug_msg);
            xx_ar_ebl_common_util_pkg.get_term_details(cons_paydoc_ic(info_rec).billing_term
                                                      ,cons_paydoc_ic(info_rec).payment_term
                                                      ,cons_paydoc_ic(info_rec).payment_term_description
                                                      ,cons_paydoc_ic(info_rec).payment_term_discount
                                                      ,cons_paydoc_ic(info_rec).payment_term_frequency
                                                      ,cons_paydoc_ic(info_rec).payment_term_report_day);
            IF (lcu_info_trx_details%ISOPEN) THEN
               CLOSE lcu_info_trx_details;
            END IF;
            OPEN lcu_info_trx_details(cons_paydoc_ic(info_rec).cons_inv_id);
            FETCH lcu_info_trx_details BULK COLLECT
               INTO paydoc_ic_tab;
            gc_debug_msg := to_char(SYSDATE
                                   ,'DD-MON-YYYY HH24:MI:SS') || ' paydoc_ic_tab.count' || paydoc_ic_tab.COUNT;
            xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                  ,TRUE
                                                  ,' ' || gc_debug_msg);
            --       FND_FILE.PUT_LINE(FND_FILE.LOG,'location '|| ' paydoc_ic_tab.count' || paydoc_ic_tab.count);
            FOR i IN 1 .. paydoc_ic_tab.COUNT
            LOOP
               BEGIN
                  lc_location          := NULL;
                  lc_province          := NULL;
                  ln_us_tax_rate       := 0;
                  ln_gst_tax_rate      := 0;
                  ln_pst_qst_tax_rate  := 0;
                  ln_hdr_tax_rate      := 0;
                  lc_ph_no_cusrv       := NULL;
                  lc_ph_no_bill        := NULL;
                  lc_orgordnbr         := NULL;
                  lc_reason_code       := NULL;
                  lc_sales_person      := NULL;
                  lc_mail_to_attention := NULL;
                  lc_sold_to_customer  := NULL;
				  lc_bill_comp_flag	   := NULL;							-- Added By Dinesh For Separate Bill Test for Bill Complete and Non-BillComplete

                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'deriving XX_AR_EBL_COMMON_UTIL_PKG.GET_AMOUNT - PAYDOCIC - CONS ID:' || cons_paydoc_ic(info_rec).cons_inv_id || 'TRX ID : ' || paydoc_ic_tab(i).customer_trx_id;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'    ' || '    ' || gc_debug_msg);

                  xx_ar_ebl_common_util_pkg.get_amount(paydoc_ic_tab(i).transaction_source
                                                      ,paydoc_ic_tab(i).customer_trx_id
                                                      ,paydoc_ic_tab(i).transaction_class
                                                      ,paydoc_ic_tab(i).rct_header_id
                                                      ,paydoc_ic_tab(i).amount_due_original
                                                      ,paydoc_ic_tab(i).sku_lines_subtotal
                                                      ,paydoc_ic_tab(i).total_delivery_amount
                                                      ,paydoc_ic_tab(i).total_miscellaneous_amount
                                                      ,paydoc_ic_tab(i).total_association_discount
                                                      ,paydoc_ic_tab(i).total_bulk_amount
                                                      ,paydoc_ic_tab(i).total_coupon_amount
                                                      ,paydoc_ic_tab(i).total_tiered_discount_amount
                                                      ,paydoc_ic_tab(i).total_gift_card_amount
                                                      ,paydoc_ic_tab(i).number_of_lines);
                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'deriving xx_ar_ebl_common_util_pkg.addr_excp_handling  - PAYDOCIC - CONS ID:' || cons_paydoc_ic(info_rec).cons_inv_id || 'TRX ID : ' || paydoc_ic_tab(i).customer_trx_id;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'    ' || '    ' || gc_debug_msg);
                  SELECT xx_ar_ebl_common_util_pkg.addr_excp_handling(cons_paydoc_ic(info_rec).customer_id
                                                                     ,cons_paydoc_ic(info_rec).cust_doc_id
                                                                     ,paydoc_ic_tab(i).ship_to_site_use_id
                                                                     ,cons_paydoc_ic(info_rec).direct_flag
                                                                     ,ln_site_attr_id)
                  INTO   paydoc_ic_tab(i) .bill_to_site_use_id
                  FROM   dual;
                  --GET BILL_TO address
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,to_char(SYSDATE
                                                                ,'DD-MON-YYYY HH24:MI:SS') || 'get address');
                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'deriving xx_ar_ebl_common_util_pkg.get_address - PAYDOCIC - CONS ID:' || cons_paydoc_ic(info_rec).cons_inv_id || 'TRX ID : ' || paydoc_ic_tab(i).customer_trx_id;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'    ' || '    ' || gc_debug_msg);
                  xx_ar_ebl_common_util_pkg.get_address(paydoc_ic_tab(i).bill_to_site_use_id
                                                       ,paydoc_ic_tab(i).bill_to_address1
                                                       ,paydoc_ic_tab(i).bill_to_address2
                                                       ,paydoc_ic_tab(i).bill_to_address3
                                                       ,paydoc_ic_tab(i).bill_to_address4
                                                       ,paydoc_ic_tab(i).bill_to_city
                                                       ,paydoc_ic_tab(i).bill_to_country
                                                       ,paydoc_ic_tab(i).bill_to_state
                                                       ,paydoc_ic_tab(i).bill_to_zip
                                                       ,lc_location
                                                       ,paydoc_ic_tab(i).bill_to_name
                                                       ,lc_ship_to_sequence
                                                       ,lc_province
                                                       ,paydoc_ic_tab(i).cust_acct_site_id
                                                       ,paydoc_ic_tab(i).cust_site_sequence
                                                       ,paydoc_ic_tab(i).customer_name);
                  -- Deriving the various tax amounts
                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'deriving xx_ar_ebl_common_util_pkg.get_tax_amount  - PAYDOCIC - CONS ID:' || cons_paydoc_ic(info_rec).cons_inv_id || 'TRX ID : ' || paydoc_ic_tab(i).customer_trx_id;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'    ' || '    ' || gc_debug_msg);
                  xx_ar_ebl_common_util_pkg.get_tax_amount(paydoc_ic_tab(i).customer_trx_id
                                                          ,lc_country
                                                          ,lc_province
                                                          ,paydoc_ic_tab(i).total_us_tax_amount
                                                          ,ln_us_tax_rate
                                                          ,paydoc_ic_tab(i).total_gst_amount
                                                          ,ln_gst_tax_rate
                                                          ,paydoc_ic_tab(i).total_pst_qst_tax
                                                          ,ln_pst_qst_tax_rate);
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,to_char(SYSDATE
                                                                ,'DD-MON-YYYY HH24:MI:SS') || 'tax amount ends');
                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'deriving mail_to_attention  - PAYDOCIC - CONS ID:' || cons_paydoc_ic(info_rec).cons_inv_id || 'TRX ID : ' || paydoc_ic_tab(i).customer_trx_id;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'    ' || '    ' || gc_debug_msg);
                  IF lc_country = 'CA' THEN
                        IF lc_province IN ('QC', 'PQ') THEN
                           paydoc_ic_tab(i).total_qst_amount := paydoc_ic_tab(i).total_pst_qst_tax;
                        ELSE
                           paydoc_ic_tab(i).total_pst_amount := paydoc_ic_tab(i).total_pst_qst_tax;
                       END IF;
                  END IF;
                  -- Getting Tax ID and Tax description

                  --GET SHIP_TO address
                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'deriving get_address - SHIP T0  - PAYDOCIC - CONS ID:' || cons_paydoc_ic(info_rec).cons_inv_id || 'TRX ID : ' || paydoc_ic_tab(i).customer_trx_id;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'    ' || '    ' || gc_debug_msg);
                  xx_ar_ebl_common_util_pkg.get_address(paydoc_ic_tab(i).ship_to_site_use_id
                                                       ,lc_dummy
                                                       ,lc_dummy
                                                       ,paydoc_ic_tab(i).ship_to_address3
                                                       ,paydoc_ic_tab(i).ship_to_address4
                                                       ,lc_dummy
                                                       ,lc_dummy
                                                       ,lc_dummy
                                                       ,lc_dummy
                                                       ,paydoc_ic_tab(i).ship_to_abbreviation
                                                       ,paydoc_ic_tab(i).ship_to_name
                                                       ,paydoc_ic_tab(i).ship_to_sequence
                                                       ,lc_dummy
                                                       ,paydoc_ic_tab(i).ship_cust_site_id
                                                       ,paydoc_ic_tab(i).ship_cust_site_sequence
                                                       ,lc_dummy);
                  lc_mail_to_attention := xx_ar_ebl_common_util_pkg.get_site_mail_attention(cons_paydoc_ic(info_rec).parent_cust_doc_id
                                                                                           ,paydoc_ic_tab(i).ship_cust_site_id
                                                                                           ,ln_site_attr_id);
                  cons_paydoc_ic(info_rec).mail_to_attention := nvl(lc_mail_to_attention
                                                                   ,cons_paydoc_ic(info_rec).mail_to_attention);
                  -- GET Order header attributes
                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'deriving get_hdr_attr_details - SHIP T0  - PAYDOCIC - CONS ID:' || cons_paydoc_ic(info_rec).cons_inv_id || 'TRX ID : ' || paydoc_ic_tab(i).customer_trx_id;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'    ' || '    ' || gc_debug_msg);
                  xx_ar_ebl_common_util_pkg.get_hdr_attr_details(paydoc_ic_tab(i).order_header_id
                                                                ,ln_spc_order_source_id
                                                                ,paydoc_ic_tab(i).bill_to_contact_email
                                                                ,paydoc_ic_tab(i).bill_to_contact_name
                                                                ,paydoc_ic_tab(i).bill_to_contact_phone
                                                                ,paydoc_ic_tab(i).bill_to_contact_phone_ext
                                                                ,paydoc_ic_tab(i).order_level_comment
                                                                ,paydoc_ic_tab(i).order_type_code
                                                                ,paydoc_ic_tab(i).order_source_code
                                                                ,paydoc_ic_tab(i).ordered_by
                                                                ,paydoc_ic_tab(i).order_date
                                                                ,paydoc_ic_tab(i).order_level_spc_comment
                                                                ,paydoc_ic_tab(i).cost_center_sft_data
                                                                ,paydoc_ic_tab(i).release_number_sft_data
                                                                ,paydoc_ic_tab(i).desktop_sft_data
                                                                ,paydoc_ic_tab(i).ship_to_address1
                                                                ,paydoc_ic_tab(i).ship_to_address2
                                                                ,paydoc_ic_tab(i).ship_to_city
                                                                ,paydoc_ic_tab(i).ship_to_state
                                                                ,paydoc_ic_tab(i).ship_to_country
                                                                ,paydoc_ic_tab(i).ship_to_zip
                                                                ,ln_hdr_tax_rate);

                  IF upper(lc_sales_channel) = 'CONTRACT' THEN
                     lc_ph_no_cusrv := lc_cont_ph_no_cusrv;
                     lc_ph_no_bill  := lc_cont_ph_no_bill;
                  ELSE
                     lc_ph_no_cusrv := lc_dir_ph_no_cusrv;
                     lc_ph_no_bill  := lc_dir_ph_no_bill;
                  END IF;

            --defect 15118
            BEGIN
                SELECT CUST_DEPT_DESCRIPTION,
				       COST_CENTER_DEPT, --Added for Defect 36437 (MOD4B Release 3)
					   DECODE(BILL_COMP_FLAG,'B','Y','Y','Y',NULL)
                INTO  paydoc_ic_tab(i).cost_center_desc_hdr,
				      paydoc_ic_tab(i).cost_center_dept, --Added for Defect 36437 (MOD4B Release 3)
					  lc_bill_comp_flag							-- Added By Dinesh For Separate Bill Test for Bill Complete and Non-BillComplete
                FROM XX_OM_HEADER_ATTRIBUTES_ALL XOHA,
                     RA_CUSTOMER_TRX_ALL RCT
                WHERE RCT.CUSTOMER_TRX_ID =paydoc_ic_tab(i).customer_trx_id
                AND RCT.ATTRIBUTE14= XOHA.HEADER_ID
               AND    rownum < 2;
            EXCEPTION
               WHEN no_data_found THEN
                  paydoc_ic_tab(i).cost_center_desc_hdr := NULL;
				  paydoc_ic_tab(i).cost_center_dept := NULL; --Added for Defect 36437 (MOD4B Release 3)
            END;
            --defect 15118
                  oe_profile.get('SO_ORGANIZATION_ID'
                                ,ln_organization_id);

                  BEGIN
                     SELECT description
                     INTO   paydoc_ic_tab(i) .carrier
                     FROM   org_freight orf
                     WHERE  orf.freight_code = paydoc_ic_tab(i).ship_via
                     AND    orf.organization_id = ln_organization_id
                     AND    rownum < 2;
                  EXCEPTION
                     WHEN no_data_found THEN
                        paydoc_ic_tab(i).carrier := NULL;
                  END;
                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'deriving get_misc_values - SHIP T0  - PAYDOCIC - CONS ID:' || cons_paydoc_ic(info_rec).cons_inv_id || 'TRX ID : ' || paydoc_ic_tab(i).customer_trx_id;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'    ' || '    ' || gc_debug_msg);
                  xx_ar_ebl_common_util_pkg.get_misc_values(paydoc_ic_tab(i).order_header_id
                                                           ,paydoc_ic_tab(i).reason_code
                                                           ,paydoc_ic_tab(i).sold_to_customer_id
                                                           ,paydoc_ic_tab(i).transaction_class
                                                           ,lc_orgordnbr
                                                           ,lc_reason_code
                                                           ,lc_sold_to_customer
                                                           ,paydoc_ic_tab(i).reconcile_date);
                  BEGIN
                     /* Begin Modification  for ver 1.6 Defect Id: 45279 Updating sales person to null
                     lc_sales_person := arpt_sql_func_util.get_salesrep_name_number(paydoc_ic_tab(i).sales_person_id
                                                                                   ,'NAME'
                                                                                   , gn_org_id);  -- defect 26440 */
	                 lc_sales_person := NULL;
	                 /* End Modification  for ver 1.6 Defect Id: 45279 Updating sales person to null */

                  EXCEPTION
                     WHEN no_data_found THEN
                        lc_sales_person := NULL;
                  END;
                  --GET soft header detail
                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'deriving Insert Header  - PAYDOCIC - CONS ID:' || cons_paydoc_ic(info_rec).cons_inv_id || 'TRX ID : ' || paydoc_ic_tab(i).customer_trx_id;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'    ' || '    ' || gc_debug_msg);

                  INSERT INTO xx_ar_ebl_cons_hdr_main
                     (cons_inv_id
                     ,customer_trx_id
                     ,mbs_doc_id
                     ,consolidated_bill_number
                     ,billdocs_delivery_method
                     ,document_type
                     ,direct_flag
                     ,cust_doc_id
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
                     ,dept_desc --Defect 15118
					 ,dept_code --Added for Defect 36437 (MOD4B Release 3)
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
                     ,infocopy_tag
                     ,batch_source_id
					 ,c_ext_attr1)
                  VALUES
                     (cons_paydoc_ic(info_rec).cons_inv_id
                     ,paydoc_ic_tab(i).customer_trx_id
                     ,cons_paydoc_ic(info_rec).mbs_doc_id
                     ,cons_paydoc_ic(info_rec).cons_bill_num
                     ,cons_paydoc_ic(info_rec).billdocs_delivery_method
                     ,decode(cons_paydoc_ic(info_rec).document_type
                            ,'Y'
                            ,'Paydoc'
                            ,'N'
                            ,'Infocopy')
                     ,decode(cons_paydoc_ic(info_rec).direct_flag
                            ,'Y'
                            ,'D'
                            ,'N'
                            ,'I')
                     ,cons_paydoc_ic(info_rec).cust_doc_id
                     ,to_date(cons_paydoc_ic(info_rec).bill_from_date) + 1
                     ,cons_paydoc_ic(info_rec).cut_off_date
                     ,nvl(decode(cons_paydoc_ic(info_rec).mail_to_attention
                                ,NULL
                                ,NULL
                                ,'ATTN: ' || cons_paydoc_ic(info_rec).mail_to_attention)
                         ,'ATTN: ACCTS PAYABLE')
                     ,paydoc_ic_tab(i).invoice_number
                     ,lc_orgordnbr
                     ,paydoc_ic_tab(i).amount_due_original
                     ,paydoc_ic_tab(i).amount_due_remaining
                     ,paydoc_ic_tab(i).amount_due_original - (paydoc_ic_tab(i).total_us_tax_amount + paydoc_ic_tab(i).total_gst_amount + paydoc_ic_tab(i).total_pst_qst_tax)
                     ,DECODE(( paydoc_ic_tab(i).total_gst_amount +  paydoc_ic_tab(i).total_pst_qst_tax +  paydoc_ic_tab(i).total_us_tax_amount),0,0,ln_hdr_tax_rate)
                     ,lc_reason_code
                     ,cons_paydoc_ic(info_rec).bill_to_date
                     ,DECODE(cons_paydoc_ic(info_rec).billdocs_delivery_method
                            ,'eXLS',decode(paydoc_ic_tab(i).transaction_class,'CM',NULL,cons_paydoc_ic(info_rec).due_date)
                            ,cons_paydoc_ic(info_rec).due_date)
                     ,cons_paydoc_ic(info_rec).currency
                     ,paydoc_ic_tab(i).order_date
                     ,paydoc_ic_tab(i).reconcile_date
                     ,paydoc_ic_tab(i).rct_header_id
                     ,paydoc_ic_tab(i).order_level_comment
                     ,paydoc_ic_tab(i).order_level_spc_comment
                     ,paydoc_ic_tab(i).order_type
                     ,paydoc_ic_tab(i).order_type_code
                     ,paydoc_ic_tab(i).order_source_code
                     ,paydoc_ic_tab(i).ordered_by
                     ,cons_paydoc_ic(info_rec).payment_term
                     ,cons_paydoc_ic(info_rec).payment_term_description
                     ,cons_paydoc_ic(info_rec).payment_term_discount
                     ,xx_ar_ebl_common_util_pkg.get_discount_date(paydoc_ic_tab(i).customer_trx_id)
                     ,cons_paydoc_ic(info_rec).payment_term_frequency
                     ,cons_paydoc_ic(info_rec).payment_term_report_day
                     ,cons_paydoc_ic(info_rec).billing_term
                     ,paydoc_ic_tab(i).total_bulk_amount
                     ,paydoc_ic_tab(i).total_coupon_amount
                     ,paydoc_ic_tab(i).total_bulk_amount + paydoc_ic_tab(i).total_tiered_discount_amount +paydoc_ic_tab(i).total_association_discount
                     ,paydoc_ic_tab(i).total_delivery_amount
                     ,paydoc_ic_tab(i).total_gift_card_amount
                     ,paydoc_ic_tab(i).total_gst_amount
                     ,paydoc_ic_tab(i).total_gst_amount + paydoc_ic_tab(i).total_pst_qst_tax
                     ,paydoc_ic_tab(i).total_miscellaneous_amount
                     ,paydoc_ic_tab(i).total_association_discount
                     ,paydoc_ic_tab(i).total_pst_amount
                     ,paydoc_ic_tab(i).total_qst_amount
                     ,paydoc_ic_tab(i).total_tiered_discount_amount
                     ,paydoc_ic_tab(i).total_us_tax_amount
                     ,paydoc_ic_tab(i).sku_lines_subtotal
                     ,lc_sales_person
                     ,cons_paydoc_ic(info_rec).customer_id
                     ,cons_paydoc_ic(info_rec).oracle_account_number
                     ,paydoc_ic_tab(i).customer_name
                     ,cons_paydoc_ic(info_rec).aops_account_number
                     ,paydoc_ic_tab(i).cust_acct_site_id
                     ,paydoc_ic_tab(i).cust_site_sequence
                     ,paydoc_ic_tab(i).customer_ref_date --to fetch
                     ,paydoc_ic_tab(i).customer_ref_number
                     ,lc_sold_to_customer
                     ,paydoc_ic_tab(i).transaction_source
                     ,paydoc_ic_tab(i).transaction_type
                     ,decode(paydoc_ic_tab(i).transaction_class
                            ,'CM'
                            ,'Credit Memo'
                            ,'DM'
                            ,'Debit Memo'
                            ,'INV'
                            ,'Invoice')
                     ,paydoc_ic_tab(i).trx_date
                     ,paydoc_ic_tab(i).bill_to_name
                     ,paydoc_ic_tab(i).bill_to_address1
                     ,paydoc_ic_tab(i).bill_to_address2
                     ,paydoc_ic_tab(i).bill_to_address3
                     ,paydoc_ic_tab(i).bill_to_address4
                     ,paydoc_ic_tab(i).bill_to_city
                     ,decode(paydoc_ic_tab(i).bill_to_country
                            ,'US'
                            ,paydoc_ic_tab(i).bill_to_state
                            ,lc_province)
                     ,paydoc_ic_tab(i).bill_to_country
                     ,paydoc_ic_tab(i).bill_to_zip
                     ,paydoc_ic_tab(i).bill_to_contact_name
                     ,paydoc_ic_tab(i).bill_to_contact_phone
                     ,paydoc_ic_tab(i).bill_to_contact_phone_ext
                     ,paydoc_ic_tab(i).bill_to_contact_email
					 ,lc_location
                     ,paydoc_ic_tab(i).carrier
                     ,paydoc_ic_tab(i).ship_to_name
                     ,paydoc_ic_tab(i).ship_to_abbreviation
                     ,paydoc_ic_tab(i).ship_to_address1
                     ,paydoc_ic_tab(i).ship_to_address2
                     ,paydoc_ic_tab(i).ship_to_address3
                     ,paydoc_ic_tab(i).ship_to_address4
                     ,paydoc_ic_tab(i).ship_to_city
                     ,paydoc_ic_tab(i).ship_to_state
                     ,paydoc_ic_tab(i).ship_to_country
                     ,paydoc_ic_tab(i).ship_to_zip
                     ,paydoc_ic_tab(i).ship_to_sequence
                     ,paydoc_ic_tab(i).shipment_ref_number
                     ,cons_paydoc_ic(info_rec).remit_address1
                     ,cons_paydoc_ic(info_rec).remit_address2
                     ,cons_paydoc_ic(info_rec).remit_address3
                     ,cons_paydoc_ic(info_rec).remit_address4
                     ,cons_paydoc_ic(info_rec).remit_city
                     ,cons_paydoc_ic(info_rec).remit_state
                     ,cons_paydoc_ic(info_rec).remit_zip
                     ,cons_paydoc_ic(info_rec).remit_country
                     ,decode(lc_country
                            ,'US'
                            ,lc_tax_number
                            ,NULL)
                     ,decode(lc_country
                            ,'CA'
                            ,lc_tax_number
                            ,NULL)
                     ,upper(nvl(cons_paydoc_ic(info_rec).cost_center_sft_hdr
                               ,'COST CENTER'))
                     ,paydoc_ic_tab(i).cost_center_desc_hdr --defect 22582
                     --,upper(nvl(paydoc_ic_tab(i).cost_center_desc_hdr
                     --          ,'COST CENTER DESCRIPTION'))--defect 15118
					 ,paydoc_ic_tab(i).cost_center_dept --Added for Defect 36437 (MOD4B Release 3)
                     ,upper(nvl(cons_paydoc_ic(info_rec).po_number_sft_hdr
                               ,'PURCHASE ORDER'))
                     ,upper(nvl(cons_paydoc_ic(info_rec).release_number_sft_hdr
                               ,'RELEASE'))
                     ,upper(nvl(cons_paydoc_ic(info_rec).desktop_sft_hdr
                               ,'DESKTOP'))
                     ,paydoc_ic_tab(i).number_of_lines
                     ,fnd_global.user_id
                     ,SYSDATE
                     ,fnd_global.user_id
                     ,SYSDATE
                     ,fnd_global.login_id
                     ,p_batch_id
                     ,fnd_profile.VALUE('ORG_ID')
                     ,paydoc_ic_tab(i).bill_to_site_use_id
                     ,cons_paydoc_ic(info_rec).parent_cust_doc_id
                     ,lc_epdf_doc_detail
                     ,ln_request_id
                     ,paydoc_ic_tab(i).invoice_number
                     ,paydoc_ic_tab(i).desktop_sft_data
                     ,paydoc_ic_tab(i).purchase_order
                     ,paydoc_ic_tab(i).cost_center_sft_data
                     ,paydoc_ic_tab(i).release_number_sft_data
                     ,lc_ph_no_cusrv
                     ,lc_ph_no_bill
                     ,cons_paydoc_ic(info_rec).infocopy_tag
                     ,paydoc_ic_tab(i).batch_source_id
					 ,lc_bill_comp_flag);						-- Added By Dinesh For Separate Bill Test for Bill Complete and Non-BillComplete
                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'Insert Lines - PAYDOCIC - CONS ID:' || cons_paydoc_ic(info_rec).cons_inv_id || 'TRX ID : ' || paydoc_ic_tab(i).customer_trx_id;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'    ' || '    ' || gc_debug_msg);
                 ln_trx_count:=ln_trx_count+1;
                  -- Calling Insert_lines
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,to_char(SYSDATE
                                                                ,'DD-MON-YYYY HH24:MI:SS') || '05');
                  insert_lines(paydoc_ic_tab(i).customer_trx_id
                              ,paydoc_ic_tab(i).transaction_class
                              ,cons_paydoc_ic(info_rec).cons_inv_id
                              ,cons_paydoc_ic(info_rec).cust_doc_id
                              ,cons_paydoc_ic(info_rec).parent_cust_doc_id
                              ,cons_paydoc_ic(info_rec).cost_center_sft_hdr
                              ,p_batch_id
                              ,ln_item_master_org
                              ,paydoc_ic_tab(i).order_source_code);

               EXCEPTION
                  WHEN OTHERS THEN
                     lc_error_log := 'Error at : ' || gc_debug_msg || ' ' || SQLERRM;
                     xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                           ,FALSE
                                                           ,'       ' || '    ' || 'Error at :' || gc_debug_msg);
                     gc_debug_msg := to_char(SYSDATE
                                            ,'DD-MON-YYYY HH24:MI:SS') || 'When others Exception  - PAYDOCIC - CONS ID:' || cons_paydoc_ic(info_rec).cons_inv_id || ' TRX ID : ' || paydoc_ic_tab(i).customer_trx_id;
                     xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                           ,FALSE
                                                           ,'       ' || gc_debug_msg);
                     xx_ar_ebl_common_util_pkg.put_log_line(TRUE
                                                           ,TRUE
                                                           ,'Error :' || SQLERRM);
                     ROLLBACK TO paydoc_ic_insert;
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
                        ,last_updated_by
                        ,last_updated_date
                        ,created_by
                        ,creation_date
                        ,last_updated_login
                        ,as_of_date
                        ,error_message)
                     VALUES
                        (fnd_profile.VALUE('ORG_ID')
                        ,cons_paydoc_ic(info_rec).parent_cust_doc_id
                        ,decode(cons_paydoc_ic(info_rec).document_type
                               ,'Y'
                               ,'Paydoc'
                               ,'N'
                               ,'Infocopy')
                        ,cons_paydoc_ic(info_rec).aops_account_number
                        ,cons_paydoc_ic(info_rec).oracle_account_number
                        ,cons_paydoc_ic(info_rec).billdocs_delivery_method
                        ,cons_paydoc_ic(info_rec).billing_term
                        ,cons_paydoc_ic(info_rec).cons_inv_id
                        ,paydoc_ic_tab(i).invoice_number
                        ,paydoc_ic_tab(i).customer_trx_id
                        ,fnd_global.user_id
                        ,SYSDATE
                        ,fnd_global.user_id
                        ,SYSDATE
                        ,fnd_global.login_id
                        ,g_as_of_date
                        ,lc_error_log);
                     retcode := 1;
                     --    COMMIT;
                     RAISE;

               END;
            END LOOP; -- End of header Cursor for PAY_DOC_IC
         EXCEPTION
            WHEN OTHERS THEN
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,TRUE
                                                     ,'        ' || gc_debug_msg);
               gc_debug_msg := 'Exception for Parent_cust_doc_id :' || cons_paydoc_ic(info_rec).parent_cust_doc_id || ' Cons inv ID = ' || cons_paydoc_ic(info_rec).cons_inv_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,TRUE
                                                     ,'        ' || gc_debug_msg);
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,TRUE
                                                     ,'Error :' || SQLERRM);
         END;
      END LOOP;
      xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                            ,FALSE
                                            ,to_char(SYSDATE
                                                    ,'DD-MON-YYYY HH24:MI:SS') ||CHR(13)
                                                    ||'Number of PAYDOC_IC transaction inserted : '||ln_trx_count);
      ln_trx_count:=0;
      ---------------------------------------------------------------
      ---------------------------------------------------------------
      ---Opening INV_IC Cusrsor
      ---------------------------------------------------------------
      ---------------------------------------------------------------
      ln_prev_document_id := 0;
      ln_prev_site_use_id := 0;
      -- Opening the Main header Query for inv_ic
      gc_debug_msg := to_char(SYSDATE
                             ,'DD-MON-YYYY HH24:MI:SS') || 'OPEN Cusrsor  - INVIC';
      xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                            ,FALSE
                                            ,gc_debug_msg);
      OPEN lcu_cons_header_inv_ic(p_batch_id
                                 ,ln_site_attr_id
                                 ,ln_org_id);
      FETCH lcu_cons_header_inv_ic BULK COLLECT
         INTO inv_ic_tab;
      gc_debug_msg := to_char(SYSDATE
                             ,'DD-MON-YYYY HH24:MI:SS') || ' inv_ic_tab.count' || inv_ic_tab.COUNT;
      xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                            ,TRUE
                                            ,gc_debug_msg);
      FOR i IN 1 .. inv_ic_tab.COUNT
      LOOP
         lc_location          := NULL;
         lc_province          := NULL;
         ln_us_tax_rate       := 0;
         ln_gst_tax_rate      := 0;
         ln_pst_qst_tax_rate  := 0;
         ln_hdr_tax_rate      := 0;
         lc_ph_no_cusrv       := NULL;
         lc_ph_no_bill        := NULL;
         lc_orgordnbr         := NULL;
         lc_reason_code       := NULL;
         lc_sales_person      := NULL;
         lc_mail_to_attention := NULL;
         lc_sold_to_customer  := NULL;
		 lc_bill_comp_flag	  := NULL;					-- Added By Dinesh For Separate Bill Test for Bill Complete and Non-BillComplete
         -- Deriving the various invoice amounts

         IF ((ln_prev_document_id = 0 AND ln_prev_site_use_id = 0) --First record
            OR (ln_prev_site_use_id != inv_ic_tab(i).bill_to_site_use_id) --Changing inv_rec.site_use_id
            OR ((ln_prev_site_use_id = inv_ic_tab(i).bill_to_site_use_id) AND (ln_prev_document_id != inv_ic_tab(i).cust_doc_id))) THEN
            BEGIN
               SELECT xx_ar_od_cbi_s.NEXTVAL
               INTO   ln_prev_cons_bill_id
               FROM   dual;
               SAVEPOINT inv_ic_insert;
               lc_process          := 'Y';

               gc_debug_msg := to_char(SYSDATE
                                      ,'DD-MON-YYYY HH24:MI:SS') || 'Populate virtual bill number  - INVIC - CONS ID:' || inv_ic_tab(i).cons_inv_id || 'TRX ID : ' || inv_ic_tab(i).customer_trx_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                      ,FALSE
                                                      ,'    ' || gc_debug_msg);
               ln_prev_document_id := inv_ic_tab(i).cust_doc_id;
               ln_prev_site_use_id := inv_ic_tab(i).bill_to_site_use_id;
            END;
         END IF;
         inv_ic_tab(i).cons_inv_id := ln_prev_cons_bill_id;
         IF (lc_process = 'Y') THEN
            BEGIN
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,FALSE
                                                     ,to_char(SYSDATE
                                                             ,'DD-MON-YYYY HH24:MI:SS') || '08');
               SELECT doc_detail_level
               INTO   lc_epdf_doc_detail
               FROM   xx_cdh_mbs_document_master
               WHERE  document_id = inv_ic_tab(i).mbs_doc_id;
               gc_debug_msg := to_char(SYSDATE
                                      ,'DD-MON-YYYY HH24:MI:SS') || 'get_amount  - INVIC - CONS ID:' || inv_ic_tab(i).cons_inv_id || 'TRX ID : ' || inv_ic_tab(i).customer_trx_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,FALSE
                                                     ,'    ' || gc_debug_msg);
               xx_ar_ebl_common_util_pkg.get_amount(inv_ic_tab(i).transaction_source
                                                   ,inv_ic_tab(i).customer_trx_id
                                                   ,inv_ic_tab(i).transaction_class
                                                   ,inv_ic_tab(i).rct_header_id
                                                   ,inv_ic_tab(i).amount_due_original
                                                   ,inv_ic_tab(i).sku_lines_subtotal
                                                   ,inv_ic_tab(i).total_delivery_amount
                                                   ,inv_ic_tab(i).total_miscellaneous_amount
                                                   ,inv_ic_tab(i).total_association_discount
                                                   ,inv_ic_tab(i).total_bulk_amount
                                                   ,inv_ic_tab(i).total_coupon_amount
                                                   ,inv_ic_tab(i).total_tiered_discount_amount
                                                   ,inv_ic_tab(i).total_gift_card_amount
                                                   ,inv_ic_tab(i).number_of_lines);

               -- Deriving Exception bill_to address
               gc_debug_msg := to_char(SYSDATE
                                      ,'DD-MON-YYYY HH24:MI:SS') || 'get_address  - INVIC - CONS ID:' || inv_ic_tab(i).cons_inv_id || 'TRX ID : ' || inv_ic_tab(i).customer_trx_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,FALSE
                                                     ,'    ' || gc_debug_msg); --GET BILL_TO address
               xx_ar_ebl_common_util_pkg.get_address(inv_ic_tab(i).bill_to_site_use_id
                                                    ,inv_ic_tab(i).bill_to_address1
                                                    ,inv_ic_tab(i).bill_to_address2
                                                    ,inv_ic_tab(i).bill_to_address3
                                                    ,inv_ic_tab(i).bill_to_address4
                                                    ,inv_ic_tab(i).bill_to_city
                                                    ,inv_ic_tab(i).bill_to_country
                                                    ,inv_ic_tab(i).bill_to_state
                                                    ,inv_ic_tab(i).bill_to_zip
                                                    ,lc_location
                                                    ,inv_ic_tab(i).bill_to_name
                                                    ,lc_ship_to_sequence
                                                    ,lc_province
                                                    ,inv_ic_tab(i).cust_acct_site_id
                                                    ,inv_ic_tab(i).cust_site_sequence
                                                    ,inv_ic_tab(i).customer_name);

               -- Deriving the various tax amounts
               gc_debug_msg := to_char(SYSDATE
                                      ,'DD-MON-YYYY HH24:MI:SS') || 'get_tax_amount  - INVIC - CONS ID:' || inv_ic_tab(i).cons_inv_id || 'TRX ID : ' || inv_ic_tab(i).customer_trx_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,FALSE
                                                     ,'    ' || gc_debug_msg); --GET BILL_TO address

               xx_ar_ebl_common_util_pkg.get_tax_amount(inv_ic_tab(i).customer_trx_id
                                                       ,lc_country
                                                       ,lc_province
                                                       ,inv_ic_tab(i).total_us_tax_amount
                                                       ,ln_us_tax_rate
                                                       ,inv_ic_tab(i).total_gst_amount
                                                       ,ln_gst_tax_rate
                                                       ,inv_ic_tab(i).total_pst_qst_tax
                                                       ,ln_pst_qst_tax_rate);

               IF lc_country = 'CA' THEN
                    IF lc_province IN ('QC', 'PQ') THEN
                     inv_ic_tab(i).total_qst_amount := inv_ic_tab(i).total_pst_qst_tax;
                    ELSE
                     inv_ic_tab(i).total_pst_amount := inv_ic_tab(i).total_pst_qst_tax;
                    END IF;
               END IF;

               gc_debug_msg := to_char(SYSDATE
                                      ,'DD-MON-YYYY HH24:MI:SS') || 'bill_from_date  - INVIC - CONS ID:' || inv_ic_tab(i).cons_inv_id || 'TRX ID : ' || inv_ic_tab(i).customer_trx_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,FALSE
                                                     ,'    ' || gc_debug_msg);
               SELECT xx_ar_ebl_common_util_pkg.bill_from_date(inv_ic_tab(i).billing_term
                                                              ,g_as_of_date)
               INTO   inv_ic_tab(i) .bill_from_date
               FROM   dual;
               gc_debug_msg := to_char(SYSDATE
                                      ,'DD-MON-YYYY HH24:MI:SS') || 'get_remit_address  - INVIC - CONS ID:' || inv_ic_tab(i).cons_inv_id || 'TRX ID : ' || inv_ic_tab(i).customer_trx_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,FALSE
                                                     ,'    ' || gc_debug_msg);

               xx_ar_ebl_common_util_pkg.get_remit_address(xx_ar_ebl_common_util_pkg.get_remit_addressid(inv_ic_tab(i).bill_to_site_use_id
                                                                                                        ,p_debug_flag)
                                                          ,inv_ic_tab(i).remit_address1
                                                          ,inv_ic_tab(i).remit_address2
                                                          ,inv_ic_tab(i).remit_address3
                                                          ,inv_ic_tab(i).remit_address4
                                                          ,inv_ic_tab(i).remit_city
                                                          ,inv_ic_tab(i).remit_state
                                                          ,inv_ic_tab(i).remit_zip
                                                          ,inv_ic_tab(i).remit_to_description
                                                          ,inv_ic_tab(i).remit_country);
               --GET SHIP_TO address
               gc_debug_msg := to_char(SYSDATE
                                      ,'DD-MON-YYYY HH24:MI:SS') || 'get_address - SHIP_TO  - INVIC - CONS ID:' || inv_ic_tab(i).cons_inv_id || 'TRX ID : ' || inv_ic_tab(i).customer_trx_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,FALSE
                                                     ,'    ' || gc_debug_msg);
               xx_ar_ebl_common_util_pkg.get_address(inv_ic_tab(i).ship_to_site_use_id
                                                    ,lc_dummy
                                                    ,lc_dummy
                                                    ,inv_ic_tab(i).ship_to_address3
                                                    ,inv_ic_tab(i).ship_to_address4
                                                    ,lc_dummy
                                                    ,lc_dummy
                                                    ,lc_dummy
                                                    ,lc_dummy
                                                    ,inv_ic_tab(i).ship_to_abbreviation
                                                    ,inv_ic_tab(i).ship_to_name
                                                    ,inv_ic_tab(i).ship_to_sequence
                                                    ,lc_dummy
                                                    ,inv_ic_tab(i).ship_cust_site_id
                                                    ,inv_ic_tab(i).ship_cust_site_sequence
                                                    ,lc_dummy);
               -- GET Order header attributes
               gc_debug_msg := to_char(SYSDATE
                                      ,'DD-MON-YYYY HH24:MI:SS') || 'get_hdr_attr_details  - INVIC - CONS ID:' || inv_ic_tab(i).cons_inv_id || 'TRX ID : ' || inv_ic_tab(i).customer_trx_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,FALSE
                                                     ,'    ' || gc_debug_msg);
               xx_ar_ebl_common_util_pkg.get_hdr_attr_details(inv_ic_tab(i).order_header_id
                                                             ,ln_spc_order_source_id
                                                             ,inv_ic_tab(i).bill_to_contact_email
                                                             ,inv_ic_tab(i).bill_to_contact_name
                                                             ,inv_ic_tab(i).bill_to_contact_phone
                                                             ,inv_ic_tab(i).bill_to_contact_phone_ext
                                                             ,inv_ic_tab(i).order_level_comment
                                                             ,inv_ic_tab(i).order_type_code
                                                             ,inv_ic_tab(i).order_source_code
                                                             ,inv_ic_tab(i).ordered_by
                                                             ,inv_ic_tab(i).order_date
                                                             ,inv_ic_tab(i).order_level_spc_comment
                                                             ,inv_ic_tab(i).cost_center_sft_data
                                                             ,inv_ic_tab(i).release_number_sft_data
                                                             ,inv_ic_tab(i).desktop_sft_data
                                                             ,inv_ic_tab(i).ship_to_address1
                                                             ,inv_ic_tab(i).ship_to_address2
                                                             ,inv_ic_tab(i).ship_to_city
                                                             ,inv_ic_tab(i).ship_to_state
                                                             ,inv_ic_tab(i).ship_to_country
                                                             ,inv_ic_tab(i).ship_to_zip
                                                             ,ln_hdr_tax_rate);
                   --defect 15118
            BEGIN
                SELECT CUST_DEPT_DESCRIPTION,
                       COST_CENTER_DEPT, --Added for Defect 36437 (MOD4B Release 3)
					   DECODE(BILL_COMP_FLAG,'B','Y','Y','Y',NULL)
                INTO   inv_ic_tab(i).cost_center_desc_hdr,
				       inv_ic_tab(i).cost_center_dept,  --Added for Defect 36437 (MOD4B Release 3)
					   lc_bill_comp_flag					-- Added By Dinesh For Separate Bill Test for Bill Complete and Non-BillComplete
                FROM XX_OM_HEADER_ATTRIBUTES_ALL XOHA,
                     RA_CUSTOMER_TRX_ALL RCT
                WHERE RCT.CUSTOMER_TRX_ID =inv_ic_tab(i).customer_trx_id
                AND RCT.ATTRIBUTE14= XOHA.HEADER_ID
               AND    rownum < 2;
            EXCEPTION
               WHEN no_data_found THEN
                  inv_ic_tab(i).cost_center_desc_hdr := NULL;
				  inv_ic_tab(i).cost_center_dept := NULL;
            END;
            --defect 15118
               --GET soft header detail
               gc_debug_msg := to_char(SYSDATE
                                      ,'DD-MON-YYYY HH24:MI:SS') || 'get_soft_header  - INVIC - CONS ID:' || inv_ic_tab(i).cons_inv_id || 'TRX ID : ' || inv_ic_tab(i).customer_trx_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,FALSE
                                                     ,'    ' || gc_debug_msg);
               xx_ar_ebl_common_util_pkg.get_soft_header(inv_ic_tab(i).customer_id
                                                        ,ln_sfthdr_group_id
                                                        ,inv_ic_tab(i).cost_center_sft_hdr
                                                        ,inv_ic_tab(i).desktop_sft_hdr
                                                        ,inv_ic_tab(i).release_number_sft_hdr
                                                        ,inv_ic_tab(i).po_number_sft_hdr);

               -- Getting customer Details
               SELECT substr(orig_system_reference
                            ,1
                            ,8)
                     ,account_number
                     ,attribute18
               INTO   inv_ic_tab(i) .aops_account_number
                     ,inv_ic_tab(i) .oracle_account_number
                     ,lc_sales_channel
               FROM   hz_cust_accounts
               WHERE  cust_account_id = inv_ic_tab(i).customer_id;
               IF upper(lc_sales_channel) = 'CONTRACT' THEN
                  lc_ph_no_cusrv := lc_cont_ph_no_cusrv;
                  lc_ph_no_bill  := lc_cont_ph_no_bill;
               ELSE
                  lc_ph_no_cusrv := lc_dir_ph_no_cusrv;
                  lc_ph_no_bill  := lc_dir_ph_no_bill;
               END IF;
               -- Getting Term Description
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,FALSE
                                                     ,to_char(SYSDATE
                                                             ,'DD-MON-YYYY HH24:MI:SS') || 'Payment term attributes - PAYDOC_IC');
               gc_debug_msg := to_char(SYSDATE
                                      ,'DD-MON-YYYY HH24:MI:SS') || 'GET_TERM_DETAILS  - INVIC - CONS ID:' || inv_ic_tab(i).cons_inv_id || 'TRX ID : ' || inv_ic_tab(i).customer_trx_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,FALSE
                                                     ,'    ' || gc_debug_msg);
               xx_ar_ebl_common_util_pkg.get_term_details(inv_ic_tab(i).billing_term
                                                         ,inv_ic_tab(i).payment_term
                                                         ,inv_ic_tab(i).payment_term_description
                                                         ,inv_ic_tab(i).payment_term_discount
                                                         ,inv_ic_tab(i).payment_term_frequency
                                                         ,inv_ic_tab(i).payment_term_report_day);

               --GET soft header detail
               oe_profile.get('SO_ORGANIZATION_ID'
                             ,ln_organization_id);

               BEGIN
                  SELECT description
                  INTO   inv_ic_tab(i) .carrier
                  FROM   org_freight orf
                  WHERE  orf.freight_code = inv_ic_tab(i).ship_via
                  AND    orf.organization_id = ln_organization_id
                  AND    rownum < 2;
               EXCEPTION
                  WHEN no_data_found THEN
                     inv_ic_tab(i).carrier := NULL;
               END;
               gc_debug_msg := to_char(SYSDATE
                                      ,'DD-MON-YYYY HH24:MI:SS') || 'get_misc_values  - INVIC - CONS ID:' || inv_ic_tab(i).cons_inv_id || 'TRX ID : ' || inv_ic_tab(i).customer_trx_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,FALSE
                                                     ,gc_debug_msg);
               xx_ar_ebl_common_util_pkg.get_misc_values(inv_ic_tab(i).order_header_id
                                                        ,inv_ic_tab(i).reason_code
                                                        ,inv_ic_tab(i).sold_to_customer_id
                                                        ,inv_ic_tab(i).transaction_class
                                                        ,lc_orgordnbr
                                                        ,lc_reason_code
                                                        ,lc_sold_to_customer
                                                        ,inv_ic_tab(i).reconcile_date);
               BEGIN
                  /* Begin Modification  for ver 1.4 Defect Id: 45279 Updating sales person to null
                  lc_sales_person := arpt_sql_func_util.get_salesrep_name_number(inv_ic_tab(i).sales_person_id
                                                                                ,'NAME'
                                                                                , gn_org_id); -- defect  26440*/
	              lc_sales_person := NULL;
	              /* End Modification  for ver 1.6 Defect Id: 45279 Updating sales person to null */

               EXCEPTION
                  WHEN no_data_found THEN
                     lc_sales_person := NULL;
               END;

               gc_debug_msg := to_char(SYSDATE
                                      ,'DD-MON-YYYY HH24:MI:SS') || 'mail_to_attention  - INVIC - CONS ID:' || inv_ic_tab(i).cons_inv_id || 'TRX ID : ' || inv_ic_tab(i).customer_trx_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,FALSE
                                                     ,'    ' || gc_debug_msg);

               lc_mail_to_attention := xx_ar_ebl_common_util_pkg.get_site_mail_attention(inv_ic_tab(i).parent_cust_doc_id
                                                                                        ,inv_ic_tab(i).ship_cust_site_id
                                                                                        ,ln_site_attr_id);
               inv_ic_tab(i).mail_to_attention := nvl(lc_mail_to_attention
                                                     ,inv_ic_tab(i).mail_to_attention);

               gc_debug_msg := to_char(SYSDATE
                                      ,'DD-MON-YYYY HH24:MI:SS') || 'Insert header  - INVIC - CONS ID:' || inv_ic_tab(i).cons_inv_id || 'TRX ID : ' || inv_ic_tab(i).customer_trx_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,FALSE
                                                     ,'    ' || gc_debug_msg);

               INSERT INTO xx_ar_ebl_cons_hdr_main
                  (cons_inv_id
                  ,customer_trx_id
                  ,mbs_doc_id
                  ,consolidated_bill_number
                  ,billdocs_delivery_method
                  ,document_type
                  ,direct_flag
                  ,cust_doc_id
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
                  ,payment_term -- attribute5
                  ,payment_term_description --lc
                  ,payment_term_discount --attribute4
                  ,payment_term_discount_date --aps
                  ,payment_term_frequency --attribute1
                  ,payment_term_report_day -- attribute2
                  ,payment_term_string -- NAME
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
				  ,dept_code --Added for Defect 36437 (MOD4B Release 3)
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
                  ,infocopy_tag
                  ,batch_source_id
				  ,c_ext_attr1)
               VALUES
                  (ln_prev_cons_bill_id
                  ,inv_ic_tab(i).customer_trx_id
                  ,inv_ic_tab(i).mbs_doc_id
                  ,ln_prev_cons_bill_id
                  ,inv_ic_tab(i).billdocs_delivery_method
                  ,decode(inv_ic_tab(i).document_type
                         ,'Y'
                         ,'Paydoc'
                         ,'N'
                         ,'Infocopy')
                  ,decode(inv_ic_tab(i).direct_flag
                         ,'Y'
                         ,'D'
                         ,'N'
                         ,'I')
                  ,inv_ic_tab(i).cust_doc_id
                  ,to_date(inv_ic_tab(i).bill_from_date) + 1
                  ,g_as_of_date
                  ,nvl(decode(inv_ic_tab(i).mail_to_attention
                             ,NULL
                             ,NULL
                             ,'ATTN: ' || inv_ic_tab(i).mail_to_attention)
                      ,'ATTN: ACCTS PAYABLE')
                  ,inv_ic_tab(i).invoice_number
                  ,lc_orgordnbr
                  ,inv_ic_tab(i).amount_due_original
                  ,inv_ic_tab(i).amount_due_remaining
                  ,inv_ic_tab(i).amount_due_original - (inv_ic_tab(i).total_us_tax_amount + inv_ic_tab(i).total_gst_amount + inv_ic_tab(i).total_pst_qst_tax)
                  ,DECODE((  inv_ic_tab(i).total_gst_amount +   inv_ic_tab(i).total_pst_qst_tax +   inv_ic_tab(i).total_us_tax_amount),0,0,ln_hdr_tax_rate)
                  ,lc_reason_code
                  ,g_as_of_date
                  ,DECODE(inv_ic_tab(i).billdocs_delivery_method
                         ,'eXLS',decode(inv_ic_tab(i).transaction_class,'CM',NULL,inv_ic_tab(i).due_date)
                         ,inv_ic_tab(i).due_date)
                  ,inv_ic_tab(i).currency
                  ,inv_ic_tab(i).order_date
                  ,inv_ic_tab(i).reconcile_date
                  ,inv_ic_tab(i).rct_header_id
                  ,inv_ic_tab(i).order_level_comment
                  ,inv_ic_tab(i).order_level_spc_comment
                  ,inv_ic_tab(i).order_type
                  ,inv_ic_tab(i).order_type_code
                  ,inv_ic_tab(i).order_source_code
                  ,inv_ic_tab(i).ordered_by
                  ,inv_ic_tab(i).payment_term
                  ,inv_ic_tab(i).payment_term_description
                  ,inv_ic_tab(i).payment_term_discount
                  ,xx_ar_ebl_common_util_pkg.get_discount_date(inv_ic_tab(i).customer_trx_id)
                  ,inv_ic_tab(i).payment_term_frequency
                  ,inv_ic_tab(i).payment_term_report_day
                  ,inv_ic_tab(i).billing_term
                  ,inv_ic_tab(i).total_bulk_amount
                  ,inv_ic_tab(i).total_coupon_amount
                  ,inv_ic_tab(i).total_bulk_amount + inv_ic_tab(i).total_tiered_discount_amount +inv_ic_tab(i).total_association_discount
                  ,inv_ic_tab(i).total_delivery_amount
                  ,inv_ic_tab(i).total_gift_card_amount
                  ,inv_ic_tab(i).total_gst_amount
                  ,inv_ic_tab(i).total_gst_amount + inv_ic_tab(i).total_pst_qst_tax
                  ,inv_ic_tab(i).total_miscellaneous_amount
                  ,inv_ic_tab(i).total_association_discount
                  ,inv_ic_tab(i).total_pst_amount
                  ,inv_ic_tab(i).total_qst_amount
                  ,inv_ic_tab(i).total_tiered_discount_amount
                  ,inv_ic_tab(i).total_us_tax_amount
                  ,inv_ic_tab(i).sku_lines_subtotal
                  ,lc_sales_person
                  ,inv_ic_tab(i).customer_id
                  ,inv_ic_tab(i).oracle_account_number
                  ,inv_ic_tab(i).customer_name
                  ,inv_ic_tab(i).aops_account_number
                  ,inv_ic_tab(i).cust_acct_site_id
                  ,inv_ic_tab(i).cust_site_sequence
                  ,inv_ic_tab(i).customer_ref_date --to fetch
                  ,inv_ic_tab(i).customer_ref_number
                  ,lc_sold_to_customer
                  ,inv_ic_tab(i).transaction_source
                  ,inv_ic_tab(i).transaction_type
                  ,decode(inv_ic_tab(i).transaction_class
                         ,'CM'
                         ,'Credit Memo'
			 ,'DM'
			 ,'Debit Memo'
                         ,'INV'
                         ,'Invoice')
                  ,inv_ic_tab(i).trx_date
                  ,inv_ic_tab(i).bill_to_name
                  ,inv_ic_tab(i).bill_to_address1
                  ,inv_ic_tab(i).bill_to_address2
                  ,inv_ic_tab(i).bill_to_address3
                  ,inv_ic_tab(i).bill_to_address4
                  ,inv_ic_tab(i).bill_to_city
                  ,decode(inv_ic_tab(i).bill_to_country
                         ,'US'
                         ,inv_ic_tab(i).bill_to_state
                         ,lc_province)
                  ,inv_ic_tab(i).bill_to_country
                  ,inv_ic_tab(i).bill_to_zip
                  ,inv_ic_tab(i).bill_to_contact_name
                  ,inv_ic_tab(i).bill_to_contact_phone
                  ,inv_ic_tab(i).bill_to_contact_phone_ext
                  ,inv_ic_tab(i).bill_to_contact_email
                  ,lc_location
                  ,inv_ic_tab(i).carrier
                  ,inv_ic_tab(i).ship_to_name
                  ,inv_ic_tab(i).ship_to_abbreviation
                  ,inv_ic_tab(i).ship_to_address1
                  ,inv_ic_tab(i).ship_to_address2
                  ,inv_ic_tab(i).ship_to_address3
                  ,inv_ic_tab(i).ship_to_address4
                  ,inv_ic_tab(i).ship_to_city
                  ,inv_ic_tab(i).ship_to_state
                  ,inv_ic_tab(i).ship_to_country
                  ,inv_ic_tab(i).ship_to_zip
                  ,inv_ic_tab(i).ship_to_sequence
                  ,inv_ic_tab(i).shipment_ref_number
                  ,inv_ic_tab(i).remit_address1
                  ,inv_ic_tab(i).remit_address2
                  ,inv_ic_tab(i).remit_address3
                  ,inv_ic_tab(i).remit_address4
                  ,inv_ic_tab(i).remit_city
                  ,inv_ic_tab(i).remit_state
                  ,inv_ic_tab(i).remit_zip
                  ,inv_ic_tab(i).remit_country
                  ,decode(lc_country
                         ,'US'
                         ,lc_tax_number
                         ,NULL)
                  ,decode(lc_country
                         ,'CA'
                         ,lc_tax_number
                         ,NULL)
                  ,upper(nvl(inv_ic_tab(i).cost_center_sft_hdr
                            ,'COST CENTER'))
                  , inv_ic_tab(i).cost_center_desc_hdr --defect 22582
                  --,upper(nvl(inv_ic_tab(i).cost_center_desc_hdr
                  --          ,'COST CENTER DESCRIPTION'))--defect 15118
				  , inv_ic_tab(i).cost_center_dept --Added for Defect 36437 (MOD4B Release 3)
                  ,upper(nvl(inv_ic_tab(i).po_number_sft_hdr
                            ,'PURCHASE ORDER'))
                  ,upper(nvl(inv_ic_tab(i).release_number_sft_hdr
                            ,'RELEASE'))
                  ,upper(nvl(inv_ic_tab(i).desktop_sft_hdr
                            ,'DESKTOP'))
                  ,inv_ic_tab(i).number_of_lines
                  ,fnd_global.user_id
                  ,SYSDATE
                  ,fnd_global.user_id
                  ,SYSDATE
                  ,fnd_global.login_id
                  ,p_batch_id
                  ,fnd_profile.VALUE('ORG_ID')
                  ,inv_ic_tab(i).bill_to_site_use_id
                  ,inv_ic_tab(i).parent_cust_doc_id
                  ,lc_epdf_doc_detail
                  ,ln_request_id
                  ,inv_ic_tab(i).invoice_number
                  ,inv_ic_tab(i).desktop_sft_data
                  ,inv_ic_tab(i).purchase_order
                  ,inv_ic_tab(i).cost_center_sft_data
                  ,inv_ic_tab(i).release_number_sft_data
                  ,lc_ph_no_cusrv
                  ,lc_ph_no_bill
                  ,inv_ic_tab(i).infocopy_tag
                  ,inv_ic_tab(i).batch_source_id
				  ,lc_bill_comp_flag);					-- Added By Dinesh For Separate Bill Test for Bill Complete and Non-BillComplete
               -- Calling Insert_lines
               gc_debug_msg := to_char(SYSDATE
                                      ,'DD-MON-YYYY HH24:MI:SS') || 'Insert Lines - INVIC - CONS ID:' || inv_ic_tab(i).cons_inv_id || 'TRX ID : ' || inv_ic_tab(i).customer_trx_id;
               xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                     ,FALSE
                                                     ,'    ' || gc_debug_msg);
               ln_trx_count := ln_trx_count+1;
               insert_lines(inv_ic_tab(i).customer_trx_id
                           ,inv_ic_tab(i).transaction_class
                           ,ln_prev_cons_bill_id
                           ,inv_ic_tab(i).cust_doc_id
                           ,inv_ic_tab(i).parent_cust_doc_id
                           ,inv_ic_tab(i).cost_center_sft_hdr
                           ,p_batch_id
                           ,ln_item_master_org
                           ,inv_ic_tab(i).order_source_code);
            EXCEPTION
               WHEN OTHERS THEN
                  lc_error_log := 'Error at : ' || gc_debug_msg || ' ' || SQLERRM;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,'       ' || '    ' || 'Error at :' || gc_debug_msg);
                  gc_debug_msg := to_char(SYSDATE
                                         ,'DD-MON-YYYY HH24:MI:SS') || 'When others exception  - INVIC - CONS ID:' || inv_ic_tab(i).cons_inv_id || ' TRX ID : ' || inv_ic_tab(i).customer_trx_id || ' Error :' || SQLERRM;
                  xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                                        ,FALSE
                                                        ,gc_debug_msg);
                  lc_process := 'N';
                  ROLLBACK TO inv_ic_insert;
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
                     ,last_updated_by
                     ,last_updated_date
                     ,created_by
                     ,creation_date
                     ,last_updated_login
                     ,as_of_date
                     ,error_message)
                  VALUES
                     (fnd_profile.VALUE('ORG_ID')
                     ,inv_ic_tab(i).parent_cust_doc_id
                     ,decode(inv_ic_tab(i).document_type
                            ,'Y'
                            ,'Paydoc'
                            ,'N'
                            ,'Infocopy')
                     ,inv_ic_tab(i).aops_account_number
                     ,inv_ic_tab(i).oracle_account_number
                     ,inv_ic_tab(i).billdocs_delivery_method
                     ,inv_ic_tab(i).billing_term
                     ,inv_ic_tab(i).cons_inv_id
                     ,inv_ic_tab(i).invoice_number
                     ,inv_ic_tab(i).customer_trx_id
                     ,fnd_global.user_id
                     ,SYSDATE
                     ,fnd_global.user_id
                     ,SYSDATE
                     ,fnd_global.login_id
                     ,g_as_of_date
                     ,lc_error_log);
                  retcode := 1;
            END;
         END IF;
      END LOOP; -- End of header Cursor for INV_IC
      xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                            ,FALSE
                                            ,to_char(SYSDATE
                                                    ,'DD-MON-YYYY HH24:MI:SS') ||CHR(13)
                                                    ||'Number of INV_IC transaction inserted : '||ln_trx_count);

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
         xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                               ,FALSE
                                               ,gc_debug_msg);
         gc_debug_msg := to_char(SYSDATE
                                ,'DD-MON-YYYY HH24:MI:SS') || 'When others exception' || ' Error :' || SQLERRM;
         xx_ar_ebl_common_util_pkg.put_log_line(p_debug
                                               ,FALSE
                                               ,gc_debug_msg);
   END extract_cons_data;
  -- +===================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- |                       WIPRO Technologies                                          |
  -- +===================================================================================+
  -- | Name        : insert_lines                                                        |
  -- | Description : Procedute to extract line level data                                |                                                              |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |DRAFT 1.0 11-MAR-2010  Ranjith Thangasamy      Initial draft version               |
  -- |1.1       08-DEC-2015  Havish Kasina           Added Cost Center Dept              |
  -- |                                               column(Module4B Release 3)          |
  -- |1.2       15-JUN-2016  Suresh Naragam          Added Line Level Tax Amount         |
  -- |                                               (Module 4B Release 4 Defect#2282)   |
  -- |1.3       23-JUN-2016  Havish Kasina           Kitting Changes Defect# 37675       |
  -- |1.4       20-AUG-2018  Aarthi                  Wave 5 - Adding TAX at SKU Level    |
  -- |                                               for NAIT - 58403                    |
  -- +===================================================================================+
   PROCEDURE insert_lines(p_cust_trx_id        IN NUMBER
                         ,p_trx_type           IN VARCHAR2
                         ,p_cons_inv_id        IN NUMBER
                         ,p_cust_doc_id        IN NUMBER
                         ,p_parent_cust_doc_id IN NUMBER
                         ,p_dept_code          IN VARCHAR2
                         ,p_batch_id           IN NUMBER
                         ,p_organization_id    IN NUMBER
                         ,p_order_source_code  IN VARCHAR2) IS
      CURSOR lcu_cons_lines IS
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
               ,XX_AR_EBL_COMMON_UTIL_PKG.get_fee_line_number(rctl1.customer_trx_id,rctl1.description,p_organization_id,rctl1.line_number) line_number  -- change 1.17
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
               ,xola.wholesaler_item wholesaler_item
               ,rctl1.interface_line_context interface_line_context
               ,rctl1.interface_line_attribute11 oe_price_adjustment_id
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
               --,xola.taxable_flag                      --Commented for Defect #7025
               ,NULL  taxable_flag                       --Added for Defect #7025
               ,xola.gsa_flag
               ,NVL(rctl1.translated_description,msi.segment1) productcdentered --Changed by Atul -- As per JIRA NAIT-63607  --rctl1.translated_description  productcdentered
               ,TRIM(xola.cust_dept_description) dept_description
               ,TRIM(xola.cost_center_dept) cost_center_dept -- Added for Defect 36437 (MOD4B Release 3)
			   ,rctl1.attribute3                 -- Added for Kitting, Defect# 37675
			   ,rctl1.attribute4                 -- Added for Kitting, Defect# 37675
			   ,rctl1.warehouse_id whse_id       -- Added for Kitting, Defect# 37675
			   ,nvl(xola.tax_amount,0) tax_amount-- Added for SKU level Tax changes NAIT 58403
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
		 AND    DECODE(rctl1.attribute3,'K',DECODE(rctl1.attribute5,'Y','1','2'),'1') = '1' -- Added for Kitting, Defect# 37675
         AND    NOT EXISTS (SELECT 1
                 FROM   oe_price_adjustments oea
                       ,fnd_lookup_values   flv
                 WHERE  oea.price_adjustment_id = nvl(rctl1.interface_line_attribute11
                                                     ,0)
                 AND    oea.attribute8 = flv.lookup_code
                 AND    flv.lookup_type = 'OD_DISCOUNT_ITEMS'
                 AND    flv.meaning IN ('Tiered Discount', 'Association Discount'))
         AND    rctl1.line_type = 'LINE'
		 ORDER BY XX_AR_EBL_COMMON_UTIL_PKG.get_fee_line_number(rctl1.customer_trx_id,rctl1.description,null,rctl1.line_number);
      TYPE cbi_lines_tab IS TABLE OF lcu_cons_lines%ROWTYPE INDEX BY BINARY_INTEGER;
      cbi_line        cbi_lines_tab;
      lc_gsa_comments VARCHAR2(1000);
      lc_line_type    VARCHAR2(1000);
      ln_seq_number   NUMBER :=0;
      ln_dummy        NUMBER :=0;
      ln_line_tax_amt NUMBER :=0;
	  ln_kit_extended_amt   NUMBER;          -- Added for Kitting, Defect# 37675
	  ln_kit_unit_price     NUMBER;          -- Added for Kitting, Defect# 37675
	  lc_kit_sku_desc       VARCHAR2(240);   -- Added for Kitting, Defect# 37675
      lv_dept_type          VARCHAR2(240);   -- Added for 1.17
   BEGIN
      -- Open Detail Cursor
      OPEN lcu_cons_lines;
      FETCH lcu_cons_lines BULK COLLECT
         INTO cbi_line;
      --    lc_error_loc   :='Inside lcu_cons_lines cursor' ;
      --    lc_error_debug := NULL;
      FOR j IN 1 .. cbi_line.COUNT
      LOOP
         -- Inserting into the header table only if it is a line item:
         lc_gsa_comments := xx_ar_ebl_common_util_pkg.gsa_comments(cbi_line(j).gsa_flag);
         IF (cbi_line(j).oe_price_adjustment_id > 0) THEN
            SELECT oea.attribute8
            INTO   lc_line_type
            FROM   oe_price_adjustments oea
            WHERE  oea.price_adjustment_id = nvl(cbi_line(j).oe_price_adjustment_id
                                                ,0);
         ELSE

               SELECT count(attribute6)
               INTO   ln_dummy
               FROM   fnd_lookup_values
               WHERE  lookup_type = 'OD_FEES_ITEMS'
               AND    attribute7 = 'DELIVERY'
               AND    nvl(attribute6
                         ,0) = cbi_line(j).inventory_item_id;
               IF ln_dummy <> 0 THEN
               lc_line_type  := 'DELIVERY';
               ln_seq_number := ln_seq_number + 1;
               ELSE
               lc_line_type  := 'ITEM';
               ln_seq_number := ln_seq_number + 1;
               END IF;

         END IF;

         BEGIN
           SELECT NVL(SUM(rctl.extended_amount),0)
           INTO ln_line_tax_amt
           FROM  ra_customer_trx_lines_all rctl
           WHERE rctl.customer_trx_id = p_cust_trx_id
           AND rctl.link_to_cust_trx_line_id = cbi_line(j).customer_trx_line_id
           AND rctl.line_type = 'TAX';
         EXCEPTION WHEN NO_DATA_FOUND THEN
           ln_line_tax_amt := 0;
         WHEN OTHERS THEN
           ln_line_tax_amt := 0;
         END;

		-- Added for Kitting, Defect# 37675
		 IF cbi_line(j).attribute3 = 'K'
			THEN
				 ln_kit_extended_amt := NULL;
				 ln_kit_unit_price   := NULL;
				 XX_AR_EBL_COMMON_UTIL_PKG.get_kit_extended_amount( p_customer_trx_id      => cbi_line(j).customer_trx_id,
																	p_sales_order_line_id  => cbi_line(j).order_line_id,
																	p_kit_quantity         => cbi_line(j).quantity_shipped,
																	x_kit_extended_amt     => ln_kit_extended_amt,
																	x_kit_unit_price       => ln_kit_unit_price
																  );

				 cbi_line(j).unit_price         := ln_kit_unit_price;
				 cbi_line(j).extended_amount    := ln_kit_extended_amt;
		 END IF;

		 lc_kit_sku_desc := NULL;
		 IF cbi_line(j).attribute4 IS NOT NULL AND cbi_line(j).attribute3 = 'D'
		    THEN
			  BEGIN
				SELECT TRIM(description)
				  INTO lc_kit_sku_desc
				  FROM mtl_system_items_b
				 WHERE segment1 = cbi_line(j).attribute4
				   AND organization_id = NVL(cbi_line(j).whse_id,p_organization_id)
				   ;
			  EXCEPTION
				WHEN OTHERS
				THEN
				  lc_kit_sku_desc := NULL;
			  END;
	     END IF;
   -- End of Kitting Changes, Defect# 37675

         -- Added code change for 1.17
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
         -- End code change for 1.17
         
         INSERT INTO xx_ar_ebl_cons_dtl_main
            (cons_inv_id
            ,customer_trx_id
            ,cust_doc_id
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
            ,line_level_comment
            ,interface_line_context
            ,price_adjustment_id
            ,last_updated_by
            ,last_updated_date
            ,created_by
            ,creation_date
            ,last_updated_login
            ,extract_batch_id
            ,org_id
            ,request_id
            ,dept_desc
            ,dept_sft_hdr
            ,dept_code -- Added for Defect 36437 (MOD4B Release 3)
            ,line_tax_amt
			,kit_sku   -- Added for Kitting, Defect# 37675
			,kit_sku_desc  -- Added for Kitting, Defect# 37675
            ,parent_cust_doc_id
			,sku_level_tax   -- Added for SKU level Tax changes NAIT 58403
			,sku_level_total -- Added for SKU level Tax changes NAIT 58403
			)
         VALUES
            (p_cons_inv_id
            ,p_cust_trx_id
            ,p_cust_doc_id
            ,cbi_line(j).customer_trx_line_id
            ,cbi_line(j).line_number
            ,lc_line_type
            ,cbi_line(j).item_description
            ,cbi_line(j).inventory_item_id
            ,cbi_line(j).inventory_item_number
            ,cbi_line(j).translated_description
            ,cbi_line(j).order_line_id
            ,cbi_line(j).po_line_number
            ,cbi_line(j).quantity_back_ordered
            ,cbi_line(j).quantity_credited
            ,cbi_line(j).quantity_invoiced
            ,cbi_line(j).quantity_ordered
            ,cbi_line(j).quantity_shipped
            ,cbi_line(j).unit_of_measure
            ,cbi_line(j).unit_price
            ,cbi_line(j).extended_amount
            ,cbi_line(j).contract_plan_id
            ,cbi_line(j).contract_seq_number
            ,cbi_line(j).productcdentered
            ,cbi_line(j).vendor_product_code
            ,cbi_line(j).cust_product_code
            ,NULL
            ,ln_seq_number
            ,NULL
            ,cbi_line(j).wholesaler_item
            ,cbi_line(j).taxable_flag
            ,lc_gsa_comments
            ,(CASE WHEN( p_order_source_code IN ('B','E','X')) THEN cbi_line(j).line_level_comment ELSE NULL END)
            ,cbi_line(j).interface_line_context
            ,cbi_line(j).oe_price_adjustment_id
            ,fnd_global.user_id
            ,SYSDATE
            ,fnd_global.user_id
            ,SYSDATE
            ,fnd_global.login_id
            ,p_batch_id
            ,fnd_profile.VALUE('ORG_ID')
            ,NULL
            ,DECODE (lv_dept_type,'LINE',cbi_line(j).dept_description)  -- decode added for 1.17
            ,decode(cbi_line(j).dept_description
                   ,NULL
                   ,NULL
                   ,nvl(p_dept_code
                       ,'Department'))
            ,cbi_line(j).cost_center_dept -- Added for Defect 36437 (MOD4B Release 3)
            ,ln_line_tax_amt
			,cbi_line(j).attribute4 -- Added for Kitting, Defect# 37675
			, lc_kit_sku_desc    -- Added for Kitting, Defect# 37675
            ,p_parent_cust_doc_id
			,cbi_line(j).tax_amount                                        -- Added for SKU level Tax changes NAIT 58403
			,nvl(cbi_line(j).tax_amount+ cbi_line(j).extended_amount,0)    -- Added for SKU level Tax changes NAIT 58403
			);
      END LOOP; -- End of Line cursor
   EXCEPTION
      WHEN OTHERS THEN
         xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                               ,TRUE
                                               ,to_char(SYSDATE
                                                       ,'DD-MON-YYYY HH24:MI:SS') || 'eRROR IN INSERT lINE ' || SQLERRM);
         CLOSE lcu_cons_lines;
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
   -- |DRAFT 1.0 11-MAR-2010  Ranjith Thangasamy   Initial draft version  |
   -- +===================================================================+
   PROCEDURE populate_trans_details(p_batch_id NUMBER) IS
     CURSOR lcu_cust_doc_ids IS
        SELECT DISTINCT hdr.parent_cust_doc_id
                       ,hdr.billdocs_delivery_method
                       ,xcem.ebill_transmission_type
                       ,xcem.file_processing_method
                       ,hdr.direct_flag
        FROM   xx_ar_ebl_cons_hdr_main hdr
              ,xx_cdh_ebl_main         xcem
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
           lc_email_address       := NULL;
           ln_file_id             := 0;
           ln_transmission_id     := 0;
           lc_file_split_criteria := NULL;
           lc_split_value         := NULL;

           IF (cust_doc_id_rec.billdocs_delivery_method = 'ePDF') THEN   --delivery method
              IF (cust_doc_id_rec.file_processing_method = '01') THEN
                 FOR cons_ids IN (SELECT DISTINCT cons_inv_id
                                  FROM   xx_ar_ebl_cons_hdr_main
                                  WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                  AND    extract_batch_id = p_batch_id)
                 LOOP
                    SELECT xx_ebl_file_seq.NEXTVAL
                    INTO   ln_file_id
                    FROM   dual;
                    SELECT xx_ebl_trans_seq.NEXTVAL
                    INTO   ln_transmission_id
                    FROM   dual;

                    UPDATE xx_ar_ebl_cons_hdr_main
                    SET    file_id         = ln_file_id
                          ,transmission_id = ln_transmission_id
                    WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                    AND    extract_batch_id = p_batch_id
                    AND    cons_inv_id = cons_ids.cons_inv_id;
                 END LOOP;

                 IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
                    FOR trx_rec IN (SELECT DISTINCT cust_acct_site_id
                                    FROM   xx_ar_ebl_cons_hdr_main
                                    WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                    AND    extract_batch_id = p_batch_id)
                    LOOP
                       lc_email_address := xx_ar_ebl_common_util_pkg.get_email_details(cust_doc_id_rec.parent_cust_doc_id
                                                                                      ,trx_rec.cust_acct_site_id);
                       UPDATE xx_ar_ebl_cons_hdr_main hdr
                       SET    email_address = nvl(lc_email_address
                                                 ,lc_null_loc_email)
                       WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                       AND    hdr.cust_acct_site_id = trx_rec.cust_acct_site_id
                       AND    extract_batch_id = p_batch_id;
                    END LOOP;
                 END IF;
              ELSIF (cust_doc_id_rec.file_processing_method = '02') THEN
                 /*   IF (cust_doc_id_rec.ebill_transmission_type <> 'EMAIL') THEN
                    SELECT xx_ebl_trans_seq.NEXTVAL
                    INTO   ln_transmission_id
                    FROM   dual;
                 END IF;*/
                 -- Update one trx with one file id
                 FOR cons_ids IN (SELECT DISTINCT cons_inv_id
                                  FROM   xx_ar_ebl_cons_hdr_main
                                  WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                  AND    extract_batch_id = p_batch_id)
                 LOOP
                    SELECT xx_ebl_file_seq.NEXTVAL
                    INTO   ln_file_id
                    FROM   dual;

                    UPDATE xx_ar_ebl_cons_hdr_main
                    SET    file_id = ln_file_id
                    WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                    AND    extract_batch_id = p_batch_id
                    AND    cons_inv_id = cons_ids.cons_inv_id;
                 END LOOP;
                 -- Update email address

                 IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
                    FOR trx_rec IN (SELECT DISTINCT cust_acct_site_id -- **
                                    FROM   xx_ar_ebl_cons_hdr_main
                                    WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                    AND    extract_batch_id = p_batch_id)
                    LOOP
                       lc_email_address := xx_ar_ebl_common_util_pkg.get_email_details(cust_doc_id_rec.parent_cust_doc_id
                                                                                      ,trx_rec.cust_acct_site_id);
                       UPDATE xx_ar_ebl_cons_hdr_main hdr
                       SET    email_address = nvl(lc_email_address
                                                 ,lc_null_loc_email)
                       WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                       AND    hdr.cust_acct_site_id = trx_rec.cust_acct_site_id
                       AND    extract_batch_id = p_batch_id;
                    END LOOP;
                 END IF;
                 --- For every distinct email address list update one Transmission
                 FOR email_ids_rec IN (SELECT DISTINCT email_address
                                       FROM   xx_ar_ebl_cons_hdr_main
                                       WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                       AND    extract_batch_id = p_batch_id)
                 LOOP
                    -- IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
                    SELECT xx_ebl_trans_seq.NEXTVAL
                    INTO   ln_transmission_id
                    FROM   dual;
                    --  END IF;
                    UPDATE xx_ar_ebl_cons_hdr_main
                    SET    transmission_id = ln_transmission_id
                    WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                    AND    nvl(email_address
                              ,'XX') = nvl(email_ids_rec.email_address
                                           ,'XX')
                    AND    extract_batch_id = p_batch_id;
                 END LOOP;
              ELSIF (cust_doc_id_rec.file_processing_method = '03') THEN
                 /*     IF (cust_doc_id_rec.ebill_transmission_type <> 'EMAIL') THEN
                    SELECT xx_ebl_file_seq.NEXTVAL
                    INTO   ln_file_id
                    FROM   dual;
                    SELECT xx_ebl_trans_seq.NEXTVAL
                    INTO   ln_transmission_id
                    FROM   dual;
                 END IF;*/
                 IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
                    FOR trx_rec IN (SELECT DISTINCT cust_acct_site_id --**
                                    FROM   xx_ar_ebl_cons_hdr_main
                                    WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                    AND    extract_batch_id = p_batch_id)
                    LOOP

                       lc_email_address := xx_ar_ebl_common_util_pkg.get_email_details(cust_doc_id_rec.parent_cust_doc_id
                                                                                      ,trx_rec.cust_acct_site_id);
                       --  END IF;
                       /*       SELECT xx_ebl_file_seq.NEXTVAL
                       INTO   ln_file_id
                       FROM   dual;*/

                       UPDATE xx_ar_ebl_cons_hdr_main hdr
                       SET    email_address = nvl(lc_email_address
                                                 ,lc_null_loc_email)
                       WHERE  hdr.cust_acct_site_id = trx_rec.cust_acct_site_id
                       AND    extract_batch_id = p_batch_id
                       AND    parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id;
                    END LOOP;
                 END IF;

				 -- Added For Bill Complete Loop By Dinesh For Separate Bill Test for Bill Complete and Non-BillComplete
                 FOR file_ids_rec IN (SELECT --- DISTINCT DISTINCT file_id
                                      DISTINCT email_address
                                              ,decode(cust_doc_id_rec.direct_flag
                                                     ,'I'
                                                     ,cust_acct_site_id
                                                     ,NULL) cust_acct_site_id
													 ,cons_inv_id		--NAIT-61963 Added cons_inv_id to print separate bills for consolidated bill.
                                      FROM   xx_ar_ebl_cons_hdr_main
                                      WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
									  AND 	 c_ext_attr1 ='Y'
                                      AND    extract_batch_id = p_batch_id)
                 LOOP
                    --      IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
                    SELECT xx_ebl_file_seq.NEXTVAL
                    INTO   ln_file_id
                    FROM   dual;
                    --      END IF;

                    UPDATE xx_ar_ebl_cons_hdr_main
                    SET    file_id = ln_file_id -- added
                    WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                    AND    nvl(email_address
                              ,'X') = nvl(file_ids_rec.email_address
                                          ,'X')
                    AND    cust_acct_site_id = nvl(file_ids_rec.cust_acct_site_id
                                                  ,cust_acct_site_id)
    				AND    cons_inv_id		= file_ids_rec.cons_inv_id				--NAIT-61963 Added cons_inv_id to print separate bills for consolidated bill.
                    AND    extract_batch_id = p_batch_id;
                 END LOOP;
				    FOR file_ids_rec IN (SELECT --- DISTINCT DISTINCT file_id
                                      DISTINCT email_address
                                              ,decode(cust_doc_id_rec.direct_flag
                                                     ,'I'
                                                     ,cust_acct_site_id
                                                     ,NULL) cust_acct_site_id
		                              FROM   xx_ar_ebl_cons_hdr_main
                                      WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
									  AND 	 c_ext_attr1 IS NULL			-- Added By Dinesh For Separate Bill Test for Bill Complete and Non-BillComplete
                                      AND    extract_batch_id = p_batch_id)
                 LOOP
                    --      IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
                    SELECT xx_ebl_file_seq.NEXTVAL
                    INTO   ln_file_id
                    FROM   dual;
                    --      END IF;

                    UPDATE xx_ar_ebl_cons_hdr_main
                    SET    file_id = ln_file_id -- added
                    WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                    AND    nvl(email_address,'X') = nvl(file_ids_rec.email_address,'X')
                    AND    cust_acct_site_id = nvl(file_ids_rec.cust_acct_site_id,cust_acct_site_id)
    	            AND    extract_batch_id = p_batch_id;
                 END LOOP;

                 FOR trans_ids_rec IN (SELECT DISTINCT file_id
                                       FROM   xx_ar_ebl_cons_hdr_main
                                       WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                       AND    extract_batch_id = p_batch_id)
                 LOOP
                    --      IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
                    SELECT xx_ebl_trans_seq.NEXTVAL
                    INTO   ln_transmission_id
                    FROM   dual;
                    --      END IF;

                    UPDATE xx_ar_ebl_cons_hdr_main
                    SET    transmission_id = ln_transmission_id
                    --      , file_id = ln_file_id -- added
                    WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                    AND   file_id = trans_ids_rec.file_id
                    AND    extract_batch_id = p_batch_id;
                 END LOOP;
              END IF;
           ELSE   -- non 'PDF'
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
                    UPDATE xx_ar_ebl_cons_hdr_main hdr
                    SET    split_identifier = (CASE WHEN(amount_due_remaining < 0) THEN 'CR' ELSE 'DR' END)
                    WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                    AND    extract_batch_id = p_batch_id;
                 ELSIF lc_file_split_criteria = 'PONPO' THEN
                    UPDATE xx_ar_ebl_cons_hdr_main hdr
                    SET    split_identifier = (CASE WHEN(po_number_sft_data IS NOT NULL) THEN 'PO' ELSE 'NPO' END)
                    WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                    AND    extract_batch_id = p_batch_id;
                 ELSIF lc_file_split_criteria = 'INVAMTABS' THEN
                    UPDATE xx_ar_ebl_cons_hdr_main hdr
                    SET    split_identifier = (CASE WHEN(abs(amount_due_remaining) < lc_split_value) THEN 'UNDER' ELSE 'OVER' END)
                    WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                    AND    extract_batch_id = p_batch_id;
                 ELSIF lc_file_split_criteria = 'INVAMT' THEN
                    UPDATE xx_ar_ebl_cons_hdr_main hdr
                    SET    split_identifier = (CASE WHEN(amount_due_remaining) < lc_split_value THEN 'UNDER' ELSE 'OVER' END)
                    WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                    AND    extract_batch_id = p_batch_id;
                 ELSE
                    UPDATE xx_ar_ebl_cons_hdr_main hdr
                    SET    split_identifier = 'NA'
                    WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                    AND    extract_batch_id = p_batch_id;
                 END IF;
              END IF;
              IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN

                 --- UPDATE EMAIL ADDRESS for each site
                 FOR trx_rec IN (SELECT DISTINCT cust_acct_site_id
                                 FROM   xx_ar_ebl_cons_hdr_main
                                 WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                                 AND    extract_batch_id = p_batch_id)
                 LOOP
                    lc_email_address := xx_ar_ebl_common_util_pkg.get_email_details(cust_doc_id_rec.parent_cust_doc_id
                                                                                   ,trx_rec.cust_acct_site_id);
                    UPDATE xx_ar_ebl_cons_hdr_main hdr
                    SET    email_address = nvl(lc_email_address
                                              ,lc_null_loc_email)
                    WHERE  hdr.parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
                    AND    hdr.cust_acct_site_id = trx_rec.cust_acct_site_id
                    AND    extract_batch_id = p_batch_id;
                 END LOOP;
              END IF;
			-- Added for BillCoplete Loop,by Dinesh For Separate Bill Test for Bill Complete and Non-BillComplete
			FOR file_ids IN (SELECT DISTINCT split_identifier
										  ,email_address
										  ,decode(cust_doc_id_rec.direct_flag
												 ,'I'
												 ,cust_acct_site_id
												 ,NULL) cust_acct_site_id
												 , cons_inv_id  -- Added for Bill complete to get consolidated bills NAIT-61963
						   FROM   xx_ar_ebl_cons_hdr_main
						   WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
						   AND    c_ext_attr1 ='Y'
						   AND    extract_batch_id = p_batch_id)
		  LOOP
			 SELECT xx_ebl_file_seq.NEXTVAL
			 INTO   ln_file_id
			 FROM   dual;

			 UPDATE xx_ar_ebl_cons_hdr_main
			 SET    file_id = ln_file_id
			 WHERE  nvl(split_identifier
					   ,'XX') = nvl(file_ids.split_identifier
								   ,'XX')
			 AND    nvl(email_address
					   ,'XX') = nvl(file_ids.email_address
									,'XX')
			 AND    cust_acct_site_id = nvl(file_ids.cust_acct_site_id
										   ,cust_acct_site_id)
			 AND    parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
			 AND    cons_inv_id = file_ids.cons_inv_id  -- Added for Bill complete to get consolidated bills NAIT-61963
			 AND    extract_batch_id = p_batch_id;
			 END LOOP;
              FOR file_ids IN (SELECT DISTINCT split_identifier
                                              ,email_address
                                              ,decode(cust_doc_id_rec.direct_flag
                                                     ,'I'
                                                     ,cust_acct_site_id
                                                     ,NULL) cust_acct_site_id
		                       FROM   xx_ar_ebl_cons_hdr_main
                               WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
							   AND    c_ext_attr1 IS NULL				-- Added By Dinesh For Separate Bill Test for Bill Complete and Non-BillComplete
                               AND    extract_batch_id = p_batch_id)
              LOOP
                 SELECT xx_ebl_file_seq.NEXTVAL
                 INTO   ln_file_id
                 FROM   dual;

                 UPDATE xx_ar_ebl_cons_hdr_main
                 SET    file_id = ln_file_id
                 WHERE  nvl(split_identifier
                           ,'XX') = nvl(file_ids.split_identifier
                                       ,'XX')
                 AND    nvl(email_address
                           ,'XX') = nvl(file_ids.email_address
                                        ,'XX')
                 AND    cust_acct_site_id = nvl(file_ids.cust_acct_site_id
                                               ,cust_acct_site_id)
                 AND    parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
	             AND    extract_batch_id = p_batch_id;
                 END LOOP;
				 --Added for BillCoplete Loop,By Dinesh For Separate Bill Test for Bill Complete and Non-BillComplete
				 FOR trans_ids_rec IN (SELECT --- DISTINCT DISTINCT file_id
                                       DISTINCT email_address
									   		   ,cons_inv_id  -- Added for Bill complete to get consolidated bills NAIT-61963
                                       FROM   xx_ar_ebl_cons_hdr_main
                                       WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
									   AND    c_ext_attr1 ='Y'
                                       AND    extract_batch_id = p_batch_id)
                 LOOP
                    --      IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
                    SELECT xx_ebl_trans_seq.NEXTVAL
                    INTO   ln_transmission_id
                    FROM   dual;
                    --      END IF;

                    UPDATE xx_ar_ebl_cons_hdr_main
                    SET    transmission_id = ln_transmission_id
                    --      , file_id = ln_file_id -- added
                    WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
					AND    cons_inv_id = trans_ids_rec.cons_inv_id  -- Added for Bill complete to get consolidated bills NAIT-61963
                    AND    nvl(email_address
                              ,'X') = nvl(trans_ids_rec.email_address
                                          ,'X')
                    AND    extract_batch_id = p_batch_id;
                 END LOOP;

                 FOR trans_ids_rec IN (SELECT --- DISTINCT DISTINCT file_id
                                       DISTINCT email_address
								       FROM   xx_ar_ebl_cons_hdr_main
                                       WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
									   AND    c_ext_attr1 IS NULL								 --Added by Dinesh For Separate Bill Test for Bill Complete and Non-BillComplete
                                       AND    extract_batch_id = p_batch_id)
                 LOOP
                    --      IF (cust_doc_id_rec.ebill_transmission_type = 'EMAIL') THEN
                    SELECT xx_ebl_trans_seq.NEXTVAL
                    INTO   ln_transmission_id
                    FROM   dual;
                    --      END IF;

                    UPDATE xx_ar_ebl_cons_hdr_main
                    SET    transmission_id = ln_transmission_id
                    --      , file_id = ln_file_id -- added
                    WHERE  parent_cust_doc_id = cust_doc_id_rec.parent_cust_doc_id
			        AND    nvl(email_address
                              ,'X') = nvl(trans_ids_rec.email_address
                                          ,'X')
                    AND    extract_batch_id = p_batch_id;
                 END LOOP;
              END IF; -- delivery method
           END LOOP; --cust_doc_id_rec
        EXCEPTION
     WHEN
     OTHERS THEN xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                                       ,TRUE
                                                       ,'Error in POPULATE_TRANS_DETAILS : ' || SQLERRM);
  END;
  END populate_trans_details;
   -- +===================================================================================+
   -- |                  Office Depot - Project Simplify                                  |
   -- |                       WIPRO Technologies                                          |
   -- +===================================================================================+
   -- | Name        : INSERT_TRANSMISSION_DETAILS                                         |
   -- | Description : Program to update transmission and file name                        |
   -- |Parameters   :                                                                     |
   -- |                                                                                   |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version   Date          Author                 Remarks                             |
   -- |=======   ==========   =============           ====================================|
   -- |DRAFT 1.0              Ranjith Prabu           Initial draft version               |
   -- |1.1       22-Jun-2015  Suresh Naragam          Done Changes to get the additional  |
   -- |                                               Columns data (Module 4B Release 1)  |
   -- |1.2       17-Aug-2015  Suresh Naragam          Added bill to location column       |
   -- |                                               (Module 4B Release 2)               |
   -- |1.3       14-MAR-2016  Suresh Naragam          Changes related to  MOD 4B Release4 |
   -- |1.4       28-Feb-2018  Aniket Jadhav CG        Wave 3 UAT Defect NAIT-29918        |
   -- |1.5       04-Sep-2018  Thilak CG               Added for the defect NAIT-27146     |
   -- |                                               Indirect merge docs transmission    |
   -- |1.6       24-Jan-2019  Thilak CG               Added consolidated_bill_number in   |
   -- |                                               Remit file_name for DefectNAIT-70500|
   -- +===================================================================================+
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
                         --, hdr.cust_acct_site_id
                        ,MIN(hdr.bill_from_date) bill_from_date
                        ,MAX(hdr.bill_to_date) bill_to_date
                        ,MAX(hdr.bill_due_date) bill_due_date
                        ,hdr.payment_term_description payment_term
         FROM   xx_ar_ebl_cons_hdr_main hdr
               ,xx_cdh_ebl_main         xcem
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

      ld_due_date       DATE := NULL;
      ln_total_due      NUMBER := 0;
      ln_file_id        NUMBER := 0;
      lc_file_name      xx_ar_ebl_cons_hdr_main.file_name%TYPE := NULL;
      ln_site_use_id    NUMBER := 0;
	  ln_cust_acct_site_id NUMBER := 0;
      lc_stub_suffix    VARCHAR2(50) := NULL;
      gc_debug_msg      VARCHAR2(1000);
      lc_account_number hz_cust_Accounts_all.account_number%TYPE;
      lc_aops_acct_number hz_cust_Accounts_all.orig_system_reference%TYPE;
      lc_customer_name  hz_parties.party_name%TYPE;
      ln_cons_inv_id    NUMBER := NULL;
      lc_payment_terms  VARCHAR2(250) := NULL;
      ld_payment_term_disc_date DATE := NULL;
      ln_total_merchandise_amt  NUMBER := 0;
      ln_total_misc_amt         NUMBER := 0;
      ln_total_gift_card_amt    NUMBER := 0;
      ln_total_salestax_amt NUMBER := 0;
   BEGIN
      BEGIN
             SELECT XFTV.TARGET_value1
             INTO   lc_stub_suffix
             FROM   xx_fin_translatedefinition XFTD
                   ,xx_fin_translatevalues     XFTV
             WHERE  XFTD.translate_id       = XFTV.translate_id
             AND    XFTD.translation_name   = 'XX_EBL_COMMON_TRANS'
             AND    XFTV.source_value1      = 'REMIT_SUFFIX'
             AND    SYSDATE                 BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
             AND    SYSDATE                 BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
             AND    XFTV.enabled_flag       = 'Y'
             AND    XFTD.enabled_flag       = 'Y';
      EXCEPTION
          WHEN OTHERS THEN
             lc_stub_suffix := '_REMIT';
      END;
      FOR trans_id IN trans_details
      LOOP
         BEGIN
            SAVEPOINT trans_insert;
            ln_file_id   := 0;
            lc_file_name := NULL;
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

            BEGIN
               gc_debug_msg := 'Fetching site_use_id and cust_acct_site_id for transmission_id = ' || trans_id.transmission_id;
               SELECT DISTINCT bill_to_site_use_id, cust_acct_site_id --Added cust_acct_site_id for Defect#NAIT-27146 by Thilak CG on 04-SEP-2018
               INTO   ln_site_use_id, ln_cust_acct_site_id
               FROM   xx_ar_ebl_cons_hdr_main hdr
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
                             FROM   xx_ar_ebl_cons_hdr_main
                             WHERE  parent_cust_doc_id = trans_id.parent_cust_doc_id
                             AND    transmission_id = trans_id.transmission_id
                             AND    extract_batch_id = p_batch_id)
            LOOP
               gc_debug_msg := 'File records feched for = ' || trans_id.transmission_id || ' File ID =;' || file_rec.file_id || ' and parent doc ID = ' || trans_id.parent_cust_doc_id;
               ln_total_due := 0;
               ld_due_date  := NULL;
               lc_payment_terms := NULL;
               ld_payment_term_disc_date := NULL;
               ln_total_merchandise_amt := 0;
               ln_total_misc_amt := 0;
               ln_total_gift_card_amt := 0;
               ln_total_salestax_amt := 0;
               BEGIN
                  SELECT SUM(original_invoice_amount-total_gift_card_amount),
                    SUM(gross_sale_amount - total_coupon_amount - total_freight_amount - total_discount_amount),
                    SUM(total_coupon_amount + total_freight_amount + total_discount_amount),
                    SUM(total_gift_card_amount),
                    SUM(total_gst_amount + total_pst_amount + total_us_tax_amount) --Module 4B Release 1
                  INTO   ln_total_due,
                    ln_total_merchandise_amt,
                    ln_total_misc_amt,
                    ln_total_gift_card_amt,
                    ln_total_salestax_amt  --Module 4B Release 1
                  FROM   xx_ar_ebl_cons_hdr_main hdr
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
                         MAX(payment_term_discount_date) --Module 4B Release 1
                  INTO   ld_due_date,
                         ld_payment_term_disc_date       --Module 4B Release 1
                  FROM   xx_ar_ebl_cons_hdr_main hdr
                  WHERE  hdr.file_id = file_rec.file_id;
               EXCEPTION
                  WHEN OTHERS THEN
                     ld_due_date := NULL;
                     ld_payment_term_disc_date := NULL;
               END;
               gc_debug_msg := 'Getting cons Bill Number';
               BEGIN
                  SELECT DISTINCT consolidated_bill_number, 				--NAIT-61963
                         payment_term  --Module 4B Release 1
                  INTO   ln_cons_inv_id,
                         lc_payment_terms  --Module 4B Release 1
                  FROM   xx_ar_ebl_cons_hdr_main hdr
                  WHERE  hdr.file_id = file_rec.file_id;
               EXCEPTION
                  WHEN TOO_MANY_ROWS THEN
                     ln_cons_inv_id := NULL;
                     lc_payment_terms := NULL;
               END;
               gc_debug_msg := 'Insert into FILE tables for transmission_id = ' || trans_id.transmission_id || ' File ID =;' || file_rec.file_id;

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
                  ,cust_account_id
                  ,org_id
                  ,created_by
                  ,creation_date
                  ,last_updated_by
                  ,last_update_date
                  ,last_update_login
                  ,billing_dt
                  ,cons_billing_number
                  ,payment_terms            --Module 4B Release 1
                  ,discount_due_date        --Module 4B Release 1
                  ,total_merchandise_amt    --Module 4B Release 1
                  ,total_sales_tax_amt      --Module 4B Release 1
                  ,total_misc_amt           --Module 4B Release 1
                  ,total_gift_card_amt      --Module 4B Release 1
                  )
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
                         --,'RENDER'
                         ,'MANIP_READY')
                  ,ln_total_due
                  ,decode(trans_id.document_type
                         ,'Paydoc'
                         ,'ORIGINAL CONSOLIDATED BILL'
                         ,'Infocopy'
                         ,'INFORMATIONAL COPY OF CONSOLIDATED BILL')
                  ,ld_due_date
                  ,file_rec.account_number
                  ,file_rec.aops_account_number
                  ,trans_id.parent_cust_doc_id
                  ,xx_ar_ebl_common_util_pkg.get_billing_associate_name(trans_id.ebill_associate)
                  ,decode(trans_id.document_type
                         ,'Paydoc'
                         ,'Y'
                         ,'N')
                  ,'CONS'
                  ,xx_ar_ebl_common_util_pkg.get_extract_status(g_as_of_date
                                                               ,trans_id.parent_cust_doc_id)
                  ,file_rec.customer_name
                  ,file_rec.customer_id
                  ,gn_org_id
                  ,fnd_global.user_id
                  ,SYSDATE
                  ,fnd_global.user_id
                  ,SYSDATE
                  ,fnd_global.login_id
                  ,g_as_of_date
                  ,ln_cons_inv_id
                  ,lc_payment_terms             --Module 4B Release 1
                  ,ld_payment_term_disc_date    --Module 4B Release 1
                  ,ln_total_merchandise_amt     --Module 4B Release 1
                  ,ln_total_salestax_amt        --Module 4B Release 1
                  ,ln_total_misc_amt            --Module 4B Release 1
                  ,(-1) * ln_total_gift_card_amt);  --Module 4B Release 1
               UPDATE xx_ar_ebl_cons_hdr_main
               SET    status = 'TRANSMISSION DETAILS INSERTED'
               WHERE  file_id = file_rec.file_id;
            END LOOP;
            IF (trans_id.zip_required = 'Y') THEN
               BEGIN
                  gc_debug_msg := 'Insert into ZIP FILE  for transmission id = ' || trans_id.transmission_id;
                  SELECT DISTINCT file_name
                  INTO   lc_file_name
                  FROM   xx_ar_ebl_cons_hdr_main hdr
                  WHERE  hdr.transmission_id = trans_id.transmission_id;

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
                     ,g_as_of_date);
               EXCEPTION
                  WHEN too_many_rows THEN

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

            IF (trans_id.document_type = 'Paydoc' AND trans_id.billdocs_delivery_method IN ('eXLS', 'eTXT')) THEN

               FOR stub_rec IN (SELECT DISTINCT cons_inv_id
                                               ,remit_address1
                                               ,remit_address2
                                               ,remit_address3
                                               ,remit_address4
                                               ,remit_city
                                               ,remit_state
                                               ,remit_zip
                                               ,remit_country country
                                               ,oracle_account_number
                                               ,aops_account_number
                                               ,customer_name
											   ,consolidated_bill_number --Added consolidated_bill_number for Defect#NAIT-70500 by Thilak --NAIT-61963
                                FROM   xx_ar_ebl_cons_hdr_main hdr, xx_cdh_cust_acct_ext_b caeb  -- join for changes for jira NAIT - 79913
                                WHERE  hdr.parent_cust_doc_id = trans_id.parent_cust_doc_id
								AND    caeb.n_ext_attr2 = trans_id.parent_cust_doc_id

                                AND    hdr.transmission_id = trans_id.transmission_id
                                AND    hdr.extract_batch_id = p_batch_id
								-- Added below check for file split criteria defect # NAIT-29918
								-- start

								AND NOT EXISTS (SELECT 1
                                                    FROM xx_ar_ebl_file eb
                                                    WHERE eb.cons_billing_number = hdr.consolidated_bill_number
                                                    AND eb.paydoc_flag IS NULL
                                                    AND eb.file_type             = 'STUB'
                                                    AND eb.status                = 'RENDER'
                                                    )
								--End
								-- start of changes for jira NAIT - 79913 - Adding check to only pick those cust_docs which has transactions in  XX_AR_EBL_CONS_HDR_MAIN
								-- so that transmission id of only those records should be picked to update transmission_id of stub files.
								AND 1 <= ( CASE WHEN caeb.c_ext_attr13 = 'DB' THEN(SELECT count(1)
													FROM XX_AR_EBL_CONS_HDR_MAIN hdr1
													WHERE 1=1
													AND hdr1.parent_cust_doc_id = trans_id.parent_cust_doc_id
													AND hdr1.transaction_class IN ('Invoice','Debit Memo')
													AND hdr1.cons_inv_id = hdr.cons_inv_id)
												WHEN caeb.c_ext_attr13 = 'CR' THEN(SELECT count(1)
													FROM XX_AR_EBL_CONS_HDR_MAIN hdr1
													WHERE 1=1
													AND hdr1.parent_cust_doc_id = trans_id.parent_cust_doc_id
													AND hdr1.transaction_class IN ('Credit Memo')
													AND hdr1.cons_inv_id = hdr.cons_inv_id)
												ELSE    1
                                            END
										 )
							-- End of changes for jira NAIT -79913

								)
               LOOP
                    --Module 4B Release 1 Start
                    lc_payment_terms := NULL;
                    ld_payment_term_disc_date := NULL;
                    ln_total_merchandise_amt := 0;
                    ln_total_gift_card_amt := 0;
                    ln_total_salestax_amt := 0;
                    ln_total_misc_amt := 0;
                    BEGIN
                        SELECT SUM(gross_sale_amount - total_coupon_amount - total_freight_amount - total_discount_amount),
                            SUM(total_coupon_amount + total_freight_amount + total_discount_amount),
                            SUM(total_gift_card_amount),
                            SUM(total_us_tax_amount + total_gst_amount + total_pst_amount)
                        INTO   ln_total_merchandise_amt,
                            ln_total_misc_amt,
                            ln_total_gift_card_amt,
                            ln_total_salestax_amt
                        FROM   xx_ar_ebl_cons_hdr_main hdr
                        WHERE  hdr.cons_inv_id = stub_rec.cons_inv_id
						 AND hdr.parent_cust_doc_id = trans_id.parent_cust_doc_id --Added Aniket CG defect # NAIT-29918
                         AND hdr.document_type = 'Paydoc';
                    EXCEPTION
                    WHEN OTHERS THEN
                        ln_total_merchandise_amt := 0;
                        ln_total_gift_card_amt := 0;
                        ln_total_salestax_amt := 0;
                        ln_total_misc_amt := 0;
                    END;
                    BEGIN
                        SELECT MAX(bill_due_date), MAX(payment_term_discount_date)
                        INTO   ld_due_date, ld_payment_term_disc_date
                        FROM   xx_ar_ebl_cons_hdr_main hdr
                        WHERE  hdr.cons_inv_id = stub_rec.cons_inv_id
                        AND document_type = 'Paydoc';
                    EXCEPTION
                    WHEN OTHERS THEN
                        ld_due_date := NULL;
                        ld_payment_term_disc_date := NULL;
                    END;
                    gc_debug_msg := 'Getting cons Bill Number';
                    BEGIN
                        SELECT DISTINCT cons_inv_id, payment_term
                        INTO   ln_cons_inv_id, lc_payment_terms
                        FROM   xx_ar_ebl_cons_hdr_main hdr
                        WHERE  hdr.cons_inv_id = stub_rec.cons_inv_id
                        AND document_type = 'Paydoc';
                    EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
                        ln_cons_inv_id := NULL;
                        lc_payment_terms := NULL;
                    END;
                    --Module 4B Release 1 End

                    INSERT INTO xx_ar_ebl_file
                     (file_id
                     ,transmission_id
                     ,file_type
                     ,file_name
                     ,status
                     ,cons_billing_number
                     ,total_due
                     ,flo_code
                     ,remit_address
                     ,account_number
                     ,aops_customer_number
                     ,customer_name
                     ,org_id
                     ,created_by
                     ,creation_date
                     ,last_updated_by
                     ,last_update_date
                     ,last_update_login
                     ,billing_dt
                     ,bill_due_dt
                     ,payment_terms             --Module 4B Release 1
                     ,discount_due_date         --Module 4B Release 1
                     ,total_merchandise_amt     --Module 4B Release 1
                     ,total_sales_tax_amt       --Module 4B Release 1
                     ,total_misc_amt            --Module 4B Release 1
                     ,total_gift_card_amt)      --Module 4B Release 1
                  VALUES
                     (xx_ebl_file_seq.NEXTVAL
                     ,trans_id.transmission_id
                     ,'STUB'
                     ,to_char(stub_rec.consolidated_bill_number)|| lc_stub_suffix || '.pdf'   --Added cons_bill_number for Defect#NAIT-70500 by Thilak
                     ,'RENDER'
                     ,stub_rec.consolidated_bill_number											--	NAIT-61963
                     ,xx_ar_cbi_paydoc_ministmnt(stub_rec.cons_inv_id
                                                ,'TOTAL')
                     ,xx_ar_ebl_common_util_pkg.xx_fin_check_digit(stub_rec.oracle_account_number
                                                                  ,stub_rec.cons_inv_id
                                                                  ,xx_ar_cbi_paydoc_ministmnt(stub_rec.cons_inv_id
                                                                                             ,'TOTAL')*100)
                     ,xx_ar_ebl_common_util_pkg.get_concat_addr(stub_rec.remit_address1
                                                               ,stub_rec.remit_address2
                                                               ,stub_rec.remit_address3
                                                               ,stub_rec.remit_address4
                                                               ,stub_rec.remit_city
                                                               ,stub_rec.remit_state
                                                               ,stub_rec.remit_zip
                                                               ,stub_rec.country)
                     ,stub_rec.oracle_account_number
                     ,stub_rec.aops_account_number
                     ,stub_rec.customer_name
                     ,gn_org_id
                     ,fnd_global.user_id
                     ,SYSDATE
                     ,fnd_global.user_id
                     ,SYSDATE
                     ,fnd_global.login_id
                     ,g_as_of_date
                     ,ld_due_date
                     ,lc_payment_terms              --Module 4B Release 1
                     ,ld_payment_term_disc_date     --Module 4B Release 1
                     ,ln_total_merchandise_amt      --Module 4B Release 1
                     ,ln_total_salestax_amt         --Module 4B Release 1
                     ,ln_total_misc_amt	            --Module 4B Release 1
                     ,(-1) *ln_total_gift_card_amt);--Module 4B Release 1
               END LOOP;
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

   -- +=========================================================================================+
   -- |                  Office Depot - Project Simplify                                        |
   -- |                          Wipro-Office Depot                                             |
   -- +=========================================================================================+
   -- | Name             :  populate_file_name                                                  |
   -- | Description      :  This Procedure is used to populate file names                       |
   -- |Change Record:                                                                           |
   -- |===============                                                                          |
   -- |Version   Date         Author           Remarks                                          |
   -- |=======   ==========   =============    ======================                           |
   -- |DRAFT 1.0 11-MAR-2010  Ranjith Thangasamy   Initial draft version                        |
   -- |1.1       14-MAR-2016  Suresh Naragam       Chnages related to  MOD 4B Release 4         |
   -- +=========================================================================================+
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
         FROM   xx_ar_ebl_cons_hdr_main hdr
               ,xx_cdh_ebl_main         xcem
         WHERE  extract_batch_id = p_batch_id
         AND    xcem.cust_doc_id = hdr.parent_cust_doc_id;

      CURSOR lcu_file_name(p_cust_doc_id IN NUMBER, p_translation_name IN VARCHAR2) IS
         SELECT val.source_value1 field_id
               ,val.source_value4 "MAP"
                ,val.source_value2 TYPE
                ,xcefn.default_if_null
                ,xcefn.constant_value
                ,val.target_value1 data_type
                ,xcefn.attribute1 data_format
         FROM   xx_cdh_ebl_file_name_dtl   xcefn
               ,xx_fin_translatedefinition def
               ,xx_fin_translatevalues     val
         WHERE  def.translate_id = val.translate_id
         AND    xcefn.field_id = to_number(val.source_value1)
         --AND    def.translation_name = 'XX_CDH_EBILLING_FIELDS'
         AND    def.translation_name = p_translation_name
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
      lc_translation_name         VARCHAR2(100);
      lc_field_name               VARCHAR2(500);
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
         IF doc_detail_rec.billdocs_delivery_method = 'eTXT' THEN
           lc_translation_name := 'XX_CDH_EBL_TXT_HDR_FIELDS';
         ELSE
           lc_translation_name := 'XX_CDH_EBILLING_FIELDS';
         END IF;
         FOR fields_rec IN lcu_file_name(doc_detail_rec.parent_cust_doc_id,lc_translation_name)
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
                  IF fields_rec.data_type = 'DATE' AND  fields_rec.data_format IS NOT NULL THEN
                    lc_field_name := 'TO_CHAR('||fields_rec.MAP||','||''''||fields_rec.data_format||''''||')';
                  ELSE
                    lc_field_name := 'TO_CHAR('||fields_rec.MAP||')';
                  END IF;
                  lc_table  := 'XX_AR_EBL_cons_HDR_MAIN';
                  --lc_select := 'SELECT to_char(' || fields_rec.MAP || ') FROM ' || lc_table || ' WHERE file_id = ' || doc_detail_rec.file_id || ' AND rownum<2';
                    lc_select := 'SELECT '||lc_field_name||' FROM ' || lc_table || ' WHERE file_id = ' || doc_detail_rec.file_id || ' AND rownum<2';
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
         UPDATE xx_ar_ebl_cons_hdr_main
         SET    file_name = REPLACE(substr(lc_final_file_string
                                          ,2)
                                   ,' '
                                   ,'')
         WHERE  parent_cust_doc_id = doc_detail_rec.parent_cust_doc_id
         AND    file_id = doc_detail_rec.file_id
         AND    nvl(split_identifier
                   ,'x') = nvl(doc_detail_rec.split_identifier
                               ,'x')
          AND    extract_batch_id = p_batch_id                               ;
      END LOOP;
   EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line(fnd_file.log
                          ,'when others - Populate file name ' || SQLERRM);
   END populate_file_name;
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
   FUNCTION get_cust_id(p_cust_doc_id NUMBER
                       ,p_attr_id NUMBER) RETURN NUMBER IS
      lc_cust_acct_id NUMBER;
   BEGIN
      SELECT cust_account_id
      INTO   lc_cust_acct_id
      FROM   xx_cdh_cust_acct_ext_b
      WHERE  n_ext_attr2 = p_cust_doc_id
      AND    attr_group_id = p_attr_id;

      RETURN lc_cust_acct_id;
   EXCEPTION
      WHEN OTHERS THEN
         xx_ar_ebl_common_util_pkg.put_log_line(FALSE
                                               ,TRUE
                                               ,'Error in getting parent cust doc id for cust doc id:' || p_cust_doc_id);
         lc_cust_acct_id := 0;
         RETURN lc_cust_acct_id;
   END;
   -- +===================================================================================+
   -- |                  Office Depot - Project Simplify                                  |
   -- |                       WIPRO Technologies                                          |
   -- +===================================================================================+
   -- | Name        : Infocopies handling logic for INV_IC scenario                       |
   -- | Description : This function will return 'Y' or 'N' depending upon whether the     |
   -- |               infocopy can be sent or not                                         |
   -- |                                                                                   |
   -- |                                                                                   |
   -- |                                                                                   |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version   Date          Author              Remarks                                |
   -- |=======   ==========   =============        =======================================|
   -- |1.0       01-Apr-10    Tamil Vendhan L      Initial Version                        |
   -- +===================================================================================+

   FUNCTION xx_ar_infocopy_handling(p_attr           IN VARCHAR2
                                   ,p_doc_term       IN VARCHAR2
                                   ,p_cut_off_date   IN DATE
                                   ,p_eff_start_date IN DATE
                                   ,p_as_of_date     IN DATE) RETURN VARCHAR2 AS

      lc_result         VARCHAR2(1);
      lc_error_location VARCHAR2(2000);

   BEGIN
      lc_error_location := 'Checking for the effective start date condition ';

      IF (xx_ar_inv_freq_pkg.compute_effective_date(p_doc_term
                                                   ,p_cut_off_date) >= p_eff_start_date) THEN

         lc_error_location := 'Checking for whether the paydoc sent or not ';

         IF (p_attr IS NOT NULL) THEN
            lc_result := 'Y';
         ELSE
            lc_error_location := 'Checking for whether the infodoc falls under the current frequency ';
            IF p_cut_off_date = p_as_of_date THEN
               lc_result := 'Y';
            ELSE
               lc_result := 'N';
            END IF;
         END IF;
      ELSE
         lc_result := 'N';
      END IF;
      RETURN(lc_result);

   EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line(fnd_file.log
                          ,'When others exception in ' || lc_error_location);
         RETURN('N');

   END xx_ar_infocopy_handling;
   -- Insert error File
   PROCEDURE insert_error_file AS
      CURSOR error_files IS
         SELECT xx_ebl_file_seq.NEXTVAL file_id
               ,xx_ebl_trans_seq.NEXTVAL transmission_id
               ,decode(xaecbs.delivery_method
                      ,'eXLS'
                      ,'XLS'
                      ,'ePDF'
                      ,'PDF'
                      ,'eTXT'
                      ,'TXT') file_type
               ,'DATAEXTRACT_FAILED' status
               ,decode(xaecbs.billdocs_paydoc_ind
                      ,'Y'
                      ,'ORIGINAL CONSOLIDATED BILL'
                      ,'N'
                      ,'INFORMATIONAL COPY OF CONSOLIDATED BILL') doc_description
               ,hza.account_number acct_number
               ,substr(hza.orig_system_reference
                      ,1
                      ,8) aops_acct_number
               ,xaecbs.parent_cust_doc_id
               ,xaecbs.billdocs_paydoc_ind paydoc_flag
               ,xaecbs.parent_cust_acct_id
               ,xcem.ebill_transmission_type
               ,xaecbs.billing_term
               ,xcem.ebill_associate
         FROM   xx_ar_ebl_cons_bills_stg    xaecbs
               ,xx_cdh_ebl_transmission_dtl xctd
               ,hz_cust_accounts            hza
               ,xx_cdh_ebl_main             xcem
         WHERE  xaecbs.parent_cust_doc_id = xctd.cust_doc_id
         AND    xcem.cust_doc_id = xaecbs.parent_cust_doc_id
         AND    xctd.ftp_send_zero_byte_file = 'Y'
         AND    xcem.ebill_transmission_type = 'FTP'
         AND    xaecbs.delivery_method = 'eTXT'
         AND    xaecbs.org_id = gn_org_id
         AND    hza.cust_account_id = xaecbs.parent_cust_acct_id
         AND    NOT EXISTS (SELECT 1
                 FROM   xx_ar_ebl_cons_hdr_main hdr
                 WHERE  hdr.parent_cust_doc_id = xctd.cust_doc_id)
         AND    EXISTS (SELECT 1
                 FROM   xx_ar_ebl_error_bills err
                 WHERE  err.cust_doc_id = xctd.cust_doc_id
                 AND    err.as_of_date = g_as_of_date);
      lcu_error_files error_files%ROWTYPE;
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
         /*  INSERT INTO XX_AR_EBL_TRANSMISSION(transmission_id
                ,customer_id
                ,customer_doc_id
                ,transmission_type
                ,status
                ,pay_terms
                , created_by
               , creation_date
               , last_updated_by
               , last_update_date
               , last_update_login
                )
         VALUES (lcu_error_files.transmission_id
                 ,lcu_error_files.parent_cust_acct_id
                 ,lcu_error_files.parent_cust_doc_id
                 ,lcu_error_files.ebill_transmission_type
                 ,'SEND'
                 ,lcu_error_files.billing_term
                 ,FND_GLOBAL.USER_ID
                 ,sysdate
                 ,FND_GLOBAL.USER_ID
                 ,sysdate
                 ,FND_GLOBAL.LOGIN_ID
                 );*/
      END LOOP;
   END insert_error_file;

   -- Insert zero Byte file
   PROCEDURE insert_zero_byte_file AS
      CURSOR zero_byte_files IS
         SELECT xx_ebl_file_seq.NEXTVAL file_id
               ,xx_ebl_trans_seq.NEXTVAL transmission_id
               ,decode(xaecbs.delivery_method
                      ,'eXLS'
                      ,'XLS'
                      ,'ePDF'
                      ,'PDF'
                      ,'eTXT'
                      ,'TXT') file_type
               ,decode(xaecbs.delivery_method
                      ,'eXLS'
                      ,'MANIP_READY'
                      ,'ePDF'
                      ,'RENDER'
                      ,'eTXT'
                      --,'RENDER'
                      ,'MANIP_READY') status
               ,decode(xaecbs.billdocs_paydoc_ind
                      ,'Y'
                      ,'ORIGINAL CONSOLIDATED BILL'
                      ,'N'
                      ,'INFORMATIONAL COPY OF CONSOLIDATED BILL') doc_description
               ,hza.account_number acct_number
               ,substr(hza.orig_system_reference
                      ,1
                      ,8) aops_acct_number
               ,xaecbs.parent_cust_doc_id
               ,xaecbs.billdocs_paydoc_ind paydoc_flag
               ,xaecbs.parent_cust_acct_id
               ,xcem.ebill_transmission_type
               ,xaecbs.billing_term
         FROM   xx_ar_ebl_cons_bills_stg    xaecbs
               ,xx_cdh_ebl_transmission_dtl xctd
               ,hz_cust_accounts            hza
               ,xx_cdh_ebl_main             xcem
         WHERE  xaecbs.parent_cust_doc_id = xctd.cust_doc_id
         AND    xcem.cust_doc_id = xaecbs.parent_cust_doc_id
         AND    xctd.ftp_send_zero_byte_file = 'Y'
         AND    xcem.ebill_transmission_type = 'FTP'
         AND    xaecbs.delivery_method = 'eTXT'
         AND    xaecbs.org_id = gn_org_id
         AND    hza.cust_account_id = xaecbs.parent_cust_acct_id
         AND    NOT EXISTS (SELECT 1
                 FROM   xx_ar_ebl_cons_hdr_main hdr
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
            ,zero_byte_flag
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
            ,billing_dt
             )
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
            ,'Y'
            ,fnd_global.user_id
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
            ,lcu_zero_byte_files.billing_term
            ,'Y'
            ,fnd_global.user_id
            ,SYSDATE
            ,fnd_global.user_id
            ,SYSDATE
            ,fnd_global.login_id);
      END LOOP;
   END insert_zero_byte_file;
   FUNCTION inv_ic_check(p_trx_id             IN NUMBER
                        ,p_cust_doc_id        IN NUMBER
                        ,p_parent_cust_doc_id IN NUMBER) RETURN VARCHAR2 AS
      lc_return VARCHAR2(1) := 'N';
   BEGIN
      BEGIN
         SELECT 'N'
         INTO   lc_return
         FROM   xx_ar_ebl_cons_hdr_hist hist
         WHERE  1 = 1
         AND    hist.cust_doc_id = p_cust_doc_id
         AND    hist.customer_trx_id = p_trx_id;
      EXCEPTION
         WHEN no_data_found THEN
            BEGIN
               SELECT 'N'
               INTO   lc_return
               FROM   xx_ar_ebl_cons_hdr_main hdr
               WHERE  1 = 1
               AND    hdr.cust_doc_id = p_cust_doc_id
               AND    hdr.customer_trx_id = p_trx_id;
            EXCEPTION
               WHEN no_data_found THEN
                  lc_return := 'Y';

            END;
            RETURN(lc_return);
      END;
      RETURN(lc_return);

   EXCEPTION
      WHEN OTHERS THEN
         RETURN(lc_return);
   END;

END xx_ar_ebl_cons_invoices;
/