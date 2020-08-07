-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XXOMFRAUDRULES.grt                                                          |
-- | Rice Id      : C1349                                                                       | 
-- | Description  : CON-C1349_AOPSFraudDataToOracle Grants Creation                             |  
-- | Purpose      : Create Grant on table XX_OM_FRAUD_RULES.                                    |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      | 
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   01-AUG-2007   Bapuji Nanapaneni    Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF


PROMPT
PROMPT Providing Grant on Custom Tables,object and Sequence to Apps......
PROMPT

PROMPT
PROMPT Providing Grant on object xx_om_fraud_rules.tbl to Apps .....
PROMPT

GRANT ALL ON  xx_om_fraud_rules TO APPS
/

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;