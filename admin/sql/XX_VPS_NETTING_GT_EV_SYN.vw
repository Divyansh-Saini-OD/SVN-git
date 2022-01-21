SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_VPS_NETTING_GT.vw                                        			|
-- | Description : Scripts to create Editioned Views and synonym for XX_VPS_NETTING_GT		|
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        09-JUL-2017     Uday Jadhav	    Initial version                             |
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_VPS_NETTING_GT.....
PROMPT **Edition View creates as XX_VPS_NETTING_GT# in XXFIN schema**
PROMPT **Synonym creates as XX_VPS_NETTING_GT in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_VPS_NETTING_GT');

SHOW ERRORS;
EXIT;