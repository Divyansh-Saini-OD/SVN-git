SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_DPSCANCEL_PKG
IS
        -- +===================================================================+
        -- |                  Office Depot - Project Simplify                  |
        -- |                       WIPRO Technologies                          |
        -- +===================================================================+
        -- | Name  :  XX_OM_DPSCANCEL_PKG                                      |
        -- | Rice ID : I1151  DPS cancel order                                 |
        -- | Description:  DPS sales orders    can be cancelled in 2 ways      |
        -- |                    1. When called from JMill                      |
        -- |                    2. Scheduled concurrent Request                |
        -- |Change Record:                                                     |
        -- |===============                                                    |
        -- |Version   Date        Author           Remarks                     |
        -- |=======   ==========  =============    ============================|
        -- |DRAFT 1.0   23-MAR-2007  Srividhya        Initial draft version    |
        -- |                         Nagarajan                                 |
        -- |                                                                   |
        -- |                                                                   |
        -- +===================================================================+

	--  +===========================================================================================+
	--  |                        Process flow of DPS Cancel Order                                   |
	--  +===========================================================================================+
	--  |     If called from Jmill                                                                  |
	--  |     |                                                                                     |
	--  |     |---1)Call cancel_by_jmill_proc                                                       |
        --  |         |                                                                                 |
	--  |         |   Parameters : Order number, Parent Line id (table type)                        |                                                      |
	--  |         |-- Calls Prevalidate_proc procedure for prevalidation                            |
        --  |         |-- Calls Process_Order procedure for line status updation                        |
	--  |         |-- Raise Business Event  to cancel the order line                                |
	--  |         |-- Business event is subscribed to procedure dpscancel_from_jmill                |
	--  |         |-- dpscancel_from_jmill cancels the bundles and calls  BUS_EVENT_BPEL_PROC       |
        --  |         |-- BUS_EVENT_BPEL_PROC Raises a Business Event to Transmit the message to        |	       
	--  |              Nowdocs Queue Management thru BPEL process                                   |
	--  |                                                                                           |
	--  |     If Called from Schedule conc .Program                                                 |
	--  |     |                                                                                     |
	--  |     |--1)Call dpscancel_proc                                                              |
	--  |        |   Parameters : Header id, Parent Line id , Number of days                        |                                                         |
	--  |        |-- Fetch all the DPS bundles that need to be cancelled                            |
	--  |        |-- Update the Status of the order line by calling Process_Order                   |
	--  |        |-- Cancel the DPS bundles by calling Cancel_bundle                                |
	--  |        |-- Call BUS_EVENT_BPEL_PROC                                                       |
	--  |        |-- Raise a Business Event to Transmit the message to Nowdocs Queue Management     |	       
	--  |             thru BPEL process                                                             |
	--  |                                                                                           |
	--- +===========================================================================================+
PROCEDURE PROCESSORDER (
                        p_process_type          IN              VARCHAR2 DEFAULT 'API'
                       ,x_header_rec            IN OUT NOCOPY   oe_order_pub.header_rec_type
                       ,x_header_adj_tbl        IN OUT NOCOPY   oe_order_pub.header_adj_tbl_type
                       ,x_order_lines_tbl       IN OUT NOCOPY   oe_order_pub.line_tbl_type
                       ,x_line_adj_tbl          IN OUT NOCOPY   oe_order_pub.line_adj_tbl_type
                       ,p_request_tbl           IN              oe_order_pub.request_tbl_type
                       ,x_return_status         OUT             VARCHAR2
                       ,x_return_message        OUT             VARCHAR2
                       )
IS
           
        -- +===================================================================+
        -- | Name  : PROCESSORDER                                              |
        -- | Description      : This program process the order and cancels     |
        -- |                    the order/line using the API                   |
        -- |                    oe_order_pub.process_order                     |
        -- |                                                                   |
        -- | Parameters :      p_process_type                                  |
        -- |                   x_header_rec                                    |
        -- |                   x_header_adj_tbl                                |
        -- |                   x_order_lines_tbl                               |
        -- |                   x_line_adj_tbl                                  |
        -- |                   p_request_tbl                                   |
        -- |                   x_return_status                                 |
        -- |                   x_return_message                                |
        -- +===================================================================+
-- Local Variables.
   lr_header                   oe_order_pub.header_rec_type;
   lr_header_val               oe_order_pub.header_val_rec_type;
   lt_header_adj               oe_order_pub.header_adj_tbl_type;
   lt_header_adj_val           oe_order_pub.header_adj_val_tbl_type;
   lt_header_price_att         oe_order_pub.header_price_att_tbl_type;
   lt_header_adj_att           oe_order_pub.header_adj_att_tbl_type;
   lt_header_adj_assoc         oe_order_pub.header_adj_assoc_tbl_type;
   lt_header_scredit           oe_order_pub.header_scredit_tbl_type;
   lt_header_scredit_val       oe_order_pub.header_scredit_val_tbl_type;
   lt_line                     oe_order_pub.line_tbl_type;
   lt_line_val                 oe_order_pub.line_val_tbl_type;
   lt_line_adj                 oe_order_pub.line_adj_tbl_type;
   lt_line_adj_val             oe_order_pub.line_adj_val_tbl_type;
   lt_line_price_att           oe_order_pub.line_price_att_tbl_type;
   lt_line_adj_att             oe_order_pub.line_adj_att_tbl_type;
   lt_line_adj_assoc           oe_order_pub.line_adj_assoc_tbl_type;
   lt_line_scredit             oe_order_pub.line_scredit_tbl_type;
   lt_line_scredit_val         oe_order_pub.line_scredit_val_tbl_type;
   lt_lot_serial               oe_order_pub.lot_serial_tbl_type;
   lt_lot_serial_val           oe_order_pub.lot_serial_val_tbl_type;
   lt_action_request           oe_order_pub.request_tbl_type;
   lc_return_status            VARCHAR2 (10)   := FND_API.G_RET_STS_SUCCESS;
   lc_return_message           VARCHAR2 (4000);
   ln_msg_count                NUMBER;
   lc_msg_data                 VARCHAR2 (4000);
   ln_msg_index_out            NUMBER;
   L_OM_API_VERSION            NUMBER               := 1.0;
   lc_errbuff                  VARCHAR2 (1000);
   lc_retcode                  VARCHAR2 (100);
   lc_error_message            VARCHAR2 (1000);
   lc_err_message              VARCHAR2 (1000);
   ln_header_id                oe_order_headers_all.header_id%TYPE;
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
   lr_header := oe_order_pub.g_miss_header_rec;
   lr_header_val := oe_order_pub.g_miss_header_val_rec;
   lt_header_adj := oe_order_pub.g_miss_header_adj_tbl;
   lt_header_adj_val := oe_order_pub.g_miss_header_adj_val_tbl;
   lt_header_price_att := oe_order_pub.g_miss_header_price_att_tbl;
   lt_header_adj_att:= oe_order_pub.g_miss_header_adj_att_tbl;
   lt_header_adj_assoc:= oe_order_pub.g_miss_header_adj_assoc_tbl;
   lt_header_scredit := oe_order_pub.g_miss_header_scredit_tbl;
   lt_header_scredit_val:= oe_order_pub.g_miss_header_scredit_val_tbl;
   lt_line:= oe_order_pub.g_miss_line_tbl;
   lt_line_val:= oe_order_pub.g_miss_line_val_tbl;
   lt_line_adj := oe_order_pub.g_miss_line_adj_tbl;
   lt_line_adj_val:= oe_order_pub.g_miss_line_adj_val_tbl;
   lt_line_price_att := oe_order_pub.g_miss_line_price_att_tbl;
   lt_line_adj_att:= oe_order_pub.g_miss_line_adj_att_tbl;
   lt_line_adj_assoc := oe_order_pub.g_miss_line_adj_assoc_tbl;
   lt_line_scredit := oe_order_pub.g_miss_line_scredit_tbl;
   lt_line_scredit_val := oe_order_pub.g_miss_line_scredit_val_tbl;
   lt_lot_serial := oe_order_pub.g_miss_lot_serial_tbl;
   lt_lot_serial_val := oe_order_pub.g_miss_lot_serial_val_tbl;
   lt_action_request := oe_order_pub.g_miss_request_tbl;
   lr_header:= x_header_rec;
   lt_header_adj := x_header_adj_tbl ;
   lt_line:= x_order_lines_tbl;
   lt_line_adj := x_line_adj_tbl;
   lt_action_request :=  p_request_tbl;

   oe_debug_pub.initialize;
   oe_debug_pub.debug_on;
   oe_debug_pub.setdebuglevel (10);
     
   -- API for cancelling the sales order/line
   

      OE_ORDER_PUB.PROCESS_ORDER( 
                                   p_api_version_number          => L_OM_API_VERSION
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
                                  ,x_line_tbl                    => lt_line
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
                
     IF nvl(lc_return_status,'E') <> FND_API.G_RET_STS_SUCCESS THEN

        FOR i IN 1 .. ln_msg_count
        LOOP
             OE_MSG_PUB.GET (
	                     p_msg_index           => i
                            ,p_encoded            => FND_API.G_FALSE
                            ,p_data               => lc_msg_data
                            ,p_msg_index_out      => ln_msg_index_out
                            );
             lc_return_message := lc_return_message || ' ' || lc_msg_data;
   
        END LOOP;
	     x_return_status := FND_API.G_RET_STS_ERROR;
             x_return_message := lc_return_message;
             gc_err_code      := 'XX_OM_0001_PROCESS_ORDER_ERROR';
	     FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0001_PROCESS_ORDER_ERROR');
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
   ROLLBACK;
   x_return_status := FND_API.G_RET_STS_ERROR;
   x_return_message := lc_return_message;

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
   -- Calling the exception framework
   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_DPSCANCEL_ORDER_ERR');
   lc_error_message := FND_MESSAGE.GET;
   gc_err_code      := 'XX_OM_0002_DPSCANCEL_ORDER_ERR';
   gc_err_desc      := SUBSTR(lc_error_message|| SQLERRM,1,1000);
   gc_entity_ref    := 'header id';
   gn_entity_ref_id := NVL(ln_header_id,0);
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
   x_return_status := FND_API.G_RET_STS_ERROR;
   x_return_message := SUBSTR( SQLERRM,1,1000);
 END PROCESSORDER;
--------------------------------------------------------------------------------------------------------------------------
PROCEDURE CANCEL_LINE (
	               p_line_id          IN       oe_order_lines_all.line_id%TYPE
                      ,p_header_id        IN       oe_order_headers_all.header_id%TYPE
                      ,p_cancel_reason    IN       VARCHAR2
                      ,x_return_status    OUT      VARCHAR2
                      ,x_return_message   OUT      VARCHAR2
		      )
IS
        -- +======================================================================+
        -- | Name  : CANCEL_LINE                                                  |
        -- | Description      : This program cancels the line when header ID      |
        -- |                    and line ID are passed                            |
        -- |                                                                      |
        -- | Parameters :        p_line_id                                        |
        -- | p_header_id                                                          |
        -- | p_cancel_reason                                                      |
        -- | x_return_status                                                      |
        -- | x_return_message                                                     |
        -- +======================================================================+
   lt_action_request     oe_order_pub.request_tbl_type    := oe_order_pub.g_miss_request_tbl;
   lr_header             oe_order_pub.header_rec_type     := oe_order_pub.g_miss_header_rec;
   lt_header_adj         oe_order_pub.header_adj_tbl_type := oe_order_pub.g_miss_header_adj_tbl;
   lt_order_lines        oe_order_pub.line_tbl_type       := oe_order_pub.g_miss_line_tbl;
   lt_line_adj           oe_order_pub.line_adj_tbl_type   := oe_order_pub.g_miss_line_adj_tbl;
   lc_return_message     VARCHAR2 (4000);
   lc_return_status      VARCHAR2 (10)                    := FND_API.G_RET_STS_SUCCESS;
   lc_errbuff            VARCHAR2 (1000);
   lc_retcode            VARCHAR2 (100);
   lc_error_message      VARCHAR2 (1000);    
   EX_PREVALIDATE_ERROR  EXCEPTION;
BEGIN

   lt_order_lines (1)                  := oe_order_pub.g_miss_line_rec;
   lt_order_lines (1).ordered_quantity := 0;
   lt_order_lines (1).line_id          := p_line_id;
   lt_order_lines (1).header_id        := p_header_id;
   lt_order_lines (1).change_reason    := p_cancel_reason;
   lt_order_lines (1).cancelled_flag   := 'Y';
   lt_order_lines (1).operation        := OE_GLOBALS.G_OPR_UPDATE;
            
   -- call the processorder to cancel the DPS order lines

   PROCESSORDER (
	         p_process_type          => 'API'
                ,x_header_rec            => lr_header
                ,x_header_adj_tbl        => lt_header_adj
                ,x_order_lines_tbl       => lt_order_lines
                ,x_line_adj_tbl          => lt_line_adj
                ,p_request_tbl           => lt_action_request
                ,x_return_status         => lc_return_status
                ,x_return_message        => lc_return_message
                );

   x_return_status := lc_return_status;
   x_return_message := lc_return_message;
             
EXCEPTION
WHEN OTHERS   THEN
   FND_MESSAGE.SET_NAME ('XXOM','XX_OM_0003_DPSCANCEL_LINE_ERR');
   lc_error_message := FND_MESSAGE.GET;
   gc_err_code      := 'XX_OM_0003_DPSCANCEL_LINE_ERR';
   gc_err_desc      := SUBSTR( lc_error_message||SQLERRM,1,1000);
   gc_entity_ref    := 'line_id';
   gn_entity_ref_id := NVL(p_line_id,0);
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
   x_return_status := FND_API.G_RET_STS_ERROR;
   x_return_message :=  SUBSTR( SQLERRM,1,1000);
END CANCEL_LINE;
--------------------------------------------------------------------------------------------------------------------------
PROCEDURE CANCEL_BUNDLE (
                         p_header_id        IN       oe_order_headers_all.header_id%TYPE
                        ,p_parent_line_id   IN       xx_om_line_attributes_all.ext_top_model_line_id%TYPE
                        ,x_return_status    OUT      VARCHAR2
                        ,x_return_message   OUT      VARCHAR2
                         )
IS

	-- +===================================================================++
	-- | Name  : CANCEL_BUNDLE                                              |
	-- | Description      : This program cancels the bundle when            |
	-- |      parent Line id is passed                                      |
	-- |                                                                    |
	-- | Parameters :        p_header_id                                    |
	-- |                     p_parent_line_id                               |
	-- |                     x_return_status                                |
	-- |                     x_return_message                               |
	-- +====================================================================+

   -- Fetch child lines of the bundle
   CURSOR lcu_parent_lines_detail(p_parent_line_id xx_om_line_attributes_all.ext_top_model_line_id%TYPE, p_header_id oe_order_headers_all.header_id%TYPE )
   IS
   SELECT OOLA.line_id
         ,OOLA.header_id
    FROM  oe_order_lines_all OOLA 
         ,oe_order_headers_all OOHA     
         ,xx_om_line_attributes_all XXOL
    WHERE XXOL.line_id = OOLA.line_id
      AND OOHA.header_id    = OOLA.header_id
      AND OOHA.header_id    = p_header_id    
      AND XXOL.ext_top_model_line_id    = p_parent_line_id
      AND OOLA.flow_status_code <> 'CANCELLED' ;

   -- Fetch the delivery ID for the sales order line
   CURSOR lcu_delivery_id ( p_order_line_id NUMBER)
   IS
   SELECT WDA.delivery_id
         ,WDD.released_status
   FROM   wsh_delivery_details WDD
         ,wsh_delivery_assignments WDA
   WHERE  WDA.delivery_detail_id = WDD.delivery_detail_id
   AND    WDD.source_line_id = p_order_line_id;

   lc_ship_msg    VARCHAR2(4000);
   lc_return_message     VARCHAR2(4000);
   lc_error_message      VARCHAR2(4000);
   lc_return_status      VARCHAR2(10) := FND_API.G_RET_STS_SUCCESS ; 
   ln_msg_count   NUMBER;
   lc_msg_data    VARCHAR2 (1000);
   ln_trip_id     wsh_trips.trip_id%TYPE;
   lc_trip_name   wsh_trips.name%TYPE;
   lc_errbuff     VARCHAR2 (1000);
   lc_retcode     VARCHAR2 (100);
   lc_delivery_exists VARCHAR2(1);
   EX_CANCEL_ERROR EXCEPTION;


BEGIN
   x_return_status := FND_API.G_RET_STS_SUCCESS ;
   FOR parent_lines_detail_rec_type IN lcu_parent_lines_detail ( p_parent_line_id,p_header_id ) --1
   LOOP
      lc_delivery_exists := 'N' ;
      FOR delivery_id_rec_type IN lcu_delivery_id ( parent_lines_detail_rec_type.line_id ) --2
      LOOP
         lc_delivery_exists := 'Y' ;
	 -- line has been  pick released, need to be backordered before cancel.
         IF delivery_id_rec_type.released_status = 'Y' THEN    --3
	    -- API for backordering the sales order.
	    WSH_DELIVERIES_PUB.DELIVERY_ACTION ( 
	                                         p_api_version_number      => 1.0
                                                ,p_init_msg_list    => FND_API.G_TRUE
                                                ,x_return_status    => lc_return_status
                                                ,x_msg_count => ln_msg_count
                                                ,x_msg_data  => lc_msg_data
                                                ,p_action_code      => 'CONFIRM'
                                                ,p_delivery_id      => delivery_id_rec_type.delivery_id
                                                ,p_sc_action_flag   => 'B'
                                                ,p_sc_close_trip_flag      => 'Y'
                                                ,x_trip_id   => ln_trip_id
                                                ,x_trip_name => lc_trip_name
                                                );
						
	    IF lc_return_status <> 'S' THEN
	       FOR i IN 1 .. FND_MSG_PUB.COUNT_MSG
               LOOP
                  lc_ship_msg := FND_MSG_PUB.GET ( 
		                                   p_msg_index      => i
                                                  ,p_encoded => 'F'
                                                  );
     
               END LOOP;
               x_return_status := FND_API.G_RET_STS_ERROR;
               x_return_message := lc_ship_msg ;
	       RAISE EX_CANCEL_ERROR;
            ELSE
	       lc_return_status := NULL;  
               CANCEL_LINE ( 
	                     p_line_id      => parent_lines_detail_rec_type.line_id
                            ,p_header_id    => parent_lines_detail_rec_type.header_id
                            ,p_cancel_reason=> 'SYSTEM'
                            ,x_return_status=> lc_return_status
                            ,x_return_message      => lc_return_message
                            );			  

               IF lc_return_status <> 'S' THEN --6a
		  x_return_status := FND_API.G_RET_STS_ERROR;
                  x_return_message := lc_return_message;
		  RAISE EX_CANCEL_ERROR;
               END IF;
	       x_return_status := FND_API.G_RET_STS_SUCCESS ; 
            END IF;
	    
         -- Not been pick released or backordered, hence can be directly cancelled.
	 ELSIF   delivery_id_rec_type.released_status IN ( 'R','B') THEN  
	     lc_return_status := NULL; 
	     
             CANCEL_LINE ( 
	                   p_line_id        => parent_lines_detail_rec_type.line_id
                          ,p_header_id      => parent_lines_detail_rec_type.header_id
                          ,p_cancel_reason  => 'SYSTEM'
                          ,x_return_status  => lc_return_status
                          ,x_return_message => lc_return_message
                          );
             IF lc_return_status <> 'S' THEN --6a
		x_return_status := FND_API.G_RET_STS_ERROR;
                x_return_message := lc_return_message;
		RAISE EX_CANCEL_ERROR;
             END IF;

	     x_return_status := FND_API.G_RET_STS_SUCCESS ;
         --Line Already cancelled.
         ELSIF   delivery_id_rec_type.released_status = 'D' THEN
	     x_return_status := FND_API.G_RET_STS_SUCCESS ;
         ELSE
	    x_return_status := FND_API.G_RET_STS_ERROR;
            FND_MESSAGE.SET_NAME ('XXOM','XX_OM_0004_INVALID_PICK_STATE');
            x_return_message := FND_MESSAGE.GET;
            RAISE EX_CANCEL_ERROR;
	 END IF;  
      END LOOP;   --2
      IF lc_delivery_exists ='N' THEN 
          CANCEL_LINE ( 
	                p_line_id        => parent_lines_detail_rec_type.line_id
                       ,p_header_id      => parent_lines_detail_rec_type.header_id
                       ,p_cancel_reason  => 'SYSTEM'
                       ,x_return_status  => lc_return_status
                       ,x_return_message => lc_return_message
                       );
          IF lc_return_status <> 'S' THEN --6a
	     x_return_status := FND_API.G_RET_STS_ERROR;
             x_return_message := lc_return_message;
	     RAISE EX_CANCEL_ERROR;
          END IF;
      END IF;	     
   END LOOP;      --1  
   
EXCEPTION
WHEN EX_CANCEL_ERROR THEN
    ROLLBACK;
    x_return_status := FND_API.G_RET_STS_ERROR;  
WHEN OTHERS   THEN
    ROLLBACK;
   FND_MESSAGE.SET_NAME ('XXOM','XX_OM_0003_DPSCANCEL_LINE_ERR');
   lc_error_message := FND_MESSAGE.GET;
   gc_err_code      := 'XX_OM_0003_DPSCANCEL_LINE_ERR';
   gc_err_desc      := SUBSTR( lc_error_message||SQLERRM ,1,1000);
   gc_entity_ref    := 'header_id';
   gn_entity_ref_id := NVL(p_header_id,0);
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

END CANCEL_BUNDLE ;
--------------------------------------------------------------------------------------------------------------------------
PROCEDURE CANCEL_ORDER (
                        p_header_id IN oe_order_headers_all.header_id%TYPE
                       ,p_cancel_reason    IN       VARCHAR2
                       ,x_return_status    OUT      VARCHAR2
                       ,x_return_message   OUT      VARCHAR2
                        )
IS
        -- +===================================================================+
        -- | Name  : CANCEL_ORDER                                               |
        -- | Description      : This program cancels the order when header ID   |
        -- |      is passed                                                     |
	-- |                                                                    |
        -- | Parameters :        p_line_id                                      |
        -- |                     p_cancel_reason                                |
        -- |                     x_return_status                                |
        -- |                     x_return_message                               |
        -- +====================================================================+
lr_header            oe_order_pub.header_rec_type := oe_order_pub.g_miss_header_rec;
lt_header_adj        oe_order_pub.header_adj_tbl_type;
lt_order_lines       oe_order_pub.line_tbl_type;
lt_line_adj          oe_order_pub.line_adj_tbl_type;
lt_action_request    oe_order_pub.request_tbl_type;
lc_return_status     VARCHAR2 (10);
lc_return_message    VARCHAR2 (4000);
lc_errbuff           VARCHAR2 (1000);
lc_retcode           VARCHAR2 (100);
lc_error_message     VARCHAR2 (1000);
EX_PREVALIDATE_ERROR EXCEPTION;

BEGIN
   lr_header.header_id         := p_header_id;
   lr_header.cancelled_flag    := 'Y';
   lr_header.operation         := OE_GLOBALS.G_OPR_UPDATE;
   lr_header.change_reason     := p_cancel_reason;

   -- call the processorder to cancel the DPS orders
   PROCESSORDER (
                  p_process_type          => 'API'
                 ,x_header_rec            => lr_header
                 ,x_header_adj_tbl        => lt_header_adj
                 ,x_order_lines_tbl       => lt_order_lines
                 ,x_line_adj_tbl          => lt_line_adj
                 ,p_request_tbl           => lt_action_request
                 ,x_return_status         => lc_return_status
                 ,x_return_message        => lc_return_message
                 );

   x_return_status := lc_return_status;
   x_return_message := lc_return_message;
   
EXCEPTION
WHEN OTHERS  THEN
   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_DPSCANCEL_ORDER_ERR');
   lc_error_message := FND_MESSAGE.GET;
   gc_err_code      := 'XX_OM_0002_DPSCANCEL_ORDER_ERR';
   gc_err_desc      := SUBSTR( lc_error_message||SQLERRM,1,1000);
   gc_entity_ref    := 'header_id';
   gn_entity_ref_id := NVL(p_header_id,0);
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
   x_return_status := FND_API.G_RET_STS_ERROR;
   x_return_message := SUBSTR( SQLERRM,1,1000);
  
END CANCEL_ORDER;
--------------------------------------------------------------------------------------------------------------------------
 PROCEDURE UPDATE_STATUS (	                   
                          p_order_line_id     IN       oe_order_lines_all.line_id%TYPE
                         ,p_update_status     IN       xx_om_line_attributes_all.trans_line_status%TYPE
                         ,x_return_status     OUT      VARCHAR2
                         )
IS

        -- +===================================================================================+
        -- | Name  :UPDATE_STATUS                                                              |
        -- | Description      : This program updates the sales order line DPS status           |
        -- |                    to cancelled.                                                  |
        -- | Parameters :                                                                      |
        -- |             p_order_line_id                                                       |
        -- |             x_return_status                                                       |
        -- +===================================================================================+


   lc_sqlcode               VARCHAR2 (100);
   lc_sqlerrm               VARCHAR2 (1000);
   lc_errbuff               VARCHAR2 (1000); 
   lc_retcode               VARCHAR2 (100);
   lc_error_message         VARCHAR2 (1000);
   lc_return_status         VARCHAR2 (10);

-- variables for calling custom API
    lt_line_rec                 XX_OM_LINE_ATTRIBUTES_T ;
    lc_licence_address          xx_om_line_attributes_all.licence_address%TYPE;
    lc_vendor_config_id         xx_om_line_attributes_all.vendor_config_id%TYPE;
    lc_fulfillment_type         xx_om_line_attributes_all.fulfillment_type%TYPE;
    lc_line_type                xx_om_line_attributes_all.line_type%TYPE;
    lc_line_modifier            xx_om_line_attributes_all.line_modifier%TYPE;
    lc_release_num              xx_om_line_attributes_all.release_num%TYPE;
    lc_cost_center_dept         xx_om_line_attributes_all.cost_center_dept%TYPE;
    lc_desktop_del_addr         xx_om_line_attributes_all.desktop_del_addr%TYPE;
    lc_vendor_site_id           xx_om_line_attributes_all.vendor_site_id%TYPE;
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
    lc_resourcing_flag          xx_om_line_attributes_all.resourcing_flag%TYPE;
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
        ,vendor_site_id   
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
        ,lc_vendor_site_id   
    FROM   xx_om_line_attributes_all
    WHERE  line_id = p_order_line_id ;
    
   lt_line_rec := XX_OM_LINE_ATTRIBUTES_T ( p_order_line_id                    
                                            ,lc_licence_address             
                                            ,lc_vendor_config_id            
                                            ,lc_fulfillment_type            
                                            ,lc_line_type                   
                                            ,lc_line_modifier               
                                            ,lc_release_num                 
                                            ,lc_cost_center_dept            
                                            ,lc_desktop_del_addr        
                                            ,lc_vendor_site_id                       
                                            ,lc_pos_trx_num                 
                                            ,lc_one_time_deal               
                                            ,p_update_status           
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
                                            ,lc_resourcing_flag            
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

    XX_OM_LINE_ATTRIBUTES_PKG.UPDATE_ROW(
                                           p_line_rec        => lt_line_rec
                                          ,x_return_status  => lc_return_status
                                          ,x_errbuf         => lc_errbuff
                                         );
 
    x_return_status := lc_return_status ;       

                                                                                                                            
EXCEPTION
WHEN NO_DATA_FOUND THEN
   x_return_status := 'E';
   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0005_UPDATE_DPS_LINE');
   lc_error_message := FND_MESSAGE.GET;
   lc_sqlcode       := SQLCODE;
   lc_sqlerrm       := SUBSTR( SQLERRM,1,1000);
   gc_err_code      := 'XX_OM_0005_UPDATE_DPS_LINE';
   gc_err_desc      :=  SUBSTR(lc_error_message||'Error while updating DPS line status  '||lc_sqlerrm,1,1000);
   gc_entity_ref    := 'line_id';
   gn_entity_ref_id :=NVL(p_order_line_id,0);
   gc_err_report_type    :=
   XXOM.XX_OM_REPORT_EXCEPTION_T (
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
   x_return_status := 'E';
   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0005_UPDATE_DPS_LINE');
   lc_error_message := FND_MESSAGE.GET;
   lc_sqlcode       := SQLCODE;
   lc_sqlerrm       := SUBSTR( SQLERRM,1,1000);
   gc_err_code      := 'XX_OM_0005_UPDATE_DPS_LINE';
   gc_err_desc      :=  SUBSTR(lc_error_message||'Error while updating DPS line status  '||lc_sqlerrm,1,1000);
   gc_entity_ref    := 'line_id';
   gn_entity_ref_id :=NVL(p_order_line_id,0);
   gc_err_report_type    :=
   XXOM.XX_OM_REPORT_EXCEPTION_T (
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
END UPDATE_STATUS;


--------------------------------------------------------------------------------------------------------------------------
PROCEDURE PREVALIDATE_PROC (
	                    p_order_header_id   IN       oe_order_headers_all.header_id%TYPE
                           ,p_order_line_id     IN       oe_order_lines_all.line_id%TYPE
                           ,x_return_status     OUT      VARCHAR2
                            )
IS
        -- +===================================================================+
        -- | Name  : PREVALIDATE_PROC                                          |
        -- | Description      : This program validates the sales order         |
        -- |                                                                   |
        -- | Parameters :        p_order_header_id                             |
        -- | p_order_line_id                                                   |
        -- | x_return_status                                                   |
        -- +===================================================================+


    -- Fetch the Valid holds for the sales order line Other than  'DPS Hold'
   CURSOR lcu_hold_name ( p_order_line_id oe_order_lines_all.line_id%TYPE )
   IS
   SELECT OHD.NAME
   FROM   oe_order_holds_all OOH
         ,oe_hold_definitions OHD
         ,oe_hold_sources_all OHSA
         ,oe_order_lines_all OOLA
   WHERE  OOLA.line_id = OOH.line_id
   AND    OOLA.header_id = OOH.header_id
   AND    OOH.hold_source_id = OHSA.hold_source_id
   AND    OHSA.hold_id = OHD.hold_id
   AND    OOH.released_flag ='N'
   AND    OOLA.line_id   = p_order_line_id
   AND    name <> gc_hold_name ;


   -- Checking for organization type to be STORE     
   CURSOR lcu_org_id (p_order_header_id oe_order_headers_all.header_id%TYPE )
   IS
   SELECT 'Y'
   FROM   hr_all_organization_units HAOU
         ,hr_lookups HL
         ,oe_order_headers_all OOHA
   WHERE  HAOU.TYPE = hl.lookup_code
   AND    HAOU.organization_id = OOHA.ship_from_org_id
   AND    OOHA.header_id  = p_order_header_id
   AND    HL.lookup_type  = gc_org_typ
   AND    HL.lookup_code  = gc_org_value
   AND    HL.enabled_flag='Y'
   AND    SYSDATE BETWEEN TO_DATE(TO_CHAR(NVL(start_date_active,SYSDATE),'DDMMYYYY')||'000000','DDMMYYYYHH24MISS')
	  AND TO_DATE(TO_CHAR(NVL(end_date_active,SYSDATE),'DDMMYYYY') ||'235959','DDMMYYYYHH24MISS') ;
    	            
    -- Checking for shipment method to be PICKUP
   CURSOR lcu_ship_mtd (p_order_header_id oe_order_headers_all.header_id%TYPE ) 
   IS
   SELECT 'Y'
   FROM   wsh_carrier_services_v WCS
	 ,oe_order_headers_all OEOH
	 ,fnd_lookup_values FLV
   WHERE OEOH.header_id    =  p_order_header_id  
   AND   OEOH.shipping_method_code = WCS.ship_method_code
   AND   WCS.ship_method_meaning   =  FLV.meaning
   AND   FLV.lookup_type  = gc_ship_lookup_typ
   AND   FLV.lookup_code  = gc_ship_method
   AND   FLV.language     = USERENV('LANG') 
   AND   FLV.enabled_flag = 'Y'
   AND   SYSDATE BETWEEN TO_DATE(TO_CHAR(NVL(FLV.start_date_active,SYSDATE),'DDMMYYYY')||'000000','DDMMYYYYHH24MISS')
	 AND TO_DATE(TO_CHAR(NVL(FLV.end_date_active,SYSDATE),'DDMMYYYY') ||'235959','DDMMYYYYHH24MISS')     	            
   AND   OEOH.flow_status_code <> 'CANCELLED';

   --  Checking for order lines to DPS LINE TYPE
   CURSOR lcu_line_tpe ( p_order_line_id oe_order_lines_all.line_id%TYPE )
   IS
   SELECT 'Y'
   FROM   oe_order_lines_all OOLA
         ,xx_om_line_attributes_all XXOL
	 ,fnd_lookup_values FLV
   WHERE  XXOL.line_id = OOLA.line_id
   AND    XXOL.line_type= FLV.meaning
   AND    OOLA.line_id = p_order_line_id
   AND    FLV.lookup_type  = gc_line_lookup_typ
   AND    FLV.lookup_code  = gc_dps_code
   AND    FLV.language     = USERENV('LANG') 
   AND    FLV.enabled_flag='Y'
   AND    SYSDATE BETWEEN TO_DATE(TO_CHAR(NVL(FLV.start_date_active,SYSDATE),'DDMMYYYY')||'000000','DDMMYYYYHH24MISS')
          AND TO_DATE(TO_CHAR(NVL(FLV.end_date_active,SYSDATE),'DDMMYYYY') ||'235959','DDMMYYYYHH24MISS');

   -- Fetching the flow status
   CURSOR lcu_line_status (  p_order_line_id oe_order_lines_all.line_id%TYPE)
   IS
   SELECT  OOLA.flow_status_code 
	  ,XXOL.trans_line_status
   FROM   oe_order_lines_all OOLA
         ,xx_om_line_attributes_all XXOL
   WHERE  XXOL.line_id = OOLA.line_id
   AND   OOLA.line_id = p_order_line_id ;

   -- Checking the payment type to be CASH or CHECK
   CURSOR lcu_payment_type (p_order_header_id oe_order_headers_all.header_id%TYPE )
   IS
   SELECT   'Y'
   FROM   oe_order_headers_all OEOH
         ,fnd_lookup_values FLV
   WHERE  OEOH.header_id = p_order_header_id
   AND    OEOH.payment_type_code = FLV.meaning  
   AND    FLV.lookup_type  = gc_pymt_lookup_typ
   AND    FLV.lookup_code  IN ( gc_pymt_code1,gc_pymt_code2)
   AND    FLV.language     = USERENV('LANG') 
   AND    FLV.enabled_flag='Y'
   AND    SYSDATE BETWEEN TO_DATE(TO_CHAR(NVL(FLV.start_date_active,SYSDATE),'DDMMYYYY')||'000000','DDMMYYYYHH24MISS')
	  AND TO_DATE(TO_CHAR(NVL(FLV.end_date_active,SYSDATE),'DDMMYYYY') ||'235959','DDMMYYYYHH24MISS');

   lc_org_exist            VARCHAR2 (1);
   lc_ship_exist           VARCHAR2 (1);
   lc_line_type_exist      VARCHAR2 (1);          
   lc_flow_status          VARCHAR2 (100);
   lc_payment_type_exist   VARCHAR2 (1);  
   lc_hold_exists          VARCHAR2 (1) := 'N';
   lc_errbuff              VARCHAR2 (1000);
   lc_retcode              VARCHAR2 (1000);
   ln_line_id		   oe_order_lines_all.line_id%TYPE;
   lc_error_message        VARCHAR2 (1000);
   lc_dps_status           VARCHAR2 (20); 
   EX_PREVALIDATE_ERROR    EXCEPTION;
   
   BEGIN

      OPEN lcu_line_status ( p_order_line_id );
      FETCH lcu_line_status
      INTO  lc_flow_status,lc_dps_status;
      CLOSE lcu_line_status;

      -- If flow status is in 'BOOKED' or 'AWAITING_SHIPPING' then return 'S' else return 'E'

     -- If the cancellation is at order level check if the line status is in   'BOOKED', 'AWAITING_SHIPPING','CANCELLED'
      IF gc_cancel_level ='Y' THEN	      
	 IF ( NVL(lc_flow_status,'XXXX') IN ('ENTERED','BOOKED', 'AWAITING_SHIPPING','CANCELLED')) THEN 
	    x_return_status := FND_API.G_RET_STS_SUCCESS;
         ELSE
	    x_return_status := 'E';
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0006_INVALID_FLST');
	    gc_err_code := 'XX_OM_0006_INVALID_FLST';
	    gc_err_desc :=FND_MESSAGE.GET;
	    gc_entity_ref := 'Line id';
	    gn_entity_ref_id :=NVL(p_order_line_id ,0);
	    RAISE EX_PREVALIDATE_ERROR;
	 END IF;
      ELSE
          -- If the cancellation is at line level check if the line status is in   'BOOKED', 'AWAITING_SHIPPING'
	  IF ( NVL(lc_flow_status,'XXXX') IN ('ENTERED','BOOKED', 'AWAITING_SHIPPING')  AND NVL(lc_dps_status,'XXX') <> gc_dps_cancel_status) THEN--4
	     x_return_status := FND_API.G_RET_STS_SUCCESS;
	  ELSE
	     x_return_status := 'E';
	     FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0006_INVALID_FLST');
	     gc_err_code := 'XX_OM_0006_INVALID_FLST';
	     gc_err_desc :=FND_MESSAGE.GET;
	     gc_entity_ref := 'Line id';
	     gn_entity_ref_id :=NVL(p_order_line_id ,0);
	     RAISE EX_PREVALIDATE_ERROR;
	  END IF;
      END IF;     
 

      --IF any Other hold other than  'DPS hold' exists

      FOR hold_name_rec_type IN lcu_hold_name ( p_order_line_id)
      LOOP
	 lc_hold_exists := 'Y';          
      END LOOP;
    
      
      IF (lc_hold_exists  = 'N') THEN
	 x_return_status := FND_API.G_RET_STS_SUCCESS;
      ELSE
         x_return_status := 'E';
	 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0007_INVALID_HOLD');
	 gc_err_code := 'XX_OM_0007_INVALID_HOLD';
	 gc_err_desc :=FND_MESSAGE.GET;
	 gc_entity_ref := 'Line id';
	 gn_entity_ref_id := NVL(p_order_line_id ,0);
	 RAISE ex_prevalidate_error;
      END IF;

      -- Checking for organization type to be STORE     
      OPEN lcu_org_id(p_order_header_id);
      FETCH lcu_org_id
      INTO lc_org_exist;
      CLOSE lcu_org_id;

      IF(lc_org_exist = 'Y') THEN
	 x_return_status := FND_API.G_RET_STS_SUCCESS;
      ELSE
	 x_return_status := 'E';
	 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0008_INVALID_ORG_TYPE');
	 gc_err_code := 'XX_OM_0008_INVALID_ORG_TYPE';
	 gc_err_desc :=FND_MESSAGE.GET;
	 gc_entity_ref := 'Line id';
	 gn_entity_ref_id :=NVL(p_order_line_id ,0);
	 RAISE EX_PREVALIDATE_ERROR;
      END IF; --Need to be uncommented
            
      OPEN lcu_ship_mtd (p_order_header_id );
      FETCH lcu_ship_mtd
      INTO  lc_ship_exist;
      CLOSE lcu_ship_mtd;

      -- If shipment method is PICKUP then return 'S' else return 'E'
      IF (lc_ship_exist = 'Y') THEN
	 x_return_status := FND_API.G_RET_STS_SUCCESS;
      ELSE
	 x_return_status := 'E';
	 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0009_INVALID_SHIP_MTD');
	 gc_err_code := 'XX_OM_0009_INVALID_SHIP_MTD';
	 gc_err_desc :=FND_MESSAGE.GET;
	 gc_entity_ref := 'Line id';
	 gn_entity_ref_id :=NVL(p_order_line_id ,0);
	 RAISE EX_PREVALIDATE_ERROR;
      END IF;  
  
      OPEN lcu_line_tpe ( p_order_line_id);
      FETCH lcu_line_tpe
      INTO  lc_line_type_exist;
      CLOSE lcu_line_tpe;
             
      -- If line type is 'DPS' then return 'S' else return 'E'
      IF (lc_line_type_exist = 'Y')  THEN 
	 x_return_status := FND_API.G_RET_STS_SUCCESS;
      ELSE
	 x_return_status := 'E';
	 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0010_INVALID_LINE_TYPE');
	 gc_err_code := 'XX_OM_0010_INVALID_LINE_TYPE';
	 gc_err_desc :=FND_MESSAGE.GET;
	 gc_entity_ref := 'Line id';
	 gn_entity_ref_id :=NVL(p_order_line_id ,0);
	 RAISE EX_PREVALIDATE_ERROR;
      END IF;

	     
      OPEN lcu_payment_type (p_order_header_id );
      FETCH lcu_payment_type
      INTO  lc_payment_type_exist;
      CLOSE lcu_payment_type;
            
      -- If payment type is either CASH or CHECK then return 'S' else return 'E'

      IF (lc_payment_type_exist = 'Y') THEN
	 x_return_status := FND_API.G_RET_STS_SUCCESS;
      ELSE
	 x_return_status := 'E';
	 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0011_INVALID_PAYTP');
	 gc_err_code := 'XX_OM_0011_INVALID_PAYTP';
	 gc_err_desc :=FND_MESSAGE.GET;
	 gc_entity_ref := 'Line id';
	 gn_entity_ref_id :=NVL(p_order_line_id ,0);
	 RAISE EX_PREVALIDATE_ERROR;
      END IF;


EXCEPTION
WHEN EX_PREVALIDATE_ERROR THEN
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
   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0012_DPS_PREVAL_ERROR');
   lc_error_message := FND_MESSAGE.GET;
   gc_err_code := 'XX_OM_0012_DPS_PREVAL_ERROR';
   gc_err_desc := SUBSTR(lc_error_message||SQLERRM,1,1000);
   gc_entity_ref := 'Line id';
   gn_entity_ref_id := NVL(p_order_line_id ,0);
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
  
END PREVALIDATE_PROC;
-------------------------------------------------------------------------------------------------------------------

PROCEDURE CANCEL_BY_JMILL_PROC ( 
                                 p_order_number      IN oe_order_headers_all.order_number%TYPE
                                ,p_order_detail_tbl  IN orderdetail_tbl_type
                                ,p_user_id           IN FND_USER.user_id%TYPE
                                ,p_responsibility_id IN FND_RESPONSIBILITY_TL.responsibility_id%TYPE
                                ,x_return_status     OUT VARCHAR2
				)
IS

        -- +===========================================================================+
        -- | Name  : CANCEL_BY_JMILL_PROC                                              |
        -- | Description      : This is the main program called from JMILL system      |
	-- | It shall do prevalidation and returns status                              |
	-- | 			 success 'S' or error 'E' accordingly .                |
	-- | 			 It then raises  the Business Event which shall cancel |
	-- | 			 the DPS Order or DPS bundles accordingly              |
        -- |                                                                           |
        -- |                                                                           |
        -- | Parameters :        p_order_header_id                                     |
        -- | p_order_detail_tbl
        -- | p_user_id 
       -- |  p_responsibility_id
        -- | x_return_status  		                                               |
        -- +===========================================================================+

   CURSOR lcu_header_detail( p_order_number oe_order_headers_all.order_number%TYPE )
   IS
   SELECT OOHA.header_id
         ,OOLA.line_id
   FROM oe_order_headers_all OOHA
       ,oe_order_lines_all OOLA
   WHERE OOLA.header_id =OOHA.Header_id
   AND  OOHA.order_number = p_order_number;

   CURSOR lcu_order_num( p_order_number oe_order_headers_all.order_number%TYPE )
   IS
   SELECT OOHA.header_id          
   FROM oe_order_headers_all OOHA            
   WHERE OOHA.order_number = p_order_number
   AND   OOHA.flow_status_code <> 'CANCELLED'						  
   AND    EXISTS  ( 
                    SELECT 'Y' 
 		    FROM oe_order_lines_all OOLA
		        ,xx_om_line_attributes_all XXOL
                    WHERE XXOL.line_id = OOLA.line_id 
                    AND   OOHA .HEADER_ID =OOLA.HEADER_ID 
		    AND   NVL(XXOL.trans_line_status,'XXX') <> gc_dps_cancel_status
		   );  
   
   CURSOR lcu_parent_lines_count( p_parent_line_id xx_om_line_attributes_all.ext_top_model_line_id%TYPE, p_order_number oe_order_headers_all.order_number%TYPE )
   IS
   SELECT COUNT(OOLA.line_id)
   FROM oe_order_lines_all OOLA 
       ,oe_order_headers_all OOHA     
       ,xx_om_line_attributes_all XXOL
   WHERE XXOL.line_id = OOLA.line_id
   AND   OOHA.header_id               = OOLA.header_id
   AND   OOHA.ORDER_NUMBER            = p_order_number    
   AND   xxol.ext_top_model_line_id               = p_parent_line_id;
    
   CURSOR lcu_parent_lines_detail(p_parent_line_id xx_om_line_attributes_all.ext_top_model_line_id%TYPE, p_order_number oe_order_headers_all.order_number%TYPE)
   IS
   SELECT OOLA.line_id
         ,OOLA.header_id
   FROM oe_order_lines_all OOLA 
       ,oe_order_headers_all OOHA     
       ,xx_om_line_attributes_all XXOL
   WHERE XXOL.line_id = OOLA.line_id
   AND   OOHA.header_id    = OOLA.header_id
   AND   OOHA.order_number = p_order_number    
   AND   xxol.ext_top_model_line_id    = p_parent_line_id;
	  
  
   CURSOR lcu_bundles (p_order_number oe_order_headers_all.order_number%TYPE ) 
   IS
   SELECT COUNT(OOLA.line_id) CNT
         ,NVL(ext_top_model_line_id,'0') PARENT_LINE_ID
	 ,oola.header_id HEADER_ID
   FROM oe_order_lines_all OOLA 
       ,oe_order_headers_all OOHA     
       ,xx_om_line_attributes_all XXOL
   WHERE OOLA.line_id = XXOL.line_id 
   AND   OOHA.header_id    = OOLA.header_id
   AND   OOHA.order_number = p_order_number
   AND   OOLA.flow_status_code <> 'CANCELLED'
   GROUP BY ext_top_model_line_id 
           ,oola.header_id;   

   ln_line_id               oe_order_lines_all.line_id%TYPE;   
   ln_header_id             oe_order_headers_all.header_id%TYPE;
   lc_return_status         VARCHAR2 (1);
   lc_request_status        NUMBER; 
   EX_CALL_BY_JMILL_ERROR   EXCEPTION;
   lc_errbuff               VARCHAR2 (1000);
   lc_retcode               VARCHAR2 (100);
   lc_error_message         VARCHAR2 (1000);
   lt_event_parameter_list  wf_parameter_list_t;
   lt_param                 wf_parameter_t;
   ln_event_key             NUMBER;
   lc_event_key             VARCHAR2(100);
   ln_parameter_index       NUMBER := 0;
   ln_count                 NUMBER;  
   lc_up_return_status      VARCHAR2(1);
   lc_prev_return_status    VARCHAR2(1);
   lt_tab_order_lines       oe_order_pub.line_tbl_type        := OE_ORDER_PUB.G_MISS_LINE_TBL;    
   lt_order_detail_tbl      orderdetail_tbl_type;
   lt_lines                 line_tbl_type ;
   ln_cnt                   NUMBER := 1;
   lc_name                  VARCHAR2(100); 
   ln_order_count           NUMBER;
   lc_cancel_event_name     VARCHAR2(100);
   ln_responsibility_id     FND_RESPONSIBILITY_TL.responsibility_id%TYPE;		
   ln_application_id        FND_RESPONSIBILITY_TL.application_id%TYPE;
   ln_user_id               FND_USER.user_id%TYPE;
             

   BEGIN
     

      BEGIN
   
     -- Query to fetch Responsibility id , Responsibility application id 
   	
	  SELECT   responsibility_id
                  ,application_id
	  INTO     ln_responsibility_id
		  ,ln_application_id
	  FROM     fnd_responsibility_tl 
	  WHERE   responsibility_id = p_responsibility_id 
	  AND     language = USERENV('LANG') ;

	 EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0014_DPS_INVALID_RESP');
	    gc_err_desc      := FND_MESSAGE.GET;
	    gc_err_code      := 'XX_OM_0014_DPS_INVALID_RESP';
	    gc_err_desc      := gc_err_desc ||SUBSTR( SQLERRM,1,1000);
	    gc_entity_ref    := 'order number';
	    gn_entity_ref_id := NVL(p_order_number,0);
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
      RAISE EX_CALL_BY_JMILL_ERROR;	
      END;

       -- Query to fetch User id ,User name is stored in Lookup
      BEGIN    	
	 SELECT user_id
         INTO   ln_user_id
         FROM   fnd_user 
         WHERE  user_id = p_user_id  ;

         EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0015_DPS_INVALID_USER');
	    gc_err_desc      := FND_MESSAGE.GET;
	    gc_err_code      := 'XX_OM_0015_DPS_INVALID_USER';
	    gc_err_desc      := gc_err_desc ||SUBSTR( SQLERRM,1,1000);
            gn_entity_ref_id := NVL(p_order_number,0);
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
       RAISE EX_CALL_BY_JMILL_ERROR;
      END;
   
      --get the name of business events to be called from fnd_lookups.
      BEGIN
	 SELECT  FLV.meaning
	 INTO    lc_cancel_event_name
	 FROM    fnd_lookup_values FLV
	 WHERE FLV.lookup_type  = gc_dps_com_lookup_typ
	 AND   FLV.lookup_code  = gc_cancel_event_name
	 AND   FLV.language     = USERENV('LANG') 
	 AND   FLV.enabled_flag='Y'
	 AND   SYSDATE BETWEEN TO_DATE(TO_CHAR(NVL(FLV.start_date_active,SYSDATE),'DDMMYYYY')||'000000','DDMMYYYYHH24MISS')
	       AND TO_DATE(TO_CHAR(NVL(FLV.end_date_active,SYSDATE),'DDMMYYYY') ||'235959','DDMMYYYYHH24MISS');
	 EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	    FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0016_DPS_INVALID_BE');
	    gc_err_desc      := FND_MESSAGE.GET;
	    gc_err_code      := 'XX_OM_0016_DPS_INVALID_BE';
	    gc_err_desc      := gc_err_desc ||SUBSTR( SQLERRM,1,1000);
	    gc_entity_ref    := 'order number';
	    gn_entity_ref_id := NVL(p_order_number,0);
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
         RAISE EX_CALL_BY_JMILL_ERROR;	    
      END; 

  
       -- Check if the supplied order number is valid.
      OPEN lcu_order_num ( NVL( p_order_number,0 ) );
      FETCH lcu_order_num INTO ln_order_count;
      CLOSE lcu_order_num ;
      
      	 
      IF NVL(ln_order_count,0) > 0  THEN--1A
	 -- check if it is Order level cancellation or Bundle level cancellation
	 IF ( p_order_detail_tbl.COUNT = 0 ) THEN
	    gc_cancel_level := 'Y';
	    -- store header_id on table type variable to be passed to business event				  
	    FOR order_num_rec_type in lcu_order_num (p_order_number)
	    LOOP					   				  
	       lt_lines(1).line_id := order_num_rec_type.header_id ;
	    END LOOP;

	    -- check to see if all the lines inside the Order are DPS bundles
	    FOR bundles_rec_type IN lcu_bundles (p_order_number)
	    LOOP
	       -- store parent line id in table type variable which needs to be passed to business event
	       ln_cnt := ln_cnt + 1 ; 
	       lt_lines(ln_cnt).line_id := bundles_rec_type.parent_line_id; 
	       IF bundles_rec_type.parent_line_id = '0' THEN      
		  x_return_status   := 'E';
		  gc_err_code      := 'XX_OM_0017_DPS_INVALID_PARENT';
		  FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0017_DPS_INVALID_PARENT');
		  gc_err_desc :=FND_MESSAGE.GET; 
		  gc_entity_ref    := 'order number';
		  gn_entity_ref_id :=NVL(p_order_number,0);
		  RAISE EX_CALL_BY_JMILL_ERROR;					          
	       END IF;
	    END LOOP;

	    -- Check if all the bundle lines in the Order are eligible to be cancelled
	    --  If prevalidate is successful , update the DFF Line status as 'Cancelled' and 
	    --  raise the Business event to cancel the Lines in EBS.

	    FOR header_detail_rec_type IN lcu_header_detail(p_order_number)
	    LOOP					  					           
	       ln_header_id := header_detail_rec_type.header_id;
	       ln_line_id   := header_detail_rec_type.line_id;             
	       PREVALIDATE_PROC (
	                         ln_header_id
	                        ,ln_line_id
	                        ,lc_prev_return_status
	                         );
   
	       -- check if prevalidation is successful
	       IF lc_prev_return_status = FND_API.G_RET_STS_SUCCESS THEN  
		  UPDATE_STATUS ( 
		                  ln_line_id
                       ,gc_dps_cancel_status 
		                 ,lc_up_return_status
				 ) ;				 			      
		  IF lc_up_return_status <> FND_API.G_RET_STS_SUCCESS THEN
		     x_return_status   := 'E';
		     gc_err_code      := 'XX_OM_0018_DPS_STAT_FAIL';
		     FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0018_DPS_STAT_FAIL');
		     gc_err_desc :=FND_MESSAGE.GET; 
		     gc_entity_ref := 'Line Id';
		     gn_entity_ref_id :=NVL(ln_line_id,0);
		     RAISE EX_CALL_BY_JMILL_ERROR;
		  ELSE 
		     lc_return_status := FND_API.G_RET_STS_SUCCESS;       
		  END IF;
		  
	       ELSE
		  x_return_status  := 'E';
		  gc_err_code      := 'XX_OM_0012_DPS_PREVAL_ERROR';
		  FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0012_DPS_PREVAL_ERROR');
		  gc_err_desc :=FND_MESSAGE.GET; 
		  gc_entity_ref    := 'Line Id';
		  gn_entity_ref_id := NVL(ln_line_id,0);
		  RAISE EX_CALL_BY_JMILL_ERROR;           
	       END IF;
	    END LOOP;

	    -- Raise the business event to cancel the Line in EBS
	    -- Event Key generation
	    SELECT xxom.xx_om_dps_cancel_s.nextval 
	    INTO   ln_event_key 
	    FROM   DUAL;
				 
	    lc_event_key:='key_'||ln_event_key;
	    lt_event_parameter_list := wf_parameter_list_t ();
	    lt_param := wf_parameter_t (NULL, NULL);
	    lt_event_parameter_list.EXTEND;
	    lt_param.setname('Header');

	    -- Value 'O' is passed to business event to identify as Order level cancellation.

	    lt_param.setvalue('O-'||TO_CHAR(lt_lines.COUNT));
	    ln_parameter_index := 1;
	    lt_event_parameter_list (ln_parameter_index) := lt_param;

            lt_param := wf_parameter_t (NULL, NULL);
	    lt_event_parameter_list.EXTEND;
	    lt_param.setname('user_id');
	    lt_param.setvalue(ln_user_id);
	    ln_parameter_index := 2;
	    lt_event_parameter_list (ln_parameter_index) := lt_param;

            lt_param := wf_parameter_t (NULL, NULL);
	    lt_event_parameter_list.EXTEND;
	    lt_param.setname('resp_id');
	    lt_param.setvalue(ln_responsibility_id);
	    ln_parameter_index := 3;
	    lt_event_parameter_list (ln_parameter_index) := lt_param;

            lt_param := wf_parameter_t (NULL, NULL);
	    lt_event_parameter_list.EXTEND;
	    lt_param.setname('resp_appl_id');
	    lt_param.setvalue(ln_application_id);
	    ln_parameter_index := 4;
	    lt_event_parameter_list (ln_parameter_index) := lt_param;

	    FOR i in lt_lines.FIRST..lt_lines.LAST
	    LOOP
	       lc_name :='line_id'||TO_CHAR(i+1);
	       lt_param := wf_parameter_t (NULL, NULL);
	       lt_event_parameter_list.EXTEND;
	       lt_param.setname(lc_name);
	       lt_param.setvalue(lt_lines(i).line_id);
	       ln_parameter_index := i+4;
	       lt_event_parameter_list (ln_parameter_index) := lt_param;
	    END LOOP;

	    WF_EVENT.RAISE (
	                    p_event_name      => lc_cancel_event_name
                           ,p_event_key       => lc_event_key
			   ,p_parameters      => lt_event_parameter_list						
         		    );
	 ELSE -- bundle level cancellation
			          
	    -- store header_id on table type variable to be passed to business event 
	    FOR order_num_rec_type in lcu_order_num (p_order_number)
	    LOOP					   				  
	       lt_lines(1).line_id := order_num_rec_type.header_id ;
	    END LOOP;
	 
	    -- Bundle Line Level cancellation
	    FOR  i in p_order_detail_tbl.FIRST..p_order_detail_tbl.LAST 
	    LOOP
	       ln_cnt := ln_cnt + 1 ; 
	       lt_lines(ln_cnt).line_id := p_order_detail_tbl(i).parent_line_id; 

	       OPEN lcu_parent_lines_count(p_order_detail_tbl(i).parent_line_id,p_order_number);
	       FETCH lcu_parent_lines_count INTO ln_count;
	       CLOSE lcu_parent_lines_count;

	       --check if there are lines for the given parent line id
	       IF ln_count<>0 THEN

		  FOR parent_lines_detail_rec_type in lcu_parent_lines_detail(p_order_detail_tbl(i).parent_line_id,p_order_number) 
		  LOOP  
                     ln_line_id   := parent_lines_detail_rec_type.line_id; 
                     ln_header_id := parent_lines_detail_rec_type.header_id;
		     PREVALIDATE_PROC (
		                       ln_header_id
                                      ,ln_line_id
                                      ,lc_prev_return_status
                                       );
   
		     -- check if prevalidation is successful
		     IF lc_prev_return_status = FND_API.G_RET_STS_SUCCESS THEN    
                        
                        UPDATE_STATUS ( 
		                        ln_line_id
                             ,gc_dps_cancel_status
		                       ,lc_up_return_status
				      ) ;
  
			IF lc_up_return_status <> FND_API.G_RET_STS_SUCCESS THEN
			   x_return_status   := 'E';
			   gc_err_code      := 'XX_OM_0018_DPS_STAT_FAIL';
			   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0018_DPS_STAT_FAIL');
			   gc_err_desc :=FND_MESSAGE.GET;
                           gc_entity_ref := 'Line Id';
                           gn_entity_ref_id :=NVL(ln_line_id,0);
                           RAISE EX_CALL_BY_JMILL_ERROR;
			ELSE 
			   lc_return_status := FND_API.G_RET_STS_SUCCESS;       
			END IF; 

		     ELSE
			x_return_status  := 'E';
			gc_err_code      := 'XX_OM_0012_DPS_PREVAL_ERROR';
			FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0012_DPS_PREVAL_ERROR');
			gc_err_desc :=FND_MESSAGE.GET;
			gc_entity_ref    := 'Line Id';
			gn_entity_ref_id := NVL(ln_line_id,0);
			RAISE EX_CALL_BY_JMILL_ERROR;           
		     END IF;

		  END LOOP;
	       ELSE		 
		  x_return_status   := 'E';
		  gc_err_code      := 'XX_OM_0017_DPS_INVALID_PARENT';
		  FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0017_DPS_INVALID_PARENT');
		  gc_err_desc :=FND_MESSAGE.GET;
		  gc_entity_ref := 'order number';
		  gn_entity_ref_id :=NVL(p_order_number,0);
		  RAISE EX_CALL_BY_JMILL_ERROR; 
	       END IF;
					
	    END LOOP;
	    -- Raise the business event to cancel the Line in EBS
 
	    -- Event Key generation
	    SELECT xxom.xx_om_dps_cancel_s.nextval 
	    INTO   ln_event_key 
	    FROM   DUAL;
				 
	    lc_event_key:='key_'||ln_event_key;
	    lt_event_parameter_list := wf_parameter_list_t ();
	    lt_param := wf_parameter_t (NULL, NULL);
	    lt_event_parameter_list.EXTEND;
	    lt_param.setname('Header');

	    -- Value 'L' is passed to business event to identify as Bundle level cancellation.
	    lt_param.setvalue('L-'||TO_CHAR(lt_lines.COUNT));
            ln_parameter_index := 1;
            lt_event_parameter_list (ln_parameter_index) := lt_param;
       
            lt_param := wf_parameter_t (NULL, NULL);
	    lt_event_parameter_list.EXTEND;
	    lt_param.setname('user_id');
	    lt_param.setvalue(ln_user_id);
	    ln_parameter_index := 2;
	    lt_event_parameter_list (ln_parameter_index) := lt_param;

            lt_param := wf_parameter_t (NULL, NULL);
	    lt_event_parameter_list.EXTEND;
	    lt_param.setname('resp_id');
	    lt_param.setvalue(ln_responsibility_id);
	    ln_parameter_index := 3;
	    lt_event_parameter_list (ln_parameter_index) := lt_param;

            lt_param := wf_parameter_t (NULL, NULL);
	    lt_event_parameter_list.EXTEND;
	    lt_param.setname('resp_appl_id');
	    lt_param.setvalue(ln_application_id);
	    ln_parameter_index := 4;
	    lt_event_parameter_list (ln_parameter_index) := lt_param;

	    FOR i in lt_lines.FIRST..lt_lines.LAST
	    LOOP
	       lc_name :='line_id'||TO_CHAR(i+1);
	       lt_param := wf_parameter_t (NULL, NULL);
	       lt_event_parameter_list.EXTEND;
	       lt_param.setname(lc_name);
	       lt_param.setvalue(lt_lines(i).line_id);
	       ln_parameter_index := i+4;
	       lt_event_parameter_list (ln_parameter_index) := lt_param;
	    END LOOP;

	    WF_EVENT.RAISE (
	                    p_event_name      => lc_cancel_event_name
                           ,p_event_key       => lc_event_key
			   ,p_parameters      => lt_event_parameter_list						
         		    );
				     
	 END IF; --Order/bundle level cancellation

      ELSE --1A
	 gc_err_code      := 'XX_OM_DPS_0019_INVALID_ORDER';
         FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_0019_INVALID_ORDER');
         gc_err_desc :=FND_MESSAGE.GET;
         gc_entity_ref    := 'order number';
         gn_entity_ref_id := nvl(p_order_number,0);
         RAISE EX_CALL_BY_JMILL_ERROR;
      END IF;--1A 
  
      COMMIT; 
      x_return_status   := 'S';
      EXCEPTION
      -- Calling the exception framework
      WHEN EX_CALL_BY_JMILL_ERROR THEN	
         ROLLBACK;
	 x_return_status   := 'E';      
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
         
      WHEN OTHERS  THEN
         ROLLBACK;
	 x_return_status   := 'E';
	 -- Calling the exception framework
	 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0020_BUS_EVENT_ERROR');
	 lc_error_message := FND_MESSAGE.GET;
         gc_err_code      := 'XX_OM_0020_BUS_EVENT_ERROR';
         gc_err_desc      := SUBSTR(lc_error_message||SQLERRM ,1,1000);
         gc_entity_ref    := 'line_id';
         gn_entity_ref_id := NVL(ln_line_id,0);
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
 
   END CANCEL_BY_JMILL_PROC;
-------------------------------------------------------------------------------------------------------------------        

PROCEDURE BUS_EVENT_BPEL_PROC  ( p_event_key IN VARCHAR2 )      
IS
             -- +===================================================================+
             -- | Name  : BUS_EVENT_BPEL_PROC                                       |
             -- | Description   : 1. This procedure is invoked from DPSCANCEL_PROC  |
             -- |                  for raising a business event which               |
             -- |                 triggers the BPEL  process                        |
	     -- |                                                                   |
             -- | Parameters :  p_event_key                                         |
             -- |                                                                   |
             -- +===================================================================+
   lt_event_parameter_list   wf_parameter_list_t;
   lc_error_message          VARCHAR2(1000);
   lc_errbuff   VARCHAR2(1000);
   lc_retcode   VARCHAR2(100);
   lc_event_key VARCHAR2(100);
   lc_bpel_event_name        VARCHAR2(100);

   BEGIN
      lc_event_key :=  p_event_key;  
      lt_event_parameter_list := wf_parameter_list_t (); 
	
      -- Get business event name from the Lookup
      
      SELECT  FLV.meaning
      INTO    lc_bpel_event_name
      FROM    fnd_lookup_values FLV
      WHERE   FLV.lookup_type  = gc_dps_com_lookup_typ
      AND   FLV.lookup_code  = gc_bpel_event_name
      AND   FLV.language     = USERENV('LANG') 
      AND   FLV.enabled_flag='Y'
      AND  SYSDATE BETWEEN TO_DATE(TO_CHAR(NVL(FLV.start_date_active,SYSDATE),'DDMMYYYY')||'000000','DDMMYYYYHH24MISS')
           AND TO_DATE(TO_CHAR(NVL(FLV.end_date_active,SYSDATE),'DDMMYYYY') ||'235959','DDMMYYYYHH24MISS');

      WF_EVENT.RAISE (
                      p_event_name      => lc_bpel_event_name
                     ,p_event_key       => lc_event_key
                     ,p_parameters      => lt_event_parameter_list
                      );
   
   EXCEPTION     
   WHEN OTHERS  THEN
     -- Calling the exception framework
     FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0020_BUS_EVENT_ERROR');
     lc_error_message := FND_MESSAGE.GET;
     gc_err_code := 'XX_OM_0020_BUS_EVENT_ERROR';
     gc_err_desc := SUBSTR( lc_error_message||SQLERRM,1,1000);
     gc_entity_ref := 'order_header_id';
     gn_entity_ref_id := 0;
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
  
   END BUS_EVENT_BPEL_PROC;
-----------------------------------------------------------------------------------------------------------------------

PROCEDURE DPSCANCEL_PROC (
                          x_errbuff           OUT      VARCHAR2
                         ,x_retcode           OUT      NUMBER
                         ,p_header_id         IN       oe_order_headers_all.header_id%TYPE
                         ,p_parent_line_id    IN       NUMBER
	                 ,p_days              IN       NUMBER
                          )
IS
     -- +==========================================================================+
     -- | Name  : DPSCANCEL_PROC                                                   |
     -- | Description :                                                            |
     -- |This procedure is called from scheduled concurrent program                |		
     -- |  1. When the header_id and line_id are passed                            |
     -- |     call the PREVALIDATE_PROC for                                        |
     -- |     validation and then cancel the Order/bundles                         |
     -- |  2. When the header_id and line_id are not passed                        |
     -- |		        call the PREVALIDATE_PROC for                      |
     -- |     validation and then cancel the Order/bundles                         |
     -- |  3. The orders in 'Booked' state and                                     |
     -- |     and 'Picked' state are fetched for cancellation. If an               |
     -- |     order is in Booked state then call CANCEL_LINE/                      |
     -- |     CANCEL_ORDER.If the order is in picked state call the                |
     -- |     API wsh_deliveries_pub.delivery_action for back order                |
     -- |     and ship confirmation and then cancel the order/line.                |
     -- |                                                                          |
     -- |                                                                          |
     -- | Parameters :      x_errbuff                                              |
     -- |     x_retcode                                                            |
     -- |     p_header_id                                                          |
     -- |     p_parent_line_id                                                     |
     -- |     p_days   (Number of Order expired days)                              |
     -- +==========================================================================+

   -- Main cursor for conc. progam .Fetch all the bundles to be cancelled.
   CURSOR lcu_cancel_dps_lines ( p_header_id oe_order_headers_all.header_id%TYPE ,p_parent_line_id NUMBER,p_days NUMBER ) 
   IS
   SELECT   OOHA.header_id
            ,XXOL.ext_top_model_line_id 
	    ,COUNT (*) cnt  
   FROM    hr_all_organization_units HAOU
          ,hr_lookups HL -- ORG TYPE
	  ,fnd_lookup_values FLV3  -- payment type
	  ,fnd_lookup_values FLV2  -- LINE TYPE
	  ,fnd_lookup_values FLV1  -- ship method
	  ,wsh_carrier_services_v WCS
          ,xx_om_line_attributes_all XXOL
          ,oe_order_lines_all OOLA
          ,oe_order_headers_all OOHA
   WHERE   OOHA.header_id = OOLA.header_id
   AND     OOLA.line_id = XXOL.line_id 
   AND     XXOL.line_type = FLV2.meaning
   AND     XXOL.ext_top_model_line_id = NVL( TO_CHAR( p_parent_line_id ),xxol.ext_top_model_line_id )
   AND     OOHA.ordered_date <=(sysdate-p_days)
   AND     OOHA.shipping_method_code = wcs.ship_method_code
   AND     WCS.ship_method_meaning = FLV1.meaning
   AND     OOLA.flow_status_code NOT IN ( 'CANCELLED','CLOSED')
   AND     OOHA.payment_type_code = FLV3.meaning
   AND     OOHA.header_id = NVL( p_header_id,OOHA.header_id )
   AND     HAOU.TYPE = HL.lookup_code
   AND     HAOU.organization_id = OOHA.ship_from_org_id
   AND     HL.lookup_type  = gc_org_typ
   AND     HL.lookup_code  = gc_org_value
   AND     HL.enabled_flag ='Y'
   AND     SYSDATE BETWEEN TO_DATE(TO_CHAR(NVL(HL.start_date_active,SYSDATE),'DDMMYYYY')||'000000','DDMMYYYYHH24MISS')
           AND TO_DATE(TO_CHAR(NVL(HL.end_date_active,SYSDATE),'DDMMYYYY') ||'235959','DDMMYYYYHH24MISS')    	  
   AND     FLV3.lookup_type = gc_pymt_lookup_typ
   AND     FLV3.lookup_code  IN ( gc_pymt_code1,gc_pymt_code2)
   AND     FLV3.language = USERENV('LANG') 
   AND     FLV3.enabled_flag='Y'
   AND     SYSDATE BETWEEN TO_DATE(TO_CHAR(NVL(FLV3.start_date_active,SYSDATE),'DDMMYYYY')||'000000','DDMMYYYYHH24MISS')
           AND TO_DATE(TO_CHAR(NVL(FLV3.end_date_active,SYSDATE),'DDMMYYYY') ||'235959','DDMMYYYYHH24MISS')  
   AND     FLV2.lookup_type = gc_line_lookup_typ
   AND     FLV2.lookup_code  = gc_dps_code
   AND     FLV2.language = USERENV('LANG') 
   AND     FLV2.enabled_flag='Y'
   AND     SYSDATE BETWEEN TO_DATE(TO_CHAR(NVL(FLV2.start_date_active,SYSDATE),'DDMMYYYY')||'000000','DDMMYYYYHH24MISS')
           AND TO_DATE(TO_CHAR(NVL(FLV2.end_date_active,SYSDATE),'DDMMYYYY') ||'235959','DDMMYYYYHH24MISS')  
   AND     FLV1.lookup_type = gc_ship_lookup_typ
   AND     FLV1.lookup_code  = gc_ship_method
   AND     FLV1.language = USERENV('LANG') 
   AND     FLV1.enabled_flag='Y'
   AND     SYSDATE BETWEEN TO_DATE(TO_CHAR(NVL(FLV1.start_date_active,SYSDATE),'DDMMYYYY')||'000000','DDMMYYYYHH24MISS')
           AND TO_DATE(TO_CHAR(NVL(FLV1.end_date_active,SYSDATE),'DDMMYYYY') ||'235959','DDMMYYYYHH24MISS')  
   GROUP BY     OOHA.header_id
               ,XXOL.ext_top_model_line_id ;

   -- Fetch all the count of lines in the given bundle.
   CURSOR lcu_cancel_dps_bundle  (p_header_id oe_order_headers_all.header_id%TYPE, p_parent_line_id xx_om_line_attributes_all.ext_top_model_line_id%TYPE )
   IS
   SELECT count(*) bundle_count
   FROM   oe_order_lines_all OOLA  
         ,xx_om_line_attributes_all XXOL
   WHERE  OOLA.line_id = XXOL.line_id 
   AND    XXOL.ext_top_model_line_id    = p_parent_line_id
   AND    OOLA.header_id    = p_header_id ;

   -- Fetch all the  lines in the  bundle for the given parent line id .

   CURSOR lcu_cancel_dps_bundle_lines  (p_header_id oe_order_headers_all.header_id%TYPE, p_parent_line_id xx_om_line_attributes_all.ext_top_model_line_id%TYPE )
   IS
   SELECT oola.line_id
   FROM   oe_order_lines_all OOLA  
         ,xx_om_line_attributes_all XXOL
   WHERE  OOLA.line_id = XXOL.line_id 
   AND    XXOL.ext_top_model_line_id    = p_parent_line_id
   AND    oola.header_id    = p_header_id ;      
    

   -- Fetch the hold name for the sales order line
   CURSOR lcu_hold_name (l_order_line_id oe_order_lines_all.line_id%TYPE )
   IS
   SELECT OHD.NAME
   FROM   oe_order_holds_all OOH
         ,oe_hold_definitions OHD
         ,oe_hold_sources_all OHSA
         ,oe_order_lines_all OOLA
   WHERE  OOLA.line_id = OOH.line_id
   AND    OOLA.header_id = OOH.header_id
   AND    OOH.hold_source_id = OHSA.hold_source_id
   AND    OHSA.hold_id = OHD.hold_id
   AND    OOH.released_flag ='N'
   AND    OOLA.line_id   = l_order_line_id
   AND    name <> gc_hold_name ;

 
   ln_header_id                 oe_order_headers_all.header_id%TYPE;
   lc_errbuff                   VARCHAR2 (1000); 
   lc_retcode                   VARCHAR2 (100); 
   EX_BUNDLE_ERROR              EXCEPTION;
   lt_order_lines               oe_order_pub.line_tbl_type;
   lc_return_status             VARCHAR2 (1000)    := FND_API.G_RET_STS_SUCCESS;
   lc_up_return_status          VARCHAR2 (1000)    := FND_API.G_RET_STS_SUCCESS;
   lc_return_message            VARCHAR2 (1000);
   lc_hold_exists               VARCHAR2 (1) ;
   lc_error_message             VARCHAR2 (1000);  
   lc_bpel_call_flag            VARCHAR2(1) := 'E';   
   ln_event_key                 NUMBER;
   lc_cancel_event_name         VARCHAR2(100);


BEGIN
 
      -- First Event key is generated which shall be used to raising business event
      SELECT xxom.xx_om_dps_cancel_s.NEXTVAL 
      INTO   ln_event_key 
      FROM   dual;
 
      -- If the header_id and line_id are not passed then fetch all the valid header_id and line_id for cancellation
      FOR cancel_dps_lines_rec_type IN lcu_cancel_dps_lines ( p_header_id,p_parent_line_id,p_days ) -- MAIN
      LOOP
	 BEGIN
		   
	    ln_header_id := cancel_dps_lines_rec_type.header_id ;

	    -- check if the number of lines in the bundle is equal to number of bundle lines satisfying cancel criteria.
	    FOR cancel_dps_bundle_rec_type IN lcu_cancel_dps_bundle ( ln_header_id,cancel_dps_lines_rec_type.ext_top_model_line_id )
	    LOOP	
		          
	       IF  cancel_dps_lines_rec_type.cnt <> cancel_dps_bundle_rec_type.bundle_count THEN	
		  gc_err_code := 'XX_OM_0021_DPS_BUNDLE_FAIL';
		  FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0021_DPS_BUNDLE_FAIL'); 
                  gc_err_desc := FND_MESSAGE.GET;
                  gc_entity_ref := 'parent_line_id';
                  gn_entity_ref_id := NVL(TO_NUMBER(cancel_dps_lines_rec_type.ext_top_model_line_id),0);
                  RAISE EX_BUNDLE_ERROR ;			       
	       END IF;
	    END LOOP;

	    lc_hold_exists := 'N';
	    FOR can_dps_bund_lines_rec_type IN lcu_cancel_dps_bundle_lines ( ln_header_id,cancel_dps_lines_rec_type.ext_top_model_line_id )
	    LOOP			 
	       -- get the hold name for the lines in the bundle			 
               -- If hold name is 'Hold For Production' , Then cancel the bundle else ignore it.

	       FOR hold_name_rec_type IN lcu_hold_name (can_dps_bund_lines_rec_type.line_id)
	       LOOP
		  lc_hold_exists := 'Y';          
	       END LOOP;

	    END LOOP;

		      
	    -- If hold exists 
	    IF NVL(lc_hold_exists,'N') <> 'Y' THEN
	    
	       -- Update the DPS Status of all the lines in the bundle to 'Cancelled'.		          
	       FOR can_dps_bund_lines_rec_type IN lcu_cancel_dps_bundle_lines ( ln_header_id,cancel_dps_lines_rec_type.ext_top_model_line_id )
	       LOOP
		  UPDATE_STATUS ( 
		                 can_dps_bund_lines_rec_type.line_id
                      ,gc_dps_cancel_status
		                ,lc_up_return_status
		                ) ;		
                                        
		  IF lc_up_return_status <> FND_API.G_RET_STS_SUCCESS THEN--5
		     gc_err_code      := 'XX_OM_0018_DPS_STAT_FAIL';
		     FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0018_DPS_STAT_FAIL');
		     gc_err_desc :=FND_MESSAGE.GET;
		     gc_entity_ref    := 'Parent Line id ';
		     gn_entity_ref_id :=NVL(cancel_dps_lines_rec_type.ext_top_model_line_id ,0);
		     RAISE EX_BUNDLE_ERROR ;
                  ELSE --5
                     lc_return_status := FND_API.G_RET_STS_SUCCESS;       
                  END IF;--5       			    
	       END LOOP;	
		  
               -- Cancel the bundle 
	       CANCEL_BUNDLE ( 
	                       p_header_id        => ln_header_id      
                              ,p_parent_line_id   => cancel_dps_lines_rec_type.ext_top_model_line_id
                              ,x_return_status    => lc_return_status    
                              ,x_return_message   => lc_return_message   
                              );			     
   
	       IF ( lc_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN	
                  gc_err_code := 'XX_OM_0022_CANCEL_BUNDLE_FAIL';
	          FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0022_CANCEL_BUNDLE_FAIL');
		  gc_err_desc :=FND_MESSAGE.GET; 
		  gc_err_desc := gc_err_desc||lc_return_message;
		  gc_entity_ref := 'parent_line_id';
		  gn_entity_ref_id := NVL(to_number(cancel_dps_lines_rec_type.ext_top_model_line_id),0);
		  RAISE EX_BUNDLE_ERROR ;
	       ELSE	
	        
		  INSERT 
         	  INTO  xx_om_dpsparent_stg
		  VALUES ( ln_event_key
		         , cancel_dps_lines_rec_type.ext_top_model_line_id
                         , SYSDATE
			 , SYSDATE
			 , fnd_profile.value ('USER_ID')
			 , fnd_profile.value ('USER_ID')
			  );
				
		  lc_bpel_call_flag := 'S';
		  FND_MESSAGE.SET_NAME('XXOM','XX_OM_0023_DPS_CANCEL_MSG');
		  FND_MESSAGE.SET_TOKEN('PARENT_LINE_ID',cancel_dps_lines_rec_type.ext_top_model_line_id,FALSE );
		  gc_err_desc      := FND_MESSAGE.GET ;
		  FND_FILE.PUT_LINE ( FND_FILE.LOG,gc_err_desc);		

	       END IF;

	    END IF; -- HOLD CHECK
		      
            COMMIT; 
	    EXCEPTION
	    WHEN EX_BUNDLE_ERROR THEN
	    ROLLBACK;
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

	 END; 
      END LOOP; -- MAIN

      -- Raising the business event for trigerring the BPEL process
      IF lc_bpel_call_flag ='S' THEN	 		   
	 BUS_EVENT_BPEL_PROC(ln_event_key);
      END IF;
   
EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK;
	 -- Calling the exception framework
	 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_DPSCANCEL_ORDER_ERR');
	 lc_error_message := FND_MESSAGE.GET;
	 gc_err_code      := 'XX_OM_0002_DPSCANCEL_ORDER_ERR';
	 gc_err_desc      := SUBSTR( lc_error_message||SQLERRM,1,1000) ;
	 gc_entity_ref    := 'order_header_id';
	 gn_entity_ref_id :=NVL(ln_header_id,0);
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
    
 END DPSCANCEL_PROC;
--------------------------------------------------------------------------------------------------------------------

FUNCTION DPSCANCEL_FROM_JMILL(
                              p_subscription_guid  IN             RAW
                             ,p_event              IN OUT NOCOPY  wf_event_t
                              )
RETURN VARCHAR2
IS
   -- +===================================================================+
   -- | Name  : DPSCANCEL_FROM_JMILL_FUNC                                 |
   -- | Description      : Business event raises this function.           |
   -- |      Passes the required parameters and calls                     |
   -- |      cancel_bundle and raise the business event                   |
   -- |      to pass cancel info to Nowdocs thru BPEL process             |
   -- |                                                                   |
   -- | Parameters :        p_subscription_guid                           |
   -- | p_event                                                           |
   -- +===================================================================+
		
   ln_order_header_id   NUMBER;
   ln_order_line_id     NUMBER;
   lc_call_source       VARCHAR2 (100);
   lc_errbuff           VARCHAR2 (1000);
   lc_retcode           VARCHAR2 (1000);
   lc_error_message     VARCHAR2 (1000);
   lt_order_detail_tbl  orderdetail_tbl_type;
   ln_cnt               NUMBER;    
   lc_cancel_type       VARCHAR2(100); 
   lc_hdr               VARCHAR2(100);
   lc_name              VARCHAR2(100);
   lc_line_id           VARCHAR2(100);
   lt_lines             line_tbl_type ;
   lt_lines_cancel      line_tbl_type ; 
   lc_return_message    VARCHAR2(4000);
   lc_return_status     VARCHAR2(10); 
   lc_bpel_call_flag    VARCHAR2(1);
   ln_event_key         NUMBER ;	
   ln_responsibility_id     FND_RESPONSIBILITY_TL.responsibility_id%TYPE;		
   ln_application_id        FND_RESPONSIBILITY_TL.application_id%TYPE;
   ln_user_id               FND_USER.user_id%TYPE;
   
BEGIN
      --Get the values for the parameters which are passed while invoking the business event
      lc_hdr := p_event.getvalueforparameter ('Header');
      lc_cancel_type := SUBSTR(lc_hdr,1,1) ;
      ln_cnt         := SUBSTR(lc_hdr,3) ;

      --fetching user_id, resp_id and resp_appl_id

      ln_user_id                := p_event.getvalueforparameter ('user_id');
      ln_responsibility_id      := p_event.getvalueforparameter ('resp_id');
      ln_application_id         := p_event.getvalueforparameter ('resp_appl_id');

      --initialising the environment
      FND_GLOBAL.APPS_INITIALIZE (
                                  ln_user_id
                                 ,ln_responsibility_id
                                 ,ln_application_id
		                  );  
			  
      -- FETCHING THE HEADER ID AND LINE ID VALUES INTO A TABLE TYPE VARIABLE.
      FOR  i in 1..ln_cnt
      LOOP
	 lc_name :='line_id'||TO_CHAR(i+1);
         lt_lines(i).line_id   := p_event.getvalueforparameter(lc_name);          
      END LOOP;
       
      -- First Event key is generated which shall be used to raising business event
      SELECT xxom.xx_om_dps_cancel_s.nextval 
      INTO   ln_event_key 
      FROM   DUAL;

      -- Seperating Header id and Line id
      FOR i IN lt_lines.FIRST..lt_lines.LAST
      LOOP
	 -- FIRST RECORD IS ALWAYS A HEADER ID.
         IF i=1 THEN
	    ln_order_header_id := lt_lines(1).line_id ;
	    lt_lines_cancel(i).line_id := NULL;
	   
	 ELSE
	    lt_lines_cancel(i-1).line_id := lt_lines(i).line_id ;
			     
	 END IF;
      END LOOP;
                   			     

      FOR i IN  1..lt_lines_cancel.COUNT
      LOOP					    
	 CANCEL_BUNDLE ( 
	                 p_header_id        => ln_order_header_id       
                        ,p_parent_line_id   => lt_lines_cancel(i).line_id
                        ,x_return_status    => lc_return_status    
                        ,x_return_message   => lc_return_message   
                        ); 
	 IF ( lc_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN	
	    lc_bpel_call_flag := 'E';

            -- Call the exception and log the error.
            gc_err_code := 'XX_OM_0022_CANCEL_BUNDLE_FAIL';
            FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0022_CANCEL_BUNDLE_FAIL');
            gc_err_desc :=FND_MESSAGE.GET; 
            gc_err_desc := gc_err_desc||lc_return_message; 
            gc_entity_ref := 'Parent Line id ';
            gn_entity_ref_id :=NVL(lt_lines_cancel(i).line_id,0);          
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
	 ELSE				    
	    INSERT INTO  xx_om_dpsparent_stg
            VALUES ( 
	             ln_event_key
  		   , lt_lines_cancel(i).line_id
                   , SYSDATE
		   , SYSDATE
		   , FND_GLOBAL.USER_ID
		   , FND_GLOBAL.USER_ID
		    );
	    lc_bpel_call_flag := 'S';
					
	 END IF;				   					      
      END LOOP;          							   

      -- Cancel the order if the cancel type is 'O'
      IF ( lc_cancel_type = 'O') THEN				     
	 CANCEL_ORDER ( 
	                p_header_id         => ln_order_header_id
                       ,p_cancel_reason     => 'SYSTEM'
                       ,x_return_status     => lc_return_status
                       ,x_return_message    => lc_return_message
                       );
		       
	 IF ( lc_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN					        
     	  
            FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0024_CANCEL_ORDER_FAIL');
	    gc_err_code := 'XX_OM_0024_CANCEL_ORDER_FAIL';
            gc_err_desc :=FND_MESSAGE.GET ;
            gc_err_desc := SUBSTR( gc_err_desc||lc_return_message,1,1000);
            gc_entity_ref := 'order_header_id';
            gn_entity_ref_id :=NVL(ln_order_header_id,0); 
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
         
	 END IF; 
      END IF;

      IF lc_bpel_call_flag ='S' THEN		
	 BUS_EVENT_BPEL_PROC(ln_event_key);
	 COMMIT;
      ELSE
	 ROLLBACK;
      END IF;		    

      RETURN 'SUCCESS';

EXCEPTION			  
WHEN OTHERS   THEN
       ROLLBACK;
      -- Calling the exception framework
      WF_CORE.CONTEXT(
	              'xx_om_dpscancel_pkg'
                     ,'dpscancel_from_jmill'
                     ,p_event.getEventName( )
	             ,p_subscription_guid
		      );
      WF_EVENT.SETERRORINFO(
	                    p_event
	                    ,'ERROR'
			    );

      FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_CALL_0025_JMILL_ERROR');
      lc_error_message := FND_MESSAGE.GET;
      gc_err_code      := 'XX_OM_CALL_0025_JMILL_ERROR';
      gc_err_desc      := SUBSTR( lc_error_message||SQLERRM,1,1000);
      gc_entity_ref    := 'ln_order_line_id';
      gn_entity_ref_id := NVL(ln_order_line_id,0);
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
      RETURN 'ERROR';
         

END DPSCANCEL_FROM_JMILL;

------------------------------------------------------------------------------------------------------------------------ 
PROCEDURE DELETE_PARENTID_BPEL (        
                                p_session_id       IN       NUMBER       
                               ,p_user_name        IN       VARCHAR2     
                               ,p_resp_name        IN       VARCHAR2     
                               ,x_return_status    OUT      VARCHAR2     
                               ,x_return_message   OUT      VARCHAR2     
                                )       
IS    

    -- +===================================================================+
    -- | Name  : DELETE_PARENTID_BPEL                                      |
    -- | Description      : This program delete Parent Line IDs stored     |
    -- |	            in the table XX_OM_DPSPARENT_STG.              |
    -- |                                                                   |
    -- | Parameters :      p_session_id                                    |
    -- |                   x_return_status                                 |
    -- |                   x_return_message                                |
    -- +===================================================================+

   lc_errbuff         VARCHAR2 (1000);
   lc_retcode         VARCHAR2 (100);
   lc_error_message   VARCHAR2 (1000);
   lc_init_status     VARCHAR2(40);     
   lc_init_message    VARCHAR2(1000);     
    
BEGIN          
    
   XX_OM_DPS_APPS_INIT_PKG.DPS_APPS_INIT(
                                         p_user_name
                                        ,p_resp_name
			                ,lc_init_status
					,lc_init_message
					);  
    
   DELETE 
   FROM xx_om_dpsparent_stg     
   WHERE event_key = p_session_id;       
    
COMMIT;     

EXCEPTION      
WHEN OTHERS THEN
    ROLLBACK;
	 -- Calling the exception framework             
   FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_0026_DELETE_ERROR');
   lc_error_message := FND_MESSAGE.GET;
   gc_err_code      := 'XX_OM_DPS_0026_DELETE_ERROR';
   gc_err_desc      := SUBSTR(lc_error_message||SQLERRM,1,1000);      
   gc_entity_ref := 'Session_id';        
   gn_entity_ref_id := NVL(p_session_id,0);            
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
   x_return_status := 'Failure';   
   x_return_message := gc_err_desc;       
        
END DELETE_PARENTID_BPEL;
END XX_OM_DPSCANCEL_PKG;
/
SHO ERR