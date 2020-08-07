SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE  XX_GI_MISSHIP_COMM_PKG AUTHID CURRENT_USER
 -- +===========================================================================+
 -- |                  Office Depot - Project Simplify                          |
 -- |             Oracle NAIO/WIPRO/Office Depot/Consulting Organization        |
 -- +===========================================================================+
 -- | Name             :  XX_GI_MISSHIP_COMM_PKG.pks                            |
 -- | Description      :  Package Spec for Comman API XX_GI_MISSHIP_COMM_PKG    |
 -- |                                                                           |
 -- | Change Record:                                                            |
 -- |===============                                                            |
 -- |Version   Date         Author           Remarks                            |
 -- |=======   ==========   =============    ===================================|
 -- |Draft 1a  29-Oct-2007  Chandan U H      Initial draft version              |
 -- | 1.0      31-Oct-2007  Chandan U H      Incorporated Review Comments       |
 -- +===========================================================================+
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

--Type used to in sending Notification Details

TYPE  item_details_rec_type IS RECORD (
                                       loc              VARCHAR2(30)
                                      ,po_number        po_headers_all.segment1%TYPE
                                      ,sku              mtl_system_items_b.segment1%TYPE
                                      ,upc_vpc          VARCHAR2(30)
                                      ,asnref           rcv_headers_interface.shipment_num%TYPE
                                      ,item_type        VARCHAR2(30)
                                       );
                                                           
--Type used to in sending PO Creation Details 

TYPE  po_add_line_rec_type IS RECORD (
                                       header_po_number          po_headers_all.segment1%TYPE
                                      ,header_vendor_id          po_headers_all.vendor_id%TYPE
                                      ,header_vendor_site_id     po_headers_all.vendor_site_id%TYPE
                                      ,line_item                 po_lines_interface.item%TYPE
                                      ,item_description          po_lines_interface.item_description%TYPE
                                      ,uom_code                  po_lines_interface.uom_code%TYPE
                                      ,org_id                    po_headers_all.org_id%TYPE
                                      ,po_header_id              po_headers_all.po_header_id%TYPE
                                      ,inv_item_id               po_lines_interface.item_id%TYPE
                                      ,line_quantity             po_lines_interface.quantity%TYPE 
                                      ,line_unit_price           po_lines_interface.unit_price%TYPE                                      
                                      ,line_ship_to_org_id       po_lines_interface.ship_to_organization_id%TYPE
                                      ,line_ship_to_location_id  po_lines_interface.ship_to_location_id%TYPE
                                      ,rowid_reference           ROWID
                                      ,interface_header_id       po_lines_interface.interface_header_id%TYPE
                                      ,error_message             VARCHAR2(240)
                                      ,error_status              VARCHAR2(100)
                                      );                                      
                                        
---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------
TYPE item_details_rec_tbl_type is TABLE OF item_details_rec_type INDEX BY BINARY_INTEGER;
item_details_rec_tbl  item_details_rec_tbl_type;
 
TYPE po_add_line_rec_tbl_type is TABLE OF po_add_line_rec_type INDEX BY BINARY_INTEGER;
p_add_po_line_tbl     po_add_line_rec_tbl_type;

-------------------------------------------------------------------------------
--Declaring send_notification procedure which launches the email Notifications
-------------------------------------------------------------------------------
PROCEDURE send_notification (
                              p_item_details      IN          item_details_rec_tbl_type
                             ,x_return_status     OUT NOCOPY  VARCHAR2
                             ,x_return_message    OUT NOCOPY  VARCHAR2
                             );

------------------------------------------------------------------
--Declaring po_get_item_price procedure which gets the Item Price
------------------------------------------------------------------
PROCEDURE  po_get_item_price (
                               p_vendor_id          IN         NUMBER
                              ,p_item_id            IN         NUMBER
                              ,p_order_qty          IN         NUMBER
                              ,p_vendor_site_id     IN  OUT    NUMBER
                              ,x_item_cost          OUT NOCOPY NUMBER
                              ,x_return_message     OUT NOCOPY VARCHAR2
                              );
                              
------------------------------------------------------------------
--Declaring  create_po_line procedure which inserts into the 
--PO Interface,to create New PO Line 
------------------------------------------------------------------
PROCEDURE  create_po_line  (
                              p_add_po_line_tbl   IN  OUT     po_add_line_rec_tbl_type
                             ,x_return_status     OUT NOCOPY  VARCHAR2
                             ,x_return_message    OUT NOCOPY  VARCHAR2
                              );
                              
------------------------------------------------------------------
--Declaring generate_message which is used in generating the 
--message body of the email Notification
------------------------------------------------------------------                              
PROCEDURE generate_message(
                              p_document_id        IN       CLOB
                             ,p_display_type       IN       VARCHAR2
                             ,p_document           IN OUT   CLOB
                             ,p_document_type      IN OUT   VARCHAR2
                             );
                              


END XX_GI_MISSHIP_COMM_PKG;
/
SHOW ERRORS;

EXIT;