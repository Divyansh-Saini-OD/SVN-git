create or replace PACKAGE XX_AR_TXN_WC_PKG 
AS
   /*====================================================================+
   |      Office Depot - Project FIT                                     |
   |   Capgemini/Office Depot/Consulting Organization                    |
   +=====================================================================+
   |Name        :XX_AR_TXN_WC_PKG                                        |
   |RICE        :                                                        |
   |Description :This Package is used for insert data into staging       |
   |             table and fetch data from staging table to flat file    |
   |                                                                     |
   |             The STAGING Procedure will perform the following steps  |
   |                                                                     |
   |             1.It will fetch the records into staging table. The     |
   |               data will be either full or incremental               |
   |                                                                     |
   |            EXTRACT STAGING procedure will perform the following     |
   |                steps                                                |
   |                                                                     |
   |            1.It will fetch the staging table data to flat file      |
   |                                                                     |
   |Change Record:                                                       |
   |==============                                                       |
   |Version    Date           Author                       Remarks       |
   |=======   ======        ====================          =========      |
   |1.00     21-Sep-2011   Narmatha Purushothaman     Initial Version    |
   |                                                                     |
   +=====================================================================*/

   /*====================================================+
   |   Record Type Declaration                           |
   |                                                     |
   |   Name: AR Transactions                             |
   +=====================================================*/
   TYPE txn_rec_type IS RECORD (
      customer_trx_id               ra_customer_trx_all.customer_trx_id%TYPE
     ,bill_to_customer_id           ra_customer_trx_all.bill_to_customer_id%TYPE
     ,bill_to_site_use_id           ra_customer_trx_all.bill_to_site_use_id%TYPE
     ,invoice_class                 ra_cust_trx_types_all.TYPE%TYPE
     ,invoice_type                  ra_cust_trx_types_all.NAME%TYPE
     ,trx_number                    ra_customer_trx_all.trx_number%TYPE
     ,consolidated_bill_number      ar_cons_inv_all.cons_billing_number%TYPE
     ,trx_date                      ra_customer_trx_all.trx_date%TYPE
     ,print_date                    ra_customer_trx_all.printing_last_printed%TYPE
     ,term_code                     ra_terms.NAME%TYPE
     ,special_instructions          ra_customer_trx_all.internal_notes%TYPE
     ,comments                      ra_customer_trx_all.comments%TYPE
     ,invoice_currency_code         ra_customer_trx_all.invoice_currency_code%TYPE
     ,send_refund                   ra_customer_trx_all.attribute9%TYPE
     ,refund_status                 ra_customer_trx_all.attribute10%TYPE
     ,billing_extension             ra_customer_trx_all.attribute15%TYPE
     ,orig_system_order_reference   oe_order_headers_all.orig_sys_document_ref%TYPE
     ,dispute_flag                  ra_customer_trx_all.attribute11%TYPE
     ,sales_person                  ra_customer_trx_all.primary_salesrep_id%TYPE
     ,po                            ra_customer_trx_all.purchase_order%TYPE
     ,release                       xx_om_header_attributes_all.release_number%TYPE
     ,cost_center                   xx_om_header_attributes_all.cost_center_dept%TYPE
     ,desktop                       xx_om_header_attributes_all.desk_del_addr%TYPE
     ,sales_order                   ra_customer_trx_all.attribute13%TYPE
     ,creation_date                 ra_customer_trx_all.creation_date%TYPE
     ,created_by                    ra_customer_trx_all.created_by%TYPE
     ,request_id                    xx_ar_trans_wc_stg.request_id%TYPE
     ,trx_creation_date             xx_ar_trans_wc_stg.trx_creation_date%TYPE
     ,ext_type                      xx_ar_trans_wc_stg.ext_type%TYPE
     ,cycle_date                    xx_ar_trans_wc_stg.cycle_date%TYPE
     ,batch_num                     xx_ar_trans_wc_stg.batch_num%TYPE
   );


   -------------------------------
   --Table type declaration
   -------------------------------
   TYPE txn_tbl_type IS TABLE OF txn_rec_type;

   TYPE reqid_tbl_type IS TABLE OF NUMBER
      INDEX BY BINARY_INTEGER;

   TYPE filename_tbl_type IS TABLE OF VARCHAR2 (240)
      INDEX BY BINARY_INTEGER;

   ------------------------------
   --Global variable declaration
   -------------------------------
   gd_last_run_date            DATE;
   gn_nextval                  NUMBER;
   gc_module_name              fnd_application_tl.application_name%TYPE                       := 'XXFIN';
   gc_program_name             fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE   := 'OD: AR TRX File Generation - WebCollect';
   gc_program_short_name       fnd_concurrent_programs.concurrent_program_name%TYPE           := 'XXARTXNEXTWC';
   gd_creation_date            hz_cust_accounts.creation_date%TYPE                            := SYSDATE;
   gn_created_by               hz_cust_accounts.created_by%TYPE                               := fnd_global.user_id;
   gn_request_id               fnd_concurrent_requests.request_id%TYPE                        := fnd_global.conc_request_id;


   PROCEDURE txn_full (
         p_errbuf                 OUT    VARCHAR2
        ,p_retcode                OUT    NUMBER
        ,p_cycle_date             IN     VARCHAR2
        ,p_batch_num              IN     NUMBER
        ,p_from_cust_account_id   IN     NUMBER
        ,p_to_cust_account_id     IN     NUMBER
        ,p_debug                  IN     VARCHAR2
        ,p_thread_num             IN     NUMBER
        ,p_process_type           IN     VARCHAR2
        ,p_action_type            IN     VARCHAR2);

   PROCEDURE txn_incr (
         p_errbuf                 OUT    VARCHAR2
        ,p_retcode                OUT    NUMBER
        ,p_cycle_date             IN     VARCHAR2
        ,p_batch_num              IN     NUMBER
        ,p_from_cust_trx_id       IN     NUMBER
        ,p_to_cust_trx_id         IN     NUMBER
        ,p_debug                  IN     VARCHAR2
        ,p_thread_num             IN     NUMBER
        ,p_process_type           IN     VARCHAR2
        ,p_action_type            IN     VARCHAR2);

   -------------------------------------------------------------------------
   -- This procedure is used to fetch the staging table data to flat file
   -------------------------------------------------------------------------
   PROCEDURE txn_extr (
         p_errbuf                 OUT    VARCHAR2
        ,p_retcode                OUT    NUMBER
        ,p_cycle_date             IN     VARCHAR2
        ,p_batch_num              IN     NUMBER
        ,p_debug                  IN     VARCHAR2
        ,p_process_type           IN     VARCHAR2
        ,p_action_type            IN     VARCHAR2);

END XX_AR_TXN_WC_PKG;
/
show errors
