-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to update the payment terms of unprocessed accounts            |	
-- |                                                                          |  
-- |Table    :    ar_cons_inv_all                                             |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          04-OCT-2017   Punit Gupta             Regression Test        |

UPDATE ar.hz_customer_profiles HCP
SET STANDARD_TERMS = 18503
WHERE hcp.cust_account_id 
IN
(
35018,
123278,
114110,
185428,
185647
)
and site_use_id is not null;

COMMIT;   

SHOW ERRORS;

EXIT;