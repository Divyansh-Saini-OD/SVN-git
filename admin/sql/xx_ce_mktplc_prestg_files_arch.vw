SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                                                  |
-- +==================================================================================+
-- | SQL Script to create the table:  xx_ce_mktplc_prestg_files_arch                       |
-- |                                                                                  |
-- |RICE_ID:I3123
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       27-MAR-2019    Priyam  P          Initial DRAFT version                |
-- |                                                                                  |
-- +==================================================================================+

PROMPT
PROMPT Creating Edition View for xx_ce_mktplc_prestg_files_arch .....
PROMPT **Edition View creates as xx_ce_mktplc_prestg_files_arch# in XXFIN schema**
PROMPT **Synonym creates as xx_ce_mktplc_prestg_files_arch in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_CE_MKTPLC_PRESTG_FILES_ARCH');

SHOW ERRORS;
EXIT;