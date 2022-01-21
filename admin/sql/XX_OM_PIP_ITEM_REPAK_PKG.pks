SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_PIP_ITEM_REPAK_PKG                                                
  
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name         :XX_OM_PIP_ITEM_REPAK_PKG.pks                        |
-- | Rice ID      :E1259_PIPCampaignDefinition                         |
-- | Description  :This package specification is used to Insert,Update |
-- |               and Lock rows of XX_OM_PIP_ITEM_REPAK Table         | 
-- |                                                                   |
-- |                                                                   |
-- |                                                                   | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |Draft1A  17-MAY-2007  Hema Chikkanna   Initial draft version       |
-- |1.0      18-MAY-2007  Hema Chikkanna   Baselined after testing     |
-- |1.1      14-JUN-2007  Hema Chikkanna   Incorporated the file name  |
-- |                                       change as per onsite        |
-- |                                       requirement                 |
-- +===================================================================+
AS
-------------------------------------
-- Procedure to insert the row into
-- XX_OM_PIP_ITEM_REPAK table
-------------------------------------
PROCEDURE insert_row (
                       x_rowid                 IN OUT NOCOPY VARCHAR2
                      ,p_inventory_item_id     IN NUMBER  
                      ,p_warehouse_id          IN NUMBER  
                      ,p_repak_flag            IN VARCHAR2
                      ,p_creation_date         IN DATE
                      ,p_created_by            IN NUMBER
                      ,p_last_update_date      IN DATE
                      ,p_last_updated_by       IN NUMBER
                      ,p_last_update_login     IN NUMBER
                      );

-------------------------------------
-- Procedure to lock the row of
-- XX_OM_PIP_ITEM_REPAK table
-------------------------------------

PROCEDURE lock_row (
                      x_rowid                 IN OUT NOCOPY VARCHAR2
                     ,p_inventory_item_id     IN NUMBER  
                     ,p_warehouse_id          IN NUMBER  
                     ,p_repak_flag            IN VARCHAR2
                   );


-------------------------------------
-- Procedure to update the rows of
-- XX_OM_PIP_ITEM_REPAK table
-------------------------------------
PROCEDURE update_row (
                       x_rowid                 IN OUT NOCOPY VARCHAR2
                      ,p_inventory_item_id     IN NUMBER  
                      ,p_warehouse_id          IN NUMBER  
                      ,p_repak_flag            IN VARCHAR2
                      ,p_last_update_date      IN DATE
                      ,p_last_updated_by       IN NUMBER
                      ,p_last_update_login     IN NUMBER   
                    );


END XX_OM_PIP_ITEM_REPAK_PKG;
/

SHOW ERRORS

EXIT;