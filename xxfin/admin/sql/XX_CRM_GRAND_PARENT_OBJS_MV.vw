CREATE MATERIALIZED VIEW XX_CRM_GRAND_PARENT_OBJS_MV
BUILD IMMEDIATE 
REFRESH COMPLETE ON DEMAND START WITH sysdate+0 NEXT SYSDATE+1/4
AS /*
  -- +============================================================================================|                                                                                                     
  -- |  Office Depot                                                                              |                                                                                                     
  -- +============================================================================================|                                                                                                     
  -- |  Name:  XX_CRM_GRAND_PARENT_OBJS_MV                                                          |                                                                                                     
  -- |                                                                                            |                                                                                                     
  -- |  Description: This package body pulls customer data as objects and interfaces with EAI for BSD   |                                                                                                     
  -- |  																					      |                                                                                                     
  -- |  Change Record:                                                                            |                                                                                                     
  -- +============================================================================================|                                                                                                     

  -- | Version     Date         Author               Remarks                                      |                                                                                                     
  -- | =========   ===========  =============        =============================================|                                                                                                    
  -- | 1.0        01-Sept-2020 Amit Kumar		     NAIT-147376 / NAIT-147376/ NAIT-136440       |                     
  -- +============================================================================================| */
SELECT  GP_ID,
  GP_NAME,
  ORIG_SYSTEM_REFERENCE
FROM
  (SELECT GP.GP_ID,
    GP.GP_NAME,
    ACT.ORIG_SYSTEM_REFERENCE
  FROM AR.HZ_CUST_ACCOUNTS ACT,
    AR.HZ_RELATIONSHIPS GREL,
    XXCRM.XX_CDH_GP_MASTER GP
  WHERE GP.PARTY_ID          = GREL.SUBJECT_ID
  AND ACT.PARTY_ID           = GREL.OBJECT_ID
  AND GREL.RELATIONSHIP_CODE = 'GRANDPARENT'
  AND GREL.RELATIONSHIP_TYPE = 'OD_CUST_HIER'
  AND GREL.DIRECTION_CODE    = 'P'
  AND GREL.STATUS            = 'A'
  AND SYSDATE BETWEEN GREL.START_DATE AND GREL.END_DATE
  UNION
  SELECT GP.GP_ID,
    GP.GP_NAME,
    ACT.ORIG_SYSTEM_REFERENCE
  FROM AR.HZ_CUST_ACCOUNTS ACT,
    AR.HZ_RELATIONSHIPS GREL,
    AR.HZ_RELATIONSHIPS PREL,
    XXCRM.XX_CDH_GP_MASTER GP
  WHERE GREL.OBJECT_ID       = PREL.SUBJECT_ID
  AND GREL.SUBJECT_ID        = GP.PARTY_ID
  AND ACT.PARTY_ID           = PREL.OBJECT_ID
  AND GREL.RELATIONSHIP_CODE = 'GRANDPARENT'
  AND GREL.RELATIONSHIP_TYPE = 'OD_CUST_HIER'
  AND GREL.DIRECTION_CODE    = 'P'
  AND GREL.STATUS            = 'A'
  AND PREL.RELATIONSHIP_CODE = 'PARENT_COMPANY'
  AND PREL.RELATIONSHIP_TYPE = 'OD_CUST_HIER'
  AND PREL.DIRECTION_CODE    = 'P'
  AND PREL.STATUS            = 'A'
  AND SYSDATE BETWEEN GREL.START_DATE AND GREL.END_DATE
  );
  