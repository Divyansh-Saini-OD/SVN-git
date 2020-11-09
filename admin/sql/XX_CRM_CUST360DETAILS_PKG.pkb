CREATE OR REPLACE  PACKAGE BODY XX_CRM_CUST360DETAILS_PKG
AS
  /*
  -- +============================================================================================|                                                                                                     
  -- |  Office Depot                                                                              |                                                                                                     
  -- +============================================================================================|                                                                                                     
  -- |  Name:  XX_CRM_CUST360DETAILS_PKG                                                          |                                                                                                     
  -- |                                                                                            |                                                                                                     
  -- |  Description: This package body pulls customer data as objects and interfaces with EAI for BSD   |                                                                                                     
  -- |  																					      |                                                                                                     
  -- |  Change Record:                                                                            |                                                                                                     
  -- +============================================================================================|                                                                                                     

  -- | Version     Date         Author               Remarks                                      |                                                                                                     
  -- | =========   ===========  =============        =============================================|                                                                                                     
  -- | 1.0         NA  			NA			         Initial version   (SVN version not found)    |                                                                                                     
  -- | 1.1         01-Sept-2020 Amit Kumar		     NAIT-147376 / NAIT-147376/ NAIT-136440       |
  -- | 1.1		  05-Nov-2020   Amit Kumar			 NAIT-161681 --To Display Credit info for 	  |
  -- |												 all customers.		  					      |  
  -- +============================================================================================| */
PROCEDURE GET_CUST_INFO (
                           P_AOPS_ACCT_ID  IN   NUMBER,
                           P_CUST_OUT      OUT  XX_CRM_FULL_CUST_INFO_BO
)
AS

XX_CRM_AR_COLLECTOR_OBJS_T   XX_CRM_AR_COLLECTOR_OBJS  :=   XX_CRM_AR_COLLECTOR_OBJS();
XX_CRM_GRAND_PARENT_OBJS_T   XX_CRM_GRAND_PARENT_OBJS  :=   XX_CRM_GRAND_PARENT_OBJS();
XX_CRM_CREDIT_LIMTS_OBJS_T   XX_CRM_CREDIT_LIMTS_OBJS  :=   XX_CRM_CREDIT_LIMTS_OBJS();
XX_CRM_AGING_BUCKET_OBJS_T   XX_CRM_AGING_BUCKET_OBJS  :=   XX_CRM_AGING_BUCKET_OBJS();
XX_CRM_EBILL_CONTACT_OBJS_T  XX_CRM_EBILL_CONTACT_OBJS :=  XX_CRM_EBILL_CONTACT_OBJS();
XX_CRM_PAYMENT_TERMS_OBJS_T  XX_CRM_PAYMENT_TERMS_OBJS :=  XX_CRM_PAYMENT_TERMS_OBJS();

FULL_CUST_INFO_BO   XX_CRM_FULL_CUST_INFO_BO;

BEGIN



SELECT CAST(MULTISET
 ( SELECT 	COLLECTOR_NAME
			,COLLECTOR_EMP_NUMBER
			,COLLECTOR_EMAIL_ADDRESS
			,COLLECTOR_SUPERVISOR_NAME
			,COLLECTOR_SUPERVISOR_EMAIL
			,COLLECTOR_PHONE_NUMBER
			,COLLECTOR_FAX_NUMBER
			,COLLECTOR_SUP_PHONE_NUMBER
			,COLLECTOR_SUP_FAX_NUMBER			
   FROM XX_CRM_AR_COLLECTOR_OBJS_MV
  WHERE ORIG_SYSTEM_REFERENCE = LPAD(P_AOPS_ACCT_ID, 8, '0') || '-00001-A0'
  AND ROWNUM                 = 1
 ) AS XX_CRM_AR_COLLECTOR_OBJS)
 INTO XX_CRM_AR_COLLECTOR_OBJS_T
 FROM DUAL;



SELECT CAST(MULTISET
 ( SELECT GP_ID,
  GP_NAME,
  ORIG_SYSTEM_REFERENCE
  FROM XX_CRM_GRAND_PARENT_OBJS_MV
  WHERE ORIG_SYSTEM_REFERENCE = LPAD(P_AOPS_ACCT_ID, 8, '0') || '-00001-A0') AS XX_CRM_GRAND_PARENT_OBJS)
 INTO XX_CRM_GRAND_PARENT_OBJS_T
 FROM DUAL;


SELECT CAST(MULTISET
 (
 --NAIT-161681 Commented--
 /* SELECT CURRENCY_CODE ,
  OVERALL_CREDIT_LIMIT ,
  TRX_CREDIT_LIMIT ,
  OTB_CREDIT_LIMIT ,
  PARENT_HIER_CREDIT_LIMIT
  FROM XX_CRM_CREDIT_LIMTS_OBJS_MV
  WHERE ORIG_SYSTEM_REFERENCE = LPAD(P_AOPS_ACCT_ID, 8, '0') || '-00001-A0'
  	ORDER BY
	  CASE
		WHEN CURRENCY_CODE = 'USD'
		THEN 0
		ELSE 1
	  END ) AS XX_CRM_CREDIT_LIMTS_OBJS) */ --NAIT-161681--Start-- Added new SQL below to replace the commented SQL.
	SELECT CURRENCY_CODE ,
	  OVERALL_CREDIT_LIMIT ,
	  TRX_CREDIT_LIMIT ,
	  OTB_CREDIT_LIMIT ,
	  PARENT_HIER_CREDIT_LIMIT
	FROM
	  (SELECT CURRENCY_CODE ,
		OVERALL_CREDIT_LIMIT ,
		TRX_CREDIT_LIMIT ,
		OTB_CREDIT_LIMIT ,
		PARENT_HIER_CREDIT_LIMIT,
		ORIG_SYSTEM_REFERENCE,
		CUST_HIER,
		row_number () over (partition BY ORIG_SYSTEM_REFERENCE order by cust_hier DESC ) row_num
	  FROM XX_CRM_CREDIT_LIMTS_OBJS_MV
	  WHERE ORIG_SYSTEM_REFERENCE = LPAD(P_AOPS_ACCT_ID, 8, '0')
		|| '-00001-A0'
	  )
	WHERE row_num=1 ) AS XX_CRM_CREDIT_LIMTS_OBJS)  -- --NAIT-161681 -end--
 INTO XX_CRM_CREDIT_LIMTS_OBJS_T     
 FROM DUAL;


SELECT CAST(MULTISET
 (SELECT CUST_ACCOUNT_ID,
	  PARTY_NAME,
	  ACCOUNT_NUMBER,
	  PARTY_NUMBER,
	  PAYMENT_TERMS,
	  TOTAL_DUE,
	  CURR,
	  PD1_30,
	  PD31_60 ,
	  PD61_90,
	  PD91_180,
	  PD181_365,
	  PD_366,
	  DISPUTED_TOTAL_AGED,
	  COLLECTOR_CODE ,
	  AOPS_NUM ,
	  ACCT_EST_DATE,
	  CREDIT_LIMIT
	FROM XX_AR_CUSTOMER_AGING_MV
	WHERE AOPS_NUM IN ((LPAD(P_AOPS_ACCT_ID, 8, '0')
	  || '-00001-A0'), NVL (
	  (SELECT par_AOPS_NUM
	  FROM XX_AR_CUSTOMER_PARENT_MV
	  WHERE orig_AOPS_NUM =(LPAD(P_AOPS_ACCT_ID, 8, '0')
		|| '-00001-A0')
	  AND rownum=1
	  ) ,LPAD(P_AOPS_ACCT_ID, 8, '0')
	  || '-00001-A0'))
	UNION
	SELECT CH_CUST_ACCOUNT_ID,
	  CH_CUSTOMER_NAME,
	  CH_CUSTOMER_NUMBER,
	  CH_PARTY_ID,
	  CH_PAYMENT_TERMS,
	  CH_TOTAL_DUE,
	  CH_CURR,
	  CH_PD1_30,
	  CH_PD31_60,
	  CH_PD61_90,
	  CH_PD91_180,
	  CH_PD181_365,
	  CH_PD_366,
	  DISPUTED_TOTAL_AGED,
	  CH_COLLECTOR,
	  CH_AOPS_NUM,
	  CH_ACCT_EST_DATE,
	  CH_CREDIT_LIMIT
	FROM XX_AR_CUSTOMER_AGING_CH_MV
	WHERE PAR_AOPS_NUM = NVL(
	  (SELECT par_AOPS_NUM
	  FROM XX_AR_CUSTOMER_PARENT_MV
	  WHERE orig_AOPS_NUM =(LPAD(P_AOPS_ACCT_ID, 8, '0')|| '-00001-A0')
	  AND rownum=1
	  ) ,LPAD(P_AOPS_ACCT_ID, 8, '0')
	  || '-00001-A0')
	AND CH_AOPS_NUM <>NVL2(
	  (SELECT par_AOPS_NUM
	  FROM XX_AR_CUSTOMER_PARENT_MV
	  WHERE orig_AOPS_NUM =(LPAD(P_AOPS_ACCT_ID, 8, '0')
		|| '-00001-A0')
	  AND rownum=1
	  ) ,LPAD(P_AOPS_ACCT_ID, 8, '0')|| '-00001-A0', 1)
	UNION
	SELECT GCH_CUST_ACCOUNT_ID,
	  GCH_CUSTOMER_NAME,
	  GCH_CUSTOMER_NUMBER,
	  GCH_PARTY_ID,
	  GCH_PAYMENT_TERMS,
	  GCH_TOTAL_DUE,
	  GCH_CURR,
	  GCH_PD1_30,
	  GCH_PD31_60,
	  GCH_PD61_90,
	  GCH_PD91_180,
	  GCH_PD181_365,
	  GCH_PD_366,
	  DISPUTED_TOTAL_AGED,
	  GCH_COLLECTOR,
	  GCH_AOPS_NUM,
	  GCH_ACCT_EST_DATE,
	  GCH_CREDIT_LIMIT
	FROM XX_AR_CUSTOMER_AGING_GC_MV
	WHERE parent_id IN
	  (SELECT
		/*+ PUSH_SUBQ NO_MERGE */
		HN.child_id
	  FROM hz_hierarchy_nodes HN ,
		   hz_cust_accounts CA
	  WHERE HN.parent_id           = CA.party_id
	  AND HN.parent_id            <> HN.child_id
	  AND CA.orig_system_reference = NVL(
		(SELECT par_AOPS_NUM
		FROM XX_AR_CUSTOMER_PARENT_MV
		WHERE orig_AOPS_NUM =(LPAD(P_AOPS_ACCT_ID, 8, '0')|| '-00001-A0')
		AND rownum=1
		) ,LPAD(P_AOPS_ACCT_ID, 8, '0')|| '-00001-A0')
	  AND NVL(HN.status,'A')='A'
	  AND SYSDATE BETWEEN NVL (HN.effective_start_date, SYSDATE) AND NVL (HN.effective_end_date, SYSDATE)
	  AND HN.hierarchy_type = 'OD_FIN_HIER'
	  ) 
 ) AS XX_CRM_AGING_BUCKET_OBJS)
 INTO XX_CRM_AGING_BUCKET_OBJS_T
 FROM DUAL;


SELECT CAST(MULTISET
 (
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
	FROM XX_CRM_EBILL_CONTACT_OBJS_MV
    WHERE  ORIG_SYSTEM_REFERENCE  = LPAD(P_AOPS_ACCT_ID, 8, '0') || '-00001-A0'
    AND ROWNUM <16
	ORDER BY PARTY_ID,
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
    END) AS XX_CRM_EBILL_CONTACT_OBJS)
 INTO XX_CRM_EBILL_CONTACT_OBJS_T
 FROM DUAL;


SELECT CAST(MULTISET
 (
  SELECT AB_BILLING_FLAG,
	PAYMENT_TERM,
	PAYTERM_FREQUENCY,
	PAYTERM_REPORTING_DAY,
	PAYTERM_PERCENTAGE,
	BILLDOCS_DOC_TYPE,
	BILLDOCS_DELIVERY_METH,
	BILLDOCS_SPECIAL_HANDLING,
	BILLDOCS_SIG_REQ,
	BILLDOCS_DIRECT_FLAG,
	BILLDOCS_AUTO_REPRINT,
	BILLDOCS_COMMENTS1,
	BILLDOCS_COMMENTS2,
	BILLDOCS_COMMENTS3,
	BILLDOCS_COMMENTS4,
	BILLDOCS_MAIL_ATTENTION,
	BILLDOCS_EFF_FROM_DATE,
	BILLDOCS_EFF_TO_DATE,
	LOCATION_ID ,
	ADDRESS1 ,
	ADDRESS2 ,
	CITY ,
	POSTAL_CODE ,
	STATE ,
	PROVINCE ,
	COUNTY ,
	COUNTRY 
  FROM XX_CRM_PAYMENT_TERMS_OBJS_MV
  WHERE ORIG_SYSTEM_REFERENCE = LPAD(P_AOPS_ACCT_ID, 8, '0') || '-00001-A0'
  AND ROWNUM = 1) AS XX_CRM_PAYMENT_TERMS_OBJS)
 INTO XX_CRM_PAYMENT_TERMS_OBJS_T
 FROM DUAL;

 FULL_CUST_INFO_BO :=
 XX_CRM_FULL_CUST_INFO_BO.create_object(
  P_AR_COLLECTOR_TAB  => XX_CRM_AR_COLLECTOR_OBJS_T ,
  P_GRAND_PARENT_TAB  => XX_CRM_GRAND_PARENT_OBJS_T ,
  P_CREDIT_LIMTS_TAB  => XX_CRM_CREDIT_LIMTS_OBJS_T ,
  P_AGING_BUCKET_TAB  => XX_CRM_AGING_BUCKET_OBJS_T ,
  P_EBILL_CONTACT_TAB => XX_CRM_EBILL_CONTACT_OBJS_T,
  P_PAYMENT_TERMS_TAB => XX_CRM_PAYMENT_TERMS_OBJS_T
 );

  P_CUST_OUT := FULL_CUST_INFO_BO;

END GET_CUST_INFO;

END XX_CRM_CUST360DETAILS_PKG;
 /
