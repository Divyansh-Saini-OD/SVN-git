-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : UPDATE OE_PRICE_ADJUSTMENTS ATTRIBUTE9                                      |
-- | Rice Id      : I1272                                                                       | 
-- | Description  : INT-I1272_SalesOrderFrom LegacySystems(HVOP) Table MODIFICATION             |  
-- | Purpose      : MODIFY  Table OE_PRICE_ADJUSTMENTS                                          |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      | 
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   31-JAN-2008   BApuji Nanapaneni        Initial Version                           |
-- |                                                                                            |
-- +============================================================================================+


SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF



PROMPT
PROMPT MODIFYING the Table OE_PRICE_ADJUSTMENTS.....
PROMPT


UPDATE ont.oe_price_adjustments 
SET attribute9 = NULL
WHERE attribute8 != '10';

/

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
