SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_AP_RCVWRITE_OFF_STG.vw                                            		|
-- | Description : Scripts to create Editioned Views and synonym for object XX_AP_RCVWRITE_OFF_STG |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- | V1.0     01-16-2018   	   Naveen Patha       Initial version               				|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_AP_RCVWRITE_OFF_STG .....
PROMPT **Edition View creates as XX_AP_RCVWRITE_OFF_STG# in XXFIN schema**
PROMPT **Synonym creates as XX_AP_RCVWRITE_OFF_STG in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN', 'XX_AP_RCVWRITE_OFF_STG'); 

SHOW ERRORS;
EXIT;