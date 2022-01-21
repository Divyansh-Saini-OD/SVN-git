SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
 
 CREATE OR REPLACE PACKAGE BODY XX_OM_POCANCEL_B2B_PKG
 -- +================================================================+
 -- |                  Office Depot - Project Simplify               |
 -- |                              WIPRO                             |
 -- +================================================================+
 -- | Name       :    XX_OM_POCANCEL_B2B_PKG                         |
 -- | RICE ID    :    E0275	PO cancel B2B                        |
 -- | Description: Custom package body which cancels the PO line     |
 -- |              when the sales order line IDs are passed          |
 -- |                                                                |
 -- |                                                                |
 -- |                                                                |
 -- |Change Record:                                                  |
 -- |===============                                                 |
 -- |Version   Date          Author              Remarks             |
 -- |=======   ==========  =============    =========================|
 -- |Draft 1A  27-MAR-2007   Niharika          Initial draft Version |
 -- |1.0       22-May-2007   Srividhya         Changed the supply    |
 -- |                                          source type ID to 17  |
 -- |                                          (external requisition)|
 -- |1.1       30-May-2007   Srividhya         Incorporated the      |
 -- |                                          review comments given |
 -- |                                          by Dedra Maloy        |
 -- +================================================================+
 AS 
    -- + ==============================================================+
    -- | Name        : PO_VAL_CANCEL_PROC                              |
    -- | Description : Procedure PO_VAL_CANCEL_PROC will perform the   |
    -- |               following:                                      |
    -- |               1. Gets the sales order IDs as parameters       |
    -- |                  through table type.                          |
    -- |               2. Fetches the po_header_id and distribution ID |
    -- |               3. Fetches the po_line_id, doc_subtype for all  |
    -- |                  approved and open purchase orders            |
    -- |               4. Call the PO cancel API for cancelling the PO |
    -- |                  lines                                        |
    -- | Parameters  : p_user_id                                       |
    -- |               p_responsibility_id                             |
    -- |               pt_sale_order_line_id                           |
    -- |                                                               |
    -- |                                                               |
    -- | Returns     :                                                 |
    -- |                                                               |
    -- |                                                               |
    -- + ==============================================================+
    PROCEDURE PO_VAL_CANCEL_PROC( p_user_id  IN  NUMBER 
                                 ,p_responsibility_id IN NUMBER 
                                 ,pt_sale_order_line_id IN line_id_tbl_type
				 ,xt_return_status OUT line_id_tbl_type
                                 ,x_ret_code OUT VARCHAR2   
                                 ,x_err_buff OUT VARCHAR2
                                 )
    IS
       --declaration of local variables
       ln_po_header_id                NUMBER;      
       ln_suppsource_line_id          NUMBER;
       ln_po_line_id                  NUMBER;
       ln_app_id                      NUMBER;
       lc_document_subtype            VARCHAR2(25);
       lc_return_status               VARCHAR2(1);
       lc_err_buff                    VARCHAR2(1000);
       lc_ret_code                    VARCHAR2(100);
       lc_msg_data                    VARCHAR2(4000) DEFAULT ' ';
       lc_err_code                    xxom.xxod_global_exceptions_tbl.error_code%TYPE;
       lc_err_desc                    xxom.xxod_global_exceptions_tbl.description%TYPE;
       lc_entity_ref                  xxom.xxod_global_exceptions_tbl.entity_ref%TYPE;
       ln_entity_ref_id               xxom.xxod_global_exceptions_tbl.entity_ref_id%TYPE;
       err_report_type                xxod_report_exception;
       ex_pocancel_error	      EXCEPTION;
    BEGIN
       -- If User ID and responsibility ID is Null then raise 
       -- exception
       IF p_user_id = NULL THEN
	  FND_MESSAGE.SET_NAME ('xxom','ODP_OM_USERID_NULL');
          lc_err_code := '101';
          lc_err_desc := FND_MESSAGE.GET;
          lc_entity_ref := 'Responsibiltiy_id';
          ln_entity_ref_id:= NVL(p_user_id,0);
	  RAISE ex_pocancel_error;
       ELSIF p_responsibility_id = NULL THEN
	  FND_MESSAGE.SET_NAME ('xxom','ODP_OM_RESP_ID_NULL');
          lc_err_code := '102';
          lc_err_desc := FND_MESSAGE.GET;
          lc_entity_ref := 'Responsibiltiy_id';
          ln_entity_ref_id:= NVL(p_responsibility_id,0);
	  RAISE ex_pocancel_error;
      END IF;
       BEGIN
          -- Fetching the responsibility ID and Application ID
          SELECT application_id
          INTO ln_app_id
          FROM fnd_responsibility_vl 
          WHERE responsibility_id = p_responsibility_id;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             FND_MESSAGE.SET_NAME ('xxom','ODP_OM_RESP_ID_NULL');
             lc_err_code := '102';
             lc_err_desc := FND_MESSAGE.GET;
             lc_entity_ref := 'Responsibiltiy_id';
             ln_entity_ref_id:= NVL(p_responsibility_id,0);
	     RAISE ex_pocancel_error;
          WHEN TOO_MANY_ROWS THEN
             FND_MESSAGE.SET_NAME ('xxom','ODP_OM_RESP_ID_MANY');
             lc_err_code := '103';
             lc_err_desc := FND_MESSAGE.GET;
             lc_entity_ref := 'responsibility_id';
	     ln_entity_ref_id:= NVL(p_responsibility_id,0);
	     RAISE ex_pocancel_error;
       END;
       FND_GLOBAL.APPS_INITIALIZE (p_user_id
                                   ,p_responsibility_id
                                   ,ln_app_id
                                   ); 
       FOR i IN pt_sale_order_line_id.FIRST .. pt_sale_order_line_id.LAST 
       LOOP
       --Fetching po header id and distribution id from mtl_reservations table.
       BEGIN
          SELECT supply_source_line_id
          INTO   ln_suppsource_line_id
          FROM mtl_reservations
          WHERE supply_source_type_id =17
          AND demand_source_line_id = pt_sale_order_line_id(i).sale_order_line_id;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
          FND_MESSAGE.SET_NAME('xxom','ODP_OM_REQUISITION_ID_NULL');
          lc_err_code := '109';
          lc_err_desc := FND_MESSAGE.GET;
          lc_entity_ref := 'sales order line ID';
          ln_entity_ref_id := NVL(pt_sale_order_line_id(i).sale_order_line_id,0);
          err_report_type := xxod_report_exception('OTHERS'
                                                ,'OTC'
                                                ,'Internal Fulfillment'
                                                ,'Purchasing'
                                                ,lc_err_code
                                                ,lc_err_desc
                                                ,lc_entity_ref
                                                ,ln_entity_ref_id
                                                 );
          xxod_global_exception_pkg.insert_exception(err_report_type
                                                     ,lc_err_buff
                                                     ,lc_ret_code
                                                     );
       WHEN TOO_MANY_ROWS THEN
          FND_MESSAGE.SET_NAME('xxom','ODP_OM_REQUISITION_ID_MANY');  
          lc_err_code := '108';
          lc_err_desc := FND_MESSAGE.GET;
          lc_entity_ref := 'sales order line ID';
          ln_entity_ref_id := NVL(pt_sale_order_line_id(i).sale_order_line_id,0);
          err_report_type := xxod_report_exception('OTHERS'
                                                ,'OTC'
                                                ,'Internal Fulfillment'
                                                ,'Purchasing'
                                                ,lc_err_code
                                                ,lc_err_desc
                                                ,lc_entity_ref
                                                ,ln_entity_ref_id
                                                 );
          xxod_global_exception_pkg.insert_exception(err_report_type
                                                     ,lc_err_buff
                                                     ,lc_ret_code
                                                     );
       END;
       BEGIN
       --Fetching po line id and document subtype which is required for calling the Po cancel API
 		  SELECT PL.po_line_id
			,PDT.document_subtype
			,PH.po_header_id
		  INTO	ln_po_line_id
			,lc_document_subtype
			,ln_po_header_id
		  FROM	po_requisition_lines_all PRL
			,po_line_locations_all	PLL
			,po_distributions_all	PD
			,po_lines_all PL 
			,po_headers_all PH
			,po_document_types_all PDT
		  WHERE PRL.requisition_line_id=ln_suppsource_line_id
		  AND	PRL.line_location_id=PLL.line_location_id
		  AND   PLL.line_location_id=PD.line_location_id
		  AND	PD.po_line_id=PL.po_line_id
		  AND	PL.po_header_id=PH.po_header_id
		  AND	PL.closed_code = 'OPEN'
		  AND	PH.authorization_status = 'APPROVED'
		  AND	PDT.document_subtype = PH.type_lookup_code
		  AND	PDT.document_type_code='PO'
		  AND	PDT.org_id=PH.org_id;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
          FND_MESSAGE.SET_NAME('xxom','ODP_OM_LINE_ID_NULL');
          lc_err_code := '110';
          lc_err_desc := FND_MESSAGE.GET;
          lc_entity_ref := 'sales order line ID';
          ln_entity_ref_id := NVL(pt_sale_order_line_id(i).sale_order_line_id,0);
          err_report_type := xxod_report_exception('OTHERS'
                                                ,'OTC'
                                                ,'Internal Fulfillment'
                                                ,'Purchasing'
                                                ,lc_err_code
                                                ,lc_err_desc
                                                ,lc_entity_ref
                                                ,ln_entity_ref_id
                                                );
          xxod_global_exception_pkg.insert_exception(err_report_type
                                                     ,lc_err_buff
                                                     ,lc_ret_code
                                                     );
       WHEN TOO_MANY_ROWS THEN
          FND_MESSAGE.SET_NAME('xxom','ODP_OM_LINE_ID_MANY');
          lc_err_code := '111';
          lc_err_desc := FND_MESSAGE.GET;
          lc_entity_ref := 'sales order line ID';
          ln_entity_ref_id := NVL(pt_sale_order_line_id(i).sale_order_line_id,0);
          err_report_type := xxod_report_exception('OTHERS'
                                                ,'OTC'
                                                ,'Internal Fulfillment'
                                                ,'Purchasing'
                                                ,lc_err_code
                                                ,lc_err_desc
                                                ,lc_entity_ref
                                                ,ln_entity_ref_id
                                                 );
          xxod_global_exception_pkg.insert_exception(err_report_type
                                                     ,lc_err_buff
                                                     ,lc_ret_code
                                                     );
       END;
       --calling the API to cancel the po line.
       PO_DOCUMENT_CONTROL_PUB.CONTROL_DOCUMENT(p_api_version	                => 1.0
                                                ,p_init_msg_list                => fnd_api.g_true
                                                ,p_commit                       => fnd_api.g_true
                                                ,x_return_status                => lc_return_status
                                                ,p_doc_type                     => 'PO'
                                                ,p_doc_subtype                  => lc_document_subtype
                                                ,p_doc_id                       => ln_po_header_id
                                                ,p_doc_num                      => NULL
                                                ,p_release_id                   => NULL
                                                ,p_release_num                  => NULL
                                                ,p_doc_line_id                  => ln_po_line_id
                                                ,p_doc_line_num                 => NULL
                                                ,p_doc_line_loc_id              => NULL
                                                ,p_doc_shipment_num             => NULL
                                                ,p_action                       => 'CANCEL'
                                                ,p_action_date                  => SYSDATE
                                                ,p_cancel_reason                => NULL
                                                ,p_cancel_reqs_flag             => 'Y'
                                                ,p_print_flag                   => NULL
                                                ,p_note_to_vendor               => NULL
                                                ,p_use_gldate                   => NULL
                                                );  
       IF (lc_return_status <> 'S') THEN  
       --getting the error message from error stack.
          IF FND_MSG_PUB.count_msg > 0 THEN
             FOR i IN 1..FND_MSG_PUB.count_msg
             LOOP
                lc_msg_data := lc_msg_data || '  ' || FND_MSG_PUB.GET(p_msg_index => i
                                                                      ,p_encoded  => 'F'
                                                                      );  
                lc_err_code := '112';
                lc_err_desc := lc_msg_data;
                lc_entity_ref := 'sales order line ID';
                ln_entity_ref_id:= NVL(pt_sale_order_line_id(i).sale_order_line_id,0) ;	
                err_report_type := xxod_report_exception('OTHERS'
                                                      ,'OTC'
                                                      ,'Internal Fulfillment'
                                                      ,'Purchasing'
                                                      ,lc_err_code
                                                      ,lc_err_desc
                                                      ,lc_entity_ref
                                                      ,ln_entity_ref_id
                                                       );
               xxod_global_exception_pkg.insert_exception(err_report_type
                                                          ,lc_err_buff
                                                          ,lc_ret_code
                                                          );
                END LOOP;
             END IF; 
          END IF;
	xt_return_status(i).status := pt_sale_order_line_id(i).sale_order_line_id
			            ||' '||lc_return_status;
      END LOOP;
       COMMIT;
       EXCEPTION
       WHEN ex_pocancel_error THEN
            x_ret_code := 'E';
	    err_report_type := xxod_report_exception('EX_POCANCEL_ERROR'
                                                    ,'OTC'
                                                    ,'Internal Fulfillment'
                                                    ,'Purchasing'
                                                    ,lc_err_code
                                                    ,lc_err_desc
                                                    ,lc_entity_ref
                                                    ,ln_entity_ref_id
                                                    );
             xxod_global_exception_pkg.insert_exception(err_report_type
                                                        ,lc_err_buff
                                                        ,lc_ret_code
                                                        );
       WHEN OTHERS THEN
          ROLLBACK;
	  x_ret_code := 'E';
          lc_err_code := '113';
          lc_err_desc := SQLERRM;
          lc_entity_ref := 'sales order line ID';
          ln_entity_ref_id := NVL(ln_po_line_id,0);
          err_report_type := xxod_report_exception('OTHERS'
                                                ,'OTC'
                                                ,'Internal Fulfillment'
                                                ,'Purchasing'
                                                ,lc_err_code
                                                ,lc_err_desc
                                                ,lc_entity_ref
                                                ,ln_entity_ref_id
                                                );
         --used to insert exception in xxod_global_exceptions_tbl table	
          xxod_global_exception_pkg.insert_exception(err_report_type
                                                     ,lc_err_buff
                                                     ,lc_ret_code
                                                     );
    END PO_VAL_CANCEL_PROC;            --end of procedure
 END XX_OM_POCANCEL_B2B_PKG;           --end of package

/
SHOW ERROR