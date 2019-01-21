WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to sychronize new tables                                       |  
-- |Description : For Bill Complete                                           |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          19-DEC-2018   Aniket J                Initial                |
-- +==========================================================================+

exec ad_zd_table.patch('XXCRM','XX_CDH_CUST_ACCT_EXT_B');

COMMIT;