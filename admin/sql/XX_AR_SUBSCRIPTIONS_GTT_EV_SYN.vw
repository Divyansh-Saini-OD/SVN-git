SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_AR_SUBSCRIPTIONS_GTT_EV_SYN.vw                                            |
-- | Description : Scripts to create Editioned Views  for object XX_AR_SUBSCRIPTIONS_GTT      	|
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        04-MAR-2018     Jaishankar Kumar     Initial version                     		|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_AR_SUBSCRIPTIONS_GTT .....
PROMPT **Edition View creates as XX_AR_SUBSCRIPTIONS_GTT# in XXFIN schema**
PROMPT **Synonym creates as XX_AR_SUBSCRIPTIONS_GTT in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AR_SUBSCRIPTIONS_GTT');

SHOW ERRORS;
EXIT;