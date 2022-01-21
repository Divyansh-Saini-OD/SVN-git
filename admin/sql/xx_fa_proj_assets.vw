
-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                              |
-- +==================================================================================+
-- | SQL Index Script to create the table:  xx_fa_status               |
-- |                                                                                  |
-- |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       15-MAR-2019   Priyam Parmar       Initial DRAFT version                      |
-- |                                                                                  |
-- +==================================================================================+

PROMPT
PROMPT Creating  View for xx_fa_status.....
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_FA_PROJ_ASSETS');

EXIT;
