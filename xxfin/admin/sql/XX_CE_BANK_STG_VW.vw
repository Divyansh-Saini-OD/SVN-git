SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_CE_BANK_STG.vw                                                            |
-- | Description : Scripts to create Editioned Views and synonym for object                     |
-- | Rice Name   : E7045                                                                          |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ===========     ================     ============================================|
-- | V1.0      23-OCT-2018     Jitendra Atale        Initial version               				|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_CE_BANK_STG .....
PROMPT **Edition View creates as XX_CE_BANK_STG# in XXFIN schema**
PROMPT **Synonym creates as XX_CE_BANK_STG in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN', 'XX_CE_BANK_STG'); 

SHOW ERRORS;
EXIT;
