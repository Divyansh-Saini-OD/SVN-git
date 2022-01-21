create or replace
PACKAGE XX_AR_PS_WC_PKG
AS
   /*==========================================================================+
   |      Office Depot - Project FIT                                           |
   |   Capgemini/Office Depot/Consulting Organization                          |
   +===========================================================================+
   |Name        : XX_AR_PS_WC_PKG                                              |
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
   |  1.0    21-SEP-2011  Narmatha Purushothaman  Initial Version              |
   |                                                                           |
   |  1.1    19-JAN-2012  R.Aldridge              Defect 16332 - modify        |
   |                                              ps_rec_type record type to be|
   |                                              generic for cash_receipt_id  |
   |                                              as well as customer_trx_id   |
   |                                                                           |
   |  1.2    07-MAR-2012  R.Aldridge              Defect 17213 - Changes for   |
   |                                              customer_id difference       |
   |                                              (override pmt sch cust ID)   |
   |                                                                           |
   |  1.3    15-MAR-2012  R.Aldridge              Defect 17213 - Changes for   |
   |                                              customer_id difference       |
   |                                              (revert to revision 159904)  |
   |                                                                           |
   |  1.4    15-MAR-2012  R.Aldridge              Defect 17213 - Changes for   |
   |                                              customer_id difference       |
   |                                              (override receipt cust ID)   |
   |	1.5	 05-JUN-2013  Manasa							R12 Upgrade Retrofit changes| 
   +==========================================================================*/
   -------------------------------
   --Global variable declaration
   -------------------------------
   gd_last_run_date              DATE;
   gn_nextval                    NUMBER;
   gc_module_name                fnd_application_tl.application_name%TYPE := 'XXFIN';
   gc_program_name               fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE := 'OD: AR PMT File Generation - WebCollect';
   gc_program_short_name         fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXARPSEXTWC';
   gd_creation_date              hz_cust_accounts.creation_date%TYPE := SYSDATE;
   gn_created_by                 hz_cust_accounts.created_by%TYPE := -1;
   gn_request_id                 fnd_concurrent_requests.request_id%TYPE := fnd_global.conc_request_id;

   -----------------------------------------------------------------------------------------------
   -- This procedure is used to fetch Full Payment Schedule data from base tables to staging table
   -----------------------------------------------------------------------------------------------
   PROCEDURE ps_full (
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

   ------------------------------------------------------------------------------------------------------
   -- This procedure is used to fetch Incremental Payment Schedule data from base tables to staging table
   ------------------------------------------------------------------------------------------------------
   PROCEDURE ps_incr (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_cycle_date             IN       VARCHAR2
     ,p_batch_num              IN       NUMBER
     ,p_from_ps_id             IN       NUMBER
     ,p_to_ps_id               IN       NUMBER
     ,p_debug                  IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
     ,p_process_type           IN       VARCHAR2
     ,p_action_type            IN       VARCHAR2);

   -------------------------------------------------------------------------
   -- This procedure is used to fetch the staging table data to flat file
   -------------------------------------------------------------------------
   PROCEDURE ps_extr (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_cycle_date             IN       VARCHAR2
     ,p_batch_num              IN       NUMBER
     ,p_debug                  IN       VARCHAR2
     ,p_process_type           IN       VARCHAR2
     ,p_action_type            IN       VARCHAR2 );

   /*====================================================+
   |   Record Type Declaration                           |
   |                                                     |
   |   Name: Payment Schedules                           |
   +=====================================================*/
   /*TYPE ps_rec_type IS RECORD (
	      customer_id                   ar_payment_schedules.customer_id%TYPE
	     ,payment_schedule_id           ar_payment_schedules.payment_schedule_id%TYPE
	     ,trx_rec_id                    ar_payment_schedules.customer_trx_id%TYPE
	     ,trx_rec_number                ar_payment_schedules.trx_number%TYPE
	     ,due_date                      ar_payment_schedules.due_date%TYPE
	     ,amount_due_original           ar_payment_schedules.amount_due_original%TYPE
	     ,amount_due_remaining          ar_payment_schedules.amount_due_remaining%TYPE
	     ,status                        ar_payment_schedules.status%TYPE
	     ,invoice_currency_code         ar_payment_schedules.invoice_currency_code%TYPE
	     ,CLASS                         ar_payment_schedules.CLASS%TYPE
	     ,amount_applied                ar_payment_schedules.amount_applied%TYPE
	     ,amount_credited               ar_payment_schedules.amount_credited%TYPE
	     ,amount_adjusted               ar_payment_schedules.amount_adjusted%TYPE
	     ,amount_in_dispute             ar_payment_schedules.amount_in_dispute%TYPE
	     ,discount_taken_earned         ar_payment_schedules.discount_taken_earned%TYPE
	     ,discount_taken_unearned       ar_payment_schedules.discount_taken_unearned%TYPE
	     ,tax_amount                    ar_payment_schedules.tax_original%TYPE
	     ,tax_amount_remaining          ar_payment_schedules.tax_remaining%TYPE
	     ,gl_date_closed                ar_payment_schedules.gl_date_closed%TYPE
	     ,creation_date                 xx_ar_ps_wc_stg.creation_date%TYPE
	     ,created_by                    xx_ar_ps_wc_stg.created_by%TYPE
	     ,request_id                    xx_ar_ps_wc_stg.request_id%TYPE
	     ,pmt_creation_date             xx_ar_ps_wc_stg.pmt_creation_date%TYPE
	     ,ext_type                      xx_ar_ps_wc_stg.ext_type%TYPE
	     ,cycle_date                    xx_ar_ps_wc_stg.cycle_date%TYPE
	     ,batch_num                     xx_ar_ps_wc_stg.batch_num%TYPE
	     ,customer_trx_id               ar_payment_schedules.customer_trx_id%TYPE
	     ,cash_receipt_id               ar_payment_schedules.cash_receipt_id%TYPE
   );*/
   -- Changed for R12 Retrofit 
   TYPE ps_rec_type IS RECORD (
      customer_id                   ar_payment_schedules_all.customer_id%TYPE
     ,payment_schedule_id           ar_payment_schedules_all.payment_schedule_id%TYPE
     ,trx_rec_id                    ar_payment_schedules_all.customer_trx_id%TYPE
     ,trx_rec_number                ar_payment_schedules_all.trx_number%TYPE
     ,due_date                      ar_payment_schedules_all.due_date%TYPE
     ,amount_due_original           ar_payment_schedules_all.amount_due_original%TYPE
     ,amount_due_remaining          ar_payment_schedules_all.amount_due_remaining%TYPE
     ,status                        ar_payment_schedules_all.status%TYPE
     ,invoice_currency_code         ar_payment_schedules_all.invoice_currency_code%TYPE
     ,CLASS                         ar_payment_schedules_all.CLASS%TYPE
     ,amount_applied                ar_payment_schedules_all.amount_applied%TYPE
     ,amount_credited               ar_payment_schedules_all.amount_credited%TYPE
     ,amount_adjusted               ar_payment_schedules_all.amount_adjusted%TYPE
     ,amount_in_dispute             ar_payment_schedules_all.amount_in_dispute%TYPE
     ,discount_taken_earned         ar_payment_schedules_all.discount_taken_earned%TYPE
     ,discount_taken_unearned       ar_payment_schedules_all.discount_taken_unearned%TYPE
     ,tax_amount                    ar_payment_schedules_all.tax_original%TYPE
     ,tax_amount_remaining          ar_payment_schedules_all.tax_remaining%TYPE
     ,gl_date_closed                ar_payment_schedules_all.gl_date_closed%TYPE
     ,creation_date                 xx_ar_ps_wc_stg.creation_date%TYPE
     ,created_by                    xx_ar_ps_wc_stg.created_by%TYPE
     ,request_id                    xx_ar_ps_wc_stg.request_id%TYPE
     ,pmt_creation_date             xx_ar_ps_wc_stg.pmt_creation_date%TYPE
     ,ext_type                      xx_ar_ps_wc_stg.ext_type%TYPE
     ,cycle_date                    xx_ar_ps_wc_stg.cycle_date%TYPE
     ,batch_num                     xx_ar_ps_wc_stg.batch_num%TYPE
     ,customer_trx_id               ar_payment_schedules_all.customer_trx_id%TYPE
     ,cash_receipt_id               ar_payment_schedules_all.cash_receipt_id%TYPE
   );

   -------------------------------
   --Table type declaration
   -------------------------------
   TYPE ps_tbl_type IS TABLE OF ps_rec_type;

   TYPE reqid_tbl_type IS TABLE OF NUMBER
      INDEX BY BINARY_INTEGER;

   TYPE filename_tbl_type IS TABLE OF VARCHAR2 (240)
      INDEX BY BINARY_INTEGER;
END XX_AR_PS_WC_PKG;
/
