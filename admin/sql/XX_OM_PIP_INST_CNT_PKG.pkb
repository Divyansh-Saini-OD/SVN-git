SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_PIP_INST_CNT_PKG                                                   
  
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_OM_PIP_INST_CNT_PKG.pkb                          |
-- | Rice ID      :E1259_PIPCampaignDefinition                         |
-- | Description  :This package body is used to Insert,Update          |
-- |               and Lock rows of XX_OM_PIP_INSERT_COUNT Table       | 
-- |                                                                   |
-- |                                                                   |
-- |                                                                   | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |Draft1A  28-MAR-2007  Hema Chikkanna   Initial draft version       |
-- |1.0      18-APR-2007  Hema Chikkanna   Baselined after testing     |
-- |1.1      27-APR-2007  Hema Chikkanna   Updated the Comments Section|
-- |                                       as per onsite requirement   |
-- |1.2      14-JUN-2007  Hema Chikkanna   Incorporated the file name  |
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
-- |               XX_OM_PIP_INSERT_COUNT table                        |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:                                                       |
-- |                    p_ship_from_org_id                             |
-- |                    p_max_csc_count                                |
-- |                    p_csc_count                                    |
-- |                    p_count_last_update_time                       |
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
                         x_rowid                    IN OUT NOCOPY VARCHAR2
                        ,p_ship_from_org_id         IN NUMBER
                        ,p_max_csc_count            IN NUMBER
                        ,p_csc_count                IN NUMBER
                        ,p_count_last_update_time   IN DATE
                        ,p_creation_date            IN DATE
                        ,p_created_by               IN NUMBER
                        ,p_last_update_date         IN DATE
                        ,p_last_updated_by          IN NUMBER
                        ,p_last_update_login        IN NUMBER
                    ) IS


            
            
BEGIN
   g_error_code         := NULL;
   g_error_description  := NULL;
   g_entity_reference   := NULL;
   g_entity_ref_id      := 0;

  INSERT INTO xx_om_pip_insert_count (
                                      ship_from_org_id        
                                     ,max_csc_count           
                                     ,csc_count               
                                     ,count_last_update_time  
                                     ,creation_date         
                                     ,created_by            
                                     ,last_update_date      
                                     ,last_updated_by       
                                     ,last_update_login     
                                     ) VALUES (
                                      p_ship_from_org_id        
                                     ,p_max_csc_count           
                                     ,p_csc_count               
                                     ,p_count_last_update_time  
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
      g_entity_reference    := 'Unexpected Error while inserting into XX_OM_PIP_INSERT_COUNT table';
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
-- |               XX_OM_PIP_INSERT_COUNT table for update             |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:        x_rowid                                        |
-- |                    p_ship_from_org_id                             |
-- |                    p_max_csc_count                                |  
-- |                    p_csc_count                                    |
-- |                    p_count_last_update_time                       |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE lock_row (
            x_rowid                    IN VARCHAR2
           ,p_ship_from_org_id         IN NUMBER
           ,p_max_csc_count            IN NUMBER 
           ,p_csc_count                IN NUMBER
           ,p_count_last_update_time   IN DATE
          ) IS

  CURSOR lcu_lock_row IS 
    SELECT XOPIC.ship_from_org_id
          ,XOPIC.max_csc_count
          ,XOPIC.csc_count
          ,XOPIC.count_last_update_time
    FROM   xx_om_pip_insert_count XOPIC
    WHERE  XOPIC.rowid = x_rowid
    FOR UPDATE OF XOPIC.ship_from_org_id NOWAIT;

  recinfo lcu_lock_row%ROWTYPE;


BEGIN
 OPEN lcu_lock_row;
  FETCH lcu_lock_row INTO recinfo;
    IF (lcu_lock_row%NOTFOUND) THEN
        CLOSE lcu_lock_row;
        FND_MESSAGE.Set_Name('FND', 'FORM_RECORD_DELETED');
        APP_EXCEPTION.raise_exception;
    END IF;
  CLOSE lcu_lock_row;
  
  IF (  
           (recinfo.ship_from_org_id   = p_ship_from_org_id)
              AND ((recinfo.max_csc_count = p_max_csc_count OR (recinfo.max_csc_count IS NULL and p_max_csc_count IS NULL))) 
               AND ((recinfo.csc_count = p_csc_count OR (recinfo.csc_count IS NULL and p_csc_count IS NULL))) 
                AND ((recinfo.count_last_update_time = p_count_last_update_time OR (recinfo.count_last_update_time IS NULL and p_count_last_update_time IS NULL))) 
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
-- |               XX_OM_PIP_INSERT_COUNT table                        |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:        x_rowid                                        |
-- |                    p_ship_from_org_id                             |
-- |                    p_max_csc_count                                |
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
                        x_rowid                    IN VARCHAR2
                       ,p_ship_from_org_id         IN NUMBER
                       ,p_max_csc_count            IN NUMBER
                       ,p_csc_count                IN NUMBER
                       ,p_count_last_update_time   IN DATE
                       ,p_last_update_date         IN DATE
                       ,p_last_updated_by          IN NUMBER
                       ,p_last_update_login        IN NUMBER
                     ) IS

BEGIN
   g_error_code         := NULL;
   g_error_description  := NULL;
   g_entity_reference   := NULL;
   g_entity_ref_id      := 0;

   
   UPDATE xx_om_pip_insert_count XOPIC
   SET    XOPIC.ship_from_org_id       = p_ship_from_org_id
         ,XOPIC.max_csc_count          = p_max_csc_count    
         ,XOPIC.csc_count              = p_csc_count
         ,XOPIC.count_last_update_time = p_count_last_update_time
         ,XOPIC.last_update_date       = p_last_update_date
         ,XOPIC.last_updated_by        = p_last_updated_by
         ,XOPIC.last_update_login      = p_last_update_login
   WHERE  XOPIC.rowid                  = x_rowid;

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
      g_entity_reference    := 'Unexpected Error while Updating the XX_OM_PIP_INSERT_COUNT table';
      g_entity_ref_id       := 0;
      g_error_code          := 'XX_OM_65100_UNEXPECTED_ERR';             

      -- Call the write_exception procedure to insert into
      -- Global exception table
      xx_om_pip_error_pkg.write_exception ( 
                                             p_error_code        => g_error_code
                                            ,p_error_description => g_error_description
                                            ,p_entity_reference  => g_entity_reference
                                            ,p_entity_ref_id     => g_entity_ref_id
                                          );


END update_row;


END XX_OM_PIP_INST_CNT_PKG;
/

SHOW ERRORS

EXIT;