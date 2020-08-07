SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_FIN_VPS_RECEIPTS_INTERIM_EV_SYN.vw                                        |
-- | Description : Scripts to create Editioned Views  for object XX_FIN_VPS_RECEIPTS_INTERIM	|
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        30-NOV-2017     Thejaswini Rajula          Initial version         		|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_FIN_VPS_RECEIPTS_INTERIM .....
PROMPT **Edition View creates as XX_FIN_VPS_RECEIPTS_INTERIM# in XXCRM schema**
PROMPT **Synonym creates as XX_FIN_VPS_RECEIPTS_INTERIM in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_FIN_VPS_RECEIPTS_INTERIM');

SHOW ERRORS;
EXIT;