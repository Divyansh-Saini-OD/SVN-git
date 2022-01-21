SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_FIN_ESP_STATS_VW.vw                                                     |
-- | Description : Scripts to create Editioned Views and synonym for object XX_FIN_ESP_STATS  |
-- | Rice Name: I3126                                                                           |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ===========     ================     ============================================|
-- | V1.0      09-OCT-2018     Havish Kasina        Initial version               				|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_FIN_ESP_STATS .....
PROMPT **Edition View creates as XX_FIN_ESP_STATS# in XXFIN schema**
PROMPT **Synonym creates as XX_FIN_ESP_STATS in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN', 'XX_FIN_ESP_STATS'); 

SHOW ERRORS;
EXIT;