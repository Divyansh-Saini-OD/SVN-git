CREATE OR REPLACE
PACKAGE BODY XX_CS_AOPS_ORDER_PKG
AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- +===================================================================+
  -- | Name  :  XX_CS_AOPS_ORDER_PKG                                     |
  -- |                                                                   |
  -- | Description: Wrapper package for Vendor Communications.           |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author           Remarks                     |
  -- |=======   ==========  =============    ============================|
  -- |1.0       24-SEP-12   Raj Jagarlamudi  Initial draft version       |
  -- |2.0       29-MAY-2014 Arun Gannarapu   added the logic to set the
  -- |                                       total_retail_count for COGS |
  -- |3.0       19-JUN-2014 Arun Gannarapu   Added the logic to set the  |
  -- |                                       prev_curr_cnt for COGS      |
  -- |4.0       22-JAN-2016 Vasu Raparla     Removed Schema References   |
  -- |                                       for R.12.2                  |
  -- +===================================================================+
  gc_action         VARCHAR2(100);
  gc_user_name      VARCHAR2(150) ;
  gc_request_number VARCHAR2(25);
  /*****************************************************************************
  -- Log Messages
  ****************************************************************************/
PROCEDURE Log_Exception(
    p_request_number     IN VARCHAR2 ,
    p_error_location     IN VARCHAR2 ,
    p_error_message_code IN VARCHAR2 ,
    p_error_msg          IN VARCHAR2 )
IS
  ln_login PLS_INTEGER   := FND_GLOBAL.Login_Id;
  ln_user_id PLS_INTEGER := FND_GLOBAL.User_Id;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error ( p_return_code => FND_API.G_RET_STS_ERROR ,p_msg_count => 1 ,p_application_name => 'XX_CRM' ,p_program_type => 'Custom Messages' ,p_program_name => 'XX_CS_AOPS_ORDER_PKG' ,p_program_id => p_request_number ,p_module_name => 'MPS' ,p_error_location => p_error_location ,p_error_message_code => p_error_message_code ,p_error_message => p_error_msg ,p_error_message_severity => 'MAJOR' ,p_error_status => 'ACTIVE' ,p_created_by => ln_user_id ,p_last_updated_by => ln_user_id ,p_last_update_login => ln_login );
END Log_Exception;
/**************************************************************************/
PROCEDURE GET_RES(
    P_REQUEST_NUMBER IN VARCHAR2,
    P_RESP           IN XMLTYPE,
    X_RETURN_STATUS  IN OUT VARCHAR2,
    X_RETURN_MSG     IN OUT VARCHAR2)
IS
  LC_ORDER_NUM     VARCHAR2(25);
  LD_ORDER_DATE    DATE;
  LC_SPLIT_ORDERS  VARCHAR2(50);
  LC_STATUS_CODE   VARCHAR2(25);
  LC_ORDER_STATUS  VARCHAR2(50);
  LD_DELIVERY_DATE DATE;
  LC_DESCRIPTION   VARCHAR2(250);
  LC_MESSAGE       VARCHAR2(2000);
  LN_INCIDENT_ID   NUMBER;
  LR_SR_REQ_REC XX_CS_SR_REC_TYPE;
  LN_TYPE_ID               NUMBER;
  LC_REQUEST_TYPE          VARCHAR2(50);
  LC_SERIAL_NO             VARCHAR2(25);
  lc_string                VARCHAR2(100);
  LC_WAREHOUSE_ID          VARCHAR2(25);
  LN_BLACK_COST            NUMBER;
  LN_COLOR_COST            NUMBER;
  ln_order_cnt             NUMBER;
  ln_order_total           NUMBER;
  ln_change_in_color_count NUMBER := 0;
  ln_change_in_black_count NUMBER := 0;
  lc_change                VARCHAR2(1) ;
  lc_color_change          VARCHAR2(1) ;
  --
  v_document dbms_xmldom.DOMDocument;
  v_node_list dbms_xmldom.DOMNodeList;
  v_node_list2 dbms_xmldom.DOMNodeList;
  v_node dbms_xmldom.DOMNode;
  v_ele dbms_xmldom.DOMElement;
  v_childnode dbms_xmldom.DOMNode;
  ndoc dbms_xmldom.DOMNode;
  v_nodename VARCHAR2(100);
  v_len      NUMBER;
BEGIN
  --dbms_output.put_line('xml status '||p_request_number);
  BEGIN
    -- fnd_file.put_line(fnd_file.log, 'Begin.. ln_order_total...');
    -- warehouse
    lc_warehouse_id := p_resp.EXTRACT('/ODPurchaseOrder/Header/ShipTo/@invLoc').getstringval();
    -- Split Orders cnt
    lc_string    := p_resp.EXTRACT('/ODPurchaseOrder/Response/NumberOfOrders/text()').getStringVal();
    ln_order_cnt := to_number(lc_string);
    -- Order Total
    IF ln_order_cnt   = 1 THEN
      lc_string      := p_resp.EXTRACT('/ODPurchaseOrder/Response/Detail/Totals/Total/text()').getStringVal();
      ln_order_total := to_number(lc_string);
    END IF;
    fnd_file.put_line(fnd_file.log, 'Warehouse and orders '||lc_warehouse_id||' - '||ln_order_cnt||'='||ln_order_total);
    -- dbms_output.put_line('Warehouse and orders '||lc_warehouse_id||' - '||ln_order_cnt||'='||ln_order_total);
  EXCEPTION
  WHEN OTHERS THEN
    NULL;
    x_return_msg := 'Error while getting warehouse id '||sqlerrm;
    Log_Exception ( p_request_number => p_request_number ,p_error_location => 'XX_CS_AOPS_ORDER_PKG.GET_RES' ,p_error_message_code => 'XX_CS_SR01a_ERR_LOG' ,p_error_msg => 'Status '||x_return_status||' '||X_RETURN_MSG);
  END;
  ----
  fnd_file.put_line(fnd_file.log, '-----------***Start of Value Assingnings***------------');
  BEGIN
    v_document := dbms_xmldom.newdomdocument(p_resp);
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log, 'Value for v_document'||SQLERRM);
  END;
  BEGIN
    ndoc := dbms_xmldom.makeNode(v_document);
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log, 'Value for ndoc'||SQLERRM);
  END;
  BEGIN
    v_node_list := dbms_xslprocessor.selectNodes(ndoc,'//Response/*/*');
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log, 'Value for v_node_list'||SQLERRM);
  END;
  BEGIN
    v_len := dbms_xmldom.getLength(v_node_list);
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log, 'Value for v_len'||SQLERRM);
  END;
  --dbms_output.put_line('node len '|| dbms_xmldom.getLength(v_node_list));
  FOR j IN 1..dbms_xmldom.getLength(v_node_list)
  LOOP
    BEGIN
      fnd_file.put_line(fnd_file.log, 'LOOP j Begins......................');
      v_node := dbms_xmldom.item(v_node_list, j-1);
      fnd_file.put_line(fnd_file.log, 'value of node list'||j);-- added for testing
    EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log, 'Line 1 v_node...'||SQLERRM);
    END;
    BEGIN
      v_ele := dbms_xmldom.makeElement(v_node);
      fnd_file.put_line(fnd_file.log, 'element of node list ');-- added for testing
    EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log, 'Line 2 v_ele...'||SQLERRM);
    END;
    BEGIN
      v_nodename := dbms_xmldom.getTagName(v_ele);
      fnd_file.put_line(fnd_file.log, 'node name of element '||v_nodename);-- added for testing
    EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log, 'Line 3 v_nodename...'||SQLERRM);
    END;
    BEGIN
      v_childnode := dbms_xmldom.getFirstChild(v_node);
      --fnd_file.put_line(fnd_file.log, 'child node of node name '||v_childnode);-- added for testing
    EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log, 'Line 3 v_childnode...'||SQLERRM);
    END;
    --dbms_output.put_line('node name '||v_nodename);
    --fnd_file.put_line(fnd_file.log, 'v_nodename :'||v_nodename);
    IF v_nodename     = 'Code' THEN
      lc_status_code := dbms_xmldom.getNodeValue(v_childnode) ;
      fnd_file.put_line(fnd_file.log, 'status code :'||lc_status_code);
      -- dbms_output.put_line('Status code ****'||lc_status_code);
    elsif v_nodename  = 'Description' THEN
      lc_description := dbms_xmldom.getNodeValue(v_childnode);
      fnd_file.put_line(fnd_file.log, 'description :'||lc_description); --added for testing
      --  dbms_output.put_line('Error description '||lc_description);
    elsif v_nodename = 'OrderDetails' THEN
      BEGIN
        v_node_list2 := dbms_xslprocessor.selectNodes(ndoc,'//Response/*/*/*');
       fnd_file.put_line(fnd_file.log, 'OrderDetails :'||v_nodename);                --added for testing
       -- fnd_file.put_line(fnd_file.log, 'OrderDetails/v_node_list2 :'||v_node_list2); --added for testing
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log, 'v_node_list2...'||SQLERRM);
      END;
      --  fnd_file.put_line(fnd_file.log, 'node list2 : v_node_list2');
      -- order details info.
      BEGIN
        fnd_file.put_line(fnd_file.log, '-----------***End of Value Assingnings***------------');
        fnd_file.put_line(fnd_file.log, 'startt d loop if node name is order details'); -- addeed for testing
        
          FOR d IN 1..dbms_xmldom.getLength(v_node_list2)
          LOOP
          begin
            fnd_file.put_line(fnd_file.log, 'LOOP d begins.....................');
            v_node := dbms_xmldom.item(v_node_list2, d-1);
            fnd_file.put_line(fnd_file.log, 'number of nodes '||d); -- addeed for testing
          EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'v_node '||SQLERRM);
          END;
          BEGIN
            v_ele := dbms_xmldom.makeElement(v_node);
           -- fnd_file.put_line(fnd_file.log, 'element of v_node'||v_ele); -- addeed for testing
          EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'v_ele '||SQLERRM);
          END;
          BEGIN
            v_nodename := dbms_xmldom.getTagName(v_ele);
           fnd_file.put_line(fnd_file.log, 'node name of element'||v_nodename); -- addeed for testing
          EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'detail node '||SQLERRM);
          END;
          BEGIN
            v_childnode := dbms_xmldom.getFirstChild(v_node);
           -- fnd_file.put_line(fnd_file.log, 'child node of node name '||v_childnode); -- addeed for testing
          EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'v_childnode '||SQLERRM);
          END;
          --   dbms_output.put_line('V_ELE '||v_ele);
          --dbms_output.put_line('detail node '||v_nodename);
          fnd_file.put_line(fnd_file.log, 'started process to get order number'||v_nodename); -- addeed for testing
          IF v_nodename = 'OrderNumber' THEN
            BEGIN
              lc_order_num := dbms_xmldom.getNodeValue(v_childnode);
              fnd_file.put_line(fnd_file.log, 'Order num :'||lc_order_num); -- addeed for testing;
            EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log, 'Order num :'||SQLERRM);
            END;
          elsif v_nodename = 'OrderStatus' THEN
            BEGIN
              lc_order_status := lc_order_num||dbms_xmldom.getNodeValue(v_childnode);
              fnd_file.put_line(fnd_file.log, 'Order status :'||lc_order_status); -- addeed for testing;
            EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log, 'Order status :'||SQLERRM);
            END;
          elsif v_nodename = 'OrderDate' THEN
            BEGIN
              ld_order_date := to_date(dbms_xmldom.getNodeValue(v_childnode),'mm/dd/yyyy');
              fnd_file.put_line(fnd_file.log, 'ld order Date :'||ld_order_date); -- addeed for testing;
            EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log, 'ld order Date :'||SQLERRM);
            END;
          elsif v_nodename = 'DeliveryDate' THEN
            BEGIN
              ld_delivery_date := to_date(dbms_xmldom.getNodeValue(v_childnode),'mm/dd/yyyy');
              fnd_file.put_line(fnd_file.log, 'Delivery Date :'||ld_delivery_date); -- addeed for testing;
            EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log, 'Delivery Date :'||SQLERRM);
              --  dbms_output.put_line('Delivery Date '||ld_delivery_date);
            END;
          END IF;
        END LOOP;
      EXCEPTION
      WHEN OTHERS THEN
        x_return_status := 'E';
        x_return_msg    := 'error XML parser '||sqlerrm;
        Log_Exception ( p_request_number => p_request_number ,p_error_location => 'XX_CS_AOPS_ORDER_PKG.GET_RES' ,p_error_message_code => 'XX_CS_SR01_ERR_LOG' ,p_error_msg => 'Status '||x_return_status||' '||X_RETURN_MSG);
      END;
      --split order details
      fnd_file.put_line(fnd_file.log, 'split order details'); -- addeed for testing;
      IF ln_order_cnt > 1 THEN
        fnd_file.put_line(fnd_file.log, 'orders count'||ln_order_cnt); -- addeed for testing;
        BEGIN
          v_node_list2 := dbms_xslprocessor.selectNodes(ndoc,'//Response/*/*/*');
        EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log, 'ln_order_cnt > 1 ~ v_node_list2....'||SQLERRM);
        END;
        -- order details info.
        BEGIN
          FOR d IN 1..dbms_xmldom.getLength(v_node_list2)
          LOOP
            fnd_file.put_line(fnd_file.log, 'split order details loop'); -- addeed for testing;
            v_node       := dbms_xmldom.item(v_node_list2, d-1);
            v_ele        := dbms_xmldom.makeElement(v_node);
            v_nodename   := dbms_xmldom.getTagName(v_ele);
            v_childnode  := dbms_xmldom.getFirstChild(v_node);
            IF v_nodename = 'OrderNumber' THEN
              BEGIN
                -- lc_order_num := dbms_xmldom.getNodeValue(v_childnode);
                lc_split_orders := dbms_xmldom.getNodeValue(v_childnode);
                fnd_file.put_line(fnd_file.log, 'split order number'||lc_split_orders); -- addeed for testing;
              EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log, 'lc_split_orders....'||SQLERRM);
              END;
            END IF;
          END LOOP;
        EXCEPTION
        WHEN OTHERS THEN
          x_return_status := 'E';
          x_return_msg    := 'error XML parser '||sqlerrm;
          Log_Exception ( p_request_number => p_request_number ,p_error_location => 'XX_CS_AOPS_ORDER_PKG.GET_RES' ,p_error_message_code => 'XX_CS_SR01_ERR_LOG' ,p_error_msg => 'Status '||x_return_status||' '||X_RETURN_MSG);
        END;
      END IF;
      fnd_file.put_line(fnd_file.log, 'v_nodename :'||v_nodename);
    END IF;
  END LOOP;
  BEGIN
    SELECT incident_id ,
      incident_type_id,
      incident_attribute_3
    INTO ln_incident_id,
      ln_type_id,
      lc_serial_no
    FROM cs_incidents_all_b
    WHERE incident_number = p_request_number;
  EXCEPTION
  WHEN OTHERS THEN
    ln_incident_id  := NULL;
    x_return_status := 'E';
    x_return_msg    := 'Error while selecing incident_id '||sqlerrm;
  END;
  --  dbms_output.put_line('incident ...'||ln_incident_id||' '||x_return_status||'Response code '||lc_status_code);
  IF NVL(x_return_status,'S') = 'S' THEN   
   lr_sr_req_rec := XX_CS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL);
    --assign values
    IF lc_status_code = 200 THEN
      LC_MESSAGE     := 'AOPS Order#'||lc_order_num||' created successfully';
      fnd_file.put_line(fnd_file.log, 'AOPS Order#'||lc_order_num||' created successfully');
      IF lc_split_orders IS NOT NULL THEN
        LC_MESSAGE       := 'AOPS Orders#'||lc_order_num||', '||lc_split_orders||' created successfully';
        fnd_file.put_line(fnd_file.log, 'AOPS Orders#'||lc_order_num||', '||lc_split_orders||' created successfully');
      END IF;
      lr_sr_req_rec.status_name := 'Order Placed';
    ELSE
      LC_MESSAGE                := lc_description;
      lr_sr_req_rec.status_name := 'Order Rejected';
      lr_sr_req_rec.zz_flag     := '_1';
    END IF;
    lr_sr_req_rec.request_id     := ln_incident_id;
    lr_sr_req_rec.request_number := p_request_number;
    lr_sr_req_rec.order_number   := lc_order_num;
    lr_sr_req_rec.ship_date      := ld_delivery_date;
    lr_sr_req_rec.csc_location   := lc_split_orders; -- split order information passing
    lr_sr_req_rec.warehouse_id   := to_number(lc_warehouse_id);
    lc_request_type              := 'MPS Supplies Request';
    BEGIN
      XX_CS_MPS_UTILITIES_PKG.UPDATE_SR (P_REQUEST_ID => LN_INCIDENT_ID, P_COMMENTS => LC_MESSAGE, P_REQ_TYPE => LC_REQUEST_TYPE, P_SR_REQ_REC => LR_SR_REQ_REC, X_RETURN_STATUS => X_RETURN_STATUS, X_RETURN_MSG => X_RETURN_MSG);
      /*      dbms_output.put_line('SR Update status '||x_return_status||' '||x_return_msg);
      Log_Exception ( p_request_number => p_request_number
      ,p_error_location     =>  'XX_CS_AOPS_ORDER_PKG.GET_RES'
      ,p_error_message_code =>  'XX_CS_SR01_LOG'
      ,p_error_msg          =>  'Status '||x_return_status); */
      IF NVL(X_RETURN_STATUS, 'N') = 'E' THEN
        Log_Exception ( p_request_number => p_request_number ,p_error_location => 'XX_CS_AOPS_ORDER_PKG.GET_RES' ,p_error_message_code => 'XX_CS_SR01_ERR_LOG' ,p_error_msg => X_RETURN_MSG);
      END IF;
      -- Check if there is any change in the counts
      BEGIN
        SELECT ( NVL(total_color_count,0) -
          (SELECT NVL(Previous_color_count,0)
          FROM xx_cs_mps_device_details
          WHERE supplies_label = 'TONERLEVEL_BLACK'
          AND serial_no        = lc_serial_no
          )),
          ( NVL(total_black_count,0) -
          (SELECT NVL(Previous_black_count,0)
          FROM xx_cs_mps_device_details
          WHERE supplies_label = 'TONERLEVEL_BLACK'
          AND serial_no        = lc_serial_no
          ))
        INTO ln_change_in_color_count,
          ln_change_in_black_count
        FROM xx_cs_mps_device_details
        WHERE supplies_label = 'USAGE'
        AND serial_no        = lc_serial_no ;
      EXCEPTION
      WHEN OTHERS THEN
        ln_change_in_color_count := 0;
        ln_change_in_black_count := 0;
      END;
      fnd_file.put_line(fnd_file.log, 'ln_change_in_color_count :'||ln_change_in_color_count ||'ln_change_in_black_count:'||ln_change_in_black_count);
      fnd_file.put_line(fnd_file.log, 'Order total :'||LN_ORDER_TOTAL);
      IF ( ln_change_in_black_count = 0 AND ln_change_in_color_count = 0 ) THEN
        lc_change                  := 'N';
      ELSE
        lc_change := 'Y';
      END IF;
      IF ln_change_in_color_count = 0 THEN
        lc_color_change          := 'N';
      ELSE
        lc_color_change := 'Y';
      END IF;
      fnd_file.put_line(fnd_file.log, 'lc_change :'||lc_change ||'lc_color_change:'||lc_color_change);
      IF LN_ORDER_TOTAL = 0 THEN
        BEGIN
          SELECT NVL(black_cpc,0)-NVL(service_cost,0),
            NVL(color_cpc,0)     -NVL(service_cost,0)
          INTO ln_black_cost,
            ln_color_cost
          FROM xx_cs_mps_device_b
          WHERE serial_no = lc_serial_no;
        EXCEPTION
        WHEN OTHERS THEN
          NULL;
        END;
        -- update mps details table
        BEGIN
          UPDATE XX_CS_MPS_DEVICE_DETAILS
          SET TONER_ORDER_NUMBER      = LC_ORDER_NUM,
            TONER_ORDER_DATE          = LD_ORDER_DATE,
            DELIVERY_DATE             = LD_DELIVERY_DATE,
            USAGE_BILLED              = NULL,
            TONER_ORDER_TOTAL         = ROUND((NVL(CURRENT_COUNT,0) +NVL(PREV_CURRENT_COUNT,0)) * (DECODE(SUPPLIES_LABEL, 'TONERLEVEL_BLACK', LN_BLACK_COST, LN_COLOR_COST)),2),
            ATTRIBUTE3                = LC_WAREHOUSE_ID,
            TONER_STOCK               = NVL(TONER_STOCK,0)                                + 1,
            TOTAL_RETAIL_COUNT        = DECODE(lc_change , 'Y', NVL(total_retail_count,0) + NVL(Current_count, 0)+NVL(PREV_CURRENT_COUNT,0), NVL(total_retail_count,0) + NVL(PREV_CURRENT_COUNT,0)),
            PREV_CURRENT_COUNT        = NULL
          WHERE SERIAL_NO             = LC_SERIAL_NO
          AND SUPPLIES_LABEL NOT     IN ( 'USAGE','TONERLEVEL_BLACK')
          AND NVL(REQUEST_NUMBER,'X') = P_REQUEST_NUMBER;
          UPDATE XX_CS_MPS_DEVICE_DETAILS
          SET TONER_ORDER_NUMBER      = LC_ORDER_NUM,
            TONER_ORDER_DATE          = LD_ORDER_DATE,
            DELIVERY_DATE             = LD_DELIVERY_DATE,
            TONER_ORDER_TOTAL         = ROUND((NVL(CURRENT_COUNT,0) +NVL(PREV_CURRENT_COUNT,0)) * (DECODE(SUPPLIES_LABEL, 'TONERLEVEL_BLACK', LN_BLACK_COST, LN_COLOR_COST)),2),
            ATTRIBUTE3                = LC_WAREHOUSE_ID,
            USAGE_BILLED              = NULL,
            TONER_STOCK               = NVL(TONER_STOCK,0)        + 1,
            TOTAL_RETAIL_COUNT        = NVL(total_retail_count,0) + NVL(Current_count, 0)+NVL(PREV_CURRENT_COUNT,0),
            PREV_CURRENT_COUNT        = NULL
          WHERE SERIAL_NO             = LC_SERIAL_NO
          AND SUPPLIES_LABEL          = 'TONERLEVEL_BLACK'
          AND NVL(REQUEST_NUMBER,'X') = P_REQUEST_NUMBER;
          IF lc_color_change          = 'Y' THEN
            UPDATE XX_CS_MPS_DEVICE_DETAILS
            SET PREV_CURRENT_COUNT       = NVL(PREV_CURRENT_COUNT,0) + NVL( CURRENT_COUNT , 0)
            WHERE SERIAL_NO              = LC_SERIAL_NO
            AND SUPPLIES_LABEL NOT      IN ( 'USAGE','TONERLEVEL_BLACK')
            AND NVL(REQUEST_NUMBER,'X') != P_REQUEST_NUMBER;
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          X_RETURN_MSG := 'Error while updating Order info '||sqlerrm;
          Log_Exception ( p_request_number => p_request_number ,p_error_location => 'XX_CS_AOPS_ORDER_PKG.GET_RES' ,p_error_message_code => 'XX_CS_SR01A_ERR_LOG' ,p_error_msg => X_RETURN_MSG);
        END;
      ELSE
        -- update mps details table
        BEGIN
          UPDATE XX_CS_MPS_DEVICE_DETAILS
          SET TONER_ORDER_NUMBER      = LC_ORDER_NUM,
            TONER_ORDER_DATE          = LD_ORDER_DATE,
            DELIVERY_DATE             = LD_DELIVERY_DATE,
            TONER_ORDER_TOTAL         = ROUND(LN_ORDER_TOTAL,2),
            ATTRIBUTE3                = LC_WAREHOUSE_ID,
            TOTAL_RETAIL_COUNT        = DECODE(lc_change , 'Y', NVL(total_retail_count,0) + NVL(Current_count, 0)+NVL(PREV_CURRENT_COUNT,0), NVL(total_retail_count,0) + NVL(PREV_CURRENT_COUNT,0)),
            PREV_CURRENT_COUNT        = NULL
          WHERE SERIAL_NO             = LC_SERIAL_NO
          AND NVL(REQUEST_NUMBER,'X') = P_REQUEST_NUMBER;
          IF lc_color_change          = 'Y' THEN
            UPDATE XX_CS_MPS_DEVICE_DETAILS
            SET PREV_CURRENT_COUNT       = NVL(PREV_CURRENT_COUNT,0) + NVL( CURRENT_COUNT , 0)
            WHERE SERIAL_NO              = LC_SERIAL_NO
            AND SUPPLIES_LABEL NOT      IN ( 'USAGE','TONERLEVEL_BLACK')
            AND NVL(REQUEST_NUMBER,'X') != P_REQUEST_NUMBER;
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          X_RETURN_MSG := 'Error while updating Order info '||sqlerrm;
          Log_Exception ( p_request_number => p_request_number ,p_error_location => 'XX_CS_AOPS_ORDER_PKG.GET_RES' ,p_error_message_code => 'XX_CS_SR01A_ERR_LOG' ,p_error_msg => X_RETURN_MSG);
        END;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      lc_message := 'error while calling update sr '||sqlerrm;
      Log_Exception ( p_request_number => p_request_number ,p_error_location => 'XX_CS_AOPS_ORDER_PKG.GET_RES' ,p_error_message_code => 'XX_CS_SR02_ERR_LOG' ,p_error_msg => lc_message);
    END;
  END IF;
END;
/**************************************************************************/
FUNCTION http_post(
    url      VARCHAR2,
    req_body VARCHAR2)
  RETURN VARCHAR2
AS
  soap_request VARCHAR2(30000);
  soap_respond VARCHAR2(30000);
  req utl_http.req;
  resp utl_http.resp;
  v_response_text VARCHAR2(32767);
  x_resp XMLTYPE;
  l_detail   VARCHAR2(32767);
  i          INTEGER;
  l_msg_data VARCHAR2(30000);
  --
  v_doc dbms_xmldom.DOMDocument;
  v_node_list dbms_xmldom.DOMNodeList;
  v_node dbms_xmldom.DOMNode;
  v_nodename VARCHAR2(150);
  v_ele dbms_xmldom.DOMElement;
  v_childnode dbms_xmldom.DOMNode;
  ndoc dbms_xmldom.DOMNode;
  v_len            NUMBER;
  ln_serviceId     NUMBER;
  lc_status        VARCHAR2(150);
  lc_return_status VARCHAR2(100) := 'false';
  lc_conn_link     VARCHAR2(3000);
  lc_message       VARCHAR2(3000);
  lr_sku_tbl XX_CS_TDS_SKU_TBL;
  lc_receiver VARCHAR2(100);
BEGIN
fnd_file.put_line(fnd_file.log, 'enter of https_Post function of aops Package');
  -- 315515
  /* soap_request:= '<?xml version = "1.0" encoding = "UTF-8"?>'||
  '<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified">'||req_body||
  '</xs:schema>'; */
  soap_request:= '<?xml version = "1.0" encoding = "UTF-8"?>'||req_body;
  l_msg_data  := soap_request;
  Log_Exception ( p_request_number => gc_request_number ,p_error_location => 'XX_CS_AOPS_ORDER_PKG.HTTP_POST' ,p_error_message_code => 'XX_CS_SR01_SUCCESS_LOG' ,p_error_msg => l_msg_data);
  --dbms_output.put_line(soap_request);
  fnd_file.put_line(fnd_file.log, 'URL:   '||url);
  fnd_file.put_line(fnd_file.log, 'Begin Request to POST the URL in AOPS Package...');
  req := utl_http.begin_request(url,'POST','HTTP/1.1'); -- Changed from POST to GET in UATGB on 15 Feb'18
  --  UTL_HTTP.SET_AUTHENTICATION (HTTP_REQ, 'G016D01/S0162114', 'Xenios02', 'Basic',true);
  utl_http.set_header(req,'Content-Type', 'text/xml'); --; charset=utf-8');
  utl_http.set_header(req,'Content-Length', LENGTH(soap_request));
  utl_http.set_header(req , 'SOAPAction' , 'process');
  utl_http.write_text(req, soap_request);
  fnd_file.put_line(fnd_file.log, 'Write soap Request... '||soap_request);
  resp := utl_http.get_response(req);
  fnd_file.put_line(fnd_file.log, 'Get Response... '||resp.status_code);
  utl_http.read_text(resp, soap_respond);
  fnd_file.put_line(fnd_file.log, 'Reading Text of soap Response... '||soap_respond);
  lc_message := 'Response Received '||resp.status_code;
  utl_http.end_response(resp);
  x_resp := XMLType.createXML(soap_respond);
  --fnd_file.put_line(fnd_file.log, 'XMLType.createXML... '||soap_respond);
  l_msg_data := 'Req '||soap_request;
  /*
  Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.HTTP_POST'
  ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
  ,p_error_msg          =>  l_msg_data);
  */
  --    x_resp := x_resp.extract('/soap:Envelop/soap:Body/child::node()'
  --              ,'xmlns:soap="http://TargetNamespace.com/XMLSchema-instance"');
  --dbms_output.put_line('Output '|| soap_respond);
  l_msg_data := 'Res '||soap_respond;
  Log_Exception ( p_request_number => gc_request_number ,p_error_location => 'XX_CS_AOPS_ORDER_PKG.HTTP_POST' ,p_error_message_code => 'XX_CS_SR01_SUCCESS_LOG' ,p_error_msg => l_msg_data);
  l_msg_data := lc_message;
  dbms_output.put_line('resp '||l_msg_data);
  v_response_text := l_msg_data;
  GET_RES(P_REQUEST_NUMBER => gc_request_number, P_RESP => x_resp, X_RETURN_STATUS => lc_status, X_RETURN_MSG => lc_message);
  RETURN v_response_text;
END;
/*------------------------------------------------------------------------
Procedure Name : Make_Param_Str
Description    : concatenates parameters for XML message
--------------------------------------------------------------------------*/
FUNCTION Make_Param_Str(
    p_param_name  IN VARCHAR2,
    p_attr_name   IN VARCHAR2,
    p_param_value IN VARCHAR2)
  RETURN VARCHAR2
IS
BEGIN
 fnd_file.put_line(fnd_file.log, 'enter the make_param_str function');
  IF P_ATTR_NAME IS NOT NULL THEN
    RETURN '<'||p_param_name||' '||p_attr_name||'="'||p_param_value||'">';
  ELSE
    RETURN '<'||p_param_name|| '>'||'<![CDATA['||p_param_value||']]>'||'</'||p_param_name||'>';
  END IF;
END Make_Param_Str;
--------------------------------------------------------------------------------
/*****************************************************************************/
PROCEDURE MAIN_PROC(
    P_HDR_REC        IN OUT NOCOPY XX_CS_ORDER_HDR_REC,
    P_LINE_TBL       IN OUT NOCOPY XX_CS_ORDER_LINES_TBL,
    P_REQUEST_NUMBER IN VARCHAR2,
    X_RETURN_STATUS  IN OUT NOCOPY VARCHAR2,
    X_RETURN_MSG     IN OUT NOCOPY VARCHAR2)
AS
 -- fnd_file.put_line(fnd_file.log, 'enter the main_proc of aops Package');
  L_URL VARCHAR2(1000):= FND_PROFILE.VALUE('XX_AOPS_ORDER_B2B_LINK'); -- OD : CS AOPS ORDER B2B LINK
  --http://b2bwmvendors.officedepot.com:5555/rest/ODServices/purchaseOrder?async=false
  --https://b2bwmvendors.officedepot.com/rest/ODServices/api/orders?async=false
  -- 'http://b2bwmvendors.officedepot.com:5555/rest/ODServices/purchaseOrder?async=false';
  -- 'http://b2bwmvendors.officedepot.com:5555/rest/ODServices/purchaseOrder?async=false
  --  https://b2bwmtest.officedepot.com/rest/ODServices/api/product/inventory?
  l_msg_data      VARCHAR2(32767) ;
  l_init_str      VARCHAR2(30000);
  l_return_status VARCHAR2(30);
  l_msg_count     NUMBER ;
  lc_aops_id      VARCHAR2(25);
  lc_aops_billto  VARCHAR2(25);
  lc_aops_shipto  VARCHAR2(25);
  lc_aops_contid  VARCHAR2(25);
  i               NUMBER;
BEGIN
  /* TODO implementation required */
  GC_REQUEST_NUMBER := P_REQUEST_NUMBER;
  -- Determine AOPS ID, SHIP-TO, BILL-TO
  fnd_file.put_line(fnd_file.log, 'enter the begin section of main_proc of aops Package');
  IF p_hdr_rec.party_id IS NOT NULL THEN
    BEGIN
      SELECT SUBSTR(orig_system_reference,1,8)
      INTO lc_aops_id
      FROM hz_cust_accounts_all
      WHERE party_id = p_hdr_rec.party_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      LC_AOPS_ID      := NULL;
      X_RETURN_STATUS := 'E';
      X_RETURN_MSG    := 'No Data Found Raised while validating customer ref num ';
      Log_Exception (p_request_number => NULL ,p_error_location => 'XX_CS_AOPS_ORDER_PKG.MAIN_PROC' ,P_ERROR_MESSAGE_CODE => 'XX_CS_SR01_ERR_LOG' ,p_error_msg => X_RETURN_MSG);
    WHEN OTHERS THEN
      LC_AOPS_ID      := NULL;
      X_RETURN_STATUS := 'E';
      X_RETURN_MSG    := 'When Others Raised while validating customer ref num ' || sqlerrm;
      Log_Exception (p_request_number => NULL ,p_error_location => 'XX_CS_AOPS_ORDER_PKG.MAIN_PROC' ,P_ERROR_MESSAGE_CODE => 'XX_CS_SR01_ERR_LOG' ,p_error_msg => X_RETURN_MSG);
    END;
  END IF;
  IF p_hdr_rec.bill_to IS NOT NULL THEN
   fnd_file.put_line(fnd_file.log, 'enter the bill_to section of main_proc of aops Package');
    BEGIN
      SELECT SUBSTR(hcs.orig_system_reference,1,8)
      INTO lc_aops_billto
      FROM hz_cust_site_uses_all hcs ,
        hz_cust_accounts_all hca ,
        hz_cust_acct_sites_all hcas
      WHERE hca.party_id         = p_hdr_rec.bill_to
      AND hca.cust_account_id    = hcas.cust_account_id
      AND hcas.cust_acct_site_id = hcs.cust_acct_site_id
      AND HCS.SITE_USE_CODE      = 'BILL_TO'
      AND hcs.primary_flag       = 'Y';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lc_aops_billto  := NULL;
      X_RETURN_STATUS := 'E';
      X_RETURN_MSG    := 'No Data Found Raised while validating Bill To ref num ';
      Log_Exception (p_request_number => NULL ,p_error_location => 'XX_CS_AOPS_ORDER_PKG.MAIN_PROC' ,P_ERROR_MESSAGE_CODE => 'XX_CS_SR01_ERR_LOG' ,p_error_msg => X_RETURN_MSG);
    WHEN OTHERS THEN
      lc_aops_billto  := NULL;
      X_RETURN_STATUS := 'E';
      X_RETURN_MSG    := 'When Others Raised while validating Bill TO ref num '|| SQLERRM;
      Log_Exception (p_request_number => NULL ,p_error_location => 'XX_CS_AOPS_ORDER_PKG.MAIN_PROC' ,P_ERROR_MESSAGE_CODE => 'XX_CS_SR01_ERR_LOG' ,p_error_msg => X_RETURN_MSG);
    END;
  END IF;
  IF p_hdr_rec.ship_to IS NOT NULL THEN
    BEGIN
      SELECT SUBSTR(orig_system_reference,10,5)
      INTO lc_aops_shipto
      FROM HZ_CUST_SITE_USES_ALL a
      WHERE SITE_USE_ID = P_HDR_REC.ship_to;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lc_aops_shipto  := NULL;
      X_RETURN_STATUS := 'E';
      X_RETURN_MSG    := 'No Data Found Raised while validating Ship To ref num ';
      Log_Exception (p_request_number => NULL ,p_error_location => 'XX_CS_AOPS_ORDER_PKG.MAIN_PROC' ,P_ERROR_MESSAGE_CODE => 'XX_CS_SR01_ERR_LOG' ,p_error_msg => X_RETURN_MSG);
    WHEN OTHERS THEN
      lc_aops_shipto  := NULL;
      X_RETURN_STATUS := 'E';
      X_RETURN_MSG    := 'When Others Raised while validating Ship TO ref num ';
      Log_Exception (p_request_number => NULL ,p_error_location => 'XX_CS_AOPS_ORDER_PKG.MAIN_PROC' ,P_ERROR_MESSAGE_CODE => 'XX_CS_SR01_ERR_LOG' ,p_error_msg => X_RETURN_MSG);
    END;
  END IF;
  /*
  IF p_hdr_rec.contact_id IS NOT NULL THEN
  BEGIN
  SELECT orig_system_reference
  INTO lc_aops_contid
  FROM hz_cust_account_roles
  where CUST_ACCOUNT_ROLE_ID = P_HDR_REC.CONTACT_ID;
  EXCEPTION
  when NO_DATA_FOUND then
  lc_aops_contid := null;
  X_RETURN_STATUS := 'E';
  X_RETURN_MSG    := 'No Data Found Raised while validating Contact ref num ';
  Log_Exception (p_request_number => null
  ,p_error_location     =>  'XX_CS_AOPS_ORDER_PKG.MAIN_PROC'
  ,P_ERROR_MESSAGE_CODE =>   'XX_CS_SR01_ERR_LOG'
  ,p_error_msg          =>  X_RETURN_MSG);
  WHEN OTHERS THEN
  lc_aops_contid := null;
  X_RETURN_STATUS := 'E';
  X_RETURN_MSG    := 'When Others Raised while validating Contact ref num ';
  Log_Exception (p_request_number => null
  ,p_error_location     =>  'XX_CS_AOPS_ORDER_PKG.MAIN_PROC'
  ,P_ERROR_MESSAGE_CODE =>   'XX_CS_SR01_ERR_LOG'
  ,p_error_msg          =>  X_RETURN_MSG);
  end;
  END IF;
  */
  --lc_aops_shipto := '00001';
  -- Header string
  IF NVL(X_RETURN_STATUS,'S') = 'S' THEN
  
   fnd_file.put_line(fnd_file.log, 'enter the X_RETURN_STATUS, main_proc of aops Package');
    L_INIT_STR               := '<ODPurchaseOrder timeStamp="'||sysdate||'" documentid="'||p_request_number||p_hdr_rec.attribute2||'">';
    l_init_str               := l_init_str||'<Header>';
	fnd_file.put_line(fnd_file.log, 'enter the header, main_proc of aops Package');
    l_init_str               := l_init_str||Make_Param_Str('Username','','OfficeDepot_EBIZ');
    l_init_str               := l_init_str||Make_Param_Str('Password','','customer password');
    -- l_init_str := l_init_str||Make_Param_Str('SalesAssociateID','',p_hdr_rec.sales_person);
    l_init_str := l_init_str||Make_Param_Str('RequestedDeliveryDate','',SYSDATE);
    l_init_str := l_init_str||Make_Param_Str('Comments','',p_hdr_rec.special_instructions);
    -- SHIP TO
    l_init_str := l_init_str||'<ShipTo>';
	fnd_file.put_line(fnd_file.log, 'enter the <ShipTo>, main_proc of aops Package'||l_init_str);
    --  l_init_str := l_init_str||'<Addr>';
    l_init_str := l_init_str||Make_Param_Str('Addr','seq',lc_aops_shipto);
	fnd_file.put_line(fnd_file.log, 'enter the <ShipTo>, main_proc of aops Package'||lc_aops_shipto);
    -- Contact
    l_init_str := l_init_str||'<Contact>';
    l_init_str := l_init_str||Make_Param_Str('Name','',p_hdr_rec.contact_name);
    l_init_str := l_init_str||Make_Param_Str('Email','type','*HTML');
    l_init_str := l_init_str||NVL(p_hdr_rec.contact_email,'test@officedepot.com')||'</Email>';
    l_init_str := l_init_str||'<PhoneNumber>';
    l_init_str := l_init_str||Make_Param_Str('Number','',p_hdr_rec.contact_phone);
    l_init_str := l_init_str||'</PhoneNumber>';
    l_init_str := l_init_str||'<FaxNumber>';
    l_init_str := l_init_str||Make_Param_Str('Number','',p_hdr_rec.contact_phone);
    l_init_str := l_init_str||'</FaxNumber>';
    l_init_str := l_init_str||'</Contact>';
    l_init_str := l_init_str||'</Addr>';
    l_init_str := l_init_str||'</ShipTo>';
    -- BILL TO
    l_init_str := l_init_str||'<BillTo>';
    -- l_init_str := l_init_str||'<Addr>';
    l_init_str := l_init_str||Make_Param_Str('Addr','id',lc_aops_billto);
	fnd_file.put_line(fnd_file.log, 'enter the <Bill To>, main_proc of aops Package'||lc_aops_billto);
    l_init_str := l_init_str||'</Addr>';
    l_init_str := l_init_str||'</BillTo>';
    l_init_str := l_init_str||'</Header>';
    -- Request
    l_init_str := l_init_str||'<Request>';
    l_init_str := l_init_str||Make_Param_Str('OrderSource','',p_hdr_rec.order_category); -- MPS/XML
	fnd_file.put_line(fnd_file.log, 'enter the <order_source>, main_proc of aops Package'||p_hdr_rec.order_category);
    -- Accounting
    l_init_str := l_init_str||'<Accounting>';
    --Raj modified the order of soft header fields as per customer setups
    --    l_init_str := l_init_str||Make_Param_Str('CostCenter','',p_hdr_rec.cost_center);
    l_init_str := l_init_str||Make_Param_Str('CostCenter','',p_hdr_rec.release);
    l_init_str := l_init_str||Make_Param_Str('Desktop','',p_hdr_rec.desk_top);
    l_init_str := l_init_str||Make_Param_Str('PONumber','',p_hdr_rec.po_number);
    -- l_init_str := l_init_str||Make_Param_Str('Release','',p_hdr_rec.release);
    l_init_str := l_init_str||Make_Param_Str('Release','',p_hdr_rec.cost_center);
    l_init_str := l_init_str||Make_Param_Str('SerialNumber','',p_hdr_rec.serial_no);
    l_init_str := l_init_str||'</Accounting>';
    -- Payment  'CR' -- Credit Card and AB -- AB billing type
    l_init_str := l_init_str||'<Payment method="'||p_hdr_rec.tendertyp||'"></Payment>';
    -- Details
    l_init_str := l_init_str||'<Detail>';
    -- lines
    i := p_line_tbl.first;
    LOOP
	fnd_file.put_line(fnd_file.log, 'enter the enter loop , main_proc of aops Package'||i);
      l_init_str := l_init_str||'<Item>';
      l_init_str := l_init_str||Make_Param_Str('LineNumber','',p_line_tbl(i).line_number);
      l_init_str := l_init_str||Make_Param_Str('Sku','',p_line_tbl(i).sku);
      l_init_str := l_init_str||Make_Param_Str('Qty','',p_line_tbl(i).order_qty);
      l_init_str := l_init_str||Make_Param_Str('UnitPrice','',p_line_tbl(i).selling_price);
      l_init_str := l_init_str||Make_Param_Str('UnitOfMeasure','',p_line_tbl(i).uom);
      l_init_str := l_init_str||Make_Param_Str('Description','',p_line_tbl(i).item_description);
      l_init_str := l_init_str||Make_Param_Str('Comments','',p_line_tbl(i).comments);
      -- Raj disable to stop the line level validation
	  fnd_file.put_line(fnd_file.log, 'enter the enter loop , attribute value1'||p_hdr_rec.attribute1);
       IF nvl(p_hdr_rec.attribute1,'N') = 'Y' then
          l_init_str := l_init_str||Make_Param_Str('CostCenter','',p_hdr_rec.release);
        END IF;
            l_init_str := l_init_str||'</Item>';
      EXIT WHEN i = p_line_tbl.last;
      i := p_line_tbl.NEXT(i);
    end loop;
    l_init_str := l_init_str||'</Detail>';
    l_init_str := l_init_str||'</Request>';
    L_INIT_STR := L_INIT_STR||'</ODPurchaseOrder>';
	 fnd_file.put_line(fnd_file.log, 'after loop of aops Package');
    /*  l_msg_data := 'before calling  http_post  '||X_RETURN_STATUS;
    Log_Exception ( p_request_number => gc_request_number
    ,p_error_location     =>  'XX_CS_AOPS_ORDER_PKG.MAIN_PROC'
    ,p_error_message_code =>  'XX_CS_SR03_SUCCESS_LOG'
    ,p_error_msg          =>  l_msg_data); */
    BEGIN
    fnd_file.put_line(fnd_file.log, 'before calling of https_Post function of aops Package');
      l_msg_data := http_post (l_url,l_init_Str) ;
	  fnd_file.put_line(fnd_file.log, 'after calling of https_Post function of aops Package');
    EXCEPTION
    WHEN OTHERS THEN
      l_msg_data := 'In event  '||sqlerrm ;
      Log_Exception (p_request_number => NULL ,p_error_location => 'XX_CS_AOPS_ORDER_PKG.MAIN_PROC' ,p_error_message_code => 'XX_CS_SR01_ERR_LOG' ,p_error_msg => l_msg_data);
      fnd_file.put_line(fnd_file.log, 'exception of of https_Post function of aops Package');
    END;
  END IF;
END MAIN_PROC;
/**********************************************************************************************************/
END XX_CS_AOPS_ORDER_PKG;
/
