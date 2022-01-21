
-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                              |
-- +==================================================================================+
-- | SQL Index Script to create the view:  XX_GL_CLD2EBS_MAPPING               |
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
PROMPT Creating  View for XX_GL_CLD2EBS_MAPPING.....
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_GL_CLD2EBS_MAPPING');

EXIT;