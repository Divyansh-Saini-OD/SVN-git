SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                              |
-- +==================================================================================+
-- | SQL Script to create the table:  XX_CE_EBAY_TRX_DTL_STG_ARCH                |
-- |                                                                                  |
-- |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       28-JUN-2018    Priyam Parmar       Initial DRAFT version                      |
-- |                                                                                  |
-- +==================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_CE_EBAY_TRX_DTL_STG_ARCH .....
PROMPT **Edition View creates as XX_CE_EBAY_TRX_DTL_STG_ARCH# in XXFIN schema**
PROMPT **Synonym creates as XX_CE_EBAY_TRX_DTL_STG_ARCH in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_CE_EBAY_TRX_DTL_STG_ARCH');

SHOW ERRORS;
EXIT;