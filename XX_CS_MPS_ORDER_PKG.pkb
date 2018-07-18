CREATE OR REPLACE PACKAGE BODY XX_CS_MPS_ORDER_PKG AS
-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  : XX_CS_MPS_ORDER_PKG.pkb                                                              |
-- | Description  : This package contains procedures related to Service Orders being inserted into|
-- |                OM IFACE tables for service order creation                                    |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        02-OCT-2012   Bapuji Nanapaneni  Initial version                                   |
-- |1.1        27-MAR-2013   Bapuji Nanapaneni  Modified avg cost to be same as po cost DEF#22572 |
-- |                                                                                              |
-- |1.2        26-FEB-2014   Arun Gannarapu     modified to pass task_id as orig_sys_ref def 28642|
-- +==============================================================================================+
PROCEDURE log_error_msgs( p_orig_sys_document_ref VARCHAR2
                        , p_order_source_id       NUMBER
                        );
						
PROCEDURE CREATE_MPS_ORDER( x_return_status  IN OUT NOCOPY VARCHAR2
                          , x_return_mesg    IN OUT NOCOPY VARCHAR2
                          , p_hdr_rec        IN xx_cs_order_hdr_rec
                          , P_lin_tbl        IN xx_cs_order_lines_tbl
                          ) AS
  -- +==================================================================================+
  -- | Name  : CREATE_MPS_ORDER                                                         |
  -- | Description      : This Procedure will create header and lin Record to send to   |
  -- |                    insert_header and insert_lines                                |
  -- |                                                                                  |
  -- |                                                                                  |
  -- | Parameters:        x_return_status IN OUT VARCHAR2 Return status                 |
  -- |                    x_return_msg    IN OUT VARCHAR2 Return Message                |
  -- |                    p_hdr_rec       IN     XX_CS_ORDER_HDR_REC Header Record      |
  -- |                    P_lin_tbl       IN     XX_CS_ORDER_LINES_TBL Line Record tbl  |
  -- +==================================================================================+

  /* Declare Local Variables */ 
  lc_orig_sys_document_ref     oe_headers_iface_all.orig_sys_document_ref%TYPE   := NULL;
  ln_org_id                    oe_headers_iface_all.org_id%TYPE                  := FND_PROFILE.VALUE('ORG_ID');
  ln_order_source_id           oe_headers_iface_all.order_source_id%TYPE         := NULL;
  lc_change_sequence           oe_headers_iface_all.change_sequence%TYPE         := NULL;
  lc_order_category            oe_headers_iface_all.order_category%TYPE          := 'ORDER';
  ln_order_type_id             oe_headers_iface_all.order_type_id%TYPE           := NULL;
  ln_price_list_id             oe_headers_iface_all.price_list_id%TYPE           := NULL;
  lc_transactional_curr_code   oe_headers_iface_all.transactional_curr_code%TYPE := 'USD';
  ln_salesrep_id               oe_headers_iface_all.salesrep_id%TYPE             := FND_PROFILE.VALUE('ONT_DEFAULT_PERSON_ID');
  lc_sales_channel_code        oe_headers_iface_all.sales_channel_code%TYPE      := 'W';
  lc_shipping_method_code      oe_headers_iface_all.shipping_method_code%TYPE    := NULL;
  lc_shipping_instructions     oe_headers_iface_all.shipping_instructions%TYPE   := NULL;
  lc_customer_po_number        oe_headers_iface_all.customer_po_number%TYPE      := NULL;
  ln_sold_to_org_id            oe_headers_iface_all.sold_to_org_id%TYPE          := NULL;
  ln_ship_from_org_id          oe_headers_iface_all.ship_from_org_id%TYPE        := NULL;
  ln_invoice_to_org_id         oe_headers_iface_all.invoice_to_org_id%TYPE       := NULL;
  ln_sold_to_contact_id        oe_headers_iface_all.sold_to_contact_id%TYPE      := NULL;
  ln_ship_to_contact_id        oe_headers_iface_all.sold_to_contact_id%TYPE      := NULL;
  ln_invoice_to_contact_id     oe_headers_iface_all.sold_to_contact_id%TYPE      := NULL;
  ln_ship_to_org_id            oe_headers_iface_all.ship_to_org_id%TYPE          := NULL;
  lc_drop_ship_flag            oe_headers_iface_all.drop_ship_flag%TYPE          := NULL;
  lc_booked_flag               oe_headers_iface_all.booked_flag%TYPE             := 'Y';
  lc_operation_code            oe_headers_iface_all.operation_code%TYPE          := 'INSERT';
  lc_error_flag                oe_headers_iface_all.error_flag%TYPE              := NULL;
  lc_ready_flag                oe_headers_iface_all.ready_flag%TYPE              := 'Y';
  ln_user_id                   oe_headers_iface_all.created_by%TYPE              := NVL(FND_GLOBAL.USER_ID,-1);
  ld_sysdate                   oe_headers_iface_all.creation_date%TYPE           := SYSDATE;
  ln_payment_term_id           oe_headers_iface_all.payment_term_id%TYPE         := NULL;
  lc_tax_exempt_flag           oe_headers_iface_all.tax_exempt_flag%TYPE         := 'S';
  ln_tax_exempt_number         oe_headers_iface_all.tax_exempt_number%TYPE       := NULL;
  lc_tax_exempt_reason_code    oe_headers_iface_all.tax_exempt_reason_code%TYPE  := NULL;
  lc_ship_to_sequence          xx_om_headers_attr_iface_all.ship_to_sequence%TYPE := NULL;
  lc_ship_to_address1          xx_om_headers_attr_iface_all.ship_to_address1%TYPE := NULL;
  lc_ship_to_address2          xx_om_headers_attr_iface_all.ship_to_address2%TYPE := NULL;
  lc_ship_to_city              xx_om_headers_attr_iface_all.ship_to_city%TYPE     := NULL;
  lc_ship_to_state             xx_om_headers_attr_iface_all.ship_to_state%TYPE    := NULL;
  lc_ship_to_country           xx_om_headers_attr_iface_all.ship_to_country%TYPE  := NULL;
  lc_ship_to_county            xx_om_headers_attr_iface_all.ship_to_county%TYPE   := NULL;
  lc_ship_to_zip               xx_om_headers_attr_iface_all.ship_to_zip%TYPE      := NULL;
  lc_ship_to_name              xx_om_headers_attr_iface_all.ship_to_name%TYPE     := NULL;
  
  lc_orig_sys_line_ref         oe_lines_iface_all.orig_sys_line_ref%TYPE         := NULL;
  ln_line_type_id              oe_lines_iface_all.line_type_id%TYPE              := NULL;
  ln_item_id                   oe_lines_iface_all.inventory_item_id%TYPE         := NULL;
  ln_lin_inv_org_id            oe_lines_iface_all.ship_from_org_id%TYPE          := NULL;
  ln_ord_qty                   oe_lines_iface_all.ordered_quantity%TYPE          := 0;
  lc_uom                       oe_lines_iface_all.order_quantity_uom%TYPE        := NULL;
  lc_calculate_price_flag      oe_lines_iface_all.calculate_price_flag%TYPE      := 'N';
  lc_line_category_code        oe_lines_iface_all.line_category_code%TYPE        := 'ORDER';
  ln_lin_ship_from_org_id      oe_headers_iface_all.ship_from_org_id%TYPE        := NULL;
  ln_unit_selling_price        oe_lines_iface_all.unit_selling_price%TYPE        := 0;
  ln_unit_list_price           oe_lines_iface_all.unit_selling_price%TYPE        := 0;
  ln_order_total               xx_om_headers_attr_iface_all.order_total%TYPE     := 0;
  ln_line_total                xx_om_headers_attr_iface_all.order_total%TYPE     := 0;
  lc_release_number            xx_om_headers_attr_iface_all.release_no%TYPE      := NULL;
  lc_cost_center               xx_om_headers_attr_iface_all.cust_dept_no%TYPE    := NULL;
  lc_desktop                   xx_om_headers_attr_iface_all.desk_top_no%TYPE     := NULL;
  ln_line_count                NUMBER                                            := 0;
  lc_line_cost_center          VARCHAR2(100)                                     := NULL;
  ln_line_ship_to_id           NUMBER                                            := NULL;
  lc_error_message             VARCHAR2(4000)                                    := NULL;
  lc_return_status             VARCHAR2(1)                                       := 'S';
  ln_request_id                NUMBER                                            := NULL;
  
  lr_header_rec                xx_cs_order_hdr_rec;
  lt_line_tbl                  xx_cs_order_lines_tbl;
  --i_idx                        BINARY_INTEGER := 0;
  --j_idx                        BINARY_INTEGER := 0;  

  lr_mps_order_hed_type g_mps_order_hed_type;
  lr_mps_order_lin_type g_mps_order_lin_type;
  
  --need to map header and line attributes from raj custom table once she gives.
BEGIN

  -- Initialize the fnd_message stack
  FND_MSG_PUB.Initialize;
  OE_BULK_MSG_PUB.Initialize;
  DBMS_OUTPUT.PUT_LINE('BEGIN OF PROCEDURE CREATE_MPS_ORDER');
  FND_PROFILE.GET('CONC_REQUEST_ID',ln_request_id);
  IF ln_request_id IS NULL THEN
    ln_request_id := -1;
  END IF;
  lr_header_rec := xx_cs_order_hdr_rec( NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
                                      , NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
                                      , NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
                                      , NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
                                      , NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
                                      );
  lr_header_rec := p_hdr_rec;
  
  --pric_list_id
  ln_price_list_id := OE_Sys_Parameters.value('XX_OM_SAS_PRICE_LIST',ln_org_id);

  --ORDER_SOURCE_ID
  BEGIN
    SELECT order_source_id
      INTO ln_order_source_id
      FROM oe_order_sources  s
         , fnd_lookup_values v
     WHERE s.order_source_id = TO_NUMBER(v.attribute6)
       AND v.lookup_type     = 'OD_ORDER_SOURCE'
       AND v.lookup_code     = '0';
	   
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lc_error_flag := 'Y';
	  log_error_msgs( p_orig_sys_document_ref => lr_header_rec.request_number
                    , p_order_source_id       => ln_order_source_id
                    );
      lc_error_message := 'Missing ORDER SOURCE ID';
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
      FND_MESSAGE.SET_TOKEN('ATTRIBUTE','ORDER SOURCE ID - '||ln_order_source_id);
      oe_bulk_msg_pub.add;	  
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED WHILE DERVING ORDER_SOURCE : '||SQLERRM);
      lc_error_flag := 'Y';
      lc_error_message := 'WHEN OTHERS RAISED WHILE DERVING ORDER_SOURCE : '||SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_ORDER_PKG.CREATE_MPS_ORDER'
                                           , p_error_message_code => 'XX_CS_MPSORD01_ERR_LOG'
                                           , p_error_msg          => lc_error_message
                                           );
  END;

  -- order_type_id
  BEGIN
    SELECT transaction_type_id
      INTO ln_order_type_id
      FROM oe_transaction_types_tl
     WHERE NAME = 'MPS US Standard';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
	  lc_error_flag := 'Y';
	  log_error_msgs( p_orig_sys_document_ref => lr_header_rec.request_number
                    , p_order_source_id       => ln_order_source_id
                    );
      lc_error_message := 'Missing TRANSACTION TYPE ID';
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
      FND_MESSAGE.SET_TOKEN('ATTRIBUTE','TRANSACTION TYPE ID - '||ln_order_type_id);
      oe_bulk_msg_pub.add;	
	  
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED WHILE DERVING ORDER_TYPE : '||SQLERRM);
      lc_error_flag := 'Y';
      lc_error_message := 'WHEN OTHERS RAISED WHILE DERVING ORDER_TYPE : '||SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_ORDER_PKG.CREATE_MPS_ORDER'
                                           , p_error_message_code => 'XX_CS_MPSORD01_ERR_LOG'
                                           , p_error_msg          => lc_error_message
                                           );
  END;

  BEGIN
    SELECT transaction_type_id
      INTO ln_line_type_id
      FROM oe_transaction_types_tl
     WHERE NAME = 'OD US MPS - LINE';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
	  lc_error_flag := 'Y';
	  log_error_msgs( p_orig_sys_document_ref => lr_header_rec.request_number
                    , p_order_source_id       => ln_order_source_id
                    );
      lc_error_message := 'Missing TRANSACTION LINE TYPE ID';
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
      FND_MESSAGE.SET_TOKEN('ATTRIBUTE','TRANSACTION LINE TYPE ID - '||ln_line_type_id);
      oe_bulk_msg_pub.add;	
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED WHILE DERVING LINE_TYPE : '||SQLERRM);
      lc_error_flag := 'Y';
      lc_error_message := 'WHEN OTHERS RAISED WHILE DERVING LINE_TYPE : '||SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_ORDER_PKG.CREATE_MPS_ORDER'
                                           , p_error_message_code => 'XX_CS_MPSORD01_ERR_LOG'
                                           , p_error_msg          => lc_error_message
                                           );
  END;
 
  
  ln_sold_to_org_id         := TO_NUMBER(lr_header_rec.party_id);
  ln_invoice_to_org_id      := TO_NUMBER(lr_header_rec.bill_to);	
  ln_ship_to_org_id         := TO_NUMBER(lr_header_rec.ship_to);
  ln_ship_from_org_id       := TO_NUMBER(lr_header_rec.attribute1);
  ln_salesrep_id            := TO_NUMBER(lr_header_rec.sales_person);
  lc_sales_channel_code     := NVL(lr_header_rec.order_category,'W');
  -- Mark for error if custom details or ship org is null
  IF ln_sold_to_org_id    IS NULL
  OR ln_invoice_to_org_id IS NULL
  OR ln_ship_to_org_id    IS NULL 
  OR ln_ship_from_org_id  IS NULL THEN
  
    lc_error_flag := 'Y';
	
	IF ln_sold_to_org_id IS NULL THEN
	  log_error_msgs( p_orig_sys_document_ref => lr_header_rec.request_number
                    , p_order_source_id       => ln_order_source_id
                    );
      lc_error_message := 'Missing customer ID';
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
      FND_MESSAGE.SET_TOKEN('ATTRIBUTE','CUSTOMER ID - '||ln_sold_to_org_id);
      oe_bulk_msg_pub.add;
    END IF;
	
	IF ln_invoice_to_org_id IS NULL THEN
	  log_error_msgs( p_orig_sys_document_ref => lr_header_rec.request_number
                    , p_order_source_id       => ln_order_source_id
                    );
      lc_error_message := 'Missing Bill To ID';
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
      FND_MESSAGE.SET_TOKEN('ATTRIBUTE','BILL_TO ID - '||ln_invoice_to_org_id);
      oe_bulk_msg_pub.add;
    END IF;
	
	IF ln_ship_to_org_id IS NULL THEN
	  log_error_msgs( p_orig_sys_document_ref => lr_header_rec.request_number
                    , p_order_source_id       => ln_order_source_id
                    );
      lc_error_message := 'Missing SHIP_TO ID';
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
      FND_MESSAGE.SET_TOKEN('ATTRIBUTE','SHIP_TO ID - '||ln_ship_to_org_id);
      oe_bulk_msg_pub.add;
    END IF;
	
	IF ln_ship_from_org_id IS NULL THEN
	  log_error_msgs( p_orig_sys_document_ref => lr_header_rec.request_number
                    , p_order_source_id       => ln_order_source_id
                    );
      lc_error_message := 'Missing SHIP_FROM ID';
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
      FND_MESSAGE.SET_TOKEN('ATTRIBUTE','SHIP_FROM ID - '||ln_ship_from_org_id);
      oe_bulk_msg_pub.add;
    END IF;	
	
  END IF;
  
/*    
    IF ln_invoice_to_org_id IS NULL THEN
      BEGIN
        SELECT site_use_id
          INTO ln_invoice_to_org_id
          FROM hz_cust_site_uses_all  c
             , hz_cust_acct_sites_all s
         WHERE s.cust_account_id   = ln_sold_to_org_id
           AND s.cust_acct_site_id = c.cust_acct_site_id
           AND c.site_use_code     = 'BILL_TO'
           AND c.org_id            = ln_org_id;
      EXCEPTION
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED WHILE DERVING CUSTOMER BILL TO : '||SQLERRM);
          lc_error_flag := 'Y';
          lc_error_message := 'WHEN OTHERS RAISED WHILE DERVING CUSTOMER BILL TO : '||SQLERRM;
          xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                               , p_error_location     => 'XX_CS_MPS_ORDER_PKG.CREATE_MPS_ORDER'
                                               , p_error_message_code => 'XX_CS_MPSORD01_ERR_LOG'
                                               , p_error_msg          => lc_error_message
                                               );
      END;
    END IF;
*/

  BEGIN
    SELECT standard_terms
      INTO ln_payment_term_id
      FROM hz_customer_profiles
     WHERE cust_account_id = ln_sold_to_org_id
       AND site_use_id IS NULL;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
	  log_error_msgs( p_orig_sys_document_ref => lr_header_rec.request_number
                    , p_order_source_id       => ln_order_source_id
                    );
      lc_error_message := 'Missing TERM ID for : '||ln_sold_to_org_id ;
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
      FND_MESSAGE.SET_TOKEN('ATTRIBUTE','TERM ID for : '||ln_sold_to_org_id);
      oe_bulk_msg_pub.add;
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED WHILE DERVING PAYMENT TERMS : '||SQLERRM);
      lc_error_flag := 'Y';
      lc_error_message :=  'WHEN OTHERS RAISED WHILE DERVING PAYMENT TERMS : '||SQLERRM;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_ORDER_PKG.CREATE_MPS_ORDER'
                                           , p_error_message_code => 'XX_CS_MPSORD01_ERR_LOG'
                                           , p_error_msg          => lc_error_message
                                           );
  END;
  
  BEGIN
    SELECT SUBSTR(NVL(l.address_lines_phonetic,p.party_name),1,40) 
         , SUBSTR(u.orig_system_reference,10,5)                        
         , l.address1                                                  
         , l.address2 ||' '||l.address3 ||' '||l.address4              
         , l.city                                                      
         , NVL(l.state , l.province)                                  
         , l.postal_code                                               
         , l.country 
      INTO lc_ship_to_name
         , lc_ship_to_sequence		
         , lc_ship_to_address1
         , lc_ship_to_address2
         , lc_ship_to_city
         , lc_ship_to_state
         , lc_ship_to_zip
         , lc_ship_to_country		   		   
      FROM hz_cust_accounts_all   c
         , hz_parties             p 
         , hz_cust_acct_sites_all a
         , hz_party_sites         ps
         , hz_locations           l
         , hz_cust_site_uses_all  u
     WHERE u.cust_acct_site_id  = a.cust_acct_site_id
       AND a.party_site_id      = ps.party_site_id
       AND l.location_id        = ps.location_id
       AND u.site_use_id        = ln_ship_to_org_id
       AND c.cust_account_id    = ln_sold_to_org_id
       AND c.party_id           = p.party_id; 
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('NO DATA FOUND WHILE DERVING SHIP TO ADDR : '||SQLERRM);
	  
	WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED WHILE DERVING SHIP TO ADDR : '||SQLERRM);
      lc_error_flag := 'Y';
      lc_error_message :=  'WHEN OTHERS RAISED WHILE DERVING SHIP TO ADDR : '||SQLERRM;	 
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_ORDER_PKG.CREATE_ORDER'
                                           , p_error_message_code => 'XX_CS_MPSORD01_ERR_LOG'
                                           , p_error_msg          => lc_error_message
                                           );		
  END;
  
  /* Validate Sales Rep */   
  IF ln_salesrep_id IS NULL THEN
    ln_salesrep_id := FND_PROFILE.VALUE('ONT_DEFAULT_PERSON_ID');
  END IF;
  
  IF ln_salesrep_id IS NULL THEN
      lc_error_message := 'Missing SALES REP ID' ;
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
      FND_MESSAGE.SET_TOKEN('ATTRIBUTE','SALES REP ID - ');
      oe_bulk_msg_pub.add;
  END IF;	
  
  SAVEPOINT PROCESS_ORDER;
   
  /* Added all values to Header Record */
  lr_mps_order_hed_type.orig_sys_document_ref    := lr_header_rec.request_number;
  lr_mps_order_hed_type.order_source_id          := ln_order_source_id;
  lr_mps_order_hed_type.org_id                   := ln_org_id;
  lr_mps_order_hed_type.change_sequence          := lc_change_sequence;
  lr_mps_order_hed_type.order_category           := lc_order_category;
  lr_mps_order_hed_type.ordered_date             := ld_sysdate;                   
  lr_mps_order_hed_type.order_type_id            := ln_order_type_id;
  lr_mps_order_hed_type.price_list_id            := ln_price_list_id;
  lr_mps_order_hed_type.transactional_curr_code  := lc_transactional_curr_code;
  lr_mps_order_hed_type.salesrep_id              := ln_salesrep_id;               
  lr_mps_order_hed_type.sales_channel_code       := lc_sales_channel_code;
  lr_mps_order_hed_type.shipping_method_code     := lc_shipping_method_code;
  lr_mps_order_hed_type.shipping_instructions    := lc_shipping_instructions;
  lr_mps_order_hed_type.customer_po_number       := lr_header_rec.customer_po_number;
  lr_mps_order_hed_type.sold_to_org_id           := ln_sold_to_org_id;
  lr_mps_order_hed_type.ship_from_org_id         := ln_ship_from_org_id;
  lr_mps_order_hed_type.invoice_to_org_id        := ln_invoice_to_org_id;
  lr_mps_order_hed_type.sold_to_contact_id       := lr_header_rec.contact_id;
  lr_mps_order_hed_type.ship_to_contact_id       := ln_ship_to_contact_id;
  lr_mps_order_hed_type.invoice_to_contact_id    := ln_invoice_to_contact_id;
  lr_mps_order_hed_type.ship_to_org_id           := ln_ship_to_org_id;
  lr_mps_order_hed_type.ship_to_org              := NULL;
  lr_mps_order_hed_type.ship_from_org            := NULL;
  lr_mps_order_hed_type.sold_to_org              := NULL;
  lr_mps_order_hed_type.invoice_to_org           := NULL;
  lr_mps_order_hed_type.drop_ship_flag           := lc_drop_ship_flag;
  lr_mps_order_hed_type.booked_flag              := lc_booked_flag;
  lr_mps_order_hed_type.operation_code           := lc_operation_code;
  lr_mps_order_hed_type.error_flag               := lc_error_flag;
  lr_mps_order_hed_type.ready_flag               := lc_ready_flag;
  lr_mps_order_hed_type.created_by               := ln_user_id;
  lr_mps_order_hed_type.creation_date            := ld_sysdate;
  lr_mps_order_hed_type.last_update_date         := ld_sysdate;
  lr_mps_order_hed_type.last_updated_by          := ln_user_id;
  lr_mps_order_hed_type.last_update_login        := NULL;
  lr_mps_order_hed_type.request_id               := NULL;
  lr_mps_order_hed_type.batch_id                 := NULL;
  lr_mps_order_hed_type.accounting_rule_id       := NULL;
  lr_mps_order_hed_type.sold_to_contact          := NULL;
  lr_mps_order_hed_type.payment_term_id          := ln_payment_term_id;
  lr_mps_order_hed_type.salesrep                 := NULL;
  lr_mps_order_hed_type.order_source             := NULL;
  lr_mps_order_hed_type.sales_channel            := NULL;
  lr_mps_order_hed_type.shipping_method          := NULL;
  lr_mps_order_hed_type.order_number             := NULL;
  lr_mps_order_hed_type.tax_exempt_flag          := lc_tax_exempt_flag;
  lr_mps_order_hed_type.tax_exempt_number        := ln_tax_exempt_number;
  lr_mps_order_hed_type.tax_exempt_reason_code   := lc_tax_exempt_reason_code;
  lr_mps_order_hed_type.ineligible_for_hvop      := NULL;
  lr_mps_order_hed_type.created_by_store_id      := NULL;
  lr_mps_order_hed_type.paid_at_store_id         := NULL;
  lr_mps_order_hed_type.paid_at_store_no         := NULL;
  lr_mps_order_hed_type.spc_card_number          := NULL; -- Need to find out
  lr_mps_order_hed_type.placement_method_code    := NULL; -- Need to find out
  lr_mps_order_hed_type.advantage_card_number    := NULL; -- Need to find out
  lr_mps_order_hed_type.created_by_id            := 'EBS';
  lr_mps_order_hed_type.delivery_code            := NULL;
  lr_mps_order_hed_type.delivery_method          := NULL;
  lr_mps_order_hed_type.release_no               := lr_header_rec.release;
  lr_mps_order_hed_type.cust_dept_no             := lr_header_rec.cost_center;
  lr_mps_order_hed_type.desk_top_no              := lr_header_rec.desk_top;
  lr_mps_order_hed_type.comments                 := lr_header_rec.special_instructions;
  lr_mps_order_hed_type.gift_flag                := NULL;
  lr_mps_order_hed_type.orig_cust_name           := NULL;
  lr_mps_order_hed_type.od_order_type            := NULL;
  lr_mps_order_hed_type.ship_to_sequence         := lc_ship_to_sequence;
  lr_mps_order_hed_type.ship_to_address1         := lc_ship_to_address1;
  lr_mps_order_hed_type.ship_to_address2         := lc_ship_to_address2;
  lr_mps_order_hed_type.ship_to_city             := lc_ship_to_city;
  lr_mps_order_hed_type.ship_to_state            := lc_ship_to_state;
  lr_mps_order_hed_type.ship_to_country          := lc_ship_to_country;
  lr_mps_order_hed_type.ship_to_county           := NULL;
  lr_mps_order_hed_type.ship_to_zip              := lc_ship_to_zip;
  lr_mps_order_hed_type.ship_to_name             := lc_ship_to_name;
  lr_mps_order_hed_type.bill_to_name             := NULL;
  lr_mps_order_hed_type.cust_contact_name        := lr_header_rec.contact_name;
  lr_mps_order_hed_type.cust_pref_phone          := lr_header_rec.contact_phone;
  lr_mps_order_hed_type.cust_pref_phextn         := NULL;
  lr_mps_order_hed_type.cust_pref_email          := NULL;
  lr_mps_order_hed_type.imp_file_name            := NULL;
  lr_mps_order_hed_type.tax_rate                 := NULL;
  lr_mps_order_hed_type.order_total              := lr_header_rec.order_total;
  lr_mps_order_hed_type.commisionable_ind        := NULL;
  lr_mps_order_hed_type.order_action_code        := NULL;
  lr_mps_order_hed_type.order_start_time         := NULL;
  lr_mps_order_hed_type.order_end_time           := ld_sysdate;
  lr_mps_order_hed_type.order_taxable_cd         := NULL;
  lr_mps_order_hed_type.override_delivery_chg_cd := NULL;
  lr_mps_order_hed_type.ship_to_geocode          := NULL;
  lr_mps_order_hed_type.cust_dept_description    := NULL;
  lr_mps_order_hed_type.tran_number              := lr_header_rec.request_number;
  lr_mps_order_hed_type.aops_geo_code            := NULL;
  lr_mps_order_hed_type.tax_exempt_amount        := NULL;
  lr_mps_order_hed_type.sr_number                := NULL;

  --Call insert_header Procedure to insert into header iface tables
  IF lr_mps_order_hed_type.orig_sys_document_ref IS NOT NULL THEN
    insert_header( p_hdr_iface_rec  => lr_mps_order_hed_type
                 , x_return_status  => lc_return_status
                 , x_return_mesg    => lc_error_message
                 );
  END IF;				 

  -- Start of line record
  --lt_line_tbl := xx_cs_order_lines_tbl();
  lt_line_tbl   := P_lin_tbl;
  
  FOR i_idx IN 1..lt_line_tbl.count LOOP
 
    lr_mps_order_lin_type.orig_sys_document_ref      := lr_mps_order_hed_type.orig_sys_document_ref;
    lr_mps_order_lin_type.order_source_id            := lr_mps_order_hed_type.order_source_id;
    lr_mps_order_lin_type.change_sequence            := lr_mps_order_hed_type.change_sequence;
    lr_mps_order_lin_type.org_id                     := lr_mps_order_hed_type.org_id;
    lr_mps_order_lin_type.orig_sys_line_ref          := lt_line_tbl(i_idx).attribute6 ; ---line_number;
    lr_mps_order_lin_type.line_number                := lt_line_tbl(i_idx).line_number;
    lr_mps_order_lin_type.line_type_id               := ln_line_type_id;
    lr_mps_order_lin_type.inventory_item_id          := NULL;
    lr_mps_order_lin_type.inventory_item             := lt_line_tbl(i_idx).sku;
    lr_mps_order_lin_type.schedule_ship_date         := NULL;
    lr_mps_order_lin_type.actual_shipment_date       := ld_sysdate;
    lr_mps_order_lin_type.salesrep_id                := lr_mps_order_hed_type.salesrep_id;
    lr_mps_order_lin_type.ordered_quantity           := lt_line_tbl(i_idx).order_qty;
    lr_mps_order_lin_type.order_quantity_uom         := lt_line_tbl(i_idx).uom;
    lr_mps_order_lin_type.shipped_quantity           := lt_line_tbl(i_idx).order_qty;
    lr_mps_order_lin_type.sold_to_org_id             := lr_mps_order_hed_type.sold_to_org_id;
    lr_mps_order_lin_type.ship_from_org_id           := TO_NUMBER(lt_line_tbl(i_idx).attribute1); --lr_mps_order_hed_type.ship_from_org_id; -- Need to change get from line rec
    lr_mps_order_lin_type.ship_to_org_id             := TO_NUMBER(lt_line_tbl(i_idx).attribute2); --lr_mps_order_hed_type.ship_to_org_id;
    lr_mps_order_lin_type.invoice_to_org_id          := lr_mps_order_hed_type.invoice_to_org_id;
    lr_mps_order_lin_type.drop_ship_flag             := lr_mps_order_hed_type.drop_ship_flag;
    lr_mps_order_lin_type.price_list_id              := lr_mps_order_hed_type.price_list_id;
    lr_mps_order_lin_type.unit_list_price            := lt_line_tbl(i_idx).selling_price;
    lr_mps_order_lin_type.unit_selling_price         := lt_line_tbl(i_idx).selling_price;
    lr_mps_order_lin_type.calculate_price_flag       := lc_calculate_price_flag;
    lr_mps_order_lin_type.tax_code                   := NULL;
    lr_mps_order_lin_type.tax_value                  := NULL;
    lr_mps_order_lin_type.tax_date                   := NULL;
    lr_mps_order_lin_type.shipping_method_code       := lr_mps_order_hed_type.shipping_method_code;
    lr_mps_order_lin_type.return_reason_code         := NULL;
    lr_mps_order_lin_type.customer_po_number         := lr_mps_order_hed_type.customer_po_number;
    lr_mps_order_lin_type.operation_code             := lr_mps_order_hed_type.operation_code;
    lr_mps_order_lin_type.error_flag                 := NULL;
    lr_mps_order_lin_type.shipping_instructions      := lr_mps_order_hed_type.shipping_instructions;
    lr_mps_order_lin_type.return_context             := NULL;
    lr_mps_order_lin_type.return_attribute1          := NULL;
    lr_mps_order_lin_type.return_attribute2          := NULL;
    lr_mps_order_lin_type.customer_item_id           := NULL;
    lr_mps_order_lin_type.customer_item_id_type      := NULL;
    lr_mps_order_lin_type.line_category_code         := lc_line_category_code;
    lr_mps_order_lin_type.creation_date              := lr_mps_order_hed_type.creation_date;
    lr_mps_order_lin_type.created_by                 := lr_mps_order_hed_type.created_by;
    lr_mps_order_lin_type.last_update_date           := lr_mps_order_hed_type.last_update_date;
    lr_mps_order_lin_type.last_updated_by            := lr_mps_order_hed_type.last_updated_by;
    lr_mps_order_lin_type.request_id                 := NULL;
    lr_mps_order_lin_type.line_id                    := NULL;
    lr_mps_order_lin_type.payment_term_id            := lr_mps_order_hed_type.payment_term_id;
    lr_mps_order_lin_type.request_date               := ld_sysdate;
    lr_mps_order_lin_type.schedule_status_code       := NULL;
    lr_mps_order_lin_type.customer_item_name         := NULL;
    lr_mps_order_lin_type.user_item_description      := NULL;
    lr_mps_order_lin_type.tax_exempt_flag            := lr_mps_order_hed_type.tax_exempt_flag;
    lr_mps_order_lin_type.tax_exempt_number          := lr_mps_order_hed_type.tax_exempt_number;
    lr_mps_order_lin_type.tax_exempt_reason_code     := lr_mps_order_hed_type.tax_exempt_reason_code;
    lr_mps_order_lin_type.customer_line_number	     := NULL;
    lr_mps_order_lin_type.vendor_product_code        := lt_line_tbl(i_idx).vendor_part_number;
    lr_mps_order_lin_type.average_cost               := lt_line_tbl(i_idx).attribute5; -- Defect#22572
    lr_mps_order_lin_type.po_cost                    := lt_line_tbl(i_idx).attribute5;
    lr_mps_order_lin_type.canada_pst                 := NULL;
    lr_mps_order_lin_type.return_act_cat_code        := NULL;
    lr_mps_order_lin_type.ret_orig_order_num         := NULL;
    lr_mps_order_lin_type.back_ordered_qty           := NULL;
    lr_mps_order_lin_type.ret_orig_order_line_num    := NULL;
    lr_mps_order_lin_type.ret_orig_order_date        := NULL;
    lr_mps_order_lin_type.wholesaler_item            := lt_line_tbl(i_idx).vendor_part_number;
    lr_mps_order_lin_type.legacy_list_price          := NULL;
    lr_mps_order_lin_type.contract_details           := lt_line_tbl(i_idx).attribute3;
    lr_mps_order_lin_type.item_Comments              := lt_line_tbl(i_idx).item_description;
    lr_mps_order_lin_type.line_Comments              := lt_line_tbl(i_idx).comments;
    lr_mps_order_lin_type.taxable_Flag               := NULL;
    lr_mps_order_lin_type.sku_Dept                   := lt_line_tbl(i_idx).attribute4;
    lr_mps_order_lin_type.item_source                := NULL;
    lr_mps_order_lin_type.config_code                := NULL;
    lr_mps_order_lin_type.ext_top_model_line_id      := NULL;
    lr_mps_order_lin_type.ext_link_to_line_id        := NULL;
    lr_mps_order_lin_type.aops_ship_date             := ld_sysdate;
    lr_mps_order_lin_type.sas_sale_date              := ld_sysdate;
    lr_mps_order_lin_type.calc_arrival_date          := ld_sysdate;
    lr_mps_order_lin_type.ret_ref_header_id          := NULL;
    lr_mps_order_lin_type.ret_ref_line_id            := NULL;
    lr_mps_order_lin_type.release_num                := lt_line_tbl(i_idx).release;
    lr_mps_order_lin_type.cost_center_dept           := lt_line_tbl(i_idx).cost_center;
    lr_mps_order_lin_type.desktop_del_addr           := lt_line_tbl(i_idx).desktop_location;
    lr_mps_order_lin_type.gsa_flag                   := NULL;
    lr_mps_order_lin_type.waca_item_ctr_num          := NULL;
    lr_mps_order_lin_type.consignment_bank_code      := NULL;
    lr_mps_order_lin_type.price_cd                   := NULL;
    lr_mps_order_lin_type.price_change_reason_cd     := NULL;
    lr_mps_order_lin_type.price_prefix_cd            := NULL;
    lr_mps_order_lin_type.commisionable_ind          := NULL;
    lr_mps_order_lin_type.cust_dept_description      := NULL;
    lr_mps_order_lin_type.unit_orig_selling_price    := lt_line_tbl(i_idx).selling_price;
 
    --Call insert_line Procedure to insert into line iface tables
    IF lr_mps_order_lin_type.orig_sys_document_ref IS NOT NULL THEN
      insert_lines( p_lin_iface_rec  => lr_mps_order_lin_type
                  , x_return_status  => lc_return_status
                  , x_return_mesg    => lc_error_message
                  );
    END IF;				  
  END LOOP;
  -- Save the messages logged so far
  OE_BULK_MSG_PUB.Save_Messages(ln_request_id);
  OE_MSG_PUB.Save_Messages(ln_request_id);
  COMMIT;

  x_return_status := lc_return_status;
  IF lc_error_message IS NOT NULL THEN
    x_return_mesg := lc_error_message;
  ELSE
    x_return_mesg := 'Success';
  END IF;

  DBMS_OUTPUT.PUT_LINE('END OF PROCEDURE CREATE_MPS_ORDER');

EXCEPTION
  WHEN OTHERS THEN
  ROLLBACK TO SAVEPOINT PROCESS_ORDER;
  DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED CREATE_MPS_ORDER : '||SQLERRM);
  x_return_status := 'E';
  x_return_mesg := 'WHEN OTHERS RAISED IN CREATE_MPS_ORDER : '||SQLERRM;
  xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                       , p_error_location     => 'XX_CS_MPS_ORDER_PKG.CREATE_MPS_ORDER'
                                       , p_error_message_code => 'XX_CS_MPSORD01_ERR_LOG'
                                       , p_error_msg          => 'WHEN OTHERS RAISED IN CREATE_MPS_ORDER : '||SQLERRM
                                       );
   
END CREATE_MPS_ORDER;

  -- +==================================================================================+
  -- | Name  : INSERT_HEADER                                                            |
  -- | Description      : This Procedure will insert into OE_HEADER_IFACE_ALL table send|
  -- |                    from CREATE_ORDER                                             |
  -- |                                                                                  |
  -- | Parameters:        x_return_status IN OUT VARCHAR2 Return status                 |
  -- |                    x_return_msg    IN OUT VARCHAR2 Return Message                |
  -- |                    p_hdr_iface_rec IN     g_mps_order_hed_type Line Record       |
  -- +==================================================================================+ 
PROCEDURE insert_header( p_hdr_iface_rec  IN G_MPS_ORDER_HED_TYPE 
                       , x_return_status  IN OUT NOCOPY VARCHAR2
                       , x_return_mesg    IN OUT NOCOPY VARCHAR2
                       ) IS 
   
  lr_mps_order_hed_type  g_mps_order_hed_type;
  lc_return_status       VARCHAR2(1);
  lc_return_mesg         VARCHAR2(4000);
BEGIN
    lc_return_status      := 'S';
    lc_return_mesg        := NULL;
    lr_mps_order_hed_type := p_hdr_iface_rec;
    IF lr_mps_order_hed_type.orig_sys_document_ref IS NOT NULL THEN

      INSERT INTO oe_headers_iface_all( orig_sys_document_ref
                                      , order_source_id
                                      , org_id
                                      , change_sequence
                                      , order_category
                                      , ordered_date
                                      , order_type_id
                                      , price_list_id
                                      , transactional_curr_code
                                      , salesrep_id
                                      , sales_channel_code
                                      , shipping_method_code
                                      , shipping_instructions
                                      , customer_po_number
                                      , sold_to_org_id
                                      , ship_from_org_id
                                      , invoice_to_org_id
                                      , sold_to_contact_id
                                      , ship_to_contact_id
                                      , invoice_to_contact_id
                                      , ship_to_org_id
                                      , ship_to_org
                                      , ship_from_org
                                      , sold_to_org
                                      , invoice_to_org
                                      , drop_ship_flag
                                      , booked_flag
                                      , operation_code
                                      , error_flag
                                      , ready_flag
                                      , created_by
                                      , creation_date
                                      , last_update_date
                                      , last_updated_by
                                      , last_update_login
                                      , request_id
                                      , batch_id
                                      , accounting_rule_id
                                      , sold_to_contact
                                      , payment_term_id
                                      , salesrep
                                      , order_source
                                      , sales_channel
                                      , shipping_method
                                      , order_number
                                      , tax_exempt_flag
                                      , tax_exempt_number
                                      , tax_exempt_reason_code
                                      , ineligible_for_hvop
                                      )
                                      VALUES
                                      ( lr_mps_order_hed_type.orig_sys_document_ref
                                      , lr_mps_order_hed_type.order_source_id
                                      , lr_mps_order_hed_type.org_id
                                      , lr_mps_order_hed_type.change_sequence
                                      , lr_mps_order_hed_type.order_category
                                      , lr_mps_order_hed_type.ordered_date
                                      , lr_mps_order_hed_type.order_type_id
                                      , lr_mps_order_hed_type.price_list_id
                                      , lr_mps_order_hed_type.transactional_curr_code
                                      , lr_mps_order_hed_type.salesrep_id
                                      , lr_mps_order_hed_type.sales_channel_code
                                      , lr_mps_order_hed_type.shipping_method_code
                                      , lr_mps_order_hed_type.shipping_instructions
                                      , lr_mps_order_hed_type.customer_po_number
                                      , lr_mps_order_hed_type.sold_to_org_id
                                      , lr_mps_order_hed_type.ship_from_org_id
                                      , lr_mps_order_hed_type.invoice_to_org_id
                                      , lr_mps_order_hed_type.sold_to_contact_id
                                      , lr_mps_order_hed_type.ship_to_contact_id
                                      , lr_mps_order_hed_type.invoice_to_contact_id
                                      , lr_mps_order_hed_type.ship_to_org_id
                                      , lr_mps_order_hed_type.ship_to_org
                                      , lr_mps_order_hed_type.ship_from_org
                                      , lr_mps_order_hed_type.sold_to_org
                                      , lr_mps_order_hed_type.invoice_to_org
                                      , lr_mps_order_hed_type.drop_ship_flag
                                      , lr_mps_order_hed_type.booked_flag
                                      , lr_mps_order_hed_type.operation_code
                                      , lr_mps_order_hed_type.error_flag
                                      , lr_mps_order_hed_type.ready_flag
                                      , lr_mps_order_hed_type.created_by
                                      , lr_mps_order_hed_type.creation_date
                                      , lr_mps_order_hed_type.last_update_date
                                      , lr_mps_order_hed_type.last_updated_by
                                      , lr_mps_order_hed_type.last_update_login
                                      , lr_mps_order_hed_type.request_id
                                      , lr_mps_order_hed_type.batch_id
                                      , lr_mps_order_hed_type.accounting_rule_id
                                      , lr_mps_order_hed_type.sold_to_contact
                                      , lr_mps_order_hed_type.payment_term_id
                                      , lr_mps_order_hed_type.salesrep
                                      , lr_mps_order_hed_type.order_source
                                      , lr_mps_order_hed_type.sales_channel
                                      , lr_mps_order_hed_type.shipping_method
                                      , lr_mps_order_hed_type.order_number
                                      , lr_mps_order_hed_type.tax_exempt_flag
                                      , lr_mps_order_hed_type.tax_exempt_number
                                      , lr_mps_order_hed_type.tax_exempt_reason_code
                                      , lr_mps_order_hed_type.ineligible_for_hvop
                                      );

      INSERT INTO xx_om_headers_attr_iface_all( orig_sys_document_ref
                                              , order_source_id
                                              , created_by_store_id
                                              , paid_at_store_id
                                              , paid_at_store_no
                                              , spc_card_number
                                              , placement_method_code
                                              , advantage_card_number
                                              , created_by_id
                                              , delivery_code
                                              , delivery_method
                                              , release_no
                                              , cust_dept_no
                                              , desk_top_no
                                              , comments
                                              , creation_date
                                              , created_by
                                              , last_update_date
                                              , last_updated_by
                                              , request_id
                                              , batch_id
                                              , gift_flag
                                              , orig_cust_name
                                              , od_order_type
                                              , ship_to_sequence
                                              , ship_to_address1
                                              , ship_to_address2
                                              , ship_to_city
                                              , ship_to_state
                                              , ship_to_country
                                              , ship_to_county
                                              , ship_to_zip
                                              , ship_to_name
                                              , bill_to_name
                                              , cust_contact_name
                                              , cust_pref_phone
                                              , cust_pref_phextn
                                              , cust_pref_email
                                              , imp_file_name
                                              , tax_rate
                                              , order_total
                                              , commisionable_ind
                                              , order_action_code
                                              , order_start_time
                                              , order_end_time
                                              , order_taxable_cd
                                              , override_delivery_chg_cd
                                              , ship_to_geocode
                                              , cust_dept_description
                                              , tran_number
                                              , aops_geo_code
                                              , tax_exempt_amount
                                              , sr_number
                                              ) VALUES
                                              ( lr_mps_order_hed_type.orig_sys_document_ref
                                              , lr_mps_order_hed_type.order_source_id
                                              , lr_mps_order_hed_type.created_by_store_id
                                              , lr_mps_order_hed_type.paid_at_store_id
                                              , lr_mps_order_hed_type.paid_at_store_no
                                              , lr_mps_order_hed_type.spc_card_number
                                              , lr_mps_order_hed_type.placement_method_code
                                              , lr_mps_order_hed_type.advantage_card_number
                                              , lr_mps_order_hed_type.created_by_id
                                              , lr_mps_order_hed_type.delivery_code
                                              , lr_mps_order_hed_type.delivery_method
                                              , lr_mps_order_hed_type.release_no
                                              , lr_mps_order_hed_type.cust_dept_no
                                              , lr_mps_order_hed_type.desk_top_no --desk_del_addr
                                              , lr_mps_order_hed_type.comments
                                              , lr_mps_order_hed_type.creation_date
                                              , lr_mps_order_hed_type.created_by
                                              , lr_mps_order_hed_type.last_update_date
                                              , lr_mps_order_hed_type.last_updated_by
                                              , lr_mps_order_hed_type.request_id
                                              , lr_mps_order_hed_type.batch_id
                                              , lr_mps_order_hed_type.gift_flag
                                              , lr_mps_order_hed_type.orig_cust_name
                                              , lr_mps_order_hed_type.od_order_type
                                              , lr_mps_order_hed_type.ship_to_sequence
                                              , lr_mps_order_hed_type.ship_to_address1
                                              , lr_mps_order_hed_type.ship_to_address2
                                              , lr_mps_order_hed_type.ship_to_city
                                              , lr_mps_order_hed_type.ship_to_state
                                              , lr_mps_order_hed_type.ship_to_country
                                              , lr_mps_order_hed_type.ship_to_county
                                              , lr_mps_order_hed_type.ship_to_zip
                                              , lr_mps_order_hed_type.ship_to_name
                                              , lr_mps_order_hed_type.bill_to_name
                                              , lr_mps_order_hed_type.cust_contact_name
                                              , lr_mps_order_hed_type.cust_pref_phone
                                              , lr_mps_order_hed_type.cust_pref_phextn
                                              , lr_mps_order_hed_type.cust_pref_email
                                              , lr_mps_order_hed_type.imp_file_name
                                              , lr_mps_order_hed_type.tax_rate
                                              , lr_mps_order_hed_type.order_total
                                              , lr_mps_order_hed_type.commisionable_ind
                                              , lr_mps_order_hed_type.order_action_code
                                              , lr_mps_order_hed_type.order_start_time
                                              , lr_mps_order_hed_type.order_end_time
                                              , lr_mps_order_hed_type.order_taxable_cd
                                              , lr_mps_order_hed_type.override_delivery_chg_cd
                                              , lr_mps_order_hed_type.ship_to_geocode
                                              , lr_mps_order_hed_type.cust_dept_description
                                              , lr_mps_order_hed_type.tran_number
                                              , lr_mps_order_hed_type.aops_geo_code
                                              , lr_mps_order_hed_type.tax_exempt_amount
                                              , lr_mps_order_hed_type.sr_number
                                              );
    END IF;
    x_return_status  := lc_return_status;
    x_return_mesg    := lc_return_mesg;
EXCEPTION
    WHEN OTHERS THEN 
      lc_return_mesg      :=  'WHEN OTHERS RAISED WHILE INSERTING INTO HEADER TBL : '||SQLERRM;
      x_return_status     := 'Y';
      DBMS_OUTPUT.PUT_LINE(lc_return_mesg);
      x_return_mesg       := lc_return_mesg;
      xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                           , p_error_location     => 'XX_CS_MPS_ORDER_PKG.INSERT_HEADER'
                                           , p_error_message_code => 'XX_CS_MPSORD01_ERR_LOG'
                                           , p_error_msg          => lc_return_mesg
                                           );
END insert_header;

  -- +==================================================================================+
  -- | Name  : INSERT_LINES                                                             |
  -- | Description      : This Procedure will insert into OE_LINES_IFACE_ALL table send |
  -- |                    from CREATE_ORDER                                             |
  -- |                                                                                  |
  -- | Parameters:        x_return_status IN OUT VARCHAR2 Return status                 |
  -- |                    x_return_msg    IN OUT VARCHAR2 Return Message                |
  -- |                    p_lin_iface_rec IN     g_mps_order_lin_type Line Record       |
  -- +==================================================================================+ 
PROCEDURE insert_lines( p_lin_iface_rec  IN g_mps_order_lin_type
                     , x_return_status  IN OUT NOCOPY VARCHAR2
                     , x_return_mesg    IN OUT NOCOPY VARCHAR2
                     ) IS
  lr_mps_order_lin_type  g_mps_order_lin_type;
  lc_return_status       VARCHAR2(1);
  lc_return_mesg         VARCHAR2(4000); 
BEGIN
    lc_return_status      := 'S';
    lc_return_mesg        := NULL;
    lr_mps_order_lin_type := p_lin_iface_rec;

    IF lr_mps_order_lin_type.orig_sys_document_ref IS NOT NULL AND lr_mps_order_lin_type.line_number IS NOT NULL THEN
        INSERT INTO oe_lines_iface_all( orig_sys_document_ref 
                                      , order_source_id
                                      , change_sequence
                                      , org_id
                                      , orig_sys_line_ref
                                      , line_number
                                      , line_type_id
                                      , inventory_item_id
                                      , inventory_item
                                      , schedule_ship_date
                                      , actual_shipment_date
                                      , salesrep_id
                                      , ordered_quantity
                                      , order_quantity_uom
                                      , shipped_quantity
                                      , sold_to_org_id
                                      , ship_from_org_id
                                      , ship_to_org_id
                                      , invoice_to_org_id
                                      , drop_ship_flag
                                      , price_list_id
                                      , unit_list_price
                                      , unit_selling_price
                                      , calculate_price_flag
                                      , tax_code
                                      , tax_value
                                      , tax_date
                                      , shipping_method_code
                                      , return_reason_code
                                      , customer_po_number
                                      , operation_code
                                      , error_flag
                                      , shipping_instructions
                                      , return_context
                                      , return_attribute1
                                      , return_attribute2
                                      , customer_item_id
                                      , customer_item_id_type
                                      , line_category_code
                                      , creation_date
                                      , created_by
                                      , last_update_date
                                      , last_updated_by
                                      , request_id
                                      , line_id
                                      , payment_term_id
                                      , request_date
                                      , schedule_status_code
                                      , customer_item_name
                                      , user_item_description
                                      , tax_exempt_flag
                                      , tax_exempt_number
                                      , tax_exempt_reason_code
                                      , customer_line_number
                                      ) VALUES
                                      ( lr_mps_order_lin_type.orig_sys_document_ref
                                      , lr_mps_order_lin_type.order_source_id
                                      , lr_mps_order_lin_type.change_sequence
                                      , lr_mps_order_lin_type.org_id	
                                      , lr_mps_order_lin_type.orig_sys_line_ref
                                      , lr_mps_order_lin_type.line_number
                                      , lr_mps_order_lin_type.line_type_id
                                      , lr_mps_order_lin_type.inventory_item_id
                                      , lr_mps_order_lin_type.inventory_item
                                      , lr_mps_order_lin_type.schedule_ship_date
                                      , lr_mps_order_lin_type.actual_shipment_date
                                      , lr_mps_order_lin_type.salesrep_id
                                      , lr_mps_order_lin_type.ordered_quantity
                                      , lr_mps_order_lin_type.order_quantity_uom
                                      , lr_mps_order_lin_type.shipped_quantity
                                      , lr_mps_order_lin_type.sold_to_org_id
                                      , lr_mps_order_lin_type.ship_from_org_id
                                      , lr_mps_order_lin_type.ship_to_org_id
                                      , lr_mps_order_lin_type.invoice_to_org_id
                                      , lr_mps_order_lin_type.drop_ship_flag	
                                      , lr_mps_order_lin_type.price_list_id
                                      , lr_mps_order_lin_type.unit_list_price 
                                      , lr_mps_order_lin_type.unit_selling_price
                                      , lr_mps_order_lin_type.calculate_price_flag
                                      , lr_mps_order_lin_type.tax_code
                                      , lr_mps_order_lin_type.tax_value
                                      , lr_mps_order_lin_type. tax_date
                                      , lr_mps_order_lin_type.shipping_method_code
                                      , lr_mps_order_lin_type.return_reason_code
                                      , lr_mps_order_lin_type.customer_po_number
                                      , lr_mps_order_lin_type.operation_code
                                      , lr_mps_order_lin_type.error_flag
                                      , lr_mps_order_lin_type.shipping_instructions
                                      , lr_mps_order_lin_type.return_context
                                      , lr_mps_order_lin_type.return_attribute1
                                      , lr_mps_order_lin_type.return_attribute2
                                      , lr_mps_order_lin_type.customer_item_id
                                      , lr_mps_order_lin_type.customer_item_id_type
                                      , lr_mps_order_lin_type.line_category_code
                                      , lr_mps_order_lin_type.creation_date
                                      , lr_mps_order_lin_type.created_by
                                      , lr_mps_order_lin_type.last_update_date
                                      , lr_mps_order_lin_type.last_updated_by
                                      , lr_mps_order_lin_type.request_id
                                      , lr_mps_order_lin_type.line_id
                                      , lr_mps_order_lin_type.payment_term_id
                                      , lr_mps_order_lin_type.request_date
                                      , lr_mps_order_lin_type.schedule_status_code
                                      , lr_mps_order_lin_type.customer_item_name
                                      , lr_mps_order_lin_type.user_item_description
                                      , lr_mps_order_lin_type.tax_exempt_flag
                                      , lr_mps_order_lin_type.tax_exempt_number
                                      , lr_mps_order_lin_type.tax_exempt_reason_code
                                      , lr_mps_order_lin_type.customer_line_number
                                      );

        INSERT INTO xx_om_lines_attr_iface_all( orig_sys_document_ref
                                              , order_source_id
                                              , request_id
                                              , vendor_product_code
                                              , average_cost
                                              , po_cost
                                              , canada_pst
                                              , return_act_cat_code
                                              , ret_orig_order_num
                                              , back_ordered_qty
                                              , ret_orig_order_line_num
                                              , ret_orig_order_date
                                              , wholesaler_item
                                              , orig_sys_line_ref
                                              , legacy_list_price
                                              , org_id
                                              , contract_details
                                              , item_Comments
                                              , line_Comments
                                              , taxable_Flag
                                              , sku_Dept
                                              , item_source
                                              , config_code
                                              , ext_top_model_line_id
                                              , ext_link_to_line_id
                                              , aops_ship_date
                                              , sas_sale_date
                                              , calc_arrival_date
                                              , creation_date
                                              , created_by
                                              , last_update_date
                                              , last_updated_by
                                              , ret_ref_header_id
                                              , ret_ref_line_id
                                              , release_num
                                              , cost_center_dept
                                              , desktop_del_addr
                                              , gsa_flag 
                                              , waca_item_ctr_num
                                              , consignment_bank_code
                                              , price_cd   
                                              , price_change_reason_cd 
                                              , price_prefix_cd
                                              , commisionable_ind  
                                              , cust_dept_description  
                                              , unit_orig_selling_price
                                              ) VALUES 
                                              ( lr_mps_order_lin_type.orig_sys_document_ref
                                              , lr_mps_order_lin_type.order_source_id
                                              , lr_mps_order_lin_type.request_id
                                              , lr_mps_order_lin_type.vendor_product_code
                                              , lr_mps_order_lin_type.average_cost
                                              , lr_mps_order_lin_type.po_cost
                                              , lr_mps_order_lin_type.canada_pst
                                              , lr_mps_order_lin_type.return_act_cat_code
                                              , lr_mps_order_lin_type.ret_orig_order_num
                                              , lr_mps_order_lin_type.back_ordered_qty
                                              , lr_mps_order_lin_type.ret_orig_order_line_num
                                              , lr_mps_order_lin_type.ret_orig_order_date
                                              , lr_mps_order_lin_type.wholesaler_item
                                              , lr_mps_order_lin_type.orig_sys_line_ref
                                              , lr_mps_order_lin_type.legacy_list_price
                                              , lr_mps_order_lin_type.org_id
                                              , lr_mps_order_lin_type.contract_details
                                              , lr_mps_order_lin_type.item_Comments
                                              , lr_mps_order_lin_type.line_comments
                                              , lr_mps_order_lin_type.taxable_flag
                                              , lr_mps_order_lin_type.sku_dept
                                              , lr_mps_order_lin_type.item_source
                                              , lr_mps_order_lin_type.config_code
                                              , lr_mps_order_lin_type.ext_top_model_line_id
                                              , lr_mps_order_lin_type.ext_link_to_line_id
                                              , lr_mps_order_lin_type.aops_ship_date
                                              , lr_mps_order_lin_type.sas_sale_date
                                              , lr_mps_order_lin_type.calc_arrival_date
                                              , lr_mps_order_lin_type.creation_date
                                              , lr_mps_order_lin_type.created_by
                                              , lr_mps_order_lin_type.last_update_date
                                              , lr_mps_order_lin_type.last_updated_by
                                              , lr_mps_order_lin_type.ret_ref_header_id
                                              , lr_mps_order_lin_type.ret_ref_line_id
                                              , lr_mps_order_lin_type.release_num
                                              , lr_mps_order_lin_type.cost_center_dept
                                              , lr_mps_order_lin_type.desktop_del_addr
                                              , lr_mps_order_lin_type.gsa_flag 
                                              , lr_mps_order_lin_type.waca_item_ctr_num
                                              , lr_mps_order_lin_type.consignment_bank_code
                                              , lr_mps_order_lin_type.price_cd   
                                              , lr_mps_order_lin_type.price_change_reason_cd 
                                              , lr_mps_order_lin_type.price_prefix_cd
                                              , lr_mps_order_lin_type.commisionable_ind  
                                              , lr_mps_order_lin_type.cust_dept_description  
                                              , lr_mps_order_lin_type.unit_orig_selling_price
                                              ); 
    END IF;
    x_return_status  := lc_return_status;
    x_return_mesg    := lc_return_mesg;	
EXCEPTION
    WHEN OTHERS THEN 
        lc_return_mesg :=  'WHEN OTHERS RAISED WHILE INSERTING INTO LINES TBL : '||SQLERRM;
        DBMS_OUTPUT.PUT_LINE(lc_return_mesg);
        x_return_status := 'Y';	
        x_return_mesg   := 	lc_return_mesg;	
        xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                             , p_error_location     => 'XX_CS_MPS_ORDER_PKG.INSERT_LINES'
                                             , p_error_message_code => 'XX_CS_MPSORD01_ERR_LOG'
                                             , p_error_msg          => lc_return_mesg
                                             );
END insert_lines;

PROCEDURE log_error_msgs( p_orig_sys_document_ref VARCHAR2
                        , p_order_source_id       NUMBER
                        ) IS	
lc_return_mesg VARCHAR2(4000);						
BEGIN
    oe_bulk_msg_pub.set_msg_context( p_entity_code                 =>  'HEADER'
                                   , p_entity_ref                     =>  NULL
                                   , p_entity_id                      =>  NULL
                                   , p_header_id                      =>  NULL
                                   , p_line_id                        =>  NULL
                                   , p_order_source_id                =>  p_order_source_id
                                   , p_orig_sys_document_ref          =>  p_orig_sys_document_ref
                                   , p_orig_sys_document_line_ref     =>  NULL
                                   , p_orig_sys_shipment_ref          => NULL
                                   , p_change_sequence                => NULL
                                   , p_source_document_type_id        => NULL
                                   , p_source_document_id             => NULL
                                   , p_source_document_line_id        => NULL
                                   , p_attribute_code                 => NULL
                                   , p_constraint_id                  => NULL );
EXCEPTION
    WHEN OTHERS THEN 
        lc_return_mesg :=  'WHEN OTHERS RAISED WHILE INSERTING INTO OE_PROCESSING_MSGS : '||SQLERRM;
        DBMS_OUTPUT.PUT_LINE(lc_return_mesg);
        xx_cs_mps_contracts_pkg.log_exception( p_object_id          => NULL
                                             , p_error_location     => 'XX_CS_MPS_ORDER_PKG.LOG_ERROR_MSGS'
                                             , p_error_message_code => 'XX_CS_MPSORD01_ERR_LOG'
                                             , p_error_msg          => lc_return_mesg
                                             );
END log_error_msgs;								

END XX_CS_MPS_ORDER_PKG;
/
SHOW ERRORS PACKAGE BODY XX_CS_MPS_ORDER_PKG;
EXIT;