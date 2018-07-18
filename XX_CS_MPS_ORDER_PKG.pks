SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CS_MPS_ORDER_PKG AS
-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  : XX_CS_MPS_ORDER_PKG.pks                                                              |
-- | Description  : This package contains procedures related to Service Contracts creation        |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        02-OCT-2012   Bapuji Nanapaneni  Initial version                                   |
-- |                                                                                              |
-- +==============================================================================================+
  -- Header Record
  TYPE g_mps_order_hed_type IS RECORD ( orig_sys_document_ref        oe_headers_iface_all.orig_sys_document_ref%TYPE
                                    , order_source_id              oe_headers_iface_all.order_source_id%TYPE
                                    , org_id                       oe_headers_iface_all.org_id%TYPE
                                    , change_sequence              oe_headers_iface_all.change_sequence%TYPE
                                    , order_category               oe_headers_iface_all.order_category%TYPE
                                    , ordered_date                 oe_headers_iface_all.ordered_date%TYPE
                                    , order_type_id                oe_headers_iface_all.order_type_id%TYPE
                                    , price_list_id                oe_headers_iface_all.price_list_id%TYPE
                                    , transactional_curr_code      oe_headers_iface_all.transactional_curr_code%TYPE
                                    , salesrep_id                  oe_headers_iface_all.salesrep_id%TYPE
                                    , sales_channel_code           oe_headers_iface_all.sales_channel_code%TYPE
                                    , shipping_method_code         oe_headers_iface_all.shipping_method_code%TYPE
                                    , shipping_instructions        oe_headers_iface_all.shipping_instructions%TYPE
                                    , customer_po_number           oe_headers_iface_all.customer_po_number%TYPE
                                    , sold_to_org_id               oe_headers_iface_all.sold_to_org_id%TYPE
                                    , ship_from_org_id             oe_headers_iface_all.ship_from_org_id%TYPE
                                    , invoice_to_org_id            oe_headers_iface_all.invoice_to_org_id%TYPE
                                    , sold_to_contact_id           oe_headers_iface_all.sold_to_contact_id%TYPE
                                    , ship_to_contact_id           oe_headers_iface_all.ship_to_contact_id%TYPE
                                    , invoice_to_contact_id        oe_headers_iface_all.invoice_to_contact_id%TYPE
                                    , ship_to_org_id               oe_headers_iface_all.ship_to_org_id%TYPE
                                    , ship_to_org                  oe_headers_iface_all.ship_to_org%TYPE
                                    , ship_from_org                oe_headers_iface_all.ship_from_org%TYPE
                                    , sold_to_org                  oe_headers_iface_all.sold_to_org%TYPE
                                    , invoice_to_org               oe_headers_iface_all.invoice_to_org%TYPE
                                    , drop_ship_flag               oe_headers_iface_all.drop_ship_flag%TYPE
                                    , booked_flag                  oe_headers_iface_all.booked_flag%TYPE
                                    , operation_code               oe_headers_iface_all.operation_code%TYPE
                                    , error_flag                   oe_headers_iface_all.error_flag%TYPE
                                    , ready_flag                   oe_headers_iface_all.ready_flag%TYPE
                                    , created_by                   oe_headers_iface_all.created_by%TYPE
                                    , creation_date                oe_headers_iface_all.creation_date%TYPE
                                    , last_update_date             oe_headers_iface_all.last_update_date%TYPE
                                    , last_updated_by              oe_headers_iface_all.last_updated_by%TYPE
                                    , last_update_login            oe_headers_iface_all.last_update_login%TYPE
                                    , request_id                   oe_headers_iface_all.request_id%TYPE
                                    , batch_id                     oe_headers_iface_all.batch_id%TYPE
                                    , accounting_rule_id           oe_headers_iface_all.accounting_rule_id%TYPE
                                    , sold_to_contact              oe_headers_iface_all.sold_to_contact%TYPE
                                    , payment_term_id              oe_headers_iface_all.payment_term_id%TYPE
                                    , salesrep                     oe_headers_iface_all.salesrep%TYPE
                                    , order_source                 oe_headers_iface_all.order_source%TYPE
                                    , sales_channel                oe_headers_iface_all.sales_channel%TYPE
                                    , shipping_method              oe_headers_iface_all.shipping_method%TYPE
                                    , order_number                 oe_headers_iface_all.order_number%TYPE
                                    , tax_exempt_flag              oe_headers_iface_all.tax_exempt_flag%TYPE
                                    , tax_exempt_number            oe_headers_iface_all.tax_exempt_number%TYPE
                                    , tax_exempt_reason_code       oe_headers_iface_all.tax_exempt_reason_code%TYPE
                                    , ineligible_for_hvop          oe_headers_iface_all.ineligible_for_hvop%TYPE
                                    , created_by_store_id          xx_om_headers_attr_iface_all.created_by_store_id%TYPE
                                    , paid_at_store_id             xx_om_headers_attr_iface_all.paid_at_store_id%TYPE
                                    , paid_at_store_no             xx_om_headers_attr_iface_all.paid_at_store_no%TYPE
                                    , spc_card_number              xx_om_headers_attr_iface_all.spc_card_number%TYPE
                                    , placement_method_code        xx_om_headers_attr_iface_all.placement_method_code%TYPE
                                    , advantage_card_number        xx_om_headers_attr_iface_all.advantage_card_number%TYPE
                                    , created_by_id                xx_om_headers_attr_iface_all.created_by_id%TYPE
                                    , delivery_code                xx_om_headers_attr_iface_all.delivery_code%TYPE
                                    , delivery_method              xx_om_headers_attr_iface_all.delivery_method%TYPE
                                    , release_no                   xx_om_headers_attr_iface_all.release_no%TYPE
                                    , cust_dept_no                 xx_om_headers_attr_iface_all.cust_dept_no%TYPE
                                    , desk_top_no                  xx_om_headers_attr_iface_all.desk_top_no%TYPE
                                    , comments                     xx_om_headers_attr_iface_all.comments%TYPE
                                    , gift_flag                    xx_om_headers_attr_iface_all.gift_flag%TYPE
                                    , orig_cust_name               xx_om_headers_attr_iface_all.orig_cust_name%TYPE
                                    , od_order_type                xx_om_headers_attr_iface_all.od_order_type%TYPE
                                    , ship_to_sequence             xx_om_headers_attr_iface_all.ship_to_sequence%TYPE
                                    , ship_to_address1             xx_om_headers_attr_iface_all.ship_to_address1%TYPE
                                    , ship_to_address2             xx_om_headers_attr_iface_all.ship_to_address2%TYPE
                                    , ship_to_city                 xx_om_headers_attr_iface_all.ship_to_city%TYPE
                                    , ship_to_state                xx_om_headers_attr_iface_all.ship_to_state%TYPE
                                    , ship_to_country              xx_om_headers_attr_iface_all.ship_to_country%TYPE
                                    , ship_to_county               xx_om_headers_attr_iface_all.ship_to_county%TYPE
                                    , ship_to_zip                  xx_om_headers_attr_iface_all.ship_to_zip%TYPE
                                    , ship_to_name                 xx_om_headers_attr_iface_all.ship_to_name%TYPE
                                    , bill_to_name                 xx_om_headers_attr_iface_all.bill_to_name%TYPE
                                    , cust_contact_name            xx_om_headers_attr_iface_all.cust_contact_name%TYPE
                                    , cust_pref_phone              xx_om_headers_attr_iface_all.cust_pref_phone%TYPE
                                    , cust_pref_phextn             xx_om_headers_attr_iface_all.cust_pref_phextn%TYPE
                                    , cust_pref_email              xx_om_headers_attr_iface_all.cust_pref_email%TYPE
                                    , imp_file_name                xx_om_headers_attr_iface_all.imp_file_name%TYPE
                                    , tax_rate                     xx_om_headers_attr_iface_all.tax_rate%TYPE
                                    , order_total                  xx_om_headers_attr_iface_all.order_total%TYPE
                                    , commisionable_ind            xx_om_headers_attr_iface_all.commisionable_ind%TYPE
                                    , order_action_code            xx_om_headers_attr_iface_all.order_action_code%TYPE
                                    , order_start_time             xx_om_headers_attr_iface_all.order_start_time%TYPE
                                    , order_end_time               xx_om_headers_attr_iface_all.order_end_time%TYPE
                                    , order_taxable_cd             xx_om_headers_attr_iface_all.order_taxable_cd%TYPE
                                    , override_delivery_chg_cd     xx_om_headers_attr_iface_all.override_delivery_chg_cd%TYPE
                                    , ship_to_geocode              xx_om_headers_attr_iface_all.ship_to_geocode%TYPE
                                    , cust_dept_description        xx_om_headers_attr_iface_all.cust_dept_description%TYPE
                                    , tran_number                  xx_om_headers_attr_iface_all.tran_number%TYPE
                                    , aops_geo_code                xx_om_headers_attr_iface_all.aops_geo_code%TYPE
                                    , tax_exempt_amount            xx_om_headers_attr_iface_all.tax_exempt_amount%TYPE
                                    , sr_number	                   xx_om_headers_attr_iface_all.sr_number%TYPE
                                    );

  -- Line Record									
  TYPE g_mps_order_lin_type IS RECORD ( orig_sys_document_ref        oe_lines_iface_all.orig_sys_document_ref%TYPE
                                    , order_source_id              oe_lines_iface_all.order_source_id%TYPE         
                                    , change_sequence              oe_lines_iface_all.change_sequence%TYPE
                                    , org_id                       oe_lines_iface_all.org_id%TYPE
                                    , orig_sys_line_ref            oe_lines_iface_all.orig_sys_line_ref%TYPE
                                    , line_number                  oe_lines_iface_all.line_number%TYPE
                                    , line_type_id                 oe_lines_iface_all.line_type_id%TYPE
                                    , inventory_item_id            oe_lines_iface_all.inventory_item_id%TYPE
                                    , inventory_item               oe_lines_iface_all.inventory_item%TYPE
                                    , schedule_ship_date           oe_lines_iface_all.schedule_ship_date%TYPE
                                    , actual_shipment_date         oe_lines_iface_all.actual_shipment_date%TYPE
                                    , salesrep_id                  oe_lines_iface_all.salesrep_id%TYPE
                                    , ordered_quantity             oe_lines_iface_all.ordered_quantity%TYPE
                                    , order_quantity_uom           oe_lines_iface_all.order_quantity_uom%TYPE
                                    , shipped_quantity             oe_lines_iface_all.shipped_quantity%TYPE
                                    , sold_to_org_id               oe_lines_iface_all.sold_to_org_id%TYPE
                                    , ship_from_org_id             oe_lines_iface_all.ship_from_org_id%TYPE
                                    , ship_to_org_id               oe_lines_iface_all.ship_to_org_id%TYPE
                                    , invoice_to_org_id            oe_lines_iface_all.invoice_to_org_id%TYPE
                                    , drop_ship_flag               oe_lines_iface_all.drop_ship_flag%TYPE
                                    , price_list_id                oe_lines_iface_all.price_list_id%TYPE
                                    , unit_list_price              oe_lines_iface_all.unit_list_price%TYPE
                                    , unit_selling_price           oe_lines_iface_all.unit_selling_price%TYPE
                                    , calculate_price_flag         oe_lines_iface_all.calculate_price_flag%TYPE
                                    , tax_code                     oe_lines_iface_all.tax_code%TYPE
                                    , tax_value                    oe_lines_iface_all.tax_value%TYPE
                                    , tax_date                     oe_lines_iface_all.tax_date%TYPE
                                    , shipping_method_code         oe_lines_iface_all.shipping_method_code%TYPE
                                    , return_reason_code           oe_lines_iface_all.return_reason_code%TYPE
                                    , customer_po_number           oe_lines_iface_all.customer_po_number%TYPE
                                    , operation_code               oe_lines_iface_all.operation_code%TYPE
                                    , error_flag                   oe_lines_iface_all.error_flag%TYPE
                                    , shipping_instructions        oe_lines_iface_all.shipping_instructions%TYPE
                                    , return_context               oe_lines_iface_all.return_context%TYPE
                                    , return_attribute1            oe_lines_iface_all.return_attribute1%TYPE
                                    , return_attribute2            oe_lines_iface_all.return_attribute2%TYPE
                                    , customer_item_id             oe_lines_iface_all.customer_item_id%TYPE
                                    , customer_item_id_type        oe_lines_iface_all.customer_item_id_type%TYPE
                                    , line_category_code           oe_lines_iface_all.line_category_code%TYPE
                                    , creation_date                oe_lines_iface_all.creation_date%TYPE
                                    , created_by                   oe_lines_iface_all.created_by%TYPE
                                    , last_update_date             oe_lines_iface_all.last_update_date%TYPE
                                    , last_updated_by              oe_lines_iface_all.last_updated_by%TYPE
                                    , request_id                   oe_lines_iface_all.request_id%TYPE
                                    , line_id                      oe_lines_iface_all.line_id%TYPE
                                    , payment_term_id              oe_lines_iface_all.payment_term_id%TYPE
                                    , request_date                 oe_lines_iface_all.request_date%TYPE
                                    , schedule_status_code         oe_lines_iface_all.schedule_status_code%TYPE
                                    , customer_item_name           oe_lines_iface_all.customer_item_name%TYPE
                                    , user_item_description        oe_lines_iface_all.user_item_description%TYPE
                                    , tax_exempt_flag              oe_lines_iface_all.tax_exempt_flag%TYPE
                                    , tax_exempt_number            oe_lines_iface_all.tax_exempt_number%TYPE
                                    , tax_exempt_reason_code       oe_lines_iface_all.tax_exempt_reason_code%TYPE
                                    , customer_line_number  	   oe_lines_iface_all.customer_line_number%TYPE
                                    , vendor_product_code          xx_om_lines_attr_iface_all.vendor_product_code%TYPE
                                    , average_cost                 xx_om_lines_attr_iface_all.average_cost%TYPE
                                    , po_cost                      xx_om_lines_attr_iface_all.po_cost%TYPE
                                    , canada_pst                   xx_om_lines_attr_iface_all.canada_pst%TYPE
                                    , return_act_cat_code          xx_om_lines_attr_iface_all.return_act_cat_code%TYPE
                                    , ret_orig_order_num           xx_om_lines_attr_iface_all.ret_orig_order_num%TYPE
                                    , back_ordered_qty             xx_om_lines_attr_iface_all.back_ordered_qty%TYPE
                                    , ret_orig_order_line_num      xx_om_lines_attr_iface_all.ret_orig_order_line_num%TYPE
                                    , ret_orig_order_date          xx_om_lines_attr_iface_all.ret_orig_order_date%TYPE
                                    , wholesaler_item              xx_om_lines_attr_iface_all.wholesaler_item%TYPE
                                    , legacy_list_price            xx_om_lines_attr_iface_all.legacy_list_price%TYPE
                                    , contract_details             xx_om_lines_attr_iface_all.contract_details%TYPE
                                    , item_Comments                xx_om_lines_attr_iface_all.item_Comments%TYPE
                                    , line_Comments                xx_om_lines_attr_iface_all.line_Comments%TYPE
                                    , taxable_Flag                 xx_om_lines_attr_iface_all.taxable_Flag%TYPE
                                    , sku_Dept                     xx_om_lines_attr_iface_all.sku_Dept%TYPE
                                    , item_source                  xx_om_lines_attr_iface_all.item_source%TYPE
                                    , config_code                  xx_om_lines_attr_iface_all.config_code%TYPE
                                    , ext_top_model_line_id        xx_om_lines_attr_iface_all.ext_top_model_line_id%TYPE
                                    , ext_link_to_line_id          xx_om_lines_attr_iface_all.ext_link_to_line_id%TYPE
                                    , aops_ship_date               xx_om_lines_attr_iface_all.aops_ship_date%TYPE
                                    , sas_sale_date                xx_om_lines_attr_iface_all.sas_sale_date%TYPE
                                    , calc_arrival_date            xx_om_lines_attr_iface_all.calc_arrival_date%TYPE
                                    , ret_ref_header_id            xx_om_lines_attr_iface_all.ret_ref_header_id%TYPE
                                    , ret_ref_line_id              xx_om_lines_attr_iface_all.ret_ref_line_id%TYPE
                                    , release_num                  xx_om_lines_attr_iface_all.release_num%TYPE
                                    , cost_center_dept             xx_om_lines_attr_iface_all.release_num%TYPE
                                    , desktop_del_addr             xx_om_lines_attr_iface_all.desktop_del_addr%TYPE
                                    , gsa_flag                     xx_om_lines_attr_iface_all.gsa_flag%TYPE
                                    , waca_item_ctr_num            xx_om_lines_attr_iface_all.waca_item_ctr_num%TYPE
                                    , consignment_bank_code        xx_om_lines_attr_iface_all.consignment_bank_code%TYPE
                                    , price_cd                     xx_om_lines_attr_iface_all.price_cd%TYPE
                                    , price_change_reason_cd       xx_om_lines_attr_iface_all.price_change_reason_cd%TYPE
                                    , price_prefix_cd              xx_om_lines_attr_iface_all.price_prefix_cd%TYPE
                                    , commisionable_ind            xx_om_lines_attr_iface_all.commisionable_ind%TYPE
                                    , cust_dept_description        xx_om_lines_attr_iface_all.cust_dept_description%TYPE
                                    , unit_orig_selling_price	   xx_om_lines_attr_iface_all.unit_orig_selling_price%TYPE
                                    );

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
PROCEDURE CREATE_MPS_ORDER( x_return_status  IN OUT NOCOPY VARCHAR2
                          , x_return_mesg    IN OUT NOCOPY VARCHAR2
                          , p_HDR_REC        IN XX_CS_ORDER_HDR_REC
                          , P_LIN_TBL        IN XX_CS_ORDER_LINES_TBL
                          ); 

  -- +==================================================================================+
  -- | Name  : INSERT_HEADER                                                            |
  -- | Description      : This Procedure will insert into OE_HEADER_IFACE_ALL table send|
  -- |                    from CREATE_ORDER                                             |
  -- |                                                                                  |
  -- | Parameters:        x_return_status IN OUT VARCHAR2 Return status                 |
  -- |                    x_return_msg    IN OUT VARCHAR2 Return Message                |
  -- |                    p_lin_iface_rec IN     g_mps_order_lin_type Line Record       |
  -- +==================================================================================+ 
PROCEDURE insert_header( p_hdr_iface_rec  IN G_MPS_ORDER_HED_TYPE
                       , x_return_status  IN OUT NOCOPY VARCHAR2

                       , x_return_mesg    IN OUT NOCOPY VARCHAR2

                       );
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

                       );
END XX_CS_MPS_ORDER_PKG;
/
SHOW ERRORS PACKAGE XX_CS_MPS_ORDER_PKG;
EXIT;