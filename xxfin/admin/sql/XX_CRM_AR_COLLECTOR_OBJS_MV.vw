CREATE MATERIALIZED VIEW XX_CRM_AR_COLLECTOR_OBJS_MV
BUILD IMMEDIATE 
REFRESH COMPLETE ON DEMAND START WITH SYSDATE+0 NEXT SYSDATE+1/4
AS 
/*
  -- +============================================================================================|                                                                                                     
  -- |  Office Depot                                                                              |                                                                                                     
  -- +============================================================================================|                                                                                                     
  -- |  Name:  XX_CRM_AR_COLLECTOR_OBJS_MV                                                          |                                                                                                     
  -- |                                                                                            |                                                                                                     
  -- |  Description: This package body pulls customer data as objects and interfaces with EAI for BSD   |                                                                                                     
  -- |  																					      |                                                                                                     
  -- |  Change Record:                                                                            |                                                                                                     
  -- +============================================================================================|                                                                                                     

  -- | Version     Date         Author               Remarks                                      |                                                                                                     
  -- | =========   ===========  =============        =============================================|                                                                                                    
  -- | 1.0        01-Sept-2020 Amit Kumar		     NAIT-147376 / NAIT-147376/ NAIT-136440       |                     
  -- +============================================================================================| */
SELECT RSC_EMP.SOURCE_NAME   COLLECTOR_NAME,
         COL.NAME              COLLECTOR_EMP_NUMBER,
         RSC_EMP.SOURCE_EMAIL  COLLECTOR_EMAIL_ADDRESS,
         RSC_SUP.SOURCE_NAME   COLLECTOR_SUPERVISOR_NAME,
         RSC_SUP.SOURCE_EMAIL  COLLECTOR_SUPERVISOR_EMAIL,
         DECODE(HP_EMP.PRIMARY_PHONE_LINE_TYPE,'PHONE',HP_EMP.PRIMARY_PHONE_NUMBER,NULL) COLLECTOR_PHONE_NUMBER,
         DECODE(HP_EMP.PRIMARY_PHONE_LINE_TYPE,'FAX',HP_EMP.PRIMARY_PHONE_NUMBER,NULL) COLLECTOR_FAX_NUMBER,
         DECODE(HP_SUPP.PRIMARY_PHONE_LINE_TYPE,'PHONE',HP_SUPP.PRIMARY_PHONE_NUMBER,NULL) COLLECTOR_SUP_PHONE_NUMBER,
         DECODE(HP_SUPP.PRIMARY_PHONE_LINE_TYPE,'FAX',HP_SUPP.PRIMARY_PHONE_NUMBER,NULL) COLLECTOR_SUP_FAX_NUMBER,
         ACCT.ORIG_SYSTEM_REFERENCE
  FROM AR.HZ_CUSTOMER_PROFILES PROF,
    AR.HZ_CUST_ACCOUNTS ACCT,
    AR.AR_COLLECTORS COL,
    JTF.JTF_RS_RESOURCE_EXTNS RSC_EMP,
    JTF.JTF_RS_RESOURCE_EXTNS RSC_SUP,
    AR.HZ_PARTIES HP_EMP,
    AR.HZ_PARTIES HP_SUPP
  WHERE ACCT.CUST_ACCOUNT_ID     =PROF.CUST_ACCOUNT_ID
  AND COL.COLLECTOR_ID(+)        = PROF.COLLECTOR_ID
  AND PROF.SITE_USE_ID      IS NULL
  AND COL.STATUS             ='A'
  AND RSC_EMP.RESOURCE_ID    =COL.RESOURCE_ID
  AND RSC_EMP.SOURCE_MGR_ID  =RSC_SUP.SOURCE_ID
  AND RSC_EMP.PERSON_PARTY_ID=HP_EMP.PARTY_ID
  AND RSC_SUP.PERSON_PARTY_ID=HP_SUPP.PARTY_ID;
  