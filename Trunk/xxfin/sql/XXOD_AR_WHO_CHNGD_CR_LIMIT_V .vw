CREATE OR REPLACE  VIEW XXOD_AR_WHO_CHNGD_CR_LIMIT_V 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                      Wipro/Office Depot                           |
-- +===================================================================+
-- | Name       : XXOD_AR_WHO_CHNGD_CR_LIMIT_V                         |
-- | Description: R0491_ Who Changed The Credit Limit report           |
-- |               displays the details by whom the Customer’s credit  |
-- |               Limits are changed.                                 |
-- |                                                                   |
-- |                                                                   |                
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author            Remarks                   |
-- |=======   ==========   =============     ==========================|
-- |1.0       09-JUL-2007  siva              Initial version-          |
-- |1.1       17-JUL-2007  siva             Changed as per Client      |
-- |                                         suggestion use HZ tables  |
-- +==================================================================+|
(
created_by
,customer_name
,credit_limit 
,trx_credit_limit
,customer_number
,creation_date
,last_updated_by
,last_update_date
,last_update_login 
,currency_code
,on_hold
,hold_date
,outstanding_balance
)
AS
SELECT fcu.user_name created_by    
       ,HP.party_name                     
       ,ACH.credit_limit                
       ,ACH.trx_credit_limit         
       ,HCA.account_number    
       ,TO_CHAR(ACH.creation_date,'DD-MON-YYYY') creation_date          
       ,fuu.user_name last_updated_by
       ,ACH.last_update_date      
       ,ACH.last_update_login      
       ,ACH.currency_code           
       ,ACH.on_hold                     
       ,ACH.hold_date                  
       ,ACH.outstanding_balance
FROM fnd_user fcu
     ,fnd_user fuu
     ,ar_credit_histories ACH
     ,hz_parties HP
     ,hz_cust_accounts HCA
WHERE HCA.cust_account_id=ACH.customer_id
      AND  HP.party_id=HCA.party_id
      AND  ACH.created_by = fcu.user_id
      AND  ACH.last_updated_by = fuu.user_id
ORDER BY HP.party_name;