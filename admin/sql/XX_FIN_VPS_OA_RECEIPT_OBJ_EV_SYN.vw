SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_FIN_VPS_OA_RECEIPT_OBJ_EV_SYN.vw                                          |
-- | Description : Scripts to create Editioned Views and synonym for XX_FIN_VPS_OA_RECEIPT_OBJ  |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        09-JUL-2017     Sreedhar Mohan       Initial version                             |
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_FIN_VPS_OA_RECEIPT_OBJ .....
PROMPT **Edition View creates as XX_FIN_VPS_OA_RECEIPT_OBJ# in XXFIN schema**
PROMPT **Synonym creates as XX_FIN_VPS_OA_RECEIPT_OBJ in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_FIN_VPS_OA_RECEIPT_OBJ');

SHOW ERRORS;
EXIT;