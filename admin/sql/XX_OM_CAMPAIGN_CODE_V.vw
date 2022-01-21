-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                                                                   |
-- +===================================================================+
-- | Name         :XX_OM_CAMPAIGN_CODE_V.vw                            |
-- | Rice ID      :E1267_PIPInterface to SAS                           |
-- | Description  :OD PIP Campaign Code View Creation                  |
-- |               Script for PIP Rules                                |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 04-SEP-2007  Visa Sivasubramanian   Initial draft version |
-- |                                                                   |
-- +===================================================================+
SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Dropping Existing Custom Views......
PROMPT

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Dropping View XX_OM_CAMPAIGN_CODE_V
PROMPT

DROP VIEW XX_OM_CAMPAIGN_CODE_V;

WHENEVER SQLERROR EXIT 1;

PROMPT
PROMPT Creating the Custom Views ......
PROMPT

PROMPT
PROMPT Creating the View XX_OM_CAMPAIGN_CODE_V.....
PROMPT

CREATE OR REPLACE FORCE VIEW XX_OM_CAMPAIGN_CODE_V (
                                                     campaign_code
                                                    ,exp_date 
                                                           )        
                                                      AS
                                               SELECT 
     									'ALL' campaign_code
                                                      ,NULL exp_date
                                               FROM sys.dual
                                               UNION
                                               SELECT 
                                                      to_char(xopcra.campaign_id) campaign_code
                                                      ,xopcra.to_date exp_date
                                               FROM xx_om_pip_campaign_rules_all xopcra,
                                                    xx_om_pip_lists xopl
                                               WHERE xopcra.campaign_id IS NOT NULL
                                                AND xopcra.campaign_id = xopl.campaign_id
                                                AND  NVL (XOPCRA.org_id, NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1), ' ', NULL, SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10))), -99)) = NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1), ' ', NULL, SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10))), -99);
                                                             

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;