CREATE OR REPLACE TYPE "XX_CRM_AGING_BUCKET_OBJ"
AS
  OBJECT
  (
    CUST_ACCOUNT_ID     NUMBER,
    PARTY_NAME          VARCHAR2(100),
    ACCOUNT_NUMBER      VARCHAR2(40),
    PARTY_NUMBER        VARCHAR2(40),
    PAYMENT_TERMS       VARCHAR2(50),
    TOTAL_DUE           NUMBER,
    CURR                NUMBER,
    PD1_30              NUMBER,
    PD31_60             NUMBER,
    PD61_90             NUMBER,
    PD91_180            NUMBER,
    PD181_365           NUMBER,
    PD_366              NUMBER,
    DISPUTED_TOTAL_AGED NUMBER,
    COLLECTOR_CODE      VARCHAR2(50),
    AOPS_NUM            VARCHAR2(60),
    ACCT_EST_DATE       VARCHAR2(60),
    CREDIT_LIMIT        NUMBER,
    STATIC
  FUNCTION CREATE_OBJECT(
      P_CUST_ACCOUNT_ID     IN NUMBER   :=NULL,
      P_PARTY_NAME          IN VARCHAR2 :=NULL,
      P_ACCOUNT_NUMBER      IN VARCHAR2 :=NULL,
      P_PARTY_NUMBER        IN VARCHAR2 :=NULL,
      P_PAYMENT_TERMS       IN VARCHAR2 :=NULL,
      P_TOTAL_DUE           IN NUMBER   :=NULL,
      P_CURR                IN NUMBER   :=NULL,
      P_PD1_30              IN NUMBER   :=NULL,
      P_PD31_60             IN NUMBER   :=NULL,
      P_PD61_90             IN NUMBER   :=NULL,
      P_PD91_180            IN NUMBER   :=NULL,
      P_PD181_365           IN NUMBER   :=NULL,
      P_PD_366              IN NUMBER   :=NULL,
      P_DISPUTED_TOTAL_AGED IN NUMBER   :=NULL,
      P_COLLECTOR_CODE      IN VARCHAR2 :=NULL,
      P_AOPS_NUM            IN VARCHAR2 :=NULL,
      P_ACCT_EST_DATE       IN VARCHAR2 :=NULL,
      P_CREDIT_LIMIT        IN NUMBER   :=NULL )
    RETURN XX_CRM_AGING_BUCKET_OBJ );
 
CREATE OR REPLACE TYPE "XX_CRM_AGING_BUCKET_OBJS"
AS
  TABLE OF XX_CRM_AGING_BUCKET_OBJ;
