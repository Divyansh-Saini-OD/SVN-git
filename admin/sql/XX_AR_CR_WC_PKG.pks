create or replace PACKAGE xx_ar_cr_wc_pkg
AS
   /*+=========================================================================+
   |      Office Depot - Project FIT                                           |
   |   Capgemini/Office Depot/Consulting Organization                          |
   +===========================================================================+
   |Name        : XX_AR_CR_WC_PKG                                              |
   |RICE        : I2158                                                        |
   |Description : This Package is used for insert data into staging            |
   |              table and fetch data from staging table to flat file         |
   |                                                                           |
   |              The STAGING Procedure will perform the following steps       |
   |                                                                           |
   |              1.It will fetch the records into staging table. The          |
   |               data will be either full or incremental                     |
   |                                                                           |
   |              EXTRACT STAGING procedure will perform the following         |
   |                steps                                                      |
   |                                                                           |
   |              1.It will fetch the staging table data to flat file          |
   |                                                                           |
   |Change Record:                                                             |
   |==============                                                             |
   |Version  Date         Author                  Remarks                      |
   |=======  ===========  ======================  =============================|
   |  1.0    30-Sep-2011  Narmatha Purushothaman  Initial Version              |
   |                                                                           |
   |  1.1    30-SEP-2011  Narmatha Purushothaman  Initial Version              |
   |                                                                           |
   |  1.2    07-NOV-2011  Narmatha Purushothaman  Modified as per MD070        |
   |                                                                           |
   |  1.3    15-MAR-2012  R.Aldridge              Defect 17213 - Changes for   | 
   |                                              customer_id difference       |
   |                                              (override receipt cust ID)   |
   +==========================================================================*/

   /*====================================================+
   |   Record Type Declaration                           |
   |                                                     |
   |   Name: Cash Receipt                                |
   +=====================================================*/
   TYPE cr_rec_type IS RECORD (
      cash_receipt_id               ar_cash_receipts_all.cash_receipt_id%TYPE
     ,customer_account_id           ar_cash_receipts_all.pay_from_customer%TYPE
     ,customer_site_use_id          ar_cash_receipts_all.customer_site_use_id%TYPE
     ,receipt_number                ar_cash_receipts_all.receipt_number%TYPE
     ,receipt_date                  ar_cash_receipts_all.receipt_date%TYPE
     ,amount                        ar_cash_receipts_all.amount%TYPE
     ,currency_code                 ar_cash_receipts_all.currency_code%TYPE
     ,status                        ar_cash_receipts_all.status%TYPE
     ,reversal_date                 ar_cash_receipts_all.reversal_date%TYPE
     ,comments                      ar_cash_receipts_all.comments%TYPE
     ,state                         ar_cash_receipt_history_all.status%TYPE
     ,receipt_method                ar_cash_receipts_all.receipt_method_id%TYPE
     ,posted_dte                    ar_cash_receipts_all.deposit_date%TYPE
     ,reversal_reason_codes         ar_cash_receipts_all.reversal_reason_code%TYPE
     ,reversal_comments             ar_cash_receipts_all.reversal_comments%TYPE
     ,send_refund                   ra_customer_trx_all.attribute9%TYPE
     ,refund_status                 ra_customer_trx_all.attribute10%TYPE
     ,creation_date                 ar_cash_receipts_all.creation_date%TYPE
     ,created_by                    ar_cash_receipts_all.created_by%TYPE
     ,request_id                    xx_ar_cr_wc_stg.request_id%TYPE
     ,rec_creation_date             xx_ar_cr_wc_stg.rec_creation_date%TYPE
     ,ext_type                      xx_ar_cr_wc_stg.ext_type%TYPE
     ,cycle_date                    xx_ar_cr_wc_stg.cycle_date%TYPE
     ,batch_num                     xx_ar_cr_wc_stg.batch_num%TYPE
     ,orig_customer_id              ar_cash_receipts_all.pay_from_customer%TYPE
     ,orig_customer_site_use_id     ar_cash_receipts_all.customer_site_use_id%TYPE
   );

-------------------------------
--Table type declaration
-------------------------------
   TYPE cr_tbl_type IS TABLE OF cr_rec_type;

   TYPE reqid_tbl_type IS TABLE OF NUMBER
      INDEX BY BINARY_INTEGER;

   TYPE filename_tbl_type IS TABLE OF VARCHAR2 (240)
      INDEX BY BINARY_INTEGER;

   -------------------------------
   --Global variable declaration
   -------------------------------
   gd_last_run_date              DATE;
   gn_nextval                    NUMBER;
   gc_module_name                fnd_application_tl.application_name%TYPE := 'XXFIN';
   gc_program_name               fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE := 'OD: AR REC File Generation - WebCollect';
   gc_program_short_name         fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXARCREXTWC';
   gd_creation_date              hz_cust_accounts.creation_date%TYPE := SYSDATE;
   gn_created_by                 hz_cust_accounts.created_by%TYPE := fnd_global.user_id;
   gn_request_id                 fnd_concurrent_requests.request_id%TYPE := fnd_global.conc_request_id;

   ----------------------------------------------------------------------------------------------
   -- This procedure is used to fetch Full Cash Receipts data from base tables to staging table
   ----------------------------------------------------------------------------------------------
   PROCEDURE cr_full (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_cycle_date             IN       VARCHAR2
     ,p_batch_num              IN       NUMBER
     ,p_from_cust_account_id   IN       NUMBER
     ,p_to_cust_account_id     IN       NUMBER
     ,p_debug                  IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
     ,p_process_type           IN       VARCHAR2
     ,p_action_type            IN       VARCHAR2);

   ---------------------------------------------------------------------------------------------------
   -- This procedure is used to fetch Incremental Cash Receipts data from base tables to staging table
   ---------------------------------------------------------------------------------------------------
   PROCEDURE cr_incr (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_cycle_date             IN       VARCHAR2
     ,p_batch_num              IN       NUMBER
     ,p_from_cash_rcpt_id      IN       NUMBER
     ,p_to_cash_rcpt_id        IN       NUMBER
     ,p_debug                  IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
     ,p_process_type           IN       VARCHAR2
     ,p_action_type            IN       VARCHAR2);

   -------------------------------------------------------------------------
   -- This procedure is used to fetch the staging table data to flat file
   -------------------------------------------------------------------------
   PROCEDURE cr_extr (
      p_errbuf         OUT      VARCHAR2
     ,p_retcode        OUT      NUMBER
     ,p_cycle_date     IN       VARCHAR2
     ,p_batch_num      IN       NUMBER
     ,p_debug          IN       VARCHAR2
     ,p_process_type   IN       VARCHAR2
     ,p_action_type    IN       VARCHAR2
   );

END xx_ar_cr_wc_pkg;
/
SHOW errors
