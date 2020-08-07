SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_PO_MLSS_HDR_PKG                                                
  
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_PO_MLSS_HDR_PKG                                  |
-- | Rice ID      :E1252_MultiLocationSupplierSourcing                 |
-- | Description  :This package body is used to Insert, Update         |
-- |               Delete, Lock rows of XX_PO_MLSS_HDR Table           | 
-- |                                                                   |
-- |                                                                   |
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
-- |1.2      18-JUN-2007  Hema Chikkanna   Incorporated the file name  |
-- |                                       change as per onsite        |
-- |                                       requirement                 |
-- |                                                                   |
-- +===================================================================+
AS

g_error_code         VARCHAR2(2000);
g_error_description  VARCHAR2(2000);
g_entity_reference   VARCHAR2(400);
g_entity_ref_id      NUMBER;
    

-- +===================================================================+
-- | Name  : INSERT_ROW                                                |
-- | Description:  This procedure is used to insert the rows into      |
-- |               XX_PO_MLSS_HDR table                                |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:                                                       |
-- |                    p_mlss_header_id                               |
-- |                    p_organization_id                              |
-- |                    p_category                                     |
-- |                    p_category_level                               |
-- |                    p_start_date                                   |
-- |                    p_end_date                                     |
-- |                    p_imu_amt_pt                                   |
-- |                    p_imu_value                                    |
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
                         x_rowid             IN OUT NOCOPY VARCHAR2
                        ,p_mlss_header_id    IN NUMBER
                        ,p_organization_id   IN NUMBER
                        ,p_category          IN VARCHAR2
                        ,p_category_level    IN VARCHAR2
                        ,p_start_date        IN DATE
                        ,p_end_date          IN DATE
                        ,p_imu_amt_pt        IN VARCHAR2
                        ,p_imu_value         IN NUMBER
                        ,p_creation_date     IN DATE
                        ,p_created_by        IN NUMBER
                        ,p_last_update_date  IN DATE
                        ,p_last_updated_by   IN NUMBER
                        ,p_last_update_login IN NUMBER
                     ) IS
                     
                     
        
BEGIN
    g_error_code         := NULL;
    g_error_description  := NULL;
    g_entity_reference   := NULL;
    g_entity_ref_id      := 0;


    INSERT INTO xx_po_mlss_hdr (
                                  mlss_header_id
                                 ,using_organization_id
                                 ,category        
                                 ,category_level
                                 ,start_date   
                                 ,end_date
                                 ,imu_amt_pt
                                 ,imu_value
                                 ,creation_date
                                 ,created_by
                                 ,last_update_date
                                 ,last_updated_by
                                 ,last_update_login
                               ) VALUES (
                                  p_mlss_header_id
                                 ,p_organization_id
                                 ,p_category
                                 ,p_category_level
                                 ,p_start_date
                                 ,p_end_date
                                 ,p_imu_amt_pt
                                 ,p_imu_value
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
      g_entity_reference    := 'Unexpected Error while inserting into XX_PO_MLSS_HDR table';
      g_entity_ref_id       := 0;
      g_error_code          := 'XX_OM_65100_UNEXPECTED_ERR';             

      -- Call the write_exception procedure to insert into
      -- Global exception table
      xx_po_mlss_pkg.write_exception ( p_error_code        => g_error_code
                                      ,p_error_description => g_error_description
                                      ,p_entity_reference  => g_entity_reference
                                      ,p_entity_ref_id     => g_entity_ref_id);

END insert_row;


-- +===================================================================+
-- | Name  : LOCK_ROW                                                  |
-- | Description:  This procedure is used to lock the rows of          |
-- |               XX_PO_MLSS_HDR table for update                     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:        p_mlss_header_id                               |
-- |                    p_end_date                                     |
-- |                    p_imu_amt_pt                                   |
-- |                    p_imu_value                                    |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE lock_row (
                      p_mlss_header_id    IN NUMBER
                     ,p_end_date          IN DATE
                     ,p_imu_amt_pt        IN VARCHAR2
                     ,p_imu_value         IN NUMBER
                   ) IS

CURSOR lcu_lock_row IS 
    SELECT XPMH.end_date
          ,XPMH.imu_amt_pt
          ,XPMH.imu_value
    FROM  xx_po_mlss_hdr XPMH
    WHERE XPMH.mlss_header_id = p_mlss_header_id
    FOR UPDATE OF XPMH.category NOWAIT;

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
           ((recinfo.end_date   = p_end_date   OR (recinfo.end_date   IS NULL and p_end_date   IS NULL)))
       AND ((recinfo.imu_amt_pt = p_imu_amt_pt OR (recinfo.imu_amt_pt IS NULL and p_imu_amt_pt IS NULL))) 
       AND ((recinfo.imu_value  = p_imu_value  OR (recinfo.imu_value  IS NULL and p_imu_value  IS NULL))) 
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
-- |               XX_PO_MLSS_HDR table                                |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:        p_mlss_header_id                               |
-- |                    p_end_date                                     |
-- |                    p_imu_amt_pt                                   |
-- |                    p_imu_value                                    |
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
                       p_mlss_header_id    IN NUMBER
                      ,p_end_date          IN DATE
                      ,p_imu_amt_pt        IN VARCHAR2 
                      ,p_imu_value         IN NUMBER
                      ,p_last_update_date  IN DATE
                      ,p_last_updated_by   IN NUMBER
                      ,p_last_update_login IN NUMBER
                    ) IS

BEGIN
   g_error_code         := NULL;
   g_error_description  := NULL;
   g_entity_reference   := NULL;
   g_entity_ref_id      := 0;

   UPDATE xx_po_mlss_hdr XPMH
   SET    XPMH.end_date          = p_end_date
         ,XPMH.Imu_amt_pt         = p_imu_amt_pt 
         ,XPMH.Imu_value          = p_imu_value
         ,XPMH.last_update_date   = p_last_update_date
         ,XPMH.last_updated_by    = p_last_updated_by
         ,XPMH.last_update_login  = p_last_update_login
   WHERE  XPMH.mlss_header_id    = p_mlss_header_id;

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
      g_entity_reference    := 'Unexpected Error while Updating the XX_PO_MLSS_HDR table';
      g_entity_ref_id       := 0;
      g_error_code          := 'XX_OM_65100_UNEXPECTED_ERR';             

      -- Call the write_exception procedure to insert into
      -- Global exception table
      xx_po_mlss_pkg.write_exception ( p_error_code       => g_error_code
                                     ,p_error_description => g_error_description
                                     ,p_entity_reference  => g_entity_reference
                                     ,p_entity_ref_id     => g_entity_ref_id);


END update_row;


-- +===================================================================+
-- | Name  : DELETE_ROW                                                |
-- | Description:  This procedure is used to delete the rows from      |
-- |               XX_PO_MLSS_HDR table                                |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:        p_mlss_header_id                               |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE delete_row (
                       p_mlss_header_id IN NUMBER 
                     ) IS
BEGIN
   g_error_code         := NULL;
   g_error_description  := NULL;
   g_entity_reference   := NULL;
   g_entity_ref_id      := 0;
      
   DELETE FROM xx_po_mlss_hdr XPMH
   WHERE xpmh.mlss_header_id  = p_mlss_header_id;

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
      g_entity_reference    := 'Unexpected Error while Deleting from XX_PO_MLSS_HDR table';
      g_entity_ref_id       := 0;
      g_error_code          := 'XX_OM_65100_UNEXPECTED_ERR';             

      -- Call the write_exception procedure to insert into
      -- Global exception table
      xx_po_mlss_pkg.write_exception ( p_error_code       => g_error_code
                                     ,p_error_description => g_error_description
                                     ,p_entity_reference  => g_entity_reference
                                     ,p_entity_ref_id     => g_entity_ref_id);


  
END delete_row;

END XX_PO_MLSS_HDR_PKG;
/

SHOW ERRORS

EXIT;