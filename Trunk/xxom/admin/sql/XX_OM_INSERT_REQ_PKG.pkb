SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE
PACKAGE BODY XX_OM_INSERT_REQ_PKG 
-- +=============================================================================================+
-- |                        Office Depot - Project Simplify                                      |
-- |                         WIPRO Consulting Organization                                       |
-- +=============================================================================================+
-- | Name         : XX_OM_INSERT_REQ_PKG                                                         |
-- | Rice Id      : E1279                                                                        |
-- | Description  : Package Body                                                                 |
-- |                                                                                             |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version    Date              Author               Remarks                                    |
-- |=======    ==========        =============        ========================                   |
-- |V1.0       21-MAY-2007       SANDEEP GORLA(WIPRO) API To insert records into Requisition     |
-- |						      interface table.This API will be           |
-- |						      called from Order line Workflow with       |
-- |						      source as 'OM' and the same API can        |
-- |						      be used for any other source(WMS) to do  	 |
-- |						      inventory transfers between warehouses.	 |
-- |V1.1       07-JUN-2007       SANDEEP GORLA(WIPRO) Changed the code to assign error_code      |
-- |                                                  direclty to the global exception procedure |                                      
-- |						      XX_LOG_EXCEPTION_PROC instead of custom    |
-- |						      numbers                                    |
-- |V1.2       10-JUL-2007       SANDEEP GORLA(WIPRO) Modified the code to remove hardcoding of  |
-- |                                                  attribute_category and assign to a variable|
-- +=============================================================================================+
AS

 
lc_error_msg            VARCHAR2(1000);
lc_entity_ref           VARCHAR2(40);
ln_entity_ref_id        NUMBER;
  
  /*****************************************************************************
   * 	AUTHOR     : Sandeep Gorla					       *
   *    RICE ID    : E1279                            			       *
   *    PROCEDURE  : XX_LOG_EXCEPTION_PROC                                     *
   *	DESCRIPTION: Procedure to log exceptions                               *
   *                                                                           *
   *                                                                           *
   *****************************************************************************/
  
  PROCEDURE XX_LOG_EXCEPTION_PROC(p_error_code        IN  VARCHAR2
                                 ,p_error_description IN  VARCHAR2
                                 ,p_entity_ref        IN  VARCHAR2
                                 ,p_entity_ref_id     IN  NUMBER
                                  )
  IS
  x_errbuf              VARCHAR2(1000);
  x_retcode             VARCHAR2(40);
  
  BEGIN
  
             exception_object_type.p_exception_header  :=    G_exception_header;
             exception_object_type.p_track_code        :=    G_track_code;
             exception_object_type.p_solution_domain   :=    G_solution_domain;
             exception_object_type.p_function          :=    G_function;
  
             exception_object_type.p_error_code        :=    p_error_code;
  	     exception_object_type.p_error_description :=    p_error_description;
  	     exception_object_type.p_entity_ref        :=    p_entity_ref;
   	     exception_object_type.p_entity_ref_id     :=    p_entity_ref_id;    
  
  
             XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(exception_object_type,x_errbuf,x_retcode);
  
  END;
  
    /*****************************************************************************
     * 	AUTHOR     : Sandeep Gorla					         *
     *  RICE ID    : E1279                            			         *
     *  PROCEDURE  : INSERT_INTO_REQ_INTF                                        *
     *	DESCRIPTION: Inserts record into Requisition Interface table.            *
     *                                                                           *
     *                                                                           *
     *****************************************************************************/

  PROCEDURE INSERT_INTO_REQ_INTF (p_source            IN   Po_Requisitions_Interface_All.interface_source_code%TYPE
                                 ,p_inv_item_id       IN   Oe_Order_Lines_All.inventory_item_id%TYPE
                                 ,p_uom               IN   Oe_Order_Lines_All.order_quantity_uom%TYPE
                                 ,p_ord_quantity      IN   Oe_Order_Lines_All.ordered_quantity%TYPE
                                 ,p_need_by_date      IN   Oe_Order_Lines_All.schedule_ship_date%TYPE
                                 ,p_dest_org_id       IN   Mtl_Parameters.organization_id%TYPE
                                 ,p_delivery_loc_id   IN   Hr_Locations_All.location_id%TYPE
                                 ,p_source_org_id     IN   Mtl_Parameters.organization_id%TYPE
                                 ,p_dest_subinv_code  IN   VARCHAR2
                                 ,p_so_order_number   IN   Oe_Order_Headers_All.order_number%TYPE
                                 ,p_so_line_id        IN   Oe_Order_Lines_All.line_id%TYPE
                                 ,x_result            OUT  VARCHAR2)
  IS
  
  lc_req_type                  Po_Requisitions_Interface_All.requisition_type%TYPE      :='INTERNAL';
  lc_dest_type_code            Po_Requisitions_Interface_All.destination_type_code%TYPE :='INVENTORY';
  lc_authorization_status      Po_Requisitions_Interface_All.authorization_status%TYPE  :='APPROVED';
  lc_source_type_code          Po_Requisitions_Interface_All.source_type_code%TYPE      :='INVENTORY';
  lc_line_attribute_category   Po_Requisitions_Interface_All.line_attribute_category%TYPE;
  ln_user_id                   Fnd_User.user_id%TYPE := FND_GLOBAL.USER_ID;
  ln_org_id                    Hr_Operating_Units.Organization_id%TYPE := TO_NUMBER(FND_PROFILE.value('ORG_ID'));
  
  
  lc_source                    Po_Requisitions_Interface_All.interface_source_code%TYPE;
  ln_inv_item_id               Oe_Order_Lines_All.inventory_item_id%TYPE;
  lc_uom                       Oe_Order_Lines_All.order_quantity_uom%TYPE;
  ln_ord_quantity              Oe_Order_Lines_All.ordered_quantity%TYPE;
  ld_need_by_date              Oe_Order_Lines_All.request_date%TYPE;
  ln_so_line_id                Oe_Order_Lines_All.line_id%TYPE;
  ln_so_order_number           Oe_Order_Headers_All.order_number%TYPE;
  ln_dest_org_id               Mtl_Parameters.organization_id%TYPE;
  ln_delivery_loc_id           Hr_Locations_All.location_id%TYPE;
  ln_source_org_id             Mtl_Parameters.organization_id%TYPE;
  lc_dest_subinv_code          VARCHAR2(50);
  ln_charge_account_id         Mtl_Parameters.material_account%TYPE;
  ln_preparer_id               Per_People_F.person_id%TYPE;
  lc_process_flag              VARCHAR2(1);
  lc_context		       VARCHAR2(15) := 'Internal';
  
  --Read the profile value for Employee number
  lc_employee_number Per_People_F.employee_number%TYPE := FND_PROFILE.VALUE('XX_OM_INTERNAL_REQUISITION_PREPARER');
    
  BEGIN
     
     --Read the profile option to get the Preparer Name
     
     
     --Assign input parameter values to local variables
     lc_source            :=p_source;
     ln_inv_item_id       :=p_inv_item_id;
     lc_uom               :=p_uom;
     ln_ord_quantity      :=p_ord_quantity;
     ld_need_by_date      :=p_need_by_date;
     ln_dest_org_id       :=p_dest_org_id;
     ln_delivery_loc_id   :=p_delivery_loc_id;
     ln_source_org_id     :=p_source_org_id;
     lc_dest_subinv_code  :=p_dest_subinv_code;
     ln_so_order_number   :=p_so_order_number;
     ln_so_line_id        :=p_so_line_id;
    
     
     IF lc_source='OM' THEN
        ln_so_order_number          :=p_so_order_number;
        ln_so_line_id               :=p_so_line_id;
        lc_line_attribute_category  :=lc_context;
     ELSE ---Setting the below variables to NULL for other sources like 'WMS'(Used for Inventory Transfers)
        ln_so_order_number         :=NULL;
        ln_so_line_id              :=NULL;
        lc_line_attribute_category :=NULL;
     END IF;
     
     --Fetch the charge account for the destination organization
     BEGIN
        SELECT material_account
        INTO   ln_charge_account_id
        FROM   mtl_parameters
        WHERE  organization_id = ln_dest_org_id;
     EXCEPTION
        WHEN NO_DATA_FOUND THEN
        ln_charge_account_id :=NULL;
        WHEN TOO_MANY_ROWS THEN
        ln_charge_account_id :=NULL;
     END;
     	
     --Fetch the person id of the generic employee who is set as a profile      
     BEGIN
        SELECT person_id
        INTO   ln_preparer_id
        FROM   per_people_f 
        WHERE  TRUNC(SYSDATE) BETWEEN TRUNC(NVL(effective_start_date,sysdate))
        AND    TRUNC(NVL(effective_end_date,sysdate))
        AND    employee_number =lc_employee_number;
     EXCEPTION 
        WHEN NO_DATA_FOUND THEN
        ln_preparer_id :=NULL;
        WHEN TOO_MANY_ROWS THEN
        ln_preparer_id :=NULL;
     END;
  	    
   BEGIN        
     INSERT INTO po_requisitions_interface_all                                                                                                                                                                                                                                                                                                                                                               
     (LAST_UPDATED_BY                                                                                                                                                                                                            
     ,LAST_UPDATE_DATE                                                                                                                                                                                                               
     ,CREATION_DATE                                                                                                                                                                                                               
     ,CREATED_BY 
     ,INTERFACE_SOURCE_CODE                                                                                                                                                                                                                                                                                                                                                                                                
     ,SOURCE_TYPE_CODE                                                                                                                                                                                                         
     ,REQUISITION_TYPE                                                                                                                                                                                                          
     ,DESTINATION_TYPE_CODE                                                                                                                                                                                     
     ,QUANTITY                                                                                                                                                                                                                                                                                                                                                                                                                                       
     ,AUTHORIZATION_STATUS                                                                                                                                                                                                                                                                                                                                                                                                                  
     ,PREPARER_ID                                                                                                                                                                                                               
     ,AUTOSOURCE_FLAG                                                                                                                                                                                                        
     ,ITEM_ID                                                                                                                                                                                                                       
     ,CHARGE_ACCOUNT_ID                                                                                                                                                                                                                                                                                                                                                                                           
     ,UOM_CODE                                                                                                                                                                                                                 
     ,SOURCE_ORGANIZATION_ID                                                                                                                                                                                                          
     ,DESTINATION_ORGANIZATION_ID                                                                                                                                                                                                
     ,DESTINATION_SUBINVENTORY                                                                                                                                                                                                 
     ,DELIVER_TO_LOCATION_ID                                                                                                                                                                                                    
     ,DELIVER_TO_REQUESTOR_ID                                                                                                                                                                                                  
     ,LINE_ATTRIBUTE_CATEGORY                                                                                                                                                                                               
     ,LINE_ATTRIBUTE6
     ,LINE_ATTRIBUTE7
     ,NEED_BY_DATE                                                                                                                                                                                                                
     ,ACCRUAL_ACCOUNT_ID                                                                                                                                                                                                         
     ,VARIANCE_ACCOUNT_ID
     ,ORG_ID)
      VALUES
      (ln_user_id
      ,SYSDATE
      ,SYSDATE
      ,ln_user_id
      ,lc_source
      ,lc_source_type_code
      ,lc_req_type
      ,lc_dest_type_code
      ,ln_ord_quantity
      ,lc_authorization_status
      ,ln_preparer_id
      ,'N'
      ,ln_inv_item_id
      ,ln_charge_account_id
      ,lc_uom
      ,ln_source_org_id
      ,ln_dest_org_id
      ,lc_dest_subinv_code
      ,ln_delivery_loc_id
      ,ln_preparer_id
      ,lc_line_attribute_category
      ,ln_so_order_number
      ,ln_so_line_id
      ,NVL(ld_need_by_date,SYSDATE)
      ,NULL
      ,NULL
      ,ln_org_id
      ); 
  COMMIT;
  x_result := 'SUCCESS';
  EXCEPTION
  WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME ('xxom','XX_OM_XDOCK_INTREQINS_FAILED');
              
             lc_error_msg	:=	 FND_MESSAGE.GET;
             lc_entity_ref	:=	'Item ID';
             ln_entity_ref_id   :=	 ln_inv_item_id;
             
             XX_LOG_EXCEPTION_PROC ('XX_OM_XDOCK_INTREQINS_FAILED'
               	            ,lc_error_msg
               	            ,lc_entity_ref
               	            ,ln_entity_ref_id
	                    );
  x_result := 'FAILURE';
  END;
  
  EXCEPTION 
  WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME ('xxom','XX_OM_XDOCK_INTREQ_OTHER_ERROR');
                
               lc_error_msg	 :=	 FND_MESSAGE.GET;
               lc_entity_ref	 :=	'Item ID';
               ln_entity_ref_id  :=	 ln_inv_item_id;
               
               XX_LOG_EXCEPTION_PROC ('XX_OM_XDOCK_INTREQ_OTHER_ERROR'
                 	            ,lc_error_msg
                 	            ,lc_entity_ref
                 	            ,ln_entity_ref_id
	                    );
  x_result := 'FAILURE';	                    
  END INSERT_INTO_REQ_INTF;

END XX_OM_INSERT_REQ_PKG;
/
show errors
 
