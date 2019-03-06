SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE
PACKAGE BODY XX_OM_INTREQ_PKG 
-- +=============================================================================================+
-- |                        Office Depot - Project Simplify                                      |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                           |
-- +=============================================================================================+
-- | Name         : XX_OM_INTREQ_PKG                                                             |
-- | Rice Id      : E1279                                                                        |
-- | Description  : Package Body                                                                 |
-- |                                                                                             |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version    Date              Author               Remarks                                    |
-- |=======    ==========        =============        ========================                   |
-- |V1.0   28-MAY-2007       SANDEEP GORLA(WIPRO)     This program will be run as a standalone   |
-- |						      program to submit for a sales order# or    |
-- |						      for all sales orders for a date range      |
-- |						      and insert data into req.Interface table   |
-- |						      to create Internal requisition for source  |
-- |						      'OM'.                                      |
-- |V1.1  12-JUN-2007       SANDEEP GORLA(WIPRO)      Modified the code to look at segment18     |
-- |                                                  instead of segment16 as the segment was    |
-- |                                                  not defined in front end while developing  |
-- |                                                  the code.                                  |
-- |V1.2  09-JUL-2007       SANDEEP GORLA(WIPRO)      Modified the code to write the error mess. |
-- |                                                  to exception pool.                         |
-- |V1.3  23-JUL-2007       SANDEEP GORLA(WIPRO)      Modified the code to implement new         |
-- |                                                  attribu structure.                         |
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
       *  AUTHOR     : Sandeep Gorla					           *
       *  RICE ID    : E1279                            			   *
       *  PROCEDURE  : IS_SALES_ORDER_ELIGIBLE                                     *
       *  DESCRIPTION: Checks whether there are any eligible sales orders .        *
       *               to create internal requisitions                             *
       *                                                                           *
       *****************************************************************************/
  
  PROCEDURE IS_SALES_ORDER_ELIGIBLE( x_retcode          OUT  VARCHAR2
                                    ,x_errbuf           OUT  VARCHAR2
                                    ,p_source           IN   VARCHAR2
                                    ,p_order_number     IN   NUMBER
                                    ,p_from_Date        IN   DATE
                                    ,p_to_date          IN   DATE
                                    )  
                                    
  IS
  
    lc_process_flag              VARCHAR2(1);
    ln_ord_num                   Oe_Order_Headers_All.order_number%TYPE;
    ln_line_id                   Oe_Order_Lines_All.line_id%TYPE;
    lc_status                    VARCHAR2(10);
    lc_cancel_flag               Po_Requisition_Lines_All.cancel_flag%TYPE;
    lc_closed_code               Po_Requisition_Lines_All.closed_code%TYPE;
    lc_debug_msg                 VARCHAR2(500);
    lcu_crossdock_so_found       VARCHAR2(1):='Y';
    lc_retcode                   VARCHAR2(100);
    lc_errbuf                    VARCHAR2(100);
    lc_source                    Po_Requisitions_Interface_All.interface_source_code%TYPE;
    lc_context                   VARCHAR2(15):='Internal';
    
    
    
    
      
    --Cursor to select the sales order numbers for the given parameters
    CURSOR lcu_crossdock_so IS
    SELECT OEH.order_number order_number
          ,OEL.line_id
    FROM   oe_order_headers_all OEH
  	  ,oe_order_lines_all OEL
  	  ,mtl_parameters MP
  	  ,xx_om_line_attributes_all XOLL     --Added as part of V.1.3
  	  --,xx_om_lines_attributes_all XOLL  --Commented as part of V.1.3
    WHERE  OEH.header_id=OEL.header_id
    AND    OEH.org_id=FND_PROFILE.value('ORG_ID')
    AND    OEH.order_number = NVL(p_order_number,OEH.order_number)
    --AND    XOLL.segment18 =to_char(MP.organization_id)  --Commented as part of V.1.3
    AND    OEL.line_id=XOLL.line_id                       --Added as part of V.1.3
    AND    XOLL.xdock_inv_org_id =MP.organization_id      --Added as part of V.1.3
    AND    TRUNC(OEH.creation_Date) BETWEEN TRUNC(NVL(p_from_date,OEH.creation_date)) 
    AND    TRUNC(NVL(p_to_date,OEH.creation_date))
    AND    OEH.flow_status_code NOT IN ('ENTERED','CANCELED')
    AND    OEL.flow_status_code NOT IN ('ENTERED','CANCELED');
   
    BEGIN
       
       lc_source := p_source;
       
       OPEN  lcu_crossdock_so;
       LOOP
       FETCH lcu_crossdock_so INTO ln_ord_num,ln_line_id;
           
       IF (lcu_crossdock_so%ROWCOUNT)=0 THEN
           lcu_crossdock_so_found :='N';
       END IF;
       EXIT WHEN lcu_crossdock_so%NOTFOUND;
       
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Processing Sales Order :'||ln_ord_num);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Processing Line ID     :'||ln_line_id);
       
       --check whether any requisition already existing for the given sales order and  line.
       
       BEGIN
          SELECT 'EXISTS'
          INTO   lc_status
          FROM   po_requisition_headers_all PRH
                ,po_requisition_lines_all PRL
          WHERE  PRH.requisition_header_id=PRL.requisition_header_id
          AND    PRL.attribute6= TO_CHAR(ln_ord_num)
          AND    PRL.attribute7= TO_CHAR(ln_line_id)
          AND    PRL.attribute_category=lc_context
          UNION 
          SELECT 'EXISTS'
          FROM   po_requisitions_interface_all 
          WHERE  line_attribute6=TO_CHAR(ln_ord_num)
          AND    line_attribute7=TO_CHAR(ln_line_id)
          AND    line_attribute_category=lc_context;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
            lc_status := NULL;
       END;
          
          --If no requisition exists then call procedure to create requisition
          IF lc_status IS NULL THEN
             
             INSERT_INTREQ_INTF(lc_retcode,lc_errbuf,lc_source,ln_ord_num,ln_line_id);
          
          --If requisition exists,check whether the requisition is cancelled or closed
          ELSIF lc_status='EXISTS' THEN
          
             BEGIN
                SELECT PRL.cancel_flag
                      ,PRL.closed_code
                INTO   lc_cancel_flag
                      ,lc_closed_code
                FROM   po_requisition_headers_all PRH
                      ,po_requisition_lines_all PRL
                WHERE  PRH.requisition_header_id=PRL.requisition_header_id
                AND    PRL.attribute6= TO_CHAR(ln_ord_num)
                AND    PRL.attribute7= TO_CHAR(ln_line_id)
                AND    PRL.attribute_category=lc_context;
             EXCEPTION 
             WHEN NO_DATA_FOUND THEN
                  lc_cancel_flag := NULL;
                  lc_closed_code := NULL;
             WHEN TOO_MANY_ROWS THEN
                  lc_debug_msg :='Too many rows while checking the status of the requisition for the order Line id -'||SUBSTR(SQLERRM,1,200);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);
                  
                  FND_MESSAGE.SET_NAME ('xxom','XX_OM_XDOCK_ERROR_REQ_STATUS');
		                
		              lc_error_msg	:=	 FND_MESSAGE.GET;
		              lc_entity_ref	:=	'Line ID';
		              ln_entity_ref_id  :=	 ln_line_id;
		               
		              XX_LOG_EXCEPTION_PROC ('XX_OM_XDOCK_ERROR_REQ_STATUS'
		                 	            ,lc_error_msg
		                 	            ,lc_entity_ref
		                 	            ,ln_entity_ref_id
	                    			     );
             END;
             
                --If Requisition is cancelled or closed ,then initiate the procedure to create requisition
              
                IF lc_cancel_flag ='Y' OR lc_closed_code ='FINALLY CLOSED' THEN
                
                   INSERT_INTREQ_INTF(lc_retcode,lc_errbuf,lc_source,ln_ord_num,ln_line_id);
                ELSE
                   lc_debug_msg :='Cannot Insert Into Interface Table.Sales order line is not eligible for Requisition creation';
                   FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);
                END IF;
          END IF;
       END LOOP;
       CLOSE lcu_crossdock_so;
       
       IF lcu_crossdock_so_found ='N' THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'No Sales Order found which is eligible for Internal Requisition Creation');
       END IF;
 
  EXCEPTION 
  WHEN OTHERS THEN
         CLOSE lcu_crossdock_so;
         lc_debug_msg := 'Encountered Unexpected Error while processing-'||SUBSTR(SQLERRM,1,200);
         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);
         FND_MESSAGE.SET_NAME ('xxom','XX_OM_XDOCK_UNEXPECTED_ERROR');
	 		                
	             lc_error_msg	:=	 FND_MESSAGE.GET;
	 	     lc_entity_ref	:=	'Line ID';
	 	     ln_entity_ref_id   :=	 ln_line_id;
	 		               
	             XX_LOG_EXCEPTION_PROC ('XX_OM_XDOCK_UNEXPECTED_ERROR'
	 		                    ,lc_error_msg
	 		                    ,lc_entity_ref
	 		                    ,ln_entity_ref_id
	                    );
  END IS_SALES_ORDER_ELIGIBLE;  
  
        /*****************************************************************************
         *  AUTHOR     : Sandeep Gorla					             *
         *  RICE ID    : E1279                            			     *
         *  PROCEDURE  : INSERT_INTREQ_INTF                                          *
         *  DESCRIPTION: Inserts record into Requisition Interface table.            *
         *                                                                           *
         *                                                                           *
         *****************************************************************************/
  
  PROCEDURE INSERT_INTREQ_INTF (x_retcode        OUT  VARCHAR2
                               ,x_errbuf         OUT  VARCHAR2
                               ,p_source         IN   Po_Requisitions_Interface_All.interface_source_code%TYPE
                               ,p_order_number   IN   Oe_Order_Headers_All.order_number%TYPE
                               ,p_line_id        IN   Oe_Order_lines_All.line_id%TYPE)
  IS
  
    --Read the profile value for Employee number  									  
    lc_employee_number Per_People_F.employee_number%TYPE := FND_PROFILE.VALUE('XX_OM_INTERNAL_REQUISITION_PREPARER');  
  
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
    lc_dest_subinv_code          VARCHAR2(50)  :=NULL;
    ln_charge_account_id         Mtl_Parameters.material_account%TYPE;
    ln_preparer_id               Per_People_F.person_id%TYPE;
    
    lc_req_type                  VARCHAR2(50)  :='INTERNAL';
    lc_dest_type_code            VARCHAR2(50)  :='INVENTORY';
    lc_authorization_status      VARCHAR2(50)  :='APPROVED';
    lc_source_type_code          VARCHAR2(50)  :='INVENTORY';
    lc_line_attribute_category   VARCHAR2(50)  :='Internal';
    ln_user_id                   NUMBER        := FND_GLOBAL.USER_ID;
    ln_org_id                    NUMBER        := TO_NUMBER(FND_PROFILE.value('ORG_ID'));
    lc_debug_msg                 VARCHAR2(500);
    lc_process_flag              VARCHAR2(1) :='Y';
  
  BEGIN
    
    ln_so_order_number  := p_order_number;
    ln_so_line_id       := p_line_id;
    lc_source           := p_source;
 
     --Get the sales order item and organization Information
     BEGIN
        SELECT 
	       OEl.ship_from_org_id
	      ,OEL.inventory_item_id
	      ,OEL.order_quantity_uom
	      ,OEL.request_date
	      ,OEL.ordered_quantity
        INTO 
	       ln_dest_org_id
	      ,ln_inv_item_id
	      ,lc_uom
	      ,ld_need_by_date
	      ,ln_ord_quantity
	FROM   oe_order_headers_all OEH
	      ,oe_order_lines_all   OEL
	WHERE  OEH.header_id=OEL.header_id
	AND    OEH.order_number=ln_so_order_number
	AND    OEL.line_id=ln_so_line_id;
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
          lc_process_flag :='N';
          lc_debug_msg :='Error while fetching sales order information-'||SUBSTR(SQLERRM,1,200);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);
          
          FND_MESSAGE.SET_NAME ('xxom','XX_OM_XDOCK_SO_FETCH_ERROR');
	  	 		                
	 	      lc_error_msg	 :=	 FND_MESSAGE.GET;
	  	      lc_entity_ref	 :=	'Line ID';
	  	      ln_entity_ref_id   :=	 ln_so_line_id;
	  	 		               
	              XX_LOG_EXCEPTION_PROC ('XX_OM_XDOCK_SO_FETCH_ERROR'
	  	 		             ,lc_error_msg
	  	 		             ,lc_entity_ref
	  	 		             ,ln_entity_ref_id
	                                    );
     WHEN TOO_MANY_ROWS THEN
          lc_process_flag :='N';
	  lc_debug_msg :='Error while fetching sales order information-'||SUBSTR(SQLERRM,1,200);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);
          
          FND_MESSAGE.SET_NAME ('xxom','XX_OM_XDOCK_SO_FETCH_ERROR');
	  	  	 		                
	  	      lc_error_msg	 :=	 FND_MESSAGE.GET;
	  	      lc_entity_ref	 :=	'Line ID';
	  	      ln_entity_ref_id   :=	 ln_so_line_id;
	  	  	 		               
	  	      XX_LOG_EXCEPTION_PROC ('XX_OM_XDOCK_SO_FETCH_ERROR'
	  	  	 		     ,lc_error_msg
	  	  	 		     ,lc_entity_ref
	  	  	 		     ,ln_entity_ref_id
	                                    );
     END;
     
     --Fetch the deliver to location id for the destination org id
     BEGIN
        SELECT location_id
        INTO   ln_delivery_loc_id
        FROM   hr_locations_all
        WHERE  inventory_organization_id=ln_dest_org_id
        AND    ship_to_site_flag='Y';
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
          lc_process_flag :='N';
          lc_debug_msg :='Error while fetching the destination Location Id-'||SUBSTR(SQLERRM,1,200);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);
          
          FND_MESSAGE.SET_NAME ('xxom','XX_OM_XDOCK_LOCID_ERROR');
	  	  	  	 		                
	  	      lc_error_msg	 :=	 FND_MESSAGE.GET;
	  	      lc_entity_ref	 :=	'Dest Loc Id';
	  	      ln_entity_ref_id   :=	 ln_dest_org_id;
	  	  	  	 		               
	  	      XX_LOG_EXCEPTION_PROC ('XX_OM_XDOCK_LOCID_ERROR'
	  	  	  	 	     ,lc_error_msg
	  	  	  	 	     ,lc_entity_ref
	  	  	  	             ,ln_entity_ref_id
	                                    );
          
     WHEN TOO_MANY_ROWS THEN
          lc_process_flag :='N';
          lc_debug_msg :='Error while fetching the destination Location Id-'||SUBSTR(SQLERRM,1,200);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);
          
          FND_MESSAGE.SET_NAME ('xxom','XX_OM_XDOCK_LOCID_ERROR');
	  	  	  	  	 		                
	  	      lc_error_msg	 :=	 FND_MESSAGE.GET;
		      lc_entity_ref	 :=	'Dest Loc Id';
		      ln_entity_ref_id   :=	 ln_dest_org_id;
	  	  	  	  	 		               
	  	      XX_LOG_EXCEPTION_PROC ('XX_OM_XDOCK_LOCID_ERROR'
	  	  	  	  	     ,lc_error_msg
	  	  	  	  	     ,lc_entity_ref
	  	  	  	  	     ,ln_entity_ref_id
	                                    );
          
          
     END;
     
     --Fetch the XDOCK Org Id(Source Organization)   
     BEGIN
        --SELECT XOLL.SEGMENT18               --Commented as part of V.1.3
	SELECT XOLL.xdock_inv_org_id          --Added as part of V.1.3
	INTO   ln_source_org_id
	FROM   oe_order_lines_all OEL
	      ,xx_om_line_attributes_all XOLL --Added as part of V.1.3
	      --,xx_om_lines_attributes_all XOLL   --Commented as part of V.1.3
	--WHERE  TO_CHAR(XOLL.combination_id)=OEL.attribute7  --Commented as part of V.1.3
	WHERE  OEL.line_id=XOLL.line_id       --Added as part of V.1.3
	AND    OEL.line_id=ln_so_line_id;
     EXCEPTION 
     WHEN NO_DATA_FOUND  THEN
          lc_process_flag := 'N';
          lc_debug_msg :='Error while fetching the Source Organization Id-'||SUBSTR(SQLERRM,1,200);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);
          
          FND_MESSAGE.SET_NAME ('xxom','XX_OM_XDOCK_SOURCE_ORG_ERROR');
	  	  	  	  	  	 		                
	  	      lc_error_msg	 :=	 FND_MESSAGE.GET;
	  	      lc_entity_ref	 :=	'Source Org Id';
	  	      ln_entity_ref_id   :=	 ln_dest_org_id;
	  	  	  	  	  	 		               
	  	      XX_LOG_EXCEPTION_PROC ('XX_OM_XDOCK_SOURCE_ORG_ERROR'
	  	  	  	  	     ,lc_error_msg
	  	  	  	  	     ,lc_entity_ref
	  	  	  	  	     ,ln_entity_ref_id
	                                    );
          
     WHEN TOO_MANY_ROWS THEN
	  lc_process_flag := 'N';
	  lc_debug_msg :='Error while fetching the Source Organization Id-'||SUBSTR(SQLERRM,1,200);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);
          
          FND_MESSAGE.SET_NAME ('xxom','XX_OM_XDOCK_SOURCE_ORG_ERROR');
	  	  	  	  	  	  	 		                
	  	      lc_error_msg	 :=	 FND_MESSAGE.GET;
	  	      lc_entity_ref	 :=	'Source Org Id';
	  	      ln_entity_ref_id   :=	 ln_dest_org_id;
	  	  	  	  	  	  	 		               
	  	      XX_LOG_EXCEPTION_PROC ('XX_OM_XDOCK_SOURCE_ORG_ERROR'
	  	  	  	  	     ,lc_error_msg
	  	  	  	  	     ,lc_entity_ref
	  	  	  	  	     ,ln_entity_ref_id
	                                    );
     END;
     
     --Fetch the charge account for the destination organization
     BEGIN
        SELECT material_account
        INTO   ln_charge_account_id
        FROM   mtl_parameters
        WHERE  organization_id = ln_dest_org_id;
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
          lc_process_flag :='N';
          lc_debug_msg :='Error while fetching the Charge Account Id-'||SUBSTR(SQLERRM,1,200);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);
          
          FND_MESSAGE.SET_NAME ('xxom','XX_OM_XDOCK_CHARGE_ACT_ERROR');
	  	  	  	  	  	  	  	 		                
	  	      lc_error_msg	 :=	 FND_MESSAGE.GET;
	  	      lc_entity_ref	 :=	'Dest Org Id';
	  	      ln_entity_ref_id   :=	 ln_dest_org_id;
	  	  	  	  	  	  	  	 		               
	  	      XX_LOG_EXCEPTION_PROC ('XX_OM_XDOCK_CHARGE_ACT_ERROR'
	  	  	  	  	     ,lc_error_msg
	  	  	  	  	     ,lc_entity_ref
	  	  	  	  	     ,ln_entity_ref_id
	                                    );
          
          
     WHEN TOO_MANY_ROWS THEN
          lc_process_flag :='N';
	  lc_debug_msg :='Error while fetching the Charge Account Id-'||SUBSTR(SQLERRM,1,200);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);
          
          FND_MESSAGE.SET_NAME ('xxom','XX_OM_XDOCK_CHARGE_ACT_ERROR');
	  	  	  	  	  	  	  	  	 		                
	  	      lc_error_msg	 :=	 FND_MESSAGE.GET;
	  	      lc_entity_ref	 :=	'Dest Org Id';
	  	      ln_entity_ref_id   :=	 ln_dest_org_id;
	  	  	  	  	  	  	  	  	 		               
	  	      XX_LOG_EXCEPTION_PROC ('XX_OM_XDOCK_CHARGE_ACT_ERROR'
	  	  	  	  	     ,lc_error_msg
	  	  	  	  	     ,lc_entity_ref
	  	  	  	  	     ,ln_entity_ref_id
	                                    );
     END;
     
     --Fetch the person id of the generic employee who is set as a profile      
   
     BEGIN
        SELECT person_id
        INTO   ln_preparer_id
        FROM   per_people_f 
        WHERE  employee_number =lc_employee_number;
     EXCEPTION 
     WHEN NO_DATA_FOUND THEN
        lc_process_flag :='N';
        lc_debug_msg :='Error while fetching the Requestor Id-'||SUBSTR(SQLERRM,1,200);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);
        
        FND_MESSAGE.SET_NAME ('xxom','XX_OM_XDOCK_PREPARER_ERROR');
		  	  	  	  	  	  	  	  	 		                
		    lc_error_msg	 :=	 FND_MESSAGE.GET;
		    lc_entity_ref	 :=	'Employee Number';
		    ln_entity_ref_id     :=	 lc_employee_number;
		  	  	  	  	  	  	  	  	 		               
		    XX_LOG_EXCEPTION_PROC ('XX_OM_XDOCK_PREPARER_ERROR'
		  	  	  	   ,lc_error_msg
		  	  	  	   ,lc_entity_ref
		  	  	  	   ,ln_entity_ref_id
	                                  );
        
     WHEN TOO_MANY_ROWS THEN
        lc_process_flag :='N';
	lc_debug_msg :='Error while fetching the Requestor Id-'||SUBSTR(SQLERRM,1,200);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);
        
        FND_MESSAGE.SET_NAME ('xxom','XX_OM_XDOCK_PREPARER_ERROR');
			  	  	  	  	  	  	  	  	 		                
	            lc_error_msg	 :=	 FND_MESSAGE.GET;
	            lc_entity_ref	 :=	'Employee Number';
		    ln_entity_ref_id     :=	 lc_employee_number;
			  	  	  	  	  	  	  	  	 		               
		    XX_LOG_EXCEPTION_PROC ('XX_OM_XDOCK_PREPARER_ERROR'
			  	  	   ,lc_error_msg
			  	  	   ,lc_entity_ref
			  	  	   ,ln_entity_ref_id
	                                  );
     END;
     
    BEGIN
      IF lc_process_flag ='Y' THEN    	    
     	           
       	INSERT INTO PO_REQUISITIONS_INTERFACE_ALL                                                                                                                                                                                                                                                                                                                                                               
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
	lc_debug_msg :='Successfully Interfaced this sales order/line';
        FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);
        ELSE
        lc_debug_msg :='Could not insert into Interface table as one of the data is missing.See the error Message above';
        FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);
        END IF;
        
     END;
   
  EXCEPTION
  WHEN OTHERS THEN
           lc_debug_msg :='Encountered Unexpected Error While Processing-'||SUBSTR(SQLERRM,1,200);
           FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);  
           
           FND_MESSAGE.SET_NAME ('xxom','XX_OM_XDOCK_UNEXPECTED_ERROR');
	   	 		                
	   	       lc_error_msg	:=	 FND_MESSAGE.GET;
	   	       lc_entity_ref	:=	'Line ID';
	   	       ln_entity_ref_id :=	 ln_so_line_id;
	   	 		               
	   	       XX_LOG_EXCEPTION_PROC ('XX_OM_XDOCK_UNEXPECTED_ERROR'
	   	 		              ,lc_error_msg
	   	 		              ,lc_entity_ref
	   	 		              ,ln_entity_ref_id
	                    		     );
  
  END INSERT_INTREQ_INTF;      
        
END XX_OM_INTREQ_PKG;
/
show errors
 
