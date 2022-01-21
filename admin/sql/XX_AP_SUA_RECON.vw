
-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                                                  |
-- +==================================================================================+
-- | SQL Index Script to create the table:  XX_AP_SUA_RECON                           |
-- |                                                                                  |
-- |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       25-JAN-2021   Paddy Sanjeevi       Initial DRAFT version                |
-- |                                                                                  |
-- +==================================================================================+

PROMPT
PROMPT Creating  View for XX_AP_SUA_RECON..... 
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AP_SUA_RECON');

EXIT;