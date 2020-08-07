SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_OM_POACK_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name  :  XX_OM_POACKINTERFACE_PKG                                 |
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
-- |DRAFT 1A              Aravind A.        Initial draft version      |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
AS
-- +===================================================================+
-- | Following are the Global parameters that are used                 |
-- | across this package                                               |
-- +===================================================================+
gc_po_status        PO_HEADERS_ALL.authorization_status%TYPE DEFAULT 'APPROVED';
gc_closed_code      PO_LINES_ALL.closed_code%TYPE            DEFAULT 'OPEN';
gc_lookup_type      FND_LOOKUP_VALUES.lookup_type%TYPE           DEFAULT 'XX_OM_PO_ACK_CODE_LOOKUPS';
gc_default_ack      VARCHAR2(100)                                DEFAULT 'Accept';
gc_ack_code_ir      VARCHAR2(2)                                  DEFAULT 'IR';
gc_ack_code_r2      VARCHAR2(2)                                  DEFAULT 'R2';
gc_ack_code_ic      VARCHAR2(2)                                  DEFAULT 'IC';
gc_doc_type_code    PO_DOCUMENT_TYPES_ALL.document_type_code%TYPE DEFAULT 'PO';
gc_api_action       VARCHAR2(30)                                  DEFAULT 'CANCEL';
gc_exp_header       XX_OM_GLOBAL_EXCEPTIONS.exception_header%TYPE   DEFAULT  'OTHERS';
gc_track_code       XX_OM_GLOBAL_EXCEPTIONS.track_code%TYPE         DEFAULT  'OTC';
gc_sol_domain       XX_OM_GLOBAL_EXCEPTIONS.solution_domain%TYPE    DEFAULT  'Internal Fulfillment';
gc_function         XX_OM_GLOBAL_EXCEPTIONS.function_name%TYPE      DEFAULT  'I0265_POAck';
gc_success_sts      VARCHAR2(1)                                     DEFAULT 'S';
gc_error_sts        VARCHAR2(1)                                     DEFAULT 'E';
gc_email_id         VARCHAR2(240)                                   DEFAULT 'mohan.suryaprakash@officedepot.com';
gn_sql_point        NUMBER                                          DEFAULT 0;
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
-- |                    returned to BPEL by this procedure             |
-- |                                                                   |
-- |                    x_po_vendor_site_id                            |
-- |                    x_po_number                                    |
-- |                    x_transaction_date                             |
-- |                    x_sales_order                                  |
-- |                    x_po_line_number                               |
-- |                    x_vendor_sku                                   |
-- |                    x_item_number                                  |
-- |                    x_upc_code                                     |
-- |                    x_shipment_date                                |
-- |                    x_ack_code                                     |
-- |                    x_email_address                                |
-- |                    x_status                                       |
-- |                    x_message                                      |
-- |                                                                   |
-- +===================================================================+
PROCEDURE VALIDATE_PROCESS_POACK(p_po_vendor_site_id     IN      po_vendor_site_id_tbl_type
                                 ,p_po_number            IN      po_segment1_tbl_type
                                 ,p_ref_po_number        IN      po_segment1_tbl_type
                                 ,p_transaction_date     IN      po_creation_date_tbl_type
                                 ,p_sales_order          IN      po_order_num_tbl_type
                                 ,p_po_line_number       IN      po_line_num_tbl_type
                                 ,p_vendor_sku           IN      po_vendor_sku_tbl_type
                                 ,p_item_number          IN      po_item_id_tbl_type
                                 ,p_upc_code             IN      po_upc_code_tbl_type
                                 ,p_shipment_date        IN      po_shipment_date_tbl_type
                                 ,p_ack_code             IN      po_ack_code_tbl_type
                                 ,x_po_vendor_site_id    OUT     po_vendor_site_id_tbl_type
                                 ,x_po_number            OUT     po_segment1_tbl_type
                                 ,x_transaction_date     OUT     po_creation_date_tbl_type
                                 ,x_sales_order          OUT     po_order_num_tbl_type
                                 ,x_po_line_number       OUT     po_line_num_tbl_type
                                 ,x_vendor_sku           OUT     po_vendor_sku_tbl_type
                                 ,x_item_number          OUT     po_item_id_tbl_type
                                 ,x_upc_code             OUT     po_upc_code_tbl_type
                                 ,x_shipment_date        OUT     po_shipment_date_tbl_type
                                 ,x_ack_code             OUT     po_ack_code_tbl_type
                                 ,x_email_address        OUT     po_email_address_tbl_type
                                 ,x_status               OUT     VARCHAR2
                                 ,x_message              OUT     VARCHAR2)
IS
   EX_HDR_INVALID      EXCEPTION;           --Exception variable for invalid Header
   EX_LINE_INVALID     EXCEPTION;           --Exception variable for invalid Line
   err_report_type     XX_OM_REPORT_EXCEPTION_T;
   lc_po_auth_status   PO_HEADERS_ALL.authorization_status%TYPE;
   lc_attrib_cat       PO_HEADERS_ALL.attribute_category%TYPE;
   lc_upc_code         MTL_CROSS_REFERENCES.cross_reference%TYPE;
   lc_closed_code      PO_LINES_ALL.closed_code%TYPE;
   lc_dropship_value   FND_FLEX_VALUES.flex_value%TYPE;
   lc_btob_value       FND_FLEX_VALUES.flex_value%TYPE;
   lc_err_code         xxom.XX_OM_GLOBAL_EXCEPTIONS.error_code%TYPE DEFAULT ' ';
   lc_err_desc         xxom.XX_OM_GLOBAL_EXCEPTIONS.description%TYPE DEFAULT ' ';
   lc_entity_ref       xxom.XX_OM_GLOBAL_EXCEPTIONS.entity_ref%TYPE;
   lc_vendor_sku       PO_ASL_SUPPLIERS_V.primary_vendor_item%TYPE;
   lc_attrib_cat_flag  VARCHAR2(1);
   ln_po_header_id     PO_LINES_ALL.po_header_id%TYPE;
   ln_po_item_id       PO_LINES_ALL.item_id%TYPE;
   ln_value_set_id     FND_FLEX_VALUE_SETS.flex_value_set_id%TYPE;
   ln_po_line_id       PO_LINES_ALL.po_line_id%TYPE;
   ln_vendor_site_id   PO_HEADERS_ALL.vendor_site_id%TYPE;
   ln_cur_hdr          PLS_INTEGER  DEFAULT 0;
   ln_entity_ref_id    xxom.XX_OM_GLOBAL_EXCEPTIONS.entity_ref_id%TYPE;
   x_update_status     VARCHAR2(100);
   x_update_message    VARCHAR2(400);
   x_init_status       VARCHAR2(100);
   x_init_message      VARCHAR2(400);
   x_cancel_status     VARCHAR2(100);
   x_cancel_message    VARCHAR2(400);
   x_err_buf           VARCHAR2(100);
   x_ret_code          VARCHAR2(100);
   BEGIN
        --Apps Initialization
        gn_sql_point := 100;
        
           --Loop through the number of PO Headers(derived from attribute COUNT)
           --and perform Header level validations
           FOR i IN 1..p_po_number.COUNT
           LOOP
              ln_cur_hdr := i;
              BEGIN
                 BEGIN
                    --Fetch authorization_status,attribute_category and vendor_site_id
                    --from PO_HEADERS_ALL table passing the segment1 value
                    gn_sql_point := 110;
                    SELECT PHA.authorization_status
                           ,PHA.vendor_site_id
                           ,PHA.po_header_id
                         INTO lc_po_auth_status
                              ,ln_vendor_site_id
                              ,ln_po_header_id
                         FROM PO_HEADERS_ALL PHA
                         WHERE PHA.segment1 = p_po_number(i);
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
                         RAISE EX_HDR_INVALID;
                 END;
                 --Check if the authorisation_status is APPROVED
                 --if not log the exception in Global exceptions table
                 IF (lc_po_auth_status <> gc_po_status) THEN
                    gn_sql_point := 120;
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
                    gn_sql_point := 130;
                    lc_err_code := 'ODP_OM_POACK_INVALID_VENSITEID';
                    FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_VENSITEID');
                    lc_err_desc := FND_MESSAGE.GET;
                    lc_entity_ref := 'Vendor Site ID';
                    ln_entity_ref_id := NVL(p_po_vendor_site_id(i),0);
                    RAISE EX_HDR_INVALID;
                 END IF;
                 --Loop through the PO lines and perform line level validations
                 gn_sql_point := 140;
                 FOR j IN 1..p_po_line_number.COUNT
                 LOOP
                    IF (p_ref_po_number(j) = p_po_number(i)) THEN
                       BEGIN
                          gn_sql_point := 150;
                             IF (p_item_number(j) IS NOT NULL) THEN
                                BEGIN
                                   SELECT PLA.item_id
                                       INTO ln_po_item_id
                                       FROM PO_SHIPMENTS_ALL_V PSAV
                                            ,PO_LINES_ALL PLA
                                       WHERE PSAV.po_line_id = PLA.po_line_id
                                          AND PLA.item_id = p_item_number(j)
                                          AND PLA.line_num = p_po_line_number(j);
                                EXCEPTION
                                   WHEN NO_DATA_FOUND THEN
                                        lc_err_code := 'ODP_OM_POACK_INVALID_ITEM';
                                        FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_ITEM');
                                        lc_err_desc := FND_MESSAGE.GET;
                                        lc_entity_ref := 'PO Number';
                                        ln_entity_ref_id := NVL(p_po_number(i),0);
                                        RAISE EX_LINE_INVALID;
                                   WHEN TOO_MANY_ROWS THEN
                                        RAISE EX_LINE_INVALID;
                                END;
                             ELSIF (p_vendor_sku(j) IS NOT NULL AND ln_po_item_id IS NULL) THEN
                                BEGIN
                                   SELECT PASL.item_id
                                       INTO ln_po_item_id
                                       FROM PO_APPROVED_SUPPLIER_LIST PASL
                                       WHERE PASL.primary_vendor_item = p_vendor_sku(j)
                                           AND PASL.vendor_id = (SELECT vendor_id
                                                                     FROM PO_VENDOR_SITES_ALL
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
                                        RAISE EX_LINE_INVALID;
                                END;
                             ELSIF (p_upc_code(j) IS NOT NULL AND ln_po_item_id IS NULL) THEN
                                BEGIN
                                   SELECT inventory_item_id
                                       INTO ln_po_item_id
                                       FROM MTL_CROSS_REFERENCES MCR
                                       WHERE MCR.cross_reference = p_upc_code(j);
                                EXCEPTION
                                   WHEN NO_DATA_FOUND THEN
                                        lc_err_code := 'ODP_OM_POACK_INVALID_UPC_CODE';
                                        FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_UPC_CODE');
                                        lc_err_desc := FND_MESSAGE.GET;
                                        lc_entity_ref := 'PO Number';
                                        ln_entity_ref_id := NVL(p_po_number(i),0);
                                        RAISE EX_LINE_INVALID;
                                   WHEN TOO_MANY_ROWS THEN
                                        RAISE EX_LINE_INVALID;
                                END;
                             END IF;

                          BEGIN
                             SELECT PLA.closed_code
                                    ,PLA.po_line_id
                                  INTO lc_closed_code
                                       ,ln_po_line_id
                                  FROM PO_LINES_ALL PLA
                                  WHERE PLA.line_num = p_po_line_number(j)
                                       AND PLA.po_header_id = ln_po_header_id
                                       AND PLA.item_id = ln_po_item_id;
                          EXCEPTION
                             WHEN NO_DATA_FOUND THEN
                                   lc_err_code := 'ODP_OM_POACK_INVALID_PO_LINE';
                                   FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_PO_LINE');
                                   lc_err_desc := FND_MESSAGE.GET;
                                   lc_entity_ref := 'PO Line Number';
                                   ln_entity_ref_id := NVL(p_po_line_number(j),0);
                                  RAISE EX_LINE_INVALID;
                          END;
                          --Check if the incoming line is in OPEN status
                          --if not log the exception in Global exceptions table
                          IF (lc_closed_code <> gc_closed_code) THEN
                             lc_err_code := 'ODP_OM_POACK_CLOSED_PO_LINE';
                             FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_CLOSED_PO_LINE');
                             lc_err_desc := FND_MESSAGE.GET;
                             lc_entity_ref := 'PO Line Number';
                             ln_entity_ref_id := NVL(p_po_line_number(j),0);
                             RAISE EX_LINE_INVALID;
                          END IF;
                          --Check if the UPC code are defined in the Item Cross Reference type
                          --if not log the exception in Global exceptions table
                          gn_sql_point := 160;
                          BEGIN
                             SELECT MCR.cross_reference
                                  INTO lc_upc_code
                                  FROM MTL_CROSS_REFERENCES MCR
                                  WHERE MCR.cross_reference = p_upc_code(j);
                          EXCEPTION
                             WHEN NO_DATA_FOUND THEN
                                  lc_err_code := 'ODP_OM_POACK_INVALID_UPC_CODE';
                                  FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_UPC_CODE');
                                  lc_err_desc := FND_MESSAGE.GET;
                                  lc_entity_ref := 'PO UPC Code';
                                  ln_entity_ref_id := NVL(p_upc_code(j),0);
                                  RAISE EX_LINE_INVALID;
                          END;
                          --Check if the Vendor SKU exists in EBS
                          --if not log the exception in Global exceptions table
                          gn_sql_point := 170;
                          BEGIN
                             SELECT 'Y'
                                  INTO lc_vendor_sku
                                  FROM PO_APPROVED_SUPPLIER_LIST PASL
                                  WHERE PASL.primary_vendor_item = p_vendor_sku(j)
                                       AND   PASL.vendor_id = (SELECT vendor_id
                                                                     FROM PO_VENDOR_SITES_ALL
                                                                     WHERE vendor_site_id = p_po_vendor_site_id(i)
                                                               );
                          EXCEPTION
                             WHEN NO_DATA_FOUND THEN
                                  lc_err_code := 'ODP_OM_POACK_INVALID_VEN_SKU';
                                  FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_INVALID_VEN_SKU');
                                  lc_err_desc := FND_MESSAGE.GET;
                                  lc_entity_ref := 'PO Vendor SKU';
                                  ln_entity_ref_id := NVL(p_vendor_sku(j),0);
                                  RAISE EX_LINE_INVALID;
                             WHEN TOO_MANY_ROWS THEN
                                  RAISE EX_LINE_INVALID;
                          END;
                          --Call the UPDATE_POACK procedure to update
                          --the PO Lines in the PO_LINE_LOCATIONS_ALL table
                          gn_sql_point := 180;
                          XX_OM_POACK_PKG.UPDATE_POACK(ln_po_line_id
                                                        ,p_ack_code(j)
                                                        ,p_shipment_date(j)
                                                        ,x_update_status
                                                        ,x_update_message
                                                        );
                          --Check if the Ack Code is IR or R2 if yes then
                          --cancel the corresponding PO Line
                          IF (p_ack_code(j) = gc_ack_code_ir OR p_ack_code(j) = gc_ack_code_r2) THEN
                             gn_sql_point := 190;
                             XX_OM_POACK_PKG.CANCEL_POLINES(p_po_number(i)
                                                             ,p_po_line_number(j)
                                                             ,x_cancel_status
                                                             ,x_cancel_message
                                                             );
                          END IF;
                          --Check if the Ack code is IC then return those lines to BPEL
                          --with other information like email-address for BPEL to send notifications
                          IF (p_ack_code(j) = gc_ack_code_ic) THEN
                             gn_sql_point := 200;
                             x_po_vendor_site_id(i) := p_po_vendor_site_id(i);
                             x_po_number(i)         := p_po_number(i);
                             x_transaction_date(i)  := p_transaction_date(i);
                             x_sales_order(i)       := p_sales_order(i);
                             x_po_line_number(j)    := p_po_line_number(j);
                             x_vendor_sku(j)        := p_vendor_sku(j);
                             x_item_number(j)       := p_item_number(j);
                             x_upc_code(j)          := p_upc_code(j);
                             x_shipment_date(j)     := p_shipment_date(j);
                             x_ack_code(j)          := p_ack_code(j);
                             x_email_address(j)     := gc_email_id;
                          END IF;

                          x_status := gc_success_sts;
                       EXCEPTION
                          WHEN EX_LINE_INVALID THEN
                               x_status := gc_error_sts;
                               x_message := lc_err_desc;
                               err_report_type :=
                                                xx_om_report_exception_t (gc_exp_header
                                                                          ,gc_track_code
                                                                          ,gc_sol_domain
                                                                          ,gc_function
                                                                          ,lc_err_code
                                                                          ,lc_err_desc
                                                                          ,lc_entity_ref
                                                                          ,ln_entity_ref_id
                                                                         );

                               XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (err_report_type
                                                                   ,x_err_buf
                                                                   ,x_ret_code
                                                                   );
                       END;
                    END IF;
                 END LOOP;
              EXCEPTION
                 WHEN EX_HDR_INVALID THEN
                      x_status := gc_error_sts;
                      x_message := lc_err_desc;
                      err_report_type :=
                                       xx_om_report_exception_t (gc_exp_header
                                                                 ,gc_track_code
                                                                 ,gc_sol_domain
                                                                 ,gc_function
                                                                 ,lc_err_code
                                                                 ,lc_err_desc
                                                                 ,lc_entity_ref
                                                                 ,ln_entity_ref_id
                                                                );

                      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (err_report_type
                                                                   ,x_err_buf
                                                                   ,x_ret_code
                                                                   );
              END;
           END LOOP;
        
   EXCEPTION
   WHEN OTHERS THEN
        lc_err_code := '0034';
        lc_err_desc := 'Error occured at..'||gn_sql_point||'The Error Message is..   '||SQLERRM;
        lc_entity_ref := 'PO Line Number';
        x_status := gc_error_sts;
        x_message := lc_err_desc;
        err_report_type :=
                        xx_om_report_exception_t (gc_exp_header
                                               ,gc_track_code
                                               ,gc_sol_domain
                                               ,gc_function
                                               ,lc_err_code
                                               ,lc_err_desc
                                               ,lc_entity_ref
                                               ,NVL(p_po_number(ln_cur_hdr),0)
                                              );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (err_report_type
                                                    ,x_err_buf
                                                    ,x_ret_code
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
PROCEDURE UPDATE_POACK(p_po_line_id     IN PO_LINES_ALL.po_line_id%TYPE
                       ,p_ack_code      IN VARCHAR2
                       ,p_shipment_date IN DATE
                       ,x_status        OUT VARCHAR2
                       ,x_message       OUT VARCHAR2)
IS
   err_report_type     XX_OM_REPORT_EXCEPTION_T;
   lc_ack_desc         PO_LINE_LOCATIONS_ALL.attribute7%TYPE;
   lc_err_code         XX_OM_GLOBAL_EXCEPTIONS.error_code%TYPE DEFAULT ' ';
   lc_err_desc         XX_OM_GLOBAL_EXCEPTIONS.description%TYPE DEFAULT ' ';
   lc_entity_ref       XX_OM_GLOBAL_EXCEPTIONS.entity_ref%TYPE;
   po_line_loc_rec     PO_LINE_LOCATIONS_ALL%ROWTYPE;
   x_err_buf           VARCHAR2(1000);
   x_ret_code          VARCHAR2(100);
   --Cursor created with reelvant records
   --with for UPDATE lock
   CURSOR lcu_po_line (p_po_line_id NUMBER)
   IS
      SELECT *
           FROM PO_LINE_LOCATIONS_ALL
           WHERE po_line_id = p_po_line_id
           FOR UPDATE;
   BEGIN
      BEGIN
         --Fetch the Acknowledgement description from lookup XX_OM_PO_ACK_CODE_LOOKUPS
         SELECT FLV.meaning
              INTO lc_ack_desc
              FROM FND_LOOKUP_VALUES FLV
              WHERE FLV.lookup_type = gc_lookup_type
                  AND FLV.lookup_code = p_ack_code
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
                              xx_om_report_exception_t (gc_exp_header
                                                        ,gc_track_code
                                                        ,gc_sol_domain
                                                        ,gc_function
                                                        ,lc_err_code
                                                        ,lc_err_desc
                                                        ,lc_entity_ref
                                                        ,NVL(p_po_line_id,0)
                                                       );
              XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (err_report_type
                                                          ,x_err_buf
                                                          ,x_ret_code
                                                          );
      END;
      --Update the table PO_LINE_LOCATIONS_ALL with the Acknowledgement description
      --and other details such as acknowledgement date,shipment date
      OPEN lcu_po_line (p_po_line_id);
      LOOP
         FETCH lcu_po_line INTO po_line_loc_rec;
         EXIT WHEN lcu_po_line%NOTFOUND;
            UPDATE PO_LINE_LOCATIONS_ALL
                 SET attribute6 = p_ack_code
                     ,attribute7 = lc_ack_desc
                     ,attribute8 = SYSDATE
                     ,attribute9 = p_shipment_date
                     ,last_update_date = SYSDATE
                     ,last_update_login = FND_GLOBAL.LOGIN_ID
                     ,last_updated_by = FND_GLOBAL.user_id
                 WHERE CURRENT OF lcu_po_line;
      END LOOP;
      CLOSE lcu_po_line;
      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
           lc_err_code := 'ODP_OM_POACK_UPD_FAILED';
           FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_POACK_UPD_FAILED');
           lc_err_desc := FND_MESSAGE.GET;
           lc_err_desc := lc_err_desc||' The Error Message is '||SQLERRM;
           lc_entity_ref := 'PO Line Number';
           x_status := gc_error_sts;
           x_message := lc_err_desc;
           err_report_type :=
                           xx_om_report_exception_t (gc_exp_header
                                                     ,gc_track_code
                                                     ,gc_sol_domain
                                                     ,gc_function
                                                     ,lc_err_code
                                                     ,lc_err_desc
                                                     ,lc_entity_ref
                                                     ,NVL(p_po_line_id,0)
                                                    );
           XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (err_report_type
                                                       ,x_err_buf
                                                       ,x_ret_code
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
PROCEDURE CANCEL_POLINES(p_po_number    IN PO_HEADERS_ALL.segment1%TYPE
                         ,p_po_line_num IN PO_LINES_ALL.line_num%TYPE
                         ,x_status      OUT VARCHAR2
                         ,x_message     OUT VARCHAR2)
IS
   err_report_type     XX_OM_REPORT_EXCEPTION_T;
   lc_doc_subtype       PO_DOCUMENT_TYPES_ALL.document_subtype%TYPE;
   lc_err_code          XX_OM_GLOBAL_EXCEPTIONS.error_code%TYPE DEFAULT ' ';
   lc_err_desc          XX_OM_GLOBAL_EXCEPTIONS.description%TYPE DEFAULT ' ';
   lc_entity_ref        XX_OM_GLOBAL_EXCEPTIONS.entity_ref%TYPE;
   ln_po_line_id        PO_LINES_ALL.po_line_id%TYPE;
   ln_po_header_id      PO_HEADERS_ALL.po_header_id%TYPE;
   x_return_status      VARCHAR2(100);
   x_err_buf            VARCHAR2(1000);
   x_ret_code           VARCHAR2(100);
   BEGIN
      BEGIN
         --Fetching mandatory parameters for PO_DOCUMENT_CONTROL_PUB.CONTROL_DOCUMENT API Call
         SELECT PLA.po_line_id
               ,PDTA.document_subtype
               ,PHA.po_header_id
              INTO ln_po_line_id
                   ,lc_doc_subtype
                   ,ln_po_header_id
              FROM PO_LINES_ALL PLA
                   ,PO_HEADERS_ALL PHA
                   ,PO_DOCUMENT_TYPES_ALL PDTA
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
                              xx_om_report_exception_t (gc_exp_header
                                                        ,gc_track_code
                                                        ,gc_sol_domain
                                                        ,gc_function
                                                        ,lc_err_code
                                                        ,lc_err_desc
                                                        ,lc_entity_ref
                                                        ,NVL(ln_po_line_id,0)
                                                       );
              XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (err_report_type
                                                          ,x_err_buf
                                                          ,x_ret_code
                                                          );
      END;
      --Call the PO_DOCUMENT_CONTROL_PUB.CONTROL_DOCUMENT API to Cancel PO Lines
      PO_DOCUMENT_CONTROL_PUB.CONTROL_DOCUMENT(p_api_version                   => 1.0
                                               ,p_init_msg_list                => fnd_api.g_true
                                               ,p_commit                       => fnd_api.g_true
                                               ,x_return_status                => x_return_status
                                               ,p_doc_type                     => gc_doc_type_code
                                               ,p_doc_subtype                  => lc_doc_subtype
                                               ,p_doc_id                       => ln_po_header_id
                                               ,p_doc_num                      => null
                                               ,p_release_id                   => null
                                               ,p_release_num                  => null
                                               ,p_doc_line_id                  => ln_po_line_id
                                               ,p_doc_line_num                 => null
                                               ,p_doc_line_loc_id              => null
                                               ,p_doc_shipment_num             => null
                                               ,p_action                       => gc_api_action
                                               ,p_action_date                  => SYSDATE
                                               ,p_cancel_reason                => null
                                               ,p_cancel_reqs_flag             => 'N'
                                               ,p_print_flag                   => null
                                               ,p_note_to_vendor               => null
                                               ,p_use_gldate                   => null
                                               );
      IF (x_return_status <> 'S') THEN
         lc_err_code := 'ODP_OM_POACK_POCANCEL_FAILED';
         IF FND_MSG_PUB.count_msg > 0 THEN
            FOR i IN 1..FND_MSG_PUB.count_msg
            LOOP
               lc_err_desc := lc_err_desc || '  ' || FND_MSG_PUB.GET( p_msg_index => i
                                                                     ,p_encoded  => 'F'
                                                                     ); 
            END LOOP;		   
         END IF;
         lc_entity_ref := 'PO Line Number';
         x_status := gc_error_sts;
         x_message := lc_err_desc;
         err_report_type :=
                           xx_om_report_exception_t (gc_exp_header
                                                     ,gc_track_code
                                                     ,gc_sol_domain
                                                     ,gc_function
                                                     ,lc_err_code
                                                     ,lc_err_desc
                                                     ,lc_entity_ref
                                                     ,NVL(ln_po_line_id,0)
                                                    );
         XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (err_report_type
                                                     ,x_err_buf
                                                     ,x_ret_code
                                                     );
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
                           xx_om_report_exception_t (gc_exp_header
                                                     ,gc_track_code
                                                     ,gc_sol_domain
                                                     ,gc_function
                                                     ,lc_err_code
                                                     ,lc_err_desc
                                                     ,lc_entity_ref
                                                     ,NVL(ln_po_line_id,0)
                                                    );
           XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (err_report_type
                                                       ,x_err_buf
                                                       ,x_ret_code
                                                       );
   END CANCEL_POLINES;
END XX_OM_POACK_PKG;

/
SHOW ERROR