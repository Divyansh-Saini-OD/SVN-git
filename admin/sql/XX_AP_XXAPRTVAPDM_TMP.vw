SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                              |
-- +==================================================================================+
-- | SQL Script to create the table:  XX_AP_XXAPRTVAPDM_TMP                |
-- |                                                                                  |
-- |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       14-JUN-2018    Priyam Parmar       Initial DRAFT version                      |
-- |                                                                                  |
-- +==================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_AP_XXAPRTVAPDM_TMP .....
PROMPT **Edition View creates as XX_AP_XXAPRTVAPDM_TMP# in XXFIN schema**
PROMPT **Synonym creates as XX_AP_XXAPRTVAPDM_TMP in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AP_XXAPRTVAPDM_TMP');

SHOW ERRORS;
EXIT;