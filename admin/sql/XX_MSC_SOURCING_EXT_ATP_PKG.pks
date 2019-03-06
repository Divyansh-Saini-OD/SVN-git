SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE  XX_MSC_SOURCING_EXT_ATP_PKG
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

  --Declaring a record, which contains the output details
  TYPE xx_msc_ext_source_ouput_t IS RECORD 
                   (  source_supplier_type         xx_po_ssa_v.supp_loc_count_ind%TYPE 
                     ,supplier_id                  xx_po_mlss_det.vendor_id%TYPE
                     ,supplier_site_id             xx_po_mlss_det.vendor_site_id%TYPE 
                     ,supplier_location            xx_po_mlss_det.supp_loc_ac%TYPE
                     ,facility_code                xx_po_mlss_det.supp_facility_cd%TYPE
                     ,supplier_account             xx_po_mlss_det.supp_loc_ac%TYPE
		     ,supplier_rank                xx_po_mlss_det.rank%TYPE 
		     ,request_date_available_qty   xx_om_suppl_inv_feed_txn_all.feed_qty%TYPE
		     ,scheduled_ship_date          DATE                         
		     ,scheduled_arrival_date       DATE                         
		     ,available_Date               DATE                         
		     ,atp_fulfillment_type         VARCHAR2(50)
		     ,atp_date_calc_sts            VARCHAR2(2)
		     ,atp_date_calc_return_message VARCHAR2(2000)
		     ,atp_date_calc_warnings       VARCHAR2(2)
		     ,atp_date_calc_warning_msg    VARCHAR2(2000)
                    );

  --Table of the record contains output details
  TYPE xx_msc_ext_source_ouput_tbl IS TABLE OF xx_msc_ext_source_ouput_t INDEX BY BINARY_INTEGER;
  lt_ext_source_ouput_tbl     xx_msc_ext_source_ouput_tbl;
  lt_ext_source_sls_ouput_tbl xx_msc_ext_source_ouput_tbl;
  lt_ext_source_mls_ouput_tbl xx_msc_ext_source_ouput_tbl;  

  --Declaring a record, which contains the output record types for both SLS and MLS
  TYPE xx_msc_extsource_slsmls_out_t IS RECORD 
                   ( atp_status                VARCHAR2(2)
                    ,atp_error_message         VARCHAR2(2000)
                    ,lt_ext_source_sls_ouput_tbl xx_msc_ext_source_ouput_tbl 
                    ,lt_ext_source_mls_ouput_tbl xx_msc_ext_source_ouput_tbl
                    );

  --Table of the record which contains the output record types for both SLS and MLS
  TYPE xx_msc_extsrc_slsmls_out_tbl IS TABLE OF xx_msc_extsource_slsmls_out_t INDEX BY BINARY_INTEGER;
  lt_msc_extsrc_slsmls_out_tbl xx_msc_extsrc_slsmls_out_tbl;


  --Cursor to fetch all the SLS suppliers 
  ---------------------------------------
  CURSOR lcu_sls_suppliers_info 
                               (
                               ,p_customer_number           hz_cust_accounts.account_number%TYPE
                               ,p_vertical_market_indicator xx_po_ssa_v.vm_indicator%TYPE
                               ,p_internal_item_number      mtl_system_items_b.segment1%TYPE
                               ,p_base_organization         mtl_parameters.organization_code%TYPE 
                               ,p_supp_loc_count_ind        xx_po_ssa_v.supp_loc_count_ind%TYPE
                               )
  IS    
  SELECT   XPSV.asl_id                 asl_id               
          ,XPSV.using_organization_id  using_organization_id
          ,XPSV.organization_code      organization_code    
          ,XPSV.item_id                item_id              
          ,XPSV.item_name              item_name            
          ,XPSV.vendor_id              vendor_id            
          ,XPSV.vendor_name            vendor_name          
          ,XPSV.vendor_site_id         vendor_site_id       
          ,XPSV.vendor_site_code       vendor_site_code     
          ,XPSV.disabled               disabled             
          ,XPSV.Vm_Indicator           vm_indicator         
          ,XPSV.rank                   rank                 
          ,XPSV.supp_loc_count_ind     supp_loc_count_ind   
          ,XPSV.inv_type_ind           inv_type_ind         
          ,XPSV.primary_supp_ind       primary_supp_ind     
          ,XPSV.lead_time              lead_time            
          ,XPSV.drop_ship_cd           drop_ship_cd         
          ,XPSV.mls_source_name	       mls_source_name
          ,MSI.primary_unit_of_measure primary_unit_of_measure
  FROM     hz_cust_accounts            HCA
          ,hz_cust_acct_sites          HCAS
          ,hz_cust_site_uses           HCSU
          ,xx_po_ssa_v                 XPSV
          ,po_approved_supplier_list   PASL
          ,mtl_system_items_b          MSI
          ,mtl_parameters              MP
  WHERE    HCA.account_number||''      = p_customer_number
  AND      HCA.cust_account_id         = HCAS.cust_account_id
  AND      HCAS.cust_acct_site_id      = HCSU.cust_acct_site_id
  AND      HCSU.attribute6             = p_vertical_market_indicator
  AND      XPSV.vm_indicator           = HCSU.Attribute6
  AND      XPSV.asl_id                 = PASL.asl_id  
  AND      XPSV.drop_ship_cd IS NOT NULL
  AND      MP.organization_code        = p_base_organization 
  AND      MP.organization_id          = XPSV.using_organization_id
  AND      XPSV.using_organization_id  = MSI.organization_id
  AND      MSI.segment1                = p_internal_item_number
  AND      XPSV.item_id                = MSI.inventory_item_id
  AND      XPSV.item_name              = MSI.segment1
  AND      XPSV.supp_loc_count_ind     = NVL(p_supp_loc_count_ind,XPSV.supp_loc_count_ind) 
  ORDER BY XPSV.rank;     
  
  --Cursor to extract virtual stock
  ---------------------------------
  CURSOR lcu_inventory_feed_info
                                (
                                 p_supplier_id  po_approved_supplier_list.vendor_id%TYPE
                                ,p_item_id      po_approved_supplier_list.item_id%TYPE
                                )
  IS
  SELECT XOSIT.on_hand_qty           on_hand_qty
  FROM   xx_om_supplier_invfeed_hdr_all XOSIH
        ,xx_om_supplier_invfeed_txn_all XOSIT
  WHERE  XOSIH.supplier_id = p_supplier_id
  AND    XOSIT.item_numer  = p_item_id
  AND    XOSIH.supplier_id = XOSIT.supplier_id;

  --Cursor to extract all the MLS suppliers
  -----------------------------------------
  CURSOR lcu_mls_suppliers_info
                                (
                                 p_base_organization    mtl_parameters.organization_code.vendor_id%TYPE
                                ,p_internal_item_number po_approved_supplier_list.item_id%TYPE
                                ,p_request_date         DATE
                                ,p_vendor_id            xx_po_mlss_det.vendor_id%TYPE
                                ,p_vendor_site_id       xx_po_mlss_det.p_vendor_site_id%TYPE
                                )
  IS
  SELECT XPMH.using_organization_id     using_organization_id
        ,XPMH.category             	category             
        ,XPMH.category_level       	category_level       
        ,XPMH.start_date           	start_date           
        ,XPMH.end_date             	end_date             
        ,XPMH.imu_amt_pt           	imu_amt_pt           
        ,XPMH.imu_value            	imu_value            
        ,XPMD.mlss_line_id     		mlss_line_id     
        ,XPMD.vendor_id        		vendor_id        
        ,XPMD.vendor_site_id   		vendor_site_id   
        ,XPMD.supply_loc_no    		supply_loc_no    
        ,XPMD.rank             		rank             
        ,XPMD.end_point        		end_point        
        ,XPMD.ds_lt            		ds_lt            
        ,XPMD.b2b_lt           		b2b_lt           
        ,XPMD.supp_loc_ac      		supp_loc_ac      
        ,XPMD.supp_facility_cd 		supp_facility_cd 
  FROM   xx_po_mlss_hdr                 XPMH
        ,xx_po_mlss_det                 XPMD 
        ,mtl_parameters                 MP
        ,mtl_categories_b               MCB
        ,mtl_category_sets              MCS
        ,mtl_item_categories            MIC
  WHERE  MP.organization_code   = p_base_organization
  AND    MP.organization_id     = XPMH.using_organization_id
  AND    XPMH.mlss_header_id    = XPMD.mlss_header_id
  AND   ((MCB.segment1          = XPMH.category  AND
	  XPMH.category_level   = 'Division')
        OR (MCB.segment3        = xpmh.category AND 
            XPMH.category_level = 'Department')	
        OR (MCB.segment4        = XPMH.category AND 
            XPMH.category_level = 'Class'))
  AND   MCB.structure_id        = MCS.structure_id	 
  AND   MCS.category_set_name   = 'Inventory'
  AND   MCB.category_id         = MIC.category_id
  AND   MIC.category_set_id     = MCS.category_set_id
  AND   MIC.organization_id     = XPMH.using_organization_id	 		   	  
  AND   MIC.inventory_item_id   = p_internal_item_id
  AND   NVL(p_request_date,SYSDATE) BETWEEN XPMH.start_date and NVL(XPMH.end_date,SYSDATE)
  AND   XPMD.vendor_id          = NVL(p_vendor_id,XPMD.vendor_id)
  AND   XPMD.vendor_site_id     = NVL(p_vendor_site_id,XPMD.vendor_site_id)
  ORDER BY XPMD.rank;

  --Cursor record type 
  ---------------------
  l_sls_suppliers_info      lcu_sls_suppliers_info%ROWTYPE;
  l_inventory_feed_info     lcu_inventory_feed_info%ROWTYPE;
  l_mls_suppliers_info      lcu_mls_suppliers_info%ROWTYPE;
  
  
  --Initializing the object type to parse the exception infos to global exception handling framework
  --------------------------------------------------------------------------------------------------
  lrec_excepn_obj_type xx_om_report_exception_t:= 
                                   xx_om_report_exception_t('OTHERS'
                                                           ,'OTC'
                                                           ,'ATP'
                                                           ,'Virtual Warehousing'
                                                           ,NULL
                                                           ,NULL
                                                           ,'Supplier Id'
                                                           ,NULL);

  --Variables used to initialize the Apps Environment
  ---------------------------------------------------
  g_c_user_name            CONSTANT   VARCHAR2(100) := 'NABARUNG'; 
  g_c_resp_name            CONSTANT   VARCHAR2(240) := 'Order Management Super User';
  g_n_user_id                         NUMBER;       --:= FND_GLOBAL.USER_ID;
  g_n_resp_id                         NUMBER;
  g_n_resp_app_id                     NUMBER;
  g_n_org_id                          NUMBER;       --:= FND_GLOBAL.ORG_ID;
  g_source_supplier_type   CONSTANT   VARCHAR2(3)  := 'SLS' ;
  
  -- +=================================================================+
  -- | Name  : Log_Exceptions                                          |
  -- | Rice Id      : E1335_Virtual_Warehouse                          | 
  -- | Description: This procedure will be responsible to store all    |  
  -- |              the exceptions occured during the procees using    | 
  -- |              global custom exception handling framework         |
  -- +=================================================================+
  PROCEDURE log_exceptions( p_error_code        IN  VARCHAR2
                           ,p_error_description IN  VARCHAR2
                           ,p_entity_ref_id     IN  PLS_INTEGER
                          );

  -- +===================================================================+
  -- | Name  : Process_External_Sourcing                                 |
  -- | Rice Id      : E1335_Virtual_Warehouse                            | 
  -- | Description:       This is a main wrapper Procedure, which will be|
  -- |                    deciding to find the best sourcing from either |
  -- |                    SLS or MLS or from BOTH suppliers.             |
  -- +===================================================================+
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
            ) ;


  -- +===================================================================+
  -- | Name  : Virtual_Warehouse_Sourcing                                |
  -- | Rice Id      : E1335_Virtual_Warehouse                            | 
  -- | Description:       This Procedure will be extarcting the required |
  -- |                    Item Quantity from the Virtual Warehouses,     |
  -- |                    where the suppliers that have a prearranged    |
  -- |                    agreement to virtually stock items for OD, an  |
  -- |                    extension of OD operated locations .           |
  -- +===================================================================+  
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
		 ,p_base_organization           IN  mtl_parameters.organization_id%TYPE           		      
		 ,p_carrier_calendar            IN  VARCHAR2
		 ,p_customer_delivery_calendar  IN  VARCHAR2
		 ,p_vendor_calendar             IN  VARCHAR2
		 ,p_organization_type           IN  VARCHAR2
		 ,p_todays_date_time            IN  DATE
		 ,x_external_source_ouput_tbl   OUT NOCOPY xx_msc_ext_source_ouput_tbl
                 ,x_atp_status                  OUT NOCOPY VARCHAR2
                 ,x_atp_error_message           OUT NOCOPY VARCHAR2
                ) ;   
                
  -- +===================================================================+
  -- | Name  : MLS_Suppliers_Sourcing                                    |
  -- | Rice Id      : E1335_Virtual_Warehouse                            | 
  -- | Description:       This Procedure will be extarcting the best     |
  -- |                    MLS supply sourcing based on the Rank.         |
  -- |                                                                   |
  -- |                                                                   |
  -- +===================================================================+
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
                         ,p_Todays_Date_Time            IN  DATE		      
                         ,x_external_source_ouput_tbl   OUT NOCOPY xx_msc_ext_source_ouput_tbl
                         ,x_atp_status                  OUT NOCOPY VARCHAR2                      
                         ,x_atp_error_message           OUT NOCOPY VARCHAR2                      
                        );

  -- +===================================================================+
  -- | Name  : MLS_Suppliers_Sourcing                                    |
  -- | Rice Id      : E1335_Virtual_Warehouse                            | 
  -- | Description:       This Procedure will be extarcting the best     |
  -- |                    supply sourcing based on the Rank for both SLS |
  -- |                    and MLS suppliers.                             |
  -- |                                                                   |
  -- +===================================================================+                         
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
                               );
 
                
  
END XX_MSC_SOURCING_EXT_ATP_PKG;
/
SHOW ERRORS;
--EXIT;