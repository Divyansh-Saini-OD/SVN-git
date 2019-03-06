SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_POS_SHIP_CONF_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XX_OM_POS_SHIP_CONF_PKG                                   |
-- | RiceID : I0227_PosPmtFeed and I0153KioskordRel                    |
-- | Description      : Package Specification containing procedure to  | 
-- |                    do all the necessary validations, to insert the|
-- |                    payment information, to release the hold and to|
-- |                    ship confirm the order.                        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  | 
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   16-Jan-2007   Neeraj R.        Initial draft version    |
-- |                                                                   |
-- +===================================================================+
AS

    g_exception xx_om_report_exception_t:= xx_om_report_exception_t('OTHERS','OTC','Order Management','POS PMT FEED',NULL,NULL,NULL,NULL);

    TYPE XX_OM_ORDER_HDR_REC_TYPE IS RECORD (
         order_number           NUMBER
        ,header_id              NUMBER
        ,transaction_type       VARCHAR2(20)
        ,pos_transaction_num    VARCHAR2(240)
        );

    TYPE XX_OM_ORDER_LINES_REC_TYPE IS RECORD (
         order_number            NUMBER
        ,sku_number              VARCHAR2(240)
        ,inventory_item_id       NUMBER
        ,line_id                 NUMBER
        ,line_number             NUMBER
        ,uom_code                VARCHAR2(50)
        ,warehouse_code          VARCHAR2(240)
        ,ship_from_org_id        NUMBER
        ,salesrep_name           VARCHAR2(240)
        ,salesrep_id             NUMBER
        ,tax_amt                 NUMBER
        ,selling_price           NUMBER
        ,shipped_quantity        NUMBER
        ,serial_number           NUMBER
        ,line_status             VARCHAR2(20)
        ,tax_code                VARCHAR2(240)
        );

    TYPE XX_OM_ORDER_LINES_TBL 
    IS TABLE OF XX_OM_ORDER_LINES_REC_TYPE INDEX BY BINARY_INTEGER;

    TYPE XX_OM_ORD_PAYMENTS_REC_TYPE IS RECORD (
         order_number           NUMBER 
        ,line_number            NUMBER
        ,payment_method         VARCHAR2(30)
        ,payment_instrument     VARCHAR2(30)
        ,payment_details        VARCHAR2(50)
        ,expiration_date        DATE
        ,payment_amount         NUMBER
        ,acct_holder_name       VARCHAR2(240)
        ,account_number         NUMBER
        ,routing_number         NUMBER
        ,authorization_code     VARCHAR2(20)
        );

    TYPE XX_OM_ORDER_PAYMENTS_TBL 
    IS TABLE OF XX_OM_ORD_PAYMENTS_REC_TYPE INDEX BY BINARY_INTEGER;

    TYPE XX_OM_ACK_LINES_REC_TYPE IS RECORD (
         line_number            NUMBER
        ,error_message          VARCHAR2(2000)
        );
        
    TYPE XX_OM_ACK_ORD_LINES_TBL 
    IS TABLE OF XX_OM_ACK_LINES_REC_TYPE INDEX BY BINARY_INTEGER;
    
    -- +===================================================================+
    -- | Name  : log_exceptions                                            |
    -- | RICE ID : E0205                                                   |
    -- | Description: This procedure s used to log the exceptions          |
    -- |                                                                   |
    -- | Parameters:                                                       |
    -- |                                                                   |
    -- |                                                                   |
    -- | Returns :                                                         |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE log_exceptions;    

    -- +===================================================================+
    -- | Name  : OD_POS_Ship_Confirm_Proc                                  |
    -- |                                                                   |
    -- | Description: This Procedure is the main procedure, which will be  |
    -- |              called by BPEL Process. It calls various procedure   |
    -- |              inside it to do all the necessary validations, to    |
    -- |              insert the payment information, to release the hold  |
    -- |              and to ship confirm the order.                       |
    -- |                                                                   |
    -- | Parameters:                                                       |
    -- |                                                                   |
    -- | Returns :                                                         |
    -- |                                                                   |
    -- +===================================================================+
    PROCEDURE OD_POS_Ship_Confirm_Proc (
        p_order_number          IN  OUT NUMBER,
        p_order_header_rec      IN  XX_OM_ORDER_HDR_REC_TYPE,
        p_order_lines_tbl       IN  XX_OM_ORDER_LINES_TBL,
        p_order_payments_tbl    IN  XX_OM_ORDER_PAYMENTS_TBL,
        x_order_lines_tbl_out   IN  OUT XX_OM_ACK_ORD_LINES_TBL,
        x_status                OUT VARCHAR2,
        x_transaction_date      OUT VARCHAR2,
        x_message               OUT VARCHAR2);
        

END XX_OM_POS_SHIP_CONF_PKG;
/
SHOW ERRORS;
--EXIT;
