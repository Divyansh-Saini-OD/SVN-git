-- +===========================================================================+
-- |                             Office Depot                                  |
-- |                                                                           |
-- +===========================================================================+
-- | Name         : XX_AP_CCIN_CONTEXT.sql                                     |
-- | Rice Id      : I2168                                                      | 
-- | Description  : Context for AP credit cards to faciliates encryption       |  
-- | Purpose      : Create Context                                             |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date          Author               Remarks                      | 
-- |=======    ==========    =================    =============================+
-- |1.0        03-NOV-2013   R. Aldridge          Initial Version              |
-- |                                                                           |
-- +===========================================================================+
SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT SETTING CONTEXT XX_AP_CCIN_CONTEXT.sql
PROMPT

CREATE OR REPLACE CONTEXT XX_AP_CCIN_CONTEXT USING XX_AP_ENCRYPT_CREDIT_CARD_PKG;
/

SHOW ERR
