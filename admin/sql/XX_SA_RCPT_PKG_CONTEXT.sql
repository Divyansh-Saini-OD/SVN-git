-- +===========================================================================+
-- |                             Office Depot                                  |
-- |                                                                           |
-- +===========================================================================+
-- | Name         : XX_SA_RCPT_PKG_CONTEXT.sql                                 |
-- | Rice Id      : I0349                                                      | 
-- | Description  :                                                            |  
-- | Purpose      : Create Context                                             |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date          Author               Remarks                      | 
-- |=======    ==========    =================    =============================+
-- |1.0        23-OCT-2013   R. Aldridge          Initial Version              |
-- |                                                                           |
-- +===========================================================================+
SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT SETTING CONTEXT XX_SA_RCPT_PKG_CONTEXT.sql
PROMPT

CREATE OR REPLACE CONTEXT XX_SA_RCPT_PKG USING XX_AR_SA_RCPT_PKG;
/

SHOW ERR
