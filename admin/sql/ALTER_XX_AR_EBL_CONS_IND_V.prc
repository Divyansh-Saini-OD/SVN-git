WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to sychronize new columns SKU_LEVEL_TAX and SKU_LEVEL_TOTAL    |  
-- |Description : For Wave 5 requirement                                      |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          19-AUG-2018   Aarthi                  Defect# Wave5          |
-- +==========================================================================+

exec ad_zd_table.patch('XXFIN','XX_AR_EBL_IND_DTL_MAIN');

exec ad_zd_table.patch('XXFIN','XX_AR_EBL_IND_DTL_HIST');

exec ad_zd_table.patch('XXFIN','XX_AR_EBL_CONS_DTL_MAIN');

exec ad_zd_table.patch('XXFIN','XX_AR_EBL_CONS_DTL_HIST');

exec ad_zd_table.patch('XXFIN','XX_AR_EBL_CONS_LINES_STG');

exec ad_zd_table.patch('XXFIN','XX_AR_EBL_CONS_LINES_HIST');

exec ad_zd_table.patch('XXFIN','XX_AR_EBL_TRANSMISSION');

exec ad_zd_table.patch('XXFIN','XX_EPDF_REQ_ID');

COMMIT;