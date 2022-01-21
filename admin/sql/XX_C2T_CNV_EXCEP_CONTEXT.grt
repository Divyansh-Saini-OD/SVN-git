-- +===========================================================================+
-- |                             Office Depot                                  |
-- |                                                                           |
-- +===========================================================================+
-- | Name         : XX_C2T_CNV_EXCEP_CONTEXT.sql                               |
-- | Rice Id      :                                                            | 
-- | Description  :                                                            |  
-- | Purpose      : Create Context for credit card conversion to tokens        |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date          Author               Remarks                      | 
-- |=======    ==========    =================    =============================+
-- |1.0        04-FEB-2015   Havish K             Initial Version              |
-- |                                                                           |
-- +===========================================================================+
SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT SETTING CONTEXT XX_C2T_CNV_EXCEP_CONTEXT.sql
PROMPT

CREATE OR REPLACE CONTEXT XX_C2T_CNV_EXCEP_CONTEXT USING XX_C2T_CNV_CC_EXCPTNS_PKG;
/

SHOW ERR