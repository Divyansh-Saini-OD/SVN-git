SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                  Office Depot - Project Simplify                                           |
-- +============================================================================================+
-- | Name        : XX_SFDC_CUST_CONV_PVT.pkb                                                    |
-- | Description : SFDC Conversion                                                              |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        26-Aug-2011     Indra Varada        Initial version                              |
-- |1.1       18-May-2016   Shubashree R     Removed the schema reference for GSCC compliance QC#37898|
-- |1.2        03-Jun-2016     Shubhashree R       Removed the procedures for TOPS Retirement   |
-- |                                               insert_XX_CRM_EXP_SITE, insert_XX_CRM_EXP_CONTACT, INS_XX_CRM_EXP_CUST_SITE_DELTA, INS_XX_CRM_EXP_PROS_SITE_DELTA|
-- +============================================================================================+

create or replace
PACKAGE BODY XX_SFDC_CUST_CONV_PVT AS

FUNCTION sfdc_isValidEmail (
pEmail IN VARCHAR2
) RETURN VARCHAR2
IS

 cEmailRegexp CONSTANT VARCHAR2(1000) := '^[a-z0-9!#$%&''*+/=?^_`{|}~-]+(\.[a-z0-9!#$%&''*+/=?^_`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+([A-Z]{2}|arpa|biz|com|info|intww|name|net|org|pro|aero|asia|cat|coop|edu|gov|jobs|mil|mobi|museum|pro|tel|travel|post)$';

BEGIN

   IF REGEXP_LIKE(pEmail,cEmailRegexp,'i') THEN
     RETURN pEmail;
   ELSE
     RETURN NULL;
   END IF;

EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END sfdc_isValidEmail;

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
    SECTOR                       VARCHAR2,
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
  )
  IS
  BEGIN
     x_ret_msg := 'S';

     INSERT INTO XX_CRM_EXP_ACCOUNT
          (
           BATCH_ID,
           RECORD_ID,
           ORACLE_PARTY_ID,
           ACCOUNT_NAME,
           ACCOUNT_LEGAL_NAME,
           AOPS_CUST_ID,
           GPARENT_GPID,
           AOPS_PARENT_CUST_ID,
           PARENT_ID,
           ORACLE_PARENT_ACCOUNT_ID,
           SEGMENT,
           SECTOR,
           DUNS_NUMBER,
           SIC_CODE,
           TOTAL_EMPLOYEES,
           OD_WCW,
           DNB_WCW,
           ACCOUNT_TYPE,
           BILLING_STREET,
           BILLING_CITY,
           BILLING_STATE,
           BILLING_ZIP,
           BILLING_COUNTRY,
           SHIPPING_STREET,
           SHIPPING_CITY,
           SHIPPING_STATE,
           SHIPPING_ZIP,
           SHIPPING_COUNTRY,
           PHONE,
           PHONE_EXT,
           OD_SIC_GROUP,
           DNB_SIC_GROUP,
           CREATED_BY_ID,
           CREATED_DATE,
           OWNER_ID,
           LAST_MODIFIED_BY_ID,
           LAST_MODIFIED_DATE,
           ORACLE_PARTY_NUMBER,
           STATUS,
           REVENUE_BAND,
           LOYALTY_TYPE,
           LOAD_STATUS,
           SFDC_RECORD_TYPE_ID,
           RECORD_TYPE,
           GP_ID
           )
           VALUES
           (
           BATCH_ID,
           XXCRM.XX_CRM_EXP_ACCOUNT_S.nextval,
           EBIZ_PARTY_ID,
           NAME,
           LEGAL_NAME,
           AOPS_CUST_ID,
           GRANDPARENT_ID,
           PARENT_AOPS_CUST_ID,
           PARENT_EBIZ_PARTY_ID,
           PARENT_EBIZ_ACCOUNT_ID,
           SEGMENT,
           SECTOR,
           DECODE(DUNS_NUMBER,'#N/A',DUNS_NUMBER,LPAD(REPLACE(DUNS_NUMBER,'-',NULL),9,0)),
           SIC_CODE,
           TOTAL_EMPLOYEES,
           REPLACE(OD_WCW,',',NULL),
           REPLACE(DNB_WCW,',',NULL),
           TYPE,
           BILLING_STREET,
           BILLING_CITY,
           BILLING_STATE,
           BILLING_POSTALCODE,
           BILLING_COUNTRY,
           SHIPPING_STREET,
           SHIPPING_CITY,
           SHIPPING_STATE,
           SHIPPING_POSTALCODE,
           SHIPPING_COUNTRY,
           PHONE,
           PHONE_EXT,
           INDUSTRY_OD_SIC_REP,
           INDUSTRY_OD_SIC_DNB,
           CREATED_BY,
           TO_CHAR(CREATION_DATE,date_format),
           OWNER_ID,
           LAST_MODIFIED_BY,
           TO_CHAR(LAST_MODIFIED_DATE,date_format),
           EBIZ_PARTY_NUMBER,
           DECODE(STATUS,'A','Active','Inactive'),
           REVENUE_BAND,
           LOYALTY_TYPE,
           'NEW',
           SFDC_RECORD_TYPE_ID,
           RECORD_TYPE,
           GP_ID
           );

  EXCEPTION WHEN OTHERS THEN
   x_ret_status := 'E';
   x_ret_msg    := SQLERRM;
  END;

  PROCEDURE insert_XX_CRM_EXP_CUST_HIER (
    BATCH_ID                     NUMBER,
    EBIZ_PARTY_ID                NUMBER,
    GRANDPARENT_ID               VARCHAR2,
    PARENT_AOPS_CUST_ID          VARCHAR2,
    PARENT_EBIZ_PARTY_ID         VARCHAR2,
    SFDC_RECORD_TYPE_ID          VARCHAR2,
    x_ret_status           OUT   VARCHAR2,
    x_ret_msg              OUT   VARCHAR2
  )
  IS
  BEGIN
     x_ret_msg := 'S';

     INSERT INTO XX_CRM_EXP_CUST_HIER
          (
           BATCH_ID,
           RECORD_ID,
           ORACLE_PARTY_ID,
           GPARENT_GPID,
           AOPS_PARENT_CUST_ID,
           PARENT_ID,
           LOAD_STATUS,
           SFDC_RECORD_TYPE_ID
           )
           VALUES
           (
           BATCH_ID,
           XXCRM.XX_CRM_EXP_CUST_HIER_S.nextval,
           EBIZ_PARTY_ID,
           GRANDPARENT_ID,
           PARENT_AOPS_CUST_ID,
           PARENT_EBIZ_PARTY_ID,
           'NEW',
           SFDC_RECORD_TYPE_ID
           );

  EXCEPTION WHEN OTHERS THEN
   x_ret_status := 'E';
   x_ret_msg    := SQLERRM;
  END;

END XX_SFDC_CUST_CONV_PVT;
/
SHOW ERRORS;