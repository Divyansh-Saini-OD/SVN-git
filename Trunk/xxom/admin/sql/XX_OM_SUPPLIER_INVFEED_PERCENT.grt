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
-- | Name             : XX_OM_SUPPLIER_INVFEED_PERCENT.grt             |
-- | Rice ID          : I1186 Supplier Inventory Feed                  |
-- | Description      : This scipt provides grant to the custom table  |
-- |                    XX_OM_SUPPLIER_INVFEED_PERCENT in APPS schema  |
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
PROMPT Providing grant on custom table xx_om_supplier_invfeed_percent
PROMPT

GRANT ALL ON  XXOM.xx_om_supplier_invfeed_percent TO APPS;                                                                    
SHOW ERROR