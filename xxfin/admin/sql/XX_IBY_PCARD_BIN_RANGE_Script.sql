SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating backup bin ranges iPayment base table script

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : SR #18786178.6 ADDING NEW CREDIT CARD NUMBERS       |
-- | RICE ID     : I0349   auth and settlement                         |
-- | Description : Creating backup of IBY_PCARD_BIN_RANGE base table   |
-- |               before applying the patch 7276501                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======  ===========   ==================   =======================|
-- |1.0      24-JUL-2008   Rama Krishna K       Initial version        |
-- +===================================================================+

PROMPT Dropping table IBY_PCARD_BIN_RANGE_BKP table

DROP TABLE iby_pcard_bin_range_bkp;

PROMPT Creating backup of IBY_PCARD_BIN_RANGE iPayment base table with IBY_PCARD_BIN_RANGE_BKP name

CREATE TABLE iby_pcard_bin_range_BKP AS SELECT * FROM iby_pcard_bin_range;

PROMPT Deleting data from IBY_PCARD_BIN_RANGE 

DELETE FROM iby_pcard_bin_range;

COMMIT;

/
SHOW ERR
