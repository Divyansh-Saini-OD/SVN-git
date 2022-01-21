SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name  :            XX_OM_DPSPARENT_STG.grt                        |
-- | Rice ID :          I1151  DPS cancel order                        |
-- | Description      : This scipt grant xx_om_dpsparent_stg to APPS   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1   25-APR-2007 Rizwan A         Initial Version             |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

GRANT ALL ON xx_om_dpsparent_stg TO apps
/
SHOW ERROR