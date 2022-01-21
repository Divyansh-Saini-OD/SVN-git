SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name        : XX_CE_MRKTPLC_INDEXES                                  |
-- | Description : I3091_CM MarketPlaces Settlement and Reconciliation-Redesign                |
-- |Change History:                                                        |
-- |---------------                                                        |
-- | RICE ID : I3091                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     18-Jun-2018  M K Pramod Kumar.         Original                       |
-- +=======================================================================+

PROMPT
PROMPT Creating Editioning View for XX_CE_MPL_SETTLEMENT_DTL .....
PROMPT **Edition View creates as XX_CE_MPL_SETTLEMENT_DTL # in XXFIN schema**
PROMPT **Synonym creates as XX_CE_MPL_SETTLEMENT_DTL in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_CE_MPL_SETTLEMENT_DTL');

EXIT;