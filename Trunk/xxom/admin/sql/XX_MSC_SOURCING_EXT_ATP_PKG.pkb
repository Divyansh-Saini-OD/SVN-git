SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_MSC_SOURCING_EXT_ATP_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name         : XX_MSC_SOURCING_EXT_ATP_PKG                                              |
-- | Rice Id      : E1335_Virtual_Warehouse                                                  | 
-- | Description  : Custom Package to implement basic business functionality for             |
-- |                Virtual Warehousing in Base Sourcing.                                    |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    | 
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   04-JUL-2007       Nabarun Ghosh    Initial Version                            |
-- |                                                                                         |
-- +=========================================================================================+
AS 

  --Declaring varibales to hold the exception infos 
  lc_error_code                xx_om_global_exceptions.error_code%TYPE; 
  lc_error_desc                xx_om_global_exceptions.description%TYPE; 
  lc_entity_ref_id             xx_om_global_exceptions.entity_ref_id%TYPE;

  lc_return_status             VARCHAR2(40);
  ln_msg_count                 PLS_INTEGER;
  lc_msg_data                  VARCHAR2(2000);
  
  
  PROCEDURE log_exceptions( p_error_code        IN  VARCHAR2
                           ,p_error_description IN  VARCHAR2
                           ,p_entity_ref_id     IN  PLS_INTEGER
                          )
  -- +===================================================================+
  -- | Name  : Log_Exceptions                                            |
  -- | Rice Id      : E1335_Virtual_Warehouse                            | 
  -- | Description: This procedure will be responsible to store all      | 
  -- |              the exceptions occured during the procees using      |
  -- |              global custom exception handling framework           |
  -- |                                                                   |
  -- | Parameters:  IN:                                                  |
  -- |     P_Error_Code        --Custom error code                       |
  -- |     P_Error_Description --Custom Error Description                |
  -- |     p_entity_ref_id     --                                        |
  -- |                                                                   |
  -- +===================================================================+
  AS
   
   --Output of the global exception framework package
   x_errbuf                    VARCHAR2(1000);
   x_retcode                   VARCHAR2(40);
   
  BEGIN
  
   
   lrec_excepn_obj_type.p_error_code        := p_error_code;
   lrec_excepn_obj_type.p_error_description := p_error_description;
   lrec_excepn_obj_type.p_entity_ref_id     := p_entity_ref_id;
   x_retcode                                := p_error_code;
   x_errbuf                                 := p_error_description;
   
   xx_om_global_exception_pkg.insert_exception(lrec_excepn_obj_type
                                              ,x_errbuf
                                              ,x_retcode
                                             );
  END log_exceptions;
  
  PROCEDURE Process_External_Sourcing
           (
              p_sls_only                    IN  VARCHAR2                         
             ,p_mls_only                    IN  VARCHAR2                         
             ,p_both                        IN  VARCHAR2                         
             ,p_operating_unit              IN  org_organization_definitions.organization_id%TYPE                                      
             ,p_customer_number             IN  hz_cust_account.acoount_number%TYPE                          
             ,p_vertical_market_indicator   IN  xx_po_ssa_v.vm_indicator%TYPE                         
             ,p_internal_item_number        IN  mtl_system_items_b.inventory_item_id%TYPE                         
             ,p_quantity_uom                IN  oe_order_lines.order_quantity_uom%TYPE                         
             ,p_quantity                    IN  oe_order_lines.ordered_quantity%TYPE                         
             ,p_currency                    IN  oe_order_headers.transactional_curr_code%TYPE                         
             -- Parameters required for calculating ATD Delivery Dates 
             ,p_delivery_prefernece         IN  VARCHAR2     -- Indicates Dropship / Back-To-Back                     
             ,p_request_date                IN  DATE         -- Customers Request date            
             ,p_request_date_type           IN  DATE         -- Type of Date customer has requested - Arrival or Ship                 
             ,p_cust_shipto_location        IN  hz_locations.location_id%TYPE                         
             ,p_cust_zip_code               IN  hz_locations.zip_code%TYPE                         
             ,p_drop_ship_org               IN  mtl_parameters.organization_code%TYPE          
             ,p_base_organization           IN  mtl_parameters.organization_code%TYPE           
             ,p_carrier_calendar            IN  VARCHAR2(40)
             ,p_customer_delivery_calendar  IN  VARCHAR2(40)
             ,p_vendor_calendar             IN  VARCHAR2(40)
             ,p_organization_type           IN  VARCHAR2(40)
             --Parameter to calculate MLS Cutoff Time
             ,p_todays_date_time            IN  oe_order_headers.ordered_date%TYPE --Sales Order Date
             -- Parameters required for IMU validations
             ,p_unit_selling_price          IN  oe_order_lines.unit_selling_price%TYPE                          
             ,p_purchase_price              IN  oe_order_lines.unit_selling_price%TYPE                         
             ,p_order_line_extended_value   IN  oe_order_lines.unit_selling_price%TYPE 
             --This needs to be passed as arguments from the calling API for IMU calc, not defined in MD050
             ,p_vendor_item_price           IN  oe_order_lines.unit_selling_price%TYPE                           
            --Output variables 
             ,x_ext_source_ouput_tbl        OUT NOCOPY xx_msc_ext_source_ouput_tbl
             ,x_atp_status                  OUT NOCOPY VARCHAR2                         
             ,x_atp_error_message           OUT NOCOPY VARCHAR2                         
            ) 
  -- +===================================================================+
  -- | Name  : Process_External_Sourcing                                 |
  -- | Rice Id      : E1335_Virtual_Warehouse                            | 
  -- | Description:       This is a main wrapper Procedure, which will be|
  -- |                    deciding to find the best sourcing from either |
  -- |                    SLS or MLS or from BOTH suppliers.             |
  -- +===================================================================+
  IS
  
    lc_atp_status                   VARCHAR2(1);
    lc_atp_error_message            VARCHAR2(4000);
    lc_sls_count                    PLS_INTEGER := 0;
    
  BEGIN

    -- Process to initialize the apps environment
    SELECT  user_id
    INTO    g_n_user_id
    FROM    fnd_user
    WHERE   user_name = g_c_user_name;

    dbms_output.put_line('g_n_user_id: '||g_n_user_id);

    SELECT  responsibility_id,
            application_id
    INTO    g_n_resp_id
           ,g_n_resp_app_id
    FROM    fnd_responsibility_vl
    WHERE   responsibility_name = g_c_resp_name;

    FND_GLOBAL.APPS_INITIALIZE(g_n_user_id, g_n_resp_id, g_n_resp_app_id);
    
    IF p_sls_only IS NOT NULL THEN
      
      Virtual_Warehouse_Sourcing(
                                 p_customer_number             => p_customer_number                    
                                ,p_vertical_market_indicator   => p_vertical_market_indicator             
                                ,p_internal_item_number        => p_internal_item_number                         
                                ,p_quantity_uom                => p_quantity_uom                              
                                ,p_quantity                    => p_quantity  
                                ,p_currency                    => p_currency
                                -- Parameters required for calculating ATD Delivery Dates 
                                ,p_delivery_prefernece         => p_delivery_prefernece       
                                ,p_request_date                => p_request_date              
                                ,p_request_date_type           => p_request_date_type         
                                ,p_cust_shipto_location        => p_cust_shipto_location      
                                ,p_cust_zip_code               => p_cust_zip_code             
                                ,p_drop_ship_org               => p_drop_ship_org             
                                ,p_base_organization           => p_base_organization                   
                                ,p_carrier_calendar            => p_carrier_calendar          
                                ,p_customer_delivery_calendar  => p_customer_delivery_calendar
                                ,p_vendor_calendar             => p_vendor_calendar           
                                ,p_organization_type           => p_organization_type         
                                ,p_Todays_Date_Time            => p_Todays_Date_Time          
                                ,x_external_source_ouput_tbl   => lt_ext_source_ouput_tbl
                                ,x_atp_status                  => lc_atp_status
                                ,x_atp_error_message           => lc_atp_error_message
                               );
       
       IF lc_atp_status = 'S' THEN                         
         x_ext_source_ouput_tbl       := lt_ext_source_ouput_tbl      ;
         x_atp_status                 := lc_atp_status                ;
         x_atp_error_message          := lc_atp_error_message         ;
       ELSE
         x_atp_status                 := lc_atp_status                ;
         x_atp_error_message          := lc_atp_error_message         ;
       END IF ;
       
    ELSIF p_mls_only IS NOT NULL THEN
    
      MLS_Suppliers_Sourcing(
                              p_customer_number             => p_customer_number                        
                             ,p_internal_item_number        => p_internal_item_number                            
                             ,p_quantity_uom                => p_quantity_uom                                 
                             ,p_quantity                    => p_quantity     
                             ,p_currency                    => p_currency   
                             ,p_unit_selling_price          => p_unit_selling_price       
                             ,p_purchase_price              => p_purchase_price           
                             ,p_order_line_extended_value   => p_order_line_extended_value
                             ,p_vendor_item_price	    => p_vendor_item_price
                             -- Parameters required for calculating ATD Delivery Dates    
                             ,p_delivery_prefernece         => p_delivery_prefernece          
                             ,p_request_date                => p_request_date                 
                             ,p_request_date_type           => p_request_date_type            
                             ,p_cust_shipto_location        => p_cust_shipto_location         
                             ,p_cust_zip_code               => p_cust_zip_code                
                             ,p_drop_ship_org               => p_drop_ship_org                
                             ,p_base_organization           => p_base_organization                      
                             ,p_carrier_calendar            => p_carrier_calendar             
                             ,p_customer_delivery_calendar  => p_customer_delivery_calendar   
                             ,p_vendor_calendar             => p_vendor_calendar              
                             ,p_organization_type           => p_organization_type            
                             ,p_Todays_Date_Time            => p_Todays_Date_Time             
                             ,x_external_source_ouput_tbl   => lt_ext_source_ouput_tbl   
                             ,x_atp_status                  => lc_atp_status   
                             ,x_atp_error_message           => lc_atp_error_message   
                            );
       
       IF lc_atp_status = 'S' THEN                         
         x_ext_source_ouput_tbl       := lt_ext_source_ouput_tbl      ;
         x_atp_status                 := lc_atp_status                ;
         x_atp_error_message          := lc_atp_error_message         ;
       ELSE
         x_atp_status                 := lc_atp_status                ;
         x_atp_error_message          := lc_atp_error_message         ;
       END IF ;
       
    ELSIF p_both IS NOT NULL THEN
      
      Process_MLS_SLS_Sourcing(
                                 p_customer_number             => p_customer_number                    
                                ,p_vertical_market_indicator   => p_vertical_market_indicator             
                                ,p_internal_item_number        => p_internal_item_number                         
                                ,p_quantity_uom                => p_quantity_uom                              
                                ,p_quantity                    => p_quantity  
                                ,p_currency                    => p_currency
                                ,p_unit_selling_price          => p_unit_selling_price       
                                ,p_purchase_price              => p_purchase_price           
                                ,p_order_line_extended_value   => p_order_line_extended_value
                                ,p_vendor_item_price	       => p_vendor_item_price
                                -- Parameters required for calculating ATD Delivery Dates 
                                ,p_delivery_prefernece         => p_delivery_prefernece       
                                ,p_request_date                => p_request_date              
                                ,p_request_date_type           => p_request_date_type         
                                ,p_cust_shipto_location        => p_cust_shipto_location      
                                ,p_cust_zip_code               => p_cust_zip_code             
                                ,p_drop_ship_org               => p_drop_ship_org             
                                ,p_base_organization           => p_base_organization                   
                                ,p_carrier_calendar            => p_carrier_calendar          
                                ,p_customer_delivery_calendar  => p_customer_delivery_calendar
                                ,p_vendor_calendar             => p_vendor_calendar           
                                ,p_organization_type           => p_organization_type         
                                ,p_Todays_Date_Time            => p_Todays_Date_Time          
                                ,x_msc_extsrc_slsmls_out_tbl   => lt_msc_extsrc_slsmls_out_tbl
                                ,x_atp_status                  => lc_atp_status
                                ,x_atp_error_message           => lc_atp_error_message
                               );       
       
       IF lc_atp_status = 'S' THEN                         
         x_ext_source_ouput_tbl       := lt_ext_source_ouput_tbl      ;
         
         FOR I_sls_mls_index IN lt_msc_extsrc_slsmls_out_tbl.FIRST..lt_msc_extsrc_slsmls_out_tbl.LAST
         LOOP
           
           lc_sls_count := 0;
           
           FOR I_sls_index IN lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl.FIRST..lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl.LAST
           LOOP
           
             lc_sls_count := NVL(lc_sls_count,0)+1;
             
             lt_ext_source_ouput_tbl(lc_sls_count).source_supplier_type         := lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_sls_index).source_supplier_type ;
             lt_ext_source_ouput_tbl(lc_sls_count).supplier_id                  := lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_sls_index).supplier_id         ;      	 
             lt_ext_source_ouput_tbl(lc_sls_count).supplier_site_id             := lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_sls_index).supplier_site_id    ;      	 
             lt_ext_source_ouput_tbl(lc_sls_count).supplier_location         	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_sls_index).supplier_location   ;      	 
             lt_ext_source_ouput_tbl(lc_sls_count).facility_code             	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_sls_index).facility_code       ;      	 
             lt_ext_source_ouput_tbl(lc_sls_count).supplier_account          	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_sls_index).supplier_account    ;      	 
             lt_ext_source_ouput_tbl(lc_sls_count).supplier_rank             	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_sls_index).supplier_rank       ;      	 
             lt_ext_source_ouput_tbl(lc_sls_count).request_date_available_qty	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_sls_index).request_date_available_qty	 ;
             lt_ext_source_ouput_tbl(lc_sls_count).atp_fulfillment_type      	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_sls_index).atp_fulfillment_type      	 ;
             lt_ext_source_ouput_tbl(lc_sls_count).scheduled_ship_date         	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_sls_index).scheduled_ship_date         ;
             lt_ext_source_ouput_tbl(lc_sls_count).scheduled_arrival_date      	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_sls_index).scheduled_arrival_date      ;
             lt_ext_source_ouput_tbl(lc_sls_count).available_Date              	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_sls_index).available_Date              ;
             lt_ext_source_ouput_tbl(lc_sls_count).atp_date_calc_sts           	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_sls_index).atp_date_calc_sts           ;
             lt_ext_source_ouput_tbl(lc_sls_count).atp_date_calc_return_message	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_sls_index).atp_date_calc_return_message;
             lt_ext_source_ouput_tbl(lc_sls_count).atp_date_calc_warnings      	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_sls_index).atp_date_calc_warnings      ;
             lt_ext_source_ouput_tbl(lc_sls_count).atp_date_calc_warning_msg   	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_sls_index).atp_date_calc_warning_msg   ;
           END LOOP;
           
           FOR I_mls_index IN lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl.FIRST..lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl.LAST
           LOOP
             
             lc_sls_count := NVL(lc_sls_count,0)+1;
             
             lt_ext_source_ouput_tbl(lc_sls_count).source_supplier_type         := lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_mls_index).source_supplier_type ;
             lt_ext_source_ouput_tbl(lc_sls_count).supplier_id                  := lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_mls_index).supplier_id         ;      	 
             lt_ext_source_ouput_tbl(lc_sls_count).supplier_site_id             := lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_mls_index).supplier_site_id    ;      	 
             lt_ext_source_ouput_tbl(lc_sls_count).supplier_location         	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_mls_index).supplier_location   ;      	 
             lt_ext_source_ouput_tbl(lc_sls_count).facility_code             	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_mls_index).facility_code       ;      	 
             lt_ext_source_ouput_tbl(lc_sls_count).supplier_account          	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_mls_index).supplier_account    ;      	 
             lt_ext_source_ouput_tbl(lc_sls_count).supplier_rank             	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_mls_index).supplier_rank       ;      	 
             lt_ext_source_ouput_tbl(lc_sls_count).request_date_available_qty	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_mls_index).request_date_available_qty	 ;
             lt_ext_source_ouput_tbl(lc_sls_count).atp_fulfillment_type      	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_mls_index).atp_fulfillment_type      	 ;
             lt_ext_source_ouput_tbl(lc_sls_count).scheduled_ship_date         	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_mls_index).scheduled_ship_date         ;
             lt_ext_source_ouput_tbl(lc_sls_count).scheduled_arrival_date      	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_mls_index).scheduled_arrival_date      ;
             lt_ext_source_ouput_tbl(lc_sls_count).available_Date              	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_mls_index).available_Date              ;
             lt_ext_source_ouput_tbl(lc_sls_count).atp_date_calc_sts           	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_mls_index).atp_date_calc_sts           ;
             lt_ext_source_ouput_tbl(lc_sls_count).atp_date_calc_return_message	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_mls_index).atp_date_calc_return_message;
             lt_ext_source_ouput_tbl(lc_sls_count).atp_date_calc_warnings      	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_mls_index).atp_date_calc_warnings      ;
             lt_ext_source_ouput_tbl(lc_sls_count).atp_date_calc_warning_msg   	:= lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).lt_ext_source_sls_ouput_tbl(I_mls_index).atp_date_calc_warning_msg   ;
             
           END LOOP;
         END LOOP;

         x_atp_status                 := lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).atp_status;
         x_atp_error_message          := lt_msc_extsrc_slsmls_out_tbl(I_sls_mls_index).atp_error_message;

       ELSE
         x_atp_status                 := 'E'                ;
         x_atp_error_message          := lc_atp_error_message         ;
       END IF ;       
       
    END IF;
          
  EXCEPTION
   WHEN OTHERS THEN
    x_status        := 'E';
    --Log Exception
    FND_MESSAGE.SET_NAME('XXOM','XX_OM_66100_UNEXPECTED_ERROR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    
    lc_error_code        := 'XX_OM_66100_UNEXPECTED_ERROR-01';
    lc_error_desc        := FND_MESSAGE.GET;
    lc_entity_ref_id     := 1;
    log_exceptions(lc_error_code             
                  ,lc_error_desc
                  ,lc_entity_ref_id    
                  );     
  END Process_External_Sourcing;

  PROCEDURE Virtual_Warehouse_Sourcing
                (
                  p_customer_number             IN  hz_cust_account.acoount_number%TYPE                                                
		 ,p_vertical_market_indicator   IN  xx_po_ssa_v.vm_indicator%TYPE                         		      
		 ,p_internal_item_number        IN  mtl_system_items_b.inventory_item_id%TYPE                         		      
		 ,p_quantity_uom                IN  oe_order_lines.order_quantity_uom%TYPE                         		      
		 ,p_quantity                    IN  oe_order_lines.ordered_quantity%TYPE                         		      
		 ,p_currency                    IN  oe_order_headers.transactional_curr_code%TYPE                        		       
		 -- Parameters required for calculating ATD Delivery Dates 		      
		 ,p_delivery_prefernece         IN  VARCHAR2     -- Indicates Dropship / Back-To-Back                    		       
		 ,p_request_date                IN  DATE         -- Customers Request date            		      
		 ,p_request_date_type           IN  DATE         -- Type of Date customer has requested - Arrival or Ship		       
		 ,p_cust_shipto_location        IN  hz_locations.location_id%TYPE                         		      
		 ,p_cust_zip_code               IN  hz_locations.zip_code%TYPE                         		      
		 ,p_drop_ship_org               IN  mtl_parameters.organization_code%TYPE          		      
		 ,p_base_organization           IN  mtl_parameters.organization_code%TYPE           		      
		 ,p_carrier_calendar            IN  VARCHAR2(40)		      
		 ,p_customer_delivery_calendar  IN  VARCHAR2(40)		      
		 ,p_vendor_calendar             IN  VARCHAR2(40)		      
		 ,p_organization_type           IN  VARCHAR2(40)		      
		 ,p_todays_date_time            IN  DATE		      
		 ,x_external_source_ouput_tbl   OUT NOCOPY xx_msc_ext_source_ouput_tbl
                 ,x_atp_status                  OUT NOCOPY VARCHAR2                      
                 ,x_atp_error_message           OUT NOCOPY VARCHAR2                      
                )                      
  -- +===================================================================+
  -- | Name  : Virtual_Warehouse_Sourcing                                |
  -- | Rice Id      : E1335_Virtual_Warehouse                            | 
  -- | Description:       This Procedure will be extarcting the required |
  -- |                    Item Quantity from the Virtual Warehouses,     |
  -- |                    where the suppliers that have a prearranged    |
  -- |                    agreement to virtually stock items for OD, an  |
  -- |                    extension of OD operated locations .           |
  -- |                                                                   |
  -- |                                                                   |
  -- +===================================================================+
  AS
  
    lc_atp_status                   VARCHAR2(2);
    lc_atp_err_message              VARCHAR2(2000);
    lc_message                      VARCHAR2(2000);
    lc_warning_message              VARCHAR2(2000); 
    ln_index                        PLS_INTEGER := 0;
    l_available_Date	            DATE;
    l_scheduled_ship_date           DATE;
    l_scheduled_arrival_date        DATE;
    l_return_codes                  VARCHAR2(2);
    l_warnings                      VARCHAR2(2);   
    l_cos_order_type                VARCHAR2(2);
    
  BEGIN

    --Loop through the SLS suppliers as per Rank Priority
    OPEN lcu_sls_suppliers_info(
                                p_customer_number          
                               ,p_vertical_market_indicator
                               ,p_internal_item_number     
                               ,p_base_organization 
                               ,'TRADE-SLS'
                               ); 
    LOOP
     FETCH lcu_sls_suppliers_info INTO  l_sls_suppliers_info;
     EXIT WHEN lcu_sls_suppliers_info%NOTFOUND;
     
      ln_index := NVL(ln_index,0) + 1;
     
      --ObtainingInventory Feed by suppliers
      OPEN lcu_inventory_feed_info(
                                   l_sls_suppliers_info.vendor_id
                                  ,l_sls_suppliers_info.item_id
                                  ); 
      FETCH lcu_inventory_feed_info INTO  l_inventory_feed_info;
      CLOSE lcu_inventory_feed_info;
       
      IF NVL(l_inventory_feed_info.on_hand_qty,0) < NVL(p_quantity,0) THEN
         
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_VWH_SUPP_QTY_ERR');
        lc_error_code        := 'XX_OM_VWH_SUPP_QTY_ERR';
        lc_error_desc        := FND_MESSAGE.GET;
        lc_entity_ref_id     := l_sls_suppliers_info.vendor_id;
        lc_atp_status        := 'E';
        lc_atp_err_message   := FND_MESSAGE.GET;
        x_atp_status         := lc_atp_status;
        x_atp_error_message  := lc_atp_err_message;
        
        log_exceptions(lc_error_code   
                      ,lc_error_desc
                      ,lc_entity_ref_id
                      );              
      ELSE
        lc_atp_status       := 'S';
        x_atp_status        := lc_atp_status;
        x_atp_error_message := 'Success';
      END IF;
          
      IF lc_atp_status = 'S' THEN
       
       x_external_source_ouput_tbl(ln_index).source_supplier_type       := 'SLS';   
       x_external_source_ouput_tbl(ln_index).supplier_id                := l_sls_suppliers_info.vendor_id;
       x_external_source_ouput_tbl(ln_index).supplier_site_id           := l_sls_suppliers_info.vendor_site_id;
       x_external_source_ouput_tbl(ln_index).supplier_location          := l_sls_suppliers_info.vendor_site_code;
       x_external_source_ouput_tbl(ln_index).facility_code              := ''; 
       x_external_source_ouput_tbl(ln_index).supplier_account           := ''; 
       x_external_source_ouput_tbl(ln_index).supplier_rank              := l_sls_suppliers_info.rank; 
       x_external_source_ouput_tbl(ln_index).request_date_available_qty := l_inventory_feed_info.on_hand_qty; 
       x_external_source_ouput_tbl(ln_index).atp_fulfillment_type       := p_delivery_prefernece;
       
       /* This part needs to be developed
       --Call the custom API for ATPDeliveryDate calculation
       
         XX_MSC_ATPDeliveryDate_Pkg 
                           (
                            p_delivery_prefernece         => p_delivery_prefernece       
                           ,p_source_supplier_type        => 'SLS' 
                           ,p_vendor_id                   => l_sls_suppliers_info.vendor_id
                           ,p_vendor_site_id              => l_sls_suppliers_info.vendor_site_id
                           ,p_customer_number             => p_customer_number
                           ,p_request_date                => p_request_date              
                           ,p_request_date_type           => p_request_date_type         
                           ,p_cust_shipto_location        => p_cust_shipto_location      
                           ,p_cust_zip_code               => p_cust_zip_code             
                           ,p_drop_ship_org               => p_drop_ship_org
                           ,p_base_organization           => p_base_organization         
                           ,p_carrier_calendar            => p_carrier_calendar          
                           ,p_customer_delivery_calendar  => p_customer_delivery_calendar
                           ,p_vendor_calendar             => p_vendor_calendar           
                           ,p_organization_type           => p_organization_type         
                           ,p_todays_date_time            => p_todays_date_time          
                           ,p_lead_time                   => l_sls_suppliers_info.lead_time
                           ,x_delivery_date               => l_available_Date
                           ,x_solicit_ship_date           => l_scheduled_ship_date 
                           ,x_return_codes                => l_return_codes
                           ,x_warnings                    => l_warnings
                           ,x_cos_order_type              => l_cos_order_type
                           -- Needs to be an output from ATP Delivery Date calculation pkg
                           ,x_scheduled_arrival_date      => l_scheduled_arrival_date 
                           );
       
       CASE 
       WHEN  l_return_codes = '00' THEN
             lc_message  = 'Delivery Date Valid';
       WHEN  l_return_codes = '01' THEN
             lc_message  = 'Delivery Table Error';
       WHEN  l_return_codes = '02' THEN
             lc_message  = 'USA Next Day table could not be built';
       WHEN  l_return_codes = '03' THEN
             lc_message  = 'USA Holiday table could not be built';
       WHEN  l_return_codes = '04' THEN
             lc_message  = 'Can Next Day table could not be built';
       WHEN  l_return_codes = '05' THEN
             lc_message  = 'Can Holiday table could not be built';
       WHEN  l_return_codes = '06' THEN
             lc_message  = 'Delivery Error Code (invalid date code)';
       WHEN  l_return_codes = '08' THEN
             lc_message  = 'Pickup order';
       WHEN  l_return_codes = '09' THEN
             lc_message  = 'Holiday Date Error';
       WHEN  l_return_codes = '10' THEN
             lc_message  = 'Delivery Prior to today’s date';
       WHEN  l_return_codes = '11' THEN
             lc_message  = 'Date is Holiday';
       WHEN  l_return_codes = '12' THEN
             lc_message  = 'Delivery date outside valid range';
       WHEN  l_return_codes = '13' THEN
             lc_message  = 'Saturday/Sunday invalid';
       WHEN  l_return_codes = '14' THEN
             lc_message  = 'Day of week invalid for this zip';
       WHEN  l_return_codes = '15' THEN
             lc_message  = 'Cross-dock date invalid';
       WHEN  l_return_codes = '16' THEN
             lc_message  = 'System date invalid';
       WHEN  l_return_codes = '17' THEN
             lc_message  = 'Today’s date invalid for non-emergency order';
       WHEN  l_return_codes = '18' THEN
             lc_message  = 'Seasonal order min date range not met';
       WHEN  l_return_codes = '19' THEN
             lc_message  = 'Common Carrier order date invalid';
       WHEN  l_return_codes = '20' THEN
             lc_message  = 'Monday Date invalid for Weekend Order';
       WHEN  l_return_codes = '21' THEN
             lc_message  = 'Location has set date as holiday';
       WHEN  l_return_codes = '22' THEN
             lc_message  = 'Location has set date for disaster';
       WHEN  l_return_codes = '23' THEN
             lc_message  = 'Order taken after cutoff may not have tomorrow as a delivery date';
       WHEN  l_return_codes = '24' THEN
             lc_message  = 'Orders taken on holidays may not have next day delivery dates';
       END CASE;             
             
       CASE
       WHEN l_warnings = '00' THEN
            lc_warning_message  = 'No Warning'; 
       WHEN l_warnings = '01' THEN
            lc_warning_message  = 'Same day order that missed cut off, will be delivered next business day'; 
       WHEN l_warnings = '02' THEN
            lc_warning_message  = 'Same day order that missed cut off but should be delivered next day by noon'; 
       END CASE            
       
       
       x_external_source_ouput_tbl(ln_index).scheduled_ship_date          := l_scheduled_ship_date; 
       x_external_source_ouput_tbl(ln_index).scheduled_arrival_date       := l_scheduled_arrival_date; 
       x_external_source_ouput_tbl(ln_index).available_Date               := l_available_Date;
       x_external_source_ouput_tbl(ln_index).atp_date_calc_sts            := l_return_codes; 
       x_external_source_ouput_tbl(ln_index).atp_date_calc_return_message := lc_message;
       x_external_source_ouput_tbl(ln_index).atp_date_calc_warnings       := l_warnings ;
       x_external_source_ouput_tbl(ln_index).atp_date_calc_warning_msg    := lc_warning_message;
       
       */
        
      END IF;       
      
    END LOOP;
    CLOSE lcu_sls_suppliers_info;
    
  EXCEPTION
   WHEN OTHERS THEN
    o_status             := FND_API.G_RET_STS_UNEXP_ERROR;
    dbms_output.put_line('Status in OTHERS: '||o_status);
    --Log Exception
    FND_MESSAGE.SET_NAME('XXOM','XX_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    
    lc_error_code        := 'XX_OM_UNEXPECTED_ERR-01';
    lc_error_desc        := FND_MESSAGE.GET;
    lc_entity_ref_id     := p_inventory_item_id;
    log_exceptions(lc_error_code             
                  ,lc_error_desc
                  ,lc_entity_ref_id    
                  );   
                  
  END Virtual_Warehouse_Sourcing;
  
  PROCEDURE MLS_Suppliers_Sourcing(
                          p_customer_number             IN  hz_cust_account.acoount_number%TYPE                
                         ,p_internal_item_number        IN  mtl_system_items_b.inventory_item_id%TYPE    
                         ,p_quantity_uom                IN  oe_order_lines.order_quantity_uom%TYPE             
                         ,p_quantity                    IN  oe_order_lines.ordered_quantity%TYPE         
                         ,p_currency                    IN  oe_order_headers.transactional_curr_code%TYPE
                         ,p_unit_selling_price          IN  oe_order_lines.unit_selling_price%TYPE 
                         ,p_purchase_price              IN  oe_order_lines.unit_selling_price%TYPE 
                         ,p_order_line_extended_value   IN  oe_order_lines.unit_selling_price%TYPE 
                         ,p_vendor_item_price	        IN  oe_order_lines.unit_selling_price%TYPE 
                         -- Parameters required for calculating ATD Delivery Dates    
                         ,p_delivery_prefernece         IN  VARCHAR2     -- Indicates Dropship / Back-To-Back                    
                         ,p_request_date                IN  DATE         -- Customers Request date            		      
                         ,p_request_date_type           IN  DATE         -- Type of Date customer has requested - Arrival or Ship
                         ,p_cust_shipto_location        IN  hz_locations.location_id%TYPE                         		 
                         ,p_cust_zip_code               IN  hz_locations.zip_code%TYPE                         		      
                         ,p_drop_ship_org               IN  mtl_parameters.organization_code%TYPE          		      
                         ,p_base_organization           IN  mtl_parameters.organization_code%TYPE           		      
                         ,p_carrier_calendar            IN  VARCHAR2(40)		      
                         ,p_customer_delivery_calendar  IN  VARCHAR2(40)		      
                         ,p_vendor_calendar             IN  VARCHAR2(40)		      
                         ,p_organization_type           IN  VARCHAR2(40)		      
                         ,p_todays_date_time            IN  DATE		      
                         ,x_external_source_ouput_tbl   OUT NOCOPY xx_msc_ext_source_ouput_tbl
                         ,x_atp_status                  OUT NOCOPY VARCHAR2                      
                         ,x_atp_error_message           OUT NOCOPY VARCHAR2                      
                        )
  -- +===================================================================+
  -- | Name  : MLS_Suppliers_Sourcing                                    |
  -- | Rice Id      : E1335_Virtual_Warehouse                            | 
  -- | Description:       This Procedure will be extarcting the best     |
  -- |                    supply sourcing based on the Rank.             |
  -- |                                                                   |
  -- |                                                                   |
  -- +===================================================================+
  IS

    lc_atp_status                   VARCHAR2(2);
    lc_atp_err_message              VARCHAR2(2000);
    l_return_codes                  VARCHAR2(2);
    lc_message                      VARCHAR2(2000);
    l_warnings                      VARCHAR2(2);   
    lc_warning_message              VARCHAR2(2000); 
    ln_index                        PLS_INTEGER := 0;
    l_available_Date	            DATE;
    l_scheduled_ship_date           DATE;
    l_scheduled_arrival_date        DATE;
    l_cos_order_type                VARCHAR2(2);
    l_vendor_id                     xx_po_mlss_det.vendor_id%TYPE;
    l_vendor_site_id		    xx_po_mlss_det.p_vendor_site_id%TYPE;
    
    l_imu_value_for_item           PLS_INTEGER;
    l_extd_retail_lst_price_item   PLS_INTEGER;
    l_mls_cutoff_time              PLS_INTEGER;
    
    
  BEGIN
  
    --Loop through the SLS suppliers as per Rank Priority
    OPEN lcu_mls_suppliers_info(
                                p_base_organization   
                               ,p_internal_item_number
                               ,p_request_date        
                               ,l_vendor_id           
                               ,l_vendor_site_id      
                               ); 
    LOOP
     FETCH lcu_mls_suppliers_info INTO  l_mls_suppliers_info;
     EXIT WHEN lcu_mls_suppliers_info%NOTFOUND;
     
     ln_index := NVL(ln_index,0) + 1;
     
     --Validating IMU
     IF l_mls_suppliers_info.imu_amt_pt = 'A' THEN 
     
      l_imu_value_for_item         := l_mls_suppliers_info.imu_value;
      l_extd_retail_lst_price_item := p_unit_selling_price * p_quantity;
      l_extd_cost_wholesaler       := p_purchase_price * p_quantity;
      l_extd_primary_vendor_cost   := p_vendor_item_price *p_quantity;
      l_wholesaler_margin          := l_extd_retail_lst_price_item - l_extd_cost_wholesaler;
      l_od_margin                  := l_extd_retail_lst_price_item - l_extd_primary_vendor_cost;
      l_loss_margin_from_wholsaler := l_od_margin - l_wholesaler_margin;
      
      IF l_loss_margin_from_wholsaler > l_imu_value_for_item THEN
         lc_atp_status := 'E';
         lc_atp_err_message := 'Supplier Excluded from IMU validation';
      ELSE    
         lc_atp_status := 'S';
      END IF;
     
     ELSIF  l_mls_suppliers_info.imu_amt_pt = 'P' THEN

      l_imu_value_for_item         := l_mls_suppliers_info.imu_value;
      l_extd_retail_lst_price_item := p_unit_selling_price * p_quantity;
      l_extd_cost_wholesaler       := p_purchase_price * p_quantity;
      l_wholesaler_margin          := l_extd_retail_lst_price_item - l_extd_cost_wholesaler;
      
      l_loss_margin_from_wholsaler := (l_wholesaler_margin*100)/ l_extd_retail_lst_price_item;
      
      IF l_loss_margin_from_wholsaler < l_imu_value_for_item THEN
         lc_atp_status := 'E';
         lc_atp_err_message := 'Supplier'||l_mls_suppliers_info.vendor_id||' Excluded by IMU validation';
      ELSE    
         lc_atp_status := 'S';
      END IF;      
     
     END IF;
     
     IF lc_atp_status := 'S'
       
       x_external_source_ouput_tbl(ln_index).source_supplier_type       := 'MLS';   
       x_external_source_ouput_tbl(ln_index).supplier_id                := l_mls_suppliers_info.vendor_id;
       x_external_source_ouput_tbl(ln_index).supplier_site_id           := l_mls_suppliers_info.vendor_site_id;
       x_external_source_ouput_tbl(ln_index).supplier_location          := l_mls_suppliers_info.supply_loc_no;
       x_external_source_ouput_tbl(ln_index).facility_code              := l_mls_suppliers_info.supp_facility_cd; 
       x_external_source_ouput_tbl(ln_index).supplier_account           := l_mls_suppliers_info.supp_loc_ac; 
       x_external_source_ouput_tbl(ln_index).supplier_rank              := l_sls_suppliers_info.rank; 
       x_external_source_ouput_tbl(ln_index).request_date_available_qty := l_inventory_feed_info.on_hand_qty; 
       x_external_source_ouput_tbl(ln_index).atp_fulfillment_type       := p_delivery_prefernece;
       
       /* This part needs to be developed
       --Call the custom API for ATPDeliveryDate calculation
       IF p_delivery_prefernece = 'Dropship' THEN
          l_supplier_lead_time := l_mls_suppliers_info.ds_lt;
       ELSIF p_delivery_prefernece = 'Back-To-Back' THEN   
          l_supplier_lead_time := l_mls_suppliers_info.b2b_lt;
       END IF;
       
       XX_MSC_ATPDeliveryDate_Pkg 
                           (
                            p_delivery_prefernece         => p_delivery_prefernece       
                           ,p_source_supplier_type        => 'SLS' 
                           ,p_vendor_id                   => l_mls_suppliers_info.vendor_id
                           ,p_vendor_site_id              => l_mls_suppliers_info.vendor_site_id
                           ,p_customer_number             => p_customer_number
                           ,p_request_date                => p_request_date              
                           ,p_request_date_type           => p_request_date_type         
                           ,p_cust_shipto_location        => p_cust_shipto_location      
                           ,p_cust_zip_code               => p_cust_zip_code             
                           ,p_drop_ship_org               => p_drop_ship_org
                           ,p_base_organization           => p_base_organization         
                           ,p_carrier_calendar            => p_carrier_calendar          
                           ,p_customer_delivery_calendar  => p_customer_delivery_calendar
                           ,p_vendor_calendar             => p_vendor_calendar           
                           ,p_organization_type           => p_organization_type         
                           ,p_todays_date_time            => p_todays_date_time          
                           ,p_lead_time                   => l_supplier_lead_time
                           ,x_delivery_date               => l_available_Date
                           ,x_solicit_ship_date           => l_scheduled_ship_date 
                           ,x_return_codes                => l_return_codes
                           ,x_warnings                    => l_warnings
                           ,x_cos_order_type              => l_cos_order_type
                           -- Needs to be an output from ATP Delivery Date calculation pkg
                           ,x_scheduled_arrival_date      => l_scheduled_arrival_date 
                           );
       
       CASE 
       WHEN  l_return_codes = '00' THEN
             lc_message  = 'Delivery Date Valid';
       WHEN  l_return_codes = '01' THEN
             lc_message  = 'Delivery Table Error';
       WHEN  l_return_codes = '02' THEN
             lc_message  = 'USA Next Day table could not be built';
       WHEN  l_return_codes = '03' THEN
             lc_message  = 'USA Holiday table could not be built';
       WHEN  l_return_codes = '04' THEN
             lc_message  = 'Can Next Day table could not be built';
       WHEN  l_return_codes = '05' THEN
             lc_message  = 'Can Holiday table could not be built';
       WHEN  l_return_codes = '06' THEN
             lc_message  = 'Delivery Error Code (invalid date code)';
       WHEN  l_return_codes = '08' THEN
             lc_message  = 'Pickup order';
       WHEN  l_return_codes = '09' THEN
             lc_message  = 'Holiday Date Error';
       WHEN  l_return_codes = '10' THEN
             lc_message  = 'Delivery Prior to today’s date';
       WHEN  l_return_codes = '11' THEN
             lc_message  = 'Date is Holiday';
       WHEN  l_return_codes = '12' THEN
             lc_message  = 'Delivery date outside valid range';
       WHEN  l_return_codes = '13' THEN
             lc_message  = 'Saturday/Sunday invalid';
       WHEN  l_return_codes = '14' THEN
             lc_message  = 'Day of week invalid for this zip';
       WHEN  l_return_codes = '15' THEN
             lc_message  = 'Cross-dock date invalid';
       WHEN  l_return_codes = '16' THEN
             lc_message  = 'System date invalid';
       WHEN  l_return_codes = '17' THEN
             lc_message  = 'Today’s date invalid for non-emergency order';
       WHEN  l_return_codes = '18' THEN
             lc_message  = 'Seasonal order min date range not met';
       WHEN  l_return_codes = '19' THEN
             lc_message  = 'Common Carrier order date invalid';
       WHEN  l_return_codes = '20' THEN
             lc_message  = 'Monday Date invalid for Weekend Order';
       WHEN  l_return_codes = '21' THEN
             lc_message  = 'Location has set date as holiday';
       WHEN  l_return_codes = '22' THEN
             lc_message  = 'Location has set date for disaster';
       WHEN  l_return_codes = '23' THEN
             lc_message  = 'Order taken after cutoff may not have tomorrow as a delivery date';
       WHEN  l_return_codes = '24' THEN
             lc_message  = 'Orders taken on holidays may not have next day delivery dates';
       END CASE;             
             
       CASE
       WHEN l_warnings = '00' THEN
            lc_warning_message  = 'No Warning'; 
       WHEN l_warnings = '01' THEN
            lc_warning_message  = 'Same day order that missed cut off, will be delivered next business day'; 
       WHEN l_warnings = '02' THEN
            lc_warning_message  = 'Same day order that missed cut off but should be delivered next day by noon'; 
       END CASE            
       
       
       x_external_source_ouput_tbl(ln_index).scheduled_ship_date          := l_scheduled_ship_date; 
       x_external_source_ouput_tbl(ln_index).scheduled_arrival_date       := l_scheduled_arrival_date; 
       x_external_source_ouput_tbl(ln_index).available_Date               := l_available_Date;
       x_external_source_ouput_tbl(ln_index).atp_date_calc_sts            := l_return_codes; 
       x_external_source_ouput_tbl(ln_index).atp_date_calc_return_message := lc_message;
       x_external_source_ouput_tbl(ln_index).atp_date_calc_warnings       := l_warnings ;
       x_external_source_ouput_tbl(ln_index).atp_date_calc_warning_msg    := lc_warning_message;
       
       */         
         
     END IF;
    
    END LOOP;
    CLOSE lcu_mls_suppliers_info;
    
  EXCEPTION
   WHEN OTHERS THEN
    o_status             := FND_API.G_RET_STS_UNEXP_ERROR;
    dbms_output.put_line('Status in OTHERS: '||o_status);
    --Log Exception
    FND_MESSAGE.SET_NAME('XXOM','XX_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    
    lc_error_code        := 'XX_OM_UNEXPECTED_ERR-01';
    lc_error_desc        := FND_MESSAGE.GET;
    lc_entity_ref_id     := p_inventory_item_id;
    log_exceptions(lc_error_code             
                  ,lc_error_desc
                  ,lc_entity_ref_id    
                  );    
  END MLS_Suppliers_Sourcing;
  
  PROCEDURE Process_MLS_SLS_Sourcing(
                                   p_customer_number             IN  hz_cust_account.acoount_number%TYPE                    
                                  ,p_vertical_market_indicator   IN  xx_po_ssa_v.vm_indicator%TYPE 
                                  ,p_internal_item_number        IN  mtl_system_items_b.inventory_item_id%TYPE                       
                                  ,p_quantity_uom                IN  oe_order_lines.order_quantity_uom%TYPE                       
                                  ,p_quantity                    IN  oe_order_lines.ordered_quantity%TYPE         
                                  ,p_currency                    IN  oe_order_headers.transactional_curr_code%TYPE
                                  ,p_unit_selling_price          IN  oe_order_lines.unit_selling_price%TYPE 
                                  ,p_purchase_price              IN  oe_order_lines.unit_selling_price%TYPE 
                                  ,p_order_line_extended_value   IN  oe_order_lines.unit_selling_price%TYPE 
                                  ,p_vendor_item_price	         IN  oe_order_lines.unit_selling_price%TYPE 
                                  -- Parameters required for calculating ATD Delivery Dates 
                                  ,p_delivery_prefernece         IN  VARCHAR2     -- Indicates Dropship / Back-To-Back                    
                                  ,p_request_date                IN  DATE         -- Customers Request date            		      
                                  ,p_request_date_type           IN  DATE         -- Type of Date customer has requested - Arrival or Ship
                                  ,p_cust_shipto_location        IN  hz_locations.location_id%TYPE                         		 
                                  ,p_cust_zip_code               IN  hz_locations.zip_code%TYPE                         		      
                                  ,p_drop_ship_org               IN  mtl_parameters.organization_code%TYPE          		      
                                  ,p_base_organization           IN  mtl_parameters.organization_code%TYPE           		                
                                  ,p_carrier_calendar            IN  VARCHAR2(40)		      
                                  ,p_customer_delivery_calendar  IN  VARCHAR2(40)		      
                                  ,p_vendor_calendar             IN  VARCHAR2(40)		      
                                  ,p_organization_type           IN  VARCHAR2(40)		      
                                  ,p_Todays_Date_Time            IN  DATE		      
                                  ,x_msc_extsrc_slsmls_out_tbl   OUT NOCOPY xx_msc_extsrc_slsmls_out_tbl
                                  ,x_atp_status                  OUT NOCOPY VARCHAR2                      
                                  ,x_atp_error_message           OUT NOCOPY VARCHAR2                      
                               )
  -- +===================================================================+
  -- | Name  : Process_MLS_SLS_Sourcing                                  |
  -- | Rice Id      : E1335_Virtual_Warehouse                            | 
  -- | Description:       This Procedure will be extarcting the best     |
  -- |                    supply sourcing based on the Rank for both SLS |
  -- |                    and MLS suppliers.                             |
  -- |                                                                   |
  -- +===================================================================+                               
  IS
    l_supp_loc_count_ind   xx_po_ssa_v.supp_loc_count_ind%TYPE;
    lc_atp_status	   VARCHAR2(2);
    lc_atp_error_message   VARCHAR2(2000);
    
  BEGIN
    
    
    --Loop through the SLS suppliers as per Rank Priority
    OPEN lcu_sls_suppliers_info(
                                p_customer_number          
                               ,p_vertical_market_indicator
                               ,p_internal_item_number     
                               ,p_base_organization 
                               ,l_supp_loc_count_ind
                               ); 
    LOOP
     FETCH lcu_sls_suppliers_info INTO  l_sls_suppliers_info;
     EXIT WHEN lcu_sls_suppliers_info%NOTFOUND;
     
      ln_index := NVL(ln_index,0) + 1;
      
      IF l_sls_suppliers_info.supp_loc_count_ind = 'TRADE-SLS' THEN
       
       Virtual_Warehouse_Sourcing(
                                  p_customer_number             => p_customer_number           
                                 ,p_vertical_market_indicator   => p_vertical_market_indicator              
                                 ,p_internal_item_number        => p_internal_item_number          
                                 ,p_quantity_uom                => p_quantity_uom              	      
                                 ,p_quantity                    => p_quantity  	      
                                 ,p_currency                    => p_currency	      
                                 -- Parameters required for calculating ATD Delivery Dates 		       
                                 ,p_delivery_prefernece         => p_delivery_prefernece       
                                 ,p_request_date                => p_request_date              		       
                                 ,p_request_date_type           => p_request_date_type         
                                 ,p_cust_shipto_location        => p_cust_shipto_location      		       
                                 ,p_cust_zip_code               => p_cust_zip_code                 
                                 ,p_drop_ship_org               => p_drop_ship_org             
                                 ,p_base_organization           => p_base_organization         
                                 ,p_carrier_calendar            => p_carrier_calendar          
                                 ,p_customer_delivery_calendar  => p_customer_delivery_calendar
                                 ,p_vendor_calendar             => p_vendor_calendar           
                                 ,p_organization_type           => p_organization_type         
                                 ,p_Todays_Date_Time            => p_Todays_Date_Time          
                                 ,x_external_source_ouput_tbl   => lt_ext_source_ouput_tbl
                                 ,x_atp_status                  => lc_atp_status
                                 ,x_atp_error_message           => lc_atp_error_message
                                );
       
       IF lc_atp_status = 'S' THEN
       
         FOR I_sls_supplier IN lt_ext_source_ouput_tbl.FIRST..lt_ext_source_ouput_tbl.LAST
         LOOP
           x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_sls_supplier).source_supplier_type         := lt_ext_source_ouput_tbl(I_sls_supplier).source_supplier_type  ;    
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_sls_supplier).supplier_id               	  := lt_ext_source_ouput_tbl(I_sls_supplier).supplier_id           ;    
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_sls_supplier).supplier_site_id          	  := lt_ext_source_ouput_tbl(I_sls_supplier).supplier_site_id      ;    
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_sls_supplier).supplier_location         	  := lt_ext_source_ouput_tbl(I_sls_supplier).supplier_location     ;    
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_sls_supplier).facility_code             	  := lt_ext_source_ouput_tbl(I_sls_supplier).facility_code         ;    
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_sls_supplier).supplier_account          	  := lt_ext_source_ouput_tbl(I_sls_supplier).supplier_account      ;    
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_sls_supplier).supplier_rank             	  := lt_ext_source_ouput_tbl(I_sls_supplier).supplier_rank         ;    
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_sls_supplier).request_date_available_qty	  := lt_ext_source_ouput_tbl(I_sls_supplier).request_date_available_qty;
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_sls_supplier).atp_fulfillment_type      	  := lt_ext_source_ouput_tbl(I_sls_supplier).atp_fulfillment_type;
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_sls_supplier).scheduled_ship_date          := lt_ext_source_ouput_tbl(I_sls_supplier).scheduled_ship_date       ;  
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_sls_supplier).scheduled_arrival_date       := lt_ext_source_ouput_tbl(I_sls_supplier).scheduled_arrival_date    ;  
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_sls_supplier).available_Date               := lt_ext_source_ouput_tbl(I_sls_supplier).available_Date            ;  
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_sls_supplier).atp_date_calc_sts            := lt_ext_source_ouput_tbl(I_sls_supplier).atp_date_calc_sts         ;  
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_sls_supplier).atp_date_calc_return_message := lt_ext_source_ouput_tbl(I_sls_supplier).atp_date_calc_return_message;
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_sls_supplier).atp_date_calc_warnings       := lt_ext_source_ouput_tbl(I_sls_supplier).atp_date_calc_warnings      ;
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_sls_supplier).atp_date_calc_warning_msg    := lt_ext_source_ouput_tbl(I_sls_supplier).atp_date_calc_warning_msg   ;
         END LOOP;
         x_msc_extsrc_slsmls_out_tbl(ln_index).atp_status := 'S';
         x_msc_extsrc_slsmls_out_tbl(ln_index).atp_error_message := 'Successfully process external ATP sourcing for the supplier'||lcu_sls_suppliers_info.vendor_id;
       ELSE
         x_msc_extsrc_slsmls_out_tbl(ln_index).atp_status := 'S';
         x_msc_extsrc_slsmls_out_tbl(ln_index).atp_error_message := 'Could not process the external ATP sourcing for the supplier'||lcu_sls_suppliers_info.vendor_id;
       END IF;

      ELSIF l_sls_suppliers_info.supp_loc_count_ind = 'TRADE-MLS' THEN
       
       MLS_Suppliers_Sourcing(
                     p_customer_number             => p_customer_number                 
                    ,p_internal_item_number        => p_internal_item_number
                    ,p_quantity_uom                => p_quantity_uom              
                    ,p_quantity                    => p_quantity  	      
                    ,p_currency                    => p_currency	      
                    ,p_unit_selling_price          =>p_unit_selling_price        
                    ,p_purchase_price              =>p_purchase_price            
                    ,p_order_line_extended_value   =>p_order_line_extended_value 
                    ,p_vendor_item_price	   =>p_vendor_item_price	       
                    -- Parameters required for calculating ATD Delivery Dates    
                    ,p_delivery_prefernece         => p_delivery_prefernece       
                    ,p_request_date                => p_request_date                
                    ,p_request_date_type           => p_request_date_type         
                    ,p_cust_shipto_location        => p_cust_shipto_location      
                    ,p_cust_zip_code               => p_cust_zip_code               
                    ,p_drop_ship_org               => p_drop_ship_org             
                    ,p_base_organization           => p_base_organization         
                    ,p_carrier_calendar            => p_carrier_calendar          
                    ,p_customer_delivery_calendar  => p_customer_delivery_calendar
                    ,p_vendor_calendar             => p_vendor_calendar           
                    ,p_organization_type           => p_organization_type         
                    ,p_Todays_Date_Time            => p_Todays_Date_Time          
                    ,x_external_source_ouput_tbl   => lt_ext_source_ouput_tbl
                    ,x_atp_status                  => lc_atp_status
                    ,x_atp_error_message           => lc_atp_error_message
                   );
       
       IF lc_atp_status = 'S' THEN
       
         FOR I_mls_supplier IN lt_ext_source_ouput_tbl.FIRST..lt_ext_source_ouput_tbl.LAST
         LOOP
           x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_mls_supplier).source_supplier_type         := lt_ext_source_ouput_tbl(I_sls_supplier).source_supplier_type  ;    
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_mls_supplier).supplier_id               	:= lt_ext_source_ouput_tbl(I_sls_supplier).supplier_id           ;    
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_mls_supplier).supplier_site_id          	:= lt_ext_source_ouput_tbl(I_sls_supplier).supplier_site_id      ;    
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_mls_supplier).supplier_location         	:= lt_ext_source_ouput_tbl(I_sls_supplier).supplier_location     ;    
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_mls_supplier).facility_code             	:= lt_ext_source_ouput_tbl(I_sls_supplier).facility_code         ;    
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_mls_supplier).supplier_account          	:= lt_ext_source_ouput_tbl(I_sls_supplier).supplier_account      ;    
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_mls_supplier).supplier_rank             	:= lt_ext_source_ouput_tbl(I_sls_supplier).supplier_rank         ;    
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_mls_supplier).request_date_available_qty	:= lt_ext_source_ouput_tbl(I_sls_supplier).request_date_available_qty;
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_mls_supplier).atp_fulfillment_type      	:= lt_ext_source_ouput_tbl(I_sls_supplier).atp_fulfillment_type;
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_mls_supplier).scheduled_ship_date          := lt_ext_source_ouput_tbl(I_sls_supplier).scheduled_ship_date       ;  
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_mls_supplier).scheduled_arrival_date       := lt_ext_source_ouput_tbl(I_sls_supplier).scheduled_arrival_date    ;  
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_mls_supplier).available_Date               := lt_ext_source_ouput_tbl(I_sls_supplier).available_Date            ;  
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_mls_supplier).atp_date_calc_sts            := lt_ext_source_ouput_tbl(I_sls_supplier).atp_date_calc_sts         ;  
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_mls_supplier).atp_date_calc_return_message := lt_ext_source_ouput_tbl(I_sls_supplier).atp_date_calc_return_message;
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_mls_supplier).atp_date_calc_warnings       := lt_ext_source_ouput_tbl(I_sls_supplier).atp_date_calc_warnings      ;
       	   x_msc_extsrc_slsmls_out_tbl(ln_index).lt_ext_source_sls_ouput_tbl(I_mls_supplier).atp_date_calc_warning_msg    := lt_ext_source_ouput_tbl(I_sls_supplier).atp_date_calc_warning_msg   ;
         END LOOP;
         x_msc_extsrc_slsmls_out_tbl(ln_index).atp_status := 'S';
         x_msc_extsrc_slsmls_out_tbl(ln_index).atp_error_message := 'Successfully process external ATP sourcing for the supplier'||lcu_sls_suppliers_info.vendor_id;
       ELSE
         x_msc_extsrc_slsmls_out_tbl(ln_index).atp_status := 'S';
         x_msc_extsrc_slsmls_out_tbl(ln_index).atp_error_message := 'Could not process the external ATP sourcing for the supplier'||lcu_sls_suppliers_info.vendor_id;
       END IF;

      END IF;
           
    END LOOP;
    CLOSE lcu_sls_suppliers_info;
    
  EXCEPTION
   WHEN OTHERS THEN
    o_status             := FND_API.G_RET_STS_UNEXP_ERROR;
    dbms_output.put_line('Status in OTHERS: '||o_status);
    --Log Exception
    FND_MESSAGE.SET_NAME('XXOM','XX_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
    
    lc_error_code        := 'XX_OM_UNEXPECTED_ERR-01';
    lc_error_desc        := FND_MESSAGE.GET;
    lc_entity_ref_id     := p_inventory_item_id;
    log_exceptions(lc_error_code             
                  ,lc_error_desc
                  ,lc_entity_ref_id    
                  );    
  END Process_MLS_SLS_Sourcing;
  
END XX_MSC_SOURCING_EXT_ATP_PKG;
/
SHOW ERRORS;
--EXIT;