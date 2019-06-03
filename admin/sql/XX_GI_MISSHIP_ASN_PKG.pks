SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
 
CREATE OR REPLACE PACKAGE  XX_GI_MISSHIP_ASN_PKG
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  WIPRO Organization                                            |
-- +================================================================================+
-- | Name        :  XXGIMISSHIPPKGS.pls                                             |
-- | Description :  This script creates custom package specifications required for  |
-- |                   MIS_SHIP AND ADD-ON PO                                       |
-- |                                                                                |
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
gn_old_po_price             rcv_transactions_interface.amount%TYPE;
gn_new_po_price             rcv_transactions_interface.amount%TYPE;
gn_quantity                 rcv_transactions_interface.quantity%TYPE;
gc_item_num                 rcv_transactions_interface.item_num%TYPE;
gn_inventory_item_id        mtl_system_items_b.inventory_item_id%TYPE;
gn_interface_transaction_id rcv_transactions_interface.interface_transaction_id%TYPE;
gn_header_interface_id      rcv_transactions_interface.header_interface_id%TYPE;
gn_org_id                   rcv_transactions_interface.to_organization_id%TYPE;
gc_document_num             rcv_transactions_interface.document_num%TYPE;
gn_po_header_id             rcv_transactions_interface.po_header_id%TYPE;
gn_po_line_id               rcv_transactions_interface.po_line_id%TYPE;
gn_po_line_num              rcv_transactions_interface.document_line_num%TYPE;
gn_vendor_id                rcv_transactions_interface.vendor_id%TYPE;
gn_vendor_site_id           rcv_transactions_interface.vendor_site_id%TYPE;
gd_receipt_date             rcv_headers_interface.expected_receipt_date%TYPE;
gc_error_message            xx_com_error_log.error_message%TYPE;
gc_error_message_code       xx_com_error_log.error_message_code%TYPE;
gc_object_id                xx_com_error_log.object_id%TYPE;
gc_object_type              xx_com_error_log.object_type%TYPE;
gn_sqlpoint                 VARCHAR2(3);
gn_ship_to_organization_id  rcv_headers_interface.ship_to_organization_id%TYPE;
gc_status_flag              VARCHAR2(10);
gc_e0342_flag               VARCHAR2(2);
gc_e0346_flag               VARCHAR2(1); 
gn_request_id               NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
gc_email_address            VARCHAR2(240);
gc_batch_id                 NUMBER;
      
-- +================================================================================+
-- | Name        :  MAIN_ADD_SKU_PROC                                               |
-- | Description :  This  custom procedure is main procedure and it will call       |
-- |                all other procedures for validations. It also check whether     |
-- |                item exists in item master or not                               |
-- | Parameters   : x_err_buf,x_ret_code                                            |
-- +================================================================================+
PROCEDURE MAIN_ADD_SKU_PROC(
                            x_errbuff        OUT  VARCHAR2
                            ,x_retcode        OUT  VARCHAR2
                            ,p_email_address  IN   VARCHAR2
                            ,p_batch_id       IN   NUMBER
                            );
           
-- +================================================================================+
-- | Name        :  VAL_ITEM_RECEV_ORG_PROC                                         |
-- | Description :  This  procedure will check whether item is available on         |
-- |                receiving organization or not                                   |
-- | Parameters   : p_item_num,p_org_id                                             |
-- +================================================================================+
PROCEDURE VAL_ITEM_RECEV_ORG_PROC(
                                  p_item_num  VARCHAR2
                                 ,p_org_id    NUMBER
                                 );
                                 
-- +================================================================================+
-- | Name        :  VAL_UPC_CODE_PROC                                               |
-- | Description :  This  procedure will check whether RTI item matches with the    |
-- |                 UPC code or not.If it matches then then Item num in RTI will   |
-- |                 be replace with this UPC code                                  |
-- | Parameters  : p_item_num,p_org_id,p_interface_transaction_id,p_master_org_id   |
-- +================================================================================+
PROCEDURE VAL_UPC_CODE_PROC(
                           p_item_num                  VARCHAR2
                           ,p_org_id                   NUMBER
                           ,p_interface_transaction_id NUMBER
                           ,p_master_org_id            NUMBER
                           );
                                
-- +================================================================================+
-- | Name        :  VAL_VPC_CODE_PROC                                               |
-- | Description :  This  procedure will check whether RTI item matches with the    |
-- |                 VPC code or not.If it matches then then Item num in RTI will   |
-- |                 be replace with this VPC code                                  |
-- | Parameters  : p_item_num,p_org_id,p_interface_transaction_id,p_master_org_id   |
-- +================================================================================+
PROCEDURE VAL_VPC_CODE_PROC(
                           p_item_num                  VARCHAR2
                           ,p_org_id                   NUMBER
                           ,p_interface_transaction_id NUMBER
                           ,p_master_org_id            NUMBER
                           );
                                
-- +================================================================================+
-- | Name        :  VAL_PO_ITEM_ORG_PROC                                            |
-- | Description :  This  procedure will Validate whether item and organization     |
-- |                both matching with Purchase Order line                          |
-- | Parameters  :  p_inventory_item_id,p_document_num,p_org_id                     |
-- +================================================================================+
PROCEDURE VAL_PO_ITEM_ORG_PROC(
                              p_inventory_item_id NUMBER
                              ,p_document_num     VARCHAR2
                              ,p_org_id           NUMBER
                              );
                                    
-- +================================================================================+
-- | Name        :  VAL_PO_ITEM_VDR_ASL_PROC                                        |
-- | Description :  This  procedure will Validate whether item and vendor are       |
-- |                mapped in ASL                                                   |
-- | Parameters  : p_inventory_item_id,p_vendor_id,p_vendor_site_id,                |
-- |               p_organization_id                                                |
-- +================================================================================+
PROCEDURE VAL_PO_ITEM_VDR_ASL_PROC(
                                  p_inventory_item_id NUMBER
                                  ,p_vendor_id        NUMBER
                                  ,p_vendor_site_id   NUMBER
                                  ,p_organization_id  NUMBER
                                  );
                                  
-- +================================================================================+
-- | Name        :  VAL_PO_OPEN_PROC                                                |
-- | Description :  This  procedure will Validate whether PO is open or not         |
-- |                                                                                |
-- | Parameters  : p_document_num,p_po_header_id                                    |
-- +================================================================================+
PROCEDURE VAL_PO_OPEN_PROC (
                           p_document_num   VARCHAR2
                           ,p_po_header_id  NUMBER
                           );
                                 
-- +================================================================================+
-- | Name        :  VAL_POINVPERIOD_PROC                                            |
-- | Description :  This  procedure will Validate whether PO/INV period is open     |
-- |                or not                                                          |
-- | Parameters  : p_interface_transaction_id,p_document_num                        |
-- +================================================================================+
PROCEDURE VAL_POINVPERIOD_PROC(
                              p_interface_transaction_id  NUMBER
                              ,p_document_num             VARCHAR2
                              );
                                 
END XX_GI_MISSHIP_ASN_PKG;
 
/
 
SHOW ERROR

