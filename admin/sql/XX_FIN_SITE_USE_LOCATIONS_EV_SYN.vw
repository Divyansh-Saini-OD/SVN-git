SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_FIN_SITE_USE_LOCATIONS_EV_SYN.vw                                            |
-- | Description : Scripts to create Editioned Views and synonym for object XX_FIN_SITE_USE_LOCATIONS  |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        31-JUL-2017     Madhu Bolli          Initial version (Defect#42651)              |
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_FIN_SITE_USE_LOCATIONS .....
PROMPT **Edition View creates as XX_FIN_SITE_USE_LOCATIONS# in XXFIN schema**
PROMPT **Synonym creates as XX_FIN_SITE_USE_LOCATIONS in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_FIN_SITE_USE_LOCATIONS');

SHOW ERRORS;
EXIT;