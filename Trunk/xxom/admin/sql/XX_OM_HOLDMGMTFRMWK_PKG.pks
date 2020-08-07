SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE  XX_OM_HOLDMGMTFRMWK_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name        : XX_OM_ODHOLDSINFO_PKG                               |
-- | Rice Id     : E0244_HoldsManagementFramework                      | 
-- | Description : Package Specification                               | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  | 
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   19-APR-2007   Nabarun Ghosh    Initial draft version    |
-- |1.1        04-JUN-2007   Nabarun Ghosh    Updated the Comments     |
-- |                                          Section as per onsite    |
-- |                                          review.                  |
-- +===================================================================+
  
   --Cursor to fetch all the additional informations of OD specific holds
   ----------------------------------------------------------------------
   CURSOR lcu_additional_info (
                              P_Hold_Id          IN Oe_Hold_Definitions.Hold_Id%TYPE
                             ,P_Order_Or_Line    IN Xx_Om_Od_Hold_Add_Info.apply_to_order_or_line%TYPE  
                             )                            
   IS    
   SELECT OH.hold_id                    hold_id              
         ,XOOHA.hold_type               hold_type                    
         ,XOOHA.apply_to_order_or_line  apply_to_order_or_line       
         ,XOOHA.org_id                  org_id                                       
         ,XOOHA.no_of_days              no_of_days                   
         ,XOOHA.stock_reserved          stock_reserved                               
         ,XOOHA.escalation_no_of_days   escalation_no_of_days        
         ,XOOHA.credit_authorization    credit_authorization         
         ,XOOHA.authorities_to_notify   authorities_to_notify                 
         ,XOOHA.priority                priority                                     
         ,XOOHA.rule_function_name      rule_function_name
         ,XOOHA.order_booking_status    order_booking_status 
         ,XOOHA.Send_To_Pool            Send_To_Pool 
         ,OH.name                       name
   FROM  xx_om_od_hold_add_info         XOOHA
        ,oe_hold_definitions            OH
   WHERE OH.attribute6                = TO_CHAR(XOOHA.combination_id)
   AND   OH.hold_Id||''               = NVL(P_Hold_Id,OH.hold_Id)
   AND   XOOHA.apply_to_order_or_line||'' =  NVL(P_Order_Or_Line,XOOHA.apply_to_order_or_line)
   AND   XOOHA.hold_type              = 'M'
   ORDER BY XOOHA.apply_to_order_or_line
           ,XOOHA.priority;
  
   --Variables holding the additional hold informations
   ----------------------------------------------------
   ln_hold_id                   Oe_Hold_Definitions.hold_id%TYPE                 ;
   lc_hold_type                 Xx_Om_Od_Hold_Add_Info.hold_type%TYPE               ;
   lc_apply_to_order_or_line    Xx_Om_Od_Hold_Add_Info.apply_to_order_or_line%TYPE  ;
   ln_org_id                    Xx_Om_Od_Hold_Add_Info.org_id%TYPE                  ;
   ln_no_of_days                Xx_Om_Od_Hold_Add_Info.no_of_days%TYPE              ;
   ln_stock_reserved            Xx_Om_Od_Hold_Add_Info.stock_reserved%TYPE          ;
   ln_escalation_no_of_days     Xx_Om_Od_Hold_Add_Info.escalation_no_of_days%TYPE   ;
   lc_credit_authorization      Xx_Om_Od_Hold_Add_Info.credit_authorization%TYPE    ;
   lc_authorities_to_notify     Xx_Om_Od_Hold_Add_Info.authorities_to_notify%TYPE   ;
   ln_priority                  Xx_Om_Od_Hold_Add_Info.priority%TYPE                ;
   lc_rule_function	        VARCHAR2(4000)                                             ;
   lc_rule_function_name	Xx_Om_Od_Hold_Add_Info.rule_function_name%TYPE      ;
   lc_order_booking_status      Xx_Om_Od_Hold_Add_Info.order_booking_status%TYPE    ;
   lc_send_to_pool              Xx_Om_Od_Hold_Add_Info.send_to_pool%TYPE            ;
   lc_name			Oe_Hold_Definitions.name%TYPE                           ;
   lc_order_or_line             Xx_Om_Od_Hold_Add_Info.apply_to_order_or_line%TYPE  ;  
  
   --Cursor to fetch the sales order details
   -----------------------------------------
   CURSOR lcu_sales_order (
                           i_order_header_id        IN Oe_Order_Headers_All.Header_Id%TYPE
    			  ,i_order_line_id          IN Oe_Order_Lines_All.Line_Id%TYPE
                         )
   IS
   SELECT OOH.order_number          order_number
         ,OOH.ordered_date	    ordered_date
         ,OOH.header_id             header_id
         ,OOL.org_id		    org_id
         ,OOL.line_id		    line_id
         ,OOL.line_number	    line_number
         ,OOL.ordered_item	    ordered_item
         ,OOL.inventory_item_id	    inventory_item_id
         ,OOL.ship_from_org_id	    ship_from_org_id
         ,OOL.ordered_quantity	    ordered_quantity
         ,OOL.order_quantity_uom    order_quantity_uom
         ,OOH.flow_status_code      flow_status_code 
   FROM  oe_order_headers OOH
        ,oe_order_lines   OOL
   WHERE OOH.header_id||'' = NVL(i_order_header_id,OOH.header_id)
   AND   OOL.line_id||''   = NVL(i_order_line_id,OOL.line_id)
   AND   OOH.header_id = OOL.header_id; 


   --Variables holding the sales order details
   ----------------------------------------------------
   ln_order_number              Oe_Order_Headers_All.order_number%TYPE      ;      
   ld_ordered_date              Oe_Order_Headers_All.ordered_date%TYPE      ; 
   ln_header_id                 Oe_Order_Headers_All.header_id%TYPE         ; 
   lo_org_id                    Oe_Order_Lines_All.org_id%TYPE              ;            
   ln_line_id                   Oe_Order_Lines_All.line_id%TYPE             ;           
   lc_line_number               Oe_Order_Lines_All.line_number%TYPE         ;       
   lc_ordered_item              Oe_Order_Lines_All.ordered_item%TYPE        ;      
   ln_inventory_item_id         Oe_Order_Lines_All.inventory_item_id%TYPE   ; 
   ln_ship_from_org_id          Oe_Order_Lines_All.ship_from_org_id%TYPE    ;  
   ln_ordered_quantity          Oe_Order_Lines_All.ordered_quantity%TYPE    ;  
   lc_order_quantity_uom        Oe_Order_Lines_All.order_quantity_uom%TYPE  ;
   lc_flow_status_code          Oe_Order_Headers_All.flow_status_code%TYPE  ;      
  

   --Cursor fetching the rule-functions for the hold id passed
   -----------------------------------------------------------
   CURSOR lcu_rulefunction_info (
                                 i_hold_id oe_hold_definitions.hold_id%TYPE
                                ) 
   IS     
   SELECT XOOHA.rule_function_name   rule_function_name
         ,OH.name                     name
   FROM  xx_om_od_hold_add_info      XOOHA
        ,oe_hold_definitions         OH
   WHERE OH.attribute6  = TO_CHAR(XOOHA.combination_id)
   AND   OH.hold_id     = i_hold_id
   AND   SYSDATE <= NVL(OH.end_date_active,SYSDATE);
   
  
  -- Variable decalred as object type referencing the global exception handling framework
  ---------------------------------------------------------------------------------------
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
  -- | Description: This function will compile the rule-function         |
  -- |              for the Hold Id passed as argument, these rule       |
  -- |              functions are developed and stored into the          |
  -- |              metadata table against each OD Hold, which will      |
  -- |              decide whether to apply or release holds.            |
  -- +===================================================================+
  FUNCTION Compile_Rule_Function(
                                 p_hold_id  IN oe_hold_definitions.hold_id%TYPE 
                                )
  RETURN CHAR;
  
  -- +=============================================================+
  -- | Name  : Generate_Rule_Function                              |
  -- | Description: This custom function will be responsible to    | 
  -- |              generate different rule-function for each of   |
  -- |              the OD Specifi Hold passed as argument which   | 
  -- |              will decide whether or not to apply / release  | 
  -- |              OD Holds from Ordre Header / Line level.       |
  -- +=============================================================+
  FUNCTION Generate_Rule_Function(
				  p_hold_id      IN oe_hold_definitions.hold_id%TYPE
                                 )
  RETURN CHAR;

  -- +=============================================================+
  -- | Name  : Apply_Hold_Manually                                 |
  -- | Description: This procedure will provide facility to        | 
  -- |              apply any OD Specific Holds in manual bucket   |
  -- |              to order /return header or on Line / return    | 
  -- |              line by invoking custom rule-function,which    | 
  -- |              requires manual review, and which should appear|
  -- |		    in Pool/queue.                                 |
  -- +=============================================================+
  PROCEDURE Apply_Hold_Manually
                              (
			       P_Order_Header_Id          IN Oe_Order_Headers_All.Header_Id%TYPE
			      ,P_Order_Line_Id            IN Oe_Order_Lines_All.Line_Id%TYPE
			      ,P_Hold_Id                  IN Oe_Hold_Definitions.Hold_Id%TYPE
			      ,x_return_status            OUT NOCOPY VARCHAR2
			      ,x_msg_count                OUT NOCOPY PLS_INTEGER
			      ,x_msg_data                 OUT NOCOPY VARCHAR2
                             );  

  -- +=============================================================+
  -- | Name  : Apply_Hold                                          |
  -- | Description: This procedure will call the seeded API        |
  -- |              OE_HOLDS_PUB to apply any OD Specific Holds in |
  -- |              manual bucket to order /return header or on    | 
  -- |              Line / return line.                            |
  -- +=============================================================+ 
  PROCEDURE Apply_Hold(
                      p_hold_id            IN    Oe_Hold_Definitions.Hold_Id%TYPE
                     ,p_order_header_id    IN    Oe_Order_Headers_All.Header_Id%TYPE
                     ,p_order_line_id      IN    Oe_Order_Lines_All.Line_Id%TYPE
                     ,P_hdr_comments       IN    VARCHAR2
                     ,p_hold_entity_code   IN    Xx_Om_Od_Hold_Add_Info.apply_to_order_or_line%TYPE
                     ,x_return_status      OUT   NOCOPY VARCHAR2
                     ,x_msg_count          OUT   NOCOPY PLS_INTEGER 
                     ,x_msg_data           OUT   NOCOPY VARCHAR2
                     ); 
 
  -- +=============================================================+
  -- | Name  : Release_Hold_Manually                               |
  -- | Description: This procedure will provide facility to        |
  -- |              release any OD Specific Holds in manual bucket |
  -- |              applied to order /return header or on Line /   |
  -- |              return line by invoking custom rule-function   |
  -- |                                                             |
  -- +=============================================================+ 
  PROCEDURE Release_Hold_Manually
                              (
			       P_Order_Header_Id        IN Oe_Order_Headers_All.Header_Id%TYPE
			      ,P_Order_Line_Id          IN Oe_Order_Lines_All.Line_Id%TYPE
			      ,P_Hold_Id                IN Oe_Hold_Definitions.Hold_Id%TYPE
			      ,P_Pool_Id                IN Xx_Od_Pool_Records.Pool_Id%TYPE
			      ,x_return_status          OUT NOCOPY VARCHAR2
			      ,x_msg_count              OUT NOCOPY PLS_INTEGER
			      ,x_msg_data               OUT NOCOPY VARCHAR2
                             );

  -- +=============================================================+
  -- | Name  : Release_Hold                                        |
  -- | Description: This procedure will call the seeded API        |
  -- |              OE_HOLDS_PUB to Releaseany OD Specific Holds   |
  -- |              in manual bucket priority wise from order      | 
  -- |              /return header or from Line / return line.     |
  -- |                                                             |
  -- +=============================================================+                              
  PROCEDURE Release_Hold(
                      p_hold_id            IN    Oe_Hold_Definitions.Hold_Id%TYPE
                     ,p_order_header_id    IN    Oe_Order_Headers_All.Header_Id%TYPE
                     ,p_order_line_id      IN    Oe_Order_Lines_All.Line_Id%TYPE
                     ,p_release_comments   IN    VARCHAR2
                     ,p_hold_entity_code   IN    Xx_Om_Od_Hold_Add_Info.apply_to_order_or_line%TYPE
                     ,x_return_status      OUT   NOCOPY VARCHAR2
                     ,x_msg_count          OUT   NOCOPY PLS_INTEGER
                     ,x_msg_data           OUT   NOCOPY VARCHAR2
                     );
                             
  -- +=============================================================+
  -- | Name  : Auto_Delete_Program                                 |
  -- | Description: This procedure will look for any OD Specific   |
  -- |              Holds applied which are not released within the| 
  -- |              specified No Of Days as per the additional hold| 
  -- |              informations and will cancel those ordres /    | 
  -- |              lines.                                         |
  -- +=============================================================+
  PROCEDURE Auto_Delete_Program(
                      x_err_buf            OUT VARCHAR2 
  		     ,x_ret_code           OUT VARCHAR2
                     ,p_hold_id            IN Oe_Hold_Definitions.Hold_Id%TYPE
                     ,p_from_date          IN DATE
                     ,p_to_date            IN DATE
                     );                             
                     
END Xx_Om_Holdmgmtfrmwk_Pkg;
/
SHOW ERRORS;
--EXIT;
