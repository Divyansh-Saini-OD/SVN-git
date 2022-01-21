CREATE MATERIALIZED VIEW XX_AR_CUSTOMER_PARENT_MV
BUILD IMMEDIATE 
REFRESH COMPLETE ON DEMAND START WITH sysdate+0 NEXT SYSDATE+1/4
AS 
/*
  -- +============================================================================================|                                                                                                     
  -- |  Office Depot                                                                              |                                                                                                     
  -- +============================================================================================|                                                                                                     
  -- |  Name:  XX_AR_CUSTOMER_PARENT_MV                                                          |                                                                                                     
  -- |                                                                                            |                                                                                                     
  -- |  Description: This package body pulls customer data as objects and interfaces with EAI for BSD   |                                                                                                     
  -- |  																					      |                                                                                                     
  -- |  Change Record:                                                                            |                                                                                                     
  -- +============================================================================================|                                                                                                     

  -- | Version     Date         Author               Remarks                                      |                                                                                                     
  -- | =========   ===========  =============        =============================================|                                                                                                    
  -- | 1.0        01-Sept-2020 Amit Kumar		     NAIT-147376 / NAIT-147376/ NAIT-136440       |                     
  -- +============================================================================================| */
SELECT HP_PAR.party_name par_customer_name ,
  HCA_PAR.account_number par_customer_number,
  HCA_PAR.orig_system_reference par_AOPS_NUM,
  HCA.account_number original_customer_number,
  HCA.orig_system_reference orig_AOPS_NUM
FROM ar.hz_parties HP_PAR ,
  ar.hz_cust_accounts HCA_PAR ,
  ar.hz_hierarchy_nodes HHN ,
  ar.hz_parties HP ,
  ar.hz_cust_accounts HCA
WHERE HP_PAR.party_id  = HCA_PAR.party_id
AND HHN.parent_id      = HP_PAR.party_id
AND HHN.parent_id     <> HHN.child_id
AND HHN.child_id       = HP.party_id
AND HP.party_id        = HCA.party_id
AND HHN.hierarchy_type = 'OD_FIN_HIER'
AND SYSDATE BETWEEN NVL (HHN.effective_start_date, SYSDATE) AND NVL (HHN.effective_end_date, SYSDATE)
AND NVL(HHN.status, 'A') = 'A'
and PARENT_TABLE_NAME='HZ_PARTIES'
and CHILD_TABLE_NAME='HZ_PARTIES'
and PARENT_OBJECT_TYPE=CHILD_OBJECT_TYPE;
