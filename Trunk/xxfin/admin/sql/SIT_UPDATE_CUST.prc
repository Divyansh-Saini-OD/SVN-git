-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to update the attributes of ar_cons_inv_all                    |	
-- |                                                                          |  
-- |Table    :    ar_cons_inv_all                                             |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          25-OCT-2018   Aniket J                                       |



UPDATE AR.HZ_CUSTOMER_PROFILES SET ATTRIBUTE6=NULL WHERE CUST_ACCOUNT_ID=7520;
UPDATE AR.HZ_CUSTOMER_PROFILES SET ATTRIBUTE6=NULL WHERE CUST_ACCOUNT_ID=7571 ; 

COMMIT;   

SHOW ERRORS;

EXIT;