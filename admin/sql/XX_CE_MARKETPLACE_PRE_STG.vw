SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                                                  |
-- +==================================================================================+
-- | SQL Script to create the table:  XX_CE_MARKETPLACE_PRE_STG                       |
-- |                                                                                  |
-- |RICE_ID:I3123
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       28-JUN-2018    Digamber S          Initial DRAFT version                |
-- |                                                                                  |
-- +==================================================================================+

PROMPT
PROMPT Creating Edition View for XX_CE_MARKETPLACE_PRE_STG .....
PROMPT **Edition View creates as XX_CE_MARKETPLACE_PRE_STG# in XXFIN schema**
PROMPT **Synonym creates as XX_CE_MARKETPLACE_PRE_STG in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_CE_MARKETPLACE_PRE_STG');

SHOW ERRORS;
EXIT;