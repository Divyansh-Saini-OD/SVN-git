create or replace PACKAGE BODY XX_WFL_POACCREJ_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name         : XX_WFL_POACCREJ_PKG                                |
-- | Rice ID      : E0274                                              |
-- | Description  : This package contains procedures that perform the  |
-- |                following activities                               |
-- |              1.FILL_KILL_PROC - Checks the backorder eligible flag|
-- |                If flag is 'Y' then Fill process is followed       |
-- |                Else Kill path is taken.                           |
-- |              2.CANCEL_OE_LINE_PROC - Cancels the original Sales   |
-- |                Order line using CANCEL_LINE procedure.            |
-- |              3.CREATE_OE_LINE_PROC - Creates and updates a new    |
-- |                sales order line using CREATE_LINE.                |
-- |              4.CREATE_LINE - Creates a new sales order line       |
-- |                copying the existing line's attributes.            |
-- |              5.CANCEL_LINE - Cancels the original Sales Order     |
-- |                line using PROCESSORDER procedure.                 |
-- |              6.PROCESSORDER - Modifies/Creates order line using   |
-- |                OE_ORDER_PUB.PROCESS_ORDER API.                    |
-- |              7.SPLIT_LINE - Splits the sales order line based on  |
-- |                quantity received and quantity cancelled.          |
-- |              8.UPDATE_OE_LINE_DFF - Updates the custom table sales|
-- |                 order line attributes.                            |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  25-JUL-2007 Christina S        Initial draft version     |
-- |VERSION 1 25-JAN-2007 Bala E           Changed the Fill_kill       |
-- |procedure to take Kill path always irrespective of Backorder flag  |
-- |enable. This change is only for VW orders Release.                 |
-- +===================================================================+
AS
-- +===================================================================+
-- | Name           : FILL_KILL_PROC                                   |
-- | Description    :  Checks the backorder eligible flag              |
-- |                  If flag is 'Y' then Fill process is followe      |
-- |                  Else Kill path is taken.                         | 
-- |                  The above funcationaly has been commeted/disabled|
-- |                  as VW Order release will not take kill path      | 
-- |                                                                   |
-- | Parameters     : p_item_type                                      |
-- |                  p_item_key                                       |
-- |                  p_actid                                          |
-- |                  p_funcmode                                       |
-- |                                                                   |
-- |                                                                   |
-- | Returns        : x_result                                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE FILL_KILL_PROC (
                            p_item_type   IN  VARCHAR2
                           ,p_item_key    IN  VARCHAR2
                           ,p_actid       IN  NUMBER
                           ,p_funcmode    IN  VARCHAR2
                           ,x_result      OUT VARCHAR2
                         )
IS
    -- Declaring local variables
    ln_inventory_item_id      mtl_system_items.inventory_item_id%TYPE;
    ln_customer_id            hz_parties.party_id%TYPE;
    ln_organization_id        oe_order_lines_all.ship_from_org_id%TYPE;
    lc_return_status          VARCHAR2 (10)  := FND_API.G_RET_STS_SUCCESS;
    lc_return_message         VARCHAR2 (4000);
    lc_result_out             VARCHAR2 (10) ;
    lc_errbuff                VARCHAR2 (1000);
    lc_retcode                VARCHAR2 (100);
    lc_error_message          VARCHAR2 (1000);
    lc_po_so_flag             VARCHAR2 (10);
    ln_extended_price         NUMBER;
    ln_po_so_line_id          NUMBER;
    lc_po_exist               VARCHAR2 (1);
    lc_so_exist               VARCHAR2 (1);
    ln_backorder_flag         NUMBER;
    EX_SO_PO_NOT_EXISTS       EXCEPTION ;
    EX_BACKORDER_FAILED       EXCEPTION ;
    -- To fetch the Sales Order Line details
    CURSOR lcu_order_line_dtls_po( p_po_line_id IN po_lines_all.po_line_id%TYPE )
    IS
        SELECT   OOL.line_id
                ,PL.po_line_id
                ,PLL.quantity_cancelled
                ,PLL.quantity_received
                ,FDFC.descriptive_flex_context_code
                ,OOL.inventory_item_id
                ,OOL.sold_to_org_id
                ,OOL.ship_from_org_id
                ,(OOL.unit_selling_price * OOL.ordered_quantity) extended_price
        FROM    fnd_descr_flex_contexts FDFC
                ,oe_order_headers_all OOH
                ,po_headers_all PH
                ,po_lines_all PL
                ,po_line_locations_all PLL
                ,oe_order_lines_all OOL
                ,po_req_distributions_all PRD
                ,po_requisition_lines_all PRL
                ,po_distributions_archive_all PDA
        WHERE OOH.header_id = OOL.header_id
        AND PLL.po_line_id = PL.po_line_id
        AND PDA.po_header_id = PH.po_header_id
        AND PDA.po_line_id = PL.po_line_id
        AND PDA.req_distribution_id  = PRD.distribution_id
        AND PRL.requisition_line_id  = PRD.requisition_line_id
        AND PH.po_header_id = PL.po_header_id
        AND FDFC.enabled_flag   = 'Y'
        AND ( PL.cancel_flag = 'Y' OR PLL.cancel_flag = 'Y')  
        AND OOL.line_id  =  (
                             SELECT MAX (OOL1.line_id) 
                             FROM oe_order_lines_all OOL1 
                             START WITH OOL1.line_id = PRL.attribute10
                             CONNECT BY PRIOR OOL1.line_id = OOL1.split_from_line_id 
                             )
        AND PH.attribute_category  = FDFC.descriptive_flex_context_code
        AND FDFC.descriptive_flexfield_name = gc_desc_flexfield_name
        AND FDFC.descriptive_flex_context_code IN (
                                                   gc_dropship_meaning
                                                  ,gc_nc_dropship_meaning
                                                  ,gc_backtoback_meaning
                                                  ,gc_nc_backtoback_meaning
                                                 )
        AND PL.po_line_id = p_po_line_id;
    -- To fetch the Order line details to be passed to Backorder API
    CURSOR lcu_order_line_dtls_so( p_so_line_id IN  oe_order_lines_all.line_id%TYPE)
    IS
        SELECT   OOL.line_id
                ,OOL.inventory_item_id
                ,OOL.sold_to_org_id
                ,OOL.ship_from_org_id
                ,(OOL.unit_selling_price * OOL.ordered_quantity) extended_price
        FROM    oe_order_lines_all OOL
        WHERE   OOL.line_id = p_so_line_id;
    --To Check if the PO corresponds to a BackToBack or Dropship Sales Order
    CURSOR lcu_valid_po ( p_po_line_id IN  po_lines_all.po_line_id%TYPE)
    IS
        SELECT 'Y' po_so_link
              ,FDFC.descriptive_flex_context_code
        FROM  fnd_descr_flex_contexts FDFC
              ,po_lines_all PL
              ,po_headers_all PH
        WHERE FDFC.descriptive_flexfield_name = 'PO_HEADERS'
        AND FDFC.enabled_flag = 'Y'
        AND PH.po_header_id = PL.po_header_id
        AND PH.attribute_category = FDFC.descriptive_flex_context_code
        AND PL.po_line_id = p_po_line_id;
BEGIN
    -- Get the values from the Event key (Item Key) to the PO or SO Line Id
    lc_po_so_flag    :=  SUBSTR(p_item_key ,1,( INSTR( p_item_key,'-')-1));
    ln_po_so_line_id :=  SUBSTR(p_item_key,(INSTR( p_item_key, '-' )+1));
    IF lc_po_so_flag = 'PO' THEN
        FOR rec_valid_po IN lcu_valid_po (ln_po_so_line_id)
        LOOP
            IF rec_valid_po.po_so_link = 'Y'
              AND  rec_valid_po.descriptive_flex_context_code IN (
                                                                   gc_dropship_meaning
                                                                  ,gc_nc_dropship_meaning
                                                                  ,gc_backtoback_meaning
                                                                  ,gc_nc_backtoback_meaning
                                                                  ) THEN
                FOR rec_order_line_dtls_po IN lcu_order_line_dtls_po(ln_po_so_line_id)
                LOOP
                    lc_po_exist           := 'Y';
                    gn_po_line_id         := rec_order_line_dtls_po.po_line_id;
                    ln_inventory_item_id  := rec_order_line_dtls_po.inventory_item_id;
                    ln_customer_id        := rec_order_line_dtls_po.sold_to_org_id;
                    ln_organization_id    := rec_order_line_dtls_po.ship_from_org_id;
                    ln_extended_price     := rec_order_line_dtls_po.extended_price;
                    WF_ENGINE.SETITEMATTRNUMBER(
                                                 itemtype => p_item_type
                                                ,itemkey  => p_item_key
                                                ,aname    => 'OE_LINE_ID'
                                                ,avalue   => rec_order_line_dtls_po.line_id
                                                );
                    WF_ENGINE.SETITEMATTRNUMBER(
                                                 itemtype => p_item_type
                                                ,itemkey  => p_item_key
                                                ,aname    => 'QTY_CANCELLED'
                                                ,avalue   => rec_order_line_dtls_po.quantity_cancelled
                                                );
                    WF_ENGINE.SETITEMATTRNUMBER(
                                                 itemtype => p_item_type
                                                ,itemkey  => p_item_key
                                                ,aname    => 'QTY_RECEIVED'
                                                ,avalue   => rec_order_line_dtls_po.quantity_received
                                                );
                    WF_ENGINE.SETITEMATTRTEXT (
                                                 itemtype => p_item_type
                                                ,itemkey  => p_item_key
                                                ,aname    => 'SO_SOURCE_TYPE'
                                                ,avalue   => rec_order_line_dtls_po.descriptive_flex_context_code
                                                );
                    -- Passing ln_organization_id, ln_inventory_item_id, ln_extended_price and ln_customer_id to                     -- IS_BACKORDEREABLE API

	   -- **********************************************************************************************************
            -- The below code call to check for back order flag has been commented as this is not required for VW orders
            -- Release 2.0
                    /*ln_backorder_flag := XX_OM_BACKORDER_PKG.IS_BACKORDERABLE (
                                                                                 p_inventory_item_id  => ln_inventory_item_id
                                                                                ,p_organization_id    => ln_organization_id
                                                                                ,p_order_line_value   => ln_extended_price
                                                                                ,p_customer_id        => ln_customer_id
                                                                                );
                    -- If backorder_flag is 1 then, Fill path is taken, else Kill path
                    IF ln_backorder_flag = 1 THEN
                        lc_result_out := 'Y';
                    ELSIF ln_backorder_flag = 2  THEN
                        lc_result_out := 'N';
                    ELSE
                    RAISE EX_BACKORDER_FAILED;
                    END IF; */
            -- To take kill path pass the 'N' value always
                    lc_result_out := 'N';
             -- *********************************************************************************************************
                    -- Assigning the value to the workflow result parameter
                    IF  lc_result_out ='Y' THEN
                        x_result:= 'COMPLETE:'||'Y';
                    ELSIF lc_result_out ='N' THEN
                        x_result:= 'COMPLETE:'||'N';
                    END IF;
                END LOOP;
            ELSE
                -- PO Exists, but there is no corresponding B2B or Dropship Sales Order. So routing workflow to Invalid path
                lc_po_exist  := 'Y';
                x_result     := 'COMPLETE:'||'I';
            END IF;
        END LOOP;
    ELSIF lc_po_so_flag = 'SO' THEN
        FOR rec_order_line_dtls_so IN lcu_order_line_dtls_so(ln_po_so_line_id)
        LOOP
            lc_so_exist           := 'Y';
            ln_inventory_item_id  := rec_order_line_dtls_so.inventory_item_id;
            ln_customer_id        := rec_order_line_dtls_so.sold_to_org_id;
            ln_organization_id    := rec_order_line_dtls_so.ship_from_org_id;
            ln_extended_price     := rec_order_line_dtls_so.extended_price;
            WF_ENGINE.SETITEMATTRNUMBER (
                                             itemtype  => p_item_type
                                            ,itemkey  => p_item_key
                                            ,aname    => 'OE_LINE_ID'
                                            ,avalue   => rec_order_line_dtls_so.line_id
                                        );
            -- Passing ln_organization_id, ln_inventory_item_id and ln_extended_price to the BACKORDER API
            -- **********************************************************************************************************
            -- The below code call to check back order flag has been commented as this is not required for VW orders in
            -- Release 2.0
           /* ln_backorder_flag := XX_OM_BACKORDER_PKG.IS_BACKORDERABLE (
                                                                         p_inventory_item_id   => ln_inventory_item_id
                                                                        ,p_organization_id    => ln_organization_id
                                                                        ,p_order_line_value   => ln_extended_price
                                                                        ,p_customer_id        => ln_customer_id
                                                                       );
            -- If backorder_flag is 1 then, Fill path is taken, else Kill path
            IF ln_backorder_flag    = 1 THEN
                lc_result_out := 'Y';
            ELSIF ln_backorder_flag = 2  THEN
                lc_result_out := 'N';
            ELSE
                RAISE EX_BACKORDER_FAILED;
            END IF; */
            
            -- To take kill path pass the 'N' value always    
   
            lc_result_out := 'N';

            -- ***********************************************************************************************************
            -- Assigning the value to the workflow result parameter
            IF  lc_result_out ='Y' THEN
                x_result:= 'COMPLETE:'||'Y';
            ELSIF lc_result_out ='N' THEN
                x_result:= 'COMPLETE:'||'N';
            END IF;
        END LOOP;
    ELSE
        -- Invalid Sales Order or Purchase Order Line Id
        RAISE EX_SO_PO_NOT_EXISTS ;
    END IF;
    --When a invalid SO/PO line id is supplied
    IF lc_po_so_flag = 'SO'
      AND  NVL(lc_so_exist,'N')  <> 'Y' THEN
       RAISE EX_SO_PO_NOT_EXISTS ;
    ELSIF lc_po_so_flag = 'PO'
      AND  NVL(lc_po_exist,'N')  <> 'Y' THEN
       RAISE EX_SO_PO_NOT_EXISTS ;
    END IF;
EXCEPTION
WHEN EX_SO_PO_NOT_EXISTS THEN
    -- Calling the exception framework
    FND_MESSAGE.SET_NAME ( 'XXOM','XX_OM_0001_SO_PO_NOT_FOUND'  );
    lc_error_message      := FND_MESSAGE.GET;
    gc_err_code           := 'XX_OM_0001_SO_PO_NOT_FOUND';
    gc_err_desc           := SUBSTR(lc_error_message,1,1000);
    gc_entity_ref         := 'PO_SO_LINE_ID ';
    gn_entity_ref_id      := NVL(ln_po_so_line_id,0);
    gc_err_report_type    :=
                             XX_OM_REPORT_EXCEPTION_T (
                                                         gc_exception_header
                                                        ,gc_exception_track
                                                        ,gc_exception_sol_dom
                                                        ,gc_error_function
                                                        ,gc_err_code
                                                        ,gc_err_desc
                                                        ,gc_entity_ref
                                                        ,gn_entity_ref_id
                                                      );
    XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                   gc_err_report_type
                                                  ,lc_errbuff
                                                  ,lc_retcode
                                                );
    WF_CORE.CONTEXT(
                        ' XX_WFL_POACCREJ_PKG '
                        ,'KILL_FILL_PROC'
                        ,p_item_type
                        ,p_item_key
                        ,TO_CHAR(p_actid)
                        ,p_funcmode
                   );
    RAISE;
WHEN EX_BACKORDER_FAILED THEN
    -- Calling the exception framework
    FND_MESSAGE.SET_NAME ('XXOM','XX_OM_0016_BACKORDER_API_ERR' );
    lc_error_message      := FND_MESSAGE.GET;
    gc_err_code           := 'XX_OM_0016_BACKORDER_API_ERR';
    gc_err_desc           := SUBSTR(lc_error_message,1,1000);
    gc_entity_ref         := 'PO_SO_LINE_ID ';
    gn_entity_ref_id      := NVL(ln_po_so_line_id,0);
    gc_err_report_type    :=
                             XX_OM_REPORT_EXCEPTION_T (
                                                          gc_exception_header
                                                         ,gc_exception_track
                                                         ,gc_exception_sol_dom
                                                         ,gc_error_function
                                                         ,gc_err_code
                                                         ,gc_err_desc
                                                         ,gc_entity_ref
                                                         ,gn_entity_ref_id
                                                        );
    XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                  gc_err_report_type
                                                 ,lc_errbuff
                                                 ,lc_retcode
                                                );
    WF_CORE.CONTEXT(
                        ' XX_WFL_POACCREJ_PKG '
                        ,'KILL_FILL_PROC'
                        ,p_item_type
                        ,p_item_key
                        ,TO_CHAR(p_actid)
                        ,p_funcmode
                   );
    RAISE;
WHEN OTHERS THEN
    -- Calling the exception framework
    gc_err_code           := 'XX_OM_0002_FILL_KILL_ERROR';
    gc_err_desc           := SUBSTR(lc_error_message|| SQLERRM,1,1000);
    gc_entity_ref         := 'PO_SO_LINE_ID ';
    gn_entity_ref_id      := NVL(ln_po_so_line_id,0);
    gc_err_report_type    :=
                              XX_OM_REPORT_EXCEPTION_T (
                                                         gc_exception_header
                                                        ,gc_exception_track
                                                        ,gc_exception_sol_dom
                                                        ,gc_error_function
                                                        ,gc_err_code
                                                        ,gc_err_desc
                                                        ,gc_entity_ref
                                                        ,gn_entity_ref_id
                                                      );
    XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                   gc_err_report_type
                                                  ,lc_errbuff
                                                  ,lc_retcode
                                                );
    WF_CORE.CONTEXT(
                    ' XX_WFL_POACCREJ_PKG '
                    ,'KILL_FILL_PROC'
                    ,p_item_type
                    ,p_item_key
                    ,TO_CHAR(p_actid)
                    ,p_funcmode
                   );
    RAISE;
END FILL_KILL_PROC;
---------------------------------------------------------------------------------------------------------------------------
-- +===================================================================+
-- | Name             : PROCESSORDER                                   |
-- | Description      : This program process the order and cancels     |
-- |                    the line using the API                         |
-- |                    OE_ORDER_PUB.PROCESS_ORDER                     |
-- |                                                                   |
-- | Parameters       : p_process_type                                 |
-- |                    x_header_rec                                   |
-- |                    x_header_adj_tbl                               |
-- |                    x_order_lines_tbl                              |
-- |                    x_line_adj_tbl                                 |
-- |                    p_request_tbl                                  |
-- |                                                                   |
-- | Returns          : x_order_lines_tbl_out                          |
-- |                    x_return_status                                |
-- |                    x_return_message                               |
-- +===================================================================+
PROCEDURE PROCESSORDER (
                        p_process_type          IN              VARCHAR2 DEFAULT 'API'
                       ,x_header_rec            IN OUT NOCOPY   OE_ORDER_PUB.HEADER_REC_TYPE
                       ,x_header_adj_tbl        IN OUT NOCOPY   OE_ORDER_PUB.HEADER_ADJ_TBL_TYPE
                       ,x_order_lines_tbl       IN OUT NOCOPY   OE_ORDER_PUB.LINE_TBL_TYPE
                       ,x_line_adj_tbl          IN OUT NOCOPY   OE_ORDER_PUB.LINE_ADJ_TBL_TYPE
                       ,p_request_tbl           IN              OE_ORDER_PUB.REQUEST_TBL_TYPE
                       ,x_order_lines_tbl_out   OUT             OE_ORDER_PUB.LINE_TBL_TYPE
                       ,x_return_status         OUT             VARCHAR2
                       ,x_return_message        OUT             VARCHAR2
                       )
IS
    -- Declaring Local Variables
    lr_header                   OE_ORDER_PUB.HEADER_REC_TYPE;
    lr_header_val               OE_ORDER_PUB.HEADER_VAL_REC_TYPE;
    lt_header_adj               OE_ORDER_PUB.HEADER_ADJ_TBL_TYPE;
    lt_header_adj_val           OE_ORDER_PUB.HEADER_ADJ_VAL_TBL_TYPE;
    lt_header_price_att         OE_ORDER_PUB.HEADER_PRICE_ATT_TBL_TYPE;
    lt_header_adj_att           OE_ORDER_PUB.HEADER_ADJ_ATT_TBL_TYPE;
    lt_header_adj_assoc         OE_ORDER_PUB.HEADER_ADJ_ASSOC_TBL_TYPE;
    lt_header_scredit           OE_ORDER_PUB.HEADER_SCREDIT_TBL_TYPE;
    lt_header_scredit_val       OE_ORDER_PUB.HEADER_SCREDIT_VAL_TBL_TYPE;
    lt_line                     OE_ORDER_PUB.LINE_TBL_TYPE;
    lt_line_out                 OE_ORDER_PUB.LINE_TBL_TYPE;
    lt_line_val                 OE_ORDER_PUB.LINE_VAL_TBL_TYPE;
    lt_line_adj                 OE_ORDER_PUB.LINE_ADJ_TBL_TYPE;
    lt_line_adj_val             OE_ORDER_PUB.LINE_ADJ_VAL_TBL_TYPE;
    lt_line_price_att           OE_ORDER_PUB.LINE_PRICE_ATT_TBL_TYPE;
    lt_line_adj_att             OE_ORDER_PUB.LINE_ADJ_ATT_TBL_TYPE;
    lt_line_adj_assoc           OE_ORDER_PUB.LINE_ADJ_ASSOC_TBL_TYPE;
    lt_line_scredit             OE_ORDER_PUB.LINE_SCREDIT_TBL_TYPE;
    lt_line_scredit_val         OE_ORDER_PUB.LINE_SCREDIT_VAL_TBL_TYPE;
    lt_lot_serial               OE_ORDER_PUB.LOT_SERIAL_TBL_TYPE;
    lt_lot_serial_val           OE_ORDER_PUB.LOT_SERIAL_VAL_TBL_TYPE;
    lt_action_request           OE_ORDER_PUB.REQUEST_TBL_TYPE;
    lc_return_status            VARCHAR2 (10)  := FND_API.G_RET_STS_SUCCESS;
    ln_om_api_version           NUMBER         := 1.0;
    ln_msg_count                NUMBER;
    ln_msg_index_out            NUMBER;
    lc_return_message           VARCHAR2 (4000);
    lc_msg_data                 VARCHAR2 (4000);
    lc_errbuff                  VARCHAR2 (1000);
    lc_retcode                  VARCHAR2 (100);
    lc_error_message            VARCHAR2 (1000);
    lc_err_message              VARCHAR2 (1000);
    EX_PROCESSORDER_ERROR       EXCEPTION;
BEGIN
    -- Table structures initialization
    lt_line.DELETE;
    lt_header_adj.DELETE;
    lt_header_adj_val.DELETE;
    lt_header_price_att.DELETE;
    lt_header_adj_att.DELETE;
    lt_header_adj_assoc.DELETE;
    lt_header_scredit.DELETE;
    lt_header_scredit_val.DELETE;
    lt_line.DELETE;
    lt_line_out.DELETE;
    lt_line_val.DELETE;
    lt_line_adj.DELETE;
    lt_line_adj_val.DELETE;
    lt_line_price_att.DELETE;
    lt_line_adj_att.DELETE;
    lt_line_adj_assoc.DELETE;
    lt_line_scredit.DELETE;
    lt_line_scredit_val.DELETE;
    lt_lot_serial.DELETE;
    lt_lot_serial_val.DELETE;
    lt_action_request.DELETE;
    -- Record structures initialization
    lr_header                  := OE_ORDER_PUB.G_MISS_HEADER_REC;
    lr_header_val              := OE_ORDER_PUB.G_MISS_HEADER_VAL_REC;
    lt_header_adj              := OE_ORDER_PUB.G_MISS_HEADER_ADJ_TBL;
    lt_header_adj_val          := OE_ORDER_PUB.G_MISS_HEADER_ADJ_VAL_TBL;
    lt_header_price_att        := OE_ORDER_PUB.G_MISS_HEADER_PRICE_ATT_TBL;
    lt_header_adj_att          := OE_ORDER_PUB.G_MISS_HEADER_ADJ_ATT_TBL;
    lt_header_adj_assoc        := OE_ORDER_PUB.G_MISS_HEADER_ADJ_ASSOC_TBL;
    lt_header_scredit          := OE_ORDER_PUB.G_MISS_HEADER_SCREDIT_TBL;
    lt_header_scredit_val      := OE_ORDER_PUB.G_MISS_HEADER_SCREDIT_VAL_TBL;
    lt_line                    := OE_ORDER_PUB.G_MISS_LINE_TBL;
    lt_line_out                := OE_ORDER_PUB.G_MISS_LINE_TBL;
    lt_line_val                := OE_ORDER_PUB.G_MISS_LINE_VAL_TBL;
    lt_line_adj                := OE_ORDER_PUB.G_MISS_LINE_ADJ_TBL;
    lt_line_adj_val            := OE_ORDER_PUB.G_MISS_LINE_ADJ_VAL_TBL;
    lt_line_price_att          := OE_ORDER_PUB.G_MISS_LINE_PRICE_ATT_TBL;
    lt_line_adj_att            := OE_ORDER_PUB.G_MISS_LINE_ADJ_ATT_TBL;
    lt_line_adj_assoc          := OE_ORDER_PUB.G_MISS_LINE_ADJ_ASSOC_TBL;
    lt_line_scredit            := OE_ORDER_PUB.G_MISS_LINE_SCREDIT_TBL;
    lt_line_scredit_val        := OE_ORDER_PUB.G_MISS_LINE_SCREDIT_VAL_TBL;
    lt_lot_serial              := OE_ORDER_PUB.G_MISS_LOT_SERIAL_TBL;
    lt_lot_serial_val          := OE_ORDER_PUB.G_MISS_LOT_SERIAL_VAL_TBL;
    lt_action_request          := OE_ORDER_PUB.G_MISS_REQUEST_TBL;
    -- Assigning values to the record types
    lr_header                  := x_header_rec;
    lt_header_adj              := x_header_adj_tbl;
    lt_line                    := x_order_lines_tbl;
    lt_line_adj                := x_line_adj_tbl;
    lt_action_request          := p_request_tbl;
    -- Initializing debug otions
    OE_DEBUG_PUB.INITIALIZE;
    OE_DEBUG_PUB.DEBUG_ON;
    OE_DEBUG_PUB.SETDEBUGLEVEL(1);
    OE_ORDER_PUB.PROCESS_ORDER(
                                   p_api_version_number          => ln_om_api_version
                                  ,p_init_msg_list               => fnd_api.g_true
                                  ,p_return_values               => fnd_api.g_false
                                  ,p_action_commit               => fnd_api.g_false
                                  ,p_action_request_tbl          => lt_action_request
                                  ,p_header_rec                  => lr_header
                                  ,p_header_val_rec              => lr_header_val
                                  ,p_header_adj_tbl              => lt_header_adj
                                  ,p_header_adj_val_tbl          => lt_header_adj_val
                                  ,p_header_price_att_tbl        => lt_header_price_att
                                  ,p_header_adj_att_tbl          => lt_header_adj_att
                                  ,p_header_adj_assoc_tbl        => lt_header_adj_assoc
                                  ,p_header_scredit_tbl          => lt_header_scredit
                                  ,p_header_scredit_val_tbl      => lt_header_scredit_val
                                  ,p_line_tbl                    => lt_line
                                  ,p_line_val_tbl                => lt_line_val
                                  ,p_line_adj_tbl                => lt_line_adj
                                  ,p_line_adj_val_tbl            => lt_line_adj_val
                                  ,p_line_price_att_tbl          => lt_line_price_att
                                  ,p_line_adj_att_tbl            => lt_line_adj_att
                                  ,p_line_adj_assoc_tbl          => lt_line_adj_assoc
                                  ,p_line_scredit_tbl            => lt_line_scredit
                                  ,p_line_scredit_val_tbl        => lt_line_scredit_val
                                  ,p_lot_serial_tbl              => lt_lot_serial
                                  ,p_lot_serial_val_tbl          => lt_lot_serial_val
                                  ,x_header_rec                  => lr_header
                                  ,x_header_val_rec              => lr_header_val
                                  ,x_header_adj_tbl              => lt_header_adj
                                  ,x_header_adj_val_tbl          => lt_header_adj_val
                                  ,x_header_price_att_tbl        => lt_header_price_att
                                  ,x_header_adj_att_tbl          => lt_header_adj_att
                                  ,x_header_adj_assoc_tbl        => lt_header_adj_assoc
                                  ,x_header_scredit_tbl          => lt_header_scredit
                                  ,x_header_scredit_val_tbl      => lt_header_scredit_val
                                  ,x_line_tbl                    => lt_line_out
                                  ,x_line_val_tbl                => lt_line_val
                                  ,x_line_adj_tbl                => lt_line_adj
                                  ,x_line_adj_val_tbl            => lt_line_adj_val
                                  ,x_line_price_att_tbl          => lt_line_price_att
                                  ,x_line_adj_att_tbl            => lt_line_adj_att
                                  ,x_line_adj_assoc_tbl          => lt_line_adj_assoc
                                  ,x_line_scredit_tbl            => lt_line_scredit
                                  ,x_line_scredit_val_tbl        => lt_line_scredit_val
                                  ,x_lot_serial_tbl              => lt_lot_serial
                                  ,x_lot_serial_val_tbl          => lt_lot_serial_val
                                  ,x_action_request_tbl          => lt_action_request
                                  ,x_return_status               => lc_return_status
                                  ,x_msg_count                   => ln_msg_count
                                  ,x_msg_data                    => lc_msg_data
                                  );
    x_order_lines_tbl_out:= lt_line_out;
    IF NVL(lc_return_status,'E') <> FND_API.G_RET_STS_SUCCESS THEN
        FOR i IN 1 .. ln_msg_count
        LOOP
             OE_MSG_PUB.GET (
                               p_msg_index          => i
                              ,p_encoded            => FND_API.G_FALSE
                              ,p_data               => lc_msg_data
                              ,p_msg_index_out      => ln_msg_index_out
                            );
             lc_return_message := lc_return_message || ' ' || lc_msg_data;
        END LOOP;
        x_return_status  := FND_API.G_RET_STS_ERROR;
        x_return_message := lc_return_message;
        gc_err_code      := 'XX_OM_0003_PROCESS_ORDER_ERR';
        FND_MESSAGE.SET_NAME ('XXOM' ,'XX_OM_0003_PROCESS_ORDER_ERR' );
        lc_err_message   := FND_MESSAGE.GET;
        gc_err_desc      := SUBSTR( lc_err_message||' '||lc_return_message,1,1000 );
        gc_entity_ref    := 'Header id';
        gn_entity_ref_id := NVL(lt_line(1).header_id,0);
        RAISE EX_PROCESSORDER_ERROR;
    END IF;
    x_return_status  := FND_API.G_RET_STS_SUCCESS;
    x_return_message := lc_return_message;
EXCEPTION
WHEN EX_PROCESSORDER_ERROR THEN
    -- Calling the exception framework
    gc_err_report_type :=
    XX_OM_REPORT_EXCEPTION_T (
                                  gc_exception_header
                                 ,gc_exception_track
                                 ,gc_exception_sol_dom
                                 ,gc_error_function
                                 ,gc_err_code
                                 ,gc_err_desc
                                 ,gc_entity_ref
                                 ,gn_entity_ref_id
                             );
    XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                   gc_err_report_type
                                                  ,lc_errbuff
                                                  ,lc_retcode
                                                );
WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0004_PROCESS_ORDER_ERR');
    lc_error_message      := FND_MESSAGE.GET;
    gc_err_code           := 'XX_OM_0004_PROCESS_ORDER_ERR';
    gc_err_desc           := SUBSTR(lc_error_message|| SQLERRM,1,1000);
    gc_entity_ref         := 'header id';
    gn_entity_ref_id      := NVL(lt_line(1).header_id,0);
    -- Calling the exception framework
    gc_err_report_type    :=
    XX_OM_REPORT_EXCEPTION_T (
                               gc_exception_header
                              ,gc_exception_track
                              ,gc_exception_sol_dom
                              ,gc_error_function
                              ,gc_err_code
                              ,gc_err_desc
                              ,gc_entity_ref
                              ,gn_entity_ref_id
                             );
    XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                 gc_err_report_type
                                                ,lc_errbuff
                                                ,lc_retcode
                                                );
    x_return_status  := FND_API.G_RET_STS_ERROR;
    x_return_message := SUBSTR( SQLERRM,1,1000);
  END PROCESSORDER;
--------------------------------------------------------------------------------------------------------------------------
-- +======================================================================+
-- | Name             : CANCEL_OE_LINE_PROC                               |
-- | Description      : This program cancels the order line using the     |
-- |                   cancel_line procedure                              |
-- |                                                                      |
-- | Parameters       : p_item_type                                       |
-- |                    p_item_key                                        |
-- |                    p_actid                                           |
-- |                    p_funcmode                                        |
-- |                                                                      |
-- |                                                                      |
-- | Returns          : x_result                                          |
-- |                                                                      |
-- +======================================================================+
PROCEDURE CANCEL_OE_LINE_PROC (
                                 p_item_type   IN  VARCHAR2
                                ,p_item_key    IN  VARCHAR2
                                ,p_actid       IN  NUMBER
                                ,p_funcmode    IN  VARCHAR2
                                ,x_result      OUT VARCHAR2
                              )
IS
    -- Declaring local variables
    lc_return_status              VARCHAR2 (10)  ;
    lc_return_message             VARCHAR2 (4000);
    lc_errbuff                    VARCHAR2 (1000);
    lc_retcode                    VARCHAR2 (100) ;
    lc_error_message              VARCHAR2 (1000);
    ln_line_id                    oe_order_lines_all.line_id%TYPE;
    lc_source_type                po_headers_all.attribute_category%TYPE;
    EX_SPLIT_LINE_ERROR           EXCEPTION;
    EX_CANCEL_OE_LINE_ERROR       EXCEPTION;
    -- To fetch the SO line details.
    CURSOR lcu_order_line_dtls( p_line_id oe_order_lines_all.line_id%TYPE )
    IS
        SELECT  OOL.line_id
               ,OOL.ordered_quantity
        FROM   oe_order_lines_all OOL
        WHERE  OOL.line_id = p_line_id;
    -- To get the Line details of the line split.
    CURSOR lcu_split_order_line_dtls ( p_line_id  oe_order_lines_all.line_id%TYPE)
    IS
          SELECT  OOL.line_id
           FROM  oe_order_lines_all OOL
          WHERE  OOL.split_from_line_id = p_line_id;            
BEGIN
    -- Assign the SO Line Id from the attribute to the variable
    ln_line_id       :=  WF_ENGINE.GETITEMATTRNUMBER (
                                                  itemtype => p_item_type
                                                 ,itemkey  => p_item_key
                                                 ,aname    => 'OE_LINE_ID'
                                                );
    lc_source_type   :=  WF_ENGINE.GETITEMATTRTEXT (
                                                      itemtype => p_item_type
                                                     ,itemkey  => p_item_key
                                                     ,aname    => 'SO_SOURCE_TYPE'
                                                      );
    gn_qty_received  := WF_ENGINE.GETITEMATTRNUMBER (
                                                      itemtype => p_item_type
                                                     ,itemkey  => p_item_key
                                                     ,aname    => 'QTY_RECEIVED'
                                                     );
    gn_qty_cancelled := WF_ENGINE.GetItemAttrText (
                                                    p_item_type
                                                   ,p_item_key
                                                   ,'QTY_CANCELLED'
                                                   );
    FOR rec_order_line_dtls IN lcu_order_line_dtls(ln_line_id)
    LOOP
        --Check if it is a partially received B2B SO.
        IF ((rec_order_line_dtls.ordered_quantity <> gn_qty_received)
          AND ( lc_source_type IN ('BackToBack', 'Non-Code BackToBack') )
          AND ( gn_qty_received <> 0 ) ) THEN
            --Split the sales order line in case of a partially received BackToBack Sales Order
            SPLIT_LINE (
                         p_line_id        =>  rec_order_line_dtls.line_id
                        ,x_return_status  => lc_return_status
                        ,x_return_message => lc_return_message
                       );
            IF NVL(lc_return_status,'E') <> FND_API.G_RET_STS_SUCCESS THEN
                gc_err_code        := 'XX_OM_0010_SPLIT_LINE_ERR';
                FND_MESSAGE.SET_NAME ( 'XXOM' ,'XX_OM_0010_SPLIT_LINE_ERR' );
                lc_error_message   := FND_MESSAGE.GET;
                gc_err_desc        := SUBSTR( lc_error_message||' '||lc_return_message,1,1000 );
                gc_entity_ref      := 'Order Line Id';
                gn_entity_ref_id   := NVL(ln_line_id,0);
                RAISE EX_SPLIT_LINE_ERROR;
            END IF;
            -- Fetch the split line and create a new Sales Order line
            FOR rec_split_order_line_dtls IN lcu_split_order_line_dtls (rec_order_line_dtls.line_id )
            LOOP
                -- Call Cancel_line procedure to cancel the SO Line
                CANCEL_LINE(
                               p_line_id        => rec_split_order_line_dtls.line_id
                              ,x_return_status  => lc_return_status
                              ,x_return_message => lc_return_message
                             );
                IF ( NVL(lc_return_status,'E') <> FND_API.G_RET_STS_SUCCESS ) THEN
                    gc_err_code         := 'XX_OM_0005_CANCEL_OE_LINE_ERR';
                    FND_MESSAGE.SET_NAME ( 'XXOM' ,'XX_OM_0005_CANCEL_OE_LINE_ERR' );
                    lc_error_message    := FND_MESSAGE.GET;
                    gc_err_desc         := SUBSTR( lc_error_message||' '||lc_return_message,1,1000 );
                    gc_entity_ref       := 'Order Line Id';
                    gn_entity_ref_id    := NVL(ln_line_id,0);
                    RAISE EX_CANCEL_OE_LINE_ERROR;
                END IF;
            END LOOP;
        ELSE
            -- Call Cancel_line procedure to cancel the SO Line
            CANCEL_LINE(
                           p_line_id        => ln_line_id
                          ,x_return_status  => lc_return_status
                          ,x_return_message => lc_return_message
                         );
            IF ( NVL(lc_return_status,'E') <> FND_API.G_RET_STS_SUCCESS ) THEN
                gc_err_code         := 'XX_OM_0005_CANCEL_OE_LINE_ERR';
                FND_MESSAGE.SET_NAME ( 'XXOM' ,'XX_OM_0005_CANCEL_OE_LINE_ERR' );
                lc_error_message    := FND_MESSAGE.GET;
                gc_err_desc         := SUBSTR( lc_error_message||' '||lc_return_message,1,1000 );
                gc_entity_ref       := 'Order Line Id';
                gn_entity_ref_id    := NVL(ln_line_id,0);
                RAISE EX_CANCEL_OE_LINE_ERROR;
            END IF;
        END IF;       
    END LOOP;
EXCEPTION
    WHEN EX_SPLIT_LINE_ERROR THEN
        -- Calling the exception framework
        gc_err_report_type :=
        XX_OM_REPORT_EXCEPTION_T (
                                  gc_exception_header
                                 ,gc_exception_track
                                 ,gc_exception_sol_dom
                                 ,gc_error_function
                                 ,gc_err_code
                                 ,gc_err_desc
                                 ,gc_entity_ref
                                 ,gn_entity_ref_id
                             );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                       gc_err_report_type
                                                      ,lc_errbuff
                                                      ,lc_retcode
                                                     );
        WF_CORE.CONTEXT(
                             ' XX_WFL_POACCREJ_PKG '
                             ,'CREATE_OE_LINE_PROC'
                             ,p_item_type
                             ,p_item_key
                             ,TO_CHAR(p_actid)
                             ,p_funcmode
                       );
        RAISE;
    WHEN EX_CANCEL_OE_LINE_ERROR THEN
        -- Calling the exception framework
        gc_err_report_type :=
        XX_OM_REPORT_EXCEPTION_T (
                                    gc_exception_header
                                   ,gc_exception_track
                                   ,gc_exception_sol_dom
                                   ,gc_error_function
                                   ,gc_err_code
                                   ,gc_err_desc
                                   ,gc_entity_ref
                                   ,gn_entity_ref_id
                                 );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                         gc_err_report_type
                                                        ,lc_errbuff
                                                        ,lc_retcode
                                                     );
        WF_CORE.CONTEXT(
                        ' XX_WFL_POACCREJ_PKG '
                        ,'CANCEL_OE_LINE_PROC'
                        ,p_item_type
                        ,p_item_key
                        ,TO_CHAR(p_actid)
                        ,p_funcmode
                   );
        RAISE;
    WHEN OTHERS THEN
        FND_MESSAGE.SET_NAME ('XXOM','XX_OM_0006_CANCEL_OE_LINE_ERR');
        lc_error_message      := FND_MESSAGE.GET;
        gc_err_code           := 'XX_OM_0006_CANCEL_OE_LINE_ERR';
        gc_err_desc           := SUBSTR( lc_error_message||SQLERRM,1,1000);
        gc_entity_ref         := 'Order Line Id';
        gn_entity_ref_id      := NVL(ln_line_id,0);
        -- Calling the exception framework
        gc_err_report_type    :=
        XX_OM_REPORT_EXCEPTION_T (
                                  gc_exception_header
                                 ,gc_exception_track
                                 ,gc_exception_sol_dom
                                 ,gc_error_function
                                 ,gc_err_code
                                 ,gc_err_desc
                                 ,gc_entity_ref
                                 ,gn_entity_ref_id
                                );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                     gc_err_report_type
                                                    ,lc_errbuff
                                                    ,lc_retcode
                                                   );
        WF_CORE.CONTEXT(
                         ' XX_WFL_POACCREJ_PKG '
                         ,'CANCEL_OE_LINE_PROC'
                        ,p_item_type
                        ,p_item_key
                        ,TO_CHAR(p_actid)
                        ,p_funcmode
                   );
        RAISE;
END CANCEL_OE_LINE_PROC;
------------------------------------------------------------------------------------------------------------------------------------------------
-- +======================================================================+
-- | Name:               CANCEL_LINE                                      |
-- | Description:        This program cancels the sales order line using  |
-- |                     the OE_ORDER_PUB.PROCESS_ORDER API               |
-- |                                                                      |
-- | Parameters:         p_line_id                                        |
-- |                                                                      |
-- | Returns:            x_return_status                                  |
-- |                     x_return_message                                 |
-- |                                                                      |
-- +======================================================================+
PROCEDURE CANCEL_LINE (
                         p_line_id          IN       oe_order_lines_all.line_id%TYPE
                        ,x_return_status    OUT      VARCHAR2
                        ,x_return_message   OUT      VARCHAR2
                       )
IS
    -- Declaring local variables
    lt_action_request           OE_ORDER_PUB.REQUEST_TBL_TYPE    := OE_ORDER_PUB.G_MISS_REQUEST_TBL;
    lr_header                   OE_ORDER_PUB.HEADER_REC_TYPE     := OE_ORDER_PUB.G_MISS_HEADER_REC;
    lt_header_adj               OE_ORDER_PUB.HEADER_ADJ_TBL_TYPE := OE_ORDER_PUB.G_MISS_HEADER_ADJ_TBL;
    lt_order_lines              OE_ORDER_PUB.LINE_TBL_TYPE       := OE_ORDER_PUB.G_MISS_LINE_TBL;
    lt_line_out                 OE_ORDER_PUB.LINE_TBL_TYPE       := OE_ORDER_PUB.G_MISS_LINE_TBL;
    lt_line_adj                 OE_ORDER_PUB.LINE_ADJ_TBL_TYPE   := OE_ORDER_PUB.G_MISS_LINE_ADJ_TBL;
    lc_return_status            VARCHAR2 (10)                    := FND_API.G_RET_STS_SUCCESS;
    lc_return_message           VARCHAR2 (4000);
    lc_errbuff                  VARCHAR2 (1000);
    lc_retcode                  VARCHAR2 (100);
    lc_error_message            VARCHAR2 (1000);
    lc_msg_data                 VARCHAR2(4000);
    ln_msg_count                NUMBER;
    lt_req_header_id            PO_TBL_NUMBER;
    lt_req_line_id              PO_TBL_NUMBER;
    EX_CANCEL_LINE_ERROR        EXCEPTION;
    EX_CANCEL_REQ_LINE_ERROR    EXCEPTION;
    --To fetch the Sales Order line details
    CURSOR lcu_order_line_dtls( p_line_id oe_order_lines_all.line_id%TYPE)
    IS
        SELECT   OOL.line_id
                ,OOL.header_id
                ,OOL.orig_sys_document_ref
                ,OOL.orig_sys_line_ref
        FROM   oe_order_lines_all OOL
        WHERE  OOL.line_id = p_line_id;
    --To fetch the requisition line details
    CURSOR lcu_req_dtls 
    IS
    SELECT PRL1.requisition_line_id
          ,PRL1.requisition_header_id
    FROM   po_req_distributions_all PRD1
           ,po_requisition_lines_all PRL1     
    WHERE PRD1.requisition_line_id = PRL1.requisition_line_id  
    AND   PRD1.distribution_id = 
                                (   
                                  SELECT REQ_DIST (PRD.distribution_id)
                                  FROM   po_req_distributions_all PRD
                                        ,po_distributions_archive_all PDA
                                        ,po_requisition_lines_all PRL
                                        ,po_change_requests PCR 
                                        ,po_lines_all PL
                                   WHERE PRD.requisition_line_id    = PRL.requisition_line_id
                                   AND   PRD.distribution_id = PDA.req_distribution_id
                                   AND   PDA.po_line_Id      = PL.po_line_Id     
                                   AND   PL.po_line_id       = PCR.document_line_id       
                                   AND   PL.po_header_id     = PCR.document_header_id
                                   AND   PDA.REVISION_NUM    = 0
                                   AND   PL.PO_LINE_ID       = gn_po_line_id);
BEGIN
    FOR rec_order_line_dtls IN lcu_order_line_dtls(p_line_id)
    LOOP
            -- Initializing record for creating new sales order line
            lt_order_lines (1)                            := OE_ORDER_PUB.G_MISS_LINE_REC;
            lt_order_lines (1).line_id                    := rec_order_line_dtls.line_id;
            lt_order_lines (1).header_id                  := rec_order_line_dtls.header_id;
            lt_order_lines (1).ordered_quantity           := 0;
            lt_order_lines (1).cancelled_flag             := 'Y' ;
            lt_order_lines (1).orig_sys_document_ref      := 'OLD-'|| rec_order_line_dtls.orig_sys_document_ref;
            lt_order_lines (1).orig_sys_line_ref          := 'OLD-'|| rec_order_line_dtls.orig_sys_line_ref;
            lt_order_lines (1).change_reason              := gc_change_reason;
        lt_order_lines (1).OPERATION                      := OE_GLOBALS.G_OPR_UPDATE;
        -- call the processorder to cancel the Sales Order line
        PROCESSORDER(
                        p_process_type           => 'API'
                        ,x_header_rec            => lr_header
                        ,x_header_adj_tbl        => lt_header_adj
                        ,x_order_lines_tbl       => lt_order_lines
                        ,x_line_adj_tbl          => lt_line_adj
                        ,p_request_tbl           => lt_action_request
                        ,x_order_lines_tbl_out   => lt_line_out
                        ,x_return_status         => lc_return_status
                        ,x_return_message        => lc_return_message
                   );
        IF lc_return_status <> 'S' THEN
            x_return_status  := FND_API.G_RET_STS_ERROR;
            x_return_message := lc_return_message;
            gc_err_code      := 'XX_OM_0005_CANCEL_OE_LINE_ERR';
            FND_MESSAGE.SET_NAME ( 'XXOM' ,'XX_OM_0005_CANCEL_OE_LINE_ERR' );
            lc_error_message := FND_MESSAGE.GET;
            gc_err_desc      := SUBSTR( lc_error_message||' '||lc_return_message,1,1000 );
            gc_entity_ref    := 'Order Line Id';
            gn_entity_ref_id := NVL(p_line_id,0);
            RAISE EX_CANCEL_LINE_ERROR;
        END IF;
        --Cancel the requisition line for BackToBack Sales Order when cancelled from ISP.
        FOR rec_req_dtls IN  lcu_req_dtls
        LOOP
            lt_req_header_id := po_tbl_number(rec_req_dtls.requisition_header_id);
            lt_req_line_id   := po_tbl_number(rec_req_dtls.requisition_line_id);
            PO_REQ_DOCUMENT_CANCEL_GRP.CANCEL_REQUISITION (
                                                               p_api_version            => 1.0
                                                              ,p_req_header_id          => lt_req_header_id
                                                              ,p_req_line_id            => lt_req_line_id
                                                              ,p_cancel_date            => SYSDATE
                                                              ,p_cancel_reason          => NULL
                                                              ,p_source                 => NULL
                                                              ,x_return_status          => lc_return_status
                                                              ,x_msg_count              => ln_msg_count
                                                              ,x_msg_data               => lc_msg_data
                                                          );
            IF lc_return_status <> 'S' THEN
                --getting the error message from error stack.
                IF FND_MSG_PUB.count_msg > 0 THEN
                    FOR i IN 1..FND_MSG_PUB.count_msg
                    LOOP
                        lc_msg_data := lc_msg_data || '  ' || FND_MSG_PUB.GET(
                                                                                p_msg_index => i
                                                                                ,p_encoded  => 'F'
                                                                              );
                    END LOOP;
                END IF;
                x_return_status  := lc_return_status;
                x_return_message := lc_msg_data;
                gc_err_code      := 'XX_OM_0007_CANCEL_REQ_LINE_ERR';
                FND_MESSAGE.SET_NAME ('XXOM' ,'XX_OM_0007_CANCEL_REQ_LINE_ERR' );
                lc_error_message := FND_MESSAGE.GET;
                RAISE EX_CANCEL_REQ_LINE_ERROR;
            END IF;
        END LOOP;
    END LOOP;
    x_return_status  := lc_return_status;
    x_return_message := lc_return_message;
EXCEPTION
    WHEN EX_CANCEL_LINE_ERROR THEN
        -- Calling the exception framework
        gc_err_report_type :=
        XX_OM_REPORT_EXCEPTION_T (
                                  gc_exception_header
                                 ,gc_exception_track
                                 ,gc_exception_sol_dom
                                 ,gc_error_function
                                 ,gc_err_code
                                 ,gc_err_desc
                                 ,gc_entity_ref
                                 ,gn_entity_ref_id
                                );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                      gc_err_report_type
                                                     ,lc_errbuff
                                                     ,lc_retcode
                                                    );
    WHEN EX_CANCEL_REQ_LINE_ERROR THEN
        -- Calling the exception framework
        gc_err_report_type :=
        XX_OM_REPORT_EXCEPTION_T (
                                  gc_exception_header
                                 ,gc_exception_track
                                 ,gc_exception_sol_dom
                                 ,gc_error_function
                                 ,gc_err_code
                                 ,gc_err_desc
                                 ,gc_entity_ref
                                 ,gn_entity_ref_id
                                  );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                      gc_err_report_type
                                                     ,lc_errbuff
                                                     ,lc_retcode
                                                     );
    WHEN OTHERS THEN
        FND_MESSAGE.SET_NAME ('XXOM','XX_OM_0009_CANCEL_LINE_ERR');
        lc_error_message      := FND_MESSAGE.GET;
        gc_err_code           := 'XX_OM_0009_CANCEL_LINE_ERR';
        gc_err_desc           := SUBSTR( lc_error_message||SQLERRM,1,1000);
        gc_entity_ref         := 'Order Line Id';
        gn_entity_ref_id      := NVL(p_line_id,0);
        -- Calling the exception framework
        gc_err_report_type    :=
        XX_OM_REPORT_EXCEPTION_T (
                                      gc_exception_header
                                     ,gc_exception_track
                                     ,gc_exception_sol_dom
                                     ,gc_error_function
                                     ,gc_err_code
                                     ,gc_err_desc
                                     ,gc_entity_ref
                                     ,gn_entity_ref_id
                                 );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                         gc_err_report_type
                                                        ,lc_errbuff
                                                        ,lc_retcode
                                                     );
         x_return_status  := FND_API.G_RET_STS_ERROR;
         x_return_message := SUBSTR( SQLERRM,1,1000);
END CANCEL_LINE;
-------------------------------------------------------------------------------------------------------------------------------------
-- +======================================================================+
-- | Name             : CREATE_OE_LINE_PROC                               |
-- | Description      : This program creates a new order line along with  |
-- |                    line attributes create_line procedure.            |
-- |                    Cancels the existing order line using             |
-- |                    cancel_line procedure.                            |
-- |                                                                      |
-- | Parameters       : p_item_type                                       |
-- |                    p_item_key                                        |
-- |                    p_actid                                           |
-- |                    p_funcmode                                        |
-- |                                                                      |
-- |                                                                      |
-- | Returns          : x_result                                          |
-- |                                                                      |
-- +======================================================================+
PROCEDURE CREATE_OE_LINE_PROC (
                                 p_item_type   IN  VARCHAR2
                                ,p_item_key    IN  VARCHAR2
                                ,p_actid       IN  NUMBER
                                ,p_funcmode    IN  VARCHAR2
                                ,x_result      OUT VARCHAR2
                              )
IS
    --Declaring local variables
    lc_return_status      VARCHAR2 (10)  := FND_API.G_RET_STS_SUCCESS;
    lc_return_message     VARCHAR2 (4000);
    lc_errbuff            VARCHAR2 (1000);
    lc_retcode            VARCHAR2 (100);
    lc_error_message      VARCHAR2 (1000);
    lc_source_type        po_headers_all.attribute_category%TYPE;
    EX_SPLIT_LINE_ERROR   EXCEPTION;
    EX_CREATE_LINE_ERROR  EXCEPTION;
    EX_CANCEL_LINE_ERROR  EXCEPTION;
    -- To fetch the SO line details.
    CURSOR lcu_order_line_dtls( p_line_id oe_order_lines_all.line_id%TYPE )
    IS
        SELECT  OOL.line_id
               ,OOL.ordered_quantity
        FROM   oe_order_lines_all OOL
        WHERE  OOL.line_id = p_line_id;
    -- To get the Line details of the line split.
    CURSOR lcu_split_order_line_dtls ( p_line_id  oe_order_lines_all.line_id%TYPE)
    IS
        SELECT  OOL.line_id
        FROM    oe_order_lines_all OOL
        WHERE  OOL.split_from_line_id = p_line_id;
BEGIN
    -- Fetch the workflow attribute values into the pl/sql variables.
    gn_line_id       :=  WF_ENGINE.GETITEMATTRNUMBER (
                                                       itemtype => p_item_type
                                                       ,itemkey  => p_item_key
                                                       ,aname    => 'OE_LINE_ID'
                                                       );
    lc_source_type   :=  WF_ENGINE.GETITEMATTRTEXT (
                                                      itemtype => p_item_type
                                                     ,itemkey  => p_item_key
                                                     ,aname    => 'SO_SOURCE_TYPE'
                                                      );
    gn_qty_received  := WF_ENGINE.GETITEMATTRNUMBER (
                                                      itemtype => p_item_type
                                                     ,itemkey  => p_item_key
                                                     ,aname    => 'QTY_RECEIVED'
                                                     );
    gn_qty_cancelled := WF_ENGINE.GetItemAttrText (
                                                    p_item_type
                                                   ,p_item_key
                                                   ,'QTY_CANCELLED'
                                                   );
    FOR rec_order_line_dtls IN lcu_order_line_dtls(gn_line_id)
    LOOP
        --Check if it is a partially received B2B SO.
        IF ((rec_order_line_dtls.ordered_quantity <> gn_qty_received)
            AND ( lc_source_type IN ('BackToBack', 'Non-Code BackToBack') )
            AND ( gn_qty_received <> 0 ) ) THEN
            --Split the sales order line in case of a partially received BackToBack Sales Order
            SPLIT_LINE (
                         p_line_id        =>  rec_order_line_dtls.line_id
                        ,x_return_status  => lc_return_status
                        ,x_return_message => lc_return_message
                       );
            IF NVL(lc_return_status,'E') <> FND_API.G_RET_STS_SUCCESS THEN
                gc_err_code        := 'XX_OM_0010_SPLIT_LINE_ERR';
                FND_MESSAGE.SET_NAME ( 'XXOM' ,'XX_OM_0010_SPLIT_LINE_ERR' );
                lc_error_message   := FND_MESSAGE.GET;
                gc_err_desc        := SUBSTR( lc_error_message||' '||lc_return_message,1,1000 );
                gc_entity_ref      := 'Order Line Id';
                gn_entity_ref_id   := NVL(gn_line_id,0);
                RAISE EX_SPLIT_LINE_ERROR;
            END IF;
            -- Fetch the split line and create a new Sales Order line
            FOR rec_split_order_line_dtls IN lcu_split_order_line_dtls (rec_order_line_dtls.line_id )
            LOOP
                CREATE_LINE (
                               p_line_id        => rec_split_order_line_dtls.line_id
                              ,x_return_status  => lc_return_status
                              ,x_return_message => lc_return_message
                            );
                IF NVL(lc_return_status,'E') <> FND_API.G_RET_STS_SUCCESS THEN
                    gc_err_code        := 'XX_OM_0011_CREATE_LINE_ERR';
                    FND_MESSAGE.SET_NAME ( 'XXOM','XX_OM_0011_CREATE_LINE_ERR' );
                    lc_error_message   := FND_MESSAGE.GET;
                    gc_err_desc        := SUBSTR( lc_error_message||' '||lc_return_message,1,1000 );
                    gc_entity_ref      := 'Order Line Id';
                    gn_entity_ref_id   := NVL(gn_line_id,0);
                    RAISE EX_CREATE_LINE_ERROR;
                END IF;
                --cancel the existing Sales Order line
                CANCEL_LINE(
                             p_line_id        => rec_split_order_line_dtls.line_id
                            ,x_return_status  => lc_return_status
                            ,x_return_message => lc_return_message
                             );
                IF NVL(lc_return_status,'E') <> FND_API.G_RET_STS_SUCCESS THEN
                    gc_err_code      := 'XX_OM_0005_CANCEL_OE_LINE_ERR';
                    FND_MESSAGE.SET_NAME ( 'XXOM' ,'XX_OM_0005_CANCEL_OE_LINE_ERR' );
                    lc_error_message   := FND_MESSAGE.GET;
                    gc_err_desc        := SUBSTR( lc_error_message||' '||lc_return_message,1,1000 );
                    gc_entity_ref      := 'Order Line Id';
                    gn_entity_ref_id   := NVL(gn_line_id,0);
                    RAISE EX_CANCEL_LINE_ERROR;
                END IF;
            END LOOP;
        ELSE
            --Create a new Sales Order line
            CREATE_LINE(
                         p_line_id        => rec_order_line_dtls.line_id
                        ,x_return_status  => lc_return_status
                        ,x_return_message => lc_return_message
                        );
            IF NVL(lc_return_status,'E') <> FND_API.G_RET_STS_SUCCESS THEN
                gc_err_code        := 'XX_OM_0011_CREATE_LINE_ERR';
                FND_MESSAGE.SET_NAME ( 'XXOM'  ,'XX_OM_0011_CREATE_LINE_ERR' );
                lc_error_message   := FND_MESSAGE.GET;
                gc_err_desc        := SUBSTR( lc_error_message||' '||lc_return_message,1,1000 );
                gc_entity_ref      := 'Order Line Id';
                gn_entity_ref_id   := NVL(gn_line_id,0);
                RAISE EX_CREATE_LINE_ERROR;
            END IF;
            --Cancel the sales order line
            CANCEL_LINE(
                           p_line_id        => rec_order_line_dtls.line_id
                          ,x_return_status  => lc_return_status
                          ,x_return_message => lc_return_message
                         );
            IF NVL(lc_return_status,'E') <> FND_API.G_RET_STS_SUCCESS THEN
                 gc_err_code        := 'XX_OM_0005_CANCEL_OE_LINE_ERR';
                 FND_MESSAGE.SET_NAME ('XXOM' ,'XX_OM_0005_CANCEL_OE_LINE_ERR' );
                 lc_error_message   := FND_MESSAGE.GET;
                 gc_err_desc        := SUBSTR( lc_error_message||' '||lc_return_message,1,1000 );
                 gc_entity_ref      := 'Order Line Id';
                 gn_entity_ref_id   := NVL(gn_line_id,0);
                 RAISE EX_CANCEL_LINE_ERROR;
            END IF;
        END IF;
    END LOOP;
EXCEPTION
    WHEN EX_SPLIT_LINE_ERROR THEN
        -- Calling the exception framework
        gc_err_report_type :=
        XX_OM_REPORT_EXCEPTION_T (
                                  gc_exception_header
                                 ,gc_exception_track
                                 ,gc_exception_sol_dom
                                 ,gc_error_function
                                 ,gc_err_code
                                 ,gc_err_desc
                                 ,gc_entity_ref
                                 ,gn_entity_ref_id
                             );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                       gc_err_report_type
                                                      ,lc_errbuff
                                                      ,lc_retcode
                                                     );
        WF_CORE.CONTEXT(
                             ' XX_WFL_POACCREJ_PKG '
                             ,'CREATE_OE_LINE_PROC'
                             ,p_item_type
                             ,p_item_key
                             ,TO_CHAR(p_actid)
                             ,p_funcmode
                       );
        RAISE;
    WHEN EX_CREATE_LINE_ERROR THEN
        -- Calling the exception framework
        gc_err_report_type :=
        XX_OM_REPORT_EXCEPTION_T (
                                  gc_exception_header
                                 ,gc_exception_track
                                 ,gc_exception_sol_dom
                                 ,gc_error_function
                                 ,gc_err_code
                                 ,gc_err_desc
                                 ,gc_entity_ref
                                 ,gn_entity_ref_id
                                );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                        gc_err_report_type
                                                        ,lc_errbuff
                                                        ,lc_retcode
                                                     );
        WF_CORE.CONTEXT(
                         ' XX_WFL_POACCREJ_PKG '
                         ,'CREATE_OE_LINE_PROC'
                         ,p_item_type
                         ,p_item_key
                         ,TO_CHAR(p_actid)
                         ,p_funcmode
                        );
        RAISE;
    WHEN EX_CANCEL_LINE_ERROR THEN
        -- Calling the exception framework
        gc_err_report_type :=
        XX_OM_REPORT_EXCEPTION_T (
                                  gc_exception_header
                                 ,gc_exception_track
                                 ,gc_exception_sol_dom
                                 ,gc_error_function
                                 ,gc_err_code
                                 ,gc_err_desc
                                 ,gc_entity_ref
                                 ,gn_entity_ref_id
                                 );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                     gc_err_report_type
                                                    ,lc_errbuff
                                                    ,lc_retcode
                                                     );
        WF_CORE.CONTEXT(
                         ' XX_WFL_POACCREJ_PKG '
                         ,'CREATE_OE_LINE_PROC'
                         ,p_item_type
                         ,p_item_key
                         ,TO_CHAR(p_actid)
                         ,p_funcmode
                       );
        RAISE;
    WHEN OTHERS THEN
        FND_MESSAGE.SET_NAME ('XXOM','XX_OM_0012_CREATE_OE_LINE_ERR');
        lc_error_message := FND_MESSAGE.GET;
        gc_err_code      := 'XX_OM_0012_CREATE_OE_LINE_ERR';
        gc_err_desc      := SUBSTR( lc_error_message||SQLERRM,1,1000);
        gc_entity_ref    := 'Order line id';
        gn_entity_ref_id := NVL(gn_line_id,0);
        -- Calling the exception framework
        gc_err_report_type    :=
        XX_OM_REPORT_EXCEPTION_T (
                                  gc_exception_header
                                 ,gc_exception_track
                                 ,gc_exception_sol_dom
                                 ,gc_error_function
                                 ,gc_err_code
                                 ,gc_err_desc
                                 ,gc_entity_ref
                                 ,gn_entity_ref_id
                              );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                     gc_err_report_type
                                                    ,lc_errbuff
                                                    ,lc_retcode
                                                   );
        WF_CORE.CONTEXT(
                         ' XX_WFL_POACCREJ_PKG '
                         ,'CREATE_OE_LINE_PROC'
                         ,p_item_type
                         ,p_item_key
                         ,TO_CHAR(p_actid)
                         ,p_funcmode
                        );
        RAISE;
END CREATE_OE_LINE_PROC;
-----------------------------------------------------------------------------------------------------------------------------------------------
-- +======================================================================+
-- | Name             : CREATE_LINE                                       |
-- | Description      : This procedure creates a new sales order line     |
-- |                    along with the line attributes and pricing details|
-- |                                                                      |
-- | Parameters       : p_line_id                                         |
-- |                                                                      |
-- | Returns          : x_return_status                                   |
-- |                    x_return_message                                  |
-- +======================================================================+
PROCEDURE CREATE_LINE(
                        p_line_id          IN       oe_order_lines_all.line_id%TYPE
                       ,x_return_status    OUT      VARCHAR2
                       ,x_return_message   OUT      VARCHAR2
                     )
IS
    --Declaring local variables
    lt_action_request          OE_ORDER_PUB.REQUEST_TBL_TYPE    := OE_ORDER_PUB.G_MISS_REQUEST_TBL;
    lr_header                  OE_ORDER_PUB.HEADER_REC_TYPE     := OE_ORDER_PUB.G_MISS_HEADER_REC;
    lt_header_adj              OE_ORDER_PUB.HEADER_ADJ_TBL_TYPE := OE_ORDER_PUB.G_MISS_HEADER_ADJ_TBL;
    lt_order_lines             OE_ORDER_PUB.LINE_TBL_TYPE       := OE_ORDER_PUB.G_MISS_LINE_TBL;
    lt_line_out                OE_ORDER_PUB.LINE_TBL_TYPE       := OE_ORDER_PUB.G_MISS_LINE_TBL;
    lt_line_adj                OE_ORDER_PUB.LINE_ADJ_TBL_TYPE   := OE_ORDER_PUB.G_MISS_LINE_ADJ_TBL;
    lc_return_status           VARCHAR2 (10)                    := FND_API.G_RET_STS_SUCCESS;
    lc_return_message          VARCHAR2 (4000);
    lc_errbuff                 VARCHAR2 (1000);
    lc_retcode                 VARCHAR2 (100);
    lc_error_message           VARCHAR2 (1000);
    ln_line_id                 oe_order_lines_all.line_id%TYPE;
    EX_CREATE_LINE_ERROR       EXCEPTION;
    -- To fetch the sales order line details
    CURSOR lcu_order_line_dtls ( p_line_id oe_order_lines_all.line_id%TYPE)
    IS
        SELECT OOL.ordered_quantity
              ,OOL.header_id
              ,OOL.line_id
              ,OOL.inventory_item_id
              ,OOL.order_quantity_uom
              ,OOL.line_type_id
              ,OOL.calculate_price_flag
              ,OOL.UNIT_SELLING_PRICE
              ,OOL.UNIT_LIST_PRICE
              ,OOL.CUST_PO_NUMBER
              ,OOL.orig_sys_document_ref
              ,OOL.tax_code
              ,OOL.source_document_type_id
              ,OOL.source_type_code
              ,OOL.ship_from_org_id
              ,OOL.price_list_id
         FROM oe_order_lines_all OOL
         WHERE OOL.line_id = p_line_id;
    -- To get Price Adjustment Details
    CURSOR lcu_price_dtls(p_line_id oe_order_lines_all.line_id%TYPE)
    IS
        SELECT  OPA.header_id
               ,OPA.line_id
               ,OPA.list_header_id
               ,OPA.list_line_id
               ,OPA.automatic_flag
               ,OPA.discount_id
               ,OPA.discount_line_id
               ,OPA.percent
               ,OPA.orig_sys_discount_ref
               ,OPA.change_sequence
               ,OPA.modified_from
               ,OPA.modified_to
               ,OPA.modifier_mechanism_type_code
               ,OPA.cost_id
               ,OPA.tax_code
               ,OPA.tax_exempt_flag
               ,OPA.tax_exempt_number
               ,OPA.tax_exempt_reason_code
               ,OPA.parent_adjustment_id
               ,OPA.invoiced_flag
               ,OPA.estimated_flag
               ,OPA.source_system_code
               ,OPA.print_on_invoice_flag
               ,OPA.charge_type_code
               ,OPA.invoiced_amount
               ,OPA.credit_or_charge_flag
               ,OPA.include_on_returns_flag
               ,OPA.proration_type_code
               ,OPA.modifier_level_code
               ,OPA.list_line_type_code
               ,OPA.list_line_no
               ,OPA.change_reason_code
               ,OPA.change_reason_text
               ,OPA.operand
               ,OPA.arithmetic_operator
               ,OPA.operand_per_pqty
               ,OPA.adjusted_amount
               ,OPA.adjusted_amount_per_pqty
               ,OPA.update_allowed
               ,OPA.updated_flag
               ,OPA.applied_flag
        FROM  oe_price_adjustments OPA
        WHERE OPA.line_id = p_line_id;
BEGIN
    FOR rec_order_line_dtls IN lcu_order_line_dtls(p_line_id)
    LOOP
            -- Initializing record for creating new sales order line
            lt_order_lines(1)                          := OE_ORDER_PUB.G_MISS_LINE_REC;
            lt_order_lines(1).ordered_quantity         := rec_order_line_dtls.ordered_quantity;
            lt_order_lines(1).header_id                := rec_order_line_dtls.header_id;
            lt_order_lines(1).inventory_item_id        := rec_order_line_dtls.inventory_item_id;
            lt_order_lines(1).order_quantity_uom       := rec_order_line_dtls.order_quantity_uom;
            lt_order_lines(1).line_type_id             := rec_order_line_dtls.line_type_id;
            lt_order_lines(1).price_list_id            := rec_order_line_dtls.price_list_id;
            lt_order_lines(1).ship_from_org_id         := NULL;
            lt_order_lines(1).calculate_price_flag     := 'N';
            lt_order_lines(1).unit_selling_price       := rec_order_line_dtls.unit_selling_price;
            lt_order_lines(1).unit_list_price          := rec_order_line_dtls.unit_list_price;
            lt_order_lines(1).cust_po_number           := rec_order_line_dtls.cust_po_number;
            lt_order_lines(1).orig_sys_document_ref    := rec_order_line_dtls.orig_sys_document_ref;
            lt_order_lines(1).orig_sys_line_ref        := p_line_id;
            lt_order_lines(1).tax_code                 := rec_order_line_dtls.tax_code;
            lt_order_lines(1).source_document_type_id  := NULL;
            lt_order_lines(1).source_type_code         := NULL;
        lt_order_lines(1).OPERATION  := OE_GLOBALS.G_OPR_CREATE;
        -- Calling processorder procedure to create a new SO line
        PROCESSORDER(
                         p_process_type          => 'API'
                        ,x_header_rec            => lr_header
                        ,x_header_adj_tbl        => lt_header_adj
                        ,x_order_lines_tbl       => lt_order_lines
                        ,x_line_adj_tbl          => lt_line_adj
                        ,p_request_tbl           => lt_action_request
                        ,x_order_lines_tbl_out   => lt_line_out
                        ,x_return_status         => lc_return_status
                        ,x_return_message        => lc_return_message
                     );
        IF NVL(lc_return_status,'E') <> FND_API.G_RET_STS_SUCCESS THEN
            x_return_status  := FND_API.G_RET_STS_ERROR;
            x_return_message := lc_return_message;
            gc_err_code      := 'XX_OM_0011_CREATE_LINE_ERR';
            FND_MESSAGE.SET_NAME ( 'XXOM' ,'XX_OM_0011_CREATE_LINE_ERR' );
            lc_error_message   := FND_MESSAGE.GET;
            gc_err_desc        := SUBSTR( lc_error_message||' '||lc_return_message,1,1000 );
            gc_entity_ref      := 'Order Line Id';
            gn_entity_ref_id   := NVL(p_line_id,0);
            RAISE EX_CREATE_LINE_ERROR;
        END IF;
        -- Assigning the newly created order line id to create pricing adjustments for that line
        ln_line_id := lt_line_out(1).line_id;
        -- creating pricing adjustments
        FOR rec_price_dtls IN lcu_price_dtls(rec_order_line_dtls.line_id)
        LOOP
             --Initailizing record for creating price adjustments details for the newly created SO line
            lt_line_adj(1)                               := OE_ORDER_PUB.G_MISS_LINE_ADJ_REC;
            lt_line_adj(1).header_id                     := rec_price_dtls.header_id;
            lt_line_adj(1).line_id                       := ln_line_id;
            lt_line_adj(1).list_header_id                := rec_price_dtls.list_header_id;
            lt_line_adj(1).list_line_id                  := rec_price_dtls.list_line_id;
            lt_line_adj(1).modifier_level_code           := rec_price_dtls.modifier_level_code;
            lt_line_adj(1).list_line_type_code           := rec_price_dtls.list_line_type_code;
            lt_line_adj(1).list_line_no                  := rec_price_dtls.list_line_no;
            lt_line_adj(1).change_reason_code            := rec_price_dtls.change_reason_code;
            lt_line_adj(1).change_reason_text            := rec_price_dtls.change_reason_text;
            lt_line_adj(1).operand                       := rec_price_dtls.operand;
            lt_line_adj(1).arithmetic_operator           := rec_price_dtls.arithmetic_operator;
            lt_line_adj(1).adjusted_amount               := rec_price_dtls.adjusted_amount;
            lt_line_adj(1).discount_id                   := rec_price_dtls.discount_id;
            lt_line_adj(1).discount_line_id              := rec_price_dtls.discount_line_id;
            lt_line_adj(1).percent                       := rec_price_dtls.percent;
            lt_line_adj(1).orig_sys_discount_ref         := rec_price_dtls.orig_sys_discount_ref;
            lt_line_adj(1).modified_from                 := rec_price_dtls.modified_from;
            lt_line_adj(1).modified_to                   := rec_price_dtls.modified_to;
            lt_line_adj(1).modifier_mechanism_type_code  := rec_price_dtls.modifier_mechanism_type_code;
            lt_line_adj(1).cost_id                       := rec_price_dtls.cost_id;
            lt_line_adj(1).tax_code                      := rec_price_dtls.tax_code;
            lt_line_adj(1).tax_exempt_flag               := rec_price_dtls.tax_exempt_flag;
            lt_line_adj(1).tax_exempt_number             := rec_price_dtls.tax_exempt_number;
            lt_line_adj(1).tax_exempt_reason_code        := rec_price_dtls.tax_exempt_reason_code;
            lt_line_adj(1).parent_adjustment_id          := rec_price_dtls.parent_adjustment_id;
            lt_line_adj(1).invoiced_flag                 := rec_price_dtls.invoiced_flag;
            lt_line_adj(1).estimated_flag                := rec_price_dtls.estimated_flag;
            lt_line_adj(1).source_system_code            := rec_price_dtls.source_system_code;
            lt_line_adj(1).print_on_invoice_flag         := rec_price_dtls.print_on_invoice_flag;
            lt_line_adj(1).charge_type_code              := rec_price_dtls.charge_type_code;
            lt_line_adj(1).invoiced_amount               := rec_price_dtls.invoiced_amount;
            lt_line_adj(1).credit_or_charge_flag         := rec_price_dtls.credit_or_charge_flag;
            lt_line_adj(1).include_on_returns_flag       := rec_price_dtls.include_on_returns_flag;
            lt_line_adj(1).proration_type_code           := rec_price_dtls.proration_type_code;
            lt_line_adj(1).operand_per_pqty              := rec_price_dtls.operand_per_pqty;
            lt_line_adj(1).adjusted_amount_per_pqty      := rec_price_dtls.adjusted_amount_per_pqty;
            lt_line_adj(1).update_allowed                := 'Y';
            lt_line_adj(1).automatic_flag                := 'Y';
            lt_line_adj(1).updated_flag                  := 'Y';
            lt_line_adj(1).applied_flag                  := 'Y';
            lt_line_adj(1).OPERATION                     := OE_GLOBALS.G_OPR_CREATE;
            lt_order_lines(1).header_id                  := rec_order_line_dtls.header_id;
            lt_order_lines(1).line_id                    := ln_line_id;
            lt_order_lines(1).OPERATION                  := OE_GLOBALS.G_OPR_UPDATE;
            -- Calling the processorder procedure to create price adjustment for the newly created SO line.
            PROCESSORDER(
                         p_process_type          => 'API'
                        ,x_header_rec            => lr_header
                        ,x_header_adj_tbl        => lt_header_adj
                        ,x_order_lines_tbl       => lt_order_lines
                        ,x_line_adj_tbl          => lt_line_adj
                        ,p_request_tbl           => lt_action_request
                        ,x_order_lines_tbl_out   => lt_line_out
                        ,x_return_status         => lc_return_status
                        ,x_return_message        => lc_return_message
                        );
            IF NVL(lc_return_status,'E') <> FND_API.G_RET_STS_SUCCESS THEN
                x_return_status   := FND_API.G_RET_STS_ERROR;
                x_return_message  := lc_return_message;
                gc_err_code       := 'XX_OM_0013_UPDATE_PRICING_ERR';
                FND_MESSAGE.SET_NAME (  'XXOM' ,'XX_OM_0013_UPDATE_PRICING_ERR' );
                lc_error_message   := FND_MESSAGE.GET;
                gc_err_desc        := SUBSTR( lc_error_message||' '||lc_return_message,1,1000 );
                gc_entity_ref      := 'Order Line Id';
                gn_entity_ref_id   := NVL(p_line_id,0);
                RAISE EX_CREATE_LINE_ERROR;
             END IF;
        END LOOP;
        -- Updating the newly created order line's DFF values in the custom table
        UPDATE_OE_LINE_DFF(
                              p_line_id        => ln_line_id
                             ,x_return_status  => lc_return_status
                             ,x_return_message => lc_return_message
                           );
    END LOOP;
    x_return_status         := lc_return_status;
    x_return_message        := lc_return_message;
EXCEPTION
    WHEN EX_CREATE_LINE_ERROR THEN
        -- Calling the exception framework
        gc_err_report_type :=
        XX_OM_REPORT_EXCEPTION_T (
                                      gc_exception_header
                                     ,gc_exception_track
                                     ,gc_exception_sol_dom
                                     ,gc_error_function
                                     ,gc_err_code
                                     ,gc_err_desc
                                     ,gc_entity_ref
                                     ,gn_entity_ref_id
                                 );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                         gc_err_report_type
                                                        ,lc_errbuff
                                                        ,lc_retcode
                                                    );
    WHEN OTHERS THEN
        FND_MESSAGE.SET_NAME ('XXOM','XX_OM_0014_CREATE_LINE_ERR');
        lc_error_message      := FND_MESSAGE.GET;
        gc_err_code           := 'XX_OM_0014_CREATE_LINE_ERR';
        gc_err_desc           := SUBSTR( lc_error_message||SQLERRM,1,1000);
        gc_entity_ref         := 'Order Line Id';
        gn_entity_ref_id      := NVL(p_line_id,0);
        -- Calling the exception framework
        gc_err_report_type    :=
        XX_OM_REPORT_EXCEPTION_T (
                                  gc_exception_header
                                 ,gc_exception_track
                                 ,gc_exception_sol_dom
                                 ,gc_error_function
                                 ,gc_err_code
                                 ,gc_err_desc
                                 ,gc_entity_ref
                                 ,gn_entity_ref_id
                                 );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                      gc_err_report_type
                                                     ,lc_errbuff
                                                     ,lc_retcode
                                                     );
        x_return_status  := FND_API.G_RET_STS_ERROR;
        x_return_message :=  SUBSTR( SQLERRM,1,1000);
END CREATE_LINE;
---------------------------------------------------------------------------------------------------------------------------------------
-- +======================================================================+
-- | Name             : SPLIT_LINE                                        |
-- | Description      : This procedure splits the sales order line        |
-- |                    based on the ordered quantity and quantity        |
-- |                    quantity received                                 |
-- | Parameters       : p_line_id                                         |
-- |                                                                      |
-- | Returns          : x_return_status                                   |
-- |                    x_return_message                                  |
-- +======================================================================+
PROCEDURE SPLIT_LINE (
                        p_line_id          IN       oe_order_lines_all.line_id%TYPE
                       ,x_return_status    OUT      VARCHAR2
                       ,x_return_message   OUT      VARCHAR2
                      )
IS
    --Declaring local variables
    lt_action_request     OE_ORDER_PUB.REQUEST_TBL_TYPE    := OE_ORDER_PUB.G_MISS_REQUEST_TBL;
    lr_header             OE_ORDER_PUB.HEADER_REC_TYPE     := OE_ORDER_PUB.G_MISS_HEADER_REC;
    lt_header_adj         OE_ORDER_PUB.HEADER_ADJ_TBL_TYPE := OE_ORDER_PUB.G_MISS_HEADER_ADJ_TBL;
    lt_order_lines        OE_ORDER_PUB.LINE_TBL_TYPE       := OE_ORDER_PUB.G_MISS_LINE_TBL;
    lt_line_adj           OE_ORDER_PUB.LINE_ADJ_TBL_TYPE   := OE_ORDER_PUB.G_MISS_LINE_ADJ_TBL;
    lt_line_out           OE_ORDER_PUB.LINE_TBL_TYPE       := OE_ORDER_PUB.G_MISS_LINE_TBL;
    lc_return_status      VARCHAR2 (10)                    := FND_API.G_RET_STS_SUCCESS;
    lc_return_message     VARCHAR2 (4000);
    lc_errbuff            VARCHAR2 (1000);
    lc_retcode            VARCHAR2 (100);
    lc_error_message      VARCHAR2 (1000);
    ln_line_id            oe_order_lines_all.line_id%TYPE;
    EX_SPLIT_LINE_ERROR   EXCEPTION;
    -- To fetch the SO line details.
    CURSOR lcu_order_line_dtls ( p_line_id oe_order_lines_all.line_id%TYPE)
    IS
        SELECT OOL.ordered_quantity
              ,OOL.header_id
              ,OOL.line_id
              ,OOL.inventory_item_id
        FROM   oe_order_lines_all OOL
        WHERE  OOL.line_id = p_line_id;
BEGIN
    FOR rec_order_line_dtls IN lcu_order_line_dtls (p_line_id)
    LOOP
        -- Initializing the order line details
        lt_order_lines (1)                       := OE_ORDER_PUB.G_MISS_LINE_REC;
        lt_order_lines (1).OPERATION             := OE_GLOBALS.G_OPR_UPDATE;
        lt_order_lines (1).split_by              := FND_GLOBAL.USER_ID;
        lt_order_lines (1).split_action_code     := 'SPLIT';
        lt_order_lines (1).header_id             := rec_order_line_dtls.header_id;
        lt_order_lines (1).line_id               := rec_order_line_dtls.line_id;
        lt_order_lines (1).ordered_quantity      := gn_qty_received;
        lt_order_lines(2)                        := OE_ORDER_PUB.G_MISS_LINE_REC;
        lt_order_lines(2).OPERATION              := OE_GLOBALS.G_OPR_CREATE;
        lt_order_lines(2).split_by               := FND_GLOBAL.USER_ID;
        lt_order_lines(2).split_action_code      := 'SPLIT';
        lt_order_lines(2).split_from_line_id     := rec_order_line_dtls.line_id;
        lt_order_lines(2).inventory_item_id      := rec_order_line_dtls.inventory_item_id;
        lt_order_lines(2).ordered_quantity       := gn_qty_cancelled;
        -- calling the processorder to split the order lines
        PROCESSORDER(
                       p_process_type          => 'API'
                      ,x_header_rec            => lr_header
                      ,x_header_adj_tbl        => lt_header_adj
                      ,x_order_lines_tbl       => lt_order_lines
                      ,x_line_adj_tbl          => lt_line_adj
                      ,p_request_tbl           => lt_action_request
                      ,x_order_lines_tbl_out   => lt_line_out
                      ,x_return_status         => lc_return_status
                      ,x_return_message        => lc_return_message
                    );
        IF NVL(lc_return_status,'E') <> FND_API.G_RET_STS_SUCCESS THEN
            x_return_status  := FND_API.G_RET_STS_ERROR;
            x_return_message := lc_return_message;
            gc_err_code      := 'XX_OM_0010_SPLIT_LINE_ERR';
            FND_MESSAGE.SET_NAME ('XXOM' ,'XX_OM_0010_SPLIT_LINE_ERR' );
            lc_error_message := FND_MESSAGE.GET;
            gc_err_desc      := SUBSTR( lc_error_message||' '||lc_return_message,1,1000 );
            gc_entity_ref    := 'Order Line Id';
            gn_entity_ref_id := NVL(p_line_id,0);
            RAISE EX_SPLIT_LINE_ERROR;
        END IF;
    END LOOP;
    x_return_status  := lc_return_status;
    x_return_message := lc_return_message;
EXCEPTION
    WHEN EX_SPLIT_LINE_ERROR THEN
        x_return_status    := FND_API.G_RET_STS_ERROR;
        x_return_message   := lc_return_message;
        -- Calling the exception framework
        gc_err_report_type :=
        XX_OM_REPORT_EXCEPTION_T (
                                  gc_exception_header
                                 ,gc_exception_track
                                 ,gc_exception_sol_dom
                                 ,gc_error_function
                                 ,gc_err_code
                                 ,gc_err_desc
                                 ,gc_entity_ref
                                 ,gn_entity_ref_id
                             );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                     gc_err_report_type
                                                    ,lc_errbuff
                                                    ,lc_retcode
                                                );
    WHEN OTHERS THEN
        FND_MESSAGE.SET_NAME ('XXOM','XX_OM_0015_SPLIT_LINE_ERR');
        lc_error_message := FND_MESSAGE.GET;
        gc_err_code      := 'XX_OM_0015_SPLIT_LINE_ERR';
        gc_err_desc      := SUBSTR( lc_error_message||SQLERRM,1,1000);
        gc_entity_ref    := 'Order line Id';
        gn_entity_ref_id := NVL(p_line_id,0);
        -- Calling the exception framework
        gc_err_report_type    :=
        XX_OM_REPORT_EXCEPTION_T (
                                   gc_exception_header
                                  ,gc_exception_track
                                  ,gc_exception_sol_dom
                                  ,gc_error_function
                                  ,gc_err_code
                                  ,gc_err_desc
                                  ,gc_entity_ref
                                 ,gn_entity_ref_id
                                 );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                       gc_err_report_type
                                                      ,lc_errbuff
                                                      ,lc_retcode
                                                   );
        x_return_status  := FND_API.G_RET_STS_ERROR;
        x_return_message := SUBSTR( SQLERRM,1,1000);
END SPLIT_LINE;
--------------------------------------------------------------------------------------------------------------------------------------------
-- +===================================================================+
-- | Name           : UPDATE_OE_LINE_DFF                               |
-- | Description    : Updates the custom table sales order line        |
-- |                  attributes.                                      |
-- | Parameters     : p_line_id                                        |
-- |                                                                   |
-- | Returns        : x_return_status                                  |
-- |                  x_return_message                                 |
-- |                                                                   |
-- +===================================================================+
PROCEDURE UPDATE_OE_LINE_DFF (
                              p_line_id         IN  oe_order_lines_all.line_id%TYPE
                             ,x_return_status   OUT VARCHAR2
                             ,x_return_message  OUT VARCHAR2
                             )
IS
    -- Declaring local variables
    lc_return_status            VARCHAR2 (100) ;
    lc_errbuff                  VARCHAR2 (4000);
    lc_retcode                  VARCHAR2 (100);
    lt_line_rec                 XX_OM_LINE_ATTRIBUTES_T ;
    lc_licence_address          xx_om_line_attributes_all.licence_address%TYPE;
    lc_vendor_config_id         xx_om_line_attributes_all.vendor_config_id%TYPE;
    lc_fulfillment_type         xx_om_line_attributes_all.fulfillment_type%TYPE;
    lc_line_type                xx_om_line_attributes_all.line_type%TYPE;
    lc_line_modifier            xx_om_line_attributes_all.line_modifier%TYPE;
    lc_release_num              xx_om_line_attributes_all.release_num%TYPE;
    lc_cost_center_dept         xx_om_line_attributes_all.cost_center_dept%TYPE;
    lc_desktop_del_addr         xx_om_line_attributes_all.desktop_del_addr%TYPE;
    ln_vendor_site_id           xx_om_line_attributes_all.vendor_site_id%TYPE;
    lc_pos_trx_num              xx_om_line_attributes_all.pos_trx_num%TYPE;
    lc_one_time_deal            xx_om_line_attributes_all.one_time_deal%TYPE;
    lc_trans_line_status        xx_om_line_attributes_all.trans_line_status%TYPE;
    ln_cust_price               xx_om_line_attributes_all.cust_price%TYPE;
    lc_cust_uom                 xx_om_line_attributes_all.cust_uom%TYPE;
    lc_cust_comments            xx_om_line_attributes_all.cust_comments%TYPE;
    lc_pip_campaign_id          xx_om_line_attributes_all.pip_campaign_id%TYPE;
    ln_ext_top_model_line_id    xx_om_line_attributes_all.ext_top_model_line_id%TYPE;
    ln_ext_link_to_line_id      xx_om_line_attributes_all.ext_link_to_line_id%TYPE;
    lc_config_code              xx_om_line_attributes_all.config_code%TYPE;
    lc_gift_message             xx_om_line_attributes_all.gift_message%TYPE;
    lc_gift_email               xx_om_line_attributes_all.gift_email%TYPE;
    lc_return_rga_number        xx_om_line_attributes_all.return_rga_number%TYPE;
    ld_delivery_date_from       xx_om_line_attributes_all.delivery_date_from%TYPE;
    ld_delivery_date_to         xx_om_line_attributes_all.delivery_date_to%TYPE;
    lc_wholesaler_fac_cd        xx_om_line_attributes_all.wholesaler_fac_cd%TYPE;
    lc_wholesaler_acct_num      xx_om_line_attributes_all.wholesaler_acct_num%TYPE;
    lc_return_act_cat_code      xx_om_line_attributes_all.return_act_cat_code%TYPE;
    lc_po_del_details           xx_om_line_attributes_all.po_del_details%TYPE;
    ln_ret_ref_header_id        xx_om_line_attributes_all.ret_ref_header_id%TYPE;
    ln_ret_ref_line_id          xx_om_line_attributes_all.ret_ref_line_id%TYPE;
    lc_ship_to_flag             xx_om_line_attributes_all.ship_to_flag%TYPE;
    lc_item_note                xx_om_line_attributes_all.item_note%TYPE;
    lc_special_desc             xx_om_line_attributes_all.special_desc%TYPE;
    lc_non_cd_line_type         xx_om_line_attributes_all.non_cd_line_type%TYPE;
    lc_supplier_type            xx_om_line_attributes_all.supplier_type%TYPE;
    lc_vendor_product_code      xx_om_line_attributes_all.vendor_product_code%TYPE;
    lc_contract_details         xx_om_line_attributes_all.contract_details%TYPE;
    lc_aops_orig_order_num      xx_om_line_attributes_all.aops_orig_order_num%TYPE;
    ld_aops_orig_order_date     xx_om_line_attributes_all.aops_orig_order_date%TYPE;
    lc_item_comments            xx_om_line_attributes_all.item_comments%TYPE;
    ln_backordered_qty          xx_om_line_attributes_all.backordered_qty%TYPE;
    lc_taxable_flag             xx_om_line_attributes_all.taxable_flag%TYPE;
    ln_waca_parent_id           xx_om_line_attributes_all.waca_parent_id%TYPE;
    ln_aops_orig_order_line_num xx_om_line_attributes_all.aops_orig_order_line_num%TYPE;
    lc_sku_dept                 xx_om_line_attributes_all.sku_dept%TYPE;
    lc_item_source              xx_om_line_attributes_all.item_source%TYPE;
    ln_average_cost             xx_om_line_attributes_all.average_cost%TYPE;
    ln_canada_pst_tax           xx_om_line_attributes_all.canada_pst_tax%TYPE;
    ln_po_cost                  xx_om_line_attributes_all.po_cost%TYPE;
    lc_waca_status              xx_om_line_attributes_all.waca_status%TYPE;
    lc_cust_item_number         xx_om_line_attributes_all.cust_item_number%TYPE;
    ld_pod_date                 xx_om_line_attributes_all.pod_date%TYPE;
    ln_return_auth_id           xx_om_line_attributes_all.return_auth_id%TYPE;
    lc_return_code              xx_om_line_attributes_all.return_code%TYPE;
    ln_sku_list_price           xx_om_line_attributes_all.sku_list_price%TYPE;
    lc_waca_item_ctr_num        xx_om_line_attributes_all.waca_item_ctr_num%TYPE;
    ld_new_schedule_ship_date   xx_om_line_attributes_all.new_schedule_ship_date%TYPE ;
    ld_new_schedule_arr_date    xx_om_line_attributes_all.new_schedule_arr_date%TYPE;
    ln_taylor_unit_price        xx_om_line_attributes_all.taylor_unit_price%TYPE;
    ln_taylor_unit_cost         xx_om_line_attributes_all.taylor_Unit_cost%TYPE;
    ln_xdock_inv_org_id         xx_om_line_attributes_all.xdock_inv_org_id%TYPE;
    lc_payment_subtype_cod_ind  xx_om_line_attributes_all.payment_subtype_cod_ind%TYPE;
    lc_del_to_post_office_ind   xx_om_line_attributes_all.del_to_post_office_ind%TYPE;
    lc_wholesaler_item          xx_om_line_attributes_all.wholesaler_item%TYPE;
    lc_cust_comm_pref           xx_om_line_attributes_all.cust_comm_pref%TYPE;
    lc_cust_pref_email          xx_om_line_attributes_all.cust_pref_email%TYPE;
    lc_cust_pref_fax            xx_om_line_attributes_all.cust_pref_fax%TYPE;
    lc_cust_pref_phone          xx_om_line_attributes_all.cust_pref_phone%TYPE;
    lc_cust_pref_phextn         xx_om_line_attributes_all.cust_pref_phextn%TYPE;
    ln_freight_line_id          xx_om_line_attributes_all.freight_line_id%TYPE;
    ln_freight_primary_line_id  xx_om_line_attributes_all.freight_primary_line_id%TYPE;
    ld_creation_date            xx_om_line_attributes_all.creation_date%TYPE;
    lc_created_by               xx_om_line_attributes_all.created_by%TYPE;
    ld_last_update_date         xx_om_line_attributes_all.last_update_date%TYPE;
    ln_last_updated_by          xx_om_line_attributes_all.last_updated_by%TYPE;
    ln_last_update_login        xx_om_line_attributes_all.last_update_login%TYPE;
BEGIN
    -- Fetch the custom DFF values for the existing SO Line
    SELECT
         licence_address
        ,vendor_config_id
        ,fulfillment_type
        ,line_type
        ,line_modifier
        ,release_num
        ,cost_center_dept
        ,desktop_del_addr
        ,pos_trx_num
        ,one_time_deal
        ,trans_line_status
        ,cust_price
        ,cust_uom
        ,cust_comments
        ,pip_campaign_id
        ,ext_top_model_line_id
        ,ext_link_to_line_id
        ,config_code
        ,gift_message
        ,gift_email
        ,return_rga_number
        ,delivery_date_from
        ,delivery_date_to
        ,wholesaler_fac_cd
        ,wholesaler_acct_num
        ,return_act_cat_code
        ,po_del_details
        ,ret_ref_header_id
        ,ret_ref_line_id
        ,ship_to_flag
        ,item_note
        ,special_desc
        ,non_cd_line_type
        ,supplier_type
        ,vendor_product_code
        ,contract_details
        ,aops_orig_order_num
        ,aops_orig_order_date
        ,item_comments
        ,backordered_qty
        ,taxable_flag
        ,waca_parent_id
        ,aops_orig_order_line_num
        ,sku_dept
        ,item_source
        ,average_cost
        ,canada_pst_tax
        ,po_cost
        ,waca_status
        ,cust_item_number
        ,pod_date
        ,return_auth_id
        ,return_code
        ,sku_list_price
        ,waca_item_ctr_num
        ,new_schedule_ship_date
        ,new_schedule_arr_date
        ,taylor_unit_price
        ,taylor_unit_cost
        ,xdock_inv_org_id
        ,payment_subtype_cod_ind
        ,del_to_post_office_ind
        ,wholesaler_item
        ,cust_comm_pref
        ,cust_pref_email
        ,cust_pref_fax
        ,cust_pref_phone
        ,cust_pref_phextn
        ,freight_line_id
        ,freight_primary_line_id
    INTO
         lc_licence_address
        ,lc_vendor_config_id
        ,lc_fulfillment_type
        ,lc_line_type
        ,lc_line_modifier
        ,lc_release_num
        ,lc_cost_center_dept
        ,lc_desktop_del_addr
        ,lc_pos_trx_num
        ,lc_one_time_deal
        ,lc_trans_line_status
        ,ln_cust_price
        ,lc_cust_uom
        ,lc_cust_comments
        ,lc_pip_campaign_id
        ,ln_ext_top_model_line_id
        ,ln_ext_link_to_line_id
        ,lc_config_code
        ,lc_gift_message
        ,lc_gift_email
        ,lc_return_rga_number
        ,ld_delivery_date_from
        ,ld_delivery_date_to
        ,lc_wholesaler_fac_cd
        ,lc_wholesaler_acct_num
        ,lc_return_act_cat_code
        ,lc_po_del_details
        ,ln_ret_ref_header_id
        ,ln_ret_ref_line_id
        ,lc_ship_to_flag
        ,lc_item_note
        ,lc_special_desc
        ,lc_non_cd_line_type
        ,lc_supplier_type
        ,lc_vendor_product_code
        ,lc_contract_details
        ,lc_aops_orig_order_num
        ,ld_aops_orig_order_date
        ,lc_item_comments
        ,ln_backordered_qty
        ,lc_taxable_flag
        ,ln_waca_parent_id
        ,ln_aops_orig_order_line_num
        ,lc_sku_dept
        ,lc_item_source
        ,ln_average_cost
        ,ln_canada_pst_tax
        ,ln_po_cost
        ,lc_waca_status
        ,lc_cust_item_number
        ,ld_pod_date
        ,ln_return_auth_id
        ,lc_return_code
        ,ln_sku_list_price
        ,lc_waca_item_ctr_num
        ,ld_new_schedule_ship_date
        ,ld_new_schedule_arr_date
        ,ln_taylor_unit_price
        ,ln_taylor_unit_cost
        ,ln_xdock_inv_org_id
        ,lc_payment_subtype_cod_ind
        ,lc_del_to_post_office_ind
        ,lc_wholesaler_item
        ,lc_cust_comm_pref
        ,lc_cust_pref_email
        ,lc_cust_pref_fax
        ,lc_cust_pref_phone
        ,lc_cust_pref_phextn
        ,ln_freight_line_id
        ,ln_freight_primary_line_id
    FROM   xx_om_line_attributes_all
    WHERE  line_id = gn_line_id;
    -- Assigning DFF details of the existing line with Vendor_site_id and resourcing_flag as NULL, to the record type variable.
    lt_line_rec := XX_OM_LINE_ATTRIBUTES_T ( p_line_id
                                            ,lc_licence_address
                                            ,lc_vendor_config_id
                                            ,lc_fulfillment_type
                                            ,lc_line_type
                                            ,lc_line_modifier
                                            ,lc_release_num
                                            ,lc_cost_center_dept
                                            ,lc_desktop_del_addr
                                            ,NULL
                                            ,lc_pos_trx_num
                                            ,lc_one_time_deal
                                            ,lc_trans_line_status
                                            ,ln_cust_price
                                            ,lc_cust_uom
                                            ,lc_cust_comments
                                            ,lc_pip_campaign_id
                                            ,ln_ext_top_model_line_id
                                            ,ln_ext_link_to_line_id
                                            ,lc_config_code
                                            ,lc_gift_message
                                            ,lc_gift_email
                                            ,lc_return_rga_number
                                            ,ld_delivery_date_from
                                            ,ld_delivery_date_to
                                            ,lc_wholesaler_fac_cd
                                            ,lc_wholesaler_acct_num
                                            ,lc_return_act_cat_code
                                            ,lc_po_del_details
                                            ,ln_ret_ref_header_id
                                            ,ln_ret_ref_line_id
                                            ,lc_ship_to_flag
                                            ,lc_item_note
                                            ,lc_special_desc
                                            ,lc_non_cd_line_type
                                            ,lc_supplier_type
                                            ,lc_vendor_product_code
                                            ,lc_contract_details
                                            ,lc_aops_orig_order_num
                                            ,ld_aops_orig_order_date
                                            ,lc_item_comments
                                            ,ln_backordered_qty
                                            ,lc_taxable_flag
                                            ,ln_waca_parent_id
                                            ,ln_aops_orig_order_line_num
                                            ,lc_sku_dept
                                            ,lc_item_source
                                            ,ln_average_cost
                                            ,ln_canada_pst_tax
                                            ,ln_po_cost
                                            ,NULL
                                            ,lc_waca_status
                                            ,lc_cust_item_number
                                            ,ld_pod_date
                                            ,ln_return_auth_id
                                            ,lc_return_code
                                            ,ln_sku_list_price
                                            ,lc_waca_item_ctr_num
                                            ,ld_new_schedule_ship_date
                                            ,ld_new_schedule_arr_date
                                            ,ln_taylor_unit_price
                                            ,ln_taylor_unit_cost
                                            ,ln_xdock_inv_org_id
                                            ,lc_payment_subtype_cod_ind
                                            ,lc_del_to_post_office_ind
                                            ,lc_wholesaler_item
                                            ,lc_cust_comm_pref
                                            ,lc_cust_pref_email
                                            ,lc_cust_pref_fax
                                            ,lc_cust_pref_phone
                                            ,lc_cust_pref_phextn
                                            ,ln_freight_line_id
                                            ,ln_freight_primary_line_id
                                            ,SYSDATE
                                            ,FND_GLOBAL.USER_ID
                                            ,SYSDATE
                                            ,FND_GLOBAL.USER_ID
                                            ,FND_GLOBAL.USER_ID
                                             );
    -- Calling the INSERT_ROW to insert a row for the newly created order line with the details of the existing line.
    XX_OM_LINE_ATTRIBUTES_PKG.INSERT_ROW(
                                           p_line_rec       => lt_line_rec
                                          ,x_return_status  => lc_return_status
                                          ,x_errbuf         => lc_errbuff
                                         );
    x_return_status := lc_return_status;
    x_return_message:= lc_errbuff;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Insert a new row for the newly created SO line.
        lt_line_rec := XX_OM_LINE_ATTRIBUTES_T ( p_line_id
                                            ,lc_licence_address
                                            ,lc_vendor_config_id
                                            ,lc_fulfillment_type
                                            ,lc_line_type
                                            ,lc_line_modifier
                                            ,lc_release_num
                                            ,lc_cost_center_dept
                                            ,lc_desktop_del_addr
                                            ,NULL
                                            ,lc_pos_trx_num
                                            ,lc_one_time_deal
                                            ,lc_trans_line_status
                                            ,ln_cust_price
                                            ,lc_cust_uom
                                            ,lc_cust_comments
                                            ,lc_pip_campaign_id
                                            ,ln_ext_top_model_line_id
                                            ,ln_ext_link_to_line_id
                                            ,lc_config_code
                                            ,lc_gift_message
                                            ,lc_gift_email
                                            ,lc_return_rga_number
                                            ,ld_delivery_date_from
                                            ,ld_delivery_date_to
                                            ,lc_wholesaler_fac_cd
                                            ,lc_wholesaler_acct_num
                                            ,lc_return_act_cat_code
                                            ,lc_po_del_details
                                            ,ln_ret_ref_header_id
                                            ,ln_ret_ref_line_id
                                            ,lc_ship_to_flag
                                            ,lc_item_note
                                            ,lc_special_desc
                                            ,lc_non_cd_line_type
                                            ,lc_supplier_type
                                            ,lc_vendor_product_code
                                            ,lc_contract_details
                                            ,lc_aops_orig_order_num
                                            ,ld_aops_orig_order_date
                                            ,lc_item_comments
                                            ,ln_backordered_qty
                                            ,lc_taxable_flag
                                            ,ln_waca_parent_id
                                            ,ln_aops_orig_order_line_num
                                            ,lc_sku_dept
                                            ,lc_item_source
                                            ,ln_average_cost
                                            ,ln_canada_pst_tax
                                            ,ln_po_cost
                                            ,NULL
                                            ,lc_waca_status
                                            ,lc_cust_item_number
                                            ,ld_pod_date
                                            ,ln_return_auth_id
                                            ,lc_return_code
                                            ,ln_sku_list_price
                                            ,lc_waca_item_ctr_num
                                            ,ld_new_schedule_ship_date
                                            ,ld_new_schedule_arr_date
                                            ,ln_taylor_unit_price
                                            ,ln_taylor_unit_cost
                                            ,ln_xdock_inv_org_id
                                            ,lc_payment_subtype_cod_ind
                                            ,lc_del_to_post_office_ind
                                            ,lc_wholesaler_item
                                            ,lc_cust_comm_pref
                                            ,lc_cust_pref_email
                                            ,lc_cust_pref_fax
                                            ,lc_cust_pref_phone
                                            ,lc_cust_pref_phextn
                                            ,ln_freight_line_id
                                            ,ln_freight_primary_line_id
                                            ,SYSDATE
                                            ,FND_GLOBAL.USER_ID
                                            ,SYSDATE
                                            ,FND_GLOBAL.USER_ID
                                            ,FND_GLOBAL.USER_ID
                                            );
    XX_OM_LINE_ATTRIBUTES_PKG.INSERT_ROW(
                                           p_line_rec       => lt_line_rec
                                          ,x_return_status  => lc_return_status
                                          ,x_errbuf         => lc_errbuff
                                        );
    x_return_status := lc_return_status;
    x_return_message:= lc_errbuff;
    WHEN OTHERS THEN
        gc_err_code           := 'XX_OM_0008_UPDATE_LINE_DFF_ERR';
        gc_err_desc           := SUBSTR(lc_errbuff|| SQLERRM,1,1000);
        gc_entity_ref         := 'Order Line Id';
        gn_entity_ref_id      := NVL(gn_line_id,0);
        -- Calling the exception framework
        gc_err_report_type    :=
                                  XX_OM_REPORT_EXCEPTION_T (
                                                                gc_exception_header
                                                               ,gc_exception_track
                                                               ,gc_exception_sol_dom
                                                               ,gc_error_function
                                                               ,gc_err_code
                                                               ,gc_err_desc
                                                               ,gc_entity_ref
                                                               ,gn_entity_ref_id
                                                          );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                         gc_err_report_type
                                                        ,lc_errbuff
                                                        ,lc_retcode
                                                    );
        x_return_status  := NVL(lc_return_status,'E');
        x_return_message := gc_err_desc;
END UPDATE_OE_LINE_DFF;
-- +===================================================================+
-- | Name           : REQ_DIST                                         |
-- | Description    : Gets the requsition distribution Id of the newly |
-- |                  created requisition in a partial receipt         |
-- |                  scenario.                                        |
-- | Parameters     : p_req_dist_id                                    |
-- |                                                                   |
-- | Returns        : NUMBER                                           |
-- |                                                                   |
-- +===================================================================+
FUNCTION REQ_DIST ( p_req_dist_id IN po_req_distributions_all.distribution_id%TYPE )
RETURN NUMBER
AS
ln_req_dist_id  po_req_distributions_all.distribution_id%TYPE;
BEGIN
    -- To get the requsition distribution_id of the new requisition created.
    SELECT MAX (distribution_id ) 
    INTO ln_req_dist_id 
    FROM po_req_distributions_all PRD 
    START WITH PRD.distribution_id = p_req_dist_id
    CONNECT BY PRIOR PRD.distribution_id  = PRD.source_req_distribution_id;
    RETURN ln_req_dist_id;
END;
END XX_WFL_POACCREJ_PKG;
