CREATE MATERIALIZED VIEW XX_AR_CUSTOMER_AGING_GC_MV
BUILD IMMEDIATE 
REFRESH FORCE ON DEMAND START WITH sysdate+0 NEXT SYSDATE+1/4
AS
  /*
  -- +============================================================================================|                                                                                                     
  -- |  Office Depot                                                                              |                                                                                                     
  -- +============================================================================================|                                                                                                     
  -- |  Name:  XX_AR_CUSTOMER_AGING_GC_MV                                                          |                                                                                                     
  -- |                                                                                            |                                                                                                     
  -- |  Description: This package body pulls customer data as objects and interfaces with EAI for BSD   |                                                                                                     
  -- |  																					      |                                                                                                     
  -- |  Change Record:                                                                            |                                                                                                     
  -- +============================================================================================|                                                                                                     

  -- | Version     Date         Author               Remarks                                      |                                                                                                     
  -- | =========   ===========  =============        =============================================|                                                                                                    
  -- | 1.0        01-Sept-2020 Amit Kumar		     NAIT-147376 / NAIT-147376/ NAIT-136440       |                     
  -- +============================================================================================| */
SELECT HCA.cust_account_id gch_cust_account_id ,
  HCA.account_number gch_customer_number ,
  HP.party_name gch_customer_name ,
  HP.party_number gch_party_id ,
  RT.name gch_payment_terms ,
  NVL(SUM (aps.amount_due_remaining                * NVL (aps.exchange_rate, 1)) ,0)gch_total_due ,
  NVL(SUM (DECODE (LEAST    (1 ,to_number( TRUNC(SYSDATE)   - TRUNC (APS.due_date)) ) ,LEAST (0 ,to_number( TRUNC (SYSDATE) - TRUNC (APS.due_date) ) ) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )) ,0)gch_curr ,
  NVL(SUM (DECODE (GREATEST (1 ,to_number(TRUNC (SYSDATE)   - TRUNC (APS.due_date)) ) ,LEAST (30 ,to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date)) ) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )) ,0)gch_pd1_30 ,
  NVL(SUM (DECODE (GREATEST (31 ,to_number(TRUNC (SYSDATE)  - TRUNC (APS.due_date)) ) ,LEAST (60 ,to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date)) ) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )) ,0)gch_pd31_60 ,
  NVL(SUM (DECODE (GREATEST (61 ,to_number(TRUNC (SYSDATE)  - TRUNC (APS.due_date)) ) ,LEAST (90 ,to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date)) ) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )) ,0)gch_pd61_90 ,
  NVL(SUM (DECODE (GREATEST (91 ,to_number(TRUNC (SYSDATE)  - TRUNC (APS.due_date)) ) ,LEAST (180 ,to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date)) ) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )),0) gch_pd91_180 ,
  NVL(SUM (DECODE (GREATEST (181 ,to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date)) ) ,LEAST (365 ,to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date)) ) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )) ,0)gch_pd181_365 ,
  NVL(SUM (DECODE (GREATEST (366 ,to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date)) ) ,GREATEST (365 ,to_number(TRUNC (SYSDATE) - TRUNC (APS.due_date)) ) ,APS.amount_due_remaining * NVL (APS.exchange_rate, 1) ,0 )) ,0)gch_pd_366 ,
  SUM (NVL (APS.amount_in_dispute, 0) * NVL (APS.exchange_rate, 1)) disputed_total_aged ,
  ARC.Name GCH_COLLECTOR ,
  HCA.orig_system_reference GCH_AOPS_NUM ,
  TO_CHAR(TO_DATE(HCA.attribute6,'YYYY/MM/DD HH24:MI:SS'),'DD-MON-YYYY') GCH_ACCT_EST_DATE ,
  HCPA.OVERALL_CREDIT_LIMIT gch_credit_limit,
  HHN.parent_id 
FROM 
  ar.hz_hierarchy_nodes HHN ,
  ar.hz_parties HP ,
  ar.hz_cust_accounts HCA ,
  ar.ar_collectors ARC ,
  ar.hz_cust_profile_amts HCPA ,
  ar.hz_customer_profiles HCP ,
  ar.ar_payment_schedules_all APS ,
  ar.ra_terms_tl RT
WHERE HHN.child_id      = HP.party_id
AND HP.party_id         = HCA.party_id
AND HHN.child_id       <> HHN.parent_id
AND HCA.cust_account_id = APS.customer_id(+)
AND HCA.cust_account_id = HCP.cust_account_id
AND ARC.collector_id    = HCP.collector_id
AND HCP.standard_terms  = RT.term_id(+)
AND HHN.parent_id      IN
 (SELECT
   /*+ PUSH_SUBQ NO_MERGE */
   HN.child_id
 FROM ar.hz_hierarchy_nodes HN ,
   ar.hz_cust_accounts CA
 WHERE HN.parent_id    = CA.party_id
  AND HN.parent_id     <> HN.child_id
 AND NVL(HN.status,'A')='A'
 AND SYSDATE BETWEEN NVL (HN.effective_start_date, SYSDATE) AND NVL (HN.effective_end_date, SYSDATE)
 AND HN.hierarchy_type = 'OD_FIN_HIER'
 )
AND HHN.hierarchy_type   = 'OD_FIN_HIER'
AND NVL(HHN.status, 'A') = 'A'
AND SYSDATE BETWEEN NVL (HHN.effective_start_date, SYSDATE) AND NVL (HHN.effective_end_date, SYSDATE)
AND HCP.site_use_id            IS NULL
AND HCP.CUST_ACCOUNT_PROFILE_ID = HCPA.CUST_ACCOUNT_PROFILE_ID
AND HCPA.currency_code          = 'USD'
GROUP BY HCA.cust_account_id ,
  HCA.account_number ,
  HP.party_name ,
  HP.party_number ,
  RT.name ,
  ARC.Name ,
  HCA.orig_system_reference ,
  TO_CHAR(TO_DATE(HCA.attribute6,'YYYY/MM/DD HH24:MI:SS'),'DD-MON-YYYY') ,
  HCPA.OVERALL_CREDIT_LIMIT,HHN.parent_id 
;
