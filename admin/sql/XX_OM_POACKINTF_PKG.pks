SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_OM_POACKINTF_PKG
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
-- |DRAFT 1A  1-JUN-07    Aravind A.        Initial draft version      |
-- |DRAFT 1B  27-JUN-07   Rizwan            Added code for nofification|
-- |                                        Removed out parameters for |
-- |                                        Notification.              |
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
-- |                    x_status                                       |
-- |                    x_message                                      |
-- |                                                                   |
-- +===================================================================+


PROCEDURE VALIDATE_PROCESS_POACK(
                                  p_po_vendor_site_id    IN      xx_om_poack_number_tbl_type
                                 ,p_po_number            IN      xx_om_poack_varchar_tbl_type
                                 ,p_ref_po_number        IN      xx_om_poack_varchar_tbl_type
                                 ,p_transaction_date     IN      xx_om_poack_date_tbl_type
                                 ,p_sales_order          IN      xx_om_poack_number_tbl_type
                                 ,p_po_line_number       IN      xx_om_poack_number_tbl_type
                                 ,p_vendor_sku           IN      xx_om_poack_varchar_tbl_type
                                 ,p_item_number          IN      xx_om_poack_varchar_tbl_type
                                 ,p_upc_code             IN      xx_om_poack_varchar_tbl_type
                                 ,p_shipment_date        IN      xx_om_poack_date_tbl_type
                                 ,p_ack_code             IN      xx_om_poack_varchar_tbl_type
                                 ,p_user_name            IN      VARCHAR2
                                 ,p_resp_name            IN      VARCHAR2
                                 ,x_status               OUT     VARCHAR2
                                 ,x_message              OUT     VARCHAR2
                                 );


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


PROCEDURE UPDATE_POACK(
                        p_po_line_id    IN  po_lines_all.po_line_id%TYPE
                       ,p_ack_code      IN  VARCHAR2
                       ,p_shipment_date IN  DATE
                       ,x_status        OUT VARCHAR2
                       ,x_message       OUT VARCHAR2
                      );


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


PROCEDURE CANCEL_POLINES(
                          p_po_number   IN  po_headers_all.segment1%TYPE
                         ,p_po_line_num IN  po_lines_all.line_num%TYPE
                         ,x_status      OUT VARCHAR2
                         ,x_message     OUT VARCHAR2
                        );




-- +===================================================================+
-- | Name  : APPS_INIT                                                 |
-- | Description   : This Procedure will be used to initialise the Apps|
-- |                                                                   |
-- | Parameters :       p_user_name                                    |
-- |                    p_resp_name                                    |
-- |                                                                   |
-- | Returns :          x_return_status                                |
-- |                   ,x_message                                      |
-- |                                                                   |
-- +===================================================================+


 PROCEDURE APPS_INIT(
		      p_user_name IN  VARCHAR2
		     ,p_resp_name IN  VARCHAR2
		     ,x_status    OUT VARCHAR2
		     ,x_message   OUT VARCHAR2
		    );


END XX_OM_POACKINTF_PKG;

/
SHOW ERROR