-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : UPDATE_EBILL_DOCS_WEBADI_UPD.prc                                             |
-- | Description : Ebill Mass Upload Webadi                                                     |
-- | Rice Id     :                                                                              |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        27-AUG-2018     Thilak CG             Initial version                            |
-- +============================================================================================+

UPDATE bne_interface_cols_b 
SET val_addl_w_c = 'value_set_id = 1011050 AND enabled_code = ''Y'' AND (NVL(start_date,SYSDATE- 1) < SYSDATE) AND (NVL(end_date,SYSDATE+ 1) > SYSDATE) AND internal_name IN (''OPSTECH'', ''ePDF'', ''PRINT'')' 
WHERE interface_col_name = 'P_DELIVERY_METHOD' 
AND application_id = 20044 
AND interface_code = 'OD_CDH_BILLDOCS_UPLOAD_INTF1';

COMMIT;
SHOW ERROR;