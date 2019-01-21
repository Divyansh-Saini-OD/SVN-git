SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Updating AR Cash Receipts to clear errors

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Updating AR_CASH_RECEIPTS table to clear error flag |
-- | RICE ID     : I0349   settlement                                  |
-- | Description : Updating AR_CASH_RECEIPTS table to clear error flag |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======  ==========   ==================    =======================|
-- |1.0      25-OCT-2007  Rama Krishna K        Updating               |
-- |                                            AR_CASH_RECEIPTS table |
-- |                                            to clear error flag    |
-- +===================================================================+


UPDATE APPS.ar_cash_receipts_all
SET        cc_error_flag = NULL
where   cc_error_flag is not null;

COMMIT;
/
SHOW ERR