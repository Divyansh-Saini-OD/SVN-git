SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_OM_SACCT_CONC_PKG AS

-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_OM_SACCT_CONC_PKG                                            |
-- | Description      : This Program will load all sales orders from         |
-- |                    Legacy System(SACCT) into EBIZ                       |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |DRAFT 1A   06-APR-2007   Bapuji Nanapaneni Initial draft version         |
-- |      1.0  21-JUN-2007                     Modified the code to          |
-- |                                           add user_item_description     |
-- |      1.1  22-JUN-2007   Manish Chavan     Added code to identify store  |
-- |                                           customer by Store No:Country  |
-- |                                           Added function to convert UOM |
-- |      1.2  24-JUL-2007   Manish Chavan     Added logic to process TAX    |
-- |                                           REFUNDS, POS/AOPS Order #     |
-- |      1.3  07-AUG-2007   Manish Chavan     Added POS fixes and Returns   |
-- |                                           Fixes                         |
-- |      1.4  11-SEP-2007   Bapuji Nanapaneni Added gsa_flag at process_line|
-- |                                       and process adjustment lines proc |
-- |      1.5  01-DEC-2008   Bapuji Nanapaneni	Defaulting the CC APP CODE   |
-- |                                          and Date if null and commented |
-- |                                            geocode API                  |
-- |      1.6      11-Mar-2009 Matthew Craig     QC13608 taxable_ind         |
-- |      1.7      14-Mar-2009 Bapuji Nanapaneni campaign code size change   |
-- |      1.8      16-Mar-2009 Matthew Craig     Performance fix per         |
-- |                                             Chuck/Satish                |
-- +=========================================================================+

PROCEDURE Process_Current_Order( p_order_tbl  IN order_tbl_type
                               , p_batch_size IN NUMBER
                               );

PROCEDURE process_header( p_order_rec    IN order_rec_type
                        , p_batch_id     IN NUMBER
                        , p_order_amt    IN OUT NOCOPY NUMBER
                        , p_order_source IN OUT NOCOPY VARCHAR2
                        , x_return_status OUT NOCOPY VARCHAR2
                        );

PROCEDURE process_line ( p_order_rec IN order_rec_type
                       , p_batch_id  IN NUMBER
                       , x_return_status OUT NOCOPY VARCHAR2
                       ) ;

PROCEDURE process_payment ( p_order_rec IN order_rec_type
                          , p_batch_id  IN NUMBER
                          , p_pay_amt   IN OUT NOCOPY NUMBER 
                          , x_return_status OUT NOCOPY VARCHAR2
                          );

PROCEDURE Process_Adjustments( p_order_rec IN order_rec_type
                             , p_batch_id  IN NUMBER
                             , x_return_status OUT NOCOPY VARCHAR2
                             );

PROCEDURE Process_Trailer( p_order_rec IN order_rec_type);

PROCEDURE set_msg_context( p_entity_code IN VARCHAR2
                         , p_warning_flag IN BOOLEAN DEFAULT FALSE
                         , p_line_ref IN VARCHAR2 DEFAULT NULL);

PROCEDURE insert_data;

PROCEDURE clear_table_memory;

PROCEDURE insert_mismatch_amount_msgs;

PROCEDURE Get_return_attributes ( p_ref_order_number IN VARCHAR2
                                , p_ref_line         IN VARCHAR2
                                , p_sold_to_org_id   IN NUMBER
                                , x_header_id        OUT NOCOPY NUMBER
                                , x_line_id          OUT NOCOPY NUMBER
                                , x_orig_sell_price  OUT NOCOPY NUMBER
                                , x_orig_ord_qty     OUT NOCOPY NUMBER
                                );

PROCEDURE Set_Header_Error(p_header_index IN BINARY_INTEGER);

PROCEDURE Process_Deposits(p_hdr_idx       IN  BINARY_INTEGER);

PROCEDURE Set_Header_Id;

PROCEDURE Load_Org_Details(p_org_no IN VARCHAR2);

PROCEDURE Create_Tax_Refund_Line(p_hdr_idx   IN BINARY_INTEGER
                               , p_order_rec IN order_rec_type);

PROCEDURE Get_return_header ( p_ref_order_number IN VARCHAR2
                            , p_sold_to_org_id   IN NUMBER
                            , x_header_id        OUT NOCOPY NUMBER
                           );

PROCEDURE Create_CashBack_Line(p_Hdr_Idx IN BINARY_INTEGER
                             , p_amount  IN NUMBER);

PROCEDURE VALIDATE_ITEM_WAREHOUSE(p_hdr_idx IN BINARY_INTEGER
                                , p_line_idx IN BINARY_INTEGER
                                , p_nonsku_flag IN VARCHAR2 DEFAULT 'N'
                                , p_item IN VARCHAR2);

PROCEDURE CLEAR_BAD_ORDERS(p_error_entity          IN VARCHAR2
                         , p_orig_sys_document_ref IN VARCHAR2
                          );

PROCEDURE WRITE_TO_FILE(p_order_tbl IN order_tbl_type);

FUNCTION GET_ORG_CODE(p_org_id IN NUMBER) RETURN VARCHAR2;

FUNCTION Get_Secure_Card_Number( p_cc_number  IN VARCHAR2) RETURN VARCHAR2
IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    RETURN (iby_cc_security_pub.secure_card_number( FND_API.G_TRUE, p_cc_number ,'N' ));
END Get_Secure_Card_Number;

-- +===================================================================+
-- | Name  : DELETE_HEADER_REC                                         |
-- | Description      : This Procedure will clear the global table for |
-- |                    BAD Order                                      |
-- |                                                                   |
-- +===================================================================+
PROCEDURE DELETE_HEADER_REC(p_idx IN BINARY_INTEGER) 
IS
BEGIN
    G_header_rec.orig_sys_document_ref.DELETE(p_idx);
    G_header_rec.order_source_id.DELETE(p_idx);
    G_header_rec.change_sequence.DELETE(p_idx);
    G_header_rec.order_category.DELETE(p_idx);
    G_header_rec.org_id.DELETE(p_idx);
    G_header_rec.ordered_date.DELETE(p_idx);
    G_header_rec.order_type_id.DELETE(p_idx);
    G_header_rec.legacy_order_type.DELETE(p_idx);
    G_header_rec.price_list_id.DELETE(p_idx);
    G_header_rec.transactional_curr_code.DELETE(p_idx);
    G_header_rec.salesrep_id.DELETE(p_idx);
    G_header_rec.sales_channel_code.DELETE(p_idx);
    G_header_rec.shipping_method_code.DELETE(p_idx);
    G_header_rec.shipping_instructions.DELETE(p_idx);
    G_header_rec.customer_po_number.DELETE(p_idx);
    G_header_rec.sold_to_org_id.DELETE(p_idx);
    G_header_rec.ship_from_org_id.DELETE(p_idx);
    G_header_rec.invoice_to_org_id.DELETE(p_idx);
    G_header_rec.sold_to_contact_id.DELETE(p_idx);
    G_header_rec.ship_to_org_id.DELETE(p_idx);
    G_header_rec.ship_to_org.DELETE(p_idx);
    G_header_rec.ship_from_org.DELETE(p_idx);
    G_header_rec.sold_to_org.DELETE(p_idx);
    G_header_rec.invoice_to_org.DELETE(p_idx);
    G_header_rec.drop_ship_flag.DELETE(p_idx);
    G_header_rec.booked_flag.DELETE(p_idx);
    G_header_rec.operation_code.DELETE(p_idx);
    G_header_rec.error_flag.DELETE(p_idx);
    G_header_rec.ready_flag.DELETE(p_idx);
    G_header_rec.payment_term_id.DELETE(p_idx);
    G_header_rec.tax_value.DELETE(p_idx);
    G_header_rec.customer_po_line_num.DELETE(p_idx);
    G_header_rec.category_code.DELETE(p_idx);
    G_header_rec.ship_date.DELETE(p_idx);
    G_header_rec.return_reason.DELETE(p_idx);
    G_header_rec.pst_tax_value.DELETE(p_idx);
    G_header_rec.return_orig_sys_doc_ref.DELETE(p_idx);
    G_header_rec.created_by.DELETE(p_idx);
    G_header_rec.creation_date.DELETE(p_idx);
    G_header_rec.last_update_date.DELETE(p_idx);
    G_header_rec.last_updated_by.DELETE(p_idx);
    G_header_rec.batch_id.DELETE(p_idx);
    G_header_rec.request_id.DELETE(p_idx);
    /* Header Attributes  */
    G_header_rec.created_by_store_id.DELETE(p_idx);
    G_header_rec.paid_at_store_id.DELETE(p_idx);
    G_header_rec.paid_at_store_no.DELETE(p_idx);
    G_header_rec.spc_card_number.DELETE(p_idx);
    G_header_rec.placement_method_code.DELETE(p_idx);
    G_header_rec.advantage_card_number.DELETE(p_idx);
    G_header_rec.created_by_id.DELETE(p_idx);
    G_header_rec.delivery_code.DELETE(p_idx);
    G_header_rec.tran_number.DELETE(p_idx);
    G_header_rec.aops_geo_code.DELETE(p_idx);
    G_header_rec.tax_exempt_amount.DELETE(p_idx);
    G_header_rec.delivery_method.DELETE(p_idx);
    G_header_rec.release_number.DELETE(p_idx);
    G_header_rec.cust_dept_no.DELETE(p_idx);
    G_header_rec.cust_dept_description.DELETE(p_idx);
    G_header_rec.desk_top_no.DELETE(p_idx);
    G_header_rec.comments.DELETE(p_idx);
    G_header_rec.start_line_index.DELETE(p_idx);
    G_header_rec.accounting_rule_id.DELETE(p_idx);
    G_header_rec.sold_to_contact.DELETE(p_idx);
    G_header_rec.header_id.DELETE(p_idx);
    G_header_rec.org_order_creation_date.DELETE(p_idx);
    G_header_rec.return_act_cat_code.DELETE(p_idx);
    G_header_rec.salesrep.DELETE(p_idx);
    G_header_rec.order_source.DELETE(p_idx);
    G_header_rec.sales_channel.DELETE(p_idx);
    G_header_rec.shipping_method.DELETE(p_idx);
    G_header_rec.deposit_amount.DELETE(p_idx);
    G_header_rec.gift_flag.DELETE(p_idx);
    G_header_rec.sas_sale_date.DELETE(p_idx);
    G_header_rec.legacy_cust_name.DELETE(p_idx);
    G_header_rec.inv_loc_no.DELETE(p_idx);
    g_header_rec.ship_to_sequence.DELETE(p_idx);
    g_header_rec.ship_to_address1.DELETE(p_idx);
    g_header_rec.ship_to_address2.DELETE(p_idx);
    g_header_rec.ship_to_city.DELETE(p_idx);
    g_header_rec.ship_to_state.DELETE(p_idx);
    g_header_rec.ship_to_country.DELETE(p_idx);
    g_header_rec.ship_to_county.DELETE(p_idx);
    g_header_rec.ship_to_zip.DELETE(p_idx);
    g_header_rec.tax_exempt_flag.DELETE(p_idx);
    g_header_rec.tax_exempt_number.DELETE(p_idx);
    g_header_rec.tax_exempt_reason.DELETE(p_idx);
    G_header_rec.ship_to_name.DELETE(p_idx);
    G_header_rec.bill_to_name.DELETE(p_idx);
    G_header_rec.cust_contact_name.DELETE(p_idx);
    G_header_rec.cust_pref_phone.DELETE(p_idx);
    G_header_rec.cust_pref_phextn.DELETE(p_idx);
    G_header_rec.deposit_hold_flag.DELETE(p_idx);
    G_header_rec.ineligible_for_hvop.DELETE(p_idx);
    G_header_rec.tax_rate.DELETE(p_idx);
    G_header_rec.order_number.DELETE(p_idx);
    G_header_rec.is_reference_return.DELETE(p_idx);
    G_header_rec.order_total.DELETE(p_idx);
    G_header_rec.commisionable_ind.DELETE(p_idx);
    G_header_rec.order_action_code.DELETE(p_idx);
    G_header_rec.order_start_time.DELETE(p_idx);
    G_header_rec.order_end_time.DELETE(p_idx);
    G_header_rec.order_taxable_cd.DELETE(p_idx);
    G_header_rec.override_delivery_chg_cd.DELETE(p_idx);
    G_header_rec.price_cd.DELETE(p_idx);
    G_header_rec.ship_to_geocode.DELETE(p_idx);

EXCEPTION
        WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in deleting BAD header  record :'||p_idx||' : '||SUBSTR(SQLERRM,1,80));
    
END DELETE_HEADER_REC;

-- +===================================================================+
-- | Name  : DELETE_LINE_REC                                           |
-- | Description      : This Procedure will clear the global table for |
-- |                    BAD Line or bad order                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE DELETE_LINE_REC(p_idx IN BINARY_INTEGER) 
IS
BEGIN
    
    G_line_rec.orig_sys_document_ref.DELETE(p_idx);
    G_line_rec.order_source_id.DELETE(p_idx);
    G_line_rec.change_sequence.DELETE(p_idx);
    G_line_rec.org_id.DELETE(p_idx);
    G_line_rec.orig_sys_line_ref.DELETE(p_idx);
    G_line_rec.ordered_date.DELETE(p_idx);
    G_line_rec.line_number.DELETE(p_idx);
    G_line_rec.line_type_id.DELETE(p_idx);
    G_line_rec.inventory_item_id.DELETE(p_idx);
    G_line_rec.inventory_item.DELETE(p_idx);
    G_line_rec.source_type_code.DELETE(p_idx);
    G_line_rec.schedule_ship_date.DELETE(p_idx);
    G_line_rec.actual_ship_date.DELETE(p_idx);
    G_line_rec.schedule_arrival_date.DELETE(p_idx);
    G_line_rec.actual_arrival_date.DELETE(p_idx);
    G_line_rec.ordered_quantity.DELETE(p_idx);
    G_line_rec.order_quantity_uom.DELETE(p_idx);
    G_line_rec.shipped_quantity.DELETE(p_idx);
    G_line_rec.sold_to_org_id.DELETE(p_idx);
    G_line_rec.ship_from_org_id.DELETE(p_idx);
    G_line_rec.ship_to_org_id.DELETE(p_idx);
    G_line_rec.invoice_to_org_id.DELETE(p_idx);
    G_line_rec.ship_to_contact_id.DELETE(p_idx);
    G_line_rec.sold_to_contact_id.DELETE(p_idx);
    G_line_rec.invoice_to_contact_id.DELETE(p_idx);
    G_line_rec.drop_ship_flag.DELETE(p_idx);
    G_line_rec.price_list_id.DELETE(p_idx);
    G_line_rec.unit_list_price.DELETE(p_idx);
    G_line_rec.unit_selling_price.DELETE(p_idx);
    G_line_rec.calculate_price_flag.DELETE(p_idx);
    G_line_rec.tax_code.DELETE(p_idx);
    G_line_rec.tax_date.DELETE(p_idx);
    G_line_rec.tax_value.DELETE(p_idx);
    G_line_rec.shipping_method_code.DELETE(p_idx);
    G_line_rec.salesrep_id.DELETE(p_idx);
    G_line_rec.return_reason_code.DELETE(p_idx);
    G_line_rec.customer_po_number.DELETE(p_idx);
    G_line_rec.operation_code.DELETE(p_idx);
    G_line_rec.error_flag.DELETE(p_idx);
    G_line_rec.shipping_instructions.DELETE(p_idx);
    G_line_rec.return_context.DELETE(p_idx);
    G_line_rec.return_attribute1.DELETE(p_idx);
    G_line_rec.return_attribute2.DELETE(p_idx);
    G_line_rec.customer_item_name.DELETE(p_idx);
    G_line_rec.customer_item_id.DELETE(p_idx);
    G_line_rec.customer_item_id_type.DELETE(p_idx);
    G_line_rec.line_category_code.DELETE(p_idx);
    G_line_rec.tot_tax_value.DELETE(p_idx);
    G_line_rec.customer_line_number.DELETE(p_idx);
    G_line_rec.created_by.DELETE(p_idx);
    G_line_rec.creation_date.DELETE(p_idx);
    G_line_rec.last_update_date.DELETE(p_idx);
    G_line_rec.last_updated_by.DELETE(p_idx);
    G_line_rec.request_id.DELETE(p_idx);
    G_line_rec.batch_id.DELETE(p_idx);
    G_line_rec.legacy_list_price.DELETE(p_idx);
    G_line_rec.vendor_product_code.DELETE(p_idx);
    G_line_rec.contract_details.DELETE(p_idx);
    G_line_rec.item_comments.DELETE(p_idx);
    G_line_rec.line_comments.DELETE(p_idx);
    G_line_rec.taxable_flag.DELETE(p_idx);
    G_line_rec.sku_dept.DELETE(p_idx);
    G_line_rec.item_source.DELETE(p_idx);
    G_line_rec.average_cost.DELETE(p_idx);
    G_line_rec.po_cost.DELETE(p_idx);
    G_line_rec.canada_pst.DELETE(p_idx);
    G_line_rec.return_act_cat_code.DELETE(p_idx);
    G_line_rec.return_reference_no.DELETE(p_idx);
    G_line_rec.back_ordered_qty.DELETE(p_idx);
    G_line_rec.return_ref_line_no.DELETE(p_idx);
    G_line_rec.org_order_creation_date.DELETE(p_idx);
    G_line_rec.wholesaler_item.DELETE(p_idx);
    G_line_rec.header_id.DELETE(p_idx);
    G_line_rec.line_id.DELETE(p_idx);
    G_line_rec.payment_term_id.DELETE(p_idx);
    G_line_rec.inventory_item.DELETE(p_idx);
    G_Line_rec.schedule_status_code.DELETE(p_idx);
    G_Line_rec.user_item_description.DELETE(p_idx);
    G_Line_rec.config_code.DELETE(p_idx);
    G_Line_rec.ext_top_model_line_id.DELETE(p_idx);
    G_Line_rec.ext_link_to_line_id.DELETE(p_idx);
    G_Line_rec.sas_sale_date.DELETE(p_idx);
    G_Line_rec.aops_ship_date.DELETE(p_idx);
    G_Line_rec.calc_arrival_date.DELETE(p_idx);
    G_Line_rec.ret_ref_header_id.DELETE(p_idx);
    G_Line_rec.ret_ref_line_id.DELETE(p_idx);
    G_Line_rec.release_number.DELETE(p_idx);
    G_Line_rec.cust_dept_no.DELETE(p_idx);
    G_Line_rec.cust_dept_description.DELETE(p_idx);
    G_Line_rec.desk_top_no.DELETE(p_idx);
    g_Line_rec.tax_exempt_flag.DELETE(p_idx);
    g_Line_rec.tax_exempt_number.DELETE(p_idx);
    g_Line_rec.tax_exempt_reason.DELETE(p_idx);
    g_Line_rec.gsa_flag.DELETE(p_idx); --Added by NB
    g_Line_rec.consignment_bank_code.DELETE(p_idx); 
    g_Line_rec.waca_item_ctr_num.DELETE(p_idx); 
    g_Line_rec.orig_selling_price.DELETE(p_idx); 
    g_line_rec.price_cd.DELETE(p_idx);
    g_line_rec.price_change_reason_cd.DELETE(p_idx);
    g_line_rec.price_prefix_cd.DELETE(p_idx);
    g_line_rec.commisionable_ind.DELETE(p_idx);
    g_line_rec.unit_orig_selling_price.DELETE(p_idx);
    
EXCEPTION
        WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in deleting BAD Line record :'||p_idx||' : '||SUBSTR(SQLERRM,1,80));
    
END DELETE_LINE_REC;

-- +===================================================================+
-- | Name  : DELETE_ADJ_REC                                            |
-- | Description      : This Procedure will clear the global table for |
-- |                    BAD Line                                       |
-- |                                                                   |
-- +===================================================================+
PROCEDURE DELETE_ADJ_REC(p_idx IN BINARY_INTEGER) 
IS
BEGIN
      /* Discount Record */
    G_line_adj_rec.orig_sys_document_ref.DELETE(p_idx);
    G_line_adj_rec.order_source_id.DELETE(p_idx);
    G_line_adj_rec.org_id.DELETE(p_idx);
    G_line_adj_rec.orig_sys_line_ref.DELETE(p_idx);
    G_line_adj_rec.orig_sys_discount_ref.DELETE(p_idx);
    G_line_adj_rec.sold_to_org_id.DELETE(p_idx);
    G_line_adj_rec.change_sequence.DELETE(p_idx);
    G_line_adj_rec.automatic_flag.DELETE(p_idx);
    G_line_adj_rec.list_header_id.DELETE(p_idx);
    G_line_adj_rec.list_line_id.DELETE(p_idx);
    G_line_adj_rec.list_line_type_code.DELETE(p_idx);
    G_line_adj_rec.applied_flag.DELETE(p_idx);
    G_line_adj_rec.operand.DELETE(p_idx);
    G_line_adj_rec.arithmetic_operator.DELETE(p_idx);
    G_line_adj_rec.pricing_phase_id.DELETE(p_idx);
    G_line_adj_rec.adjusted_amount.DELETE(p_idx);
    G_line_adj_rec.inc_in_sales_performance.DELETE(p_idx);
    G_line_adj_rec.operation_code.DELETE(p_idx);
    G_line_adj_rec.error_flag.DELETE(p_idx);
    G_line_adj_rec.request_id.DELETE(p_idx);
    G_line_adj_rec.context.DELETE(p_idx);
    G_line_adj_rec.attribute6.DELETE(p_idx);
    G_line_adj_rec.attribute7.DELETE(p_idx);
    G_line_adj_rec.attribute8.DELETE(p_idx);
    G_line_adj_rec.attribute9.DELETE(p_idx);
    G_line_adj_rec.attribute10.DELETE(p_idx);

EXCEPTION
        WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in deleting BAD ADJ record :'||p_idx||' : '||SUBSTR(SQLERRM,1,80));
    
END DELETE_ADJ_REC;
    
-- +===================================================================+
-- | Name  : DELETE_PAYMENT_REC                                        |
-- | Description      : This Procedure will clear the global table for |
-- |                    BAD Payment record  or bad order               |
-- |                                                                   |
-- +===================================================================+
PROCEDURE DELETE_PAYMENT_REC(p_idx IN BINARY_INTEGER) 
IS
BEGIN
    /* payment record */
    G_payment_rec.orig_sys_document_ref.DELETE(p_idx);
    G_payment_rec.order_source_id.DELETE(p_idx);
    G_payment_rec.orig_sys_payment_ref.DELETE(p_idx);
    G_payment_rec.org_id.DELETE(p_idx);
    G_payment_rec.payment_type_code.DELETE(p_idx);
    G_payment_rec.payment_collection_event.DELETE(p_idx);
    G_payment_rec.prepaid_amount.DELETE(p_idx);
    G_payment_rec.credit_card_number.DELETE(p_idx);
    G_payment_rec.credit_card_holder_name.DELETE(p_idx);
    G_payment_rec.credit_card_expiration_date.DELETE(p_idx);
    G_payment_rec.credit_card_code.DELETE(p_idx);
    G_payment_rec.credit_card_approval_code.DELETE(p_idx);
    G_payment_rec.credit_card_approval_date.DELETE(p_idx);
    G_payment_rec.check_number.DELETE(p_idx);
    G_payment_rec.payment_amount.DELETE(p_idx);
    G_payment_rec.operation_code.DELETE(p_idx);
    G_payment_rec.error_flag.DELETE(p_idx);
    G_payment_rec.receipt_method_id.DELETE(p_idx);
    G_payment_rec.payment_number.DELETE(p_idx);
    G_payment_rec.attribute6.DELETE(p_idx);
    G_payment_rec.attribute7.DELETE(p_idx);
    G_payment_rec.attribute8.DELETE(p_idx);
    G_payment_rec.attribute9.DELETE(p_idx);
    G_payment_rec.attribute10.DELETE(p_idx);
    G_payment_rec.sold_to_org_id.DELETE(p_idx);
    G_payment_rec.attribute11.DELETE(p_idx);
    G_payment_rec.attribute12.DELETE(p_idx);
    G_payment_rec.attribute13.DELETE(p_idx);
    G_payment_rec.attribute15.DELETE(p_idx);
    G_payment_rec.payment_set_id.DELETE(p_idx);
    
EXCEPTION
        WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in deleting BAD PAYMENT record :'||p_idx||' : '||SUBSTR(SQLERRM,1,80));
    
END DELETE_PAYMENT_REC;

-- +===================================================================+
-- | Name  : DELETE_RET_TENDER_REC                                     |
-- | Description  : This Procedure will clear the global table for BAD |
-- |                return tender record or bad order                  |
-- |                                                                   |
-- +===================================================================+
PROCEDURE DELETE_RET_TENDER_REC(p_idx IN BINARY_INTEGER) 
IS
BEGIN
    /* tender record */
    G_return_tender_rec.orig_sys_document_ref.DELETE(p_idx);
    G_return_tender_rec.orig_sys_payment_ref.DELETE(p_idx);
    G_return_tender_rec.order_source_id.DELETE(p_idx);
    G_return_tender_rec.payment_number.DELETE(p_idx);
    G_return_tender_rec.payment_type_code.DELETE(p_idx);
    G_return_tender_rec.credit_card_code.DELETE(p_idx);
    G_return_tender_rec.credit_card_number.DELETE(p_idx);
    G_return_tender_rec.credit_card_holder_name.DELETE(p_idx);
    G_return_tender_rec.credit_card_expiration_date.DELETE(p_idx);
    G_return_tender_rec.credit_amount.DELETE(p_idx);
    G_return_tender_rec.request_id.DELETE(p_idx);
    G_return_tender_rec.sold_to_org_id.DELETE(p_idx);
    G_return_tender_rec.cc_auth_manual.DELETE(p_idx);
    G_return_tender_rec.merchant_nbr.DELETE(p_idx);
    G_return_tender_rec.cc_auth_ps2000.DELETE(p_idx);
    G_return_tender_rec.allied_ind.DELETE(p_idx);
    G_return_tender_rec.sold_to_org_id.DELETE(p_idx);
    G_return_tender_rec.receipt_method_id.DELETE(p_idx);
    G_return_tender_rec.cc_mask_number.DELETE(p_idx);
    G_return_tender_rec.od_payment_type.DELETE(p_idx);
    
EXCEPTION
        WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in deleting BAD Return Tender record :'||p_idx||' : '||SUBSTR(SQLERRM,1,80));
    
END DELETE_RET_TENDER_REC;
    


-- Master Concurrent Program

PROCEDURE Upload_Data (
                           x_retcode          OUT NOCOPY NUMBER
                         , x_errbuf           OUT NOCOPY VARCHAR2
                         , p_file_name        IN         VARCHAR2
                         , p_debug_level      IN         NUMBER DEFAULT 0
                         , p_batch_size       IN         NUMBER DEFAULT 1200
                         ) IS
-- +===================================================================+
-- | Name  : Upload_Data                                               |
-- | Description      : This Procedure will vaildate the file name     |
-- |                    create multiple child request depend on file   |
-- |                    count                                          |
-- |                                                                   |
-- | Parameters      : p_file_name   IN -> SAS file name               |
-- |                   P_debug_level IN -> Debug Level i.e 0 to 5      |
-- |                   P_batch_size  IN -> Size of Batch ex. 1200      |
-- |                   x_retcode           OUT                         |
-- |                   x_errbuf            OUT                         |
-- +===================================================================+

      lc_file_name                  VARCHAR2 (100);
      lc_short_name                 VARCHAR2 (200);
      ln_request_id                 NUMBER           := 0;
      lb_wait                       BOOLEAN;
      lc_phase                      VARCHAR2 (100);
      lc_status                     VARCHAR2 (100);
      lc_devpha                     VARCHAR2 (100);
      lc_devsta                     VARCHAR2 (100);
      lc_mesg                       VARCHAR2 (100);
      lc_o_unit                     VARCHAR2(50);
      lc_fname                      VARCHAR2(100);
      lc_error_flag                  VARCHAR2(1);
      lc_return_status               VARCHAR2(1);
      lc_file_date                   VARCHAR2(20);

-- Cursor to fetch file history
CURSOR c_file_validate ( p_fname VARCHAR2) IS
      SELECT file_name, error_flag
        FROM xx_om_sacct_file_history
       WHERE file_name = p_fname;

       -- For the Parent Wait for child to finish
  l_req_data               VARCHAR2(10);
  l_req_data_counter       NUMBER;
  ln_child_req_counter     NUMBER;
  l_count                  NUMBER;

BEGIN
    x_retcode := 0;
    Process_Child( p_file_name           => p_file_name
                 , p_debug_level       => p_debug_level
                 , p_batch_size        => p_batch_size
                 , x_return_status     => lc_return_status
                 );
    IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Process Child returned error');
        RAISE FND_API.G_EXC_ERROR;
    END IF;
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Process Child was success');
    x_retcode := 0;
EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Process Child raised error');
        x_retcode := 2;
        x_errbuf := 'Please check the log file for error messages';
        raise FND_API.G_EXC_ERROR;
    WHEN OTHERS THEN
      x_retcode := 2;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Unexpected error '||substr(sqlerrm,1,200));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
      x_errbuf := 'Please check the log file for error messages';
      raise FND_API.G_EXC_ERROR;
END Upload_Data;

PROCEDURE Process_Child  (
                           p_file_name         IN          VARCHAR2
                         , p_debug_level       IN          NUMBER
                         , p_batch_size        IN          NUMBER
                         , x_return_status     OUT NOCOPY  VARCHAR2
                         ) IS

-- +===================================================================+
-- | Name  : Process_Child                                             |
-- | Description      : This Procedure will reads order by order and   |
-- |                    process the orders to interface tables. The    |
-- |                    std Bulk order import program is called to     |
-- |                    import into base tables. A record is inserted  |
-- |                    into history tables. If any error occers while |
-- |                    processing an error flag is set to Y in history|
-- |                    table                                          |
-- |                                                                   |
-- | Parameters      : p_file_name   IN -> DEFAULT 'SAS'               |
-- |                   P_debug_level IN -> Debug Level i.e 0 to 5      |
-- |                   P_batch_size  IN -> Size of Batch ex. 1500      |
-- |                   x_return_status     OUT                         |                                                |
-- +===================================================================+

    lc_input_file_handle    UTL_FILE.file_type;
    lc_input_file_path      VARCHAR2 (250);
    lc_curr_line            VARCHAR2 (1340);
    lc_return_status        VARCHAR2(100);
    ln_debug_level          NUMBER;
    lc_errbuf               VARCHAR2(2000);
    ln_retcode              NUMBER;
    lc_file_path            VARCHAR2(100) := FND_PROFILE.VALUE('XX_OM_SAS_FILE_DIR');
    lb_has_records          BOOLEAN;
    i                       BINARY_INTEGER;
    lc_orig_sys_document_ref       oe_headers_iface_all.orig_sys_document_ref%TYPE;
    lc_curr_orig_sys_document_ref  oe_headers_iface_all.orig_sys_document_ref%TYPE;
    lc_record_type          VARCHAR2(10);
    l_order_tbl             order_tbl_type;
    lc_error_flag           VARCHAR2(1) := 'N';
    lc_filename             VARCHAR2(100);
    ln_start_time           NUMBER;
    ln_end_time             NUMBER;
    j                       BINARY_INTEGER;
    lb_at_trailer           BOOLEAN := FALSE;
    lc_arch_path            VARCHAR2(100);
    ln_master_request_id    NUMBER;
    lb_read_error           BOOLEAN := FALSE;
BEGIN

x_return_status := 'S';

-- Initialize the fnd_message stack
FND_MSG_PUB.Initialize;
OE_BULK_MSG_PUB.Initialize;
G_FILE_NAME := p_file_name;

-- Initialize the Global
G_MODE := 'SAS_IMPORT';
G_ERROR_COUNT := 0;
XX_OM_HVOP_UTIL_PKG.G_USE_TEST_CC := NVL(FND_PROFILE.VALUE('XX_OM_USE_TEST_CC'),'N');

-- Set the Debug level in oe_debug_pub

IF nvl(p_debug_level, -1) >= 0 THEN
    FND_PROFILE.PUT('ONT_DEBUG_LEVEL',p_debug_level);
    oe_debug_pub.G_Debug_Level := p_debug_level;
    lc_filename := oe_debug_pub.set_debug_mode ('CONC');
END IF;

ln_debug_level := oe_debug_pub.g_debug_level;

SELECT hsecs INTO ln_start_time FROM v$timer;

BEGIN
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Entering Process_Child the debug level is :'|| ln_debug_level);
    END IF;
    FND_PROFILE.GET('CONC_REQUEST_ID',G_request_id);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Start Procedure ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Path : ' || lc_file_path);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Name : ' || p_file_name);
    -- Open the file
    lc_input_file_handle := UTL_FILE.fopen(lc_file_path, p_file_name, 'R',1000);
EXCEPTION
    WHEN UTL_FILE.invalid_path THEN
         oe_debug_pub.add ('Invalid Path: ' || SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invalid file Path: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.invalid_mode THEN
         oe_debug_pub.add ('Invalid Mode: ' || SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invalid Mode: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.invalid_filehandle THEN
         oe_debug_pub.add ('Invalid file handle: ' || SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invalid file handle: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.invalid_operation THEN
         oe_debug_pub.add ('Invalid operation: ' || SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'File does not exist: ' || SQLERRM);
         XX_OM_HVOP_UTIL_PKG.SEND_NOTIFICATION('HVOP: File MIssing','SAS trigger file is listing the HVOP file :'||p_file_name||' which can not be found under '||lc_file_path);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.read_error THEN
         oe_debug_pub.add ('Read Error: ' || SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Read Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.internal_error THEN
         oe_debug_pub.add ('Internal Error: ' || SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Internal Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN NO_DATA_FOUND THEN
         oe_debug_pub.add ('No data found: ' || SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Empty File: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN VALUE_ERROR THEN
         oe_debug_pub.add ('Value Error: ' || SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Value Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, SQLERRM);
         UTL_FILE.fclose (lc_input_file_handle);
         RAISE FND_API.G_EXC_ERROR;
END;

lb_has_records := TRUE;
i := 0;

-- Check if the file has been run before
SELECT count(file_name)
INTO g_file_run_count
FROM xx_om_sacct_file_history
WHERE file_name = p_file_name;

-- Set Batch Counter Global
G_Batch_Counter := 0;
BEGIN

    -- Load LINE_ID SEQUENCE values into g_line_id global
    SELECT oe_order_lines_s.nextval
    BULK COLLECT INTO g_line_id
    FROM xx_om_hvop_seq_lock
    WHERE ROWNUM <= 90000
    FOR UPDATE;

    -- Release the lock
    COMMIT;
    SELECT hsecs INTO ln_end_time FROM v$timer;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Time spent in Getting Line Id SEQ data is (sec) '||((ln_end_time-ln_start_time)/100));

    
    -- Set the Counter for the global
    g_Line_Id_Seq_Ctr := 1;
    LOOP
        BEGIN

            lc_curr_line := NULL;
            /* UTL FILE READ START */
            UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO MORE RECORDS TO READ');
            lb_has_records := FALSE;
            IF l_order_tbl.COUNT = 0 THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG, 'THE FILE IS EMPTY, NO RECORDS');
               RAISE FND_API.G_EXC_ERROR;
            END IF;
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while reading'||sqlerrm);
            lb_has_records := FALSE;
            IF l_order_tbl.COUNT = 0 THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG, 'THE FILE IS EMPTY NO RECORDS');
            END IF;
            RAISE FND_API.G_EXC_ERROR;
        END;

        -- Always get the exact byte length in lc_curr_line to avoid reading new line characters
        lc_curr_line := substr(lc_curr_line,1,330);
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('My Line Is :'||lc_curr_line);
        END IF;

        lc_orig_sys_document_ref := TRIM(substr(lc_curr_line,1 ,20));

        IF lc_curr_orig_sys_document_ref IS NULL THEN
           lc_curr_orig_sys_document_ref := lc_orig_sys_document_ref;
        END IF;

        -- IF Order has changed or we are at the last record of the file
        IF lc_curr_orig_sys_document_ref <> lc_orig_sys_document_ref  OR
           NOT lb_has_records
        THEN
            -- If at the trailer record
            IF lb_at_trailer THEN
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add('We are at the trailer record');
                END IF;
                Process_Trailer(l_order_tbl(1));
            ELSE
                IF NOT lb_read_error THEN
                    Process_current_order( p_order_tbl  => l_order_tbl
                                         , p_batch_size => p_batch_size);
                END IF;
            oe_debug_pub.add('After processing current order :');
            END IF;
            l_order_tbl.DELETE;
            lb_read_error := FALSE;
            i := 0;
            -- If reached the 500 count or last order then insert data into interface tables
            IF G_Header_rec.orig_sys_document_ref.COUNT >= 500 OR
            NOT lb_has_records  THEN
               insert_data;
               clear_table_memory;
            END IF;

        END IF;

        lc_curr_orig_sys_document_ref := lc_orig_sys_document_ref;

        IF NOT lb_has_records THEN
            -- nothing to process so exit the loop
            EXIT;
        END IF;

        lc_record_type := substr(lc_curr_line,21,2);


        BEGIN
            IF lc_record_type = '10' THEN -- header record
                i := i + 1;
                l_order_tbl(i).record_type := lc_record_type;
                l_order_tbl(i).file_line   := lc_curr_line;
            ELSIF lc_record_type = '11' THEN -- Header comments record
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add('The comments Rec is '|| substr(lc_curr_line,33,298));
                END IF;
                l_order_tbl(i).file_line   := l_order_tbl(i).file_line||substr(lc_curr_line,33,298);
            ELSIF lc_record_type = '12' THEN -- Header Address record
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add('The addr Rec is '|| substr(lc_curr_line,33,298));
                END IF;
                l_order_tbl(i).file_line   := l_order_tbl(i).file_line||substr(lc_curr_line,33,298);
            ELSIF lc_record_type = '20' THEN -- Line Record
                i := i + 1;
                l_order_tbl(i).record_type := lc_record_type;
                l_order_tbl(i).file_line   := lc_curr_line;
            ELSIF lc_record_type = '21' THEN  -- Line comments record
                l_order_tbl(i).file_line   := l_order_tbl(i).file_line ||substr(lc_curr_line,33,298);
            ELSIF lc_record_type = '30' THEN -- Adjustments record
                i := i + 1;
                l_order_tbl(i).record_type := lc_record_type;
                l_order_tbl(i).file_line   := lc_curr_line;
            ELSIF lc_record_type = '40' THEN -- Payment Record
                i := i + 1;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add('The Payment Rec is '|| lc_curr_line);
                END IF;
                l_order_tbl(i).record_type := lc_record_type;
                l_order_tbl(i).file_line   := lc_curr_line;
            ELSIF lc_record_type = '99' THEN -- Trailer Record
                i := i + 1;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add('The Trailer Rec is '|| lc_curr_line);
                END IF;
                l_order_tbl(i).record_type := lc_record_type;
                l_order_tbl(i).file_line   := lc_curr_line;
                lb_at_trailer := TRUE;

            END IF;
        EXCEPTION
            WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error While reading Order Record ' || lc_orig_sys_document_ref || ' The record type is '||lc_record_type);
               -- Need to skip reading this Order.
               lb_read_error := TRUE;
        END;
    END LOOP;

    -- If trailer record is missing then we need to raise hard error as it can happen as a result of file getting truncated
    -- during transmission 
    IF NOT lb_at_trailer THEN
        -- Send email notification that trailer record is missing
        XX_OM_HVOP_UTIL_PKG.SEND_NOTIFICATION('HVOP Trailer record missing','Trailer record is missing on the file :'||p_file_name);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR: Trailer record is missing on the file :'||p_file_name); 
        lc_error_flag := 'Y';
        ROLLBACK;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
    lc_error_flag := 'Y';
    ROLLBACK;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error in Process Child :'||substr(SQLERRM,1,80)); 
    -- Send email notification
    XX_OM_HVOP_UTIL_PKG.SEND_NOTIFICATION('HVOP unexpected Error','Unexpected error while processing the file : '||p_file_name || 'Check the request log for request_id :'||g_request_id);
END;

-- Save the messages logged so far
OE_BULK_MSG_PUB.Save_Messages(G_REQUEST_ID);
OE_MSG_PUB.Save_Messages(G_REQUEST_ID);

-- Commit the data to database. Even if the Import fails later we still want record to exist in
-- interface table.
COMMIT;

SELECT hsecs INTO ln_end_time FROM v$timer;

FND_FILE.PUT_LINE(FND_FILE.LOG,'Time spent in Reading data is (sec) '||((ln_end_time-ln_start_time)/100));

-- After reading the whole file Call the HVOP program to Import the data
-- Check if no error occurred during reading of file
--lc_error_flag := 'Y'; -- CNV04SPECIFIC

IF lc_error_flag = 'N' THEN

    -- Move the file to archive directory
    BEGIN
        lc_arch_path := FND_PROFILE.VALUE('XX_OM_SAS_ARCH_FILE_DIR');
        UTL_FILE.FCOPY(lc_file_path, p_file_name, lc_arch_path, p_file_name||'.done');
        UTL_FILE.FREMOVE(lc_file_path, p_file_name);
    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to move file to archieval directory');
    END;

    -- Running the file for first time
    IF g_file_run_count = 0 THEN   

        -- Get the Master Request ID
        BEGIN
            SELECT parent_request_id
            INTO ln_master_request_id
            FROM fnd_run_requests
            WHERE request_id = G_Request_Id;

        EXCEPTION
            WHEN OTHERS THEN
                ln_master_request_id := G_Request_Id;

        END;

        -- Create log into the File History Table
        INSERT INTO xx_om_sacct_file_history
          ( file_name
          , file_type
          , request_id
          , master_request_id
          , process_date
          , total_orders
          , total_lines
          , error_flag
          , creation_date
          , created_by
          , last_update_date
          , last_updated_by
          , legacy_header_count
          , legacy_line_count
          , legacy_adj_count
          , legacy_payment_count
          , legacy_header_amount
          , legacy_tax_amount
          , legacy_line_amount
          , legacy_adj_amount
          , legacy_payment_amount
          , acct_order_total
          , org_id
          , cash_back_amount
          )
        VALUES
          ( p_file_name
          , 'ORDER'
          , g_request_id
          , ln_master_request_id
          , G_Process_Date -- SYSDATE
          , G_Header_Counter
          , G_Line_Counter
          , lc_error_flag
          , SYSDATE
          , FND_GLOBAL.USER_ID
          , SYSDATE
          , FND_GLOBAL.USER_ID
          , g_header_count
          , g_line_count
          , g_adj_count
          , g_payment_count
          , g_header_tot_amt
          , g_tax_tot_amt
          , g_line_tot_amt
          , g_adj_tot_amt
          , g_payment_tot_amt
          , g_acct_order_tot
          , g_org_id
          , G_CashBack_Total
          );
    ELSE -- In rerun mode

        -- We are in rerun mode and need to update the record in xx_om_sacct_file_history
        UPDATE xx_om_sacct_file_history
        SET total_orders = total_orders + G_Header_Counter
        , total_lines = total_lines + G_Line_Counter
        , cash_back_amount = cash_back_amount + G_CashBack_Total
        WHERE file_name = p_file_name; 
   

    END IF;
    COMMIT;

    -- Set the header_ids on interface data
    SET_HEADER_ID;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Before calling HVOP API');
    OE_BULK_ORDER_IMPORT_PVT.ORDER_IMPORT_CONC_PGM(
       p_order_source_id         => NULL
     , p_orig_sys_document_ref   => NULL
     , p_validate_only           => 'N'
     , p_validate_desc_flex      => 'N'
     , p_defaulting_mode         => 'N'
     , p_num_instances           => 0
     , p_batch_size              => NULL
     , p_rtrim_data              => 'N'
     , p_process_tax             => 'N'
     , p_process_configurations  => 'N'
     , p_dummy                   => NULL
     , p_validate_configurations => 'N'
     , p_schedule_configurations => 'N'
     , errbuf                    => lc_errbuf
     , retcode                   => ln_retcode
    );
    -- oe_debug_pub.add('Return Status from OE_BULK_ORDER_IMPORT_PVT: '||ln_retcode);
    IF ln_retcode <> 0 THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Failure in Importing Orders');
    END IF;

    -- If there were orders marked for error then send email notification
    IF g_error_count > 0 THEN
        XX_OM_HVOP_UTIL_PKG.SEND_NOTIFICATION('HVOP Errors','There are '||g_error_count||' orders marked for error while processing the file :'||p_file_name);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'SAS Import program marked '||g_error_count||' orders for error out of '||g_header_count||' orders in the file :'||p_file_name);
    END IF;
ELSE
    x_return_status := 'E';
END IF;
-- Print time spent in Receipt Creation
FND_FILE.PUT_LINE(FND_FILE.LOG,'Time spent in receipt creation ' || XX_OM_SALES_ACCT_PKG.g_create_receipt_time);

EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
        x_return_status := 'E';
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Expected error in Process Child :'||substr(SQLERRM,1,80));
    WHEN OTHERS THEN
        x_return_status := 'E';
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error in Process Child :'||substr(SQLERRM,1,80));
END Process_Child;

PROCEDURE Process_Current_Order(
      p_order_tbl  IN order_tbl_type
    , p_batch_size IN NUMBER )
IS
-- +===================================================================+
-- | Name  : Process_Current_Order                                     |
-- | Description      : This Procedure will read line by line from flat|
-- |                    file and process each order by order till end  |
-- |                    of file                                        |
-- |                                                                   |
-- | Parameters:        p_order_tbl IN order tbl type                  |
-- |                    p_batch_size IN size of batch                  |
-- +===================================================================+

  ln_hdr_count      BINARY_INTEGER;
  ln_debug_level    CONSTANT NUMBER := oe_debug_pub.g_debug_level;
  ln_order_amount   NUMBER;
  ln_payment_amount NUMBER;
  ln_mismatch_ind   NUMBER;
  lc_aops_pos_flag  VARCHAR2(1);
  i                 BINARY_INTEGER;
  lc_return_status  VARCHAR2(1);
  lc_err            VARCHAR2(40);
  lb_has_tender     BOOLEAN;
BEGIN
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('In Process Current Order :'||g_batch_counter);
    END IF;

    -- Batch_IDs are preassigned for HVOP orders
    IF G_Batch_Id IS NULL OR
       g_batch_counter >= p_batch_size
    THEN
        SELECT oe_batch_id_s.nextval INTO G_batch_id FROM DUAL;
        g_batch_counter := 0;
    END IF;

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('My Batch_ID is :' || g_batch_id);
    END IF;

    -- Set the line number counter per order
    G_Line_Nbr_Counter := 0;
    ln_order_amount := 0;
    ln_payment_amount := 0;
    G_Order_Line_Tax_ctr := 0;
    G_RMA_Line_Tax_ctr  := 0;
    G_Has_Debit_Card := FALSE;
    lb_has_tender := FALSE;

    FOR k IN 1..p_order_tbl.COUNT LOOP
        
        IF p_order_tbl(k).record_type = '10' THEN
            process_header(p_order_tbl(k), g_batch_id, ln_order_amount,lc_aops_pos_flag, lc_return_status);
        ELSIF p_order_tbl(k).record_type = '20' THEN
            process_line(p_order_tbl(k), g_batch_id, lc_return_status);
        ELSIF p_order_tbl(k).record_type = '40' THEN
            lb_has_tender := TRUE;
            process_payment(p_order_tbl(k), g_batch_id, ln_payment_amount, lc_return_status);
        ELSIF p_order_tbl(k).record_type = '30' THEN
            Process_Adjustments(p_order_tbl(k), g_batch_id, lc_return_status);
        END IF;

        IF lc_return_status = 'U' THEN
            -- No need to process this order any further, exit the loop
            g_error_count := g_error_count + 1;
            GOTO END_OF_ORDER;
        END IF;

    END LOOP;
    IF ln_debug_level > 0 THEN
        oe_debug_pub.ADD('After processing all entities ' || lc_return_status, 1);
    END IF;

    ln_hdr_count := G_Header_Rec.Orig_sys_document_ref.COUNT;

    oe_debug_pub.ADD('MAC ACCT Order Total IS: '||ln_order_amount);
    -- Get the actual order total based on display distribution
    ln_order_amount := ROUND(G_Header_Rec.order_total(ln_hdr_count),2);
    oe_debug_pub.ADD('MAC Order Total IS: '||ln_order_amount);
    oe_debug_pub.ADD('MAC payment Total IS: '||ln_payment_amount);

    -- Match the Order Total with the payment total
    IF lb_has_tender AND
       ln_order_amount <> ln_payment_amount AND
       ln_order_amount <> 0
    THEN
        IF ln_debug_level > 0 THEN
            oe_debug_pub.ADD('Order Total Mismatch found: '||ln_order_amount||'-'||ln_payment_amount, 1);
        END IF;
        Set_Header_Error(ln_hdr_count);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Total Mismatch ' ||lc_aops_pos_flag);
        set_msg_context(p_entity_code => 'HEADER');
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_PAYMENT_TOTAL_MISMATCH');
        FND_MESSAGE.SET_TOKEN('ATTRIBUTE1','Total Order Amount'||ln_order_amount);
        FND_MESSAGE.SET_TOKEN('ATTRIBUTE2','Total Payment Amount'||ln_payment_amount);
        oe_bulk_msg_pub.add;
    END IF;

    -- Check if the current order has deposits against it
    -- Or check if the order amount is non zero and no tender record came

    IF G_Header_Rec.deposit_amount(ln_hdr_count) > 0 OR 
      (NOT (lb_has_tender) AND ln_order_amount <> 0) THEN
        Process_Deposits(p_hdr_idx => ln_hdr_count);
    END IF;

    -- Check if the error_flag is set on header record. If yes then make sure that we populate request_id on it.
    -- so that the error reporting can look at these errors.
    IF G_Header_Rec.error_flag(ln_hdr_count) = 'Y' AND G_Header_Rec.request_id(ln_hdr_count) IS NULL THEN
        G_Header_Rec.request_id(ln_hdr_count) := G_REQUEST_ID;
    END IF;

    IF G_Header_Rec.error_flag(ln_hdr_count) = 'Y' THEN
        g_error_count := g_error_count + 1;
        oe_debug_pub.add('This Order has errors :' || G_Header_Rec.Orig_sys_document_ref(ln_hdr_count));
    END IF;
    
    <<END_OF_ORDER>>
    IF lc_return_status = 'U' THEN
        -- Dump the order table into a file to process later
        write_to_file(p_order_tbl);
    END IF;
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Exiting Process_Current_Order :' || lc_return_status);
    END IF;

END Process_Current_Order;

PROCEDURE Process_Deposits(p_hdr_idx IN  BINARY_INTEGER) IS

-- +===================================================================+
-- | Name  : Process_Deposits                                          |
-- | Description      : This Procedure will look for any deposits exist|
-- |                    if found it will create a payment aganist the  |
-- |                    deposit                                        |
-- |                                                                   |
-- | Parameters:        p_hdr_idx IN header index                      |
-- +===================================================================+

CURSOR C_DEPOSITS (p_osd_ref IN VARCHAR2 , p_invoicing_on IN VARCHAR2) IS
     SELECT orig_sys_document_ref
        , order_source_id
        , payment_type_code
        , receipt_method_id
        , payment_set_id
        , orig_sys_payment_ref
        , avail_balance
        , credit_card_number
        , credit_card_expiration_date
        , credit_card_code
        , credit_card_approval_code
        , credit_card_approval_date
        , check_number
        , CC_AUTH_MANUAL
        , MERCHANT_NUMBER
        , CC_AUTH_PS2000
        , ALLIED_IND
        , cc_mask_number
        , od_payment_type
        , credit_card_holder_name
        , cash_receipt_id
        , debit_card_approval_ref
        , cc_entry_mode
        , cvv_resp_code
        , avs_resp_code
        , auth_entry_mode
    FROM xx_om_legacy_deposits d
    WHERE d.orig_sys_document_ref = p_osd_ref
    AND d.avail_balance > 0
    AND d.I1025_STATUS <> 'CANCELLED'
    AND NVL(error_flag, 'N') = 'N'
    AND (cash_receipt_id is NOT NULL OR p_invoicing_on = 'N' OR od_payment_type = 'AB')
    ORDER by avail_balance 
    FOR UPDATE;

    i                        BINARY_INTEGER := 0;
    j                        BINARY_INTEGER := 0;
    ln_debug_level           CONSTANT NUMBER := oe_debug_pub.g_debug_level;
    lc_orig_sys_ref          VARCHAR2(30);
    ln_dep_count             BINARY_INTEGER;
    ln_deposit_amt           NUMBER;
    ln_avail_balance         NUMBER;
    l_hold_id                NUMBER;
    l_msg_count              NUMBER;
    l_msg_data               VARCHAR2(2000);
    l_return_status          VARCHAR2(1);
    lb_put_on_hold           BOOLEAN;
    lc_hold_comments         VARCHAR2(1000);
    l_payment_set_id         NUMBER;
    lc_invoicing_on          VARCHAR2(1) := OE_SYS_PARAMETERS.VALUE('XX_OM_INVOICING_ON',G_Org_Id);
BEGIN
    lc_orig_sys_ref := SUBSTR(G_Header_Rec.orig_sys_document_ref(p_hdr_idx),1,9)||'001';

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Entering Process Deposits :' || lc_orig_sys_ref);
        oe_debug_pub.add('lc_orig_sys_ref : '||lc_orig_sys_ref);
        oe_debug_pub.add('lc_invoicing_on : '|| lc_invoicing_on);
    END IF;

    -- Populate header_id so that AR receipt can be adjusted.

    SELECT oe_order_headers_s.nextval
    INTO G_Header_Rec.header_id(p_hdr_idx)
    FROM DUAL;


    SAVEPOINT PROCESS_DEPOSIT;

    -- Get the order total paid by deposit
    ln_deposit_amt := G_Header_Rec.deposit_amount(p_hdr_idx);

    -- Get the current index for payment record
    i := g_payment_rec.orig_sys_document_ref.count;
   
    -- Set the counter for Payment Number counter
    j := 0;

    FOR C1 IN C_DEPOSITS(lc_orig_sys_ref, lc_invoicing_on) LOOP

        i := i + 1;
        j := j + 1;

        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('Payment Ref is :' || C1.orig_sys_payment_ref);
            oe_debug_pub.add('Deposit Amount is :' || ln_deposit_amt);
            oe_debug_pub.add('Available balance is :' || C1.avail_balance);
        END IF;
 
         -- IF pay type is 'AB' skip processing receipt creation and applying hold.
        IF c1.od_payment_type = 'AB' THEN
            EXIT;
        END IF;
       
        IF ln_deposit_amt <= C1.avail_balance THEN
            G_payment_rec.prepaid_amount(i) := ln_deposit_amt;
            -- Order Total is matched by the availbale balance
            ln_avail_balance := C1.avail_balance - ln_deposit_amt;
            ln_deposit_amt := 0;
        ELSE
            G_payment_rec.prepaid_amount(i) := C1.avail_balance;
            -- Set the remaining balance
            ln_deposit_amt := ln_deposit_amt - C1.avail_balance;
            ln_avail_balance := 0;
        END IF;

        G_payment_rec.payment_set_id(i) := C1.payment_set_id;
        -- Call the AR API to adjust the receipt it will return the payment_set_id
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('Before Calling reapply_deposit_prepayment :' || C1.cash_receipt_id);
        END IF;
  
        -- Call this API only if INVOICING is ON
        IF lc_invoicing_on = 'Y' THEN

            XX_AR_PREPAYMENTS_PKG.reapply_deposit_prepayment
            ( p_init_msg_list     => FND_API.G_FALSE 
            , p_commit            => FND_API.G_FALSE
            , p_validation_level  => FND_API.G_VALID_LEVEL_FULL
            , p_cash_receipt_id   => C1.cash_receipt_id
            , p_header_id         => G_Header_Rec.header_id(p_hdr_idx)
            , p_order_number      => to_number(G_Header_Rec.orig_sys_document_ref(p_hdr_idx))
            , p_apply_amount      => G_payment_rec.prepaid_amount(i)  
            , x_payment_set_id    => l_payment_set_id 
            , x_return_status     => l_return_status
            , x_msg_count         => l_msg_count 
            , x_msg_data          => l_msg_data 
            );
            IF l_return_status <> FND_API.G_RET_STS_SUCCESS OR l_payment_set_id IS NULL THEN
                oe_debug_pub.add('Failure in reapply_deposit_prepayment :' || l_msg_data);
                oe_debug_pub.add('Payment Set ID is :' || l_payment_set_id);
                IF l_msg_count > 0 THEN
                    FOR k in 1 .. l_msg_count loop
                        l_msg_data := fnd_msg_pub.get( p_msg_index => k, p_encoded => 'F');
                        FND_FILE.PUT_LINE(FND_FILE.LOG,l_msg_data);
                    END LOOP;
                END IF;
                -- set the payment_set_id from C1
                G_payment_rec.payment_set_id(i) := C1.payment_set_id;
                lb_put_on_hold := TRUE;
                IF l_payment_set_id IS NULL THEN
                    lc_hold_comments := ' Reapply deposit prepayment for orig_sys_payment_ref :'||c1.orig_sys_payment_ref || ' did not return payment_set_id';
                ELSE
                    lc_hold_comments := 'Failed to reapply deposit prepayment for orig_sys_payment_ref :'||c1.orig_sys_payment_ref || ' Make sure to update the payment_set_id on this payment record';
                END IF;

                FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to reapply deposit for order :'||G_Header_Rec.orig_sys_document_ref(p_hdr_idx));
            END IF;
        END IF;

        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('Payment Set ID after applying the receipt:'||G_payment_rec.payment_set_id(i));
        END IF;

        -- Update the XX_OM_LEGACY_DEPOSIT table for the available balance
        UPDATE xx_om_legacy_deposits
        SET avail_balance = ln_avail_balance
          , last_update_date = SYSDATE 
          , last_updated_by = FND_GLOBAL.USER_ID 
        WHERE CURRENT OF C_DEPOSITS;

        G_payment_rec.payment_set_id(i) := l_payment_set_id;
        G_payment_rec.payment_type_code(i) := C1.payment_type_code;
        G_payment_rec.receipt_method_id(i) := C1.receipt_method_id;
        G_payment_rec.orig_sys_payment_ref(i):= C1.orig_sys_payment_ref;
        G_payment_rec.credit_card_number(i) := C1.credit_card_number;
        G_payment_rec.credit_card_expiration_date(i) := C1.credit_card_expiration_date;
        G_payment_rec.credit_card_code(i) := C1.credit_card_code;
        G_payment_rec.credit_card_approval_code(i) := C1.credit_card_approval_code;
        G_payment_rec.credit_card_approval_date(i) := C1.credit_card_approval_date;
        G_payment_rec.check_number(i) := C1.check_number;
        G_payment_rec.attribute6(i) := C1.CC_AUTH_MANUAL;
        G_payment_rec.attribute7(i) := C1.MERCHANT_NUMBER;
        G_payment_rec.attribute8(i) := C1.CC_AUTH_PS2000;
        G_payment_rec.attribute9(i) := C1.ALLIED_IND;
        G_payment_rec.attribute10(i) := C1.cc_mask_number;
        G_payment_rec.attribute11(i) := C1.od_payment_type;
        G_payment_rec.attribute12(i) := C1.DEBIT_CARD_APPROVAL_REF;
        G_payment_rec.attribute13(i) := C1.CC_ENTRY_MODE||':'||C1.CVV_RESP_CODE||':'||C1.AVS_RESP_CODE||':'||C1.AUTH_ENTRY_MODE;
        G_payment_rec.attribute15(i) := C1.cash_receipt_id;
        G_payment_rec.credit_card_holder_name(i) := C1.credit_card_holder_name;


        G_payment_rec.orig_sys_document_ref(i) := G_Header_Rec.orig_sys_document_ref(p_hdr_idx);
        G_payment_rec.sold_to_org_id(i) := G_Header_Rec.sold_to_org_id(p_hdr_idx);
        G_payment_rec.order_source_id(i):= G_Header_Rec.order_source_id(p_hdr_idx);
        G_payment_rec.payment_number(i) := j;
        G_payment_rec.payment_amount(i) := G_payment_rec.prepaid_amount(i);

        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('OD Payment type is :' || G_payment_rec.attribute11(i));
            oe_debug_pub.ADD('receipt_method = '||G_payment_rec.receipt_method_id(i));
            oe_debug_pub.ADD('orig_sys_document_ref = '||G_payment_rec.orig_sys_document_ref(i));
            oe_debug_pub.ADD('order_source_id = '||G_payment_rec.order_source_id(i));
            oe_debug_pub.ADD('orig_sys_payment_ref = '||G_payment_rec.orig_sys_payment_ref(i));
            oe_debug_pub.ADD('payment_amount = '||G_payment_rec.payment_amount(i));
            oe_debug_pub.ADD('lc_cc_number = '||G_payment_rec.credit_card_number(i));
            oe_debug_pub.ADD('credit_card_expiration_date = '||G_payment_rec.credit_card_expiration_date(i));
            oe_debug_pub.ADD('credit_card_approval_code = '||G_payment_rec.credit_card_approval_code(i));
            oe_debug_pub.ADD('credit_card_approval_date = '||G_payment_rec.credit_card_approval_date(i));
            oe_debug_pub.ADD('check_number = '||G_payment_rec.check_number(i));
            oe_debug_pub.ADD('CC Auth Manual = '||G_payment_rec.attribute6(i));
            oe_debug_pub.ADD('Merchant Number = '||G_payment_rec.attribute7(i));
            oe_debug_pub.ADD('CC_AUTH_PS2000 = '||G_payment_rec.attribute8(i));
            oe_debug_pub.ADD('ALLIED_IND = '||G_payment_rec.attribute9(i));
            oe_debug_pub.ADD('CC Mask = '||G_payment_rec.attribute10(i));
            oe_debug_pub.ADD('credit_card_holder_name = '||G_payment_rec.credit_card_holder_name(i));
        END IF;
        
        IF ln_deposit_amt = 0 THEN
            EXIT;
        END IF;
    END LOOP;


    -- If Deposit record not found
    IF j = 0 THEN
        -- Need to put the order on hold
        lb_put_on_hold := TRUE;
        lc_hold_comments := 'Deposit record not found for the order. Either the record does not exist or the record is not yet processed by AR or it is marked as error';
        -- NO need to set error just add message.
        set_msg_context(p_entity_code => 'HEADER',
                        p_warning_flag => TRUE);
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_NO_DEPOSIT_FOUND');
        oe_bulk_msg_pub.add;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'WARNING: Deposit Record not found for the Order : '||G_header_Rec.orig_sys_document_ref(p_hdr_idx));
        IF ln_debug_level > 0 THEN
           oe_debug_pub.ADD(' WARNING: Deposit Record not found for the Order : '||G_header_Rec.orig_sys_document_ref(p_hdr_idx), 1);
           oe_debug_pub.ADD(' Order error flag : '||G_header_Rec.error_flag(p_hdr_idx), 1);
        END IF;
    END IF;

    -- If the Order is not totally paid by deposit then also create it with pending deposit hold.
    IF ln_deposit_amt > 0 AND j > 0 THEN
        -- Need to put the order on hold
        lb_put_on_hold := TRUE;
        lc_hold_comments := 'Partial Deposit record found. Need remaining amount :'||ln_deposit_amt ||' before we can process this order';
        FND_FILE.PUT_LINE(FND_FILE.LOG,'WARNING: Partial Deposit Record found for the Order : '||G_header_Rec.orig_sys_document_ref(p_hdr_idx));
    END IF;

    IF lb_put_on_hold THEN
        -- We will need to put this order on Pending Deposit Hold and also mark it for SOI and not HVOP
        G_header_Rec.booked_flag(p_hdr_idx) := NULL;
        G_header_Rec.batch_id(p_hdr_idx) := NULL;
        G_header_rec.deposit_hold_flag(p_hdr_idx) := 'Y';
        G_header_rec.ineligible_for_hvop(p_hdr_idx) := 'Y';
        IF NVL(G_header_Rec.error_flag(p_hdr_idx),'N') = 'N' THEN
            G_header_Rec.request_id(p_hdr_idx) := NULL;
        END IF;

        -- Get the Hold ID
        SELECT HOLD_ID
        INTO l_hold_id
        FROM oe_hold_definitions
        WHERE NAME = 'OD: SAS Pending deposit hold';

        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('After getting the hold_id '||l_hold_id);
        END IF;

        -- Insert ACTION to put this order on hold..
        INSERT INTO OE_ACTIONS_INTERFACE 
        ( org_id
        , order_source_id
        , orig_sys_document_ref
        , operation_code
        , sold_to_org_id
        , hold_id
        , change_sequence
        , comments
        )
        VALUES
        (
          G_org_id
        , G_header_Rec.order_source_id(p_hdr_idx)
        , G_header_Rec.orig_sys_document_ref(p_hdr_idx)
        , OE_GLOBALS.G_APPLY_HOLD
        , G_header_Rec.sold_to_org_id(p_hdr_idx)
        , l_hold_id
        , G_header_Rec.change_sequence(p_hdr_idx)
        , lc_hold_comments
        ); 

        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('After inserting action to put order on hold '||l_hold_id);
        END IF;

    END IF;

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add(' Exiting Process_Deposits');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO SAVEPOINT PROCESS_DEPOSIT;
        Set_Header_Error(p_hdr_idx);
        oe_debug_pub.ADD(' Failed to process Deposit for the Order : '||G_header_Rec.orig_sys_document_ref(p_hdr_idx), 1);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to process Deposit Records for Header '||g_header_rec.orig_sys_document_ref(p_hdr_idx));
        FND_FILE.PUT_LINE(FND_FILE.LOG,'The error is '||SQLERRM);
        --RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Process_Deposits;

PROCEDURE Process_Trailer( p_order_rec IN order_rec_type) IS

-- +===================================================================+
-- | Name  : Process_Trailer                                          |
-- | Description      : This Procedure will read the last line where   |
-- |                    total headers, total lines etc send in each    |
-- |                    feed and insert into history tbl               |
-- |                                                                   |
-- | Parameters:        p_order_rec IN order_rec_type                  |
-- +===================================================================+

ln_debug_level  CONSTANT NUMBER := oe_debug_pub.g_debug_level;
lc_process_date VARCHAR2(14);
lb_day_deduct   BOOLEAN := FALSE;
BEGIN
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Entering  Trailer Header');
    END IF;

        g_header_count    := SUBSTR(p_order_rec.file_line, 42,  7);
        g_line_count      := SUBSTR(p_order_rec.file_line, 50,  7);
        g_adj_count       := SUBSTR(p_order_rec.file_line, 58,  7);
        g_payment_count   := SUBSTR(p_order_rec.file_line, 66,  7);
        -- Need to read the Order Total based on display distribution of discount records.
        g_acct_order_tot  := SUBSTR(p_order_rec.file_line, 73, 13);
        g_header_tot_amt  := SUBSTR(p_order_rec.file_line, 180, 13);
        g_tax_tot_amt     := SUBSTR(p_order_rec.file_line, 86, 13);
        g_line_tot_amt    := SUBSTR(p_order_rec.file_line, 99, 13);
        g_adj_tot_amt     := SUBSTR(p_order_rec.file_line, 112, 13);
        g_payment_tot_amt := SUBSTR(p_order_rec.file_line, 125, 13);

        -- Read the Process Date from tariler record
        lc_process_date := NVL(TRIM(SUBSTR(p_order_rec.file_line,193,14)),to_char(sysdate,'YYYYMMDDHH24MISS'));
        BEGIN
            IF TO_NUMBER(SUBSTR(lc_process_date,9,2)) < 10 THEN
                g_process_date := TRUNC(TO_DATE(lc_process_date,'YYYYMMDDHH24MISS')) - 1;
            ELSE
                g_process_date := TRUNC(TO_DATE(lc_process_date,'YYYYMMDDHH24MISS'));
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error reading Process Date from trailer record :' || lc_process_date );
                g_process_date := TRUNC(SYSDATE);
        END;
        

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Header Count is :'||g_header_count);
        oe_debug_pub.add('Line Count is :'||g_line_count);
        oe_debug_pub.add('Adj Count is :'||g_adj_count);
        oe_debug_pub.add('Payment Count is :'||g_payment_count);
        oe_debug_pub.add('Header Amount is :'||g_header_tot_amt);
        oe_debug_pub.add('Tax Total is :'||g_tax_tot_amt);
        oe_debug_pub.add('Line Total is :'||g_line_tot_amt);
        oe_debug_pub.add('Adj Total is :'||g_adj_tot_amt);
        oe_debug_pub.add('Payment Total is :'||g_payment_tot_amt);
        oe_debug_pub.add('Process Date derived is :'||g_process_date);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to process trailer record ');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'The error is '||SQLERRM);
END Process_Trailer;

PROCEDURE process_header(
      p_order_rec IN order_rec_type
    , p_batch_id  IN NUMBER
    , p_order_amt IN OUT NOCOPY NUMBER
    , p_order_source IN OUT NOCOPY VARCHAR2
    , x_return_status OUT NOCOPY VARCHAR2
    )
IS

-- +===================================================================+
-- | Name  : process_header                                            |
-- | Description      : This Procedure will read the header line       |
-- |                    validate , derive and insert into oe_header_   |
-- |                    iface_all tbl and xx_om_headers_attr_iface_all |
-- |                                                                   |
-- | Parameters:        p_order_rec IN order_rec_type                  |
-- |                    p_batch_id  IN batch_id                        |
-- |                    p_order_amt OUT Return tot ord amt             |
-- |                    p_order_source OUT Return order source         |
-- +===================================================================+

  i BINARY_INTEGER;
  lc_order_source            VARCHAR2(20);
  lc_order_type              VARCHAR2(20);
  lc_salesrep                VARCHAR2(7);
  lc_sales_channel           VARCHAR2(20);
  lc_sold_to_contact         VARCHAR2(50);
  lc_paid_at_store_id        VARCHAR2(20);
  lc_customer_ref            VARCHAR2(50);
  lc_orig_sys_customer_ref   VARCHAR2(50);
  lc_orig_sys_bill_address_ref VARCHAR2(50);
  lc_bill_address1           VARCHAR2(80);
  lc_bill_address2           VARCHAR2(80);
  lc_bill_city               VARCHAR2(80);
  lc_bill_state              VARCHAR2(2);
  lc_bill_country            VARCHAR2(3);
  lc_bill_zip                VARCHAR2(15);
  lc_orig_sys_ship_address_ref VARCHAR2(50);
  lc_ship_address1           VARCHAR2(80);
  lc_ship_address2           VARCHAR2(80);
  lc_ship_city               VARCHAR2(80);
  lc_ship_state              VARCHAR2(2);
  lc_ship_country            VARCHAR2(3);
  lc_ship_zip                VARCHAR2(15);
  lc_orig_order_no           VARCHAR2(50);
  lc_orig_sub_num            VARCHAR2(30);
  lc_return_reason_code      VARCHAR2(50);
  lc_customer_type           VARCHAR2(20);
  ld_ship_date               DATE;
  ln_tax_value               NUMBER;
  ln_us_tax                  NUMBER;
  ln_gst_tax                 NUMBER;
  ln_pst_tax                 NUMBER;
  lc_err_msg                 VARCHAR2(240);
  lc_return_status           VARCHAR2(80);
  --v_return_reason           VARCHAR2(30);
  lc_order_category          VARCHAR2(2);
  lb_store_customer          BOOLEAN := FALSE;
  lc_return_ref_no           VARCHAR2(30);
  lc_cust_po_number          VARCHAR2(22);
  lc_release_no              VARCHAR2(12);
  lc_return_act_cat_code     VARCHAR2(100);
  lc_orig_sys                VARCHAR2(10);
  ln_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
  lc_sas_sale_date           VARCHAR2(10);
  lc_tax_sign                VARCHAR2(1);
  ln_seq                     NUMBER;
  lc_aops_pos_flag           VARCHAR2(1);
  lc_status                  VARCHAR2(1);
  lc_ord_date                VARCHAR2(10);
  lc_ord_time                VARCHAR2(10);
  lc_ord_end_time            VARCHAR2(10);
  ln_freight_customer_ref    NUMBER;
  lc_tran_number             VARCHAR2(60);
  lc_loc_country             VARCHAR2(10) := NULL;
  lc_opu_country             VARCHAR2(10) := NULL;        
BEGIN
    x_return_status := 'S';

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Entering  Process Header');
    END IF;

    -- Get the current index for header record
    i := G_Header_Rec.Orig_sys_document_ref.COUNT + 1;
    G_Header_Rec.error_flag(i) := NULL;

    G_header_rec.orig_sys_document_ref(i) := RTRIM(SUBSTR(p_order_rec.file_line, 1, 20));
    
    p_order_amt := (SUBSTR(p_order_rec.file_line, 268,  1))||SUBSTR(p_order_rec.file_line, 269,  10);

    -- If the current transaction is a POS correction then we will be getting same
    -- value for orig_sys_document_ref. To make it unique,
    -- set the orig_sys_document_ref = orig_sys_doc_ref || sequence value

    IF SUBSTR(p_order_rec.file_line, 32, 1) IN ('A','D') THEN -- If correction_flag is TRUE
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('Inside Correction Transaction');
        END IF;

        SELECT xx_om_nonsku_line_s.NEXTVAL
        INTO ln_seq
        FROM DUAL;

        G_header_rec.orig_sys_document_ref(i) := G_header_rec.orig_sys_document_ref(i) ||
                                                 '-c-'|| ln_seq ;

    END IF;

    -- Read the order source from file
    lc_order_source := LTRIM(SUBSTR (p_order_rec.file_line, 143,  1));
    -- If no order source comes from SAS then default it to 'O'
    IF lc_order_source IS NULL THEN
        lc_order_source := 'O';
    END IF;

    -- To get order source id
    IF lc_order_source IS NOT NULL THEN
        g_header_rec.order_source_id(i) := order_source(lc_order_source);

        IF g_header_rec.order_source_id(i) IS NULL THEN
            Set_Header_Error(i);
            g_header_rec.order_source(i) := lc_order_source;
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'ORDER_SOURCE_ID NOT FOUND FOR Order Source : ' || lc_order_source;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAILED_ATTR_DERIVATION');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE','ORDER SOURCE - '||lc_order_source);
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.add(lc_err_msg, 1);
            END IF;
        END IF;
    ELSE
        g_header_rec.order_source_id(i) := NULL;
    END IF;

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('ordered date' ||SUBSTR(p_order_rec.file_line, 33,10));
        oe_debug_pub.add('ordered time' ||SUBSTR(p_order_rec.file_line,831,8));
    END IF;

    BEGIN
        lc_ord_date := TRIM(SUBSTR(p_order_rec.file_line, 33,10));
        lc_ord_time := TRIM(SUBSTR(p_order_rec.file_line,831,8));
        G_header_rec.ordered_date(i) := TO_DATE(lc_ord_date||' '||lc_ord_time,'YYYY-MM-DD HH24:MI:SS');
    EXCEPTION
        WHEN OTHERS THEN
            G_header_rec.ordered_date(i) := NULL;
            lc_ord_date := NULL;
            lc_ord_time := NULL;
            Set_Header_Error(i);
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'Error reading Ordered Date' || SUBSTR(p_order_rec.file_line, 33, 10) || ' '||SUBSTR(p_order_rec.file_line,831,8);
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_READ_ERROR');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1','Ordred Date');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',SUBSTR(p_order_rec.file_line, 33, 10));
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE3','YYYY-MM-DD HH24:MI:SS');
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.add(lc_err_msg, 1);
            END IF;
    END;
    G_header_rec.transactional_curr_code(i) := SUBSTR(p_order_rec.file_line, 43,  3);
    lc_salesrep                             := TRIM(SUBSTR(p_order_rec.file_line, 46, 7));
    lc_sales_channel                        := TRIM(SUBSTR (p_order_rec.file_line, 53,  1));
    G_header_rec.customer_po_number(i)      := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 98,  22)));

    lc_sold_to_contact                      := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 120, 14)));
    lc_aops_pos_flag                        := LTRIM(SUBSTR (p_order_rec.file_line, 329,  1));
    p_order_source                          := lc_aops_pos_flag;
    G_header_rec.legacy_order_type(i)       := LTRIM(SUBSTR (p_order_rec.file_line, 216,  1));
    g_header_rec.drop_ship_flag(i)          := LTRIM(SUBSTR (p_order_rec.file_line, 134,  1));
    --need to find out from cdh team how many char for orig sys ref
    lc_customer_ref                         := LTRIM(SUBSTR(p_order_rec.file_line, 218, 8));
    g_header_rec.tax_value(i)               := SUBSTR(p_order_rec.file_line, 88, 10);
    lc_tax_sign                             := SUBSTR(p_order_rec.file_line, 87, 1);
    G_header_rec.pst_tax_value(i)           := SUBSTR(p_order_rec.file_line, 77, 10);

    IF lc_tax_sign = '-' THEN
        G_header_rec.pst_tax_value(i) := -1 * G_header_rec.pst_tax_value(i);
        G_header_rec.tax_value(i) := -1 * G_header_rec.tax_value(i);
    END IF;
     
    -- Set Order Total
    G_header_rec.order_total(i) := G_header_rec.tax_value(i);

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Next 1' ||SUBSTR (p_order_rec.file_line, 283,8));
    END IF;

    -- If POS order or SPC card or PRO card purchase from POS
    --IF lc_order_source IN ('P','S','U') THEN
    IF lc_aops_pos_flag = 'P' THEN
        G_header_rec.return_orig_sys_doc_ref(i) := TRIM(SUBSTR (p_order_rec.file_line, 279, 20));
        oe_debug_pub.add('Reading org_order_creation_date' || LTRIM(SUBSTR (p_order_rec.file_line, 283,8)));
        BEGIN
            G_header_rec.org_order_creation_date(i) := TO_DATE(LTRIM(SUBSTR (p_order_rec.file_line, 283,8)),'YYYYMMDD');
        EXCEPTION
        WHEN OTHERS THEN
            G_header_rec.org_order_creation_date(i) := NULL;
            Set_Header_Error(i);
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'Error reading Orig Order Date' || SUBSTR(p_order_rec.file_line, 283, 8);
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_READ_ERROR');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1','Orig Order Date');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',SUBSTR(p_order_rec.file_line, 283, 8));
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE3','YYYYMMDD');
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.add(lc_err_msg, 1);
            END IF;
        END;
    ELSE
        oe_debug_pub.add('Reading  org_order_creation_date' || LTRIM(SUBSTR (p_order_rec.file_line, 860,10)));
        G_header_rec.return_orig_sys_doc_ref(i) := SUBSTR(p_order_rec.file_line, 279, 12);
        BEGIN
            G_header_rec.org_order_creation_date(i) := TO_DATE(LTRIM(SUBSTR (p_order_rec.file_line, 860,10)),'YYYY-MM-DD');
        EXCEPTION
        WHEN OTHERS THEN
            G_header_rec.org_order_creation_date(i) := NULL;
            Set_Header_Error(i);
            oe_debug_pub.add('In Error for date' || LTRIM(SUBSTR (p_order_rec.file_line, 860,10)));
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'Error reading Orig Order Date' || SUBSTR(p_order_rec.file_line, 860, 10);
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_READ_ERROR');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1','Orig Order Date');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',SUBSTR(p_order_rec.file_line, 860, 10));
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE3','YYYY-MM-DD');
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.add(lc_err_msg, 1);
            END IF;
        END;
    END IF;

    BEGIN
        G_header_rec.ship_date(i) := TO_DATE(LTRIM(SUBSTR (p_order_rec.file_line, 226,10)),'YYYY-MM-DD');
    EXCEPTION
        WHEN OTHERS THEN
            G_header_rec.ship_date(i) := NULL;
            Set_Header_Error(i);
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'Error reading Ship Date' || SUBSTR(p_order_rec.file_line, 226, 10);
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_READ_ERROR');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1','Ship Date');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',SUBSTR(p_order_rec.file_line, 226, 10));
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE3','YYYY-MM-DD');
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.add(lc_err_msg, 1);
            END IF;
    END;
    -- If no reason is provided for return then we will use CN as reason code.
    lc_return_reason_code                   := NVL(LTRIM(SUBSTR (p_order_rec.file_line, 301,    2)),'CN');
    lc_return_act_cat_code                  := NVL(LTRIM(SUBSTR (p_order_rec.file_line, 303,    2)),'RT') || '-' ||
                                              NVL(LTRIM(SUBSTR (p_order_rec.file_line, 305,    1)),'C') || '-' ||
                                              lc_return_reason_code;

    lc_paid_at_store_id                    := TO_NUMBER(LTRIM(SUBSTR (p_order_rec.file_line,135,4)));
    G_header_rec.inv_loc_no(i)             := TO_NUMBER(LTRIM(SUBSTR (p_order_rec.file_line,139,4)));
    G_header_rec.spc_card_number(i)        := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 196, 20)));
    -- Need values from BOB
    G_header_rec.placement_method_code(i)    := NULL;
    G_header_rec.advantage_card_number(i)   := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 236, 10)));
    G_header_rec.created_by_id(i)           := LTRIM(SUBSTR (p_order_rec.file_line, 250,  7));
    G_header_rec.delivery_code(i)           := LTRIM(SUBSTR (p_order_rec.file_line, 328,  1));
    lc_tran_number                          := LTRIM(SUBSTR (p_order_rec.file_line, 308, 20)); --Vertex change NB
    G_header_rec.tax_exempt_amount(i)       := LTRIM(SUBSTR (p_order_rec.file_line, 562, 10)); --Vertex change NB
    G_header_rec.aops_geo_code(i)           := LTRIM(SUBSTR (p_order_rec.file_line, 572,  9)); --Vertex change NB
    G_header_rec.delivery_method(i)         := RTRIM(SUBSTR (p_order_rec.file_line, 246,  3));
    G_header_rec.release_number(i)          := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 144, 12)));
    G_header_rec.cust_dept_no(i)            := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 156, 20)));
    G_header_rec.desk_top_no(i)             := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 176, 20)));
    --   v_return_reason                         := SUBSTR(p_order_rec.file_line,  267,    2);
    G_header_rec.comments(i)                := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 331, 90)));
    G_header_rec.shipping_instructions(i)   := NULL;
    lc_order_category                       := SUBSTR (p_order_rec.file_line, 217,   1);
    G_header_rec.deposit_amount(i)          := LTRIM(SUBSTR(p_order_rec.file_line, 258,  10));
    G_header_rec.gift_flag(i)               := SUBSTR (p_order_rec.file_line, 839,  1);
    lc_sas_sale_date                        := LTRIM(SUBSTR(p_order_rec.file_line, 821,  10));
    G_header_rec.tax_exempt_number(i)       := TRIM(SUBSTR (p_order_rec.file_line, 840,  20));

    -- transaction number if POS transaction 1st 20 char and for aops it is lc_tran_number 
    IF lc_order_source IN ('P','S','U') THEN
        G_header_rec.tran_number(i) := G_header_rec.orig_sys_document_ref(i);
    ELSE
        G_header_rec.tran_number(i) := lc_tran_number;
    END IF;

    IF lc_sas_sale_date IS NOT NULL THEN
        BEGIN
            G_header_rec.sas_sale_date(i) := TO_DATE(lc_sas_sale_date, 'YYYY-MM-DD');
        EXCEPTION
          WHEN OTHERS THEN
            G_header_rec.sas_sale_date(i) := NULL;
            Set_Header_Error(i);
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'Error reading SAS Sale Date' || lc_sas_sale_date;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_READ_ERROR');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1','SAS Sale Date');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE2', lc_sas_sale_date);
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE3','YYYY-MM-DD');
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.add(lc_err_msg, 1);
            END IF;
        END;
    ELSE -- For POS the SAS date will come in ship_date
        G_header_rec.sas_sale_date(i) := G_Header_rec.ship_date(i);
    END IF;

    --need to change in futher
    lc_orig_sys_bill_address_ref             := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 629, 5)));
    lc_orig_sys_ship_address_ref             := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 725, 5)));
    lc_ship_address1                         := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 730, 25)));
    lc_ship_address2                         := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 755, 25)));
    lc_ship_city                             := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 780, 25)));
    lc_ship_state                            := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 805,  2)));
    lc_ship_zip                              := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 807, 11)));
    lc_ship_country                          := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 818,  3)));
    g_header_rec.ship_to_county(i)           := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 536,  25)));
    -- Added code to staore the AOPS address on order header attributes table
    g_header_rec.ship_to_sequence(i)         := lc_orig_sys_ship_address_ref;
    g_header_rec.ship_to_address1(i)         := lc_ship_address1;
    g_header_rec.ship_to_address2(i)         := lc_ship_address2;
    g_header_rec.ship_to_city(i)             := lc_ship_city;
    g_header_rec.ship_to_state(i)            := lc_ship_state;
    g_header_rec.ship_to_country(i)          := lc_ship_country;
    g_header_rec.ship_to_zip(i)              := lc_ship_zip;
    g_header_rec.ship_to_geocode(i)          := NULL;

    -- Set the booked_flag = Y
    g_header_rec.booked_flag(i)             := 'Y';
    g_header_rec.ineligible_for_hvop(i)     := NULL;
    g_header_rec.sold_to_org(i)             := NULL;
    g_header_rec.sold_to_org_id(i)          := NULL;
    g_header_rec.sold_to_contact(i)         := NULL;
    g_header_rec.sold_to_contact_id(i)      := NULL;
    g_header_rec.Ship_to_org(i)             := NULL;
    g_header_rec.Ship_to_org_id(i)          := NULL;
    g_header_rec.Invoice_to_org(i)          := NULL;
    g_header_rec.Invoice_to_org_id(i)       := NULL;
    g_header_rec.Ship_From_Org(i)           := NULL;
    g_header_rec.salesrep(i)                := NULL;
    g_header_rec.order_source(i)            := NULL;
    g_header_rec.sales_channel(i)           := NULL;
    g_header_rec.shipping_method(i)         := NULL;
    G_Header_Rec.Shipping_Method_Code(i)    := NULL;
    g_header_rec.legacy_cust_name(i)        := NULL;
    g_header_rec.deposit_hold_flag(i)       := NULL;
    G_header_rec.ship_to_name(i)            := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 421,  30))); --Modified by NB
    G_header_rec.bill_to_name(i)            := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 451,  30))); --Modified by NB
    G_header_rec.cust_contact_name(i)       := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 870,  25))); --Modified by NB
    G_header_rec.cust_pref_phone(i)         := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 895,  11))); --Modified By NB
    G_header_rec.cust_pref_phextn(i)        := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 906,  4)));  -- Modified By NB
    G_header_rec.tax_rate(i)                := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 910,  7)));
    g_header_rec.is_reference_return(i)     := 'N';
    -- added to read the alternate shipper for export orders
    ln_freight_customer_ref                 := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 503,  8))); 
    G_header_rec.cust_dept_description(i)   := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 511, 25)));

    -- Get the Datawarehouse attributes
    G_header_rec.commisionable_ind(i)       := TRIM(SUBSTR (p_order_rec.file_line, 481,  1));
    lc_ord_end_time                         := TRIM(SUBSTR (p_order_rec.file_line, 484,  8));
    G_header_rec.price_cd(i)                := TRIM(SUBSTR (p_order_rec.file_line, 492,  1));
    G_header_rec.order_taxable_cd(i)        := TRIM(SUBSTR (p_order_rec.file_line, 493,  1));
    G_header_rec.order_action_code(i)       := TRIM(SUBSTR (p_order_rec.file_line, 494,  3));
    G_header_rec.override_delivery_chg_cd(i) := TRIM(SUBSTR (p_order_rec.file_line, 497, 2));
    oe_debug_pub.add('Next 4', 1);

    -- Derive the Date and time for the start/end times
    IF lc_ord_time IS NOT NULL AND 
       lc_ord_end_time IS NOT NULL AND
       lc_ord_date IS NOT NULL 
    THEN
        BEGIN
            IF lc_ord_end_time >= lc_ord_time  THEN
                G_header_rec.order_start_time(i) := TO_DATE(lc_ord_date||' '||lc_ord_time,'YYYY-MM-DD HH24:MI:SS'); 
            ELSE
                G_header_rec.order_start_time(i) := TO_DATE(lc_ord_date||' '||lc_ord_time,'YYYY-MM-DD HH24:MI:SS') - 1;
            END IF;
            G_header_rec.order_end_time(i) := TO_DATE(lc_ord_date||' '||lc_ord_end_time,'YYYY-MM-DD HH24:MI:SS');
        EXCEPTION
            WHEN OTHERS THEN
                G_header_rec.order_start_time(i) := G_header_rec.ORDERED_DATE(i);
                G_header_rec.order_end_time(i) := NULL;
                set_msg_context(p_entity_code => 'HEADER');
                lc_err_msg := 'Error reading Order End Time ' || lc_ord_end_time;
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_READ_ERROR');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE1','Order End Date');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',lc_ord_end_time);
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE3','HH24:MI:SS');
                oe_bulk_msg_pub.add;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add(lc_err_msg, 1);
                END IF;
        END;
    ELSE
        G_header_rec.order_end_time(i) := NULL;
        G_header_rec.order_start_time(i) := NULL;
    
    END IF;
    
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('G_Header_Rec count is :'|| to_char(i-1));
        oe_debug_pub.add('Order Total amount is :'|| p_order_amt);
        oe_debug_pub.ADD('orig_sys_document_ref = '||G_header_rec.orig_sys_document_ref(i));
        oe_debug_pub.ADD('ordered_date = '||G_header_rec.ordered_date(i));
        oe_debug_pub.ADD('transactional_curr_code = '||G_header_rec.transactional_curr_code(i));
        oe_debug_pub.ADD('lc_salesrep = '||lc_salesrep);
        oe_debug_pub.ADD('customer_po_number = '||G_header_rec.customer_po_number(i));
        oe_debug_pub.ADD('lc_sold_to_contact = '||lc_sold_to_contact);
        oe_debug_pub.ADD('lc_order_source = '||lc_order_source);
        oe_debug_pub.ADD('lc_aops_pos_flag = '||lc_aops_pos_flag);
        oe_debug_pub.ADD('legacy_order_type = '||G_header_rec.legacy_order_type(i));
        oe_debug_pub.ADD('drop_ship_flag = '||g_header_rec.drop_ship_flag(i) );
        oe_debug_pub.ADD('lc_customer_ref  = '||lc_customer_ref);
        oe_debug_pub.ADD('tax_value  = '||g_header_rec.tax_value(i));
        oe_debug_pub.ADD('pst_tax_value  = '||G_header_rec.pst_tax_value(i));
        oe_debug_pub.ADD('return_ref_no  = '||G_header_rec.return_orig_sys_doc_ref(i));
        oe_debug_pub.ADD('ship_date  = '||G_header_rec.ship_date(i));
        oe_debug_pub.ADD('lc_return_reason_code  = '||lc_return_reason_code);
        oe_debug_pub.ADD('lc_paid_at_store_id  = '||lc_paid_at_store_id);
        oe_debug_pub.ADD('Inv Location No  = '||G_header_rec.inv_loc_no(i));
        oe_debug_pub.ADD('spc_card_number  = '||G_header_rec.spc_card_number(i));
        oe_debug_pub.ADD('advantage_card_number  = '||G_header_rec.advantage_card_number(i));
        oe_debug_pub.ADD('created_by_id  = '||G_header_rec.created_by_id(i));
        oe_debug_pub.ADD('delivery_code  = '||G_header_rec.delivery_code(i));
        oe_debug_pub.ADD('tran_number  = '||G_header_rec.tran_number(i));
        oe_debug_pub.ADD('aops_geo_code  = '||G_header_rec.aops_geo_code(i));
        oe_debug_pub.ADD('tax_exempt_amount  = '||G_header_rec.tax_exempt_amount(i));
        oe_debug_pub.ADD('release_number  = '||G_header_rec.release_number(i));
        oe_debug_pub.ADD('cust_dept_no  = '||G_header_rec.cust_dept_no(i));
        oe_debug_pub.ADD('cust_dept_desc  = '||G_header_rec.cust_dept_description(i));
        oe_debug_pub.ADD('desk_top_no  = '||G_header_rec.desk_top_no(i));
        oe_debug_pub.ADD('comments  = '||G_header_rec.comments(i));
        oe_debug_pub.ADD('lc_order_category  = '||lc_order_category);
        oe_debug_pub.ADD('lc_orig_sys_bill_address_ref = '||lc_orig_sys_bill_address_ref);
        oe_debug_pub.ADD('lc_orig_sys_ship_address_ref = '||lc_orig_sys_ship_address_ref);
        oe_debug_pub.add('addr1 ' ||lc_ship_address1);
        oe_debug_pub.add('Addr2 ' ||lc_ship_address2);
        oe_debug_pub.add('City ' ||lc_ship_city);
        oe_debug_pub.add('State ' ||lc_ship_state);
        oe_debug_pub.add('Country ' ||lc_ship_country );
        oe_debug_pub.add('zip ' ||lc_ship_zip);
        oe_debug_pub.add('Deposit Amount IS :'||G_header_rec.deposit_amount(i));
        oe_debug_pub.add('Tax Exempt Number IS :'||G_header_rec.tax_exempt_number(i));
        oe_debug_pub.add('Order Start Time  IS :'||G_header_rec.order_start_time(i));
        oe_debug_pub.add('Order End Time  IS :'||G_header_rec.order_end_time(i));
        oe_debug_pub.add('After reading header record ');
    END IF;


    -- Check if the order source is PRO-CARD or SPC-CARD
    -- and no customer reference is sent then give error

    IF lc_order_source IN ('S','U') AND
       lc_customer_ref IS NULL
    THEN
        Set_Header_Error(i);
        set_msg_context(p_entity_code => 'HEADER');
        lc_err_msg := 'Missing Customer reference for PRO/SPC card order : ';
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_CUST_MISSING_PROSPC');
        oe_bulk_msg_pub.add;
        IF ln_debug_level > 0 THEN
            oe_debug_pub.ADD(lc_err_msg, 1);
        END IF;
    END IF;
    
    -- To Get Order Number for SPC and PRO-CARD

    /*
    IF lc_order_source IN ('S','U') THEN
        g_header_rec.order_number(i) := NVL(TO_NUMBER(RTRIM(SUBSTR(p_order_rec.file_line, 308,12))),TO_NUMBER(g_header_rec.orig_sys_document_ref(i)));
    ELSIF lc_order_source = 'P' THEN
    */
    IF lc_aops_pos_flag = 'P' THEN
        g_header_rec.order_number(i) := NULL;
    ELSE
        g_header_rec.order_number(i) := TO_NUMBER(g_header_rec.orig_sys_document_ref(i));
    END IF;
    
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Order Number is : '|| g_header_rec.order_number(i));
    END IF;
   
    -- To set order type, category , batch_id, request_id and change_sequence
    IF lc_order_category = 'O' THEN -- For Orders
        g_header_rec.order_category(i) := 'ORDER';
        IF lc_aops_pos_flag = 'P' THEN
            g_header_rec.order_type_id(i) := OE_Sys_Parameters.value('D-SO-POS',G_Org_Id);
        ELSE
            g_header_rec.order_type_id(i) := OE_Sys_Parameters.value('D-SO',G_Org_Id);
        END IF;
        g_header_rec.change_sequence(i) := NULL; --'SALES_ACCT_HVOP';
        g_header_rec.batch_id(i) := p_batch_id;
        g_header_rec.request_id(i) := g_request_id;
        g_header_rec.return_reason(i)  := NULL;
        g_header_rec.return_act_cat_code(i) := NULL;
    ELSE -- for Mixed or return orders
        IF lc_aops_pos_flag = 'P' THEN
            g_header_rec.order_type_id(i) := OE_Sys_Parameters.value('D-RO-POS',G_Org_Id);
        ELSE
            g_header_rec.order_type_id(i) := OE_Sys_Parameters.value('D-RO',G_Org_Id);
        END IF;
        g_header_rec.change_sequence(i) := NULL; --'SALES_ACCT_SOI';
        g_header_rec.order_category(i) := 'MIXED';
        g_header_rec.return_reason(i)  := return_reason(lc_return_reason_code);
        g_header_rec.batch_id(i) := NULL;
        g_header_rec.request_id(i) := NULL;
        g_header_rec.return_act_cat_code(i) := Get_Ret_ActCatReason_Code(lc_return_act_cat_code);
        IF g_header_rec.return_act_cat_code(i) IS NULL THEN
            Set_Header_Error(i);
            g_header_rec.return_act_cat_code(i) := lc_return_act_cat_code;
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'Return Action Category Reason Invalid : ' || lc_return_act_cat_code;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_REQ_ATTR_MISSING');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Return Action Category Reason');
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        END IF;
    END IF;

    -- To get Price List Id
    g_header_rec.price_list_id(i) := OE_Sys_Parameters.value('XX_OM_SAS_PRICE_LIST',G_Org_Id);

    -- To get Inv Location (ship_from_org_id)
    IF G_header_rec.inv_loc_no(i) IS NOT NULL THEN
        g_header_rec.ship_from_org_id(i) := Get_Organization_Id(G_header_rec.inv_loc_no(i));
        IF g_header_rec.ship_from_org_id(i) IS NULL THEN
            Set_Header_Error(i);
            g_header_rec.ship_from_org(i) := G_header_rec.inv_loc_no(i);
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'SHIP_FROM_ORG_ID NOT FOUND FOR SALE LOCATION ID : ' || G_header_rec.inv_loc_no(i);
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAIL_SHIPFROM_DERIVATION');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1',G_header_rec.inv_loc_no(i));
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        END IF;
    ELSE
        g_header_rec.ship_from_org(i) := NULL;
        g_header_rec.ship_from_org_id(i) := NULL;
    END IF;

    -- To get sale store id - Need different values but right now we are deriving it based on
    -- Sale Location Id
    -- To get paid at store id

    IF lc_paid_at_store_id IS NOT NULL THEN
        oe_debug_pub.ADD('Get Store details', 1);
        g_header_rec.paid_at_store_no(i) := lc_paid_at_store_id;
        -- Load the Org only if it is of type STORE.
        -- Validation to check location belong to same operating unit
        lc_loc_country := Get_store_Country(g_header_rec.paid_at_store_no(i));
        lc_opu_country := Get_org_code(g_org_id);
        IF ln_debug_level > 0 THEN
        oe_debug_pub.ADD('Store Location: '|| g_header_rec.paid_at_store_no(i));
        oe_debug_pub.ADD('Store Location Country: '|| lc_loc_country);
        oe_debug_pub.ADD('Operating Unit Country: '|| lc_opu_country);
        END IF;

        IF lc_loc_country = lc_opu_country THEN 
            g_header_rec.paid_at_store_id(i) := Get_Store_Id(lc_paid_at_store_id);
            g_header_rec.created_by_store_id(i) := g_header_rec.paid_at_store_id(i);
        ELSE
            g_header_rec.paid_at_store_id(i) := NULL;
            g_header_rec.created_by_store_id(i) := NULL;
            Set_Header_Error(i);
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'Store Location is in wrong operating unit: '||g_header_rec.paid_at_store_no(i);
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_WRONG_OP_UNIT');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1',g_header_rec.paid_at_store_no(i));
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        END IF;
    ELSE
        g_header_rec.paid_at_store_id(i) := NULL;
        g_header_rec.paid_at_store_no(i) := NULL;
        g_header_rec.created_by_store_id(i) := NULL;
    END IF;

    -- To get Salesrep ID
    IF lc_salesrep IS NOT NULL THEN
        g_header_rec.salesrep_id(i) := sales_rep(lc_salesrep);
        IF g_header_rec.salesrep_id(i) IS NULL THEN
            -- Need to bypass this validation till we get the actual salesrep conversion data
            --Set_Header_Error(i);
            --g_header_rec.salesrep(i) := lc_salesrep;
            set_msg_context(p_entity_code => 'HEADER',
                            p_warning_flag => TRUE);
            lc_err_msg := 'SALESREP_ID NOT FOUND FOR SALES REP : ' || lc_salesrep;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAIL_SALESREP_DERIVATION');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1',lc_salesrep);
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',g_header_rec.orig_sys_document_ref(i));
        --    oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;

            -- Commenting out the salesrep derivation since CRM has provided conversion data
            -- for salesreps.
            g_header_rec.salesrep_id(i) := FND_PROFILE.VALUE('ONT_DEFAULT_PERSON_ID');
        END IF;
    ELSE
        g_header_rec.salesrep_id(i) := FND_PROFILE.VALUE('ONT_DEFAULT_PERSON_ID');
    END IF;

    -- To get sales channel code
    IF lc_sales_channel IS NOT NULL THEN
        g_header_rec.sales_channel_code(i) := sales_channel(lc_sales_channel);
        IF g_header_rec.sales_channel_code(i) IS NULL THEN
            Set_Header_Error(i);
            g_header_rec.sales_channel(i) := lc_sales_channel;
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'SALES_CHANNEL_CODE NOT FOUND FOR SALES CHANNEL : ' || lc_sales_channel;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAIL_SALESC_DERIVATION');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1',lc_sales_channel);
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        END IF;
    ELSE
        g_header_rec.sales_channel_code(i) := NULL;
    END IF;

    -- To get customer_id
    IF lc_customer_ref IS NULL THEN
        -- It could be store order
        G_Header_Rec.Sold_to_org_id(i) := NULL;
        IF G_Header_Rec.Paid_At_Store_No(i) IS NULL THEN
            -- Need to give error if POS order but missing store location
            Set_Header_Error(i);
            g_header_rec.sold_to_org_id(i) := NULL;
            g_header_rec.sold_to_org(i) := lc_customer_ref;
            set_msg_context( p_entity_code => 'HEADER');
            lc_err_msg := 'SOLD_TO_ORG_ID NOT FOUND FOR ORIG_SYS_CUSTOMER_ID : ' || lc_customer_ref;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_CUST_REF');
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        ELSE
            -- Format the customer reference as stored in OSR table in hz_orig_sys_references
            lc_orig_sys_customer_ref := LPAD(G_Header_Rec.Paid_At_Store_No(i),6,'0')||get_store_country(G_Header_Rec.Paid_At_Store_No(i));
            lc_orig_sys := 'RMS'; -- For store customer
            lb_store_customer := TRUE;
        END IF;
    ELSE
        -- Format the customer reference as stored in OSR table in hz_orig_sys_references
        lc_orig_sys_customer_ref := lc_customer_ref || '-00001-A0';
        lc_orig_sys := 'A0'; -- OSR for legacy converted customers
    END IF;

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Customer Ref is :'||lc_orig_sys_customer_ref);
    END IF;

    -- Get the Sold_to_Org_Id (Customer Account) for the customer reference

    IF lc_orig_sys_customer_ref IS NOT NULL THEN

        IF lb_store_customer THEN
            -- Check if the customer already exists in the cache
            IF G_Sold_To_Org_ID.EXISTS(lc_orig_sys_customer_ref) THEN
                g_header_rec.sold_to_org_id(i) := G_Sold_To_ORg_ID(lc_orig_sys_customer_ref);
            END IF;
        END IF;

        IF g_header_rec.sold_to_org_id(i) IS NULL THEN
            -- Call the cross reference API from CDH to get sold_to_org_id
            HZ_ORIG_SYSTEM_REF_PUB.get_owner_table_id(
                               p_orig_system => lc_orig_sys,
                               p_orig_system_reference => lc_orig_sys_customer_ref,
                               p_owner_table_name => 'HZ_CUST_ACCOUNTS',
                               x_owner_table_id => g_header_rec.sold_to_org_id(i),
                               x_return_status =>  lc_return_status );
            -- Check if it is PRO CARD Order
            IF lc_order_source = 'U' AND g_header_rec.sold_to_org_id(i) IS NULL THEN
                -- Need to treat it as POS order
                lb_store_customer := TRUE;
                lc_orig_sys := 'RMS';
                lc_orig_sys_customer_ref := LPAD(G_Header_Rec.Paid_At_Store_No(i),6,'0')||get_store_country(G_Header_Rec.Paid_At_Store_No(i)); 
                lc_order_source := 'P';
                G_Header_Rec.order_source_id(i) := order_source(lc_order_source); 
                lc_orig_sys_ship_address_ref := NULL;

                -- Check the store customer cache
                IF G_Sold_To_Org_ID.EXISTS(lc_orig_sys_customer_ref) THEN
                   g_header_rec.sold_to_org_id(i) := G_Sold_To_ORg_ID(lc_orig_sys_customer_ref);
                ELSE
                   -- Call the cross reference API from CDH to get sold_to_org_id
                   HZ_ORIG_SYSTEM_REF_PUB.get_owner_table_id(
                               p_orig_system => lc_orig_sys,
                               p_orig_system_reference => lc_orig_sys_customer_ref,
                               p_owner_table_name => 'HZ_CUST_ACCOUNTS',
                               x_owner_table_id => g_header_rec.sold_to_org_id(i),
                               x_return_status =>  lc_return_status );
                END IF;
            END IF;

            IF g_header_rec.sold_to_org_id(i) IS NULL AND (lc_return_status <> fnd_api.g_ret_sts_success ) THEN

                Set_Header_Error(i);
                g_header_rec.sold_to_org(i) := lc_orig_sys_customer_ref;
                IF NOT lb_store_customer THEN
                    g_header_rec.ship_to_org(i) := lc_customer_ref ||'-'|| lc_orig_sys_ship_address_ref||'-A0';
                ELSE
                    g_header_rec.ship_to_org(i) := NULL;
                END IF;
                set_msg_context( p_entity_code => 'HEADER');
                lc_err_msg := 'SOLD_TO_ORG_ID NOT FOUND FOR ORIG_SYS_CUSTOMER_ID : ' || lc_orig_sys_customer_ref;
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAIL_CUSTACCT_DERIVATION');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE1',lc_orig_sys_customer_ref);
                oe_bulk_msg_pub.add;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.ADD(lc_err_msg, 1);
                END IF;
            ELSE
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add('The Customer Account Found: '||g_header_rec.sold_to_org_id(i));
                END IF;
            END IF;
          
            -- Set the value in Store customer Cache
            IF lb_store_customer AND g_header_rec.sold_to_org_id(i) IS NOT NULL THEN
                G_Sold_To_ORg_ID(lc_orig_sys_customer_ref) := g_header_rec.sold_to_org_id(i);
            END IF;

        END IF;

        -- Get the party name to be stored in as customer name on the order.
        IF g_header_rec.sold_to_org_id(i) IS NOT NULL THEN

            -- If store customer and party name exists in CACHE
            IF lb_store_customer AND G_Party_Name.EXISTS(lc_orig_sys_customer_ref) THEN
                g_header_rec.legacy_cust_name(i) := G_Party_Name(lc_orig_sys_customer_ref);
            ELSE

              BEGIN
                SELECT party_name
                  INTO g_header_rec.legacy_cust_name(i)
                  FROM hz_cust_accounts hca
                     , hz_parties hp
                 WHERE hca.cust_account_id = g_header_rec.sold_to_org_id(i)
                   AND hca.party_id = hp.party_id;
              EXCEPTION
                WHEN OTHERS THEN
                  g_header_rec.legacy_cust_name(i) := NULL;
              END;

              -- Set the value in Cache only for store customer
              IF lb_store_customer THEN
                  G_Party_Name(lc_orig_sys_customer_ref) := g_header_rec.legacy_cust_name(i);
              END IF;

            END IF; -- IF lb_store_customer
        END IF; -- IF g_header_rec.sold_to_org_id(i) IS NOT NUL
    END IF; -- IF lc_orig_sys_customer_ref IS NOT NULL

    -- Get sold to contact id using the reference
    IF lc_sold_to_contact IS NOT NULL AND
       g_header_rec.sold_to_org_id(i) IS NOT NULL THEN
       HZ_ORIG_SYSTEM_REF_PUB.get_owner_table_id(p_orig_system => 'A0',
                              p_orig_system_reference => lc_sold_to_contact,
                              p_owner_table_name =>'HZ_CUST_ACCOUNT_ROLES',
                              x_owner_table_id => g_header_rec.sold_to_contact_id(i),
                              x_return_status =>  lc_return_status);

       IF (lc_return_status <> fnd_api.g_ret_sts_success) THEN
            --Set_Header_Error(i);
            g_header_rec.sold_to_contact_id(i) := NULL;
            --g_header_rec.sold_to_contact(i) := lc_sold_to_contact;
            set_msg_context(p_entity_code => 'HEADER',
                            p_warning_flag => TRUE);
            lc_err_msg := 'SOLD_TO_CONTACT_ID NOT FOUND FOR SOLD TO CONTACT : ' || lc_sold_to_contact;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAIL_CONTACT_DERIVATION');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1',lc_sold_to_contact);
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',g_header_rec.orig_sys_document_ref(i));
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        ELSE
            IF ln_debug_level > 0 THEN
                oe_debug_pub.add('Successfully derived the sold_to_contact, now trying to validate against account' || g_header_rec.sold_to_contact_id(i));
            END IF;

            -- Validate if the Sold_To_Contact is a valid contact for the derived sold_to_org_id
            BEGIN
                SELECT status
                INTO lc_status
                FROM HZ_CUST_ACCOUNT_ROLES 
                WHERE cust_account_role_id = g_header_rec.sold_to_contact_id(i)
                AND cust_account_id =  g_header_rec.sold_to_org_id(i)
                AND status = 'A';

            EXCEPTION
                WHEN OTHERS THEN
                    -- Not a valid contact or contact does not exist for the account.
                    IF ln_debug_level > 0 THEN
                        oe_debug_pub.add(' Contact does not exists for the account or it is inactive ');
                    END IF;
                    set_msg_context(p_entity_code => 'HEADER',
                            p_warning_flag => TRUE);
                    FND_MESSAGE.SET_NAME('XXOM','XX_OM_INVALID_CONTACT_WARNING');
                    FND_MESSAGE.SET_TOKEN('ATTRIBUTE1',g_header_rec.sold_to_contact_id(i));
                    FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',g_header_rec.sold_to_org_id(i));
                    FND_MESSAGE.SET_TOKEN('ATTRIBUTE3',g_header_rec.orig_sys_document_ref(i));
                    oe_bulk_msg_pub.add;
                    g_header_rec.sold_to_contact_id(i) := NULL;
            END;
        END IF;
    ELSE
        g_header_rec.sold_to_contact_id(i) := NULL;
        g_header_rec.sold_to_contact(i) := lc_sold_to_contact;
    END IF;

    IF g_header_rec.sold_to_org_id(i) IS NOT NULL
    THEN
        -- Check if the Order is paided by deposit
        IF G_Header_Rec.deposit_amount(i) > 0 THEN
            -- Check if the Payment Term is already fetched for DEPOSIT
            IF G_DEPOSIT_TERM_ID IS NULL THEN
                BEGIN
                    SELECT TERM_ID
                    INTO G_DEPOSIT_TERM_ID
                    FROM RA_TERMS_VL
                    WHERE NAME = 'SA_DEPOSIT';
                EXCEPTION
                    WHEN OTHERS THEN
                        G_DEPOSIT_TERM_ID := NULL;
                END;
            END IF;
            g_header_rec.payment_term_id(i) := G_DEPOSIT_TERM_ID;
        ELSE
            -- Get the payment term from Customer Account setup
            g_header_rec.payment_term_id(i) := payment_term(g_header_rec.sold_to_org_id(i));
        END IF;

        IF g_header_rec.payment_term_id(i) IS NULL THEN
            Set_Header_Error(i);
            set_msg_context( p_entity_code  => 'HEADER');
            lc_err_msg := 'PAYMENT_TERM_ID NOT FOUND FOR Customer ID : ' || g_header_rec.sold_to_org_id(i);
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAIL_PAYTERM_DERIVATION');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1',g_header_rec.sold_to_org_id(i));
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        END IF;
    ELSE
        g_header_rec.payment_term_id(i) := NULL;
    END IF;

    -- Get Accounting Rule Id
    IF NOT G_Accounting_Rule_Id.EXISTS(g_header_rec.order_type_id(i)) THEN
        BEGIN
            SELECT accounting_rule_id
            INTO g_accounting_rule_id(g_header_rec.order_type_id(i))
            FROM oe_order_types_v
            WHERE order_type_id = g_header_rec.order_type_id(i);
            g_header_rec.accounting_rule_id(i):= g_accounting_rule_id(g_header_rec.order_type_id(i));
        EXCEPTION
            WHEN OTHERS THEN
                g_header_rec.accounting_rule_id(i):= NULL;
        END;
    ELSE
        g_header_rec.accounting_rule_id(i) := G_Accounting_Rule_Id(g_header_rec.order_type_id(i));
    END IF;

    IF g_header_rec.sold_to_org_id(i) IS NOT NULL THEN
        -- To get ship_to for store customers, or SPC Card purchase or Pro Card purchase */
        IF lb_store_customer OR
           ((lc_order_source = 'S' OR
             lc_order_source = 'U') AND 
             lc_orig_sys_ship_address_ref IS NULL)
        THEN
            -- For store customers, SAS feed will not be sending us the shipto and billto
            -- references. We will use the default BillTo and ShipTo for them
            Get_Def_Shipto( p_cust_account_id => g_header_rec.sold_to_org_id(i)
                          , x_ship_to_org_id => g_header_rec.ship_to_org_id(i));
            IF g_header_rec.ship_to_org_id(i) IS NULL THEN
                Set_Header_Error(i);
                set_msg_context( p_entity_code  => 'HEADER');
                lc_err_msg := 'No Ship To found for the store customer : ' || g_header_rec.sold_to_org_id(i);
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_NO_DEF_SHIPTO');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE',lc_orig_sys_customer_ref);
                oe_bulk_msg_pub.add;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.ADD(lc_err_msg, 1);
                END IF;
            END IF;

            Get_Def_BillTo( p_cust_account_id => g_header_rec.sold_to_org_id(i)
                      , x_bill_to_org_id => g_header_rec.invoice_to_org_id(i));
            IF g_header_rec.Invoice_to_org_id(i) IS NULL THEN
                Set_Header_Error(i);
                set_msg_context( p_entity_code  => 'HEADER');
                lc_err_msg := 'No Bill To found for the store customer : ' || g_header_rec.sold_to_org_id(i);
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_NO_DEF_BILLTO');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE',lc_orig_sys_customer_ref);
                oe_bulk_msg_pub.add;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.ADD(lc_err_msg, 1);
                END IF;
            END IF;

        ELSE -- For non-store customers e.g. AOPS orders and SPC/PRO card orders with ship sequence
            lc_orig_sys_ship_address_ref := lc_customer_ref ||'-'|| lc_orig_sys_ship_address_ref||'-A0' ;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD('Ship REf2 ' ||lc_orig_sys_ship_address_ref);
                oe_debug_pub.ADD('Sold To Org Is ' ||g_header_rec.sold_to_org_id(i));
                oe_debug_pub.ADD('Ordered Date IS ' ||g_header_rec.ordered_date(i));
                oe_debug_pub.ADD('Orig Sys Doc Ref ' ||g_header_rec.orig_sys_document_ref(i));
            END IF;
            IF NVL(ln_freight_customer_ref,0) <> 0
                AND g_header_rec.legacy_order_type(i) = 'X' THEN
                lc_orig_sys_ship_address_ref := ln_freight_customer_ref || '-00001-A0';
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.ADD('Freight Forwarders Ship Ref :' ||lc_orig_sys_ship_address_ref);
                END IF;
            END IF;

            Derive_Ship_To( p_orig_sys_document_ref => g_header_rec.orig_sys_document_ref(i)
                          , p_sold_to_org_id        => g_header_rec.sold_to_org_id(i)
                          , p_order_source_id       => ''
                          , p_orig_sys_ship_ref     => lc_orig_sys_ship_address_ref
                          , p_ordered_date          => g_header_rec.ordered_date(i)
                          , p_address_line1         => lc_ship_address1
                          , p_address_line2         => lc_ship_address2
                          , p_city                  => lc_ship_city
                          , p_state                 => lc_ship_state
                          , p_country               => lc_ship_country
                          , p_province              => ''
                          , p_postal_code           => lc_ship_zip
                          , p_order_source          => lc_order_source
                          , x_ship_to_org_id        => g_header_rec.ship_to_org_id(i)
                          , x_invoice_to_org_id     => g_header_rec.invoice_to_org_id(i)
                          , x_ship_to_geocode       => g_header_rec.ship_to_geocode(i)
                          );
            IF ln_debug_level > 0 THEN
                    oe_debug_pub.ADD('Ship_to_org_id :'|| g_header_rec.ship_to_org_id(i));
                    oe_debug_pub.ADD('Invoice_to_org_id :'|| g_header_rec.invoice_to_org_id(i)); 
                    oe_debug_pub.ADD('Ship_to_geocode :'|| g_header_rec.ship_to_geocode(i));
            END IF;
            IF g_header_rec.ship_to_org_id(i) IS NULL THEN
                Set_Header_Error(i);
                set_msg_context( p_entity_code  => 'HEADER');
                g_header_rec.ship_to_org(i) := lc_orig_sys_ship_address_ref;
                lc_err_msg := 'Not able to find the ShipTo for : ' || lc_orig_sys_ship_address_ref ;
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAIL_SHIPTO_DERIVATION');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE', lc_orig_sys_ship_address_ref);
                oe_bulk_msg_pub.add;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.ADD(lc_err_msg, 1);
                END IF;
            END IF;

            -- If no default billTo setup for the shipto then use the Primary BillTo on the order
            IF g_header_rec.invoice_to_org_id(i) IS NULL THEN
                -- Get Primary BillTo for the customer account
                Get_Def_BillTo( p_cust_account_id => g_header_rec.sold_to_org_id(i)
                              , x_bill_to_org_id => g_header_rec.invoice_to_org_id(i));
                IF g_header_rec.Invoice_to_org_id(i) IS NULL THEN
                    Set_Header_Error(i);
                    set_msg_context( p_entity_code  => 'HEADER');
                    lc_err_msg := 'No Bill To found for the customer : ' || g_header_rec.sold_to_org_id(i);
                    FND_MESSAGE.SET_NAME('XXOM','XX_OM_NO_DEF_BILLTO');
                    FND_MESSAGE.SET_TOKEN('ATTRIBUTE',lc_orig_sys_customer_ref );
                    oe_bulk_msg_pub.add;
                    IF ln_debug_level > 0 THEN
                        oe_debug_pub.ADD(lc_err_msg, 1);
                    END IF;
                END IF;
            END IF;

        END IF; -- for non-store customers

    ELSE -- g_header_rec.sold_to_org_id(i)
        g_header_rec.ship_to_org_id(i) := NULL;
        g_header_rec.invoice_to_org_id(i) := NULL;
        g_header_rec.ship_to_geocode(i) := NULL;
    END IF;

    -- For SPC and PRO card orders, get the Soft Header Info and Actual ShipTo address
    IF lc_order_source in ('S','U') AND
       g_header_rec.sold_to_org_id(i) IS NOT NULL AND
       g_header_rec.ship_to_org_id(i) IS NOT NULL AND
       g_header_rec.invoice_to_org_id(i) IS NOT NULL 
    THEN
        BEGIN
            -- No need to get the Soft Header info as it will be passed by SAS in future
            -- Get the Soft Header Info ..
            /*
            SELECT ATTRIBUTE1
                 , ATTRIBUTE3
                 , ATTRIBUTE5
                 , ATTRIBUTE10
            INTO   g_header_rec.customer_po_number(i)
                 , g_header_rec.release_number(i)
                 , g_header_rec.cust_dept_no(i)
                 , g_header_rec.desk_top_no(i)
            FROM HZ_CUST_ACCOUNTS
            WHERE CUST_ACCOUNT_ID = g_header_rec.sold_to_org_id(i);
            */

            -- Get the ShipTo address
            SELECT ADDRESS1
                 , ADDRESS2
                 , CITY
                 , STATE
                 , COUNTRY
                 , POSTAL_CODE
                 , COUNTY
            INTO   g_header_rec.ship_to_address1(i)
                 , g_header_rec.ship_to_address2(i)
                 , g_header_rec.ship_to_city(i)
                 , g_header_rec.ship_to_state(i)
                 , g_header_rec.ship_to_country(i)
                 , g_header_rec.ship_to_zip(i)
                 , g_header_rec.ship_to_county(i)
            FROM HZ_CUST_SITE_USES_ALL SITE, 
                 HZ_PARTY_SITES PARTY_SITE,
                 HZ_LOCATIONS LOC, 
                 HZ_CUST_ACCT_SITES_ALL ACCT_SITE
            WHERE SITE.SITE_USE_ID = g_header_rec.ship_to_org_id(i)
            AND ACCT_SITE.CUST_ACCOUNT_ID = g_header_rec.sold_to_org_id(i)
            AND SITE.SITE_USE_CODE = 'SHIP_TO'
            AND SITE.org_id = g_org_id
            AND SITE.CUST_ACCT_SITE_ID = ACCT_SITE.CUST_ACCT_SITE_ID
            AND ACCT_SITE.PARTY_SITE_ID = PARTY_SITE.PARTY_SITE_ID
            AND PARTY_SITE.LOCATION_ID = LOC.LOCATION_ID;

        EXCEPTION
            WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to get either the soft header or shipto address for '||g_header_rec.orig_sys_document_ref(i));
        END;
    END IF;

    -- Get the Ship_Method_Code for Header record
    IF g_header_rec.delivery_method(i) IS NOT NULL THEN
        g_header_rec.shipping_method_code(i) := Get_Ship_Method(g_header_rec.delivery_method(i));
        IF g_header_rec.shipping_method_code(i) IS NULL THEN
             Set_Header_Error(i);
             g_header_rec.shipping_method(i) := g_header_rec.delivery_method(i);
             set_msg_context( p_entity_code  => 'HEADER');
             lc_err_msg := 'No Shipping Method found for : ' || g_header_rec.delivery_method(i);
             FND_MESSAGE.SET_NAME('XXOM','XX_OM_NO_SHIP_METHOD');
             FND_MESSAGE.SET_TOKEN('ATTRIBUTE',g_header_rec.delivery_method(i));
             oe_bulk_msg_pub.add;
             IF ln_debug_level > 0 THEN
                 oe_debug_pub.ADD(lc_err_msg, 1);
             END IF;
        END IF;
    END IF;

    -- Read Tax Exemption Details
    IF G_header_rec.tax_exempt_number(i) IS NOT NULL THEN
        G_header_rec.tax_exempt_reason(i) := 'EXEMPT';
        G_header_rec.tax_exempt_flag(i) := 'O';
    ELSE
        G_header_rec.tax_exempt_reason(i) := NULL;
        G_header_rec.tax_exempt_flag(i) := 'S';
    END IF;

    -- If the order is for TAX CREDIT ONLY orders then it will not have any line records.
    -- We will need to create one line record with dummy item = 'TAX REFUND'.
    IF SUBSTR(G_Header_rec.Return_act_cat_code(i),1,2) = 'ST' THEN
        -- Create an order line with dummy item for TAX REFUND
        IF ln_debug_level > 0 THEN
           oe_debug_pub.ADD('This is a TAX REFUND ORDER', 1);
        END IF;
        Create_Tax_Refund_Line(p_hdr_idx   => i
                             , p_order_rec => p_order_rec
                              );
    END IF;

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Order Type is '||g_header_rec.order_type_id(i));
        oe_debug_pub.add('Change Seq is '||g_header_rec.change_sequence(i));
        oe_debug_pub.add('Order Category is '||g_header_rec.order_category(i));
        oe_debug_pub.add('Return Reason is '||g_header_rec.return_reason(i));
        oe_debug_pub.add('Request_id '||g_request_id);
        oe_debug_pub.add('Order Source is '||g_header_rec.order_source_id(i));
        oe_debug_pub.add('Price List Id is  '||g_header_rec.price_list_id(i));
        oe_debug_pub.add('Shipping Method is  '||g_header_rec.shipping_method_code(i));
        oe_debug_pub.add('Salesrep is  '||g_header_rec.salesrep_id(i));
        oe_debug_pub.add('Sale Channel is  '||g_header_rec.sales_channel_code(i));
        oe_debug_pub.add('Warehouse is  '||g_header_rec.ship_from_org_id(i));
        oe_debug_pub.add('Ship To id is  '||g_header_rec.ship_to_org_id(i));
        oe_debug_pub.add('Ship To Org is  '||g_header_rec.ship_to_org(i));
        oe_debug_pub.add('Invoice To Org is  '||g_header_rec.Invoice_to_org(i));
        oe_debug_pub.add('Invoice To Org Id is  '||g_header_rec.Invoice_to_org_id(i));
        oe_debug_pub.add('Sold To Org Id is  '||g_header_rec.Sold_to_org_id(i));
        oe_debug_pub.add('Sold To Org is  '||g_header_rec.Sold_to_org(i));
        oe_debug_pub.add('Paid At Store ID is '||g_header_rec.paid_at_store_id(i));
        oe_debug_pub.add('Paid At Store No is '||g_header_rec.paid_at_store_no(i));
        oe_debug_pub.add('Payment Term ID is '||g_header_rec.payment_term_id(i));
        oe_debug_pub.add('Gift Flag is '||g_header_rec.gift_flag(i));
        oe_debug_pub.add('Error Flag is '||g_header_rec.error_flag(i));
    END IF;

    -- Increment the global header counter
    G_header_counter := G_header_counter + 1;

    -- Return success
    x_return_status := 'S';
EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to process Header '||g_header_rec.orig_sys_document_ref(i));
        FND_FILE.PUT_LINE(FND_FILE.LOG,'The error is '||SQLERRM);
        -- Need to clear this BAD order
        CLEAR_BAD_ORDERS('HEADER',g_header_rec.orig_sys_document_ref(i));
        x_return_status := 'U';
END process_header;


PROCEDURE process_line (
      p_order_rec IN order_rec_type
    , p_batch_id IN NUMBER
    , x_return_status OUT NOCOPY VARCHAR2
    ) IS

-- +===================================================================+
-- | Name  : process_line                                              |
-- | Description      : This Procedure will read the lines line from   |
-- |                     file validate , derive and insert into        |
-- |                    oe_lines_iface_all tbl and xx_om_lines_attr    |
-- |                    _iface_all                                     |
-- |                                                                   |
-- | Paramenters        p_order_rec IN order_rec_type                  |
-- |                    p_batch_id  IN batch_id                        |
-- +===================================================================+
  i                       NUMBER;
  ln_hdr_ind              NUMBER;
  lc_item                 VARCHAR2(7);
  ln_item                 NUMBER;
  lc_err_msg              VARCHAR2(200);
  lc_source_type_code     VARCHAR2(50);
  ln_line_count           NUMBER;
  lc_customer_item        VARCHAR2(50);
  lc_order_qty_sign         VARCHAR2(1);
  lc_return_attribute2    VARCHAR2(50);
  ln_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
  ln_item_id              NUMBER;
  ln_bundle_id            NUMBER;
  ln_header_id            NUMBER;
  ln_line_id              NUMBER;
  ln_orig_sell_price      NUMBER;
  ln_orig_ord_qty         NUMBER;

BEGIN
    x_return_status := 'S';

    -- Line number counter per order
    G_Line_Nbr_Counter := G_Line_Nbr_Counter + 1;

    i := g_line_rec.orig_sys_document_ref.COUNT + 1;

    ln_hdr_ind := g_header_rec.orig_sys_document_ref.COUNT;
    lc_order_qty_sign  := SUBSTR(p_order_rec.file_line, 40,  1);

    IF G_Header_Rec.Order_Category(ln_hdr_ind) = 'ORDER' THEN
        G_Batch_counter := G_Batch_counter + 1;
        G_Line_Rec.Request_id(i) := G_Request_id;
        G_Order_Line_Tax_ctr := G_Order_Line_Tax_ctr + 1;
    ELSE
        IF lc_order_qty_sign = '-' THEN
            G_RMA_Line_Tax_ctr := G_RMA_Line_Tax_ctr + 1;
        ELSE
            G_Order_Line_Tax_ctr := G_Order_Line_Tax_ctr + 1;
        END IF;
        G_Line_Rec.Request_id(i) := NULL;
    END IF;

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Entering Line Processing' || ln_hdr_ind );
        oe_debug_pub.add('Line Count is '||i);
        oe_debug_pub.add('G_Order_Line_Counter is '||G_Order_Line_Tax_ctr);
        oe_debug_pub.add('G_RMA_Line_Tax_ctr is '||G_RMA_Line_Tax_ctr);
        oe_debug_pub.add('Tax Value as header is '||G_Header_Rec.Tax_Value(ln_hdr_ind));
    END IF;

    IF G_Line_Id.EXISTS(g_Line_Id_Seq_Ctr) THEN
        G_Line_Rec.Line_ID(i) := G_Line_Id(g_Line_Id_Seq_Ctr);
        g_Line_Id_Seq_Ctr := g_Line_Id_Seq_Ctr + 1;
    ELSE 
        -- Get the value from Sequence
        SELECT oe_order_lines_s.nextval
        INTO   G_Line_Rec.Line_ID(i)
        FROM DUAL;
    END IF;

    G_line_Rec.orig_sys_document_ref(i) := g_header_rec.orig_sys_document_ref(ln_hdr_ind);
    G_line_rec.orig_sys_line_ref(i)     := SUBSTR(p_order_rec.file_line, 23, 5);
    G_line_rec.order_source_id(i)       := g_header_rec.order_source_id(ln_hdr_ind);
    G_line_rec.change_sequence(i)       := g_header_rec.change_sequence(ln_hdr_ind);
    G_line_rec.line_number(i)           := G_Line_Nbr_Counter; --G_line_rec.orig_sys_line_ref(i);

    -- For first line of an order
    IF G_Line_Nbr_Counter = 1 THEN
        G_Header_Rec.start_line_index(ln_hdr_ind) := i;
    END IF;

    -- Set Tax value on first return line of order if tax value < 0
    -- Set Tax value on first outbound line of order is tax value >= 0

    IF G_Order_Line_Tax_ctr = 1 AND G_Header_Rec.Tax_Value(ln_hdr_ind) >= 0 THEN
        G_Line_Rec.Tax_Value(i) := G_Header_Rec.Tax_Value(ln_hdr_ind);
        G_Line_Rec.canada_pst(i) := G_Header_Rec.pst_tax_value(ln_hdr_ind);
        -- Increment the counter so that it does not assign it again
        G_Order_Line_Tax_ctr := G_Order_Line_Tax_ctr + 1;
    ELSIF G_RMA_Line_Tax_ctr = 1 AND G_Header_Rec.Tax_Value(ln_hdr_ind) < 0 THEN
        G_Line_Rec.Tax_Value(i) := -1 * G_Header_Rec.Tax_Value(ln_hdr_ind);
        G_Line_Rec.canada_pst(i) := -1 * G_Header_Rec.pst_tax_value(ln_hdr_ind);
        -- Increment the counter so that it does not assign it again
        G_RMA_Line_Tax_ctr := G_RMA_Line_Tax_ctr + 1;
    ELSE
        G_Line_Rec.Tax_Value(i) := 0;
        G_Line_Rec.canada_pst(i) := 0;
    END IF;

    ln_item := LTRIM(SUBSTR(p_order_rec.file_line, 33,  7));
    IF ln_item <= 99999 THEN
        lc_item := LPAD(ln_item,6,'0');
    ELSE 
        lc_item := ln_item;
    END IF;

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Start Line Index is :'||G_Header_Rec.start_line_index(ln_hdr_ind));
        oe_debug_pub.add('Item Read from file is :'||lc_item);
    END IF;

    G_line_rec.schedule_ship_date(i)    := NULL; --g_header_rec.ship_date(ln_hdr_ind);
    G_line_rec.actual_ship_date(i)      := NULL;
    G_Line_rec.sas_sale_date(i)         := g_header_rec.sas_sale_date(ln_hdr_ind);
    G_Line_rec.aops_ship_date(i)        := g_header_rec.ship_date(ln_hdr_ind);
    G_line_rec.salesrep_id(i)           := g_header_rec.salesrep_id(ln_hdr_ind);
    G_line_rec.ordered_quantity(i)      := SUBSTR(p_order_rec.file_line, 41,  5);
    G_line_rec.order_quantity_uom(i)    := SUBSTR(p_order_rec.file_line,187, 2);
    G_line_rec.shipped_quantity(i)      := LTRIM(SUBSTR(p_order_rec.file_line, 47,  5));

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Start Line Index is :111');
    END IF;

    -- If the shipped quantity is coming in as 0 , for credit only returns, then set it to NULL.
    IF G_line_rec.shipped_quantity(i) = 0 THEN
        G_line_rec.shipped_quantity(i) := NULL;
    END IF;
    G_line_rec.sold_to_org_id(i)        := g_header_rec.sold_to_org_id(ln_hdr_ind);
    G_line_rec.ship_from_org_id(i)      := g_header_rec.ship_from_org_id(ln_hdr_ind);
    G_line_rec.ship_to_org_id(i)        := g_header_rec.ship_to_org_id(ln_hdr_ind);
    G_line_rec.invoice_to_org_id(i)     := g_header_rec.invoice_to_org_id(ln_hdr_ind);
    G_line_rec.sold_to_contact_id(i)    := g_header_rec.sold_to_contact_id(ln_hdr_ind);
    G_line_rec.drop_ship_flag(i)        := g_header_rec.drop_ship_flag(ln_hdr_ind);
    G_line_rec.price_list_id(i)         := g_header_rec.price_list_id(ln_hdr_ind);
    -- Changing following code to avoid rounding errors. 08/15/2008
    -- Use the extended amount to derive the unit price
    -- G_line_rec.unit_list_price(i)       := SUBSTR(p_order_rec.file_line, 70, 10);
    -- G_line_rec.unit_selling_price(i)    := SUBSTR(p_order_rec.file_line, 70, 10);
    G_line_rec.unit_list_price(i)       := SUBSTR(p_order_rec.file_line, 92, 10) / nvl(G_line_rec.shipped_quantity(i),G_line_rec.ordered_quantity(i));
    G_line_rec.unit_selling_price(i)    := G_line_rec.unit_list_price(i);

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Start Line Index is :112');
    END IF;

    G_line_rec.tax_date(i)              := g_header_rec.ordered_date(ln_hdr_ind);
    G_line_rec.shipping_method_code(i)  := g_header_rec.shipping_method_code(ln_hdr_ind);

    G_line_rec.customer_po_number(i)    := g_header_rec.customer_po_number(ln_hdr_ind);
    G_line_rec.shipping_instructions(i) := g_header_rec.shipping_instructions(ln_hdr_ind);
    lc_customer_item                    := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,  107, 20)));
    G_line_rec.ret_ref_header_id(i)     := NULL;
    G_line_rec.ret_ref_line_id(i)       := NULL;
    G_line_rec.return_context(i)        := NULL;
    G_line_rec.return_attribute1(i)     := NULL;
    G_line_rec.return_attribute2(i)     := NULL;
    G_line_rec.org_order_creation_date(i) := NULL;
    G_line_rec.desk_top_no(i)           := g_header_rec.desk_top_no(ln_hdr_ind);
    G_line_rec.release_number(i)        := g_header_rec.release_number(ln_hdr_ind);
    -- Always populate return action category code for all lines under order category of  Mixed / Return.
    G_Line_Rec.Return_act_cat_code(i)   := g_header_rec.Return_act_cat_code(ln_hdr_ind);
    G_Line_Rec.tax_exempt_flag(i)       := g_header_rec.Tax_Exempt_Flag(ln_hdr_ind);
    G_Line_Rec.tax_exempt_number(i)     := g_header_rec.Tax_Exempt_number(ln_hdr_ind);
    G_Line_Rec.tax_exempt_reason(i)     := g_header_rec.Tax_Exempt_reason(ln_hdr_ind);

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Start Line Index is :113');
    END IF;

    -- Read the data warehouse attributes
    G_line_rec.price_cd(i)              := g_header_rec.price_cd(ln_hdr_ind);
    G_line_rec.price_change_reason_cd(i):= TRIM(SUBSTR(p_order_rec.file_line,  289, 5));
    -- modified on 14-mar-2009 by NB changed 2 to 5 characters read
    G_line_rec.price_prefix_cd(i)       := TRIM(SUBSTR(p_order_rec.file_line,  294, 5));
    G_line_rec.commisionable_ind(i)     := TRIM(SUBSTR(p_order_rec.file_line,  288, 1));
    G_line_rec.unit_orig_selling_price(i):= TRIM(SUBSTR(p_order_rec.file_line, 299, 11));
    -- Read customer line number
    G_Line_Rec.customer_line_number(i)  := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,  283, 5)));
    
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Start Line Index is :1114');
    END IF;

    IF lc_order_qty_sign = '-' THEN
        G_line_rec.line_category_code(i)    := 'RETURN';
        G_Line_Rec.schedule_status_code(i)  := NULL;
        G_line_rec.calc_arrival_date(i)     := g_header_rec.ship_date(ln_hdr_ind);
        G_Line_Rec.org_order_creation_date(i):= g_header_rec.org_order_creation_date(ln_hdr_ind);
        G_line_rec.return_reason_code(i)    := g_header_rec.return_reason(ln_hdr_ind);
        G_Header_Rec.order_total(ln_hdr_ind):= G_Header_Rec.order_total(ln_hdr_ind) + 
                                               (G_line_rec.unit_selling_price(i) * 
                                                NVL(G_Line_Rec.Shipped_quantity(i),G_line_rec.ordered_quantity(i)) * -1);
     ELSE
        G_line_rec.line_category_code(i)    := 'ORDER';
        IF g_header_rec.ORDER_CATEGORY(ln_hdr_ind) <> 'ORDER' THEN
            G_Line_Rec.schedule_status_code(i)  := NULL;
        ELSE
            G_Line_Rec.schedule_status_code(i)  := NULL; --'SCHEDULED';
        END IF;
        -- Once rules are derived we will add logic to calculate the schedule_arrival_date
        G_line_rec.calc_arrival_date(i)       := g_header_rec.ship_date(ln_hdr_ind);
        G_Line_Rec.org_order_creation_date(i) := NULL;
        G_line_rec.return_reason_code(i)      := NULL;
        G_Header_Rec.order_total(ln_hdr_ind):= G_Header_Rec.order_total(ln_hdr_ind) + (G_line_rec.unit_selling_price(i) * 
                                                NVL(G_Line_Rec.Shipped_Quantity(i),G_line_rec.ordered_quantity(i)));
    END IF;

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Start Line Index is :115');
    END IF;
    -- oe_debug_pub.add('The order total is ' || G_Header_Rec.order_total(ln_hdr_ind));
    G_line_rec.vendor_product_code(i)   := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 147, 20)));
    G_line_rec.wholesaler_item(i)       := LTRIM(SUBSTR(p_order_rec.file_line, 127, 20));
    G_line_rec.legacy_list_price(i)     := LTRIM(SUBSTR(p_order_rec.file_line, 59, 10));
    G_line_rec.contract_details(i)      := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 167, 20)));
    G_line_rec.taxable_flag(i)          := LTRIM(SUBSTR(p_order_rec.file_line, 189, 1));
    G_line_rec.sku_dept(i)              := LTRIM(SUBSTR(p_order_rec.file_line, 190, 3));
    G_line_rec.item_source(i)           := LTRIM(SUBSTR(p_order_rec.file_line, 193, 2));
    G_line_rec.average_cost(i)          := LTRIM(SUBSTR(p_order_rec.file_line, 207, 10));
    G_line_rec.po_cost(i)               := LTRIM(SUBSTR(p_order_rec.file_line, 196, 10));
    G_line_rec.back_ordered_qty(i)      := LTRIM(SUBSTR(p_order_rec.file_line, 53,  5));
    G_line_rec.line_comments(i)         := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 336, 245)));
    -- NO more copy from header. Read the value from line record
    G_line_rec.cust_dept_no(i)          := SUBSTR(p_order_rec.file_line, 581, 20);
    G_line_rec.cust_dept_description(i) := SUBSTR(p_order_rec.file_line, 601, 25);
    -- Need to read from file..
    G_line_rec.item_comments(i)         := NULL;
    G_line_rec.payment_term_id(i)       := g_header_rec.payment_term_id(ln_hdr_ind);

     IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Start Line Index is :116');
    END IF;

    IF G_line_rec.line_category_code(i) = 'RETURN' THEN
        G_line_rec.return_reference_no(i)   := g_header_rec.return_orig_sys_doc_ref(ln_hdr_ind);
        G_line_rec.return_ref_line_no(i)    := SUBSTR(p_order_rec.file_line, 102, 5);
    ELSE
        G_line_rec.return_reference_no(i)   := NULL;
        G_line_rec.return_ref_line_no(i)    := NULL;
    END IF;

    -- Once Bob sends the entered product code uncomment the below line
    G_line_rec.user_item_description(i) := RTRIM(SUBSTR(p_order_rec.file_line, 218, 20));
    G_line_rec.line_type_id(i) := NULL;
    G_Line_Rec.ordered_date(i) := G_Header_Rec.Ordered_Date(ln_hdr_ind);
    G_line_rec.inventory_item(i) := NULL;
    G_line_rec.customer_item_name(i) := NULL;
    G_Line_rec.config_code(i) := RTRIM(SUBSTR(p_order_rec.file_line, 248, 20));
    G_Line_rec.gsa_flag(i)    := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 268,  1))); --Added By NB
    ln_bundle_id := TO_NUMBER(LTRIM(SUBSTR(p_order_rec.file_line, 238, 10)));
    G_line_rec.orig_selling_price(i) := NULL;

    IF ln_bundle_id = 0 THEN
        G_line_rec.ext_top_model_line_id(i) := G_line_rec.line_id(i);
        G_line_rec.ext_link_to_line_id(i) := G_line_rec.line_id(i);
        G_Curr_Top_Line_Id := G_line_rec.line_id(i);
    ELSIF ln_bundle_id > 0 THEN
        G_line_rec.ext_top_model_line_id(i) := G_Curr_Top_Line_Id;
        G_line_rec.ext_link_to_line_id(i) := G_Curr_Top_Line_Id;
    ELSE
        G_line_rec.ext_top_model_line_id(i) := NULL;
        G_line_rec.ext_link_to_line_id(i) := NULL;
    END IF;

    oe_debug_pub.add('8 ');
    G_line_rec.waca_item_ctr_num(i)     := TRIM(SUBSTR(p_order_rec.file_line, 269, 12));
    G_line_rec.consignment_bank_code(i) := TRIM(SUBSTR(p_order_rec.file_line, 281, 2));

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Tax Value is '||G_Line_Rec.Tax_Value(i));
        oe_debug_pub.add('Tax Value PST is '||G_Line_Rec.canada_pst(i));
        oe_debug_pub.add('Customer Item is '|| lc_customer_item);
        oe_debug_pub.ADD('orig_sys_document_ref = '||G_line_Rec.orig_sys_document_ref(i));
        oe_debug_pub.ADD('orig_sys_line_ref = '||G_line_rec.orig_sys_line_ref(i));
        oe_debug_pub.ADD('order_source_id = '||G_line_rec.order_source_id(i));
        oe_debug_pub.ADD('change_sequence = '||G_line_rec.change_sequence(i));
        oe_debug_pub.ADD('line_number = '||G_line_rec.line_number(i));
        oe_debug_pub.ADD('lc_order_qty_sign = '||lc_order_qty_sign);
        oe_debug_pub.ADD('ln_item = '||ln_item);
        oe_debug_pub.ADD('schedule_ship_date = '||G_line_rec.schedule_ship_date(i));
        oe_debug_pub.ADD('actual_ship_date = '||G_line_rec.actual_ship_date(i));
        oe_debug_pub.ADD('salesrep_id = '||G_line_rec.salesrep_id(i));
        oe_debug_pub.ADD('ordered_quantity = '||G_line_rec.ordered_quantity(i));
        oe_debug_pub.ADD('shipped_quantity = '||G_line_rec.shipped_quantity(i));
        oe_debug_pub.ADD('sold_to_org_id = '||G_line_rec.sold_to_org_id(i));
        oe_debug_pub.ADD('ship_from_org_id = '||G_line_rec.ship_from_org_id(i));
        oe_debug_pub.ADD('ship_to_org_id = '||G_line_rec.ship_to_org_id(i));
        oe_debug_pub.ADD('invoice_to_org_id = '||G_line_rec.invoice_to_org_id(i));
        oe_debug_pub.ADD('sold_to_contact_id = '||G_line_rec.sold_to_contact_id(i));
        oe_debug_pub.ADD('drop_ship_flag = '||G_line_rec.drop_ship_flag(i));
        oe_debug_pub.ADD('price_list_id(i) = '||G_line_rec.price_list_id(i));
        oe_debug_pub.ADD('unit_list_price = '||G_line_rec.unit_list_price(i));
        oe_debug_pub.ADD('unit_selling_price = '||G_line_rec.unit_selling_price(i));
        oe_debug_pub.ADD('tax_date = '||G_line_rec.tax_date(i));
        oe_debug_pub.ADD('shipping_method_code = '||G_line_rec.shipping_method_code(i));
        oe_debug_pub.ADD('line_number = '||G_line_rec.line_number(i));
        oe_debug_pub.ADD('Return Reason Code = '||G_line_rec.return_reason_code(i));
        oe_debug_pub.ADD('customer_po_number(i) = '||G_line_rec.customer_po_number(i) );
        oe_debug_pub.ADD('shipping_instructions = '||G_line_rec.shipping_instructions(i));
        oe_debug_pub.ADD('lc_customer_item = '||lc_customer_item);
        oe_debug_pub.ADD('G_line_rec.line_category_code(i) = '||G_line_rec.line_category_code(i));
        oe_debug_pub.ADD('Return Ref no :' ||G_line_rec.return_reference_no(i), 1);
        oe_debug_pub.ADD('Return Ref Line no :' ||G_line_rec.return_ref_line_no(i), 1);
        oe_debug_pub.ADD('User Item Description :' ||G_line_rec.user_item_description(i), 1);
        oe_debug_pub.add('Bundle ID '||ln_bundle_id);
        oe_debug_pub.add('Ext top model id : ' ||G_line_rec.ext_top_model_line_id(i),1);
        oe_debug_pub.add('Ext Link To Line id : ' ||G_line_rec.ext_link_to_line_id(i),1);
        oe_debug_pub.add('Config Code : ' ||G_line_rec.config_code(i), 1);
    END IF;

    -- Validate Item and Warehouse/Store
    Validate_Item_Warehouse( p_hdr_idx  => ln_hdr_ind
                           , p_line_idx => i
                           , p_item     => lc_item);

    IF lc_customer_item IS NOT NULL THEN
        G_line_rec.customer_item_id(i) := customer_item_id(lc_customer_item,G_header_rec.sold_to_org_id(ln_hdr_ind));
        G_line_rec.customer_item_id_type(i) := NULL ; --'CUST';
        IF G_line_rec.customer_item_id(i) IS NULL THEN
            G_line_rec.customer_item_name(i) := lc_customer_item;
        END IF;
    ELSE
        G_line_rec.customer_item_id(i) := NULL;
        G_line_rec.customer_item_id_type(i) := NULL;
        G_line_rec.customer_item_name(i) := lc_customer_item;
    END IF;

    /*
    IF g_header_rec.legacy_order_type(ln_hdr_ind) IS NOT NULL THEN
        g_line_rec.line_type_id(i) := oe_sys_Parameters.value(g_header_rec.legacy_order_type(ln_hdr_ind)||'-L',G_Org_Id);
    ELSIF g_header_rec.legacy_order_type(ln_hdr_ind) IS NULL AND lc_order_qty_sign = '+' THEN
        g_line_rec.line_type_id(i) := oe_sys_Parameters.value('D-SL',G_Org_Id);
    ELSIF g_header_rec.legacy_order_type(ln_hdr_ind) IS NULL AND lc_order_qty_sign = '-' THEN
        g_line_rec.line_type_id(i) := oe_sys_Parameters.value('D-RL',G_Org_Id);
    END IF;
    */

    -- Simple line type assignments
    IF lc_order_qty_sign = '+' THEN
        g_line_rec.line_type_id(i) := oe_sys_Parameters.value('D-SL',G_Org_Id);
    ELSE
        g_line_rec.line_type_id(i) := oe_sys_Parameters.value('D-RL',G_Org_Id);
    END IF;

    -- Since Line Type is a required field for order check if it has got derived
    IF g_line_rec.line_type_id(i) IS NULL THEN
        Set_Header_Error(ln_hdr_ind);
        set_msg_context( p_entity_code => 'HEADER'
                        ,p_line_ref    => G_Line_Rec.Orig_Sys_Line_Ref(i));
        lc_err_msg := 'Failed to derive Line Type For the line ';
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAILED_LINE_TYPE');
        oe_bulk_msg_pub.add;
        IF ln_debug_level > 0 THEN
            oe_debug_pub.ADD(lc_err_msg, 1);
        END IF;

    END IF;

    IF g_line_rec.line_category_code(i) = 'RETURN' AND
       G_line_rec.return_reference_no(i) IS NOT NULL AND
       G_line_rec.return_ref_line_no(i) IS NOT NULL
    THEN
        IF ln_debug_level > 0 THEN
            oe_debug_pub.ADD('This return has reference', 1);
        END IF;
        ln_header_id := NULL;
        ln_line_id := NULL;
        ln_orig_sell_price := NULL;
        ln_orig_ord_qty := NULL;
        Get_return_attributes( G_line_rec.return_reference_no(i)
                         , G_line_rec.return_ref_line_no(i)
                         , G_line_rec.sold_to_org_id(i)
                         , ln_header_id
                         , ln_line_id
                         , ln_orig_sell_price
                         , ln_orig_ord_qty
                         );

        IF ln_debug_level > 0 THEN
            oe_debug_pub.ADD('Ref Header Id is  ' || ln_header_id, 1);
            oe_debug_pub.ADD('Ref Line Id is  ' || ln_line_id, 1);
            oe_debug_pub.ADD('Orig Sell Price is ' || ln_orig_sell_price, 1);
            oe_debug_pub.ADD('Orig Ord Qty is ' || ln_orig_ord_qty, 1);
        END IF;
        -- Store the original sell price for this return line.
        G_line_rec.orig_selling_price(i) := ln_orig_sell_price;
        G_line_rec.ret_ref_header_id(i) := ln_header_id;
        G_line_rec.ret_ref_line_id(i) := ln_line_id;

        -- For price variance return do not put the reference info on out of box fields as it can
        -- can cause issues when real product is returned.
        -- For legacy returns with reference, if the line quantity is greater than the original quantity in EBS
        -- then do not use the return_context and return_attributes to store the reference. This will prevent the return order from getting booked
        -- during over return check.
        -- We have found issues in using the out of box return reference fields. There are rounding issues with the order amounts. Hence
        -- we have decided to not use the reference info on return_context, return_attribute1 and return_attribute2.
            /*
            IF SUBSTR(G_line_rec.Return_act_cat_code(i),1,2) <> 'PV'  AND
               g_line_rec.ordered_quantity(i) <= ln_orig_ord_qty 
            THEN
                G_line_rec.return_context(i) := 'ORDER';
                G_line_rec.return_attribute1(i) := ln_header_id;
                G_line_rec.return_attribute2(i) := ln_line_id;
                -- Mark the Order as With Reference.
                G_Header_Rec.Is_Reference_Return(ln_hdr_ind) := 'Y';
            END IF;
            */
    END IF;

    -- Print all derived attributes
    IF ln_debug_level > 0 THEN
        oe_debug_pub.ADD('Line Type = '||G_line_rec.line_type_id(i));
        oe_debug_pub.ADD('Item = '||G_line_rec.inventory_item_id(i));
        oe_debug_pub.ADD('Item = '||G_line_rec.inventory_item(i));
        oe_debug_pub.ADD('Cust Item = '||G_line_rec.customer_item_id(i));
        oe_debug_pub.add('Error Flag is '||g_header_rec.error_flag(ln_hdr_ind));
    END IF;

    -- Increment the global Line counter used in determining batch size
    G_Line_counter := G_Line_counter + 1;

    x_return_status := 'S';

EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to process line record '||g_line_rec.orig_sys_line_ref(i) || ' for order '||g_header_rec.orig_sys_document_ref(ln_hdr_ind)||'-'||G_line_rec.orig_sys_line_ref(i));
        FND_FILE.PUT_LINE(FND_FILE.LOG,'The error is '||sqlerrm);
        -- Need to clear this BAD order
        CLEAR_BAD_ORDERS('LINE',g_line_rec.orig_sys_document_ref(i));
        x_return_status := 'U';
END process_line;

PROCEDURE process_payment(p_order_rec  IN order_rec_type
                        , p_batch_id   IN NUMBER
                        , p_pay_amt    IN OUT NOCOPY NUMBER 
                        , x_return_status OUT NOCOPY VARCHAR2
) IS

-- +===================================================================+
-- | Name  : process_payment                                           |
-- | Description      : This Procedure will read the payments line from|
-- |                     file validate , derive and insert into        |
-- |                    oe_payments_iface_all and xx_om_ret_tenders_   |
-- |                    iface_all tbls                                 |
-- |                                                                   |
-- | Parameters:        p_order_rec IN order_rec_type                  |
-- |                    p_batch_id  IN batch_id                        |
-- |                    p_pay_amt  OUT Return payment amount           |
-- +===================================================================+
  i                    BINARY_INTEGER;
  lc_pay_type           VARCHAR2(10);
  ln_sold_to_org_id     NUMBER;
  ln_payment_number     NUMBER := 0;
  lc_err_msg            VARCHAR2(1000);
  ln_hdr_ind            NUMBER;
  lc_payment_type_code  VARCHAR2(30);
  lc_cc_code            VARCHAR2(80);
  lc_cc_name            VARCHAR2(80);
  lc_pay_sign           VARCHAR2(1);
  ln_pay_amount         NUMBER;
  ln_receipt_method_id  NUMBER;
  ld_exp_date           DATE;
  ln_debug_level        CONSTANT NUMBER := oe_debug_pub.g_debug_level;
  --lr_pub_key            RAW(25);
  --lr_cc_act             RAW(128);
  lc_pay_seq            VARCHAR2(3);
  lc_key_name           VARCHAR2(25);
  lc_cc_number_enc      VARCHAR2(128);
  lc_cc_number_dec      VARCHAR2(80);
  lc_cc_mask            VARCHAR2(20);
  lc_cc_entry           VARCHAR2(30);
  lc_cvv_resp           VARCHAR2(1);
  lc_avs_resp           VARCHAR2(1);
  lc_auth_entry_mode    VARCHAR2(1);
  ln_length             NUMBER := 16;
  ln_pay_amt            NUMBER ;
BEGIN
    x_return_status := 'S';

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Entering Process_Payment');
    END IF;

    ln_hdr_ind := g_header_rec.orig_sys_document_ref.count;
    lc_pay_seq := SUBSTR(p_order_rec.file_line, 33,  3);
    lc_pay_type := SUBSTR(p_order_rec.file_line, 36,  2);
    lc_pay_sign := SUBSTR(p_order_rec.file_line, 38,  1);
  

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Pay Type ' || lc_pay_type);
        oe_debug_pub.add('Pay Sign: ' || lc_pay_sign);
    END IF;

    -- Read the Payment amount
    ln_pay_amount := SUBSTR(p_order_rec.file_line, 39, 10);


    IF lc_pay_type IS NULL THEN
        set_msg_context( p_entity_code => 'HEADER_PAYMENT');
        Set_Header_Error(ln_hdr_ind);
        lc_err_msg := 'PAYMENT METHOD Missing  ';
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
        FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Tender Type');
        oe_bulk_msg_pub.add;
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add(lc_err_msg, 1);
        END IF;

    END IF;

    -- Check if paying by debit card
    IF lc_pay_type = '16' AND
       lc_pay_sign = '+'
    THEN
        G_Has_Debit_Card := TRUE;
    ELSIF lc_pay_type = '01' AND
          lc_pay_sign = '-'  AND
          G_Has_Debit_Card
    THEN
        -- It is a CASH back Transaction and we will need to create a Line record.
        Create_CashBack_Line(p_Hdr_Idx => ln_hdr_ind
                           , p_amount  => ln_pay_amount);
        RETURN;
    END IF;

    -- Capture the payment total for the order
    -- p_pay_amt := p_pay_amt + ((lc_pay_sign)||ln_pay_amount);
    
     p_pay_amt := ln_pay_amt + ((lc_pay_sign)||ln_pay_amount);
    -- If the payment record is Account Billing or OD house account then Skip payment record creation
    IF lc_pay_type = 'AB' OR
       lc_pay_type = '20' THEN
        -- Need to skip the payment record creation
        GOTO SKIP_PAYMENT;
    END IF;

    IF lc_pay_type IS NOT NULL THEN
        Get_Pay_Method( p_payment_instrument => lc_pay_type
                  , p_payment_type_code  => lc_payment_type_code
                  , p_credit_card_code   => lc_cc_code);

        IF lc_payment_type_code IS NULL THEN
            set_msg_context( p_entity_code => 'HEADER_PAYMENT');
            Set_Header_Error(ln_hdr_ind);
            lc_payment_type_code := lc_pay_type;
            lc_err_msg := 'INVALID PAYMENT METHOD :' ||lc_pay_type;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAIL_PAYMTD_DERIVATION');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1',lc_pay_type);
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.add(lc_err_msg, 1);
            END IF;
        END IF;
    END IF;

    IF g_header_rec.legacy_cust_name(ln_hdr_ind) IS NULL THEN
        lc_cc_name := credit_card_name(g_header_rec.sold_to_org_id(ln_hdr_ind));
    ELSE
        lc_cc_name := g_header_rec.legacy_cust_name(ln_hdr_ind);
    END IF;

    -- Get the receipt method for the tender type
    ln_receipt_method_id := Get_receipt_method(lc_pay_type,g_org_id,G_Header_Rec.paid_at_store_no(ln_hdr_ind));

    -- For retun refund check there is no receipt method setup by AR. So it is OK to have null value for
    -- return refund payment record.
    IF ln_receipt_method_id IS NULL AND
       G_header_rec.order_category(ln_hdr_ind) = 'ORDER' AND
       lc_pay_type <> '11'
    THEN
        set_msg_context( p_entity_code => 'HEADER_PAYMENT');
        Set_Header_Error(ln_hdr_ind);
        lc_err_msg := 'Could not derive Receipt Method for the payment instrument';
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_NO_RECEIPT_METHOD');
        FND_MESSAGE.SET_TOKEN('ATTRIBUTE1',lc_pay_type);
        oe_bulk_msg_pub.add;
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add(lc_err_msg, 1);
        END IF;

    END IF;

    -- Read the CC exp date first
    BEGIN
        ld_exp_date := TO_DATE(LTRIM(SUBSTR(p_order_rec.file_line, 69,  4)),'MMYY');
    EXCEPTION
        WHEN OTHERS THEN
            ld_exp_date := NULL;
            Set_Header_Error(ln_hdr_ind);
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'Error reading CC Exp Date' || SUBSTR(p_order_rec.file_line, 69, 4);
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_READ_ERROR');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1','CC Exp Date');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',SUBSTR(p_order_rec.file_line, 69, 4));
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE3','MMYY');
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.add(lc_err_msg, 1);
            END IF;
    END;

    -- Read Credit Card Details..
    lc_key_name       := TRIM(SUBSTR (p_order_rec.file_line, 174, 25));
    lc_cc_number_enc  := TRIM(SUBSTR (p_order_rec.file_line, 199, 48));
    lc_cc_mask        := TRIM(SUBSTR (p_order_rec.file_line, 49,  20));
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Key Name' || lc_key_name, 1);
        --oe_debug_pub.add('CC Num' || lc_cc_number_enc, 1);
        oe_debug_pub.add('CC Mask' || lc_cc_mask, 1);
    END IF;

    IF lc_cc_number_enc IS NULL AND lc_cc_mask IS NOT NULL AND lc_payment_type_code = 'CREDIT_CARD' THEN
        lc_cc_number_enc := lc_cc_mask;
    END IF;

    IF lc_cc_number_enc IS NOT NULL THEN
        IF XX_OM_HVOP_UTIL_PKG.G_USE_TEST_CC = 'N' THEN
            -- Use the Credit card read from the file
            XX_OD_SECURITY_KEY_PKG.DECRYPT( p_module  => 'HVOP'
			          , p_key_label       => lc_key_name
			          , p_encrypted_val   => lc_cc_number_enc
			          , p_format          => 'EBCDIC'
                                  , x_decrypted_val   => lc_cc_number_dec
                                  , x_error_message   => lc_err_msg
                                  );
        ELSE
            -- Use the first 6 and last 4 of the CC mask and generate a TEST credit card
            IF lc_pay_type = '26' THEN
                ln_length := 15;
            END IF;
            lc_cc_number_dec := XX_OM_HVOP_UTIL_PKG.GET_TEST_CC(SUBSTR(lc_cc_mask,1,6),SUBSTR(lc_cc_mask,7,4),ln_length);
            IF ln_debug_level > 0 THEN
                oe_debug_pub.add('Test CC number is '|| lc_cc_number_dec );
            END IF;
        END IF;

        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('CC Num' || lc_cc_number_dec, 1);
            oe_debug_pub.add('CC Num length' || length(lc_cc_number_dec), 1);
            oe_debug_pub.add('Error Message' || lc_err_msg, 1);
        END IF;

        IF lc_cc_number_dec IS NOT NULL THEN

            IF SUBSTR(lc_cc_number_dec,1,6)||SUBSTR(lc_cc_number_dec,-4,4) <> lc_cc_mask THEN
                Set_Header_Error(ln_hdr_ind);
                set_msg_context(p_entity_code => 'HEADER');
                lc_err_msg := 'Decrypted Credit card number :' || SUBSTR(lc_cc_number_dec,1,6)||SUBSTR(lc_cc_number_dec,-4,4) ||' does not match mask value ' || lc_cc_mask;
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_CC_MASK_MISMATCH');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE1',SUBSTR(lc_cc_number_dec,1,6)||SUBSTR(lc_cc_number_dec,-4,4));
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',lc_cc_mask);
                oe_bulk_msg_pub.add;
                IF ln_debug_level > 0 THEN
                   oe_debug_pub.add(lc_err_msg, 1);
                END IF;
            END IF;

            -- Get the encrypted value from ORACLE API
            lc_cc_number_dec := Get_Secure_Card_Number(lc_cc_number_dec);
            oe_debug_pub.add('Oracle enc cc num is '|| lc_cc_number_dec );
        END IF;

    END IF;

    --IF G_header_rec.order_category(ln_hdr_ind) = 'ORDER' THEN
    IF lc_pay_sign = '+' THEN
        oe_debug_pub.add('Start reading Payment Record 2');
        i :=g_payment_rec.orig_sys_document_ref.count+1;
        G_payment_rec.payment_type_code(i)          := lc_payment_type_code;
        G_payment_rec.receipt_method_id(i)          := ln_receipt_method_id;
        G_payment_rec.orig_sys_document_ref(i)      := G_header_rec.orig_sys_document_ref(ln_hdr_ind);
        G_payment_rec.sold_to_org_id(i)             := G_header_rec.sold_to_org_id(ln_hdr_ind);
        G_payment_rec.order_source_id(i)            := G_header_rec.order_source_id(ln_hdr_ind);
        G_payment_rec.orig_sys_payment_ref(i)       := lc_pay_seq;
        G_payment_rec.prepaid_amount(i)             := NULL;
        G_payment_rec.payment_amount(i)             := ln_pay_amount;
        G_payment_rec.payment_set_id(i)             := NULL;
        G_payment_rec.credit_card_number(i)         := lc_cc_number_dec;

        IF lc_cc_number_enc IS NOT NULL THEN

            IF lc_cc_number_dec IS NULL THEN
                Set_Header_Error(ln_hdr_ind);
                G_payment_rec.credit_card_number(i) := lc_key_name||':'||lc_cc_number_enc;
                set_msg_context(p_entity_code => 'HEADER');
                lc_err_msg := 'Error Decrypting credit card number' || lc_cc_number_enc;
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_CC_DECRYPT_ERROR');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE1',lc_err_msg);
                oe_bulk_msg_pub.add;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add(lc_err_msg, 1);
                END IF;
            END IF;

            G_payment_rec.credit_card_expiration_date(i) := ld_exp_date;
            IF ld_exp_date IS NULL THEN
                set_msg_context( p_entity_code => 'HEADER_PAYMENT');
                Set_Header_Error(ln_hdr_ind);
                lc_err_msg := 'CC EXP DATE IS MISSING';
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Credit Card EXP date');
                oe_bulk_msg_pub.add;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add(lc_err_msg, 1);
                END IF;
            END IF;
            G_payment_rec.credit_card_code(i)            := lc_cc_code;
            IF lc_cc_code IS NULL THEN
                set_msg_context( p_entity_code => 'HEADER_PAYMENT');
                Set_Header_Error(ln_hdr_ind);
                lc_err_msg := 'Credit Card code IS MISSING';
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Credit Card Code');
                oe_bulk_msg_pub.add;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add(lc_err_msg, 1);
                END IF;
            END IF;
            G_payment_rec.credit_card_approval_code(i)   := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 75,  6)));

            -- Ignore the validation for Debit Cards, OD CHARGE and SPS
            IF G_payment_rec.credit_card_approval_code(i) IS NULL AND
                lc_pay_type NOT IN (16)
            THEN
                G_payment_rec.credit_card_approval_code(i) := '999999';
                -- commented out because we are defaulting the value '999999' NB
               /*
                set_msg_context( p_entity_code => 'HEADER_PAYMENT');
                Set_Header_Error(ln_hdr_ind);
                lc_err_msg := 'CC approval code is missing';
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Credit Card Approval Code');
                oe_bulk_msg_pub.add;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add(lc_err_msg, 1);
                END IF;
               */

            END IF;
            BEGIN
                G_payment_rec.credit_card_approval_date(i)   := TO_DATE(LTRIM(SUBSTR(p_order_rec.file_line, 81, 10)),'YYYY-MM-DD');

            EXCEPTION
                WHEN OTHERS THEN
                    G_payment_rec.credit_card_approval_date(i) := NULL;
                    Set_Header_Error(ln_hdr_ind);
                    set_msg_context(p_entity_code => 'HEADER');
                    lc_err_msg := 'Error reading CC Approval Date' || SUBSTR(p_order_rec.file_line, 81, 10);
                    FND_MESSAGE.SET_NAME('XXOM','XX_OM_READ_ERROR');
                    FND_MESSAGE.SET_TOKEN('ATTRIBUTE1','CC Approval Date');
                    FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',SUBSTR(p_order_rec.file_line, 81, 10));
                    FND_MESSAGE.SET_TOKEN('ATTRIBUTE3','YYYY-MM-DD');
                    oe_bulk_msg_pub.add;
                    IF ln_debug_level > 0 THEN
                       oe_debug_pub.add(lc_err_msg, 1);
                    END IF;
            END;

            -- Ignore the validation for Debit Cards, OD CHARGE and SPS
            IF G_payment_rec.credit_card_approval_date(i) IS NULL AND
                lc_pay_type NOT IN (16)
            THEN
                G_payment_rec.credit_card_approval_date(i) := G_header_rec.ordered_date(ln_hdr_ind);
               -- Defaulting the value to Order Date NB
               /*
                set_msg_context( p_entity_code => 'HEADER_PAYMENT');
                Set_Header_Error(ln_hdr_ind);
                lc_err_msg := 'CC approval date is missing';
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Credit Card Approval Date');
                oe_bulk_msg_pub.add;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add(lc_err_msg, 1);
                END IF;
               */
            END IF;
        ELSE
            G_payment_rec.credit_card_number(i)          := NULL;
            G_payment_rec.credit_card_expiration_date(i) := NULL;
            G_payment_rec.credit_card_code(i)            := NULL;
            G_payment_rec.credit_card_approval_code(i)   := NULL;
            G_payment_rec.credit_card_approval_date(i)   := NULL;
        END IF;

        G_payment_rec.check_number(i)               := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 91, 20)));
        G_payment_rec.payment_number(i)             := lc_pay_seq;
        G_payment_rec.attribute6(i)                 := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,  111, 1)));
        G_payment_rec.attribute7(i)                 := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 112, 11)));
        G_payment_rec.attribute8(i)                 := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 123, 50)));
        G_payment_rec.attribute9(i)                 := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,  173, 1)));
        G_payment_rec.credit_card_holder_name(i)    := lc_cc_name;
        G_payment_rec.attribute10(i)                := lc_cc_mask;
        G_payment_rec.attribute11(i)                := lc_pay_type;
        G_payment_rec.attribute15(i)                := NULL;

        -- Read the Debit Card Approval reference number
        G_payment_rec.attribute12(i)                := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,  247, 30)));

        -- Adding the code to capture CC entry mode (keyed or swiped), CVV response code and AVS response code
        lc_cc_entry := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 277, 1)));
        lc_cvv_resp := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 278, 1)));
        lc_avs_resp := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 279, 1)));
        lc_auth_entry_mode := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 280, 1)));
        G_payment_rec.attribute13(i) := lc_cc_entry||':'||lc_cvv_resp||':'||lc_avs_resp||':'||lc_auth_entry_mode;

        IF ln_debug_level > 0 THEN
            oe_debug_pub.ADD('lc_pay_type = '||lc_pay_type);
            oe_debug_pub.ADD('receipt_method = '||G_payment_rec.receipt_method_id(i));
            oe_debug_pub.ADD('orig_sys_document_ref = '||G_payment_rec.orig_sys_document_ref(i));
            oe_debug_pub.ADD('order_source_id = '||G_payment_rec.order_source_id(i));
            oe_debug_pub.ADD('orig_sys_payment_ref = '||G_payment_rec.orig_sys_payment_ref(i));
            oe_debug_pub.ADD('prepaid amount = '||G_payment_rec.prepaid_amount(i));
            oe_debug_pub.ADD('lc_cc_number = '||G_payment_rec.credit_card_number(i));
            oe_debug_pub.ADD('credit_card_expiration_date = '||G_payment_rec.credit_card_expiration_date(i));
            oe_debug_pub.ADD('credit_card_approval_code = '||G_payment_rec.credit_card_approval_code(i));
            oe_debug_pub.ADD('credit_card_approval_date = '||G_payment_rec.credit_card_approval_date(i));
            oe_debug_pub.ADD('check_number = '||G_payment_rec.check_number(i));
            oe_debug_pub.ADD('attribute6 = '||G_payment_rec.attribute6(i));
            oe_debug_pub.ADD('attribute7 = '||G_payment_rec.attribute7(i));
            oe_debug_pub.ADD('attribute8 = '||G_payment_rec.attribute8(i));
            oe_debug_pub.ADD('attribute9 = '||G_payment_rec.attribute9(i));
            oe_debug_pub.ADD('attribute10 = '||G_payment_rec.attribute10(i));
            oe_debug_pub.ADD('attribute11 = '||G_payment_rec.attribute11(i));
            oe_debug_pub.ADD('attribute12 = '||G_payment_rec.attribute12(i));
            oe_debug_pub.ADD('attribute13 = '||G_payment_rec.attribute13(i));
            oe_debug_pub.ADD('credit_card_holder_name = '||G_payment_rec.credit_card_holder_name(i));
            oe_debug_pub.add('Error Flag is '||g_header_rec.error_flag(ln_hdr_ind));
        END IF;
       

    ELSE -- If Sign is -ve then it is return tender info record
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('Start reading Payment Record for Return tender ');
        END IF;

        i :=G_Return_Tender_Rec.orig_sys_document_ref.count+1;
        G_Return_Tender_Rec.payment_type_code(i)           := lc_payment_type_code;
        G_return_tender_rec.orig_sys_document_ref(i)       := G_header_rec.orig_sys_document_ref(ln_hdr_ind);
        G_return_tender_rec.receipt_method_id(i)           := ln_receipt_method_id;
        G_return_tender_rec.order_source_id(i)             := G_header_rec.order_source_id(ln_hdr_ind);
        G_return_tender_rec.orig_sys_payment_ref(i)        := lc_pay_seq;
        G_return_tender_rec.payment_number(i)              := lc_pay_seq;
        G_return_tender_rec.credit_card_code(i)            := lc_cc_code;
        G_return_tender_rec.credit_card_number(i)          := lc_cc_number_dec;

        IF lc_cc_number_enc IS NOT NULL THEN
            IF lc_cc_number_dec IS NULL THEN
                Set_Header_Error(ln_hdr_ind);
                G_return_tender_rec.credit_card_number(i) := lc_key_name||':'||lc_cc_number_enc;
                set_msg_context(p_entity_code => 'HEADER');
                lc_err_msg := 'Error Decrypting credit card number' || lc_cc_number_enc;
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_CC_DECRYPT_ERROR');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE1',lc_err_msg);
                oe_bulk_msg_pub.add;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add(lc_err_msg, 1);
                END IF;
            END IF;
            G_return_tender_rec.credit_card_expiration_date(i) := ld_exp_date;
            IF ld_exp_date IS NULL THEN
                set_msg_context( p_entity_code => 'HEADER_PAYMENT');
                Set_Header_Error(ln_hdr_ind);
                lc_err_msg := 'CC EXP DATE IS MISSING';
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Credit Card EXP date');
                oe_bulk_msg_pub.add;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add(lc_err_msg, 1);
                END IF;
            END IF;
            IF lc_cc_code IS NULL THEN
                set_msg_context( p_entity_code => 'HEADER_PAYMENT');
                Set_Header_Error(ln_hdr_ind);
                lc_err_msg := 'Credit Card code IS MISSING';
                FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Credit Card Code');
                oe_bulk_msg_pub.add;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add(lc_err_msg, 1);
                END IF;
            END IF;
        ELSE
            G_return_tender_rec.credit_card_number(i)          := NULL;
            G_return_tender_rec.credit_card_expiration_date(i) := NULL;
        END IF;

        G_return_tender_rec.credit_amount(i)               := ln_pay_amount;
        G_return_tender_rec.sold_to_org_id(i)              := G_header_rec.sold_to_org_id(ln_hdr_ind);
        G_return_tender_rec.cc_auth_manual(i)              := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 111, 1)));
        G_return_tender_rec.merchant_nbr(i)                := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 112, 11)));
        G_return_tender_rec.cc_auth_ps2000(i)              := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 123, 50)));
        G_return_tender_rec.allied_ind(i)                  := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,  173, 1)));
        G_return_tender_rec.credit_card_holder_name(i)     := lc_cc_name;
        G_return_tender_rec.cc_mask_number(i)              := lc_cc_mask;
        G_return_tender_rec.od_payment_type(i)             := lc_pay_type;


        IF ln_debug_level > 0 THEN
            oe_debug_pub.ADD('Return tender orig_sys_document_ref = '||G_return_tender_rec.orig_sys_document_ref(i));
            oe_debug_pub.ADD('payment_type_code = '||G_return_tender_rec.payment_type_code(i));
            oe_debug_pub.ADD('order_source_id = '||G_return_tender_rec.order_source_id(i));
            oe_debug_pub.ADD('orig_sys_payment_ref = '||G_return_tender_rec.orig_sys_payment_ref(i));
            oe_debug_pub.ADD('payment_amount = '||G_return_tender_rec.credit_amount(i));
            oe_debug_pub.ADD('lc_cc_number = '||G_return_tender_rec.credit_card_number(i));
            oe_debug_pub.ADD('credit_card_expiration_date = '||G_return_tender_rec.credit_card_expiration_date(i));
            oe_debug_pub.ADD('credit_card_holder_name = '||G_return_tender_rec.credit_card_holder_name(i));
            oe_debug_pub.ADD('cc_auth_manual = '||G_return_tender_rec.cc_auth_manual(i));
            oe_debug_pub.ADD('merchant_nbr = '||G_return_tender_rec.merchant_nbr(i));
            oe_debug_pub.ADD('cc_auth_ps2000 = '||G_return_tender_rec.cc_auth_ps2000(i));
            oe_debug_pub.ADD('allied_ind = '||G_return_tender_rec.allied_ind(i));
        END IF;

    END IF;

    <<SKIP_PAYMENT>>

    x_return_status := 'S';

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Error Flag is '||g_header_rec.error_flag(ln_hdr_ind));
        oe_debug_pub.add('Exiting Process Payment ');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to process Payment :'||lc_pay_seq||' for order '||g_header_rec.orig_sys_document_ref(ln_hdr_ind));
        FND_FILE.PUT_LINE(FND_FILE.LOG,'The error is '||SQLERRM);
        -- Need to clear this BAD order
        CLEAR_BAD_ORDERS('PAYMENT',G_header_rec.orig_sys_document_ref(ln_hdr_ind));
        x_return_status := 'U';
END process_payment;

-- +===================================================================+
-- | Name  : Init_Line_Record                                          |
-- | Description      : This Procedure will read set line record for   |
-- |                    non SKU item lines such as TAX refund or       |
-- |                    delivery charges                               |
-- |                                                                   |
-- | Parameters:        p_line_idx  IN Line Index                      |
-- |                    p_hdr_idx   IN Header Index                    |
-- |                    p_rec_type  IN indicates the type of non-sku   |
-- |                    p_line_category IN indicates RETURN or ORDER   |
-- +===================================================================+
PROCEDURE Init_Line_Record(p_line_idx IN BINARY_INTEGER
                         , p_hdr_idx  IN BINARY_INTEGER
                         , p_rec_type IN VARCHAR2
                         , p_line_category IN VARCHAR2)
IS
ln_debug_level   CONSTANT NUMBER := oe_debug_pub.g_debug_level;
BEGIN
    G_Line_Rec.orig_sys_document_ref(p_line_idx) := G_Header_Rec.orig_sys_document_ref(p_hdr_idx);
    G_line_rec.payment_term_id(p_line_idx)   := g_header_rec.payment_term_id(p_hdr_idx);
    G_Line_Rec.order_source_id(p_line_idx) := G_Header_Rec.order_source_id(p_hdr_idx);
    G_Line_Rec.ordered_date(p_line_idx) := G_Header_Rec.Ordered_Date(p_hdr_idx);
    G_Line_Rec.change_sequence(p_line_idx) := G_Header_Rec.change_sequence(p_hdr_idx);
    G_Line_Rec.tax_exempt_flag(p_line_idx) := g_header_rec.Tax_Exempt_Flag(p_hdr_idx);
    G_Line_Rec.tax_exempt_number(p_line_idx) := g_header_rec.Tax_Exempt_number(p_hdr_idx);
    G_Line_Rec.tax_exempt_reason(p_line_idx) := g_header_rec.Tax_Exempt_reason(p_hdr_idx);
    G_Line_Rec.request_id(p_line_idx) := NULL;
    G_line_rec.ret_ref_header_id(p_line_idx) := NULL;
    G_line_rec.ret_ref_line_id(p_line_idx) := NULL;
    G_Line_Rec.line_number(p_line_idx) := G_Line_Nbr_Counter;
    G_Line_Rec.schedule_ship_date(p_line_idx) := NULL;
    G_Line_Rec.actual_ship_date(p_line_idx) := NULL;
    G_Line_Rec.schedule_arrival_date(p_line_idx) := NULL;
    G_Line_Rec.actual_arrival_date(p_line_idx) := NULL;
    G_Line_Rec.ordered_quantity(p_line_idx) := 1;
    G_Line_Rec.order_quantity_uom(p_line_idx) := 'EA';
    G_Line_Rec.shipped_quantity(p_line_idx) := NULL;
    G_Line_Rec.sold_to_org_id(p_line_idx) := G_Header_Rec.Sold_To_org_Id(p_hdr_idx);
    G_Line_Rec.ship_to_org_id(p_line_idx) := G_Header_Rec.Ship_To_org_Id(p_hdr_idx);
    G_Line_Rec.ship_from_org_id(p_line_idx) := G_Header_Rec.Ship_from_org_Id(p_hdr_idx);
    G_Line_Rec.invoice_to_org_id(p_line_idx) := G_Header_Rec.invoice_to_org_id(p_hdr_idx);
    G_Line_Rec.sold_to_contact_id(p_line_idx) := G_Header_Rec.sold_to_contact_id(p_hdr_idx);
    G_Line_Rec.drop_ship_flag(p_line_idx) := NULL;
    G_Line_Rec.price_list_id(p_line_idx) := G_Header_Rec.Price_List_Id(p_hdr_idx);
    G_Line_Rec.tax_date(p_line_idx) := G_Header_Rec.ordered_date(p_hdr_idx);
    G_Line_Rec.tax_value(p_line_idx) := NULL;
    G_Line_Rec.shipping_method_code(p_line_idx) := NULL;
    G_Line_Rec.salesrep_id(p_line_idx) := G_Header_Rec.salesrep_id(p_hdr_idx);
    G_Line_Rec.customer_po_number(p_line_idx) := G_Header_Rec.customer_po_number(p_hdr_idx);
    G_Line_Rec.operation_code(p_line_idx) := 'CREATE';
    G_Line_Rec.shipping_instructions(p_line_idx) := NULL;
    G_Line_Rec.return_context(p_line_idx) := NULL;
    G_Line_Rec.return_attribute1(p_line_idx) := NULL;
    G_Line_Rec.return_attribute2(p_line_idx) := NULL;
    G_Line_Rec.customer_item_name(p_line_idx) := NULL;
    G_Line_Rec.customer_item_id(p_line_idx) := NULL;
    G_Line_Rec.customer_item_id_type(p_line_idx) := NULL;
    G_Line_Rec.tot_tax_value(p_line_idx) := NULL;
    G_Line_Rec.customer_line_number(p_line_idx) := NULL;
    G_line_rec.org_order_creation_date(p_line_idx) := NULL;
    G_Line_Rec.Return_act_cat_code(p_line_idx)   := NULL;
    G_Line_Rec.legacy_list_price(p_line_idx) := NULL;
    G_Line_Rec.vendor_product_code(p_line_idx) := NULL;
    G_Line_Rec.contract_details(p_line_idx) := NULL;
    G_Line_Rec.item_comments (p_line_idx) := NULL;
    G_Line_Rec.line_comments(p_line_idx) := NULL;
    G_Line_Rec.taxable_flag(p_line_idx) := NULL;
    G_Line_Rec.sku_dept(p_line_idx) := NULL;
    G_Line_Rec.item_source(p_line_idx) := NULL;
    G_Line_Rec.average_cost(p_line_idx) := NULL;
    G_Line_Rec.po_cost(p_line_idx) := NULL;
    G_Line_Rec.canada_pst(p_line_idx) := NULL;
    G_Line_Rec.return_reference_no(p_line_idx) := NULL;
    G_Line_Rec.back_ordered_qty(p_line_idx) := NULL;
    G_Line_Rec.return_ref_line_no(p_line_idx) := NULL;
    G_Line_Rec.wholesaler_item(p_line_idx) := NULL;
    G_line_Rec.user_item_description(p_line_idx) := NULL;
    G_line_rec.ext_top_model_line_id(p_line_idx) := NULL;
    G_line_rec.ext_link_to_line_id(p_line_idx) := NULL;
    G_line_rec.config_code(p_line_idx) := NULL;
    G_line_rec.calc_arrival_date(p_line_idx) := NULL;
    G_line_rec.aops_ship_date(p_line_idx) := NULL;
    G_line_rec.sas_sale_date(p_line_idx) := g_header_rec.sas_sale_date(p_hdr_idx);
    G_line_rec.cust_dept_no(p_line_idx) := g_header_rec.cust_dept_no(p_hdr_idx);
    G_line_rec.cust_dept_description(p_line_idx) := g_header_rec.cust_dept_description(p_hdr_idx);
    G_line_rec.desk_top_no(p_line_idx) := g_header_rec.desk_top_no(p_hdr_idx);
    G_line_rec.release_number(p_line_idx) := g_header_rec.release_number(p_hdr_idx);
    G_Line_Rec.gsa_flag(p_line_idx) := NULL;
    G_line_rec.waca_item_ctr_num(p_line_idx) := NULL;
    G_line_rec.consignment_bank_code(p_line_idx) := NULL;
    G_line_rec.price_cd(p_line_idx)              := NULL;
    G_line_rec.price_change_reason_cd(p_line_idx):= NULL;
    G_line_rec.price_prefix_cd(p_line_idx)       := NULL;
    G_line_rec.commisionable_ind(p_line_idx)     := NULL;
    G_line_rec.inventory_item_id(p_line_idx)     := NULL;
    G_line_rec.inventory_item(p_line_idx)        := NULL;
    G_line_rec.unit_orig_selling_price(p_line_idx) := NULL;

    IF G_Header_Rec.Order_Category(p_hdr_idx) = 'ORDER' THEN
        G_Line_Rec.request_id (p_line_idx) := G_Request_Id;
        G_Batch_Counter := G_Batch_Counter + 1;
        G_Order_Line_Tax_ctr := G_Order_Line_Tax_ctr + 1;
    ELSE
        IF p_line_category = 'RETURN' THEN
            G_RMA_Line_Tax_ctr := G_RMA_Line_Tax_ctr + 1;
        ELSE
            G_Order_Line_Tax_ctr := G_Order_Line_Tax_ctr + 1;
        END IF;
        G_Line_Rec.request_id (p_line_idx) := NULL;
    END IF;

    IF G_Line_Id.EXISTS(g_Line_Id_Seq_Ctr) THEN
        G_Line_Rec.Line_ID(p_line_idx) := G_Line_Id(g_Line_Id_Seq_Ctr);
        SELECT p_rec_type||'-'||xx_om_nonsku_line_s.NEXTVAL
        INTO   G_line_rec.orig_sys_line_ref(p_line_idx)
        FROM DUAL;
        g_Line_Id_Seq_Ctr := g_Line_Id_Seq_Ctr + 1;
    ELSE 
        SELECT oe_order_lines_s.nextval
             , p_rec_type||'-'||xx_om_nonsku_line_s.NEXTVAL
        INTO   G_Line_Rec.Line_ID(p_line_idx)
             , G_line_rec.orig_sys_line_ref(p_line_idx)
        FROM DUAL;
    END IF;

    -- For first line of an order
    IF G_Line_Nbr_Counter = 1 THEN
        G_Header_Rec.start_line_index(p_hdr_idx) := p_line_idx;
    END IF;

    -- Set Tax value on first return line of order if tax value < 0
    -- Set Tax value on first outbound line of order is tax value >= 0

    IF G_Order_Line_Tax_ctr = 1 AND G_Header_Rec.Tax_Value(p_hdr_idx) >=0 THEN
        G_Line_Rec.Tax_Value(p_line_idx) := G_Header_Rec.Tax_Value(p_hdr_idx);
        G_Line_Rec.canada_pst(p_line_idx) := G_Header_Rec.pst_tax_value(p_hdr_idx);
        -- Increment the counter so that it does not assign it again
        G_Order_Line_Tax_ctr := G_Order_Line_Tax_ctr + 1;
    ELSIF G_RMA_Line_Tax_ctr = 1 AND G_Header_Rec.Tax_Value(p_hdr_idx) < 0 THEN
        G_Line_Rec.Tax_Value(p_line_idx) := -1 * G_Header_Rec.Tax_Value(p_hdr_idx);
        G_Line_Rec.canada_pst(p_line_idx) := -1 * G_Header_Rec.pst_tax_value(p_hdr_idx);
        -- Increment the counter so that it does not assign it again
        G_RMA_Line_Tax_ctr := G_RMA_Line_Tax_ctr + 1;
    ELSE
        G_Line_Rec.Tax_Value(p_line_idx) := 0;
        G_Line_Rec.canada_pst(p_line_idx) := 0;
    END IF;

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Start Line Index is :'||G_Header_Rec.start_line_index(p_hdr_idx));
    END IF;

    -- Get and Validate Item and Warehouse/Store
    Validate_Item_Warehouse( p_hdr_idx     => p_hdr_idx
                           , p_line_idx    => p_line_idx
                           , p_nonsku_flag => 'Y'
                           , p_item        => p_rec_type);

EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in Init line record for '||g_line_rec.orig_sys_line_ref(p_line_idx) || ' for order '||g_header_rec.orig_sys_document_ref(p_hdr_idx));
        FND_FILE.PUT_LINE(FND_FILE.LOG,'The error is '||sqlerrm);
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END Init_Line_Record;

PROCEDURE Create_Tax_Refund_Line(p_hdr_idx   IN BINARY_INTEGER
                               , p_order_rec IN order_rec_type)
IS
lb_line_idx      BINARY_INTEGER;
ln_debug_level   CONSTANT NUMBER := oe_debug_pub.g_debug_level;
BEGIN
    IF ln_debug_level > 0 THEN
       oe_debug_pub.ADD('Entering Create_Tax_Refund_Line' ||p_hdr_idx, 1);
    END IF;

    -- Line number counter per order
    G_Line_Nbr_Counter := G_Line_Nbr_Counter + 1;
    -- Get the next Line Index
    lb_line_idx := G_Line_Rec.orig_sys_document_ref.COUNT + 1;

    -- Replacing 'ST' with 'TRF' for tax refund item has ST is been used for wholesaler discount NB 
    Init_Line_Record(p_line_idx => lb_line_idx
                   , p_hdr_idx  => p_hdr_idx
                   , p_rec_type => 'TRF'
                   , p_line_category => 'RETURN');

    G_Line_Rec.line_type_id(lb_line_idx) := OE_Sys_Parameters.value('D-RL',G_Org_Id);
    G_Line_Rec.return_reason_code(lb_line_idx) := g_header_rec.return_reason(p_hdr_idx);
    G_Line_Rec.line_category_code(lb_line_idx) := 'RETURN';
    G_Line_Rec.Return_act_cat_code(lb_line_idx):= g_header_rec.Return_act_cat_code(p_hdr_idx);
    G_Line_Rec.org_order_creation_date(lb_line_idx):= g_header_rec.org_order_creation_date(p_hdr_idx);
    G_Line_Rec.return_reference_no(lb_line_idx):= g_header_rec.return_orig_sys_doc_ref(p_hdr_idx);
    G_Line_Rec.schedule_status_code(lb_line_idx) := NULL;
    -- Need to set the price to zero. The tax value will be populated with the correct value.

    -- Need to set the price to zero. The tax value will be populated with the correct value.
    G_Line_Rec.unit_list_price(lb_line_idx) := 0; -- substr(p_order_rec.file_line,269,10);
    G_Line_Rec.unit_selling_price(lb_line_idx) := 0; -- G_Line_Rec.unit_list_price(lb_line_idx);
    -- Populate the reference info on the line.
    Get_return_header ( p_ref_order_number => g_header_rec.return_orig_sys_doc_ref(p_hdr_idx)
                      , p_sold_to_org_id   => g_header_rec.sold_to_org_id(p_hdr_idx)
                      , x_header_id        => g_line_rec.ret_ref_header_id(lb_line_idx)
                      );
    IF ln_debug_level > 0 THEN
       oe_debug_pub.ADD('After getting the header reference :' ||g_line_rec.ret_ref_header_id(lb_line_idx), 1);
    END IF;


    -- Increment the global Line counter used in determining batch size
    G_Line_counter := G_Line_counter + 1;

    IF ln_debug_level > 0 THEN
       oe_debug_pub.ADD('Exiting Create_Tax_Refund_Line' ||p_hdr_idx, 1);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to process Tax Refund Line record for order '||g_header_rec.orig_sys_document_ref(p_hdr_idx));
        FND_FILE.PUT_LINE(FND_FILE.LOG,'The error is '||SQLERRM);
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END Create_Tax_Refund_Line;

-- +===================================================================+
-- | Name  : Create_CashBack_Line                                      |
-- | Description      : This Procedure will create cash-back line      |
-- |                                                                   |
-- | Parameters:        p_Hdr_Idx IN Header Index                      |
-- |                    p_amount  IN Line Amount                       |
-- +===================================================================+

PROCEDURE Create_CashBack_Line(p_Hdr_Idx IN BINARY_INTEGER
                             , p_amount IN NUMBER)
IS
    lb_line_idx    BINARY_INTEGER;
    ln_debug_level   CONSTANT NUMBER := oe_debug_pub.g_debug_level;
BEGIN
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Before processing CashBack Line' || p_amount);
    END IF;

    G_Line_Nbr_Counter := G_Line_Nbr_Counter + 1;

    -- Get the current Line Index
    lb_line_idx := G_Line_Rec.orig_sys_document_ref.COUNT + 1;

    G_Line_Rec.line_category_code(lb_line_idx) := 'ORDER';

    -- Initialize and set the line record
    Init_Line_Record(p_line_idx => lb_line_idx
                   , p_hdr_idx  => p_hdr_idx
                   , p_rec_type => 'CASHBK'
                   , p_line_category => 'ORDER');

    -- Need to charge customer for the fee/ del charge
    G_Line_Rec.line_type_id(lb_line_idx) := OE_Sys_Parameters.value('D-SL',G_Org_Id);
    G_Line_Rec.line_category_code(lb_line_idx) := 'ORDER';
    G_Line_Rec.return_reason_code(lb_line_idx) := NULL;
    G_Line_Rec.org_order_creation_date(lb_line_idx):= NULL;
    G_Line_Rec.schedule_status_code(lb_line_idx) := NULL;

    G_Line_Rec.unit_list_price(lb_line_idx) := p_amount;
    G_Line_Rec.unit_selling_price(lb_line_idx) := p_amount;
    G_Line_Rec.taxable_flag(lb_line_idx) := 'N';

    -- Add the cash back amount to Order Total
    G_Header_Rec.order_total(p_Hdr_Idx):= G_Header_Rec.order_total(p_Hdr_Idx) + p_amount;
    G_CashBack_Total := G_CashBack_Total + p_amount;

    -- Increment the global Line counter used in determining batch size
    G_Line_counter := G_Line_counter + 1;

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('After processing CashBack Line');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to process Cash Back line '||g_line_rec.orig_sys_line_ref(lb_line_idx) || ' for order '||g_header_rec.orig_sys_document_ref(p_Hdr_Idx));
        FND_FILE.PUT_LINE(FND_FILE.LOG,'The error is '||substr(SQLERRM,1,200));
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Create_CashBack_Line;

-- +===================================================================+
-- | Name  : process_Adjustments                                       |
-- | Description      : This Procedure will read the Adjustment line   |
-- |                     from file validate , derive and insert into   |
-- |                    oe_price_adjs_iface_all tbl                    |
-- |                                                                   |
-- | Parameters:        p_order_rec IN order_rec_type                  |
-- |                    p_batch_id  IN batch_id                        |
-- +===================================================================+

PROCEDURE Process_Adjustments(
      p_order_rec IN order_rec_type
    , p_batch_id  IN NUMBER
    , x_return_status OUT NOCOPY VARCHAR2)
IS
  lc_rec_type      VARCHAR2(2);
  --lb_line_nbr      BINARY_INTEGER;
  lc_line_nbr      VARCHAR2(5);
  lb_adj_idx       BINARY_INTEGER;
  lb_hdr_idx       BINARY_INTEGER;
  lb_line_idx      BINARY_INTEGER;
  lb_curr_line_idx BINARY_INTEGER;
  lc_list_name     VARCHAR2(100);
  lc_adj_sign      VARCHAR2(1);
  ln_debug_level   CONSTANT NUMBER := oe_debug_pub.g_debug_level;

BEGIN
    x_return_status := 'S';
    -- Check if it is a discount/coupon record
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Entering Process Adjustments');
    END IF;
    lc_rec_type := substr(p_order_rec.file_line,108,2);
    lc_line_nbr := substr(p_order_rec.file_line,33,5);
    lb_adj_idx := G_Line_Adj_Rec.orig_sys_document_ref.COUNT + 1;
    lb_hdr_idx := G_Header_Rec.orig_sys_document_ref.COUNT;
    lb_curr_line_idx := G_Line_Rec.orig_sys_document_ref.COUNT;

    -- Check if the discount applies to whole order
    IF lc_line_nbr = '00000' THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Found discount record with missing line reference for order:'|| G_Header_Rec.orig_sys_document_ref(lb_hdr_idx));
        -- Check if the display distribution is NULL
        IF to_number(substr(p_order_rec.file_line,98,10)) = 0 THEN
            -- Ignore this discount record and proceed with order creation
            GOTO END_OF_ADJ; 
        END IF;
        -- Need to put it on First Line of the order
        lb_line_idx := G_Header_Rec.Start_Line_Index(lb_hdr_idx);
        -- We will need to mark the order for error 
        Set_Header_Error(lb_hdr_idx);
        set_msg_context(p_entity_code => 'HEADER');
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_DIS_MISSING_LINE_REF');
        FND_MESSAGE.SET_TOKEN('ATTRIBUTE1',G_Line_Adj_Rec.orig_sys_discount_ref(lb_adj_idx));
        oe_bulk_msg_pub.add;
    END IF;
    -- Get the Adjustment reference number
    G_Line_Adj_Rec.orig_sys_discount_ref(lb_adj_idx) := LTRIM(RTRIM(substr(p_order_rec.file_line,56,30)));

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Rec Type is :'||lc_rec_type);
        oe_debug_pub.add('Line Nbr is  :'||lc_line_nbr);
        oe_debug_pub.add('Adjustment Index is  :'||lb_adj_idx);
        oe_debug_pub.add('Line Curr Line Index is :'||lb_curr_line_idx);
    END IF;

    IF lc_rec_type IN ('AD','TD', '00','10','20','21','22','30','50') THEN
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('Processing Discount ');
        END IF;
        -- Get the List Header Id and List Line Id for discount/coupon records.
        IF G_LIST_HEADER_ID is NULL THEN
            -- Get the list header id from system parameter
            G_LIST_HEADER_ID := oe_sys_parameters.value('XX_OM_SAS_DISCOUNT_LIST',G_Org_Id);

            -- This dummy discount list will only hold one record..
            SELECT list_line_id
            INTO G_List_Line_Id
            FROM qp_list_lines
            WHERE list_header_id = G_LIST_HEADER_ID
            AND ROWNUM = 1;

        END IF;

        -- Find the line index for the adjustment record.
        IF lc_line_nbr <> '00000' THEN
            -- Loop over line table to figure out which line this discount belongs to
            FOR j IN G_Header_Rec.Start_Line_Index(lb_hdr_idx)..lb_curr_line_idx LOOP
                IF lc_line_nbr = G_Line_Rec.orig_sys_line_ref(j) THEN
                    IF ln_debug_level > 0 THEN
                        oe_debug_pub.add('Match Found for ADJ line ref '||lc_line_nbr);
                    END IF;
                    lb_line_idx := j;
                    EXIT;
                END IF;
            END LOOP;
            IF lb_line_idx IS NULL THEN
                -- Give error that adj record doesn't point to correct line
                oe_debug_pub.ADD('ADJ record does not point to correct line :'||lc_line_nbr);
            END IF;
        END IF;

        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('Line index for adj record is : '||lb_line_idx);
        END IF;

        G_Line_Adj_Rec.orig_sys_document_ref(lb_adj_idx):= G_Header_Rec.orig_sys_document_ref(lb_hdr_idx);
        G_Line_Adj_Rec.order_source_id(lb_adj_idx) := G_Header_Rec.order_source_id(lb_hdr_idx);
        G_Line_Adj_Rec.orig_sys_line_ref(lb_adj_idx) := substr(p_order_rec.file_line,33,5);
        G_Line_Adj_Rec.sold_to_org_id(lb_adj_idx) := G_Header_Rec.Sold_To_Org_ID(lb_hdr_idx);
        G_Line_Adj_Rec.list_header_id(lb_adj_idx) := G_List_Header_Id;
        G_Line_Adj_Rec.list_line_id(lb_adj_idx) := G_List_Line_Id;
        G_Line_Adj_Rec.list_line_type_code(lb_adj_idx) := 'DIS';
        G_Line_Adj_Rec.operand(lb_adj_idx) := substr(p_order_rec.file_line,98,10);
        G_Line_Adj_Rec.pricing_phase_id(lb_adj_idx) := 2;
        G_Line_Adj_Rec.adjusted_amount(lb_adj_idx) := -1 * G_Line_Adj_Rec.operand(lb_adj_idx)/
                              NVL(G_Line_Rec.shipped_quantity(lb_line_idx),G_Line_Rec.ordered_quantity(lb_line_idx));
        G_Line_Adj_Rec.operation_code(lb_adj_idx) := 'CREATE';
        G_Line_Adj_Rec.context(lb_adj_idx) := 'SALES_ACCT';
        G_Line_Adj_Rec.attribute6(lb_adj_idx) := LTRIM(substr(p_order_rec.file_line,38,9));
        G_Line_Adj_Rec.attribute7(lb_adj_idx) := LTRIM(substr(p_order_rec.file_line,54,1));
        G_Line_Adj_Rec.attribute8(lb_adj_idx) := lc_rec_type; --G_Line_Adj_Rec.orig_sys_discount_ref(lb_adj_idx);

        -- For COUPON type discounts, populate the owner information .
        IF lc_rec_type = '10' THEN
            -- Changed to populate the text instead of the owner id as requested by AR
            IF LTRIM(substr(p_order_rec.file_line,55,1)) IN ('1','3','4','6') THEN
                G_Line_Adj_Rec.attribute9(lb_adj_idx) := 'ADVERTISING';
            ELSE
                G_Line_Adj_Rec.attribute9(lb_adj_idx) := 'MERCHANDISING';
            END IF;
        ELSE
            G_Line_Adj_Rec.attribute9(lb_adj_idx) := NULL;
        END IF;

        G_Line_Adj_Rec.attribute10(lb_adj_idx) := TO_NUMBER(substr(p_order_rec.file_line,87,10));
        G_Line_Adj_Rec.change_sequence(lb_adj_idx) := G_Header_Rec.change_sequence(lb_hdr_idx);
        IF G_Header_Rec.Order_Category(lb_hdr_idx) = 'ORDER' THEN
           G_Line_Adj_Rec.request_id(lb_adj_idx) := G_Request_Id;
        ELSE
           G_Line_Adj_Rec.request_id(lb_adj_idx) := NULL;
        END IF;

        -- Set the Unit Selling Price on the Line Record
        G_Line_Rec.Unit_Selling_Price(lb_line_idx) := G_Line_Rec.Unit_Selling_Price(lb_line_idx) + G_Line_Adj_Rec.adjusted_amount(lb_adj_idx);

        -- Adjust the Order Total based on adjustment to unit selling price
        IF G_Line_Rec.line_category_code(lb_line_idx) = 'RETURN' THEN
            G_Header_Rec.Order_Total(lb_hdr_idx) := G_Header_Rec.Order_Total(lb_hdr_idx) + 
                                                    (G_Line_Adj_Rec.adjusted_amount(lb_adj_idx) * 
                                                     NVL(G_Line_Rec.Shipped_Quantity(lb_line_idx),G_Line_Rec.ordered_quantity(lb_line_idx)) * -1);
        ELSE
            G_Header_Rec.Order_Total(lb_hdr_idx) := G_Header_Rec.Order_Total(lb_hdr_idx) + 
                                                    G_Line_Adj_Rec.adjusted_amount(lb_adj_idx) * 
                                                    NVL(G_Line_Rec.shipped_quantity(lb_line_idx),G_Line_Rec.ordered_quantity(lb_line_idx));
        END IF;

        IF ln_debug_level > 0 THEN
            oe_debug_pub.ADD('lc_rec_type = '||lc_rec_type);
            oe_debug_pub.ADD('lc_line_nbr = '||lc_line_nbr);
            oe_debug_pub.ADD('orig_sys_document_ref = '||G_Line_Adj_Rec.orig_sys_document_ref(lb_adj_idx));
            oe_debug_pub.ADD('order_source_id = '||G_Line_Adj_Rec.order_source_id(lb_adj_idx));
            oe_debug_pub.ADD('orig_sys_line_ref = '||G_Line_Adj_Rec.orig_sys_line_ref(lb_adj_idx));
            oe_debug_pub.ADD('orig_sys_discount_ref = '||G_Line_Adj_Rec.orig_sys_discount_ref(lb_adj_idx));
            oe_debug_pub.ADD('sold_to_org_id = '||G_Line_Adj_Rec.sold_to_org_id(lb_adj_idx));
            oe_debug_pub.ADD('list_header_id = '||G_Line_Adj_Rec.list_header_id(lb_adj_idx));
            oe_debug_pub.ADD('list_line_id = '||G_Line_Adj_Rec.list_line_id(lb_adj_idx));
            oe_debug_pub.ADD('list_line_type_code = '||G_Line_Adj_Rec.list_line_type_code(lb_adj_idx));
            oe_debug_pub.ADD('operand = '||G_Line_Adj_Rec.operand(lb_adj_idx));
            oe_debug_pub.ADD('pricing_phase_id = '||G_Line_Adj_Rec.pricing_phase_id(lb_adj_idx));
            oe_debug_pub.ADD('adjusted_amount = '||G_Line_Adj_Rec.adjusted_amount(lb_adj_idx));
            oe_debug_pub.ADD('operation_code = '||G_Line_Adj_Rec.operation_code(lb_adj_idx));
            oe_debug_pub.ADD('context = '||G_Line_Adj_Rec.context(lb_adj_idx));
            oe_debug_pub.ADD('attribute6 = '||G_Line_Adj_Rec.attribute6(lb_adj_idx));
            oe_debug_pub.ADD('attribute7 = '||G_Line_Adj_Rec.attribute7(lb_adj_idx));
            oe_debug_pub.ADD('attribute8 = '||G_Line_Adj_Rec.attribute8(lb_adj_idx));
            oe_debug_pub.ADD('attribute9 = '||G_Line_Adj_Rec.attribute9(lb_adj_idx));
            oe_debug_pub.ADD('attribute10 = '||G_Line_Adj_Rec.attribute10(lb_adj_idx));
            oe_debug_pub.add('Error Flag is '||g_header_rec.error_flag(lb_hdr_idx));
            oe_debug_pub.add(' ADJ The order total is ' || G_Header_Rec.order_total(lb_hdr_idx));
            oe_debug_pub.add(' Line Ship Qty is ' || G_Line_Rec.Shipped_Quantity(lb_line_idx));
            oe_debug_pub.add(' adjusted amount is ' ||G_Line_Adj_Rec.adjusted_amount(lb_adj_idx));
            oe_debug_pub.add(' operand amount is ' ||G_Line_Adj_Rec.operand(lb_adj_idx));
        END IF;

    ELSE

        G_Line_Nbr_Counter := G_Line_Nbr_Counter + 1;
        -- Get the current Line Index
        lb_line_idx := G_Line_Rec.orig_sys_document_ref.COUNT + 1;

        -- For Delivery Charges, Fees etc we will need to create line record.
        lc_adj_sign := substr(p_order_rec.file_line,97,1);

        IF lc_adj_sign = '-' THEN
            G_Line_Rec.line_category_code(lb_line_idx) := 'RETURN';
        ELSE
            G_Line_Rec.line_category_code(lb_line_idx) := 'ORDER';
        END IF;

        -- Initialize and set the line record
        Init_Line_Record(p_line_idx => lb_line_idx
                       , p_hdr_idx  => lb_hdr_idx
                       , p_rec_type => lc_rec_type
                       , p_line_category => G_Line_Rec.line_category_code(lb_line_idx));

        G_Line_Rec.Return_act_cat_code(lb_line_idx):= g_header_rec.Return_act_cat_code(lb_hdr_idx);

        G_Line_Rec.unit_list_price(lb_line_idx) := substr(p_order_rec.file_line,98,10);
        G_Line_Rec.unit_selling_price(lb_line_idx) := G_Line_Rec.unit_list_price(lb_line_idx);

        -- If the non-sku is 'SP or 'UN' Then put the correct orig_sys_line_ref on the line record

        --IF lc_rec_type IN ('SP','UN','SD') THEN
        --G_Line_Rec.orig_sys_line_ref(lb_line_idx) := substr(p_order_rec.file_line,33,5);
        G_Line_Rec.sas_sale_date(lb_line_idx) := g_header_rec.sas_sale_date(lb_hdr_idx);
        G_Line_Rec.aops_ship_date(lb_line_idx) := g_header_rec.ship_date(lb_hdr_idx);
        G_Line_Rec.calc_arrival_date(lb_line_idx) := g_header_rec.ship_date(lb_hdr_idx);
        --END IF;

        -- Read the COST amounts from file for NON-SKU items
        G_line_rec.average_cost(lb_line_idx) := NVL(TRIM(substr(p_order_rec.file_line,111,11)),0);
        G_line_rec.po_cost(lb_line_idx) := G_line_rec.average_cost(lb_line_idx);
        -- MFC 11-mar-2009 QC13608 use the passed taxable ind for the adjustment
        G_line_rec.taxable_flag(lb_line_idx) := NVL(substr(p_order_rec.file_line,110,1),'Y');


        IF lc_adj_sign = '-' THEN
            G_Line_Rec.line_type_id(lb_line_idx) := OE_Sys_Parameters.value('D-RL',G_Org_Id);
            G_Line_Rec.return_reason_code(lb_line_idx) := NVL(g_header_rec.return_reason(lb_hdr_idx),'00');
            G_Line_Rec.line_category_code(lb_line_idx) := 'RETURN';
            G_Line_Rec.org_order_creation_date(lb_line_idx):= g_header_rec.org_order_creation_date(lb_hdr_idx);
            G_Line_Rec.return_reference_no(lb_line_idx):= g_header_rec.return_orig_sys_doc_ref(lb_hdr_idx);
            G_Line_Rec.schedule_status_code(lb_line_idx) := NULL;
            G_Header_Rec.order_total(lb_hdr_idx):= G_Header_Rec.order_total(lb_hdr_idx) + G_line_rec.unit_selling_price(lb_line_idx) * -1;
        ELSE
            -- Need to charge customer for the fee/ del charge
            G_Line_Rec.line_type_id(lb_line_idx) := OE_Sys_Parameters.value('D-SL',G_Org_Id);
            G_Line_Rec.line_category_code(lb_line_idx) := 'ORDER';
            G_Line_Rec.return_reason_code(lb_line_idx) := NULL;
            G_Line_Rec.org_order_creation_date(lb_line_idx):= NULL;
            G_Line_Rec.return_reference_no(lb_line_idx):= NULL;
            G_Line_Rec.schedule_status_code(lb_line_idx) := NULL;
            G_Header_Rec.order_total(lb_hdr_idx):= G_Header_Rec.order_total(lb_hdr_idx) + G_line_rec.unit_selling_price(lb_line_idx); 
        END IF;
        -- oe_debug_pub.add('ADJ - LINE The order total is ' || G_Header_Rec.order_total(lb_hdr_idx));

        -- Increment the global Line counter used in determining batch size
        G_Line_counter := G_Line_counter + 1;
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('Orig Sys Line Ref is '||G_Line_Rec.orig_sys_line_ref(lb_line_idx));
            oe_debug_pub.add('Error Flag is '||g_header_rec.error_flag(lb_hdr_idx));
        END IF;

    END IF;
    <<END_OF_ADJ>>
    x_return_status := 'S';

EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in processing adjustment record for order '||g_header_rec.orig_sys_document_ref(lb_hdr_idx));
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Line Nmber for adjustment record is '||lc_line_nbr);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'The error is '||SQLERRM);
        -- Need to clear this BAD order
        CLEAR_BAD_ORDERS('ADJUSTMENT',G_header_rec.orig_sys_document_ref(lb_hdr_idx));
        x_return_status := 'U';
END Process_Adjustments;


PROCEDURE get_def_shipto( p_cust_account_id  IN NUMBER
                        , x_ship_to_org_id  OUT NOCOPY NUMBER)
IS

-- +===================================================================+
-- | Name  : Get_Def_Shipto                                            |
-- | Description      : This Procedure is called to derive default     |
-- |                    Ship_to address for POS Orders                 |
-- |                                                                   |
-- | Parameters      : p_cust_account_id   IN -> pass customer_id      |
-- |                   x_ship_to_org_id   OUT -> get bill_to_org_id    |
-- +===================================================================+

BEGIN
    SELECT site_use.site_use_id
    INTO   x_ship_to_org_id
    FROM   hz_cust_site_uses_all site_use
        ,  hz_cust_acct_sites_all addr
    WHERE addr.cust_account_id = p_cust_account_id
    AND addr.cust_acct_site_id = site_use.cust_acct_site_id
    AND site_use.site_use_code = 'SHIP_TO'
    AND site_use.org_id = g_org_id
    AND site_use.primary_flag = 'Y'
    AND site_use.status = 'A';

EXCEPTION
    WHEN OTHERS THEN
        x_ship_to_org_id := NULL;
END;

PROCEDURE get_def_billto( p_cust_account_id  IN NUMBER
                        , x_bill_to_org_id  OUT NOCOPY NUMBER)
IS

-- +===================================================================+
-- | Name  : Get_Def_Billto                                            |
-- | Description      : This Procedure is called to derive default     |
-- |                    Bill_to address for POS Orders                 |
-- |                                                                   |
-- | Parameters      : p_cust_account_id   IN -> pass customer_id      |
-- |                   x_bill_to_org_id   OUT -> get bill_to_org_id    |
-- +===================================================================+

BEGIN
    SELECT site_use.site_use_id
    INTO   x_bill_to_org_id
    FROM   hz_cust_accounts_all acct
        ,  hz_cust_site_uses_all site_use
        ,  hz_cust_acct_sites_all addr
    WHERE acct.cust_account_id = p_cust_account_id
    AND acct.cust_account_id = addr.cust_account_id
    AND addr.cust_acct_site_id = site_use.cust_acct_site_id
    AND site_use.site_use_code = 'BILL_TO'
    AND site_use.org_id = g_org_id
    AND site_use.primary_flag = 'Y'
    AND site_use.status = 'A'
    AND addr.BILL_TO_FLAG = 'P' -- 16-Mar-2009
    AND addr.STATUS = 'A';      -- 16-Mar-2009

EXCEPTION
    WHEN OTHERS THEN
        x_bill_to_org_id := NULL;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS IN Get_Def_Billto ::'||substr(SQLERRM,1,200));
END get_def_billto;

-- +===================================================================+
-- | Name  : Derive_Ship_To                                            |
-- | Description      : This Procedure is called to derive Ship_to     |
-- |                    Address                                        |
-- |                                                                   |
-- | Parameters     : p_sold_to_org_id  IN -> pass customer_id         |
-- |                  P_orig_sys_document_ref IN -> pass orig order ref|
-- |                  p_order_source_id IN -> pass order_source_id     |
-- |                  p_orig_sys_ship_ref IN -> pass orig_ship_ref     |
-- |                  p_ordered_date      IN -> pass ordered date      |
-- |                  p_address_line1     IN -> pass address1          |
-- |                  p_address_line2     IN -> pass address2          |
-- |                  p_city              IN -> pass city              |
-- |                  p_state             In -> pass state             |
-- |                  p_country           IN -> pass country           |
-- |                  p_province          IN -> pass province          |
-- |                  p_order_source      IN -> pass order source      |
-- |                  x_ship_to_org_id   OUT -> get ship_to_org_id     |
-- +===================================================================+
PROCEDURE Derive_Ship_To(
    p_sold_to_org_id        IN NUMBER,
    p_orig_sys_document_ref IN VARCHAR2,
    p_order_source_id       IN NUMBER,
    p_orig_sys_ship_ref     IN VARCHAR2,
    p_ordered_date          IN DATE,
    p_address_line1         IN VARCHAR2,
    p_address_line2         IN VARCHAR2,
    p_city                  IN VARCHAR2,
    p_postal_code           IN VARCHAR2,
    p_state                 IN VARCHAR2,
    p_country               IN VARCHAR2,
    p_province              IN VARCHAR2,
    p_order_source          IN VARCHAR2,
    x_ship_to_org_id        IN OUT NOCOPY NUMBER,
    x_invoice_to_org_id     IN OUT NOCOPY NUMBER,
    x_ship_to_geocode       IN OUT NOCOPY VARCHAR2)
IS
  ln_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
  lc_match       VARCHAR2(10);



  ln_Ship_To_id         NUMBER;
  ln_Invoice_To_id      NUMBER;
  lc_postal_code        VARCHAR2(60);
  lc_geocode            VARCHAR2(30);
  ln_invoice_to_org_id  NUMBER;
  l_orig_sys_ref_tbl    T_VCHAR50;
  lb_create_new_shipTo  BOOLEAN := FALSE;
  lc_hvop_shipto_ref    VARCHAR2(50);
  lc_last_ref           VARCHAR2(50);
  lc_return_status      VARCHAR2(1);
  ln_hvop_ref_count     NUMBER;
  lc_country            VARCHAR2(30);
  lc_amz_cust_no        VARCHAR2(30);
  l_request             XX_TWE_GEOCODE_UTIL.GEOCODE_REQUEST_T;
  l_response            XX_TWE_GEOCODE_UTIL.GEOCODE_RESPONSE_T;
BEGIN
    IF ln_debug_level > 0 THEN
       oe_debug_pub.add('Inside Derive Ship To ');
       oe_debug_pub.add('Ship Ref ' || p_orig_sys_ship_ref);
       oe_debug_pub.add('Ordered date ' || p_ordered_date);
    END IF;

    x_ship_to_org_id := NULL;
    x_invoice_to_org_id := NULL;
    x_ship_to_geocode := NULL;

    -- First find out the no of records in hz_orig_sys_references for the
    -- specified p_orig_sys_ship_ref
    BEGIN
        SELECT owner_table_id,
              bill_to_site_use_id,
              loc.postal_code,
              loc.attribute14
         INTO ln_Ship_To_id,
              ln_Invoice_To_id,
              lc_postal_code,
              lc_geocode
         FROM hz_orig_sys_references osr,
              hz_cust_site_uses_all site_use,
              hz_locations loc,
              hz_party_sites site,
              hz_cust_acct_sites acct_site
        WHERE osr.orig_system = 'A0'
          AND osr.owner_table_name = 'HZ_CUST_SITE_USES_ALL'
          AND osr.orig_system_reference = p_orig_sys_ship_ref ||'-SHIP_TO'
          AND osr.status = 'A'
          AND osr.owner_table_id = site_use.site_use_id
          AND site_use.site_use_code = 'SHIP_TO'
          AND site_use.org_id = g_org_id
          AND site_use.cust_acct_site_id = acct_site.cust_acct_site_id
          AND acct_site.party_site_id = site.party_site_id
          AND site.location_id = loc.location_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            oe_debug_pub.add('No data found for the ShipTo reference from legacy');
            -- If it is the SPC or PRO card customer then we derive the default Ship-To
            IF p_order_source IN ('S','U') THEN
                Get_Def_Shipto( p_cust_account_id => p_sold_to_org_id
                              , x_ship_to_org_id => ln_Ship_To_id);
            END IF;
            -- IF can not derive the ship to then return 
            IF  ln_Ship_To_id IS NULL THEN
                RETURN;
            END IF;
    END;

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Ship To  reference found :'||ln_Ship_To_id);
    END IF;

    x_ship_to_org_id := ln_Ship_To_id;

    -- IF amazon order then
    IF p_order_source = 'A' THEN

        -- Get Amazon Customer Account Number
        lc_amz_cust_no := OE_Sys_Parameters.value('XX_OM_AMAZON_ACCOUNT_NUMBER',G_Org_Id);

        IF ln_debug_level > 0 THEN
               oe_debug_pub.add('This is Amazon Order :' ||lc_amz_cust_no);
        END IF;

        IF lc_amz_cust_no IS NOT NULL THEN
            -- Get the Primary BillTo for the AMAZON account.
            SELECT SITE_USE.SITE_USE_ID
            INTO x_invoice_to_org_id
            FROM HZ_CUST_ACCOUNTS ACCT ,
                 HZ_CUST_SITE_USES_ALL SITE_USE ,
                 HZ_CUST_ACCT_SITES_ALL ADDR
            WHERE ACCT.ACCOUNT_NUMBER = lc_amz_cust_no
            AND ACCT.CUST_ACCOUNT_ID = ADDR.CUST_ACCOUNT_ID
            AND ADDR.CUST_ACCT_SITE_ID = SITE_USE.CUST_ACCT_SITE_ID
            AND SITE_USE.SITE_USE_CODE = 'BILL_TO'
            AND SITE_USE.PRIMARY_FLAG = 'Y'
            AND SITE_USE.ORG_ID = G_ORG_ID
            AND SITE_USE.STATUS = 'A';
        END IF;
    ELSE
        IF ln_invoice_to_id IS NULL THEN
            -- Get the default Primary Bill To for the customer account
            Get_Def_Billto( p_sold_to_org_id
                          , ln_invoice_to_id);
            END IF;
            x_invoice_to_org_id := ln_invoice_to_id;
    END IF;

    -- If SPC or PRO card orders then they are true POS orders and no need to populate the geocode on them
    IF p_order_source in ('U','S') THEN
        x_ship_to_geocode := NULL;
        GOTO SHIP_TO_END;
    END IF;

    -- Check if the Ship_To postal code from AOPS order  matches with the one on the HZ_LOCATIONS
    IF NVL(p_postal_code,' ') = NVL(lc_postal_code ,' ') THEN
        -- Use the Geocode returned from HZ_LOCATIONS
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add(' Match found so using the geocode from HZ_LOCATIONS ');
        END IF;
        x_ship_to_geocode := lc_geocode;
    ELSE
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add(' No match found hence calling the TWE API ');
        END IF;
        -- The Ship_To address on AOPS order is different and will need to get the new Geocode
        -- by calling the API XX_TWE_GEOCODE_UTIL.GEOCODE_INVOKE 
        l_request.address.line_1 := p_address_line1; 
        l_request.address.line_2 := p_address_line2; 
        l_request.address.city := p_city; 
        l_request.address.state_province := p_state; 
        l_request.address.postalcode := p_postal_code; 
        l_request.address.country := p_country; 
       
        BEGIN
 
        --    l_response := XX_TWE_GEOCODE_UTIL.GEOCODE_INVOKE(l_request);
            l_response.geocode := NULL;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.add(' Geocode ' || l_response.geocode );
            --    oe_debug_pub.add(' Status  ' || l_response.status.result||' : '||l_response.status.code||' : '||l_response.status.description);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                l_response.geocode := NULL;
                oe_debug_pub.add('In Others Calling XX_TWE_GEOCODE_UTIL API');
        END;

        -- Check the return values
        IF NVL(l_response.geocode,'') = '' THEN
            x_ship_to_geocode := NULL;
        ELSE
            x_ship_to_geocode := l_response.geocode;
        END IF;

    END IF;

    <<SHIP_TO_END>>
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add(' Geocode ' || x_ship_to_geocode );
        oe_debug_pub.add(' Shipto  ' || x_ship_to_org_id );
        oe_debug_pub.add(' BillTo  ' || x_invoice_to_org_id );
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add('In Others for Derive ShipTo');
        oe_debug_pub.add('Error :' ||substr(SQLERRM,1,80));
        x_ship_to_org_id := NULL;
        x_invoice_to_org_id := NULL;
        x_ship_to_geocode := NULL;
END Derive_Ship_To;

FUNCTION order_source(p_order_source IN VARCHAR2 ) RETURN VARCHAR2 IS
-- +===================================================================+
-- | Name  : order_source                                              |
-- | Description     : To derive order_source_id by passing order      |
-- |                   source                                          |
-- |                                                                   |
-- | Parameters     : p_order_source  IN -> pass order source          |
-- |                                                                   |
-- | Return         : order_source_id                                  |
-- +===================================================================+

BEGIN
IF NOT g_order_source.exists  (p_order_source)  THEN
      SELECT attribute6
        INTO g_order_source(p_order_source)
        FROM apps.fnd_lookup_values
       WHERE lookup_type = 'OD_ORDER_SOURCE'
          AND lookup_code = UPPER(p_order_source);

END IF;
RETURN(g_order_source(p_order_source));
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END order_source;

FUNCTION sales_rep (p_sales_rep IN VARCHAR2) RETURN NUMBER IS
-- +===================================================================+
-- | Name  : sales_rep                                                 |
-- | Description     : To derive salesrep_id by passing salesrep       |
-- |                                                                   |
-- |                                                                   |
-- | Parameters     : p_sales_rep  IN -> pass salesrep                 |
-- |                                                                   |
-- | Return         : sales_rep_id                                     |
-- +===================================================================+

BEGIN
IF NOT g_sales_rep.exists(p_sales_rep) THEN
         SELECT jrs.salesrep_id
          INTO g_sales_rep(p_sales_rep)
          FROM jtf_rs_defresroles_vl jrdv,
               jtf_rs_salesreps jrs,
               xxtps_sp_mapping mp
         WHERE jrdv.role_resource_id = jrs.resource_id
           AND jrs.org_id = g_org_id
           AND mp.sp_id_orig = p_sales_rep
           AND jrdv.attribute15 = mp.sp_id_new
           AND nvl(jrs.end_date_active,sysdate) >= sysdate
           AND ROWNUM = 1;

END IF;
RETURN(g_sales_rep(p_sales_rep));
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END sales_rep;

FUNCTION Get_Ship_Method (p_ship_method IN VARCHAR2) RETURN VARCHAR2 IS
-- +===================================================================+
-- | Name  : get_ship_method                                           |
-- | Description     : To derive ship_method_code by passing           |
-- |                   delivery code                                   |
-- |                                                                   |
-- | Parameters     : p_ship_method  IN -> pass delivery code          |
-- |                                                                   |
-- | Return         : ship_method_code                                 |
-- +===================================================================+

BEGIN
IF NOT g_Ship_Method.exists(p_ship_method) THEN
         SELECT ship.lookup_code
          INTO g_Ship_Method(p_Ship_Method)
          FROM oe_ship_methods_v ship,
               fnd_lookup_values lkp
         WHERE lkp.attribute6 = ship.lookup_code
           AND lkp.lookup_code = p_ship_method
           AND lkp.lookup_type = 'OD_SHIP_METHODS';

END IF;
RETURN(g_Ship_Method(p_Ship_Method));
EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add('Not able to get the ship method '||substr(SQLERRM,1,90)) ;
        RETURN NULL;
END Get_Ship_Method;

FUNCTION Get_Ret_ActCatReason_Code (p_code IN VARCHAR2) RETURN VARCHAR2 IS
-- +===================================================================+
-- | Name  : Get_Ret_ActCatReason_Code                                 |
-- | Description     : To  derive return_act_cat_code by passing       |
-- |                   action,category,reason                          |
-- |                                                                   |
-- | Parameters     : p_code  IN -> pass code                          |
-- |                                                                   |
-- | Return         : account_category_code                            |
-- +===================================================================+

BEGIN
IF NOT g_Ret_ActCatReason.exists(p_code) THEN
         SELECT lkp.lookup_code
          INTO g_Ret_ActCatReason(p_code)
          FROM fnd_lookup_values lkp
         WHERE lkp.lookup_code = p_code
           AND lkp.lookup_type = 'OD_GMIL_REASON_KEY';

END IF;
RETURN(g_Ret_ActCatReason(p_code));
EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add('4UNEXPECTED ERROR: '||SQLERRM ) ;
        RETURN NULL;
END Get_Ret_ActCatReason_Code;


FUNCTION sales_channel(p_sales_channel IN VARCHAR2) RETURN VARCHAR2 IS
-- +===================================================================+
-- | Name  : sales_channel                                             |
-- | Description     : To validate sales_channel_code by passing       |
-- |                   sales channel                                   |
-- |                                                                   |
-- | Parameters     : p_sales_channel  IN -> pass sales channel        |
-- |                                                                   |
-- | Return         : sales_channel_code                               |
-- +===================================================================+

BEGIN
IF NOT g_sales_channel.exists(p_sales_channel) THEN
      SELECT lookup_code
        INTO g_sales_channel(p_sales_channel)
        FROM oe_lookups
       WHERE lookup_type = 'SALES_CHANNEL'
         AND lookup_code = p_sales_channel;

END IF;
RETURN(g_sales_channel(p_sales_channel));
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END sales_channel;

FUNCTION return_reason (p_return_reason IN VARCHAR2)
-- +===================================================================+
-- | Name  : return_reason                                             |
-- | Description     : To derive return_reason_code by passing         |
-- |                   return reason                                   |
-- |                                                                   |
-- | Parameters     : p_return_reason  IN -> pass return reason        |
-- |                                                                   |
-- | Return         : return_reason_code                               |
-- +===================================================================+

RETURN VARCHAR2
IS
BEGIN
IF NOT g_return_reason.exists (p_return_reason) THEN
    SELECT lookup_code
      INTO g_return_reason(p_return_reason)
      FROM OE_AR_LOOKUPS_V
     WHERE lookup_type ='CREDIT_MEMO_REASON'
       AND UPPER(lookup_code) = UPPER(p_return_reason);
END IF;
RETURN(g_return_reason(p_return_reason));
EXCEPTION
    WHEN OTHERS THEN
        RETURN(NULL);
END return_reason;

FUNCTION payment_term (p_sold_to_org_id IN NUMBER) RETURN NUMBER IS
-- +===================================================================+
-- | Name  : payment_term                                              |
-- | Description     : To derive payment_term_id by passing            |
-- |                   customer_id                                     |
-- |                                                                   |
-- | Parameters     : p_sold_to_org_id  IN -> pass customer id         |
-- |                                                                   |
-- | Return         : payment_term_id                                  |
-- +===================================================================+

ln_payment_term_id  NUMBER;
BEGIN
    SELECT standard_terms
      INTO ln_payment_term_id
      FROM hz_customer_profiles
     WHERE cust_account_id = p_sold_to_org_id
     AND site_use_id IS NULL;

    RETURN ln_payment_term_id;

EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END payment_term;

FUNCTION Get_Organization_id (p_org_no IN VARCHAR2) RETURN NUMBER IS
-- +===================================================================+
-- | Name  : Get_Organization_id                                       |
-- | Description     : To derive store_id by passing                   |
-- |                   store location                                  |
-- |                                                                   |
-- | Parameters     : p_org_no  IN -> pass store location              |
-- |                                                                   |
-- | Return         : store_id for KFF DFF                             |
-- +===================================================================+

BEGIN
    IF NOT g_org_rec.organization_id.exists(p_org_no) THEN
        Load_org_details(p_org_no);
    END IF;
    RETURN(g_org_rec.organization_id(p_org_no));
EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add('Error in Getting Org ID: '||SQLERRM ) ;
        RETURN NULL;

END Get_Organization_id;

FUNCTION Get_org_code (p_org_id IN NUMBER) RETURN VARCHAR2 IS
-- +===================================================================+
-- | Name  : Get_org_code                                              |
-- | Description     : To derive opu country by passing                |
-- |                   org id                                          |
-- |                                                                   |
-- | Parameters     : p_org_id  IN -> pass opu id                      |
-- |                                                                   |
-- | Return         : opu country                                      |
-- +===================================================================+

lc_ou_country VARCHAR2(10);
BEGIN
    SELECT SUBSTR(name,(INSTR(name,'_',1,1) +1),2) name
        INTO  LC_OU_COUNTRY
        FROM hr_operating_units
        WHERE organization_id = p_org_id;
    
    RETURN LC_OU_COUNTRY;
EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add('Error in Getting operating unit name: '||SQLERRM);
        RETURN NULL;
END;
-- +===================================================================+
-- | Name  : Get_Store_id                                              |
-- | Description     : To derive store_id by passing                   |
-- |                   store location                                  |
-- |                                                                   |
-- | Parameters     : p_org_no  IN -> pass store location              |
-- |                                                                   |
-- | Return         : store_id for KFF DFF                             |
-- +===================================================================+
FUNCTION Get_Store_id(p_org_no IN VARCHAR2) RETURN NUMBER IS
BEGIN

    IF NOT g_org_rec.organization_id.exists(p_org_no) THEN
        Load_org_details(p_org_no);
    END IF;
    IF SUBSTR(G_org_rec.organization_type(p_org_no),1,5) = 'STORE' THEN
        RETURN(g_org_rec.organization_id(p_org_no));
    ELSE
        RETURN NULL;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add('Error in GEtting Store ID : '||SQLERRM ) ;
        RETURN NULL;

END Get_Store_id;

-- +===================================================================+
-- | Name  : Get_store_Country                                         |
-- | Description     : To derive store country by passing              |
-- |                   store location                                  |
-- |                                                                   |
-- | Parameters     : p_STORE_no  IN -> pass store location            |
-- |                                                                   |
-- | Return         : Country code                                     |
-- +===================================================================+
FUNCTION Get_Store_Country (p_store_no IN VARCHAR2) RETURN VARCHAR2 IS
BEGIN
    IF NOT g_org_rec.organization_id.exists(p_store_no) THEN
        Load_org_details(p_store_no);
    END IF;
    RETURN(g_org_rec.country_code(p_store_no));
EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add('ERROR in getting country code: '||SQLERRM ) ;
        RETURN NULL;

END Get_Store_Country;

-- +===================================================================+
-- | Name  : Get_UOM_Code                                              |
-- | Description : To derive item UOM(EBS) by passing legacy UOM code  |
-- |                                                                   |
-- | Parameters  : p_legacy_uom  IN -> pass legacy UOM code            |
-- |                                                                   |
-- | Return      : UOM Code                                            |
-- +===================================================================+
FUNCTION Get_UOM_Code (p_legacy_uom IN VARCHAR2) RETURN VARCHAR2 IS
BEGIN
IF G_UOM_CODE.exists(p_legacy_uom) THEN
    RETURN G_UOM_CODE(p_legacy_uom);
ELSE
    SELECT uom_code
      INTO G_UOM_CODE(p_legacy_uom)
      FROM mtl_units_of_measure_vl
     WHERE attribute1 = p_legacy_uom
     AND ROWNUM = 1;
    RETURN G_UOM_CODE(p_legacy_uom);
END IF;
EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add('ERROR in getting UOM code: '||SQLERRM ) ;
        RETURN NULL;

END Get_UOM_Code;

-- +===================================================================+
-- | Name  : Load_Org_Details                                          |
-- | Description : Local procedure to load org details                 |
-- |                                                                   |
-- | Parameters  : p_org_no  IN -> pass inv/store location no          |
-- |                                                                   |
-- | Return      : None                                                |
-- +===================================================================+

PROCEDURE Load_Org_Details(p_org_no IN VARCHAR2)
IS
BEGIN
    SELECT organization_id,
           attribute5,
           org.name,
           org.type
      INTO g_org_rec.organization_id(p_org_no),
           g_org_rec.country_code(p_org_no),
           g_org_rec.organization_name(p_org_no),
           g_org_rec.organization_type(p_org_no)
      FROM hr_all_organization_units ORG
     WHERE attribute1 = p_org_no;
EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add('Error in loading Org Details: '||SQLERRM ) ;

END Load_Org_Details;

-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization        |
-- +====================================================================+
-- | Name  : Get_return_Attributes                                      |
-- | Description      : This Procedure is called to get header_id and   |
-- |                    line_id for return orders by passing the header |
-- |                    line ref's and sold_to_org_id                   |
-- |                                                                    |
-- | Parameters:        p_ref_order_number IN PASS orig order no        |
-- |                    p_ref_line IN PASS orig ref line no for a return|
-- |                    p_sold_to_org_id IN PASS customer id            |
-- |                    x_header_id OUT REUTRN Header_id for orig ord no|
-- |                    x_line_id OUT RETURN line_id of orig line no    |
-- +====================================================================+

PROCEDURE Get_return_attributes ( p_ref_order_number IN VARCHAR2
                                , p_ref_line         IN VARCHAR2
                                , p_sold_to_org_id   IN NUMBER
                                , x_header_id        OUT NOCOPY NUMBER
                                , x_line_id          OUT NOCOPY NUMBER
                                , x_orig_sell_price  OUT NOCOPY NUMBER
                                , x_orig_ord_qty     OUT NOCOPY NUMBER
                           )
IS
BEGIN

    SELECT header_id, line_id, ordered_quantity, unit_selling_price
      INTO x_header_id, x_line_id, x_orig_ord_qty, x_orig_sell_price
      FROM oe_order_lines_all
     WHERE orig_sys_document_ref = p_ref_order_number
       AND orig_sys_line_ref = p_ref_line
       AND sold_to_org_id = p_sold_to_org_id;
EXCEPTION
    WHEN OTHERS THEN

        x_header_id := NULL;
        x_line_id   := NULL;
        x_orig_ord_qty := NULL;
        x_orig_sell_price := NULL;
END Get_return_attributes;

-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization        |
-- +====================================================================+
-- | Name  : Get_return_header                                          |
-- | Description      : This Procedure is called to get reference       |
-- |header_id for return orders by passing the orig_sys_document_ref    |
-- |                                                                    |
-- | Parameters:        p_ref_order_number IN PASS orig order no        |
-- |                    p_sold_to_org_id IN PASS customer id            |
-- |                    x_header_id OUT REUTRN Header_id for orig ord no|
-- +====================================================================+
PROCEDURE Get_return_header ( p_ref_order_number IN VARCHAR2
                            , p_sold_to_org_id   IN NUMBER
                            , x_header_id        OUT NOCOPY NUMBER
                           )
IS
BEGIN

    SELECT header_id
      INTO x_header_id
      FROM oe_order_headers_all
     WHERE orig_sys_document_ref = p_ref_order_number
       AND sold_to_org_id = p_sold_to_org_id
       AND ROWNUM = 1;
EXCEPTION
    WHEN OTHERS THEN
        x_header_id := NULL;

END Get_Return_Header;


FUNCTION customer_item_id (p_cust_item IN VARCHAR2, p_customer_id IN NUMBER) RETURN NUMBER IS
-- +===================================================================+
-- | Name  : customer_item_id                                          |
-- | Description     : To derive customer_item_id  by passing          |
-- |                   legacy customer product_code                    |
-- |                                                                   |
-- | Parameters     : p_cust_item  IN -> pass customer sku number      |
--|                   p_customer_id IN -> pass customer_id             |
-- |                                                                   |
-- | Return         : customer_item_id                                 |
-- +===================================================================+

ln_cust_item_id   NUMBER;
BEGIN
    SELECT customer_item_id
      INTO ln_cust_item_id
      FROM mtl_customer_items
     WHERE customer_item_number = p_cust_item
       AND customer_id = p_customer_id;

    RETURN ln_cust_item_id;

EXCEPTION
    WHEN OTHERS THEN
        RETURN(NULL);
END customer_item_id;

FUNCTION get_inventory_item_id ( p_item IN VARCHAR2) RETURN NUMBER IS
-- +===================================================================+
-- | Name  : get_inventory_item_id                                     |
-- | Description     : To derive inventory_item_id  by passing         |
-- |                   legacy item number                              |
-- |                                                                   |
-- | Parameters     : p_item  IN -> pass sku number                    |
-- |                                                                   |
-- | Return         : inventory_item_id                                |
-- +===================================================================+

    ln_master_organization_id NUMBER;
    ln_inventory_item_id    NUMBER;
BEGIN
    ln_master_organization_id := oe_sys_parameters.VALUE('MASTER_ORGANIZATION_ID', g_org_id);
    SELECT inventory_item_id
    INTO ln_inventory_item_id
    FROM mtl_system_items_b
    WHERE organization_id = ln_master_organization_id
    AND segment1 = p_item;

    RETURN ln_inventory_item_id;
EXCEPTION
    WHEN OTHERS THEN
        return NULL;
END get_inventory_item_id;

PROCEDURE Get_Pay_Method(
      p_payment_instrument IN VARCHAR2
    , p_payment_type_code IN OUT NOCOPY VARCHAR2
    , p_credit_card_code  IN OUT NOCOPY VARCHAR2)
IS

-- +===================================================================+
-- | Name  : Get_Pay_Method                                            |
-- | Description      : This Procedure is called to get pay method     |
-- |                    code and credit_card_code                      |
-- |                                                                   |
-- | Parameters:        p_payment_instrument IN pass pay instrument    |
-- |                    p_payment_type_code OUT Return payment_code    |
-- |                    p_credit_card_code  OUT Return credit_card_code|
-- +===================================================================+

BEGIN
    IF NOT g_pay_method_code.exists(p_payment_instrument) THEN
        SELECT attribute7, attribute6
        INTO g_pay_method_code(p_payment_instrument), g_cc_code(p_payment_instrument)
        FROM fnd_lookup_values
        WHERE lookup_type = 'OD_PAYMENT_TYPES'
        AND lookup_code = p_payment_instrument;

    END IF;
    p_payment_type_code := g_pay_method_code(p_payment_instrument);
    p_credit_card_code := g_cc_code(p_payment_instrument);
EXCEPTION
    WHEN OTHERS THEN
        p_payment_type_code := NULL;
        p_credit_card_code := NULL;
END Get_pay_method;

FUNCTION Get_receipt_method(
      p_pay_method_code IN VARCHAR2
    , p_org_id IN NUMBER
    , p_Store_No IN VARCHAR2
    ) RETURN VARCHAR2 IS
-- +===================================================================+
-- | Name  : Get_receipt_method                                        |
-- | Description     : To derive receipt_method_id  by passing         |
-- |                   legacy payment_method_code, org_id, current     |
-- |                    header index                                   |
-- | Parameters     : p_pay_method_code  IN -> pass pay method code    |
-- |                  p_org_id           IN -> operating unit id       |
-- |                  p_store_no         IN -> Store No                |
-- |                                                                   |
-- | Return         : receipt_method_id                                |
-- +===================================================================+

  ln_receipt_method_id   NUMBER;
  lc_cash_name           VARCHAR2(20);
BEGIN
    IF G_OU_COUNTRY IS NULL THEN
        -- Get the OU Name
        SELECT SUBSTR(name,(INSTR(name,'_',1,1) +1),2) name
        INTO  G_OU_COUNTRY
        FROM hr_operating_units
        WHERE organization_id = g_org_id;

    END IF;

    IF p_pay_method_code IN ('01','51','81','10','31','80') THEN

        lc_cash_name := G_OU_COUNTRY || '_OM_CASH_'|| LPAD(p_store_no,6,'0');

        SELECT receipt_method_id
        INTO ln_receipt_method_id
        FROM AR_RECEIPT_METHODS
        WHERE NAME = lc_cash_name;

    ELSE
        ln_receipt_method_id := OE_Sys_Parameters.value(p_pay_method_code,G_Org_Id);

    END IF;

    RETURN ln_receipt_method_id;

EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add('NO_DATA_FOUND in receipt_method_code: '||p_store_no) ;
        RETURN NULL;
END Get_receipt_method;

FUNCTION credit_card_name(p_sold_to_org_id IN NUMBER) RETURN VARCHAR2 IS
-- +===================================================================+
-- | Name  : credit_card_name                                          |
-- | Description     : To derive credit_card_name  by passing          |
-- |                   customer id                                     |
-- |                                                                   |
-- | Parameters     : p_sold_to_org_id  IN -> pass customer id         |
-- |                                                                   |
-- | Return         : credit_card_name                                 |
-- +===================================================================+

  lc_cc_name VARCHAR2(80);
BEGIN
    SELECT party_name
    INTO lc_cc_name
    FROM hz_parties p,
         hz_cust_accounts a
    WHERE a.cust_account_id = p_sold_to_org_id
    AND   a.party_id = p.party_id;

    RETURN lc_cc_name;

EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END credit_card_name;

PROCEDURE Set_Header_Error(p_header_index IN BINARY_INTEGER)
IS

-- +===================================================================+
-- | Name  : Set_Header_Error                                          |
-- | Description      : This Procedure is called to set error_flag     |
-- |                    at header iface all when an error is raised    |
-- |                    while validating                               |
-- |                                                                   |
-- | Parameter:         p_header_index IN passing header index         |
-- +===================================================================+

BEGIN
    g_header_rec.error_flag(p_header_index) := 'Y';
    g_header_rec.batch_id(p_header_index) := NULL;
    --g_header_rec.request_id(p_header_index) := NULL;

END Set_Header_Error;

PROCEDURE clear_table_memory IS
-- +===================================================================+
-- | Name  : Clear_Table_Memory                                        |
-- | Description      : This Procedure will clear the cache i.e delete |
-- |                    data from temporay tables for every 500 records|
-- |                                                                   |
-- +===================================================================+

BEGIN

G_header_rec.orig_sys_document_ref.DELETE;
G_header_rec.order_source_id.DELETE;
G_header_rec.change_sequence.DELETE;
G_header_rec.order_category.DELETE;
G_header_rec.org_id.DELETE;
G_header_rec.ordered_date.DELETE;
G_header_rec.order_type_id.DELETE;
G_header_rec.legacy_order_type.DELETE;
G_header_rec.price_list_id.DELETE;
G_header_rec.transactional_curr_code.DELETE;
G_header_rec.salesrep_id.DELETE;
G_header_rec.sales_channel_code.DELETE;
G_header_rec.shipping_method_code.DELETE;
G_header_rec.shipping_instructions.DELETE;
G_header_rec.customer_po_number.DELETE;
G_header_rec.sold_to_org_id.DELETE;
G_header_rec.ship_from_org_id.DELETE;
G_header_rec.invoice_to_org_id.DELETE;
G_header_rec.sold_to_contact_id.DELETE;
G_header_rec.ship_to_org_id.DELETE;
G_header_rec.ship_to_org.DELETE;
G_header_rec.ship_from_org.DELETE;
G_header_rec.sold_to_org.DELETE;
G_header_rec.invoice_to_org.DELETE;
G_header_rec.drop_ship_flag.DELETE;
G_header_rec.booked_flag.DELETE;
G_header_rec.operation_code.DELETE;
G_header_rec.error_flag.DELETE;
G_header_rec.ready_flag.DELETE;
G_header_rec.payment_term_id.DELETE;
G_header_rec.tax_value.DELETE;
G_header_rec.customer_po_line_num.DELETE;
G_header_rec.category_code.DELETE;
G_header_rec.ship_date.DELETE;
G_header_rec.return_reason.DELETE;
G_header_rec.pst_tax_value.DELETE;
G_header_rec.return_orig_sys_doc_ref.DELETE;
G_header_rec.created_by.DELETE;
G_header_rec.creation_date.DELETE;
G_header_rec.last_update_date.DELETE;
G_header_rec.last_updated_by.DELETE;
G_header_rec.batch_id.DELETE;
G_header_rec.request_id.DELETE;
/* Header Attributes  */
G_header_rec.created_by_store_id.DELETE;
G_header_rec.paid_at_store_id.DELETE;
G_header_rec.paid_at_store_no.DELETE;
G_header_rec.spc_card_number.DELETE;
G_header_rec.placement_method_code.DELETE;
G_header_rec.advantage_card_number.DELETE;
G_header_rec.created_by_id.DELETE;
G_header_rec.delivery_code.DELETE;
G_header_rec.tran_number.DELETE;
G_header_rec.aops_geo_code.DELETE;
G_header_rec.tax_exempt_amount.DELETE;
G_header_rec.delivery_method.DELETE;
G_header_rec.release_number.DELETE;
G_header_rec.cust_dept_no.DELETE;
G_header_rec.desk_top_no.DELETE;
G_header_rec.comments.DELETE;
G_header_rec.start_line_index.DELETE;
G_header_rec.accounting_rule_id.DELETE;
G_header_rec.sold_to_contact.DELETE;
G_header_rec.header_id.DELETE;
G_header_rec.org_order_creation_date.DELETE;
G_header_rec.return_act_cat_code.DELETE;
G_header_rec.salesrep.DELETE;
G_header_rec.order_source.DELETE;
G_header_rec.sales_channel.DELETE;
G_header_rec.shipping_method.DELETE;
G_header_rec.deposit_amount.DELETE;
G_header_rec.gift_flag.DELETE;
G_header_rec.sas_sale_date.DELETE;
G_header_rec.legacy_cust_name.DELETE;
G_header_rec.inv_loc_no.DELETE;
g_header_rec.ship_to_sequence.DELETE;
g_header_rec.ship_to_address1.DELETE;
g_header_rec.ship_to_address2.DELETE;
g_header_rec.ship_to_city.DELETE;
g_header_rec.ship_to_state.DELETE;
g_header_rec.ship_to_country.DELETE;
g_header_rec.ship_to_county.DELETE;
g_header_rec.ship_to_zip.DELETE;
g_header_rec.tax_exempt_flag.DELETE;
g_header_rec.tax_exempt_number.DELETE;
g_header_rec.tax_exempt_reason.DELETE;
G_header_rec.ship_to_name.DELETE;
G_header_rec.bill_to_name.DELETE;
G_header_rec.cust_contact_name.DELETE;
G_header_rec.cust_pref_phone.DELETE;
G_header_rec.cust_pref_phextn.DELETE;
G_header_rec.deposit_hold_flag.DELETE;
G_header_rec.ineligible_for_hvop.DELETE;
G_header_rec.tax_rate.DELETE;
G_header_rec.order_number.DELETE;
G_header_rec.is_reference_return.DELETE;
G_header_rec.order_total.DELETE;
G_header_rec.commisionable_ind.DELETE;
G_header_rec.order_action_code.DELETE;
G_header_rec.order_start_time.DELETE;
G_header_rec.order_end_time.DELETE;
G_header_rec.order_taxable_cd.DELETE;
G_header_rec.override_delivery_chg_cd.DELETE;
G_header_rec.price_cd.DELETE;
G_header_rec.ship_to_geocode.DELETE;
G_header_rec.cust_dept_description.DELETE;

/* line Record */
G_line_rec.orig_sys_document_ref.DELETE;
G_line_rec.order_source_id.DELETE;
G_line_rec.change_sequence.DELETE;
G_line_rec.org_id.DELETE;
G_line_rec.orig_sys_line_ref.DELETE;
G_line_rec.ordered_date.DELETE;
G_line_rec.line_number.DELETE;
G_line_rec.line_type_id.DELETE;
G_line_rec.inventory_item_id.DELETE;
G_line_rec.inventory_item.DELETE;
G_line_rec.source_type_code.DELETE;
G_line_rec.schedule_ship_date.DELETE;
G_line_rec.actual_ship_date.DELETE;
G_line_rec.schedule_arrival_date.DELETE;
G_line_rec.actual_arrival_date.DELETE;
G_line_rec.ordered_quantity.DELETE;
G_line_rec.order_quantity_uom.DELETE;
G_line_rec.shipped_quantity.DELETE;
G_line_rec.sold_to_org_id.DELETE;
G_line_rec.ship_from_org_id.DELETE;
G_line_rec.ship_to_org_id.DELETE;
G_line_rec.invoice_to_org_id.DELETE;
G_line_rec.ship_to_contact_id.DELETE;
G_line_rec.sold_to_contact_id.DELETE;
G_line_rec.invoice_to_contact_id.DELETE;
G_line_rec.drop_ship_flag.DELETE;
G_line_rec.price_list_id.DELETE;
G_line_rec.unit_list_price.DELETE;
G_line_rec.unit_selling_price.DELETE;
G_line_rec.calculate_price_flag.DELETE;
G_line_rec.tax_code.DELETE;
G_line_rec.tax_date.DELETE;
G_line_rec.tax_value.DELETE;
G_line_rec.shipping_method_code.DELETE;
G_line_rec.salesrep_id.DELETE;
G_line_rec.return_reason_code.DELETE;
G_line_rec.customer_po_number.DELETE;
G_line_rec.operation_code.DELETE;
G_line_rec.error_flag.DELETE;
G_line_rec.shipping_instructions.DELETE;
G_line_rec.return_context.DELETE;
G_line_rec.return_attribute1.DELETE;
G_line_rec.return_attribute2.DELETE;
G_line_rec.customer_item_name.DELETE;
G_line_rec.customer_item_id.DELETE;
G_line_rec.customer_item_id_type.DELETE;
G_line_rec.line_category_code.DELETE;
G_line_rec.tot_tax_value.DELETE;
G_line_rec.customer_line_number.DELETE;
G_line_rec.created_by.DELETE;
G_line_rec.creation_date.DELETE;
G_line_rec.last_update_date.DELETE;
G_line_rec.last_updated_by.DELETE;
G_line_rec.request_id.DELETE;
G_line_rec.batch_id.DELETE;
G_line_rec.legacy_list_price.DELETE;
G_line_rec.vendor_product_code.DELETE;
G_line_rec.contract_details.DELETE;
G_line_rec.item_comments.DELETE;
G_line_rec.line_comments.DELETE;
G_line_rec.taxable_flag.DELETE;
G_line_rec.sku_dept.DELETE;
G_line_rec.item_source.DELETE;
G_line_rec.average_cost.DELETE;
G_line_rec.po_cost.DELETE;
G_line_rec.canada_pst.DELETE;
G_line_rec.return_act_cat_code.DELETE;
G_line_rec.return_reference_no.DELETE;
G_line_rec.back_ordered_qty.DELETE;
G_line_rec.return_ref_line_no.DELETE;
G_line_rec.org_order_creation_date.DELETE;
G_line_rec.wholesaler_item.DELETE;
G_line_rec.header_id.DELETE;
G_line_rec.line_id.DELETE;
G_line_rec.payment_term_id.DELETE;
G_line_rec.inventory_item.DELETE;
G_Line_rec.schedule_status_code.DELETE;
G_Line_rec.user_item_description.DELETE;
G_Line_rec.config_code.DELETE;
G_Line_rec.ext_top_model_line_id.DELETE;
G_Line_rec.ext_link_to_line_id.DELETE;
G_Line_rec.sas_sale_date.DELETE;
G_Line_rec.aops_ship_date.DELETE;
G_Line_rec.calc_arrival_date.DELETE;
G_Line_rec.ret_ref_header_id.DELETE;
G_Line_rec.ret_ref_line_id.DELETE;
G_Line_rec.release_number.DELETE;
G_Line_rec.cust_dept_no.DELETE;
G_Line_rec.cust_dept_description.DELETE;
G_Line_rec.desk_top_no.DELETE;
g_Line_rec.tax_exempt_flag.DELETE;
g_Line_rec.tax_exempt_number.DELETE;
g_Line_rec.tax_exempt_reason.DELETE;
g_Line_rec.gsa_flag.DELETE; --Added by NB
g_Line_rec.consignment_bank_code.DELETE; 
g_Line_rec.waca_item_ctr_num.DELETE; 
g_Line_rec.orig_selling_price.DELETE; 
g_line_rec.price_cd.DELETE;
g_line_rec.price_change_reason_cd.DELETE;
g_line_rec.price_prefix_cd.DELETE;
g_line_rec.commisionable_ind.DELETE;
g_line_rec.unit_orig_selling_price.DELETE;

  /* Discount Record */
G_line_adj_rec.orig_sys_document_ref.DELETE;
G_line_adj_rec.order_source_id.DELETE;
G_line_adj_rec.org_id.DELETE;
G_line_adj_rec.orig_sys_line_ref.DELETE;
G_line_adj_rec.orig_sys_discount_ref.DELETE;
G_line_adj_rec.sold_to_org_id.DELETE;
G_line_adj_rec.change_sequence.DELETE;
G_line_adj_rec.automatic_flag.DELETE;
G_line_adj_rec.list_header_id.DELETE;
G_line_adj_rec.list_line_id.DELETE;
G_line_adj_rec.list_line_type_code.DELETE;
G_line_adj_rec.applied_flag.DELETE;
G_line_adj_rec.operand.DELETE;
G_line_adj_rec.arithmetic_operator.DELETE;
G_line_adj_rec.pricing_phase_id.DELETE;
G_line_adj_rec.adjusted_amount.DELETE;
G_line_adj_rec.inc_in_sales_performance.DELETE;
G_line_adj_rec.operation_code.DELETE;
G_line_adj_rec.error_flag.DELETE;
G_line_adj_rec.request_id.DELETE;
G_line_adj_rec.context.DELETE;
G_line_adj_rec.attribute6.DELETE;
G_line_adj_rec.attribute7.DELETE;
G_line_adj_rec.attribute8.DELETE;
G_line_adj_rec.attribute9.DELETE;
G_line_adj_rec.attribute10.DELETE;

/* payment record */
G_payment_rec.orig_sys_document_ref.DELETE;
G_payment_rec.order_source_id.DELETE;
G_payment_rec.orig_sys_payment_ref.DELETE;
G_payment_rec.org_id.DELETE;
G_payment_rec.payment_type_code.DELETE;
G_payment_rec.payment_collection_event.DELETE;
G_payment_rec.prepaid_amount.DELETE;
G_payment_rec.credit_card_number.DELETE;
G_payment_rec.credit_card_holder_name.DELETE;
G_payment_rec.credit_card_expiration_date.DELETE;
G_payment_rec.credit_card_code.DELETE;
G_payment_rec.credit_card_approval_code.DELETE;
G_payment_rec.credit_card_approval_date.DELETE;
G_payment_rec.check_number.DELETE;
G_payment_rec.payment_amount.DELETE;
G_payment_rec.operation_code.DELETE;
G_payment_rec.error_flag.DELETE;
G_payment_rec.receipt_method_id.DELETE;
G_payment_rec.payment_number.DELETE;
G_payment_rec.attribute6.DELETE;
G_payment_rec.attribute7.DELETE;
G_payment_rec.attribute8.DELETE;
G_payment_rec.attribute9.DELETE;
G_payment_rec.attribute10.DELETE;
G_payment_rec.sold_to_org_id.DELETE;
G_payment_rec.attribute11.DELETE;
G_payment_rec.attribute12.DELETE;
G_payment_rec.attribute13.DELETE;
G_payment_rec.attribute15.DELETE;
G_payment_rec.payment_set_id.DELETE;

/* tender record */
G_return_tender_rec.orig_sys_document_ref.DELETE;
G_return_tender_rec.orig_sys_payment_ref.DELETE;
G_return_tender_rec.order_source_id.DELETE;
G_return_tender_rec.payment_number.DELETE;
G_return_tender_rec.payment_type_code.DELETE;
G_return_tender_rec.credit_card_code.DELETE;
G_return_tender_rec.credit_card_number.DELETE;
G_return_tender_rec.credit_card_holder_name.DELETE;
G_return_tender_rec.credit_card_expiration_date.DELETE;
G_return_tender_rec.credit_amount.DELETE;
G_return_tender_rec.request_id.DELETE;
G_return_tender_rec.sold_to_org_id.DELETE;
G_return_tender_rec.cc_auth_manual.DELETE;
G_return_tender_rec.merchant_nbr.DELETE;
G_return_tender_rec.cc_auth_ps2000.DELETE;
G_return_tender_rec.allied_ind.DELETE;
G_return_tender_rec.sold_to_org_id.DELETE;
G_return_tender_rec.receipt_method_id.DELETE;
G_return_tender_rec.cc_mask_number.DELETE;
G_return_tender_rec.od_payment_type.DELETE;

EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in deleting global records :'||SUBSTR(SQLERRM,1,80));

END Clear_Table_Memory;



 PROCEDURE insert_data IS

-- +===================================================================+
-- | Name  : Insert_Data                                               |
-- | Description      : This Procedure will insert into Interface      |
-- |                    tables                                         |
-- |                                                                   |
-- +===================================================================+
BEGIN
    oe_debug_pub.add('Before Inserting data into headers');
    BEGIN
    FORALL i_hed IN G_header_rec.orig_sys_document_ref.FIRST..G_header_rec.orig_sys_document_ref.LAST
        INSERT INTO oe_headers_iface_all
                        ( orig_sys_document_ref
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
                 VALUES ( G_header_rec.orig_sys_document_ref(i_hed)
                        , G_header_rec.order_source_id(i_hed)
                        , G_org_id
                        , G_header_rec.change_sequence(i_hed)
                        , G_header_rec.order_category(i_hed)
                        , G_header_rec.ordered_date(i_hed)
                        , G_header_rec.order_type_id(i_hed)
                        , G_header_rec.price_list_id(i_hed)
                        , G_header_rec.transactional_curr_code(i_hed)
                        , G_header_rec.salesrep_id(i_hed)
                        , G_header_rec.sales_channel_code(i_hed)
                        , G_header_rec.shipping_method_code(i_hed)
                        , G_header_rec.shipping_instructions(i_hed)
                        , G_header_rec.customer_po_number(i_hed)
                        , G_header_rec.sold_to_org_id(i_hed)
                        , G_header_rec.ship_from_org_id(i_hed)
                        , G_header_rec.invoice_to_org_id(i_hed)
                        , G_header_rec.sold_to_contact_id(i_hed)
                        , G_header_rec.ship_to_org_id(i_hed)
                        , G_header_rec.ship_to_org(i_hed)
                        , G_header_rec.ship_from_org(i_hed)
                        , G_header_rec.sold_to_org(i_hed)
                        , G_header_rec.invoice_to_org(i_hed)
                        , G_header_rec.drop_ship_flag(i_hed)
                        , G_header_rec.booked_flag(i_hed)
                        , 'INSERT'
                        , G_header_rec.error_flag(i_hed)
                        , 'Y'
                        , FND_GLOBAL.USER_ID
                        , SYSDATE
                        , SYSDATE
                        , FND_GLOBAL.USER_ID
                        , NULL
                        , G_header_rec.request_id(i_hed)
                        , G_header_rec.batch_id(i_hed)
                        , G_header_rec.accounting_rule_id(i_hed)
                        , G_header_rec.sold_to_contact(i_hed)
                        , G_header_rec.payment_term_id(i_hed)
                        , G_Header_rec.salesrep(i_hed)
                        , G_header_rec.order_source(i_hed)
                        , G_header_rec.sales_channel(i_hed)
                        , G_header_rec.shipping_method(i_hed)
                        , g_header_rec.order_number(i_hed)
                        , G_header_rec.tax_exempt_flag(i_hed)
                        , G_header_rec.tax_exempt_number(i_hed)
                        , G_header_rec.tax_exempt_reason(i_hed)
                        , G_header_rec.ineligible_for_hvop(i_hed)
                        );
    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in inserting Header records :'||SUBSTR(SQLERRM,1,80));
            RAISE FND_API.G_EXC_ERROR;
    END;
    oe_debug_pub.add('Before Inserting data into headers attr');

    BEGIN
    FORALL i_hed IN G_header_rec.orig_sys_document_ref.FIRST..G_header_rec.orig_sys_document_ref.LAST
        INSERT INTO xx_om_headers_attr_iface_all
                        ( orig_sys_document_ref
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
                        ) VALUES
                        ( G_header_rec.orig_sys_document_ref(i_hed)
                        , G_header_rec.order_source_id(i_hed)
                        , G_header_rec.created_by_store_id(i_hed)
                        , G_header_rec.paid_at_store_id(i_hed)
                        , G_header_rec.paid_at_store_no(i_hed)
                        , G_header_rec.spc_card_number(i_hed)
                        , G_header_rec.placement_method_code(i_hed)
                        , G_header_rec.advantage_card_number(i_hed)
                        , G_header_rec.created_by_id(i_hed)
                        , G_header_rec.delivery_code(i_hed)
                        , G_header_rec.delivery_method(i_hed)
                        , G_header_rec.release_number(i_hed)
                        , G_header_rec.cust_dept_no(i_hed)
                        , G_header_rec.desk_top_no(i_hed)
                        , G_header_rec.comments(i_hed)
                        , SYSDATE
                        , FND_GLOBAL.USER_ID
                        , SYSDATE
                        , FND_GLOBAL.USER_ID
                        , G_header_rec.request_id(i_hed)
                        , G_header_rec.batch_id(i_hed)
                        , G_header_rec.gift_flag(i_hed)
                        , G_header_rec.legacy_cust_name(i_hed)
                        , G_header_rec.legacy_order_type(i_hed)
                        , G_header_rec.ship_to_sequence(i_hed)
                        , G_header_rec.ship_to_address1(i_hed)
                        , G_header_rec.ship_to_address2(i_hed)
                        , G_header_rec.ship_to_city(i_hed)
                        , G_header_rec.ship_to_state(i_hed)
                        , G_header_rec.ship_to_country(i_hed)
                        , G_header_rec.ship_to_county(i_hed)
                        , G_header_rec.ship_to_zip(i_hed)
                        , G_header_rec.ship_to_name(i_hed)
                        , G_header_rec.bill_to_name(i_hed)
                        , G_header_rec.cust_contact_name(i_hed)
                        , G_header_rec.cust_pref_phone(i_hed)
                        , G_header_rec.cust_pref_phextn(i_hed)
                        , G_FILE_NAME
                        , G_header_rec.tax_rate(i_hed)
                        , G_header_rec.order_total(i_hed)
                        , G_header_rec.commisionable_ind(i_hed)
                        , G_header_rec.order_action_code(i_hed)
                        , G_header_rec.order_start_time(i_hed)
                        , G_header_rec.order_end_time(i_hed) 
                        , G_header_rec.order_taxable_cd(i_hed)
                        , G_header_rec.override_delivery_chg_cd(i_hed)  
                        , G_header_rec.ship_to_geocode(i_hed)  
                        , G_header_rec.cust_dept_description(i_hed)
                        , G_header_rec.tran_number(i_hed)
                        , G_header_rec.aops_geo_code(i_hed)
                        , G_header_rec.tax_exempt_amount(i_hed)
                        );
    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in inserting Header Attribute records :'||SUBSTR(SQLERRM,1,80));
            RAISE FND_API.G_EXC_ERROR;
    END;

    oe_debug_pub.add('Before Inserting data into lines');
    BEGIN
    FORALL i_lin IN G_line_rec.orig_sys_document_ref.FIRST.. G_line_rec.orig_sys_document_ref.LAST
        INSERT INTO oe_lines_iface_all
                        ( orig_sys_document_ref
                        , order_source_id
                        , change_sequence
                        , org_id
                        , orig_sys_line_ref
                        , line_number
                        , line_type_id
                        , inventory_item_id
                        , inventory_item
                        --, source_type_code
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
                        )
                 VALUES ( G_line_rec.orig_sys_document_ref(i_lin)
                        , G_line_rec.order_source_id(i_lin)
                        , G_line_rec.change_sequence(i_lin)
                        , G_org_id
                        , G_line_rec.orig_sys_line_ref(i_lin)
                        , G_line_rec.line_number(i_lin)
                        , G_line_rec.line_type_id(i_lin)
                        , G_line_rec.inventory_item_id(i_lin)
                        , G_line_rec.inventory_item(i_lin)
                        --, G_line_rec.source_type_code(i_lin)
                        , G_line_rec.schedule_ship_date(i_lin)
                        , G_line_rec.actual_ship_date(i_lin)
                        , G_line_rec.salesrep_id(i_lin)
                        , G_line_rec.ordered_quantity(i_lin)
                        , G_line_rec.order_quantity_uom(i_lin)
                        , G_line_rec.shipped_quantity(i_lin)
                        , G_line_rec.sold_to_org_id(i_lin)
                        , G_line_rec.ship_from_org_id(i_lin)
                        , G_line_rec.ship_to_org_id(i_lin)
                        , G_line_rec.invoice_to_org_id(i_lin)
                        , G_line_rec.drop_ship_flag(i_lin)
                        , G_line_rec.price_list_id(i_lin)
                        , G_line_rec.unit_list_price(i_lin)
                        , G_line_rec.unit_selling_price(i_lin)
                        , 'N'
                        , 'Location'
                        , G_line_rec.tax_value(i_lin)
                        , G_line_rec.tax_date(i_lin)
                        , G_line_rec.shipping_method_code(i_lin)
                        , G_line_rec.return_reason_code(i_lin)
                        , G_line_rec.customer_po_number(i_lin)
                        , 'INSERT'
                        , 'N'
                        , G_line_rec.shipping_instructions(i_lin)
                        , G_line_rec.return_context(i_lin)
                        , G_line_rec.return_attribute1(i_lin)
                        , G_line_rec.return_attribute2(i_lin)
                        , G_line_rec.customer_item_id(i_lin)
                        , G_line_rec.customer_item_id_type(i_lin)
                        , G_line_rec.line_category_code(i_lin)
                        , SYSDATE
                        , FND_GLOBAL.USER_ID
                        , SYSDATE
                        , FND_GLOBAL.USER_ID
                        , G_request_id
                        , G_line_rec.line_id(i_lin) 
                        , G_line_rec.payment_term_id(i_lin)
                        , G_line_rec.ordered_date(i_lin)
                        , G_line_rec.schedule_status_code(i_lin)
                        , G_line_rec.customer_item_id(i_lin)
                        , G_line_rec.user_item_description(i_lin)
                        , G_line_rec.tax_exempt_flag(i_lin)
                        , G_line_rec.tax_exempt_number(i_lin)
                        , G_line_rec.tax_exempt_reason(i_lin)
                        , G_line_rec.customer_line_number(i_lin)
                        );
    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in inserting Line records :'||SUBSTR(SQLERRM,1,80));
            RAISE FND_API.G_EXC_ERROR;
    END;

      oe_debug_pub.add('Before Inserting data into lines attr');
    BEGIN
    FORALL i_lin IN G_line_rec.orig_sys_document_ref.FIRST.. G_line_rec.orig_sys_document_ref.LAST
        INSERT INTO xx_om_lines_attr_iface_all
                        ( orig_sys_document_ref
 			, order_source_id
 			, request_id
 			, vendor_product_code
 			, average_cost
 			, po_cost
 			, canada_pst
 			, return_act_cat_code
 			, RET_ORIG_ORDER_NUM
 			, back_ordered_qty
 			, RET_ORIG_ORDER_LINE_NUM
 			, RET_ORIG_ORDER_DATE
 			, wholesaler_item
 			, Orig_sys_line_ref
 			, Legacy_list_price
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
                        , gsa_flag --Added by NB
                        , waca_item_ctr_num
                        , consignment_bank_code
                        , price_cd   
                        , price_change_reason_cd 
                        , price_prefix_cd
                        , commisionable_ind  
                        , cust_dept_description  
                        , unit_orig_selling_price
 	      		)
                 VALUES ( G_line_rec.orig_sys_document_ref(i_lin)
 			, G_line_rec.order_source_id(i_lin)
 			, G_request_id
 			, G_line_rec.vendor_product_code(i_lin)
 			, G_line_rec.average_cost(i_lin)
 			, G_line_rec.po_cost(i_lin)
 			, G_line_rec.canada_pst(i_lin)
 			, G_line_rec.return_act_cat_code(i_lin)
 			, G_line_rec.return_reference_no(i_lin)
 			, G_line_rec.back_ordered_qty(i_lin)
 			, G_line_rec.return_ref_line_no(i_lin)
 			, G_line_rec.org_order_creation_date(i_lin)
 			, G_line_rec.wholesaler_item(i_lin)
 			, G_line_rec.orig_sys_line_ref(i_lin)
 			, G_line_rec.legacy_list_price(i_lin)
 			, G_org_id
 			, G_line_rec.contract_details(i_lin)
                        , G_line_rec.item_comments(i_lin)
 			, G_line_rec.line_comments(i_lin)
 			, G_line_rec.taxable_flag(i_lin)
 			, G_line_rec.sku_dept(i_lin)
 			, G_line_rec.item_source(i_lin)
                        , G_line_rec.config_code(i_lin)
                        , G_line_rec.ext_top_model_line_id(i_lin)
                        , G_line_rec.ext_link_to_line_id(i_lin)
                        , G_line_rec.aops_ship_date(i_lin)
                        , G_line_rec.sas_sale_date(i_lin)
                        , G_line_rec.calc_arrival_date(i_lin)
 			, SYSDATE
 			, FND_GLOBAL.USER_ID
 			, SYSDATE
 			, FND_GLOBAL.USER_ID
                        , G_line_rec.ret_ref_header_id(i_lin)
                        , G_line_rec.ret_ref_line_id(i_lin)
                        , G_line_rec.release_number(i_lin)
                        , G_line_rec.cust_dept_no(i_lin)
                        , G_line_rec.desk_top_no(i_lin)
                        , G_line_rec.gsa_flag(i_lin) --Added By NB
                        , G_line_rec.waca_item_ctr_num(i_lin)
                        , G_line_rec.consignment_bank_code(i_lin)
                        , G_line_rec.price_cd(i_lin)   
                        , G_line_rec.price_change_reason_cd(i_lin) 
                        , G_line_rec.price_prefix_cd(i_lin)
                        , G_line_rec.commisionable_ind(i_lin)  
                        , G_line_rec.cust_dept_description(i_lin) 
                        , G_line_rec.unit_orig_selling_price(i_lin) 
 			);
    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in inserting Line Attr records :'||SUBSTR(SQLERRM,1,80));
            RAISE FND_API.G_EXC_ERROR;
    END;


      oe_debug_pub.add('Before Inserting data into price adjs');
    BEGIN
    FORALL i_dis IN G_line_adj_rec.orig_sys_document_ref.FIRST..G_line_adj_rec.orig_sys_document_ref.LAST
        INSERT INTO oe_price_adjs_iface_all
                        ( orig_sys_document_ref
                        , order_source_id
                        , change_sequence
                        , org_id
                        , orig_sys_line_ref
                        , orig_sys_discount_ref
                        , sold_to_org_id
                        , automatic_flag
                        , list_header_id
                        , list_line_id
                        , list_line_type_code
                        , applied_flag
                        , operand
                        , arithmetic_operator
                        , pricing_phase_id
                        , adjusted_amount
                        , inc_in_sales_performance
                        , request_id
                        , operation_code
                        , context
                        , attribute6
                        , attribute7
                        , attribute8
                        , attribute9
                        , attribute10
                        , created_by
                        , creation_date
                        , last_update_date
                        , last_updated_by
                        , OPERAND_PER_PQTY
                        , ADJUSTED_AMOUNT_PER_PQTY
                        )
                 VALUES ( G_line_adj_rec.orig_sys_document_ref(i_dis)
                        , G_line_adj_rec.order_source_id(i_dis)
                        , G_line_adj_rec.change_sequence(i_dis)
                        , G_org_id
                        , G_line_adj_rec.orig_sys_line_ref(i_dis)
                        , G_line_adj_rec.orig_sys_discount_ref(i_dis)
                        , G_line_adj_rec.sold_to_org_id(i_dis)
                        , 'N'
                        , G_line_adj_rec.list_header_id(i_dis)
                        , G_line_adj_rec.list_line_id(i_dis)
                        , 'DIS'
                        , 'Y'
                        , G_line_adj_rec.operand(i_dis)
                        , 'LUMPSUM'
                        , G_line_adj_rec.pricing_phase_id(i_dis)
                        , G_line_adj_rec.adjusted_amount(i_dis)
                        , 'Y'
                        , G_request_id
                        , 'INSERT'
                        , 'SALES_ACCT'
                        , G_line_adj_rec.attribute6(i_dis)
                        , G_line_adj_rec.attribute7(i_dis)
                        , G_line_adj_rec.attribute8(i_dis)
                        , G_line_adj_rec.attribute9(i_dis)
                        , G_line_adj_rec.attribute10(i_dis)
                        , FND_GLOBAL.USER_ID
                        , SYSDATE
                        , SYSDATE
                        , FND_GLOBAL.USER_ID
                        , G_line_adj_rec.operand(i_dis)
                        , G_line_adj_rec.adjusted_amount(i_dis)
                        );
      oe_debug_pub.add('Before Inserting data into Payments');
    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in inserting Adjustments records :'||SUBSTR(SQLERRM,1,80));
            RAISE FND_API.G_EXC_ERROR;
    END;

    BEGIN
    FORALL i_pay IN G_payment_rec.orig_sys_document_ref.FIRST.. G_payment_rec.orig_sys_document_ref.LAST
        INSERT INTO oe_payments_iface_all
                        ( orig_sys_document_ref
                        , order_source_id
                        , orig_sys_payment_ref
                        , org_id
                        , payment_type_code
                        , payment_collection_event
                        , prepaid_amount
                        , credit_card_number
                        , credit_card_holder_name
                        , credit_card_expiration_date
                        , credit_card_code
                        , credit_card_approval_code
                        , credit_card_approval_date
                        , check_number
                        , payment_amount
                        , operation_code
                        , error_flag
                        , receipt_method_id
                        , payment_number
                        , created_by
                        , creation_date
                        , last_update_date
                        , last_updated_by
                        , request_id
                        , context
                        , attribute6
                        , attribute7
                        , attribute8
                        , attribute9
                        , attribute10
                        , attribute11
                        , attribute12
                        , attribute13
                        , attribute15
                        , sold_to_org_id
                        , payment_set_id
 			      )
                 VALUES ( G_payment_rec.orig_sys_document_ref(i_pay)
                        , G_payment_rec.order_source_id(i_pay)
                        , G_payment_rec.orig_sys_payment_ref(i_pay)
                        , G_org_id
                        , G_payment_rec.payment_type_code(i_pay)
                        , 'PREPAY'
                        , G_payment_rec.prepaid_amount(i_pay)
                        , G_payment_rec.credit_card_number(i_pay)
                        , G_payment_rec.credit_card_holder_name(i_pay)
                        , G_payment_rec.credit_card_expiration_date(i_pay)
                        , G_payment_rec.credit_card_code(i_pay)
                        , G_payment_rec.credit_card_approval_code(i_pay)
                        , G_payment_rec.credit_card_approval_date(i_pay)
                        , G_payment_rec.check_number(i_pay)
                        , G_payment_rec.payment_amount(i_pay)
                        , 'INSERT'
                        , 'N'
                        , G_payment_rec.receipt_method_id(i_pay)
                        , G_payment_rec.payment_number(i_pay)
                        , FND_GLOBAL.USER_ID
                        , SYSDATE
                        , SYSDATE
                        , FND_GLOBAL.USER_ID
                        , G_request_id
                        , 'SALES_ACCT_HVOP'
                        , G_payment_rec.attribute6(i_pay)
                        , G_payment_rec.attribute7(i_pay)
                        , G_payment_rec.attribute8(i_pay)
                        , G_payment_rec.attribute9(i_pay)
                        , G_payment_rec.attribute10(i_pay)
                        , G_payment_rec.attribute11(i_pay)
                        , G_payment_rec.attribute12(i_pay)
                        , G_payment_rec.attribute13(i_pay)
                        , G_payment_rec.attribute15(i_pay)
                        , G_payment_rec.sold_to_org_id(i_pay)
                        , G_payment_rec.payment_set_id(i_pay)
                        );
      oe_debug_pub.add('Before Inserting data into Return tenders');

    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in Payment records :'||SUBSTR(SQLERRM,1,80));
            RAISE FND_API.G_EXC_ERROR;
    END;

    BEGIN
    FORALL i_pay IN G_return_tender_rec.orig_sys_document_ref.FIRST..G_return_tender_rec.orig_sys_document_ref.LAST
        INSERT INTO xx_om_ret_tenders_iface_all
                        ( orig_sys_document_ref
                        , order_source_id
                        , orig_sys_payment_ref
                        , payment_number
                        , request_id
                        , payment_type_code
                        , credit_card_code
                        , credit_card_number
                        , credit_card_holder_name
                        , credit_card_expiration_date
                        , credit_amount
                        , org_id
                        , sold_to_org_id
                        , created_by
                        , creation_date
                        , last_update_date
                        , last_updated_by
                        , cc_auth_manual
                        , merchant_number
                        , cc_auth_ps2000
                        , allied_ind
                        , receipt_method_id
                        , cc_mask_number
                        , od_payment_type
                        )
                 VALUES ( G_return_tender_rec.orig_sys_document_ref(i_pay)
                        , G_return_tender_rec.order_source_id(i_pay)
                        , G_return_tender_rec.orig_sys_payment_ref(i_pay)
                        , G_return_tender_rec.payment_number(i_pay)
                        , G_request_id
                        , G_return_tender_rec.payment_type_code(i_pay)
                        , G_return_tender_rec.credit_card_code(i_pay)
                        , G_return_tender_rec.credit_card_number(i_pay)
                        , G_return_tender_rec.credit_card_holder_name(i_pay)
                        , G_return_tender_rec.credit_card_expiration_date(i_pay)
                        , G_return_tender_rec.credit_amount(i_pay)
                        , G_org_id
                        , G_return_tender_rec.sold_to_org_id(i_pay)
                        , FND_GLOBAL.USER_ID
                        , SYSDATE
                        , SYSDATE
                        , FND_GLOBAL.USER_ID
                        , G_return_tender_rec.cc_auth_manual(i_pay)
                        , G_return_tender_rec.merchant_nbr(i_pay)
                        , G_return_tender_rec.cc_auth_ps2000(i_pay)
                        , G_return_tender_rec.allied_ind(i_pay)
                        , G_return_tender_rec.receipt_method_id(i_pay)
                        , G_return_tender_rec.cc_mask_number(i_pay)
                        , G_return_tender_rec.od_payment_type(i_pay)
                        );
    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in inserting Return Tenders records :'||SUBSTR(SQLERRM,1,80));
            RAISE FND_API.G_EXC_ERROR;
    END;

  oe_debug_pub.add('End of Inserting data into Return tenders');
END insert_data;

PROCEDURE set_msg_context( p_entity_code IN VARCHAR2
                         , p_warning_flag IN BOOLEAN DEFAULT FALSE
                         , p_line_ref IN VARCHAR2 DEFAULT NULL)
IS

-- +====================================================================+
-- | Name  : set_msg_context                                            |
-- | Description      : This Procedure will set message context         |
-- |                    the messages will be inserted into oe_processing|
-- |                    _msgs                                           |
-- |                                                                    |
-- | Parameters:        p_entity_code IN entity i.e. HEADER,LINE ETC    |
-- |                    p_line_ref    IN line reference number          |
-- +====================================================================+

    l_hdr_ind BINARY_INTEGER := g_header_rec.orig_sys_document_ref.COUNT;
    l_orig_sys_doc_ref VARCHAR2(80);
BEGIN
    IF p_warning_flag THEN
        l_orig_sys_doc_ref := NULL;
    ELSE
        l_orig_sys_doc_ref := g_header_rec.orig_sys_document_ref(l_hdr_ind);
    END IF;

    oe_bulk_msg_pub.set_msg_context( p_entity_code                 =>  p_entity_code
                                , p_entity_ref                     =>  NULL
                                , p_entity_id                      =>  NULL
                                , p_header_id                      =>  NULL
                                , p_line_id                        =>  NULL
                                , p_order_source_id                =>  g_header_rec.order_source_id(l_hdr_ind)
                                , p_orig_sys_document_ref	   =>  l_orig_sys_doc_ref
                                , p_orig_sys_document_line_ref     =>  p_line_ref
                                , p_orig_sys_shipment_ref   	   => NULL
                                , p_change_sequence   	           => NULL
                                , p_source_document_type_id        => NULL
                                , p_source_document_id	           => NULL
                                , p_source_document_line_id	   => NULL
                                , p_attribute_code       	   => NULL
                                , p_constraint_id		   => NULL );

END set_msg_context;

PROCEDURE insert_mismatch_amount_msgs IS

-- +====================================================================+
-- | Name  : insert_mismatch_amount_msgs                                |
-- | Description      : This Procedure will check the tot ord amt and   |
-- |                    payment amt mismatch                            |
-- |                                                                    |
-- +====================================================================+

  ln_msg_id NUMBER;

BEGIN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Entering insert_mismatch_amount_msgs ' );
FORALL i IN G_Ord_Tot_Mismatch_Rec.orig_sys_document_ref.FIRST .. G_Ord_Tot_Mismatch_Rec.orig_sys_document_ref.LAST
    INSERT INTO oe_processing_msgs
        ( Transaction_id
        , request_id
        , original_sys_document_ref
        , order_source_id
        , created_by
        , creation_date
        , last_updated_by
        , last_update_date
        , message_text
        , program_application_id
        )
    VALUES
        ( OE_MSG_ID_S.NEXTVAL
        , g_request_id
        , G_Ord_Tot_Mismatch_Rec.orig_sys_document_ref(i)
        , G_Ord_Tot_Mismatch_Rec.order_source_id(i)
        , FND_GLOBAL.USER_ID
        , SYSDATE
        , FND_GLOBAL.USER_ID
        , SYSDATE
        , G_Ord_Tot_Mismatch_Rec.Message(i)
        , 660
        );
    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in inserting Mismatch records :'||SUBSTR(SQLERRM,1,80));
            RAISE FND_API.G_EXC_ERROR;

END insert_mismatch_amount_msgs;

PROCEDURE SET_HEADER_ID
IS

-- +====================================================================+
-- | Name  : set_header_id                                              |
-- | Description      : This Procedure will set the header_id i.e.      |
-- |                    sequence number                                 |
-- |                                                                    |
-- +====================================================================+

  ln_order_source_id        T_NUM;
  lc_orig_sys_document_ref  T_V80;

BEGIN
    -- High volume import assumes that global headers table
    -- populated by oe_bulk_process_header.load_headers will have
    -- header records sorted in the ascending order for BOTH header_id
    -- and for (order_source_id,orig_sys_ref) combination.
    -- So order by order_source_id, orig_sys_ref when assigning
    -- header_id from the sequence. If it is not ordered thus, header_ids
    -- will be in random order in the global table and workflows/pricing
    -- for orders may be skipped.
   SELECT order_source_id, orig_sys_document_ref
   BULK COLLECT INTO ln_order_source_id, lc_orig_sys_document_ref
   FROM oe_headers_iface_all
   WHERE request_id = g_request_id
   AND order_category = 'ORDER'
   AND NVL(INELIGIBLE_FOR_HVOP,'N') = 'N'
   ORDER BY order_source_id, orig_sys_document_ref, change_sequence;

   -- Now bulk update the header_ids
   FORALL I IN 1..ln_order_source_id.COUNT
      UPDATE OE_HEADERS_IFACE_ALL
      SET header_id = oe_order_headers_s.nextval
      WHERE order_source_id = ln_order_source_id(i)
      AND orig_sys_document_ref = lc_orig_sys_document_ref(i)
      AND request_id = g_request_id;


EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in updating header_ids :'||SUBSTR(SQLERRM,1,80));
        RAISE FND_API.G_EXC_ERROR;

END SET_HEADER_ID;

-- +====================================================================+
-- | Name  : VALIDATE_ITEM_WAREHOUSE                                    |
-- | Description      : This procedure will be used by HVOP to validate |
-- | the combination of item/warehouse is valid or not.                 |
-- +====================================================================+
PROCEDURE VALIDATE_ITEM_WAREHOUSE(p_hdr_idx IN BINARY_INTEGER
                                , p_line_idx IN BINARY_INTEGER
                                , p_nonsku_flag IN VARCHAR2 DEFAULT 'N'
                                , p_item IN VARCHAR2)
IS
ln_item_id     NUMBER;
ln_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
lc_err_msg     VARCHAR2(200);
BEGIN
    IF p_item IS NULL THEN
        Set_Header_Error(p_hdr_idx);
        set_msg_context( p_entity_code => 'HEADER'
                        ,p_line_ref    => G_Line_Rec.Orig_Sys_Line_Ref(p_line_idx));
        lc_err_msg := 'Item Missing : ';
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
        FND_MESSAGE.SET_TOKEN('ATTRIBUTE','SKU Id');
        oe_bulk_msg_pub.add;
        IF ln_debug_level > 0 THEN
            oe_debug_pub.ADD(lc_err_msg, 1);
        END IF;
        G_line_rec.inventory_item_id(p_line_idx) := NULL;

    ELSE
        -- IF NON SKU item then get the inventory_item_id from fnd_lookup_values
        IF p_nonsku_flag = 'Y' THEN
            -- Get Inventory Item
            BEGIN
                SELECT attribute6
                  INTO G_Line_Rec.inventory_item_id(p_line_idx)
                  FROM fnd_lookup_values
                 WHERE lookup_type = 'OD_FEES_ITEMS'
                   AND lookup_code = p_item;
            EXCEPTION
                WHEN OTHERS THEN
                    G_line_rec.inventory_item_id(p_line_idx) := NULL;
            END;
        ELSE
            G_line_rec.inventory_item_id(p_line_idx) := get_inventory_item_id(p_item);
        END IF;

        IF G_line_rec.inventory_item_id(p_line_idx) IS NOT NULL AND
           G_line_rec.ship_from_org_id(p_line_idx) IS NOT NULL THEN
            BEGIN
                SELECT inventory_item_id
                  INTO ln_item_id
                  FROM mtl_system_items_b
                 WHERE inventory_item_id = G_line_rec.inventory_item_id(p_line_idx)
                   AND organization_id = G_line_rec.ship_from_org_id(p_line_idx);

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    Set_Header_Error(p_hdr_idx);
                    set_msg_context( p_entity_code => 'HEADER'
                            ,p_line_ref    => G_Line_Rec.Orig_Sys_Line_Ref(p_line_idx));
                    lc_err_msg := 'Item : '||p_item || 'Not Assigned to Warehouse/Store : '|| G_line_rec.ship_from_org_id(p_line_idx);
                    FND_MESSAGE.SET_NAME('XXOM','XX_OM_INVALID_ITEM_WAREHOUSE');
                    FND_MESSAGE.SET_TOKEN('ATTRIBUTE1', p_item );
                    FND_MESSAGE.SET_TOKEN('ATTRIBUTE2', g_org_rec.organization_name(G_header_rec.inv_loc_no(p_hdr_idx)));
                    oe_bulk_msg_pub.add;
                    IF ln_debug_level > 0 THEN
                            oe_debug_pub.ADD(lc_err_msg, 1);
                    END IF;
            END;
        END IF;

        -- If failed to derive the item then give error
        IF G_line_rec.inventory_item_id(p_line_idx) IS NULL THEN 
            G_line_rec.inventory_item(p_line_idx) := p_item;
            Set_Header_Error(p_hdr_idx);
            set_msg_context( p_entity_code => 'HEADER'
                            ,p_line_ref    => G_Line_Rec.Orig_Sys_Line_Ref(p_line_idx));
            lc_err_msg := 'ITEM NOT FOUND FOR  : ' || p_item;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAIL_SKU_DERIVATION');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE',p_item);
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        END IF; -- IF G_line_rec.inventory_item_id(p_line_idx) IS NULL

    END IF; -- IF p_item IS NULL 

END VALIDATE_ITEM_WAREHOUSE;

-- +=======================================================================+
-- | Name  : CLEAR_BAD_ORDERS                                              |
-- | Description      : This procedure will be used by HVOP to clear the   |
-- | data from pl-sql global tables for orders that failed with unexpected |
-- | errors.                                                               |
-- +=======================================================================+
PROCEDURE CLEAR_BAD_ORDERS(p_error_entity          IN VARCHAR2
                         , p_orig_sys_document_ref IN VARCHAR2
                          )
IS
i BINARY_INTEGER;
ln_debug_level   CONSTANT NUMBER := oe_debug_pub.g_debug_level;
BEGIN

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Entering the CLEAR_BAD_ORDERS :'||p_error_entity||' :'||p_orig_sys_document_ref);
    END IF;
  
    -- Add the BAD order message to message stack
    set_msg_context(p_entity_code => 'HEADER');
    FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAIL_TO_READ_ORDER');
    FND_MESSAGE.SET_TOKEN('ATTRIBUTE',p_orig_sys_document_ref);
    oe_bulk_msg_pub.add;

    -- Check if it is a header record that caused the unexpected error
    IF P_ERROR_ENTITY = 'HEADER' THEN
        GOTO SKIP_TO_HEADER;   
    END IF;
    -- We need to check all other ENTITY tables for the failed orig_sys_doc ref

    -- Check for the order lines for this BAD order
    i := g_line_rec.orig_sys_document_ref.LAST;
    IF i > 0 THEN
        WHILE g_line_rec.orig_sys_document_ref(i) = p_orig_sys_document_ref LOOP
            IF ln_debug_level > 0 THEN
                oe_debug_pub.add('Found bad line to delete :' || i);
            END IF;
            -- Delete the Line record
            DELETE_LINE_REC(i);
            IF P_ERROR_ENTITY <> 'LINE' THEN
                -- Decrement the line counter
                G_line_counter := G_line_counter - 1;
            END IF;
            i := i - 1;
            IF i = 0 THEN
                EXIT;
            END IF;
        END LOOP; 
    END IF;
    oe_debug_pub.add('After line delete :' || i);

    -- Check for the Price adjustments for this BAD order
    i := g_line_adj_rec.orig_sys_document_ref.LAST;
    IF i > 0 THEN
        WHILE g_line_adj_rec.orig_sys_document_ref(i) = p_orig_sys_document_ref LOOP
            IF ln_debug_level > 0 THEN
                oe_debug_pub.add('Found bad Adjustment to delete :' || i);
            END IF;
            -- Delete the Adjustment record
            DELETE_ADJ_REC(i);
            i := i - 1;
            IF i = 0 THEN
                EXIT;
            END IF;
        END LOOP; 
    END IF;

    oe_debug_pub.add('After ADJ delete :' || i);

    -- Check for the Tenders  for this BAD order
    i := g_payment_rec.orig_sys_document_ref.LAST;
    IF i > 0 THEN
        WHILE g_payment_rec.orig_sys_document_ref(i) = p_orig_sys_document_ref LOOP
            IF ln_debug_level > 0 THEN
                oe_debug_pub.add('Found bad Payment to delete :' || i);
            END IF;
            -- Delete the Payment record
            DELETE_PAYMENT_REC(i);
            i := i - 1;
            IF i = 0 THEN
                EXIT;
            END IF;
        END LOOP; 
    END IF;
    oe_debug_pub.add('After payment rec delete :' || i);

    i := G_return_tender_rec.orig_sys_document_ref.LAST;
    IF i > 0 THEN
        WHILE G_return_tender_rec.orig_sys_document_ref(i) = p_orig_sys_document_ref LOOP
            IF ln_debug_level > 0 THEN
                oe_debug_pub.add('Found bad Return Tender to delete :' || i);
            END IF;
            -- Delete the return tender record
            DELETE_RET_TENDER_REC(i);
            i := i - 1;
            IF i = 0 THEN
                EXIT;
            END IF;
        END LOOP; 
    END IF;
    oe_debug_pub.add('After return tender rec delete :' || i);

    -- decrement the header counter
    G_Header_Counter := G_Header_Counter - 1;

    <<SKIP_TO_HEADER>>

    -- Now clear the header record
    i := g_header_rec.orig_sys_document_ref.LAST;
    IF g_header_rec.orig_sys_document_ref(i) = p_orig_sys_document_ref THEN
        -- Delete the header record
        DELETE_HEADER_REC(i);
    END IF;
    
    IF ln_debug_level > 0 THEN
         oe_debug_pub.add('Header Count is :' || g_header_rec.orig_sys_document_ref.COUNT );
         oe_debug_pub.add('Exiting CLEAR_BAD_ORDERS:' );
    END IF;
   
END CLEAR_BAD_ORDERS;

PROCEDURE WRITE_TO_FILE(p_order_tbl IN order_tbl_type)
IS
lf_Handle     utl_file.file_type;
lc_file_path  VARCHAR2(100) := FND_PROFILE.VALUE('XX_OM_SAS_FILE_DIR');
lc_record     VARCHAR2(330);
lc_context    VARCHAR2(32);
BEGIN
    -- Check if the file is OPEN
    lf_Handle := utl_file.fopen(lc_file_path, G_File_Name||'.unp', 'A');

    -- Start reading the p_order_tbl
    FOR k in 1..p_order_tbl.count LOOP
        IF p_order_tbl(k).record_type = '10' THEN
            lc_record := SUBSTR(p_order_tbl(k).file_line,1,330);
            lc_context := SUBSTR(lc_record,1,32);
            IF lc_record is not NULL THEN
                -- Write it to the file
                utl_file.put_line(lf_Handle, lc_record, FALSE);
            END IF;
  
            -- check if it has 11 record
            lc_record := SUBSTR(p_order_tbl(k).file_line,331,298);
            IF lc_record IS NOT NULL THEN
                -- Write it to the file
                utl_file.put_line(lf_Handle,substr(lc_context,1,21)||'1'||substr(lc_context,23,10)||lc_record, FALSE);
            END IF;

            -- check if it has 12 record
            lc_record := SUBSTR(p_order_tbl(k).file_line,629,298);
            IF lc_record IS NOT NULL THEN
                -- Write it to the file
                utl_file.put_line(lf_Handle,substr(lc_context,1,21)||'2'||substr(lc_context,23,10)||lc_record, FALSE);
            END IF;

        ELSIF p_order_tbl(k).record_type = '20' THEN
            lc_record := SUBSTR(p_order_tbl(k).file_line,1,330);
            lc_context := SUBSTR(lc_record,1,32);
            IF lc_record is not NULL THEN
                -- Write it to the file
                utl_file.put_line(lf_Handle, lc_record, FALSE);
            END IF;
  
            -- check if it has 21 record
            lc_record := SUBSTR(p_order_tbl(k).file_line,331,298);
            IF lc_record IS NOT NULL THEN
                -- Write it to the file
                utl_file.put_line(lf_Handle,substr(lc_context,1,21)||'1'||substr(lc_context,23,10)||lc_record, FALSE);
            END IF;

        ELSIF p_order_tbl(k).record_type IN ('40','30') THEN
            lc_record := SUBSTR(p_order_tbl(k).file_line,1,330);
            IF lc_record is not NULL THEN
                -- Write it to the file
                utl_file.put_line(lf_Handle, lc_record, FALSE);
            END IF;
        END IF;
    END LOOP;
    utl_file.fflush(lf_Handle);
    utl_file.fclose(lf_Handle);
EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error While writing Order Record to file ' || G_File_Name||'.unp' || SQLERRM );
         NULL;
END WRITE_TO_FILE;

END XX_OM_SACCT_CONC_PKG;
/
SHOW ERRORS PACKAGE BODY XX_OM_SACCT_CONC_PKG;
EXIT;
