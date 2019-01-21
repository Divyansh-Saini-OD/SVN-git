SET SHOW OFF;
SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;

WHENEVER SQLERROR CONTINUE;

WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE XX_CRM_CUST360INFO_PKG
--+======================================================================+
--|      Office Depot -                                                  |
--+======================================================================+
--|Name       : XX_CRM_CUST360INFO_PKG.pks                               |
--|Description: This Package is used for returning resultsets for each   |
--|             query in Customer 360 application                        |
--|                                                                      |
--| History                                                              |
--| 20-Sep-2012   Sreedhar Mohan  Intial Draft                           |
--+======================================================================+
AS

TYPE AR_COLLECTOR_TYP IS RECORD ( 
    COLLECTOR_NAME                VARCHAR2(360),
    COLLECTOR_EMP_NUMBER          VARCHAR2(30),
    COLLECTOR_EMAIL_ADDRESS       VARCHAR2(2000), 
    COLLECTOR_SUPERVISOR_NAME     VARCHAR2(360),
    COLLECTOR_SUPERVISOR_EMAIL    VARCHAR2(2000),
    COLLECTOR_PHONE_NUMBER        VARCHAR2(25),
    COLLECTOR_FAX_NUMBER          VARCHAR2(25),
    COLLECTOR_SUP_PHONE_NUMBER    VARCHAR2(25),
    COLLECTOR_SUP_FAX_NUMBER      VARCHAR2(25)
);

TYPE GRAND_PARENT_TYP IS RECORD ( 
    GP_ID                         NUMBER,
    GP_NAME                       VARCHAR2(360),
    ORIG_SYSTEM_REFERENCE         VARCHAR2(255)
);  

TYPE CREDIT_LIMTS_TYP IS RECORD ( 
    CURRENCY_CODE                VARCHAR2(15),
    OVERALL_CREDIT_LIMIT         NUMBER,
    TRX_CREDIT_LIMIT             NUMBER
); 

TYPE AGING_BUCKET_TYP IS RECORD ( 
    CURRENT_BAL                  NUMBER,
    DAYS_1_30                    NUMBER,
    DAYS_31_60                   NUMBER,
    DAYS_61_90                   NUMBER,
    DAYS_91_180                  NUMBER,
    DAYS_181_365                 NUMBER,
    DAYS_366_PLUS                NUMBER
); 

TYPE EBILL_CONTACT_TYP IS RECORD ( 
    RESP_TYPE                    VARCHAR2(30),
    CONTACT_POINT_ID             NUMBER(15),
    SALUTATION                   VARCHAR2(60),
    PARTY_ID                     NUMBER(15),
    FIRST_NAME                   VARCHAR2(150),
    LAST_NAME                    VARCHAR2(150),
    JOB_TITLE                    VARCHAR2(100),
    CONTACT_POINT_TYPE           VARCHAR2(30),
    EMAIL_ADDRESS                VARCHAR2(2000),
    PHONE_LN_TYPE                VARCHAR2(30),
    PHONE_LN_TYPE_DESC           VARCHAR2(80),
    PHONE_COUNTRY_CODE           VARCHAR2(10),
    PHONE_AREA_CODE              VARCHAR2(10),
    PHONE_NUMBER                 VARCHAR2(40),
    EXTENSION                    VARCHAR2(20),
    PRIMARY_CONTACT_POINT        VARCHAR2(1),
    PREFERRED_FLAG               VARCHAR2(1)
);    

TYPE PAYMENT_TERMS_TYP IS RECORD ( 
    AB_BILLING_FLAG              VARCHAR2(1),
    PAYMENT_TERM                 VARCHAR2(15),
    PAYTERM_FREQUENCY            VARCHAR2(150),
    PAYTERM_REPORTING_DAY        VARCHAR2(150),
    PAYTERM_PERCENTAGE           VARCHAR2(150),
    BILLDOCS_DOC_TYPE            VARCHAR2(150),
    BILLDOCS_DELIVERY_METH       VARCHAR2(150),
    BILLDOCS_SPECIAL_HANDLING    VARCHAR2(150),
    BILLDOCS_SIG_REQ             VARCHAR2(150),
    BILLDOCS_DIRECT_FLAG         VARCHAR2(150),
    BILLDOCS_AUTO_REPRINT        VARCHAR2(150),
    BILLDOCS_COMMENTS1           VARCHAR2(150),
    BILLDOCS_COMMENTS2           VARCHAR2(150),
    BILLDOCS_COMMENTS3           VARCHAR2(150),
    BILLDOCS_COMMENTS4           VARCHAR2(150),
    BILLDOCS_MAIL_ATTENTION      VARCHAR2(150),
    BILLDOCS_EFF_FROM_DATE       DATE,
    BILLDOCS_EFF_TO_DATE         DATE,
    LOCATION_ID                  NUMBER(15),
    ADDRESS1                     VARCHAR2(240),
    ADDRESS2                     VARCHAR2(240),
    CITY                         VARCHAR2(60),
    POSTAL_CODE                  VARCHAR2(60),
    STATE                        VARCHAR2(60),
    PROVINCE                     VARCHAR2(60),
    COUNTY                       VARCHAR2(60),
    COUNTRY                      VARCHAR2(60)
);

TYPE AR_COLLECTOR_INFO    IS TABLE OF AR_COLLECTOR_TYP;
TYPE GRAND_PARENT_INFO    IS TABLE OF GRAND_PARENT_TYP;
TYPE CREDIT_LIMTS_INFO    IS TABLE OF CREDIT_LIMTS_TYP;
TYPE AGING_BUCKET_INFO    IS TABLE OF AGING_BUCKET_TYP;
TYPE EBILL_CONTACT_INFO   IS TABLE OF EBILL_CONTACT_TYP;
TYPE PAYMENT_TERMS_INFO   IS TABLE OF PAYMENT_TERMS_TYP;


TYPE FULL_CUST_INFO_REC_TYP IS RECORD(
  AR_COLLECTOR_TAB            AR_COLLECTOR_INFO, 
  GRAND_PARENT_TAB            GRAND_PARENT_INFO, 
  CREDIT_LIMTS_TAB            CREDIT_LIMTS_INFO, 
  AGING_BUCKET_TAB            AGING_BUCKET_INFO, 
  EBILL_CONTACT_TAB           EBILL_CONTACT_INFO,
  PAYMENT_TERMS_TAB           PAYMENT_TERMS_INFO 
);

PROCEDURE GET_CUST_INFO (
  P_AOPS_ACCT_ID  IN   NUMBER,
  P_CUST_OUT      OUT  FULL_CUST_INFO_REC_TYP
);


END XX_CRM_CUST360INFO_PKG;
/
SHOW ERR;