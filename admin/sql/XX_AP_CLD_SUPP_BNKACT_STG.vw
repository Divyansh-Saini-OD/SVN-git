
-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                              |
-- +==================================================================================+
-- | SQL Index Script to create the view:  XX_AP_CLD_SUPP_BNKACT_STG               |
-- |                                                                                  |
-- |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       18-JUN-2019   Priyam/Visu       Initial DRAFT version                   |
-- |                                                                                  |
-- +==================================================================================+

PROMPT
PROMPT Creating  View for XX_AP_CLD_SUPP_BNKACT_STG.....
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AP_CLD_SUPP_BNKACT_STG');

EXIT;