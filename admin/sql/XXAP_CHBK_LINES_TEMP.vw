SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                              |
-- +==================================================================================+
-- | SQL Script to create the table:  XXAP_CHBK_LINES_TEMP                |
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
PROMPT Creating Editioning View for XXAP_CHBK_LINES_TEMP .....
PROMPT **Edition View creates as XXAP_CHBK_LINES_TEMP# in XXFIN schema**
PROMPT **Synonym creates as XXAP_CHBK_LINES_TEMP in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XXAP_CHBK_LINES_TEMP');

SHOW ERRORS;
EXIT;