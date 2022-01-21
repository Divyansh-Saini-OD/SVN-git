WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- |SQL Script to sychronize new columns STATUS and END_DATE_ACTIVE	      |  
-- |Description : For Supplier Interface EBS                                  |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          21-JAN-2021   Gitanjali Singh         JIRA # NAIT-127517     |
-- +==========================================================================+

exec ad_zd_table.patch('XXFIN','XX_AP_CLD_SUPP_BCLS_STG');

COMMIT;
COMMIT;