SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_AR_SUBSCRIPTION_PAYLOADS_EV_SYN.vw                                        |
-- | Description : Scripts to create Editioned Views  for object XX_AR_SUBSCRIPTION_PAYLOADS	|
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        03-20-2018      Dinesh Nagapuri      Initial version         		     		|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_AR_SUBSCRIPTION_PAYLOADS .....
PROMPT **Edition View creates as XX_AR_SUBSCRIPTION_PAYLOADS# in XXFIN schema**
PROMPT **Synonym creates as XX_AR_SUBSCRIPTION_PAYLOADS in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AR_SUBSCRIPTION_PAYLOADS');

SHOW ERRORS;
EXIT;