-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to update the payment terms of unprocessed accounts            |	
-- |                                                                          |  
-- |Table    :    FND_LOOKUP_VALUES                                             |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          20-FEB-2018   Thilak Kumar E          Regression Test        |
-- +==========================================================================+

DELETE FROM FND_LOOKUP_VALUES WHERE LOOKUP_CODE = '10069' AND LOOKUP_TYPE ='XX_AR_EBL_TXT_DATA_FMT_COLS';

COMMIT;   

SHOW ERRORS;
EXIT;