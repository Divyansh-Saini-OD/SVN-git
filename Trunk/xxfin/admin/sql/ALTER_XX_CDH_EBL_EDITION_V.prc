WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
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
-- |1.0          09-JUN-2018   Thilak Kumar E          Defect# Wave4          |
-- +==========================================================================+

exec ad_zd_table.patch('XXCRM','XX_CDH_EBL_MAIN');

exec ad_zd_table.patch('XXCRM','XX_CDH_EBL_TEMPL_DTL_TXT');

exec ad_zd_table.patch('XXCRM','XX_CDH_EBL_TEMPL_HDR_TXT');

exec ad_zd_table.patch('XXCRM','XX_CDH_EBL_TEMPL_TRL_TXT');

COMMIT;