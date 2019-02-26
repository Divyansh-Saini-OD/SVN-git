SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_CDH_AOPS_EXTERNAL_USERS_VW.vw                                             |
-- | Description : Scripts to create Editioned Views and synonym for object                     |
-- |               XX_CDH_AOPS_EXTERNAL_USERS_VW                                                |
-- | Rice Name   : E1328                                                                        |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ===========     ================     ============================================|
-- | V1.0      31-DEC-2018     Havish Kasina        Initial version               				|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_CDH_AOPS_EXTERNAL_USERS .....
PROMPT **Edition View creates as XX_CDH_AOPS_EXTERNAL_USERS# in XXCOMN schema**
PROMPT **Synonym creates as XX_CDH_AOPS_EXTERNAL_USERS in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXCOMN', 'XX_CDH_AOPS_EXTERNAL_USERS'); 

SHOW ERRORS;
EXIT;