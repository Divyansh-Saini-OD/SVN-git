SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                              |
-- +==================================================================================+
-- | SQL Script to create the table:  XX_AP_INV_MATCH_DETAIL_219                |
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
PROMPT Creating Editioning View for XX_AP_INV_MATCH_DETAIL_219 .....
PROMPT **Edition View creates as XX_AP_INV_MATCH_DETAIL_219# in XXFIN schema**
PROMPT **Synonym creates as XX_AP_INV_MATCH_DETAIL_219 in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AP_INV_MATCH_DETAIL_219');

SHOW ERRORS;
EXIT;