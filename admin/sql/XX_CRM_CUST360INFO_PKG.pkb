SET SHOW OFF;
SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;

WHENEVER SQLERROR CONTINUE;

WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY XX_CRM_CUST360INFO_PKG
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
PROCEDURE GET_CUST_INFO (
                           P_AOPS_ACCT_ID  IN   NUMBER,
                           P_CUST_OUT      OUT  FULL_CUST_INFO_REC_TYP
)
AS

AR_COLLECTOR_TBL      AR_COLLECTOR_INFO;
GRAND_PARENT_TBL      GRAND_PARENT_INFO;
CREDIT_LIMTS_TBL      CREDIT_LIMTS_INFO;
AGING_BUCKET_TBL      AGING_BUCKET_INFO;
EBILL_CONTACT_TBL     EBILL_CONTACT_INFO;
PAYMENT_TERMS_TBL     PAYMENT_TERMS_INFO;

CUST360_INFO_REC      FULL_CUST_INFO_REC_TYP;

  CURSOR C_AR_COLLECTOR_INFO (P_AOPS_ACCT_ID NUMBER)
  IS
  SELECT RSC_EMP.SOURCE_NAME   COLLECTOR_NAME,
         COL.NAME              COLLECTOR_EMP_NUMBER,
         RSC_EMP.SOURCE_EMAIL  COLLECTOR_EMAIL_ADDRESS,
         RSC_SUP.SOURCE_NAME   COLLECTOR_SUPERVISOR_NAME,
         RSC_SUP.SOURCE_EMAIL  COLLECTOR_SUPERVISOR_EMAIL,
         DECODE(HP_EMP.PRIMARY_PHONE_LINE_TYPE,'PHONE',HP_EMP.PRIMARY_PHONE_NUMBER,NULL) COLLECTOR_PHONE_NUMBER,
         DECODE(HP_EMP.PRIMARY_PHONE_LINE_TYPE,'FAX',HP_EMP.PRIMARY_PHONE_NUMBER,NULL) COLLECTOR_FAX_NUMBER,
         DECODE(HP_SUPP.PRIMARY_PHONE_LINE_TYPE,'PHONE',HP_SUPP.PRIMARY_PHONE_NUMBER,NULL) COLLECTOR_SUP_PHONE_NUMBER,
         DECODE(HP_SUPP.PRIMARY_PHONE_LINE_TYPE,'FAX',HP_SUPP.PRIMARY_PHONE_NUMBER,NULL) COLLECTOR_SUP_FAX_NUMBER
  FROM APPS.HZ_CUSTOMER_PROFILES PROF,
    APPS.HZ_CUST_ACCOUNTS ACCT,
    APPS.AR_COLLECTORS COL,
    APPS.JTF_RS_RESOURCE_EXTNS RSC_EMP,
    APPS.JTF_RS_RESOURCE_EXTNS RSC_SUP,
    APPS.HZ_PARTIES HP_EMP,
    APPS.HZ_PARTIES HP_SUPP
  WHERE ACCT.CUST_ACCOUNT_ID     =PROF.CUST_ACCOUNT_ID
  AND COL.COLLECTOR_ID(+)        = PROF.COLLECTOR_ID
  AND ACCT.ORIG_SYSTEM_REFERENCE = LPAD(P_AOPS_ACCT_ID, 8, '0') || '-00001-A0'
  AND PROF.SITE_USE_ID      IS NULL
  AND COL.STATUS             ='A'
  AND RSC_EMP.RESOURCE_ID    =COL.RESOURCE_ID
  AND RSC_EMP.SOURCE_MGR_ID  =RSC_SUP.SOURCE_ID
  AND RSC_EMP.PERSON_PARTY_ID=HP_EMP.PARTY_ID
  AND RSC_SUP.PERSON_PARTY_ID=HP_SUPP.PARTY_ID
  AND ROWNUM                 = 1;
  
  CURSOR C_GRAND_PARENT_INFO (P_AOPS_ACCT_ID NUMBER)
  IS
  SELECT X.GP_ID                   GP_ID,
         X.GP_NAME                 GP_NAME,
         X.ORIG_SYSTEM_REFERENCE   ORIG_SYSTEM_REFERENCE
  FROM
    (SELECT  GP.GP_ID,
             GP.GP_NAME,
             ACT.ORIG_SYSTEM_REFERENCE
    FROM     APPS.HZ_CUST_ACCOUNTS ACT,
             APPS.HZ_RELATIONSHIPS GREL,
             APPS.XX_CDH_GP_MASTER GP
    WHERE    ACT.ORIG_SYSTEM_REFERENCE = LPAD(P_AOPS_ACCT_ID, 8, '0') || '-00001-A0'
    AND      GP.PARTY_ID            = GREL.SUBJECT_ID
    AND      ACT.PARTY_ID           = GREL.OBJECT_ID
    AND      GREL.RELATIONSHIP_CODE = 'GRANDPARENT'
    AND      GREL.RELATIONSHIP_TYPE = 'OD_CUST_HIER'
    AND      GREL.DIRECTION_CODE    = 'P'
    AND      GREL.STATUS            = 'A'
    AND      SYSDATE BETWEEN GREL.START_DATE AND GREL.END_DATE
    UNION
    SELECT   GP.GP_ID,
             GP.GP_NAME,
             ACT.ORIG_SYSTEM_REFERENCE
    FROM     APPS.HZ_CUST_ACCOUNTS ACT,
             APPS.HZ_RELATIONSHIPS GREL,
             APPS.HZ_RELATIONSHIPS PREL,
             APPS.XX_CDH_GP_MASTER GP
    WHERE    ACT.ORIG_SYSTEM_REFERENCE = LPAD(P_AOPS_ACCT_ID, 8, '0') || '-00001-A0'
      AND    GREL.OBJECT_ID         = PREL.SUBJECT_ID
      AND    GREL.SUBJECT_ID        = GP.PARTY_ID
      AND    ACT.PARTY_ID           = PREL.OBJECT_ID
      AND    GREL.RELATIONSHIP_CODE = 'GRANDPARENT'
      AND    GREL.RELATIONSHIP_TYPE = 'OD_CUST_HIER'
      AND    GREL.DIRECTION_CODE    = 'P'
      AND    GREL.STATUS            = 'A'
      AND    PREL.RELATIONSHIP_CODE = 'PARENT_COMPANY'
      AND    PREL.RELATIONSHIP_TYPE = 'OD_CUST_HIER'
      AND    PREL.DIRECTION_CODE    = 'P'
      AND    PREL.STATUS            = 'A'
      AND    SYSDATE BETWEEN GREL.START_DATE AND GREL.END_DATE
    ) X
  WHERE ROWNUM = 1;
  
  CURSOR C_CREDIT_LIMTS_INFO (P_AOPS_ACCT_ID NUMBER)
  IS
  SELECT HCPA.CURRENCY_CODE          CURRENCY_CODE,
         HCPA.OVERALL_CREDIT_LIMIT   OVERALL_CREDIT_LIMIT,
         HCPA.TRX_CREDIT_LIMIT       TRX_CREDIT_LIMIT
  FROM   APPS.HZ_CUST_ACCOUNTS       HCA,
         APPS.HZ_CUST_PROFILE_AMTS   HCPA
  WHERE  HCA.ORIG_SYSTEM_REFERENCE = LPAD(P_AOPS_ACCT_ID, 8, '0') || '-00001-A0'
    AND  HCPA.CUST_ACCOUNT_ID      = HCA.CUST_ACCOUNT_ID
    AND  SITE_USE_ID IS NULL
    AND  ROWNUM < 21
   ORDER BY
   CASE
     WHEN HCPA.CURRENCY_CODE = 'USD' THEN 
       0
     ELSE
       1
   END;

  CURSOR C_AGING_BUCKET_INFO (P_AOPS_ACCT_ID NUMBER)
  IS
  SELECT  SUM(
    CASE
      WHEN FLOOR(SYSDATE-DUE_DATE) BETWEEN -9999999 AND 0
      THEN AMOUNT_DUE_REMAINING
      ELSE 0
    END) CURRENT_BAL,
    SUM(
    CASE
      WHEN FLOOR(SYSDATE-DUE_DATE) BETWEEN 1 AND 30
      THEN AMOUNT_DUE_REMAINING
      ELSE 0
    END) DAYS_1_30,
    SUM(
    CASE
      WHEN FLOOR(SYSDATE-DUE_DATE) BETWEEN 31 AND 60
      THEN AMOUNT_DUE_REMAINING
      ELSE 0
    END) DAYS_31_60,
    SUM(
    CASE
      WHEN FLOOR(SYSDATE-DUE_DATE) BETWEEN 61 AND 90
      THEN AMOUNT_DUE_REMAINING
      ELSE 0
    END) DAYS_61_90,
    SUM(
    CASE
      WHEN FLOOR(SYSDATE-DUE_DATE) BETWEEN 91 AND 180
      THEN AMOUNT_DUE_REMAINING
      ELSE 0
    END) DAYS_91_180,
    SUM(
    CASE
      WHEN FLOOR(SYSDATE-DUE_DATE) BETWEEN 181 AND 365
      THEN AMOUNT_DUE_REMAINING
      ELSE 0
    END) DAYS_181_365,
    SUM(
    CASE
      WHEN FLOOR(SYSDATE-DUE_DATE) BETWEEN 366 AND 99999999
      THEN  AMOUNT_DUE_REMAINING 
      ELSE 0
    END) DAYS_366_PLUS
        FROM APPS.AR_PAYMENT_SCHEDULES_ALL ARPAYMENTSCHEDULESV,
          APPS.HZ_CUST_ACCOUNTS ACCT,
          APPS.AR_LOOKUPS AL
        WHERE  ARPAYMENTSCHEDULESV.CUSTOMER_ID           = ACCT.CUST_ACCOUNT_ID
        AND ARPAYMENTSCHEDULESV.STATUS                = 'OP'      
        AND ARPAYMENTSCHEDULESV.INVOICE_CURRENCY_CODE = 'USD'
        AND ACCT.ORIG_SYSTEM_REFERENCE = LPAD(P_AOPS_ACCT_ID, 8, '0') || '-00001-A0'
        AND AL.LOOKUP_TYPE                            ='ARI_PMT_APPROVAL_STATUS'
        AND AL.LOOKUP_CODE                            =NVL(ARPAYMENTSCHEDULESV.PAYMENT_APPROVAL,'PENDING')
      AND ARPAYMENTSCHEDULESV.CLASS IN  ('INV', 'DM', 'CB', 'DEP');

  CURSOR C_EBILL_CONTACT_INFO (P_AOPS_ACCT_ID NUMBER)
  IS
  SELECT RESP_TYPE ,
    CONTACT_POINT_ID,
    SALUTATION ,
    PARTY_ID,
    FIRST_NAME ,
    LAST_NAME ,
    JOB_TITLE ,
    CONTACT_POINT_TYPE ,
    EMAIL_ADDRESS ,
    PHONE_LN_TYPE,
    PHONE_LN_TYPE_DESC,
    PHONE_COUNTRY_CODE ,
    PHONE_AREA_CODE ,
    PHONE_NUMBER ,
    EXTENSION ,
    PRIMARY_CONTACT_POINT,
    PREFERRED_FLAG
  FROM
    (SELECT HRR.RESPONSIBILITY_TYPE RESP_TYPE ,
      HCP.CONTACT_POINT_ID CONTACT_POINT_ID,
      PARTY.SALUTATION SALUTATION ,
      PARTY.PARTY_ID,
      SUBSTRB (PARTY.PERSON_FIRST_NAME ,1 ,40 ) FIRST_NAME ,
      SUBSTRB (PARTY.PERSON_LAST_NAME ,1 ,50 ) LAST_NAME ,
      ORG_CONT.JOB_TITLE JOB_TITLE ,
      HCP.CONTACT_POINT_TYPE CONTACT_POINT_TYPE ,
      HCP.EMAIL_ADDRESS EMAIL_ADDRESS ,
      PHONE_LINE_TYPE PHONE_LN_TYPE,
      (SELECT MEANING
      FROM FND_LOOKUP_VALUES
      WHERE LOOKUP_TYPE = 'PHONE_LINE_TYPE'
      AND LANGUAGE      = SYS_CONTEXT('USERENV', 'LANG')
      AND LOOKUP_CODE   = PHONE_LINE_TYPE
      AND ROWNUM        =1
      ) PHONE_LN_TYPE_DESC,
      HCP.PHONE_COUNTRY_CODE PHONE_COUNTRY_CODE ,
      HCP.PHONE_AREA_CODE PHONE_AREA_CODE ,
      HCP.PHONE_NUMBER PHONE_NUMBER ,
      HCP.PHONE_EXTENSION EXTENSION ,
      HCP.PRIMARY_FLAG PRIMARY_CONTACT_POINT,
      HCP.PRIMARY_BY_PURPOSE PREFERRED_FLAG
    FROM HZ_CONTACT_POINTS HCP,
      HZ_CUST_ACCOUNT_ROLES ACCT_ROLE,
      HZ_PARTIES PARTY,
      HZ_PARTIES REL_PARTY,
      HZ_RELATIONSHIPS REL,
      HZ_ORG_CONTACTS ORG_CONT ,
      HZ_CUST_ACCOUNTS ROLE_ACCT,
      HZ_CONTACT_RESTRICTIONS CONT_RES,
      HZ_PERSON_LANGUAGE PER_LANG,
      HZ_ROLE_RESPONSIBILITY HRR
    WHERE ACCT_ROLE.PARTY_ID             = REL.PARTY_ID
    AND ACCT_ROLE.ROLE_TYPE              = 'CONTACT'
    AND ORG_CONT.PARTY_RELATIONSHIP_ID   = REL.RELATIONSHIP_ID
    AND REL.SUBJECT_ID                   = PARTY.PARTY_ID
    AND REL_PARTY.PARTY_ID               = REL.PARTY_ID
    AND HCP.OWNER_TABLE_ID(+)     = REL_PARTY.PARTY_ID
    AND HCP.CONTACT_POINT_TYPE(+) = 'EMAIL'
    AND HCP.PRIMARY_FLAG(+)       = 'Y'
    AND ACCT_ROLE.CUST_ACCOUNT_ID        = ROLE_ACCT.CUST_ACCOUNT_ID
    AND ROLE_ACCT.PARTY_ID               = REL.OBJECT_ID
    AND PARTY.PARTY_ID                   = PER_LANG.PARTY_ID(+)
    AND PER_LANG.NATIVE_LANGUAGE(+)      = 'Y'
    AND PARTY.PARTY_ID                   = CONT_RES.SUBJECT_ID(+)
    AND CONT_RES.SUBJECT_TABLE(+)        = 'HZ_PARTIES'
    AND HCP.OWNER_TABLE_NAME(+)   = 'HZ_PARTIES'
    AND HRR.RESPONSIBILITY_TYPE = 'BILLING'
    AND HRR.CUST_ACCOUNT_ROLE_ID = ACCT_ROLE.CUST_ACCOUNT_ROLE_ID
    AND ROLE_ACCT.ORIG_SYSTEM_REFERENCE  = LPAD(P_AOPS_ACCT_ID, 8, '0') || '-00001-A0'  
    UNION
    SELECT HRR.RESPONSIBILITY_TYPE RESP_TYPE,
          HCP.CONTACT_POINT_ID CONTACT_POINT_ID,
          PARTY.SALUTATION SALUTATION ,
          PARTY.PARTY_ID,
          SUBSTRB (PARTY.PERSON_FIRST_NAME ,1 ,40 ) FIRST_NAME ,
          SUBSTRB (PARTY.PERSON_LAST_NAME ,1 ,50 ) LAST_NAME ,
          ORG_CONT.JOB_TITLE JOB_TITLE ,
          HCP.CONTACT_POINT_TYPE CONTACT_POINT_TYPE ,
          HCP.EMAIL_ADDRESS EMAIL_ADDRESS ,
          PHONE_LINE_TYPE PHONE_LN_TYPE,
          (SELECT MEANING
          FROM FND_LOOKUP_VALUES
          WHERE LOOKUP_TYPE = 'PHONE_LINE_TYPE'
          AND LANGUAGE      = SYS_CONTEXT('USERENV', 'LANG')
          AND LOOKUP_CODE   = PHONE_LINE_TYPE
          AND ROWNUM        =1
          ) PHONE_LN_TYPE_DESC,
          HCP.PHONE_COUNTRY_CODE PHONE_COUNTRY_CODE ,
          HCP.PHONE_AREA_CODE PHONE_AREA_CODE ,
          HCP.PHONE_NUMBER PHONE_NUMBER ,
          HCP.PHONE_EXTENSION EXTENSION ,
          HCP.PRIMARY_FLAG PRIMARY_CONTACT_POINT,
          HCP.PRIMARY_BY_PURPOSE PREFERRED_FLAG
      FROM HZ_CONTACT_POINTS HCP,
        HZ_CUST_ACCOUNT_ROLES ACCT_ROLE,
        HZ_PARTIES PARTY,
        HZ_PARTIES REL_PARTY,
        HZ_RELATIONSHIPS REL,
        HZ_ORG_CONTACTS ORG_CONT ,
        HZ_CUST_ACCOUNTS ROLE_ACCT,
        HZ_CONTACT_RESTRICTIONS CONT_RES,
        HZ_PERSON_LANGUAGE PER_LANG,
        HZ_ROLE_RESPONSIBILITY HRR,
        --HZ_CUST_ACCT_SITES_ALL HCAS,
        HZ_CUST_SITE_USES_ALL HCSU
      WHERE ACCT_ROLE.PARTY_ID             = REL.PARTY_ID
      AND ACCT_ROLE.ROLE_TYPE              = 'CONTACT'
      AND ORG_CONT.PARTY_RELATIONSHIP_ID   = REL.RELATIONSHIP_ID
      AND REL.SUBJECT_ID                   = PARTY.PARTY_ID
      AND REL_PARTY.PARTY_ID               = REL.PARTY_ID
      AND HCP.OWNER_TABLE_ID(+)            = REL_PARTY.PARTY_ID
      AND HCP.CONTACT_POINT_TYPE        in  ('EMAIL','PHONE', 'FAX')
      AND HCP.PRIMARY_FLAG(+)              = 'Y'
      AND ACCT_ROLE.CUST_ACCOUNT_ID        = ROLE_ACCT.CUST_ACCOUNT_ID
      AND ACCT_ROLE.CUST_ACCT_SITE_ID      = HCSU.CUST_ACCT_SITE_ID
      AND HCSU.SITE_USE_CODE               = 'BILL_TO'
      AND ROLE_ACCT.PARTY_ID               = REL.OBJECT_ID
      AND PARTY.PARTY_ID                   = PER_LANG.PARTY_ID(+)
      AND PER_LANG.NATIVE_LANGUAGE(+)      = 'Y'
      AND PARTY.PARTY_ID                   = CONT_RES.SUBJECT_ID(+)
      AND CONT_RES.SUBJECT_TABLE(+)        = 'HZ_PARTIES'
      AND HCP.OWNER_TABLE_NAME(+)   = 'HZ_PARTIES'
      AND HRR.RESPONSIBILITY_TYPE = 'DUN'
      AND HRR.CUST_ACCOUNT_ROLE_ID = ACCT_ROLE.CUST_ACCOUNT_ROLE_ID
      AND ROLE_ACCT.ORIG_SYSTEM_REFERENCE  = LPAD(P_AOPS_ACCT_ID, 8, '0') || '-00001-A0'
      AND ROWNUM < 16
    ) ORDER BY PARTY_ID,
    PREFERRED_FLAG DESC,
    CASE
    WHEN PHONE_LN_TYPE = 'GEN' THEN
      '0'
    WHEN PHONE_LN_TYPE = 'FAX' THEN
      '1'
    WHEN PHONE_LN_TYPE = 'MOBILE' THEN
      '2'
    ELSE
      PHONE_LN_TYPE
    END;

  CURSOR C_PAYMENT_TERMS_INFO (P_AOPS_ACCT_ID NUMBER)
  IS
  SELECT PROF.ATTRIBUTE3              AB_BILLING_FLAG,
    NVL(TERM.DESCRIPTION, TERM.NAME)  PAYMENT_TERM,
    TERM.ATTRIBUTE1                   PAYTERM_FREQUENCY,
    TERM.ATTRIBUTE2                   PAYTERM_REPORTING_DAY,
    TERM.ATTRIBUTE3                   PAYTERM_PERCENTAGE,
    BILL.C_EXT_ATTR1                  BILLDOCS_DOC_TYPE,
    BILL.C_EXT_ATTR3                  BILLDOCS_DELIVERY_METH,
    BILL.C_EXT_ATTR4                  BILLDOCS_SPECIAL_HANDLING,
    BILL.C_EXT_ATTR5                  BILLDOCS_SIG_REQ,
    BILL.C_EXT_ATTR7                  BILLDOCS_DIRECT_FLAG,
    BILL.C_EXT_ATTR8                  BILLDOCS_AUTO_REPRINT,
    BILL.C_EXT_ATTR17                 BILLDOCS_COMMENTS1,
    BILL.C_EXT_ATTR18                 BILLDOCS_COMMENTS2,
    BILL.C_EXT_ATTR19                 BILLDOCS_COMMENTS3,
    BILL.C_EXT_ATTR20                 BILLDOCS_COMMENTS4,
    BILL.C_EXT_ATTR15                 BILLDOCS_MAIL_ATTENTION,
    BILL.D_EXT_ATTR1                  BILLDOCS_EFF_FROM_DATE,
    BILL.D_EXT_ATTR2                  BILLDOCS_EFF_TO_DATE,
    LOC.LOCATION_ID                   LOCATION_ID ,
    LOC.ADDRESS1                      ADDRESS1 ,
    LOC.ADDRESS2                      ADDRESS2 ,
    LOC.CITY                          CITY ,
    LOC.POSTAL_CODE                   POSTAL_CODE ,
    LOC.STATE                         STATE ,
    LOC.PROVINCE                      PROVINCE ,
    LOC.COUNTY                        COUNTY ,
    LOC.COUNTRY                       COUNTRY
  FROM APPS.HZ_CUST_ACCOUNTS ACCT
  JOIN APPS.HZ_CUST_ACCT_SITES_ALL HCAS
  ON ACCT.CUST_ACCOUNT_ID = HCAS.CUST_ACCOUNT_ID
  JOIN APPS.HZ_CUST_SITE_USES_ALL HCSUA
  ON HCAS.CUST_ACCT_SITE_ID = HCSUA.CUST_ACCT_SITE_ID
  AND HCSUA.SITE_USE_CODE   = 'BILL_TO'
  JOIN APPS.HZ_PARTY_SITES HPS
  ON HCAS.PARTY_SITE_ID           = HPS.PARTY_SITE_ID
  AND HPS.IDENTIFYING_ADDRESS_FLAG='Y'
  JOIN APPS.HZ_LOCATIONS LOC
  ON HPS.LOCATION_ID = LOC.LOCATION_ID
  LEFT JOIN APPS.HZ_CUSTOMER_PROFILES PROF
  ON ACCT.CUST_ACCOUNT_ID = PROF.CUST_ACCOUNT_ID
  AND PROF.SITE_USE_ID   IS NULL
  LEFT JOIN APPS.RA_TERMS TERM
  ON PROF.STANDARD_TERMS = TERM.TERM_ID
  LEFT JOIN APPS.XX_CDH_CUST_ACCT_EXT_B BILL
  ON ACCT.CUST_ACCOUNT_ID         = BILL.CUST_ACCOUNT_ID
  AND BILL.C_EXT_ATTR2            = 'Y'
  AND NVL(BILL.C_EXT_ATTR13,'DB') = 'DB'
  AND TRUNC(SYSDATE) BETWEEN NVL(BILL.D_EXT_ATTR1, SYSDATE -1) AND NVL(BILL.D_EXT_ATTR2, SYSDATE +1)
  AND BILL.ATTR_GROUP_ID           = 166
  AND BILL.C_EXT_ATTR16            = 'COMPLETE'
  WHERE ACCT.ORIG_SYSTEM_REFERENCE = LPAD(P_AOPS_ACCT_ID, 8, '0') || '-00001-A0'
  AND ROWNUM = 1;  

BEGIN
  OPEN C_AR_COLLECTOR_INFO (P_AOPS_ACCT_ID );
  FETCH C_AR_COLLECTOR_INFO BULK COLLECT INTO AR_COLLECTOR_TBL;
  CLOSE C_AR_COLLECTOR_INFO;

  OPEN C_GRAND_PARENT_INFO (P_AOPS_ACCT_ID );
  FETCH C_GRAND_PARENT_INFO BULK COLLECT INTO GRAND_PARENT_TBL;
  CLOSE C_GRAND_PARENT_INFO;

  OPEN C_CREDIT_LIMTS_INFO (P_AOPS_ACCT_ID );
  FETCH C_CREDIT_LIMTS_INFO BULK COLLECT INTO CREDIT_LIMTS_TBL;
  CLOSE C_CREDIT_LIMTS_INFO;

  OPEN C_AGING_BUCKET_INFO (P_AOPS_ACCT_ID );
  FETCH C_AGING_BUCKET_INFO BULK COLLECT INTO AGING_BUCKET_TBL;
  CLOSE C_AGING_BUCKET_INFO;

  OPEN C_EBILL_CONTACT_INFO (P_AOPS_ACCT_ID );
  FETCH C_EBILL_CONTACT_INFO BULK COLLECT INTO EBILL_CONTACT_TBL;
  CLOSE C_EBILL_CONTACT_INFO;

  OPEN C_PAYMENT_TERMS_INFO (P_AOPS_ACCT_ID );
  FETCH C_PAYMENT_TERMS_INFO BULK COLLECT INTO PAYMENT_TERMS_TBL;
  CLOSE C_PAYMENT_TERMS_INFO;

  CUST360_INFO_REC.AR_COLLECTOR_TAB     := AR_COLLECTOR_TBL;
  CUST360_INFO_REC.GRAND_PARENT_TAB     := GRAND_PARENT_TBL;  
  CUST360_INFO_REC.CREDIT_LIMTS_TAB     := CREDIT_LIMTS_TBL;    
  CUST360_INFO_REC.AGING_BUCKET_TAB     := AGING_BUCKET_TBL;    
  CUST360_INFO_REC.EBILL_CONTACT_TAB    := EBILL_CONTACT_TBL;   
  CUST360_INFO_REC.PAYMENT_TERMS_TAB    := PAYMENT_TERMS_TBL;   
  
  P_CUST_OUT := CUST360_INFO_REC;

END GET_CUST_INFO;

END XX_CRM_CUST360INFO_PKG;
/
SHOW ERR;