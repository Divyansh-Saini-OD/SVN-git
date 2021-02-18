
-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                                                  |
-- +==================================================================================+
-- | SQL Index Script to create the table:  XX_AP_SUA_INTF_FILES                      |
-- |                                                                                  |
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
PROMPT Creating  View for xx_ap_sua_intf_files.....
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AP_SUA_INTF_FILES');

EXIT;