
-- +==================================================================================+  
-- | Office Depot - Project Simplify                                                  |
-- |                                                              |
-- +==================================================================================+
-- | SQL Script to create the table:  XX_AR_INVOICE_COPY_LIST                         |
-- |                                                                                  |
-- |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       26-APR-2019   M K Pramod Kumar     Initial DRAFT version for NAIT-119893 |
-- |                                                                                  |
-- +==================================================================================+

PROMPT
PROMPT Creating  View for XX_AR_INVOICE_COPY_LIST.....
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_AR_INVOICE_COPY_LIST');

EXIT;