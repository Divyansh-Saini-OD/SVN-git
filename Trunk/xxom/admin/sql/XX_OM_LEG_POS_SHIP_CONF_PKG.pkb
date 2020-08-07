SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_LEG_POS_SHIP_CONF_PKG
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
-- |DRAFT 1A   15-Feb-2007   Neeraj R.        Initial draft version    |
-- |                                                                   |
-- |DRAFT 1B   15-Apr-2007   Shashi Kumar     Altered the code to      |
-- |                                          include update payment   |
-- |                                          functionality.           |
-- |1.0        07-Jun-2007   Shashi Kumar     Baselined After Testing  |
-- |                                          The User name used is    |
-- |                                        'SHASHIK' to initialize the| 
-- |                                         APPS.Please update to the |
-- |                                         correct one at production |
-- +===================================================================+
   AS

--Declare all the global variables to be used in procedure
GC_USER_NAME                CONSTANT VARCHAR2(240) := 'SHASHIK';
GC_RESP_NAME                CONSTANT VARCHAR2(240) := 'OD US Order Management Super User'; 

GN_USER_ID                  NUMBER; 
GN_RESP_ID                  NUMBER;
GN_RESP_APP_ID              NUMBER;

GN_ORG_ID                   NUMBER; 

-- Transaction Types
GC_SHIP_CONF_TRX_TYPE       CONSTANT VARCHAR2(20) := 'ShipConf';
GC_HOLD_REL_TRX_TYPE        CONSTANT VARCHAR2(20) := 'HoldRel';

-- Line Statuses
GC_NEW_LINE                 CONSTANT VARCHAR2(10) := 'New';
GC_MIXED_BAG_LINE           CONSTANT VARCHAR2(10) := 'Mixed';
GC_CANCEL_LINE              CONSTANT VARCHAR2(10) := 'Cancel';

-- Global exception variables
G_ENTITY_REF                VARCHAR2(1000);
G_ENTITY_REF_ID             NUMBER;
G_ERROR_DESCRIPTION         VARCHAR2(4000);
G_ERROR_CODE                VARCHAR2(100);

-- +===================================================================+
-- | Name  : Log_Exceptions                                            |
-- | Description: This procedure will be responsible to store all      | 
-- |              the exceptions occured during the process using      |
-- |              global custom exception handling framework           |
-- |                                                                   |
-- | Parameters:  IN:                                                  |
-- |     P_Error_Code        --Custom error code                       |
-- |     P_Error_Description --Custom Error Description                |
-- |     p_exception_header  --Errors occured under the exception      |
-- |                           'NO_DATA_FOUND / OTHERS'                |  
-- |     p_entity_ref        --'Hold id'                               |
-- |     p_entity_ref_id     --'Value of the Hold Id'                  |
-- |                                                                   |
-- +===================================================================+

PROCEDURE log_exceptions
  
AS

--Variables holding the values from the global exception framework package
--------------------------------------------------------------------------
x_errbuf                    VARCHAR2(1000);
x_retcode                   VARCHAR2(40);

BEGIN

   g_exception.p_error_code        := g_error_code;
   g_exception.p_error_description := g_error_description;
   g_exception.p_entity_ref        := g_entity_ref;
   g_exception.p_entity_ref_id     := g_entity_ref_id;

   BEGIN
       XX_OM_GLOBAL_EXCEPTION_PKG.insert_exception(g_exception
                                                  ,x_errbuf
                                                  ,x_retcode
                                                 );
   END;    
END log_exceptions;

-- +===================================================================+
-- | Name  : Validate_Ord_Header_Proc                                  |
-- |                                                                   |
-- | Description:       This Procedure will be used to validate the    |
-- |                    Order Header record.                           |
-- |                                                                   |
-- | Parameters:        Order Header Record                            |
-- |                                                                   |
-- | Returns :          Status - 'S' for success and 'E' for error     |
-- |                    Error Message - if procedure errors out        |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Validate_Ord_Header_Proc (
                                    p_order_header_rec  IN OUT XX_OM_ORDER_HDR_REC_TYPE,
                                    x_status            OUT VARCHAR2,
                                    x_message           OUT VARCHAR2
                                   )
    
AS
    
    ln_header_id            oe_order_headers.header_id%TYPE;    
    lr_order_header_rec     XX_OM_ORDER_HDR_REC_TYPE;

BEGIN

    lr_order_header_rec := p_order_header_rec;
    
    x_status := 'S';
    
    --
    -- Validation for Order Number
    --
    BEGIN
    
        SELECT header_id
        INTO   ln_header_id
        FROM   oe_order_headers_all
        WHERE  order_number = lr_order_header_rec.order_number
        AND    org_id       = GN_ORG_ID;
        
    EXCEPTION
        
        WHEN NO_DATA_FOUND THEN
            ln_header_id := NULL;
            x_status     := 'E';
            x_message    := 'Order No ''' || lr_order_header_rec.order_number || ''' does not exist in Oracle.';
            
        WHEN OTHERS THEN
            ln_header_id := NULL;
            x_status     := 'E';
            x_message    := 'Unexpected error occurred while validating the Order No. ' || SQLERRM;
            
            g_entity_ref        := 'ORDER_NUMBER';
            g_entity_ref_id     := lr_order_header_rec.order_number;
            
            FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
            FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
            FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
            
            g_error_description:= FND_MESSAGE.GET;
            g_error_code       := 'ODP_OM_UNEXPECTED_ERR';
            
            log_exceptions;            
            
    END;
    
    lr_order_header_rec.header_id := ln_header_id;
    
    --
    -- Validation for Transaction Type
    --
    IF lr_order_header_rec.transaction_type NOT IN (GC_SHIP_CONF_TRX_TYPE, GC_HOLD_REL_TRX_TYPE) THEN
        x_status  := 'E';
        x_message := x_message || ', Transaction Type should contain a value either ''' || GC_SHIP_CONF_TRX_TYPE || ''' or ''' ||GC_HOLD_REL_TRX_TYPE || '''.';
    END IF;
    
    p_order_header_rec := lr_order_header_rec;
    
EXCEPTION

    WHEN OTHERS THEN
        x_status  := 'E';
        x_message := 'Unexpected error occurred in the procedure ''Validate_Ord_Header_Proc''. ' || SQLERRM;    
        
        g_entity_ref        := 'HEADER_ID';
        g_entity_ref_id     := ln_header_id;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := 'ODP_OM_UNEXPECTED_ERR';

        log_exceptions; 
 
END Validate_Ord_Header_Proc;


-- +===================================================================+
-- | Name  : Validate_Ord_Payments_Proc                                |
-- |                                                                   |
-- | Description:       This procedure will be used to validate the    |
-- |                    order pre-payment data.                        |
-- |                                                                   |
-- | Parameters:        p_order_payments_tbl - PL/SQL table            |
-- |                                                                   |
-- | Returns :          Status - 'S' for success and 'E' for error     |
-- |                    Error Message - if procedure errors out        |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Validate_Ord_Payments_Proc (
                                      p_header_id            IN NUMBER   
                                     ,p_order_payments_tbl   IN OUT XX_OM_ORDER_PAYMENTS_TBL
                                     ,x_status               OUT VARCHAR2
                                     ,x_message              OUT VARCHAR2
                                     ,x_ack_ord_pmts_tbl     OUT XX_OM_ACK_ORD_LINES_TBL) 
AS
    lc_status               VARCHAR2(1);
    lc_message              VARCHAR2(2000);
    ln_index                NUMBER;    
    ln_dummy                NUMBER;
    lc_ack_message          VARCHAR2(2000);
    
    ln_organization_id      org_organization_definitions.organization_id%type;
    ln_inv_item_id          mtl_system_items.inventory_item_id%type;
    
    lt_order_payments_tbl   XX_OM_ORDER_PAYMENTS_TBL;
    lt_ack_ord_pmts_tbl     XX_OM_ACK_ORD_LINES_TBL;
    
BEGIN

    lt_order_payments_tbl := p_order_payments_tbl;
    ln_index := 1;
    x_status := 'S';
    
    IF lt_order_payments_tbl.COUNT > 0 THEN
    
        FOR i IN lt_order_payments_tbl.FIRST..lt_order_payments_tbl.LAST 
        LOOP
        
            lc_status := 'S';
            lc_message := '';
            
            --
            -- Validation for Line Number
            --
            IF lt_order_payments_tbl(i).line_number IS NULL THEN
                
                lc_status := 'E';
                x_status := 'E';
                lc_message := lc_message || ' Payment''s Line Number should not be null.';
                
            ELSE                
            
                SELECT count(1)
                INTO   ln_dummy
                FROM   oe_payments
                WHERE  header_id = p_header_id
                AND    payment_number = lt_order_payments_tbl(i).line_number;
                
                IF lt_order_payments_tbl(i).authorization_code IS NULL 
                     AND  ln_dummy = 0 THEN
                     
                     lc_status := 'E';
                     x_status := 'E';
                     lc_message := lc_message || ' Payment should exist to update with the payment number '|| lt_order_payments_tbl(i).line_number || '.';
                
                END IF;

                IF lt_order_payments_tbl(i).authorization_code IS NOT NULL  
                    AND ln_dummy <> 0 THEN
                
                    lc_status  := 'E';
                    x_status := 'E';
                    lc_message := lc_message || ' Payment already exists with the payment number '|| lt_order_payments_tbl(i).line_number || '.';
                    
                END IF;
                
            END IF;

            --
            -- Validation for Payment Method
            --
            IF lt_order_payments_tbl(i).payment_method IS NULL THEN
            
                lc_status := 'E';
                x_status := 'E';
                lc_message := lc_message || ' Payment Method should not be null for Payment Number.';

            ELSE
            
                IF lt_order_payments_tbl(i).payment_method NOT IN ('CASH', 'CHECK', 'CREDIT_CARD', 'DIRECT_DEBIT') THEN

                    lc_status := 'E';
                    x_status := 'E';
                    lc_message := lc_message || ' Please enter a valid Payment Method.';
                    
                END IF;
            
            END IF;
            
            IF lt_order_payments_tbl(i).payment_method = 'CREDIT_CARD' THEN
                
                IF lt_order_payments_tbl(i).expiration_date IS NULL THEN
                
                    lc_status := 'E';
                    x_status := 'E';
                    lc_message := lc_message || ' Expiration Date is mandatory for Credit Card payments for Payment Number.';
                
                END IF;
                
                IF lt_order_payments_tbl(i).payment_details IS NULL THEN
                
                    lc_status := 'E';
                    x_status := 'E';
                    lc_message := lc_message || ' Payment Details (Credit Card Number) is mandatory for Credit Card payments for Payment Number.';
                
                END IF;
                
            END IF;
            
            IF lc_status = 'E' THEN                
                lt_ack_ord_pmts_tbl(ln_index).line_number   := lt_order_payments_tbl(i).line_number;
                lt_ack_ord_pmts_tbl(ln_index).error_message := lc_message;
                ln_index := ln_index + 1;
            END IF;            
            
        END LOOP;
        
    END IF;
    
    x_ack_ord_pmts_tbl := lt_ack_ord_pmts_tbl;
    
    p_order_payments_tbl := lt_order_payments_tbl;
    
        lc_ack_message := '';
    
        IF x_ack_ord_pmts_tbl.COUNT > 0 THEN
            FOR i IN x_ack_ord_pmts_tbl.FIRST..x_ack_ord_pmts_tbl.LAST
            LOOP
                lc_ack_message := lc_ack_message || ' Payment Line No-> ' || x_ack_ord_pmts_tbl(i).line_number || ': ' || x_ack_ord_pmts_tbl(i).error_message;
            END LOOP;
        END IF;
        
        x_message := '';
    
EXCEPTION

    WHEN OTHERS THEN
        x_status := 'E';
        x_message := ' Procedure Validate_Ord_Payments_Proc: Unexpected error occurred: ' || SUBSTR(SQLERRM, 255) || '.';
        
        g_entity_ref        := 'HEADER_ID';
        g_entity_ref_id     := p_header_id;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := 'ODP_OM_UNEXPECTED_ERR';

        log_exceptions;        

END Validate_Ord_Payments_Proc;

-- +===================================================================+
-- |        Name: Line_and_Payment_Proc                                |
-- |                                                                   |
-- | Description: This procedure calls the standard API                |
-- |              oe_order_pub.process_order to create lines or        |
-- |              payments.                                            |
-- |                                                                   |
-- | Parameters:  Header Id                                            |
-- |              p_order_lines_tbl - PL/SQL table                     |
-- |              p_header_payment_tbl - PL/SQL table                  |
-- |                                                                   |
-- | Returns :    Status - 'S' for success and 'E' for error           |
-- |              Error Message - if procedure errors out              |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Line_and_Payment_Proc (
                                 p_header_id             IN  NUMBER,
                                 p_order_lines_tbl       IN  oe_order_pub.line_tbl_type,
                                 p_header_payment_tbl    IN  oe_order_pub.header_payment_tbl_type,
                                 x_status                OUT VARCHAR2,
                                 x_message               OUT VARCHAR2
                                )

AS

    lc_return_status                VARCHAR2(1000)                              := NULL;
    ln_msg_count                    NUMBER                                      := 0;
    lc_msg_data                     VARCHAR2(4000)                              := NULL;
    
    ln_api_version_number           NUMBER                                      := 1.0;
    lc_init_msg_list                VARCHAR2(10)                                := FND_API.G_FALSE;
    lc_return_values                VARCHAR2(10)                                := FND_API.G_FALSE;
    lc_action_commit                VARCHAR2(10)                                := FND_API.G_FALSE;
    
    lr_header_rec                   oe_order_pub.header_rec_type                := oe_order_pub.g_miss_header_rec;    
    lr_old_header_rec               oe_order_pub.header_rec_type                := oe_order_pub.g_miss_header_rec;
    lr_header_val_rec               oe_order_pub.header_val_rec_type            := oe_order_pub.g_miss_header_val_rec;
    lr_old_header_val_rec           oe_order_pub.header_val_rec_type            := oe_order_pub.g_miss_header_val_rec;
        
    lt_header_adj_tbl               oe_order_pub.header_adj_tbl_type            := oe_order_pub.g_miss_header_adj_tbl;
    lt_old_header_adj_tbl           oe_order_pub.header_adj_tbl_type            := oe_order_pub.g_miss_header_adj_tbl;
    lt_header_adj_val_tbl           oe_order_pub.header_adj_val_tbl_type        := oe_order_pub.g_miss_header_adj_val_tbl;
    lt_old_header_adj_val_tbl       oe_order_pub.header_adj_val_tbl_type        := oe_order_pub.g_miss_header_adj_val_tbl;
    lt_header_price_att_tbl         oe_order_pub.header_price_att_tbl_type      := oe_order_pub.g_miss_header_price_att_tbl;
    lt_old_header_price_att_tbl     oe_order_pub.header_price_att_tbl_type      := oe_order_pub.g_miss_header_price_att_tbl;
    lt_header_adj_att_tbl           oe_order_pub.header_adj_att_tbl_type        := oe_order_pub.g_miss_header_adj_att_tbl;
    lt_old_header_adj_att_tbl       oe_order_pub.header_adj_att_tbl_type        := oe_order_pub.g_miss_header_adj_att_tbl;
    lt_header_adj_assoc_tbl         oe_order_pub.header_adj_assoc_tbl_type      := oe_order_pub.g_miss_header_adj_assoc_tbl;
    lt_old_header_adj_assoc_tbl     oe_order_pub.header_adj_assoc_tbl_type      := oe_order_pub.g_miss_header_adj_assoc_tbl;
    lt_header_scredit_tbl           oe_order_pub.header_scredit_tbl_type        := oe_order_pub.g_miss_header_scredit_tbl;
    lt_old_header_scredit_tbl       oe_order_pub.header_scredit_tbl_type        := oe_order_pub.g_miss_header_scredit_tbl;
    lt_header_scredit_val_tbl       oe_order_pub.header_scredit_val_tbl_type    := oe_order_pub.g_miss_header_scredit_val_tbl;
    lt_old_header_scredit_val_tbl   oe_order_pub.header_scredit_val_tbl_type    := oe_order_pub.g_miss_header_scredit_val_tbl;
    lt_line_tbl                     oe_order_pub.line_tbl_type                  := oe_order_pub.g_miss_line_tbl;
    lt_old_line_tbl                 oe_order_pub.line_tbl_type                  := oe_order_pub.g_miss_line_tbl;
    lt_line_val_tbl                 oe_order_pub.line_val_tbl_type              := oe_order_pub.g_miss_line_val_tbl;
    lt_old_line_val_tbl             oe_order_pub.line_val_tbl_type              := oe_order_pub.g_miss_line_val_tbl;
    lt_line_adj_tbl                 oe_order_pub.line_adj_tbl_type              := oe_order_pub.g_miss_line_adj_tbl;
    lt_old_line_adj_tbl             oe_order_pub.line_adj_tbl_type              := oe_order_pub.g_miss_line_adj_tbl;
    lt_line_adj_val_tbl             oe_order_pub.line_adj_val_tbl_type          := oe_order_pub.g_miss_line_adj_val_tbl;
    lt_old_line_adj_val_tbl         oe_order_pub.line_adj_val_tbl_type          := oe_order_pub.g_miss_line_adj_val_tbl;
    lt_line_price_att_tbl           oe_order_pub.line_price_att_tbl_type        := oe_order_pub.g_miss_line_price_att_tbl;
    lt_old_line_price_att_tbl       oe_order_pub.line_price_att_tbl_type        := oe_order_pub.g_miss_line_price_att_tbl;
    lt_line_adj_att_tbl             oe_order_pub.line_adj_att_tbl_type          := oe_order_pub.g_miss_line_adj_att_tbl;
    lt_old_line_adj_att_tbl         oe_order_pub.line_adj_att_tbl_type          := oe_order_pub.g_miss_line_adj_att_tbl;
    lt_line_adj_assoc_tbl           oe_order_pub.line_adj_assoc_tbl_type        := oe_order_pub.g_miss_line_adj_assoc_tbl;
    lt_old_line_adj_assoc_tbl       oe_order_pub.line_adj_assoc_tbl_type        := oe_order_pub.g_miss_line_adj_assoc_tbl;
    lt_line_scredit_tbl             oe_order_pub.line_scredit_tbl_type          := oe_order_pub.g_miss_line_scredit_tbl;
    lt_old_line_scredit_tbl         oe_order_pub.line_scredit_tbl_type          := oe_order_pub.g_miss_line_scredit_tbl;
    lt_line_scredit_val_tbl         oe_order_pub.line_scredit_val_tbl_type      := oe_order_pub.g_miss_line_scredit_val_tbl;
    lt_old_line_scredit_val_tbl     oe_order_pub.line_scredit_val_tbl_type      := oe_order_pub.g_miss_line_scredit_val_tbl;
    lt_lot_serial_tbl               oe_order_pub.lot_serial_tbl_type            := oe_order_pub.g_miss_lot_serial_tbl;
    lt_old_lot_serial_tbl           oe_order_pub.lot_serial_tbl_type            := oe_order_pub.g_miss_lot_serial_tbl;
    lt_lot_serial_val_tbl           oe_order_pub.lot_serial_val_tbl_type        := oe_order_pub.g_miss_lot_serial_val_tbl;
    lt_old_lot_serial_val_tbl       oe_order_pub.lot_serial_val_tbl_type        := oe_order_pub.g_miss_lot_serial_val_tbl;
    lt_action_request_tbl           oe_order_pub.request_tbl_type               := oe_order_pub.g_miss_request_tbl;
    lt_header_payment_tbl           oe_order_pub.header_payment_tbl_type        := oe_order_pub.g_miss_header_payment_tbl;
    lt_old_header_payment_tbl       oe_order_pub.header_payment_tbl_type;    
    lt_header_payment_val_tbl       oe_order_pub.header_payment_val_tbl_type;
    lt_old_header_payment_val_tbl   oe_order_pub.header_payment_val_tbl_type; 
    lt_line_payment_tbl             oe_order_pub.line_payment_tbl_type;
    lt_old_line_payment_tbl         oe_order_pub.line_payment_tbl_type;
    lt_line_payment_val_tbl         oe_order_pub.line_payment_val_tbl_type;
    lt_old_line_payment_val_tbl     oe_order_pub.line_payment_val_tbl_type;
    
       
BEGIN

    x_status := 'S';

    lt_header_payment_tbl   := p_header_payment_tbl;    
    lt_line_tbl             := p_order_lines_tbl;
    
    IF lt_line_tbl.COUNT > 0 OR lt_header_payment_tbl.COUNT > 0 THEN
        
        oe_order_pub.process_order (
                                     p_api_version_number           => ln_api_version_number
                                    ,p_init_msg_list                => lc_init_msg_list
                                    ,p_return_values                => lc_return_values
                                    ,p_action_commit                => lc_action_commit
                                    ,x_return_status                => lc_return_status
                                    ,x_msg_count                    => ln_msg_count
                                    ,x_msg_data                     => lc_msg_data
                                    ,p_header_rec                   => lr_header_rec
                                    ,p_old_header_rec               => lr_old_header_rec
                                    ,p_header_val_rec               => lr_header_val_rec
                                    ,p_old_header_val_rec           => lr_old_header_val_rec
                                    ,p_Header_Adj_tbl               => lt_Header_Adj_tbl    
                                    ,p_old_Header_Adj_tbl           => lt_old_Header_Adj_tbl
                                    ,p_Header_Adj_val_tbl           => lt_Header_Adj_val_tbl
                                    ,p_old_Header_Adj_val_tbl       => lt_old_Header_Adj_val_tbl
                                    ,p_Header_price_Att_tbl         => lt_Header_price_Att_tbl
                                    ,p_old_Header_Price_Att_tbl     => lt_old_Header_Price_Att_tbl
                                    ,p_Header_Adj_Att_tbl           => lt_Header_Adj_Att_tbl
                                    ,p_old_Header_Adj_Att_tbl       => lt_old_Header_Adj_Att_tbl
                                    ,p_Header_Adj_Assoc_tbl         => lt_Header_Adj_Assoc_tbl
                                    ,p_old_Header_Adj_Assoc_tbl     => lt_old_Header_Adj_Assoc_tbl
                                    ,p_Header_Scredit_tbl           => lt_Header_Scredit_tbl
                                    ,p_old_Header_Scredit_tbl       => lt_old_Header_Scredit_tbl
                                    ,p_Header_Scredit_val_tbl       => lt_Header_Scredit_val_tbl
                                    ,p_old_Header_Scredit_val_tbl   => lt_old_Header_Scredit_val_tbl
                                    ,p_Header_Payment_tbl           => lt_Header_Payment_tbl
                                    ,p_old_Header_Payment_tbl       => lt_old_Header_Payment_tbl
                                    ,p_Header_Payment_val_tbl       => lt_Header_Payment_val_tbl 
                                    ,p_old_Header_Payment_val_tbl   => lt_old_Header_Payment_val_tbl
                                    ,p_line_tbl                     => lt_line_tbl
                                    ,p_old_line_tbl                 => lt_old_line_tbl
                                    ,p_line_val_tbl                 => lt_line_val_tbl
                                    ,p_old_line_val_tbl             => lt_old_line_val_tbl
                                    ,p_Line_Adj_tbl                 => lt_Line_Adj_tbl      
                                    ,p_old_Line_Adj_tbl             => lt_old_Line_Adj_tbl
                                    ,p_Line_Adj_val_tbl             => lt_Line_Adj_val_tbl
                                    ,p_old_Line_Adj_val_tbl         => lt_old_Line_Adj_val_tbl
                                    ,p_Line_price_Att_tbl           => lt_Line_price_Att_tbl
                                    ,p_old_Line_Price_Att_tbl       => lt_old_Line_Price_Att_tbl
                                    ,p_Line_Adj_Att_tbl             => lt_Line_Adj_Att_tbl
                                    ,p_old_Line_Adj_Att_tbl         => lt_old_Line_Adj_Att_tbl
                                    ,p_Line_Adj_Assoc_tbl           => lt_Line_Adj_Assoc_tbl
                                    ,p_old_Line_Adj_Assoc_tbl       => lt_old_Line_Adj_Assoc_tbl
                                    ,p_Line_Scredit_tbl             => lt_Line_Scredit_tbl
                                    ,p_old_Line_Scredit_tbl         => lt_old_Line_Scredit_tbl
                                    ,p_Line_Scredit_val_tbl         => lt_Line_Scredit_val_tbl
                                    ,p_old_Line_Scredit_val_tbl     => lt_old_Line_Scredit_val_tbl
                                    ,p_Line_Payment_tbl             => lt_Line_Payment_tbl
                                    ,p_old_Line_Payment_tbl         => lt_old_Line_Payment_tbl
                                    ,p_Line_Payment_val_tbl         => lt_Line_Payment_val_tbl
                                    ,p_old_Line_Payment_val_tbl     => lt_old_Line_Payment_val_tbl
                                    ,p_Lot_Serial_tbl               => lt_Lot_Serial_tbl
                                    ,p_old_Lot_Serial_tbl           => lt_old_Lot_Serial_tbl
                                    ,p_Lot_Serial_val_tbl           => lt_Lot_Serial_val_tbl
                                    ,p_old_Lot_Serial_val_tbl       => lt_old_Lot_Serial_val_tbl
                                    ,p_action_request_tbl           => lt_action_request_tbl
                                    ,x_header_rec                   => lr_header_rec
                                    ,x_header_val_rec               => lr_header_val_rec
                                    ,x_Header_Adj_tbl               => lt_Header_Adj_tbl
                                    ,x_Header_Adj_val_tbl           => lt_Header_Adj_val_tbl
                                    ,x_Header_price_Att_tbl         => lt_Header_price_Att_tbl
                                    ,x_Header_Adj_Att_tbl           => lt_Header_Adj_Att_tbl
                                    ,x_Header_Adj_Assoc_tbl         => lt_Header_Adj_Assoc_tbl
                                    ,x_Header_Scredit_tbl           => lt_Header_Scredit_tbl
                                    ,x_Header_Scredit_val_tbl       => lt_Header_Scredit_val_tbl
                                    ,x_Header_Payment_tbl           => lt_Header_Payment_tbl
                                    ,x_Header_Payment_val_tbl       => lt_Header_Payment_val_tbl
                                    ,x_line_tbl                     => lt_line_tbl
                                    ,x_line_val_tbl                 => lt_line_val_tbl
                                    ,x_Line_Adj_tbl                 => lt_Line_Adj_tbl
                                    ,x_Line_Adj_val_tbl             => lt_Line_Adj_val_tbl
                                    ,x_Line_price_Att_tbl           => lt_Line_price_Att_tbl
                                    ,x_Line_Adj_Att_tbl             => lt_Line_Adj_Att_tbl
                                    ,x_Line_Adj_Assoc_tbl           => lt_Line_Adj_Assoc_tbl
                                    ,x_Line_Scredit_tbl             => lt_Line_Scredit_tbl
                                    ,x_Line_Scredit_val_tbl         => lt_Line_Scredit_val_tbl
                                    ,x_Line_Payment_tbl             => lt_Line_Payment_tbl
                                    ,x_Line_Payment_val_tbl         => lt_Line_Payment_val_tbl
                                    ,x_Lot_Serial_tbl               => lt_Lot_Serial_tbl
                                    ,x_Lot_Serial_val_tbl           => lt_Lot_Serial_val_tbl
                                    ,x_action_request_tbl           => lt_action_request_tbl
                                    ,p_rtrim_data                   => 'N'
                                   );

        COMMIT;        
    
        IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN
            x_status := 'S';
        ELSE
            
            x_status := 'E';
            
            IF ln_msg_count = 1 THEN
                lc_msg_data := SUBSTR(OE_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE), 1, 255);
            ELSE                           
                FOR i IN 1..ln_msg_count - 1
                LOOP
                    lc_msg_data := lc_msg_data || ', ' || SUBSTR(OE_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE), 1, 255);
                END LOOP;
            END IF;         

        END IF;

    END IF;
    
    COMMIT;
    
    x_message := 'Procedure Line_and_Payment_Proc: ' || lc_msg_data;
    
EXCEPTION
    
    WHEN OTHERS THEN
        x_status := 'E';
        x_message := 'Procedure Line_and_Payment_Proc: Unexpected error occurred: ' || SQLERRM;    
        
        g_entity_ref        := 'HEADER_ID';
        g_entity_ref_id     := p_header_id;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := 'ODP_OM_UNEXPECTED_ERR';

        log_exceptions;
        
END Line_and_Payment_Proc;

-- +====================================================================+
-- | Name  : Insert_Update_Payment_Proc                                 |
-- |                                                                    |
-- | Description: This procedure creates/Update the pre-payment at order|
-- |              header level and processes it. This also releases the |
-- |              hold "Pending Process Payment Hold", if it is applied.|
-- |                                                                    |
-- | Parameters:        p_header_id, p_order_payments_tbl               |
-- |                                                                    |
-- | Returns :          x_status                                        |
-- |                    x_message                                       |
-- +====================================================================+

PROCEDURE Insert_update_Payment_Proc(
                                     p_header_id             IN     NUMBER,
                                     p_order_payments_tbl    IN     XX_OM_ORDER_PAYMENTS_TBL,
                                     x_status                OUT    VARCHAR2,
                                     x_message               OUT    VARCHAR2,
                                     x_ack_int_pmts_tbl      IN OUT XX_OM_ACK_ORD_LINES_TBL
                                    )
AS

    lt_order_payments_tbl   XX_OM_ORDER_PAYMENTS_TBL;
    lt_order_lines_tbl      oe_order_pub.line_tbl_type;
    lt_header_payment_tbl   oe_order_pub.header_payment_tbl_type := oe_order_pub.g_miss_header_payment_tbl;
    lt_order_holds_tbl      oe_holds_pvt.order_tbl_type;
    lc_receipt_method_name  VARCHAR2(240);
    ln_receipt_method_id    NUMBER;
    ln_header_id            NUMBER;
    ln_hold_id              NUMBER;
    ln_total_amount         NUMBER;
    ln_total_prepaid_amount NUMBER;
    lc_status               VARCHAR2(20);
    ln_msg_count            NUMBER;
    lc_msg_data             VARCHAR2(2000);
    lc_message              VARCHAR2(2000);
    
    lc_prepmt_status        VARCHAR2(20);
    lc_prepmt_message       VARCHAR2(2000);
    lc_procpmt_status       VARCHAR2(20);
    lc_propmt_msg_data      VARCHAR2(2000);
    lc_relhold_status       VARCHAR2(20);
    lc_relhold_msg_data     VARCHAR2(2000);
    ln_line_number          NUMBER;
    
BEGIN

    x_status := 'S';
    
    lt_order_payments_tbl := p_order_payments_tbl;
    ln_header_id          := p_header_id;
    
    -- Profile Option-> OM: Payment method for Credit Card Transactions
    ln_receipt_method_id := FND_PROFILE.VALUE('ONT_RECEIPT_METHOD_ID'); -- It returns Receipt_Method_Id
    
    --
    -- Populating Oe_Order_Pub.Header_Payment_Tbl
    --
    
    IF lt_order_payments_tbl.COUNT > 0 THEN
    
        FOR i IN lt_order_payments_tbl.FIRST..lt_order_payments_tbl.LAST
        LOOP
        
            IF lt_order_payments_tbl(i).authorization_code IS NULL THEN
            
                ln_line_number := lt_order_payments_tbl(i).line_number;
                -- Update statement
                BEGIN
                    
                    UPDATE oe_payments 
                    SET    payment_amount   = lt_order_payments_tbl(i).payment_amount,
                           last_update_date = SYSDATE
                    WHERE  header_id        = p_header_id
                    AND    payment_number   = ln_line_number;
            
                    COMMIT;
                END;
                
                OE_PrePayment_PVT.Process_Payments (
                                                    p_header_id         => ln_header_id
                                                    ,p_calling_action    => NULL
                                                    ,p_amount            => NULL
                                                    ,p_delayed_request   => 'N'
                                                    ,x_msg_count         => ln_msg_count
                                                    ,x_msg_data          => lc_propmt_msg_data
                                                    ,x_return_status     => lc_procpmt_status
                                                   );
                           
                COMMIT;   
                
                IF lc_procpmt_status = FND_API.G_RET_STS_SUCCESS THEN
                
                    lc_procpmt_status := 'S';
                    lc_propmt_msg_data := '';
                
                ELSE
                
                    lc_procpmt_status := 'E';
                
                    IF ln_msg_count = 1 THEN
                        lc_propmt_msg_data := SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE), 1, 255);
                    ELSE                           
                        FOR p IN 1..ln_msg_count - 1
                        LOOP
                            lc_propmt_msg_data := lc_propmt_msg_data || ', ' || SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE), 1, 255);
                            x_ack_int_pmts_tbl(i).error_message := SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE), 1, 255);
                        END LOOP;
                    END IF;         
                
                END IF;  -- lc_procpmt_status = FND_API.G_RET_STS_SUCCESS
                        
                IF lc_procpmt_status = 'S' THEN

                     --
                     -- Get the sum of Prepaid Amount of the Order
                     --
                    SELECT NVL(SUM(OP.prepaid_amount), 0)
                    INTO   ln_total_prepaid_amount
                    FROM   oe_payments OP
                    WHERE  OP.header_id = ln_header_id;

                    --
                    -- Get the Total Amount of the Order (Sub Total + Tax Total + Freight)
                    --     
                    ln_total_amount := NVL(oe_oe_totals_summary.prt_order_total(ln_header_id),0);

                    IF ln_total_prepaid_amount = ln_total_amount THEN

                        SELECT hold_id
                        INTO   ln_hold_id
                        FROM   oe_hold_definitions
                        WHERE  name = 'Pending Process Payment Hold';

                        --
                        -- Calling the standard API to release the payment hold
                        --
                        lt_order_holds_tbl(1).header_id := ln_header_id;      

                        OE_Holds_PUB.Release_Holds (
                                                     p_api_version          => 1.0
                                                    ,p_order_tbl            => lt_order_holds_tbl
                                                    ,p_hold_id              => ln_hold_id
                                                    ,p_release_reason_code  => 'POS_HOLD_RELEASE'      -- Email from Milind on 12-Feb-2007
                                                    ,p_release_comment      => 'Hold released by POS.'
                                                    ,x_return_status        => lc_relhold_status
                                                    ,x_msg_count            => ln_msg_count
                                                    ,x_msg_data             => lc_relhold_msg_data
                                                    );

                        COMMIT;    

                        IF lc_relhold_status = FND_API.G_RET_STS_SUCCESS THEN
    
                           lc_relhold_status := 'S';
                           lc_relhold_msg_data := '';
 
                        ELSE

                            lc_relhold_status := 'E';

                            IF ln_msg_count = 1 THEN
                              lc_relhold_msg_data := SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE), 1, 255);
                            ELSE                           
                              FOR p IN 1..ln_msg_count - 1
                                LOOP
                                 lc_relhold_msg_data := lc_relhold_msg_data || ', ' || SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE), 1, 255);
                                 x_ack_int_pmts_tbl(i).error_message := SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE), 1, 255);
                                END LOOP;
                            END IF;    -- ln_msg_count     

                         END IF;   -- lc_relhold_status = FND_API.G_RET_STS_SUCCESS                     

                    END IF; -- End of IF ln_total_prepaid_amount = ln_total_amount THEN

                END IF; -- End of IF lc_procpmt_status = 'S' THEN

                IF  lc_procpmt_status = 'E' OR lc_relhold_status <> FND_API.G_RET_STS_SUCCESS THEN

                    x_status  := 'E';
                    x_message := 'Procedure Insert_Payment_Proc: ' || lc_prepmt_message || ', ' || lc_propmt_msg_data || ', ' || lc_relhold_msg_data;

                ELSE

                    x_status  := 'S';
                    x_message := '';

                END IF;                   

            ELSE  -- payment auth code is not null

                lt_header_payment_tbl(i).created_by                      := GN_USER_ID;
                lt_header_payment_tbl(i).creation_date                   := SYSDATE;
                lt_header_payment_tbl(i).last_updated_by                 := GN_USER_ID;
                lt_header_payment_tbl(i).last_update_date                := SYSDATE;

                lt_header_payment_tbl(i).payment_collection_event        := 'PREPAY';     
                lt_header_payment_tbl(i).payment_level_code              := 'ORDER';          
                lt_header_payment_tbl(i).operation                       := OE_GLOBALS.G_OPR_CREATE;
                lt_header_payment_tbl(i).defer_payment_processing_flag   := 'N';
                lt_header_payment_tbl(i).receipt_method_id               := ln_receipt_method_id;

                lt_header_payment_tbl(i).header_id                       := ln_header_id;
                lt_header_payment_tbl(i).payment_number                  := lt_order_payments_tbl(i).line_number;
                lt_header_payment_tbl(i).payment_type_code               := lt_order_payments_tbl(i).payment_method;  -- Credit Card, Cash, Check

                IF lt_order_payments_tbl(i).payment_method = 'CASH' THEN

                    NULL;

                ELSIF lt_order_payments_tbl(i).payment_method = 'CHECK' THEN
    
                    lt_header_payment_tbl(i).check_number := lt_order_payments_tbl(i).payment_details;

                ELSIF lt_order_payments_tbl(i).payment_method = 'CREDIT_CARD' THEN

                    lt_header_payment_tbl(i).credit_card_number             := lt_order_payments_tbl(i).payment_details;     -- This will be the Credit Card Number or Check Number or Money Order Number
                    lt_header_payment_tbl(i).credit_card_expiration_date    := lt_order_payments_tbl(i).expiration_date;     -- This will be the Expiration Date of Credit Card. This field is required only for Credit Card payments
                    lt_header_payment_tbl(i).credit_card_holder_name        := lt_order_payments_tbl(i).acct_holder_name;  
                    lt_header_payment_tbl(i).credit_card_code               := lt_order_payments_tbl(i).payment_instrument;  -- Need to check it...Type of Card for Credit Cards and Gift Cards (Ex. Visa, Master, or Office Depot Gift Card)
                    lt_header_payment_tbl(i).credit_card_approval_code      := lt_order_payments_tbl(i).authorization_code;  -- We need NOT it. I tested it.            

                ELSIF lt_order_payments_tbl(i).payment_method = 'DIRECT_DEBIT' THEN

                    NULL;

                    -- At this point of time, we can ignore 'Account Number' and 'Routing Number'. Email from Milind on 01-Feb-2007
    
                    -- We don't need it lt_header_payment_tbl(1).payment_... := p_order_payments_tbl(i).account_number;  -- 
                    -- We don't need it lt_header_payment_tbl(1).payment_... := p_order_payments_tbl(i).routing_number;  --

                    -- In case of DIRECT_DEBIT, we need to store BANK_ACCOUNT_ID in Payment_Trx_Id
                    -- select ba.bank_account_num into l_bank_account_number
                    -- from ap_bank_accounts ba
                    -- where ba.bank_account_id = l_bank_account_id;

                END IF;

                lt_header_payment_tbl(i).payment_amount := lt_order_payments_tbl(i).payment_amount;

            END IF;

        END LOOP;
    
        IF lt_header_payment_tbl.COUNT > 0 THEN

            --
            -- Calling procedure Process_Order_Proc to insert the prepayment
            --
            Line_and_Payment_Proc(
                                  p_header_id             => ln_header_id,
                                  p_order_lines_tbl       => lt_order_lines_tbl,
                                  p_header_payment_tbl    => lt_header_payment_tbl,
                                  x_status                => lc_prepmt_status,
                                  x_message               => lc_prepmt_message
                                 );
    
            IF lc_prepmt_status = 'E' THEN
                lc_prepmt_message := 'Error occured while entering the payment: ' || lc_prepmt_message;
            END IF;            
    
            IF lc_prepmt_status = 'S' THEN
    
                --
                -- Calling the standard API to process the prepayment
                --
                OE_PrePayment_PVT.Process_Payments (
                                                    p_header_id         => ln_header_id
                                                   ,p_calling_action    => NULL
                                                   ,p_amount            => NULL
                                                   ,p_delayed_request   => 'N'
                                                   ,x_msg_count         => ln_msg_count
                                                   ,x_msg_data          => lc_propmt_msg_data
                                                   ,x_return_status     => lc_procpmt_status
                                                   );
        
                IF lc_procpmt_status = FND_API.G_RET_STS_SUCCESS THEN

                    lc_procpmt_status := 'S';
                    lc_propmt_msg_data := '';
    
                ELSE

                    lc_procpmt_status := 'E';

                    IF ln_msg_count = 1 THEN
                        lc_propmt_msg_data := SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE), 1, 255);
                    ELSE                           
                        FOR i IN 1..ln_msg_count - 1
                        LOOP
                            lc_propmt_msg_data := lc_propmt_msg_data || ', ' || SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE), 1, 255);
                            x_ack_int_pmts_tbl(i).error_message := SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE), 1, 255);                            
                        END LOOP;
                    END IF;         
    
                END IF;

                IF lc_procpmt_status = 'S' THEN

                    --
                    -- Get the sum of Prepaid Amount of the Order
                    --
                    SELECT NVL(SUM(OP.prepaid_amount), 0)
                    INTO   ln_total_prepaid_amount
                    FROM   oe_payments OP
                    WHERE  OP.header_id = ln_header_id;

                    --
                    -- Get the Total Amount of the Order (Sub Total + Tax Total + Freight)
                    --     
                    ln_total_amount := NVL(oe_oe_totals_summary.prt_order_total(ln_header_id),0);
        
                    IF ln_total_prepaid_amount = ln_total_amount THEN
        
                        SELECT hold_id
                        INTO   ln_hold_id
                        FROM   oe_hold_definitions
                        WHERE  name = 'Pending Process Payment Hold';

                        --
                        -- Calling the standard API to release the payment hold
                        --
                        lt_order_holds_tbl(1).header_id := ln_header_id;
        
                        OE_Holds_PUB.Release_Holds (
                                                    p_api_version          => 1.0
                                                   ,p_order_tbl            => lt_order_holds_tbl
                                                   ,p_hold_id              => ln_hold_id
                                                   ,p_release_reason_code  => 'POS_HOLD_RELEASE'      -- Email from Milind on 12-Feb-2007
                                                   ,p_release_comment      => 'Hold released by POS.'
                                                   ,x_return_status        => lc_relhold_status
                                                   ,x_msg_count            => ln_msg_count
                                                   ,x_msg_data             => lc_relhold_msg_data
                                                   );
    
                        IF lc_relhold_status = FND_API.G_RET_STS_SUCCESS THEN
    
                            lc_relhold_status := 'S';
                            lc_relhold_msg_data := '';
            
                        ELSE
    
                            lc_relhold_status := 'E';
        
                            IF ln_msg_count = 1 THEN
                                lc_relhold_msg_data := SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE), 1, 255);
                            ELSE                           
                                FOR i IN 1..ln_msg_count - 1
                                LOOP
                                    lc_relhold_msg_data := lc_relhold_msg_data || ', ' || SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE), 1, 255);
                                    x_ack_int_pmts_tbl(i).error_message := SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE), 1, 255);                                    
                                END LOOP;
                            END IF;         
        
                        END IF;                        

                    END IF; -- End of IF ln_total_prepaid_amount = ln_total_amount THEN

                END IF; -- End of IF lc_procpmt_status = 'S' THEN

            END IF; -- End of IF lc_prepmt_status = 'S' THEN

            IF lc_prepmt_status = 'E' OR lc_procpmt_status = 'E' OR lc_relhold_status <> FND_API.G_RET_STS_SUCCESS THEN

                x_status  := 'E';
                x_message := 'Procedure Insert_Payment_Proc: ' || lc_prepmt_message || ', ' || lc_propmt_msg_data || ', ' || lc_relhold_msg_data;
    
            ELSE
    
                x_status  := 'S';
                x_message := '';
    
            END IF;            

        END IF; -- End of IF lt_header_payment_tbl.COUNT > 0 THEN
    
    END IF;
    
EXCEPTION
    
    WHEN OTHERS THEN
        x_status  := 'E';
        x_message := 'Procedure Insert_Payment_Proc: Unexpected error occurred: ' || SQLERRM;
        
        g_entity_ref        := 'HEADER_ID';
        g_entity_ref_id     := p_header_id;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := 'ODP_OM_UNEXPECTED_ERR';

        log_exceptions;        

END Insert_update_Payment_Proc;

-- +===================================================================+
-- | Name  : Update_POD_Proc                                           |
-- |                                                                   |
-- | Description: This procedure is used to update the Proof of        |
-- |              Delivery in the attribute10 of table OE_ORDER_LINES. |
-- |                                                                   |
-- | Parameters: p_header_id, p_delivery_id, p_pos_transaction_num     |
-- |                                                                   |
-- | Returns: x_status, x_message                                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE Update_POD_Proc(
                          p_header_id             IN  NUMBER,
                          p_delivery_id           IN  NUMBER,
                          p_pos_transaction_num   IN  VARCHAR2,
                          x_status                OUT VARCHAR2,
                          x_message               OUT VARCHAR2
                         )
AS
    -- 
    -- Cursor to get the Source Line Ids of the delivery
    --
    CURSOR lcu_get_source_line_ids 
    IS 
    SELECT  WDD.source_line_id
    FROM    wsh_delivery_details     WDD
           ,wsh_delivery_assignments WDA
    WHERE   WDD.delivery_detail_id = WDA.delivery_detail_id
    AND     WDA.delivery_id        = p_delivery_id 
    AND     WDD.source_header_id   = p_header_id;
    
BEGIN

    x_status := 'S';
    x_message := '';
    
    FOR source_line_ids_rec IN lcu_get_source_line_ids 
    LOOP

        BEGIN

            UPDATE oe_order_lines OOL
            SET    OOL.attribute10      = p_pos_transaction_num  -- As per email by Milind on 30-Jan-2007
                  ,OOL.last_updated_by  = GN_USER_ID
                  ,OOL.last_update_date = SYSDATE
            WHERE  OOL.line_id          = source_line_ids_rec.source_line_id;
            
            COMMIT;    

        EXCEPTION

            WHEN OTHERS THEN
                x_status := 'E';
                x_message := 'Procedure Update_POD_Proc: Unexpected error occurred while updating the POD detail in OE_ORDER_LINES.';
        END;

    END LOOP;
    
EXCEPTION

    WHEN OTHERS THEN
        x_status  := 'E';
        x_message := 'Procedure Update_POD_Proc: Unexpected error occurred: ' || SUBSTR(SQLERRM, 255) || '.'; 
        
        g_entity_ref        := 'HEADER_ID';
        g_entity_ref_id     := p_header_id;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := 'ODP_OM_UNEXPECTED_ERR';

        log_exceptions;          

END Update_POD_Proc;

-- +===================================================================+
-- | Name  : Ship_Confirm_Proc                                         |
-- |                                                                   |
-- | Description: This procedure calls the standard API                |
-- |              WSH_DELIVERIES_PUB.DELIVERY_ACTION to do the Ship    |
-- |              Confirm.                                             |
-- |                                                                   |
-- | Parameters: p_delivery_id, p_delivery_name                        |
-- |                                                                   |
-- | Returns:    x_status, x_message                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE Ship_Confirm_Proc(
                            p_delivery_id           IN  NUMBER,
                            p_delivery_name         IN  NUMBER,
                            x_status                OUT VARCHAR2,
                            x_message               OUT VARCHAR2
                           )
AS
    ln_api_version          NUMBER          := 1.0;
    lc_init_msg_list        VARCHAR2(10)    := FND_API.G_FALSE;
    lc_return_status        VARCHAR2(1000)  := NULL;
    ln_msg_count            NUMBER          := 0;
    lc_msg_data             VARCHAR2(4000)  := NULL;

    lc_delivery_name        VARCHAR2(100);
    ln_delivery_id          NUMBER;
    
    ln_trip_id              NUMBER;
    lc_trip_name            VARCHAR2(100);
    
BEGIN
    
    ln_delivery_id   := p_delivery_id;
    lc_delivery_name := p_delivery_name;
    
    x_status := 'S';
    
    WSH_DELIVERIES_PUB.DELIVERY_ACTION(p_api_version_number     =>  ln_api_version
                                      ,p_init_msg_list          =>  lc_init_msg_list
                                      ,x_return_status          =>  lc_return_status
                                      ,x_msg_count              =>  ln_msg_count
                                      ,x_msg_data               =>  lc_msg_data
                                      ,p_action_code            =>  'CONFIRM'
                                      ,p_delivery_id            =>  ln_delivery_id
                                      ,p_delivery_name          =>  lc_delivery_name 
                                      ,x_trip_id                =>  ln_trip_id
                                      ,x_trip_name              =>  lc_trip_name
                                      );
                                      
    COMMIT;
    
    IF lc_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN
        x_status := 'S';
    ELSIF lc_return_status = WSH_UTIL_CORE.G_RET_STS_ERROR THEN
        IF ln_msg_count = 1 THEN
            lc_msg_data := SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE), 1, 512);
        ELSE                           
            FOR i IN 1..ln_msg_count - 1
            LOOP
                lc_msg_data := lc_msg_data || ', ' || SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE), 1, 512);
            END LOOP;
        END IF;         
        x_message := 'Procedure Ship_Confirm_Proc: ' || lc_msg_data || '.';
        x_status := 'E';        
        
    END IF;
    
EXCEPTION
    
    WHEN OTHERS THEN
    
        x_status  := 'E';
        x_message := 'Procedure Ship_Confirm_Proc: Unexpected error occurred: ' || SUBSTR(SQLERRM, 255) || '.';  
        
        g_entity_ref        := 'DELIVERY_ID';
        g_entity_ref_id     := p_delivery_id;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := 'ODP_OM_UNEXPECTED_ERR';

        log_exceptions;        

END Ship_Confirm_Proc;

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
                                    x_order_lines_tbl_out   OUT XX_OM_ACK_ORD_LINES_TBL,
                                    x_status                OUT VARCHAR2,
                                    x_transaction_date      OUT VARCHAR2,
                                    x_message               OUT VARCHAR2
                                   )

AS
    ln_order_number         NUMBER;
    lc_status               VARCHAR2(20);
    lc_tot_message          VARCHAR2(4000);
    lc_message              VARCHAR2(4000);
    lc_hdr_msg              VARCHAR2(4000);
    
    --lc_line_status          VARCHAR2(20);    
    lc_pmt_status           VARCHAR2(20);
    --lc_pr_ln_status         VARCHAR2(20);
    lc_pr_pmt_status        VARCHAR2(20);
    lc_pod_status           VARCHAR2(20);
    lc_hdr_status           VARCHAR2(20);
    lc_ship_status          VARCHAR2(20);
    
    lc_hdr_message          VARCHAR2(4000);
    --lc_line_message         VARCHAR2(4000);
    lc_pmt_message          VARCHAR2(4000);
    --lc_pr_ln_message        VARCHAR2(4000);
    lc_pr_pmt_message       VARCHAR2(4000);
    lc_pod_message          VARCHAR2(4000);
    lc_ship_message         VARCHAR2(4000);

    lr_order_header_rec     XX_OM_ORDER_HDR_REC_TYPE;
    lt_order_lines_tbl      XX_OM_ORDER_LINES_TBL;
    lt_order_payments_tbl   XX_OM_ORDER_PAYMENTS_TBL;
    lt_ack_ord_lines_tbl    XX_OM_ACK_ORD_LINES_TBL;
    lt_ack_ord_pmts_tbl     XX_OM_ACK_ORD_LINES_TBL;
    lt_ack_int_pmts_tbl     XX_OM_ACK_ORD_LINES_TBL;
    
    lc_ackpmt  varchar2(4000);

    -- 
    -- Cursor to get the Delivery Ids of an order
    --
    CURSOR lcu_get_delivery_ids (
        p_header_id     NUMBER
    )    
    IS 
    SELECT WND.delivery_id, WND.name
    FROM   wsh_new_deliveries  WND
    WHERE  EXISTS (SELECT 'X'
                   FROM   wsh_delivery_details     WDD,
                          wsh_delivery_assignments WDA
                   WHERE  WDA.delivery_id        = WND.delivery_id 
                   AND    WDD.delivery_detail_id = WDA.delivery_detail_id
                   AND    WDD.source_header_id   = p_header_id
                  );

BEGIN

    x_status := 'S';
    
    BEGIN
        SELECT user_id
        INTO   GN_USER_ID
        FROM   fnd_user
        WHERE  user_name = GC_USER_NAME;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            GN_USER_ID := NULL;
            x_status := 'E';
            x_message := 'User ''' || GC_USER_NAME || ''' doesn''t exist in Oracle.';
        WHEN OTHERS THEN
            GN_USER_ID := NULL;
            x_status := 'E';
            x_message := 'Unexpected error occurred while getting user id of user ''' || GC_USER_NAME || ''': ' || SQLERRM || '.';
    END;
    
    BEGIN
        SELECT responsibility_id
              ,application_id
        INTO   GN_RESP_ID
              ,GN_RESP_APP_ID
        FROM   fnd_responsibility_vl        
        WHERE  responsibility_name = GC_RESP_NAME;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            GN_RESP_ID := NULL;
            GN_RESP_APP_ID := NULL;
            x_status := 'E';
            x_message := 'Responsibility ''' || GC_RESP_NAME || ''' doesn''t exist in Oracle.';
        WHEN OTHERS THEN
            GN_RESP_ID := NULL;
            GN_RESP_APP_ID := NULL;
            x_status := 'E';
            x_message := 'Unexpected error occurred while getting responsibilty id of responsibilty ''' || GC_RESP_NAME || ''': ' || SQLERRM || '.';
    END;
    
    IF (GN_USER_ID IS NOT NULL) AND (GN_RESP_ID IS NOT NULL) AND (GN_RESP_APP_ID IS NOT NULL) THEN
    
        FND_GLOBAL.APPS_INITIALIZE(GN_USER_ID, GN_RESP_ID, GN_RESP_APP_ID);
        
        GN_ORG_ID := FND_GLOBAL.ORG_ID;
        
        lr_order_header_rec     := p_order_header_rec;
        lt_order_lines_tbl      := p_order_lines_tbl;
        lt_order_payments_tbl   := p_order_payments_tbl;
        
        ------------------------------
        -- Call validation procedure
        ------------------------------
       
        Validate_Ord_Header_Proc(
                                 p_order_header_rec  => lr_order_header_rec
                                ,x_status            => lc_hdr_status
                                ,x_message           => lc_hdr_message
                                );
            
        lt_ack_ord_lines_tbl(1).error_message :=  lc_hdr_message;   
            
        IF lc_hdr_status = 'S' THEN

            IF p_order_payments_tbl.COUNT > 0 THEN
            
                ------------------------------
                -- Call validation procedure
                ------------------------------           
                Validate_Ord_Payments_Proc(
                                           p_header_id            => lr_order_header_rec.header_id
                                          ,p_order_payments_tbl   => lt_order_payments_tbl
                                          ,x_status               => lc_pmt_status
                                          ,x_message              => lc_pmt_message
                                          ,x_ack_ord_pmts_tbl     => lt_ack_ord_pmts_tbl
                                          );
                                          
            END IF;

           -- altered the code to include update payment functionality by shashi --
            
            IF lc_pmt_status = 'S' AND lr_order_header_rec.transaction_type IN (GC_SHIP_CONF_TRX_TYPE, GC_HOLD_REL_TRX_TYPE) THEN

                Insert_update_Payment_Proc(
                                           p_header_id             => lr_order_header_rec.header_id
                                          ,p_order_payments_tbl    => lt_order_payments_tbl
                                          ,x_status                => lc_pr_pmt_status
                                          ,x_message               => lc_pr_pmt_message
                                          ,x_ack_int_pmts_tbl      => lt_ack_int_pmts_tbl
                                          );
                                          
            END IF;

            IF lc_pr_pmt_status = 'S' AND lr_order_header_rec.transaction_type = GC_SHIP_CONF_TRX_TYPE THEN
                FOR delivery_ids_rec IN lcu_get_delivery_ids (p_header_id => lr_order_header_rec.header_id)
                LOOP

                    Update_POD_Proc(
                                    p_header_id           => lr_order_header_rec.header_id
                                   ,p_delivery_id         => delivery_ids_rec.delivery_id
                                   ,p_pos_transaction_num => lr_order_header_rec.pos_transaction_num
                                   ,x_status              => lc_pod_status
                                   ,x_message             => lc_pod_message
                                   );
                        
                    IF lc_pod_status = 'S' THEN

                        Ship_Confirm_Proc(
                                          p_delivery_id     => delivery_ids_rec.delivery_id
                                         ,p_delivery_name   => delivery_ids_rec.name
                                         ,x_status          => lc_ship_status
                                         ,x_message         => lc_ship_message
                                         );
                            
                    END IF;

                END LOOP;

            END IF;

        END IF;

        x_order_lines_tbl_out := lt_ack_ord_lines_tbl;

        IF lc_hdr_status = 'E' -- OR lc_line_status = 'E' -- Need to remove it for legacy
            OR lc_pmt_status = 'E' -- OR lc_pr_ln_status = 'E' -- Need to remove it for legacy
                OR lc_pr_pmt_status = 'E' 
                    OR lc_pod_status = 'E' 
                        OR lc_ship_status = 'E' THEN

                            x_status := 'E';
                            
                            x_message := lc_hdr_message ||'^ ' -- || lc_line_message || '^ '  -- Need to remove it for legacy
                                            || lc_pmt_message || '^ ' -- || lc_pr_ln_message || '^ ' -- Need to remove it for legacy
                                                || lc_pr_pmt_message || '^ ' || lc_pod_message || '^ ' || lc_ship_message; 
                                                
            x_order_lines_tbl_out(1).error_message := x_message;  

        END IF;    
        
        x_transaction_date := TO_CHAR(SYSDATE, 'DD-MON-RRRR: HH:MI:SS AM');

        p_order_number := p_order_header_rec.order_number;
        
        IF x_status = 'S' THEN
            x_status := 'SUCCESS';
            x_order_lines_tbl_out(1).error_message := 'SUCCESS';
        ELSIF x_status = 'E' THEN
            x_status := 'FAILURE';
        END IF;
        
        IF lt_ack_ord_pmts_tbl.COUNT > 0 then 
        
            FOR i in lt_ack_ord_pmts_tbl.FIRST..lt_ack_ord_pmts_tbl.LAST LOOP

            IF lt_ack_int_pmts_tbl.count > 0 THEN 
                FOR i in lt_ack_int_pmts_tbl.FIRST..lt_ack_int_pmts_tbl.LAST LOOP
                   lc_ackpmt := lc_ackpmt || lt_ack_int_pmts_tbl(i).error_message;
                END LOOP;
            END IF;

            x_order_lines_tbl_out(i).error_message  := lc_hdr_message || lc_ackpmt || lt_ack_ord_pmts_tbl(i).error_message || lc_ship_message;

            END LOOP;
        END IF;

    ELSE
        x_status := 'FAILURE';
        x_message := 'Either user ''' || GC_USER_NAME || ''' or responsibility ''' || GC_RESP_NAME || ''' doesn''t exist in Oracle.';

        g_entity_ref           := 'ORDER_NUMBER';        
        g_entity_ref_id        := 0;
        g_error_code           := 'XX_OM_65100_USERRESP_ID_NULL';
        g_error_description    := FND_MESSAGE.GET_STRING('XXOM','XX_OM_65100_USERRESP_ID_NULL');
        
        log_exceptions;        
 
    END IF; -- End of IF (GN_USER_ID IS NOT NULL) AND (GN_RESP_ID IS NOT NULL) AND (GN_RESP_APP_ID IS NOT NULL) THEN
    
EXCEPTION
    
    WHEN OTHERS THEN
        x_status  := 'E';
        x_message := 'Unexpected error occurred in the procedure ''OD_POS_Ship_Confirm_Proc''. ' || SQLERRM;
        
        g_entity_ref        := 'ORDER_NUMBER';
        g_entity_ref_id     := lr_order_header_rec.order_number;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := 'ODP_OM_UNEXPECTED_ERR';

        log_exceptions;        

END OD_POS_Ship_Confirm_Proc;

END XX_OM_LEG_POS_SHIP_CONF_PKG;
/
SHOW ERRORS;
EXIT;