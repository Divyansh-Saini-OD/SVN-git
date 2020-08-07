CREATE OR REPLACE PACKAGE XX_AR_RECON_TO_WC_PKG
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
   |Version    Date         Author               Remarks                       |
   |=========  ===========  ===================  ==============================|
   |  1.0      03-OCT-2011  Maheswararao N       Created this package.         |
   |                                                                           |
   |  1.1      19-DEC-2011  Maheswararao N       Modified as per rick comments |
   |                                                                           |
   |  1.2      07-MAR-2012  R.Aldridge           Defect 17213 - Changes for    | 
   |                                             customer_id difference        |
   |                                             (override pmt sch cust ID)    |   
   |                                                                           |
   |  1.3      05-MAR-2012  R.Aldridge           Defect 17213 - Changes for    | 
   |                                             customer_id difference        |
   |                                             (revert to revision 156773)   |   
   |                                                                           |
   |  1.4      07-MAR-2012  R.Aldridge           Defect 17213 - Changes for    | 
   |                                             customer_id difference        |
   |                                             (override receipt cust ID)    |   
   +=========================================================================+*/

   --This procedure is used to register through a concurrent program to fetch the 
   --all open transactions from ar_payment_schedules_all to custom table (XX_AR_RECON_OPEN_ITM )
   PROCEDURE aps_opentrans_dump (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER    
     ,p_debug           IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2   
   );

   -- This procedure is used to register through a concurrent program 
   -- and calls the above procedures.
   PROCEDURE ar_recon_main (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER     
     ,p_debug           IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
     ,p_process_type    IN       VARCHAR2
   );

-- Record type declaration
   TYPE recon_rec_type IS RECORD (
      customer_number        xx_ar_recon_trans_stg.customer_number%TYPE
     ,cust_account_id        xx_ar_recon_trans_stg.cust_account_id%TYPE
     ,customer_site_use_id   xx_ar_recon_trans_stg.customer_site_use_id%TYPE
     ,customer_name          xx_ar_recon_trans_stg.customer_name%TYPE
     ,ap_dunning_contact     xx_ar_recon_trans_stg.ap_dunning_contact%TYPE
     ,collector_id           xx_ar_recon_trans_stg.collector_id%TYPE
     ,collector_name         xx_ar_recon_trans_stg.collector_name%TYPE
     ,org_id                 xx_ar_recon_trans_stg.org_id%TYPE
     ,currency               xx_ar_recon_trans_stg.currency%TYPE
     ,trx_number             xx_ar_recon_trans_stg.trx_number%TYPE
     ,open_balance           xx_ar_recon_trans_stg.open_balance%TYPE
     ,TYPE                   xx_ar_recon_trans_stg.TYPE%TYPE
     ,cust_trx_id            xx_ar_recon_trans_stg.cust_trx_id%TYPE
     ,cash_receipt_id        xx_ar_recon_trans_stg.cash_receipt_id%TYPE
     ,creation_date          xx_ar_recon_trans_stg.creation_date%TYPE
     ,created_by             xx_ar_recon_trans_stg.created_by%TYPE
     ,request_id             xx_ar_recon_trans_stg.request_id%TYPE     
   );

-- Table type declaration
   TYPE recon_tbl_type IS TABLE OF recon_rec_type;

   TYPE req_number_tbl_type IS TABLE OF fnd_concurrent_requests.request_id%TYPE
      INDEX BY PLS_INTEGER;

   TYPE file_name_tbl_type IS TABLE OF VARCHAR2 (240)
      INDEX BY PLS_INTEGER;

END XX_AR_RECON_TO_WC_PKG;
/

SHOW ERRORS;