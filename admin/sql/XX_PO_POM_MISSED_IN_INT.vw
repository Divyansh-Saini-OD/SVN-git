SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_PO_POM_MISSED_IN_INT.vw                                            			|
-- | Description : Scripts to create Editioned Views and synonym for object XX_PO_POM_MISSED_IN_INT|
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- | V1.0     01-04-2018   		Madhu Bolli          Initial version               				|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_PO_POM_MISSED_IN_INT .....
PROMPT **Edition View creates as XX_PO_POM_MISSED_IN_INT# in XXFIN schema**
PROMPT **Synonym creates as XX_PO_POM_MISSED_IN_INT in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN', 'XX_PO_POM_MISSED_IN_INT'); 

SHOW ERRORS;
EXIT;