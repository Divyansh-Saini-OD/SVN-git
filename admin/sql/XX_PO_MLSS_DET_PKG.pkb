SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_PO_MLSS_DET_PKG                                                
  
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                 Oracle NAIO Consulting Organization               |
-- +===================================================================+
-- | Name         :XX_PO_MLSS_DET_PKG                                  |
-- | Rice ID      :E1252_MultiLocationSupplierSourcing                 |
-- | Description  :This package body is used to Insert, Update         |
-- |               Delete, Lock rows of XX_PO_MLSS_DET Table           | 
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
-- |               XX_PO_MLSS_DET table                                |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:  p_mlss_header_id                                     |
-- |              p_mlss_line_id                                       |
-- |              p_vendor_id                                          |
-- |              p_vendor_site_id                                     |
-- |              p_supply_loc_no                                      |
-- |              p_rank                                               |
-- |              p_end_point                                          |
-- |              p_ds_lt                                              |
-- |              p_b2b_lt                                             |
-- |              p_supp_loc_ac                                        |
-- |              p_supp_facility_cd                                   |
-- |              p_creation_date                                      |
-- |              p_created_by                                         |
-- |              p_last_update_date                                   |
-- |              p_last_updated_by                                    |
-- |              p_last_update_login                                  |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_row_id                                       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE insert_row (
                        x_rowid             IN OUT NOCOPY VARCHAR2
                       ,p_mlss_header_id    IN NUMBER
                       ,p_mlss_line_id      IN NUMBER
                       ,p_vendor_id         IN NUMBER
                       ,p_vendor_site_id    IN NUMBER
                       ,p_supply_loc_no     IN VARCHAR2
                       ,p_rank              IN NUMBER
                       ,p_end_point         IN VARCHAR2
                       ,p_ds_lt             IN NUMBER
                       ,p_b2b_lt            IN NUMBER
                       ,p_supp_loc_ac       IN NUMBER
                       ,p_supp_facility_cd  IN VARCHAR2
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

  INSERT INTO xx_po_mlss_det (
                         mlss_header_id  
                        ,mlss_line_id    
                        ,vendor_id     
                        ,vendor_site_id  
                        ,supply_loc_no   
                        ,rank            
                        ,end_point       
                        ,ds_lt           
                        ,b2b_lt          
                        ,supp_loc_ac     
                        ,supp_facility_cd                      
                        ,creation_date
                        ,created_by
                        ,last_update_date
                        ,last_updated_by
                        ,last_update_login
                       ) VALUES (
                         p_mlss_header_id
                        ,p_mlss_line_id     
                        ,p_vendor_id       
                        ,p_vendor_site_id   
                        ,p_supply_loc_no    
                        ,p_rank             
                        ,p_end_point        
                        ,p_ds_lt            
                        ,p_b2b_lt           
                        ,p_supp_loc_ac      
                        ,p_supp_facility_cd
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
      g_entity_reference    := 'Unexpected Error while inserting into XX_PO_MLSS_DET table';
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
-- |               XX_PO_MLSS_DET table for update                     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:         p_mlss_header_id                              |
-- |                     p_mlss_line_id                                |
-- |                     p_vendor_id                                   |
-- |                     p_vendor_site_id                              |
-- |                     p_supply_loc_no                               |
-- |                     p_rank                                        |
-- |                     p_end_point                                   |
-- |                     p_ds_lt                                       |
-- |                     p_b2b_lt                                      |
-- |                     p_supp_loc_ac                                 |
-- |                     p_supp_facility_cd                            |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


PROCEDURE lock_row (
                       p_mlss_header_id    IN NUMBER
                      ,p_mlss_line_id      IN NUMBER
                      ,p_vendor_id         IN NUMBER
                      ,p_vendor_site_id    IN NUMBER
                      ,p_supply_loc_no     IN VARCHAR2
                      ,p_rank              IN NUMBER
                      ,p_end_point         IN VARCHAR2
                      ,p_ds_lt             IN NUMBER
                      ,p_b2b_lt            IN NUMBER
                      ,p_supp_loc_ac       IN NUMBER
                      ,p_supp_facility_cd  IN VARCHAR2
                     ) IS

  CURSOR lcu_lock_row IS
     SELECT XPMD.vendor_id
         ,XPMD.vendor_site_id
         ,XPMD.supply_loc_no
         ,XPMD.rank
         ,XPMD.end_point
         ,XPMD.ds_lt
         ,XPMD.b2b_lt
         ,XPMD.supp_loc_ac
         ,XPMD.supp_facility_cd
     FROM   xx_po_mlss_det XPMD
     WHERE  XPMD.mlss_header_id = p_mlss_header_id
     AND    XPMD.mlss_line_id   = p_mlss_line_id
     FOR UPDATE OF XPMD.vendor_id NOWAIT;
    
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
            ((recinfo.vendor_id        = p_vendor_id        OR (recinfo.vendor_id         IS NULL AND p_vendor_id        IS NULL)))
         AND ((recinfo.vendor_site_id   = p_vendor_site_id   OR (recinfo.vendor_site_id    IS NULL AND p_vendor_site_id   IS NULL))) 
         AND ((recinfo.supply_loc_no    = p_supply_loc_no    OR (recinfo.supply_loc_no     IS NULL AND p_supply_loc_no    IS NULL))) 
         AND ((recinfo.rank             = p_rank             OR (recinfo.rank               IS NULL AND p_rank             IS NULL))) 
         AND ((recinfo.end_point        = p_end_point        OR (recinfo.end_point          IS NULL AND p_end_point        IS NULL))) 
         AND ((recinfo.ds_lt            = p_ds_lt            OR (recinfo.ds_lt              IS NULL AND p_ds_lt            IS NULL))) 
         AND ((recinfo.b2b_lt           = p_b2b_lt           OR (recinfo.b2b_lt             IS NULL AND p_b2b_lt           IS NULL))) 
         AND ((recinfo.supp_loc_ac      = p_supp_loc_ac      OR (recinfo.supp_loc_ac       IS NULL AND p_supp_loc_ac      IS NULL)))
         AND ((recinfo.supp_facility_cd = p_supp_facility_cd OR (recinfo.supp_facility_cd  IS NULL AND p_supp_facility_cd IS NULL)))
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
-- |               XX_PO_MLSS_DET table                                |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:        p_mlss_header_id                               |
-- |                    p_mlss_line_id                                 |
-- |                    p_vendor_id                                    |
-- |                    p_vendor_site_id                               |
-- |                    p_supply_loc_no                                |
-- |                    p_rank                                         |
-- |                    p_end_point                                    |
-- |                    p_ds_lt                                        |
-- |                    p_b2b_lt                                       |
-- |                    p_supp_loc_ac                                  |
-- |                    p_supp_facility_cd                             |
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
                       ,p_mlss_line_id      IN NUMBER
                       ,p_vendor_id         IN NUMBER
                       ,p_vendor_site_id    IN NUMBER
                       ,p_supply_loc_no     IN VARCHAR2
                       ,p_rank              IN NUMBER
                       ,p_end_point         IN VARCHAR2
                       ,p_ds_lt             IN NUMBER
                       ,p_b2b_lt            IN NUMBER
                       ,p_supp_loc_ac       IN NUMBER
                       ,p_supp_facility_cd  IN VARCHAR2
                       ,p_last_update_date  IN DATE
                       ,p_last_updated_by   IN NUMBER
                       ,p_last_update_login IN NUMBER
                     )IS

BEGIN

   g_error_code         := NULL;
   g_error_description  := NULL;
   g_entity_reference   := NULL;
   g_entity_ref_id      := 0;

   UPDATE xx_po_mlss_det XPMD 
   SET    XPMD.vendor_id          =  p_vendor_id       
         ,XPMD.vendor_site_id     =  p_vendor_site_id  
         ,XPMD.supply_loc_no      =  p_supply_loc_no  
         ,XPMD.rank               =  p_rank            
         ,XPMD.end_point          =  p_end_point       
         ,XPMD.ds_lt              =  p_ds_lt           
         ,XPMD.b2b_lt             =  p_b2b_lt 
         ,XPMD.supp_loc_ac        =  p_supp_loc_ac      
         ,XPMD.supp_facility_cd   =  p_supp_facility_cd
         ,XPMD.last_update_date   =  p_last_update_date
         ,XPMD.last_updated_by    =  p_last_updated_by
         ,XPMD.last_update_login  =  p_last_update_login
   WHERE  XPMD.mlss_header_id     =  p_mlss_header_id
   AND    XPMD.mlss_line_id       =  p_mlss_line_id;

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
      g_entity_reference    := 'Unexpected Error while Updating the XX_PO_MLSS_DET table';
      g_entity_ref_id       := 0;
      g_error_code          := 'XX_OM_65100_UNEXPECTED_ERR';             

      -- Call the write_exception procedure to insert into
      -- Global exception table
      xx_po_mlss_pkg.write_exception ( p_error_code        => g_error_code
                                     ,p_error_description => g_error_description
                                     ,p_entity_reference  => g_entity_reference
                                     ,p_entity_ref_id     => g_entity_ref_id);


END update_row;

-- +===================================================================+
-- | Name  : DELETE_ROW                                                |
-- | Description:  This procedure is used to delete the rows from      |
-- |               XX_PO_MLSS_DET table                                |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:        p_mlss_header_id                               |
-- |                    p_mlss_line_id                                 |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE delete_row (
                       p_mlss_header_id IN NUMBER
                      ,p_mlss_line_id   IN NUMBER
                     )IS
                     
BEGIN
  DELETE FROM xx_po_mlss_det XPMD
  WHERE XPMD.mlss_header_id  = p_mlss_header_id
  AND   XPMD.mlss_line_id    = p_mlss_line_id;

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
     g_entity_reference    := 'Unexpected Error while Deleting from XX_PO_MLSS_DET table';
     g_entity_ref_id       := 0;
     g_error_code          := 'XX_OM_65100_UNEXPECTED_ERR';             

     -- Call the write_exception procedure to insert into
     -- Global exception table
     xx_po_mlss_pkg.write_exception ( p_error_code       => g_error_code
                                    ,p_error_description => g_error_description
                                    ,p_entity_reference  => g_entity_reference
                                    ,p_entity_ref_id     => g_entity_ref_id);
  
  
    
END delete_row;

END XX_PO_MLSS_DET_PKG;
/

SHOW ERRORS

EXIT;