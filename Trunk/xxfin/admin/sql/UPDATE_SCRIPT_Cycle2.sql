-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to update the status for reprocess of records for XLS and TXT  |  
-- |Table    : XX_AR_EBL_FILE                                                 |
-- |Description : For Defect 42312                                            |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          12-JUN-2017   Punit Gupta             Defect 42381           |
-- +==========================================================================+
UPDATE XX_AR_EBL_FILE 
SET STATUS = 'MANIP_READY'
WHERE FILE_ID IN
(2963753,
 2963780
);

UPDATE XX_AR_EBL_CONS_HDR_MAIN
SET STATUS = 'MANIP_READY'
WHERE FILE_ID IN
(2963753,
 2963780
);

DELETE FROM xx_ar_ebl_txt_hdr_stg
WHERE file_id = 2963753;

DELETE FROM xx_ar_ebl_txt_dtl_stg
WHERE file_id = 2963753;

DELETE FROM xx_ar_ebl_txt_trl_stg
WHERE file_id = 2963753;

DELETE FROM xx_ar_ebl_xls_stg
WHERE file_id = 2963780;

COMMIT;