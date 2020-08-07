SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +==================================================================================+  
-- | Office Depot - C2FO                                                              |
-- |                                                                                  |
-- +==================================================================================+
-- | SQL Script to create the table:  XX_AP_C2FO_MARKETS                              |
-- |                                                                                  |
-- |RICE_ID:                                                                          |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   ===============      =====================================|
-- |1.0       28-AUG-2018   Antonio Morales      Initial version                      |
-- |                                                                                  |
-- +==================================================================================+

PROMPT
PROMPT Creating Edition View for XX_AP_C2FO_MARKETS .....
PROMPT **Edition View creates as XX_AP_C2FO_MARKETS# in XXFIN schema**
PROMPT **Synonym creates as XX_AP_C2FO_MARKETS in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AP_C2FO_MARKETS');

SHOW ERRORS;
EXIT;