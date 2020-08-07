SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_FIN_VPS_SYS_NETTING_STG_EV_SYN.vw                                            |
-- | Description : Scripts to create Editioned Views and synonym for object XX_FIN_VPS_SYS_NETTING_STG|
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |DRAFT 1A 04-OCT-2017 Uday Jadhav   Initial draft version          		   		|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_FIN_VPS_SYS_NETTING_STG .....
PROMPT **Edition View creates as XX_FIN_VPS_SYS_NETTING_STG# in XXFIN schema**
PROMPT **Synonym creates as XX_FIN_VPS_SYS_NETTING_STG in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_FIN_VPS_SYS_NETTING_STG');

SHOW ERRORS;
EXIT;