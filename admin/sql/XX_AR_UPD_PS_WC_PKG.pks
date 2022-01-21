CREATE OR REPLACE PACKAGE XX_AR_UPD_PS_WC_PKG
AS
--+==========================================================================================+
--|      Office Depot - Project FIT                                                          |
--|   Capgemini/Office Depot/Consulting Organization                                         |
--+==========================================================================================+
--|Name        :XX_AR_UPD_PS_WC_PKG                                                          |
--|RICE        :                                                                             |
--|Description :This Package is used for insert PS data into staging                         |
--|             table for newly eligible customers on CDH eligible table                     |
--|                                                                                          |
--|Change Record:                                                                            |
--|==============                                                                            |
--|Version    Date           Author                       Remarks                            |
--|=======   ======        ====================          =========                           |
--|1.0      03-NOV-2011    Maheswararao N              Initial Version                       |
--|                                                                                          |
--|                                                                                          |
--+==========================================================================================+

   -- This procedure is used to register through a concurrent program and calls the above procedures.
   PROCEDURE ar_upd_ps_main (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_debug           IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2    
   );

-- Record type declaration
   TYPE upd_ps_rec_type IS RECORD (
      PAYMENT_SCHEDULE_ID        ar_payment_schedules_all.PAYMENT_SCHEDULE_ID%TYPE
     ,STATUS                     ar_payment_schedules_all.STATUS%TYPE
     ,CLASS                      ar_payment_schedules_all.CLASS%TYPE
     ,CUST_TRX_TYPE_ID           ra_cust_trx_types_all.CUST_TRX_TYPE_ID%TYPE
     ,CUSTOMER_ID                ar_payment_schedules_all.CUSTOMER_ID%TYPE
     ,CUSTOMER_SITE_USE_ID       ar_payment_schedules_all.CUSTOMER_SITE_USE_ID%TYPE
     ,CUSTOMER_TRX_ID            ar_payment_schedules_all.CUSTOMER_TRX_ID%TYPE
     ,CASH_RECEIPT_ID            ar_payment_schedules_all.CASH_RECEIPT_ID%TYPE
     ,LAST_UPDATE_DATE           ar_payment_schedules_all.LAST_UPDATE_DATE%TYPE
     ,AMOUNT_DUE_ORIGINAL        ar_payment_schedules_all.AMOUNT_DUE_ORIGINAL%TYPE
     ,AMOUNT_DUE_REMAINING       ar_payment_schedules_all.AMOUNT_DUE_REMAINING%TYPE
     ,AMOUNT_APPLIED             ar_payment_schedules_all.AMOUNT_APPLIED%TYPE
     ,AMOUNT_ADJUSTED            ar_payment_schedules_all.AMOUNT_ADJUSTED%TYPE
     ,AMOUNT_IN_DISPUTE          ar_payment_schedules_all.AMOUNT_IN_DISPUTE%TYPE
     ,AMOUNT_CREDITED            ar_payment_schedules_all.AMOUNT_CREDITED%TYPE
     ,CASH_APPLIED_AMOUNT_LAST   ar_payment_schedules_all.CASH_APPLIED_AMOUNT_LAST%TYPE
     ,CASH_RECEIPT_AMOUNT_LAST   ar_payment_schedules_all.CASH_RECEIPT_AMOUNT_LAST%TYPE
     ,ADJUSTMENT_AMOUNT_LAST     ar_payment_schedules_all.ADJUSTMENT_AMOUNT_LAST%TYPE
     ,CREATION_DATE   		 ar_payment_schedules_all.CREATION_DATE%TYPE
     ,CREATED_BY		 ar_payment_schedules_all.CREATED_BY%TYPE
   );

-- Table type declaration
   TYPE upd_ps_tbl_type IS TABLE OF upd_ps_rec_type;
END XX_AR_UPD_PS_WC_PKG;
/

SHOW ERRORS;