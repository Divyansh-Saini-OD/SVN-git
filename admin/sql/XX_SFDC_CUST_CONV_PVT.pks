SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                  Office Depot - Project Simplify                                           |
-- +============================================================================================+
-- | Name        : XX_SFDC_CUST_CONV_PVT.pks                                                    |
-- | Description : SFDC Conversion                                                              |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        26-Aug-2011     Indra Varada        Initial version                              |
-- |1.1        03-Jun-2016     Shubhashree R       Removed the procedures for TOPS Retirement   |
-- |                                               insert_XX_CRM_EXP_SITE, insert_XX_CRM_EXP_CONTACT, INS_XX_CRM_EXP_CUST_SITE_DELTA, INS_XX_CRM_EXP_PROS_SITE_DELTA|
-- +============================================================================================+

create or replace
PACKAGE XX_SFDC_CUST_CONV_PVT AS

 date_format      VARCHAR2(50) := 'MM/dd/yyyy HH:mm:ss';

  PROCEDURE insert_XX_CRM_EXP_ACCOUNT (
    BATCH_ID                     NUMBER,
    EBIZ_PARTY_ID                NUMBER,
    NAME                         VARCHAR2,
    LEGAL_NAME                   VARCHAR2,
    GP_LEGAL_FLAG                VARCHAR2,
    AOPS_CUST_ID                 VARCHAR2,
    GRANDPARENT_ID               NUMBER,
    PARENT_AOPS_CUST_ID          VARCHAR2,
    PARENT_EBIZ_PARTY_ID         NUMBER,
    PARENT_EBIZ_ACCOUNT_ID       NUMBER,
    SEGMENT                      VARCHAR2,
    SECTOR                     VARCHAR2,
    DUNS_NUMBER                  VARCHAR2,
    SIC_CODE                     VARCHAR2,
    TOTAL_EMPLOYEES              VARCHAR2,
    OD_WCW                       VARCHAR2,
    DNB_WCW                      VARCHAR2,
    TYPE                         VARCHAR2,
    BILLING_STREET               VARCHAR2,
    BILLING_CITY                 VARCHAR2,
    BILLING_STATE                VARCHAR2,
    BILLING_POSTALCODE           VARCHAR2,
    BILLING_COUNTRY              VARCHAR2,
    SHIPPING_STREET              VARCHAR2,
    SHIPPING_CITY                VARCHAR2,
    SHIPPING_STATE               VARCHAR2,
    SHIPPING_POSTALCODE          VARCHAR2,
    SHIPPING_COUNTRY             VARCHAR2,
    PHONE                        VARCHAR2,
    PHONE_EXT                    VARCHAR2,
    INDUSTRY_OD_SIC_REP          VARCHAR2,
    INDUSTRY_OD_SIC_DNB          VARCHAR2,
    CREATED_BY                   VARCHAR2,
    CREATION_DATE                DATE,
    OWNER_ID                     VARCHAR2,
    LAST_MODIFIED_BY             VARCHAR2,
    LAST_MODIFIED_DATE           DATE,
    EBIZ_PARTY_NUMBER            VARCHAR2,
    STATUS                       VARCHAR2,
    REVENUE_BAND                 VARCHAR2,
    LOYALTY_TYPE                 VARCHAR2,
    SFDC_RECORD_TYPE_ID          VARCHAR2,
    RECORD_TYPE                  VARCHAR2,
    GP_ID                        NUMBER,
    x_ret_status           OUT   VARCHAR2,
    x_ret_msg              OUT   VARCHAR2
  );

  PROCEDURE insert_XX_CRM_EXP_CUST_HIER (
    BATCH_ID                     NUMBER,
    EBIZ_PARTY_ID                NUMBER,
    GRANDPARENT_ID               VARCHAR2,
    PARENT_AOPS_CUST_ID          VARCHAR2,
    PARENT_EBIZ_PARTY_ID         VARCHAR2,
    SFDC_RECORD_TYPE_ID          VARCHAR2,
    x_ret_status           OUT   VARCHAR2,
    x_ret_msg              OUT   VARCHAR2
  );

END XX_SFDC_CUST_CONV_PVT;
/
SHOW ERRORS;
