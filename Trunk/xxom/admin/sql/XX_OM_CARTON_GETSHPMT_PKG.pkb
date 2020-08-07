SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_CARTON_GETSHPMT_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name         : XX_OM_CARTON_GETSHPMT_PKG                                         |
-- | Rice Id      : I0030_Cartonization                                                      | 
-- | Description  : Custom Test Package to create the XML DOc for OAGIS GetShipmentUnit      |
-- |                used for WMOS Cartonization.                                             |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    | 
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   03-JUL-2007       Nabarun          Initial Version                            |
-- |                                                                                         |
-- +=========================================================================================+
AS 

  --Declaring varibales to hold the exception infos 
  lc_error_code                xx_om_global_exceptions.error_code%TYPE; 
  lc_error_desc                xx_om_global_exceptions.description%TYPE; 
  lc_entity_ref                xx_om_global_exceptions.entity_ref%TYPE;
  lc_entity_ref_id             xx_om_global_exceptions.entity_ref_id%TYPE;

  
  PROCEDURE log_exceptions( p_error_code        IN  VARCHAR2
                           ,p_error_description IN  VARCHAR2
                           ,p_entity_ref        IN  VARCHAR2
                           ,p_entity_ref_id     IN  PLS_INTEGER
                          )
  -- +===================================================================+
  -- | Name  : Log_Exceptions                                            |
  -- | Rice Id      : I0030_Cartonization                                | 
  -- | Description: This procedure will be responsible to store all      | 
  -- |              the exceptions occured during the procees using      |
  -- |              global custom exception handling framework           |
  -- |                                                                   |
  -- | Parameters:  IN:                                                  |
  -- |     P_Error_Code        --Custom error code                       |
  -- |     P_Error_Description --Custom Error Description                |
  -- |     p_entity_ref        --                                        |
  -- |     p_entity_ref_id     --                                        |
  -- |                                                                   |
  -- +===================================================================+
  AS
   
   --Output of the global exception framework package
   x_errbuf                    VARCHAR2(1000);
   x_retcode                   VARCHAR2(40);
   ln_count                    NUMBER := 0;
   
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

  PROCEDURE GetShipmentUnit_To_Wmos(
                                    p_delivery_id            IN   wsh_new_deliveries.delivery_id%TYPE
                                   ,x_getshipmentunit_tbl   OUT  NOCOPY xx_om_getshipmentunit_tbl
                                   )                               
  IS

    CURSOR lcu_delivery_details (i_delivery_id wsh_new_deliveries.delivery_id%TYPE)
    IS
    SELECT  WND.delivery_id             DELIVERY_ID
          ,WND.name                    DELIVERY_NUMBER
          ,MP.organization_code        WHSE
          ,WDD.delivery_detail_id      DELIVERY_LINE_NUMBER
          ,KFV.concatenated_segments   SKU 
          ,WDD.requested_quantity      SKU_QTY
          ,MSI.replenish_to_order_flag WHOLESALE_SKU_FLAG
          ,'RT' RETURN_TYPE 
      FROM wsh_new_deliveries       WND,
           wsh_delivery_assignments WDA,
           wsh_delivery_details     WDD,
           mtl_system_items_b       MSI,
           mtl_system_items_kfv     KFV,
           mtl_parameters           MP 
     WHERE WDA.delivery_id         = WND.delivery_id 
     AND   WDD.delivery_detail_id  = WDA.delivery_detail_id 
     AND   WDD.organization_id     = MP.organization_id 
     AND   MSI.inventory_item_id   = WDD.inventory_item_id
     AND   MSI.organization_id     = WDD.organization_id
     AND   KFV.inventory_item_id   = WDD.inventory_item_id
     AND   KFV.organization_id     = WDD.organization_id
     AND   WND.delivery_id         = i_delivery_id;

    cur_delivery_details_ref    lcu_delivery_details_rfcur;
    lc_delivery_details         VARCHAR2(4000);
    
    
  BEGIN
    
    FOR l_delivery_details IN lcu_delivery_details(p_delivery_id)
    LOOP
         ln_count := NVL(ln_count,0)+1;
         
         x_getshipmentunit_tbl(ln_count).delivery_id := l_delivery_details.delivery_id;
         x_getshipmentunit_tbl(ln_count).delivery_number := l_delivery_details.delivery_number;     
         x_getshipmentunit_tbl(ln_count).whse := l_delivery_details.whse;                
         x_getshipmentunit_tbl(ln_count).delivery_line_number := l_delivery_details.delivery_line_number;
         x_getshipmentunit_tbl(ln_count).sku := l_delivery_details.sku;                 
         x_getshipmentunit_tbl(ln_count).sku_qty := l_delivery_details.sku_qty;             
         x_getshipmentunit_tbl(ln_count).wholesale_sku_flag := l_delivery_details.wholesale_sku_flag;  
         x_getshipmentunit_tbl(ln_count).return_type := l_delivery_details.return_type;         
         
         x_getshipmentunit_tbl(ln_count).ctn_type     := 'ctn_type';  
         x_getshipmentunit_tbl(ln_count).season       := 'season';    
         x_getshipmentunit_tbl(ln_count).season_yr    := 2007;        
         x_getshipmentunit_tbl(ln_count).style        := 'style'     ;
         x_getshipmentunit_tbl(ln_count).style_sfx    := 'style_sfx' ;
         x_getshipmentunit_tbl(ln_count).color        := 'color'     ;
         x_getshipmentunit_tbl(ln_count).color_sfx    := 'color_sfx' ;
         x_getshipmentunit_tbl(ln_count).sec_dim      := 100;          
         x_getshipmentunit_tbl(ln_count).qual               := 'qual';          
         x_getshipmentunit_tbl(ln_count).size_desc          := 'size_desc';  
         x_getshipmentunit_tbl(ln_count).spl_instr_code_1   := 'spl_instr_code_1' ;            
         x_getshipmentunit_tbl(ln_count).spl_instr_code_2   := 'spl_instr_code_2' ;            
         x_getshipmentunit_tbl(ln_count).spl_instr_code_3   := 'spl_instr_code_3' ;            
         x_getshipmentunit_tbl(ln_count).spl_instr_code_4   := 'spl_instr_code_4' ;            
         x_getshipmentunit_tbl(ln_count).spl_instr_code_5   := 'spl_instr_code_5' ;            
         x_getshipmentunit_tbl(ln_count).spl_instr_code_6   := 'spl_instr_code_6' ;            
         x_getshipmentunit_tbl(ln_count).spl_instr_code_7   := 'spl_instr_code_7' ;            
         x_getshipmentunit_tbl(ln_count).spl_instr_code_8   := 'spl_instr_code_8' ;            
         x_getshipmentunit_tbl(ln_count).spl_instr_code_9   := 'spl_instr_code_9' ;            
         x_getshipmentunit_tbl(ln_count).spl_instr_code_10  := 'spl_instr_code_10';            
         x_getshipmentunit_tbl(ln_count).host_input_id      := 1;
         							    
    END LOOP;							    
        

  END GetShipmentUnit_To_Wmos;    
  

END XX_OM_CARTON_GETSHPMT_PKG ;
/
SHOW ERRORS;
--EXIT;

