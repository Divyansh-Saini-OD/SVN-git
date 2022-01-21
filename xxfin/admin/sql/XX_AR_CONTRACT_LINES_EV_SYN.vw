SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_AR_CONTRACT_LINES_EV_SYN.vw                                               |
-- | Description : Scripts to create Editioned Views  for object XX_AR_CONTRACT_LINES	        |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        19-JAN-2018     Sridhar Mohan        Initial version                             |
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_AR_CONTRACT_LINES .....
PROMPT **Edition View creates as XX_AR_CONTRACT_LINES# in XXFIN schema**
PROMPT **Synonym creates as XX_AR_CONTRACT_LINES in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AR_CONTRACT_LINES');

SHOW ERRORS;
EXIT;