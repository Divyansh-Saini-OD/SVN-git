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

UPDATE ar.ar_cons_inv_all arci
SET attribute2 = NULL,
attribute4 = NULL,
attribute10 = NULL,
attribute15 = NULL
WHERE arci.customer_id IN
(35018,
123278,
114110,
185428,
185647);

COMMIT;   

SHOW ERRORS;

EXIT;