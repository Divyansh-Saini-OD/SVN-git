SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating SQL Script XX_IBY_PCARD_L1_FIX.sql

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Script to fix 'L' value for purchase cards          |
-- | RICE ID     : I0349   settlement                                  |
-- | Description : Fix for Production instance to fix 'L' value        |
-- |               for purchase cards                                  |
-- |                                                                   |
-- |Change RecORd:                                                     |
-- |===============                                                    |
-- |Version   Date          AuthOR              Remarks                |
-- |=======  ==========   ==================    =======================|
-- |1.0      06-JUL-2009  Rama Krishna K        Initial version        |
-- |                                            Defect #428            |
-- +===================================================================+

UPDATE iby_pcard_bin_range
SET    pcard_subtype = 'P'
WHERE  lowerlimit = '424604000' and upperlimit = '424604999'
OR     lowerlimit = '424604000' and upperlimit = '424604999'
OR     lowerlimit = '405501000' and upperlimit = '405501999'
OR     lowerlimit = '405502000' and upperlimit = '405502999'
OR     lowerlimit = '405503000' and upperlimit = '405503999'
OR     lowerlimit = '405504000' and upperlimit = '405504999'
OR     lowerlimit = '405607000' and upperlimit = '405607999'
OR     lowerlimit = '480452000' and upperlimit = '480452999'
OR     lowerlimit = '471500000' and upperlimit = '471500999'
OR     lowerlimit = '471503000' and upperlimit = '471503999'
OR     lowerlimit = '471515000' and upperlimit = '471515999'
OR     lowerlimit = '471529000' and upperlimit = '471529999'
OR     lowerlimit = '471563000' and upperlimit = '471563999'
OR     lowerlimit = '471595000' and upperlimit = '471595999'
OR     lowerlimit = '471596000' and upperlimit = '471596999';

UPDATE iby_pcard_bin_range
SET    pcard_subtype = 'B'
WHERE  lowerlimit = '430736000' and upperlimit = '430736999';

COMMIT;

/
SHOW ERR
