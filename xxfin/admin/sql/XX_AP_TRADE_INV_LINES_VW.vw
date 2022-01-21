SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_AP_TRADE_INV_LINES_VW.vw                                            		|
-- | Description : Scripts to create Editioned Views and synonym for object XX_AP_TRADE_INV_LINES |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- | V1.0     01-10-2018   	   Havish Kasina        Initial version               				|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_AP_TRADE_INV_LINES .....
PROMPT **Edition View creates as XX_AP_TRADE_INV_LINES# in XXFIN schema**
PROMPT **Synonym creates as XX_AP_TRADE_INV_LINES in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN', 'XX_AP_TRADE_INV_LINES'); 

SHOW ERRORS;
EXIT;