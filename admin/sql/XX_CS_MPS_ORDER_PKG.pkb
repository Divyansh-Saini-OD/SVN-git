SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CS_MPS_ORDER_PKG AS
-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  : XX_CS_MPS_ORDER_PKG.pkb                                                              |
-- | Description  : This package contains procedures related to Service Contracts creation        |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        02-OCT-2012   Bapuji Nanapaneni  Initial version                                   |
-- |                                                                                              |
-- +==============================================================================================+

PROCEDURE CREATE_ORDER( x_return_status  IN OUT NOCOPY VARCHAR2
                      , x_return_mesg    IN OUT NOCOPY VARCHAR2
					  , p_sr_number      IN            VARCHAR2
                      ) AS 
  -- +=====================================================================+
  -- | Name  : CREATE_ORDER                                                |
  -- | Description      : This Procedure will create Record in OM IFACE TBL|
  -- |                                                                     |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        x_return_status IN OUT VARCHAR2 Return status    |
  -- |                    x_return_msg    IN OUT VARCHAR2 Return Message   |
  -- +=====================================================================+
  CURSOR c_header_info (p_incident_number VARCHAR2) IS
  SELECT cf.debrief_header_id
       , cb.incident_number
       , cb.customer_id partyid
       , cb.bill_to_site_use_id
       , cb.ship_to_site_use_id
       , cb.inv_organization_id 
       , cb.bill_to_contact_id invoice_contact_id
       , cb.ship_to_contact_id ship_contact_id
       , cb.current_contact_person_id sold_contact_id
    FROM cs_incidents_all_b   cb
       , jtf_tasks_b          jb
       , jtf_task_assignments ja
       , csf_debrief_headers  cf
   WHERE cf.task_assignment_id = ja.task_assignment_id
     AND ja.task_id            = jb.task_id
     AND jb.source_object_id   = cb.incident_id
     AND cb.incident_number    = p_incident_number;

  CURSOR c_line_info (p_header_id IN NUMBER) IS
  SELECT debrief_header_id
       , debrief_line_number
       , inventory_item_id
       , issuing_inventory_org_id lnv_org_id
       , uom_code
       , quantity 
    FROM csf_debrief_lines 
   WHERE debrief_header_id = p_header_id ;--127;  

  lc_orig_sys_document_ref     oe_headers_iface_all.orig_sys_document_ref%TYPE   := NULL;
  ln_org_id                    oe_headers_iface_all.org_id%TYPE                  := FND_PROFILE.VALUE('ORG_ID');
  ln_order_source_id           oe_headers_iface_all.order_source_id%TYPE         := NULL;  
  lc_change_sequence           oe_headers_iface_all.change_sequence%TYPE         := NULL;
  lc_order_category            oe_headers_iface_all.order_category%TYPE          := 'ORDER';           
  ln_order_type_id             oe_headers_iface_all.order_type_id%TYPE           := NULL;
  ln_price_list_id             oe_headers_iface_all.price_list_id%TYPE           := NULL;
  lc_transactional_curr_code   oe_headers_iface_all.transactional_curr_code%TYPE := 'USD';
  ln_salesrep_id               oe_headers_iface_all.salesrep_id%TYPE             := FND_PROFILE.VALUE('ONT_DEFAULT_PERSON_ID');
  lc_sales_channel_code        oe_headers_iface_all.sales_channel_code%TYPE      := NULL;
  lc_shipping_method_code      oe_headers_iface_all.shipping_method_code%TYPE    := NULL;
  lc_shipping_instructions     oe_headers_iface_all.shipping_instructions%TYPE   := NULL;
  lc_customer_po_number        oe_headers_iface_all.customer_po_number%TYPE      := NULL;
  ln_sold_to_org_id            oe_headers_iface_all.sold_to_org_id%TYPE          := NULL;
  ln_ship_from_org_id          oe_headers_iface_all.ship_from_org_id%TYPE        := NULL;
  ln_invoice_to_org_id         oe_headers_iface_all.invoice_to_org_id%TYPE       := NULL;
  ln_sold_to_contact_id        oe_headers_iface_all.sold_to_contact_id%TYPE      := NULL;
  ln_ship_to_contact_id        oe_headers_iface_all.sold_to_contact_id%TYPE      := NULL;
  ln_invoice_to_contact_id     oe_headers_iface_all.sold_to_contact_id%TYPE     := NULL;
  ln_ship_to_org_id            oe_headers_iface_all.ship_to_org_id%TYPE          := NULL;
  lc_drop_ship_flag            oe_headers_iface_all.drop_ship_flag%TYPE          := NULL;
  lc_booked_flag               oe_headers_iface_all.booked_flag%TYPE             := 'Y';
  lc_operation_code            oe_headers_iface_all.operation_code%TYPE          := 'INSERT';
  lc_error_flag                oe_headers_iface_all.error_flag%TYPE              := NULL;
  lc_ready_flag                oe_headers_iface_all.ready_flag%TYPE              := 'Y';
  ln_user_id                   oe_headers_iface_all.created_by%TYPE              := NVL(FND_GLOBAL.USER_ID,-1);
  ld_sysdate                   oe_headers_iface_all.creation_date%TYPE           := SYSDATE;
  ln_payment_term_id           oe_headers_iface_all.payment_term_id%TYPE         := NULL;
  lc_tax_exempt_flag           oe_headers_iface_all.tax_exempt_flag%TYPE         := NULL;
  ln_tax_exempt_number         oe_headers_iface_all.tax_exempt_number%TYPE       := NULL;
  lc_tax_exempt_reason_code    oe_headers_iface_all.tax_exempt_reason_code%TYPE  := NULL;
  
  lc_orig_sys_line_ref         oe_lines_iface_all.orig_sys_line_ref%TYPE         := NULL;
  ln_line_type_id              oe_lines_iface_all.line_type_id%TYPE              := NULL;
  ln_item_id                   oe_lines_iface_all.inventory_item_id%TYPE         := NULL;
  ln_lin_inv_org_id            oe_lines_iface_all.ship_from_org_id%TYPE          := NULL;
  ln_ord_qty                   oe_lines_iface_all.ordered_quantity%TYPE          := 0;
  lc_uom                       oe_lines_iface_all.order_quantity_uom%TYPE        := NULL;  
  lc_calculate_price_flag      oe_lines_iface_all.calculate_price_flag%TYPE      := 'N';  
  lc_line_category_code        oe_lines_iface_all.line_category_code%TYPE        := 'ORDER';
  ln_lin_ship_from_org_id      oe_headers_iface_all.ship_from_org_id%TYPE        := NULL;
  --need to mapp header and line attributes from raj custom tbls once she gives.
BEGIN
  DBMS_OUTPUT.PUT_LINE('BEGIN OF LOOP');
  
  --pric_list_id
  ln_price_list_id := OE_Sys_Parameters.value('XX_OM_SAS_PRICE_LIST',ln_org_id);
  
  --ORDER_SOURCE_ID
  BEGIN
    SELECT order_source_id 
      INTO ln_order_source_id
      FROM oe_order_sources 
     WHERE name = 'MPS'; 
	 
  EXCEPTION
     WHEN OTHERS THEN
	 DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED WHILE DERVING ORDER_SOURCE : '||SQLERRM);	
	 lc_error_flag := 'Y';
  END;
  
  -- order_type_id
  BEGIN
    SELECT transaction_type_id
      INTO ln_order_type_id
      FROM oe_transaction_types_tl
     WHERE NAME = 'MPS US Standard';
  EXCEPTION
     WHEN OTHERS THEN
	 DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED WHILE DERVING ORDER_TYPE : '||SQLERRM);	
	 lc_error_flag := 'Y';
  END;

  BEGIN  
    SELECT transaction_type_id
      INTO ln_line_type_id
      FROM oe_transaction_types_tl
     WHERE NAME = 'OD US MPS - LINE';
  EXCEPTION
     WHEN OTHERS THEN
	 DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED WHILE DERVING LINE_TYPE : '||SQLERRM);	
	 lc_error_flag := 'Y';
  END;
   

   
  FOR r_header_info IN c_header_info (p_sr_number) LOOP
  
    lc_orig_sys_document_ref  := r_header_info.incident_number;

    BEGIN
      SELECT cust_account_id 
        INTO ln_sold_to_org_id
        FROM hz_cust_accounts_all
       WHERE party_id = r_header_info.partyid;
    EXCEPTION
      WHEN OTHERS THEN
	  DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED WHILE DERVING CUSTOMER : '||SQLERRM);	
	  lc_error_flag := 'Y';
    END;    
    BEGIN
      SELECT standard_terms
        INTO ln_payment_term_id
        FROM hz_customer_profiles
       WHERE cust_account_id = ln_sold_to_org_id
         AND site_use_id IS NULL; 
    EXCEPTION
      WHEN OTHERS THEN
	  DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED WHILE DERVING CUSTOMER : '||SQLERRM);	
	  lc_error_flag := 'Y';
    END;
	
    ln_ship_from_org_id       := r_header_info.inv_organization_id;
    ln_invoice_to_org_id      := r_header_info.bill_to_site_use_id;
    ln_sold_to_contact_id     := r_header_info.sold_contact_id;
    ln_ship_to_contact_id     := r_header_info.ship_contact_id;
    ln_invoice_to_contact_id  := r_header_info.invoice_contact_id;
    ln_ship_to_org_id         := r_header_info.ship_to_site_use_id;          
    
    
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
                                    ( lc_orig_sys_document_ref
                                    , ln_order_source_id
                                    , ln_org_id
                                    , lc_change_sequence
                                    , lc_order_category
                                    , ld_sysdate
                                    , ln_order_type_id
                                    , ln_price_list_id
                                    , lc_transactional_curr_code
                                    , ln_salesrep_id
                                    , lc_sales_channel_code
                                    , lc_shipping_method_code
                                    , lc_shipping_instructions
                                    , lc_customer_po_number
                                    , ln_sold_to_org_id
                                    , ln_ship_from_org_id
                                    , ln_invoice_to_org_id
                                    , ln_sold_to_contact_id
                                    , ln_ship_to_contact_id
                                    , ln_invoice_to_contact_id
                                    , ln_ship_to_org_id
                                    , NULL
                                    , NULL
                                    , NULL
                                    , NULL  
                                    , lc_drop_ship_flag
                                    , lc_booked_flag
                                    , lc_operation_code
                                    , lc_error_flag
                                    , lc_ready_flag
                                    , ln_user_id
                                    , ld_sysdate
                                    , ld_sysdate
                                    , ln_user_id
                                    , NULL
                                    , NULL
                                    , NULL
                                    , NULL
                                    , NULL
                                    , ln_payment_term_id 
                                    , NULL
                                    , NULL
                                    , NULL
                                    , NULL
                                    , NULL
                                    , lc_tax_exempt_flag           
                                    , ln_tax_exempt_number         
                                    , lc_tax_exempt_reason_code 
                                    , NULL
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
                                            ( lc_orig_sys_document_ref
                                            , ln_order_source_id
                                            , NULL --created_by_store_id
                                            , NULL --paid_at_store_id
                                            , NULL --paid_at_store_no
                                            , NULL --spc_card_number
                                            , NULL --placement_method_code
                                            , NULL --advantage_card_number
                                            , NULL --created_by_id
                                            , NULL --delivery_code
                                            , NULL --delivery_method
                                            , NULL --release_number
                                            , NULL --cost_center_dept
                                            , NULL --desk_del_addr
                                            , NULL --comments
                                            , ld_sysdate
                                            , ln_user_id
                                            , ld_sysdate
                                            , ln_user_id
                                            , NULL --request_id
                                            , NULL --batch_id
                                            , NULL --gift_flag
                                            , NULL --orig_cust_name
                                            , NULL --od_order_type
                                            , NULL --ship_to_sequence
                                            , NULL --ship_to_address1
                                            , NULL --ship_to_address2
                                            , NULL --ship_to_city
                                            , NULL --ship_to_state
                                            , NULL --ship_to_country
                                            , NULL --ship_to_county
                                            , NULL --ship_to_zip
                                            , NULL --ship_to_name
                                            , NULL --bill_to_name
                                            , NULL --cust_contact_name
                                            , NULL --cust_pref_phone
                                            , NULL --cust_pref_phextn
                                            , NULL --cust_pref_email
                                            , NULL --imp_file_name
                                            , NULL --tax_rate 
                                            , 0    -- order_total
                                            , NULL --commisionable_ind
                                            , NULL --order_action_code
                                            , NULL --order_start_time
                                            , NULL --order_send_time
                                            , NULL --order_taxable_cd
                                            , NULL --override_delivery_chg_id
                                            , NULL --ship_to_geo_code
                                            , NULL --cust_dept_description
                                            , NULL --tran_number
                                            , NULL --aops_geo_code
                                            , NULL --tax_exempt_amount
                                            , NULL --sr_number
                                            );
    
    FOR r_line_info IN c_line_info(r_header_info.debrief_header_id) LOOP

      lc_orig_sys_line_ref     := r_line_info.debrief_line_number;
      ln_item_id               := r_line_info.inventory_item_id;
      ln_lin_ship_from_org_id  := r_line_info.lnv_org_id;
      ln_ord_qty               := r_line_info.quantity;
      lc_uom                   := r_line_info.uom_code;
      
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
                                    ( lc_orig_sys_document_ref
                                    , ln_order_source_id
                                    , lc_change_sequence
                                    , ln_org_id	
                                    , lc_orig_sys_line_ref
                                    , lc_orig_sys_line_ref
                                    , ln_line_type_id
                                    , ln_item_id
                                    , NULL
                                    , NULL
                                    , NULL
                                    , ln_salesrep_id
                                    , ln_ord_qty
                                    , lc_uom 
                                    , ln_ord_qty
                                    , ln_sold_to_org_id
                                    , ln_lin_ship_from_org_id
                                    , ln_ship_to_org_id
                                    , ln_invoice_to_org_id
                                    , lc_drop_ship_flag	
                                    , ln_price_list_id
                                    , 0 --unit_list_price
                                    , 0 --unit_selling_price
                                    , lc_calculate_price_flag
                                    , NULL
                                    , NULL
                                    , NULL 
                                    , lc_shipping_method_code
                                    , NULL
                                    , lc_customer_po_number
                                    , lc_operation_code
                                    , lc_error_flag
                                    , lc_shipping_instructions
                                    , NULL
                                    , NULL
                                    , NULL
                                    , NULL
                                    , NULL
                                    , lc_line_category_code
                                    , ld_sysdate
                                    , ln_user_id
                                    , ld_sysdate
                                    , ln_user_id
                                    , NULL
                                    , NULL
                                    , ln_payment_term_id
                                    , ld_sysdate
                                    , NULL
                                    , NULL
                                    , NULL
                                    , lc_tax_exempt_flag
                                    , ln_tax_exempt_number
                                    , lc_tax_exempt_reason_code
                                    , NULL
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
                                            , RELEASE_NUM
                                            , COST_CENTER_DEPT
                                            , DESKTOP_DEL_ADDR
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
                                            ( lc_orig_sys_document_ref
                                            , ln_order_source_id
                                            , NULL
                                            , NULL --vendor_product_code
                                            , NULL --average_cost
                                            , NULL --po_cost
                                            , NULL --canada_pst_tax
                                            , NULL --return_act_cat_code
                                            , NULL --ret_orig_order_num
                                            , NULL --backordered_qty
                                            , NULL --ret_orig_order_line_num
                                            , NULL --ret_orig_order_date
                                            , NULL --wholesaler_item
                                            , lc_orig_sys_line_ref
                                            , NULL --sku_list_price
                                            , ln_org_id
                                            , NULL --contract_details
                                            , NULL --item_note
                                            , NULL --item_comments
                                            , NULL --taxable_flag
                                            , NULL --sku_dept
                                            , NULL --item_source
                                            , NULL --config_code
                                            , NULL --ext_top_model_line_id
                                            , NULL --ext_link_to_line_id
                                            , NULL --aops_ship_date
                                            , NULL --sas_sale_date
                                            , NULL --calc_arrival_date
                                            , ld_sysdate
                                            , ln_user_id
                                            , ld_sysdate
                                            , ln_user_id
                                            , NULL --ret_ref_header_id
                                            , NULL --ret_ref_line_id
                                            , NULL -- RELEASE_NUM
                                            , NULL -- COST_CENTER_DEPT
                                            , NULL -- DESKTOP_DEL_ADDR
                                            , NULL -- gsa_flag 
                                            , NULL -- waca_item_ctr_num
                                            , NULL -- consignment_bank_code
                                            , NULL -- price_cd   
                                            , NULL -- price_change_reason_cd 
                                            , NULL -- price_prefix_cd
                                            , NULL -- commisionable_ind  
                                            , NULL -- cust_dept_description  
                                            , NULL -- unit_orig_selling_price
                                            ); 
    END LOOP;  
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('END OF LOOP');

EXCEPTION
  WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('WHEN OTHERS RAISED : '||SQLERRM);	
  lc_error_flag := 'Y';
END CREATE_ORDER;
END XX_CS_MPS_ORDER_PKG;
/
SHOW ERRORS PACKAGE BODY XX_CS_MPS_ORDER_PKG;