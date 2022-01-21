SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_GI_CONSIGNMENT_DTLS_PKG
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |             Oracle NAIO/WIPRO/Office Depot/Consulting Organization        |
-- +===========================================================================+
-- | Name             :  XX_GI_CONSIGNMENT_DTLS_PKG.pkb                        |
-- | Description      :  This Package is used in Custom Solution Approach of   |
-- |                     Consignment.This is a Custom API which would be used  |
-- |                     by other packages to derive consignment details.      |
-- |                                                                           |
-- | Change Record:                                                            |
-- |===============                                                            |
-- |Version   Date         Author           Remarks                            |
-- |=======   ==========   =============    ===================================|
-- |Draft 1a  11-Sep-2007  Chandan U H      Initial draft version              |
-- |Draft 1b  19-Sep-2007  Chandan U H      Incorporated Global Org condition  |
-- |1.0       26-Sep-2007  Chandan U H      Baselined                          |
-- |1.1       08-Oct-2007  Chandan U H      Added a case for return status as 'W'|
-- +===========================================================================+
AS

-- ---------------------------
-- Global Variable Declaration
-- ---------------------------
-- +===========================================================================+
-- | Name         :  XX_GI_IS_CONSIGNED                                        |
-- |                                                                           |
-- | Description  :  This procedure returns the consignment status of an item  |
-- |                 belonging to an organization.                             |
-- |                 This returns the vendor_id,vendor_site_id for that        |
-- |                 Item-Org combination.                                     |
-- |                                                                           |
-- |In Parameters :  p_item_id                                                 |
-- |                 p_organization_id                                         |
-- |                                                                           |
-- |Out Parameters:  x_consignment_flag                                        |
-- |                 x_vendor_id                                               |
-- |                 x_vendor_site_id                                          |
-- |                 x_return_status                                           |
-- |                 x_return_message                                          |
-- |                                                                           |
-- +===========================================================================+

PROCEDURE  XX_GI_IS_CONSIGNED  
                ( p_item_id               IN    NUMBER
                 ,p_organization_id       IN    NUMBER
                 ,x_consignment_flag      OUT   NOCOPY  VARCHAR2
                 ,x_vendor_id             OUT   NOCOPY  NUMBER
                 ,x_vendor_site_id        OUT   NOCOPY  NUMBER                 
                 ,x_return_status         OUT   NOCOPY  VARCHAR2
                 ,x_return_message        OUT   NOCOPY  VARCHAR2
                )
IS

-- -----------------------------------------
-- Local Variable and Exceptions Declaration
-- -----------------------------------------
lc_org_valid                  VARCHAR2(1);  --Flag to check whether org is valid
lc_item_valid                 VARCHAR2(1);  --Flag to check whether item is valid
lc_invalid_org_msg            VARCHAR2(240);--To capture error message if Org Id is NULL
lc_invalid_item_msg           VARCHAR2(240);--To capture error message if Item Id is NULL
lc_invalid_asl_msg            VARCHAR2(240);--To capture error message if no consignment details exist even for Global Org.

-- ---------------------------------------------
-- Cursor to derive Vendor Id and Vendor Site Id
-- ---------------------------------------------
CURSOR lcu_vendor_dtls( p_item_id          IN NUMBER
                       ,p_organization_id  IN NUMBER
                       )
IS
SELECT PASL.vendor_id
      ,PVSA.vendor_site_id 
FROM   po_approved_supplier_list PASL
      ,po_vendor_sites_all PVSA
WHERE  PVSA.vendor_site_id         =  PASL.vendor_site_id 
AND    PASL.attribute6             =  'Y'
AND    UPPER(PVSA.attribute8)      =  'TR-CON'
AND    PASL.asl_status_id          =  2
AND    NVL (PASL.disable_flag,'N') = 'N'
AND    PASL.item_id                =  p_item_id
AND   (PASL.using_organization_id  = p_organization_id OR PASL.using_organization_id   = -1)
ORDER BY PASL.using_organization_id DESC; 

BEGIN 

      x_consignment_flag := 'N';
      x_return_status    := 'E';
-- --------------------------
-- Validate the Organization
-- --------------------------
      BEGIN
            
         IF p_organization_id IS NULL THEN         
            fnd_message.set_name('XXPTP','XX_GI_60001_INAVLID_ORG');
            fnd_message.set_token('ORGANIZATION_ID',NULL);
            lc_invalid_org_msg  := SUBSTR(fnd_message.get,1,240);
            x_return_message    := lc_invalid_org_msg||'.';            
         ELSE            
            SELECT 'Y'         
            INTO   lc_org_valid
            FROM   hr_all_organization_units
            WHERE  organization_id  = p_organization_id;          
         END IF;   --p_organization_id IS NULL
         
      EXCEPTION
          WHEN NO_DATA_FOUND THEN 
             lc_org_valid       := 'N';
             x_return_status    := 'E';
             fnd_message.set_name('XXPTP','XX_GI_60001_INAVLID_ORG');
             fnd_message.set_token('ORGANIZATION_ID',p_organization_id);
             lc_invalid_org_msg := SUBSTR(fnd_message.get,1,240);
             x_return_message   := lc_invalid_org_msg||'.';
          WHEN OTHERS THEN
             lc_org_valid       := 'N';
             x_return_status    := 'E';
             x_return_message   := SQLERRM;         
             x_return_message   := SUBSTR(x_return_message,1,240);
      END;
-- ------------------------------
-- Validate the Item if Org Valid
-- ------------------------------         
      BEGIN
         
         IF (p_item_id IS NULL) THEN
            fnd_message.set_name('XXPTP','XX_GI_60002_INVALID_ITEM');
            fnd_message.set_token('ITEM_ID',NULL);
            lc_invalid_item_msg := SUBSTR(fnd_message.get,1,240);
            x_return_message    := x_return_message||' '||lc_invalid_item_msg;   
         
         ELSIF NVL(lc_org_valid,'N') = 'Y'THEN -- Check only if valid organization
         
            SELECT 'Y'
            INTO   lc_item_valid
            FROM   mtl_system_items_b
            WHERE  inventory_item_id = p_item_id
            AND    organization_id   = p_organization_id              
            AND    rownum = 1;
            
         END IF;  --IF inventory_item_id IS NULL

      EXCEPTION
          WHEN NO_DATA_FOUND THEN             
             lc_item_valid      := 'N';
             x_return_status    := 'E';
             fnd_message.set_name('XXPTP','XX_GI_60003_INVALID_ITM_ORG');
             fnd_message.set_token('ORGANIZATION_ID',p_organization_id);
             fnd_message.set_token('ITEM_ID',p_item_id);     
             lc_invalid_item_msg:= SUBSTR(fnd_message.get,1,240);
             x_return_message   := x_return_message||' '||lc_invalid_item_msg;
          WHEN OTHERS THEN          
             lc_item_valid      := 'N';
             x_return_status    := 'E';
             x_return_message   := x_return_message||'When Others Then Raised when Validating Item.Oracle error : '||SQLERRM;     
             x_return_message   := SUBSTR(x_return_message,1,240);
      END;   
               
-- --------------------------------------------------------------
-- When Both Item and Org are Valid,Fetch the Consignment details
-- --------------------------------------------------------------   
      IF NVL(lc_item_valid,'N') = 'Y' AND NVL(lc_org_valid,'N') = 'Y' THEN    
           
            OPEN  lcu_vendor_dtls(p_item_id,p_organization_id);
            FETCH lcu_vendor_dtls 
            INTO  x_vendor_id,x_vendor_site_id;
            
               IF lcu_vendor_dtls%NOTFOUND THEN 
                    CLOSE lcu_vendor_dtls;      --Closing the cursor as reopening the same for Global Org                    
                    
                         x_consignment_flag  := 'N'; 
                         x_return_status     := 'W';                      
                         fnd_message.set_name('XXPTP','XX_GI_60004_ASL_NOT_FOUND');
                         fnd_message.set_token('ORGANIZATION_ID',p_organization_id);
                         fnd_message.set_token('ITEM_ID',p_item_id);                      
                         lc_invalid_asl_msg  := SUBSTR(fnd_message.get,1,240);
                         x_return_message    := lc_invalid_asl_msg;                          
                         x_return_message    := SUBSTR(x_return_message,1,240);              
               ELSE       
               
                  CLOSE lcu_vendor_dtls;--Closing the cursor if lcu_vendor_dtls is FOUND.  
                  
               END IF;--END IF of lcu_vendor_dtls%NOTFOUND of the cursor                

             -- If valid vendor_id and vendor_site_id are selected,return Success            
            IF  NVL(x_vendor_id,0) <> 0 AND NVL(x_vendor_site_id,0) <> 0 THEN            
                x_consignment_flag := 'Y';               
                x_return_status    := 'S';        
            END IF;            
      END IF;   -- NVL(lc_item_valid,'N') = 'Y' AND NVL(lc_org_valid,'N') = 'Y'      
      
EXCEPTION
   WHEN OTHERS THEN
      x_consignment_flag := 'N'; 
      x_return_status    := 'E';
      x_return_message   := 'When Others Raised when Deriving the Consignment details. Oracle error : '||SQLERRM;
      x_return_message   := SUBSTR(x_return_message,1,240);    
END XX_GI_IS_CONSIGNED;
    
END XX_GI_CONSIGNMENT_DTLS_PKG;
/
SHOW ERRORS
EXIT;  