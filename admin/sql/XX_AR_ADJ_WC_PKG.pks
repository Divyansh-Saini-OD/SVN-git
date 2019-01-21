create or replace PACKAGE XX_AR_ADJ_WC_PKG
AS
   /*========================================================================================+
   |      Office Depot - Project FIT                                                         |
   |   Capgemini/Office Depot/Consulting Organization                                        |
   +=========================================================================================+
   |Name        :XX_AR_ADJ_WC_PKG                                                            |
   |RICE        :                                                                            |
   |Description :This Package is used for insert data into staging                           |
   |             table and fetch data from staging table to flat file                        |
   |                                                                                         |
   |            The STAGING Procedure will perform the following steps                       |
   |                                                                                         |
   |             1.It will fetch the records into staging table. The                         |
   |               data will be either full or incremental                                   |
   |                                                                                         |
   |             EXTRACT STAGING procedure will perform the following                        |
   |                steps                                                                    |
   |                                                                                         |
   |              1.It will fetch the staging table data to flat file                        |
   |                                                                                         |
   |                                                                                         |
   |                                                                                         |
   |Change Record:                                                                           |
   |==============                                                                           |
   |Version    Date           Author                       Remarks                           |
   |=======   ======        ====================          =========                          |
   |1.0     30-Sep-2011     Narmatha Purushothaman        Initial Version                    |
   |                                                                                         |
   |                                                                                         |
   +=========================================================================================*/
   ---------------------------------Global variable declaration
   -------------------------------
   gd_last_run_date              DATE;
   gn_nextval                    NUMBER;
   gc_module_name                fnd_application_tl.application_name%TYPE := 'XXFIN';
   gc_program_name               fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE := 'OD: AR ADJ File Generation - WebCollect';
   gc_program_short_name         fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXARADJEXTWC';
   gd_creation_date              hz_cust_accounts.creation_date%TYPE := SYSDATE;
   gn_created_by                 hz_cust_accounts.created_by%TYPE := fnd_global.user_id;
   gn_request_id                 fnd_concurrent_requests.request_id%TYPE := fnd_global.conc_request_id;

-----------------------------------------------------------------------------------------------
-- This procedure is used to fetch Full adjustments data from base tables to staging table
-----------------------------------------------------------------------------------------------
   PROCEDURE adj_full (
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

-----------------------------------------------------------------------------------------------
-- This procedure is used to fetch Incremental adjustments data from base tables to staging table
-----------------------------------------------------------------------------------------------
   PROCEDURE adj_incr (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_cycle_date             IN       VARCHAR2
     ,p_batch_num              IN       NUMBER
     ,p_from_adj_id            IN       NUMBER
     ,p_to_adj_id              IN       NUMBER
     ,p_debug                  IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
     ,p_process_type           IN       VARCHAR2
     ,p_action_type            IN       VARCHAR2);

-----------------------------------------------------------------------
-- This procedure is used to fetch the staging table data to flat file
-----------------------------------------------------------------------
   PROCEDURE adj_extr (
      p_errbuf                 OUT     VARCHAR2
     ,p_retcode                OUT     NUMBER
     ,p_cycle_date             IN      VARCHAR2
     ,p_batch_num              IN      NUMBER
     ,p_debug                  IN      VARCHAR2
     ,p_process_type           IN      VARCHAR2
     ,p_action_type            IN      VARCHAR2
   );

/*====================================================+
|   Record Type Declaration                           |
|                                                     |
|   Name: Adjustments                                 |
+=====================================================*/
   TYPE adj_rec_type IS RECORD (
      from_adjustment_id            ar_adjustments_all.adjustment_id%TYPE
     ,from_adjustment_number        ar_adjustments_all.adjustment_number%TYPE
     ,cust_account_id               hz_cust_accounts.cust_account_id%TYPE
     ,bill_to_site_use_id           ra_customer_trx_all.bill_to_site_use_id%TYPE
     ,to_class                      ar_adjustments_all.TYPE%TYPE
     ,to_customer_trx_id            ar_adjustments_all.customer_trx_id%TYPE
     ,trx_number                    ra_customer_trx_all.trx_number%TYPE
     ,apply_date                    ar_adjustments_all.apply_date%TYPE
     ,amount_adjusted               ar_adjustments_all.amount%TYPE
     ,tax_adjusted                  ar_adjustments_all.tax_adjusted%TYPE
     ,receivables_charges_adjusted  ar_adjustments_all.receivables_charges_adjusted%TYPE
     ,adjustment_reason_code        ar_adjustments_all.reason_code%TYPE
     ,comments                      ar_adjustments_all.comments%TYPE
     ,adjustment_activity_name      ar_receivables_trx_all.NAME%TYPE
     ,adjustment_type               ar_adjustments_all.adjustment_type%TYPE
     ,adjustment_status             ar_adjustments_all.status%TYPE
     ,creation_date                 ar_adjustments_all.creation_date%TYPE
     ,created_by                    ar_adjustments_all.created_by%TYPE
     ,request_id                    xx_ar_ps_wc_stg.request_id%TYPE
     ,adj_creation_date             xx_ar_ps_wc_stg.pmt_creation_date%TYPE
     ,ext_type                      xx_ar_ps_wc_stg.ext_type%TYPE
     ,cycle_date                    xx_ar_ps_wc_stg.cycle_date%TYPE
     ,batch_num                     xx_ar_ps_wc_stg.batch_num%TYPE
   );

-------------------------------
--Table type declaration
-------------------------------
   TYPE adj_tbl_type IS TABLE OF adj_rec_type;

   TYPE reqid_tbl_type IS TABLE OF NUMBER
      INDEX BY BINARY_INTEGER;

   TYPE filename_tbl_type IS TABLE OF VARCHAR2 (240)
      INDEX BY BINARY_INTEGER;
END XX_AR_ADJ_WC_PKG;
/

SHOW errors