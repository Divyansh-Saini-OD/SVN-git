
-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                                                  |
-- +==================================================================================+
-- | SQL Index Script to create the table:  XX_AP_CLD_SITE_DFF_STG                    |
-- |                                                                                  |
-- |                                                                                  |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       24-JUN-2019   Havish Kasina        Initial DRAFT version                |
-- |                                                                                  |
-- +==================================================================================+

PROMPT
PROMPT Creating  View for XX_AP_CLD_SITE_DFF_STG.....
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AP_CLD_SITE_DFF_STG');

EXIT;