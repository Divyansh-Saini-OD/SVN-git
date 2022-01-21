-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to update the status for reprocess of records for TXT          |  
-- |Table    : XX_AR_EBL_FILE                                                 |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          26-OCT-2017   Punit Gupta                                    |
-- +==========================================================================+
UPDATE XX_AR_EBL_FILE 
SET STATUS = 'MANIP_READY'
WHERE FILE_ID = 3974965;

UPDATE XX_AR_EBL_CONS_HDR_MAIN
SET STATUS = 'MANIP_READY'
WHERE FILE_ID = 3974965;

DELETE FROM xx_ar_ebl_txt_hdr_stg
WHERE FILE_ID = 3974965;

DELETE FROM xx_ar_ebl_txt_dtl_stg
WHERE FILE_ID = 3974965;

DELETE FROM xx_ar_ebl_txt_trl_stg
WHERE FILE_ID = 3974965;

COMMIT;