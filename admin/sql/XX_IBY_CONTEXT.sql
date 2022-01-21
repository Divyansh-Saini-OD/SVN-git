-- +===========================================================================+
-- |                              Office Depot                                 |
-- |                                                                           |
-- +===========================================================================+
-- | Name         : XX_IBY_CONTEXT.sql                                         |
-- | Rice Id      : I0349                                                      | 
-- | Description  :                                                            |  
-- | Purpose      : Create Context                                             |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date          Author               Remarks                      | 
-- |=======    ==========    =================    =============================+
-- |1.0        09-SEP-2013   R. Aldridge          Initial Version              |
-- |                                                                           |
-- +===========================================================================+
SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT SETTING CONTEXT XX_IBY_CONTEXT.sql
PROMPT

CREATE OR REPLACE CONTEXT XX_IBY_CONTEXT USING XX_IBY_SETTLEMENT_PKG;
/

SHOW ERR
