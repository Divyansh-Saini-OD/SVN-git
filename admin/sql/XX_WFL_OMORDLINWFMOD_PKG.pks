SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE  XX_WFL_OMORDLINWFMOD_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name         : XX_WFL_OMORDLINWFMOD_PKG                           |
-- | Rice Id      : E0202_OrderLineWorkflowModification                | 
-- | Description  : Package Specification                              | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  | 
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   19-APR-2007   Nabarun Ghosh    Initial draft version    |
-- |                                                                   |
-- |1.1        04-JUN-2007   Nabarun Ghosh    Updated the Comments     |
-- |                                          Section as per onsite    |
-- |                                          review                   |
-- |1.2        24-JUL-2007   Nabarun Ghosh    Updated the code due to  |
-- |                                          changes in DFF/KFF       |
-- +===================================================================+
  
   --Cursor to fetch all the additional informations of OD specific holds
   ----------------------------------------------------------------------
   CURSOR lcu_additional_info 
                            (
                             p_order_booking_status  IN xx_om_od_hold_add_info.order_booking_status%TYPE
                            )
   IS    
   SELECT OH.hold_id                    hold_id              
         ,XXOHA.hold_type               hold_type                    
         ,XXOHA.apply_to_order_or_line  apply_to_order_or_line       
         ,XXOHA.org_id                  org_id                                       
         ,XXOHA.no_of_days              no_of_days                   
         ,XXOHA.stock_reserved          stock_reserved                               
         ,XXOHA.escalation_no_of_days   escalation_no_of_days        
         ,XXOHA.credit_authorization    credit_authorization         
         ,XXOHA.authorities_to_notify   authorities_to_notify                 
         ,XXOHA.priority                priority                                     
         ,XXOHA.rule_function_name      rule_function_name
         ,XXOHA.order_booking_status    order_booking_status 
         ,XXOHA.Send_To_Pool            send_to_pool 
         ,OH.name                       name
   FROM  xx_om_od_hold_add_info        XXOHA
        ,oe_hold_definitions           OH
   WHERE OH.attribute6                = TO_CHAR(XXOHA.combination_id)
   AND   SYSDATE                      <= NVL(OH.end_date_active,SYSDATE)
   AND   XXOHA.apply_to_order_or_line =  'L'
   AND   XXOHA.order_booking_status||''   =   NVL(p_order_booking_status,XXOHA.order_booking_status)
   AND   XXOHA.hold_type              =  'A'
   ORDER BY XXOHA.priority;


  --Cursor to fetch the sales order details
  -----------------------------------------
  CURSOR lcu_get_so_info (
		         i_order_line_id   IN Oe_Order_Lines_All.Line_Id%TYPE
                         )
  IS
  SELECT OOH.order_number       order_number
        ,OOH.ordered_date       ordered_date
        ,OOH.header_id          header_id
        ,OOH.flow_status_code   order_header_status
        ,HOU.organization_id    org_id
        ,OOL.line_id            line_id
        ,OOL.line_number	      line_number
        ,OOL.ordered_item	      ordered_item
        ,OOL.inventory_item_id  inventory_item_id
        ,OOL.ship_from_org_id   ship_from_org_id
        ,OOL.ordered_quantity   ordered_quantity
        ,OOL.order_quantity_uom order_quantity_uom
        ,OOL.flow_status_code   order_line_status
  FROM  oe_order_headers    OOH
       ,oe_order_lines      OOL
       ,hr_operating_units  HOU
  WHERE OOL.line_id||''   = NVL(i_order_line_id,OOL.line_id) 
  AND   OOH.header_id = OOL.header_id
  AND   OOH.org_id    = HOU.organization_id
  AND   HOU.organization_id = (SELECT X.organization_id
                               FROM   hr_operating_units X
                               WHERE  HOU.organization_id =  X.organization_id)  
  AND   OOH.flow_status_code NOT IN ('CANCELED')
  AND   OOL.flow_status_code NOT IN ('CANCELED')
  AND   OOL.top_model_line_id IS NULL;

  
  --Cursor to fetch the hold details, which are being applied on the sales order line
  -----------------------------------------------------------------------------------
  CURSOR lcu_holds_info (
			i_order_line_id        IN Oe_Order_Lines_All.Line_Id%TYPE
		       ,i_order_header_id      IN Oe_Order_Lines_All.Header_Id%TYPE
		       ,i_order_booking_status IN xx_om_od_hold_add_info.order_booking_status%TYPE
                       )
  IS                     
  SELECT OHD.hold_id                  hold_id 
  	,XOOHA.stock_reserved         stock_reserved
  	,OHD.name                     name  
  	,XOOHA.priority               priority
  	,XOOHA.rule_function_name     rule_function_name
  	,XOOHA.apply_to_order_or_line apply_to_order_or_line
  	,XOOHA.no_of_days             no_of_days
  FROM   oe_order_holds                 OH
  	,oe_hold_sources                OHS 
  	,xx_om_od_hold_add_info         XOOHA
  	,oe_hold_definitions            OHD
  WHERE OH.header_id               = i_order_header_id
  AND   OH.line_id                 = i_order_line_id
  AND   OH.hold_release_id IS NULL 
  AND   OH.released_flag           ='N'
  AND   OH.line_id IS NOT NULL 
  AND   OH.hold_source_id            = OHS.hold_source_id
  AND   OHS.hold_id                  = OHD.hold_id
  AND   OHD.attribute6               = TO_CHAR(XOOHA.combination_id)
  AND   XOOHA.apply_to_order_or_line =  'L'
  AND   XOOHA.order_booking_status||''   =   NVL(i_order_booking_status,XOOHA.order_booking_status)
  AND   XOOHA.hold_type              =  'A';
  
  
  --Cursor to fetch the hold details for the types like Furniture / High Return / Wait for Return
  -----------------------------------------------------------------------------------------------
  CURSOR lcu_holds_info_wait (
			      i_order_line_id        IN Oe_Order_Lines_All.Line_Id%TYPE
		             ,i_order_header_id      IN Oe_Order_Lines_All.Header_Id%TYPE
                            )
  IS  
  SELECT OHD.name                       name
        ,OHD.hold_id                    hold_id
        ,XOOHA.apply_to_order_or_line   apply_to_order_or_line
  FROM   oe_order_holds                 OH
        ,oe_hold_sources                OHS
        ,xx_om_od_hold_add_info         XOOHA
        ,oe_hold_definitions            OHD 
  WHERE  OH.header_id                 = i_order_header_id
  AND    OH.line_id                   = i_order_line_id
  AND    OH.hold_release_id IS NULL   
  AND    OH.released_flag             = 'N'
  AND    OH.hold_source_id            = OHS.hold_source_id
  AND    OHS.hold_id                  = OHD.hold_id 
  AND    OHD.attribute6               = TO_CHAR(XOOHA.combination_id)
  AND    XOOHA.hold_type              = 'A'
  AND    XOOHA.apply_to_order_or_line = 'L'
  AND    OHD.name = 'OD WAITING FOR RETURN'; 
  
  --Cursor record type 
  ---------------------
  cur_additional_info             lcu_additional_info%ROWTYPE;
  cur_holds_info                  lcu_holds_info%ROWTYPE; 
  cur_holds_info_wait             lcu_holds_info_wait%ROWTYPE;
  cur_get_so_info                 lcu_get_so_info%ROWTYPE;
  
  --Variables required for processing Stock reservation
  -----------------------------------------------------
  l_rsv                        inv_reservation_global.mtl_reservation_rec_type;
  l_rsv_id                     PLS_INTEGER;
  l_dummy_sn                   inv_reservation_global.serial_number_tbl_type;
  l_reserved_qty               PLS_INTEGER;
  ln_reservation_id            PLS_INTEGER;
  ln_sales_order_id            mtl_sales_orders.sales_order_id%TYPE;

	
  -- Variable decalred as object type referencing the global exception handling framework
  ---------------------------------------------------------------------------------------
  g_exception_header  CONSTANT xx_om_global_exceptions.exception_header%TYPE := 'OTHERS';
  g_track_code        CONSTANT xx_om_global_exceptions.track_code%TYPE       := 'OTC';
  g_solution_domain   CONSTANT xx_om_global_exceptions.solution_domain%TYPE  := 'Sales Order';
  g_function          CONSTANT xx_om_global_exceptions.function_name%TYPE    := 'OrderLineWorkflowModification';
  
  
  lrec_excepn_obj_type xx_om_report_exception_t:= 
                                   xx_om_report_exception_t(NULL
                                                        ,NULL
                                                        ,NULL
                                                        ,NULL
                                                        ,NULL
                                                        ,NULL
                                                        ,NULL
                                                        ,NULL);
   
  -- +=============================================================+
  -- | Name  : Log_Exceptions                                      |
  -- | Rice Id : E0202_OrderLineWorkflowModification               |
  -- | Description: This procedure will be responsible to store all|  
  -- |              the exceptions occured during the procees using| 
  -- |              global custom exception handling framework     |
  -- +=============================================================+
  PROCEDURE log_exceptions( p_error_code        IN  VARCHAR2
                           ,p_error_description IN  VARCHAR2
                           ,p_entity_ref        IN  VARCHAR2
                           ,p_entity_ref_id     IN  PLS_INTEGER
                          );
                          
  -- +===================================================================+
  -- | Name  : Compile_Rule_Function                                     |
  -- | Rice Id : E0202_OrderLineWorkflowModification                     |
  -- | Description: This function will compile the rule-function         |
  -- |              for the Hold Id passed as argument, these rule       |
  -- |              functions are developed and stored into the          |
  -- |              metadata table against each OD Hold, which will      |
  -- |              decide whether to apply or release holds.            |
  -- +===================================================================+
  FUNCTION Compile_Rule_Function(
                                 p_hold_id  IN oe_hold_definitions.hold_id%TYPE 
                                )
  RETURN CHAR ;
  
  -- +===================================================================+
  -- | Name    : Apply_Hold_Before_Booking                               |
  -- | Rice Id : E0202_OrderLineWorkflowModification                     |
  -- | Description: This procedure will be called from the order line wf |
  -- |              process, this will be applying any OD specific holds |
  -- |              on the SO line before booking process.               |
  -- +===================================================================+
  PROCEDURE Apply_Hold_Before_Booking
                                    (
                                     i_itemtype     IN  VARCHAR2,
                                     i_itemkey      IN  VARCHAR2,
                                     i_actid        IN  PLS_INTEGER,
                                     i_funcmode     IN  VARCHAR2,
                                     o_result       OUT NOCOPY VARCHAR2
                                    );
                                    
  -- +===================================================================+
  -- | Name    : Is_Hold_Applied_Bef_Booking                             |
  -- | Rice Id : E0202_OrderLineWorkflowModification                     |
  -- | Description: This procedure will validate any OD Specific Holds   |
  -- |              are applied on the line or not.                      |
  -- +===================================================================+ 
  PROCEDURE Is_Hold_Applied_Bef_Booking
                                    (
                                     i_itemtype     IN  VARCHAR2,
                                     i_itemkey      IN  VARCHAR2,
                                     i_actid        IN  PLS_INTEGER,
                                     i_funcmode     IN  VARCHAR2,
                                     o_result       OUT NOCOPY VARCHAR2
                                    );                                    
  -- +===================================================================+
  -- | Name    : Is_Wait_For_Return_Hold                                 |
  -- | Rice Id : E0202_OrderLineWorkflowModification                     |
  -- | Description: This procedure will be used to check OD Wait For     |
  -- |              Return Hold.                                         |
  -- +===================================================================+ 
  PROCEDURE Is_Wait_For_Return_Hold
                                    (
                                     i_itemtype     IN  VARCHAR2,
                                     i_itemkey      IN  VARCHAR2,
                                     i_actid        IN  PLS_INTEGER,
                                     i_funcmode     IN  VARCHAR2,
                                     o_result       OUT NOCOPY VARCHAR2
                                    );

  -- +===================================================================+
  -- | Name    : Apply_Hold_After_Booking                                |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                                   |
  -- | Description: This procedure will be called from the order line wf |
  -- |              process, this will be applying any OD specific holds |
  -- |              on the SO line after booking process.                |
  -- +===================================================================+
  PROCEDURE Apply_Hold_After_Booking
                                    (
                                     i_itemtype     IN  VARCHAR2,
                                     i_itemkey      IN  VARCHAR2,
                                     i_actid        IN  PLS_INTEGER,
                                     i_funcmode     IN  VARCHAR2,
                                     o_result       OUT NOCOPY VARCHAR2
                                    );

  -- +===================================================================+
  -- | Name    : Is_Hold_Exists_After_Book                               |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                                   |
  -- | Description: This procedure will be called from the order line wf |
  -- |              process, this will be validating any OD specific     |
  -- |              holds on the SO line after booking process.          |
  -- +===================================================================+
  PROCEDURE Is_Hold_Exists_After_Book
                                    (
                                     i_itemtype     IN  VARCHAR2,
                                     i_itemkey      IN  VARCHAR2,
                                     i_actid        IN  PLS_INTEGER,
                                     i_funcmode     IN  VARCHAR2,
                                     o_result       OUT NOCOPY VARCHAR2
                                    );
  
  -- +=============================================================+
  -- | Name  : Apply_Hold                                          |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                             |
  -- | Description: This procedure will call the seeded API        |
  -- |              OE_HOLDS_PUB to apply any OD Specific Holds in |
  -- |              manual bucket to order /return header or on    | 
  -- |              Line / return line.                            |
  -- +=============================================================+ 
  PROCEDURE Apply_Hold(
                      p_hold_id             IN    Oe_Hold_Definitions.Hold_Id%TYPE
                     ,p_order_header_id     IN    Oe_Order_Headers_All.Header_Id%TYPE
                     ,p_order_line_id       IN    Oe_Order_Lines_All.Line_Id%TYPE
                     ,p_hold_apply_comments IN    VARCHAR2
                     ,x_return_status       OUT   NOCOPY VARCHAR2
                     ,x_msg_count           OUT   NOCOPY PLS_INTEGER 
                     ,x_msg_data            OUT   NOCOPY VARCHAR2
                     ); 

  -- +===================================================================+
  -- | Name    : OD_Reserve                                              |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                                   |
  -- | Description: This procedure will be responsible to reserve        |
  -- |              sales order inventory on applying OD Holds.          |
  -- +===================================================================+ 
  PROCEDURE OD_Reserve
                      (
                       p_header_id          IN  oe_order_headers.header_id%TYPE,
                       p_line_id            IN  oe_order_lines.line_id%TYPE,
                       p_ship_from_org_id   IN  oe_order_lines.ship_from_org_id%TYPE,
                       p_inventory_item_id  IN  oe_order_lines.inventory_item_id%TYPE,
                       p_order_number       IN  oe_order_headers.order_number%TYPE,
                       p_order_quantity_uom IN  oe_order_lines.order_quantity_uom%TYPE,
                       p_ordered_quantity   IN  oe_order_lines.ordered_quantity%TYPE,
                       x_return_status      OUT NOCOPY VARCHAR2,
                       x_msg_count          OUT NOCOPY PLS_INTEGER ,
                       x_msg_data           OUT NOCOPY VARCHAR2,
                       x_quantity_reserved  OUT oe_order_lines.ordered_quantity%TYPE
                      );

  -- +===================================================================+
  -- | Name    : Is_Buyers_Remorse_Hold                                  |
  -- | Rice Id : E0202_OrderLineWorkflowModification                     |
  -- | Description: This procedure will be called from the order line wf |
  -- |              process after the booking process inorder to         |
  -- |              validate whether the OD Buyers Remorse Hold is applied| 
  -- |              on the order line or not.                            |
  -- +===================================================================+ 
  PROCEDURE Is_Buyers_Remorse_Hold
                                    (
                                     i_itemtype     IN  VARCHAR2,
                                     i_itemkey      IN  VARCHAR2,
                                     i_actid        IN  PLS_INTEGER,
                                     i_funcmode     IN  VARCHAR2,
                                     o_result       OUT NOCOPY VARCHAR2
                                    );

  -- +===================================================================+
  -- | Name    : Unreserve_Before_Booking                                |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                                   |
  -- | Description: This procedure will be responsible for relieving any |
  -- |              sales order inventory being reserved on applying OD  |
  -- |              Holds before booking process.                        |
  -- +===================================================================+ 
  PROCEDURE Unreserve_Before_Booking
                                    (
                                     i_itemtype     IN  VARCHAR2,
                                     i_itemkey      IN  VARCHAR2,
                                     i_actid        IN  PLS_INTEGER,
                                     i_funcmode     IN  VARCHAR2,
                                     o_result       OUT NOCOPY VARCHAR2
                                    );

  -- +===================================================================+
  -- | Name    : Unreserve_After_Booking                                 |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                                   |
  -- | Description: This procedure will be responsible for relieving any |
  -- |              sales order inventory being reserved on applying OD  |
  -- |              Holds after the booking process.                     |
  -- +===================================================================+ 
  PROCEDURE Unreserve_After_Booking
                                    (
                                     i_itemtype     IN  VARCHAR2,
                                     i_itemkey      IN  VARCHAR2,
                                     i_actid        IN  PLS_INTEGER,
                                     i_funcmode     IN  VARCHAR2,
                                     o_result       OUT NOCOPY VARCHAR2
                                    );

  -- +===================================================================+
  -- | Name    : OD_Unreserve                                            |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                                   |
  -- | Description: This procedure will be responsible for relieving any |
  -- |              sales order inventory being reserved on applying OD  |
  -- |              Holds.                                               |
  -- +===================================================================+ 
  PROCEDURE OD_Unreserve
                        (
                         p_header_id          IN  oe_order_headers.header_id%TYPE,
                         p_line_id            IN  oe_order_lines.line_id%TYPE,
                         p_ship_from_org_id   IN  oe_order_lines.ship_from_org_id%TYPE,
                         p_inventory_item_id  IN  oe_order_lines.inventory_item_id%TYPE,
                         p_order_number       IN  oe_order_headers.order_number%TYPE,
                         x_return_status      OUT NOCOPY VARCHAR2,
                         x_msg_count          OUT NOCOPY PLS_INTEGER ,
                         x_msg_data           OUT NOCOPY VARCHAR2 
                        );

  -- +===================================================================+
  -- | Name  : Release_Hold_Before_Booking                               |
  -- | Rice Id: E0202_OrderLineWorkflowModification                                                    |
  -- | Description: This procedure will provide facility to              |
  -- |              release any OD Specific Holds applied to order /     |
  -- |              return header or on Line / return line before the    |
  -- |              booking process based on the additional informations.|
  -- +===================================================================+ 
  PROCEDURE Release_Hold_Before_Booking
                              (
			       i_itemtype     IN  VARCHAR2
			      ,i_itemkey      IN  VARCHAR2
			      ,i_actid        IN  PLS_INTEGER
			      ,i_funcmode     IN  VARCHAR2
			      ,o_result       OUT NOCOPY VARCHAR2
                             );

  -- +===================================================================+
  -- | Name  : Release_Hold_After_Booking                                |
  -- | Rice Id: E0202_OrderLineWorkflowModification                                                    |
  -- | Description: This procedure will provide facility to              |
  -- |              release any OD Specific Holds applied to order /     |
  -- |              return header or on Line / return line after the     |
  -- |              booking process based on the additional informations.|
  -- +===================================================================+ 
  PROCEDURE Release_Hold_After_Booking
                              (
			       i_itemtype     IN  VARCHAR2
			      ,i_itemkey      IN  VARCHAR2
			      ,i_actid        IN  PLS_INTEGER
			      ,i_funcmode     IN  VARCHAR2
			      ,o_result       OUT NOCOPY VARCHAR2
                             );

  -- +===================================================================+
  -- | Name  : Release_Hold                                              |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                                   |  
  -- | Description: This procedure will call the seeded API              |
  -- |              OE_HOLDS_PUB to Releaseany OD Specific Holds         |
  -- |              priority wise from order /return header or from      | 
  -- |              Line / return line.                                  |
  -- +===================================================================+ 
  PROCEDURE Release_Hold(
                      p_hold_id            IN    Oe_Hold_Definitions.Hold_Id%TYPE
                     ,p_order_header_id    IN    Oe_Order_Headers_All.Header_Id%TYPE
                     ,p_order_line_id      IN    Oe_Order_Lines_All.Line_Id%TYPE
                     ,p_release_comments   IN    VARCHAR2
                     ,p_hold_entity_code   IN    xx_om_od_hold_add_info.apply_to_order_or_line%TYPE
                     ,x_return_status      OUT   NOCOPY VARCHAR2
                     ,x_msg_count          OUT   NOCOPY PLS_INTEGER 
                     ,x_msg_data           OUT   NOCOPY PLS_INTEGER
                     );

END XX_WFL_OMORDLINWFMOD_PKG;
/
SHOW ERRORS;
--EXIT;
