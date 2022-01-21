-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to update the status for reprocessing of records for TXT       |  
-- |Table    : XX_AR_EBL_FILE                                                 |
-- |Description : For Defect# 42312                                           |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          06-JUN-2017   Punit Gupta             Defect# 42312          |
-- +==========================================================================+
UPDATE XX_AR_EBL_FILE 
SET STATUS = 'MANIP_READY'
WHERE FILE_TYPE = 'TXT'
AND FILE_ID IN
(2960250,
2960251,
2960252,
2960253,
2960254
);

UPDATE XX_AR_EBL_CONS_HDR_MAIN
SET STATUS = 'MANIP_READY'
WHERE FILE_ID IN
(2960250,
2960251,
2960252,
2960253,
2960254
);

COMMIT;