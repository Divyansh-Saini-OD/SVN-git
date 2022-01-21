REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb checkfile(120.3.12010100.3=120.5)(115.7=120.0):~PROD:~PATH:~FILE
/*===========================================================================+
 |               Copyright (c) 1995, 2014 Oracle Corporation                       |
 |                  Redwood Shores, California, USA                          |
 |                       All rights reserved.                                |
 +===========================================================================*/

SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
DEFINE PACKAGE_NAME="PO_REQ_LINES_SV1"
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
CREATE or REPLACE PACKAGE BODY PO_REQ_LINES_SV1 as
/* $Header: POXRQL2B.pls 120.7.12020000.3 2014/07/23 06:49:33 rkandima ship $ */
/*==========================  po_req_lines_sv1  ============================*/

/*===========================================================================

  PROCEDURE NAME:	get_vendor_sourcing_info

===========================================================================*/
PROCEDURE get_vendor_sourcing_info( x_vendor_id		 IN  	NUMBER,
				    x_vendor_site_id  	 IN  	NUMBER,
				    x_vendor_contact_id	 IN  	NUMBER,
				    x_po_header_id	 IN  	NUMBER,
				    x_document_type_code IN  	VARCHAR2,
		        	    x_buyer_id		 IN  	NUMBER,
				    x_vendor_name	 IN OUT	NOCOPY VARCHAR2,
				    x_vendor_location	 IN OUT	NOCOPY VARCHAR2,
				    x_vendor_contact	 IN OUT	NOCOPY VARCHAR2,
				    x_vendor_phone	 IN OUT NOCOPY VARCHAR2,
				    x_po_num		 IN OUT	NOCOPY VARCHAR2,
				    x_doc_type_disp	 IN OUT	NOCOPY VARCHAR2,
				    x_buyer		 IN OUT NOCOPY VARCHAR2) IS

x_progress VARCHAR2(3) := NULL;

BEGIN

   x_progress := '010';

   po_vendors_sv.get_vendor_details (x_vendor_id,
				     x_vendor_site_id,
				     x_vendor_contact_id,
				     x_vendor_name,
				     x_vendor_location,
				     x_vendor_contact,
				     x_vendor_phone);

   x_progress :='020';

   po_headers_sv3.get_doc_num (x_po_num,
			       x_po_header_id);

   x_progress := '030';

   po_core_s.get_displayed_value ('SOURCE DOCUMENT TYPE',
				   x_document_type_code,
				   x_doc_type_disp);

   x_progress := '040';

   IF (x_buyer_id is not null) THEN

      /* Bug - 1921406 - Changed the sql to use po_buyers_val_v
      instead of po_buyers_all_v, because po_buyers_all_v has no
      effectivity dates and hence returns multiple rows.  */

      /* Bug 2779096 : added exception handler to the following
       select so that if the buyer id is not valid and does not
       exist in po_buyers_val_v we we assign null */
     
      begin
        SELECT full_name
        INTO   x_buyer
        FROM   po_buyers_val_v
        WHERE  employee_id = x_buyer_id;
      exception
       when others then
          x_buyer := null;
      end;

  
   END IF;

   EXCEPTION
   WHEN OTHERS THEN
      po_message_s.sql_error('get_vendor_sourcing_info', x_progress, sqlcode);
      raise;

END get_vendor_sourcing_info;



/*===========================================================================

  PROCEDURE NAME:	val_src_details()

===========================================================================*/
PROCEDURE val_src_details  (x_src_org_id		IN OUT NOCOPY NUMBER,
			    x_src_org			IN OUT NOCOPY VARCHAR2,
			    x_src_org_code		IN OUT NOCOPY VARCHAR2,
			    x_item_id			IN NUMBER,
			    x_item_rev			IN VARCHAR2,
			    x_inv_org_id		IN NUMBER,
			    x_outside_op_line_type	IN VARCHAR2,
			    x_mrp_planned_item		IN VARCHAR2,
			    x_src_sub			IN OUT NOCOPY VARCHAR2,
			    x_src_type			IN OUT NOCOPY VARCHAR2,
			    x_dest_type			IN VARCHAR2,
			    x_dest_org_id		IN VARCHAR2,
			    x_dest_sub			IN VARCHAR2,
			    x_deliver_to_loc_id		IN NUMBER,
			    x_val_code			IN VARCHAR2,
			    x_sob_id			IN OUT NOCOPY NUMBER) IS

x_progress VARCHAR2(3) := NULL;

x_stock_enabled_flag	mtl_system_items.stock_enabled_flag%type;
x_internal_orderable	mtl_system_items.internal_order_enabled_flag%type;
x_purchasing_enabled_flag mtl_system_items.purchasing_enabled_flag%type;
x_outside_operation_flag  mtl_system_items.outside_operation_flag%type;
x_inventory_asset_flag  mtl_system_items.inventory_asset_flag%type;

X_inventory_org_id	  NUMBER;
X_planned_item_flag	  VARCHAR2(1);
X_outside_op_uom_type     mtl_system_items.outside_operation_uom_type%type;
X_invoice_close_tolerance mtl_system_items.invoice_close_tolerance%type;
X_receive_close_tolerance mtl_system_items.receive_close_tolerance%type;
X_receipt_required_flag   VARCHAR2(1);

x_customer_id	po_location_associations.customer_id%type;
x_address_id    po_location_associations.address_id%type;
x_site_use_id   po_location_associations.site_use_id%type;

x_error_type   VARCHAR2(50);

--<INVCONV R12 START>
x_secondary_default_ind            mtl_system_items.secondary_default_ind%TYPE:= NULL;                 
x_grade_control_flag               mtl_system_items.grade_control_flag%TYPE:= NULL;
x_secondary_unit_of_measure        mtl_units_of_measure.unit_of_measure%TYPE:= NULL;
x_secondary_unit_of_measure_tl	   mtl_units_of_measure.unit_of_measure_tl%TYPE:= NULL;
--<INVCONV R12 END>


BEGIN

   x_progress := '010';


   /* Obtain the source org and source org code
   ** since this saves us a network round trip from 
   ** client to fetch the code and org.
   */

   po_orgs_sv.get_org_info (x_src_org_id,
			    x_sob_id,
			    x_src_org_code,
			    x_src_org);

   /*
   ** Stop processing if the source  type
   ** is null.
   */
   /* Ben: 2/6/97 This procedure was checking the item attributes in the 
           DESTINATION ORG, when it should have been in the SOURCE ORG.
           Changing it: If no source org has been entered by the user then
           do nothing.
   */

   IF (x_src_type is null) OR (x_src_org_id is null) THEN
    x_src_org_id   := null;
    x_src_org	   := null;
    x_src_org_code := null;
    x_src_sub      := null;

    return;

   END IF;


   /* Determine which set of fields are to
   ** to be validated, call the corresponding
   ** validation functions.
   */

   IF (x_val_code = 'ALL') THEN

     x_progress := '020';

     /* Ben: 2/7/97. We should be getting the attributes for the item in the 
             source org.

         IF (x_dest_org_id is null) THEN
           x_inventory_org_id := x_inv_org_id;

         ELSE
           x_inventory_org_id := x_dest_org_id;

         END IF;
      */

      x_inventory_org_id := x_src_org_id ;

      x_progress := '030';

    --<INVCONV R12 START> since package signature has changed modified this to pass 3 new parameters

     po_items_sv2.get_item_details (X_item_id,
                             X_inventory_org_id,
                             X_planned_item_flag,
                             X_outside_operation_flag,
                             X_outside_op_uom_type,
                             X_invoice_close_tolerance,
                             X_receive_close_tolerance,
                             X_receipt_required_flag,
                             X_stock_enabled_flag,
			     X_internal_orderable,
			     X_purchasing_enabled_flag,
			     X_inventory_asset_flag,
			     --<INVCONV R12 START>
                             X_secondary_default_ind,
                             X_grade_control_flag,
                             X_secondary_unit_of_measure ) ;
                             --<INVCONV R12 END>


     /* Obtain the customer information 
     ** for the deliver to location.
     */

        x_progress := '040';

	po_customers_sv.get_cust_details(x_deliver_to_loc_id,
					 x_customer_id,
					 x_address_id,
					 x_site_use_id,
                                         x_src_org_id); -- Bug 5028505

        x_progress := '050';

     IF (po_req_lines_sv.val_src_type (x_src_type,
				       x_item_id,
				       x_internal_orderable,
				       x_stock_enabled_flag,
				       x_purchasing_enabled_flag,
				       x_customer_id,
				       x_outside_op_line_type,
                                       x_deliver_to_loc_id) = FALSE) THEN

	IF (x_src_type = 'INVENTORY') THEN
	  
	  x_src_org_id   := null;
	  x_src_org      := null;	
	  x_src_org_code := null;
	  x_src_sub      := null;
	  x_src_type     := null;

	  return;

        ELSIF (x_src_type = 'VENDOR') THEN

	/* 
	** copy null into the vendor related
	** fields. Since no validation is 
        ** being performed for vendor related
	** fields, copying null into the
        ** source type field should be sufficient.
	*/

	  x_src_type := null;

	END IF;
    END IF;
 
  END IF;


  IF (x_src_type = 'INVENTORY') THEN
    IF ((x_val_code = 'ALL') OR 
	(x_val_code = 'ORG')) THEN
     
       x_progress := '060';

       IF (po_orgs_sv2.val_source_org (x_src_org_id,
				      x_dest_org_id, 
				      x_dest_type,
				      x_item_id,
				      x_item_rev,
				      x_sob_id,
				      x_error_type) = FALSE) THEN


	 x_src_org_id   := null;
	 x_src_org      := null;
	 x_src_org_code := null;
	 x_src_sub      := null;

         
	/*
   	** DEBUG: Need to find a way of displaying
  	** this message. Setting the message name
	** and using fnd_message.warn may be  a 
 	** possible solution.
	*/        

         IF (x_error_type = 'SRC_DEST_ORG_CONTROL_MISMATCH') THEN
            fnd_message.set_name ('PO',
				  'PO_RQ_INV_LOOSER_TIGHTER');

         -- begin bug 3279513
         ELSE --that is,  x_error_type = 'INVALID_ORG'
            fnd_message.set_name ('PO',
                  'PO_RI_INVALID_SOURCE_ORG_ID');
         -- end bug 3279513
         END IF;

	 return;

      ELSE 

         -- Bug 5028505 , Added validation for location when validating the 
         -- Source Organization. We are now Validating that the deliver_to_location 
         -- has customer location association in the Source Organizations 
         -- Operating Unit 

         IF (x_deliver_to_loc_id is not null AND 
               x_src_org_id is NOT NULL) THEN
              IF (po_locations_sv2.val_location (x_deliver_to_loc_id,
                                          x_dest_org_id,
                                          'N',
                                          'N',
                                          'Y',
                                           x_src_org_id) = FALSE) THEN

	             x_src_org_id   := null;
	             x_src_org      := null;
	             x_src_org_code := null;
                     fnd_message.set_name ('PO','PO_REQ_SRC_REQUIRES_CUST');
                     return;

              END IF;
          END IF;

       END IF;
    END IF;

   IF ((x_val_code = 'ALL') OR
       (x_val_code = 'ORG') OR
       (x_val_code = 'SUB')) THEN 

   /*Bug4256488: call the val_subinventory procedure to perform validations on
     the source subinventory only when source subinventory is not null*/
    IF (x_src_sub is not null) THEN

    x_progress := '070';    
 
    IF (po_subinventories_s2.val_subinventory (x_dest_sub,
					       x_dest_org_id,
					       x_src_type,
					       x_src_sub,
					       x_src_org_id,
					       trunc(sysdate),
					       x_item_id,
					       x_dest_type,
					       'SOURCE',
					       x_error_type) = FALSE) THEN
       x_src_sub := null;

       IF (x_error_type = 'DEST_SUB_EQS_SRC_SUB') THEN
         fnd_message.set_name ('PO',
			       'PO_RQ_SOURCE_SUB_EQS_DEST_SUB');

       ELSIF (x_error_type = 'INVALID_SUB') THEN
         fnd_message.set_name ('PO',
			       'PO_RI_INVALID_SRC_SUBINV');

       ELSIF (x_error_type = 'INVALID_EXP_ASSET_SUBS') THEN
         fnd_message.set_name ('PO', 
			       'PO_RQ_INV_EXP_SUB_NA');

       /* Ben: 2/7/97 added the following error message when Order entry 
               reservation is on, but sub is not reservable.
       */
       ELSIF (x_error_type = 'PO_RI_SRC_SUB_NOT_RESERVABLE') THEN

         fnd_message.set_name ('PO','PO_RI_SRC_SUB_NOT_RESERVABLE');

       END IF;

       return;

    END IF;
    END IF;  --Bug4256488
   END IF;

 ELSIF (x_src_type = 'VENDOR') THEN
    IF (x_val_code = 'ALL') THEN
  
    /* Any validation for vendor fields should be here */

    null;

    END IF;
 END IF;
  
   EXCEPTION
   WHEN OTHERS THEN
      po_message_s.sql_error('val_src_details', x_progress, sqlcode);
      raise;

END val_src_details;



/*===========================================================================

  FUNCTION NAME:	get_max_line_num

===========================================================================*/

 FUNCTION get_max_line_num 
	(X_header_id   NUMBER) return number is

 x_max_line_num NUMBER;

 BEGIN

	SELECT nvl(max(line_num), 0)
	INTO   x_max_line_num
	FROM   po_requisition_lines
	WHERE  requisition_header_id = x_header_id;

   return(x_max_line_num);

   EXCEPTION
   WHEN OTHERS THEN
      return(0);
   RAISE;

 END get_max_line_num;                      


/*===========================================================================

  PROCEDURE NAME:	update_modified_by_agent_flag

===========================================================================*/

PROCEDURE update_modified_by_agent_flag(x_req_line_id    IN  NUMBER,
					x_agent_id	 IN  NUMBER)
IS

x_progress  VARCHAR2(3) := NULL;
BEGIN

   x_progress := '010';

   -- <REQINPOOL>: added update of reqs_in_pool_flag and of
   -- WHO columns.
   UPDATE po_requisition_lines
   SET    modified_by_agent_flag = 'Y',
          reqs_in_pool_flag      = NULL,
 	  purchasing_agent_id    = x_agent_id,
	  last_update_date       = SYSDATE,
          last_updated_by        = FND_GLOBAL.USER_ID,
          last_update_login      = FND_GLOBAL.LOGIN_ID
   WHERE  requisition_line_id    = x_req_line_id;


   EXCEPTION
   WHEN OTHERS THEN
      --dbms_output.put_line('In exception');
      po_message_s.sql_error('update_modified_by_agent_flag', 
			      x_progress, sqlcode);
      raise;
END update_modified_by_agent_flag;


/*===========================================================================

  PROCEDURE NAME:	get_cost_price

===========================================================================*/

PROCEDURE get_cost_price (x_item_id		 IN  	NUMBER,
			  x_organization_id  	 IN  	NUMBER,
			  x_unit_of_measure	 IN  	VARCHAR2,
			  x_cost_price		 IN OUT	NOCOPY NUMBER)

IS
x_progress  	VARCHAR2(3) := NULL;
x_primary_cost  NUMBER	    := NULL;
x_primary_uom   VARCHAR2(25) := NULL;

BEGIN

   /*
   ** Make sure that the input parameters
   ** are being passed in.
   */

   IF ((x_item_id is null) OR
       (x_organization_id is null) OR
       (x_unit_of_measure is null)) THEN
      return;

   END IF;

   x_progress := '010';

   /*
   ** Obtain the cost price for the specified
   ** item and organization. This price is
   ** in the primary unit of measure.
   */

   po_items_sv2.get_item_cost (x_item_id,
			       x_organization_id,	
			       x_primary_cost);

 
   /*
   ** If the primary cost is zero there is
   ** no need to continue with the conversion.
   */

   IF (x_primary_cost = 0) THEN

     x_cost_price := x_primary_cost;
     return;

   END IF;

   /* 
   ** Obtain the primary unit of measure
   ** for the item.
   */

   x_progress := '020';

     SELECT primary_unit_of_measure 
     INTO   x_primary_uom
     FROM   mtl_system_items
     WHERE  inventory_item_id = x_item_id
     AND    organization_id   = x_organization_id;

   /*
   ** If the primary unit of measure is
   ** the same as the unit of measure 
   ** passed to this procedure then the cost
   ** does not have to be converted.
   */

   IF (x_primary_uom = x_unit_of_measure) THEN

     x_cost_price := x_primary_cost;
     return;

   END IF;

    IF (po_uom_sv2.convert_inv_cost(X_item_id,
				    X_unit_of_measure,
				    X_primary_uom,
				    X_primary_cost,
				    X_cost_price) = TRUE) then

      return;

    ELSE
     
     x_cost_price := 0;

    END IF; 


   EXCEPTION
   WHEN OTHERS THEN
      --dbms_output.put_line('In exception');
      po_message_s.sql_error('get_cost_price', 
			      x_progress, sqlcode);
      raise;
END get_cost_price;

/*===========================================================================

  PROCEDURE NAME:	update_transfer_price

===========================================================================*/

PROCEDURE update_transfer_price (p_request_id	IN  	NUMBER)
IS

     x_transaction_id            NUMBER;
     x_inventory_item_id         NUMBER;
     x_transaction_qty           NUMBER;
     x_transaction_uom           VARCHAR2(40);
     x_from_organization_id      NUMBER;
     x_from_ou                   NUMBER  ;
     x_to_organization_id        NUMBER;
     x_to_ou                     NUMBER  ;
     x_msg_data                  VARCHAR2(3000);
     x_msg_count                 NUMBER;
     x_unit_price    NUMBER := 0;
     x_unit_price_priuom         NUMBER := 0;
     x_incr_transfer_price       NUMBER;
     x_incr_currency_code        VARCHAR2(4);
     x_currency_code             VARCHAR2(4);
     x_return_status             VARCHAR2(1);
     x_progress             VARCHAR2(4);
     x_user_unit_price 		NUMBER;
     x_source_type_code		VARCHAR2(25);
     x_rate_date DATE; --Bug # 12914933

-- bug 18188230 start

l_src_process_enabled_flag  VARCHAR(1):=NULL;
l_dest_process_enabled_flag VARCHAR(1):=NULL;

l_from_ou                   NUMBER;
l_to_ou                     NUMBER;

l_dest_currency             VARCHAR2(50);      
l_set_of_books_id           NUMBER;       
l_def_rate_type             VARCHAR2(50);

x_cost_method               VARCHAR2(10);
x_cost_component_class_id   NUMBER;
x_cost_analysis_code        VARCHAR2(10);

x_no_of_rows                NUMBER;
l_ret_val                   NUMBER;

x_trans_qty                 NUMBER; 

l_return_status VARCHAR2(10);
l_uom_code                  mtl_material_transactions.transaction_uom%TYPE;

-- bug 18188230 End

  CURSOR interface_line_cursor is
  SELECT transaction_id, item_id, quantity, uom_code, source_organization_id, destination_organization_id, source_type_code, unit_price,
  trunc(nvl(nvl(pri.rate_date,pri.gl_date),pri.creation_date)) rate_date
  FROM po_requisitions_interface pri
  WHERE request_id = p_request_id;

BEGIN

   	x_progress := '010';

	 OPEN interface_line_cursor;
	 loop
	
	FETCH interface_line_cursor INTO x_transaction_id, x_inventory_item_id, x_transaction_qty, x_transaction_uom, x_from_organization_id, x_to_organization_id, x_source_type_code, x_user_unit_price,x_rate_date;
	EXIT WHEN interface_line_cursor%NOTFOUND;
	
	/*
	   ** getting values for the parameters for
	   ** API GMF_get_transfer_price_PUB.get_transfer_price
	   */


	x_progress := '020';

/*    Removing this part for Bug 10209640 */
--Bug 13392437 Uncommented the if condition as we should not override the price if the price column has value 
		
	if ((x_inventory_item_id is not null) and (x_user_unit_price is null) and (x_source_type_code = 'INVENTORY')) then
	/*
	SELECT to_number(src.org_information3) src_ou, to_number(dest.org_information3) dest_ou
	INTO x_from_ou, x_to_ou
	FROM hr_organization_information src, hr_organization_information dest
	WHERE src.organization_id = x_from_organization_id
	AND src.org_information_context = 'Accounting Information'
	AND dest.organization_id = x_to_organization_id
	AND dest.org_information_context = 'Accounting Information';	
*/
	x_progress := '030';
	--Calling the API to get the transfer price
	
     
     /* Removing this part for Bug 10209640
     
       GMF_get_transfer_price_PUB.get_transfer_price (
            p_api_version             => 1.0
          , p_init_msg_list           => 'F'

          , p_inventory_item_id       => x_inventory_item_id
          , p_transaction_qty         => x_transaction_qty
          , p_transaction_uom         => x_transaction_uom
 
          , p_transaction_id          => NULL
          , p_global_procurement_flag => 'N'
          , p_drop_ship_flag          => 'N'
 
          , p_from_organization_id    => x_from_organization_id
          , p_from_ou                 => x_from_ou
          , p_to_organization_id      => x_to_organization_id
          , p_to_ou                   => x_to_ou

          , p_transfer_type           => 'INTORG'
          , p_transfer_source         => 'INTREQ'

          , x_return_status           => x_return_status
          , x_msg_data                => x_msg_data
          , x_msg_count               => x_msg_count

          , x_transfer_price          => x_unit_price
          , x_transfer_price_priuom   => x_unit_price_priuom
          , x_currency_code           => x_currency_code
          , x_incr_transfer_price     => x_incr_transfer_price  -- not used 
          , x_incr_currency_code      => x_incr_currency_code   -- not used
	  
	  );

	*/

	-- x_unit_price := por_util_pkg.get_item_cost(x_inventory_item_id, x_from_organization_id, x_transaction_uom, x_to_organization_id,x_rate_date);

-- bug 18188230 start

IF x_to_organization_id is not NULL then



    SELECT NVL(src.process_enabled_flag,'N'), NVL(dest.process_enabled_flag,'N')
    INTO l_src_process_enabled_flag, l_dest_process_enabled_flag
    FROM mtl_parameters src, mtl_parameters dest
    WHERE src.organization_id  = x_from_organization_id
    AND dest.organization_id = x_to_organization_id;
    END IF;


  IF (l_src_process_enabled_flag <> l_dest_process_enabled_flag)
  OR (l_src_process_enabled_flag = 'Y' AND l_dest_process_enabled_flag = 'Y')
  THEN
    -- for process-discrete and vice-versa orders. Call get transfer price API
    -- for process-process orders. Call get cost API

    -- get the from ou and to ou
    -- B7462235 - Changed org_information2 to org_information3 to fetch OU Id
    SELECT to_number(src.org_information3) src_ou, to_number(dest.org_information3) dest_ou
      INTO l_from_ou, l_to_ou
      FROM hr_organization_information src, hr_organization_information dest
     WHERE src.organization_id = x_from_organization_id
       AND src.org_information_context = 'Accounting Information'
       AND dest.organization_id = x_to_organization_id
       AND dest.org_information_context = 'Accounting Information';




    IF (l_src_process_enabled_flag = 'Y' AND l_dest_process_enabled_flag = 'Y') AND
       (l_from_ou = l_to_ou)
    THEN
    -- process/process within same OU

      l_ret_val := GMF_CMCOMMON.Get_Process_Item_Cost (
                       p_api_version              => 1.0
                     , p_init_msg_list            => 'T'
                     , x_return_status            => l_return_status
                     , x_msg_count                => x_msg_count
                     , x_msg_data                 => x_msg_data
                     , p_inventory_item_id        => x_inventory_item_id
                     , p_organization_id          => x_from_organization_id
                     , p_transaction_date         => sysdate
                     , p_detail_flag              => 1          -- returns unit_price
                     , p_cost_method              => x_cost_method
                     , p_cost_component_class_id  => x_cost_component_class_id
                     , p_cost_analysis_code       => x_cost_analysis_code
                     , x_total_cost               => x_unit_price
                     , x_no_of_rows               => x_no_of_rows
                   );

       IF l_ret_val <> 1
       THEN
         x_unit_price := 0;
       END IF;



    ELSE
       -- process to discrete or descrete to process or process to process across OUs
       -- then invoke transfer price API
       -- pmarada bug 4687787

       SELECT uom_code
         INTO l_uom_code
         FROM mtl_units_of_measure
        WHERE unit_of_measure = x_transaction_uom ;



       GMF_get_transfer_price_PUB.get_transfer_price (
            p_api_version             => 1.0
          , p_init_msg_list           => 'F'

          , p_inventory_item_id       => x_inventory_item_id
          , p_transaction_qty         => x_trans_qty
          , p_transaction_uom         => l_uom_code

          , p_transaction_id          => NULL
          , p_global_procurement_flag => 'N'
          , p_drop_ship_flag          => 'N'

          , p_from_organization_id    => x_from_organization_id
          , p_from_ou                 => l_from_ou
          , p_to_organization_id      => x_to_organization_id
          , p_to_ou                   => l_to_ou

          , p_transfer_type           => 'INTORD'
          , p_transfer_source         => 'INTREQ'

          , x_return_status           => l_return_status
          , x_msg_data                => x_msg_data
          , x_msg_count               => x_msg_count

          , x_transfer_price          => x_unit_price
          , x_transfer_price_priuom   => x_unit_price_priuom
          , x_currency_code           => x_currency_code
          , x_incr_transfer_price     => x_incr_transfer_price  /* not used */
          , x_incr_currency_code      => x_incr_currency_code  /* not used */
          );

        IF l_return_status <> 'S' OR
          x_unit_price IS NULL
        THEN
          x_unit_price    := 0;
        ELSE  
           --Added the following code for bug 12914933 to convert the price 
          --if dest and source currency are different 	 
		        BEGIN
				        select gsob.currency_code
				        ,ood.set_of_books_id,
				        psp.DEFAULT_RATE_TYPE
				        into l_dest_currency
				        ,l_set_of_books_id,
				        l_def_rate_type
								from gl_sets_of_books gsob,
								org_organization_definitions ood,						
								po_system_parameters psp
								where ood.set_of_books_id = gsob.set_of_books_id
								and ood.organization_id = x_to_organization_id;
								
						EXCEPTION
							WHEN OTHERS THEN
							   --l_dest_currency := NULL;
							   null;
					  END;
			   
			      IF l_dest_currency <>  x_currency_code THEN
			  	 
			  	  x_unit_price :=  x_unit_price * gl_currency_api.get_closest_rate_sql( l_set_of_books_id , 
                                                            x_currency_code,nvl(x_rate_date,trunc(sysdate)),l_def_rate_type,30);
        END IF;
        END IF;

    END IF;
    --<INVCONV R12 END OPM INVCONV  umoogala>
  ELSE

    po_req_lines_sv1.get_cost_price (  x_inventory_item_id,
             x_from_organization_id,
             x_transaction_uom,
             x_unit_price);
    

       IF x_unit_price IS NULL
            THEN
              x_unit_price    := 0;
            ELSE  
              --if dest and source currency are different 	 
    		        BEGIN
    				        select gsob.currency_code
    				        ,ood.set_of_books_id,
    				        psp.DEFAULT_RATE_TYPE
    				        into l_dest_currency
    				        ,l_set_of_books_id,
    				        l_def_rate_type
    								from gl_sets_of_books gsob,
    								org_organization_definitions ood,						
    								po_system_parameters psp
    								where ood.set_of_books_id = gsob.set_of_books_id
    								and ood.organization_id = x_to_organization_id;
    								
    						EXCEPTION
    							WHEN OTHERS THEN
    							   --l_dest_currency := NULL;
    							   null;
    					  END;
                            BEGIN
    				        select gsob.currency_code
    				        into x_currency_code
    								from gl_sets_of_books gsob,
    								org_organization_definitions ood						
    								where ood.set_of_books_id = gsob.set_of_books_id
    								and ood.organization_id = x_from_organization_id;
    								
    						EXCEPTION
    							WHEN OTHERS THEN
    							   x_currency_code := NULL;
    					  END;
    			   
    			      IF l_dest_currency <>  x_currency_code THEN
    			  	 
    			  	  x_unit_price :=  x_unit_price * gl_currency_api.get_closest_rate_sql( l_set_of_books_id , 
                                                                x_currency_code,nvl(x_rate_date,trunc(sysdate)),l_def_rate_type,30);
            END IF;
            END IF;
             
  END IF;
  
  -- bug 18188230 End

	x_progress := '040';

  x_unit_price := round(x_unit_price,10);
        
        
		UPDATE po_requisitions_interface pri
			 SET pri.unit_price = x_unit_price , pri.base_unit_price = x_unit_price
		WHERE transaction_id = x_transaction_id;
        
        
        end if; 

	END LOOP;
	x_progress := '050';


   EXCEPTION
   WHEN OTHERS THEN
      po_message_s.sql_error('get_cost_price',
			      x_progress, sqlcode);
      raise;
END update_transfer_price;


END po_req_lines_sv1;


/
commit;
--show errors;
exit;






