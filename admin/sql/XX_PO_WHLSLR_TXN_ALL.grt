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
-- | Name             : XX_PO_WHLSLR_TXN_ALL.grt                       |
-- | Rice ID          : I1331 GetOM Info                               |
-- | Description      : This scipt provides grant to the custom table  |
-- |                    XX_PO_WHLSLR_HDR_ALL in APPS schema            |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1   25-JUL-2007 Aravind A         Initial Version            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROMPT
PROMPT Providing grant on custom table xx_po_whlslr_txn_all
PROMPT

GRANT ALL ON  XXOM.xx_po_whlslr_txn_all TO APPS;                                                                                             
                   

SHOW ERROR