-- +===========================================================================+
-- |                              Office Depot                                 |
-- |                                                                           |
-- +===========================================================================+
-- | Name         : XX_OM_DEP_CONTEXT.sql                                      |
-- | Rice Id      : I1272                                                      | 
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
PROMPT SETTING CONTEXT XX_OM_DEP_CONTEXT.sql
PROMPT

CREATE OR REPLACE CONTEXT XX_OM_DEP_CONTEXT USING XX_OM_HVOP_DEPOSIT_CONC_PKG;
/

SHOW ERR
