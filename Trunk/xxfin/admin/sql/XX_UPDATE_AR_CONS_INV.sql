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
-- |1.0          29-SEP-2017   Punit Gupta             Regression Test        |

UPDATE apps.ar_cons_inv_all arci
SET attribute2 = NULL,
attribute4 = NULL,
attribute10 = NULL,
attribute15 = NULL
WHERE arci.customer_id IN
(SELECT DISTINCT xaecbs.cust_account_id
FROM apps.xx_ar_ebl_cons_bills_stg xaecbs
WHERE xaecbs.cust_doc_id IN 
(117522929,117522930,117522936,117522939,117522943,117522944,117522945,117522947,117522949,117522950)
);

COMMIT;   

SHOW ERRORS;

EXIT;