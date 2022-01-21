
-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                              |
-- +==================================================================================+
-- | SQL Script to create the table:  XX_GL_JRNLS_CLD_INTF_STG                         |
-- |                                                                                  |
-- |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       26-APR-2019   M K Pramod Kumar     Initial DRAFT version for (Oracle Cloud to EBS GL Interface) |
-- |                                                                                  |
-- +==================================================================================+

PROMPT
PROMPT Creating  View for XX_GL_JRNLS_CLD_INTF_STG.....
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_GL_JRNLS_CLD_INTF_STG');

EXIT;