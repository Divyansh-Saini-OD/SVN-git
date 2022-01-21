-- +===========================================================================+
-- |                             Office Depot                                  |
-- |                                                                           |
-- +===========================================================================+
-- | Name         : XX_AP_CCOUT_CONTEXT.sql                                    |
-- | Rice Id      : I0438_EFT PMT                                              | 
-- | Description  : Context for AP credit cards to faciliates encryption       |  
-- | Purpose      : Create Context                                             |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date          Author               Remarks                      | 
-- |=======    ==========    =================    =============================+
-- |1.0        18-NOV-2013   R. Aldridge          Initial Version              |
-- |                                                                           |
-- +===========================================================================+
SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT SETTING CONTEXT XX_AP_CCOUT_CONTEXT.sql
PROMPT

CREATE OR REPLACE CONTEXT XX_AP_CCOUT_CONTEXT USING XX_AP_NACHABOA_EFT_PKG;
/

SHOW ERR
