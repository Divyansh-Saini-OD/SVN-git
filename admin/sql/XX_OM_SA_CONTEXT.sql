-- +===========================================================================+
-- |                            Office Depot                                   |
-- |                                                                           |
-- +===========================================================================+
-- | Name         : XX_OM_SA_CONTEXT.sql                                       |
-- | Rice Id      : I1272                                                      |
-- | Description  :                                                            |
-- | Purpose      : SETTING CONTEXT                                            |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date          Author                Remarks                     |
-- |=======    ==========    =================    =============================+
-- | 1.0       10-MAY-2011   Bapuji Nanapaneni    Initial Version              |
-- |                                                                           |
-- +===========================================================================+
SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT SETTING CONTEXT XX_OM_SA_CONTEXT.sql
PROMPT

CREATE OR REPLACE CONTEXT XX_OM_SA_CONTEXT USING XX_OM_SALES_ACCT_PKG;
/

SHOW ERR
