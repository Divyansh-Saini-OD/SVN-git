--SET VERIFY OFF;
--SET SHOW OFF;
--SET ECHO OFF;
--SET TAB OFF;
--SET FEEDBACK OFF;
--WHENEVER SQLERROR CONTINUE;
--WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :    xx_ar_paydocs_bl_update.sql
-- | 
-- | Description  : This script is to set the bill leve value a s "SITE" |
-- | for all the consolidated customers 
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author               Remarks                 |
-- |=======   ==========  =============        ======================= |
-- |1.0       20-JAN-13 Arun Gannarapu   Initial draft version       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+



Update apps.xx_cdh_cust_acct_ext_b
set c_ext_attr20 = 'SITE'
where c_ext_attr1 = 'Consolidated Bill' --Like 'Con%' --solidated'
and c_ext_attr2 = 'Y' -- Paydoc 
and attr_group_id = 166 ;

/

Commit ;

/
