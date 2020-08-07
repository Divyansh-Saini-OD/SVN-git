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
-- |1.0          19-SEP-2018   Aniket J                Initial                |
-- +==========================================================================+

exec ad_zd_table.patch('XXFIN','XX_AR_OPSTECH_BILL_STG');

exec ad_zd_table.patch('XXFIN','XX_AR_OPSTECH_FILE');

COMMIT;