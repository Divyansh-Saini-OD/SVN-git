WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- |SQL Script to sychronize update in column dataytpe for column DCN	      |  
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          13-APR-2021   Pratik Gadia            NAIT-176470            |
-- +==========================================================================+

exec ad_zd_table.patch('XXFIN','XX_AP_DCN_STG');


COMMIT;