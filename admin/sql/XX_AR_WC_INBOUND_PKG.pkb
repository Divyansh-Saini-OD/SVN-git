PROMPT "Creating Package Body XX_AR_WC_INBOUND_PKG ..."

CREATE OR REPLACE PACKAGE BODY APPS.XX_AR_WC_INBOUND_PKG
AS
   /*====================================================================+
   |      office depot - project fit                                     |
   |   capgemini/office depot/consulting organization                    |
   +=====================================================================+
   |name        :xx_ar_wc_inbound_pkg                                    |
   |rice        :                                                        |
   |description :this package is used for insert data into staging       |
   |             table and fetch data from staging table to flat file    |
   |                                                                     |
   |                                                                     |
   |change record:                                                       |
   |==============                                                       |
   |version    date           author                       remarks       |
   |=======   ======       =====================      ===============    |
   |1.00     21-sep-2011   TJ sanjeeva                initial version    |
   |                                                                     |
   +=====================================================================*/
   PROCEDURE insert_stg (
      p_trx_category         IN       VARCHAR2
     ,p_wc_id                IN       VARCHAR2
     ,p_customer_trx_id      IN       NUMBER
     ,p_transaction_number   IN       VARCHAR2
     ,p_dispute_number       IN       VARCHAR2
     ,p_cust_account_id      IN       NUMBER
     ,p_cust_acct_number     IN       VARCHAR2
     ,p_bill_to_site_id      IN       NUMBER
     ,p_amount               IN       NUMBER
     ,p_currency_code        IN       VARCHAR2
     ,p_reason_code          IN       VARCHAR2
     ,p_comments             IN       VARCHAR2
     ,p_request_date         IN       DATE
     ,p_requested_by         IN       VARCHAR2
     ,p_send_refund          IN       VARCHAR2
     ,p_transaction_type     IN       VARCHAR2
     ,p_dispute_status       IN       VARCHAR2
     ,p_trx_status           OUT      VARCHAR2
     ,p_trx_message          OUT      VARCHAR2
   )
   AS
   BEGIN
      INSERT INTO xx_ar_wc_inbound_stg
                  (trx_category
                  ,wc_id
                  ,customer_trx_id
                  ,transaction_number
                  ,dispute_number
                  ,cust_account_id
                  ,cust_acct_number
                  ,bill_to_site_id
                  ,amount
                  ,currency_code
                  ,reason_code
                  ,comments
                  ,request_date
                  ,requested_by
                  ,send_refund
                  ,adj_activity_name
                  ,dispute_status
                  ,trx_status
                  ,trx_message
                  ,creation_date
                  ,created_by
                  ,last_update_date
                  ,last_updated_by
                  )
           VALUES (p_trx_category
                  ,p_wc_id
                  ,p_customer_trx_id
                  ,p_transaction_number
                  ,p_dispute_number
                  ,p_cust_account_id
                  ,p_cust_acct_number
                  ,p_bill_to_site_id
                  ,p_amount
                  ,p_currency_code
                  ,p_reason_code
                  ,p_comments
                  ,p_request_date
                  ,p_requested_by
                  ,p_send_refund
                  ,p_transaction_type
                  ,p_dispute_status
                  ,p_trx_status
                  ,p_trx_message
                  ,SYSDATE
                  ,-1
                  ,SYSDATE
                  ,-1
                  );

      p_trx_status := 'S';
      p_trx_message := 'Record is inserted in xx_ar_wc_inbound_stg table';
   EXCEPTION
      WHEN OTHERS
      THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error' || '-' || SQLERRM);
         p_trx_status := 'E';
         p_trx_message := 'Error while inserting Record in xx_ar_wc_inbound_stg table' || '-' || SQLERRM;
   END;
END XX_AR_WC_INBOUND_PKG;
/

SHOW error
