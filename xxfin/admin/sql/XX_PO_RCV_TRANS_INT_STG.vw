SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_PO_RCV_TRANS_INT_STG.vw                                            			|
-- | Description : Scripts to create Editioned Views and synonym for object XX_PO_RCV_TRANS_INT_STG|
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        09-OCT-2017     Madhu Bolli          Initial version (Trade Payables Project)    |
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_PO_RCV_TRANS_INT_STG .....
PROMPT **Edition View creates as XX_PO_RCV_TRANS_INT_STG# in XXFIN schema**
PROMPT **Synonym creates as XX_PO_RCV_TRANS_INT_STG in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN', 'XX_PO_RCV_TRANS_INT_STG'); 

SHOW ERRORS;
EXIT;