CREATE MATERIALIZED VIEW XX_AR_CUSTOMER_AGING_CH_MV
BUILD IMMEDIATE 
REFRESH COMPLETE ON DEMAND START WITH sysdate+0 NEXT SYSDATE+1/4
AS
  /*
  -- +============================================================================================|                                                                                                     
  -- |  Office Depot                                                                              |                                                                                                     
  -- +============================================================================================|                                                                                                     
  -- |  Name:  XX_AR_CUSTOMER_AGING_CH_MV                                                          |                                                                                                     
  -- |                                                                                            |                                                                                                     
  -- |  Description: This package body pulls customer data as objects and interfaces with EAI for BSD   |                                                                                                     
  -- |  																					      |                                                                                                     
  -- |  Change Record:                                                                            |                                                                                                     
  -- +============================================================================================|                                                                                                     

  -- | Version     Date         Author               Remarks                                      |                                                                                                     
  -- | =========   ===========  =============        =============================================|                                                                                                    
  -- | 1.0        01-Sept-2020 Amit Kumar		     NAIT-147376 / NAIT-147376/ NAIT-136440       |                     
  -- +============================================================================================| */
SELECT  /*+ FULL(APS) PARALLEL(APS,8) dynamic_sampling(0) */
  HCA_CH.cust_account_id ch_cust_account_id ,
  HP_CH.party_name ch_customer_name ,
  HCA.account_number par_customer_number,
  HCA_CH.account_number ch_customer_number ,
  HP_CH.party_number ch_party_id ,
  RT.name ch_payment_terms ,
  NVL(SUM (APS.amount_due_remaining                * NVL (APS.exchange_rate, 1)),0) ch_total_due ,
  NVL(SUM (DECODE (LEAST    (1 ,to_number(TRUNC(SYSDATE)   - TRUNC (APS.due_date) ) ) ,LEAST (0 ,to_number( TRUNC (SYSDATE) - TRUNC (APS.due_date) ) ) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )),0) ch_curr ,
  NVL(SUM (DECODE (GREATEST (1 ,to_number(TRUNC (SYSDATE)   - TRUNC (APS.due_date)) ) ,LEAST (30 ,to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date)) ) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )),0) ch_pd1_30 ,
  NVL(SUM (DECODE (GREATEST (31 ,to_number(TRUNC (SYSDATE)  - TRUNC (APS.due_date)) ) ,LEAST (60 ,to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date)) ) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )),0) ch_pd31_60 ,
  NVL(SUM (DECODE (GREATEST (61 ,to_number(TRUNC (SYSDATE)  - TRUNC (APS.due_date)) ) ,LEAST (90 ,to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date)) ) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )) ,0)ch_pd61_90 ,
  NVL(SUM (DECODE (GREATEST (91 ,to_number(TRUNC (SYSDATE)  - TRUNC (APS.due_date)) ) ,LEAST (180 ,to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date)) ) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )) ,0)ch_pd91_180 ,
  NVL(SUM (DECODE (GREATEST (181 ,to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date)) ) ,LEAST (365 ,to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date)) ) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )) ,0)ch_pd181_365 ,
  NVL(SUM (DECODE (GREATEST (366 ,to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date)) ) ,GREATEST (365 ,to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date)) ) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )) ,0)ch_pd_366 ,
  SUM (NVL (APS.amount_in_dispute, 0) * NVL (APS.exchange_rate, 1)) disputed_total_aged ,
  ARC.Name CH_COLLECTOR ,
  HCA_CH.orig_system_reference CH_AOPS_NUM ,
  HCA.orig_system_reference PAR_AOPS_NUM ,
  HCA_CH.attribute6 CH_ACCT_EST_DATE ,
  HCPA.OVERALL_CREDIT_LIMIT CH_credit_limit
FROM 
  ar.hz_hierarchy_nodes HHN ,
  ar.hz_parties HP_CH ,
  ar.hz_parties HP ,
  ar.ar_collectors ARC ,
  ar.hz_cust_accounts HCA_CH ,
  ar.hz_cust_accounts HCA ,
  ar.ar_payment_schedules_all APS ,
  ar.hz_customer_profiles HCP ,
  ar.hz_cust_profile_amts HCPA ,
  ar.ra_terms_tl RT
WHERE HHN.child_id              = HP_CH.party_id
AND ARC.collector_id            = HCP.collector_id
AND HP_CH.party_id              = HCA_CH.party_id
AND HCA_CH.cust_account_id      = APS.customer_id(+)
AND aps.status                  = 'OP'
AND aps.CLASS                  IN ('PMT','CB','INV','DM','CM')
AND HCP.cust_account_id         = HCA_CH.cust_account_id
AND HCP.standard_terms          = RT.term_id(+)
AND HHN.parent_id              <> HHN.child_id
AND HHN.parent_id               = HP.party_id
AND HP.party_id                 = HCA.party_id
AND HCP.site_use_id            IS NULL
AND HHN.hierarchy_type          = 'OD_FIN_HIER'
AND HCP.CUST_ACCOUNT_PROFILE_ID = HCPA.CUST_ACCOUNT_PROFILE_ID
AND HCPA.currency_code          = 'USD'
AND NVL(HHN.status, 'A')        = 'A'
AND SYSDATE BETWEEN NVL (HHN.effective_start_date, SYSDATE) AND NVL (HHN.effective_end_date, SYSDATE)
AND HHN.level_number       = 1
GROUP BY HCA_CH.cust_account_id ,
  HP_CH.party_name ,
  HCA.account_number ,
  HCA_CH.account_number ,
  HP_CH.party_number ,
  RT.name ,
  ARC.Name ,
  HCA_CH.orig_system_reference , HCA.orig_system_reference,
  HCA_CH.attribute6 ,
  HCPA.OVERALL_CREDIT_LIMIT;
