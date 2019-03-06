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
-- | Name             : XX_OM_SUPP_INV_PERCENT_S.grt                   |
-- | Rice ID          : I1186 Supplier Inventory Feed                  |
-- | Description      : This scipt provides grant to the sequence      |
-- |                    XX_OM_SUPP_INV_PERCENT_S in APPS schema        |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1   6-JULY-2007 Aravind A         Initial Version            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROMPT
PROMPT Providing grant on sequence xx_om_supp_inv_percent_s
PROMPT

GRANT ALL ON  XXOM.xx_om_supp_inv_percent_s TO APPS;                                                                          
SHOW ERROR