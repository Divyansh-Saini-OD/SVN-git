-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XXOMPIPCAMPAIGNRULESALLG.grt                        |
-- | Rice ID      :E1259_PIPCampaignDefinition                         |
-- | Description  :OD PIP Campaign Defintion Grant Creation            |
-- |               Script for PIP Rules                                |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 15-MAR-2007  Hema Chikkanna   Initial draft version       |
-- |1.0      17-MAR-2007  Hema Chikkanna   Baselined after testing     |
-- |1.1      27-APR-2007  Hema Chikkanna   Updated the Comments Section|
-- |                                       as per onsite requirement   |
-- |1.2      04-MAY-2007  Hema Chikkanna   Created Indvidual scripts as|
-- |                                       per onsite requirement      |
-- |1.3      14-JUN-2007  Hema Chikkanna   Incorporated the file name  |
-- |                                       change as per onsite        |
-- |                                       requirement                 |
-- |                                                                   |
-- +===================================================================+
SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF


PROMPT
PROMPT Providing Grant on Custom Table and Sequence to Apps......
PROMPT

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Providing Grant on the Table XX_OM_PIP_CAMPAIGN_RULES_ALL to Apps .....
PROMPT


GRANT ALL ON  XX_OM_PIP_CAMPAIGN_RULES_ALL TO APPS;


PROMPT
PROMPT Providing Grant on the Sequence XX_OM_PIP_CAMPAIGN_RULES_S to Apps .....
PROMPT


GRANT ALL ON  XX_OM_PIP_CAMPAIGN_RULES_S TO APPS;


WHENEVER SQLERROR CONTINUE;


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

