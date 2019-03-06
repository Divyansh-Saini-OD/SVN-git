-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_OM_PIP_ITEM_REPAK_V.vw                           |
-- | Rice ID      :E1259_PIPCampaignDefinition                         |
-- | Description  :OD PIP Campaign Definition View Creation            |
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
PROMPT Dropping View XX_OM_PIP_ITEM_REPAK_V
PROMPT

DROP VIEW XX_OM_PIP_ITEM_REPAK_V ;


WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Creating the Custom Views ......
PROMPT

PROMPT
PROMPT Creating the View XX_OM_PIP_ITEM_REPAK_V .....
PROMPT

CREATE OR REPLACE FORCE VIEW XX_OM_PIP_ITEM_REPAK_V
                                                    (   row_id
                                                       ,inventory_item_id
                                                       ,inventory_item
                                                       ,warehouse_id
                                                       ,warehouse
                                                       ,repak_flag
                                                       ,created_by 
                                                       ,creation_date
                                                       ,last_update_date
                                                       ,last_updated_by
                                                       ,last_update_login
                                                    ) AS 
                                                   SELECT  XOPIR.rowid
                                                          ,XOPIR.inventory_item_id
                                                          ,MSIB.segment1
                                                          ,XOPIR.warehouse_id 
                                                          ,HOUV.name
                                                          ,XOPIR.repak_flag
                                                          ,XOPIR.created_by 
                                                          ,XOPIR.creation_date 
                                                          ,XOPIR.last_update_date 
                                                          ,XOPIR.last_updated_by 
                                                          ,XOPIR.last_update_login 
                                                    FROM   xx_om_pip_item_repak       XOPIR
                                                          ,mtl_system_items_b         MSIB
                                                          ,hr_organization_units_v    HOUV
                                                    WHERE  XOPIR.inventory_item_id   = msib.inventory_item_id
                                                    AND    XOPIR.warehouse_id        = HOUV.organization_id
                                                    AND    MSIB.organization_id      = OE_SYS_PARAMETERS.VALUE 
                                                                                         ('MASTER_ORGANIZATION_ID',FND_PROFILE.VALUE ('ORG_ID'))
                                                    ORDER BY XOPIR.inventory_item_id;


WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;