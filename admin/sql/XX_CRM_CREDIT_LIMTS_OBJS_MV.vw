DROP MATERIALIZED VIEW XX_CRM_CREDIT_LIMTS_OBJS_MV;

CREATE MATERIALIZED VIEW XX_CRM_CREDIT_LIMTS_OBJS_MV
BUILD IMMEDIATE 
REFRESH COMPLETE ON DEMAND START WITH SYSDATE+0 NEXT SYSDATE+1/4
AS
/*
  -- +============================================================================================|                                                                                                     
  -- |  Office Depot                                                                              |                                                                                                     
  -- +============================================================================================|                                                                                                     
  -- |  Name:  XX_CRM_CREDIT_LIMTS_OBJS_MV                                                        |                                                                                                     
  -- |                                                                                            |                                                                                                     
  -- |  Description: View created to get  Credit Limit for any Customer						      |                                                                                                     
  -- |  																					      |                                                                                                     
  -- |  Change Record:                                                                            |                                                                                                     
  -- +============================================================================================|                                                                                                     

  -- | Version     Date         Author               Remarks                                      |                                                                                                     
  -- | =========   ===========  =============        =============================================|                                                                                                    
  -- | 1.0        01-Sept-2020  Amit Kumar		     NAIT-147376 / NAIT-147376/ NAIT-136440       |
  -- | 1.1		  05-Nov-2020   Amit Kumar			 NAIT-161681 --Removed CAD Curreny UNION Stmt.|
  -- |												 Added UNION to extract Credit limit info for |
  -- | 												 customers without parent/hieriachy.		  |
  -- +============================================================================================| */
  SELECT /*+ PARALLEL(8) */ HCPA.CURRENCY_CODE ,
	  DECODE(HCPA.OVERALL_CREDIT_LIMIT, 1, 0, 2, 0, NULL, 0, HCPA.OVERALL_CREDIT_LIMIT) OVERALL_CREDIT_LIMIT,
	  DECODE(HCPA.TRX_CREDIT_LIMIT, 1, 0, 2, 0, NULL, 0, HCPA.TRX_CREDIT_LIMIT) TRX_CREDIT_LIMIT ,
	  DECODE(HCPAP.OVERALL_CREDIT_LIMIT, 1, 0, 2, 0, NULL, 0, HCPAP.OVERALL_CREDIT_LIMIT)- NVL( OTB.TOTAL_AMOUNT_DUE,0) OTB_CREDIT_LIMIT ,
	  DECODE(HCPAP.OVERALL_CREDIT_LIMIT, 1, 0, 2, 0, NULL, 0, HCPAP.OVERALL_CREDIT_LIMIT) PARENT_HIER_CREDIT_LIMIT ,
	  HCA.ORIG_SYSTEM_REFERENCE,
	  'Y' CUST_HIER
	FROM ar.hz_parties HP_PAR ,
	  ar.hz_cust_accounts HCA_PAR ,
	  ar.hz_hierarchy_nodes HHN ,
	  ar.hz_parties HP ,
	  ar.hz_cust_accounts HCA,
	  AR.HZ_CUST_PROFILE_AMTS HCPA,
	  AR.HZ_CUST_PROFILE_AMTS HCPAP,
	  ( SELECT DISTINCT OT1.CUST_NUM,
		OT1.CUSTOMER_ID,
		order_num,
		total_Amount_due
	  FROM XXFIN.XX_AR_OTB_TRANSACTIONS OT1
	  WHERE order_num =
		(SELECT MAX(ot2.order_num)
		FROM XXFIN.XX_AR_OTB_TRANSACTIONS OT2
		WHERE OT2.customer_id=ot1.customer_id
		)
	  AND OT1.CREATION_DATE =
		(SELECT MAX(ot3.creation_Date)
		FROM XXFIN.XX_AR_OTB_TRANSACTIONS OT3
		WHERE OT3.customer_id=ot1.customer_id
		AND ot3.order_num    =ot1.order_num
		)
	  AND response_Action<>'X'
	  ) OTB
	WHERE HP_PAR.party_id  = HCA_PAR.party_id
	AND HHN.parent_id      = HP_PAR.party_id
	AND HHN.child_id       = HP.party_id
	AND HP.party_id        = HCA.party_id
	AND HHN.hierarchy_type = 'OD_FIN_HIER'
    AND HHN.parent_id     <> HHN.child_id
	AND SYSDATE BETWEEN NVL (HHN.effective_start_date, SYSDATE) AND NVL (HHN.effective_end_date, SYSDATE)
	AND NVL(HHN.status, 'A')       	= 'A'
	and NVL(hca.status, 'A') 		= 'A'
	and NVL(hca_par.status, 'A') 	= 'A'
	AND PARENT_TABLE_NAME          ='HZ_PARTIES'
	AND CHILD_TABLE_NAME           ='HZ_PARTIES'
	AND PARENT_OBJECT_TYPE         =CHILD_OBJECT_TYPE
	AND HCPA.CUST_ACCOUNT_ID       = HCA.CUST_ACCOUNT_ID
	AND HCPAP.CUST_ACCOUNT_ID      = HCA_PAR.CUST_ACCOUNT_ID
	AND HCPA.SITE_USE_ID          IS NULL
	AND HCPAP.SITE_USE_ID         IS NULL
	AND HCA.CUST_ACCOUNT_ID        = OTB.CUSTOMER_ID (+)
	AND HCPA.CURRENCY_CODE        ='USD'
	AND HCPAP.CURRENCY_CODE       ='USD'
	UNION
	SELECT /*+ PARALLEL(8) */ HCPA.CURRENCY_CODE CURRENCY_CODE,
	  HCPA.OVERALL_CREDIT_LIMIT OVERALL_CREDIT_LIMIT,
	  HCPA.TRX_CREDIT_LIMIT TRX_CREDIT_LIMIT,
	  (DECODE(HCPA.OVERALL_CREDIT_LIMIT, 1, 0, 2, 0, NULL, 0, HCPA.OVERALL_CREDIT_LIMIT)- NVL( OTB.TOTAL_AMOUNT_DUE,0) ) OTB_CREDIT_LIMIT,
	  0 PARENT_HIER_CREDIT_LIMIT,
	  HCA.ORIG_SYSTEM_REFERENCE,
	  'N' CUST_HIER
	FROM AR.HZ_CUST_ACCOUNTS HCA,
	  AR.HZ_CUST_PROFILE_AMTS HCPA,
	  ( SELECT DISTINCT OT1.CUST_NUM,
		OT1.CUSTOMER_ID,
		order_num,
		total_Amount_due
	  FROM XXFIN.XX_AR_OTB_TRANSACTIONS OT1
	  WHERE order_num =
		(SELECT MAX(ot2.order_num)
		FROM XXFIN.XX_AR_OTB_TRANSACTIONS OT2
		WHERE OT2.customer_id=ot1.customer_id
		)
	  AND OT1.CREATION_DATE =
		(SELECT MAX(ot3.creation_Date)
		FROM XXFIN.XX_AR_OTB_TRANSACTIONS OT3
		WHERE OT3.customer_id=ot1.customer_id
		AND ot3.order_num    =ot1.order_num
		)
	  AND response_Action<>'X'
	  ) OTB
	WHERE HCPA.CUST_ACCOUNT_ID       = HCA.CUST_ACCOUNT_ID
	AND HCA.CUST_ACCOUNT_ID        = OTB.CUSTOMER_ID (+)
	AND SITE_USE_ID               IS NULL
	AND HCPA.CURRENCY_CODE         ='USD'
	and NVL(hca.status, 'A') = 'A';
	
CREATE INDEX APPS.XX_CRM_CREDIT_LIMTS_OBJS_MV_N1 ON APPS.XX_CRM_CREDIT_LIMTS_OBJS_MV
  (
    ORIG_SYSTEM_REFERENCE
  )
  COMPUTE STATISTICS NOPARALLEL LOGGING;
  
CREATE OR REPLACE PUBLIC SYNONYM XX_CRM_CREDIT_LIMTS_OBJS_MV FOR APPS.XX_CRM_CREDIT_LIMTS_OBJS_MV;

GRANT SELECT ON XX_CRM_CREDIT_LIMTS_OBJS_MV TO "ERP_SYSTEM_TABLE_SELECT_ROLE";