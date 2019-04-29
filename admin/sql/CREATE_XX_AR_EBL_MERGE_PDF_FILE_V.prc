WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to sychronize new tables                                       |  
-- |Description : For Ebill Central                                           |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          29-APR-2019   Thilak E                Initial                |
-- +==========================================================================+

exec ad_zd_table.patch('XXFIN','XX_AR_EBL_MERGE_PDF_BC_FILE');

COMMIT;