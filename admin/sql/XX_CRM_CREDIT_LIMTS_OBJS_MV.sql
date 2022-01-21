CREATE MATERIALIZED VIEW XX_CRM_CREDIT_LIMTS_OBJS_MV
BUILD IMMEDIATE 
REFRESH COMPLETE ON DEMAND START WITH SYSDATE+0 NEXT SYSDATE+1/4
AS
/*
  -- +============================================================================================|                                                                                                     
  -- |  Office Depot                                                                              |                                                                                                     
  -- +============================================================================================|                                                                                                     
  -- |  Name:  XX_CRM_CREDIT_LIMTS_OBJS_MV                                                          |                                                                                                     
  -- |                                                                                            |                                                                                                     
  -- |  Description: This package body pulls customer data as objects and interfaces with EAI for BSD   |                                                                                                     
  -- |  																					      |                                                                                                     
  -- |  Change Record:                                                                            |                                                                                                     
  -- +============================================================================================|                                                                                                     

  -- | Version     Date         Author               Remarks                                      |                                                                                                     
  -- | =========   ===========  =============        =============================================|                                                                                                    
  -- | 1.0        01-Sept-2020 Amit Kumar		     NAIT-147376 / NAIT-147376/ NAIT-136440       |                     
  -- +============================================================================================| */
SELECT DISTINCT HCPA.CURRENCY_CODE ,
  HCPA.OVERALL_CREDIT_LIMIT ,
  HCPA.TRX_CREDIT_LIMIT ,
  (HCPA1.OVERALL_CREDIT_LIMIT- OTB.TOTAL_AMOUNT_DUE ) OTB_CREDIT_LIMIT ,
  HCPA1.OVERALL_CREDIT_LIMIT PARENT_HIER_CREDIT_LIMIT ,
  HCA.ORIG_SYSTEM_REFERENCE,
  OTB.CUST_NUM AOPS_CUST_NUM,
  OTB.ORACLE_CUST_NUM
FROM AR.HZ_CUST_ACCOUNTS HCA,
  AR.HZ_CUST_PROFILE_AMTS HCPA,
  XXFIN.XX_AR_OTB_TRANSACTIONS OTB,
  AR.HZ_CUST_ACCOUNTS HCAP,
  AR.HZ_CUST_PROFILE_AMTS HCPA1
WHERE HCPA.CUST_ACCOUNT_ID     = HCA.CUST_ACCOUNT_ID
AND HCA.CUST_ACCOUNT_ID        = OTB.CUSTOMER_ID
AND HCA.ACCOUNT_NUMBER         = OTB.ORACLE_CUST_NUM
AND OTB.PARENT_PARTY_ID        = HCAP.PARTY_ID
AND HCPA1.CUST_ACCOUNT_ID      = HCAP.CUST_ACCOUNT_ID
AND HCPA.SITE_USE_ID          IS NULL
AND HCPA1.SITE_USE_ID         IS NULL
AND hcpa.object_version_number =
  (SELECT MAX(b.object_version_number)
  FROM AR.HZ_CUST_PROFILE_AMTS b
  WHERE b.CUST_ACCOUNT_ID=HCA.CUST_ACCOUNT_ID
  AND b.currency_code    ='USD'
  )
AND hcpa1.object_version_number =
  (SELECT MAX(a.object_version_number)
  FROM AR.HZ_CUST_PROFILE_AMTS a
  WHERE a.CUST_ACCOUNT_ID=HCAP.CUST_ACCOUNT_ID
  AND a.currency_code    ='USD'
  )
AND OTB.ORDER_NUM =
  (SELECT MAX(ot2.order_num)
  FROM XXFIN.XX_AR_OTB_TRANSACTIONS OT2
  WHERE OT2.CUSTOMER_ID=HCA.CUST_ACCOUNT_ID
  )
AND HCPA.CURRENCY_CODE ='USD'
AND HCPA1.CURRENCY_CODE='USD'
UNION
SELECT DISTINCT HCPA.CURRENCY_CODE ,
  HCPA.OVERALL_CREDIT_LIMIT ,
  HCPA.TRX_CREDIT_LIMIT ,
  (HCPA1.OVERALL_CREDIT_LIMIT- OTB.TOTAL_AMOUNT_DUE ) OTB_CREDIT_LIMIT ,
  HCPA1.OVERALL_CREDIT_LIMIT PARENT_HIER_CREDIT_LIMIT ,
  HCA.ORIG_SYSTEM_REFERENCE,
  OTB.CUST_NUM AOPS_CUST_NUM,
  OTB.ORACLE_CUST_NUM
FROM AR.HZ_CUST_ACCOUNTS HCA,
  AR.HZ_CUST_PROFILE_AMTS HCPA,
  XXFIN.XX_AR_OTB_TRANSACTIONS OTB,
  AR.HZ_CUST_ACCOUNTS HCAP,
  AR.HZ_CUST_PROFILE_AMTS HCPA1
WHERE HCPA.CUST_ACCOUNT_ID     = HCA.CUST_ACCOUNT_ID
AND HCA.CUST_ACCOUNT_ID        = OTB.CUSTOMER_ID
AND HCA.ACCOUNT_NUMBER         = OTB.ORACLE_CUST_NUM
AND OTB.PARENT_PARTY_ID        = HCAP.PARTY_ID
AND HCPA1.CUST_ACCOUNT_ID      = HCAP.CUST_ACCOUNT_ID
AND HCPA.SITE_USE_ID          IS NULL
AND HCPA1.SITE_USE_ID         IS NULL
AND hcpa.object_version_number =
  (SELECT MAX(b.object_version_number)
  FROM AR.HZ_CUST_PROFILE_AMTS b
  WHERE b.CUST_ACCOUNT_ID=HCA.CUST_ACCOUNT_ID
  AND b.currency_code    ='CAD'
  )
AND hcpa1.object_version_number =
  (SELECT MAX(a.object_version_number)
  FROM AR.HZ_CUST_PROFILE_AMTS a
  WHERE a.CUST_ACCOUNT_ID=HCAP.CUST_ACCOUNT_ID
  AND a.currency_code    ='CAD'
  )
AND OTB.ORDER_NUM =
  (SELECT MAX(ot2.order_num)
  FROM XXFIN.XX_AR_OTB_TRANSACTIONS OT2
  WHERE OT2.CUSTOMER_ID=HCA.CUST_ACCOUNT_ID
  )
AND HCPA.CURRENCY_CODE ='CAD'
AND HCPA1.CURRENCY_CODE='CAD';
/