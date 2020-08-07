SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_AR_SUBSCRIPTIONS_EV_SYN.vw                                                |
-- | Description : Scripts to create Editioned Views  for object XX_AR_SUBSCRIPTIONS        	|
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        30-NOV-2017     Thejaswini Rajula          Initial version         		|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_AR_SUBSCRIPTIONS .....
PROMPT **Edition View creates as XX_AR_SUBSCRIPTIONS# in XXFIN schema**
PROMPT **Synonym creates as XX_AR_SUBSCRIPTIONS in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AR_SUBSCRIPTIONS');

SHOW ERRORS;
EXIT;