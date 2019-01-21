SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_AR_SERV_CONTR_API_ERRORS_EV_SYN.vw                                        |
-- | Description : Scripts to create Editioned Views  for object XX_AR_SERV_CONTR_API_ERRORS	|
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        03-JAN-2018     Sridhar Burri        Initial version                             |
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_AR_SERV_CONTR_API_ERRORS .....
PROMPT **Edition View creates as XX_AR_SERV_CONTR_API_ERRORS# in XXFIN schema**
PROMPT **Synonym creates as XX_AR_SERV_CONTR_API_ERRORS in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AR_SERV_CONTR_API_ERRORS');

SHOW ERRORS;
EXIT;