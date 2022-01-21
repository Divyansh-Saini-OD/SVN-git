SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                                                  |
-- +==================================================================================+
-- | SQL Script to create the table:  XX_CE_MKTPLC_PRE_STG_FILES                       |
-- |                                                                                  |
-- |RICE_ID:I3123
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       18-SEP-2018    Priyam  P          Initial DRAFT version                |
-- |                                                                                  |
-- +==================================================================================+

PROMPT
PROMPT Creating Edition View for XX_CE_MKTPLC_PRE_STG_FILES .....
PROMPT **Edition View creates as XX_CE_MKTPLC_PRE_STG_FILES# in XXFIN schema**
PROMPT **Synonym creates as XX_CE_MKTPLC_PRE_STG_FILES in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_CE_MKTPLC_PRE_STG_FILES');

SHOW ERRORS;
EXIT;