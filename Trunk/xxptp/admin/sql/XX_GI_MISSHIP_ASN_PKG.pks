SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_GI_MISSHIP_ASN_PKG
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- | Name        :  XX_GI_MISSHIP_ASN_PKG.pks                                    |
-- | Description :  Mis - Ship SKU and Add - on PO Package Spec                  |
-- |                                                                             |
-- |Change Record:                                                               |
-- |===============                                                              |
-- |  Version      Date         Author             Remarks                       |
-- | =========  =========== =============== ==================================== |
-- |  DRAFT 1a  17-Oct-2007   Ritu Shukla     Initial draft version              |
-- |    1.0     31-Oct-2007   Vikas Raina     Incorporated TL Review Comments    |
-- +=============================================================================+

AS
----------------------------
--Declaring Global Constants
----------------------------

----------------------------
--Declaring Global Variables
----------------------------

-----------------------------------
--Declaring Global Record Variables
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

------------------------------------------------------------------------------------------------------
--Declaring VALIDATE_SKU_ASN_PROC procedure which gets called from OD: GI Item Validation For ASN Data
------------------------------------------------------------------------------------------------------
PROCEDURE validate_sku_asn_proc(
                                 x_errbuf              OUT NOCOPY VARCHAR2
                                ,x_retcode             OUT NOCOPY VARCHAR2
                               );
                               
-- +======================================================================+
-- | Name        :  derive_profile_value                                  |
-- | Description :  This procedure derives prifile option value for the   |
-- |                given profile option                                  |
-- |                                                                      |
-- | Parameters  :  p_profile_option                                      |
-- |                                                                      |
-- | Returns     :  x_profile_value                                       |
-- |                x_status                                              |
-- |                x_message                                             |
-- +======================================================================+
PROCEDURE derive_profile_value(  p_profile_option      IN         VARCHAR2
                                ,x_profile_value       OUT NOCOPY VARCHAR2
                                ,x_status              OUT NOCOPY VARCHAR2
                                ,x_message             OUT NOCOPY VARCHAR2
                               );
                               
-- +======================================================================+
-- | Name        :  derive_master_organization                            |
-- | Description :  This procedure derives master organization in the     |
-- |                system                                                |
-- |                                                                      |
-- | Parameters  :                                                        |
-- |                                                                      |
-- | Returns     :  x_master_organization                                 |
-- |                x_status                                              |
-- |                x_message                                             |
-- +======================================================================+
PROCEDURE derive_master_organization(  x_master_organization OUT NOCOPY VARCHAR2
                                      ,x_status              OUT NOCOPY VARCHAR2
                                      ,x_message             OUT NOCOPY VARCHAR2
                                    );
                                    
-- +======================================================================+
-- | Name        :  check_po_line                                         |
-- | Description :  This procedure checks if item exits in PO Line. Also  |
-- |                derives the status of PO                              |
-- |                                                                      |
-- | Parameters  :  p_header_id                                           |
-- |                p_item_id                                             |
-- |                p_org_id                                              |
-- |                                                                      |
-- | Returns     :  x_authorization_status                                |
-- |                x_line_id                                             |
-- |                x_status                                              |
-- |                x_message                                             |
-- +======================================================================+
PROCEDURE check_po_line (  p_header_id              IN         NUMBER
                          ,p_item_num               IN         VARCHAR2
                          ,x_authorization_status   OUT NOCOPY VARCHAR2
                          ,x_line_id                OUT NOCOPY NUMBER
                          ,x_status                 OUT NOCOPY VARCHAR2
                          ,x_message                OUT NOCOPY VARCHAR2
                        );

-- +======================================================================+
-- | Name        :  upc_validation                                        |
-- | Description :  This procedure checks if UPC Code exist for an        |
-- |                item                                                  |
-- |                                                                      |
-- | Parameters  :  p_organizaion_id                                      |
-- |                p_item_num                                            |
-- |                                                                      |
-- | Returns     :  x_inv_item_num                                        |
-- |                x_inventory_item_id                                   |
-- |                x_primary_uom_code                                    |
-- |                x_count                                               |
-- |                x_status                                              |
-- |                x_message                                             |
-- +======================================================================+
PROCEDURE upc_validation(  p_organization_id         IN         NUMBER
                          ,p_item_num                IN         VARCHAR2
                          ,x_inv_item_num            OUT NOCOPY VARCHAR2
                          ,x_inventory_item_id       OUT NOCOPY NUMBER
                          ,x_primary_uom_code        OUT NOCOPY VARCHAR2
                          ,x_count                   OUT NOCOPY NUMBER
                          ,x_status                  OUT NOCOPY VARCHAR2
                          ,x_message                 OUT NOCOPY VARCHAR2
                        );
                        
-- +======================================================================+
-- | Name        :  vpc_validation                                        |
-- | Description :  This procedure checks if VPC Code exist for an        |
-- |                item                                                  |
-- |                                                                      |
-- | Parameters  :  p_organizaion_id                                      |
-- |                p_item_num                                            |
-- |                p_vendor_id                                           |
-- |                                                                      |
-- | Returns     :  x_inv_item_num                                        |
-- |                x_inventory_item_id                                   |
-- |                x_primary_uom_code                                    |
-- |                x_count                                               |
-- |                x_status                                              |
-- |                x_message                                             |
-- +======================================================================+
PROCEDURE vpc_validation(  p_organization_id         IN         NUMBER
                          ,p_item_num                IN         VARCHAR2
                          ,p_vendor_id               IN         NUMBER
                          ,x_inv_item_num            OUT NOCOPY VARCHAR2
                          ,x_inventory_item_id       OUT NOCOPY NUMBER
                          ,x_primary_uom_code        OUT NOCOPY VARCHAR2
                          ,x_count                   OUT NOCOPY NUMBER
                          ,x_status                  OUT NOCOPY VARCHAR2
                          ,x_message                 OUT NOCOPY VARCHAR2
                        );
                        
-- +======================================================================+
-- | Name        :  item_in_master_and_recv                               |
-- | Description :  This procedure checks if item exist in master and     |
-- |                receiving org                                         |
-- |                                                                      |
-- | Parameters  :  p_organizaion_id                                      |
-- |                p_item_num                                            |
-- |                                                                      |
-- | Returns     :  x_inv_item_num                                        |
-- |                x_inventory_item_id                                   |
-- |                x_primary_uom_code                                    |
-- |                x_count                                               |
-- |                x_status                                              |
-- |                x_message                                             |
-- +======================================================================+
PROCEDURE item_in_master_and_recv(  p_organization_id         IN         NUMBER
                                   ,p_item_num                IN         VARCHAR2
                                   ,x_inventory_item_id       OUT NOCOPY NUMBER
                                   ,x_primary_uom_code        OUT NOCOPY VARCHAR2
                                   ,x_item_description        OUT NOCOPY VARCHAR2
                                   ,x_count                   OUT NOCOPY NUMBER
                                   ,x_status                  OUT NOCOPY VARCHAR2
                                   ,x_message                 OUT NOCOPY VARCHAR2
                                 );
                                 
                                 
END XX_GI_MISSHIP_ASN_PKG;
/

SHOW ERRORS
EXIT;
