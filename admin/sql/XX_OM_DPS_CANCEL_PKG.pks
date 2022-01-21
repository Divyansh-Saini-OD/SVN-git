SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_DPSCANCEL_PKG
IS
	-- +===================================================================+
	-- |                  Office Depot - Project Simplify                  |
	-- |                       WIPRO Technologies                          |
	-- +===================================================================+
	-- | Name  :  XX_OM_DPSCANCEL_PKG                                      |
	-- | Rice ID : I1151  DPS cancel order                                 |
	-- | Description:  This package cancels the DPS sales orders in 2 ways |
	-- |                    1. When called from JMill                      |
	-- |                    2. Schedule concurrent Request                 |
	-- |Change Record:                                                     |
	-- |===============                                                    |
	-- |Version   Date        Author           Remarks                     |
	-- |=======   ==========  =============    ============================|
	-- |1.0      23-MAR-2007  Srividhya        Initial draft version       |
	-- |                      Nagarajan                                    |  
	-- |                                                                   |
	-- |                                                                   |
	-- +===================================================================+
	   gc_err_code             xxom.xx_om_global_exceptions.error_code%TYPE;
	   gc_err_desc             xxom.xx_om_global_exceptions.description%TYPE;
	   gc_entity_ref           xxom.xx_om_global_exceptions.entity_ref%TYPE;
	   gn_entity_ref_id        xxom.xx_om_global_exceptions.entity_ref_id%TYPE;
	   gc_err_report_type      xx_om_report_exception_t;
	   gc_dps_code             fnd_lookup_values.lookup_code%TYPE DEFAULT 'DPS'; 
	   gc_pymt_code1           fnd_lookup_values.lookup_code%TYPE DEFAULT 'CASH';
	   gc_pymt_code2           fnd_lookup_values.lookup_code%TYPE DEFAULT 'CHECK';
	   gc_ship_method          fnd_lookup_values.lookup_code%TYPE DEFAULT 'PICKUP';
	   gc_line_lookup_typ      fnd_lookup_values.lookup_type%TYPE DEFAULT 'XX_OM_LINE_TYPES'; 
	   gc_pymt_lookup_typ      fnd_lookup_values.lookup_type%TYPE DEFAULT 'XX_OM_DPS_PAYMENT_TYPES'; 
	   gc_ship_lookup_typ      fnd_lookup_values.lookup_type%TYPE DEFAULT 'XX_OM_DPS_SHIP_METHOD';
	   gc_dps_com_lookup_typ   fnd_lookup_values.lookup_type%TYPE DEFAULT 'XX_OM_DPS_CANCEL_LOOKUP';
	   gc_org_typ              hr_lookups.lookup_type%TYPE DEFAULT 'ORG_TYPE';
	   gc_org_value            hr_lookups.lookup_code%TYPE DEFAULT 'STRG';
	   gc_hold_name            VARCHAR2(100) DEFAULT 'DPS Hold';
	   gc_dps_cancel_status    VARCHAR2(20) := 'XX_OM_CANCELLED';
	   gc_cancel_event_name    VARCHAR2(100):= 'BE_CANCEL' ;
	   gc_bpel_event_name      VARCHAR2(100) := 'BE_BPEL';
	   gc_cancel_level         VARCHAR2(10) := 'N' ;
	   gc_resp_name            VARCHAR2(100) := 'RESP_ID';
	   gc_user_name            VARCHAR2(100) := 'USER_ID' ; 
	   gc_exception_header     VARCHAR2(20) := 'OTHERS';
	   gc_exception_track      VARCHAR2(20) := 'OTC';
	   gc_exception_sol_dom    VARCHAR2(20) := 'Order Management';
	   gc_error_function       VARCHAR2(20) := 'DPS cancel-I 1151';
		
	 

	   TYPE orderdetail_rec_type IS RECORD( parent_line_id        VARCHAR2(100) );

	   TYPE orderdetail_tbl_type IS TABLE OF orderdetail_rec_type INDEX BY BINARY_INTEGER; 
	   
	   TYPE line_rec_type IS RECORD( line_id  VARCHAR2(100) );

	   TYPE line_tbl_type IS TABLE OF line_rec_type INDEX BY BINARY_INTEGER;

	-- +===================================================================+
	-- | Name  : PROCESSORDER                                              |
	-- | Description      : This program process the order and cancels     | 
	-- |			the order/line using the API                   |
	-- |                    oe_order_pub.process_order                     |
	-- |                                                                   |
	-- | Parameters :      p_process_type                                  |
	-- |                   x_header_rec                                    |
	-- |           	       x_header_adj_tbl                                |
	-- |                   x_tab_order_lines                               |
	-- |                   x_line_adj_tbl                                  |
	-- |                   p_request_tbl                                   |
	-- |                   x_return_status                                 |
	-- |                   x_return_message                                |
	-- +===================================================================+    
	  PROCEDURE PROCESSORDER (
	                           p_process_type          IN              VARCHAR2 DEFAULT 'API'
				  ,x_header_rec            IN OUT NOCOPY   oe_order_pub.header_rec_type
				  ,x_header_adj_tbl        IN OUT NOCOPY   oe_order_pub.header_adj_tbl_type
				  ,x_order_lines_tbl       IN OUT NOCOPY   oe_order_pub.line_tbl_type
				  ,x_line_adj_tbl          IN OUT NOCOPY   oe_order_pub.line_adj_tbl_type
				  ,p_request_tbl           IN              oe_order_pub.request_tbl_type
				  ,x_return_status         OUT             VARCHAR2
				  ,x_return_message        OUT             VARCHAR2
				   ) ;

	-- +======================================================================+
	-- | Name  : CANCEL_LINE                                                  |
	-- | Description      : This program cancels the line when header ID      |
	-- |                    and line ID are pased                             |
	-- |                                                                      |
	-- | Parameters :        p_line_id                                        |
	-- |                     p_header_id                                      |
	-- |                     p_cancel_reason                                  |
	-- |                     x_return_status                                  |
	-- |                     x_return_message                                 |
	-- +======================================================================+

           PROCEDURE CANCEL_LINE (
	                          p_line_id          IN       oe_order_lines_all.line_id%TYPE
                                 ,p_header_id        IN       oe_order_headers_all.header_id%TYPE
                                 ,p_cancel_reason    IN       VARCHAR2
                                 ,x_return_status    OUT      VARCHAR2
                                 ,x_return_message   OUT      VARCHAR2
                                 );
	 -- +===================================================================+
	-- | Name  : CANCEL_BUNDLE                                              |
	-- | Description      : This program cancels the bundle when            |
	-- |                    parent Line id is passed                        |
	-- | Parameters :        i_line_id                                      |
	-- |                     i_cancel_reason                                |
	-- |                     o_return_status                                |
	-- |                     o_return_message                               |
	-- +====================================================================+

           PROCEDURE CANCEL_BUNDLE (
                                    p_header_id        IN       oe_order_headers_all.header_id%TYPE
                                   ,p_parent_line_id   IN       xx_om_line_attributes_all.ext_top_model_line_id%TYPE
                                   ,x_return_status    OUT      VARCHAR2
                                   ,x_return_message   OUT      VARCHAR2
                                    );

	 -- +===================================================================+
	-- | Name  : CANCEL_ORDER                                               |
	-- | Description      : This program cancels the order when header ID   |
	-- |                    is passed                                       |
	-- | Parameters :        i_line_id                                      |
	-- |                     i_cancel_reason                                |
	-- |                     o_return_status                                |
	-- |                     o_return_message                               |
	-- +====================================================================+

	   PROCEDURE CANCEL_ORDER  (
	                            p_header_id        IN       oe_order_headers_all.header_id%TYPE
	                           ,p_cancel_reason    IN       VARCHAR2
	                           ,x_return_status    OUT      VARCHAR2
	                           ,x_return_message   OUT      VARCHAR2
	                           );
          
        -- +===================================================================================+
        -- | Name  :UPDATE_STATUS                                                              |
        -- | Description      : This program updates the sales order line DPS status           |
        -- |                    to cancelled.                                                  |
        -- | Parameters :                                                                      |
        -- |             p_order_line_id                                                       |
        -- |             x_return_status                                                       |
        -- +===================================================================================+

            PROCEDURE UPDATE_STATUS (	                   
                                    p_order_line_id     IN       oe_order_lines_all.line_id%TYPE
                                   ,p_update_status     IN       xx_om_line_attributes_all.trans_line_status%TYPE
                                   ,x_return_status     OUT      VARCHAR2
                                   ) ;

	-- +===================================================================+
	-- | Name  : PREVALIDATE_PROC                                          |
	-- | Description      : This program validates the sales order line    |
	-- |                                                                   |
	-- | Parameters :        p_order_header_id                             |
	-- |                     p_order_line_id                               |
	-- |                     x_return_status                               |
	-- +===================================================================+

           PROCEDURE PREVALIDATE_PROC (
	                               p_order_header_id   IN       oe_order_headers_all.header_id%TYPE
                                      ,p_order_line_id     IN       oe_order_lines_all.line_id%TYPE
                                      ,x_return_status     OUT      VARCHAR2
                                      );

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

	   PROCEDURE CANCEL_BY_JMILL_PROC ( 
                                 p_order_number      IN oe_order_headers_all.order_number%TYPE
                                ,p_order_detail_tbl  IN orderdetail_tbl_type
                                ,p_user_id           IN FND_USER.user_id%TYPE
                                ,p_responsibility_id IN FND_RESPONSIBILITY_TL.responsibility_id%TYPE
                                ,x_return_status     OUT VARCHAR2
				                         );
	      
		     -- +===================================================================+
		     -- | Name  : BUS_EVENT_BPEL_PROC                                       |
		     -- | Description   : 1. This procedure is invoked from DPSCANCEL_PROC  |
		     -- |                    for raising a business event which             |
		     -- |                     triggers the BPEL  process                    |
		     -- |                                                                   |
		     -- | Parameters :  p_event_key                                         |
		     -- |                                                                   |
		     -- +===================================================================+

	   PROCEDURE BUS_EVENT_BPEL_PROC ( p_event_key IN VARCHAR2 );


			-- +==========================================================================+
			-- | Name  : DPSCANCEL_PROC                                                   |
			-- | Description :                                                             |
			-- |              This procedure is called from scheduled concurrent program   |		
			-- |                1. When the header_id and line_id are passed               |
			-- |                   call the PREVALIDATE_PROC for                          |
			-- |                   validation and then cancel the Order/bundles           |
			-- |                2. When the header_id and line_id are not passed          |
			-- |		        call the PREVALIDATE_PROC for                         |
			-- |                   validation and then cancel the Order/bundles           |
			-- |                3. The orders in 'Booked' state and                       |
			-- |                   and 'Picked' state are fetched for cancellation. If an |
			-- |                   order is in Booked state then call CANCEL_LINE/        |
			-- |                   CANCEL_ORDER.If the order is in picked state call the  |
			-- |                   API wsh_deliveries_pub.delivery_action for back order  |
			-- |                   and ship confirmation and then cancel the order/line.  |
			-- |                                                                          |
			-- |                                                                          |
			-- | Parameters :      x_errbuff                                              |
			-- |                   x_retcode                                              |
			-- |                   p_header_id                                            |
			-- |                   p_parent_line_id                                       |
			-- |                   p_days                                                 |
			-- +==========================================================================+
	  PROCEDURE DPSCANCEL_PROC (
		                    x_errbuff           OUT      VARCHAR2
		                   ,x_retcode           OUT      NUMBER
		                   ,p_header_id         IN       oe_order_headers_all.header_id%TYPE
		                   ,p_parent_line_id    IN       NUMBER
		                   ,p_days              IN       NUMBER
		                   );
	   
		         -- +===================================================================+
			 -- | Name  : DPSCANCEL_FROM_JMILL_FUNC                                 |
			 -- | Description      : Business event raises this function.           |
			 -- |                    Passes the required parameters and calls       |
			 -- |                    cancel_bundle and raise the business event     |
			 -- |                    to pass cancel info to Nowdocs thru BPEL process|
			 -- |                                                                   |
			 -- | Parameters :        p_subscription_guid                           |
			 -- |                     p_event                                       |
			 -- +===================================================================+
	   
	  FUNCTION DPSCANCEL_FROM_JMILL (
					 p_subscription_guid IN RAW
					,p_event             IN OUT  wf_event_t
					)
	  RETURN VARCHAR2;

	-- +===================================================================+
	-- | Name  : DELETE_PARENTID_BPEL                                      |
	-- | Description      : This program delete Parent Line IDs stored     |
	-- |			            in the table XX_OM_DPSPARENT_STG.  |
	-- |                                                                   |
	-- | Parameters :      p_session_id                                    |
	-- |                   x_return_status                                 |
	-- |                   x_return_message                                |
	-- +===================================================================+
	  PROCEDURE DELETE_PARENTID_BPEL (  
	                                   p_session_id       IN       NUMBER                                                                                           
					  ,p_user_name        IN       VARCHAR2     
					  ,p_resp_name        IN       VARCHAR2           
					  ,x_return_status    OUT      VARCHAR2          
					  ,x_return_message   OUT      VARCHAR2         
					  ) ;      
					  
END XX_OM_DPSCANCEL_PKG;
/
