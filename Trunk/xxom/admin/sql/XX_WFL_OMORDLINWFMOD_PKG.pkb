SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_WFL_OMORDLINWFMOD_PKG 
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name         : xx_wfl_omordlinwfmod_pkg                                                |
-- | Rice Id      : E0202_OrderLineWorkflowModification                                      | 
-- | Description  : Script to apply / release OD Specific Automatic Holds to a sales order   |
-- |                at the Header / Line level based on the additional informations captured |
-- |                captured in the metadat table for each of the OD Specific Holds being    |
-- |                entred through seeded holds form in EBS.                                 |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    | 
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   07-MAY-2007       Nabarun Ghosh    Initial version                            |
-- |1.1        04-JUN-2007       Nabarun Ghosh    Updated the Comments Section as per onsite |
-- |                                              review                                     |
-- |1.2        24-JUL-2007       Nabarun Ghosh    Updated the code due to                    |
-- |                                              changes in DFF/KFF                         |
-- +=========================================================================================+
AS

   --Variables holding the API status
   ----------------------------------
   lc_return_status              VARCHAR2(1)   := FND_API.G_RET_STS_SUCCESS;
   ln_msg_count                  PLS_INTEGER        := 0;
   lc_msg_data                   VARCHAR2(4000);
   api_ver_info      CONSTANT    PLS_INTEGER := 1.0;
   
   --Variables required for setting Apps contexts
   ----------------------------------------------
   ln_user_id                    PLS_INTEGER;
   ln_resp_id                    PLS_INTEGER;
   ln_appl_id                    PLS_INTEGER;  

   --variable holding the error details
   ------------------------------------
   ln_exception_occured         PLS_INTEGER       := 0;
   lc_error_code                xx_om_global_exceptions.error_code%TYPE; 
   lc_error_desc                xx_om_global_exceptions.description%TYPE; 
   lc_entity_ref                xx_om_global_exceptions.entity_ref%TYPE;
   lc_entity_ref_id             xx_om_global_exceptions.entity_ref_id%TYPE;
  
   --Variable holding the output of the rule-function
   --------------------------------------------------
   lc_rule_result               VARCHAR2(1000);
   lc_rule_function_result      VARCHAR2(3);
   lc_sqlerrm                   VARCHAR2(1000); 
   
   --Variables required for processing Holds
   -----------------------------------------
   lc_hold_apply_comments         VARCHAR2(2000) := 'XX OD Holds';
   lc_hold_release_comments       VARCHAR2(2000) := 'XX OD Holds';
   ln_count                       PLS_INTEGER := 0;
   ln_hold_exists                 PLS_INTEGER := 0;
   
  PROCEDURE log_exceptions( p_error_code        IN  VARCHAR2
                           ,p_error_description IN  VARCHAR2
                           ,p_entity_ref        IN  VARCHAR2
                           ,p_entity_ref_id     IN  PLS_INTEGER
                          )
  -- +===================================================================+
  -- | Name  : Log_Exceptions                                            |
  -- | Rice Id      : E0202_OrderLineWorkflowModification                                              | 
  -- | Description: This procedure will be responsible to store all      | 
  -- |              the exceptions occured during the procees using      |
  -- |              global custom exception handling framework           |
  -- |                                                                   |
  -- | Parameters:  IN:                                                  |
  -- |     P_Error_Code        --Custom error code                       |
  -- | 	   P_Error_Description --Custom Error Description                |
  -- | 	   p_entity_ref        --'Hold id'                               |
  -- | 	   p_entity_ref_id     --'Value of the Hold Id'                  |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    =========================|
  -- |DRAFT 1A   07-MAY-2007   Nabarun Ghosh    Initial version          |
  -- +===================================================================+
  AS
   
   
   --Variables holding the values from the global exception framework package
   --------------------------------------------------------------------------
   x_errbuf                    VARCHAR2(1000);
   x_retcode                   VARCHAR2(40);
   
  BEGIN
  
   lrec_excepn_obj_type.p_exception_header  := g_exception_header;
   lrec_excepn_obj_type.p_track_code        := g_track_code      ;
   lrec_excepn_obj_type.p_solution_domain   := g_solution_domain ;
   lrec_excepn_obj_type.p_function          := g_function        ;
   
   lrec_excepn_obj_type.p_error_code        := p_error_code;
   lrec_excepn_obj_type.p_error_description := p_error_description;
   lrec_excepn_obj_type.p_entity_ref        := p_entity_ref;
   lrec_excepn_obj_type.p_entity_ref_id     := p_entity_ref_id;
   x_retcode                                := p_error_code;
   x_errbuf                                 := p_error_description;
   
   xx_om_global_exception_pkg.insert_exception(lrec_excepn_obj_type
                                              ,x_errbuf
                                              ,x_retcode
                                             );
  END log_exceptions;

  FUNCTION Compile_Rule_Function(
                                 p_hold_id  IN oe_hold_definitions.hold_id%TYPE 
                                )
  RETURN CHAR 
  -- +===================================================================+
  -- | Name  : Compile_Rule_Function                                     |
  -- | Rice Id : E0244                                                   |
  -- | Description: This function will compile the rule-function         |
  -- |              for the Hold Id passed as argument, these rule       |
  -- |              functions are developed and stored into the          |
  -- |              metadata table against each OD Hold, which will      |
  -- |              decide whether to apply or release holds.            |
  -- |                                                                   |
  -- | Parameters:  IN:                                                  |
  -- |     p_hold_id  --Id of the OD Specific Holds                      |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   19-APR-2007   Nabarun Ghosh    Initial draft version    |
  -- +===================================================================+
  IS

   --Variables holding the cursor field values
   --------------------------------------------
   lc_rule_function         VARCHAR2(4000)     ;
   lc_rule_function_name    VARCHAR2(30)       ;
   lc_hold_name             oe_hold_definitions.name%TYPE;
   
  BEGIN
   
   --Initializing the exception variables
   --------------------------------------
   lc_error_code         := NULL;
   lc_error_desc         := NULL;
   lc_entity_ref         := NULL;
   lc_entity_ref_id      := 0;
   lc_rule_function      := NULL;
   lc_rule_function_name := NULL;

   
   SELECT XXOHA.rule_function_name     rule_function_name
   INTO   lc_rule_function_name
   FROM  xx_om_od_hold_add_info        XXOHA
        ,oe_hold_definitions           OH
   WHERE OH.attribute6                = TO_CHAR(XXOHA.combination_id)
   AND   XXOHA.hold_type              =  'A'
   AND   OH.hold_id                   = p_hold_id;
   
   
   IF lc_rule_function_name IS NOT NULL THEN  
   
     --Obtain the rule-function script developed dynamically
     -------------------------------------------------------
     
     SELECT XX_OM_HOLDMGMTFRMWK_PKG.Generate_Rule_Function(p_hold_id)
     INTO   lc_rule_function
     FROM   DUAL;
     /*
     lc_rule_function := XX_OM_HOLDMGMTFRMWK_PKG.Generate_Rule_Function 
                                                 (
                                                   p_hold_id 
                                                 );
     */                                                 
     --Compile rule-function for the hold 
     -------------------------------------
     BEGIN
       EXECUTE IMMEDIATE lc_rule_function ;
       lc_rule_function := 'S';
     EXCEPTION
      WHEN OTHERS THEN
       
       lc_rule_function := 'E';
       
       FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       
       lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-02';
       lc_error_desc        := FND_MESSAGE.GET;
       lc_entity_ref        := 'Hold Id';
       lc_entity_ref_id     := p_hold_id;
     END;                                         
     
   ELSE
   
     --Log exceptions into global exception handling framework
     ---------------------------------------------------------
     lc_rule_function     := 'E';
     lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-05';
     lc_error_desc        := 'Rule-Function does not exists for the hold id';
     lc_entity_ref        := 'Hold Id';
     lc_entity_ref_id     := P_Hold_Id;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );
    END IF;
    RETURN lc_rule_function;
     
  EXCEPTION
   WHEN OTHERS THEN
     lc_rule_function     := 'U';
     lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-06';
     lc_error_desc        := 'Unexpected error:'||SUBSTR(SQLERRM,1,230);
     lc_entity_ref        := 'Hold Id';
     lc_entity_ref_id     := P_Hold_Id;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );
     RETURN lc_rule_function;     
  END Compile_Rule_Function; 

  PROCEDURE Apply_Hold(
                      p_hold_id             IN    Oe_Hold_Definitions.Hold_Id%TYPE
                     ,p_order_header_id     IN    Oe_Order_Headers_All.Header_Id%TYPE
                     ,p_order_line_id       IN    Oe_Order_Lines_All.Line_Id%TYPE
                     ,p_hold_apply_comments IN    VARCHAR2
                     ,x_return_status       OUT   NOCOPY VARCHAR2
                     ,x_msg_count           OUT   NOCOPY PLS_INTEGER 
                     ,x_msg_data            OUT   NOCOPY VARCHAR2
                     )
  -- +===================================================================+
  -- | Name  : Apply_Hold                                                |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                                   |
  -- | Description: This procedure will call the seeded API              |
  -- |              OE_HOLDS_PUB to apply any OD Specific Holds in       |
  -- |              manual bucket to order /return header or on          | 
  -- |              Line / return line.                                  |
  -- |                                                                   |
  -- | Parameters:  IN:                                                  |
  -- |     P_Order_Header_Id --Order / Return Header Id                  |
  -- | 	   P_Order_Line_Id   --Order / Return Line Id                    |
  -- | 	   p_hold_id         --Hold Id                                   |
  -- |     p_hold_apply_comments    --Hold apply comments                |
  -- |                                                                   |  
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   09-MAY-2007   Nabarun Ghosh    Initial draft version    |
  -- +===================================================================+
  IS  
  
   /* Extracting All the hold sources on the order header id */
   CURSOR cr_hold_source(i_hold_id      Oe_Hold_Definitions.Hold_Id%TYPE) 
   IS
   SELECT hold_source_id
     FROM oe_hold_sources
    WHERE hold_entity_code = 'O'
      AND hold_id   = i_hold_id
      AND released_flag    = 'N';
   
   --Variables required for processing Holds
   -----------------------------------------
   l_hdr_hold_source_rec        oe_holds_pvt.hold_source_rec_type;
   l_chk_hold_sources           PLS_INTEGER := 0;
   ln_hold_source_id            oe_hold_sources.hold_source_id%TYPE;
   
  BEGIN
  
   -------------------------------
   /*Apply Order Line Level Hold*/
   -------------------------------
   l_chk_hold_sources := 0;
   lc_return_status   := NULL;
   ln_msg_count       := NULL;
   lc_msg_data        := NULL; 
   
   lc_entity_ref        := 'Order Line Id';
   lc_entity_ref_id     := p_order_line_id;    
   
   SELECT COUNT(1)
   INTO l_chk_hold_sources
   FROM oe_hold_sources
   WHERE hold_entity_code = 'O'
   AND hold_id       = p_hold_id
   AND released_flag      = 'N';
       
   IF l_chk_hold_sources > 0 THEN
         
     OPEN cr_hold_source(
                         p_hold_id
                        );
     FETCH cr_hold_source
     INTO  ln_hold_source_id;        
     
     l_hdr_hold_source_rec.hold_source_id    := ln_hold_source_id;
             
   END IF;

   l_hdr_hold_source_rec.line_id           := p_order_line_id;
   l_hdr_hold_source_rec.hold_entity_code  := 'O';
   l_hdr_hold_source_rec.hold_id           := p_hold_id;
   l_hdr_hold_source_rec.hold_entity_id    := p_order_header_id;
   l_hdr_hold_source_rec.header_id         := p_order_header_id;
   l_hdr_hold_source_rec.hold_comment      := p_hold_apply_comments;

   OE_HOLDS_PUB.APPLY_HOLDS
                 (p_api_version      => api_ver_info
                 ,p_validation_level => FND_API.G_VALID_LEVEL_NONE
                 ,p_hold_source_rec  => l_hdr_hold_source_rec
                 ,x_return_status    => lc_return_status
                 ,x_msg_count        => ln_msg_count
                 ,x_msg_data         => lc_msg_data);
       
   IF TRIM(UPPER(lc_return_status)) <> TRIM(UPPER(FND_API.G_RET_STS_SUCCESS)) THEN
      x_return_status      := lc_return_status;
      x_msg_count          := ln_msg_count;
      x_msg_data           := lc_msg_data;
   ELSIF  TRIM(UPPER(lc_return_status)) = TRIM(UPPER(FND_API.G_RET_STS_SUCCESS)) THEN
      x_return_status      := lc_return_status;
      x_msg_count          := ln_msg_count;
      x_msg_data           := lc_msg_data;
   END IF;               
     
  EXCEPTION
    WHEN OTHERS THEN
      x_return_status := 'E';
      x_msg_count     :=  1 ;
      x_msg_data      :=  'Unexpected error in Apply_Hold due to: '||SUBSTR(SQLERRM,1,240);
      
      --Process to populate global exception handling framework
      ---------------------------------------------------------
      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-01';
      lc_error_desc        := FND_MESSAGE.GET;
      log_exceptions(lc_error_code             
                    ,lc_error_desc
                    ,lc_entity_ref       
                    ,lc_entity_ref_id    
                    );                   
  END Apply_Hold;

  PROCEDURE OD_Reserve
                      (
                       p_header_id          IN  oe_order_headers.header_id%TYPE,
                       p_line_id            IN  oe_order_lines.line_id%TYPE,
                       p_ship_from_org_id   IN  oe_order_lines.ship_from_org_id%TYPE,
                       p_inventory_item_id  IN  oe_order_lines.inventory_item_id%TYPE,
                       p_order_number       IN  oe_order_headers.order_number%TYPE,
                       p_order_quantity_uom IN  oe_order_lines.order_quantity_uom%TYPE,
                       p_ordered_quantity   IN  oe_order_lines.ordered_quantity%TYPE,
                       x_return_status      OUT VARCHAR2,
                       x_msg_count          OUT PLS_INTEGER ,
                       x_msg_data           OUT VARCHAR2,
                       x_quantity_reserved  OUT oe_order_lines.ordered_quantity%TYPE
                      )
  -- +===================================================================+
  -- | Name    : OD_Reserve                                              |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                                   |
  -- | Description: This procedure will be responsible to reserve        |
  -- |              sales order inventory on applying OD Holds.          |
  -- |                                                                   |  
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   09-MAY-2007   Nabarun Ghosh    Initial draft version    |
  -- +===================================================================+
  IS

   --Variables required for processing Stock reservation
   -----------------------------------------------------
   l_rsv                        inv_reservation_global.mtl_reservation_rec_type;
   l_rsv_id                     PLS_INTEGER;
   l_dummy_sn                   inv_reservation_global.serial_number_tbl_type;
   l_reserved_qty               PLS_INTEGER;
   ln_reservation_id            PLS_INTEGER;
   ln_sales_order_id            mtl_sales_orders.sales_order_id%TYPE;
  
  BEGIN
    
    lc_entity_ref        := 'Order Line Id';
    lc_entity_ref_id     := p_line_id;

    BEGIN
     SELECT MSO.sales_order_id sales_order_id
     INTO   ln_sales_order_id
     FROM   mtl_sales_orders   MSO 
     WHERE  MSO.segment1     = p_order_number;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       ln_sales_order_id := 0;

       --Process to populate global exception handling framework
       ---------------------------------------------------------
       FND_MESSAGE.SET_NAME('XXOM','ODP_OM_ORDLINWFMOD_NULL_SO_ID');
       lc_error_code        := 'ODP_OM_ORDLINWFMOD_NULL_SO_ID';
       lc_error_desc        := FND_MESSAGE.GET;
       
     WHEN OTHERS THEN   
       ln_sales_order_id := 0;

       --Process to populate global exception handling framework
       ---------------------------------------------------------
       FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-1.1';
       lc_error_desc        := FND_MESSAGE.GET;
    END;     
    
    --Logging error in custom global exception handling framework
    -------------------------------------------------------------
    IF ln_sales_order_id = 0 THEN
     log_exceptions(lc_error_code             
                   ,lc_error_desc          
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );
    END IF;
    
    --Validate whether reservation already exists or not
    ----------------------------------------------------
    ln_count := 0;
    SELECT COUNT(1)
    INTO   ln_count
    FROM   mtl_reservations    MR
          ,mfg_lookups         ML 
          ,mtl_sales_orders    MSO 
    WHERE MR.demand_source_header_id = MSO.sales_order_id
    AND   MSO.segment1               = p_order_number
    AND   MR.demand_source_line_id   = p_line_id 
    AND   MR.organization_id         = p_ship_from_org_id
    AND   MR.inventory_item_id       = p_inventory_item_id
    AND   MR.demand_source_type_id   = ML.lookup_code
    AND   ML.lookup_type             = 'MTL_SUPPLY_DEMAND_SOURCE_TYPE'
    AND   ML.lookup_code in (2,9);
    
    IF ln_count = 0 THEN
      
      --Preparing the reservation records 
      -----------------------------------
      l_rsv.reservation_id               := ln_reservation_id; 
      l_rsv.requirement_date             := Sysdate;              
      l_rsv.organization_id              := p_ship_from_org_id;
      l_rsv.inventory_item_id            := p_inventory_item_id;
      l_rsv.demand_source_type_id        := inv_reservation_global.g_source_type_oe;
      l_rsv.demand_source_name           := 'XX SO Reserv';
      l_rsv.demand_source_header_id      := ln_sales_order_id;
      l_rsv.demand_source_line_id        := p_line_id; 
      l_rsv.demand_source_delivery       := NULL;
      l_rsv.primary_uom_code             := p_order_quantity_uom;
      l_rsv.primary_uom_id               := NULL;
      l_rsv.reservation_uom_code         := NULL;
      l_rsv.reservation_uom_id           := NULL;
      l_rsv.reservation_quantity         := NULL;
      l_rsv.primary_reservation_quantity := p_ordered_quantity;
      l_rsv.autodetail_group_id          := NULL;
      l_rsv.external_source_code         := NULL;
      l_rsv.external_source_line_id      := NULL;
      l_rsv.supply_source_type_id        := inv_reservation_global.g_source_type_inv;
      l_rsv.supply_source_header_id      := NULL;
      l_rsv.supply_source_line_id        := NULL;
      l_rsv.supply_source_name           := NULL;
      l_rsv.supply_source_line_detail    := NULL;
      l_rsv.revision                     := NULL;
      l_rsv.subinventory_code            := NULL;
      l_rsv.subinventory_id              := NULL;
      l_rsv.locator_id                   := NULL;
      l_rsv.lot_number                   := NULL;
      l_rsv.lot_number_id                := NULL;
      l_rsv.pick_slip_number             := NULL;
      l_rsv.lpn_id                       := NULL;
      l_rsv.attribute_category           := NULL;
      l_rsv.attribute1                   := NULL;
      l_rsv.attribute2                   := NULL;
      l_rsv.attribute3                   := NULL;
      l_rsv.attribute4                   := NULL;
      l_rsv.attribute5                   := NULL;
      l_rsv.attribute6                   := NULL;
      l_rsv.attribute7                   := NULL;
      l_rsv.attribute8                   := NULL;
      l_rsv.attribute9                   := NULL;
      l_rsv.attribute10                  := NULL;
      l_rsv.attribute11                  := NULL;
      l_rsv.attribute12                  := NULL;
      l_rsv.attribute13                  := NULL;
      l_rsv.attribute14                  := NULL;
      l_rsv.attribute15                  := NULL;
      l_rsv.ship_ready_flag              := NULL;
      l_rsv.staged_flag                  := NULL;
      
      
      --Calling the seeded API to create stock reservations
      -----------------------------------------------------
      INV_RESERVATION_PUB.CREATE_RESERVATION
         (
           p_api_version_number        => api_ver_info
         , p_init_msg_lst              => FND_API.G_TRUE
         , x_return_status             => lc_return_status
         , x_msg_count                 => ln_msg_count
         , x_msg_data                  => lc_msg_data
         , p_rsv_rec                   => l_rsv
         , p_serial_number             => l_dummy_sn
         , x_serial_number             => l_dummy_sn
         , p_partial_reservation_flag  => FND_API.G_TRUE
         , p_force_reservation_flag    => FND_API.G_FALSE
         , p_validation_flag           => FND_API.G_TRUE
         , x_quantity_reserved         => l_reserved_qty
         , x_reservation_id            => l_rsv_id
         );
         
         CASE 
         WHEN lc_return_status = FND_API.G_RET_STS_SUCCESS THEN
            x_return_status  := lc_return_status;
            x_msg_count      := ln_msg_count    ;
            x_msg_data       := lc_msg_data     ;
         ELSE
            x_return_status  := lc_return_status;
            x_msg_count      := ln_msg_count    ;
            x_msg_data       := lc_msg_data     ;
         END CASE;
    ELSE
      --If stock reservation exists
      -----------------------------
      x_return_status  := 'E';
      x_msg_count      := 0;
      x_msg_data       := 'Reservation already exists..';
    END IF; --End of check for existing reservation
  
  EXCEPTION
    WHEN OTHERS THEN
      x_return_status := 'E';
      x_msg_count     :=  1 ;
      x_msg_data      :=  'Unexpected error in OD_Reserve due to: '||SUBSTR(SQLERRM,1,240);

      --Process to populate global exception handling framework
      ---------------------------------------------------------
      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      
      lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-02';
      lc_error_desc        := FND_MESSAGE.GET;
      log_exceptions(lc_error_code             
                    ,lc_error_desc
                    ,lc_entity_ref       
                    ,lc_entity_ref_id    
                    );                   
  END OD_Reserve;                      

  PROCEDURE Apply_Hold_Before_Booking
                                    (
                                     i_itemtype     IN  VARCHAR2,
                                     i_itemkey      IN  VARCHAR2,
                                     i_actid        IN  PLS_INTEGER,
                                     i_funcmode     IN  VARCHAR2,
                                     o_result       OUT NOCOPY VARCHAR2
                                    )
  -- +===================================================================+
  -- | Name    : Apply_Hold_Before_Booking                               |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                                   |
  -- | Description: This procedure will be called from the order line wf |
  -- |              process, this will be applying any OD specific holds |
  -- |              on the SO line before booking process.               |
  -- |                                                                   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   07-MAY-2007   Nabarun Ghosh    Initial draft version    |
  -- +===================================================================+
  IS
   
   --Declaring local variables
   ---------------------------
   ln_line_id              Oe_Order_Lines.Line_Id%TYPE;
   ln_hold_exists          PLS_INTEGER := 0;
   ln_quantity_reserved    Oe_Order_Lines.Ordered_Quantity%TYPE;
   lx_hold_id              Oe_Hold_Definitions.Hold_Id%TYPE;
   lx_header_id            Oe_Order_Lines.Header_Id%TYPE;
   lx_line_id              Oe_Order_Lines.Line_Id%TYPE; 
   
   --Variables populating the workflow attributes
   ----------------------------------------------
   lc_notify_to            xx_om_od_hold_add_info.authorities_to_notify%TYPE;
   lc_order_line_details   LONG;
   lc_notification_msg     VARCHAR2(4000);
   lc_entity_name          Oe_Hold_Definitions.name%TYPE; 
   lc_entity_id            PLS_INTEGER;
   ln_pool_id              PLS_INTEGER;
   ln_check_hold_function  PLS_INTEGER;
   
  BEGIN
   IF (i_funcmode = 'RUN') THEN
     ----------------------
     -- Set Apps Context --
     ----------------------
     ln_user_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'USER_ID');
     ln_resp_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'RESPONSIBILITY_ID');
     ln_appl_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'APPLICATION_ID');
     fnd_global.apps_initialize(user_id => ln_user_id, resp_id => ln_resp_id, resp_appl_id => ln_appl_id);  
     
     lc_entity_ref     := NULL;
     lc_entity_ref_id  := 0;
     ln_line_id        := NULL;
     
     --Obtain the SO line id
     -----------------------
     ln_line_id           := TO_NUMBER(i_itemkey);
     lc_entity_ref        := 'SO Line Id';
     lc_entity_ref_id     := ln_line_id;

     --Obtain the SO header details
     ------------------------------
     OPEN  lcu_get_so_info(
                           ln_line_id
                          ) ;
     FETCH lcu_get_so_info INTO cur_get_so_info;
     CLOSE lcu_get_so_info; 
     
       --Initializing the exception variables
       --------------------------------------
       lc_error_code     := NULL;
       lc_error_desc     := NULL;
       
       --Loop through the metadata table to get all hold additional informations
       --------------------------------------------------------------------------
       OPEN lcu_additional_info(
                               'B'
                              ); 
       LOOP
        FETCH lcu_additional_info INTO  cur_additional_info;
        EXIT WHEN lcu_additional_info%NOTFOUND;
             
          SELECT COUNT(1)
          INTO   ln_check_hold_function
          FROM  all_objects 
          WHERE object_name  = UPPER(cur_additional_info.rule_function_name)
          AND   status       = 'VALID';
             
          IF ln_check_hold_function = 0 THEN
             lc_rule_function_result := NULL;
           
             --Compile the rule function
             ---------------------------
             -- lc_rule_function_result := Compile_Rule_Function(cur_additional_info.hold_id);
             SELECT Compile_Rule_Function(cur_additional_info.hold_id)
             INTO   lc_rule_function_result
             FROM DUAL;
          ELSE
           lc_rule_function_result := 'S';
          END IF;
             
          IF lc_rule_function_result <> 'S' THEN
           --Process to populate global exception handling framework
           ---------------------------------------------------------
           FND_MESSAGE.SET_NAME('XXOM','ODP_OM_ORDLINWFMOD_COMPRULFUNC'); -- Message has to create
           lc_error_code        := 'ODP_OM_ORDLINWFMOD_COMPRULFUNC-01';
           lc_error_desc        := FND_MESSAGE.GET;
           log_exceptions(lc_error_code             
                         ,lc_error_desc
                         ,lc_entity_ref       
                         ,lc_entity_ref_id    
                         );                   
           lc_rule_function_result := 'E';   
          END IF;   
             
          IF  lc_rule_function_result = 'S' THEN
             
             --------------------------------------------------------------- 
             /* Execute the rule-function to get the result for this hold */
             ---------------------------------------------------------------
             
             CASE 
             WHEN UPPER(cur_additional_info.name) = 'OD HELD FOR COMMENTS' THEN
	         lc_rule_function_result := NULL;
	         lx_hold_id              := NULL;
	         lx_header_id            := NULL;
	         lx_line_id              := NULL;
	         
	         lx_hold_id   := cur_additional_info.hold_id;
	         lx_header_id := cur_get_so_info.header_id;
	         lx_line_id   := NVL(ln_line_id,0);

  	         EXECUTE IMMEDIATE 'SELECT '||cur_additional_info.rule_function_name||'('
   	                                                           ||''''||'APPLY'||''''
	                                                           ||','||lx_hold_id    --cur_additional_info.hold_id
	                                                           ||','||lx_header_id --cur_get_so_info.header_id
	                                                           ||','||lx_line_id  --NVL(ln_line_id,0)
	                                                           ||','||''''||cur_additional_info.apply_to_order_or_line||''''
	                                                           ||')'
	                                    ||' FROM DUAL' INTO lc_rule_function_result; 
	     ELSE
	         lc_rule_function_result := NULL;
	         lx_hold_id              := NULL;
	         lx_header_id            := NULL;
	         lx_line_id              := NULL;
	         
	         lx_hold_id   := cur_additional_info.hold_id;
	         lx_header_id := cur_get_so_info.header_id;
	         lx_line_id   := NVL(ln_line_id,0);
	         
	         EXECUTE IMMEDIATE 'SELECT '||cur_additional_info.rule_function_name||'('
	                                                           ||''''||'APPLY'||''''
	                                                           ||','||lx_hold_id --cur_additional_info.hold_id
	                                                           ||','||lx_header_id --cur_get_so_info.header_id
	                                                           ||','||lx_line_id --NVL(ln_line_id,0)
	                                                           ||')'
	                                    ||' FROM DUAL' INTO lc_rule_function_result; 
	     END CASE;
	     
  	  END IF;   
  	  
	     --Validating whether any unexpected errors occured while executing rule-function
	     --------------------------------------------------------------------------------
	     IF NVL(lc_rule_function_result,'E') = FND_API.G_RET_STS_ERROR THEN
	       
	       --Logging error in custom global exception handling framework
	       -------------------------------------------------------------
	       FND_MESSAGE.SET_NAME('XXOM','ODP_OM_ORDLINWFMOD_EXCRULFUNC');
	       lc_error_code        := 'ODP_OM_ORDLINWFMOD_EXCRULFUNC-01';
	       lc_error_desc        := FND_MESSAGE.GET;
	       log_exceptions(lc_error_code             
	                     ,lc_error_desc
	                     ,lc_entity_ref       
	                     ,lc_entity_ref_id    
	                     );                   
	                     
	       --Logging error in standard wf error
	       ------------------------------------
	       WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,
	                       'Unexpected error in executing rule-function for the line id:'||cur_get_so_info.line_id);
	       o_result := 'ERROR:';
	       APP_EXCEPTION.RAISE_EXCEPTION;
    
	     ELSE
	       --OD holds should be applied 
       	       ---------------------------- 
	       IF lc_rule_function_result = 'Y' THEN 
  	         
  	         -------------------------------------------------
  	         /* Process-I: Processing for applying OD Holds */
  	         -------------------------------------------------
  	         --Validating if any hold exists or not
  	         --------------------------------------
  	         ln_hold_exists := 0;
  	         
  	         SELECT COUNT(1)
	         INTO   ln_hold_exists
	         FROM   oe_order_holds                OH
	               ,oe_hold_sources               OHS
	               ,xx_om_od_hold_add_info        XOOHA
	               ,oe_hold_definitions           OHD 
	         WHERE  OH.header_id                 = cur_get_so_info.header_id
	         AND    OH.line_id                   = cur_get_so_info.line_id
	         AND    OH.hold_release_id IS NULL   
	         AND    OH.released_flag             = 'N'
	         AND    OH.hold_source_id            = OHS.hold_source_id
	         AND    OHS.hold_id                  = OHD.hold_id 
	         AND    OHD.attribute6               = TO_CHAR(XOOHA.combination_id)
	         AND    XOOHA.hold_type              = 'A'
	         AND    XOOHA.apply_to_order_or_line = 'L';
	         
	         IF ln_hold_exists = 0 THEN

                   --------------------------------------------------------
	           --Call the seeded API to apply OD Hold on the line level
	           --------------------------------------------------------
	           lc_hold_apply_comments := lc_hold_apply_comments||': '||cur_additional_info.name||' being applied to the line: '||ln_line_id;

	           Apply_Hold(
	                    p_hold_id             => cur_additional_info.hold_id
	                   ,p_order_header_id     => cur_get_so_info.header_id
	                   ,p_order_line_id       => ln_line_id
	                   ,p_hold_apply_comments => lc_hold_apply_comments
	                   ,x_return_status       => lc_return_status
	                   ,x_msg_count           => ln_msg_count
	                   ,x_msg_data            => lc_msg_data
	                   );

	           IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN   
	       	     
	       	     -------------------------------------------------------------------
	       	     /* Process-II: Processing for Sales Order Inventory Reservations */
	       	     -------------------------------------------------------------------
	       	     IF NVL(cur_additional_info.stock_reserved,0) > 0 THEN
	       	       lc_return_status := NULL;
	       	       lc_msg_data      := NULL;
	       	       ln_msg_count     := 0   ;

	       	       OD_Reserve 
	       	                 (
	       	                  p_header_id          =>cur_get_so_info.header_id,
	       	                  p_line_id            =>ln_line_id,
	       	                  p_ship_from_org_id   =>cur_get_so_info.ship_from_org_id,
	       	                  p_inventory_item_id  =>cur_get_so_info.inventory_item_id,
	       	                  p_order_number       =>cur_get_so_info.order_number,
	       	                  p_order_quantity_uom =>cur_get_so_info.order_quantity_uom,
	       	                  p_ordered_quantity   =>cur_get_so_info.ordered_quantity,
	       	                  x_return_status      =>lc_return_status,
	       	                  x_msg_count          =>ln_msg_count,
	       	                  x_msg_data           =>lc_msg_data,
	       	                  x_quantity_reserved  =>ln_quantity_reserved
	       	                 );
	       	          
	       	        
	       	        IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
	       	         
	       	         FND_MESSAGE.SET_NAME('XXOM','ODP_OM_ORDLINWFMOD_SO_RESRVN');
	       	         
	       	         IF NVL(ln_msg_count,0) = 1 THEN
	       	            --Logging error in global exception framework
	       	            ---------------------------------------------
	       	            lc_error_code        := 'ODP_OM_ORDLINWFMOD_SO_RESRVN-01';
	       	            lc_error_desc        := FND_MESSAGE.GET;
	       	            log_exceptions(lc_error_code             
	       	                          ,lc_error_desc
	       	                          ,lc_entity_ref       
	       	                          ,lc_entity_ref_id    
	       	                          );  
	       	                          
	       	            --Logging error in standard wf error
	       	            ------------------------------------
	       	            WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,              
	       	                            'Failed to reserve the so inventory on the line id: '||ln_line_id||' due to '||lc_msg_data);
	       	                             
	       	         ELSE
	       	           FOR l_index IN 1..NVL(ln_msg_count,0) 
	       	           LOOP
	       	            --Logging error in global exception framework
	       	            ---------------------------------------------
	       	            lc_error_code        := 'ODP_OM_ORDLINWFMOD_SO_RESRVN-01';
	       	            lc_error_desc        := FND_MESSAGE.GET;
	       	            log_exceptions(lc_error_code             
	       	                          ,lc_error_desc
	       	                          ,lc_entity_ref       
	       	                          ,lc_entity_ref_id    
	       	                          );  
	       	            --Logging error in standard wf error
	       	            ------------------------------------
	       	            WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,              
	       	                            'Failed to reserve the so inventory on the line id: '||ln_line_id||' due to '||lc_msg_data);
	       	       
	       	           END LOOP;
	       	         END IF;
	       	        END IF; --End of return status validation for un-reservation
	       	     END IF;   -- Stock reservation info from Metadata table 
	       	     --------------------------------------------------------------------------------------------
	       	     /* Process-III: Send this order with hold details to pool table < MD070 of POOL Framework>  */
	       	     --------------------------------------------------------------------------------------------
	       	     /*
	       	     IF cur_additional_info.send_to_pool = 'Y' THEN
	       	     
	       	       --Obtain the Pool Id based on the Specific Hold
	       	       -----------------------------------------------
	       	       IF cur_additional_info.name LIKE 'OD%CREDIT%HOLD' THEN
	       	          ln_pool_name := 'Account Billing Pool';
	       	       ELSIF cur_additional_info.name LIKE 'OD%CREDIT%CARD%FAILURE%' THEN
	       	          ln_pool_name := 'Credit Card Auth Failure  Poo';
	       	       ELSIF cur_additional_info.name LIKE 'OD%FRAUD%HOLD' THEN
	       	          ln_pool_name := 'Fraud Pool';
	       	       ELSIF cur_additional_info.name LIKE 'OD%AMAZON%HOLD' THEN
	       	          ln_pool_name := 'Amazon Pool';
	       	       ELSIF cur_additional_info.name LIKE 'OD%LARGE%ORDER%HOLD' THEN
	       	          ln_pool_name := 'Large Order Pool';
	       	       ELSIF cur_additional_info.name LIKE 'OD%FURNITURE%HOLD' THEN
	       	          ln_pool_name := 'Furniture Pool';
	       	       ELSIF cur_additional_info.name LIKE 'OD%HIGH%RETURN%PROB%PROD%HOLD' THEN
	       	          ln_pool_name := 'High Returns/Problem Product Pool';   
	       	       END IF;   
	       	       
	       	       SELECT pool_id
	       	       INTO   ln_pool_id
	       	       FROM   xx_od_pool_names  POOL
	       	       WHERE  POOL.pool_name = ln_pool_name;
	       	       
	       	       IF lc_apply_to_order_or_line = 'O' THEN
	       	          lc_entity_name := 'ORDER';
	       	          lc_entity_id   := cur_get_so_info.header_id; 
	       	       ELSIF lc_apply_to_order_or_line = 'L' THEN
	       	          lc_entity_name := 'LINE';
	       	          lc_entity_id   := ln_line_id;
	       	       END IF;
	       	       
	       	       --Insert Into Pool 
	       	       ------------------
	       	       --INSERT INTO xx_od_pool_records (
	       	                                     pool_id        --This is the Pool Id from which the API is invoked
	       	                                    ,entity_name    --This should indicate whether the action needs to be performed on the Order or Line
	       	     			            ,entity_id      --This can be either the Order Header Id or Line Id
	       	     			            ,reviewer       --This is the User Id of the CSR who is invoking the Action
                     			            ,priority       --Priority of the Pool record. This column will be used based on the needs of the Pool
	       	     			            ,holdover_code  --Hold Over Code that indicates the action performed by the CSR on the record
	       	     			       )
	       	     			VALUES (
	       	                                     ln_pool_id     --TBD 
	       	                                    ,lc_entity_name
	       	                                    ,lc_entity_id    
	       	                                    ,ln_user_id     
	       	                                    ,cur_additional_info.priority    --TBD
	       	                                    ,cur_additional_info.name        --Hold Name
	       	     			       );
	       	     END IF;  --End of validation Pool Records
	       	     */
	           ELSE
                     
                     FND_MESSAGE.SET_NAME('XXOM','ODP_OM_ORDLINWFMOD_APPLY_HOLD');
	             IF ln_msg_count = 1 THEN
	                --Logging errors in custom global exception framework
	                -----------------------------------------------------
                 	lc_error_code        := 'ODP_OM_ORDLINWFMOD_APPLY_HOLD-01';
	                lc_error_desc        := FND_MESSAGE.GET;
	                log_exceptions(lc_error_code             
	                              ,lc_error_desc
	                              ,lc_entity_ref       
	                              ,lc_entity_ref_id    
	                             );
	                            
                       --Logging error in standard wf error
		       ------------------------------------
		       WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,
		                       'Failed to apply OD hold before booking process on the line id: '||cur_get_so_info.line_id||' due to '||lc_msg_data);
		                       
	            ELSE
	               FOR l_index IN 1..ln_msg_count 
	               LOOP
	                 --Logging errors in custom global exception framework
	                 -----------------------------------------------------
                         lc_error_code        := 'ODP_OM_ORDLINWFMOD_APPLY_HOLD-01';
                         lc_error_desc        := FND_MESSAGE.GET;
                         log_exceptions(lc_error_code             
                                       ,lc_error_desc
                                       ,lc_entity_ref       
                                       ,lc_entity_ref_id    
                                      );
                         --Logging error in standard wf error
		         ------------------------------------
		         WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,
		                         'Failed to apply OD hold before booking process on the line id: '||cur_get_so_info.line_id||' due to '||lc_msg_data);
   
	               END LOOP;
	            END IF; 
	           END IF; --Return status validation
    	         END IF; --If hold exists on line level
               END IF; --If OD Holds should be applied
       	     END IF; --End of validaion for unexpected error while executing rule-funtion
       	     
        --END IF; --End of validating unexpected error occured while compiling rule-fintion
       END LOOP; -- End of loop for metadata table
       CLOSE lcu_additional_info;
       
       ln_hold_exists := 0;
       
       SELECT COUNT(1)
       INTO   ln_hold_exists
       FROM   oe_order_holds                OH
             ,oe_hold_sources               OHS
             ,xx_om_od_hold_add_info        XOOHA
             ,oe_hold_definitions           OHD 
       WHERE  OH.header_id                 = cur_get_so_info.header_id
       AND    OH.line_id                   = ln_line_id
       AND    OH.hold_release_id IS NULL   
       AND    OH.released_flag             = 'N'
       AND    OH.hold_source_id            = OHS.hold_source_id
       AND    OHS.hold_id                  = OHD.hold_id 
       AND    OHD.attribute6               = TO_CHAR(XOOHA.combination_id)
       AND    XOOHA.hold_type              = 'A'
       AND    XOOHA.apply_to_order_or_line = 'L'
       AND    XOOHA.order_booking_status   = 'B' ;
       
       IF ln_hold_exists > 0 THEN
          o_result := 'COMPLETE:Y';
       ELSE   
          o_result := 'COMPLETE:N';
       END IF;   
       RETURN;
       
   ELSIF (i_funcmode = 'CANCEL') THEN
        o_result := 'COMPLETE:N';
        RETURN;
   END IF;
  
  EXCEPTION WHEN OTHERS THEN
     --Process to populate global exception handling framework
     ---------------------------------------------------------
     FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     
     lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-03';
     lc_error_desc        := FND_MESSAGE.GET;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );                   

     wf_core.context('xx_wfl_omordlinwfmod_pkg','Apply_Hold_Before_Booking',i_itemtype,i_itemkey,
                    'Others: '||SQLERRM);
     o_result := wf_engine.eng_error;
     APP_EXCEPTION.RAISE_EXCEPTION;

  END Apply_Hold_Before_Booking; 
  
  PROCEDURE Is_Hold_Applied_Bef_Booking
                                    (
                                     i_itemtype     IN  VARCHAR2,
                                     i_itemkey      IN  VARCHAR2,
                                     i_actid        IN  PLS_INTEGER,
                                     i_funcmode     IN  VARCHAR2,
                                     o_result       OUT NOCOPY VARCHAR2
                                    )
  -- +===================================================================+
  -- | Name    : Is_Hold_Applied_Bef_Booking                             |
  -- | Rice Id : E0202_OrderLineWorkflowModification                     |
  -- | Description: This procedure will validate any OD Specific Holds   |
  -- |              are applied on the line or not.                      |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   24-JUL-2007   Nabarun Ghosh    Initial draft version    |
  -- +===================================================================+
  IS

   --Declaring local variables
   ---------------------------
   ln_line_id              Oe_Order_Lines.Line_Id%TYPE;
   lc_hold_name            Oe_Hold_Definitions.Name%TYPE;
   ln_wt_time              PLS_INTEGER;
   ln_count                PLS_INTEGER := 0;
   ln_hold_exists          PLS_INTEGER := 0;
   
  BEGIN
  
   IF (i_funcmode = 'RUN') THEN
     ----------------------
     -- Set Apps Context --
     ----------------------
     ln_user_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'USER_ID');
     ln_resp_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'RESPONSIBILITY_ID');
     ln_appl_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'APPLICATION_ID');
     fnd_global.apps_initialize(user_id => ln_user_id, resp_id => ln_resp_id, resp_appl_id => ln_appl_id);  
     
     lc_entity_ref        := NULL;
     lc_entity_ref_id     := NULL;
     ln_line_id           := NULL;
     
     --Obtain the SO line id
     -----------------------
     ln_line_id           := TO_NUMBER(i_itemkey);
     lc_entity_ref        := 'Order Line Id';
     lc_entity_ref_id     := ln_line_id;
     
       OPEN  lcu_get_so_info(
                             ln_line_id
                            ) ;
       FETCH lcu_get_so_info INTO cur_get_so_info;
       CLOSE lcu_get_so_info;
       
       SELECT COUNT(1)
       INTO   ln_hold_exists
       FROM   oe_order_holds                OH
             ,oe_hold_sources               OHS
             ,xx_om_od_hold_add_info        XOOHA
             ,oe_hold_definitions           OHD 
       WHERE  OH.header_id                 = cur_get_so_info.header_id
       AND    OH.line_id                   = ln_line_id
       AND    OH.hold_release_id IS NULL   
       AND    OH.released_flag             = 'N'
       AND    OH.hold_source_id            = OHS.hold_source_id
       AND    OHS.hold_id                  = OHD.hold_id 
       AND    OHD.attribute6               = TO_CHAR(XOOHA.combination_id)
       AND    XOOHA.hold_type              = 'A'
       AND    XOOHA.apply_to_order_or_line = 'L'
       AND    XOOHA.order_booking_status   = 'B' ;
       
       IF ln_hold_exists > 0 THEN
          o_result := 'COMPLETE:Y';
       ELSE
          o_result := 'COMPLETE:N';
       END IF; --End of If Hold Exists   
       
       RETURN;
  
   ELSIF (i_funcmode = 'CANCEL') THEN
     o_result := 'COMPLETE: ';
     RETURN;
   END IF;
  
  EXCEPTION WHEN OTHERS THEN
     
     --Process to populate global exception handling framework
     ---------------------------------------------------------
     FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     
     lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-04';
     lc_error_desc        := FND_MESSAGE.GET;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );                   
     
     wf_core.context('xx_wfl_omordlinwfmod_pkg','Is_Hold_Applied_Bef_Booking',i_itemtype,i_itemkey,
                    'Unknown Error: '||SQLERRM);
     o_result := wf_engine.eng_error;
     APP_EXCEPTION.RAISE_EXCEPTION;
     
  END Is_Hold_Applied_Bef_Booking;
  
  PROCEDURE Is_Wait_For_Return_Hold
                                    (
                                     i_itemtype     IN  VARCHAR2,
                                     i_itemkey      IN  VARCHAR2,
                                     i_actid        IN  PLS_INTEGER,
                                     i_funcmode     IN  VARCHAR2,
                                     o_result       OUT NOCOPY VARCHAR2
                                    )
  -- +===================================================================+
  -- | Name    : Is_Wait_For_Return_Hold                                 |
  -- | Rice Id : E0202_OrderLineWorkflowModification                     |
  -- | Description: This procedure will be used to check OD Wait For     |
  -- |              Return Hold.                                         |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   24-JUL-2007   Nabarun Ghosh    Initial draft version    |
  -- +===================================================================+
  IS

   --Declaring local variables
   ---------------------------
   ln_line_id              Oe_Order_Lines.Line_Id%TYPE;
   lc_hold_name            Oe_Hold_Definitions.Name%TYPE;
   ln_wt_time              PLS_INTEGER;
   ln_count                PLS_INTEGER := 0;
   ln_hold_exists          PLS_INTEGER := 0;
   ln_wait_for_return      PLS_INTEGER := 0;
   ln_rma_line_id          PLS_INTEGER := 0;
   ln_rma_receipt          PLS_INTEGER := 0;
   
  BEGIN
  
   IF (i_funcmode = 'RUN') THEN
     ----------------------
     -- Set Apps Context --
     ----------------------
     ln_user_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'USER_ID');
     ln_resp_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'RESPONSIBILITY_ID');
     ln_appl_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'APPLICATION_ID');
     fnd_global.apps_initialize(user_id => ln_user_id, resp_id => ln_resp_id, resp_appl_id => ln_appl_id);  
     
     lc_entity_ref        := NULL;
     lc_entity_ref_id     := NULL;
     ln_line_id           := NULL;
     
     --Obtain the SO line id
     -----------------------
     ln_line_id           := TO_NUMBER(i_itemkey);
     lc_entity_ref        := 'Order Line Id';
     lc_entity_ref_id     := ln_line_id;
     
       OPEN  lcu_get_so_info(
                             ln_line_id
                            ) ;
       FETCH lcu_get_so_info INTO cur_get_so_info;
       CLOSE lcu_get_so_info;
       
          SELECT COUNT(1)
          INTO   ln_wait_for_return
          FROM   oe_order_holds             OH
                ,oe_hold_sources            OHS
                ,xx_om_od_hold_add_info     XOOHA
                ,oe_hold_definitions        OHD 
          WHERE  OH.header_id                     = cur_get_so_info.header_id
          AND    OH.line_id                       = ln_line_id
          AND    OH.hold_release_id IS NULL   
          AND    OH.released_flag                 = 'N'
          AND    OH.hold_source_id                = OHS.hold_source_id
          AND    OHS.hold_id                      = OHD.hold_id 
          AND    OHD.attribute6                   = TO_CHAR(XOOHA.combination_id)
          AND    XOOHA.hold_type                  = 'A'
          AND    XOOHA.apply_to_order_or_line     = 'L'
          AND    XOOHA.order_booking_status       = 'B'
          AND    OHD.name = 'OD WAITING FOR RETURN';  
          
          IF ln_wait_for_return > 0 THEN
            BEGIN
            
              SELECT NVL(KFF.ret_ref_line_id,0)
              INTO ln_rma_line_id
              FROM xx_om_line_attributes_all KFF
                  ,oe_order_lines L
              WHERE KFF.line_id = L.line_id   
              AND L.line_id     = ln_line_id
              AND L.header_id   = cur_get_so_info.header_id;
              
            EXCEPTION
             WHEN NO_DATA_FOUND THEN
              ln_rma_line_id:=0;
             WHEN OTHERS THEN
              ln_rma_line_id:=0;
            END;
            
            SELECT COUNT(1)
            INTO ln_rma_receipt
            FROM rcv_shipment_headers RSH
                ,rcv_shipment_lines   RSL
                ,oe_order_lines       OOL
                ,oe_order_headers     OOH
            WHERE OOL.line_id             = ln_rma_line_id 
            AND RSL.oe_order_header_id    = OOL.header_id
            AND RSL.oe_order_line_id      = OOL.line_id
            AND OOL.header_id             = OOH.header_id
            AND RSH.shipment_header_id    = RSL.shipment_header_id
            AND NVL(RSH.customer_id,-99)  = NVL(OOH.sold_to_org_id,-99)
            AND RSH.receipt_num IS NOT NULL
            AND RSH.receipt_source_code     = 'CUSTOMER'
            AND NVL(OOL.ordered_quantity,0) = (SELECT SUM(NVL(X.quantity_received,0))
                                               FROM  rcv_shipment_lines X
                                               WHERE RSL.shipment_header_id = RSH.shipment_header_id
                                              );
            
            IF NVL(ln_rma_receipt,0) > 0 THEN
              o_result := 'COMPLETE:Y';
            ELSE
              o_result := 'COMPLETE:N';
              ln_wt_time  := 2; 
              ln_wt_time  := (ln_wt_time / 24)/60;
              wf_engine.SetItemAttrNumber(itemtype => i_itemtype,
                                          itemkey  => i_itemkey,
                                          aname    => 'XX_OD_WAIT_TIME',
                                          avalue   => ln_wt_time);
            END IF;
          ELSE
            o_result := 'COMPLETE:N';
            ln_wt_time  := 2; 
            ln_wt_time  := (ln_wt_time / 24)/60;
            wf_engine.SetItemAttrNumber(itemtype => i_itemtype,
                                        itemkey  => i_itemkey,
                                        aname    => 'XX_OD_WAIT_TIME',
                                        avalue   => ln_wt_time);
          END IF; --End of Wait For return chk
          
       RETURN;
  
   ELSIF (i_funcmode = 'CANCEL') THEN
     o_result := 'COMPLETE: ';
     RETURN;
   END IF;
  
  EXCEPTION WHEN OTHERS THEN
     
     --Process to populate global exception handling framework
     ---------------------------------------------------------
     FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     
     lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-04';
     lc_error_desc        := FND_MESSAGE.GET;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );                   
     
     wf_core.context('xx_wfl_omordlinwfmod_pkg','Is_Wait_For_Return_Hold',i_itemtype,i_itemkey,
                    'Unknown Error: '||SQLERRM);
     o_result := wf_engine.eng_error;
     APP_EXCEPTION.RAISE_EXCEPTION;
     
  END Is_Wait_For_Return_Hold;  
  
  PROCEDURE Unreserve_Before_Booking
                                    (
                                     i_itemtype     IN  VARCHAR2,
                                     i_itemkey      IN  VARCHAR2,
                                     i_actid        IN  PLS_INTEGER,
                                     i_funcmode     IN  VARCHAR2,
                                     o_result       OUT NOCOPY VARCHAR2
                                    )
  -- +===================================================================+
  -- | Name    : Unreserve_Before_Booking                                |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                                   |
  -- | Description: This procedure will be responsible for relieving any |
  -- |              sales order inventory being reserved on applying OD  |
  -- |              Holds before the booking process.                    |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |==============                                                     |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   09-MAY-2007   Nabarun Ghosh    Initial draft version    |
  -- +===================================================================+
  IS

   --Declaring local variables
   ---------------------------
   ln_line_id              Oe_Order_Lines.Line_Id%TYPE;
   lc_do_unreserve         VARCHAR2(1) := 'N';
   
   --Variables used for holding Hold informations
   ----------------------------------------------
   ln_hold_id                          oe_hold_definitions.hold_id%TYPE;
   ln_stock_reserved                   xx_om_od_hold_add_info.stock_reserved%TYPE;
   
  BEGIN
  
   IF (i_funcmode = 'RUN') THEN
     ----------------------
     -- Set Apps Context --
     ----------------------
     ln_user_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'USER_ID');
     ln_resp_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'RESPONSIBILITY_ID');
     ln_appl_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'APPLICATION_ID');
     fnd_global.apps_initialize(user_id => ln_user_id, resp_id => ln_resp_id, resp_appl_id => ln_appl_id);  
   
     ln_line_id           := NULL;
     lc_entity_ref        := NULL;
     lc_entity_ref_id     := NULL;       
     
     --Obtain the SO line id
     -----------------------
     ln_line_id           := TO_NUMBER(i_itemkey);
     lc_entity_ref        := 'Order Line Id';
     lc_entity_ref_id     := ln_line_id;       
     
     --Obtain the SO header details
     ------------------------------
     OPEN  lcu_get_so_info(
                                     ln_line_id
                                    ) ;
     FETCH lcu_get_so_info INTO cur_get_so_info;
     CLOSE lcu_get_so_info; 
     
     --Extract the stock reserved period for the holds applied on the SO line.
     ------------------------------------------------------------------------
     OPEN lcu_holds_info(
                         ln_line_id
                        ,cur_get_so_info.header_id
                        ,'B'
                       ); 
     LOOP
      FETCH lcu_holds_info INTO  cur_holds_info;
      EXIT WHEN lcu_holds_info%NOTFOUND;
     
      CASE 
      WHEN cur_holds_info.name = 'OD FURNITURE REVIEW'             OR
      	   cur_holds_info.name = 'OD HIGH RETURNS/PROBLEM PRODUCT' OR
      	   cur_holds_info.name = 'OD WAITING FOR RETURN'           THEN
      	   
           lc_do_unreserve := 'Y';
           
        BEGIN
        
           SELECT 'Y'
           INTO   lc_do_unreserve              
           FROM   mtl_reservations          MR
                 ,mfg_lookups               ML 
                 ,mtl_sales_orders          MSO
           WHERE MSO.segment1               = cur_get_so_info.order_number
           AND   MR.demand_source_header_id = MSO.sales_order_id
           AND   MR.demand_source_line_id   = ln_line_id 
           AND   MR.organization_id         = cur_get_so_info.ship_from_org_id
           AND   MR.inventory_item_id       = cur_get_so_info.inventory_item_id
           AND   MR.demand_source_type_id   = ML.lookup_code
           AND   ML.lookup_type             = 'MTL_SUPPLY_DEMAND_SOURCE_TYPE'
           AND   ML.lookup_code IN (2,9)
           AND   (TRUNC(SYSDATE) - NVL(TRUNC(MR.creation_date),TRUNC(SYSDATE))) > NVL(cur_holds_info.stock_reserved,0);
           
        EXCEPTION   
         WHEN NO_DATA_FOUND THEN
             lc_do_unreserve := 'N';
         WHEN OTHERS THEN
             lc_do_unreserve := 'N';
        END;     
      END CASE;

      IF NVL(lc_do_unreserve,'N') = 'Y' THEN     
           
           OD_Unreserve
                       (
                         p_header_id           => cur_get_so_info.header_id   
                        ,p_line_id             => ln_line_id   
                        ,p_ship_from_org_id    => cur_get_so_info.ship_from_org_id
                        ,p_inventory_item_id   => cur_get_so_info.inventory_item_id
                        ,p_order_number        => cur_get_so_info.order_number
                        ,x_return_status       => lc_return_status
                        ,x_msg_count           => ln_msg_count
                        ,x_msg_data            => lc_msg_data
                       );

       	  IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN
       	    o_result := 'COMPLETE: ';
       	  ELSE
       	   FND_MESSAGE.SET_NAME('XXOM','ODP_OM_ORDLINWFMOD_SO_UNRESRV');
       	   IF ln_msg_count = 1 THEN
       	   
       	      --Logging error in global exception framework
       	      ---------------------------------------------
       	      lc_error_code        := 'ODP_OM_ORDLINWFMOD_SO_UNRESRV-01';
       	      lc_error_desc        := FND_MESSAGE.GET;
       	      log_exceptions(lc_error_code             
       	                    ,lc_error_desc
       	                    ,lc_entity_ref       
       	                    ,lc_entity_ref_id    
       	                    );  
       	                    
       	      --Logging error in standard wf error
       	      ------------------------------------
       	      WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Unreserve_Before_Booking',i_itemtype,i_itemkey,              
       	                      'Failed to un-reserve the sales order inventory on the line id: '||ln_line_id||' due to '||lc_msg_data);
       	                       
       	   ELSE
       	     FOR l_index IN 1..ln_msg_count LOOP
  
       	      --Logging error in global exception framework
       	      ---------------------------------------------
       	      lc_error_code        := 'ODP_OM_ORDLINWFMOD_SO_UNRESRV-01';
       	      lc_error_desc        := FND_MESSAGE.GET;
       	      log_exceptions(lc_error_code             
       	                    ,lc_error_desc
       	                    ,lc_entity_ref       
       	                    ,lc_entity_ref_id    
       	                    );  
       	      --Logging error in standard wf error
       	      ------------------------------------
       	      WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Unreserve_Before_Booking',i_itemtype,i_itemkey,              
       	                      'Failed to un-reserve the sales order inventory on the line id: '||ln_line_id||' due to '||lc_msg_data);
  
       	     END LOOP;
       	   END IF;
       	   o_result := 'ERROR:';
       	   APP_EXCEPTION.RAISE_EXCEPTION;
       	  END IF; --End of return status validation for un-reservation
      ELSE
         o_result := 'COMPLETE: '; --If no reservation occures
      END IF;   --End of validation to check whether ureservation should be done or not  
     END LOOP; --End of loop extracting hold details
     CLOSE lcu_holds_info;
     
     RETURN;
         
   ELSIF (i_funcmode = 'CANCEL') THEN
     o_result := 'COMPLETE: ';
   RETURN;
   END IF;
  
  EXCEPTION WHEN OTHERS THEN
     
     --Process to populate global exception handling framework
     ---------------------------------------------------------
     FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     
     lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-05';
     lc_error_desc        := FND_MESSAGE.GET;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );                   
     
     wf_core.context('xx_wfl_omordlinwfmod_pkg','Unreserve_Before_Booking',i_itemtype,i_itemkey,
                    'Unknown Error: '||SQLERRM);
     o_result := wf_engine.eng_error;
     APP_EXCEPTION.RAISE_EXCEPTION;
  END Unreserve_Before_Booking; 

  PROCEDURE Release_Hold_Before_Booking
                              (
			       i_itemtype     IN  VARCHAR2
			      ,i_itemkey      IN  VARCHAR2
			      ,i_actid        IN  PLS_INTEGER
			      ,i_funcmode     IN  VARCHAR2
			      ,o_result       OUT NOCOPY VARCHAR2
                             )
  -- +===================================================================+
  -- | Name  : Release_Hold_Before_Booking                               |
  -- | Rice Id: E0202_OrderLineWorkflowModification                                                    |
  -- | Description: This procedure will provide facility to              |
  -- |              release any OD Specific Holds applied to order /     |
  -- |              return header or on Line / return line before the    |
  -- |              booking process based on the additional informations.|
  -- |                                                                   |
  -- |                                                                   |  
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   10-MAY-2007   Nabarun Ghosh    Initial draft version    |
  -- +===================================================================+
  IS

   lc_do_release           VARCHAR2(1) := 'N';
   ln_line_id              Oe_Order_Lines.Line_Id%TYPE;
   ln_wt_time              PLS_INTEGER;
   lc_entity_name          VARCHAR2(10);
   lc_entity_id            PLS_INTEGER;
   ln_count                PLS_INTEGER := 0;
   
  BEGIN

   IF (i_funcmode = 'RUN') THEN
     ----------------------
     -- Set Apps Context --
     ----------------------
     ln_user_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'USER_ID');
     ln_resp_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'RESPONSIBILITY_ID');
     ln_appl_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'APPLICATION_ID');
     fnd_global.apps_initialize(user_id => ln_user_id, resp_id => ln_resp_id, resp_appl_id => ln_appl_id);  
   
     ln_line_id           := NULL;
     lc_entity_ref        := NULL;
     lc_entity_ref_id     := NULL;       
     --Obtain the SO line id
     -----------------------
     ln_line_id        := TO_NUMBER(i_itemkey);
     lc_entity_ref     := 'Order Line Id';
     lc_entity_ref_id  := ln_line_id;  
     
     --Obtain the SO header details
     ------------------------------
     OPEN  lcu_get_so_info(
                           ln_line_id
                          ) ;
     FETCH lcu_get_so_info INTO cur_get_so_info;
     CLOSE lcu_get_so_info; 
     
     --Initializing the exception variables
     --------------------------------------
     lc_error_code     := NULL;
     lc_error_desc     := NULL;
     lc_entity_ref     := NULL;
     lc_entity_ref_id  := 0;
     
     OPEN lcu_holds_info_wait(
                              ln_line_id
                             ,cur_get_so_info.header_id
                            ); 
     LOOP
       FETCH lcu_holds_info_wait INTO  cur_holds_info_wait;
       EXIT WHEN lcu_holds_info_wait%NOTFOUND;  
        
        --Release Order / Line Level Hold
        ---------------------------------
        lc_hold_release_comments := lc_hold_release_comments||': '||cur_holds_info_wait.name||' being released from the line: '||ln_line_id;
        
        Release_Hold(             
               p_hold_id                => cur_holds_info_wait.hold_id               
              ,p_order_header_id        => cur_get_so_info.header_id       
              ,p_order_line_id          => ln_line_id       
              ,p_release_comments       => lc_hold_release_comments       
              ,p_hold_entity_code       => cur_holds_info_wait.apply_to_order_or_line
              ,x_return_status          => lc_return_status       
              ,x_msg_count              => ln_msg_count
              ,x_msg_data               => lc_msg_data       
              );
           
        IF NVL(lc_return_status,'E') = FND_API.G_RET_STS_SUCCESS THEN 
        
           --Remove record from the Pool table
           -----------------------------------
           /*
           ln_count                := 0;
           SELECT COUNT(1)
           INTO   ln_count
           FROM   oe_order_holds H
           WHERE  H.header_id = cur_get_so_info.header_id
           AND    H.line_id IS NULL;  
           
           IF ln_count > 0 THEN
              ln_count       := 0; 
              lc_entity_name := 'ORDER';
              lc_entity_id   :=  cur_get_so_info.header_id;
           ELSE
              SELECT COUNT(1)
              INTO   ln_count
              FROM   oe_order_holds H
              WHERE  H.header_id = cur_get_so_info.header_id
              AND    H.line_id IS NOT NULL; 
              
              IF ln_count > 0 THEN
                 ln_count       := 0; 
                 lc_entity_name := 'LINE';
                 lc_entity_id   :=  ln_line_id;
              END IF;
           END IF;
           
           DELETE 
           FROM   xx_od_pool_records
           WHERE  entity_name   = lc_entity_name
           AND    entity_id     = lc_entity_id
           AND    holdover_code = cur_holds_info.name;
           */ 
           o_result := 'COMPLETE: ';    
        ELSE   
          FND_MESSAGE.SET_NAME('XXOM','ODP_OM_ORDLINWFMOD_REL_HOLD');
          IF NVL(ln_msg_count,1) = 1 THEN   
             lc_error_code        := 'ODP_OM_ORDLINWFMOD_REL_HOLD-01';   
             lc_error_desc        := FND_MESSAGE.GET;
             log_exceptions(lc_error_code                
                           ,lc_error_desc   
                           ,lc_entity_ref          
                           ,lc_entity_ref_id        
	                   );                      
	       --Logging error in standard wf error   
	       ------------------------------------   
	       WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Release_Hold_Before_Booking',i_itemtype,i_itemkey,   
	                       'Could not release hold from the line id:'||ln_line_id||' due to '||lc_msg_data);   
	   
	  ELSE   
	     FOR l_index IN 1..NVL(ln_msg_count,1)    
	     LOOP   
	       lc_error_code        := 'ODP_OM_ORDLINWFMOD_REL_HOLD-01';   
	       lc_error_desc        := FND_MESSAGE.GET;
	       log_exceptions(lc_error_code                
	                     ,lc_error_desc   
	                     ,lc_entity_ref          
	                     ,lc_entity_ref_id       
	                     );                      
	                        
	       --Logging error in standard wf error   
	       ------------------------------------   
	       WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Release_Hold_Before_Booking',i_itemtype,i_itemkey,   
	                       'Could not release hold from the line id:'||ln_line_id||' due to '||lc_msg_data);   
	        
	     END LOOP;   
	  END IF;   
	  o_result := 'ERROR:';   
	  APP_EXCEPTION.RAISE_EXCEPTION;
	END IF; --Return status validation   
	
      END LOOP;
      CLOSE lcu_holds_info_wait;
      
      RETURN;
      
   ELSIF (i_funcmode = 'CANCEL') THEN
        o_result := 'COMPLETE: ';
        RETURN;
   END IF;
   
  EXCEPTION WHEN OTHERS THEN
  
     --Process to populate global exception handling framework
     ---------------------------------------------------------
     FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     
     lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-06';
     lc_error_desc        := FND_MESSAGE.GET;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );  
                   
     wf_core.context('xx_wfl_omordlinwfmod_pkg','Release_Hold_Before_Booking',i_itemtype,i_itemkey,
                    'Unknown Error: '||SQLERRM);
     o_result := wf_engine.eng_error;
     APP_EXCEPTION.RAISE_EXCEPTION;
     
  END Release_Hold_Before_Booking;

  PROCEDURE Apply_Hold_After_Booking
                                    (
                                     i_itemtype     IN  VARCHAR2,
                                     i_itemkey      IN  VARCHAR2,
                                     i_actid        IN  PLS_INTEGER,
                                     i_funcmode     IN  VARCHAR2,
                                     o_result       OUT NOCOPY VARCHAR2
                                    )
  -- +===================================================================+
  -- | Name    : Apply_Hold_After_Booking                                |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                                   |
  -- | Description: This procedure will be called from the order line wf |
  -- |              process, this will be applying any OD specific holds |
  -- |              on the SO line after booking process.                |
  -- |                                                                   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   07-MAY-2007   Nabarun Ghosh    Initial draft version    |
  -- +===================================================================+
  IS
   
   --Declaring local variables
   ---------------------------
   ln_line_id              Oe_Order_Lines.Line_Id%TYPE;
   ln_hold_exists          PLS_INTEGER := 0;
   ln_quantity_reserved    Oe_Order_Lines.Ordered_Quantity%TYPE;
   
   --Variables populating the workflow attributes
   ----------------------------------------------
   lc_notify_to            xx_om_od_hold_add_info.authorities_to_notify%TYPE;
   lc_order_line_details   VARCHAR2(4000);
   lc_notification_msg     VARCHAR2(2000);
   lc_entity_name          VARCHAR2(10); 
   lc_entity_id            PLS_INTEGER;
   ln_pool_id              PLS_INTEGER;
   
   ln_check_hold_function  PLS_INTEGER; 
   
  BEGIN
   IF (i_funcmode = 'RUN') THEN
     ----------------------
     -- Set Apps Context --
     ----------------------
     ln_user_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'USER_ID');
     ln_resp_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'RESPONSIBILITY_ID');
     ln_appl_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'APPLICATION_ID');
     fnd_global.apps_initialize(user_id => ln_user_id, resp_id => ln_resp_id, resp_appl_id => ln_appl_id);  
   
     ln_line_id        := NULL;
     lc_entity_ref     := NULL;
     lc_entity_ref_id  := NULL;
     
     --Obtain the SO line id
     -----------------------
     ln_line_id        := TO_NUMBER(i_itemkey);
     lc_entity_ref     := 'Order Line Id';
     lc_entity_ref_id  := ln_line_id;  
     
     --Obtain the SO header details
     ------------------------------
     OPEN  lcu_get_so_info(
                                     ln_line_id
                                    ) ;
     FETCH lcu_get_so_info INTO cur_get_so_info;
     CLOSE lcu_get_so_info; 
     
       --Initializing the exception variables
       --------------------------------------
       lc_error_code     := NULL;
       lc_error_desc     := NULL;
       
       --Loop through the nmetadata table to get all hold additional informations
       --------------------------------------------------------------------------
       OPEN lcu_additional_info(
                               'A'
                              ); 
       LOOP
        FETCH lcu_additional_info INTO  cur_additional_info;
        EXIT WHEN lcu_additional_info%NOTFOUND;
        
        SELECT COUNT(1)
        INTO   ln_check_hold_function
        FROM  all_objects 
        WHERE object_name  = UPPER(cur_additional_info.rule_function_name)
        AND   status       = 'VALID';
           
        IF ln_check_hold_function = 0 THEN
           lc_rule_function_result := NULL;
           
           --Compile the rule function
           ---------------------------
           SELECT Compile_Rule_Function(cur_additional_info.hold_id)
           INTO   lc_rule_function_result
           FROM DUAL;
           
        ELSE
         lc_rule_function_result := 'S';
        END IF;
           
        IF lc_rule_function_result <> 'S' THEN
         --Process to populate global exception handling framework
         ---------------------------------------------------------
         FND_MESSAGE.SET_NAME('XXOM','ODP_OM_ORDLINWFMOD_COMPRULFUNC'); -- Message has to create
         lc_error_code        := 'ODP_OM_ORDLINWFMOD_COMPRULFUNC-02';
         lc_error_desc        := FND_MESSAGE.GET;
         log_exceptions(lc_error_code             
                       ,lc_error_desc
                       ,lc_entity_ref       
                       ,lc_entity_ref_id    
                       );                   
         lc_rule_function_result := 'E';   
        END IF;   
           
        IF  lc_rule_function_result = 'S' THEN
             --------------------------------------------------------------- 
             /* Execute the rule-function to get the result for this hold */
             ---------------------------------------------------------------
               IF UPPER(cur_additional_info.name) = 'OD HELD FOR COMMENTS' THEN
  	         EXECUTE IMMEDIATE 'SELECT '||cur_additional_info.rule_function_name||'('
   	                                                           ||''''||'APPLY'||''''
	                                                           ||','||cur_additional_info.hold_id
	                                                           ||','||cur_get_so_info.header_id
	                                                           ||','||ln_line_id
	                                                           ||','||''''||cur_additional_info.apply_to_order_or_line||''''
	                                                           ||')'
	                                    ||' FROM DUAL' INTO lc_rule_function_result; 
	       ELSE
	         EXECUTE IMMEDIATE 'SELECT '||cur_additional_info.rule_function_name||'('
	                                                           ||''''||'APPLY'||''''
	                                                           ||','||cur_additional_info.hold_id
	                                                           ||','||cur_get_so_info.header_id
	                                                           ||','||ln_line_id
	                                                           ||')'
	                                    ||' FROM DUAL' INTO lc_rule_function_result; 
	       END IF;
	       
  	END IF;
  	
	     --Validating whether any unexpected errors occured while executing rule-function
	     --------------------------------------------------------------------------------
	     IF NVL(lc_rule_function_result,'E') = FND_API.G_RET_STS_ERROR THEN
	       
	       --Logging error in custom global exception handling framework
	       -------------------------------------------------------------
	       FND_MESSAGE.SET_NAME('XXOM','ODP_OM_ORDLINWFMOD_EXCRULFUNC');
	       lc_error_code        := 'ODP_OM_ORDLINWFMOD_EXCRULFUNC-02';
	       lc_error_desc        := FND_MESSAGE.GET;
	       log_exceptions(lc_error_code             
	                     ,lc_error_desc
	                     ,lc_entity_ref       
	                     ,lc_entity_ref_id    
	                     );                   
	                     
	       --Logging error in standard wf error
	       ------------------------------------
	       WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Apply_Hold_After_Booking',i_itemtype,i_itemkey,
	                       'Unexpected error in executing rule-function for the line id:'||ln_line_id);
	       o_result := 'ERROR:';
	       APP_EXCEPTION.RAISE_EXCEPTION;
    
	     ELSE
	       --OD holds should be applied 
       	       ---------------------------- 
	       IF lc_rule_function_result = 'Y' THEN 
  	         -------------------------------------------------
  	         /* Process-I: Processing for applying OD Holds */
  	         -------------------------------------------------
  	         --Validating if any hold exists or not
  	         --------------------------------------
  	         ln_hold_exists := 0;
  	         
  	         SELECT COUNT(1)
	         INTO   ln_hold_exists
	         FROM   oe_order_holds                OH
	               ,oe_hold_sources               OHS
	               ,xx_om_od_hold_add_info        XOOHA
	               ,oe_hold_definitions           OHD 
	         WHERE  OH.header_id                 = cur_get_so_info.header_id
	         AND    OH.line_id                   = cur_get_so_info.line_id
	         AND    OH.hold_release_id IS NULL   
	         AND    OH.released_flag             = 'N'
	         AND    OH.hold_source_id            = OHS.hold_source_id
	         AND    OHS.hold_id                  = OHD.hold_id 
	         AND    OHD.attribute6               = TO_CHAR(XOOHA.combination_id)
	         AND    XOOHA.hold_type              = 'A'
	         AND    XOOHA.apply_to_order_or_line = 'L'
	         AND    XOOHA.order_booking_status   = 'A';
	         
	         IF ln_hold_exists = 0 THEN
	         
	           --Call the seeded API to apply OD Hold on the line level
	           --------------------------------------------------------
	           lc_hold_apply_comments := lc_hold_apply_comments||': '||cur_additional_info.name||' being applied to the line: '||ln_line_id;

	           Apply_Hold(
	                    p_hold_id             => cur_additional_info.hold_id
	                   ,p_order_header_id     => cur_get_so_info.header_id
	                   ,p_order_line_id       => ln_line_id
	                   ,p_hold_apply_comments => lc_hold_apply_comments
	                   ,x_return_status       => lc_return_status
	                   ,x_msg_count           => ln_msg_count
	                   ,x_msg_data            => lc_msg_data
	                   );

	           IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN   
	             
  	             -------------------------------------------------------------------
  	             /* Process-II: Processing for Sales Order Inventory Reservations */
  	             -------------------------------------------------------------------
    	             IF NVL(cur_additional_info.stock_reserved,0) > 0 THEN
                       lc_return_status := NULL;
                       lc_msg_data      := NULL;
                       ln_msg_count     := 0   ;
                       
                       OD_Reserve 
		                 (
		                  p_header_id          =>cur_get_so_info.header_id,
		                  p_line_id            =>ln_line_id,
		                  p_ship_from_org_id   =>cur_get_so_info.ship_from_org_id,
		                  p_inventory_item_id  =>cur_get_so_info.inventory_item_id,
		                  p_order_number       =>cur_get_so_info.order_number,
		                  p_order_quantity_uom =>cur_get_so_info.order_quantity_uom,
		                  p_ordered_quantity   =>cur_get_so_info.ordered_quantity,
		                  x_return_status      =>lc_return_status,
		                  x_msg_count          =>ln_msg_count,
		                  x_msg_data           =>lc_msg_data,
		                  x_quantity_reserved  =>ln_quantity_reserved
		                 );
                      
                        IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                         
                         FND_MESSAGE.SET_NAME('XXOM','ODP_OM_ORDLINWFMOD_SO_RESRVN');
                         
                         IF ln_msg_count = 1 THEN
                         
                            --Logging error in global exception framework
                            ---------------------------------------------
                            lc_error_code        := 'ODP_OM_ORDLINWFMOD_SO_RESRVN-02';
                            lc_error_desc        := FND_MESSAGE.GET;
                            log_exceptions(lc_error_code             
                                          ,lc_error_desc
                                          ,lc_entity_ref       
                                          ,lc_entity_ref_id    
                                          );  
                                          
                            --Logging error in standard wf error
                            ------------------------------------
                            WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Apply_Hold_After_Booking',i_itemtype,i_itemkey,              
                                            'Failed to reserve the so inventory on the line id: '||ln_line_id||' due to '||lc_msg_data);
                                             
                         ELSE
                           FOR l_index IN 1..ln_msg_count LOOP
                       
                            --Logging error in global exception framework
                            ---------------------------------------------
                            lc_error_code        := 'ODP_OM_ORDLINWFMOD_SO_RESRVN-02';
                            lc_error_desc        := FND_MESSAGE.GET;
                            log_exceptions(lc_error_code             
                                          ,lc_error_desc
                                          ,lc_entity_ref       
                                          ,lc_entity_ref_id    
                                          );  
                            --Logging error in standard wf error
                            ------------------------------------
                            WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Apply_Hold_After_Booking',i_itemtype,i_itemkey,              
                                            'Failed to reserve the so inventory on the line id: '||ln_line_id||' due to '||lc_msg_data);
                       
                           END LOOP;
                         END IF;
                        END IF; --End of return status validation for un-reservation
    	             END IF;   -- Stock reservation info from Metadata table 
    	             
    	             --------------------------------------------------------------------------------------------
    	             /* Process-III: Send this order with hold details to pool table < MD070 of POOL Framework>  */
    	             --------------------------------------------------------------------------------------------
    	             /*
    	             IF cur_additional_info.send_to_pool = 'Y' THEN
    	             
    	               --Obtain the Pool Id based on the Specific Hold
    	               -----------------------------------------------
    	               IF cur_additional_info.name LIKE 'OD%CREDIT%HOLD' THEN
    	                  ln_pool_name := 'Account Billing Pool';
    	               ELSIF cur_additional_info.name LIKE 'OD%CREDIT%CARD%FAILURE%' THEN
    	                  ln_pool_name := 'Credit Card Auth Failure  Poo';
    	               ELSIF cur_additional_info.name LIKE 'OD%FRAUD%HOLD' THEN
    	                  ln_pool_name := 'Fraud Pool';
    	               ELSIF cur_additional_info.name LIKE 'OD%AMAZON%HOLD' THEN
    	                  ln_pool_name := 'Amazon Pool';
    	               ELSIF cur_additional_info.name LIKE 'OD%LARGE%ORDER%HOLD' THEN
    	                  ln_pool_name := 'Large Order Pool';
    	               ELSIF cur_additional_info.name LIKE 'OD%FURNITURE%HOLD' THEN
    	                  ln_pool_name := 'Furniture Pool';
    	               ELSIF cur_additional_info.name LIKE 'OD%HIGH%RETURN%PROB%PROD%HOLD' THEN
    	                  ln_pool_name := 'High Returns/Problem Product Pool';   
    	               END IF;   
    	               
    	               SELECT pool_id
    	               INTO   ln_pool_id
    	               FROM   xx_od_pool_names  POOL
    	               WHERE  POOL.pool_name = ln_pool_name;
    	               
    	               IF lc_apply_to_order_or_line = 'O' THEN
    	                  lc_entity_name := 'ORDER';
    	                  lc_entity_id   := cur_get_so_info.header_id; 
    	               ELSIF lc_apply_to_order_or_line = 'L' THEN
    	                  lc_entity_name := 'LINE';
    	                  lc_entity_id   := ln_line_id;
    	               END IF;
    	               
    	               ----insert into Pool 
    	               ------------------
    	               --insert INTO xx_od_pool_records (
    	                                             pool_id        --This is the Pool Id from which the API is invoked
    	                                            ,entity_name    --This should indicate whether the action needs to be performed on the Order or Line
    	             			            ,entity_id      --This can be either the Order Header Id or Line Id
    	             			            ,reviewer       --This is the User Id of the CSR who is invoking the Action
    	             			            ,priority       --Priority of the Pool record. This column will be used based on the needs of the Pool
    	             			            ,holdover_code  --Hold Over Code that indicates the action performed by the CSR on the record
    	             			       )
    	             			VALUES (
    	                                             ln_pool_id     --TBD 
    	                                            ,lc_entity_name
    	                                            ,lc_entity_id    
    	                                            ,ln_user_id     
    	                                            ,cur_additional_info.priority    --TBD
    	                                            ,cur_additional_info.name        --Hold Name
    	             			       );
    	             END IF;  --End of validation Pool Records
    	             */
	           ELSE
	             
                     --Logging errors in custom global exception framework
                     -----------------------------------------------------
                     FND_MESSAGE.SET_NAME('XXOM','ODP_OM_ORDLINWFMOD_APPLY_HOLD');
                     
	             IF ln_msg_count = 1 THEN
	                lc_error_code        := 'ODP_OM_ORDLINWFMOD_APPLY_HOLD-02';
	                lc_error_desc        := FND_MESSAGE.GET;
	                log_exceptions(lc_error_code             
	                              ,lc_error_desc
	                              ,lc_entity_ref       
	                              ,lc_entity_ref_id    
	                             );
	                            
                       --Logging error in standard wf error
		       ------------------------------------
		       WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Apply_Hold_After_Booking',i_itemtype,i_itemkey,
		                       'Failed to apply OD hold after booking process on the line id: '||ln_line_id||' due to '||lc_msg_data);
		                       
	            ELSE
	               FOR l_index IN 1..ln_msg_count 
	               LOOP
	                 lc_error_code        := 'ODP_OM_ORDLINWFMOD_APPLY_HOLD-02';
	                 lc_error_desc        := FND_MESSAGE.GET;
	                 log_exceptions(lc_error_code             
	                               ,lc_error_desc
	                               ,lc_entity_ref       
	                               ,lc_entity_ref_id    
	                               );                   
                      
                         --Logging error in standard wf error
		         ------------------------------------
		         WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Apply_Hold_After_Booking',i_itemtype,i_itemkey,
		                         'Failed to apply OD hold after booking process on the line id: '||ln_line_id||' due to '||lc_msg_data);
   
	               END LOOP;
	            END IF; 
	           END IF; --Return status validation
    	         END IF; --If hold exists on line level
               END IF; --If OD Holds should be applied
       	     END IF; --End if validayion for unexpected error while executing rule-funtion
       END LOOP; -- End of loop for metadata table
       CLOSE lcu_additional_info;
       ln_hold_exists := 0;
       
       o_result := 'COMPLETE: ';
       RETURN;
       
   ELSIF (i_funcmode = 'CANCEL') THEN
        o_result := 'COMPLETE:N';
        RETURN;
   END IF;
  
  EXCEPTION WHEN OTHERS THEN
     
     --Process to populate global exception handling framework
     ---------------------------------------------------------
     FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     
     lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-07';
     lc_error_desc        := FND_MESSAGE.GET;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );                   
     
     wf_core.context('xx_wfl_omordlinwfmod_pkg','Apply_Hold_After_Booking',i_itemtype,i_itemkey,
                    'Unknown Error: '||SQLERRM);
     o_result := wf_engine.eng_error;
     APP_EXCEPTION.RAISE_EXCEPTION;
     
  END Apply_Hold_After_Booking; 

  PROCEDURE Is_Hold_Exists_After_Book
                                    (
                                     i_itemtype     IN  VARCHAR2,
                                     i_itemkey      IN  VARCHAR2,
                                     i_actid        IN  PLS_INTEGER,
                                     i_funcmode     IN  VARCHAR2,
                                     o_result       OUT NOCOPY VARCHAR2
                                    )
  -- +===================================================================+
  -- | Name    : Is_Hold_Exists_After_Book                                |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                                   |
  -- | Description: This procedure will be called from the order line wf |
  -- |              process, this will be validating any OD specific holds |
  -- |              on the SO line after booking process.                |
  -- |                                                                   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   07-MAY-2007   Nabarun Ghosh    Initial draft version    |
  -- +===================================================================+
  IS
   
   --Declaring local variables
   ---------------------------
   ln_line_id              Oe_Order_Lines.Line_Id%TYPE;
   ln_hold_exists          PLS_INTEGER := 0;
   
  BEGIN
   IF (i_funcmode = 'RUN') THEN
     ----------------------
     -- Set Apps Context --
     ----------------------
     ln_user_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'USER_ID');
     ln_resp_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'RESPONSIBILITY_ID');
     ln_appl_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'APPLICATION_ID');
     fnd_global.apps_initialize(user_id => ln_user_id, resp_id => ln_resp_id, resp_appl_id => ln_appl_id);  
   
     ln_line_id        := NULL;
     lc_entity_ref     := NULL;
     lc_entity_ref_id  := NULL;
     
     --Obtain the SO line id
     -----------------------
     ln_line_id        := TO_NUMBER(i_itemkey);
     lc_entity_ref     := 'Order Line Id';
     lc_entity_ref_id  := ln_line_id;  
     
     --Obtain the SO header details
     ------------------------------
     OPEN  lcu_get_so_info(
                                     ln_line_id
                                    ) ;
     FETCH lcu_get_so_info INTO cur_get_so_info;
     CLOSE lcu_get_so_info; 

      --------------------------------------
      --Validating if any hold exists or not
      --------------------------------------
      ln_hold_exists := 0;
      
      SELECT COUNT(1)
      INTO   ln_hold_exists
      FROM   oe_order_holds                OH
            ,oe_hold_sources               OHS
            ,xx_om_od_hold_add_info        XOOHA
            ,oe_hold_definitions           OHD 
      WHERE  OH.header_id                 = cur_get_so_info.header_id
      AND    OH.line_id                   = ln_line_id
      AND    OH.hold_release_id IS NULL   
      AND    OH.released_flag             = 'N'
      AND    OH.hold_source_id            = OHS.hold_source_id
      AND    OHS.hold_id                  = OHD.hold_id 
      AND    OHD.attribute6               = TO_CHAR(XOOHA.combination_id)
      AND    XOOHA.hold_type              = 'A'
      AND    XOOHA.apply_to_order_or_line = 'L'
      AND    XOOHA.order_booking_status   = 'A';
      
      IF ln_hold_exists > 0 THEN
        o_result := 'COMPLETE:Y';
      ELSE   
        o_result := 'COMPLETE:N';
      END IF;   
      RETURN;
       
   ELSIF (i_funcmode = 'CANCEL') THEN
        o_result := 'COMPLETE:N';
        RETURN;
   END IF;
  
  EXCEPTION WHEN OTHERS THEN
     
     --Process to populate global exception handling framework
     ---------------------------------------------------------
     FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     
     lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-08';
     lc_error_desc        := FND_MESSAGE.GET;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );                   

     wf_core.context('xx_wfl_omordlinwfmod_pkg','Is_Hold_Exists_After_Book',i_itemtype,i_itemkey,
                    'Unknown Error: '||SQLERRM);
     o_result := wf_engine.eng_error;
     APP_EXCEPTION.RAISE_EXCEPTION;

  END Is_Hold_Exists_After_Book;          

  PROCEDURE Is_Buyers_Remorse_Hold
                                    (
                                     i_itemtype     IN  VARCHAR2,
                                     i_itemkey      IN  VARCHAR2,
                                     i_actid        IN  PLS_INTEGER,
                                     i_funcmode     IN  VARCHAR2,
                                     o_result       OUT NOCOPY VARCHAR2
                                    )
  -- +===================================================================+
  -- | Name    : Is_Buyers_Remorse_Hold                                  |
  -- | Rice Id : E0202_OrderLineWorkflowModification                     |
  -- | Description: This procedure will be called from the order line wf |
  -- |              process after the booking process inorder to         |
  -- |              validate whether the OD Buyers Remorse Hold is applied| 
  -- |              on the order line or not.                            |
  -- |                                                                   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   24-JUL-2007   Nabarun Ghosh    Initial draft version    |
  -- +===================================================================+
  IS

   --Declaring local variables
   ---------------------------
   ln_line_id              Oe_Order_Lines.Line_Id%TYPE;
   ln_hold_exists          PLS_INTEGER := 0;
   ln_wt_time              PLS_INTEGER;
   
  BEGIN
  
   IF (i_funcmode = 'RUN') THEN
     ----------------------
     -- Set Apps Context --
     ----------------------
     ln_user_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'USER_ID');
     ln_resp_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'RESPONSIBILITY_ID');
     ln_appl_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'APPLICATION_ID');
     fnd_global.apps_initialize(user_id => ln_user_id, resp_id => ln_resp_id, resp_appl_id => ln_appl_id);  
   
     ln_line_id        := NULL;
     lc_entity_ref     := NULL;
     lc_entity_ref_id  := NULL;
     
     --Obtain the SO line id
     -----------------------
     ln_line_id        := TO_NUMBER(i_itemkey);
     lc_entity_ref     := 'Order Line Id';
     lc_entity_ref_id  := ln_line_id;  
     
     --Obtain the SO header details
     ------------------------------
     OPEN  lcu_get_so_info(
                                    ln_line_id
                                   );
     FETCH lcu_get_so_info INTO cur_get_so_info;
     CLOSE lcu_get_so_info; 
     
     ln_hold_exists := 0;
     
     SELECT COUNT(1)
     INTO   ln_hold_exists
     FROM   oe_order_holds                OH
           ,oe_hold_sources               OHS
           ,xx_om_od_hold_add_info        XOOHA
           ,oe_hold_definitions           OHD 
     WHERE  OH.header_id                 = cur_get_so_info.header_id
     AND    OH.line_id                   = ln_line_id
     AND    OH.hold_release_id IS NULL   
     AND    OH.released_flag             = 'N'
     AND    OH.hold_source_id            = OHS.hold_source_id
     AND    OHS.hold_id                  = OHD.hold_id 
     AND    OHD.attribute6               = TO_CHAR(XOOHA.combination_id)
     AND    XOOHA.hold_type              = 'A'
     AND    XOOHA.apply_to_order_or_line = 'L'
     AND    XOOHA.order_booking_status   = 'A';
     
     IF NVL(ln_hold_exists,0) > 0 THEN
        o_result := 'COMPLETE:N';
        
        --Validating whether OD Buyers Remorse Hold
        -------------------------------------------
          ln_hold_exists := 0;
       
          SELECT COUNT(1)
          INTO   ln_hold_exists
          FROM   oe_order_holds                OH
                ,oe_hold_sources               OHS
                ,xx_om_od_hold_add_info        XOOHA
                ,oe_hold_definitions           OHD 
          WHERE  OH.header_id                 = cur_get_so_info.header_id
          AND    OH.line_id                   = ln_line_id
          AND    OH.hold_release_id IS NULL   
          AND    OH.released_flag             = 'N'
          AND    OH.hold_source_id            = OHS.hold_source_id
          AND    OHS.hold_id                  = OHD.hold_id 
          AND    OHD.attribute6               = TO_CHAR(XOOHA.combination_id)
          AND    XOOHA.hold_type              = 'A'
          AND    XOOHA.apply_to_order_or_line = 'L'
          AND    XOOHA.order_booking_status   = 'A'
          AND    OHD.name                     = 'OD BUYERS REMORSE';
       
          IF NVL(ln_hold_exists,0) > 0 THEN
            ln_wt_time  := 2; 
            ln_wt_time  := (ln_wt_time / 24)/60;
            wf_engine.SetItemAttrNumber(itemtype => i_itemtype,
                                        itemkey  => i_itemkey,
                                        aname    => 'XX_OD_WAIT_TIME',
                                        avalue   => ln_wt_time);
            o_result := 'COMPLETE:Y';
          ELSE
            o_result := 'COMPLETE:N';
          END IF;
     ELSE
       o_result := 'COMPLETE:N';
     END IF;
     
     RETURN;
     
   ELSIF (i_funcmode = 'CANCEL') THEN
     o_result := 'COMPLETE:N';
     RETURN;
   END IF;
  
  EXCEPTION WHEN OTHERS THEN
     
     --Process to populate global exception handling framework
     ---------------------------------------------------------
     FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     
     lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-09';
     lc_error_desc        := FND_MESSAGE.GET;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );                   
     
     wf_core.context('xx_wfl_omordlinwfmod_pkg','Is_Buyers_Remorse_Hold',i_itemtype,i_itemkey,
                    'Unknown Error: '||SQLERRM);
     o_result := wf_engine.eng_error;
     APP_EXCEPTION.RAISE_EXCEPTION;

  END Is_Buyers_Remorse_Hold; 
  
  PROCEDURE Unreserve_After_Booking
                                    (
                                     i_itemtype     IN  VARCHAR2,
                                     i_itemkey      IN  VARCHAR2,
                                     i_actid        IN  PLS_INTEGER,
                                     i_funcmode     IN  VARCHAR2,
                                     o_result       OUT NOCOPY VARCHAR2
                                    )
  -- +===================================================================+
  -- | Name    : Unreserve_After_Booking                                 |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                                   |
  -- | Description: This procedure will be responsible for relieving any |
  -- |              sales order inventory being reserved on applying OD  |
  -- |              Holds after the booking process.                     |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |==============                                                     |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   09-MAY-2007   Nabarun Ghosh    Initial draft version    |
  -- +===================================================================+
  IS

   --Declaring local variables
   ---------------------------
   ln_line_id              Oe_Order_Lines.Line_Id%TYPE;
   lc_do_unreserve         VARCHAR2(1) := 'N';
   
   --Variables used for holding Hold informations
   ----------------------------------------------
   ln_hold_id                          oe_hold_definitions.hold_id%TYPE;
   ln_stock_reserved                   xx_om_od_hold_add_info.stock_reserved%TYPE;
   
  BEGIN
  
   IF (i_funcmode = 'RUN') THEN
     ----------------------
     -- Set Apps Context --
     ----------------------
     ln_user_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'USER_ID');
     ln_resp_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'RESPONSIBILITY_ID');
     ln_appl_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'APPLICATION_ID');
     fnd_global.apps_initialize(user_id => ln_user_id, resp_id => ln_resp_id, resp_appl_id => ln_appl_id);  
   
     ln_line_id        := NULL;
     lc_entity_ref     := NULL;
     lc_entity_ref_id  := NULL;
     
     --Obtain the SO line id
     -----------------------
     ln_line_id        := TO_NUMBER(i_itemkey);
     lc_entity_ref     := 'Order Line Id';
     lc_entity_ref_id  := ln_line_id;  
     
     --Obtain the SO header details
     ------------------------------
     OPEN  lcu_get_so_info(
                                    ln_line_id
                                   );
     FETCH lcu_get_so_info INTO cur_get_so_info;
     CLOSE lcu_get_so_info; 
     
     --Extract the stock reserved period for the holds applied on the SO line.
     ------------------------------------------------------------------------
     OPEN lcu_holds_info(
                         ln_line_id
                        ,cur_get_so_info.header_id
                        ,'A'
                       ); 
     LOOP
      FETCH lcu_holds_info INTO  cur_holds_info;
      EXIT WHEN lcu_holds_info%NOTFOUND;
     
      IF cur_holds_info.name = 'OD HELD FOR CROSSDOC HOLD'  THEN
         lc_do_unreserve := 'Y';
      ELSE
        BEGIN 
           SELECT 'Y'
           INTO   lc_do_unreserve              
           FROM   mtl_reservations          MR
                 ,mfg_lookups               ML 
                 ,mtl_sales_orders          MSO
           WHERE MSO.segment1               = cur_get_so_info.order_number
           AND   MR.demand_source_header_id = MSO.sales_order_id
           AND   MR.demand_source_line_id   = ln_line_id 
           AND   MR.organization_id         = cur_get_so_info.ship_from_org_id
           AND   MR.inventory_item_id       = cur_get_so_info.inventory_item_id
           AND   MR.demand_source_type_id   = ML.lookup_code
           AND   ML.lookup_type             = 'MTL_SUPPLY_DEMAND_SOURCE_TYPE'
           AND   ML.lookup_code IN (2,9)
           AND   (TRUNC(SYSDATE) - NVL(TRUNC(MR.creation_date),TRUNC(SYSDATE))) > NVL(cur_holds_info.stock_reserved,0);
        EXCEPTION   
         WHEN NO_DATA_FOUND THEN
             lc_do_unreserve := 'N';
         WHEN OTHERS THEN
             lc_do_unreserve := 'N';
        END;     
      END IF;
      
      IF NVL(lc_do_unreserve,'N') = 'Y' THEN     
           
           OD_Unreserve
                       (
                         p_header_id           => cur_get_so_info.header_id   
                        ,p_line_id             => ln_line_id   
                        ,p_ship_from_org_id    => cur_get_so_info.ship_from_org_id
                        ,p_inventory_item_id   => cur_get_so_info.inventory_item_id
                        ,p_order_number        => cur_get_so_info.order_number
                        ,x_return_status       => lc_return_status
                        ,x_msg_count           => ln_msg_count
                        ,x_msg_data            => lc_msg_data
                       );

       	  IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN
       	    o_result := 'COMPLETE: ';
       	  ELSE
       	   
       	   FND_MESSAGE.SET_NAME('XXOM','ODP_OM_ORDLINWFMOD_SO_UNRESRV');
       	   
       	   IF ln_msg_count = 1 THEN
       	   
       	      --Logging error in global exception framework
       	      ---------------------------------------------
       	      lc_error_code        := 'ODP_OM_ORDLINWFMOD_SO_UNRESRV-02';
       	      lc_error_desc        := FND_MESSAGE.GET;
       	      log_exceptions(lc_error_code             
       	                    ,lc_error_desc
       	                    ,lc_entity_ref       
       	                    ,lc_entity_ref_id    
       	                    );  
       	                    
       	      --Logging error in standard wf error
       	      ------------------------------------
       	      WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Unreserve_After_Booking',i_itemtype,i_itemkey,              
       	                      'Failed to un-reserve the sales order inventory on the line id: '||ln_line_id||' due to '||lc_msg_data);
       	                       
       	   ELSE
       	     FOR l_index IN 1..ln_msg_count LOOP
  
       	      --Logging error in global exception framework
       	      ---------------------------------------------
       	      lc_error_code        := 'ODP_OM_ORDLINWFMOD_SO_UNRESRV-02';
       	      lc_error_desc        := FND_MESSAGE.GET;
       	      log_exceptions(lc_error_code             
       	                    ,lc_error_desc
       	                    ,lc_entity_ref       
       	                    ,lc_entity_ref_id    
       	                    );  
       	      --Logging error in standard wf error
       	      ------------------------------------
       	      WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Unreserve_After_Booking',i_itemtype,i_itemkey,              
       	                      'Failed to un-reserve the sales order inventory on the line id: '||ln_line_id||' due to '||lc_msg_data);
  
       	     END LOOP;
       	   END IF;
       	   o_result := 'ERROR:';
       	   APP_EXCEPTION.RAISE_EXCEPTION;
       	  END IF; --End of return status validation for un-reservation
      ELSE
         o_result := 'COMPLETE: '; --If no reservation occures
      END IF;   --End of validation to check whether ureservation should be done or not  
      
     END LOOP; --End of loop extracting hold details
     CLOSE lcu_holds_info;
     
     RETURN;
     
   ELSIF (i_funcmode = 'CANCEL') THEN
     o_result := 'COMPLETE: ';
     RETURN;
   END IF;
  
  EXCEPTION WHEN OTHERS THEN
     
     --Process to populate global exception handling framework
     ---------------------------------------------------------
     FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     
     lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-12';
     lc_error_desc        := FND_MESSAGE.GET;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );                   
     
     wf_core.context('xx_wfl_omordlinwfmod_pkg','Unreserve_After_Booking',i_itemtype,i_itemkey,
                    'Unknown Error: '||SQLERRM);
     o_result := wf_engine.eng_error;
     APP_EXCEPTION.RAISE_EXCEPTION;

  END Unreserve_After_Booking; 
  
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
                        )
  -- +===================================================================+
  -- | Name    : OD_Unreserve                                            |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                                   |
  -- | Description: This procedure will be responsible for relieving any |
  -- |              sales order inventory being reserved on applying OD  |
  -- |              Holds.                                               |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |==============                                                     |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   09-MAY-2007   Nabarun Ghosh    Initial draft version    |
  -- +===================================================================+
  IS


   --Variables used for unreservation
   ----------------------------------
   l_rsv                               inv_reservation_global.mtl_reservation_rec_type;
   ln_reservation_id                   mtl_reservations.reservation_id%TYPE;
   ln_organization_id                  mtl_reservations.organization_id%TYPE;             
   ln_inventory_item_id                mtl_reservations.inventory_item_id%TYPE;           
   lc_primary_uom_code                 mtl_reservations.primary_uom_code%TYPE;            
   ln_pri_reserv_quantity              mtl_reservations.primary_reservation_quantity%TYPE;
   ln_demand_source_header_id          mtl_reservations.demand_source_header_id%TYPE;     
   ln_demand_source_line_id            mtl_reservations.demand_source_line_id%TYPE;       
   lr_original_serial_number           inv_reservation_global.serial_number_tbl_type;
   ln_primary_relieved_quantity        mtl_reservations.primary_reservation_quantity%TYPE;
   ln_primary_remain_quantity          mtl_reservations.primary_reservation_quantity%TYPE; 
   ln_exception                        PLS_INTEGER := 0;
   

  BEGIN 

        lc_entity_ref     := 'Order Line Id';
        lc_entity_ref_id  := p_line_id;  

        --Obtaining the reservation details to relieve.
       	-----------------------------------------------
       	ln_exception := 0;
       	BEGIN
       	 SELECT MR.reservation_id                reservation_id
       	       ,MR.organization_id               organization_id
       	       ,MR.inventory_item_id             inventory_item_id
       	       ,MR.primary_uom_code              primary_uom_code
       	       ,MR.primary_reservation_quantity  primary_reservation_quantity
       	       ,MR.demand_source_header_id       demand_source_header_id
       	       ,MR.demand_source_line_id         demand_source_line_id 
       	 INTO   ln_reservation_id              
       	       ,ln_organization_id             
       	       ,ln_inventory_item_id           
       	       ,lc_primary_uom_code            
       	       ,ln_pri_reserv_quantity
       	       ,ln_demand_source_header_id     
       	       ,ln_demand_source_line_id       
       	 FROM   mtl_reservations                 MR
       	       ,mfg_lookups                      ML 
       	       ,mtl_sales_orders                 MSO 
       	 WHERE MR.demand_source_header_id = MSO.sales_order_id
       	 AND   MSO.segment1               = p_order_number
       	 AND   MR.demand_source_line_id   = p_line_id 
       	 AND   MR.organization_id         = p_ship_from_org_id
       	 AND   MR.inventory_item_id       = p_inventory_item_id
       	 AND   MR.demand_source_type_id   = ML.lookup_code
       	 AND   ML.lookup_type             = 'MTL_SUPPLY_DEMAND_SOURCE_TYPE'
       	 AND   ML.lookup_code IN (2,9);
       	EXCEPTION
       	 WHEN NO_DATA_FOUND THEN
       	   ln_exception                    := 1;
       	   ln_reservation_id               := NULL;  
       	   ln_organization_id              := NULL;  
       	   ln_inventory_item_id            := NULL;  
       	   lc_primary_uom_code             := NULL;  
       	   ln_pri_reserv_quantity          := NULL;
       	   ln_demand_source_header_id      := NULL;
       	   ln_demand_source_line_id        := NULL;
       	   
       	   FND_MESSAGE.SET_NAME('XXOM','ODP_OM_ORDLINWFMOD_NO_RESRVN');
       	   
       	   lc_error_code                   := 'ODP_OM_ORDLINWFMOD_NO_RESRVN-01'; 
       	   lc_error_desc                   := FND_MESSAGE.GET;
       	   
       	 WHEN OTHERS THEN
       	   ln_exception                    := 1;
       	   ln_reservation_id               := NULL;  
       	   ln_organization_id              := NULL;  
       	   ln_inventory_item_id            := NULL;  
       	   lc_primary_uom_code             := NULL;  
       	   ln_pri_reserv_quantity          := NULL;
       	   ln_demand_source_header_id      := NULL;
       	   ln_demand_source_line_id        := NULL;
       	   
       	   FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
       	   FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       	   FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       	   
       	   lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-13';
       	   lc_error_desc        := FND_MESSAGE.GET;
       	END;
       
       	IF ln_exception > 0 THEN
       	   ln_exception := 0;
       	   
       	  --Logging error in custom global exception handling framework
       	  -------------------------------------------------------------
       	  log_exceptions(lc_error_code             
       	                ,lc_error_desc
       	                ,lc_entity_ref       
       	                ,lc_entity_ref_id    
       	                );                   
       	                
          x_return_status  := 'E';
          x_msg_count      := 1  ;
          x_msg_data       := lc_error_desc ;
          
       	ELSE
       	  
       	  --Preparing the records for relieving reservation         
       	  -------------------------------------------------                      
       	  l_rsv.reservation_id               := ln_reservation_id; 
       	  l_rsv.requirement_date             := Sysdate;	             
       	  l_rsv.organization_id              := ln_organization_id;
       	  l_rsv.inventory_item_id            := ln_inventory_item_id;
       	  l_rsv.demand_source_type_id        := inv_reservation_global.g_source_type_oe;
       	  l_rsv.demand_source_name           := 'XX SO Reserv';
       	  l_rsv.demand_source_header_id      := ln_demand_source_header_id;
       	  l_rsv.demand_source_line_id        := ln_demand_source_line_id; 
       	  l_rsv.demand_source_delivery       := NULL;
       	  l_rsv.primary_uom_code             := lc_primary_uom_code;
       	  l_rsv.primary_uom_id               := NULL;
       	  l_rsv.reservation_uom_code         := NULL;
       	  l_rsv.reservation_uom_id           := NULL;
       	  l_rsv.reservation_quantity         := NULL;
       	  l_rsv.primary_reservation_quantity := ln_pri_reserv_quantity;
       	  l_rsv.autodetail_group_id          := NULL;
       	  l_rsv.external_source_code         := NULL;
       	  l_rsv.external_source_line_id      := NULL;
       	  l_rsv.supply_source_type_id        := inv_reservation_global.g_source_type_inv;
       	  l_rsv.supply_source_header_id      := NULL;
       	  l_rsv.supply_source_line_id        := NULL;
       	  l_rsv.supply_source_name           := NULL;
       	  l_rsv.supply_source_line_detail    := NULL;
       	  l_rsv.revision                     := NULL;
       	  l_rsv.subinventory_code            := NULL;
       	  l_rsv.subinventory_id              := NULL;
       	  l_rsv.locator_id                   := NULL;
       	  l_rsv.lot_number                   := NULL;
       	  l_rsv.lot_number_id                := NULL;
       	  l_rsv.pick_slip_number             := NULL;
       	  l_rsv.lpn_id                       := NULL;
       	  l_rsv.attribute_category           := NULL;
       	  l_rsv.attribute1                   := NULL;
       	  l_rsv.attribute2                   := NULL;
       	  l_rsv.attribute3                   := NULL;
       	  l_rsv.attribute4                   := NULL;
       	  l_rsv.attribute5                   := NULL;
       	  l_rsv.attribute6                   := NULL;
       	  l_rsv.attribute7                   := NULL;
       	  l_rsv.attribute8                   := NULL;
       	  l_rsv.attribute9                   := NULL;
       	  l_rsv.attribute10                  := NULL;
       	  l_rsv.attribute11                  := NULL;
       	  l_rsv.attribute12                  := NULL;
       	  l_rsv.attribute13                  := NULL;
       	  l_rsv.attribute14                  := NULL;
       	  l_rsv.attribute15                  := NULL;
       	  l_rsv.ship_ready_flag              := NULL;
       	  l_rsv.staged_flag                  := NULL;
       	  
       	  --Calling the seeded API to create stock reservations
       	  -----------------------------------------------------
       	  INV_RESERVATION_PUB.relieve_reservation
       	     (
       	       p_api_version_number        => api_ver_info        
       	     , p_init_msg_lst              => FND_API.G_TRUE
       	     , x_return_status             => lc_return_status
       	     , x_msg_count                 => ln_msg_count
       	     , x_msg_data                  => lc_msg_data
       	     , p_rsv_rec                   => l_rsv
       	     , p_primary_relieved_quantity => ln_primary_relieved_quantity
       	     , p_relieve_all               => FND_API.G_TRUE
       	     , p_original_serial_number    => lr_original_serial_number
       	     , p_validation_flag           => FND_API.G_TRUE
       	     , x_primary_relieved_quantity => ln_primary_relieved_quantity
       	     , x_primary_remain_quantity   => ln_primary_remain_quantity  
       	     );
       	  
       	  IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN
       	    x_return_status  := lc_return_status;
       	    x_msg_count      := ln_msg_count    ;
       	    x_msg_data       := lc_msg_data     ;
       	    
       	  ELSE
       	    x_return_status  := lc_return_status;
       	    x_msg_count      := ln_msg_count    ;
       	    x_msg_data       := lc_msg_data     ;
       	  END IF; 
       	  
       	END IF; --End of extracting reservation details
  EXCEPTION
    WHEN OTHERS THEN
    
     x_return_status := 'E'; 
     x_msg_count     :=  1 ;
     x_msg_data      :=  'Unexpected error in OD_Unreserve due to: '||SUBSTR(SQLERRM,1,240);
    
     --Process to populate global exception handling framework
     ---------------------------------------------------------
     FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     
     lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-14';
     lc_error_desc        := FND_MESSAGE.GET;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );                   
  END OD_Unreserve;

  PROCEDURE Release_Hold_After_Booking
                              (
			       i_itemtype     IN  VARCHAR2
			      ,i_itemkey      IN  VARCHAR2
			      ,i_actid        IN  PLS_INTEGER
			      ,i_funcmode     IN  VARCHAR2
			      ,o_result       OUT NOCOPY VARCHAR2
                             )
  -- +===================================================================+
  -- | Name  : Release_Hold_After_Booking                                |
  -- | Rice Id: E0202_OrderLineWorkflowModification                                                    |
  -- | Description: This procedure will provide facility to              |
  -- |              release any OD Specific Holds applied to order /     |
  -- |              return header or on Line / return line after the     |
  -- |              booking process based on the additional informations.|
  -- |                                                                   |
  -- |                                                                   |  
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   10-MAY-2007   Nabarun Ghosh    Initial draft version    |
  -- +===================================================================+
  IS

   lc_do_release           VARCHAR2(1) := 'N';
   ln_line_id              Oe_Order_Lines.Line_Id%TYPE;
   ln_wt_time              PLS_INTEGER;
   lc_entity_name          VARCHAR2(10);
   lc_entity_id            PLS_INTEGER;
   
  BEGIN

   IF (i_funcmode = 'RUN') THEN
     ----------------------
     -- Set Apps Context --
     ----------------------
     ln_user_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'USER_ID');
     ln_resp_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'RESPONSIBILITY_ID');
     ln_appl_id := wf_engine.GetItemAttrNumber(itemtype => i_itemtype, itemkey => i_itemkey, aname => 'APPLICATION_ID');
     fnd_global.apps_initialize(user_id => ln_user_id, resp_id => ln_resp_id, resp_appl_id => ln_appl_id);  
   
     ln_line_id        := NULL;
     lc_entity_ref     := NULL;
     lc_entity_ref_id  := NULL;  
     
     --Obtain the SO line id
     -----------------------
     ln_line_id        := TO_NUMBER(i_itemkey);
     lc_entity_ref     := 'Order Line Id';
     lc_entity_ref_id  := ln_line_id;  
     
     --Obtain the SO header details
     ------------------------------
     OPEN  lcu_get_so_info(
                                     ln_line_id
                                    ) ;
     FETCH lcu_get_so_info INTO cur_get_so_info;
     CLOSE lcu_get_so_info; 
     
     --Initializing the exception variables
     --------------------------------------
     lc_error_code     := NULL;
     lc_error_desc     := NULL;
       
     --Loop through the nmetadata table to get all hold additional informations
     --------------------------------------------------------------------------
     OPEN lcu_holds_info(
                         ln_line_id
                        ,cur_get_so_info.header_id
                        ,'A'
                       ); 
     LOOP
      FETCH lcu_holds_info INTO  cur_holds_info;
      EXIT WHEN lcu_holds_info%NOTFOUND;
      
      o_result := 'COMPLETE: ';
      
      IF cur_holds_info.name = 'OD BUYERS REMORSE' THEN
         --Release Order / Line Level Hold
         ---------------------------------
         lc_hold_release_comments := lc_hold_release_comments||': '||cur_holds_info.name||' being released from the line: '||ln_line_id;
         Release_Hold(             
                p_hold_id                => cur_holds_info.hold_id               
               ,p_order_header_id        => cur_get_so_info.header_id       
               ,p_order_line_id          => ln_line_id       
               ,p_release_comments       => lc_hold_release_comments       
               ,p_hold_entity_code       => cur_holds_info.apply_to_order_or_line
               ,x_return_status          => lc_return_status       
               ,x_msg_count              => ln_msg_count
               ,x_msg_data               => lc_msg_data       
               );
         
         IF NVL(lc_return_status,'E') = FND_API.G_RET_STS_SUCCESS THEN 
            
            --Remove record from the Pool table
            -----------------------------------
            /*
            ln_count                := 0;
            SELECT COUNT(1)
            INTO   ln_count
            FROM   oe_order_holds H
            WHERE  H.header_id = cur_get_so_info.header_id
            AND    H.line_id IS NULL;  
            
            IF ln_count > 0 THEN
               ln_count       := 0; 
               lc_entity_name := 'ORDER';
               lc_entity_id   :=  cur_get_so_info.header_id;
            ELSE
               SELECT COUNT(1)
               INTO   ln_count
               FROM   oe_order_holds H
               WHERE  H.header_id = cur_get_so_info.header_id
               AND    H.line_id IS NOT NULL; 
               
               IF ln_count > 0 THEN
                  ln_count       := 0; 
                  lc_entity_name := 'LINE';
                  lc_entity_id   :=  ln_line_id;
               END IF;
            END IF;
            
            DELETE 
            FROM   xx_od_pool_records
            WHERE  entity_name   = lc_entity_name
            AND    entity_id     = lc_entity_id
            AND    holdover_code = cur_holds_info.name;
            */
            o_result := 'COMPLETE: '; 
            
         ELSE
           
           FND_MESSAGE.SET_NAME('XXOM','ODP_OM_ORDLINWFMOD_REL_HOLD');
           
      	   IF NVL(ln_msg_count,1) = 1 THEN
              lc_error_code        := 'ODP_OM_ORDLINWFMOD_REL_HOLD-02';
      	      lc_error_desc        := FND_MESSAGE.GET;
      	      log_exceptions(lc_error_code             
      	                    ,lc_error_desc
      	                    ,lc_entity_ref       
      	                    ,lc_entity_ref_id    
      	                    );                   
      	        --Logging error in standard wf error
      	        ------------------------------------
      	        WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Release_Hold_After_Booking',i_itemtype,i_itemkey,
      	                        'Could not release hold from the line id:'||ln_line_id||' due to '||lc_msg_data);
      
      	   ELSE
      	      FOR l_index IN 1..NVL(ln_msg_count,1) 
      	      LOOP
      	        lc_error_code        := 'ODP_OM_ORDLINWFMOD_REL_HOLD-02';
      	        lc_error_desc        := FND_MESSAGE.GET;
      	        log_exceptions(lc_error_code             
      	                      ,lc_error_desc
      	                      ,lc_entity_ref       
      	                      ,lc_entity_ref_id    
      	                      );                   
      	                      
      	        --Logging error in standard wf error
      	        ------------------------------------
      	        WF_CORE.CONTEXT('xx_wfl_omordlinwfmod_pkg','Release_Hold_After_Booking',i_itemtype,i_itemkey,
      	                        'Could not release hold from the line id:'||ln_line_id||' due to '||lc_msg_data);
      	      
      	      END LOOP;
      	   END IF;
      	   o_result := 'ERROR:';
      	   APP_EXCEPTION.RAISE_EXCEPTION;
      	 END IF; --Return status validation
      	 
      END IF; --End of validation for Buyers Remorse Hold
      
     END LOOP; -- End of loop for for holds informations applied on line
     CLOSE lcu_holds_info;
     
     RETURN;
     
   ELSIF (i_funcmode = 'CANCEL') THEN
        o_result := 'COMPLETE: ';
        RETURN;
   ELSE
        o_result := 'COMPLETE: ';
        RETURN;
   END IF;
  
  EXCEPTION 
    WHEN OTHERS THEN
     
     --Process to populate global exception handling framework
     ---------------------------------------------------------
     FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     
     lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-15';
     lc_error_desc        := FND_MESSAGE.GET;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );                   
     
     wf_core.context('xx_wfl_omordlinwfmod_pkg','Release_Hold_After_Booking',i_itemtype,i_itemkey,
                    'Unknown Error: '||SQLERRM);
     o_result := wf_engine.eng_error;
     APP_EXCEPTION.RAISE_EXCEPTION;
     
  END Release_Hold_After_Booking;

  PROCEDURE Release_Hold(
                      p_hold_id            IN    Oe_Hold_Definitions.Hold_Id%TYPE
                     ,p_order_header_id    IN    Oe_Order_Headers_All.Header_Id%TYPE
                     ,p_order_line_id      IN    Oe_Order_Lines_All.Line_Id%TYPE
                     ,p_release_comments   IN    VARCHAR2
                     ,p_hold_entity_code   IN    xx_om_od_hold_add_info.apply_to_order_or_line%TYPE
                     ,x_return_status      OUT   NOCOPY VARCHAR2
                     ,x_msg_count          OUT   NOCOPY PLS_INTEGER 
                     ,x_msg_data           OUT   NOCOPY PLS_INTEGER
                     )
                     
  -- +===================================================================+
  -- | Name  : Release_Hold                                              |
  -- | Rice Id : E0202_OrderLineWorkflowModification                                                   |  
  -- | Description: This procedure will call the seeded API              |
  -- |              OE_HOLDS_PUB to Releaseany OD Specific Holds         |
  -- |              priority wise from order /return header or from      | 
  -- |              Line / return line.                                  |
  -- |                                                                   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  | 
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   10-MAY-2007   Nabarun Ghosh    Initial draft version    |
  -- +===================================================================+
  IS  
  
   --Variables required for processing Holds
   -----------------------------------------
   l_hdr_hold_source_rec        oe_holds_pvt.hold_source_rec_type;
   l_hdr_hold_release_rec       oe_holds_pvt.hold_release_rec_type;
   ln_exception_occured         PLS_INTEGER := 0;
   ln_hold_source_id            oe_hold_sources.hold_source_id%TYPE; 
   ln_order_hold_id             oe_order_holds.order_hold_id%TYPE;
   lc_reason_code               VARCHAR2(100); 
   
  BEGIN

     ln_hold_source_id := NULL;
     ln_order_hold_id  := NULL;
     ln_exception_occured := 0;
     
     --Deriving the Hold source code
     -------------------------------
      BEGIN
       SELECT OHS.hold_source_id
             ,OH.order_hold_id
       INTO   ln_hold_source_id
             ,ln_order_hold_id
       FROM   oe_order_holds   OH
             ,oe_hold_sources  OHS 
       WHERE OH.header_id           = P_Order_Header_Id
       AND OH.hold_release_id IS NULL 
       AND OH.released_flag         ='N'
       AND OH.line_id IS NOT NULL 
       AND OH.hold_source_id        = OHS.hold_source_id
       AND OHS.hold_id              = P_Hold_Id;
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
         ln_exception_occured := 1;
         ln_hold_source_id    := NULL;
         ln_order_hold_id     := NULL;
         
         FND_MESSAGE.SET_NAME('XXOM','ODP_OM_ORDLINWFMOD_NO_HLDSRC');
         lc_error_code        := 'ODP_OM_ORDLINWFMOD_NO_HLDSRC-01';
         lc_error_desc        := FND_MESSAGE.GET;
         lc_entity_ref        := 'Order Header Id';
         lc_entity_ref_id     := P_Order_Header_Id;
       WHEN OTHERS THEN
         ln_exception_occured := 1;
         ln_hold_source_id    := NULL;
         ln_order_hold_id     := NULL;
         
         FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
         FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
         FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
         
         lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-16';
         lc_error_desc        := FND_MESSAGE.GET;
         lc_entity_ref        := 'Hold Id';
         lc_entity_ref_id     := p_hold_id;
      END;
    
     --Check whether any exceptions occured or not
     ---------------------------------------------
     IF ln_exception_occured > 0 THEN
       log_exceptions( lc_error_code             
                      ,lc_error_desc
                      ,lc_entity_ref       
                      ,lc_entity_ref_id    
                     );
     END IF;
     
     IF ln_exception_occured = 0 THEN  
      
      BEGIN
        SELECT lkp.lookup_code
        INTO lc_reason_code
        FROM oe_lookups lkp
        WHERE lkp.enabled_flag = 'Y'
        AND SYSDATE BETWEEN NVL (lkp.start_date_active, SYSDATE)
                            AND NVL (lkp.end_date_active, SYSDATE)
        AND lkp.lookup_code NOT IN ('EXPIRE', 'PASS_CREDIT')
        AND lkp.lookup_type = 'RELEASE_REASON'
        AND lkp.lookup_code = 'MANUAL_RELEASE_MARGIN_HOLD'
        ORDER BY lkp.meaning;
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
         ln_exception_occured := 1;
         lc_reason_code       := NULL;
         --Process to populate global exception handling framework
         ---------------------------------------------------------
         FND_MESSAGE.SET_NAME('XXOM','ODP_OM_ORDLINWFMOD_REL_REASON');
         lc_error_code        := 'ODP_OM_ORDLINWFMOD_REL_REASON-01';
         lc_error_desc        := FND_MESSAGE.GET;
         lc_entity_ref        := 'Order Header Id';
         lc_entity_ref_id     := P_Order_Header_Id;
       WHEN OTHERS THEN
         ln_exception_occured := 1;
         lc_reason_code       := NULL;
         --Process to populate global exception handling framework
         ---------------------------------------------------------
         FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
         FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
         FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
         
         lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-17';
         lc_error_desc        := FND_MESSAGE.GET;
         lc_entity_ref        := 'Hold Id';
         lc_entity_ref_id     := p_hold_id;
      END;

      --Preparing hold source records to Release Hold
      -----------------------------------------------
      l_hdr_hold_source_rec.hold_id              := p_hold_id;
      l_hdr_hold_source_rec.hold_entity_id       := p_order_header_id;
      l_hdr_hold_source_rec.hold_entity_code     := 'O';
      l_hdr_hold_source_rec.header_id            := p_order_header_id;
      l_hdr_hold_source_rec.line_id              := p_order_line_id;
      l_hdr_hold_release_rec.hold_source_id      := ln_hold_source_id;
      l_hdr_hold_release_rec.release_reason_code := lc_reason_code;
      l_hdr_hold_release_rec.order_hold_id       := ln_order_hold_id;
      l_hdr_hold_release_rec.release_comment     := p_release_comments;	

      --Check whether any exceptions occured or not
      ---------------------------------------------
      IF ln_exception_occured > 0 THEN
        log_exceptions( lc_error_code             
                       ,lc_error_desc
                       ,lc_entity_ref       
                       ,lc_entity_ref_id    
                      );
      END IF;
      
      IF ln_exception_occured = 0 THEN  
       
       --Calling the seeded API to release holds
       -----------------------------------------
       OE_HOLDS_PUB.RELEASE_HOLDS
                 (p_api_version      => api_ver_info
                 ,p_init_msg_list    => FND_API.G_FALSE
                 ,p_commit           => FND_API.G_FALSE
                 ,p_validation_level => FND_API.G_VALID_LEVEL_NONE
                 ,p_hold_source_rec  => l_hdr_hold_source_rec
                 ,p_hold_release_rec => l_hdr_hold_release_rec
                 ,x_return_status    => lc_return_status
                 ,x_msg_count        => ln_msg_count
                 ,x_msg_data         => lc_msg_data);
               
       IF TRIM(UPPER(lc_return_status)) <> TRIM(UPPER(FND_API.G_RET_STS_SUCCESS)) THEN
          x_return_status      := lc_return_status;
          x_msg_count          := ln_msg_count;
          x_msg_data           := lc_msg_data;
       ELSIF  TRIM(UPPER(lc_return_status)) = TRIM(UPPER(FND_API.G_RET_STS_SUCCESS)) THEN
          x_return_status      := lc_return_status;
          x_msg_count          := ln_msg_count;
          x_msg_data           := lc_msg_data;
       END IF; 
       
      END IF; --Validation for release reason code ends here
     END IF;  --Validation for order holds ends here           
     
  EXCEPTION
    WHEN OTHERS THEN
      x_return_status := 'E';
      x_msg_count     :=  1 ;
      x_msg_data      :=  SUBSTR(SQLERRM,1,240);
      
      --Process to populate global exception handling framework
      ---------------------------------------------------------
      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
      
      lc_error_code        := 'ODP_OM_UNEXPECTED_ERR-18';
      lc_error_desc        := FND_MESSAGE.GET;
      lc_entity_ref        := 'Hold Id';
      lc_entity_ref_id     := p_hold_id;
      log_exceptions(lc_error_code             
                    ,lc_error_desc
                    ,lc_entity_ref       
                    ,lc_entity_ref_id    
                    );                   
  END Release_Hold;
END XX_WFL_OMORDLINWFMOD_PKG;
/
SHOW ERRORS;
--EXIT;