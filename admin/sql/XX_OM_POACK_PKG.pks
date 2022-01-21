SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE 
PACKAGE XX_OM_POACK_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name  :  XX_OM_POACK_PKG                                          |
-- | Rice ID : I0265                                                   |
-- | Description: This package contains procedures that perform the    |
-- |              following activities                                 |
-- |              1.Validate the PO Acknowledgement Message            |
-- |              2.Update the Acknowledgement details                 |
-- |              3.Cancel a PO Line                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A              Aravind A.        Initial draft version      |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
AS

-- +===================================================================+
-- | Name  : VALIDATE_PROCESS_POACK                                    |
-- | Description   : This procedure will validate the input PO Ack     |
-- |                 message and will call the UPDATE_POACK if the PO  |
-- |                 is accepted or will call the CANCEL_POLINES if    |
-- |                 the PO is rejected                                |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :       Following are the Table type variables         |
-- |                    that are passed to this procedure              |
-- |                                                                   |
-- |                    p_po_vendor_site_id                            |
-- |                    p_po_number                                    |
-- |                    p_ref_po_number                                |
-- |                    p_transaction_date                             |
-- |                    p_sales_order                                  |
-- |                    p_po_line_number                               |
-- |                    p_vendor_sku                                   |
-- |                    p_item_number                                  |
-- |                    p_upc_code                                     |
-- |                    p_shipment_date                                |
-- |                    p_ack_code                                     |
-- |                                                                   |
-- | Returns :          Following are the table type parameters        |
-- |                    returned to BPEL by this procedure             |
-- |                                                                   |
-- |                    x_po_vendor_site_id                            |
-- |                    x_po_number                                    |
-- |                    x_transaction_date                             |
-- |                    x_sales_order                                  |
-- |                    x_po_line_number                               |
-- |                    x_vendor_sku                                   |
-- |                    x_item_number                                  |
-- |                    x_upc_code                                     |
-- |                    x_shipment_date                                |
-- |                    x_ack_code                                     |
-- |                    x_email_address                                |
-- |                    x_status                                       |
-- |                    x_message                                      |
-- |                                                                   |
-- +===================================================================+

TYPE po_vendor_site_id_tbl_type IS TABLE OF PO_HEADERS_ALL.vendor_site_id%TYPE INDEX BY BINARY_INTEGER;

TYPE po_segment1_tbl_type IS TABLE OF PO_HEADERS_ALL.segment1%TYPE INDEX BY BINARY_INTEGER;

TYPE po_creation_date_tbl_type IS TABLE OF PO_HEADERS_ALL.creation_date%TYPE INDEX BY BINARY_INTEGER;

TYPE po_vendor_sku_tbl_type IS TABLE OF VARCHAR2(25) INDEX BY BINARY_INTEGER;

TYPE po_order_num_tbl_type IS TABLE OF OE_ORDER_HEADERS_ALL.order_number%TYPE INDEX BY BINARY_INTEGER;

TYPE po_line_num_tbl_type IS TABLE OF PO_LINES_ALL.line_num%TYPE INDEX BY BINARY_INTEGER;

TYPE po_item_id_tbl_type IS TABLE OF PO_LINES_ALL.item_id%TYPE INDEX BY BINARY_INTEGER;

TYPE po_upc_code_tbl_type IS TABLE OF VARCHAR2(25) INDEX BY BINARY_INTEGER;

TYPE po_shipment_date_tbl_type IS TABLE OF DATE INDEX BY BINARY_INTEGER;

TYPE po_ack_code_tbl_type IS TABLE OF VARCHAR2(10) INDEX BY BINARY_INTEGER;

TYPE po_email_address_tbl_type IS TABLE OF WF_ROLES.email_address%TYPE INDEX BY BINARY_INTEGER;

PROCEDURE VALIDATE_PROCESS_POACK(p_po_vendor_site_id     IN      po_vendor_site_id_tbl_type
                                 ,p_po_number            IN      po_segment1_tbl_type
                                 ,p_ref_po_number        IN      po_segment1_tbl_type
                                 ,p_transaction_date     IN      po_creation_date_tbl_type
                                 ,p_sales_order          IN      po_order_num_tbl_type
                                 ,p_po_line_number       IN      po_line_num_tbl_type
                                 ,p_vendor_sku           IN      po_vendor_sku_tbl_type
                                 ,p_item_number          IN      po_item_id_tbl_type
                                 ,p_upc_code             IN      po_upc_code_tbl_type
                                 ,p_shipment_date        IN      po_shipment_date_tbl_type
                                 ,p_ack_code             IN      po_ack_code_tbl_type
                                 ,x_po_vendor_site_id    OUT     po_vendor_site_id_tbl_type
                                 ,x_po_number            OUT     po_segment1_tbl_type
                                 ,x_transaction_date     OUT     po_creation_date_tbl_type
                                 ,x_sales_order          OUT     po_order_num_tbl_type
                                 ,x_po_line_number       OUT     po_line_num_tbl_type
                                 ,x_vendor_sku           OUT     po_vendor_sku_tbl_type
                                 ,x_item_number          OUT     po_item_id_tbl_type
                                 ,x_upc_code             OUT     po_upc_code_tbl_type
                                 ,x_shipment_date        OUT     po_shipment_date_tbl_type
                                 ,x_ack_code             OUT     po_ack_code_tbl_type
                                 ,x_email_address        OUT     po_email_address_tbl_type
                                 ,x_status               OUT     VARCHAR2
                                 ,x_message              OUT     VARCHAR2);

-- +===================================================================+
-- | Name  : UPDATE_POACK                                              |
-- | Description   : This Procedure is used to update Acknowledgement  |
-- |                 for the PO Lines in PO_LINE_LOCATIONS_ALL table   |
-- |                                                                   |
-- | Parameters :       p_po_line_id                                   |
-- |                    p_ack_code                                     |
-- |                    p_shipment_date                                |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_status                                       |
-- |                    x_message                                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE UPDATE_POACK(p_po_line_id     IN PO_LINES_ALL.po_line_id%TYPE
                       ,p_ack_code      IN VARCHAR2
                       ,p_shipment_date IN DATE
                       ,x_status        OUT VARCHAR2
                       ,x_message       OUT VARCHAR2);

-- +===================================================================+
-- | Name  : CANCEL_POLINES                                            |
-- | Description   : This Procedure is used cancel those PO Lines      |
-- |                 which had acknowledgement as Rejected             |
-- |                                                                   |
-- | Parameters :       p_po_line_id                                   |
-- |                    p_ack_code                                     |
-- |                    p_shipment_date                                |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_status                                       |
-- |                    x_message                                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE CANCEL_POLINES(p_po_number    IN PO_HEADERS_ALL.segment1%TYPE
                         ,p_po_line_num IN PO_LINES_ALL.line_num%TYPE
                         ,x_status      OUT VARCHAR2
                         ,x_message     OUT VARCHAR2);


END XX_OM_POACK_PKG;
/
SHOW ERROR