PROMPT "Creating Package XX_AR_WC_INBOUND_PKG ..."

CREATE OR REPLACE PACKAGE APPS.XX_AR_WC_INBOUND_PKG
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
      P_TRX_CATEGORY         IN       VARCHAR2
     ,P_WC_ID                IN       VARCHAR2
     ,P_CUSTOMER_TRX_ID      IN       NUMBER
     ,P_TRANSACTION_NUMBER   IN       VARCHAR2
     ,P_DISPUTE_NUMBER       IN       VARCHAR2
     ,P_CUST_ACCOUNT_ID      IN       NUMBER
     ,P_CUST_ACCT_NUMBER     IN       VARCHAR2
     ,P_BILL_TO_SITE_ID      IN       NUMBER
     ,P_AMOUNT               IN       NUMBER
     ,P_CURRENCY_CODE        IN       VARCHAR2
     ,P_REASON_CODE          IN       VARCHAR2
     ,P_COMMENTS             IN       VARCHAR2
     ,P_REQUEST_DATE         IN       DATE
     ,P_REQUESTED_BY         IN       VARCHAR2
     ,P_SEND_REFUND          IN       VARCHAR2
     ,P_TRANSACTION_TYPE     IN       VARCHAR2
     ,P_DISPUTE_STATUS       IN       VARCHAR2
     ,P_TRX_STATUS           OUT      VARCHAR2
     ,P_TRX_MESSAGE          OUT      VARCHAR2
   );
END XX_AR_WC_INBOUND_PKG;
/
show errors
