CREATE OR REPLACE VIEW XXOD_AR_DEFAULT_FIRST_PMT_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                      Wipro/Office Depot                           |
-- +===================================================================+
-- | Name  : XXOD_AR_DEFAULT_FIRST_PMT_V                               |
-- | Description: R0450_Default first payment report provides on a     | 
-- |              daily basis all accounts who have no prior           |
-- |              purchasing history with Office Depot                 |
-- |               and have a invoice which is past due.               | 
-- |                                                                   |
-- |                                                                   |                
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author            Remarks                   |
-- |=======   ==========   =============     ==========================|
-- |1.0       30-JUL-2007  Antony            Initial version           |
-- +===================================================================+|
(customer_number
,customer_name
,amount_past_due
,days_past_due
,credit_limit
,city
,state
)
AS              
(SELECT  HCA.account_number 			
        ,HP.party_name 				
        ,APS.amount_due_remaining		                   
        ,TRUNC(SYSDATE) - TRUNC(MIN(APS.due_date))	
        ,HCPA.overall_credit_limit 		                    
        ,HL.city 				                    
        ,HL.state 				                     
FROM  ar_payment_schedules   APS
      ,hz_cust_accounts      HCA
      ,hz_parties            HP
      ,hz_cust_profile_amts  HCPA
      ,hz_locations          HL
      ,hz_party_sites        HPS
      ,ra_customer_trx       RCT
      ,gl_sets_of_books      GSOB                 
WHERE APS.status                  = 'OP'
AND GSOB.set_of_books_id          = fnd_profile.value('GL_SET_OF_BKS_ID') 
AND GSOB.currency_code            = HCPA.currency_code
AND HCPA.cust_account_id          = APS.customer_id
AND APS.customer_id               = HCA.cust_account_id
AND APS.customer_id               = RCT.paying_customer_id
AND HCA.party_id                  = HP.party_id
AND HPS.party_id                  = HP.party_id
AND HPS.location_id               = HL.location_id
AND HPS.identifying_address_flag  = 'Y'
AND APS.amount_due_remaining  != 0
AND TRUNC(RCT.term_due_date) <= TRUNC(SYSDATE)
AND TRUNC(APS.due_date)           <= TRUNC(SYSDATE)
AND HCPA.site_use_id IS NULL
AND EXISTS (
                SELECT RCTX.paying_customer_id
                FROM ra_customer_trx    RCTX
                     ,ra_cust_trx_types RCTT
                WHERE RCTX.paying_customer_id     = RCT.paying_customer_id
                      AND   RCTX.cust_trx_type_id = RCTT.cust_trx_type_id
                      AND   RCTT.type             ='INV'
                GROUP BY RCTX.paying_customer_id 
                HAVING COUNT(RCTX.paying_customer_id) = 1)
GROUP BY HCA.account_number 			
         ,HP.party_name 				
         ,APS.amount_due_remaining		                   
         ,HCPA.overall_credit_limit 		                    
         ,HL.city 				                    
         ,HL.state );
