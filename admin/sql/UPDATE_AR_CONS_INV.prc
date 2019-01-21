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
-- +==========================================================================+

UPDATE AR_CONS_INV_ALL
SET ATTRIBUTE4  = NULL,
   ATTRIBUTE15  = NULL
WHERE CONS_INV_ID IN (8016306,8016354,8016900,8016822,8016925,8016472);

COMMIT;   

SHOW ERRORS;

EXIT;