-- +===========================================================================+
-- |                             Office Depot                                  |
-- |                                                                           |
-- +===========================================================================+
-- | Name         : XX_AR_SUBSCRIPTIONS_MT_CTX.sql                            |
-- | Rice Id      : E7044                                                      | 
-- | Description  :                                                            |  
-- | Purpose      : Create Context                                             |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date          Author               Remarks                      | 
-- |=======    ==========    =================    =============================+
-- |1.0        09-Mar-2018   Sreedhar Mohan          Initial Version           |
-- |                                                                           |
-- +===========================================================================+
SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT SETTING CONTEXT XX_AR_SUBSCRIPTIONS_MT_CTX.sql
PROMPT

CREATE OR REPLACE CONTEXT XX_AR_SUBSCRIPTIONS_MT_CTX USING XX_AR_SUBSCRIPTIONS_MT_PKG;
/
