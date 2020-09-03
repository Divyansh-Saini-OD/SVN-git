CREATE MATERIALIZED VIEW XX_CRM_EBILL_CONTACT_OBJS_MV
BUILD IMMEDIATE 
REFRESH COMPLETE ON DEMAND START WITH sysdate+0 NEXT SYSDATE+1/4
AS /*
  -- +============================================================================================|                                                                                                     
  -- |  Office Depot                                                                              |                                                                                                     
  -- +============================================================================================|                                                                                                     
  -- |  Name:  XX_CRM_EBILL_CONTACT_OBJS_MV                                                          |                                                                                                     
  -- |                                                                                            |                                                                                                     
  -- |  Description: This package body pulls customer data as objects and interfaces with EAI for BSD   |                                                                                                     
  -- |  																					      |                                                                                                     
  -- |  Change Record:                                                                            |                                                                                                     
  -- +============================================================================================|                                                                                                     

  -- | Version     Date         Author               Remarks                                      |                                                                                                     
  -- | =========   ===========  =============        =============================================|                                                                                                    
  -- | 1.0        01-Sept-2020 Amit Kumar		     NAIT-147376 / NAIT-147376/ NAIT-136440       |                     
  -- +============================================================================================| */
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
    PREFERRED_FLAG,
    ORIG_SYSTEM_REFERENCE
  FROM
    (SELECT /*+ PARALLEL(8)*/ HRR.RESPONSIBILITY_TYPE RESP_TYPE ,
      HCP.CONTACT_POINT_ID CONTACT_POINT_ID,
      HP.SALUTATION SALUTATION ,
      HP.PARTY_ID,
      SUBSTRB (HP.PERSON_FIRST_NAME ,1 ,40 ) FIRST_NAME ,
      SUBSTRB (HP.PERSON_LAST_NAME ,1 ,50 ) LAST_NAME ,
      ORG_CONT.JOB_TITLE JOB_TITLE ,
      HCP.CONTACT_POINT_TYPE CONTACT_POINT_TYPE ,
      HCP.EMAIL_ADDRESS EMAIL_ADDRESS ,
      PHONE_LINE_TYPE PHONE_LN_TYPE,
      LKP.MEANING PHONE_LN_TYPE_DESC,
      HCP.PHONE_COUNTRY_CODE PHONE_COUNTRY_CODE ,
      HCP.PHONE_AREA_CODE PHONE_AREA_CODE ,
      HCP.PHONE_NUMBER PHONE_NUMBER ,
      HCP.PHONE_EXTENSION EXTENSION ,
      HCP.PRIMARY_FLAG PRIMARY_CONTACT_POINT,
      HCP.PRIMARY_BY_PURPOSE PREFERRED_FLAG,
	  ACCT.ORIG_SYSTEM_REFERENCE
    FROM 
	  AR.HZ_CUST_ACCT_SITES_ALL HCAS ,
      AR.HZ_CUST_SITE_USES_ALL HCSUA ,
      AR.HZ_PARTIES HP ,
      AR.HZ_PARTY_SITES HPS ,
      AR.HZ_CUST_ACCOUNT_ROLES HCAR ,
      AR.HZ_RELATIONSHIPS HR ,
      AR.HZ_ORG_CONTACTS ORG_CONT ,
      AR.HZ_ROLE_RESPONSIBILITY HRR ,
      AR.HZ_CONTACT_POINTS HCP ,
      AR.HZ_CUST_ACCOUNTS ACCT,
	  APPLSYS.FND_LOOKUP_VALUES LKP
    WHERE ACCT.CUST_ACCOUNT_ID      = HCAS.CUST_ACCOUNT_ID
    AND HCAS.CUST_ACCT_SITE_ID      = HCSUA.CUST_ACCT_SITE_ID
    AND HCAS.PARTY_SITE_ID          = HPS.PARTY_SITE_ID
    AND HPS.IDENTIFYING_ADDRESS_FLAG='Y'
    AND HCSUA.SITE_USE_CODE         = 'BILL_TO'
    AND HP.PARTY_ID                 = HR.SUBJECT_ID
    AND HCAR.PARTY_ID               = HR.PARTY_ID
    AND HCAR.CUST_ACCT_SITE_ID      = HCSUA.CUST_ACCT_SITE_ID
    AND HRR.CUST_ACCOUNT_ROLE_ID    = HCAR.CUST_ACCOUNT_ROLE_ID
    AND HR.SUBJECT_TYPE             = 'PERSON'
    AND HR.RELATIONSHIP_ID          = ORG_CONT.PARTY_RELATIONSHIP_ID
    AND HCAR.STATUS                 = 'A'
    AND HCAR.PARTY_ID               = HCP.OWNER_TABLE_ID
    AND HCP.STATUS                  = 'A'
    AND HRR.RESPONSIBILITY_TYPE     = 'BILLING'
	AND LKP.LOOKUP_TYPE = 'PHONE_LINE_TYPE'
      AND LKP.LANGUAGE      = SYS_CONTEXT('USERENV', 'LANG')
      AND LKP.LOOKUP_CODE   = HCP.PHONE_LINE_TYPE 
    AND CONTACT_POINT_TYPE         IN ('PHONE', 'EMAIL')
    UNION
    SELECT /*+ PARALLEL(8)*/ HRR.RESPONSIBILITY_TYPE RESP_TYPE ,
      HCP.CONTACT_POINT_ID CONTACT_POINT_ID,
      HP.SALUTATION SALUTATION ,
      HP.PARTY_ID,
      SUBSTRB (HP.PERSON_FIRST_NAME ,1 ,40 ) FIRST_NAME ,
      SUBSTRB (HP.PERSON_LAST_NAME ,1 ,50 ) LAST_NAME ,
      ORG_CONT.JOB_TITLE JOB_TITLE ,
      HCP.CONTACT_POINT_TYPE CONTACT_POINT_TYPE ,
      HCP.EMAIL_ADDRESS EMAIL_ADDRESS ,
      PHONE_LINE_TYPE PHONE_LINE_TYPE,
      LKP.MEANING  PHONE_LN_TYPE_DESC,
      HCP.PHONE_COUNTRY_CODE PHONE_COUNTRY_CODE ,
      HCP.PHONE_AREA_CODE PHONE_AREA_CODE ,
      HCP.PHONE_NUMBER PHONE_NUMBER ,
      HCP.PHONE_EXTENSION EXTENSION ,
      HCP.PRIMARY_FLAG PRIMARY_CONTACT_POINT,
      HCP.PRIMARY_BY_PURPOSE PREFERRED_FLAG,
	  ACCT.ORIG_SYSTEM_REFERENCE
    FROM 
	  AR.HZ_CUST_ACCT_SITES_ALL HCAS ,
      AR.HZ_CUST_SITE_USES_ALL HCSUA ,
      AR.HZ_PARTIES HP ,
      AR.HZ_PARTY_SITES HPS ,
      AR.HZ_CUST_ACCOUNT_ROLES HCAR ,
      AR.HZ_RELATIONSHIPS HR ,
      AR.HZ_ORG_CONTACTS ORG_CONT ,
      AR.HZ_ROLE_RESPONSIBILITY HRR ,
      AR.HZ_CONTACT_POINTS HCP ,
      AR.HZ_CUST_ACCOUNTS ACCT,
	  APPLSYS.FND_LOOKUP_VALUES LKP
    WHERE ACCT.CUST_ACCOUNT_ID      = HCAS.CUST_ACCOUNT_ID
    AND HCAS.CUST_ACCT_SITE_ID      = HCSUA.CUST_ACCT_SITE_ID
    AND HCAS.PARTY_SITE_ID          = HPS.PARTY_SITE_ID
    AND HPS.IDENTIFYING_ADDRESS_FLAG='Y'
    AND HCSUA.SITE_USE_CODE         = 'BILL_TO'
    AND HP.PARTY_ID                 = HR.SUBJECT_ID
    AND HCAR.PARTY_ID               = HR.PARTY_ID
    AND HCAR.CUST_ACCT_SITE_ID      = HCSUA.CUST_ACCT_SITE_ID
    AND HRR.CUST_ACCOUNT_ROLE_ID    = HCAR.CUST_ACCOUNT_ROLE_ID
    AND HR.SUBJECT_TYPE             = 'PERSON'
    AND HR.RELATIONSHIP_ID          = ORG_CONT.PARTY_RELATIONSHIP_ID
    AND HCAR.STATUS                 = 'A'
    AND HCAR.PARTY_ID               = HCP.OWNER_TABLE_ID
    AND HCP.STATUS                  = 'A'
    AND HRR.RESPONSIBILITY_TYPE     = 'DUN'
    AND HCP.CONTACT_POINT_PURPOSE   = 'DUNNING'
	AND LKP.LOOKUP_TYPE = 'PHONE_LINE_TYPE'
      AND LKP.LANGUAGE      = SYS_CONTEXT('USERENV', 'LANG')
      AND LKP.LOOKUP_CODE   = HCP.PHONE_LINE_TYPE 
    AND CONTACT_POINT_TYPE         IN ('PHONE', 'EMAIL')
    )  ;
	/