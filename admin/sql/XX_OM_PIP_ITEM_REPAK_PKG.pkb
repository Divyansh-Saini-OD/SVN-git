SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_PIP_ITEM_REPAK_PKG                                                   
  
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name         :XX_OM_PIP_ITEM_REPAK_PKG.pkb                        |
-- | Rice ID      :E1259_PIPCampaignDefinition                         |
-- | Description  :This package body is used to Insert,Update          |
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
   g_error_code         VARCHAR2(2000);
   g_error_description  VARCHAR2(2000);
   g_entity_reference   VARCHAR2(400);
   g_entity_ref_id      NUMBER;


-- +===================================================================+
-- | Name  : INSERT_ROW                                                |
-- | Description:  This procedure is used to insert the rows into      |
-- |               XX_OM_PIP_ITEM_REPAK table                          |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:                                                       |
-- |                    p_inventory_item_id                            |
-- |                    p_warehouse_id                                 |
-- |                    p_repak_flag                                   |
-- |                    p_creation_date                                |
-- |                    p_created_by                                   |
-- |                    p_last_update_date                             |
-- |                    p_last_updated_by                              |
-- |                    p_last_update_login                            |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_row_id                                       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
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
                      ) IS
BEGIN
   g_error_code         := NULL;
   g_error_description  := NULL;
   g_entity_reference   := NULL;
   g_entity_ref_id      := 0;

   INSERT INTO xx_om_pip_item_repak (
                                     inventory_item_id
                                    ,warehouse_id     
                                    ,repak_flag       
                                    ,creation_date    
                                    ,created_by       
                                    ,last_update_date 
                                    ,last_updated_by  
                                    ,last_update_login
                                    ) VALUES (
                                     p_inventory_item_id  
                                    ,p_warehouse_id       
                                    ,p_repak_flag         
                                    ,p_creation_date      
                                    ,p_created_by         
                                    ,p_last_update_date   
                                    ,p_last_updated_by    
                                    ,p_last_update_login  
                                   );
  

   IF SQL%ROWCOUNT = 0 THEN
       RAISE NO_DATA_FOUND;
   END IF;
  
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RAISE;
   WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
      g_error_description   := FND_MESSAGE.GET;
      g_entity_reference    := 'Unexpected Error while inserting into XX_OM_PIP_ITEM_REPAK table';
      g_entity_ref_id       := 0;
      g_error_code          := 'XX_OM_65100_UNEXPECTED_ERR';             

      -- Call the write_exception procedure to insert into
      -- Global exception table
      xx_om_pip_error_pkg.write_exception ( p_error_code        => g_error_code
                                           ,p_error_description => g_error_description
                                           ,p_entity_reference  => g_entity_reference
                                           ,p_entity_ref_id     => g_entity_ref_id
                                          );

END insert_row;


-- +===================================================================+
-- | Name  : LOCK_ROW                                                  |
-- | Description:  This procedure is used to lock the rows of          |
-- |               XX_OM_PIP_ITEM_REPAK table for update               |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:        x_rowid                                        |
-- |                    p_inventory_item_id                            |
-- |                    p_warehouse_id                                 |
-- |                    p_repak_flag                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE lock_row (
                      x_rowid                 IN OUT NOCOPY VARCHAR2
                     ,p_inventory_item_id     IN NUMBER  
                     ,p_warehouse_id          IN NUMBER  
                     ,p_repak_flag            IN VARCHAR2
                   ) IS

  CURSOR lcu_lock_row IS 
    SELECT XOPIR.inventory_item_id
          ,XOPIR.warehouse_id
          ,XOPIR.repak_flag 
    FROM   xx_om_pip_item_repak XOPIR
    WHERE  XOPIR.rowid = x_rowid
    FOR UPDATE OF XOPIR.inventory_item_id,XOPIR.warehouse_id NOWAIT;

  recinfo lcu_lock_row%ROWTYPE;


BEGIN
 OPEN lcu_lock_row;
  FETCH lcu_lock_row INTO recinfo;
    IF (lcu_lock_row%NOTFOUND) THEN
        CLOSE lcu_lock_row;
        FND_MESSAGE.Set_Name('FND','FORM_RECORD_DELETED');
        APP_EXCEPTION.raise_exception;
    END IF;
  CLOSE lcu_lock_row;
  
  IF (  
              (recinfo.inventory_item_id       = p_inventory_item_id )
          AND (recinfo.warehouse_id            = p_warehouse_id) 
          AND (recinfo.repak_flag              = p_repak_flag  ) 
     ) THEN
    NULL;
  ELSE
      FND_MESSAGE.Set_Name('FND', 'FORM_RECORD_CHANGED');
      APP_EXCEPTION.raise_exception;
  END IF;

RETURN;

END lock_row;


-- +===================================================================+
-- | Name  : UPDATE_ROW                                                |
-- | Description:  This procedure is used to update the rows of        |
-- |               XX_OM_PIP_ITEM_REPAK table                          |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:        x_rowid                                        |
-- |                    p_inventory_item_id                            |
-- |                    p_warehouse_id                                 |
-- |                    p_repak_flag                                   |
-- |                    p_last_update_date                             |
-- |                    p_last_updated_by                              |
-- |                    p_last_update_login                            |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


PROCEDURE update_row (
                       x_rowid                 IN OUT NOCOPY VARCHAR2
                      ,p_inventory_item_id     IN NUMBER  
                      ,p_warehouse_id          IN NUMBER  
                      ,p_repak_flag            IN VARCHAR2
                      ,p_last_update_date      IN DATE
                      ,p_last_updated_by       IN NUMBER
                      ,p_last_update_login     IN NUMBER   
                    ) IS

BEGIN

   g_error_code         := NULL;
   g_error_description  := NULL;
   g_entity_reference   := NULL;
   g_entity_ref_id      := 0;



   UPDATE xx_om_pip_item_repak XOPIR
   SET    XOPIR.inventory_item_id      = p_inventory_item_id  
         ,XOPIR.warehouse_id           = p_warehouse_id       
         ,XOPIR.repak_flag             = p_repak_flag         
         ,XOPIR.last_update_date       = p_last_update_date
         ,XOPIR.last_updated_by        = p_last_updated_by
         ,XOPIR.last_update_login      = p_last_update_login
   WHERE  XOPIR.rowid                  = x_rowid;

  IF (SQL%NOTFOUND) THEN
    RAISE NO_DATA_FOUND;
  END IF;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RAISE;
   WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
      g_error_description   := FND_MESSAGE.GET;
      g_entity_reference    := 'Unexpected Error while inserting into XX_OM_PIP_ITEM_REPAK table';
      g_entity_ref_id       := 0;
      g_error_code          := 'XX_OM_65100_UNEXPECTED_ERR';             

      -- Call the write_exception procedure to insert into
      -- Global exception table
      xx_om_pip_error_pkg.write_exception ( p_error_code        => g_error_code
                                           ,p_error_description => g_error_description
                                           ,p_entity_reference  => g_entity_reference
                                           ,p_entity_ref_id     => g_entity_ref_id
                                          );



END update_row;


END XX_OM_PIP_ITEM_REPAK_PKG;
/

SHOW ERRORS

EXIT;