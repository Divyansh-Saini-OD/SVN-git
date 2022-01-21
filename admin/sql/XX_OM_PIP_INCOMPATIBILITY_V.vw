-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_OM_PIP_INCOMPATIBILITY_V.vw                      |
-- | Rice ID      :E1259_PIPCampaignDefinition                         |
-- | Description  :OD PIP Campaign Definition View Creation            |
-- |               Script for PIP Incompatibility                      |
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
PROMPT Dropping View XX_OM_PIP_INCOMPATIBILITY_V
PROMPT

DROP VIEW XX_OM_PIP_INCOMPATIBILITY_V ;

WHENEVER SQLERROR EXIT 1;


PROMPT
PROMPT Creating the Custom Views ......
PROMPT

PROMPT
PROMPT Creating the View XX_OM_PIP_INCOMPATIBILITY_V .....
PROMPT

CREATE OR REPLACE FORCE VIEW XX_OM_PIP_INCOMPATIBILITY_V
                                                        (   row_id
                                                           ,insert_item_id
                                                           ,insert_item
                                                           ,incompatible_item_id
                                                           ,incompatible_item
                                                           ,active_flag
                                                           ,created_by 
                                                           ,creation_date
                                                           ,last_update_date
                                                           ,last_updated_by
                                                           ,last_update_login)
                                                     AS 
                                                       SELECT 
                                                           XOPI.rowid
                                                          ,XOPI.insert_item_id
                                                          ,MSIB.segment1
                                                          ,XOPI.incompatible_item_id 
                                                          ,MSIC.segment1
                                                          ,XOPI.active_flag
                                                          ,XOPI.created_by 
                                                          ,XOPI.creation_date 
                                                          ,XOPI.last_update_date 
                                                          ,XOPI.last_updated_by 
                                                          ,XOPI.last_update_login 
                                                    FROM   xx_om_pip_incompatibility  XOPI
                                                          ,mtl_system_items_b         MSIB
                                                          ,mtl_system_items_b         MSIC
                                                    WHERE  xopi.insert_item_id       = msib.inventory_item_id
                                                    AND    xopi.incompatible_item_id = msic.inventory_item_id
                                                    AND    msic.organization_id      = msib.organization_id      
                                                    AND    msib.organization_id      = OE_SYS_PARAMETERS.VALUE 
                                                                                         ('MASTER_ORGANIZATION_ID',FND_PROFILE.VALUE ('ORG_ID'));
                    


WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;