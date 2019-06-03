SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
 
CREATE OR REPLACE PACKAGE XX_GI_EXCEPTION_PKG
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  WIPRO Organization                                            |
-- +================================================================================+
-- | Name        :  XX_GI_EXCEPTION_PKG.pks                                         |
-- | Rice Id     :  E0346c_Mis-Ship and Add SKU Error Handling                      |
-- | Description :  This script creates custom package body required for            |
-- |                Mis-Ship and Add SKU Error Handling                             |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author           Remarks                                  |
-- |=======   ==========  =============    ============================             |
-- |1.0      28-MAY-2007  Rahul Bagul      Initial draft version                    |
-- |                                                                                |
-- +================================================================================+
AS
gn_old_po_price         rcv_transactions_interface.amount%TYPE;
gn_new_po_price         rcv_transactions_interface.amount%TYPE;
gn_quantity             rcv_transactions_interface.quantity%TYPE;
gc_document_num         rcv_transactions_interface.document_num%TYPE;
gn_inventory_item_id    mtl_system_items_b.inventory_item_id%TYPE;
gn_po_line_id           rcv_transactions_interface.po_line_id%TYPE;
gc_error_message        xx_com_error_log.error_message%TYPE;
gc_error_message_code   xx_com_error_log.error_message_code%TYPE;
gc_object_id            xx_com_error_log.object_id%TYPE;
gc_object_type          xx_com_error_log.object_type%TYPE;
gn_sqlpoint             VARCHAR2(3);

-- +==================================================================================+
-- | Name        :  INSERT_PO_LINE_PROC                                               |
-- | Description :  This procedure is submitting  concurrent program ‘Import Standard |
-- |                Purchase Order’ to add new PO line on existing PO                 |
-- |                                                                                  |
-- +==================================================================================+
PROCEDURE INSERT_PO_LINE_PROC(
                               p_po_number                 IN VARCHAR2
                               ,p_po_header_id             IN NUMBER
                               ,p_org_id                   IN NUMBER
                               ,p_item_number              IN VARCHAR2
                               ,p_line_type                IN VARCHAR2
                               ,p_new_quantity             IN NUMBER
                               ,p_unit_price               IN NUMBER
                               ,p_promised_date            IN DATE
                               ,p_interface_transaction_id IN NUMBER
                               ,p_inventory_item_id        IN NUMBER
                               ,p_batch_id                 IN NUMBER
                               );
-- +===================================================================================+
 -- | Name        :  NOTIFY_PROC                                                       |
 -- | Description :  This procedure is submitting  concurrent program ‘Import Standard |
 -- |                Purchase Order’ to add new PO line on existing PO                 |
 -- |                                                                                  |
-- +===================================================================================+ 
PROCEDURE NOTIFY_PROC (
                       p_request_id                 IN      NUMBER
                       ,p_item_type                 IN      VARCHAR2
                       ,p_interface_transaction_id  IN      NUMBER
                       ,p_email_address             IN      VARCHAR2
                       ,x_errbuff                   OUT     VARCHAR2
                       ,x_retcode                   OUT     VARCHAR2
                      );
END XX_GI_EXCEPTION_PKG;
/

SHOW ERROR