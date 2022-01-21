SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_ONT_POS_SHIP_CONF_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XX_ONT_POS_SHIP_CONF_PKG                                  |
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

--Declare all the global variables to be used in procedure
GC_USER_NAME                CONSTANT VARCHAR2(240) := 'SHASHIK';
GC_RESP_NAME                CONSTANT VARCHAR2(240) := 'OD US Order Management Super User';

GN_USER_ID                  NUMBER; -- := FND_GLOBAL.USER_ID;
GN_RESP_ID                  NUMBER;
GN_RESP_APP_ID              NUMBER;

GN_ORG_ID                   NUMBER; -- := FND_GLOBAL.ORG_ID;

-- Global exception variables
g_entity_ref                VARCHAR2(1000);
g_entity_ref_id             NUMBER;
g_error_description         VARCHAR2(4000);
g_error_code                VARCHAR2(100);

-- Transaction Types
GC_SHIP_CONF_TRX_TYPE       CONSTANT VARCHAR2(20) := 'ShipConf';
GC_HOLD_REL_TRX_TYPE        CONSTANT VARCHAR2(20) := 'HoldRel';

-- Line Statuses
GC_NEW_LINE                 CONSTANT VARCHAR2(10) := 'New';
GC_MIXED_BAG_LINE           CONSTANT VARCHAR2(10) := 'Mixed';
GC_CANCEL_LINE              CONSTANT VARCHAR2(10) := 'Cancel';


-- +===================================================================+
-- | Name  : Log_Exceptions                                            |
-- | Rice Id      : I0227_PosPmtFeed                                   | 
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
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  | 
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   10-Apr-2007   Shashi Kumar     Initial draft version    |
-- +===================================================================+

PROCEDURE log_exceptions
  
AS

--Variables holding the values from the global exception framework package
--------------------------------------------------------------------------
x_errbuf                    VARCHAR2(1000);
x_retcode                   VARCHAR2(40);

BEGIN

   g_exception.p_exception_header  := 'OTHERS';
   g_exception.p_track_code        := 'OTC';
   g_exception.p_solution_domain   := 'Order Management';
   g_exception.p_function          := 'PosPmtFeed';
   g_exception.p_error_code        := g_error_code;
   g_exception.p_error_description := g_error_description;
   g_exception.p_entity_ref        := g_entity_ref;
   g_exception.p_entity_ref_id     := g_entity_ref_id;

   BEGIN
       XXOD_GLOBAL_EXCEPTION_PKG.insert_exception(g_exception
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
    p_order_header_rec  IN OUT XX_ONT_ORDER_HDR_REC_TYPE,
    x_status            OUT VARCHAR2,
    x_message           OUT VARCHAR2)
    
AS
    
    ln_header_id            oe_order_headers.header_id%TYPE;    
    lr_order_header_rec     XX_ONT_ORDER_HDR_REC_TYPE;

BEGIN

    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;

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
            
            g_entity_ref        := 'Unexpected Error while validating Order No';
            g_entity_ref_id     := 0;
            
            FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
            FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
            FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
            
            g_error_description:= FND_MESSAGE.GET;
            g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');
            
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
        
        g_entity_ref        := 'Unexpected Error in Validate_Ord_Header_Proc procedure';
        g_entity_ref_id     := 0;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

        log_exceptions;        
 
END Validate_Ord_Header_Proc;

-- +===================================================================+
-- | Name  : Get_Line_Info                                             |
-- |                                                                   |
-- | Description:       This procedure is used to get the line_id and  |
-- |                    ordered_quantity of a line in an order.        |
-- |                                                                   |
-- | Parameters:        Header_id                                      |
-- |                    Ship From Org Id                               |
-- |                    Inventory Item Id                              |
-- |                    Line Number                                    |
-- |                                                                   |
-- | Returns :          Line Id                                        |
-- |                    Ordered Quantity                               |
-- |                    Status - 'S' for success and 'E' for error     |
-- |                    Error Message - if procedure errors out        |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_Line_Info (
                 p_header_id            IN  NUMBER
                ,p_ship_from_org_id     IN  NUMBER
                ,p_inventory_item_id    IN  NUMBER
                ,p_line_number          IN  NUMBER
                ,x_line_id              OUT NUMBER
                ,x_ordered_qty          OUT NUMBER
                ,x_status               OUT VARCHAR2
                ,x_message              OUT VARCHAR2)
AS

    ln_line_id          oe_order_lines.line_id%TYPE;
    ln_ordered_qty      oe_order_lines.ordered_quantity%TYPE;

BEGIN

    x_status := 'S';  
    
    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;
    
    BEGIN
    
        SELECT OOL.line_id
              ,OOL.ordered_quantity
        INTO   ln_line_id
              ,ln_ordered_qty
        FROM   oe_order_lines OOL
        WHERE  OOL.header_id         = p_header_id
        AND    OOL.ship_from_org_id  = p_ship_from_org_id
        AND    OOL.inventory_item_id = p_inventory_item_id
        AND    OOL.line_number       = p_line_number;
    
    EXCEPTION
        
        WHEN NO_DATA_FOUND THEN
            ln_line_id := NULL;
            ln_ordered_qty := NULL;
            x_status     := 'E';
            x_message    := 'Order Line doesn''t exist in Oracle.';
            
        WHEN OTHERS THEN
            ln_line_id := NULL;
            ln_ordered_qty := NULL;
            x_status     := 'E';
            x_message    := 'Unexpected error occurred while getting the Line_Id and Ordered Qty: ' || SQLERRM;
            
            g_entity_ref        := 'Unexpected Error while getting line Id and Ordered quantity';
            g_entity_ref_id     := 0;

            FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
            FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
            FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

            g_error_description:= FND_MESSAGE.GET;
            g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

            log_exceptions;             
            
    END;
    
    x_line_id     := ln_line_id;
    x_ordered_qty := ln_ordered_qty;
    
EXCEPTION

    WHEN OTHERS THEN
        ln_line_id := NULL;
        ln_ordered_qty := NULL;
        x_status  := 'E';
        x_message := 'Procedure Get_Line_Info: Unexpected error occurred: ' || SQLERRM;   
        
        g_entity_ref        := 'Unexpected Error in procedure Get_Line_Info';
        g_entity_ref_id     := 0;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');  
        
        log_exceptions;          

END Get_Line_Info;

-- +===================================================================+
-- | Name  : Validate_Ord_Lines_Proc                                   |
-- |                                                                   |
-- | Description:       This Procedure is used to validate the Order   |
-- |                    Lines data.                                    |
-- |                                                                   |
-- | Parameters:        Header Id                                      |
-- |                    order_lines_tbl - PL/SQL table to hold the data|
-- |                                                                   |
-- | Returns :          Status - 'S' for success and 'E' for error     |
-- |                    Error Message - if procedure errors out        |
-- |                    x_ack_ord_lines_tbl-PL/SQL table to acknowledge|
-- |                                        POS system.                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Validate_Ord_Lines_Proc (
     p_header_id            IN NUMBER   
    ,p_order_lines_tbl      IN OUT XX_ONT_ORDER_LINES_TBL
    ,x_status               OUT VARCHAR2
    ,x_message              OUT VARCHAR2
    ,x_ack_ord_lines_tbl    OUT XX_ONT_ACK_ORD_LINES_TBL) 
AS
    lc_status               VARCHAR2(1);
    lc_message              VARCHAR2(4000);
    lc_line_status          VARCHAR2(1);
    lc_line_message         VARCHAR2(4000);
    lc_ack_message          VARCHAR2(4000);
    ln_index                NUMBER;
    
    ln_organization_id      org_organization_definitions.organization_id%type;
    ln_inv_item_id          mtl_system_items.inventory_item_id%type;
    ln_line_id              oe_order_lines.line_id%type;
    ln_ordered_qty          oe_order_lines.ordered_quantity%type;
    ln_salesrep_id          oe_order_lines.salesrep_id%type;
    
    lt_order_lines_tbl      XX_ONT_ORDER_LINES_TBL;
    lt_ack_ord_lines_tbl    XX_ONT_ACK_ORD_LINES_TBL;
    
BEGIN

    x_message := '';
    
    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;

    lt_order_lines_tbl := p_order_lines_tbl;

    x_status := 'S';
    
    ln_index := 1;

    IF lt_order_lines_tbl.COUNT > 0 THEN
    
        FOR i IN lt_order_lines_tbl.FIRST..lt_order_lines_tbl.LAST 
        LOOP

            lc_status := 'S';
            lc_message := '';
            lc_line_message := '';
            
            ln_organization_id  := NULL;
            ln_inv_item_id      := NULL;
            ln_line_id          := NULL;
            ln_salesrep_id      := NULL;
            
            --
            -- Validation for Line Number
            --
            IF lt_order_lines_tbl(i).line_number IS NULL THEN
            
                lc_status := 'E';
                x_status := 'E';
                lc_message := lc_message || ' Line Number should not be null.';

            END IF;
            
            --FND_FILE.PUT_LINE(FND_FILE.LOG,'Lines Validation: lc_status: ' || lc_status);
            --FND_FILE.PUT_LINE(FND_FILE.LOG,'Lines Validation: lc_message: ' || lc_message);
            
            --
            -- Validation for Warehouse Code
            --
            IF lt_order_lines_tbl(i).warehouse_code IS NULL THEN
            
                lc_status := 'E';
                x_status := 'E';
                lc_message := lc_message || ' Warehouse Code should not be null.';

            ELSE

                BEGIN
                
                    g_entity_ref        := NULL;
                    g_entity_ref_id     := 0;
                    g_error_description := NULL;
                    g_error_code        := NULL;                

                    SELECT organization_id 
                    INTO   ln_organization_id
                    FROM   org_organization_definitions 
                    WHERE  organization_code = lt_order_lines_tbl(i).warehouse_code;

                EXCEPTION

                    WHEN NO_DATA_FOUND THEN
                        ln_organization_id := NULL;
                        lc_status := 'E';
                        x_status := 'E';
                        lc_message := lc_message || ' Warehouse Code does not exist in Oracle.';  

                    WHEN OTHERS THEN
                        ln_organization_id := NULL;
                        lc_status := 'E';
                        x_status := 'E';
                        lc_message := lc_message || ' Unexpected error occurred while validating the Warehouse : ' || SUBSTR(SQLERRM, 255) || '.';
                        
                        g_entity_ref        := 'Unexpected error occurred while validating the Warehouse';
                        g_entity_ref_id     := 0;

                        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
                        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                        g_error_description:= FND_MESSAGE.GET;
                        g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');
                            
                        log_exceptions;
                        
                END;
                
                lt_order_lines_tbl(i).ship_from_org_id := ln_organization_id;

            END IF;
            
            --
            -- Validation for Item Number
            --
            IF lt_order_lines_tbl(i).sku_number IS NULL THEN
            
                lc_status := 'E';
                x_status := 'E';
                lc_message := lc_message || ' SKU Number should not be null.';
            
            ELSE
                
                IF ln_organization_id IS NOT NULL THEN

                    BEGIN
                    
                        g_entity_ref        := NULL;
                        g_entity_ref_id     := 0;
                        g_error_description := NULL;
                        g_error_code        := NULL;

                        SELECT inventory_item_id 
                        INTO   ln_inv_item_id
                        FROM   mtl_system_items
                        WHERE  organization_id = ln_organization_id
                        AND    segment1 = lt_order_lines_tbl(i).sku_number;

                    EXCEPTION

                        WHEN NO_DATA_FOUND THEN
                            ln_inv_item_id := NULL;
                            lc_status := 'E';
                            x_status := 'E';
                            lc_message := lc_message || ' SKU Number does not exist in Oracle for the Warehouse.';    
                        
                        WHEN OTHERS THEN
                            ln_inv_item_id := NULL;
                            lc_status := 'E';
                            x_status := 'E';
                            lc_message := lc_message || ' Unexpected error occurred while validating the Ordered Item: ' || SUBSTR(SQLERRM, 255) || '.' ;
                            
                            g_entity_ref        := 'Unexpected error occurred while validating the Ordered Item';
                            g_entity_ref_id     := 0;

                            FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                            FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
                            FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                            g_error_description:= FND_MESSAGE.GET;
                            g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');
                                
                            log_exceptions;
                            
                    END;
                    
                    lt_order_lines_tbl(i).inventory_item_id := ln_inv_item_id;
                
                END IF;
                
            END IF;
            
            --
            -- Validation for Unit of Measure Code
            --            
            IF lt_order_lines_tbl(i).uom_code IS NULL THEN
            
                lt_order_lines_tbl(i).uom_code := 'EA';
            
            END IF;
            
            --
            -- Validation for Line Status
            --
            IF lt_order_lines_tbl(i).line_status NOT IN (GC_NEW_LINE, GC_MIXED_BAG_LINE, GC_CANCEL_LINE) THEN
            
                lc_status := 'E';
                x_status := 'E';
                lc_message := lc_message || ' Line Status should have one of the following values: New, Mixed, Cancel.';
                
            ELSE
            
                IF lt_order_lines_tbl(i).line_status = GC_CANCEL_LINE THEN
                    
                    IF lt_order_lines_tbl(i).shipped_quantity <> 0 THEN
                    
                        lc_status := 'E';
                        x_status := 'E';
                        lc_message := lc_message || ' For Cancelled Line, Shipped Quantity should be zero.';
                    
                    END IF;
                    
                    IF ln_organization_id IS NOT NULL AND ln_inv_item_id IS NOT NULL THEN
                        --
                        -- Calling procedure to get the Line Id
                        --
                        Get_Line_Info (
                             p_header_id            => p_header_id
                            ,p_ship_from_org_id     => ln_organization_id
                            ,p_inventory_item_id    => ln_inv_item_id
                            ,p_line_number          => lt_order_lines_tbl(i).line_number
                            ,x_line_id              => ln_line_id
                            ,x_ordered_qty          => ln_ordered_qty
                            ,x_status               => lc_line_status
                            ,x_message              => lc_line_message);

                        IF lc_line_status = 'E' THEN

                            lc_status := 'E';
                            x_status := 'E';
                            lc_message := lc_message || ' ' || lc_line_message;

                        ELSE

                            lt_order_lines_tbl(i).line_id := ln_line_id;

                        END IF;
                        
                    END IF;                        
                    
                ELSIF lt_order_lines_tbl(i).line_status = GC_MIXED_BAG_LINE THEN                     
                    
                    IF ln_organization_id IS NOT NULL AND ln_inv_item_id IS NOT NULL THEN
                        --
                        -- Calling procedure to get the Ordered Quantity
                        --
                        Get_Line_Info (
                             p_header_id            => p_header_id
                            ,p_ship_from_org_id     => ln_organization_id
                            ,p_inventory_item_id    => ln_inv_item_id
                            ,p_line_number          => lt_order_lines_tbl(i).line_number
                            ,x_line_id              => ln_line_id
                            ,x_ordered_qty          => ln_ordered_qty
                            ,x_status               => lc_line_status
                            ,x_message              => lc_line_message);

                        IF lc_line_status = 'E' THEN

                            lc_status := 'E';
                            x_status := 'E';
                            lc_message := lc_message || ' ' || lc_line_message;

                        ELSE

                            IF lt_order_lines_tbl(i).shipped_quantity > ln_ordered_qty THEN

                                lc_status  := 'E';
                                x_status := 'E';
                                lc_message := lc_message || ' The Shipped Qty cannot be more than the Ordered Qty.';

                            END IF;

                        END IF;                            

                        lt_order_lines_tbl(i).line_id := ln_line_id;
                        
                    END IF;
                    
                ELSIF lt_order_lines_tbl(i).line_status = GC_NEW_LINE THEN

                    IF ln_organization_id IS NOT NULL AND ln_inv_item_id IS NOT NULL THEN
                        --
                        -- Validation that if the line_status is 'New' then it shouldn't exist in Oracle
                        --
                        Get_Line_Info (
                             p_header_id            => p_header_id
                            ,p_ship_from_org_id     => ln_organization_id
                            ,p_inventory_item_id    => ln_inv_item_id
                            ,p_line_number          => lt_order_lines_tbl(i).line_number
                            ,x_line_id              => ln_line_id
                            ,x_ordered_qty          => ln_ordered_qty
                            ,x_status               => lc_line_status
                            ,x_message              => lc_line_message);

                        IF ln_line_id IS NOT NULL THEN 

                            lc_status  := 'E';
                            x_status := 'E';
                            lc_message := lc_message || ' If line is NEW then it should not exist in Oracle.';                        

                        END IF;
                    
                    END IF;
                    
                    IF lt_order_lines_tbl(i).salesrep_name IS NOT NULL THEN
                    
                        --
                        -- Getting the Salesrep Id
                        --
                        BEGIN

                            SELECT salesrep_id
                            INTO   ln_salesrep_id
                            FROM   ra_salesreps  
                            WHERE  name = lt_order_lines_tbl(i).salesrep_name;

                        EXCEPTION

                            WHEN NO_DATA_FOUND THEN
                                ln_salesrep_id := NULL;
                                lc_status := 'E';
                                x_status := 'E';
                                lc_message := lc_message || ' Salesrep does not exist in Oracle.';    

                            WHEN OTHERS THEN
                                ln_salesrep_id := NULL;
                                lc_status := 'E';
                                x_status := 'E';
                                lc_message := lc_message || ' Unexpected error occurred while validating the Salesrep: ' || SUBSTR(SQLERRM, 255) || '.';
                                
                                g_entity_ref        := 'Unexpected Error while validating the Salesrep';
                                g_entity_ref_id     := 0;

                                FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                                FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
                                FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                                g_error_description:= FND_MESSAGE.GET;
                                g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

                                log_exceptions;                                
                                
                        END;
                        
                        lt_order_lines_tbl(i).salesrep_id := ln_salesrep_id;
                        
                    END IF;

                END IF;              
                
            END IF;
            
-- Removed By Shashi on 11-May-07 so that the BPEL ack table type gets success condition
--            IF lc_status = 'E' THEN                
                lt_ack_ord_lines_tbl(ln_index).line_number   := lt_order_lines_tbl(i).line_number;
                lt_ack_ord_lines_tbl(ln_index).error_message := lc_message;
                ln_index := ln_index + 1;
--            END IF;
            
        END LOOP;
        
    END IF;
    
    -- Error in Request Id: 13676183
    
    x_ack_ord_lines_tbl := lt_ack_ord_lines_tbl;

    p_order_lines_tbl := lt_order_lines_tbl;
    
    --x_status := lc_status; --Not Required
    
    IF x_status = 'E' THEN
    
        lc_ack_message := '';
    
        IF x_ack_ord_lines_tbl.COUNT > 0 THEN
            FOR i IN x_ack_ord_lines_tbl.FIRST..x_ack_ord_lines_tbl.LAST
            LOOP
                lc_ack_message := lc_ack_message || ' Line No-> ' || x_ack_ord_lines_tbl(i).line_number || ': ' || x_ack_ord_lines_tbl(i).error_message;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'x_ack_ord_lines_tbl: lc_ack_message: ' || lc_ack_message);
            END LOOP;
        END IF;
        
        x_message := 'Procedure Validate_Ord_Lines_Proc: ' || lc_ack_message;
    
    ELSE        
        
        x_message := '';
        
    END IF;
    
EXCEPTION

    WHEN OTHERS THEN
        x_status := 'E';
        x_message := 'Procedure Validate_Ord_Lines_Proc: Unexpected error occurred: ' || SQLERRM;    
        
        g_entity_ref        := 'Unexpected Error in Validate_Ord_Lines_Proc procedure';
        g_entity_ref_id     := 0;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

        log_exceptions;        

END Validate_Ord_Lines_Proc;

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
    ,p_order_payments_tbl   IN OUT XX_ONT_ORDER_PAYMENTS_TBL
    ,x_status               OUT VARCHAR2
    ,x_message              OUT VARCHAR2
    ,x_ack_ord_pmts_tbl     OUT XX_ONT_ACK_ORD_LINES_TBL) 
AS
    lc_status               VARCHAR2(1);
    lc_message              VARCHAR2(2000);
    ln_index                NUMBER;    
    ln_dummy                NUMBER;
    lc_ack_message          VARCHAR2(2000);
    
    ln_organization_id      org_organization_definitions.organization_id%type;
    ln_inv_item_id          mtl_system_items.inventory_item_id%type;
    
    lt_order_payments_tbl   XX_ONT_ORDER_PAYMENTS_TBL;
    lt_ack_ord_pmts_tbl     XX_ONT_ACK_ORD_LINES_TBL;
    
BEGIN

    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;
    
    lt_order_payments_tbl := p_order_payments_tbl;
    
    ln_index := 1;

    x_status := 'S';

    IF lt_order_payments_tbl.COUNT > 0 THEN
    
        FOR i IN lt_order_payments_tbl.FIRST..lt_order_payments_tbl.LAST 
        LOOP
        
            FND_FILE.PUT_LINE(FND_FILE.LOG,'');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'In lt_order_payments_tbl.COUNT: ' || lt_order_payments_tbl.COUNT);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'i: ' || i);
        
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
                
                IF ln_dummy <> 0 THEN
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
                    -- Need to see whether we can have these from lookups
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
            
--            IF lc_status = 'E' THEN                
                lt_ack_ord_pmts_tbl(ln_index).line_number   := lt_order_payments_tbl(i).line_number;
                lt_ack_ord_pmts_tbl(ln_index).error_message := lc_message;
                ln_index := ln_index + 1;
--            END IF;            
            
        END LOOP;
        
    END IF;
    
    x_ack_ord_pmts_tbl := lt_ack_ord_pmts_tbl;
    
    p_order_payments_tbl := lt_order_payments_tbl;
    
    --x_status := lc_status;  -- We don't need it. Remove it...
    
    IF x_status = 'E' THEN
    
        lc_ack_message := '';
    
        IF x_ack_ord_pmts_tbl.COUNT > 0 THEN
            FOR i IN x_ack_ord_pmts_tbl.FIRST..x_ack_ord_pmts_tbl.LAST
            LOOP
                lc_ack_message := lc_ack_message || ' Payment Line No-> ' || x_ack_ord_pmts_tbl(i).line_number || ': ' || x_ack_ord_pmts_tbl(i).error_message;
            END LOOP;
        END IF;
        
        x_message := 'Procedure Validate_Ord_Payments_Proc: ' || lc_ack_message;
    
    ELSE        
        
        x_message := '';
        
    END IF;    
    
EXCEPTION

    WHEN OTHERS THEN
        x_status := 'E';
        x_message := ' Procedure Validate_Ord_Payments_Proc: Unexpected error occurred: ' || SUBSTR(SQLERRM, 255) || '.';
        
        g_entity_ref        := 'Unexpected Error in calling Validate_Ord_payments_Proc';
        g_entity_ref_id     := 0;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

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
    x_message               OUT VARCHAR2)

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
    
    x                               VARCHAR2(2000);  -- Remove it
       
BEGIN

    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;

    x_status := 'S';

    lt_header_payment_tbl   := p_header_payment_tbl;    
    lt_line_tbl             := p_order_lines_tbl;
    
    --fnd_global.apps_initialize(3644, 50269, 660);
    
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
            ,p_rtrim_data                   => 'N');

        --COMMIT;        
    
        IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN
            --FND_FILE.PUT_LINE(FND_FILE.LOG,'FND_API.G_RET_STS_SUCCESS...');
            x_status := 'S';
        ELSE
            -- FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR in oe_order_pub.process_order: '||lc_return_status);
            -- FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_msg_count: ' || ln_msg_count);
            
            x_status := 'E';
            
            IF ln_msg_count = 1 THEN
                lc_msg_data := SUBSTR(OE_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE), 1, 255);
            ELSE                           
                FOR i IN 1..ln_msg_count - 1
                LOOP
                    lc_msg_data := lc_msg_data || ', ' || SUBSTR(OE_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE), 1, 255);
                    -- FND_FILE.PUT_LINE(FND_FILE.LOG, SUBSTR(lc_msg_data, 1, 255));
                END LOOP;
            END IF;         

        END IF;

    END IF;
    
    --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Line_and_Payment_Proc: lc_msg_data: ' || lc_msg_data);
    
    x_message := 'Procedure Line_and_Payment_Proc: ' || lc_msg_data;
    
    
EXCEPTION
    
    WHEN OTHERS THEN
        x_status := 'E';
        x_message := 'Procedure Line_and_Payment_Proc: Unexpected error occurred: ' || SQLERRM;  
        
        g_entity_ref        := 'Unexpected Error in calling Line_and_Payment_Proc Procedure';
        g_entity_ref_id     := 0;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

        log_exceptions;
    
END Line_and_Payment_Proc;

-- +====================================================================+
-- | Name  : Insert_Payment_Proc                                        |
-- |                                                                    |
-- | Description: This procedure creates the pre-payment at order       |
-- |              header level and processes it. This also releases the |
-- |              hold "Pending Process Payment Hold", if it is applied.|
-- |                                                                    |
-- | Parameters:        p_header_id, p_order_payments_tbl               |
-- |                                                                    |
-- | Returns :          x_status                                        |
-- |                    x_message                                       |
-- +====================================================================+
PROCEDURE Insert_Payment_Proc (
    p_header_id             IN  NUMBER,
    p_order_payments_tbl    IN  XX_ONT_ORDER_PAYMENTS_TBL,
    x_status                OUT VARCHAR2,
    x_message               OUT VARCHAR2)
AS

    lt_order_payments_tbl   XX_ONT_ORDER_PAYMENTS_TBL;
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
    
BEGIN

    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;

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
        
        END LOOP;
        
    END IF;
    
    IF lt_header_payment_tbl.COUNT > 0 THEN
    
        --
        -- Calling procedure Process_Order_Proc to insert the prepayment
        --
        Line_and_Payment_Proc (
            p_header_id             => ln_header_id,
            p_order_lines_tbl       => lt_order_lines_tbl,
            p_header_payment_tbl    => lt_header_payment_tbl,
            x_status                => lc_prepmt_status,
            x_message               => lc_prepmt_message);
            
        IF lc_prepmt_status = 'E' THEN
            lc_prepmt_message := 'Error occured while entering the payment: ' || lc_prepmt_message;
        END IF;            
            
        --FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_prepmt_status: ' || lc_prepmt_status);
        --FND_FILE.PUT_LINE(FND_FILE.LOG, 'lc_prepmt_message: ' || lc_prepmt_message);

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
               ,x_return_status     => lc_procpmt_status);
               
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
                        ,x_msg_data             => lc_relhold_msg_data);
                        
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
    
EXCEPTION
    
    WHEN OTHERS THEN
        x_status  := 'E';
        x_message := 'Procedure Insert_Payment_Proc: Unexpected error occurred: ' || SQLERRM;
        
        g_entity_ref        := 'Unexpected Error in calling Insert_Payment_Proc';
        g_entity_ref_id     := 0;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

        log_exceptions;        

END Insert_Payment_Proc;

-- +===================================================================+
-- | Name  : Get_Delivery_Detail_Id                                    |
-- |                                                                   |
-- | Description: This procedure is used to get the delivery detail id.|
-- |                                                                   |
-- | Parameters: p_source_header_id, p_source_line_id                  |
-- |                                                                   |
-- | Returns :   x_delivery_detail_id, x_status, x_message             |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_Delivery_Detail_Id (
                 p_source_header_id     IN  NUMBER
                ,p_source_line_id       IN  NUMBER
                ,x_delivery_detail_id   OUT NUMBER
                ,x_status               OUT VARCHAR2
                ,x_message              OUT VARCHAR2)
AS
    ln_delivery_detail_id   NUMBER;
    
BEGIN

    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;

    x_status := 'S';

    BEGIN
        
        SELECT WDD.delivery_detail_id
        INTO   ln_delivery_detail_id
        FROM   wsh_delivery_details WDD
        WHERE  WDD.source_header_id = p_source_header_id
        AND    WDD.source_line_id   = p_source_line_id;                    
       
    EXCEPTION
        
        WHEN NO_DATA_FOUND THEN
            ln_delivery_detail_id   := NULL;
            x_status     := 'E';
            x_message    := 'Delivery_Detail_Id doesn''t exist for the combination for Source_Header_Id and Source_Line_Id.';
            
        WHEN OTHERS THEN
            ln_delivery_detail_id   := NULL;
            x_status     := 'E';
            x_message    := 'Unexpected error occurred while getting the Delivery_Detail_Id. ' || SQLERRM;
            
            g_entity_ref        := 'Unexpected error occurred while getting the Delivery_Detail_Id.';
            g_entity_ref_id     := 0;

            FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
            FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
            FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

            g_error_description:= FND_MESSAGE.GET;
            g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

            log_exceptions;
            
    END;
    
    x_delivery_detail_id   := ln_delivery_detail_id;
    
EXCEPTION

    WHEN OTHERS THEN
        ln_delivery_detail_id := NULL;        
        x_status  := 'E';
        x_message := 'Unexpected error occurred in the procedure ''Get_Delivery_Detail_Id''. ' || SQLERRM;  
        
        g_entity_ref        := 'Unexpected error occurred in the procedure Get_Delivery_Detail_Id';
        g_entity_ref_id     := 0;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR'); 
        
        log_exceptions;        

END Get_Delivery_Detail_Id;

-- +===================================================================+
-- | Name  : Delivery_Lines_Proc                                       |
-- |                                                                   |
-- | Description: This procedure update the delivery details.          |
-- |                                                                   |
-- | Parameters: p_changed_attributes                                  |
-- |                                                                   |
-- | Returns: x_status, x_message                                      |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Delivery_Lines_Proc (
                 p_changed_attributes IN  wsh_delivery_details_pub.changedattributetabtype
                ,x_status             OUT VARCHAR2
                ,x_message            OUT VARCHAR2)
AS
    lt_changed_attributes       wsh_delivery_details_pub.changedattributetabtype;
   
    lc_status                   VARCHAR2(100);
    ln_msg_count                NUMBER;
    lc_msg_data                 VARCHAR2(4000);

    ln_api_version_number       NUMBER          := 1.0;
    lc_init_msg_list            VARCHAR2(30);
    lc_commit                   VARCHAR2(30);

    lc_source_code              VARCHAR2(5)     := 'OE';
    
BEGIN

    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;

    lt_changed_attributes := p_changed_attributes;
    
    x_status := 'S';
    
    -- Initialize return status
    -- x := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

    /*FND_GLOBAL.APPS_INITIALIZE(user_id      => 1001594
                              ,resp_id      => 52892
                              ,resp_appl_id => 660);*/
    
    WSH_DELIVERY_DETAILS_PUB.Update_Shipping_Attributes(
        p_api_version_number    => ln_api_version_number,
        p_init_msg_list         => lc_init_msg_list,
        p_commit                => lc_commit,
        x_return_status         => lc_status,
        x_msg_count             => ln_msg_count,
        x_msg_data              => lc_msg_data,
        p_changed_attributes    => lt_changed_attributes,
        p_source_code           => lc_source_code);
        
    --COMMIT;        
        
    IF lc_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN

        x_status     := 'S';
    ELSE

        x_status     := 'E';
        
        IF ln_msg_count = 1 THEN
            lc_msg_data := SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE), 1, 512);

        ELSE                           
            FOR i IN 1..ln_msg_count - 1
            LOOP
                lc_msg_data := SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE), 1, 512);

            END LOOP;
        END IF;         
    END IF;
    
    
EXCEPTION

    WHEN OTHERS THEN
        x_status  := 'E';
        x_message := 'Unexpected error occurred in the procedure ''Delivery_Lines_Proc''. ' || SQLERRM;  
        
        g_entity_ref        := 'Unexpected Error in calling price List';
        g_entity_ref_id     := 0;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

        log_exceptions;        

END Delivery_Lines_Proc;

-- +===================================================================+
-- |        Name: Process_POS_Lines_Proc                               |
-- | Description: This Procedure will be used to:                      |
-- |              - Inserting a new line in existing order             |
-- |              - Updating the order line quantity                   |
-- |              - Cancelling an existing order line                  |
-- |              - Updating the delivery detail line quantity         |
-- |                                                                   |
-- |  Parameters: p_header_id, p_transaction_type, p_order_lines_tbl   |
-- |                                                                   |
-- | Returns :    x_ret_status, x_message                              |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Process_POS_Lines_Proc (
    p_header_id         IN  NUMBER,
    p_transaction_type  IN  VARCHAR2,
    p_order_lines_tbl   IN  XX_ONT_ORDER_LINES_TBL,
    x_ret_status        OUT VARCHAR2,
    x_message           OUT VARCHAR2)
    
AS

    lc_status                       VARCHAR2(1)                                     := NULL;
    lc_message                      VARCHAR2(1000)                                  := NULL;
    ln_msg_count                    NUMBER                                          := 0;
    lc_msg_data                     VARCHAR2(4000)                                  := NULL;
    
    lc_new_ln_status                VARCHAR2(1);
    lc_new_ln_message               VARCHAR2(4000);
    
    lc_mdfd_ln_status               VARCHAR2(1);
    lc_mdfd_ln_message              VARCHAR2(4000);
    
    lc_dlvry_ln_status              VARCHAR2(1);
    lc_dlvry_ln_message             VARCHAR2(4000);    
    
    ln_api_version_number           NUMBER                                          := 1.0;
    lc_init_msg_list                VARCHAR2(10)                                    := FND_API.G_FALSE;
    lc_return_values                VARCHAR2(10)                                    := FND_API.G_FALSE;
    lc_action_commit                VARCHAR2(10)                                    := FND_API.G_FALSE;
    
    lt_order_lines_tbl              XX_ONT_ORDER_LINES_TBL;
    
    lt_new_lines_tbl                oe_order_pub.line_tbl_type                      := oe_order_pub.g_miss_line_tbl;
    lt_modified_order_lines_tbl     oe_order_pub.line_tbl_type                      := oe_order_pub.g_miss_line_tbl;
    lt_modified_dlvry_lines_tbl     wsh_delivery_details_pub.changedattributetabtype;
    
    lt_header_payment_tbl           oe_order_pub.header_payment_tbl_type            := oe_order_pub.g_miss_header_payment_tbl;
    
    ln_delivery_detail_id           wsh_delivery_details.delivery_detail_id%type;
    
    ln_line_type_id                 oe_wf_line_assign_v.line_type_id%type;
           
BEGIN

    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;
    
    x_ret_status := 'S';

    lt_order_lines_tbl := p_order_lines_tbl;
    
    --fnd_global.apps_initialize(3644, 50269, 660);
    --
    -- Get the line_type_id and pass it below 
    --
    BEGIN
        
        SELECT OWLA.line_type_id
        INTO   ln_line_type_id
        FROM   oe_transaction_types_v OTTV,
               oe_wf_line_assign_v    OWLA,
               oe_order_headers       OOH
        WHERE  OTTV.transaction_type_id = OOH.order_type_id
        AND    OTTV.transaction_type_id = OWLA.order_type_id
        AND    OWLA.process_name        = 'R_BILL_ONLY'         -- Line Flow - Generic, Bill Only (Workflow Process)
        AND    TRUNC(SYSDATE) BETWEEN TRUNC(OWLA.start_date_active) AND TRUNC(NVL(OWLA.end_date_active,SYSDATE))
        AND    OOH.header_id = p_header_id;
        
        lc_status := 'S';
        
    EXCEPTION
    
        WHEN NO_DATA_FOUND THEN
        
            ln_line_type_id := NULL;
            lc_status := 'E';
    
        WHEN OTHERS THEN
        
            ln_line_type_id := NULL;
            lc_status := 'E';
    END;

    IF p_transaction_type = GC_HOLD_REL_TRX_TYPE THEN

        IF lt_order_lines_tbl.COUNT > 0 THEN

            FOR i IN lt_order_lines_tbl.FIRST..lt_order_lines_tbl.LAST
            LOOP

                IF lt_order_lines_tbl(i).line_status = GC_NEW_LINE THEN

                    lt_new_lines_tbl(i)                     := OE_ORDER_PUB.G_MISS_LINE_REC;

                    lt_new_lines_tbl(i).created_by          := GN_USER_ID;
                    lt_new_lines_tbl(i).creation_date       := SYSDATE;
                    lt_new_lines_tbl(i).last_updated_by     := GN_USER_ID;
                    lt_new_lines_tbl(i).last_update_date    := SYSDATE;
                    lt_new_lines_tbl(i).operation           := OE_GLOBALS.G_OPR_CREATE;

                    lt_new_lines_tbl(i).header_id           := p_header_id;
                    lt_new_lines_tbl(i).inventory_item_id   := lt_order_lines_tbl(i).inventory_item_id;
                    lt_new_lines_tbl(i).line_number         := lt_order_lines_tbl(i).line_number;
                    lt_new_lines_tbl(i).order_quantity_uom  := lt_order_lines_tbl(i).uom_code;
                    lt_new_lines_tbl(i).ship_from_org_id    := lt_order_lines_tbl(i).ship_from_org_id;
                    lt_new_lines_tbl(i).salesrep_id         := lt_order_lines_tbl(i).salesrep_id;
                    lt_new_lines_tbl(i).tax_value           := lt_order_lines_tbl(i).tax_amt;
                    lt_new_lines_tbl(i).unit_selling_price  := lt_order_lines_tbl(i).selling_price;                    
                    lt_new_lines_tbl(i).ordered_quantity    := lt_order_lines_tbl(i).shipped_quantity;

                    --lt_new_lines_tbl(i).cust_model_serial_number    := lt_order_lines_tbl(i).serial_number; -- Need to check

                    lt_new_lines_tbl(i).line_type_id        := ln_line_type_id;

                    -- lt_new_lines_tbl(i).request_date                 -- We may need to capture this

                ELSIF lt_order_lines_tbl(i).line_status IN (GC_MIXED_BAG_LINE, GC_CANCEL_LINE) THEN

                    lt_modified_order_lines_tbl(i)                   := OE_ORDER_PUB.G_MISS_LINE_REC;

                    lt_modified_order_lines_tbl(i).created_by          := GN_USER_ID;
                    lt_modified_order_lines_tbl(i).creation_date       := SYSDATE;
                    lt_modified_order_lines_tbl(i).last_updated_by     := GN_USER_ID;
                    lt_modified_order_lines_tbl(i).last_update_date    := SYSDATE;
                    lt_modified_order_lines_tbl(i).operation           := OE_GLOBALS.G_OPR_UPDATE;

                    lt_modified_order_lines_tbl(i).header_id         := p_header_id;
                    --lt_modified_order_lines_tbl(i).inventory_item_id   := ???;   -- We may need it...
                    lt_modified_order_lines_tbl(i).line_id           := lt_order_lines_tbl(i).line_id;                    

                    lt_modified_order_lines_tbl(i).ordered_quantity  := lt_order_lines_tbl(i).shipped_quantity;
                    --lt_modified_order_lines_tbl(i).ship_from_org_id              :=  ???;   -- We may need it...

                    IF lt_modified_order_lines_tbl(i).ordered_quantity <> 0 THEN

                        lt_modified_order_lines_tbl(i).change_reason     := 'REDUCED QTY BY POS';
                        lt_modified_order_lines_tbl(i).change_comments   := NULL;

                    ELSE

                        lt_modified_order_lines_tbl(i).change_reason     := 'CANCELLED LINE BY POS';
                        lt_modified_order_lines_tbl(i).change_comments   := NULL;                    

                    END IF;

                END IF;            

             END LOOP;

        END IF;

    ELSIF p_transaction_type = GC_SHIP_CONF_TRX_TYPE THEN

        IF lt_order_lines_tbl.COUNT > 0 THEN

            FOR i IN lt_order_lines_tbl.FIRST..lt_order_lines_tbl.LAST
            LOOP

                IF lt_order_lines_tbl(i).line_status = GC_NEW_LINE THEN

                    lt_new_lines_tbl(i)                     := OE_ORDER_PUB.G_MISS_LINE_REC;

                    lt_new_lines_tbl(i).created_by          := GN_USER_ID;
                    lt_new_lines_tbl(i).creation_date       := SYSDATE;
                    lt_new_lines_tbl(i).last_updated_by     := GN_USER_ID;
                    lt_new_lines_tbl(i).last_update_date    := SYSDATE;
                    lt_new_lines_tbl(i).operation           := OE_GLOBALS.G_OPR_CREATE;

                    lt_new_lines_tbl(i).header_id           := p_header_id;
                    lt_new_lines_tbl(i).inventory_item_id   := lt_order_lines_tbl(i).inventory_item_id;
                    lt_new_lines_tbl(i).line_number         := lt_order_lines_tbl(i).line_number;
                    lt_new_lines_tbl(i).order_quantity_uom  := lt_order_lines_tbl(i).uom_code;
                    lt_new_lines_tbl(i).ship_from_org_id    := lt_order_lines_tbl(i).ship_from_org_id;
                    lt_new_lines_tbl(i).salesrep_id         := lt_order_lines_tbl(i).salesrep_id;
                    lt_new_lines_tbl(i).tax_value           := lt_order_lines_tbl(i).tax_amt;
                    lt_new_lines_tbl(i).unit_selling_price  := lt_order_lines_tbl(i).selling_price;                    
                    lt_new_lines_tbl(i).ordered_quantity    := lt_order_lines_tbl(i).shipped_quantity;

                    --lt_new_lines_tbl(i).cust_model_serial_number    := lt_order_lines_tbl(i).serial_number; -- Not required for new line because the mapping is given for wsh_delivery_details_pub.changedattributetabtype

                    lt_new_lines_tbl(i).line_type_id        := ln_line_type_id;

                    -- lt_new_lines_tbl(i).request_date                 -- We may need to capture this

                ELSIF lt_order_lines_tbl(i).line_status IN (GC_MIXED_BAG_LINE, GC_CANCEL_LINE) THEN

                    Get_Delivery_Detail_Id (
                         p_source_header_id     => p_header_id
                        ,p_source_line_id       => lt_order_lines_tbl(i).line_id
                        ,x_delivery_detail_id   => ln_delivery_detail_id
                        ,x_status               => lc_status
                        ,x_message              => lc_message);
                        
                    IF lc_status = 'S' THEN

                        -- WHO columns are NOT available in ChangedAttributeRecType

                        --lt_modified_dlvry_lines_tbl(i).created_by          := G_USER_ID;
                        --lt_modified_dlvry_lines_tbl(i).creation_date       := SYSDATE;
                        --lt_modified_dlvry_lines_tbl(i).last_updated_by     := G_USER_ID;
                        --lt_modified_dlvry_lines_tbl(i).last_update_date    := SYSDATE;
                        --lt_modified_dlvry_lines_tbl(i).operation           := OE_GLOBALS.G_OPR_CREATE; We don't need it

                        lt_modified_dlvry_lines_tbl(i).source_header_id     := p_header_id;
                        lt_modified_dlvry_lines_tbl(i).source_line_id       := lt_order_lines_tbl(i).line_id;
                        lt_modified_dlvry_lines_tbl(i).delivery_detail_id   := ln_delivery_detail_id;
                        lt_modified_dlvry_lines_tbl(i).shipped_quantity     := lt_order_lines_tbl(i).shipped_quantity;
                        lt_modified_dlvry_lines_tbl(i).serial_number        := lt_order_lines_tbl(i).serial_number;  -- Mapped as per email from Milind on 30-Jan-2007

                        --lt_modified_dlvry_lines_tbl(i).ship_from_org_id   := 113;   -- We may need it...
                    
                    ELSE
                    
                        lc_message := 'If transaction type is ' || GC_SHIP_CONF_TRX_TYPE || ' and line status is either ' || GC_MIXED_BAG_LINE || ' or ' || GC_CANCEL_LINE || ' then the delivery should already be created.' || lc_message || ' ';

                    END IF;

                END IF;

            END LOOP;

        END IF; -- End of IF lt_order_lines_tbl.COUNT > 0 THEN

    END IF; -- End of IF p_transaction_type = GC_HOLD_REL_TRX_TYPE THEN
        
    IF lt_new_lines_tbl.COUNT > 0 THEN
    
        lc_new_ln_status := 'S';
    
        --
        -- Call the procedure to add Bill Only lines programatically
        --        
        Line_and_Payment_Proc (
             p_header_id             => p_header_id
            ,p_order_lines_tbl       => lt_new_lines_tbl
            ,p_header_payment_tbl    => lt_header_payment_tbl
            ,x_status                => lc_new_ln_status
            ,x_message               => lc_new_ln_message);
        
        IF lc_new_ln_status <> 'S' THEN
            
            lc_new_ln_message := 'Error occurred while creating NEW Lines: ' || lc_new_ln_message || '.';
            
        ELSE 
        
            lc_new_ln_message := '';
            
        END IF;

    END IF;

    IF lt_modified_order_lines_tbl.COUNT > 0 THEN
        
        --
        -- Call the procedure to reduce/cancel the quantity of an order line
        --        
        lc_mdfd_ln_status := 'S';
        
        Line_and_Payment_Proc (
             p_header_id             => p_header_id
            ,p_order_lines_tbl       => lt_modified_order_lines_tbl
            ,p_header_payment_tbl    => lt_header_payment_tbl
            ,x_status                => lc_mdfd_ln_status
            ,x_message               => lc_mdfd_ln_message);
            
        IF lc_mdfd_ln_status <> 'S' THEN
            
            lc_mdfd_ln_message := 'Error occurred while creating MIXED or CANCEL Lines: ' || lc_mdfd_ln_message;
            
        ELSE
        
            lc_mdfd_ln_message := '';
            
        END IF;
        
    END IF;

    IF lt_modified_dlvry_lines_tbl.COUNT > 0 THEN
    
        --
        -- Call the procedure to reduce/cancel the quantity of a delivery line
        --        
        lc_dlvry_ln_status := 'S';
        
        Delivery_Lines_Proc (
             p_changed_attributes   => lt_modified_dlvry_lines_tbl
            ,x_status               => lc_dlvry_ln_status
            ,x_message              => lc_dlvry_ln_message);
        
        IF lc_dlvry_ln_status <> 'S' THEN
            
            lc_dlvry_ln_message := 'Error occurred while updating Delivery Lines: ' || lc_dlvry_ln_message;
            
        ELSE
        
            lc_dlvry_ln_message := '';
            
        END IF;        

    END IF;
    
    IF lc_status <> 'S' OR lc_new_ln_status <> 'S' OR lc_mdfd_ln_status <> 'S' OR lc_dlvry_ln_status <> 'S' THEN
        x_ret_status := 'E';
        x_message := lc_message || ' ' || lc_new_ln_message || ' ' || lc_mdfd_ln_message || ' ' || lc_dlvry_ln_message;
    ELSIF lc_message = 'S' AND lc_new_ln_status = 'S' AND lc_mdfd_ln_status = 'S' AND lc_dlvry_ln_status = 'S' THEN       
        x_ret_status := lc_status;
        x_message := 0;
    END IF;
    
        
EXCEPTION
    
    WHEN OTHERS THEN    
        x_ret_status := 'E';
        x_message := 'Procedure Process_POS_Lines_Proc: Unexpected error occurred: ' || SUBSTR(SQLERRM, 255) || '.';   

        g_entity_ref        := 'Unexpected Error in calling Process_POS_Lines_Proc';
        g_entity_ref_id     := 0;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

        log_exceptions;        
    
END Process_POS_Lines_Proc;

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
PROCEDURE Update_POD_Proc (
    p_header_id             IN  NUMBER,
    p_delivery_id           IN  NUMBER,
    p_pos_transaction_num   IN  VARCHAR2,
    x_status                OUT VARCHAR2,
    x_message               OUT VARCHAR2)
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

    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;
    
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
        
        g_entity_ref        := 'Unexpected Error in calling Update_POD_Proc';
        g_entity_ref_id     := 0;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

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
PROCEDURE Ship_Confirm_Proc (
    p_delivery_id           IN  NUMBER,
    p_delivery_name         IN  NUMBER,
    x_status                OUT VARCHAR2,
    x_message               OUT VARCHAR2)
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
    
    --fnd_global.apps_initialize(3644, 50269, 660);
   
    --p_delivery_id   := 139011; -- For Order # 2584
    --p_delivery_name := 139011;
    
    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;
    
    ln_delivery_id   := p_delivery_id;
    lc_delivery_name := p_delivery_name;
    
    x_status := 'S';
    
    WSH_DELIVERIES_PUB.DELIVERY_ACTION( p_api_version_number     =>  ln_api_version
                                      , p_init_msg_list          =>  lc_init_msg_list
                                      , x_return_status          =>  lc_return_status
                                      , x_msg_count              =>  ln_msg_count
                                      , x_msg_data               =>  lc_msg_data
                                      , p_action_code            =>  'CONFIRM'
                                      , p_delivery_id            =>  ln_delivery_id
                                      , p_delivery_name          =>  lc_delivery_name 
                                      , x_trip_id                =>  ln_trip_id
                                      , x_trip_name              =>  lc_trip_name
                                      );
                                      
    --COMMIT;
    
    IF lc_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN
        
        x_status := 'S';
        
    ELSE
    
        IF ln_msg_count = 1 THEN
            
            lc_msg_data := SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE), 1, 512);
        
        ELSE                           
            
            FOR i IN 1..ln_msg_count - 1
            LOOP
                
                lc_msg_data := lc_msg_data || ', ' || SUBSTR(FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE), 1, 512);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_msg_data: ' || lc_msg_data);
            
            END LOOP;
        
        END IF;         
        
        x_message := 'Procedure Ship_Confirm_Proc: ' || lc_msg_data || '.';
        x_status := 'E';        
        
    END IF;
    
    -- Erroring out: Request Id: 13600824

EXCEPTION
    
    WHEN OTHERS THEN
        x_status  := 'E';
        x_message := 'Procedure Ship_Confirm_Proc: Unexpected error occurred: ' || SUBSTR(SQLERRM, 255) || '.';   
        g_entity_ref        := 'Unexpected Error in calling price List';
        g_entity_ref_id     := 0;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

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
    p_order_header_rec      IN  XX_ONT_ORDER_HDR_REC_TYPE,
    p_order_lines_tbl       IN  XX_ONT_ORDER_LINES_TBL,
    p_order_payments_tbl    IN  XX_ONT_ORDER_PAYMENTS_TBL,
    x_order_lines_tbl_out   IN OUT XX_ONT_ACK_ORD_LINES_TBL,
    x_status                OUT VARCHAR2,
    x_transaction_date      OUT VARCHAR2,
    x_message               OUT VARCHAR2)

AS
    ln_order_number         NUMBER;
    lc_status               VARCHAR2(20);
    lc_message              VARCHAR2(4000);
    
    lc_line_status          VARCHAR2(20);    
    lc_pmt_status           VARCHAR2(20);
    lc_pr_ln_status         VARCHAR2(20);
    lc_pr_pmt_status        VARCHAR2(20);
    lc_pod_status           VARCHAR2(20);
    lc_hdr_status           VARCHAR2(20);
    lc_ship_status          VARCHAR2(20);
    
    lc_hdr_message          VARCHAR2(4000);
    lc_line_message         VARCHAR2(4000);
    lc_pmt_message          VARCHAR2(4000);
    lc_pr_ln_message        VARCHAR2(4000);
    lc_pr_pmt_message       VARCHAR2(4000);
    lc_pod_message          VARCHAR2(4000);
    lc_ship_message         VARCHAR2(4000);

    lr_order_header_rec     XX_ONT_ORDER_HDR_REC_TYPE;
    lt_order_lines_tbl      XX_ONT_ORDER_LINES_TBL;    
    lt_order_payments_tbl   XX_ONT_ORDER_PAYMENTS_TBL;    
    lt_ack_ord_lines_tbl    XX_ONT_ACK_ORD_LINES_TBL;    
    lt_ack_ord_pmts_tbl     XX_ONT_ACK_ORD_LINES_TBL;

    -- 
    -- Cursor to get the Delivery Ids of an order
    --
    CURSOR lcu_get_delivery_ids (
        p_header_id     NUMBER
    )    
    IS 
    SELECT WND.delivery_id, WND.name
    FROM   wsh_new_deliveries  WND
    WHERE  EXISTS (
        SELECT 'X'
        FROM   wsh_delivery_details     WDD,
               wsh_delivery_assignments WDA
        WHERE  WDA.delivery_id        = WND.delivery_id 
        AND    WDD.delivery_detail_id = WDA.delivery_detail_id
        AND    WDD.source_header_id   = p_header_id
    );

BEGIN

    g_entity_ref        := NULL;
    g_entity_ref_id     := 0;
    g_error_description := NULL;
    g_error_code        := NULL;
    
    x_status := 'S';
    
    -- Getting the user id
    
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
        
    -- Getting the responsibility_id and application_id
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
        Validate_Ord_Header_Proc (
             p_order_header_rec  => lr_order_header_rec
            ,x_status            => lc_hdr_status
            ,x_message           => lc_hdr_message);

        IF lc_hdr_status = 'S' THEN

            IF lt_order_lines_tbl.COUNT > 0 THEN

                FND_FILE.PUT_LINE(FND_FILE.LOG,'lr_order_header_rec.header_id: ' || lr_order_header_rec.header_id);

                ------------------------------
                -- Call validation procedure
                ------------------------------
                Validate_Ord_Lines_Proc (
                     p_header_id            => lr_order_header_rec.header_id
                    ,p_order_lines_tbl      => lt_order_lines_tbl
                    ,x_status               => lc_line_status
                    ,x_message              => lc_line_message
                    ,x_ack_ord_lines_tbl    => lt_ack_ord_lines_tbl);
                    
            END IF;

            IF p_order_payments_tbl.COUNT > 0 THEN

                ------------------------------
                -- Call validation procedure
                ------------------------------           
                Validate_Ord_Payments_Proc (
                     p_header_id            => lr_order_header_rec.header_id
                    ,p_order_payments_tbl   => lt_order_payments_tbl
                    ,x_status               => lc_pmt_status
                    ,x_message              => lc_pmt_message
                    ,x_ack_ord_pmts_tbl     => lt_ack_ord_pmts_tbl);
                    
            END IF;
            
            --AND lc_line_status = 'S'
            
            IF lc_line_status = 'S' AND lr_order_header_rec.transaction_type IN (GC_SHIP_CONF_TRX_TYPE, GC_HOLD_REL_TRX_TYPE) THEN

                Process_POS_Lines_Proc (
                     p_header_id        => lr_order_header_rec.header_id              
                    ,p_transaction_type => lr_order_header_rec.transaction_type
                    ,p_order_lines_tbl  => lt_order_lines_tbl
                    ,x_ret_status       => lc_pr_ln_status
                    ,x_message          => lc_pr_ln_message);


            END IF;

            --lc_pmt_message = 'S' AND 
            
            IF lc_pmt_status = 'S' AND lr_order_header_rec.transaction_type IN (GC_SHIP_CONF_TRX_TYPE, GC_HOLD_REL_TRX_TYPE) THEN

                Insert_Payment_Proc (
                     p_header_id             => lr_order_header_rec.header_id
                    ,p_order_payments_tbl    => lt_order_payments_tbl
                    ,x_status                => lc_pr_pmt_status
                    ,x_message               => lc_pr_pmt_message);
                    

            END IF;

            IF lc_pr_ln_status = 'S' AND lc_pr_pmt_status = 'S' AND lr_order_header_rec.transaction_type = GC_SHIP_CONF_TRX_TYPE THEN

                FOR delivery_ids_rec IN lcu_get_delivery_ids (p_header_id => lr_order_header_rec.header_id)
                LOOP

                    Update_POD_Proc (
                         p_header_id           => lr_order_header_rec.header_id
                        ,p_delivery_id         => delivery_ids_rec.delivery_id
                        ,p_pos_transaction_num => lr_order_header_rec.pos_transaction_num
                        ,x_status              => lc_pod_status
                        ,x_message             => lc_pod_message);
                        
                    IF lc_pod_status = 'S' THEN

                        Ship_Confirm_Proc (
                             p_delivery_id     => delivery_ids_rec.delivery_id
                            ,p_delivery_name   => delivery_ids_rec.name
                            ,x_status          => lc_ship_status
                            ,x_message         => lc_ship_message);
                            

                    END IF;

                END LOOP;

            END IF;

        END IF;
        
        x_order_lines_tbl_out := lt_ack_ord_lines_tbl;
        
        
        IF lc_hdr_status = 'E' OR lc_line_status = 'E' OR lc_pmt_status = 'E' 
            OR lc_pr_ln_status = 'E' OR lc_pr_pmt_status = 'E' OR lc_pod_status = 'E' 
                OR lc_ship_status = 'E' THEN

                    x_status := 'E';
                    x_message := lc_hdr_message ||'^ ' || lc_line_message || '^ ' || lc_pmt_message || '^ ' 
                                    || lc_pr_ln_message || '^ ' || lc_pr_pmt_message || '^ ' || lc_pod_message 
                                        || '^ ' || lc_ship_message;

        END IF;                

        x_transaction_date := TO_CHAR(SYSDATE, 'DD-MON-RRRR: HH:MI:SS AM');

        p_order_number := p_order_header_rec.order_number;
        
        IF x_status = 'S' THEN
            x_status := 'SUCCESS';
        ELSIF x_status = 'E' THEN
            x_status := 'FAILURE';
        END IF;
        
    ELSE
    
        x_status := 'FAILURE';
        
        x_message := 'Either user ''' || GC_USER_NAME || ''' or responsibility ''' || GC_RESP_NAME || ''' doesn''t exist in Oracle.';
 
    END IF; -- End of IF (GN_USER_ID IS NOT NULL) AND (GN_RESP_ID IS NOT NULL) AND (GN_RESP_APP_ID IS NOT NULL) THEN
    

    IF x_order_lines_tbl_out.COUNT > 0 THEN
        FOR i IN x_order_lines_tbl_out.FIRST..x_order_lines_tbl_out.LAST
        LOOP
            FND_FILE.PUT_LINE(FND_FILE.LOG,'                Line Number: ' || x_order_lines_tbl_out(i).line_number);
        END LOOP;
    END IF;
    
    
EXCEPTION
    
    WHEN OTHERS THEN
        x_status  := 'E';
        x_message := 'Unexpected error occurred in the procedure ''OD_POS_Ship_Confirm_Proc''. ' || SQLERRM;
        
        g_entity_ref        := 'Unexpected Error in calling OD_POS_Ship_Confirm_Proc procedure';
        g_entity_ref_id     := 0;

        FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

        g_error_description:= FND_MESSAGE.GET;
        g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

        log_exceptions;      

END OD_POS_Ship_Confirm_Proc;

END XX_ONT_POS_SHIP_CONF_PKG;
/
SHOW ERRORS;
-- EXIT;
