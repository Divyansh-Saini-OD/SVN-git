SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_CARTONIZATION_WMOS_PKG
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

  --Declaring varibales to hold the exception infos 
  lc_error_code                xx_om_global_exceptions.error_code%TYPE; 
  lc_error_desc                xx_om_global_exceptions.description%TYPE; 
  lc_entity_ref                xx_om_global_exceptions.entity_ref%TYPE;
  lc_entity_ref_id             xx_om_global_exceptions.entity_ref_id%TYPE;

  ln_c_api_version             CONSTANT  PLS_INTEGER  := 1.0 ;
  lc_return_status             VARCHAR2(40);
  ln_msg_count                 PLS_INTEGER;
  lc_msg_data                  VARCHAR2(2000);
  
  
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
  -- | 	   P_Error_Description --Custom Error Description                |
  -- | 	   p_entity_ref        --                                        |
  -- | 	   p_entity_ref_id     --                                        |
  -- |                                                                   |
  -- +===================================================================+
  AS
   
   --Output of the global exception framework package
   lc_errbuf                    VARCHAR2(1000);
   lc_retcode                   VARCHAR2(40);
   
  BEGIN
  
   lrec_excepn_obj_type.p_exception_header  := g_exception_header;
   lrec_excepn_obj_type.p_track_code        := g_track_code      ;
   lrec_excepn_obj_type.p_solution_domain   := g_solution_domain ;
   lrec_excepn_obj_type.p_function          := g_function        ;
   
   lrec_excepn_obj_type.p_error_code        := p_error_code;
   lrec_excepn_obj_type.p_error_description := p_error_description;
   lrec_excepn_obj_type.p_entity_ref        := p_entity_ref;
   lrec_excepn_obj_type.p_entity_ref_id     := p_entity_ref_id;
   
   xx_om_global_exception_pkg.insert_exception(lrec_excepn_obj_type
                                              ,lc_errbuf
                                              ,lc_retcode
                                             );
  END log_exceptions;

  PROCEDURE Log_Carton_Wmos_Proc_status( 
                                      p_delivery_id     IN  wsh_new_deliveries.delivery_id%TYPE
                                     ,p_process_status  IN  wsh_new_deliveries.attribute1%TYPE
                                     ,x_status          OUT NOCOPY VARCHAR2
                                     )
  -- +===================================================================+
  -- | Name  : Log_Carton_Wmos_Proc_status                               |
  -- | Rice Id      : I0030_Cartonization                                | 
  -- | Description:       This Procedure will be updating the process    |
  -- |                    status for the delivery in wsh_new_deliveries, |  
  -- |                    to identify the exact state of the processing. |
  -- | Parameters                                                        |
  -- | IN        :        p_delivery_id                                  |
  -- |                    p_process_status                               |
  -- | Returns   :        x_status                                       |
  -- |                                                                   |
  -- +===================================================================+                    
  AS

   ln_delivery_id                  wsh_new_deliveries.delivery_id%TYPE;
   lc_errbuf                       VARCHAR2(1000);
   
   lc_redelivery_flag              xx_wsh_delivery_att_all.redelivery_flag%TYPE;         
   lc_del_backtoback_ind      	   xx_wsh_delivery_att_all.del_backtoback_ind%TYPE;      
   ln_no_of_shiplabels        	   xx_wsh_delivery_att_all.no_of_shiplabels%TYPE;        
   ld_new_sch_ship_date       	   xx_wsh_delivery_att_all.new_sch_ship_date%TYPE;       
   ld_new_sch_arr_date        	   xx_wsh_delivery_att_all.new_sch_arr_date%TYPE;        
   ld_actual_deliverd_date    	   xx_wsh_delivery_att_all.actual_deliverd_date%TYPE;    
   ld_new_del_date_from_time  	   xx_wsh_delivery_att_all.new_del_date_from_time%TYPE;  
   ld_new_del_date_to_time    	   xx_wsh_delivery_att_all.new_del_date_to_time%TYPE;    
   lc_delivery_cancelled_ind  	   xx_wsh_delivery_att_all.delivery_cancelled_ind%TYPE;  
   lc_delivery_trans_ind      	   xx_wsh_delivery_att_all.delivery_trans_ind%TYPE;      
   lc_pod_exceptions_comments 	   xx_wsh_delivery_att_all.pod_exceptions_comments%TYPE; 
   lc_retransmit_pick_ticket  	   xx_wsh_delivery_att_all.retransmit_pick_ticket%TYPE;  
   lc_payment_subtype_cod_ind 	   xx_wsh_delivery_att_all.payment_subtype_cod_ind%TYPE; 
   lc_del_to_post_office_ind  	   xx_wsh_delivery_att_all.del_to_post_office_ind%TYPE;  
   
   
  BEGIN
    FND_MSG_PUB.INITIALIZE;
    lc_return_status                        := NULL;
    
    lr_wsh_dlv_att_obj_type.delivery_id                  := p_delivery_id          ;
    lr_wsh_dlv_att_obj_type.od_internal_delivery_status  := p_process_status       ;
    lr_wsh_dlv_att_obj_type.redelivery_flag              := lc_redelivery_flag     ;    
    lr_wsh_dlv_att_obj_type.del_backtoback_ind      	 := lc_del_backtoback_ind  ;   
    lr_wsh_dlv_att_obj_type.no_of_shiplabels        	 := ln_no_of_shiplabels    ;   
    lr_wsh_dlv_att_obj_type.new_sch_ship_date       	 := ld_new_sch_ship_date   ;   
    lr_wsh_dlv_att_obj_type.new_sch_arr_date        	 := ld_new_sch_arr_date    ;   
    lr_wsh_dlv_att_obj_type.actual_deliverd_date    	 := ld_actual_deliverd_date;   
    lr_wsh_dlv_att_obj_type.new_del_date_from_time  	 := ld_new_del_date_from_time; 
    lr_wsh_dlv_att_obj_type.new_del_date_to_time    	 := ld_new_del_date_to_time  ; 
    lr_wsh_dlv_att_obj_type.delivery_cancelled_ind  	 := lc_delivery_cancelled_ind; 
    lr_wsh_dlv_att_obj_type.delivery_trans_ind      	 := lc_delivery_trans_ind    ; 
    lr_wsh_dlv_att_obj_type.pod_exceptions_comments 	 := lc_pod_exceptions_comments;
    lr_wsh_dlv_att_obj_type.retransmit_pick_ticket  	 := lc_retransmit_pick_ticket ;
    lr_wsh_dlv_att_obj_type.payment_subtype_cod_ind 	 := lc_payment_subtype_cod_ind;
    lr_wsh_dlv_att_obj_type.del_to_post_office_ind  	 := lc_del_to_post_office_ind ;
    
    xx_wsh_delivery_attributes_pkg.update_row (
                                               x_return_status       =>lc_return_status
                                              ,x_errbuf              =>lc_errbuf
                                              ,p_delivery_attributes =>lr_wsh_dlv_att_obj_type
                                              );    
    
    IF lc_return_status = 'S' THEN
       x_status  := 'S';
    ELSE
       x_status  := 'E';
    END IF;
    

  EXCEPTION
   WHEN OTHERS THEN
     x_status             := 'U';
     --Log Exception
     ---------------
     FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     
     lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR-02';
     lc_error_desc        := FND_MESSAGE.GET;
     lc_entity_ref        := 'Delivery Id';
     lc_entity_ref_id     := p_delivery_id;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );                   
  END Log_Carton_Wmos_Proc_status; 
  
  PROCEDURE  Split_Delivery_Lines( 
                                     p_delivery_detail_id         IN         wsh_delivery_details.delivery_detail_id%TYPE
                                    ,p_sku_quantity               IN         wsh_delivery_details.requested_quantity%TYPE
                                    ,x_splited_delvery_detail_id  OUT NOCOPY wsh_delivery_details.delivery_detail_id%TYPE 
                                    ,x_splited_requested_quantity OUT NOCOPY wsh_delivery_details.requested_quantity%TYPE 
                                    ,x_return_status              OUT NOCOPY VARCHAR2
                                    ,x_msg_count                  OUT NOCOPY PLS_INTEGER
                                    ,x_msg_data                   OUT NOCOPY VARCHAR2
                                    )
  -- +===================================================================+
  -- | Name  : Split_Delivery_Lines                                      |
  -- | Rice Id      : I0030_Cartonization                                | 
  -- | Description: This procedure will cater the requirement, if in a   | 
  -- |              delivery line where the SKU quantity is packed into  |
  -- |              more than 1 carton will be split equal to number of  |
  -- |              cartons and requested quantity on each delivery line | 
  -- |              is updated with container id and SKUs quantity in    |
  -- |              container(carton)                                    | 
  -- |                                                                   |
  -- | Parameters:        p_delivery_detail_id                           |
  -- |                    p_sku_quantity                                 |
  -- |                                                                   |
  -- | Returns :          x_return_status                                |
  -- |			  x_msg_count    				 |
  -- |			  x_msg_data     				 |
  -- |                                                                   |
  -- +===================================================================+
  AS
   
   --Local varibales to this procedure
   ln_splited_dlvery_detail_id     wsh_delivery_details.delivery_detail_id%TYPE;
   ln_split_sku_quantity           wsh_delivery_details.requested_quantity%TYPE;
   ln_split_sku_quantity2          wsh_delivery_details.requested_quantity%TYPE;
   ln_delivery_detail              wsh_delivery_details.delivery_detail_id%TYPE; 
   ln_api_ver                      PLS_INTEGER;
   gc_error_msg                    VARCHAR2(2000);
   
  BEGIN

    lc_return_status := NULL;
    ln_msg_count     := NULL;   
    lc_msg_data      := NULL;    
    ln_split_sku_quantity  := p_sku_quantity;
    ln_delivery_detail     := p_delivery_detail_id;
    ln_api_ver             := 1;
    
    FND_MSG_PUB.INITIALIZE;
    --Standard WSH API to Split Delivery Line.      
    WSH_DELIVERY_DETAILS_PUB.Split_Line(
                                        p_api_version       => ln_api_ver, 
                                        p_init_msg_list     => FND_API.G_FALSE ,
                                        p_commit            => FND_API.G_TRUE,
                                        p_validation_level  => FND_API.G_VALID_LEVEL_FULL,
                                        x_return_status     => lc_return_status,
                                        x_msg_count         => ln_msg_count,
                                        x_msg_data          => lc_msg_data, 
                                        p_from_detail_id    => ln_delivery_detail,
                                        x_new_detail_id     => ln_splited_dlvery_detail_id,
                                        x_split_quantity    => ln_split_sku_quantity,
                                        x_split_quantity2   => ln_split_sku_quantity2
                                        );


    IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN 
          COMMIT;
          x_splited_delvery_detail_id  := ln_splited_dlvery_detail_id;
          x_splited_requested_quantity := ln_split_sku_quantity;
    ELSE
        x_splited_delvery_detail_id  := 0;
        x_splited_requested_quantity := 0;
        IF ln_msg_count = 1 THEN
              x_return_status              := lc_return_status;
              x_msg_count                  := ln_msg_count;
              x_msg_data                   := lc_msg_data;
        ELSE
          FOR l_index IN 1..ln_msg_count 
          LOOP
             gc_error_msg    :=   SUBSTR(FND_MSG_PUB.GET(p_msg_index => l_index
                                                        ,p_encoded => FND_API.G_FALSE),1,255);
             x_return_status              := lc_return_status;
             x_msg_count                  := ln_msg_count;
             x_msg_data                   := gc_error_msg;
          END LOOP;
        END IF;
    END IF; --Return status validation
                     
  EXCEPTION    
   WHEN OTHERS THEN
    x_return_status              := FND_API.G_RET_STS_UNEXP_ERROR;
    x_msg_count                  :=  1 ;
    x_msg_data                   :=  'Unexpected Error on Split Delivery Line: '||SUBSTR(SQLERRM,1,240);
    x_splited_delvery_detail_id  := 0;
    x_splited_requested_quantity := 0;
    
    --Log Exception
    ---------------
    FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    
    lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR-06';
    lc_error_desc        := FND_MESSAGE.GET;
    lc_entity_ref        := 'Delivery Detail Id';
    lc_entity_ref_id     := p_delivery_detail_id;
    log_exceptions(lc_error_code             
                  ,lc_error_desc
                  ,lc_entity_ref       
                  ,lc_entity_ref_id    
                  );                   
  END Split_Delivery_Lines;    
  
  PROCEDURE  Create_Lpn( 
                        p_carton_id             IN  PLS_INTEGER
                       ,p_organization_id       IN  mtl_parameters.organization_id%TYPE
                       ,p_container_name        IN  wsh_delivery_details.container_name%TYPE
                       ,x_container_instance_id OUT NOCOPY PLS_INTEGER
                       ,x_return_status         OUT NOCOPY VARCHAR2
                       ,x_msg_count             OUT NOCOPY PLS_INTEGER
                       ,x_msg_data              OUT NOCOPY VARCHAR2
                      )
  -- +===================================================================+
  -- | Name  : Create_Lpn                                                |
  -- | Rice Id      : I0030_Cartonization                                | 
  -- | Description: This procedure will cater the requirement to create  | 
  -- |              LPN.                                                 |
  -- |                                                                   |
  -- | Parameters:        p_container_item_id                            |
  -- |                    p_organization_id                              |
  -- |                    p_container_name                               |
  -- |                                                                   |
  -- | Returns :          x_return_status                                |
  -- |			  x_msg_count    				 |
  -- |			  x_msg_data     				 |
  -- |                                                                   |
  -- +===================================================================+                             
  AS
  
    lc_container_item_name          mtl_system_items_b.segment1%TYPE;
    lc_container_item_id            mtl_system_items_b.inventory_item_id%TYPE;
    ln_container_item_seg           fnd_flex_ext.segmentarray;
    lc_organization_code            mtl_parameters.organization_code%TYPE;
    lc_name_prefix                  VARCHAR2(4000);
    lc_name_suffix                  VARCHAR2(4000);
    ln_base_number                  PLS_INTEGER;
    ln_num_digits                   PLS_INTEGER;
    container_ids_rec_type          WSH_UTIL_CORE.ID_TAB_TYPE;
    gc_error_msg                    VARCHAR2(2000);
    ln_lpn_quantity                 PLS_INTEGER := 1;
    ln_master_organization_id       mtl_parameters.master_organization_id%TYPE;
    ln_new_container_id             PLS_INTEGER;
    ln_continue                     PLS_INTEGER := 0;
    
  BEGIN
      
      lc_return_status := NULL;
      ln_msg_count     := NULL;
      lc_msg_data      := NULL;
      ln_continue      := 0;
      
      BEGIN
        SELECT organization_code
        INTO   lc_organization_code
        FROM   mtl_parameters 
        WHERE  organization_id = p_organization_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lc_organization_code := NULL;
        WHEN OTHERS THEN
          lc_organization_code := NULL;
      END;  
      IF lc_organization_code IS NULL THEN
        ln_continue     := 1; 
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        x_msg_count     :=  1 ;
        x_msg_data      :=  'Unexpected Error: Could not derive organization code';
      END IF;
      BEGIN
        SELECT MSI.inventory_item_id
        INTO   lc_container_item_id
        FROM   mtl_system_items_b MSI
        WHERE  MSI.segment1            = p_container_name
        AND    MSI.organization_id     = p_organization_id
        AND    MSI.container_item_flag = 'Y';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lc_container_item_id := NULL;
        WHEN OTHERS THEN
          lc_container_item_id := NULL;
      END;  
      
      IF lc_container_item_id IS NULL THEN
        ln_continue     := 1; 
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        x_msg_count     :=  1 ;
        x_msg_data      :=  'Unexpected Error: Could not derive container item id';
      END IF;
      IF ln_continue = 0 THEN
        --Standard WSH API to Create LPN. 
        WSH_CONTAINER_PUB.Create_Containers(
                                            p_api_version           => ln_c_api_version,
                                            p_init_msg_list         => FND_API.G_TRUE,
                                            p_commit                => FND_API.G_TRUE,
                                            p_validation_level      => FND_API.G_VALID_LEVEL_FULL,
                                            x_return_status         => lc_return_status,
                                            x_msg_count             => ln_msg_count,
                                            x_msg_data              => lc_msg_data,
                                            p_container_item_id     => lc_container_item_id, 
                                            p_container_item_name   => p_container_name,     
                                            p_container_item_seg    => ln_container_item_seg ,
                                            p_organization_id       => p_organization_id,
                                            p_organization_code     => lc_organization_code,
                                            p_name_prefix           => lc_name_prefix,
                                            p_name_suffix           => lc_name_suffix,
                                            p_base_number           => ln_base_number,
                                            p_num_digits            => ln_num_digits,
                                            p_quantity              => ln_lpn_quantity,
                                            p_container_name        => TO_CHAR(p_carton_id), --p_container_name, --TO_CHAR(p_organization_id), 
                                            x_container_ids         => container_ids_rec_type
                                           );
      
      
        IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN 
          COMMIT;
          x_container_instance_id := container_ids_rec_type(1);
          x_return_status         := lc_return_status;
          x_msg_count             := ln_msg_count;
          x_msg_data              := lc_msg_data;
        ELSE
           x_container_instance_id := 0;
           IF ln_msg_count = 1 THEN
              x_return_status      := lc_return_status;
              x_msg_count          := ln_msg_count;
              x_msg_data           := lc_msg_data;
           ELSE
              FOR l_index IN 1..ln_msg_count 
              LOOP
                gc_error_msg    :=   SUBSTR(FND_MSG_PUB.GET(p_msg_index => l_index
                                                           ,p_encoded => FND_API.G_FALSE),1,255);
                x_return_status      := lc_return_status;
                x_msg_count          := ln_msg_count;
                x_msg_data           := gc_error_msg;
              END LOOP;
           END IF;
        END IF; --Return status validation
      END IF; 
      
  EXCEPTION    
   WHEN OTHERS THEN 
     x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
     x_msg_count     :=  1 ;
     x_msg_data      :=  'Unexpected Error on Creating LPN: '||SUBSTR(SQLERRM,1,240);
     
     --Log Exception
     ---------------
     FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     
     lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR-03';
     lc_error_desc        := FND_MESSAGE.GET;
     lc_entity_ref        := 'Organization_id';
     lc_entity_ref_id     := p_organization_id;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );                   
  END Create_Lpn;
  
  PROCEDURE Assign_Lpn( 
                       p_delivery_detail_id    IN  wsh_delivery_details.delivery_detail_id%TYPE
                      ,p_container_instance_id IN  PLS_INTEGER
                      ,x_return_status         OUT NOCOPY VARCHAR2
                      ,x_msg_count             OUT NOCOPY PLS_INTEGER
                      ,x_msg_data              OUT NOCOPY VARCHAR2
                      )
  -- +===================================================================+
  -- | Name  : Assign_Lpn                                                |
  -- | Rice Id      : I0030_Cartonization                                | 
  -- | Description: This procedure will cater the requirement to assign  | 
  -- |              LPN to the Delivery.                                 |
  -- |                                                                   |
  -- | Parameters:        p_container_item_id                            |
  -- |                    p_organization_id                              |
  -- |                    p_container_name                               |
  -- |                                                                   |
  -- | Returns :          x_return_status                                |
  -- |			  x_msg_count    				 |
  -- |			  x_msg_data     				 |
  -- |                                                                   |
  -- +===================================================================+                              
  IS

  detail_tab_rec_type             WSH_UTIL_CORE.ID_TAB_TYPE;
  ln_cont_instance_id             PLS_INTEGER ;
  gc_error_msg                    VARCHAR2(2000);
  ln_delivery_name                wsh_new_deliveries.name%TYPE;
  ln_delivery_id                  wsh_new_deliveries.delivery_id%TYPE;
  lc_container_name               wsh_delivery_details.container_name%TYPE; 
  
  BEGIN

      lc_return_status        := NULL;
      ln_msg_count            := NULL;
      lc_msg_data             := NULL;
      g_c_action_code         := NULL;
      g_c_action_code         := 'PACK';
      
      detail_tab_rec_type(1)  := p_delivery_detail_id;
      ln_cont_instance_id     := p_container_instance_id;
      
      WSH_CONTAINER_PUB.Container_Actions(
                                          p_api_version       => ln_c_api_version,
                                          p_init_msg_list     => FND_API.G_TRUE,
                                          p_commit            => FND_API.G_TRUE,
                                          p_validation_level  => FND_API.G_VALID_LEVEL_FULL,
                                          x_return_status     => lc_return_status,
                                          x_msg_count         => ln_msg_count,
                                          x_msg_data          => lc_msg_data,
                                          p_detail_tab        => detail_tab_rec_type,
                                          p_container_name    => lc_container_name,  
                                          p_cont_instance_id  => ln_cont_instance_id, -- It should be always 1, if only one LPN is being vreated
                                          p_container_flag    => g_c_container_flag,
                                          p_delivery_flag     => g_c_delivery_flag,
                                          p_delivery_id       => ln_delivery_id,  
                                          p_delivery_name     => ln_delivery_name,
                                          p_action_code       => g_c_action_code
                                         ); 
                                         
      IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN 
          COMMIT;
          x_return_status      := lc_return_status;
          x_msg_count          := ln_msg_count;
          x_msg_data           := lc_msg_data;
      ELSE
           
           IF ln_msg_count = 1 THEN
              x_return_status      := lc_return_status;
              x_msg_count          := ln_msg_count;
              x_msg_data           := lc_msg_data;
           ELSE
              FOR l_index IN 1..ln_msg_count 
              LOOP
                gc_error_msg    :=   SUBSTR(FND_MSG_PUB.GET(p_msg_index => l_index
                                                           ,p_encoded => FND_API.G_FALSE),1,255);
                x_return_status      := lc_return_status;
                x_msg_count          := ln_msg_count;
                x_msg_data           := gc_error_msg;
              END LOOP;
           END IF;
      END IF; --Return status validation
          
  EXCEPTION    
  WHEN OTHERS THEN
     x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
     x_msg_count     :=  1 ;
     x_msg_data      :=  'Unexpected Error on Assigning LPN: '||SUBSTR(SQLERRM,1,240);
     
     --Log Exception
     ---------------
     FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     
     lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR-04';
     lc_error_desc        := FND_MESSAGE.GET;
     lc_entity_ref        := 'Delivery Detail Id';
     lc_entity_ref_id     := p_delivery_detail_id;
     log_exceptions(lc_error_code             
                   ,lc_error_desc
                   ,lc_entity_ref       
                   ,lc_entity_ref_id    
                   );
  END Assign_Lpn;

  PROCEDURE Update_Addl_Delivery_Dtls_Info
                           ( 
                            p_delivery_detail_id  IN  wsh_delivery_details.delivery_detail_id%TYPE
                           ,p_carton_length       IN  wsh_delivery_details.Attribute1%TYPE
                           ,p_carton_width        IN  wsh_delivery_details.Attribute2%TYPE
                           ,p_carton_height       IN  wsh_delivery_details.Attribute3%TYPE
                           ,p_uom                 IN  wsh_delivery_details.Attribute4%TYPE
                           ,x_status              OUT NOCOPY VARCHAR2
                           )
  -- +===================================================================+
  -- | Name  : Update_Addl_Delivery_Dtls_Info                            |
  -- | Rice Id      : I0030_Cartonization                                | 
  -- | Description:       This Procedure will cater the requirement to   |
  -- |                    update the Additional Delivery Detail          |
  -- |                    Information of Carton Length, Carton Width,    |
  -- |                    Carton Height and the LxWxH UOM.               |
  -- | Parameters                                                        |
  -- | IN        :        p_delivery_detail_id                           |
  -- |			  p_carton_length                                |
  -- |			  p_carton_width			         |
  -- |			  p_carton_height				 |
  -- |			  p_uom                                          |
  -- |									 |
  -- | Returns   :        x_status                                       |
  -- |                                                                   |
  -- +===================================================================+
  AS
  
  lc_delivery_detail_id             xx_wsh_delivery_det_att_all.delivery_detail_id%TYPE;
  lc_pkt_transmission_ind           xx_wsh_delivery_det_att_all.pkt_transmission_ind%TYPE;
  lc_del_creation_ind               xx_wsh_delivery_det_att_all.del_creation_ind%TYPE;
  lc_old_delivery_number            xx_wsh_delivery_det_att_all.old_delivery_number%TYPE;
  lc_backtoback_del_creation_ind    xx_wsh_delivery_det_att_all.backtoback_del_creation_ind%TYPE;
  ln_lpn_length                     xx_wsh_delivery_det_att_all.lpn_length%TYPE;
  ln_lpn_width                      xx_wsh_delivery_det_att_all.lpn_width%TYPE;
  ln_lpn_height                     xx_wsh_delivery_det_att_all.lpn_height%TYPE; 
  lc_lpn_type                       xx_wsh_delivery_det_att_all.lpn_type%TYPE;
  ln_count                          PLS_INTEGER;
  lc_errbuf                         VARCHAR2(1000);
  lc_return_status                  VARCHAR2(40)  ;
  
  BEGIN
    lr_wsh_dlv_det_att_obj_type.delivery_detail_id           := p_delivery_detail_id          ;
    lr_wsh_dlv_det_att_obj_type.pkt_transmission_ind         := lc_pkt_transmission_ind       ;
    lr_wsh_dlv_det_att_obj_type.del_creation_ind             := lc_del_creation_ind           ;
    lr_wsh_dlv_det_att_obj_type.old_delivery_number          := lc_old_delivery_number        ;
    lr_wsh_dlv_det_att_obj_type.backtoback_del_creation_ind  := lc_backtoback_del_creation_ind;
    lr_wsh_dlv_det_att_obj_type.lpn_length                   := p_carton_length               ;
    lr_wsh_dlv_det_att_obj_type.lpn_width                    := p_carton_width                ;
    lr_wsh_dlv_det_att_obj_type.lpn_height                   := p_carton_height               ;
    lr_wsh_dlv_det_att_obj_type.lpn_type                     := p_uom                         ;
    ln_count                                                 := 0                             ;  
    
    SELECT COUNT(1)
    INTO   ln_count
    FROM   xx_wsh_delivery_det_att_all
    WHERE  delivery_detail_id = p_delivery_detail_id;
    
    IF  ln_count > 0 THEN
        xx_wsh_delivery_det_att_pkg.update_row (
                                                 x_return_status               =>lc_return_status
                                                ,x_errbuf                      =>lc_errbuf
                                                ,p_delivery_details_attributes =>lr_wsh_dlv_det_att_obj_type
                                               );
    ELSE
        xx_wsh_delivery_det_att_pkg.insert_row (
                                                 x_return_status               =>lc_return_status
                                                ,x_errbuf                      =>lc_errbuf
                                                ,p_delivery_details_attributes =>lr_wsh_dlv_det_att_obj_type
                                               );    
    END IF;
    
    IF lc_return_status = 'S' THEN
       x_status  := 'S';
    ELSE
       x_status  := 'E';
    END IF;   
    
  EXCEPTION
   WHEN OTHERS THEN
    x_status             := 'U';
    --Log Exception
    ---------------
    FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
   
    lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR-04';
    lc_error_desc        := FND_MESSAGE.GET;
    lc_entity_ref        := 'Delivery Detail Id';
    lc_entity_ref_id     := p_delivery_detail_id;
    log_exceptions(lc_error_code             
                  ,lc_error_desc
                  ,lc_entity_ref       
                  ,lc_entity_ref_id    
                  );                   
  END Update_Addl_Delivery_Dtls_Info;

  PROCEDURE Update_Addl_Delivery_Info( 
                                      p_delivery_id   IN  wsh_new_deliveries.delivery_id%TYPE
                                     ,p_number_of_lpn IN  wsh_new_deliveries.number_of_lpn%TYPE
                                     ,p_gross_weight  IN  wsh_new_deliveries.gross_weight%TYPE
                                     ,p_volume        IN  wsh_new_deliveries.volume%TYPE
                                     ,x_return_status OUT NOCOPY VARCHAR2
                                     ,x_msg_count     OUT NOCOPY PLS_INTEGER
                                     ,x_msg_data      OUT NOCOPY VARCHAR2
                                     )
  -- +===================================================================+
  -- | Name  : Update_Addl_Delivery_Info                                 |
  -- | Rice Id      : I0030_Cartonization                                | 
  -- | Description:       This Procedure will cater the requirement to   |
  -- |                    update the Additional Delivery Information of  |
  -- |                    of Total No Of Carton, Gross Weight and        |
  -- |                    Total Volume.                                  |
  -- | Parameters                                                        |
  -- | IN        :        p_delivery_id                                  |
  -- |			  p_number_of_lpn                                |
  -- |			  p_gross_weight			         |
  -- |			  p_volume				         |
  -- |									 |
  -- | Returns   :        x_status                                       |
  -- |                                                                   |
  -- +===================================================================+                        
  AS

   lc_name                         VARCHAR2(4000);
   ln_delivery_id                  wsh_new_deliveries.delivery_id%TYPE;
   delivery_info_rec_type          wsh_deliveries_pub.delivery_pub_rec_type;
   gc_error_msg                    VARCHAR2(2000);
  
  BEGIN
    
    lc_return_status                        := NULL;
    ln_msg_count                            := NULL;
    lc_msg_data                             := NULL;
    g_c_action_code                         := NULL;
    g_c_action_code                         := 'UPDATE';  
    delivery_info_rec_type.delivery_id      :=  p_delivery_id;
    delivery_info_rec_type.number_of_lpn    :=  p_number_of_lpn;
    delivery_info_rec_type.gross_weight     :=  p_gross_weight;
    delivery_info_rec_type.volume           :=  p_volume;
    WSH_DELIVERIES_PUB.Create_Update_Delivery( 
                                             p_api_version_number   => ln_c_api_version,
                                             p_init_msg_list        => FND_API.G_TRUE,
                                             x_return_status        => lc_return_status,
                                             x_msg_count            => ln_msg_count,
                                             x_msg_data             => lc_msg_data,
                                             p_action_code          => g_c_action_code,
                                             p_delivery_info        => delivery_info_rec_type,
                                             p_delivery_name        => FND_API.G_NULL_CHAR,    --FND_API.G_MISS_CHAR,
                                             x_delivery_id          => ln_delivery_id,
                                             x_name                 => lc_name
                                            );
    
    
      IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN 
          COMMIT;
          x_return_status      := lc_return_status;
          x_msg_count          := ln_msg_count;
          x_msg_data           := lc_msg_data;
      ELSE
           
           IF ln_msg_count = 1 THEN
              x_return_status      := lc_return_status;
              x_msg_count          := ln_msg_count;
              x_msg_data           := lc_msg_data;
           ELSE
              FOR l_index IN 1..ln_msg_count 
              LOOP
                gc_error_msg    :=   SUBSTR(FND_MSG_PUB.GET(p_msg_index => l_index
                                                           ,p_encoded => FND_API.G_FALSE),1,255);
                x_return_status      := lc_return_status;
                x_msg_count          := ln_msg_count;
                x_msg_data           := gc_error_msg;
              END LOOP;
           END IF;
      END IF; --Return status validation

  EXCEPTION    
   WHEN OTHERS THEN 
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    x_msg_count     :=  1 ;
    x_msg_data      :=  'Unexpected Error on Update of Addl Delv Info: '||SUBSTR(SQLERRM,1,240);
    
    --Log Exception
    ---------------
    FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    
    lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR-05';
    lc_error_desc        := FND_MESSAGE.GET;
    lc_entity_ref        := 'Delivery Id';
    lc_entity_ref_id     := p_delivery_id;
    log_exceptions(lc_error_code             
                  ,lc_error_desc
                  ,lc_entity_ref       
                  ,lc_entity_ref_id    
                  );
    
  END Update_Addl_Delivery_Info; 

  PROCEDURE Process_Cartonization_Wmos(
                                       p_showshipunit_firstlvl_tbl   IN  xx_om_showship_firstlvl_tbl
                                      ,x_status                      OUT NOCOPY VARCHAR2
                                      ,x_errcode                     OUT NOCOPY NUMBER
                                      )
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
  -- |                                                                   |
  -- | Parameters                                                        |
  -- | IN        :        p_rec_showshipunit_firstlvl_t                  |
  -- |			  p_rec_showshipunit_seclvl_t                    |
  -- |			  p_rec_showshipunit_thirdlvl_t			 |
  -- |									 |
  -- | Returns   :        x_status                                       |
  -- |                    x_errcode -- 0 = Success                       |  
  -- |                              -- 1 = Error                         |  
  -- |                                                                   |
  -- +===================================================================+
  AS
    lc_status                       VARCHAR2(2);
    lc_errcode                      PLS_INTEGER := 0;
    ln_no_of_cartons                PLS_INTEGER := 0;
    ln_proceed                      PLS_INTEGER := 0;
    ln_organization_id              wsh_delivery_details.organization_id%TYPE;
    ln_cartonization_eligible       PLS_INTEGER := 0;
    ln_split_line_flg               PLS_INTEGER := 0;
    ln_delvery_detail_id            wsh_delivery_details.delivery_detail_id%TYPE;
    ln_splited_delvery_detail_id    wsh_delivery_details.delivery_detail_id%TYPE;
    ln_splited_requested_quantity   wsh_delivery_details.requested_quantity%TYPE;
    ln_lpn_assigned_flg             PLS_INTEGER := 0;
    ln_container_exists             PLS_INTEGER := 0;
    ln_req_quantity                 wsh_delivery_details.requested_quantity%TYPE;
    ln_container_instance_id        PLS_INTEGER := 0;
    ln_chk_ignore_for_planning      PLS_INTEGER := 0;
    
    ln_firstlvl_delivery_id        wsh_new_deliveries.delivery_id%TYPE;
    ln_seclvl_delivery_id          wsh_new_deliveries.delivery_id%TYPE; 
    ln_thirdlvl_delivery_number    wsh_new_deliveries.delivery_id%TYPE;     
    
  BEGIN
     
    ln_proceed       := 0;
    ln_no_of_cartons := 0;
    
    -- Process to initialize the apps environment
    SELECT  user_id
    INTO    g_n_user_id
    FROM    fnd_user
    WHERE   user_name = g_c_user_name;
    
    SELECT  responsibility_id,
            application_id
    INTO    g_n_resp_id
           ,g_n_resp_app_id
    FROM    fnd_responsibility_vl
    WHERE   responsibility_name = g_c_resp_name;
    
    FND_GLOBAL.APPS_INITIALIZE(g_n_user_id, g_n_resp_id, g_n_resp_app_id);
    
    lt_showshipunit_firstlvl_tbl  :=     p_showshipunit_firstlvl_tbl;   
      
    --Opening the loop for the top level record type
    FOR I_firstlvl IN lt_showshipunit_firstlvl_tbl.first..lt_showshipunit_firstlvl_tbl.last
    LOOP
      ln_firstlvl_delivery_id := 0;
      ln_firstlvl_delivery_id := lt_showshipunit_firstlvl_tbl(I_firstlvl).delivery_id;
      
      SELECT COUNT(1)
      INTO   ln_cartonization_eligible
      FROM   wsh_new_deliveries       WND
            ,xx_wsh_delivery_att_all  XWDA 
      WHERE  WND.delivery_id = ln_firstlvl_delivery_id
      AND    WND.delivery_id = XWDA.delivery_id
      AND    XWDA.od_internal_delivery_status  = g_cartonization_eligible;
      
      IF ln_cartonization_eligible > 0 THEN
      
        --Updating cartonization process status for the Delivery 
        Log_Carton_Wmos_Proc_status( 
                                    ln_firstlvl_delivery_id
                                   ,g_cartonization_started
                                   ,lc_status
                                   );
        
        IF lc_status <> FND_API.G_RET_STS_SUCCESS THEN
	    ln_proceed := 1;
        END IF;
        
        IF ln_proceed = 0 THEN
          --Check XML Error in first level attributes
          IF (lt_showshipunit_firstlvl_tbl(I_firstlvl).ProcStatCode) > 0 THEN
              ln_proceed := 1;
              --Log Exceptions
              FND_MESSAGE.SET_NAME('XXOM','XX_OM_65502_CWMOS_1ST_LVL_ERR');
              lc_error_code        := 'XX_OM_65502_CWMOS_1ST_LVL_ERR';
              lc_error_desc        := FND_MESSAGE.GET;
              lc_entity_ref        := 'Delivery Id';
              lc_entity_ref_id     := ln_firstlvl_delivery_id;
              x_status             := 'E';
              x_errcode            := 1;
              log_exceptions(lc_error_code   
                            ,lc_error_desc
                            ,lc_entity_ref   
                            ,lc_entity_ref_id
                            );               
          END IF;
        END IF; 

        IF  ln_proceed = 0 THEN
          
          --Opening the loop for the 2nd level record type
          FOR I_seclvl IN lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl.first..lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl.last
          LOOP
            --Check XML Error in 2nd level attributes
            ln_seclvl_delivery_id := 0;
            ln_seclvl_delivery_id := lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).delivery_id;

            IF lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).ProcStatCode > 0 THEN
              --Log Exceptions
              FND_MESSAGE.SET_NAME('XXOM','XX_OM_65503_CWMOS_2ND_LVL_ERR');
              lc_error_code        := 'XX_OM_65503_CWMOS_2ND_LVL_ERR';
              lc_error_desc        := FND_MESSAGE.GET;
              lc_entity_ref        := 'Delivery Id';
              lc_entity_ref_id     := ln_seclvl_delivery_id; --lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).delivery_id;
              x_status             := 'E';
              x_errcode            := 1;
              log_exceptions(lc_error_code   
                            ,lc_error_desc
                            ,lc_entity_ref   
                            ,lc_entity_ref_id
                            );               
            ELSE          

              IF ln_firstlvl_delivery_id = ln_seclvl_delivery_id THEN  
              
                --Opening the loop for the 3rd level record type         
                FOR I_thirdlvl IN lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl.first..lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl.last
                LOOP

                  --Check XML Error in 3rd level attributes
                  IF lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).ProcStatCode > 0 THEN
                    --Log Exceptions
                    FND_MESSAGE.SET_NAME('XXOM','XX_OM_65504_CWMOS_3RD_LVL_ERR');
                    lc_error_code        := 'XX_OM_65504_CWMOS_3RD_LVL_ERR';
                    lc_error_desc        := FND_MESSAGE.GET;
                    lc_entity_ref        := 'Delivery Id';
                    lc_entity_ref_id     := lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).delivery_number;
                    x_status             := 'E';
                    x_errcode            := 1;
                    log_exceptions(lc_error_code   
                                  ,lc_error_desc
                                  ,lc_entity_ref   
                                  ,lc_entity_ref_id
                                  );               
                  ELSE          

                     ln_thirdlvl_delivery_number := 0;
                     ln_thirdlvl_delivery_number := lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).delivery_number;
                    IF ln_seclvl_delivery_id = ln_thirdlvl_delivery_number THEN
                      --Validating that carton number should be same 
                      
                      IF lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).container_id = lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).container_id THEN
                        
                        --Assigning the parent delivery detail id
                        ln_delvery_detail_id  := 0;
                        ln_delvery_detail_id  := lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).delivery_detail_id;
                        
                        --Updating cartonization process status for the Delivery 
                        Log_Carton_Wmos_Proc_status( 
                                                    ln_firstlvl_delivery_id
                                                   ,g_lpn_started
                                                   ,lc_status
                                                   );
  			
                        IF lc_status <> FND_API.G_RET_STS_SUCCESS THEN
                             ln_proceed := 1;
                        END IF;

                        IF ln_proceed = 0 THEN
                          ln_proceed      := 0;
                          --Validating the Sku Qty with Parent Qty in Delivery Lines
                          BEGIN
                          
                            SELECT NVL(WDD.requested_quantity,0) requested_quantity
                            INTO   ln_req_quantity
                            FROM   wsh_new_deliveries       WND
                                  ,wsh_delivery_assignments WDA
                                  ,wsh_delivery_details     WDD
                            WHERE  WDA.delivery_id        = WND.delivery_id
                            AND    WND.delivery_id        = lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).delivery_number 
                            AND    WDA.delivery_detail_id = WDD.delivery_detail_id
                            AND    WDD.delivery_detail_id = ln_delvery_detail_id
                            AND    WDD.inventory_item_id  = lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).inventory_item_id;

                          EXCEPTION
                           WHEN NO_DATA_FOUND THEN
                             ln_req_quantity := 0;
                             ln_proceed      := 1;
                             FND_MESSAGE.SET_NAME('XXOM','XX_OM_65511_CWMOS_NULL_REQQTY');
                             lc_error_code        := 'XX_OM_65511_CWMOS_NULL_REQQTY';
                             lc_error_desc        := FND_MESSAGE.GET;
                             lc_entity_ref        := 'Delivery Id';
                             lc_entity_ref_id     := lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).delivery_number;
                           WHEN OTHERS THEN  
                             ln_req_quantity := 0;
                             ln_proceed      := 1;
                             FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
                             FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                             FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                            
                             lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR-05';
                             lc_error_desc        := FND_MESSAGE.GET;
                             lc_entity_ref        := 'Delivery Id';
                             lc_entity_ref_id     := lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).delivery_number;
                          END;   
                          
                          IF ln_proceed  > 0 THEN
                             ln_split_line_flg := 1;
                             log_exceptions(lc_error_code             
                                          ,lc_error_desc
                                          ,lc_entity_ref       
                                          ,lc_entity_ref_id    
                                          );
                          END IF;  
                          
                          IF ln_proceed = 0 THEN
                            IF ln_req_quantity = NVL((lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).requested_quantity),0) THEN
                               ln_split_line_flg   := 1;
                            ELSIF ln_req_quantity > NVL((lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).requested_quantity),0) THEN
                               ln_split_line_flg   := 0;
                            ELSIF ln_req_quantity < NVL((lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).requested_quantity),0) THEN   
                                 ln_split_line_flg := 1;
                                 ln_proceed        := 1;
                            END IF;
                          END IF;

                          IF ln_split_line_flg = 0 THEN
                          
                             ln_proceed := 0;
                            -- Spliting Delivery Detail Line if the Sku Qty does not matches 
                            -- with Parent Qty in Delivery Lines.
                               
                            lc_return_status := NULL;
                            ln_msg_count     := NULL;
                            lc_msg_data      := NULL;
                            
                            --Call the procedure to split delivery detail lines
                            Split_Delivery_Lines(  
                                                 p_delivery_detail_id         => ln_delvery_detail_id
                                                ,p_sku_quantity               => lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).requested_quantity
                                                ,x_splited_delvery_detail_id  => ln_splited_delvery_detail_id
                                                ,x_splited_requested_quantity => ln_splited_requested_quantity
                                                ,x_return_status              => lc_return_status
                                                ,x_msg_count                  => ln_msg_count    
                                                ,x_msg_data                   => lc_msg_data     
                                                );
                                                
                            ln_delvery_detail_id := ln_splited_delvery_detail_id;
                            
                            --Validate API Return status
                            IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN 
                                ln_proceed := 0;
                                --This code is to the bug of validating Ignore for Planning statuses are different
                                SELECT COUNT(1)
                                INTO   ln_chk_ignore_for_planning
                                FROM   wsh_delivery_details WDD
                                WHERE  delivery_detail_id = ln_delvery_detail_id
                                AND    ignore_for_planning = 'Y';
                                
                                IF ln_chk_ignore_for_planning = 0 THEN
                                  
                                  UPDATE wsh_delivery_details
                                  SET    ignore_for_planning = 'Y'
                                  WHERE  delivery_detail_id = ln_delvery_detail_id
                                  AND    ignore_for_planning <> 'Y';
                                  COMMIT;
                                END IF;
                               
                            ELSE
                                 ln_proceed := 1;

                                 FND_MESSAGE.SET_NAME('XXOM','XX_OM_65510_CWMOS_SPLT_FAILED');
                                 IF ln_msg_count = 1 THEN
                                    lc_error_code        := 'XX_OM_65510_CWMOS_SPLT_FAILED';
                                    lc_error_desc        := FND_MESSAGE.GET;
                                    lc_entity_ref        := 'Delivery Id';
                                    lc_entity_ref_id     := lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).delivery_number;
                                    log_exceptions(lc_error_code             
                                                  ,lc_error_desc
                                                  ,lc_entity_ref       
                                                  ,lc_entity_ref_id    
                                                  );                   
                                 ELSE
                                    FOR l_index IN 1..ln_msg_count 
                                    LOOP
                                      lc_error_code        := 'XX_OM_65510_CWMOS_SPLT_FAILED';
                                      lc_error_desc        := FND_MESSAGE.GET;
                                      lc_entity_ref        := 'Delivery Id';
                                      lc_entity_ref_id     := lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).delivery_number;
                                      log_exceptions(lc_error_code             
                                                    ,lc_error_desc
                                                    ,lc_entity_ref       
                                                    ,lc_entity_ref_id    
                                                    );                   
                                    END LOOP;
                                 END IF;
                            END IF; --Return status validation
                          END IF;--End of Delv Line Spliting Process
                        END IF;--End of updating status as LPN Started
                          
                        IF ln_proceed = 0 THEN  --If split line suceeds then start create LPN
                            --Process to Create LPN
                            lc_return_status := NULL;
                            ln_msg_count     := NULL;
                            lc_msg_data      := NULL;
                            
                            BEGIN
                              --Obtain the organization_id
                              SELECT WDD.organization_id
                              INTO   ln_organization_id
                              FROM   wsh_delivery_details WDD
                              WHERE  WDD.delivery_detail_id  = ln_delvery_detail_id 
                              AND    WDD.inventory_item_id   = lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).inventory_item_id;
                            EXCEPTION
                              WHEN NO_DATA_FOUND THEN
                                ln_proceed := 1;
                                FND_MESSAGE.SET_NAME('XXOM','XX_OM_65513_CWMOS_NUL_INV_ORG'); 
                                lc_error_code        := 'XX_OM_65513_CWMOS_NUL_INV_ORG'; 
                                lc_error_desc        := FND_MESSAGE.GET; 
                                lc_entity_ref        := 'Delivery Detail Id'; 
                                lc_entity_ref_id     := ln_delvery_detail_id ;
                              WHEN OTHERS THEN
                                ln_proceed := 1;
                                FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
                                FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                                FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                                lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR-06';
                                lc_error_desc        := FND_MESSAGE.GET;
                                lc_entity_ref        := 'Delivery Detail Id';
                                lc_entity_ref_id     := ln_delvery_detail_id ;
                            END;  

                            IF ln_proceed > 0 THEN                          
                             log_exceptions(lc_error_code   
                                           ,lc_error_desc 
                                           ,lc_entity_ref   
                                           ,lc_entity_ref_id
                                          );               
                             lc_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
                             ln_msg_count     := 1;
                             lc_msg_data      := lc_error_desc;
                            ELSE
                              
                              SELECT COUNT(1)
                              INTO  ln_container_exists
                              FROM  wsh_delivery_details WDD
                              WHERE WDD.source_code = 'WSH'
                              AND   WDD.item_description =   (
                                                              SELECT MSI.description
                              				      FROM   mtl_system_items_b MSI
                              				      WHERE  MSI.segment1          = lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).carton_type
                              				      AND    MSI.inventory_item_id = WDD.inventory_item_id
                              				      AND    MSI.organization_id   = ln_organization_id
                              				      AND    MSI.container_item_flag = 'Y' 
                                                             )
                              AND   WDD.organization_id    = ln_organization_id
                              AND   WDD.container_name     = TO_CHAR(lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).container_id)
                              AND   WDD.delivery_detail_id = source_line_id
                              AND   WDD.container_flag     = 'Y';

                              IF ln_container_exists = 0 THEN
                                
                                Create_Lpn( 
                                           p_carton_id             => lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).container_id
                                          ,p_organization_id       => ln_organization_id
                                          --Parameter Container Name, passed as Carton Type, which is based on
                                          --Closed Issue#:10 of MD070 Resolution by Milind.
                                          ,p_container_name        => lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).carton_type
                                          ,x_container_instance_id => ln_container_instance_id
                                          ,x_return_status         => lc_return_status
                                          ,x_msg_count             => ln_msg_count    
                                          ,x_msg_data              => lc_msg_data     
                                         );
                                 
                              ELSE
                                 lc_return_status := FND_API.G_RET_STS_SUCCESS;
                                 ln_proceed := 0; 
                              END IF;
                              
                            END IF;
                          
                            --Validate API Return status
                            IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN 
                                ln_proceed := 0;
                                COMMIT; 
                              
                            ELSE 
                              ln_proceed := 1;
                              FND_MESSAGE.SET_NAME('XXOM','XX_OM_65505_CWMOS_LPN_FAILED'); 
                              IF ln_msg_count = 1 THEN 
                                  lc_error_code        := 'XX_OM_65505_CWMOS_LPN_FAILED'; 
                                  lc_error_desc        := FND_MESSAGE.GET; 
                                  lc_entity_ref        := 'Delivery Id'; 
                                  lc_entity_ref_id     := ln_delvery_detail_id; 
                                  log_exceptions(lc_error_code              
                                                ,lc_error_desc 
                                                ,lc_entity_ref        
                                                ,lc_entity_ref_id     
                                                );                    
                              ELSE 
                                 FOR l_index IN 1..ln_msg_count  
                                 LOOP 
                                    lc_error_code        := 'XX_OM_65505_CWMOS_LPN_FAILED'; 
                                    lc_error_desc        := FND_MESSAGE.GET; 
                                    lc_entity_ref        := 'Delivery Id'; 
                                    lc_entity_ref_id     := ln_delvery_detail_id;
                                    log_exceptions(lc_error_code              
                                                  ,lc_error_desc 
                                                  ,lc_entity_ref        
                                                  ,lc_entity_ref_id     
                                                  );                    
                                 END LOOP; 
                              END IF; 
                            END IF; --Return status validation 
                        END IF; --End of If split line suceeds then start create LPN

                        --If LPN Creation succeeds then Assign LPN
                        IF ln_proceed = 0 THEN
                          --Assign LPN to Delivery Detail Line
                          IF NVL(ln_container_instance_id,0) = 0 THEN

                           BEGIN 
                             SELECT WDD.delivery_detail_id
                             INTO  ln_container_instance_id
                             FROM  wsh_delivery_details WDD
                             WHERE WDD.source_code = 'WSH'
                             AND   WDD.item_description =   (
                                                             SELECT MSI.description
                                                             FROM   mtl_system_items_b MSI
                                                             WHERE  MSI.segment1          = lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).carton_type
                                                             AND    MSI.inventory_item_id = WDD.inventory_item_id
                                                             AND    MSI.organization_id   = ln_organization_id
                                                             AND    MSI.container_item_flag = 'Y' 
                                                             )
                             AND   WDD.organization_id    = ln_organization_id 
                             AND   WDD.delivery_detail_id = source_line_id
                             AND   WDD.container_name     = TO_CHAR(lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).container_id)
                             AND   WDD.container_flag     = 'Y'
                             AND NOT EXISTS (
                                         SELECT 1
                                         FROM   wsh_delivery_details wddtl,
                                                wsh_delivery_assignments wdda
                                         WHERE  wdda.delivery_detail_id        = wddtl.delivery_detail_id
                                         AND    wdda.parent_delivery_detail_id = WDD.delivery_detail_id  
                                         );
                           EXCEPTION
                             WHEN NO_DATA_FOUND THEN
                               ln_proceed := 1;
                               ln_container_instance_id := NULL;
                               FND_MESSAGE.SET_NAME('XXOM','XX_OM_65514_CWMOS_CONT_EXISTS'); 
                               lc_error_code        := 'XX_OM_65514_CWMOS_CONT_EXISTS'; 
                               lc_error_desc        := FND_MESSAGE.GET; 
                               lc_entity_ref        := 'Delivery Detail Id'; 
                               lc_entity_ref_id     := ln_delvery_detail_id ;
                             WHEN OTHERS THEN
                               ln_proceed := 1;
                               ln_container_instance_id := NULL;
                               FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
                               FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                               FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                               lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR-06';
                               lc_error_desc        := FND_MESSAGE.GET;
                               lc_entity_ref        := 'Delivery Detail Id';
                               lc_entity_ref_id     := ln_delvery_detail_id ;
                           END;
                           
                          END IF;

                          IF ln_proceed > 0 THEN
                            log_exceptions(lc_error_code              
                                          ,lc_error_desc 
                                          ,lc_entity_ref        
                                          ,lc_entity_ref_id     
                                          );                    
                          END IF;

                          IF ln_proceed = 0 THEN    
                              Assign_Lpn( 
                                         p_delivery_detail_id    => ln_delvery_detail_id  --If splited then the new or else the parent dlv_dtl_id
                                        ,p_container_instance_id => ln_container_instance_id 
                                        ,x_return_status         => lc_return_status
                                        ,x_msg_count             => ln_msg_count    
                                        ,x_msg_data              => lc_msg_data     
                                        );

                              --Validate API Return status
                              IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN  
                                  COMMIT; 
                              ELSE 
                             
                                ln_proceed := 1;
                                FND_MESSAGE.SET_NAME('XXOM','XX_OM_65506_CWMOS_ASGNLPNFAIL'); 
                                IF ln_msg_count = 1 THEN 
                                    lc_error_code        := 'XX_OM_65506_CWMOS_ASGNLPNFAIL'; 
                                    lc_error_desc        := FND_MESSAGE.GET; 
                                    lc_entity_ref        := 'Delivery Id'; 
                                    lc_entity_ref_id     := ln_delvery_detail_id;
                                    log_exceptions(lc_error_code              
                                                  ,lc_error_desc 
                                                  ,lc_entity_ref        
                                                  ,lc_entity_ref_id     
                                                  );                    
                                ELSE 
                                   FOR l_index IN 1..ln_msg_count  
                                   LOOP 
                                      lc_error_code        := 'XX_OM_65506_CWMOS_ASGNLPNFAIL'; 
                                      lc_error_desc        := FND_MESSAGE.GET; 
                                      lc_entity_ref        := 'Delivery Id'; 
                                      lc_entity_ref_id     := ln_delvery_detail_id;
                                      log_exceptions(lc_error_code              
                                                    ,lc_error_desc 
                                                    ,lc_entity_ref        
                                                    ,lc_entity_ref_id     
                                                    );                    
                                   END LOOP; 
                                END IF; 
                              END IF; --Return status validation 
                          END IF; --End of check where LPN Already exists    
                          
                        END IF; --End of chk where LPN Creation succeeds, then Assign LPN

                        --If LPN Assignment to delivery succeeds, then update Addl Dlv Dtl Info 
                        IF ln_proceed = 0 THEN
                              --Update Additional Delivery Detail Info
                              lc_status  := NULL;
                              ln_proceed := 0;
                              
                              Update_Addl_Delivery_Dtls_Info
			                               ( 
			                                p_delivery_detail_id  => ln_delvery_detail_id
			                               ,p_carton_length       => lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).length
			                               ,p_carton_width        => lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).width
			                               ,p_carton_height       => lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).height
			                               ,p_uom                 => lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).carton_size
			                               ,x_status              => lc_status
                                                       );

                              
                              --Validate API Return status
                              IF lc_status <> FND_API.G_RET_STS_SUCCESS THEN  
                                ln_proceed := 1;
                              END IF; --Return status validation 

                        END IF; --End of chk where LPN Assignment succeeds, then Update Dlv Dtl Info
                                                    
                        --If Updation of Addl Dlv Dtl Info Succeeds, the update Addl Dlv Info
                        IF ln_proceed = 0 THEN
                              --Update Additional Delivery Info
                              ln_proceed := 0 ;
                              Update_Addl_Delivery_Info( 
			                                p_delivery_id   => lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).delivery_number 
			                               ,p_number_of_lpn => lt_showshipunit_firstlvl_tbl(I_firstlvl).number_of_lpn
			                               ,p_gross_weight  => lt_showshipunit_firstlvl_tbl(I_firstlvl).gross_weight
			                               ,p_volume        => lt_showshipunit_firstlvl_tbl(I_firstlvl).volume
			                               ,x_return_status => lc_return_status
			                               ,x_msg_count     => ln_msg_count    
			                               ,x_msg_data      => lc_msg_data     
                                                       );

                              --Validate API Return status
                              IF lc_return_status = FND_API.G_RET_STS_SUCCESS THEN  
                                  COMMIT; 
                              ELSE 
                                ln_proceed := 1;
                                FND_MESSAGE.SET_NAME('XXOM','XX_OM_65508_CWMOS_ADDLV_FAIL'); 
                                IF ln_msg_count = 1 THEN 
                                    lc_error_code        := 'XX_OM_65508_CWMOS_ADDLV_FAIL'; 
                                    lc_error_desc        := FND_MESSAGE.GET; 
                                    lc_entity_ref        := 'Delivery Id'; 
                                    lc_entity_ref_id     := lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).delivery_number; 
                                    log_exceptions(lc_error_code              
                                                  ,lc_error_desc 
                                                  ,lc_entity_ref        
                                                  ,lc_entity_ref_id     
                                                  );                    
                                ELSE 
                                
                                   FOR l_index IN 1..ln_msg_count  
                                   LOOP 
                                      lc_error_code        := 'XX_OM_65508_CWMOS_ADDLV_FAIL'; 
                                      lc_error_desc        := FND_MESSAGE.GET; 
                                      lc_entity_ref        := 'Delivery Id'; 
                                      lc_entity_ref_id     := lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).delivery_number;
                                      log_exceptions(lc_error_code              
                                                    ,lc_error_desc 
                                                    ,lc_entity_ref        
                                                    ,lc_entity_ref_id     
                                                    );                    
                                   END LOOP; 
                                END IF; 
                              END IF; --Return status validation 
                        END IF; --End of chk for Update Dlv Info
                        
                      END IF; --End of validating the carton id of 2nd and 3rd level
                    ELSE
                   
                     --Log Exceptions
                     FND_MESSAGE.SET_NAME('XXOM','XX_OM_65500_CWMOS_INVLD_DLVID');
                     lc_error_code        := 'XX_OM_65500_CWMOS_INVLD_DLVID-01';
                     lc_error_desc        := FND_MESSAGE.GET;
                     lc_entity_ref        := 'Delivery Id';
                     lc_entity_ref_id     := lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).lt_showshipunit_thirdlvl_tbl(I_thirdlvl).delivery_number;
                     x_status             := 'E';
                     x_errcode            := 1;
                     log_exceptions(lc_error_code   
                                   ,lc_error_desc
                                   ,lc_entity_ref   
                                   ,lc_entity_ref_id
                                   );               
                    END IF; -- End of validating deliver id of 2nd and 3rd level
                  END IF; --End of Check XML Error in 3rd level attributes   
                END LOOP;--End of Third level record type loop
              
              ELSE
                 --Log Exceptions
                 FND_MESSAGE.SET_NAME('XXOM','XX_OM_65500_CWMOS_INVLD_DLVID');
                 lc_error_code        := 'XX_OM_65500_CWMOS_INVLD_DLVID-02';
                 lc_error_desc        := FND_MESSAGE.GET;
                 lc_entity_ref        := 'Delivery Id';
                 lc_entity_ref_id     := ln_seclvl_delivery_id; --lt_showshipunit_firstlvl_tbl(I_firstlvl).lt_showshipunit_seclvl_tbl(I_seclvl).delivery_id;
                 x_status             := 'E';
                 x_errcode            := 1;
                 log_exceptions(lc_error_code   
                               ,lc_error_desc
                               ,lc_entity_ref   
                               ,lc_entity_ref_id
                               );               
              END IF; -- End of validating deliver id of 1st and 2nd level
            END IF; --End of Check XML Error in 2nd level attributes 
          END LOOP; --End of Second level record type loop
          
          --Validating, whether all the delivery detail line got assigned to LPN or not.
          SELECT COUNT(1)
          INTO   ln_lpn_assigned_flg
          FROM   wsh_new_deliveries       WND
                ,wsh_delivery_assignments WDA
                ,wsh_delivery_details     WDD
          WHERE  WDA.delivery_id        = WND.delivery_id
          AND    WND.delivery_id        = ln_firstlvl_delivery_id
          AND    WDA.delivery_detail_id = WDD.delivery_detail_id
          AND    WDD.container_name     IS NOT NULL
          AND    WDD.container_flag     = 'Y';
          
          IF ln_lpn_assigned_flg > 0 THEN     
	    --Updating cartonization process status for the Delivery 
	    Log_Carton_Wmos_Proc_status( 
	                                ln_firstlvl_delivery_id
	                               ,g_cartonization_complete
	                               ,lc_status
	                              );
	    x_status             := FND_API.G_RET_STS_SUCCESS;
	    x_errcode            := 0;
	  ELSE
	    --Log Exceptions
	    FND_MESSAGE.SET_NAME('XXOM','XX_OM_CWMOS_ERROR');
	    lc_error_code        := 'XX_OM_CWMOS_ERROR';
	    lc_error_desc        := FND_MESSAGE.GET;
	    lc_entity_ref        := 'Delivery Id';
	    lc_entity_ref_id     := ln_firstlvl_delivery_id;
	    x_status             := 'E';
	    x_errcode            := 1;
	    log_exceptions(lc_error_code   
	                  ,lc_error_desc
	                  ,lc_entity_ref   
	                  ,lc_entity_ref_id
	                  );               
	  END IF; 
          
        END IF; -- End of Check XML Error in 1st level attributes 
      ELSE  --Else of cartonization eligible

        --Log Exceptions
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_65515_CWMOS_NOT_ELGBL');
        lc_error_code        := 'XX_OM_65515_CWMOS_NOT_ELGBL-02';
        lc_error_desc        := FND_MESSAGE.GET;
        lc_entity_ref        := 'Delivery Id';
        lc_entity_ref_id     := ln_firstlvl_delivery_id; --lt_showshipunit_firstlvl_tbl(I_firstlvl).delivery_id;
        x_status             := 'E';
        x_errcode            := 1;
        log_exceptions(lc_error_code   
                      ,lc_error_desc
                      ,lc_entity_ref   
                      ,lc_entity_ref_id
                      );               
      END IF; --End of chk cartonization eligible  
    END LOOP; --End of First level record type loop
        
  EXCEPTION
   WHEN OTHERS THEN
    x_status             := FND_API.G_RET_STS_UNEXP_ERROR;
    x_errcode            := 1;
    --Log Exception
    FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    
    lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR-01';
    lc_error_desc        := FND_MESSAGE.GET;
    lc_entity_ref        := 'XML ShowShipmentUnit Null value';
    lc_entity_ref_id     := 1;
    log_exceptions(lc_error_code             
                  ,lc_error_desc
                  ,lc_entity_ref       
                  ,lc_entity_ref_id    
                  );                   
  END Process_Cartonization_Wmos;

END XX_OM_CARTONIZATION_WMOS_PKG ;
/
SHOW ERRORS;
--EXIT;

