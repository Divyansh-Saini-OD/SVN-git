CREATE MATERIALIZED VIEW XX_AR_CUSTOMER_AGING_MV
BUILD IMMEDIATE 
REFRESH COMPLETE ON DEMAND START WITH SYSDATE+0 NEXT SYSDATE+1/4
AS
  /*
  -- +============================================================================================|                                                                                                     
  -- |  Office Depot                                                                              |                                                                                                     
  -- +============================================================================================|                                                                                                     
  -- |  Name:  XX_AR_CUSTOMER_AGING_MV                                                          |                                                                                                     
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
  /*+ PARALLEL(8) dynamic_sampling(0) */
  HCA.cust_account_id ,
  HP.party_name ,
  HCA.account_number ,
  HP.party_number ,
  RT.name payment_terms ,
  NVL(SUM (APS.amount_due_remaining                         * NVL (APS.exchange_rate, 1)),0) total_due ,
  NVL(SUM (DECODE (LEAST (1, to_number(TRUNC (SYSDATE)      - TRUNC (APS.due_date))) ,LEAST (0, to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date))) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )) ,0)curr ,
  NVL(SUM (DECODE (GREATEST (1, to_number(TRUNC (SYSDATE)   - TRUNC (APS.due_date))) ,LEAST (30, to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date))) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )) ,0)pd1_30 ,
  NVL(SUM (DECODE (GREATEST (31, to_number(TRUNC (SYSDATE)  - TRUNC (APS.due_date))) ,LEAST (60, to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date))) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )),0) pd31_60 ,
  NVL(SUM (DECODE (GREATEST (61, to_number(TRUNC (SYSDATE)  - TRUNC (APS.due_date))) ,LEAST (90, to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date))) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )) ,0)pd61_90 ,
  NVL(SUM (DECODE (GREATEST (91, to_number(TRUNC (SYSDATE)  - TRUNC (APS.due_date))) ,LEAST (180, to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date))) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )) ,0)pd91_180 ,
  NVL(SUM (DECODE (GREATEST (181, to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date))) ,LEAST (365, to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date))) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )),0) pd181_365 ,
  NVL(SUM (DECODE (GREATEST (366, to_number(TRUNC (SYSDATE) - TRUNC (aps.due_date))) ,GREATEST (365, to_number(TRUNC (SYSDATE) - TRUNC (aps.due_date))) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )) ,0)pd_366 ,
  SUM (NVL (APS.amount_in_dispute, 0) * NVL (APS.exchange_rate, 1)) disputed_total_aged ,
  ARC.Name collector_code ,
  HCA.orig_system_reference AOPS_NUM ,
  HCA.attribute6 ACCT_EST_DATE ,
  HCPA.OVERALL_CREDIT_LIMIT credit_limit
FROM AR.HZ_PARTIES HP ,
  AR.HZ_CUST_ACCOUNTS HCA ,
  AR.AR_PAYMENT_SCHEDULES_ALL APS ,
  AR.HZ_CUSTOMER_PROFILES HCP ,
  AR.AR_COLLECTORS ARC ,
  AR.HZ_CUST_PROFILE_AMTS HCPA ,
  AR.RA_TERMS_TL RT,
  xxcrm.xx_crm_wcelg_cust ELG
WHERE HP.party_id               = HCA.party_id
AND HCA.cust_account_id         = APS.customer_id(+)
AND HCP.cust_account_id (+)        = HCA.cust_account_id
AND HCA.cust_account_id         = ELG.cust_account_id
AND HCA.party_id                =ELG.party_id
AND ELG.party_id                =hp.party_id
AND ARC.collector_id            = HCP.collector_id
AND HCP.standard_terms          = RT.term_id(+)
AND HCP.site_use_id            IS NULL
AND HCP.CUST_ACCOUNT_PROFILE_ID = HCPA.CUST_ACCOUNT_PROFILE_ID
AND HCPA.currency_code          = 'USD'
AND aps.status                  = 'OP'
AND NVL(aps.CLASS, 'INV')    IN ('PMT','CB','INV','DM','CM')
GROUP BY HCA.cust_account_id,
  HP.party_name,
  HCA.account_number,
  HP.party_number,
  RT.name ,
  ARC.NAME ,
  HCA.ORIG_SYSTEM_REFERENCE,
  HCA.ATTRIBUTE6,
  HCPA.OVERALL_CREDIT_LIMIT;
 