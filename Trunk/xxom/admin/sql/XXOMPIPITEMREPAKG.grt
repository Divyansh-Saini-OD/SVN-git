-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XXOMPIPITEMREPAKG.grt                               |
-- | Rice ID      :E1259_PIPCampaignDefinition                         |
-- | Description  :OD PIP Campaign Definition Grant Creation           |
-- |               Script for PIP Item Repak                           |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 17-MAY-2007  Hema Chikkanna   Initial draft version       |
-- |1.0      18-MAY-2007  Hema Chikkanna   Baselined after testing     |
-- |1.1      14-JUN-2007  Hema Chikkanna   Incorporated the file name  |
-- |                                       change as per onsite        |
-- |                                       requirement                 |
-- +===================================================================+
SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF


PROMPT
PROMPT Providing Grant on Custom Table to Apps......
PROMPT

WHENEVER SQLERROR EXIT 1


PROMPT
PROMPT Providing Grant on the Table XX_OM_PIP_ITEM_REPAK to Apps .....
PROMPT


GRANT ALL ON  XX_OM_PIP_ITEM_REPAK TO APPS;


WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
