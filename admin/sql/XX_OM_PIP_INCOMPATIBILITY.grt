SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                                                                   |
-- +===================================================================+
-- | Name             : XX_OM_PIP_INCOMPATIBILITY.grt                  |
-- | Rice ID          : E1259_PIPCampaignDefinition                    |
-- | Description      : This script provides grant to the table        |
-- |                    XX_OM_PIP_INCOMPATIBILITY in APPS schema       |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version  Date         Author           Remarks                     |
-- |=======  ===========  =============    ============================|
-- |1.0      17-SEP-2007  Matthew Craig    Initial Version             |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROMPT
PROMPT Providing grant on table XX_OM_PIP_INCOMPATIBILITY
PROMPT

GRANT ALL ON  XXOM.XX_OM_PIP_INCOMPATIBILITY TO APPS;                                                                           
SHOW ERROR