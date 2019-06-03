CREATE OR REPLACE
PACKAGE  XX_GI_MISSHIP_RECPT_PKG
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  WIPRO Organization                                            |
-- +================================================================================+
-- | Name        :  XXGIMISSHIPPKGS.pls                                             |
-- | Description :  This script creates custom package specifications required for  |
-- |                   MIS_SHIP AND ADD-ON PO                                       |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author           Remarks                                  |
-- |=======   ==========  =============    ============================             |
-- |DRAFT 1A 09-APR-2007  Rahul Bagul        Initial draft version                  |
-- |                                                                                |
-- +================================================================================+
AS
-- Declaration of global variables

gn_old_po_price             xx_gi_rcv_po_dtl.amount%TYPE;
gn_new_po_price             xx_gi_rcv_po_dtl.amount%TYPE;
gn_rev_num                  xx_gi_rcv_po_dtl.po_revision_num%TYPE;
gn_shipment_num             xx_gi_rcv_po_dtl.shipment_num%TYPE;
gn_quantity                 xx_gi_rcv_po_dtl.quantity%TYPE;
gc_item_num                 xx_gi_rcv_po_dtl.item_num%TYPE;
gn_inventory_item_id        mtl_system_items_b.inventory_item_id%TYPE;
gn_interface_transaction_id xx_gi_rcv_po_dtl.interface_transaction_id%TYPE;
gn_header_interface_id      xx_gi_rcv_po_dtl.header_interface_id%TYPE;
gn_org_id                   xx_gi_rcv_po_dtl.to_organization_id%TYPE;
gc_document_num             xx_gi_rcv_po_dtl.document_num%TYPE;
gn_po_header_id             xx_gi_rcv_po_dtl.po_header_id%TYPE;
gn_po_line_id               xx_gi_rcv_po_dtl.po_line_id%TYPE;
gn_po_line_num              xx_gi_rcv_po_dtl.document_line_num%TYPE;
gn_vendor_id                xx_gi_rcv_po_dtl.vendor_id%TYPE;
gn_vendor_site_id           xx_gi_rcv_po_dtl.vendor_site_id%TYPE;
gd_receipt_date             xx_gi_rcv_po_hdr.expected_receipt_date%TYPE;
gc_error_message            xx_com_error_log.error_message%TYPE;
gc_error_message_code       xx_com_error_log.error_message_code%TYPE;
gc_object_id                xx_com_error_log.object_id%TYPE;
gc_object_type              xx_com_error_log.object_type%TYPE;
gn_sqlpoint                 VARCHAR2(3);
gn_ship_to_organization_id  xx_gi_rcv_po_hdr.ship_to_organization_id%TYPE;
gc_status_flag              VARCHAR2(10);
gc_e0342_flag               VARCHAR2(2);
gc_e0346_flag               VARCHAR2(1);
gc_e0346_status_flag        VARCHAR2(1);
gn_request_id               NUMBER := FND_GLOBAL.CONC_REQUEST_ID; 
gc_email_address            VARCHAR2(240);
gc_batch_id                 NUMBER;
-- +================================================================================+
-- | Name        :  MAIN_ADD_SKU_RECPT_PROC                                         |
-- | Description :  This  custom procedure is main procedure and it will call       |
-- |                all other procedures for validations. It also check whether     |
-- |                item exists in item master or not                               |
-- | Parameters  :   x_errbuff,x_retcode                                            |
-- +================================================================================+
PROCEDURE MAIN_ADD_SKU_RECPT_PROC(
                                  x_errbuff       OUT  VARCHAR2
                                 ,x_retcode       OUT  VARCHAR2
                                 ,p_email_address IN   VARCHAR2
                                 ,p_batch_id      IN   NUMBER
                                  );
-- +================================================================================+
-- | Name        :  VAL_ITEM_RECEV_ORG_PROC                                         |
-- | Description :  This  procedure will check whether item is available on         |
-- |                receiving organization or not                                   |
-- | Parameters  :   p_item_num,p_org_id                                            |
-- +================================================================================+
PROCEDURE VAL_ITEM_RECEV_ORG_PROC(
                                  p_item_num  IN  VARCHAR2
                                 ,p_org_id    IN  NUMBER
                                  );
-- +================================================================================+
-- | Name        :  VAL_UPC_CODE_PROC                                               |
-- | Description :  This  procedure will check whether RTI item matches with the    |
-- |                 UPC code or not.If it matches then then Item num in RTI will   |
-- |                 be replace with this UPC code                                  |
-- | Parameters  :   p_item_num,p_org_id,p_interface_transaction_id,p_master_org_id |
-- +================================================================================+
PROCEDURE VAL_UPC_CODE_PROC(
                            p_item_num                 IN  VARCHAR2
                           ,p_org_id                   IN  NUMBER
                           ,p_interface_transaction_id IN  NUMBER
                           ,p_master_org_id            IN  NUMBER
                            );
-- +================================================================================+
-- | Name        :  VAL_VPC_CODE_PROC                                               |
-- | Description :  This  procedure will check whether RTI item matches with the    |
-- |                 VPC code or not.If it matches then then Item num in RTI will   |
-- |                 be replace with this VPC code                                  |
-- | Parameters  :   p_item_num,p_org_id,p_interface_transaction_id,p_master_org_id |
-- +================================================================================+
PROCEDURE VAL_VPC_CODE_PROC(
                            p_item_num                 IN VARCHAR2
                           ,p_org_id                   IN NUMBER
                           ,p_interface_transaction_id IN NUMBER
                           ,p_master_org_id            IN NUMBER
                             );
-- +================================================================================+
-- | Name        :  VAL_PO_ITEM_ORG_PROC                                            |
-- | Description :  This  procedure will Validate whether item and organization     |
-- |                both matching with Purchase Order line                          |
-- | Parameters  :   p_inventory_item_id,p_document_num,p_org_id                    |
-- +================================================================================+
PROCEDURE VAL_PO_ITEM_ORG_PROC(
                               p_inventory_item_id  IN NUMBER
                              ,p_document_num       IN VARCHAR2
                              ,p_org_id             IN NUMBER
                               );
-- +================================================================================+
-- | Name        :  VAL_PO_ITEM_VDR_ASL_PROC                                        |
-- | Description :  This  procedure will Validate whether item and vendor are       |
-- |                mapped in ASL                                                   |
-- | Parameters  :  p_inventory_item_id,p_vendor_id,p_vendor_site_id,               |
-- |                p_organization_id                                               |
-- +================================================================================+
PROCEDURE VAL_PO_ITEM_VDR_ASL_PROC(
                                   p_inventory_item_id IN NUMBER
                                  ,p_vendor_id         IN NUMBER
                                  ,p_vendor_site_id    IN NUMBER
                                  ,p_organization_id   IN NUMBER
                                  );
-- +================================================================================+
-- | Name        :  VAL_PO_OPEN_PROC                                                |
-- | Description :  This  procedure will Validate whether PO is open or not         |
-- | Parameters  :  p_document_num,p_po_header_id                                   |
-- +================================================================================+
PROCEDURE VAL_PO_OPEN_PROC (
                            p_document_num  IN VARCHAR2
                           ,p_po_header_id  IN NUMBER
                            );
-- +================================================================================+
-- | Name        :  VAL_POINVPERIOD_PROC                                            |
-- | Description :  This  procedure will Validate whether PO/INV period is open     |
-- |                or not                                                          |
-- | Parameters  :  p_interface_transaction_id,p_document_num                       |
-- +================================================================================+
PROCEDURE VAL_POINVPERIOD_PROC(
                               p_interface_transaction_id  IN NUMBER
                              ,p_document_num              IN VARCHAR2
                               );
-- +================================================================================+
-- | Name        :  INTERORG_ADD_SKU_PROC                                           |
-- | Description :  This  custom procedure is main procedure and it will call       |
-- |                all other procedures for validations. It also check whether     |
-- |                item exists in item master or not                               |
-- | Parameters  : x_errbuff,x_retcode                                              |
-- +================================================================================+
PROCEDURE INTERORG_ADD_SKU_PROC(
                                 x_errbuff OUT VARCHAR2
                                ,x_retcode OUT VARCHAR2
                                );
-- +================================================================================+
-- | Name        :  INTERORG_VAL_RECEV_ORG_PROC                                     |
-- | Description :  This  procedure will check whether item is available on         |
-- |                receiving organization or not                                   |
-- | Parameters  :  p_item_num ,p_org_id                                            |
-- +================================================================================+
PROCEDURE INTERORG_VAL_RECEV_ORG_PROC(
                                      p_item_num   IN VARCHAR2
                                     ,p_org_id     IN NUMBER
                                     );
END XX_GI_MISSHIP_RECPT_PKG;
/
SHOW ERROR