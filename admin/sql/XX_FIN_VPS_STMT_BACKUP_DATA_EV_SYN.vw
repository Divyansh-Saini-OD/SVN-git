SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_FIN_VPS_STMT_BACKUP_DATA_EV_SYN.vw                                        |
-- | Description : Scripts to create Editioned Views and synonym for XX_FIN_VPS_STMT_BACKUP_DATA|
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        09-JUL-2017     Sreedhar Mohan       Initial version                             |
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_FIN_VPS_STMT_BACKUP_DATA .....
PROMPT **Edition View creates as XX_FIN_VPS_STMT_BACKUP_DATA# in XXFIN schema**
PROMPT **Synonym creates as XX_FIN_VPS_STMT_BACKUP_DATA in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_FIN_VPS_STMT_BACKUP_DATA');

SHOW ERRORS;
EXIT;