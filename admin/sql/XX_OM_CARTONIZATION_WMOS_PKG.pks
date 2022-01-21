SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE  XX_OM_CARTONIZATION_WMOS_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name         : XX_OM_CARTONIZATION_WMOS_PKG                                             |
-- | Rice Id      : I0030_Cartonization                                                      | 
-- | Description  : Custom Package to implement basic business functionality for             |
-- |                WMOS Cartonization.                                                      |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    | 
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   01-FEB-2007       Francis          Initial Version                            |
-- |1.1        30-MAY-2007       Nabarun Ghosh    Incorporated the business process logic to |
-- |                                              create LPN and assign to a delivery.       |
-- |                                                                                         |
-- +=========================================================================================+
AS

  --Declaring a record, which contains the third level output attributes 
  --of the output XML from wmos system.
  TYPE xx_om_showshipunit_thirdlvl_t IS RECORD 
                   (  container_id               NUMBER
                     ,delivery_number            NUMBER
                     ,delivery_detail_id         NUMBER
                     ,ContainerLineNum           NUMBER
                     ,inventory_item_id          NUMBER
                     ,requested_quantity	 NUMBER
		     ,spl_instr_code_1           VARCHAR2(2000)
		     ,spl_instr_code_2           VARCHAR2(2000)
		     ,spl_instr_code_3           VARCHAR2(2000)
		     ,spl_instr_code_4           VARCHAR2(2000)
		     ,spl_instr_code_5           VARCHAR2(2000)
		     ,spl_instr_code_6           VARCHAR2(2000)
		     ,spl_instr_code_7	         VARCHAR2(2000)
		     ,spl_instr_code_8	         VARCHAR2(2000)
		     ,spl_instr_code_9	         VARCHAR2(2000)
		     ,spl_instr_code_10	         VARCHAR2(2000)
		     ,Season                     VARCHAR2(200)
		     ,Season_yr                  VARCHAR2(200)
		     ,Style                      VARCHAR2(200)
		     ,StyleSfx                   VARCHAR2(200)
		     ,Color                      VARCHAR2(200)
		     ,ColorSfx                   VARCHAR2(200) 
		     ,SecDim                     VARCHAR2(200)
		     ,Qual                       VARCHAR2(200)
		     ,SizeDesc                   VARCHAR2(200)
		     ,ProcStatCode               NUMBER
		     ,ProcDateTime               DATE
                    );

  --Table of the record contains delivery detail info
  TYPE xx_om_showship_thirdlvl_tbl IS TABLE OF xx_om_showshipunit_thirdlvl_t INDEX BY BINARY_INTEGER;
  lt_showshipunit_thirdlvl_tbl xx_om_showship_thirdlvl_tbl;
   
  --Declaring a record, which contains the second level output attributes 
  --of the output XML from wmos system.
  TYPE xx_om_showshipunit_seclvl_t IS RECORD 
                   (  container_id               NUMBER
                     ,delivery_id                NUMBER
                     ,gross_weight               NUMBER
                     ,volume                     NUMBER
		     ,length                     NUMBER          --Represents the Attribute1 of the XML Document ShowShipmentUnit 
		     ,width			 NUMBER          --Represents the Attribute2 of the XML Document ShowShipmentUnit
		     ,height			 NUMBER          --Represents the Attribute3 of the XML Document ShowShipmentUnit
		     ,carton_type                VARCHAR2(200)   --Represent Carton Name, based on the resolution provided in MD070
		     ,carton_size                VARCHAR2(200)   --Represents the UOM in the XML Document ShowShipmentUnit, Require Clarification
		     ,postmaster                 NUMBER
		     ,spl_instr_code_1           VARCHAR2(2000)
		     ,spl_instr_code_2           VARCHAR2(2000)
		     ,spl_instr_code_3           VARCHAR2(2000)
		     ,spl_instr_code_4           VARCHAR2(2000)
		     ,spl_instr_code_5           VARCHAR2(2000)
		     ,spl_instr_code_6           VARCHAR2(2000)
		     ,spl_instr_code_7	         VARCHAR2(2000)
		     ,spl_instr_code_8	         VARCHAR2(2000)
		     ,spl_instr_code_9	         VARCHAR2(2000)
		     ,spl_instr_code_10	         VARCHAR2(2000)
		     ,ProcStatCode               NUMBER
		     ,ProcDateTime               DATE
		     ,lt_showshipunit_thirdlvl_tbl xx_om_showship_thirdlvl_tbl
                    );

  --Table of the record conatins container level info
  TYPE xx_om_showshipunit_seclvl_tbl IS TABLE OF xx_om_showshipunit_seclvl_t INDEX BY BINARY_INTEGER;
  lt_showshipunit_seclvl_tbl xx_om_showshipunit_seclvl_tbl;


  --Declaring a record, which contains the top level output attributes 
  --of the output XML from wmos system.
  TYPE xx_om_showshipunit_firstlvl_t IS RECORD 
                   (  delivery_id                NUMBER
                     ,number_of_lpn              NUMBER  --Represents Total No Of Cartons in the XML Document ShowShipmentUnit
                     ,gross_weight               NUMBER 
                     ,volume                     NUMBER
		     ,spl_instr_code_1           VARCHAR2(2000)
		     ,spl_instr_code_2           VARCHAR2(2000)
		     ,spl_instr_code_3           VARCHAR2(2000)
		     ,spl_instr_code_4           VARCHAR2(2000)
		     ,spl_instr_code_5           VARCHAR2(2000)
		     ,spl_instr_code_6           VARCHAR2(2000)
		     ,spl_instr_code_7	         VARCHAR2(2000)
		     ,spl_instr_code_8	         VARCHAR2(2000)
		     ,spl_instr_code_9	         VARCHAR2(2000)
		     ,spl_instr_code_10	         VARCHAR2(2000)
		     ,ProcStatCode               NUMBER
		     ,ProcDateTime               DATE
		     ,lt_showshipunit_seclvl_tbl xx_om_showshipunit_seclvl_tbl
                    );

  --Table of the record contains Deliver level informations 
  TYPE xx_om_showship_firstlvl_tbl IS TABLE OF xx_om_showshipunit_firstlvl_t INDEX BY BINARY_INTEGER;
  lt_showshipunit_firstlvl_tbl xx_om_showship_firstlvl_tbl;
      
  
  --Declaring the variables holding the constant values for global exception handling framework
  ---------------------------------------------------------------------------------------------
  g_exception_header  CONSTANT xx_om_global_exceptions.exception_header%TYPE := 'OTHERS'            ;
  g_track_code        CONSTANT xx_om_global_exceptions.track_code%TYPE       := 'OTC'               ;
  g_solution_domain   CONSTANT xx_om_global_exceptions.solution_domain%TYPE  := 'Pick Release'      ;
  g_function          CONSTANT xx_om_global_exceptions.function_name%TYPE    := 'Cartonization WMOS';
  
  --Declaring variables holding info of the proces to assign LPN
  --------------------------------------------------------------
  g_c_container_flag       CONSTANT   VARCHAR2(1)   := 'N';
  g_c_delivery_flag        CONSTANT   VARCHAR2(1)   := 'Y';
  g_c_action_code                     VARCHAR2(10);
  g_c_user_name            CONSTANT   VARCHAR2(100) := 'NABARUNG'; 
  g_c_resp_name            CONSTANT   VARCHAR2(240) := 'Order Management Super User';
  g_n_user_id                         NUMBER        := FND_GLOBAL.USER_ID;
  g_n_resp_id                         NUMBER;
  g_n_resp_app_id                     NUMBER;
  g_n_org_id                          NUMBER;       --:= FND_GLOBAL.ORG_ID;

  --Initializing the object type to parse the exception infos to global exception handling framework
  --------------------------------------------------------------------------------------------------
  lrec_excepn_obj_type xx_om_report_exception_t:= 
                                   xx_om_report_exception_t(NULL
                                                           ,NULL
                                                           ,NULL
                                                           ,NULL
                                                           ,NULL
                                                           ,NULL
                                                           ,NULL
                                                           ,NULL);
                                                           
  --Initializing the object type to parse the additional delivery detail informations
  -----------------------------------------------------------------------------------
  lr_wsh_dlv_det_att_obj_type xx_wsh_delivery_det_att_t:= 
                                   xx_wsh_delivery_det_att_t(NULL                
                                                            ,NULL  	      
                                                            ,NULL  	      
                                                            ,NULL  	      
                                                            ,NULL  	      
                                                            ,NULL  	      
                                                            ,NULL  	      
                                                            ,NULL  	      
                                                            ,NULL  	      
                                                            ,SYSDATE	      
                                                            ,g_n_user_id      
                                                            ,SYSDATE  	      
                                                            ,g_n_user_id      
                                                            ,g_n_user_id      
                                                            );            

  --Initializing the object type to parse the additional delivery informations
  ----------------------------------------------------------------------------
  lr_wsh_dlv_att_obj_type xx_wsh_delivery_att_t:= 
                                       xx_wsh_delivery_att_t(NULL        
                                                            ,NULL     
                                                            ,NULL     
                                                            ,NULL     
                                                            ,NULL     
                                                            ,NULL     
                                                            ,NULL     
                                                            ,NULL     
                                                            ,NULL     
                                                            ,NULL     
                                                            ,NULL     
                                                            ,NULL     
                                                            ,NULL     
                                                            ,NULL
                                                            ,NULL
                                                            ,NULL
                                                            ,SYSDATE
                                                            ,g_n_user_id
                                                            ,SYSDATE
                                                            ,g_n_user_id
                                                            ,g_n_user_id
                                                            );    
                                                            

  --Declaring variables holding different cartonization process status
  --------------------------------------------------------------------
  g_cartonization_started    CONSTANT wsh_new_deliveries.attribute1%TYPE := 'CARTONIZATION STARTED' ;
  g_lpn_started              CONSTANT wsh_new_deliveries.attribute1%TYPE := 'LPN STARTED'           ;
  g_cartonization_complete   CONSTANT wsh_new_deliveries.attribute1%TYPE := 'CARTONIZATION COMPLETE';
  g_cartonization_eligible   CONSTANT wsh_new_deliveries.attribute1%TYPE := 'CARTONIZATION ELIGIBLE';


  
  -- +=================================================================+
  -- | Name  : Log_Exceptions                                          |
  -- | Rice Id      : I0030_Cartonization                              | 
  -- | Description: This procedure will be responsible to store all    |  
  -- |              the exceptions occured during the procees using    | 
  -- |              global custom exception handling framework         |
  -- +=================================================================+
  PROCEDURE log_exceptions( p_error_code        IN  VARCHAR2
                           ,p_error_description IN  VARCHAR2
                           ,p_entity_ref        IN  VARCHAR2
                           ,p_entity_ref_id     IN  PLS_INTEGER
                          );
  
  -- +===================================================================+
  -- | Name  : Log_Carton_Wmos_Proc_status                               |
  -- | Rice Id      : I0030_Cartonization                                | 
  -- | Description:       This Procedure will be updating the process    |
  -- |                    status for the delivery in wsh_new_deliveries, |  
  -- |                    to identify the exact state of the processing. |
  -- +===================================================================+
  PROCEDURE   Log_Carton_Wmos_Proc_status( 
                                          p_delivery_id     IN  wsh_new_deliveries.delivery_id%TYPE
                                         ,p_process_status  IN  wsh_new_deliveries.attribute1%TYPE
                                         ,x_status          OUT VARCHAR2
                                         );
  -- +===================================================================+
  -- | Name  : Split_Delivery_Lines                                      |
  -- | Rice Id      : I0030_Cartonization                                | 
  -- | Description: This procedure will cater the requirement, if in a   | 
  -- |              delivery line where the SKU quantity is packed into  |
  -- |              more than 1 carton will be split equal to number of  |
  -- |              cartons and requested quantity on each delivery line | 
  -- |              is updated with container id and SKUs quantity in    |
  -- |              container(carton)                                    | 

  -- +===================================================================+
  PROCEDURE  Split_Delivery_Lines( 
                                  p_delivery_detail_id         IN         wsh_delivery_details.delivery_detail_id%TYPE
                                 ,p_sku_quantity               IN         wsh_delivery_details.requested_quantity%TYPE
                                 ,x_splited_delvery_detail_id  OUT NOCOPY wsh_delivery_details.delivery_detail_id%TYPE 
                                 ,x_splited_requested_quantity OUT NOCOPY wsh_delivery_details.requested_quantity%TYPE 
                                 ,x_return_status              OUT NOCOPY VARCHAR2
                                 ,x_msg_count                  OUT NOCOPY PLS_INTEGER
                                 ,x_msg_data                   OUT NOCOPY VARCHAR2
                                 );

  -- +===================================================================+
  -- | Name  : Create_Lpn                                                |
  -- | Rice Id      : I0030_Cartonization                                | 
  -- | Description: This procedure will cater the requirement to create  | 
  -- |              LPN.                                                 |
  -- +===================================================================+
  PROCEDURE  Create_Lpn( 
                        p_carton_id             IN  PLS_INTEGER
                       ,p_organization_id       IN  mtl_parameters.organization_id%TYPE
                       ,p_container_name        IN  wsh_delivery_details.container_name%TYPE
                       ,x_container_instance_id OUT NOCOPY PLS_INTEGER
                       ,x_return_status         OUT NOCOPY VARCHAR2
                       ,x_msg_count             OUT NOCOPY PLS_INTEGER
                       ,x_msg_data              OUT NOCOPY VARCHAR2
                      );

  -- +===================================================================+
  -- | Name  : Assign_Lpn                                                |
  -- | Rice Id      : I0030_Cartonization                                | 
  -- | Description: This procedure will cater the requirement to assign  | 
  -- |              LPN to the Delivery.                                 |
  -- |                                                                   |
  -- +===================================================================+
  PROCEDURE Assign_Lpn( 
                       p_delivery_detail_id    IN  wsh_delivery_details.delivery_detail_id%TYPE
                      ,p_container_instance_id IN  PLS_INTEGER
                      ,x_return_status         OUT NOCOPY VARCHAR2
                      ,x_msg_count             OUT NOCOPY PLS_INTEGER
                      ,x_msg_data              OUT NOCOPY VARCHAR2
                      );

  -- +===================================================================+
  -- | Name  : Update_Addl_Delivery_Dtls_Info                            |
  -- | Rice Id      : I0030_Cartonization                                | 
  -- | Description:       This Procedure will cater the requirement to   |
  -- |                    update the Additional Delivery Detail          |
  -- |                    Information of Carton Length, Carton Width,    |
  -- |                    Carton Height and the LxWxH UOM.               |
  -- +===================================================================+
  PROCEDURE Update_Addl_Delivery_Dtls_Info
                           ( 
                            p_delivery_detail_id  IN  wsh_delivery_details.delivery_detail_id%TYPE
                           ,p_carton_length       IN  wsh_delivery_details.Attribute1%TYPE
                           ,p_carton_width        IN  wsh_delivery_details.Attribute2%TYPE
                           ,p_carton_height       IN  wsh_delivery_details.Attribute3%TYPE
                           ,p_uom                 IN  wsh_delivery_details.Attribute4%TYPE
                           ,x_status              OUT NOCOPY VARCHAR2
                           );
  
  -- +===================================================================+
  -- | Name  : Update_Addl_Delivery_Info                                 |
  -- | Rice Id      : I0030_Cartonization                                | 
  -- | Description:       This Procedure will cater the requirement to   |
  -- |                    update the Additional Delivery Information of  |
  -- |                    of Total No Of Carton, Gross Weight and        |
  -- |                    Total Volume.                                  |
  -- +===================================================================+
  PROCEDURE Update_Addl_Delivery_Info( 
                                      p_delivery_id   IN  wsh_new_deliveries.delivery_id%TYPE
                                     ,p_number_of_lpn IN  wsh_new_deliveries.number_of_lpn%TYPE
                                     ,p_gross_weight  IN  wsh_new_deliveries.gross_weight%TYPE
                                     ,p_volume        IN  wsh_new_deliveries.volume%TYPE
                                     ,x_return_status OUT NOCOPY VARCHAR2
                                     ,x_msg_count     OUT NOCOPY PLS_INTEGER
                                     ,x_msg_data      OUT NOCOPY VARCHAR2
                                     );
  
  -- +===================================================================+
  -- | Name  : Process_Cartonization_Wmos                                |
  -- | Rice Id      : I0030_Cartonization                                |
  -- | Description:       This Procedure will be accepting the output    |
  -- |                    OAGIS9.0 XML Document ShowShipment details,    |
  -- |                    based on the output it will split the delivery |
  -- |                    lines if no.of cartonaization is more than one,|
  -- |                    create the LPN, assign this to delivery line   |
  -- |                    and update the status according to the         |
  -- |                    processing.                                    |  
  -- |                    OAGIS9.0 XML Document as an input parameters to|
  -- |                    Manhattan EIS Server for WMoS                  |
  -- +===================================================================+
  
  PROCEDURE Process_Cartonization_Wmos(
                                       p_showshipunit_firstlvl_tbl IN  xx_om_showship_firstlvl_tbl
                                      ,x_status                    OUT NOCOPY VARCHAR2
                                      ,x_errcode                   OUT NOCOPY NUMBER
                                      );

END XX_OM_CARTONIZATION_WMOS_PKG;
/
SHOW ERRORS;
--EXIT;