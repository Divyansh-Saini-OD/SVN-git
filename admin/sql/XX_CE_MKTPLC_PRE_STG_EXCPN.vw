SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                                                  |
-- +==================================================================================+
-- | SQL Script to create the table:  XX_CE_MKTPLC_PRE_STG_EXCPN                       |
-- |                                                                                  |
-- |RICE_ID:I3123
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       08-AUG-18    Priyam P          Initial DRAFT version                |
-- |                                                                                  |
-- +==================================================================================+

PROMPT
PROMPT Creating Edition View for XX_CE_MKTPLC_PRE_STG_EXCPN .....
PROMPT **Edition View creates as XX_CE_MKTPLC_PRE_STG_EXCPN# in XXFIN schema**
PROMPT **Synonym creates as XX_CE_MKTPLC_PRE_STG_EXCPN in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_CE_MKTPLC_PRE_STG_EXCPN');

SHOW ERRORS;
EXIT;