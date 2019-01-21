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
-- |1.0          16-DEC-2018   Aniket J                                       |
-- +==========================================================================+


UPDATE  AR_CONS_INV_ALL  
SET attribute4 = REPLACE(attribute4 ,'-','|'),
last_update_date= SYSDATE,
last_updated_by = -1 
WHERE attribute4 IS NOT NULL
AND attribute4 LIKE 'Y-%';

COMMIT;   

SHOW ERRORS;

EXIT;