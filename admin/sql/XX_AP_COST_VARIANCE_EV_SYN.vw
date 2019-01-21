SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_AP_COST_VARIANCE.vw                                            |
-- | Description : Scripts to create Editioned Views and synonym for object XX_FIN_VPS_RECEIPTS_STG|
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        11/08/2017      Uday Jadhav          Initial version         					|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_AP_COST_VARIANCE .....
PROMPT **Edition View creates as XX_AP_COST_VARIANCE# in XXFIN schema**
PROMPT **Synonym creates as XX_AP_COST_VARIANCE in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AP_COST_VARIANCE');

SHOW ERRORS;
EXIT;