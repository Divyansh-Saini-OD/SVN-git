CREATE OR REPLACE PACKAGE XX_AR_RECAPPL_WC_PKG
AS
   /*==========================================================================+
   |      Office Depot - Project FIT                                           |
   |   Capgemini/Office Depot/Consulting Organization                          |
   +===========================================================================+
   |Name        : XX_AR_RECAPPL_WC_PKG                                         |
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
   |  1.0    22-Sep-2011  Narmatha Purushothaman  Initial Version              |
   |  1.1    22-May-2011  Jay Gupta               Changes for defect 17526     |
   +===========================================================================*/

   -------------------------------
   --Global variable declaration
   -------------------------------
   gd_last_run_date        DATE;
   gn_nextval              NUMBER;
   gc_module_name          fnd_application_tl.application_name%TYPE                       := 'XXFIN';
   gc_program_name         fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE   := 'OD: AR APP File Generation - WebCollect';
   gc_program_short_name   fnd_concurrent_programs.concurrent_program_name%TYPE           := 'XXARRAEXTWC';
   gd_creation_date        hz_cust_accounts.creation_date%TYPE                            := SYSDATE;
   gn_created_by           hz_cust_accounts.created_by%TYPE                               := fnd_global.user_id;
   gn_request_id               fnd_concurrent_requests.request_id%TYPE                        := fnd_global.conc_request_id;

   ------------------------------------------------------------------------------------------------------
   -- This procedure is used to fetch Full Receivable Applications data from base tables to staging table
   -------------------------------------------------------------------------------------------------------
   PROCEDURE rappl_full (
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

   -------------------------------------------------------------------------------------------------------------
   -- This procedure is used to fetch Incremental Receivable Applications data from base tables to staging table
   --------------------------------------------------------------------------------------------------------------
   PROCEDURE rappl_incr (
         p_errbuf                 OUT      VARCHAR2
        ,p_retcode                OUT      NUMBER
        ,p_cycle_date             IN       VARCHAR2
        ,p_batch_num              IN       NUMBER
        ,p_from_recappl_id        IN       NUMBER
        ,p_to_recappl_id          IN       NUMBER
        ,p_debug                  IN       VARCHAR2
        ,p_thread_num             IN       NUMBER
        ,p_process_type           IN       VARCHAR2
        ,p_action_type            IN       VARCHAR2);

   -------------------------------------------------------------------------
   -- This procedure is used to fetch the staging table data to flat file
   -------------------------------------------------------------------------
   PROCEDURE rappl_extr (
         p_errbuf                 OUT      VARCHAR2
        ,p_retcode                OUT      NUMBER
        ,p_cycle_date             IN       VARCHAR2
        ,p_batch_num              IN       NUMBER
        ,p_debug                  IN       VARCHAR2
        ,p_process_type           IN       VARCHAR2
        ,p_action_type            IN       VARCHAR2);

   /*====================================================+
   |   Record Type Declaration                           |
   |                                                     |
   |   Name: Receivable Applications                     |
   +=====================================================*/
   TYPE recappl_rec_type IS RECORD (
      receipt_type                ar_cash_receipts_all.TYPE%TYPE
     ,receivable_application_id   ar_receivable_applications_all.receivable_application_id%TYPE
     ,customer_trx_id             ar_receivable_applications_all.customer_trx_id%TYPE
     ,trx_number                  VARCHAR2(30)                                    -- ra_customer_trx_all.trx_number%TYPE
     ,cash_receipt_id             ar_cash_receipts_all.cash_receipt_id%TYPE
     ,from_class                  ar_receivable_applications_all.application_type%TYPE
     ,to_class                    VARCHAR2(80)                                  -- ar_lookups.meaning%TYPE
     ,applied_customer_trx_id     ar_receivable_applications_all.applied_customer_trx_id%TYPE
     ,applied_trx_number          ra_customer_trx_all.trx_number%TYPE
     ,apply_date                  ar_receivable_applications_all.apply_date%TYPE
     ,amount_applied              ar_receivable_applications_all.amount_applied%TYPE
     ,discount_taken              ar_receivable_applications_all.earned_discount_taken%TYPE
     ,comments                    ar_receivable_applications_all.comments%TYPE
     ,status                      ar_receivable_applications_all.status%TYPE
     ,creation_date               xx_ar_recappl_wc_stg.creation_date%TYPE
     ,created_by                  xx_ar_recappl_wc_stg.created_by%TYPE
     ,request_id                  xx_ar_recappl_wc_stg.request_id%TYPE
     ,app_creation_date           xx_ar_recappl_wc_stg.app_creation_date%TYPE
     ,ext_type                    xx_ar_recappl_wc_stg.ext_type%TYPE
     ,cycle_date                  xx_ar_recappl_wc_stg.cycle_date%TYPE
     ,batch_num                   xx_ar_recappl_wc_stg.batch_num%TYPE
     ,activity_name               AR_RECEIVABLES_TRX.name%TYPE  -- V1.1
   );

   -------------------------------
   --Table type declaration
   -------------------------------
   TYPE recappl_tbl_type IS TABLE OF recappl_rec_type;

   TYPE reqid_tbl_type IS TABLE OF NUMBER
      INDEX BY BINARY_INTEGER;

   TYPE filename_tbl_type IS TABLE OF VARCHAR2 (240)
      INDEX BY BINARY_INTEGER;


END XX_AR_RECAPPL_WC_PKG;
/

SHOW ERRORS
