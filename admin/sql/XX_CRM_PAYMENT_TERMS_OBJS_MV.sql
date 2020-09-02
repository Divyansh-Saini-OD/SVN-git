CREATE MATERIALIZED VIEW XX_CRM_PAYMENT_TERMS_OBJS_MV
BUILD IMMEDIATE 
REFRESH COMPLETE ON DEMAND START WITH sysdate+0 NEXT SYSDATE+1/4
AS 
/*
  -- +============================================================================================|                                                                                                     
  -- |  Office Depot                                                                              |                                                                                                     
  -- +============================================================================================|                                                                                                     
  -- |  Name:  XX_CRM_PAYMENT_TERMS_OBJS_MV                                                          |                                                                                                     
  -- |                                                                                            |                                                                                                     
  -- |  Description: This package body pulls customer data as objects and interfaces with EAI for BSD   |                                                                                                     
  -- |  																					      |                                                                                                     
  -- |  Change Record:                                                                            |                                                                                                     
  -- +============================================================================================|                                                                                                     

  -- | Version     Date         Author               Remarks                                      |                                                                                                     
  -- | =========   ===========  =============        =============================================|                                                                                                    
  -- | 1.0        01-Sept-2020 Amit Kumar		     NAIT-147376 / NAIT-147376/ NAIT-136440       |                     
  -- +============================================================================================| */
SELECT
  /*+ PARALLEL(8)*/
  PROF.ATTRIBUTE3 AB_BILLING_FLAG,
  NVL(TERM1.DESCRIPTION, TERM1.NAME) PAYMENT_TERM,
  TERM.ATTRIBUTE1 PAYTERM_FREQUENCY,
  TERM.ATTRIBUTE2 PAYTERM_REPORTING_DAY,
  TERM.ATTRIBUTE3 PAYTERM_PERCENTAGE,
  BILL.C_EXT_ATTR1 BILLDOCS_DOC_TYPE,
  BILL.C_EXT_ATTR3 BILLDOCS_DELIVERY_METH,
  BILL.C_EXT_ATTR4 BILLDOCS_SPECIAL_HANDLING,
  BILL.C_EXT_ATTR5 BILLDOCS_SIG_REQ,
  BILL.C_EXT_ATTR7 BILLDOCS_DIRECT_FLAG,
  BILL.C_EXT_ATTR8 BILLDOCS_AUTO_REPRINT,
  BILL.C_EXT_ATTR17 BILLDOCS_COMMENTS1,
  BILL.C_EXT_ATTR18 BILLDOCS_COMMENTS2,
  BILL.C_EXT_ATTR19 BILLDOCS_COMMENTS3,
  BILL.C_EXT_ATTR20 BILLDOCS_COMMENTS4,
  BILL.C_EXT_ATTR15 BILLDOCS_MAIL_ATTENTION,
  BILL.D_EXT_ATTR1 BILLDOCS_EFF_FROM_DATE,
  BILL.D_EXT_ATTR2 BILLDOCS_EFF_TO_DATE,
  LOC.LOCATION_ID LOCATION_ID ,
  LOC.ADDRESS1 ADDRESS1 ,
  LOC.ADDRESS2 ADDRESS2 ,
  LOC.CITY CITY ,
  LOC.POSTAL_CODE POSTAL_CODE ,
  LOC.STATE STATE ,
  LOC.PROVINCE PROVINCE ,
  LOC.COUNTY COUNTY ,
  LOC.COUNTRY COUNTRY,
  ACCT.ORIG_SYSTEM_REFERENCE
FROM AR.HZ_CUST_ACCOUNTS ACCT
JOIN AR.HZ_CUST_ACCT_SITES_ALL HCAS
ON ACCT.CUST_ACCOUNT_ID = HCAS.CUST_ACCOUNT_ID
JOIN AR.HZ_CUST_SITE_USES_ALL HCSUA
ON HCAS.CUST_ACCT_SITE_ID = HCSUA.CUST_ACCT_SITE_ID
AND HCSUA.SITE_USE_CODE   = 'BILL_TO'
JOIN AR.HZ_PARTY_SITES HPS
ON HCAS.PARTY_SITE_ID           = HPS.PARTY_SITE_ID
AND HPS.IDENTIFYING_ADDRESS_FLAG='Y'
JOIN AR.HZ_LOCATIONS LOC
ON HPS.LOCATION_ID = LOC.LOCATION_ID
LEFT JOIN AR.HZ_CUSTOMER_PROFILES PROF
ON ACCT.CUST_ACCOUNT_ID = PROF.CUST_ACCOUNT_ID
AND PROF.SITE_USE_ID   IS NULL
LEFT JOIN AR.RA_TERMS_B TERM
ON PROF.STANDARD_TERMS = TERM.TERM_ID
LEFT JOIN AR.RA_TERMS_TL TERM1
ON PROF.STANDARD_TERMS = TERM1.TERM_ID
LEFT JOIN XXCRM.XX_CDH_CUST_ACCT_EXT_B BILL
ON ACCT.CUST_ACCOUNT_ID         = BILL.CUST_ACCOUNT_ID
AND BILL.C_EXT_ATTR2            = 'Y'
AND NVL(BILL.C_EXT_ATTR13,'DB') = 'DB'
AND TRUNC(SYSDATE) BETWEEN NVL(BILL.D_EXT_ATTR1, SYSDATE -1) AND NVL(BILL.D_EXT_ATTR2, SYSDATE +1)
AND BILL.ATTR_GROUP_ID = 166
AND BILL.C_EXT_ATTR16  = 'COMPLETE';
/