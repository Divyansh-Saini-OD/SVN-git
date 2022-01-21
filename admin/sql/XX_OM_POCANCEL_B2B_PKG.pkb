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
 -- +================================================================ +
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
  -- + ======================================================================================+     
    -- | Name        : PO_VAL_CANCEL_PROC                                                    |
    -- | Description : Procedure PO_VAL_CANCEL_PROC will perform the                         |
    -- |               following:                                                            |
    -- |               1. Gets the sales order IDs as parameters                             |
    -- |                  through table type.                                                |
    -- |               2. Fetches the po_header_id and distribution ID                       |
    -- |               3. Fetches the po_line_id, doc_subtype for all                        |
    -- |                  approved and open purchase orders                                  |
    -- |               4. Call the PO cancel API for cancelling the PO                       |
    -- |                  lines                                                              |
    -- | Parameters  : p_user_id                 IN parameter user id                        |
    -- |               p_responsibility_id       IN parameter Resp Id                        |
    -- |               px_sales_order_line_id_tbl IN OUT table type parameter with            |
    -- |                                         SO line id --  line id                      |
    -- |                                         PO cancel line  status - values 'E' OR 'S'  |
    -- |                                                                                     |
    -- |               x_status                  OUT program execution status                |
    -- |                                         it can return values 'E' or'S'              |
    -- |					 E --> program errored intermittently        | 
    -- |				         S --> program completed successful          |
    -- |                                                                                     |
    -- |                                                                                     |
    -- + ====================================================================================+

    PROCEDURE PO_VAL_CANCEL_PROC( p_user_id                 IN  NUMBER 
                                 ,p_responsibility_id       IN NUMBER 
                                 ,px_sales_order_line_id_tbl IN OUT line_id_tbl_type
				 ,x_status                  OUT VARCHAR2  
                                 )
    IS
       --declaration of local variables
       ln_po_header_id                po_headers_all.po_header_id%TYPE;      
       ln_po_line_id                  po_lines_all.po_line_id%TYPE;
       ln_app_id                      fnd_responsibility_vl.application_id%TYPE;
       lc_document_subtype            po_document_types_all.document_subtype%TYPE;
       lc_return_status               VARCHAR2(1);
       lc_msg_data                    VARCHAR2(20000);     
       EX_POCANCEL_ERROR	      EXCEPTION;
       EX_INVALID_PO_CANCEL           EXCEPTION;
       lc_po_line_exists              VARCHAR2(1); 

       -- exception pkg variables
       lc_err_code                    xxom.xx_om_global_exceptions.error_code%TYPE;
       lc_err_desc                    xxom.xx_om_global_exceptions.description%TYPE;
       lc_entity_ref                  xxom.xx_om_global_exceptions.entity_ref%TYPE;
       ln_entity_ref_id               xxom.xx_om_global_exceptions.entity_ref_id%TYPE;
       err_report_type                xx_om_report_exception_t;
       lc_sqlcode                     VARCHAR2 (100);
       lc_sqlerrm                     VARCHAR2 (1000);
       lc_errbuff                     VARCHAR2 (1000); 
       lc_retcode                     VARCHAR2 (100);
       lc_error_message               VARCHAR2 (4000);
       lc_user_exists                 VARCHAR2 (1);


       CURSOR lcu_main_po_lines ( p_so_line_id mtl_reservations.demand_source_line_id%TYPE )
       IS
       SELECT PL.po_line_id
             ,PDT.document_subtype
             ,PH.po_header_id
	     ,'Y'    
       FROM  po_lines_all PL 
	    ,po_headers_all PH
	    ,po_document_types_all PDT
	    ,mtl_supply       MS
	    ,mtl_reservations MT
       WHERE  PL.closed_code          = 'OPEN'
	AND  PH.authorization_status  = gc_auth_status
	AND  PDT.document_subtype     = PH.type_lookup_code
	AND  PDT.document_type_code   = gc_po_type
	AND  PDT.org_id               =PH.org_id
	AND  PL.po_header_id          = PH.po_header_id
	AND  MS.po_line_id            = PL.po_line_id
	AND  MT.supply_source_line_id = MS.supply_source_id
	AND  MT.supply_source_type_id = gn_supp_source_type_id  
	AND  MT.demand_source_line_id = p_so_line_id ;
	
      
    BEGIN
       -- If User ID and responsibility ID is Null then raise  exception

       gn_sql_point := 10;

       IF ( p_user_id IS NULL OR p_responsibility_id IS NULL ) THEN
	  FND_MESSAGE.SET_NAME ('XXOM','ODP_OM_USERID_RESPID_NULL');
          lc_err_code := 'ODP_OM_USERID_RESPID_NULL';
          lc_err_desc := FND_MESSAGE.GET;
          lc_entity_ref := 'NA';
          ln_entity_ref_id:= 0;
	  RAISE ex_pocancel_error; 
       ELSE	  
          BEGIN
             -- Fetching the responsibility  Application ID
	     gn_sql_point := 20;
      
	     SELECT application_id
             INTO ln_app_id
             FROM fnd_responsibility_vl FRV
	     WHERE responsibility_id =  p_responsibility_id
	     AND  SYSDATE BETWEEN TO_DATE(TO_CHAR(NVL(FRV.start_date,SYSDATE),'DDMMYYYY')||'000000','DDMMYYYYHH24MISS')
                                      AND     TO_DATE(TO_CHAR(NVL(FRV.end_date,SYSDATE),'DDMMYYYY') ||'235959','DDMMYYYYHH24MISS');
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
             FND_MESSAGE.SET_NAME ('XXOM','ODP_OM_RESP_ID_INVALID');
             lc_err_code := 'ODP_OM_RESP_ID_INVALID';
             lc_err_desc := FND_MESSAGE.GET;
             lc_entity_ref := 'Responsibility_id';
             ln_entity_ref_id:= NVL(p_responsibility_id,0);
	     RAISE ex_pocancel_error;
          WHEN TOO_MANY_ROWS THEN
             FND_MESSAGE.SET_NAME ('XXOM','ODP_OM_RESP_ID_MANY');
             lc_err_code := 'ODP_OM_RESP_ID_MANY';
             lc_err_desc := FND_MESSAGE.GET;
             lc_entity_ref := 'responsibility_id';
	     ln_entity_ref_id:= NVL(p_responsibility_id,0);
	     RAISE ex_pocancel_error;
          END;

	   BEGIN
             -- Fetching the user ID
	     gn_sql_point := 20;
      
	     SELECT 'Y'
             INTO lc_user_exists
             FROM fnd_user FU
	     WHERE user_id =  p_user_id
	     AND  SYSDATE BETWEEN TO_DATE(TO_CHAR(NVL(FU.start_date,SYSDATE),'DDMMYYYY')||'000000','DDMMYYYYHH24MISS')
                                      AND     TO_DATE(TO_CHAR(NVL(FU.end_date,SYSDATE),'DDMMYYYY') ||'235959','DDMMYYYYHH24MISS');
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
             FND_MESSAGE.SET_NAME ('XXOM','ODP_OM_USER_ID_INVALID');
             lc_err_code := 'ODP_OM_USER_ID_INVALID';
             lc_err_desc := FND_MESSAGE.GET;
             lc_entity_ref := 'User_id';
             ln_entity_ref_id:= NVL( p_user_id,0);
	     RAISE ex_pocancel_error;
          WHEN TOO_MANY_ROWS THEN
             FND_MESSAGE.SET_NAME ('XXOM','ODP_OM_USER_ID_MANY');
             lc_err_code := 'ODP_OM_USER_ID_MANY';
             lc_err_desc := FND_MESSAGE.GET;
             lc_entity_ref := 'User_id';
	     ln_entity_ref_id:= NVL( p_user_id,0);
	     RAISE ex_pocancel_error;
          END;

       END IF;
        gn_sql_point := 30;
       -- Initialising the Apps environment 
       FND_GLOBAL.APPS_INITIALIZE  (p_user_id
                                   ,p_responsibility_id
                                   ,ln_app_id
                                   ); 

       -- Main loop to fetch and cancel the PO lines for the given table type Sales order line id.

    IF px_sales_order_line_id_tbl.COUNT > 0 THEN

       FOR i IN px_sales_order_line_id_tbl.FIRST .. px_sales_order_line_id_tbl.LAST 
       LOOP
          BEGIN
         
          --initialising variable 
	   gn_sql_point := 40;
	  lc_po_line_exists := 'N' ;
	  lc_msg_data := NULL;
	  gc_line_id := px_sales_order_line_id_tbl(i).sales_order_line_id ; 

           --Fetching po info for cancelling the PO Line using Po cancel API.
          OPEN lcu_main_po_lines ( px_sales_order_line_id_tbl(i).sales_order_line_id );
              FETCH lcu_main_po_lines
              INTO  ln_po_line_id 
	           ,lc_document_subtype
		   ,ln_po_header_id 
		   ,lc_po_line_exists ;
          CLOSE lcu_main_po_lines;


          gn_sql_point := 50;
          IF lc_po_line_exists = 'Y' THEN

	     --calling the API to cancel the po line.
             PO_DOCUMENT_CONTROL_PUB.CONTROL_DOCUMENT( p_api_version	              => 1.0
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
              gn_sql_point := 60; 
              IF  (lc_return_status <> 'S') THEN 
                 --getting the error message from error stack.
                 IF FND_MSG_PUB.count_msg > 0 THEN
                    FOR i IN 1..FND_MSG_PUB.count_msg
                    LOOP
		        gn_sql_point := 10;
                       lc_msg_data := lc_msg_data || '  ' || FND_MSG_PUB.GET( p_msg_index => i
                                                                             ,p_encoded  => 'F'
                                                                             ); 
                    END LOOP;		   
                 END IF;
		 FND_MESSAGE.SET_NAME('XXOM' ,'ODP_OM_PO_CANCEL_FAIL');
                 lc_err_code      := 'ODP_OM_PO_CANCEL_FAIL';
                 lc_err_desc      := FND_MESSAGE.GET;
		 lc_err_desc      := SUBSTR(lc_err_desc||lc_msg_data,1,1000);
                 lc_entity_ref    := 'sales order line ID';
                 ln_entity_ref_id := NVL(px_sales_order_line_id_tbl(i).sales_order_line_id,0); 
		 RAISE EX_INVALID_PO_CANCEL ;
               ELSE
	           px_sales_order_line_id_tbl(i).status :='S' ;
               END IF;	
	       
           ELSE
	      FND_MESSAGE.SET_NAME('XXOM' ,'ODP_OM_PO_LINE_NOT_FOUND');
              lc_err_code      := 'ODP_OM_PO_LINE_NOT_FOUND';
              lc_err_desc      := FND_MESSAGE.GET;
              lc_entity_ref    := 'sales order line ID';
              ln_entity_ref_id := NVL(px_sales_order_line_id_tbl(i).sales_order_line_id,0); 
	      RAISE EX_INVALID_PO_CANCEL ;
         						       
           END IF; --PO LINE EXISTS
            gn_sql_point := 70;	     
          EXCEPTION
             WHEN EX_INVALID_PO_CANCEL THEN
	     px_sales_order_line_id_tbl(i).status :='E' ;             	     
	     err_report_type  :=
                    xx_om_report_exception_t (gc_exception_header
                                             ,gc_exception_track
                                             ,gc_exception_sol_dom
                                             ,gc_error_function
                                             ,lc_err_code
                                             ,lc_err_desc
                                             ,lc_entity_ref
                                             ,ln_entity_ref_id
                                              );
                         
             XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (err_report_type
                                                        ,lc_errbuff
                                                        ,lc_retcode
                                                         );
          END;           	
       END LOOP;
       COMMIT;
    ELSE
       FND_MESSAGE.SET_NAME ('XXOM','ODP_OM_NO_LINE_ID');
       lc_err_code := 'ODP_OM_NO_LINE_ID';
       lc_err_desc := FND_MESSAGE.GET;
       lc_entity_ref := 'Responsibiltiy_id';
       ln_entity_ref_id:= NVL(p_responsibility_id,0);
       RAISE ex_pocancel_error;
    END IF;
       x_status := 'S' ;
    EXCEPTION
       WHEN ex_pocancel_error THEN
            x_status := 'E' ;
	    err_report_type  :=
                    xx_om_report_exception_t (gc_exception_header
                                             ,gc_exception_track
                                             ,gc_exception_sol_dom
                                             ,gc_error_function
                                             ,lc_err_code
                                             ,lc_err_desc
                                             ,lc_entity_ref
                                             ,ln_entity_ref_id
                                              );
                         
            XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (err_report_type
                                                        ,lc_errbuff
                                                        ,lc_retcode
                                                         );
       WHEN OTHERS THEN
          ROLLBACK;
	   x_status := 'E' ;
	   fnd_message.set_name ('XXOM', 'ODP_OM_PO_CANCEL_UNKNOWN_ERROR');
           lc_error_message := fnd_message.get;
           lc_sqlcode       := SQLCODE;
           lc_sqlerrm       := SUBSTR( SQLERRM,1,1000);
           lc_err_code      := SQLCODE;
           lc_err_desc      := SUBSTR(lc_error_message||'Error while processing PO cancel B2B lines at '||gn_sql_point||' '||lc_sqlerrm,1,1000);
           lc_entity_ref    := 'line_id';
           ln_entity_ref_id := NVL(gc_line_id,0);
           err_report_type  :=
                    xx_om_report_exception_t (gc_exception_header
                                             ,gc_exception_track
                                             ,gc_exception_sol_dom
                                             ,gc_error_function
                                             ,lc_err_code
                                             ,lc_err_desc
                                             ,lc_entity_ref
                                             ,ln_entity_ref_id
                                              );
                         
            XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (err_report_type
                                                        ,lc_errbuff
                                                        ,lc_retcode
                                                         );
	
    END PO_VAL_CANCEL_PROC;            --end of procedure
 END XX_OM_POCANCEL_B2B_PKG;           --end of package

/
SHOW ERROR