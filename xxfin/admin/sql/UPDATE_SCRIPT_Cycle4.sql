-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to update the status for reprocessing of records for TXT       |  
-- |Table    : XX_AR_EBL_FILE                                                 |
-- |Description : For Defect#                                                 |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          21-JUN-2017   Punit Gupta             Defect#42496           |
-- +==========================================================================+

UPDATE XX_AR_EBL_FILE 
SET STATUS = 'MANIP_READY'
WHERE FILE_TYPE = 'TXT'
AND FILE_ID IN
(2964066,
 2964067,
 2964068,
 2964092,
 2964094,
 2964099
);

UPDATE XX_AR_EBL_CONS_HDR_MAIN
SET STATUS = 'MANIP_READY'
WHERE FILE_ID IN
(2964066,
 2964067,
 2964068,
 2964092,
 2964094,
 2964099
);

COMMIT;