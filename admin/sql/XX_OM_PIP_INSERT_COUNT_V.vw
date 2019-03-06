-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_OM_PIP_INSERT_COUNT_V.vw                         |
-- | Rice ID      :E1259_PIPCampaignDefinition                         |
-- | Description  :OD PIP Campaign Definition view Creation            |
-- |               Script for CSC Count                                |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 28-MAR-2007  Hema Chikkanna   Initial draft version       |
-- |1.0      18-APR-2007  Hema Chikkanna   Baselined after testing     |
-- |1.1      27-APR-2007  Hema Chikkanna   Updated the Comments Section|
-- |                                       as per onsite requirement   |
-- |1.2      04-MAY-2007  Hema Chikkanna   Created Indvidual scripts as|
-- |                                       per onsite requirement      |
-- |1.3      14-JUN-2007  Hema Chikkanna   Incorporated the file name  |
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
PROMPT Dropping Existing Custom Views......
PROMPT

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Dropping View XX_OM_PIP_INSERT_COUNT_V
PROMPT

DROP VIEW XX_OM_PIP_INSERT_COUNT_V;

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Creating the Custom Views ......
PROMPT

PROMPT
PROMPT Creating the View XX_OM_PIP_INSERT_COUNT_V .....
PROMPT

CREATE OR REPLACE FORCE VIEW XX_OM_PIP_INSERT_COUNT_V
                                                      ( row_id
                                                       ,ship_from_org_id
                                                       ,max_csc_count
                                                       ,csc_location
                                                       ,csc_count
                                                       ,count_last_update_time
                                                       ,created_by 
                                                       ,creation_date
                                                       ,last_update_date
                                                       ,last_updated_by
                                                       ,last_update_login)
                                                     AS 
                                                       SELECT 
                                                           XOPIC.rowid
                                                          ,XOPIC.ship_from_org_id 
                                                          ,XOPIC.max_csc_count
                                                          ,HOUV.name
                                                          ,XOPIC.csc_count 
                                                          ,XOPIC.count_last_update_time 
                                                          ,XOPIC.created_by 
                                                          ,XOPIC.creation_date 
                                                          ,XOPIC.last_update_date 
                                                          ,XOPIC.last_updated_by 
                                                          ,XOPIC.last_update_login 
                                                    FROM   xx_om_pip_insert_count    XOPIC
                                                          ,hr_organization_units_v   HOUV
                                                    WHERE XOPIC.ship_from_org_id    = HOUV.organization_id      
                                                    ORDER BY XOPIC.ship_from_org_id;
                    

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;