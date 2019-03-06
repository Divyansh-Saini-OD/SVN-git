SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_OM_POACKINTF_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name  :  XX_OM_POACKINTF_PKG                                      |
-- | Rice ID : I0265                                                   |
-- | Description: This package contains procedures that perform the    |
-- |              following activities                                 |
-- |              1.Validate the PO Acknowledgement Message            |
-- |              2.Update the Acknowledgement details                 |
-- |              3.Cancel a PO Line                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  1-JUN-07   Aravind A.        Initial draft version       |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
AS
-- +===================================================================+
-- | Following are the Global parameters that are used                 |
-- | across this package                                               |
-- +===================================================================+
gc_po_status        po_headers_all.authorization_status%TYPE       DEFAULT  'APPROVED';
gc_closed_code      po_lines_all.closed_code%TYPE                  DEFAULT  'OPEN';
gc_lookup_type      fnd_lookup_values.lookup_type%TYPE             DEFAULT  'XX_OM_PO_ACK_CODE_LOOKUPS';
gc_po_lookup_type   fnd_lookup_values.lookup_type%TYPE             DEFAULT  'OD_PO_CANCEL_ISP';
gc_default_ack      VARCHAR2(100)                                  DEFAULT  'Accept';
gc_ack_code_ir      VARCHAR2(2)                                    DEFAULT  'IR';
gc_ack_code_ia      VARCHAR2(2)                                    DEFAULT  'IA';
gc_ack_code_r2      VARCHAR2(2)                                    DEFAULT  'R2';
gc_ack_code_ic      VARCHAR2(2)                                    DEFAULT  'IC';
gc_doc_type_code    po_document_types_all.document_type_code%TYPE  DEFAULT  'PO';
gc_api_action       VARCHAR2(30)                                   DEFAULT  'CANCEL';
gc_exp_header       xx_om_global_exceptions.exception_header%TYPE  DEFAULT  'OTHERS';
gc_track_code       xx_om_global_exceptions.track_code%TYPE        DEFAULT  'OTC';
gc_sol_domain       xx_om_global_exceptions.solution_domain%TYPE   DEFAULT  'Internal Fulfillment';
gc_function         xx_om_global_exceptions.function_name%TYPE     DEFAULT  'I0265_POAck';
gc_success_sts      VARCHAR2(1)                                    DEFAULT  'S';
gc_error_sts        VARCHAR2(1)                                    DEFAULT  'E';
gc_line_loc_closed  po_line_locations_all.closed_code%TYPE         DEFAULT  'CLOSED FOR RECEIVING';
-- +===================================================================+
-- | Name  : VALIDATE_PROCESS_POACK                                    |
-- | Description   : This procedure will validate the input PO Ack     |
-- |                 message and will call the UPDATE_POACK if the PO  |
-- |                 is accepted or will call the CANCEL_POLINES if    |
-- |                 the PO is rejected                                |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :       Following are the Table type variables         |
-- |                    that are passed to this procedure              |
-- |                                                                   |
-- |                    p_po_vendor_site_id                            |
-- |                    p_po_number                                    |
-- |                    p_ref_po_number                                |
-- |                    p_transaction_date                             |
-- |                    p_sales_order                                  |
-- |                    p_po_line_number                               |
-- |                    p_vendor_sku                                   |
-- |                    p_item_number                                  |
-- |                    p_upc_code                                     |
-- |                    p_shipment_date                                |
-- |                    p_ack_code                                     |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          Following are the table type parameters        |
-- |                    returned by this procedure                     |
-- |                                                                   |
-- |                    x_status                                       |
-- |                    x_message                                      |
-- |                                                                   |
-- +===================================================================+
PROCEDURE VALIDATE_PROCESS_POACK  (
                                  p_po_vendor_site_id    IN      xx_om_poack_number_tbl_type
                                 ,p_po_number            IN      xx_om_poack_varchar_tbl_type
                                 ,p_ref_po_number        IN      xx_om_poack_varchar_tbl_type
                                 ,p_transaction_date     IN      xx_om_poack_date_tbl_type
                                 ,p_sales_order          IN      xx_om_poack_number_tbl_type
                                 ,p_po_line_number       IN      xx_om_poack_number_tbl_type
                                 ,p_vendor_sku           IN      xx_om_poack_varchar_tbl_type
                                 ,p_item_number          IN      xx_om_poack_varchar_tbl_type
                                 ,p_upc_code             IN      xx_om_poack_varchar_tbl_type
                                 ,p_shipment_date        IN      xx_om_poack_date_tbl_type
                                 ,p_ack_code             IN      xx_om_poack_varchar_tbl_type
                                 ,p_user_name            IN      VARCHAR2
                                 ,p_resp_name            IN      VARCHAR2
                                 ,x_status               OUT     VARCHAR2
                                 ,x_message              OUT     VARCHAR2
                                 )
IS
   EX_HDR_INVALID      EXCEPTION;           --Exception variable for invalid Header
   EX_LINE_INVALID     EXCEPTION;           --Exception variable for invalid Line
   EX_APPSINIT_FAIL    EXCEPTION;           --Exception variable for invalid apps fail
   err_report_type     xx_om_report_exception_t;
   lc_po_auth_status   po_headers_all.authorization_status%TYPE;
   lc_upc_code         mtl_cross_references.cross_reference%TYPE;
   lc_closed_code      po_lines_all.closed_code%TYPE;
   lc_err_code         xx_om_global_exceptions.error_code%TYPE DEFAULT ' ';
   lc_err_desc         xx_om_global_exceptions.description%TYPE DEFAULT ' ';
   lc_entity_ref       xx_om_global_exceptions.entity_ref%TYPE;
   lc_vendor_sku       po_asl_suppliers_v.primary_vendor_item%TYPE;
   ln_po_header_id     po_lines_all.po_header_id%TYPE;
   ln_po_item_id       po_lines_all.item_id%TYPE DEFAULT 0;
   ln_po_line_id       po_lines_all.po_line_id%TYPE;
   ln_vendor_site_id   po_headers_all.vendor_site_id%TYPE;
   ln_cur_hdr          PLS_INTEGER  DEFAULT 0;
   ln_entity_ref_id    xx_om_global_exceptions.entity_ref_id%TYPE;
   lc_update_status    VARCHAR2(100);
   lc_update_message   VARCHAR2(400);
   lc_cancel_status    VARCHAR2(100);
   lc_cancel_message   VARCHAR2(400);
   lc_appsinit_status  VARCHAR2(400);
   lc_appsinit_message VARCHAR2(400);
   lc_err_buf          VARCHAR2(240);
   lc_ret_code         VARCHAR2(30);
   ln_nid              NUMBER;
   lc_message_text     VARCHAR(4000);
   lc_notf_flag        VARCHAR2(1) := 'N';
   lc_message_item_text VARCHAR2(4000);
   lc_notif_role       wf_local_roles.name%TYPE;
   lc_vendor_name      po_vendors.vendor_name%TYPE;
   lc_role_found       VARCHAR2(1) DEFAULT 'N';
   lc_item_number      mtl_system_items.segment1%TYPE;
   lc_item_valid       VARCHAR2(1);
   --Cursor for fetching item id
   CURSOR lcu_item_id (
                       p_item_number mtl_system_items.segment1%TYPE
                       ,p_po_header_id po_headers_all.po_header_id%TYPE
                       ,p_po_line_number po_lines_all.po_line_id%TYPE
                       )
   IS
     SELECT MSI.inventory_item_id
     FROM mtl_system_items MSI
          ,po_line_locations_all PLLA
          ,po_lines_all PLA
     WHERE MSI.segment1 = p_item_number
     AND MSI.organization_id = PLLA.ship_to_organization_id
     AND PLLA.po_line_id = PLA.po_line_id
     AND PLA.po_header_id = p_po_header_id
     AND PLA.line_num = p_po_line_number ;
   BEGIN

           --Initializing Apps.
           XX_OM_POACKINTF_PKG.APPS_INIT(
                                        p_user_name
                                        ,p_resp_name
                                        ,lc_appsinit_status
                                        ,lc_appsinit_message
                                        );           

           --Setting Title and Message body for Notification.
           lc_message_text := CHR(10)|| CHR(10)||'Following are the order details for change request'|| CHR(10)|| CHR(10);
           
           --Loop through the number of PO Headers(derived from attribute COUNT)
           --and perform Header level validations
           FOR i IN 1..p_po_number.COUNT
           LOOP
              IF (lc_appsinit_status =  gc_error_sts) THEN
                 x_status  := gc_error_sts;
                 x_message := lc_appsinit_message;
                 lc_err_code := lc_appsinit_message;
                 FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_APPSINT_FAILED');
                 lc_err_desc := FND_MESSAGE.GET;
                 lc_entity_ref := 'PO Number';
                 ln_entity_ref_id := NVL(p_po_number(i),0);
                 RAISE EX_APPSINIT_FAIL;
              END IF;

              ln_cur_hdr := i;
              BEGIN
                 BEGIN
                    --Fetch authorization_status,attribute_category and vendor_site_id
                    --from PO_HEADERS_ALL table passing the segment1 value
                    SELECT PHA.authorization_status
                           ,PHA.vendor_site_id
                           ,PHA.po_header_id
                           ,PV.vendor_name
                    INTO lc_po_auth_status
                        ,ln_vendor_site_id
                        ,ln_po_header_id
                        ,lc_vendor_name
                    FROM po_headers_all PHA
                         ,po_vendor_sites_all PVSA
                         ,po_vendors PV
                         ,fnd_lookup_values FLV
                    WHERE PHA.vendor_site_id = PVSA.vendor_site_id
                    AND PVSA.vendor_id = PV.vendor_id
                    AND FLV.lookup_type = gc_po_lookup_type
                    AND FLV.lookup_code IN ('BACKTOBACK','DROPSHIP')
                    AND FLV.language = USERENV('LANG')
                    AND FLV.enabled_flag= 'Y'
                    AND PHA.attribute_category = FLV.meaning
                    AND PHA.segment1 = p_po_number(i);
                 EXCEPTION
                    --When the specified PO Number (Segment1) is not found
                    --log the exception in Global exceptions table
                    WHEN NO_DATA_FOUND THEN
                         lc_err_code := 'ODP_OM_POACK_INVALID_PO';
                         FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_PO');
                         lc_err_desc := FND_MESSAGE.GET;
                         lc_entity_ref := 'PO Number';
                         ln_entity_ref_id := NVL(p_po_number(i),0);
                         RAISE EX_HDR_INVALID;
                    WHEN TOO_MANY_ROWS THEN
                         lc_err_code := 'ODP_OM_POACK_INVALID_PO';
                         FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_PO');
                         lc_err_desc := FND_MESSAGE.GET;
                         lc_entity_ref := 'PO Number';
                         ln_entity_ref_id := NVL(p_po_number(i),0);
                         RAISE EX_HDR_INVALID;
                 END;
                 --Check if the authorisation_status is APPROVED
                 --if not log the exception in Global exceptions table
                 IF (NVL(lc_po_auth_status,'X') <> gc_po_status) THEN
                    lc_err_code := 'ODP_OM_POACK_UNAPPROVED_PO';
                    FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_UNAPPROVED_PO');
                    lc_err_desc := FND_MESSAGE.GET;
                    lc_entity_ref := 'PO Number';
                    ln_entity_ref_id := NVL(p_po_number(i),0);
                    RAISE EX_HDR_INVALID;
                 END IF;
                 --Check if the vendor_site_id matches with the input vendor_site_id
                 --if not log the exception in Global exceptions table
                 IF (ln_vendor_site_id <> p_po_vendor_site_id(i)) THEN
                    lc_err_code := 'ODP_OM_POACK_INVALID_VENSITEID';
                    FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_VENSITEID');
                    lc_err_desc := FND_MESSAGE.GET;
                    lc_entity_ref := 'Vendor Site ID';
                    ln_entity_ref_id := NVL(p_po_vendor_site_id(i),0);
                    RAISE EX_HDR_INVALID;
                 END IF;
                 --Loop through the PO lines and perform line level validations

                 lc_message_item_text := NULL;

                 FOR j IN 1..p_po_line_number.COUNT
                 LOOP
                    BEGIN
                       ln_po_item_id := 0;
                       IF (p_ref_po_number(j) = p_po_number(i)) THEN
                                IF (p_item_number(j) IS NOT NULL) THEN
                                      --Fetching item id from the cursor
                                      FOR item_id_rec IN lcu_item_id(p_item_number(j)
                                                                    ,ln_po_header_id
                                                                    ,p_po_line_number(j))
                                      LOOP
                                         ln_po_item_id := item_id_rec.inventory_item_id;
                                      END LOOP;

                                      IF (ln_po_item_id = 0) THEN
                                         lc_err_code := 'ODP_OM_POACK_INVALID_ITEM_NUM';                       
                                         FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_ITEM_NUM');       
                                         lc_err_desc := FND_MESSAGE.GET;                                       
                                         lc_entity_ref := 'PO Line Number';                                    
                                         ln_entity_ref_id := NVL(p_po_line_number(j),0);                       
                                         err_report_type :=                                                    
                                                          xx_om_report_exception_t (                           
                                                                                    gc_exp_header              
                                                                                    ,gc_track_code             
                                                                                    ,gc_sol_domain             
                                                                                    ,gc_function               
                                                                                    ,lc_err_code               
                                                                                    ,SUBSTR(lc_err_desc,1,1000)
                                                                                    ,lc_entity_ref             
                                                                                    ,ln_entity_ref_id          
                                                                                   );                          
                                                                                                               
                                         XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (                         
                                                                                      err_report_type          
                                                                                      ,lc_err_buf              
                                                                                      ,lc_ret_code             
                                                                                     );                        

                                      END IF;
                                END IF;

                                IF (p_vendor_sku(j) IS NOT NULL 
                                       AND ln_po_item_id = 0) THEN
                                   BEGIN
                                        SELECT PASL.item_id
                                        INTO ln_po_item_id
                                        FROM po_approved_supplier_list PASL
                                        WHERE PASL.primary_vendor_item = p_vendor_sku(j)
                                        AND NVL(PASL.disable_flag,'N')<>'Y'
                                        AND PASL.vendor_id = (
                                                              SELECT PVSA.vendor_id
                                                              FROM po_vendor_sites_all PVSA
                                                              WHERE vendor_site_id = p_po_vendor_site_id(i)
                                                             );
                                   EXCEPTION
                                      WHEN NO_DATA_FOUND THEN
                                           lc_err_code := 'ODP_OM_POACK_INVALID_VEN_SKU';
                                           FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_VEN_SKU');
                                           lc_err_desc := FND_MESSAGE.GET;
                                           lc_entity_ref := 'PO Number';
                                           ln_entity_ref_id := NVL(p_po_number(i),0);
                                           RAISE EX_LINE_INVALID;
                                      WHEN TOO_MANY_ROWS THEN
                                           lc_err_code := 'ODP_OM_POACK_INVALID_VEN_SKU';
                                           FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_VEN_SKU');
                                           lc_err_desc := FND_MESSAGE.GET;
                                           lc_entity_ref := 'PO Number';
                                           ln_entity_ref_id := NVL(p_po_number(i),0);
                                           RAISE EX_LINE_INVALID;
                                   END;
                                END IF;

                                IF (p_upc_code(j) IS NOT NULL 
                                       AND ln_po_item_id = 0) THEN
                                   BEGIN
                                      SELECT MCR.inventory_item_id
                                      INTO ln_po_item_id
                                      FROM mtl_cross_references MCR
                                      WHERE MCR.cross_reference = p_upc_code(j);
                                   EXCEPTION
                                      WHEN NO_DATA_FOUND THEN
                                           lc_err_code := 'ODP_OM_POACK_INVALID_UPC_CODE';
                                           FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_UPC_CODE');
                                           lc_err_desc := FND_MESSAGE.GET;
                                           lc_entity_ref := 'PO Number';
                                           ln_entity_ref_id := NVL(p_po_number(i),0);
                                           err_report_type :=                                                     
                                                            xx_om_report_exception_t (                            
                                                                                      gc_exp_header               
                                                                                      ,gc_track_code              
                                                                                      ,gc_sol_domain              
                                                                                      ,gc_function                
                                                                                      ,lc_err_code                
                                                                                      ,SUBSTR(lc_err_desc,1,1000) 
                                                                                      ,lc_entity_ref              
                                                                                      ,ln_entity_ref_id           
                                                                                     );                           
                                                                                                                  
                                           XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (                          
                                                                                        err_report_type           
                                                                                        ,lc_err_buf               
                                                                                        ,lc_ret_code              
                                                                                       );                        

                                      WHEN TOO_MANY_ROWS THEN
                                           lc_err_code := 'ODP_OM_POACK_INVALID_UPC_CODE';
                                           FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_UPC_CODE');
                                           lc_err_desc := FND_MESSAGE.GET;
                                           lc_entity_ref := 'PO Number';
                                           ln_entity_ref_id := NVL(p_po_number(i),0);
                                           err_report_type :=                                                     
                                                            xx_om_report_exception_t (                            
                                                                                      gc_exp_header               
                                                                                      ,gc_track_code              
                                                                                      ,gc_sol_domain              
                                                                                      ,gc_function                
                                                                                      ,lc_err_code                
                                                                                      ,SUBSTR(lc_err_desc,1,1000) 
                                                                                      ,lc_entity_ref              
                                                                                      ,ln_entity_ref_id           
                                                                                     );                           
                                                                                                                  
                                           XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (                          
                                                                                        err_report_type           
                                                                                        ,lc_err_buf               
                                                                                        ,lc_ret_code              
                                                                                       );                         

                                   END;
                                END IF;

                                IF (ln_po_item_id <> 0) THEN

                                    BEGIN
                                       SELECT 'Y'
                                       INTO lc_item_valid
                                       FROM mtl_system_items MSI
                                       WHERE MSI.inventory_item_id = ln_po_item_id
                                       AND   (NVL(MSI.enabled_flag, 'N')) = 'Y' 
                                       AND  TRUNC(SYSDATE) BETWEEN TRUNC(NVL(MSI.start_date_active, SYSDATE)) 
                                                                    AND TRUNC(NVL(MSI.end_date_active, SYSDATE))                                      
                                       AND ROWNUM = 1;
                                    EXCEPTION
                                       WHEN NO_DATA_FOUND THEN
                                            lc_err_code := 'ODP_OM_POACK_INVALID_ITEM';
                                            FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_ITEM');
                                            lc_err_desc := FND_MESSAGE.GET;
                                            lc_entity_ref := 'PO Number';
                                            ln_entity_ref_id := NVL(p_po_number(i),0);
                                            RAISE EX_LINE_INVALID;
                                    END;
                                 ELSE
                                    lc_err_code := 'ODP_OM_POACK_INVALID_ITEM';
                                    FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_ITEM');
                                    lc_err_desc := FND_MESSAGE.GET;
                                    lc_entity_ref := 'PO Number';
                                    ln_entity_ref_id := NVL(p_po_number(i),0);
                                    RAISE EX_LINE_INVALID;
                                 END IF;

                             BEGIN
                                SELECT PLA.closed_code
                                       ,PLA.po_line_id
                                INTO lc_closed_code
                                     ,ln_po_line_id
                                FROM po_lines_all PLA
                                WHERE PLA.line_num = p_po_line_number(j)
                                AND PLA.po_header_id = ln_po_header_id
                                AND PLA.item_id = ln_po_item_id;

                                SELECT MSI.segment1
                                INTO lc_item_number
                                FROM mtl_system_items MSI
                                WHERE MSI.inventory_item_id = ln_po_item_id
                                AND ROWNUM=1;

                             EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                      lc_err_code := 'ODP_OM_POACK_INVALID_PO_LINE';
                                      FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_PO_LINE');
                                      lc_err_desc := FND_MESSAGE.GET;
                                      lc_entity_ref := 'PO Line Number';
                                      ln_entity_ref_id := NVL(p_po_line_number(j),0);
                                      RAISE EX_LINE_INVALID;
                                WHEN TOO_MANY_ROWS THEN
                                      lc_err_code := 'ODP_OM_POACK_INVALID_PO_LINE';
                                      FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_PO_LINE');
                                      lc_err_desc := FND_MESSAGE.GET;
                                      lc_entity_ref := 'PO Line Number';
                                      ln_entity_ref_id := NVL(p_po_line_number(j),0);
                                      RAISE EX_LINE_INVALID;
                             END;
                             --Check if the incoming line is in OPEN status
                             --if not log the exception in Global exceptions table
                             IF (NVL(lc_closed_code,'OPEN') <> gc_closed_code) THEN
                                lc_err_code := 'ODP_OM_POACK_CLOSED_PO_LINE';
                                FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_CLOSED_PO_LINE');
                                lc_err_desc := FND_MESSAGE.GET;
                                lc_entity_ref := 'PO Line Number';
                                ln_entity_ref_id := NVL(p_po_line_number(j),0);
                                RAISE EX_LINE_INVALID;
                             END IF;
                             --Check if the UPC code are defined in the Item Cross Reference type
                             --if not log the exception in Global exceptions table
                             BEGIN
                                SELECT MCR.cross_reference
                                INTO lc_upc_code
                                FROM mtl_cross_references MCR
                                     ,mtl_cross_reference_types MCRT
                                WHERE MCRT.cross_reference_type = MCR.cross_reference_type
                                AND MCR.cross_reference = p_upc_code(j)
                                AND TRUNC(NVL(MCRT.disable_date,SYSDATE)) >= TRUNC(SYSDATE);
                             EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                     lc_err_code := 'ODP_OM_POACK_INVALID_UPC_CODE';
                                     FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_UPC_CODE');
                                     lc_err_desc := FND_MESSAGE.GET;
                                     lc_entity_ref := 'PO Line Number';
                                     ln_entity_ref_id := NVL(p_po_line_number(j),0);
                                     err_report_type :=                                                    
                                                      xx_om_report_exception_t (                           
                                                                                gc_exp_header              
                                                                                ,gc_track_code             
                                                                                ,gc_sol_domain             
                                                                                ,gc_function               
                                                                                ,lc_err_code               
                                                                                ,SUBSTR(lc_err_desc,1,1000)
                                                                                ,lc_entity_ref             
                                                                                ,ln_entity_ref_id          
                                                                               );                          
                                                                                                           
                                     XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (                         
                                                                                  err_report_type          
                                                                                  ,lc_err_buf              
                                                                                  ,lc_ret_code             
                                                                                 );                        
                                WHEN TOO_MANY_ROWS THEN
                                     lc_err_code := 'ODP_OM_POACK_INVALID_UPC_CODE';
                                     FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_UPC_CODE');
                                     lc_err_desc := FND_MESSAGE.GET;
                                     lc_entity_ref := 'PO Line Number';
                                     ln_entity_ref_id := NVL(p_po_line_number(j),0);
                                     err_report_type :=                                                    
                                                      xx_om_report_exception_t (                           
                                                                                gc_exp_header              
                                                                                ,gc_track_code             
                                                                                ,gc_sol_domain             
                                                                                ,gc_function               
                                                                                ,lc_err_code               
                                                                                ,SUBSTR(lc_err_desc,1,1000)
                                                                                ,lc_entity_ref             
                                                                                ,ln_entity_ref_id          
                                                                               );                          
                                                                                                           
                                     XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (                         
                                                                                  err_report_type          
                                                                                  ,lc_err_buf              
                                                                                  ,lc_ret_code             
                                                                                 );                       

                             END;
                             --Check if the Vendor SKU exists in EBS
                             --if not log the exception in Global exceptions table
                             BEGIN
                                SELECT 'Y'
                                INTO lc_vendor_sku
                                FROM po_approved_supplier_list PASL
                                WHERE PASL.primary_vendor_item = p_vendor_sku(j)
                                AND NVL(PASL.disable_flag,'N')<>'Y'
                                AND   PASL.vendor_id = (
                                                         SELECT PVSA.vendor_id
                                                         FROM PO_VENDOR_SITES_ALL PVSA
                                                         WHERE vendor_site_id = p_po_vendor_site_id(i)
                                                       );
                             EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                     lc_err_code := 'ODP_OM_POACK_INVALID_VEN_SKU';
                                     FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_VEN_SKU');
                                     lc_err_desc := FND_MESSAGE.GET;
                                     lc_entity_ref := 'PO Line Number';
                                     ln_entity_ref_id := NVL(p_po_line_number(j),0);
                                     RAISE EX_LINE_INVALID;
                                WHEN TOO_MANY_ROWS THEN
                                     lc_err_code := 'ODP_OM_POACK_INVALID_VEN_SKU';
                                     FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_VEN_SKU');
                                     lc_err_desc := FND_MESSAGE.GET;
                                     lc_entity_ref := 'PO Line Number';
                                     ln_entity_ref_id := NVL(p_po_line_number(j),0);
                                     RAISE EX_LINE_INVALID;
                             END;

                             --Check if the Ack Code is IR or R2 if yes then
                             --cancel the corresponding PO Line
                             IF (p_ack_code(j) = gc_ack_code_ir 
                                 OR p_ack_code(j) = gc_ack_code_r2) THEN
                                                   CANCEL_POLINES(
                                                                   p_po_number(i)
                                                                   ,p_po_line_number(j)
                                                                   ,lc_cancel_status
                                                                   ,lc_cancel_message
                                                                  );
                             END IF;

                             IF (lc_cancel_status <> gc_success_sts ) THEN
                                RAISE EX_LINE_INVALID;
                             END IF;

                             --Check if the Ack code is IC then build message body for sending notification
                             IF (p_ack_code(j) = gc_ack_code_ic) THEN

                                lc_notf_flag := 'Y';

                                 IF (lc_message_item_text IS NULL) THEN
                                    lc_message_item_text := lc_item_number;
                                 ELSE
                                    lc_message_item_text := lc_message_item_text||', '||lc_item_number;
                                 END IF;

                             END IF;

                             --Call the UPDATE_POACK procedure to update
                             --the PO Lines in the PO_LINE_LOCATIONS_ALL table
                                                UPDATE_POACK(
                                                              ln_po_line_id
                                                              ,p_ack_code(j)
                                                              ,p_shipment_date(j)
                                                              ,lc_update_status
                                                              ,lc_update_message
                                                              );

 
                             IF (lc_update_status <> gc_success_sts) THEN
                                RAISE EX_LINE_INVALID;
                             ELSE
                                COMMIT;
                                x_status := gc_success_sts;
                             END IF;
                             
                       ELSE
                          lc_err_code := 'ODP_OM_POACK_INVALID_PO_LINE';
                          FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_PO_LINE');
                          lc_err_desc := FND_MESSAGE.GET;
                          lc_entity_ref := 'PO Line Number';
                          ln_entity_ref_id := NVL(p_po_line_number(j),0);
                          RAISE EX_LINE_INVALID;
                       END IF;

                    EXCEPTION
                       WHEN EX_LINE_INVALID THEN
                            ROLLBACK;
                            x_status := gc_error_sts;
                            x_message := lc_err_desc;
                            err_report_type :=
                                             xx_om_report_exception_t (
                                                                       gc_exp_header
                                                                       ,gc_track_code
                                                                       ,gc_sol_domain
                                                                       ,gc_function
                                                                       ,lc_err_code
                                                                       ,SUBSTR(lc_err_desc,1,1000)
                                                                       ,lc_entity_ref
                                                                       ,ln_entity_ref_id
                                                                      );

                            XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                                         err_report_type
                                                                         ,lc_err_buf
                                                                         ,lc_ret_code
                                                                        );
                    END;

                 END LOOP;
                 lc_message_text := lc_message_text||'Purchase Order '||p_po_number(i)||' with the items '||lc_message_item_text||' have been requested for changes.'||chr(10)||chr(13);
                 IF (lc_notf_flag = 'Y' 
                     AND lc_role_found = 'N') THEN
                     BEGIN
                        lc_role_found := 'Y';
                        --Fetching the buyer role to send the notification
                        SELECT WLR.name
                        INTO lc_notif_role
                        FROM per_all_people_f PAPF
                             , po_agents PA
                             , fnd_user FU
                             ,wf_local_roles WLR
                             ,po_headers_all PHA
                        WHERE TRUNC(SYSDATE) BETWEEN TRUNC(NVL(PAPF.effective_start_date,SYSDATE)) AND TRUNC(NVL(PAPF.effective_end_date,SYSDATE))
                        AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(PA.start_date_active, SYSDATE)) AND TRUNC(NVL(PA.end_date_active, SYSDATE))
                        AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(FU.start_date, SYSDATE)) AND TRUNC(NVL(FU.end_date, SYSDATE))
                        AND PAPF.person_id = PA.agent_id
                        AND FU.person_party_id = PAPF.party_id
                        AND FU.user_name = WLR.name
                        AND PA.agent_id = PHA.agent_id
                        AND PHA.segment1 = p_po_number(i);
                     EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                          lc_err_code := 'ODP_OM_POACK_NO_ROLE';
                          FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_NO_ROLE');
                          lc_err_desc := FND_MESSAGE.GET;
                          lc_entity_ref := 'PO Number';
                          ln_entity_ref_id := NVL(p_po_number(i),0);
                          err_report_type :=
                                            xx_om_report_exception_t (
                                                                       gc_exp_header
                                                                       ,gc_track_code
                                                                       ,gc_sol_domain
                                                                       ,gc_function
                                                                       ,lc_err_code
                                                                       ,SUBSTR(lc_err_desc,1,1000)
                                                                       ,lc_entity_ref
                                                                       ,ln_entity_ref_id
                                                                      );

                          XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                                        err_report_type
                                                                        ,lc_err_buf
                                                                        ,lc_ret_code
                                                                       );
                                                    
                     END;
                 END IF;
              EXCEPTION
                 WHEN EX_HDR_INVALID THEN
                      x_status := gc_error_sts;
                      x_message := lc_err_desc;
                      err_report_type :=
                                       xx_om_report_exception_t (
                                                                  gc_exp_header
                                                                 ,gc_track_code
                                                                 ,gc_sol_domain
                                                                 ,gc_function
                                                                 ,lc_err_code
                                                                 ,SUBSTR(lc_err_desc,1,1000)
                                                                 ,lc_entity_ref
                                                                 ,ln_entity_ref_id
                                                                );

                      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                                   err_report_type
                                                                   ,lc_err_buf
                                                                   ,lc_ret_code
                                                                  );
              END;
           END LOOP;
           IF (lc_notf_flag = 'Y') THEN
                     ln_nid := WF_NOTIFICATION.SEND(
                                                     role => lc_notif_role
                                                     , msg_type => 'WFMAIL'
                                                     , msg_name => 'O_OPEN_MAIL_FYI'
                                                    );
                     WF_NOTIFICATION.SETATTRTEXT(
                                                  ln_nid
                                                  , 'SUBJECT'
                                                  , 'Change Requests on PO Acknowledgement Messages'
                                                 );
                     WF_NOTIFICATION.SETATTRTEXT(
                                                  ln_nid
                                                  , 'SENDER'
                                                  , lc_vendor_name
                                                  );
                     WF_NOTIFICATION.SETATTRTEXT(
                                                ln_nid
                                                ,'BODY'
                                                ,lc_message_text
                                                );
                     WF_NOTIFICATION.DENORMALIZE_NOTIFICATION(
                                                              ln_nid 
                                                              );
                     COMMIT;
           END IF;
           
   EXCEPTION
   WHEN EX_APPSINIT_FAIL THEN
       ROLLBACK;
       err_report_type :=
             xx_om_report_exception_t (
                                         gc_exp_header
                                        ,gc_track_code
                                        ,gc_sol_domain
                                        ,gc_function
                                        ,lc_err_code
                                        ,SUBSTR(lc_err_desc,1,1000)
                                        ,lc_entity_ref
                                        ,ln_entity_ref_id
                                       );

      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                   err_report_type
                                                   ,lc_err_buf
                                                   ,lc_ret_code
                                                  );

   WHEN OTHERS THEN
        ROLLBACK;
        lc_err_code := SQLCODE;
        lc_err_desc := 'The Error Message is..   '||SQLERRM;
        lc_entity_ref := 'PO Number';
        x_status := gc_error_sts;
        x_message := lc_err_desc;
        err_report_type :=
                        xx_om_report_exception_t (
                                                   gc_exp_header
                                                  ,gc_track_code
                                                  ,gc_sol_domain
                                                  ,gc_function
                                                  ,lc_err_code
                                                  ,SUBSTR(lc_err_desc,1,1000)
                                                  ,lc_entity_ref
                                                  ,NVL(p_po_number(ln_cur_hdr),0)
                                                 );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                     err_report_type
                                                    ,lc_err_buf
                                                    ,lc_ret_code
                                                    );
   END VALIDATE_PROCESS_POACK;
-- +===================================================================+
-- | Name  : UPDATE_POACK                                              |
-- | Description   : This Procedure is used to update Acknowledgement  |
-- |                 for the PO Lines in PO_LINE_LOCATIONS_ALL table   |
-- |                                                                   |
-- | Parameters :       p_po_line_id                                   |
-- |                    p_ack_code                                     |
-- |                    p_shipment_date                                |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_status                                       |
-- |                    x_message                                      |
-- |                                                                   |
-- +===================================================================+
PROCEDURE UPDATE_POACK(
                       p_po_line_id     IN po_lines_all.po_line_id%TYPE
                       ,p_ack_code      IN VARCHAR2
                       ,p_shipment_date IN DATE
                       ,x_status        OUT VARCHAR2
                       ,x_message       OUT VARCHAR2
                       )
IS
   EX_ACK_EXISTS       EXCEPTION;
   EX_LINE_LOC_CLOSED  EXCEPTION;

   err_report_type     xx_om_report_exception_t;

   lc_ack_desc         po_line_locations_all.attribute7%TYPE;
   lc_ack_code         po_line_locations_all.attribute6%TYPE;
   lc_err_code         xx_om_global_exceptions.error_code%TYPE DEFAULT ' ';
   lc_err_desc         xx_om_global_exceptions.description%TYPE DEFAULT ' ';
   lc_entity_ref       xx_om_global_exceptions.entity_ref%TYPE;
   po_line_loc_rec     po_line_locations_all%ROWTYPE;
   lc_err_buf          VARCHAR2(240);
   lc_ret_code         VARCHAR2(30);
   --Cursor created with reelvant records
   --with for UPDATE lock
   CURSOR lcu_po_line (p_po_line_id NUMBER)
   IS
      SELECT *
      FROM PO_LINE_LOCATIONS_ALL
      WHERE po_line_id = p_po_line_id
      FOR UPDATE;
   BEGIN
      lc_ack_code := p_ack_code;
      IF (lc_ack_code <> gc_ack_code_ia 
          AND lc_ack_code <> gc_ack_code_ir 
          AND lc_ack_code <> gc_ack_code_r2 
          AND lc_ack_code <> gc_ack_code_ic) THEN
         lc_ack_code := gc_ack_code_ia;
      END IF;
      BEGIN
         --Fetch the Acknowledgement description from lookup XX_OM_PO_ACK_CODE_LOOKUPS
         SELECT FLV.meaning
         INTO lc_ack_desc
         FROM fnd_lookup_values FLV
         WHERE FLV.lookup_type = gc_lookup_type
         AND FLV.lookup_code = p_ack_code
         AND FLV.enabled_flag = 'Y'
         AND FLV.language = USERENV('LANG');
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
              lc_ack_desc := gc_default_ack;
              lc_err_code := 'ODP_OM_POACK_NO_ACKDESC';
              FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_NO_ACKDESC');
              lc_err_desc := FND_MESSAGE.GET;
              lc_entity_ref := 'PO Line Number';
              x_status := gc_error_sts;
              x_message := lc_err_desc;
              err_report_type :=
                              xx_om_report_exception_t (
                                                        gc_exp_header
                                                        ,gc_track_code
                                                        ,gc_sol_domain
                                                        ,gc_function
                                                        ,lc_err_code
                                                        ,SUBSTR(lc_err_desc,1,1000)
                                                        ,lc_entity_ref
                                                        ,NVL(p_po_line_id,0)
                                                       );
              XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                           err_report_type
                                                           ,lc_err_buf
                                                           ,lc_ret_code
                                                          );
      END;
      --Update the table PO_LINE_LOCATIONS_ALL with the Acknowledgement description
      --and other details such as acknowledgement date,shipment date
      OPEN lcu_po_line (p_po_line_id);
      LOOP
         FETCH lcu_po_line INTO po_line_loc_rec;
         EXIT WHEN lcu_po_line%NOTFOUND;

         IF (po_line_loc_rec.attribute6 IS NOT NULL) THEN
            RAISE EX_ACK_EXISTS;
         END IF;

         IF (po_line_loc_rec.closed_code = gc_line_loc_closed) THEN
            RAISE EX_LINE_LOC_CLOSED;
         END IF;

            UPDATE po_line_locations_all
              SET attribute6 = lc_ack_code
                  ,attribute7 = lc_ack_desc
                  ,attribute8 = SYSDATE
                  ,attribute9 = p_shipment_date
                  ,last_update_date = SYSDATE
                  ,last_update_login = FND_GLOBAL.LOGIN_ID
                  ,last_updated_by = FND_GLOBAL.user_id
              WHERE CURRENT OF lcu_po_line;
      END LOOP;
      CLOSE lcu_po_line;
      x_status := gc_success_sts;
      --COMMIT;
   EXCEPTION
      WHEN EX_ACK_EXISTS THEN
           lc_err_code := 'ODP_OM_POACK_ACK_EXIST';
           FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_ACK_EXIST');
           lc_err_desc := FND_MESSAGE.GET;
           x_status := gc_error_sts;
           x_message := lc_err_desc;
           lc_entity_ref := 'PO Line Number';
           err_report_type :=
                           xx_om_report_exception_t (
                                                      gc_exp_header
                                                     ,gc_track_code
                                                     ,gc_sol_domain
                                                     ,gc_function
                                                     ,lc_err_code
                                                     ,SUBSTR(lc_err_desc,1,1000)
                                                     ,lc_entity_ref
                                                     ,NVL(p_po_line_id,0)
                                                    );
           XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                        err_report_type
                                                       ,lc_err_buf
                                                       ,lc_ret_code
                                                       );
      WHEN EX_LINE_LOC_CLOSED THEN
           lc_err_code := 'ODP_OM_POACK_LINE_LOC_CLOSED';
           FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_LINE_LOC_CLOSED');
           lc_err_desc := FND_MESSAGE.GET;
           x_status := gc_error_sts;
           x_message := lc_err_desc;
           lc_entity_ref := 'PO Line Number';
           err_report_type :=
                           xx_om_report_exception_t (
                                                      gc_exp_header
                                                     ,gc_track_code
                                                     ,gc_sol_domain
                                                     ,gc_function
                                                     ,lc_err_code
                                                     ,SUBSTR(lc_err_desc,1,1000)
                                                     ,lc_entity_ref
                                                     ,NVL(p_po_line_id,0)
                                                    );
           XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                        err_report_type
                                                       ,lc_err_buf
                                                       ,lc_ret_code
                                                       );
      WHEN OTHERS THEN
           lc_err_code := 'ODP_OM_POACK_UPD_FAILED';
           FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_UPD_FAILED');
           lc_err_desc := FND_MESSAGE.GET;
           lc_err_desc := lc_err_desc||' The Error Message is '||SQLERRM;
           lc_entity_ref := 'PO Line Number';
           x_status := gc_error_sts;
           x_message := lc_err_desc;
           err_report_type :=
                           xx_om_report_exception_t (
                                                      gc_exp_header
                                                     ,gc_track_code
                                                     ,gc_sol_domain
                                                     ,gc_function
                                                     ,lc_err_code
                                                     ,SUBSTR(lc_err_desc,1,1000)
                                                     ,lc_entity_ref
                                                     ,NVL(p_po_line_id,0)
                                                    );
           XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                        err_report_type
                                                        ,lc_err_buf
                                                        ,lc_ret_code
                                                       );
   END UPDATE_POACK;
-- +===================================================================+
-- | Name  : CANCEL_POLINES                                            |
-- | Description   : This Procedure is used cancel those PO Lines      |
-- |                 which had acknowledgement as Rejected             |
-- |                                                                   |
-- | Parameters :       p_po_line_id                                   |
-- |                    p_ack_code                                     |
-- |                    p_shipment_date                                |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_status                                       |
-- |                    x_message                                      |
-- |                                                                   |
-- +===================================================================+
PROCEDURE CANCEL_POLINES(
                          p_po_number    IN po_headers_all.segment1%TYPE
                         ,p_po_line_num IN po_lines_all.line_num%TYPE
                         ,x_status      OUT VARCHAR2
                         ,x_message     OUT VARCHAR2
                         )
IS
   err_report_type      xx_om_report_exception_t;
   lc_doc_subtype       po_document_types_all.document_subtype%TYPE;
   lc_err_code          xx_om_global_exceptions.error_code%TYPE DEFAULT ' ';
   lc_err_desc          xx_om_global_exceptions.description%TYPE DEFAULT ' ';
   lc_entity_ref        xx_om_global_exceptions.entity_ref%TYPE;
   ln_po_line_id        po_lines_all.po_line_id%TYPE;
   ln_po_header_id      po_headers_all.po_header_id%TYPE;
   lc_return_status     VARCHAR2(100);
   lc_err_buf           VARCHAR2(240);
   lc_ret_code          VARCHAR2(30);
   BEGIN
      BEGIN
         --Fetching mandatory parameters for PO_DOCUMENT_CONTROL_PUB.CONTROL_DOCUMENT API Call
         SELECT PLA.po_line_id
               ,PDTA.document_subtype
               ,PHA.po_header_id
         INTO ln_po_line_id
             ,lc_doc_subtype
             ,ln_po_header_id
         FROM po_lines_all PLA
             ,po_headers_all PHA
             ,po_document_types_all PDTA
         WHERE PHA.segment1 = p_po_number
         AND PLA.line_num = p_po_line_num
         AND PLA.po_header_id = PHA.po_header_id
         AND PDTA.document_subtype = PHA.type_lookup_code
         AND PHA.org_id = PDTA.org_id
         AND PDTA.document_type_code = gc_doc_type_code;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
              lc_err_code := 'ODP_OM_POACK_POCANCEL_FAILED';
              FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_POCANCEL_FAILED');
              lc_err_desc := FND_MESSAGE.GET;
              lc_entity_ref := 'PO Line Number';
              x_status := gc_error_sts;
              x_message := lc_err_desc;
              err_report_type :=
                              xx_om_report_exception_t (
                                                         gc_exp_header
                                                        ,gc_track_code
                                                        ,gc_sol_domain
                                                        ,gc_function
                                                        ,lc_err_code
                                                        ,SUBSTR(lc_err_desc,1,1000)
                                                        ,lc_entity_ref
                                                        ,NVL(ln_po_line_id,0)
                                                       );
              XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                           err_report_type
                                                           ,lc_err_buf
                                                           ,lc_ret_code
                                                          );
      END;
      --Call the PO_DOCUMENT_CONTROL_PUB.CONTROL_DOCUMENT API to Cancel PO Lines
      PO_DOCUMENT_CONTROL_PUB.CONTROL_DOCUMENT(
                                                p_api_version                   => 1.0
                                               ,p_init_msg_list                => FND_API.G_TRUE
                                               ,p_commit                       => FND_API.G_TRUE
                                               ,x_return_status                => lc_return_status
                                               ,p_doc_type                     => gc_doc_type_code
                                               ,p_doc_subtype                  => lc_doc_subtype
                                               ,p_doc_id                       => ln_po_header_id
                                               ,p_doc_num                      => NULL
                                               ,p_release_id                   => NULL
                                               ,p_release_num                  => NULL
                                               ,p_doc_line_id                  => ln_po_line_id
                                               ,p_doc_line_num                 => NULL
                                               ,p_doc_line_loc_id              => NULL
                                               ,p_doc_shipment_num             => NULL
                                               ,p_action                       => gc_api_action
                                               ,p_action_date                  => SYSDATE
                                               ,p_cancel_reason                => NULL
                                               ,p_cancel_reqs_flag             => 'Y'
                                               ,p_print_flag                   => NULL
                                               ,p_note_to_vendor               => NULL
                                               ,p_use_gldate                   => NULL
                                               );
      IF (lc_return_status <> 'S') THEN
         lc_err_code := 'ODP_OM_POACK_POCANCEL_FAILED';
         IF (FND_MSG_PUB.COUNT_MSG > 0) THEN
            FOR i IN 1..FND_MSG_PUB.COUNT_MSG
            LOOP
               lc_err_desc := lc_err_desc || '  ' || FND_MSG_PUB.GET(
                                                                     p_msg_index => i
                                                                     ,p_encoded  => 'F'
                                                                     );
            END LOOP;
         END IF;
         lc_entity_ref := 'PO Line Number';
         x_status := gc_error_sts;
         x_message := lc_err_desc;
         err_report_type :=
                           xx_om_report_exception_t (
                                                      gc_exp_header
                                                     ,gc_track_code
                                                     ,gc_sol_domain
                                                     ,gc_function
                                                     ,lc_err_code
                                                     ,SUBSTR(lc_err_desc,1,1000)
                                                     ,lc_entity_ref
                                                     ,NVL(ln_po_line_id,0)
                                                    );
         XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                      err_report_type
                                                     ,lc_err_buf
                                                     ,lc_ret_code
                                                     );
      ELSE
         x_status := gc_success_sts;
      END IF;
      
   EXCEPTION
      WHEN OTHERS THEN
           lc_err_code := 'ODP_OM_POACK_POCANCEL_FAILED';
           FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_POCANCEL_FAILED');
           lc_err_desc := FND_MESSAGE.GET;
           lc_err_desc := lc_err_desc||' The Error Message is '||SQLERRM;
           lc_entity_ref := 'PO Line Number';
           x_status := gc_error_sts;
           x_message := lc_err_desc;
           err_report_type :=
                           xx_om_report_exception_t (
                                                      gc_exp_header
                                                     ,gc_track_code
                                                     ,gc_sol_domain
                                                     ,gc_function
                                                     ,lc_err_code
                                                     ,SUBSTR(lc_err_desc,1,1000)
                                                     ,lc_entity_ref
                                                     ,NVL(ln_po_line_id,0)
                                                    );
           XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                        err_report_type
                                                       ,lc_err_buf
                                                       ,lc_ret_code
                                                       );
   END CANCEL_POLINES;

  -- +===================================================================+
  -- | Name  : APPS_INIT                                                 |
  -- | Description   : This Procedure will be used to initialise the Apps|
  -- |                                                                   |
  -- | Parameters :       p_user_name                                    |
  -- |                    p_resp_name                                    |
  -- |                                                                   |
  -- | Returns :          x_return_status                                |
  -- |                    x_message                                      |
  -- |                                                                   |
  -- +===================================================================+


   PROCEDURE APPS_INIT(
                        p_user_name IN  VARCHAR2
                       ,p_resp_name IN  VARCHAR2
                       ,x_status    OUT VARCHAR2
                       ,x_message   OUT VARCHAR2
                      )
   AS

        ln_responsibility_id       fnd_responsibility_tl.responsibility_id%TYPE;
        ln_application_id          fnd_responsibility_tl.application_id%TYPE;
        ln_user_id                 fnd_user.user_id%TYPE;

        BEGIN
                x_status := gc_success_sts;
                x_message := 'Success';

                -- Apps Initialization

                FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_RESP_NAME');
                x_message := FND_MESSAGE.GET;

                SELECT FRT.responsibility_id
                      ,FRT.application_id
                INTO  ln_responsibility_id
                      ,ln_application_id
                FROM  fnd_responsibility_tl FRT
                WHERE FRT.responsibility_name = p_resp_name
                AND FRT.language = USERENV('LANG');

                FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_USER_NAME');
                x_message := FND_MESSAGE.GET;

                SELECT user_id
                INTO ln_user_id
                FROM fnd_user
                WHERE user_name = p_user_name;

                FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_APPSINT_FAILED');
                x_message := FND_MESSAGE.GET;
                FND_GLOBAL.APPS_INITIALIZE (
                                             ln_user_id
                                            ,ln_responsibility_id
                                            ,ln_application_id
                                           );
                x_message := 'Successfully initialized Apps';

        EXCEPTION
                WHEN OTHERS THEN
                    x_status := gc_error_sts;
     END APPS_INIT;

END XX_OM_POACKINTF_PKG;

/
SHOW ERROR