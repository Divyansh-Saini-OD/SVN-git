-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : UPDATE OE_PAYMENTS.sql                                                      |
-- | Rice Id      : I1272                                                                       | 
-- | Description  : INT-I1272_SalesOrderFrom LegacySystems(HVOP) Table UPDATE                   |  
-- | Purpose      : UPDATE Standard Table OE_PAYMENTS                                           |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      | 
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   28-APR-2008   Bapuji Nanapaneni        Initial Version                           |
-- |                                                                                            |
-- +============================================================================================+


SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF



PROMPT
PROMPT UPDATE the Table OE_PAYMENTS.....
PROMPT

UPDATE ont.oe_payments
      SET receipt_method_id = 11247
WHERE receipt_method_id = 2026;

/
COMMIT;
/

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
