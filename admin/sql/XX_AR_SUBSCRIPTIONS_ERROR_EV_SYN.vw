SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_AR_SUBSCRIPTIONS_ERRORV_SYN.vw                                            |
-- | Description : Scripts to create Editioned Views  for object XX_AR_SUBSCRIPTIONS_ERROR    	|
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        04-MAR-2018     Jaishankar Kumar     Initial version                     		|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_AR_SUBSCRIPTIONS_ERROR .....
PROMPT **Edition View creates as XX_AR_SUBSCRIPTIONS_ERROR# in XXFIN schema**
PROMPT **Synonym creates as XX_AR_SUBSCRIPTIONS_ERROR in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AR_SUBSCRIPTIONS_ERROR');

SHOW ERRORS;
EXIT;