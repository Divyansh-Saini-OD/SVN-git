create or replace PACKAGE BODY      xx_om_sacct_conc_pkg
AS
-- +========================================================================================================================+
-- |                  Office Depot - Project Simplify                                                                       |
-- |                  Office Depot                                                                                          |
-- +========================================================================================================================+
-- | Name  : XX_OM_SACCT_CONC_PKG                                                                                           |
-- | Rice ID: I1272                                                                                                         |
-- | Description      : This Program will load all sales orders from                                                        |
-- |                    Legacy System(SACCT) into EBIZ                                                                      |
-- |                                                                                                                        |
-- |                                                                                                                        |
-- |Change Record:                                                                                                          |
-- |===============                                                                                                         |
-- |Version    Date          Author            Remarks                                                                      |
-- |=======    ==========    =============     ==============================                                               |
-- |DRAFT 1A   06-APR-2007   Bapuji Nanapaneni Initial draft version                                                        |
-- |      1.0  21-JUN-2007                     Modified the code to                                                         |
-- |                                           add user_item_description                                                    |
-- |      1.1  22-JUN-2007   Manish Chavan     Added code to identify store                                                 |
-- |                                           customer by Store No:Country                                                 |
-- |                                           Added function to convert UOM                                                |
-- |      1.2  24-JUL-2007   Manish Chavan     Added logic to process TAX                                                   |
-- |                                           REFUNDS, POS/AOPS Order #                                                    |
-- |      1.3  07-AUG-2007   Manish Chavan     Added POS fixes and Returns                                                  |
-- |                                           Fixes                                                                        |
-- |      1.4  11-SEP-2007   Bapuji Nanapaneni Added gsa_flag at process_line                                               |
-- |                                       and process adjustment lines proc                                                |
-- |      1.5  01-DEC-2008   Bapuji Nanapaneni  Defaulting the CC APP CODE                                                  |
-- |                                          and Date if null and commented                                                |
-- |                                            geocode API                                                                 |
-- |      1.6      11-Mar-2009 Matthew Craig     QC13608 taxable_ind                                                        |
-- |      1.7      14-Mar-2009 Bapuji Nanapaneni campaign code size change                                                  |
-- |      1.8      16-Mar-2009 Matthew Craig     Performance fix per                                                        |
-- |                                             Chuck/Satish                                                               |
-- |      1.9      28-JUL-2009 Bapuji Nanapaneni Fixed Defect ID 541                                                        |
-- |      2.0      29-JUL-2009 Bapuji Nanapaneni Fixed Defect ID 747                                                        |
-- |      2.1      28-OCT-2009 Bapuji Nanapaneni Fixed defect 2569 tax code                                                 |
-- |      2.2      17-Feb-2010 Bapuji Nanapaneni  Added get_salesrep_for                                                    |
-- |                                              _legacyrep                                                                |
-- |      2.3      10-MAY-2010 Bapuji N          Modify get_salesrep_for_lega                                               |
-- |                                             cyrep logic.                                                               |
-- |                                             Added logic not to fail and                                                |
-- |                                           write to unp file 0 qty orders                                               |
-- |      2.4      28-SEP-2010 Bapuji N        Modifed taxable_flag to pass                                                 |
-- |                                           Null QC 7025                                                                 |
-- |      2.5      07-JAN-2010 Bapuji N        Modifed SPC/PRO card orders to                                               |
-- |                                           show AOPS ORD NUM for R11.2                                                  |
-- |      2.6      07-FEB-2011 Bapuji N        Added order source function                                                  |
-- |                                           to detrmine all POE order to                                                 |
-- |                                        assign new line type for SDR 11.2                                               |
-- |      2.7      18-MAY-2011 Bapuji N        Added back the taxable flag                                                  |
-- |      2.8      07-JUL-2011 Bapuji N        Reverting back SPC/PRO changes                                               |
-- |      2.8      27-JUL-2011 Bapuji N     Added new column SR_NUMBER for                                                  |
-- |                                        parts project 11.4                                                              |
-- |      2.9      08-SEP-2011 Bapuji N        For single pay read ord tot                                                  |
-- |                                        from record 11 REL 11.5                                                         |
-- |      3.0      19-APR-2012 Bapuji N     Added CB Logic for single pay                                                   |
-- |                                        Defect No 17015                                                                 |
-- |      3.1      25-APR-2012 Ray Strauss  CR 623 reset payment terms to                                                   |
-- |                                        immediate                                                                       |
-- |      3.2      26-APR-2012 Oracle AMS Team  Changing the logic for                                                      |
-- |                                            deriving the transaction line                                               |
-- |                                            type and invoice source for                                                 |
-- |                                            POS Single payment and zero                                                 |
-- |                                            dollar transactions                                                         |
-- |      3.3      19-JUN-2012 Bapuji N         Added Customer Email                                                        |
-- |      3.4      26-OCT-2012 Bapuji N     Added ATR Flag for service ord                                                  |
-- |                                        validation                                                                      |
-- |      3.5      01-FEB-2012 Bapuji N     Added device_serial_num                                                         |
-- |      3.6      24-MAY-1013 Bapuji N     Amazon changes                                                                  |
-- |      3.7      27-JUN-2013 Bapuji N     Retro Fit for 12i upgrade                                                       |
-- |      3.8      28-Aug-2013  Edson M     Added new encryption solution                                                   |
-- |      3.9      12-Sept-2013 Edson M     Defect 25150                                                                    |
-- |      4.0      02-OCT-2013  Edson M     Re-retrofitting                                                                 |
-- |     ----------- Added as part of retrofitting for R12 ----------------                                                 |
-- |      4.1      15-AUG-2013 Raj J      MPS COGs changes(mps_toner_retail)                                                |
-- |                                      Added new get_mps_retail proc.                                                    |
-- |      4.2      8-OCT-2013  Raj J      Updated Sarita M defect#22640                                                     |
-- |                                      Over writted on 10/2                                                              |
-- |      4.3      8-OCT-2013  Raj J      Added MPS retail fix defect#25830                                                 |
-- |      4.4      4-NOV-2013  Raj J      Added MPS Retail to Returns                                                       |
-- |      4.5      27-DEC-2013 Edson M    Made changes to ensure that will                                                  |
-- |                                      testing in nonn-prod.. Credit cards                                               |
-- |                                      Are not expired.  Defect 27237                                                    |
-- |      5.0     04-Feb-2013 Edson M.    Changes for Defect 27883                                                          |
-- |      6.0     04-MAR-2014 Edson Mo.   Changes for Defect 28566                                                          |
-- |      6.1     14-May-2014 Edson M.    Core indicator changes                                                            |
-- |      7.0     25-Jun-2014 Vivek S.    RCC changes                                                                       |
-- |      8.0     17-JUL-2014 Arun G      Made changes to include the line                                                  |
-- |                                      type changes                                                                      | 
-- |      9.0     25-JUL-2014 Vivek S     Made changes in Process Tender to                                                 | 
-- |                                      to fix the defect# 31153                                                          |
-- |     10.0     07-NOV-2014 Arun G      Added MPS program types to get_serial_no_for_atr                                  | 
-- |                                      function to fix the 0.01 issue defect 26594 	                                    |
-- |     11.0     02-JAN-2015 Avinash B   Changes for AMZ MPL                                                               |
-- |     12.0     16-Apr-2015 Arun G      Made changes for Tonization project                                               |
-- |                                      defect 34103                                                                      |
-- |     13.0     30-Jun-2015 Arun G      Made changes to fix the defect #34899                                             |
-- |     14.0     20-Jul-2015 Arun G      Made changes to fix the defect #35134                                             |
-- |     15.0     20-Jul-2015 Arun G      Made changes to fix the defect #35134                                             |
-- |                                      removed the TRIM                                                                  |
-- |     16.0     30-Jul-2015 Arun G      Made changes to fix RCC AOPS                                                      |
-- |                                      defect 35323                                                                      |
-- |     17.0     06-Aug-2015 Arun G      Made changes to default AOPS ref as                                               |
-- |                                      Oracle Order number for AOPS RCC Orders                                           |
-- |     18.0     07-Aug-2015 Arun G      Made changes to fix the line type issue                                           |
-- |                                      for RCC AOPS orders # 1604                                                        |                                                     
-- |     19.0     10-Aug-2015 Arun G      Made changes to add new order types                                               |
-- |                                      for RCC AOPS .                                                                    |
-- |     20.0     18-Aug-2015 Saritha M   Made changes to include customer validation                                       |
-- |                                      for line level transation derivation fix the                                      | 
-- |                                      defect 34951                                                                      |
-- |     21.0     21-Sep-2015 Arun G      Made changes to capture the line level taxes                                      |
-- |                                      for EDI Customer Defect 35944                                                     |
-- |     22.0     11-OCT-2015 Arun G      Made changes to fix the line comments issue                                       |
-- |                                      defect 36124                                                                      |
-- |     23.0     12-Oct-2015 Arun G      Made changes to process tax refunds/cash back orders                              |
-- |                                      for RCC orders .Defect 36081                                                      |
-- |     24.0     30-Oct-2015 Arun G      Made changes to fix the comments issue Defect 36286                               |
---|     25.0     07-Jan-2016 Anoop Salim Made changes to introduce new procedure to capture line level tax Defect 36885    |
-- |     26.0     18-Feb-2016  Arun G     Made changes for Master Pass project Defect 37172                                 |
-- |     27.0     11-Apr-2016  Arun G     Made changes to fix the defect 2119 - masterpass                                  |
-- |     28.0     06-May-2016  Arun G     Made changes for Kitting Project defect 37676                                     |
-- |     29.0     13-JUNE-2017 Arun G     Made Changes for Validation failed for Shipping Method Defect# 41999              |
-- |     30.0     28-JUL-2017  Venkata B  Made Changes for Biz Ops Project and HVOP Kit Orders Issue Fix                    |
-- |     40.0     18-JAN-2018  Arun G     Made changes for TECHZONE project to derive the Order type Defect#44139           | 
-- |     41.0     14-NOV-2018  Arun G     Made changes for Bill Complete Project                                            |
-- |     42.0     19-MAY-2019  Arun G     Made changes for Service contract project  JIRA 90510                             |  
-- +========================================================================================================================+
    PROCEDURE process_current_order(
        p_order_tbl   IN  order_tbl_type,
        p_batch_size  IN  NUMBER);

    PROCEDURE process_header(
        p_order_rec      IN             order_rec_type,
        p_batch_id       IN             NUMBER,
        p_order_amt      IN OUT NOCOPY  NUMBER,
        p_order_source   IN OUT NOCOPY  VARCHAR2,
        x_return_status  OUT NOCOPY     VARCHAR2);

    PROCEDURE process_line(
        p_order_rec      IN             order_rec_type,
        p_batch_id       IN             NUMBER,
        x_return_status  OUT NOCOPY     VARCHAR2);

    PROCEDURE process_payment(
        p_order_rec      IN             order_rec_type,
        p_batch_id       IN             NUMBER,
        p_pay_amt        IN OUT NOCOPY  NUMBER,
        x_return_status  OUT NOCOPY     VARCHAR2);

    PROCEDURE process_tender(
        p_order_rec      IN             order_rec_type,
        p_batch_id       IN             NUMBER,
        x_return_status  OUT NOCOPY     VARCHAR2);

    PROCEDURE process_adjustments(
        p_order_rec      IN             order_rec_type,
        p_batch_id       IN             NUMBER,
        x_return_status  OUT NOCOPY     VARCHAR2);
-- Added procedure process_line_tax as per 36885 ver 25.0
    PROCEDURE process_line_tax(
        p_order_rec      IN             order_rec_type,
        p_batch_id       IN             NUMBER,
        x_return_status  OUT NOCOPY     VARCHAR2);
-- End of Procedure section as per defect 36885 ver 25.0
    PROCEDURE process_trailer(
        p_order_rec  IN  order_rec_type);

    PROCEDURE set_msg_context(
        p_entity_code   IN  VARCHAR2,
        p_warning_flag  IN  BOOLEAN DEFAULT FALSE,
        p_line_ref      IN  VARCHAR2 DEFAULT NULL);

    PROCEDURE insert_data;

    PROCEDURE clear_table_memory;

    PROCEDURE insert_mismatch_amount_msgs;

    FUNCTION get_serial_no_for_atr(
        p_serial_no     VARCHAR2,
        p_order_number  VARCHAR2,
        p_ordered_date  DATE)
        RETURN NUMBER;

    FUNCTION get_mps_retail(
        p_serial_no     VARCHAR2,
        p_order_number  VARCHAR2,
        p_item          VARCHAR2)
        RETURN NUMBER;

    PROCEDURE get_return_attributes(
        p_ref_order_number  IN             VARCHAR2,
        p_ref_line          IN             VARCHAR2,
        p_ref_item_id       IN             NUMBER,
        p_sold_to_org_id    IN             NUMBER,
        x_header_id         OUT NOCOPY     NUMBER,
        x_line_id           OUT NOCOPY     NUMBER,
        x_orig_sell_price   OUT NOCOPY     NUMBER,
        x_orig_ord_qty      OUT NOCOPY     NUMBER);

    PROCEDURE set_header_error(
        p_header_index  IN  BINARY_INTEGER);

    PROCEDURE process_deposits(
        p_hdr_idx  IN  BINARY_INTEGER);

    PROCEDURE set_header_id;

    PROCEDURE load_org_details(
        p_org_no  IN  VARCHAR2);

    PROCEDURE create_tax_refund_line(
        p_hdr_idx    IN  BINARY_INTEGER,
        p_order_rec  IN  order_rec_type);

    PROCEDURE get_return_header(
        p_ref_order_number  IN             VARCHAR2,
        p_sold_to_org_id    IN             NUMBER,
        x_header_id         OUT NOCOPY     NUMBER);

    PROCEDURE create_cashback_line(
        p_hdr_idx  IN  BINARY_INTEGER,
        p_amount   IN  NUMBER);

    PROCEDURE validate_item_warehouse(
        p_hdr_idx      IN  BINARY_INTEGER,
        p_line_idx     IN  BINARY_INTEGER,
        p_nonsku_flag  IN  VARCHAR2 DEFAULT 'N',
        p_item         IN  VARCHAR2);

    PROCEDURE clear_bad_orders(
        p_error_entity           IN  VARCHAR2,
        p_orig_sys_document_ref  IN  VARCHAR2);

    PROCEDURE write_to_file(
        p_order_tbl  IN  order_tbl_type);

    FUNCTION get_org_code(
        p_org_id  IN  NUMBER)
        RETURN VARCHAR2;

    PROCEDURE get_owner_table_id(
        p_orig_system            IN             VARCHAR2,
        p_orig_system_reference  IN             VARCHAR2,
        p_owner_table            IN             VARCHAR2,
        x_owner_table_id         OUT NOCOPY     NUMBER,
        x_return_status          OUT NOCOPY     VARCHAR2);

    -- Modified for R12
    PROCEDURE get_secure_card_number(
        p_cc_number            IN      VARCHAR2,
        x_cc_number_encrypted  OUT     VARCHAR2,
        x_identifier           OUT     VARCHAR2,
        x_error_message        OUT     VARCHAR2)
    IS
    BEGIN
        --RETURN (iby_cc_security_pub.secure_card_number( FND_API.G_TRUE, p_cc_number ,'N' )); -- Commented for 12i Retro Fit by NB
        x_error_message := NULL;
        DBMS_SESSION.set_context(namespace      => 'XX_OM_SAS_CONTEXT',
                                 ATTRIBUTE      => 'TYPE',
                                 VALUE          => 'EBS');
        xx_od_security_key_pkg.encrypt_outlabel(p_module             => 'AJB',
                                                p_key_label          => NULL,
                                                p_algorithm          => '3DES',
                                                p_decrypted_val      => p_cc_number,
                                                x_encrypted_val      => x_cc_number_encrypted,
                                                x_error_message      => x_error_message,
                                                x_key_label          => x_identifier);
    END get_secure_card_number;

-- +===================================================================+
-- | Name  : DELETE_HEADER_REC                                         |
-- | Description      : This Procedure will clear the global table for |
-- |                    BAD Order                                      |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE delete_header_rec(
        p_idx  IN  BINARY_INTEGER)
    IS
    BEGIN
        g_header_rec.orig_sys_document_ref.DELETE(p_idx);
        g_header_rec.order_source_id.DELETE(p_idx);
        g_header_rec.change_sequence.DELETE(p_idx);
        g_header_rec.order_category.DELETE(p_idx);
        g_header_rec.org_id.DELETE(p_idx);
        g_header_rec.ordered_date.DELETE(p_idx);
        g_header_rec.order_type_id.DELETE(p_idx);
        g_header_rec.legacy_order_type.DELETE(p_idx);
        g_header_rec.price_list_id.DELETE(p_idx);
        g_header_rec.transactional_curr_code.DELETE(p_idx);
        g_header_rec.salesrep_id.DELETE(p_idx);
        g_header_rec.sales_channel_code.DELETE(p_idx);
        g_header_rec.shipping_method_code.DELETE(p_idx);
        g_header_rec.shipping_instructions.DELETE(p_idx);
        g_header_rec.customer_po_number.DELETE(p_idx);
        g_header_rec.sold_to_org_id.DELETE(p_idx);
        g_header_rec.ship_from_org_id.DELETE(p_idx);
        g_header_rec.invoice_to_org_id.DELETE(p_idx);
        g_header_rec.sold_to_contact_id.DELETE(p_idx);
        g_header_rec.ship_to_org_id.DELETE(p_idx);
        g_header_rec.ship_to_org.DELETE(p_idx);
        g_header_rec.ship_from_org.DELETE(p_idx);
        g_header_rec.sold_to_org.DELETE(p_idx);
        g_header_rec.invoice_to_org.DELETE(p_idx);
        g_header_rec.drop_ship_flag.DELETE(p_idx);
        g_header_rec.booked_flag.DELETE(p_idx);
        g_header_rec.operation_code.DELETE(p_idx);
        g_header_rec.error_flag.DELETE(p_idx);
        g_header_rec.ready_flag.DELETE(p_idx);
        g_header_rec.payment_term_id.DELETE(p_idx);
        g_header_rec.tax_value.DELETE(p_idx);
        g_header_rec.customer_po_line_num.DELETE(p_idx);
        g_header_rec.category_code.DELETE(p_idx);
        g_header_rec.ship_date.DELETE(p_idx);
        g_header_rec.return_reason.DELETE(p_idx);
        g_header_rec.pst_tax_value.DELETE(p_idx);
        g_header_rec.return_orig_sys_doc_ref.DELETE(p_idx);
        g_header_rec.created_by.DELETE(p_idx);
        g_header_rec.creation_date.DELETE(p_idx);
        g_header_rec.last_update_date.DELETE(p_idx);
        g_header_rec.last_updated_by.DELETE(p_idx);
        g_header_rec.batch_id.DELETE(p_idx);
        g_header_rec.request_id.DELETE(p_idx);
        /* Header Attributes  */
        g_header_rec.created_by_store_id.DELETE(p_idx);
        g_header_rec.paid_at_store_id.DELETE(p_idx);
        g_header_rec.paid_at_store_no.DELETE(p_idx);
        g_header_rec.spc_card_number.DELETE(p_idx);
        g_header_rec.placement_method_code.DELETE(p_idx);
        g_header_rec.advantage_card_number.DELETE(p_idx);
        g_header_rec.created_by_id.DELETE(p_idx);
        g_header_rec.delivery_code.DELETE(p_idx);
        g_header_rec.tran_number.DELETE(p_idx);
        g_header_rec.aops_geo_code.DELETE(p_idx);
        g_header_rec.tax_exempt_amount.DELETE(p_idx);
        g_header_rec.delivery_method.DELETE(p_idx);
        g_header_rec.release_number.DELETE(p_idx);
        g_header_rec.cust_dept_no.DELETE(p_idx);
        g_header_rec.cust_dept_description.DELETE(p_idx);
        g_header_rec.desk_top_no.DELETE(p_idx);
        g_header_rec.comments.DELETE(p_idx);
        g_header_rec.start_line_index.DELETE(p_idx);
        g_header_rec.accounting_rule_id.DELETE(p_idx);
        g_header_rec.invoicing_rule_id.DELETE(p_idx);
        g_header_rec.sold_to_contact.DELETE(p_idx);
        g_header_rec.header_id.DELETE(p_idx);
        g_header_rec.org_order_creation_date.DELETE(p_idx);
        g_header_rec.return_act_cat_code.DELETE(p_idx);
        g_header_rec.salesrep.DELETE(p_idx);
        g_header_rec.order_source.DELETE(p_idx);
        g_header_rec.sales_channel.DELETE(p_idx);
        g_header_rec.shipping_method.DELETE(p_idx);
        g_header_rec.deposit_amount.DELETE(p_idx);
        g_header_rec.gift_flag.DELETE(p_idx);
        g_header_rec.sas_sale_date.DELETE(p_idx);
        g_header_rec.legacy_cust_name.DELETE(p_idx);
        g_header_rec.inv_loc_no.DELETE(p_idx);
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
        g_header_rec.ship_to_name.DELETE(p_idx);
        g_header_rec.bill_to_name.DELETE(p_idx);
        g_header_rec.cust_contact_name.DELETE(p_idx);
        g_header_rec.cust_pref_phone.DELETE(p_idx);
        g_header_rec.cust_pref_phextn.DELETE(p_idx);
        g_header_rec.cust_pref_email.DELETE(p_idx);
        g_header_rec.deposit_hold_flag.DELETE(p_idx);
        g_header_rec.ineligible_for_hvop.DELETE(p_idx);
        g_header_rec.tax_rate.DELETE(p_idx);
        g_header_rec.order_number.DELETE(p_idx);
        g_header_rec.is_reference_return.DELETE(p_idx);
        g_header_rec.order_total.DELETE(p_idx);
        g_header_rec.commisionable_ind.DELETE(p_idx);
        g_header_rec.order_action_code.DELETE(p_idx);
        g_header_rec.order_start_time.DELETE(p_idx);
        g_header_rec.order_end_time.DELETE(p_idx);
        g_header_rec.order_taxable_cd.DELETE(p_idx);
        g_header_rec.override_delivery_chg_cd.DELETE(p_idx);
        g_header_rec.price_cd.DELETE(p_idx);
        g_header_rec.ship_to_geocode.DELETE(p_idx);
        g_header_rec.sr_number.DELETE(p_idx);
        g_header_rec.atr_order_flag.DELETE(p_idx);                                                  --Added for Rel12.5
        g_header_rec.device_serial_num.DELETE(p_idx);                                              -- Added for Rel13.1
        g_header_rec.app_id.DELETE(p_idx);                                                         -- Added for Rel13.3
        g_header_rec.order_source_cd.DELETE(p_idx);                                                           -- CR 623
        g_header_rec.rcc_transaction.DELETE(p_idx);                                                -- added for rcc
        g_header_rec.external_transaction_number.DELETE(p_idx);					   -- Added for Amz mpl     
        g_header_rec.freight_tax_amount.DELETE(p_idx);                                             -- added for line level tax   
        g_header_rec.freight_tax_rate.DELETE(p_idx);                                               -- added for line level tax
        g_header_rec.bill_level.DELETE(p_idx);                                                     -- added for kitting
        g_header_rec.bill_override_flag.DELETE(p_idx);                                             -- added for kitting
	g_header_rec.appid_ordertype_value.DELETE(p_idx);                                          -- added for defect#44139 
	g_header_rec.appid_linetype_value.DELETE(p_idx);                                           -- added for defect#44139
	g_header_rec.appid_base_ordertype.DELETE(p_idx);                                           -- added for defect#44139
        g_header_rec.bill_complete_flag.DELETE(p_idx);                                             -- added for Billcomplete 
        g_header_rec.parent_order_number.DELETE(p_idx);                                            -- added for BillComplete
        g_header_rec.cost_center_split.DELETE(p_idx);                                              -- added for BillCompelte

    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed in deleting BAD header  record :'
                              || p_idx
                              || ' : '
                              || SUBSTR(SQLERRM,
                                        1,
                                        80));
    END delete_header_rec;

-- +===================================================================+
-- | Name  : DELETE_LINE_REC                                           |
-- | Description      : This Procedure will clear the global table for |
-- |                    BAD Line or bad order                          |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE delete_line_rec(
        p_idx  IN  BINARY_INTEGER)
    IS
    BEGIN
        g_line_rec.orig_sys_document_ref.DELETE(p_idx);
        g_line_rec.order_source_id.DELETE(p_idx);
        g_line_rec.change_sequence.DELETE(p_idx);
        g_line_rec.org_id.DELETE(p_idx);
        g_line_rec.orig_sys_line_ref.DELETE(p_idx);
        g_line_rec.ordered_date.DELETE(p_idx);
        g_line_rec.line_number.DELETE(p_idx);
        g_line_rec.line_type_id.DELETE(p_idx);
        g_line_rec.inventory_item_id.DELETE(p_idx);
        g_line_rec.inventory_item.DELETE(p_idx);
        g_line_rec.source_type_code.DELETE(p_idx);
        g_line_rec.schedule_ship_date.DELETE(p_idx);
        g_line_rec.actual_ship_date.DELETE(p_idx);
        g_line_rec.schedule_arrival_date.DELETE(p_idx);
        g_line_rec.actual_arrival_date.DELETE(p_idx);
        g_line_rec.ordered_quantity.DELETE(p_idx);
        g_line_rec.order_quantity_uom.DELETE(p_idx);
        g_line_rec.shipped_quantity.DELETE(p_idx);
        g_line_rec.sold_to_org_id.DELETE(p_idx);
        g_line_rec.ship_from_org_id.DELETE(p_idx);
        g_line_rec.ship_to_org_id.DELETE(p_idx);
        g_line_rec.invoice_to_org_id.DELETE(p_idx);
        g_line_rec.ship_to_contact_id.DELETE(p_idx);
        g_line_rec.sold_to_contact_id.DELETE(p_idx);
        g_line_rec.invoice_to_contact_id.DELETE(p_idx);
        g_line_rec.drop_ship_flag.DELETE(p_idx);
        g_line_rec.price_list_id.DELETE(p_idx);
        g_line_rec.unit_list_price.DELETE(p_idx);
        g_line_rec.unit_selling_price.DELETE(p_idx);
        g_line_rec.calculate_price_flag.DELETE(p_idx);
        g_line_rec.tax_code.DELETE(p_idx);
        g_line_rec.tax_date.DELETE(p_idx);
        g_line_rec.tax_value.DELETE(p_idx);
       -- g_line_rec.shipping_method_code.DELETE(p_idx);
        g_line_rec.salesrep_id.DELETE(p_idx);
        g_line_rec.return_reason_code.DELETE(p_idx);
        g_line_rec.customer_po_number.DELETE(p_idx);
        g_line_rec.operation_code.DELETE(p_idx);
        g_line_rec.error_flag.DELETE(p_idx);
        g_line_rec.shipping_instructions.DELETE(p_idx);
        g_line_rec.return_context.DELETE(p_idx);
        g_line_rec.return_attribute1.DELETE(p_idx);
        g_line_rec.return_attribute2.DELETE(p_idx);
        g_line_rec.customer_item_name.DELETE(p_idx);
        g_line_rec.customer_item_id.DELETE(p_idx);
        g_line_rec.customer_item_id_type.DELETE(p_idx);
        g_line_rec.line_category_code.DELETE(p_idx);
        g_line_rec.tot_tax_value.DELETE(p_idx);
        g_line_rec.customer_line_number.DELETE(p_idx);
        g_line_rec.created_by.DELETE(p_idx);
        g_line_rec.creation_date.DELETE(p_idx);
        g_line_rec.last_update_date.DELETE(p_idx);
        g_line_rec.last_updated_by.DELETE(p_idx);
        g_line_rec.request_id.DELETE(p_idx);
        g_line_rec.batch_id.DELETE(p_idx);
        g_line_rec.legacy_list_price.DELETE(p_idx);
        g_line_rec.vendor_product_code.DELETE(p_idx);
        g_line_rec.contract_details.DELETE(p_idx);
        g_line_rec.item_comments.DELETE(p_idx);
        g_line_rec.line_comments.DELETE(p_idx);
        g_line_rec.taxable_flag.DELETE(p_idx);
        g_line_rec.sku_dept.DELETE(p_idx);
        g_line_rec.item_source.DELETE(p_idx);
        g_line_rec.average_cost.DELETE(p_idx);
        g_line_rec.po_cost.DELETE(p_idx);
        g_line_rec.canada_pst.DELETE(p_idx);
        g_line_rec.return_act_cat_code.DELETE(p_idx);
        g_line_rec.return_reference_no.DELETE(p_idx);
        g_line_rec.back_ordered_qty.DELETE(p_idx);
        g_line_rec.return_ref_line_no.DELETE(p_idx);
        g_line_rec.org_order_creation_date.DELETE(p_idx);
        g_line_rec.wholesaler_item.DELETE(p_idx);
        g_line_rec.header_id.DELETE(p_idx);
        g_line_rec.line_id.DELETE(p_idx);
        g_line_rec.payment_term_id.DELETE(p_idx);
        g_line_rec.inventory_item.DELETE(p_idx);
        g_line_rec.schedule_status_code.DELETE(p_idx);
        g_line_rec.user_item_description.DELETE(p_idx);
        g_line_rec.config_code.DELETE(p_idx);
        g_line_rec.ext_top_model_line_id.DELETE(p_idx);
        g_line_rec.ext_link_to_line_id.DELETE(p_idx);
        g_line_rec.sas_sale_date.DELETE(p_idx);
        g_line_rec.aops_ship_date.DELETE(p_idx);
        g_line_rec.calc_arrival_date.DELETE(p_idx);
        g_line_rec.ret_ref_header_id.DELETE(p_idx);
        g_line_rec.ret_ref_line_id.DELETE(p_idx);
        g_line_rec.release_number.DELETE(p_idx);
        g_line_rec.cust_dept_no.DELETE(p_idx);
        g_line_rec.cust_dept_description.DELETE(p_idx);
        g_line_rec.desk_top_no.DELETE(p_idx);
        g_line_rec.tax_exempt_flag.DELETE(p_idx);
        g_line_rec.tax_exempt_number.DELETE(p_idx);
        g_line_rec.tax_exempt_reason.DELETE(p_idx);
        g_line_rec.gsa_flag.DELETE(p_idx);                                                                --Added by NB
        g_line_rec.consignment_bank_code.DELETE(p_idx);
        g_line_rec.waca_item_ctr_num.DELETE(p_idx);
        g_line_rec.orig_selling_price.DELETE(p_idx);
        g_line_rec.price_cd.DELETE(p_idx);
        g_line_rec.price_change_reason_cd.DELETE(p_idx);
        g_line_rec.price_prefix_cd.DELETE(p_idx);
        g_line_rec.commisionable_ind.DELETE(p_idx);
        g_line_rec.unit_orig_selling_price.DELETE(p_idx);
        g_line_rec.mps_toner_retail.DELETE(p_idx);
        g_line_rec.core_type_indicator.DELETE(p_idx);
        g_line_rec.upc_code.DELETE(p_idx);
        g_line_rec.price_type.DELETE(p_idx);
        g_line_rec.external_sku.DELETE(p_idx);
        g_line_rec.line_tax_amount.DELETE(p_idx);
        g_line_rec.line_tax_rate.DELETE(p_idx);
        g_line_rec.kit_sku.DELETE(p_idx);
        g_line_rec.kit_qty.DELETE(p_idx);
        g_line_rec.kit_vpc.DELETE(p_idx);
        g_line_rec.kit_dept.DELETE(p_idx);
        g_line_rec.kit_seqnum.DELETE(p_idx);
        g_line_rec.service_end_date.DELETE(p_idx);

    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed in deleting BAD Line record :'
                              || p_idx
                              || ' : '
                              || SUBSTR(SQLERRM,
                                        1,
                                        80));
    END delete_line_rec;

-- +===================================================================+
-- | Name  : DELETE_ADJ_REC                                            |
-- | Description      : This Procedure will clear the global table for |
-- |                    BAD Line                                       |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE delete_adj_rec(
        p_idx  IN  BINARY_INTEGER)
    IS
    BEGIN
        /* Discount Record */
        g_line_adj_rec.orig_sys_document_ref.DELETE(p_idx);
        g_line_adj_rec.order_source_id.DELETE(p_idx);
        g_line_adj_rec.org_id.DELETE(p_idx);
        g_line_adj_rec.orig_sys_line_ref.DELETE(p_idx);
        g_line_adj_rec.orig_sys_discount_ref.DELETE(p_idx);
        g_line_adj_rec.sold_to_org_id.DELETE(p_idx);
        g_line_adj_rec.change_sequence.DELETE(p_idx);
        g_line_adj_rec.automatic_flag.DELETE(p_idx);
        g_line_adj_rec.list_header_id.DELETE(p_idx);
        g_line_adj_rec.list_line_id.DELETE(p_idx);
        g_line_adj_rec.list_line_type_code.DELETE(p_idx);
        g_line_adj_rec.applied_flag.DELETE(p_idx);
        g_line_adj_rec.operand.DELETE(p_idx);
        g_line_adj_rec.arithmetic_operator.DELETE(p_idx);
        g_line_adj_rec.pricing_phase_id.DELETE(p_idx);
        g_line_adj_rec.adjusted_amount.DELETE(p_idx);
        g_line_adj_rec.inc_in_sales_performance.DELETE(p_idx);
        g_line_adj_rec.operation_code.DELETE(p_idx);
        g_line_adj_rec.error_flag.DELETE(p_idx);
        g_line_adj_rec.request_id.DELETE(p_idx);
        g_line_adj_rec.CONTEXT.DELETE(p_idx);
        g_line_adj_rec.attribute6.DELETE(p_idx);
        g_line_adj_rec.attribute7.DELETE(p_idx);
        g_line_adj_rec.attribute8.DELETE(p_idx);
        g_line_adj_rec.attribute9.DELETE(p_idx);
        g_line_adj_rec.attribute10.DELETE(p_idx);
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed in deleting BAD ADJ record :'
                              || p_idx
                              || ' : '
                              || SUBSTR(SQLERRM,
                                        1,
                                        80));
    END delete_adj_rec;

-- +===================================================================+
-- | Name  : DELETE_PAYMENT_REC                                        |
-- | Description      : This Procedure will clear the global table for |
-- |                    BAD Payment record  or bad order               |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE delete_payment_rec(
        p_idx  IN  BINARY_INTEGER)
    IS
    BEGIN
        /* payment record */
        g_payment_rec.orig_sys_document_ref.DELETE(p_idx);
        g_payment_rec.order_source_id.DELETE(p_idx);
        g_payment_rec.orig_sys_payment_ref.DELETE(p_idx);
        g_payment_rec.org_id.DELETE(p_idx);
        g_payment_rec.payment_type_code.DELETE(p_idx);
        g_payment_rec.payment_collection_event.DELETE(p_idx);
        g_payment_rec.prepaid_amount.DELETE(p_idx);
        g_payment_rec.credit_card_number.DELETE(p_idx);
        g_payment_rec.credit_card_holder_name.DELETE(p_idx);
        g_payment_rec.credit_card_expiration_date.DELETE(p_idx);
        g_payment_rec.credit_card_code.DELETE(p_idx);
        g_payment_rec.credit_card_approval_code.DELETE(p_idx);
        g_payment_rec.credit_card_approval_date.DELETE(p_idx);
        g_payment_rec.check_number.DELETE(p_idx);
        g_payment_rec.payment_amount.DELETE(p_idx);
        g_payment_rec.operation_code.DELETE(p_idx);
        g_payment_rec.error_flag.DELETE(p_idx);
        g_payment_rec.receipt_method_id.DELETE(p_idx);
        g_payment_rec.payment_number.DELETE(p_idx);
        g_payment_rec.attribute6.DELETE(p_idx);
        g_payment_rec.attribute7.DELETE(p_idx);
        g_payment_rec.attribute8.DELETE(p_idx);
        g_payment_rec.attribute9.DELETE(p_idx);
        g_payment_rec.attribute10.DELETE(p_idx);
        g_payment_rec.sold_to_org_id.DELETE(p_idx);
        g_payment_rec.attribute11.DELETE(p_idx);
        g_payment_rec.attribute12.DELETE(p_idx);
        g_payment_rec.attribute13.DELETE(p_idx);
        g_payment_rec.attribute15.DELETE(p_idx);
        g_payment_rec.payment_set_id.DELETE(p_idx);
        g_payment_rec.attribute3.DELETE(p_idx);
        g_payment_rec.attribute14.DELETE(p_idx);
        g_payment_rec.attribute2.DELETE(p_idx);

    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed in deleting BAD PAYMENT record :'
                              || p_idx
                              || ' : '
                              || SUBSTR(SQLERRM,
                                        1,
                                        80));
    END delete_payment_rec;

-- +===================================================================+
-- | Name  : DELETE_RET_TENDER_REC                                     |
-- | Description  : This Procedure will clear the global table for BAD |
-- |                return tender record or bad order                  |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE delete_ret_tender_rec(
        p_idx  IN  BINARY_INTEGER)
    IS
    BEGIN
        /* tender record */
        g_return_tender_rec.orig_sys_document_ref.DELETE(p_idx);
        g_return_tender_rec.orig_sys_payment_ref.DELETE(p_idx);
        g_return_tender_rec.order_source_id.DELETE(p_idx);
        g_return_tender_rec.payment_number.DELETE(p_idx);
        g_return_tender_rec.payment_type_code.DELETE(p_idx);
        g_return_tender_rec.credit_card_code.DELETE(p_idx);
        g_return_tender_rec.credit_card_number.DELETE(p_idx);
        g_return_tender_rec.credit_card_holder_name.DELETE(p_idx);
        g_return_tender_rec.credit_card_expiration_date.DELETE(p_idx);
        g_return_tender_rec.credit_amount.DELETE(p_idx);
        g_return_tender_rec.request_id.DELETE(p_idx);
        g_return_tender_rec.sold_to_org_id.DELETE(p_idx);
        g_return_tender_rec.cc_auth_manual.DELETE(p_idx);
        g_return_tender_rec.merchant_nbr.DELETE(p_idx);
        g_return_tender_rec.cc_auth_ps2000.DELETE(p_idx);
        g_return_tender_rec.allied_ind.DELETE(p_idx);
        g_return_tender_rec.sold_to_org_id.DELETE(p_idx);
        g_return_tender_rec.receipt_method_id.DELETE(p_idx);
        g_return_tender_rec.cc_mask_number.DELETE(p_idx);
        g_return_tender_rec.od_payment_type.DELETE(p_idx);
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed in deleting BAD Return Tender record :'
                              || p_idx
                              || ' : '
                              || SUBSTR(SQLERRM,
                                        1,
                                        80));
    END delete_ret_tender_rec;
-- +===================================================================+
-- | Name  : DELETE_TENDER_REC                                         |
-- | Description  : This Procedure will clear the global table for BAD |
-- |                return record or bad order                         |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE delete_tender_rec(
        p_idx  IN  BINARY_INTEGER)
    IS
    BEGIN
        /* tender record */
        g_tender_rec.orig_sys_document_ref.DELETE(p_idx);
        g_tender_rec.orig_sys_payment_ref.DELETE(p_idx);
        g_tender_rec.order_source_id.DELETE(p_idx);
        g_tender_rec.routing_line1.DELETE(p_idx);
        g_tender_rec.routing_line2.DELETE(p_idx);
        g_tender_rec.routing_line3.DELETE(p_idx);
        g_tender_rec.routing_line4.DELETE(p_idx);
        g_tender_rec.batch_id.DELETE(p_idx);

   EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed in deleting BAD Tender record :'
                              || p_idx
                              || ' : '
                              || SUBSTR(SQLERRM,
                                        1,
                                        80));
    END delete_tender_rec;

-- Master Concurrent Program
    PROCEDURE upload_data(
        x_retcode      OUT NOCOPY     NUMBER,
        x_errbuf       OUT NOCOPY     VARCHAR2,
        p_file_name    IN             VARCHAR2,
        p_debug_level  IN             NUMBER DEFAULT 0,
        p_batch_size   IN             NUMBER DEFAULT 1200)
    IS
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
        lc_file_name          VARCHAR2(100);
        lc_short_name         VARCHAR2(200);
        ln_request_id         NUMBER        := 0;
        lb_wait               BOOLEAN;
        lc_phase              VARCHAR2(100);
        lc_status             VARCHAR2(100);
        lc_devpha             VARCHAR2(100);
        lc_devsta             VARCHAR2(100);
        lc_mesg               VARCHAR2(100);
        lc_o_unit             VARCHAR2(50);
        lc_fname              VARCHAR2(100);
        lc_error_flag         VARCHAR2(1);
        lc_return_status      VARCHAR2(1);
        lc_file_date          VARCHAR2(20);

-- Cursor to fetch file history
        CURSOR c_file_validate(
            p_fname  VARCHAR2)
        IS
            SELECT file_name,
                   error_flag
            FROM   xx_om_sacct_file_history
            WHERE  file_name = p_fname;

        -- For the Parent Wait for child to finish
        l_req_data            VARCHAR2(10);
        l_req_data_counter    NUMBER;
        ln_child_req_counter  NUMBER;
        l_count               NUMBER;
    BEGIN
        x_retcode := 0;
        process_child(p_file_name          => p_file_name,
                      p_debug_level        => p_debug_level,
                      p_batch_size         => p_batch_size,
                      x_return_status      => lc_return_status);

        IF lc_return_status <> fnd_api.g_ret_sts_success
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              'Process Child returned error');
            RAISE fnd_api.g_exc_error;
        END IF;

        fnd_file.put_line(fnd_file.LOG,
                          'Process Child was success');
        x_retcode := 0;
    EXCEPTION
        WHEN fnd_api.g_exc_error
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              'Process Child raised error');
            x_retcode := 2;
            x_errbuf := 'Please check the log file for error messages';
            RAISE fnd_api.g_exc_error;
        WHEN OTHERS
        THEN
            x_retcode := 2;
            fnd_file.put_line(fnd_file.output,
                                 'Unexpected error '
                              || SUBSTR(SQLERRM,
                                        1,
                                        200));
            fnd_file.put_line(fnd_file.output,
                              '');
            x_errbuf := 'Please check the log file for error messages';
            RAISE fnd_api.g_exc_error;
    END upload_data;

    PROCEDURE process_child(
        p_file_name      IN             VARCHAR2,
        p_debug_level    IN             NUMBER,
        p_batch_size     IN             NUMBER,
        x_return_status  OUT NOCOPY     VARCHAR2)
    IS
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
        lc_input_file_handle           UTL_FILE.file_type;
        lc_input_file_path             VARCHAR2(250);
        lc_curr_line                   VARCHAR2(1340);
        lc_return_status               VARCHAR2(100);
        ln_debug_level                 NUMBER;
        lc_errbuf                      VARCHAR2(2000);
        ln_retcode                     NUMBER;
        lc_file_path                   VARCHAR2(100)                         := fnd_profile.VALUE('XX_OM_SAS_FILE_DIR');
        lb_has_records                 BOOLEAN;
        i                              BINARY_INTEGER;
        lc_orig_sys_document_ref       oe_headers_iface_all.orig_sys_document_ref%TYPE;
        lc_curr_orig_sys_document_ref  oe_headers_iface_all.orig_sys_document_ref%TYPE;
        lc_record_type                 VARCHAR2(10);
        lc_record_line_type            VARCHAR2(10);
        l_order_tbl                    order_tbl_type;
        lc_error_flag                  VARCHAR2(1)                                       := 'N';
        lc_filename                    VARCHAR2(100);
        ln_start_time                  NUMBER;
        ln_end_time                    NUMBER;
        j                              BINARY_INTEGER;
        lb_at_trailer                  BOOLEAN                                           := FALSE;
        lc_arch_path                   VARCHAR2(100);
        ln_master_request_id           NUMBER;
        lb_read_error                  BOOLEAN                                           := FALSE;
        lc_rec_21_exists               VARCHAR2(1) := NULL;

    BEGIN
        x_return_status := 'S';
-- Initialize the fnd_message stack
        fnd_msg_pub.initialize;
        oe_bulk_msg_pub.initialize;
        g_file_name := p_file_name;
-- Initialize the Global
        g_mode := 'SAS_IMPORT';
        g_error_count := 0;
        xx_om_hvop_util_pkg.g_use_test_cc := NVL(fnd_profile.VALUE('XX_OM_USE_TEST_CC'),
                                                 'N');

-- Set the Debug level in oe_debug_pub
        IF NVL(p_debug_level,
               -1) >= 0
        THEN
            fnd_profile.put('ONT_DEBUG_LEVEL',
                            p_debug_level);
            oe_debug_pub.g_debug_level := p_debug_level;
            lc_filename := oe_debug_pub.set_debug_mode('CONC');
        END IF;

        ln_debug_level := oe_debug_pub.g_debug_level;

        SELECT hsecs
        INTO   ln_start_time
        FROM   v$timer;

        BEGIN
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Entering Process_Child the debug level is :'
                                 || ln_debug_level);
            END IF;

            fnd_profile.get('CONC_REQUEST_ID',
                            g_request_id);
            fnd_file.put_line(fnd_file.LOG,
                              'Start Procedure ');
            fnd_file.put_line(fnd_file.LOG,
                                 'File Path : '
                              || lc_file_path);
            fnd_file.put_line(fnd_file.LOG,
                                 'File Name : '
                              || p_file_name);
            -- Open the file
            lc_input_file_handle := UTL_FILE.fopen(lc_file_path,
                                                   p_file_name,
                                                   'R',
                                                   1000);
        EXCEPTION
            WHEN UTL_FILE.invalid_path
            THEN
                oe_debug_pub.ADD(   'Invalid Path: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'Invalid file Path: '
                                  || SQLERRM);
                RAISE fnd_api.g_exc_error;
            WHEN UTL_FILE.invalid_mode
            THEN
                oe_debug_pub.ADD(   'Invalid Mode: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'Invalid Mode: '
                                  || SQLERRM);
                RAISE fnd_api.g_exc_error;
            WHEN UTL_FILE.invalid_filehandle
            THEN
                oe_debug_pub.ADD(   'Invalid file handle: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'Invalid file handle: '
                                  || SQLERRM);
                RAISE fnd_api.g_exc_error;
            WHEN UTL_FILE.invalid_operation
            THEN
                oe_debug_pub.ADD(   'Invalid operation: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'File does not exist: '
                                  || SQLERRM);
                xx_om_hvop_util_pkg.send_notification('HVOP: File MIssing',
                                                         'SAS trigger file is listing the HVOP file :'
                                                      || p_file_name
                                                      || ' which can not be found under '
                                                      || lc_file_path);
                RAISE fnd_api.g_exc_error;
            WHEN UTL_FILE.read_error
            THEN
                oe_debug_pub.ADD(   'Read Error: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'Read Error: '
                                  || SQLERRM);
                RAISE fnd_api.g_exc_error;
            WHEN UTL_FILE.internal_error
            THEN
                oe_debug_pub.ADD(   'Internal Error: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'Internal Error: '
                                  || SQLERRM);
                RAISE fnd_api.g_exc_error;
            WHEN NO_DATA_FOUND
            THEN
                oe_debug_pub.ADD(   'No data found: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'Empty File: '
                                  || SQLERRM);
                RAISE fnd_api.g_exc_error;
            WHEN VALUE_ERROR
            THEN
                oe_debug_pub.ADD(   'Value Error: '
                                 || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                     'Value Error: '
                                  || SQLERRM);
                RAISE fnd_api.g_exc_error;
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  SQLERRM);
                UTL_FILE.fclose(lc_input_file_handle);
                RAISE fnd_api.g_exc_error;
        END;

        lb_has_records := TRUE;
        i := 0;

-- Check if the file has been run before
        SELECT COUNT(file_name)
        INTO   g_file_run_count
        FROM   xx_om_sacct_file_history
        WHERE  file_name = p_file_name;

-- Set Batch Counter Global
        g_batch_counter := 0;

-- get immediate payment terms id - CR 623
        BEGIN
            SELECT term_id
            INTO   g_im_pay_term_id
            FROM   ra_terms_vl
            WHERE  NAME = 'IMMEDIATE';
        EXCEPTION
            WHEN OTHERS
            THEN
                g_im_pay_term_id := NULL;
                fnd_file.put_line(fnd_file.LOG,
                                  'IMMEDIATE payment term not found in RA_TERMS_VL');
        END;

-- Get Term_id for deposits - 623
        BEGIN
            SELECT term_id
            INTO   g_deposit_term_id
            FROM   ra_terms_vl
            WHERE  NAME = 'SA_DEPOSIT';
        EXCEPTION
            WHEN OTHERS
            THEN
                g_deposit_term_id := NULL;
        END;

        BEGIN
            -- Load LINE_ID SEQUENCE values into g_line_id global
            SELECT     oe_order_lines_s.NEXTVAL
            BULK COLLECT INTO g_line_id
            FROM       xx_om_hvop_seq_lock
            WHERE      ROWNUM <= 90000
            FOR UPDATE;

            -- Release the lock
            COMMIT;

            SELECT hsecs
            INTO   ln_end_time
            FROM   v$timer;

            fnd_file.put_line(fnd_file.LOG,
                                 'Time spent in Getting Line Id SEQ data is (sec) '
                              || (  (  ln_end_time
                                     - ln_start_time)
                                  / 100));
            -- Set the Counter for the global
            g_line_id_seq_ctr := 1;

            LOOP
                BEGIN
                    lc_curr_line := NULL;
                    /* UTL FILE READ START */
                    UTL_FILE.get_line(lc_input_file_handle,
                                      lc_curr_line);
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                          'NO MORE RECORDS TO READ');
                        lb_has_records := FALSE;

                        IF l_order_tbl.COUNT = 0
                        THEN
                            fnd_file.put_line(fnd_file.LOG,
                                              'THE FILE IS EMPTY, NO RECORDS');
                            RAISE fnd_api.g_exc_error;
                        END IF;
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'Error while reading'
                                          || SQLERRM);
                        lb_has_records := FALSE;

                        IF l_order_tbl.COUNT = 0
                        THEN
                            fnd_file.put_line(fnd_file.LOG,
                                              'THE FILE IS EMPTY NO RECORDS');
                        END IF;

                        RAISE fnd_api.g_exc_error;
                END;

                -- Always get the exact byte length in lc_curr_line to avoid reading new line characters
                lc_curr_line := SUBSTR(lc_curr_line,
                                       1,
                                       330);

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'My Line Is :'
                                     || lc_curr_line);
                END IF;

                lc_orig_sys_document_ref := TRIM(SUBSTR(lc_curr_line,
                                                        1,
                                                        20));

                IF lc_curr_orig_sys_document_ref IS NULL
                THEN
                    lc_curr_orig_sys_document_ref := lc_orig_sys_document_ref;
                END IF;

                -- IF Order has changed or we are at the last record of the file
                IF lc_curr_orig_sys_document_ref <> lc_orig_sys_document_ref OR NOT lb_has_records
                THEN
                    -- If at the trailer record
                    IF lb_at_trailer
                    THEN
                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD('We are at the trailer record');
                        END IF;

                        process_trailer(l_order_tbl(1));
                    ELSE
                        IF NOT lb_read_error
                        THEN
                            process_current_order(p_order_tbl       => l_order_tbl,
                                                  p_batch_size      => p_batch_size);
                        END IF;

                        oe_debug_pub.ADD('After processing current order :');
                    END IF;

                    l_order_tbl.DELETE;
                    lb_read_error := FALSE;
                    i := 0;

                    -- If reached the 500 count or last order then insert data into interface tables
                    IF g_header_rec.orig_sys_document_ref.COUNT >= 500 OR NOT lb_has_records
                    THEN
                        insert_data;
                        clear_table_memory;
                    END IF;
                END IF;

                lc_curr_orig_sys_document_ref := lc_orig_sys_document_ref;

                IF NOT lb_has_records
                THEN
                    -- nothing to process so exit the loop
                    EXIT;
                END IF;

                lc_record_type := SUBSTR(lc_curr_line,
                                         21,
                                         2);
                /* defect: 1744 reading line number for line comments */ --NB
                lc_record_line_type := SUBSTR(lc_curr_line,
                                              28,
                                              4);

                BEGIN
                    IF lc_record_type = '10'
                    THEN                                                                               -- header record
                        i :=   i
                             + 1;
                        l_order_tbl(i).record_type := lc_record_type;
                        l_order_tbl(i).file_line := lc_curr_line;

                        lc_rec_21_exists := 'N' ; -- AG 
                    ELSIF lc_record_type = '11'
                    THEN                                                                       -- Header comments record
                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD(   'The comments Rec is '
                                             || SUBSTR(lc_curr_line,
                                                       33,
                                                       298));
                        END IF;

                        l_order_tbl(i).file_line :=    l_order_tbl(i).file_line
                                                    || SUBSTR(lc_curr_line,
                                                              33,
                                                              298);
                    ELSIF lc_record_type = '12'
                    THEN                                                                        -- Header Address record
                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD(   'The addr Rec is '
                                             || SUBSTR(lc_curr_line,
                                                       33,
                                                       298));
                        END IF;

                        l_order_tbl(i).file_line :=    l_order_tbl(i).file_line
                                                    || SUBSTR(lc_curr_line,
                                                              33,
                                                              298);
                    ELSIF lc_record_type = '13'
                    THEN                                                                 -- Header Customer Email record
                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD(   'The Customer Email Rec is '
                                             || SUBSTR(lc_curr_line,
                                                       33,
                                                       298));
                        END IF;

                        l_order_tbl(i).file_line :=    l_order_tbl(i).file_line
                                                    || SUBSTR(lc_curr_line,
                                                              33,
                                                              298);
                    ELSIF lc_record_type = '20'
                    THEN                                                                                  -- Line Record
                        i :=   i
                             + 1;
                        l_order_tbl(i).record_type := lc_record_type;
                        l_order_tbl(i).file_line := lc_curr_line;
                        lc_rec_21_exists := 'N' ; -- AG 
                    ELSIF lc_record_type = '21' AND lc_record_line_type = '0001'
                    THEN                                                                         -- Line comments record
                        l_order_tbl(i).file_line :=    l_order_tbl(i).file_line
                                                    || SUBSTR(lc_curr_line,
                                                              33,
                                                              298);

                        lc_rec_21_exists := 'Y';        -- AG                   
                    ELSIF lc_record_type = '21' AND lc_record_line_type = '0002'
                    THEN                                                                     -- 2nd line comments record
                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD(   'The line comments Rec is '
                                             || SUBSTR(lc_curr_line,
                                                       33,
                                                       298));
                        END IF;

                        l_order_tbl(i).file_line :=    l_order_tbl(i).file_line
                                                    || SUBSTR(lc_curr_line,
                                                              33,
                                                              298);

                        lc_rec_21_exists := 'Y';        -- AG                   
                    /* Commented as per defect 36885 ver 25.0
                    ELSIF lc_record_type = '22'           
                    THEN                                                                        
                      IF lc_rec_21_exists = 'N'
                      THEN
                        l_order_tbl(i).file_line :=    l_order_tbl(i).file_line||LPAD(' ',298) -- AG Testing
                                                        || SUBSTR(lc_curr_line,
                                                                  33,
                                                                  298);
                      ELSE
                        l_order_tbl(i).file_line :=    l_order_tbl(i).file_line
                                                       || SUBSTR(lc_curr_line,
                                                                 33,
                                                                 298);
                      END IF;  */ 

                      -- End of comments section as per defect 36885 ver 25.0

                    -- Added as per defect 36885 ver 25.0

                    ELSIF lc_record_type = '22'                    -- Line tax record       
		    THEN                                                                       
		       i :=   i 
		      	    + 1;
		       l_order_tbl(i).record_type := lc_record_type;
		       l_order_tbl(i).file_line := lc_curr_line;

		   -- End as per defect 36885 ver 25.0  

                    ELSIF lc_record_type = '30'
                    THEN                                                                           -- Adjustments record
                        i :=   i
                             + 1;
                        l_order_tbl(i).record_type := lc_record_type;
                        l_order_tbl(i).file_line := lc_curr_line;
                    ELSIF lc_record_type = '40'
                    THEN                                                                               -- Payment Record
                        i :=   i
                             + 1;

                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD(   'The Payment Rec is '
                                             || lc_curr_line);
                        END IF;

                        l_order_tbl(i).record_type := lc_record_type;
                        l_order_tbl(i).file_line := lc_curr_line;


                    ELSIF lc_record_type = '41'
                    THEN                                                                               -- Tender Record
                        i :=   i
                             + 1;

                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD(   'The Tender Rec is '
                                             || lc_curr_line);
                        END IF;

                        l_order_tbl(i).record_type := lc_record_type;
                        l_order_tbl(i).file_line := lc_curr_line;


                    ELSIF lc_record_type = '99'
                    THEN                                                                               -- Trailer Record
                        i :=   i
                             + 1;

                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD(   'The Trailer Rec is '
                                             || lc_curr_line);
                        END IF;

                        l_order_tbl(i).record_type := lc_record_type;
                        l_order_tbl(i).file_line := lc_curr_line;
                        lb_at_trailer := TRUE;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'Error While reading Order Record '
                                          || lc_orig_sys_document_ref
                                          || ' The record type is '
                                          || lc_record_type);
                        -- Need to skip reading this Order.
                        lb_read_error := TRUE;
                END;
            END LOOP;

            -- If trailer record is missing then we need to raise hard error as it can happen as a result of file getting truncated
            -- during transmission
            IF NOT lb_at_trailer
            THEN
                -- Send email notification that trailer record is missing
                xx_om_hvop_util_pkg.send_notification('HVOP Trailer record missing',
                                                         'Trailer record is missing on the file :'
                                                      || p_file_name);
                fnd_file.put_line(fnd_file.LOG,
                                     'ERROR: Trailer record is missing on the file :'
                                  || p_file_name);
                lc_error_flag := 'Y';
                ROLLBACK;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                lc_error_flag := 'Y';
                ROLLBACK;
                fnd_file.put_line(fnd_file.LOG,
                                     'Unexpected error in Process Child :'
                                  || SUBSTR(SQLERRM,
                                            1,
                                            80));
                -- Send email notification
                xx_om_hvop_util_pkg.send_notification('HVOP unexpected Error',
                                                         'Unexpected error while processing the file : '
                                                      || p_file_name
                                                      || 'Check the request log for request_id :'
                                                      || g_request_id);
        END;

-- Save the messages logged so far
        oe_bulk_msg_pub.save_messages(g_request_id);
        oe_msg_pub.save_messages(g_request_id);
-- Commit the data to database. Even if the Import fails later we still want record to exist in
-- interface table.
        COMMIT;

        SELECT hsecs
        INTO   ln_end_time
        FROM   v$timer;

        fnd_file.put_line(fnd_file.LOG,
                             'Time spent in Reading data is (sec) '
                          || (  (  ln_end_time
                                 - ln_start_time)
                              / 100));

-- After reading the whole file Call the HVOP program to Import the data
-- Check if no error occurred during reading of file
--lc_error_flag := 'Y'; -- CNV04SPECIFIC
        IF lc_error_flag = 'N'
        THEN
            -- Move the file to archive directory
            BEGIN
                lc_arch_path := fnd_profile.VALUE('XX_OM_SAS_ARCH_FILE_DIR');
                UTL_FILE.fcopy(lc_file_path,
                               p_file_name,
                               lc_arch_path,
                                  p_file_name
                               || '.done');
                UTL_FILE.fremove(lc_file_path,
                                 p_file_name);
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                      'Failed to move file to archieval directory');
            END;

            -- Running the file for first time
            IF g_file_run_count = 0
            THEN
                -- Get the Master Request ID
                BEGIN
                    SELECT parent_request_id
                    INTO   ln_master_request_id
                    FROM   fnd_run_requests
                    WHERE  request_id = g_request_id;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        ln_master_request_id := g_request_id;
                END;

                -- Create log into the File History Table
                INSERT INTO xx_om_sacct_file_history
                            (file_name,
                             file_type,
                             request_id,
                             master_request_id,
                             process_date,
                             total_orders,
                             total_lines,
                             error_flag,
                             creation_date,
                             created_by,
                             last_update_date,
                             last_updated_by,
                             legacy_header_count,
                             legacy_line_count,
                             legacy_adj_count,
                             legacy_payment_count,
                             legacy_header_amount,
                             legacy_tax_amount,
                             legacy_line_amount,
                             legacy_adj_amount,
                             legacy_payment_amount,
                             acct_order_total,
                             org_id,
                             cash_back_amount)
                     VALUES (p_file_name,
                             'ORDER',
                             g_request_id,
                             ln_master_request_id,
                             g_process_date                                                                   -- SYSDATE
                                           ,
                             g_header_counter,
                             g_line_counter,
                             lc_error_flag,
                             SYSDATE,
                             fnd_global.user_id,
                             SYSDATE,
                             fnd_global.user_id,
                             g_header_count,
                             g_line_count,
                             g_adj_count,
                             g_payment_count,
                             g_header_tot_amt,
                             g_tax_tot_amt,
                             g_line_tot_amt,
                             g_adj_tot_amt,
                             g_payment_tot_amt,
                             g_acct_order_tot,
                             g_org_id,
                             g_cashback_total);
            ELSE                                                                                        -- In rerun mode
                -- We are in rerun mode and need to update the record in xx_om_sacct_file_history
                UPDATE xx_om_sacct_file_history
                SET total_orders =   total_orders
                                   + g_header_counter,
                    total_lines =   total_lines
                                  + g_line_counter,
                    cash_back_amount =   cash_back_amount
                                       + g_cashback_total
                WHERE  file_name = p_file_name;
            END IF;

            COMMIT;
            -- Set the header_ids on interface data
            set_header_id;
            fnd_file.put_line(fnd_file.LOG,
                              'Before calling HVOP API');
            oe_bulk_order_import_pvt.order_import_conc_pgm(p_order_source_id              => NULL,
                                                           p_orig_sys_document_ref        => NULL,
                                                           p_validate_only                => 'N',
                                                           p_validate_desc_flex           => 'N',
                                                           p_defaulting_mode              => 'N',
                                                           p_num_instances                => 0,
                                                           p_batch_size                   => NULL,
                                                           p_rtrim_data                   => 'N',
                                                           p_process_tax                  => 'N',
                                                           p_process_configurations       => 'N',
                                                           p_dummy                        => NULL,
                                                           p_validate_configurations      => 'N',
                                                           p_schedule_configurations      => 'N',
                                                           errbuf                         => lc_errbuf,
                                                           retcode                        => ln_retcode,
                                                           p_operating_unit               => g_org_id
                                                                                                     --Added for 12i Retro Fit by NB
                                                          );

            -- oe_debug_pub.add('Return Status from OE_BULK_ORDER_IMPORT_PVT: '||ln_retcode);
            IF ln_retcode <> 0
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'Failure in Importing Orders');
            END IF;

            -- If there were orders marked for error then send email notification
            IF g_error_count > 0
            THEN
                xx_om_hvop_util_pkg.send_notification('HVOP Errors',
                                                         'There are '
                                                      || g_error_count
                                                      || ' orders marked for error while processing the file :'
                                                      || p_file_name);
                fnd_file.put_line(fnd_file.output,
                                     'SAS Import program marked '
                                  || g_error_count
                                  || ' orders for error out of '
                                  || g_header_count
                                  || ' orders in the file :'
                                  || p_file_name);
            END IF;
        ELSE
            x_return_status := 'E';
        END IF;

-- Print time spent in Receipt Creation
        fnd_file.put_line(fnd_file.LOG,
                             'Time spent in receipt creation '
                          || xx_om_sales_acct_pkg.g_create_receipt_time);
    EXCEPTION
        WHEN fnd_api.g_exc_error
        THEN
            x_return_status := 'E';
            fnd_file.put_line(fnd_file.LOG,
                                 'Expected error in Process Child :'
                              || SUBSTR(SQLERRM,
                                        1,
                                        80));
        WHEN OTHERS
        THEN
            x_return_status := 'E';
            fnd_file.put_line(fnd_file.LOG,
                                 'Unexpected error in Process Child :'
                              || SUBSTR(SQLERRM,
                                        1,
                                        80));
    END process_child;

    PROCEDURE process_current_order(
        p_order_tbl   IN  order_tbl_type,
        p_batch_size  IN  NUMBER)
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
        ln_hdr_count             BINARY_INTEGER;
        ln_debug_level  CONSTANT NUMBER         := oe_debug_pub.g_debug_level;
        ln_order_amount          NUMBER;
        ln_payment_amount        NUMBER;
        ln_order_amt             NUMBER;
        ln_order_pymt_amt        NUMBER;
        ln_mismatch_ind          NUMBER;
        lc_aops_pos_flag         VARCHAR2(1);
        i                        BINARY_INTEGER;
        lc_return_status         VARCHAR2(1);
        lc_err                   VARCHAR2(40);
        lb_has_tender            BOOLEAN;
    BEGIN
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'In Process Current Order :'
                             || g_batch_counter);
        END IF;

        -- Batch_IDs are preassigned for HVOP orders
        IF g_batch_id IS NULL OR g_batch_counter >= p_batch_size
        THEN
            SELECT oe_batch_id_s.NEXTVAL
            INTO   g_batch_id
            FROM   DUAL;

            g_batch_counter := 0;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'My Batch_ID is :'
                             || g_batch_id);
        END IF;

        -- Set the line number counter per order
        g_line_nbr_counter := 0;
        ln_order_amount := 0;
        ln_payment_amount := 0;
        g_order_line_tax_ctr := 0;
        g_rma_line_tax_ctr := 0;
        g_has_debit_card := FALSE;
        lb_has_tender := FALSE;

        FOR k IN 1 .. p_order_tbl.COUNT
        LOOP
            IF p_order_tbl(k).record_type = '10'
            THEN
                process_header(p_order_tbl(k),
                               g_batch_id,
                               ln_order_amount,
                               lc_aops_pos_flag,
                               lc_return_status);
            ELSIF p_order_tbl(k).record_type = '20'
            THEN
                process_line(p_order_tbl(k),
                             g_batch_id,
                             lc_return_status);
            ELSIF p_order_tbl(k).record_type = '40'
            THEN
                lb_has_tender := TRUE;
                process_payment(p_order_tbl(k),
                                g_batch_id,
                                ln_payment_amount,
                                lc_return_status);

            ELSIF p_order_tbl(k).record_type = '41'
            THEN
                process_tender(p_order_tbl(k),
                               g_batch_id,
                               lc_return_status);

            ELSIF p_order_tbl(k).record_type = '30'
            THEN
                process_adjustments(p_order_tbl(k),
                                    g_batch_id,
                                    lc_return_status);
           -- END IF;
            ELSIF p_order_tbl(k).record_type = '22'   -- Added as per 36885 ver 25.0
	    THEN
	       process_line_tax(p_order_tbl(k),
	                        g_batch_id,
	                        lc_return_status);
            END IF;

            IF lc_return_status = 'U'
            THEN
                -- No need to process this order any further, exit the loop
                g_error_count :=   g_error_count
                                 + 1;
                GOTO end_of_order;
            END IF;
        END LOOP;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'After processing all entities '
                             || lc_return_status,
                             1);
        END IF;

        ln_hdr_count := g_header_rec.orig_sys_document_ref.COUNT;
        oe_debug_pub.ADD(   'MAC ACCT Order Total IS: '
                         || ln_order_amount);
        -- Get the actual order total based on display distribution
        ln_order_amount := ROUND(g_header_rec.order_total(ln_hdr_count),
                                 2);
        oe_debug_pub.ADD(   'MAC Order Total IS: '
                         || ln_order_amount);
        oe_debug_pub.ADD(   'MAC payment Total IS: '
                         || ln_payment_amount);

        -- Match the Order Total with the payment total
        IF lb_has_tender AND ln_order_amount <> ln_payment_amount AND ln_order_amount <> 0
        THEN
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Order Total Mismatch found: '
                                 || ln_order_amount
                                 || '-'
                                 || ln_payment_amount,
                                 1);
            END IF;

            set_header_error(ln_hdr_count);
            fnd_file.put_line(fnd_file.LOG,
                                 'Total Mismatch '
                              || lc_aops_pos_flag);
            set_msg_context(p_entity_code      => 'HEADER');
            fnd_message.set_name('XXOM',
                                 'XX_OM_PAYMENT_TOTAL_MISMATCH');
            fnd_message.set_token('ATTRIBUTE1',
                                     'Total Order Amount'
                                  || ln_order_amount);
            fnd_message.set_token('ATTRIBUTE2',
                                     'Total Payment Amount'
                                  || ln_payment_amount);
            oe_bulk_msg_pub.ADD;
        END IF;

        -- Check if the current order has deposits against it
        -- Or check if the order amount is non zero and no tender record came
        IF g_header_rec.deposit_amount(ln_hdr_count) > 0 OR(NOT(lb_has_tender) AND ln_order_amount <> 0)
        THEN
            process_deposits(p_hdr_idx      => ln_hdr_count);
        END IF;

        -- If AOPS order, or SPC / PRO card, and fully paid my non AB then set payment terms to immediate
        -- CR 623
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('Checking AOPS / SPC / PRO for immediate payment terms :');
            oe_debug_pub.ADD(   '         order_source    = '
                             || g_header_rec.order_source_cd(ln_hdr_count));
            oe_debug_pub.ADD(   '         payment_term_id = '
                             || g_header_rec.payment_term_id(ln_hdr_count));
            oe_debug_pub.ADD(   '         order_total     = '
                             || ROUND(g_header_rec.order_total(ln_hdr_count),
                                      2));
        END IF;

        IF g_im_pay_term_id IS NOT NULL
        THEN                                                                        -- MUST HAVE AN IMMEDIATE PAYMENT ID
            IF     g_header_rec.order_source_cd(ln_hdr_count) IN('A', 'P')
               AND                                                                     -- IF AOPS ORDER / SPC / PRO CARD
                   (   g_header_rec.payment_term_id(ln_hdr_count) IS NULL
                    OR (    g_header_rec.payment_term_id(ln_hdr_count) <> g_deposit_term_id
                        AND                                                                   -- AND NOT PAID-BY-DEPOSIT
                            g_header_rec.payment_term_id(ln_hdr_count) <> g_im_pay_term_id))
            THEN                                                                            -- AND NOT ALREADY IMMEDIATE
                ln_order_amt := ROUND(g_header_rec.order_total(ln_hdr_count),
                                      2);                                                      -- CALCULATE ORDER AMOUNT
                ln_order_pymt_amt := 0;                                                    -- INITIALIZE PAYMENTS AMOUNT

                FOR i IN 1 .. g_payment_rec.orig_sys_document_ref.COUNT
                LOOP                                                                           -- TOTAL ALL DETAIL LINES
                    IF g_header_rec.orig_sys_document_ref(ln_hdr_count) = g_payment_rec.orig_sys_document_ref(i)
                    THEN
                        ln_order_pymt_amt :=   ln_order_pymt_amt
                                             + g_payment_rec.payment_amount(i);
                    END IF;
                END LOOP;

                IF ln_order_amt = ln_order_pymt_amt
                THEN                                                                     -- IF AOPS ORDER and FULLY PAID
                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(   '         setting immediate terms   = '
                                         || ln_order_pymt_amt);
                    END IF;

                    g_header_rec.payment_term_id(ln_hdr_count) := g_im_pay_term_id;        -- CHANGE HEADER TO IMMEDIATE

                    FOR i IN 1 .. g_line_rec.orig_sys_document_ref.COUNT
                    LOOP                                                                         -- FOR ALL DETAIL LINES
                        IF g_header_rec.orig_sys_document_ref(ln_hdr_count) = g_line_rec.orig_sys_document_ref(i)
                        THEN
                            g_line_rec.payment_term_id(i) := g_im_pay_term_id;      -- CHANGE DETAIL LINES TO IMMEDIATE
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        END IF;

        -- Check if the error_flag is set on header record. If yes then make sure that we populate request_id on it.
        -- so that the error reporting can look at these errors.
        IF g_header_rec.error_flag(ln_hdr_count) = 'Y' AND g_header_rec.request_id(ln_hdr_count) IS NULL
        THEN
            g_header_rec.request_id(ln_hdr_count) := g_request_id;
        END IF;

        IF g_header_rec.error_flag(ln_hdr_count) = 'Y'
        THEN
            g_error_count :=   g_error_count
                             + 1;
            oe_debug_pub.ADD(   'This Order has errors :'
                             || g_header_rec.orig_sys_document_ref(ln_hdr_count));
        END IF;

        <<end_of_order>>
        IF lc_return_status = 'U'
        THEN
            -- Dump the order table into a file to process later
            write_to_file(p_order_tbl);
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Exiting Process_Current_Order :'
                             || lc_return_status);
        END IF;
    END process_current_order;

    PROCEDURE process_deposits(
        p_hdr_idx  IN  BINARY_INTEGER)
    IS
-- +===================================================================+
-- | Name  : Process_Deposits                                          |
-- | Description      : This Procedure will look for any deposits exist|
-- |                    if found it will create a payment aganist the  |
-- |                    deposit                                        |
-- |                                                                   |
-- | Parameters:        p_hdr_idx IN header index                      |
-- +===================================================================+
        CURSOR c_deposits(
            p_osd_ref       IN  VARCHAR2,
            p_invoicing_on  IN  VARCHAR2)
        IS
            SELECT     dt.orig_sys_document_ref orig_sys_document_ref,
                       dt.order_source_id,
                       payment_type_code,
                       receipt_method_id,
                       payment_set_id,
                       orig_sys_payment_ref,
                       avail_balance,
                       credit_card_number credit_card_number_enc,
                       credit_card_expiration_date,
                       credit_card_code,
                       credit_card_approval_code,
                       credit_card_approval_date,
                       check_number,
                       cc_auth_manual,
                       merchant_number,
                       cc_auth_ps2000,
                       allied_ind,
                       cc_mask_number,
                       od_payment_type,
                       credit_card_holder_name,
                       cash_receipt_id,
                       debit_card_approval_ref,
                       cc_entry_mode,
                       cvv_resp_code,
                       avs_resp_code,
                       auth_entry_mode,
                       d.single_pay_ind,
                       d.IDENTIFIER,
                       d.token_flag,
                       d.emv_card,
                       d.emv_terminal,
                       d.emv_transaction,
                       d.emv_offline,
                       d.emv_fallback,
                       d.emv_tvr
            FROM       xx_om_legacy_deposits d,
                       xx_om_legacy_dep_dtls dt
            WHERE      dt.orig_sys_document_ref = p_osd_ref
            AND        d.avail_balance > 0
            AND        d.i1025_status <> 'CANCELLED'
            AND        NVL(error_flag,
                           'N') = 'N'
            AND        (cash_receipt_id IS NOT NULL OR 'N' = 'N' OR od_payment_type = 'AB')
            AND        d.transaction_number = dt.transaction_number
            ORDER BY   avail_balance
            FOR UPDATE;

        i                        BINARY_INTEGER := 0;
        j                        BINARY_INTEGER := 0;
        ln_debug_level  CONSTANT NUMBER         := oe_debug_pub.g_debug_level;
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
        lc_invoicing_on          VARCHAR2(1)    := oe_sys_parameters.VALUE('XX_OM_INVOICING_ON',
                                                                           g_org_id);
        lc_err_msg               VARCHAR2(1000);
        lc_payment_type_code     fnd_lookup_values.attribute7%TYPE;
        lc_cc_code               fnd_lookup_values.attribute6%TYPE;
    BEGIN
        /* R11.2 Change to capture both POS and AOPS orders for SDR */
        IF LENGTH(g_header_rec.orig_sys_document_ref(p_hdr_idx)) > 12
        THEN
            lc_orig_sys_ref := g_header_rec.orig_sys_document_ref(p_hdr_idx);
        ELSE
            lc_orig_sys_ref :=    SUBSTR(g_header_rec.orig_sys_document_ref(p_hdr_idx),
                                         1,
                                         9)
                               || '001';
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Entering Process Deposits :'
                             || lc_orig_sys_ref);
            oe_debug_pub.ADD(   'lc_orig_sys_ref : '
                             || lc_orig_sys_ref);
            oe_debug_pub.ADD(   'lc_invoicing_on : '
                             || lc_invoicing_on);
        END IF;

        -- Populate header_id so that AR receipt can be adjusted.
        SELECT oe_order_headers_s.NEXTVAL
        INTO   g_header_rec.header_id(p_hdr_idx)
        FROM   DUAL;

        SAVEPOINT process_deposit;
        -- Get the order total paid by deposit
        ln_deposit_amt := g_header_rec.deposit_amount(p_hdr_idx);
        -- Get the current index for payment record
        i := g_payment_rec.orig_sys_document_ref.COUNT;
        -- Set the counter for Payment Number counter
        j := 0;

        FOR c1 IN c_deposits(lc_orig_sys_ref,
                             lc_invoicing_on)
        LOOP
            i :=   i
                 + 1;
            j :=   j
                 + 1;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Payment Ref is :'
                                 || c1.orig_sys_payment_ref);
                oe_debug_pub.ADD(   'Deposit Amount is :'
                                 || ln_deposit_amt);
                oe_debug_pub.ADD(   'Available balance is :'
                                 || c1.avail_balance);
            END IF;

            -- IF pay type is 'AB' skip processing receipt creation and applying hold.
            IF c1.od_payment_type = 'AB'
            THEN
                EXIT;
            END IF;

            IF ln_deposit_amt <= c1.avail_balance
            THEN
                g_payment_rec.prepaid_amount(i) := ln_deposit_amt;
                -- Order Total is matched by the availbale balance
                ln_avail_balance :=   c1.avail_balance
                                    - ln_deposit_amt;
                ln_deposit_amt := 0;
            ELSE
                g_payment_rec.prepaid_amount(i) := c1.avail_balance;
                -- Set the remaining balance
                ln_deposit_amt :=   ln_deposit_amt
                                  - c1.avail_balance;
                ln_avail_balance := 0;
            END IF;

            g_payment_rec.payment_set_id(i) := c1.payment_set_id;

            -- Call the AR API to adjust the receipt it will return the payment_set_id
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Before Calling reapply_deposit_prepayment :'
                                 || c1.cash_receipt_id);
            END IF;

            -- Call this API only if INVOICING is ON
            IF lc_invoicing_on = 'Y'
            THEN
                xx_ar_prepayments_pkg.reapply_deposit_prepayment
                                                      (p_init_msg_list         => fnd_api.g_false,
                                                       p_commit                => fnd_api.g_false,
                                                       p_validation_level      => fnd_api.g_valid_level_full,
                                                       p_cash_receipt_id       => c1.cash_receipt_id,
                                                       p_header_id             => g_header_rec.header_id(p_hdr_idx),
                                                       p_order_number          => g_header_rec.orig_sys_document_ref
                                                                                                              (p_hdr_idx),
                                                       p_apply_amount          => g_payment_rec.prepaid_amount(i),
                                                       x_payment_set_id        => l_payment_set_id,
                                                       x_return_status         => l_return_status,
                                                       x_msg_count             => l_msg_count,
                                                       x_msg_data              => l_msg_data);

                IF l_return_status <> fnd_api.g_ret_sts_success OR l_payment_set_id IS NULL
                THEN
                    oe_debug_pub.ADD(   'Failure in reapply_deposit_prepayment :'
                                     || l_msg_data);
                    oe_debug_pub.ADD(   'Payment Set ID is :'
                                     || l_payment_set_id);

                    IF l_msg_count > 0
                    THEN
                        FOR k IN 1 .. l_msg_count
                        LOOP
                            l_msg_data := fnd_msg_pub.get(p_msg_index      => k,
                                                          p_encoded        => 'F');
                            fnd_file.put_line(fnd_file.LOG,
                                              l_msg_data);
                        END LOOP;
                    END IF;

                    -- set the payment_set_id from C1
                    g_payment_rec.payment_set_id(i) := c1.payment_set_id;
                    lb_put_on_hold := TRUE;

                    IF l_payment_set_id IS NULL
                    THEN
                        -- Mark all orders for error if payment set id is null
                        g_header_rec.error_flag(p_hdr_idx) := 'Y';
                        set_msg_context(p_entity_code      => 'HEADER');
                        lc_err_msg :=
                               'reapply_deposit_prepayment did not return Payment set id for order  : '
                            || g_header_rec.orig_sys_document_ref(p_hdr_idx);
                        fnd_message.set_name('XXOM',
                                             'XX_OM_REQ_ATTR_MISSING');
                        fnd_message.set_token('ATTRIBUTE',
                                              lc_err_msg);
                        oe_bulk_msg_pub.ADD;
                        oe_debug_pub.ADD(lc_err_msg,
                                         1);
                        lc_hold_comments :=
                               ' Reapply deposit prepayment for orig_sys_payment_ref :'
                            || c1.orig_sys_payment_ref
                            || ' did not return payment_set_id';
                    ELSE
                        lc_hold_comments :=
                               'Failed to reapply deposit prepayment for orig_sys_payment_ref :'
                            || c1.orig_sys_payment_ref
                            || ' Make sure to update the payment_set_id on this payment record';
                    END IF;

                    fnd_file.put_line(fnd_file.LOG,
                                         'Failed to reapply deposit for order :'
                                      || g_header_rec.orig_sys_document_ref(p_hdr_idx));
                END IF;
            END IF;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Payment Set ID after applying the receipt:'
                                 || g_payment_rec.payment_set_id(i));
            END IF;

            -- Update the XX_OM_LEGACY_DEPOSIT table for the available balance
            UPDATE xx_om_legacy_deposits
            SET avail_balance = ln_avail_balance,
                last_update_date = SYSDATE,
                last_updated_by = fnd_global.user_id
            WHERE  cash_receipt_id = c1.cash_receipt_id;

            --WHERE CURRENT OF C_DEPOSITS;
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'UPDATED ln_avail_balance ::'
                                 || ln_avail_balance);
                oe_debug_pub.ADD(   'UPDATED xx_om_legacy_deposits ::'
                                 || SQL%ROWCOUNT);
            END IF;

            get_pay_method(p_payment_instrument      => c1.od_payment_type,
                           p_payment_type_code       => lc_payment_type_code,
                           p_credit_card_code        => lc_cc_code);

            IF lc_payment_type_code IS NULL
            THEN
                set_msg_context(p_entity_code      => 'HEADER_PAYMENT');
                set_header_error(p_hdr_idx);
                lc_err_msg :=    'INVALID PAYMENT METHOD :'
                              || c1.od_payment_type;
                fnd_message.set_name('XXOM',
                                     'XX_OM_FAIL_PAYMTD_DERIVATION');
                fnd_message.set_token('ATTRIBUTE1',
                                      c1.od_payment_type);
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;

            g_payment_rec.payment_set_id(i) := l_payment_set_id;
            g_payment_rec.payment_type_code(i) := NVL(lc_payment_type_code, c1.od_payment_type);
            g_payment_rec.credit_card_code(i) := lc_cc_code;
            g_payment_rec.receipt_method_id(i) := c1.receipt_method_id;
            g_payment_rec.orig_sys_payment_ref(i) := c1.orig_sys_payment_ref;
            g_payment_rec.credit_card_number_enc(i) := c1.credit_card_number_enc;
            g_payment_rec.credit_card_expiration_date(i) := c1.credit_card_expiration_date;
            g_payment_rec.credit_card_approval_code(i) := c1.credit_card_approval_code;
            g_payment_rec.credit_card_approval_date(i) := c1.credit_card_approval_date;
            g_payment_rec.check_number(i) := c1.check_number;
            g_payment_rec.IDENTIFIER(i) := c1.IDENTIFIER;
            g_payment_rec.attribute6(i) := c1.cc_auth_manual;
            g_payment_rec.attribute7(i) := c1.merchant_number;
            g_payment_rec.attribute8(i) := c1.cc_auth_ps2000;
            g_payment_rec.attribute9(i) := c1.allied_ind;
            g_payment_rec.attribute10(i) := c1.cc_mask_number;
            g_payment_rec.attribute11(i) := c1.od_payment_type;
            g_payment_rec.attribute12(i) := c1.debit_card_approval_ref;
            g_payment_rec.attribute13(i) :=
                   c1.cc_entry_mode
                || ':'
                || c1.cvv_resp_code
                || ':'
                || c1.avs_resp_code
                || ':'
                || c1.auth_entry_mode
                || ':'
                || c1.single_pay_ind;                                                                /*added for R11.2*/
            g_payment_rec.attribute15(i) := c1.cash_receipt_id;
            g_payment_rec.credit_card_holder_name(i) := c1.credit_card_holder_name;
            g_payment_rec.orig_sys_document_ref(i) := g_header_rec.orig_sys_document_ref(p_hdr_idx);
            -- G_Header_Rec.request_id(p_hdr_idx) := NULL;
            g_payment_rec.sold_to_org_id(i) := g_header_rec.sold_to_org_id(p_hdr_idx);
            g_payment_rec.order_source_id(i) := g_header_rec.order_source_id(p_hdr_idx);
            g_payment_rec.payment_number(i) := j;
            g_payment_rec.payment_amount(i) := g_payment_rec.prepaid_amount(i);
            g_payment_rec.attribute3(i)     := c1.token_flag;
            g_payment_rec.attribute14(i)    := c1.emv_card||'.'||c1.emv_terminal||'.'||c1.emv_transaction||'.'||
                                                c1.emv_offline||'.'||c1.emv_fallback||'.'||c1.emv_tvr;
            g_payment_rec.attribute2(i)     :=  NULL;

            --g_payment_rec.wallet_type(i)    := c1.wallet_type;
            --g_payment_rec.wallet_id(i)      := c1.wallet_id;


            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'OD Payment type is :'
                                 || g_payment_rec.attribute11(i));
                oe_debug_pub.ADD(   'receipt_method = '
                                 || g_payment_rec.receipt_method_id(i));
                oe_debug_pub.ADD(   'orig_sys_document_ref = '
                                 || g_payment_rec.orig_sys_document_ref(i));
                oe_debug_pub.ADD(   'order_source_id = '
                                 || g_payment_rec.order_source_id(i));
                oe_debug_pub.ADD(   'orig_sys_payment_ref = '
                                 || g_payment_rec.orig_sys_payment_ref(i));
                oe_debug_pub.ADD(   'payment_amount = '
                                 || g_payment_rec.payment_amount(i));
                oe_debug_pub.ADD(   'lc_cc_number = '
                                 || g_payment_rec.credit_card_number_enc(i));
                oe_debug_pub.ADD(   'credit_card_expiration_date = '
                                 || g_payment_rec.credit_card_expiration_date(i));
                oe_debug_pub.ADD(   'credit_card_approval_code = '
                                 || g_payment_rec.credit_card_approval_code(i));
                oe_debug_pub.ADD(   'credit_card_approval_date = '
                                 || g_payment_rec.credit_card_approval_date(i));
                oe_debug_pub.ADD(   'check_number = '
                                 || g_payment_rec.check_number(i));
                oe_debug_pub.ADD(   'identifier  = '
                                 || g_payment_rec.IDENTIFIER(i));
                oe_debug_pub.ADD(   'CC Auth Manual = '
                                 || g_payment_rec.attribute6(i));
                oe_debug_pub.ADD(   'Merchant Number = '
                                 || g_payment_rec.attribute7(i));
                oe_debug_pub.ADD(   'CC_AUTH_PS2000 = '
                                 || g_payment_rec.attribute8(i));
                oe_debug_pub.ADD(   'ALLIED_IND = '
                                 || g_payment_rec.attribute9(i));
                oe_debug_pub.ADD(   'CC Mask = '
                                 || g_payment_rec.attribute10(i));
                oe_debug_pub.ADD(   'credit_card_holder_name = '
                                 || g_payment_rec.credit_card_holder_name(i));
                oe_debug_pub.ADD(   'Token Flag = '
                                 || g_payment_rec.attribute3(i));
                oe_debug_pub.ADD(   'EMV details = '
                                 || g_payment_rec.attribute14(i));
            END IF;

            IF ln_deposit_amt = 0
            THEN
                EXIT;
            END IF;
        END LOOP;

        -- If Deposit record not found
        IF j = 0
        THEN
            -- Need to put the order on hold
            lb_put_on_hold := TRUE;
            lc_hold_comments :=
                'Deposit record not found for the order. Either the record does not exist or the record is not yet processed by AR or it is marked as error';
            -- NO need to set error just add message.
            set_msg_context(p_entity_code       => 'HEADER',
                            p_warning_flag      => TRUE);
            fnd_message.set_name('XXOM',
                                 'XX_OM_NO_DEPOSIT_FOUND');
            oe_bulk_msg_pub.ADD;
            fnd_file.put_line(fnd_file.LOG,
                                 'WARNING: Deposit Record not found for the Order : '
                              || g_header_rec.orig_sys_document_ref(p_hdr_idx));

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   ' WARNING: Deposit Record not found for the Order : '
                                 || g_header_rec.orig_sys_document_ref(p_hdr_idx),
                                 1);
                oe_debug_pub.ADD(   ' Order error flag : '
                                 || g_header_rec.error_flag(p_hdr_idx),
                                 1);
            END IF;
        END IF;

        -- If the Order is not totally paid by deposit then also create it with pending deposit hold.
        IF ln_deposit_amt > 0 AND j > 0
        THEN
            -- Need to put the order on hold
            lb_put_on_hold := TRUE;
            lc_hold_comments :=
                   'Partial Deposit record found. Need remaining amount :'
                || ln_deposit_amt
                || ' before we can process this order';
            fnd_file.put_line(fnd_file.LOG,
                                 'WARNING: Partial Deposit Record found for the Order : '
                              || g_header_rec.orig_sys_document_ref(p_hdr_idx));
        END IF;

        IF lb_put_on_hold
        THEN
            -- We will need to put this order on Pending Deposit Hold and also mark it for SOI and not HVOP
            g_header_rec.booked_flag(p_hdr_idx) := NULL;
            g_header_rec.batch_id(p_hdr_idx) := NULL;
            g_header_rec.deposit_hold_flag(p_hdr_idx) := 'Y';
            g_header_rec.ineligible_for_hvop(p_hdr_idx) := 'Y';

            IF NVL(g_header_rec.error_flag(p_hdr_idx),
                   'N') = 'N'
            THEN
                g_header_rec.request_id(p_hdr_idx) := NULL;
            END IF;

            -- Get the Hold ID
            SELECT hold_id
            INTO   l_hold_id
            FROM   oe_hold_definitions
            WHERE  NAME = 'OD: SAS Pending deposit hold';

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'After getting the hold_id '
                                 || l_hold_id);
            END IF;

            -- Insert ACTION to put this order on hold..
            INSERT INTO oe_actions_interface
                        (org_id,
                         order_source_id,
                         orig_sys_document_ref,
                         operation_code,
                         sold_to_org_id,
                         hold_id,
                         change_sequence,
                         comments)
                 VALUES (g_org_id,
                         g_header_rec.order_source_id(p_hdr_idx),
                         g_header_rec.orig_sys_document_ref(p_hdr_idx),
                         oe_globals.g_apply_hold,
                         g_header_rec.sold_to_org_id(p_hdr_idx),
                         l_hold_id,
                         g_header_rec.change_sequence(p_hdr_idx),
                         lc_hold_comments);

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'After inserting action to put order on hold '
                                 || l_hold_id);
            END IF;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(' Exiting Process_Deposits');
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK TO SAVEPOINT process_deposit;
            set_header_error(p_hdr_idx);
            oe_debug_pub.ADD(   ' Failed to process Deposit for the Order : '
                             || g_header_rec.orig_sys_document_ref(p_hdr_idx),
                             1);
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed to process Deposit Records for Header '
                              || g_header_rec.orig_sys_document_ref(p_hdr_idx));
            fnd_file.put_line(fnd_file.LOG,
                                 'The error is '
                              || SQLERRM);
    --RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END process_deposits;

    PROCEDURE process_trailer(
        p_order_rec  IN  order_rec_type)
    IS
-- +===================================================================+
-- | Name  : Process_Trailer                                          |
-- | Description      : This Procedure will read the last line where   |
-- |                    total headers, total lines etc send in each    |
-- |                    feed and insert into history tbl               |
-- |                                                                   |
-- | Parameters:        p_order_rec IN order_rec_type                  |
-- +===================================================================+
        ln_debug_level  CONSTANT NUMBER       := oe_debug_pub.g_debug_level;
        lc_process_date          VARCHAR2(14);
        lb_day_deduct            BOOLEAN      := FALSE;
    BEGIN
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('Entering  Trailer Header');
        END IF;

        g_header_count := SUBSTR(p_order_rec.file_line,
                                 42,
                                 7);
        g_line_count := SUBSTR(p_order_rec.file_line,
                               50,
                               7);
        g_adj_count := SUBSTR(p_order_rec.file_line,
                              58,
                              7);
        g_payment_count := SUBSTR(p_order_rec.file_line,
                                  66,
                                  7);
        -- Need to read the Order Total based on display distribution of discount records.
        g_acct_order_tot := SUBSTR(p_order_rec.file_line,
                                   73,
                                   13);
        g_header_tot_amt := SUBSTR(p_order_rec.file_line,
                                   180,
                                   13);
        g_tax_tot_amt := SUBSTR(p_order_rec.file_line,
                                86,
                                13);
        g_line_tot_amt := SUBSTR(p_order_rec.file_line,
                                 99,
                                 13);
        g_adj_tot_amt := SUBSTR(p_order_rec.file_line,
                                112,
                                13);
        g_payment_tot_amt := SUBSTR(p_order_rec.file_line,
                                    125,
                                    13);
        -- Read the Process Date from tariler record
        lc_process_date := NVL(TRIM(SUBSTR(p_order_rec.file_line,
                                           193,
                                           14)),
                               TO_CHAR(SYSDATE,
                                       'YYYYMMDDHH24MISS'));

        BEGIN
            IF TO_NUMBER(SUBSTR(lc_process_date,
                                9,
                                2)) < 10
            THEN
                g_process_date :=   TRUNC(TO_DATE(lc_process_date,
                                                  'YYYYMMDDHH24MISS'))
                                  - 1;
            ELSE
                g_process_date := TRUNC(TO_DATE(lc_process_date,
                                                'YYYYMMDDHH24MISS'));
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Error reading Process Date from trailer record :'
                                  || lc_process_date);
                g_process_date := TRUNC(SYSDATE);
        END;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Header Count is :'
                             || g_header_count);
            oe_debug_pub.ADD(   'Line Count is :'
                             || g_line_count);
            oe_debug_pub.ADD(   'Adj Count is :'
                             || g_adj_count);
            oe_debug_pub.ADD(   'Payment Count is :'
                             || g_payment_count);
            oe_debug_pub.ADD(   'Header Amount is :'
                             || g_header_tot_amt);
            oe_debug_pub.ADD(   'Tax Total is :'
                             || g_tax_tot_amt);
            oe_debug_pub.ADD(   'Line Total is :'
                             || g_line_tot_amt);
            oe_debug_pub.ADD(   'Adj Total is :'
                             || g_adj_tot_amt);
            oe_debug_pub.ADD(   'Payment Total is :'
                             || g_payment_tot_amt);
            oe_debug_pub.ADD(   'Process Date derived is :'
                             || g_process_date);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              'Failed to process trailer record ');
            fnd_file.put_line(fnd_file.LOG,
                                 'The error is '
                              || SQLERRM);
    END process_trailer;

    PROCEDURE process_header(
        p_order_rec      IN             order_rec_type,
        p_batch_id       IN             NUMBER,
        p_order_amt      IN OUT NOCOPY  NUMBER,
        p_order_source   IN OUT NOCOPY  VARCHAR2,
        x_return_status  OUT NOCOPY     VARCHAR2)
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
        i                             BINARY_INTEGER;
        lc_order_source               VARCHAR2(20);
        lc_order_type                 VARCHAR2(20);
        lc_salesrep                   VARCHAR2(7);
        lc_sales_channel              VARCHAR2(20);
        lc_sold_to_contact            VARCHAR2(50);
        lc_paid_at_store_id           VARCHAR2(20);
        lc_customer_ref               VARCHAR2(50);
        lc_orig_sys_customer_ref      VARCHAR2(50);
        lc_orig_sys_bill_address_ref  VARCHAR2(50);
        lc_bill_address1              VARCHAR2(80);
        lc_bill_address2              VARCHAR2(80);
        lc_bill_city                  VARCHAR2(80);
        lc_bill_state                 VARCHAR2(2);
        lc_bill_country               VARCHAR2(3);
        lc_bill_zip                   VARCHAR2(15);
        lc_orig_sys_ship_address_ref  VARCHAR2(50);
        lc_ship_address1              VARCHAR2(80);
        lc_ship_address2              VARCHAR2(80);
        lc_ship_city                  VARCHAR2(80);
        lc_ship_state                 VARCHAR2(2);
        lc_ship_country               VARCHAR2(3);
        lc_ship_zip                   VARCHAR2(15);
        lc_orig_order_no              VARCHAR2(50);
        lc_orig_sub_num               VARCHAR2(30);
        lc_return_reason_code         VARCHAR2(50);
        --lc_customer_type           VARCHAR2(20);
        ld_ship_date                  DATE;
        ln_tax_value                  NUMBER;
        ln_us_tax                     NUMBER;
        ln_gst_tax                    NUMBER;
        ln_pst_tax                    NUMBER;
        lc_err_msg                    VARCHAR2(240);
        lc_return_status              VARCHAR2(80);
        --v_return_reason           VARCHAR2(30);
        lc_order_category             VARCHAR2(2);
        lb_store_customer             BOOLEAN        := FALSE;
        lc_return_ref_no              VARCHAR2(30);
        lc_cust_po_number             VARCHAR2(22);
        lc_release_no                 VARCHAR2(12);
        lc_return_act_cat_code        VARCHAR2(100);
        lc_orig_sys                   VARCHAR2(10);
        ln_debug_level       CONSTANT NUMBER         := oe_debug_pub.g_debug_level;
        lc_sas_sale_date              VARCHAR2(10);
        lc_tax_sign                   VARCHAR2(1);
        ln_seq                        NUMBER;
        lc_aops_pos_flag              VARCHAR2(1);
        lc_status                     VARCHAR2(1);
        lc_ord_date                   VARCHAR2(10);
        lc_ord_time                   VARCHAR2(10);
        lc_ord_end_time               VARCHAR2(10);
        ln_freight_customer_ref       NUMBER;
        lc_tran_number                VARCHAR2(60);
        lc_loc_country                VARCHAR2(10)   := NULL;
        lc_opu_country                VARCHAR2(10)   := NULL;
        lc_test_date                  VARCHAR2(10)   := 'N';
        ld_sysdate                    DATE           := SYSDATE;
        ln_order_amt                  NUMBER;
        lc_single_pay_flag            VARCHAR2(1);
        lc_customer_type              VARCHAR2(1);
        lc_serial_count               NUMBER;
    BEGIN
        x_return_status := 'S';
        /* Added by NB to get profile value for test ship date */
        lc_test_date := fnd_profile.VALUE('XX_OM_USE_TEST_SHIP_DATE');
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('Entering  Process Header');
            oe_debug_pub.ADD(   'lc_test_date :'
                             || lc_test_date);
        END IF;

        -- Get the current index for header record
        i :=   g_header_rec.orig_sys_document_ref.COUNT
             + 1;
        g_header_rec.error_flag(i) := NULL;
        g_header_rec.orig_sys_document_ref(i) := RTRIM(SUBSTR(p_order_rec.file_line,
                                                              1,
                                                              20));
        p_order_amt :=    (SUBSTR(p_order_rec.file_line,
                                  268,
                                  1))
                       || SUBSTR(p_order_rec.file_line,
                                 269,
                                 10);

        -- If the current transaction is a POS correction then we will be getting same
        -- value for orig_sys_document_ref. To make it unique,
        -- set the orig_sys_document_ref = orig_sys_doc_ref || sequence value
        IF SUBSTR(p_order_rec.file_line,
                  32,
                  1) IN('A', 'D')
        THEN                                                                               -- If correction_flag is TRUE
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD('Inside Correction Transaction');
            END IF;

            SELECT xx_om_nonsku_line_s.NEXTVAL
            INTO   ln_seq
            FROM   DUAL;

            g_header_rec.orig_sys_document_ref(i) :=    g_header_rec.orig_sys_document_ref(i)
                                                     || '-c-'
                                                     || ln_seq;
        END IF;

        -- Read the order source from file
        lc_order_source := LTRIM(SUBSTR(p_order_rec.file_line,
                                        143,
                                        1));

        -- If no order source comes from SAS then default it to 'O'
        IF lc_order_source IS NULL
        THEN
            lc_order_source := 'O';
        END IF;

        g_header_rec.order_source_cd(i) := SUBSTR(p_order_rec.file_line,
                                                  329,
                                                  1);                                                -- CR 623 system-cd


        g_header_rec.app_id(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                              605,
                                              10));                                                    -- Added for 13.3										  
		IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'app_id            : '
                             || g_header_rec.app_id(i));
        END IF;  




        -- To get order source id
        IF lc_order_source IS NOT NULL
        THEN
            g_header_rec.order_source_id(i) := order_source(p_order_source    => lc_order_source
			                                                ,p_app_id         => g_header_rec.app_id(i)
														   );

            IF g_header_rec.order_source_id(i) IS NULL
            THEN
                set_header_error(i);
                g_header_rec.order_source(i) := lc_order_source;
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg :=    'ORDER_SOURCE_ID NOT FOUND FOR Order Source : '
                              || lc_order_source;
                fnd_message.set_name('XXOM',
                                     'XX_OM_FAILED_ATTR_DERIVATION');
                fnd_message.set_token('ATTRIBUTE',
                                         'ORDER SOURCE - '
                                      || lc_order_source);
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;
        ELSE
            g_header_rec.order_source_id(i) := NULL;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'ordered date'
                             || SUBSTR(p_order_rec.file_line,
                                       33,
                                       10));
            oe_debug_pub.ADD(   'ordered time'
                             || SUBSTR(p_order_rec.file_line,
                                       831,
                                       8));
        END IF;

        BEGIN
            lc_ord_date := TRIM(SUBSTR(p_order_rec.file_line,
                                       33,
                                       10));
            lc_ord_time := TRIM(SUBSTR(p_order_rec.file_line,
                                       831,
                                       8));
            g_header_rec.ordered_date(i) := TO_DATE(   lc_ord_date
                                                    || ' '
                                                    || lc_ord_time,
                                                    'YYYY-MM-DD HH24:MI:SS');
        EXCEPTION
            WHEN OTHERS
            THEN
                g_header_rec.ordered_date(i) := NULL;
                lc_ord_date := NULL;
                lc_ord_time := NULL;
                set_header_error(i);
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg :=
                       'Error reading Ordered Date'
                    || SUBSTR(p_order_rec.file_line,
                              33,
                              10)
                    || ' '
                    || SUBSTR(p_order_rec.file_line,
                              831,
                              8);
                fnd_message.set_name('XXOM',
                                     'XX_OM_READ_ERROR');
                fnd_message.set_token('ATTRIBUTE1',
                                      'Ordred Date');
                fnd_message.set_token('ATTRIBUTE2',
                                      SUBSTR(p_order_rec.file_line,
                                             33,
                                             10));
                fnd_message.set_token('ATTRIBUTE3',
                                      'YYYY-MM-DD HH24:MI:SS');
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
        END;

        g_header_rec.transactional_curr_code(i) := SUBSTR(p_order_rec.file_line,
                                                          43,
                                                          3);
        lc_salesrep := TRIM(SUBSTR(p_order_rec.file_line,
                                   46,
                                   7));
        lc_sales_channel := TRIM(SUBSTR(p_order_rec.file_line,
                                        53,
                                        1));
        g_header_rec.customer_po_number(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                                 98,
                                                                 22)));
        lc_sold_to_contact := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                 120,
                                                 14)));
        lc_aops_pos_flag := LTRIM(SUBSTR(p_order_rec.file_line,
                                         329,
                                         1));
        p_order_source := lc_aops_pos_flag;
        g_header_rec.legacy_order_type(i) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                          216,
                                                          1));
        g_header_rec.drop_ship_flag(i) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                       134,
                                                       1));
        --need to find out from cdh team how many char for orig sys ref
        lc_customer_ref := LTRIM(SUBSTR(p_order_rec.file_line,
                                        218,
                                        8));
        g_header_rec.tax_value(i) := SUBSTR(p_order_rec.file_line,
                                            88,
                                            10);
        lc_tax_sign := SUBSTR(p_order_rec.file_line,
                              87,
                              1);
        g_header_rec.pst_tax_value(i) := SUBSTR(p_order_rec.file_line,
                                                77,
                                                10);

        IF lc_tax_sign = '-'
        THEN
            g_header_rec.pst_tax_value(i) :=   -1
                                             * g_header_rec.pst_tax_value(i);
            g_header_rec.tax_value(i) :=   -1
                                         * g_header_rec.tax_value(i);
        END IF;

        -- Set Order Total
        g_header_rec.order_total(i) := g_header_rec.tax_value(i);

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Next 1'
                             || SUBSTR(p_order_rec.file_line,
                                       283,
                                       8));
        END IF;

        -- If POS order or SPC card or PRO card purchase from POS
        --IF lc_order_source IN ('P','S','U') THEN
        IF lc_aops_pos_flag = 'P'
        THEN
            g_header_rec.return_orig_sys_doc_ref(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                                                   279,
                                                                   20));
            oe_debug_pub.ADD(   'Reading org_order_creation_date'
                             || LTRIM(SUBSTR(p_order_rec.file_line,
                                             283,
                                             8)));

            BEGIN
                g_header_rec.org_order_creation_date(i) :=
                                                      TO_DATE(LTRIM(SUBSTR(p_order_rec.file_line,
                                                                           283,
                                                                           8)),
                                                              'YYYYMMDD');
            EXCEPTION
                WHEN OTHERS
                THEN
                    g_header_rec.org_order_creation_date(i) := NULL;
                    set_header_error(i);
                    set_msg_context(p_entity_code      => 'HEADER');
                    lc_err_msg :=    'Error reading Orig Order Date'
                                  || SUBSTR(p_order_rec.file_line,
                                            283,
                                            8);
                    fnd_message.set_name('XXOM',
                                         'XX_OM_READ_ERROR');
                    fnd_message.set_token('ATTRIBUTE1',
                                          'Orig Order Date');
                    fnd_message.set_token('ATTRIBUTE2',
                                          SUBSTR(p_order_rec.file_line,
                                                 283,
                                                 8));
                    fnd_message.set_token('ATTRIBUTE3',
                                          'YYYYMMDD');
                    oe_bulk_msg_pub.ADD;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(lc_err_msg,
                                         1);
                    END IF;
            END;
        ELSE
            oe_debug_pub.ADD(   'Reading  org_order_creation_date'
                             || LTRIM(SUBSTR(p_order_rec.file_line,
                                             860,
                                             10)));
            g_header_rec.return_orig_sys_doc_ref(i) := SUBSTR(p_order_rec.file_line,
                                                              279,
                                                              12);
            BEGIN
                g_header_rec.org_order_creation_date(i) :=
                                                   TO_DATE(LTRIM(SUBSTR(p_order_rec.file_line,
                                                                        860,
                                                                        10)),
                                                           'YYYY-MM-DD');
            EXCEPTION
                WHEN OTHERS
                THEN
                    g_header_rec.org_order_creation_date(i) := NULL;
                    set_header_error(i);
                    oe_debug_pub.ADD(   'In Error for date'
                                     || LTRIM(SUBSTR(p_order_rec.file_line,
                                                     860,
                                                     10)));
                    set_msg_context(p_entity_code      => 'HEADER');
                    lc_err_msg :=    'Error reading Orig Order Date'
                                  || SUBSTR(p_order_rec.file_line,
                                            860,
                                            10);
                    fnd_message.set_name('XXOM',
                                         'XX_OM_READ_ERROR');
                    fnd_message.set_token('ATTRIBUTE1',
                                          'Orig Order Date');
                    fnd_message.set_token('ATTRIBUTE2',
                                          SUBSTR(p_order_rec.file_line,
                                                 860,
                                                 10));
                    fnd_message.set_token('ATTRIBUTE3',
                                          'YYYY-MM-DD');
                    oe_bulk_msg_pub.ADD;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(lc_err_msg,
                                         1);
                    END IF;
            END;
        END IF;

        BEGIN
            g_header_rec.ship_date(i) := TO_DATE(LTRIM(SUBSTR(p_order_rec.file_line,
                                                              226,
                                                              10)),
                                                 'YYYY-MM-DD');
        EXCEPTION
            WHEN OTHERS
            THEN
                g_header_rec.ship_date(i) := NULL;
                set_header_error(i);
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg :=    'Error reading Ship Date'
                              || SUBSTR(p_order_rec.file_line,
                                        226,
                                        10);
                fnd_message.set_name('XXOM',
                                     'XX_OM_READ_ERROR');
                fnd_message.set_token('ATTRIBUTE1',
                                      'Ship Date');
                fnd_message.set_token('ATTRIBUTE2',
                                      SUBSTR(p_order_rec.file_line,
                                             226,
                                             10));
                fnd_message.set_token('ATTRIBUTE3',
                                      'YYYY-MM-DD');
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
        END;
        -- If no reason is provided for return then we will use CN as reason code.
        lc_return_reason_code := NVL(LTRIM(SUBSTR(p_order_rec.file_line,
                                                  301,
                                                  2)),
                                     'CN');
        lc_return_act_cat_code :=
               NVL(LTRIM(SUBSTR(p_order_rec.file_line,
                                303,
                                2)),
                   'RT')
            || '-'
            || NVL(LTRIM(SUBSTR(p_order_rec.file_line,
                                305,
                                1)),
                   'C')
            || '-'
            || lc_return_reason_code;
        lc_paid_at_store_id := TO_NUMBER(LTRIM(SUBSTR(p_order_rec.file_line,
                                                      135,
                                                      4)));
        g_header_rec.inv_loc_no(i) := TO_NUMBER(LTRIM(SUBSTR(p_order_rec.file_line,
                                                             139,
                                                             4)));
        g_header_rec.spc_card_number(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                              196,
                                                              20)));
        -- Need values from BOB
        g_header_rec.placement_method_code(i) := NULL;
        g_header_rec.advantage_card_number(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                                    236,
                                                                    10)));
        g_header_rec.created_by_id(i) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                      250,
                                                      7));
        g_header_rec.delivery_code(i) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                      328,
                                                      1));
        lc_tran_number := RTRIM(LTRIM(SUBSTR(p_order_rec.file_line,
                                             308,
                                             20)));                                                   --Vertex change NB
        g_header_rec.tax_exempt_amount(i) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                          562,
                                                          10));                                       --Vertex change NB
        g_header_rec.aops_geo_code(i) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                      572,
                                                      9));                                            --Vertex change NB
        g_header_rec.sr_number(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                        581,
                                                        13)));                          -- 11.4 change for parts project
        g_header_rec.delivery_method(i) := RTRIM(SUBSTR(p_order_rec.file_line,
                                                        246,
                                                        3));
        g_header_rec.release_number(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                             144,
                                                             12)));
        g_header_rec.cust_dept_no(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                           156,
                                                           20)));
        g_header_rec.desk_top_no(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                          176,
                                                          20)));
        --   v_return_reason                         := SUBSTR(p_order_rec.file_line,  267,    2);
        g_header_rec.comments(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                       331,
                                                       90)));
        g_header_rec.shipping_instructions(i) := NULL;
        lc_order_category := SUBSTR(p_order_rec.file_line,
                                    217,
                                    1);
        g_header_rec.deposit_amount(i) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                       258,
                                                       10));
        g_header_rec.gift_flag(i) := SUBSTR(p_order_rec.file_line,
                                            839,
                                            1);
        lc_sas_sale_date := LTRIM(SUBSTR(p_order_rec.file_line,
                                         821,
                                         10));
        g_header_rec.tax_exempt_number(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                                         840,
                                                         20));
        /* REL 11.5 Added this condition for Single Pay POS order total AMT */
        ln_order_amt := SUBSTR(p_order_rec.file_line,
                               269,
                               10);
        lc_single_pay_flag := SUBSTR(p_order_rec.file_line,
                                     917,
                                     1);
        -- Added for Release 12.5
        g_header_rec.atr_order_flag(i) := NULL;
        lc_customer_type := SUBSTR(p_order_rec.file_line,
                                   306,
                                   1);
        -- Added for Rel13.1
        g_header_rec.device_serial_num(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                                         1027,
                                                         25));

        IF lc_customer_type = 'C'
        THEN                                                       -- Raj added 8/18/13 for filter to contract customers
            IF g_header_rec.device_serial_num(i) IS NOT NULL
            THEN
                --lc_serial_count := get_serial_no_for_atr(p_serial_no => G_header_rec.customer_po_number(i));
                lc_serial_count :=
                    get_serial_no_for_atr(p_serial_no         => g_header_rec.device_serial_num(i),
                                          p_order_number      => g_header_rec.orig_sys_document_ref(i),
                                          p_ordered_date      => g_header_rec.ordered_date(i));

                -- Raj modified on 8/15/13 by adding MPS type order flag
                IF lc_serial_count = 1
                THEN
                    g_header_rec.atr_order_flag(i) := 'ATR';
                ELSIF lc_serial_count = 2
                THEN
                    g_header_rec.atr_order_flag(i) := 'MPS';
                ELSE
                    g_header_rec.atr_order_flag(i) := NULL;
                END IF;
            END IF;
        END IF;

        g_header_rec.external_transaction_number(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                              		1052,
                                              		25));                                          -- Added for Amz mpl 

        g_header_rec.freight_tax_rate(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                              		1077,
                                              		7));                                           -- Added for Line level tax  -- AG Change

        g_header_rec.freight_tax_amount(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                              		1084,
                                              		9));                                           -- Added for Line level tax  -- AG Change

   
        g_header_rec.bill_level(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                              		615,                                           -- Added for Kitting
                                              		1));   
        g_header_rec.bill_override_flag(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                              		616,                                           -- Added for Kitting
                                              		1));   
        g_header_rec.bill_complete_flag(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                              		1093,
                                              		1));                                           -- Added for bill complete
        g_header_rec.parent_order_number(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                              		1094,
                                              		9));                                           -- Added for bill complete
        g_header_rec.cost_center_split(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                              		1103,
                                              		1));                                           -- Added for bill complete

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'lc_customer_type : '
                             || lc_customer_type);
            oe_debug_pub.ADD(   'lc_serial_count  : '
                             || lc_serial_count);
            oe_debug_pub.ADD(   'atr_order_flag   : '
                             || g_header_rec.atr_order_flag(i));
            oe_debug_pub.ADD(   'device_serial_num : '
                             || g_header_rec.device_serial_num(i));
            oe_debug_pub.ADD(   'external_transaction_number            : '
                             || g_header_rec.external_transaction_number(i));                              
            oe_debug_pub.ADD(   'freight tax amount           : '
                             || g_header_rec.freight_tax_amount(i));   
            oe_debug_pub.ADD(   'freight tax rate             : '
                             || g_header_rec.freight_tax_rate(i));   
            oe_debug_pub.ADD(   'Bill Level             : '
                             || g_header_rec.bill_level(i));   
            oe_debug_pub.ADD(   'bill_override_flag             : '
                             || g_header_rec.bill_override_flag(i));  
            oe_debug_pub.ADD(   'bill_complete_flag             : '
                             || g_header_rec.bill_complete_flag(i)); 
            oe_debug_pub.ADD(   'Parent_Order_Number             : '
                             || g_header_rec.parent_order_number(i)); 
            oe_debug_pub.ADD(   'cost_center_split_flag             : '
                             || g_header_rec.cost_center_split(i));  
        END IF;

        IF     g_header_rec.deposit_amount(i) = 0
           AND ln_order_amt = 0
           AND NVL(lc_single_pay_flag,
                   'N') = 'Y'
           AND lc_aops_pos_flag = 'P'
        THEN
            g_header_rec.deposit_amount(i) :=
                                      (  LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                            595,
                                                            10)))
                                       + g_header_rec.tax_value(i));
        END IF;

        -- transaction number if POS transaction 1st 20 char and for aops it is lc_tran_number
        --MODIFIED BY NB fOR R11.2
        IF lc_aops_pos_flag = 'P'
        THEN
            --IF lc_order_source = 'P' THEN
            g_header_rec.tran_number(i) := g_header_rec.orig_sys_document_ref(i);
        --ELSIF lc_order_source IN ('S','U') THEN
        --    G_header_rec.tran_number(i) := G_header_rec.orig_sys_document_ref(i);
        --    G_header_rec.orig_sys_document_ref(i) := lc_tran_number;
        ELSE
            g_header_rec.tran_number(i) := lc_tran_number;
        END IF;

        IF lc_sas_sale_date IS NOT NULL
        THEN
            BEGIN
                g_header_rec.sas_sale_date(i) := TO_DATE(lc_sas_sale_date,
                                                         'YYYY-MM-DD');
            EXCEPTION
                WHEN OTHERS
                THEN
                    g_header_rec.sas_sale_date(i) := NULL;
                    set_header_error(i);
                    set_msg_context(p_entity_code      => 'HEADER');
                    lc_err_msg :=    'Error reading SAS Sale Date'
                                  || lc_sas_sale_date;
                    fnd_message.set_name('XXOM',
                                         'XX_OM_READ_ERROR');
                    fnd_message.set_token('ATTRIBUTE1',
                                          'SAS Sale Date');
                    fnd_message.set_token('ATTRIBUTE2',
                                          lc_sas_sale_date);
                    fnd_message.set_token('ATTRIBUTE3',
                                          'YYYY-MM-DD');
                    oe_bulk_msg_pub.ADD;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(lc_err_msg,
                                         1);
                    END IF;
            END;
        ELSE                                                              -- For POS the SAS date will come in ship_date
            g_header_rec.sas_sale_date(i) := g_header_rec.ship_date(i);
        END IF;

        --need to change in futher
        lc_orig_sys_bill_address_ref := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                           629,
                                                           5)));
        lc_orig_sys_ship_address_ref := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                           725,
                                                           5)));
        lc_ship_address1 := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                               730,
                                               25)));
        lc_ship_address2 := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                               755,
                                               25)));
        lc_ship_city := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                           780,
                                           25)));
        lc_ship_state := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                            805,
                                            2)));
        lc_ship_zip := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                          807,
                                          11)));
        lc_ship_country := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                              818,
                                              3)));
        g_header_rec.ship_to_county(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                             536,
                                                             25)));
        -- Added code to staore the AOPS address on order header attributes table
        g_header_rec.ship_to_sequence(i) := lc_orig_sys_ship_address_ref;
        g_header_rec.ship_to_address1(i) := lc_ship_address1;
        g_header_rec.ship_to_address2(i) := lc_ship_address2;
        g_header_rec.ship_to_city(i) := lc_ship_city;
        g_header_rec.ship_to_state(i) := lc_ship_state;
        g_header_rec.ship_to_country(i) := lc_ship_country;
        g_header_rec.ship_to_zip(i) := lc_ship_zip;
        g_header_rec.ship_to_geocode(i) := NULL;
        -- Set the booked_flag = Y
        g_header_rec.booked_flag(i) := 'Y';
        g_header_rec.ineligible_for_hvop(i) := NULL;
        g_header_rec.sold_to_org(i) := NULL;
        g_header_rec.sold_to_org_id(i) := NULL;
        g_header_rec.sold_to_contact(i) := NULL;
        g_header_rec.sold_to_contact_id(i) := NULL;
        g_header_rec.ship_to_org(i) := NULL;
        g_header_rec.ship_to_org_id(i) := NULL;
        g_header_rec.invoice_to_org(i) := NULL;
        g_header_rec.invoice_to_org_id(i) := NULL;
        g_header_rec.ship_from_org(i) := NULL;
        g_header_rec.salesrep(i) := NULL;
        g_header_rec.order_source(i) := NULL;
        g_header_rec.sales_channel(i) := NULL;
        g_header_rec.shipping_method(i) := NULL;
        g_header_rec.shipping_method_code(i) := NULL;
        g_header_rec.legacy_cust_name(i) := NULL;
        g_header_rec.deposit_hold_flag(i) := NULL;
        g_header_rec.ship_to_name(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                           421,
                                                           30)));                                       --Modified by NB
        g_header_rec.bill_to_name(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                           451,
                                                           30)));                                       --Modified by NB
        g_header_rec.cust_contact_name(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                                870,
                                                                25)));                                  --Modified by NB
        g_header_rec.cust_pref_phone(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                              895,
                                                              11)));                                    --Modified By NB
        g_header_rec.cust_pref_email(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                              927,
                                                              100)));                        -- Added by NB for Rel 12.4
        g_header_rec.cust_pref_phextn(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                               906,
                                                               4)));                                   -- Modified By NB
        g_header_rec.tax_rate(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                       910,
                                                       7)));
        g_header_rec.is_reference_return(i) := 'N';
        -- added to read the alternate shipper for export orders
        ln_freight_customer_ref := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                      503,
                                                      8)));
        g_header_rec.cust_dept_description(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                                    511,
                                                                    25)));
        -- Get the Datawarehouse attributes
        g_header_rec.commisionable_ind(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                                         481,
                                                         1));
        lc_ord_end_time := TRIM(SUBSTR(p_order_rec.file_line,
                                       484,
                                       8));
        g_header_rec.price_cd(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                                492,
                                                1));
        g_header_rec.order_taxable_cd(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                                        493,
                                                        1));
        g_header_rec.order_action_code(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                                         494,
                                                         3));
        g_header_rec.override_delivery_chg_cd(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                                                497,
                                                                2));
        oe_debug_pub.ADD('Next 4',
                         1);

        -- Derive the Date and time for the start/end times
        IF lc_ord_time IS NOT NULL AND lc_ord_end_time IS NOT NULL AND lc_ord_date IS NOT NULL
        THEN
            BEGIN
                IF lc_ord_end_time >= lc_ord_time
                THEN
                    g_header_rec.order_start_time(i) :=
                                                    TO_DATE(   lc_ord_date
                                                            || ' '
                                                            || lc_ord_time,
                                                            'YYYY-MM-DD HH24:MI:SS');
                ELSE
                    g_header_rec.order_start_time(i) :=
                                                   TO_DATE(   lc_ord_date
                                                           || ' '
                                                           || lc_ord_time,
                                                           'YYYY-MM-DD HH24:MI:SS')
                                                 - 1;
                END IF;

                g_header_rec.order_end_time(i) :=
                                                 TO_DATE(   lc_ord_date
                                                         || ' '
                                                         || lc_ord_end_time,
                                                         'YYYY-MM-DD HH24:MI:SS');
            EXCEPTION
                WHEN OTHERS
                THEN
                    g_header_rec.order_start_time(i) := g_header_rec.ordered_date(i);
                    g_header_rec.order_end_time(i) := NULL;
                    set_msg_context(p_entity_code      => 'HEADER');
                    lc_err_msg :=    'Error reading Order End Time '
                                  || lc_ord_end_time;
                    fnd_message.set_name('XXOM',
                                         'XX_OM_READ_ERROR');
                    fnd_message.set_token('ATTRIBUTE1',
                                          'Order End Date');
                    fnd_message.set_token('ATTRIBUTE2',
                                          lc_ord_end_time);
                    fnd_message.set_token('ATTRIBUTE3',
                                          'HH24:MI:SS');
                    oe_bulk_msg_pub.ADD;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(lc_err_msg,
                                         1);
                    END IF;
            END;
        ELSE
            g_header_rec.order_end_time(i) := NULL;
            g_header_rec.order_start_time(i) := NULL;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'G_Header_Rec count is :'
                             || TO_CHAR(  i
                                        - 1));
            oe_debug_pub.ADD(   'Order Total amount is :'
                             || p_order_amt);
            oe_debug_pub.ADD(   'orig_sys_document_ref = '
                             || g_header_rec.orig_sys_document_ref(i));
            oe_debug_pub.ADD(   'ordered_date = '
                             || g_header_rec.ordered_date(i));
            oe_debug_pub.ADD(   'transactional_curr_code = '
                             || g_header_rec.transactional_curr_code(i));
            oe_debug_pub.ADD(   'lc_salesrep = '
                             || lc_salesrep);
            oe_debug_pub.ADD(   'customer_po_number = '
                             || g_header_rec.customer_po_number(i));
            oe_debug_pub.ADD(   'lc_sold_to_contact = '
                             || lc_sold_to_contact);
            oe_debug_pub.ADD(   'lc_order_source = '
                             || lc_order_source);
            oe_debug_pub.ADD(   'lc_aops_pos_flag = '
                             || lc_aops_pos_flag);
            oe_debug_pub.ADD(   'legacy_order_type = '
                             || g_header_rec.legacy_order_type(i));
            oe_debug_pub.ADD(   'drop_ship_flag = '
                             || g_header_rec.drop_ship_flag(i));
            oe_debug_pub.ADD(   'lc_customer_ref  = '
                             || lc_customer_ref);
            oe_debug_pub.ADD(   'tax_value  = '
                             || g_header_rec.tax_value(i));
            oe_debug_pub.ADD(   'pst_tax_value  = '
                             || g_header_rec.pst_tax_value(i));
            oe_debug_pub.ADD(   'return_ref_no  = '
                             || g_header_rec.return_orig_sys_doc_ref(i));
            oe_debug_pub.ADD(   'ship_date  = '
                             || g_header_rec.ship_date(i));
            oe_debug_pub.ADD(   'lc_return_reason_code  = '
                             || lc_return_reason_code);
            oe_debug_pub.ADD(   'lc_paid_at_store_id  = '
                             || lc_paid_at_store_id);
            oe_debug_pub.ADD(   'Inv Location No  = '
                             || g_header_rec.inv_loc_no(i));
            oe_debug_pub.ADD(   'spc_card_number  = '
                             || g_header_rec.spc_card_number(i));
            oe_debug_pub.ADD(   'advantage_card_number  = '
                             || g_header_rec.advantage_card_number(i));
            oe_debug_pub.ADD(   'created_by_id  = '
                             || g_header_rec.created_by_id(i));
            oe_debug_pub.ADD(   'delivery_code  = '
                             || g_header_rec.delivery_code(i));
            oe_debug_pub.ADD(   'tran_number  = '
                             || g_header_rec.tran_number(i));
            oe_debug_pub.ADD(   'aops_geo_code  = '
                             || g_header_rec.aops_geo_code(i));
            oe_debug_pub.ADD(   'tax_exempt_amount  = '
                             || g_header_rec.tax_exempt_amount(i));
            oe_debug_pub.ADD(   'release_number  = '
                             || g_header_rec.release_number(i));
            oe_debug_pub.ADD(   'cust_dept_no  = '
                             || g_header_rec.cust_dept_no(i));
            oe_debug_pub.ADD(   'cust_dept_desc  = '
                             || g_header_rec.cust_dept_description(i));
            oe_debug_pub.ADD(   'desk_top_no  = '
                             || g_header_rec.desk_top_no(i));
            oe_debug_pub.ADD(   'comments  = '
                             || g_header_rec.comments(i));
            oe_debug_pub.ADD(   'lc_order_category  = '
                             || lc_order_category);
            oe_debug_pub.ADD(   'lc_orig_sys_bill_address_ref = '
                             || lc_orig_sys_bill_address_ref);
            oe_debug_pub.ADD(   'lc_orig_sys_ship_address_ref = '
                             || lc_orig_sys_ship_address_ref);
            oe_debug_pub.ADD(   'addr1 '
                             || lc_ship_address1);
            oe_debug_pub.ADD(   'Addr2 '
                             || lc_ship_address2);
            oe_debug_pub.ADD(   'City '
                             || lc_ship_city);
            oe_debug_pub.ADD(   'State '
                             || lc_ship_state);
            oe_debug_pub.ADD(   'Country '
                             || lc_ship_country);
            oe_debug_pub.ADD(   'zip '
                             || lc_ship_zip);
            oe_debug_pub.ADD(   'Deposit Amount IS :'
                             || g_header_rec.deposit_amount(i));
            oe_debug_pub.ADD(   'Tax Exempt Number IS :'
                             || g_header_rec.tax_exempt_number(i));
            oe_debug_pub.ADD(   'Order Start Time  IS :'
                             || g_header_rec.order_start_time(i));
            oe_debug_pub.ADD(   'Order End Time  IS :'
                             || g_header_rec.order_end_time(i));
            oe_debug_pub.ADD(   'POS CUST EMAIL IS  :'
                             || g_header_rec.cust_pref_email(i));
            oe_debug_pub.ADD('After reading header record ');
        END IF;

        -- Check if the order source is PRO-CARD or SPC-CARD
        -- and no customer reference is sent then give error
        IF lc_order_source IN('S', 'U') AND lc_customer_ref IS NULL
        THEN
            set_header_error(i);
            set_msg_context(p_entity_code      => 'HEADER');
            lc_err_msg := 'Missing Customer reference for PRO/SPC card order : ';
            fnd_message.set_name('XXOM',
                                 'XX_OM_CUST_MISSING_PROSPC');
            oe_bulk_msg_pub.ADD;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(lc_err_msg,
                                 1);
            END IF;
        END IF;

        -- To Get Order Number for SPC and PRO-CARD

        --MODIFIED BY NB fOR R11.2
--    IF lc_order_source IN ('S','U') THEN
--        g_header_rec.order_number(i) := NVL(TO_NUMBER(RTRIM(SUBSTR(p_order_rec.file_line, 308,12))),TO_NUMBER(g_header_rec.orig_sys_document_ref(i)));
--    ELSIF lc_order_source = 'P' THEN
        IF lc_aops_pos_flag = 'P'
        THEN
            g_header_rec.order_number(i) := NULL;
        ELSE
            g_header_rec.order_number(i) := TO_NUMBER(g_header_rec.orig_sys_document_ref(i));
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Order Number is : '
                             || g_header_rec.order_number(i));
        END IF;

        g_header_rec.rcc_transaction(i) := NULL;
        g_header_rec.appid_ordertype_value(i) :=NULL;
        g_header_rec.appid_linetype_value(i)  :=NULL;
        g_header_rec.appid_base_ordertype(i)  :=NULL; 		
        -- To set order type, category , batch_id, request_id and change_sequence
        IF lc_order_category = 'O'
        THEN                                                                                               -- For Orders
            g_header_rec.order_category(i) := 'ORDER';

            --MODIFIED BY NB fOR R11.2
            IF lc_aops_pos_flag = 'P'
            THEN
                oe_debug_pub.ADD('XX_AR_RCC_CUSTOMER_REF ' ||fnd_profile.value('XX_AR_RCC_CUSTOMER_REF'));

                IF lc_customer_ref= NVL(fnd_profile.value('XX_AR_RCC_CUSTOMER_REF'), 'XXX')
                THEN
                   g_header_rec.order_type_id(i) := oe_sys_parameters.VALUE('D-SO-POS-RCC',
                                                                           g_org_id);
                   g_header_rec.rcc_transaction(i) := 'Y';
				ELSIF is_appid_need_ordertype(p_app_id       => g_header_rec.app_id(i),   -- added for the defect#44139
				                              p_order_source => lc_aops_pos_flag,
                                              x_otype_value  => g_header_rec.appid_ordertype_value(i),
                                              x_ltype_value  => g_header_rec.appid_linetype_value(i)
											 )
                THEN 
                  g_header_rec.order_type_id(i) := oe_sys_parameters.VALUE(g_header_rec.appid_ordertype_value(i),
                                                                           g_org_id);
                  g_header_rec.appid_base_ordertype(i) := 'Y';   
                ELSE
                   g_header_rec.order_type_id(i) := oe_sys_parameters.VALUE('D-SO-POS',
                                                                           g_org_id);
                END IF;                                                                 
            ELSE 
               -- Added to support AOPS RCC orders .
              IF lc_customer_ref= NVL(fnd_profile.value('XX_AR_RCC_CUSTOMER_REF'), 'XXX')
              THEN
                g_header_rec.order_type_id(i) := oe_sys_parameters.VALUE('D-SO-AOPS-RCC',
                                                                           g_org_id);
                g_header_rec.rcc_transaction(i) := 'Y';
                g_header_rec.order_number(i) := TO_NUMBER(g_header_rec.orig_sys_document_ref(i));

              ELSIF is_appid_need_ordertype(p_app_id       => g_header_rec.app_id(i),  -- added for the defect#44139
			                                p_order_source => null,
                                             x_otype_value  => g_header_rec.appid_ordertype_value(i),
                                             x_ltype_value  => g_header_rec.appid_linetype_value(i)
											)
              THEN 
                  g_header_rec.order_type_id(i) := oe_sys_parameters.VALUE(g_header_rec.appid_ordertype_value(i),
                                                                           g_org_id);
                  g_header_rec.appid_base_ordertype(i) := 'Y';

             ELSE
               g_header_rec.order_type_id(i) := oe_sys_parameters.VALUE('D-SO',
                                                                         g_org_id); 
  	          END IF;
            END IF;

            g_header_rec.change_sequence(i) := NULL;                                                --'SALES_ACCT_HVOP';
            g_header_rec.batch_id(i) := p_batch_id;
            g_header_rec.request_id(i) := g_request_id;
            --g_header_rec.return_reason(i)  := NULL;   --  Commented by Saritha Oracle AMS Team to derive return reason code for standard orders as well as per ver 3.8.
            g_header_rec.return_reason(i) := return_reason(lc_return_reason_code);
            -- Added by Saritha to derive return reason code from function as per ver 3.8
            g_header_rec.return_act_cat_code(i) := NULL;
        ELSE                                                                               -- for Mixed or return orders
            IF lc_aops_pos_flag = 'P'
            THEN

                oe_debug_pub.ADD('XX_AR_RCC_CUSTOMER_REF ' ||fnd_profile.value('XX_AR_RCC_CUSTOMER_REF'));

                IF lc_customer_ref=  NVL(fnd_profile.value('XX_AR_RCC_CUSTOMER_REF'),'XXX')
                THEN
                   g_header_rec.order_type_id(i) := oe_sys_parameters.VALUE('D-RO-POS-RCC',
                                                                           g_org_id);

                   g_header_rec.rcc_transaction(i) := 'Y';

                ELSE
                   g_header_rec.order_type_id(i) := oe_sys_parameters.VALUE('D-RO-POS',
                                                                           g_org_id);
                END IF;                                                                 
            ELSE
              -- Added to Support AOPS RCC orders ..
             IF lc_customer_ref= NVL(fnd_profile.value('XX_AR_RCC_CUSTOMER_REF'), 'XXX')
             THEN
                 g_header_rec.order_type_id(i) := oe_sys_parameters.VALUE('D-RO-AOPS-RCC',
                                                                           g_org_id);
                 g_header_rec.rcc_transaction(i) := 'Y';
                 g_header_rec.order_number(i) := TO_NUMBER(g_header_rec.orig_sys_document_ref(i));
             ELSE
			       g_header_rec.order_type_id(i) := oe_sys_parameters.VALUE('D-RO',g_org_id);
             END IF;
            END IF;

            g_header_rec.change_sequence(i) := NULL;                                                 --'SALES_ACCT_SOI';
            g_header_rec.order_category(i) := 'MIXED';
            g_header_rec.return_reason(i) := return_reason(lc_return_reason_code);
            g_header_rec.batch_id(i) := NULL;
            g_header_rec.request_id(i) := NULL;
            g_header_rec.return_act_cat_code(i) := get_ret_actcatreason_code(lc_return_act_cat_code);

            IF g_header_rec.return_act_cat_code(i) IS NULL
            THEN
                set_header_error(i);
                g_header_rec.return_act_cat_code(i) := lc_return_act_cat_code;
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg :=    'Return Action Category Reason Invalid : '
                              || lc_return_act_cat_code;
                fnd_message.set_name('XXOM',
                                     'XX_OM_REQ_ATTR_MISSING');
                fnd_message.set_token('ATTRIBUTE',
                                      'Return Action Category Reason');
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;
        END IF;

        -- To get Price List Id
        g_header_rec.price_list_id(i) := oe_sys_parameters.VALUE('XX_OM_SAS_PRICE_LIST',
                                                                 g_org_id);

        -- To get Inv Location (ship_from_org_id)
        IF g_header_rec.inv_loc_no(i) IS NOT NULL
        THEN
            g_header_rec.ship_from_org_id(i) := get_organization_id(g_header_rec.inv_loc_no(i));

            IF g_header_rec.ship_from_org_id(i) IS NULL
            THEN
                set_header_error(i);
                g_header_rec.ship_from_org(i) := g_header_rec.inv_loc_no(i);
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg :=    'SHIP_FROM_ORG_ID NOT FOUND FOR SALE LOCATION ID : '
                              || g_header_rec.inv_loc_no(i);
                fnd_message.set_name('XXOM',
                                     'XX_OM_FAIL_SHIPFROM_DERIVATION');
                fnd_message.set_token('ATTRIBUTE1',
                                      g_header_rec.inv_loc_no(i));
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;
        ELSE
            g_header_rec.ship_from_org(i) := NULL;
            g_header_rec.ship_from_org_id(i) := NULL;
        END IF;

        -- To get sale store id - Need different values but right now we are deriving it based on
        -- Sale Location Id
        -- To get paid at store id
        IF lc_paid_at_store_id IS NOT NULL
        THEN
            oe_debug_pub.ADD('Get Store details',
                             1);
            g_header_rec.paid_at_store_no(i) := lc_paid_at_store_id;
            -- Load the Org only if it is of type STORE.
            -- Validation to check location belong to same operating unit
            lc_loc_country := get_store_country(g_header_rec.paid_at_store_no(i));
            lc_opu_country := get_org_code(g_org_id);

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Store Location: '
                                 || g_header_rec.paid_at_store_no(i));
                oe_debug_pub.ADD(   'Store Location Country: '
                                 || lc_loc_country);
                oe_debug_pub.ADD(   'Operating Unit Country: '
                                 || lc_opu_country);
                oe_debug_pub.ADD( 'RCC transaction :'
                                  ||  g_header_rec.rcc_transaction(i));
				oe_debug_pub.ADD( 'APP ID Order Type :'
                                  ||  g_header_rec.appid_ordertype_value(i));
                oe_debug_pub.ADD( 'APP ID Line Type :'
                                  ||  g_header_rec.appid_linetype_value(i));
				oe_debug_pub.ADD( 'APP Id Base Order Type :'
                                  ||  g_header_rec.appid_base_ordertype(i));				  

            END IF;

            IF lc_loc_country = lc_opu_country
            THEN
                g_header_rec.paid_at_store_id(i)    := get_store_id(lc_paid_at_store_id);
                g_header_rec.created_by_store_id(i) := g_header_rec.paid_at_store_id(i);
            ELSE
                g_header_rec.paid_at_store_id(i) := NULL;
                g_header_rec.created_by_store_id(i) := NULL;
                set_header_error(i);
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg :=    'Store Location is in wrong operating unit: '
                              || g_header_rec.paid_at_store_no(i);
                fnd_message.set_name('XXOM',
                                     'XX_OM_WRONG_OP_UNIT');
                fnd_message.set_token('ATTRIBUTE1',
                                      g_header_rec.paid_at_store_no(i));
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;
        ELSE
            g_header_rec.paid_at_store_id(i) := NULL;
            g_header_rec.paid_at_store_no(i) := NULL;
            g_header_rec.created_by_store_id(i) := NULL;
        END IF;

        -- To get Salesrep ID
        IF lc_salesrep IS NOT NULL
        THEN
            --   g_header_rec.salesrep_id(i) := sales_rep(lc_salesrep);
            g_header_rec.salesrep_id(i) :=
                get_salesrep_for_legacyrep(p_org_id          => g_org_id,
                                           p_sales_rep       => lc_salesrep,
                                           p_as_of_date      => ld_sysdate);

            IF g_header_rec.salesrep_id(i) IS NULL
            THEN
                -- Need to bypass this validation till we get the actual salesrep conversion data
                --Set_Header_Error(i);
                --g_header_rec.salesrep(i) := lc_salesrep;
                set_msg_context(p_entity_code       => 'HEADER',
                                p_warning_flag      => TRUE);
                lc_err_msg :=    'SALESREP_ID NOT FOUND FOR SALES REP : '
                              || lc_salesrep;
                fnd_message.set_name('XXOM',
                                     'XX_OM_FAIL_SALESREP_DERIVATION');
                fnd_message.set_token('ATTRIBUTE1',
                                      lc_salesrep);
                fnd_message.set_token('ATTRIBUTE2',
                                      g_header_rec.orig_sys_document_ref(i));

                --    oe_bulk_msg_pub.add;
                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;

                -- Commenting out the salesrep derivation since CRM has provided conversion data
                -- for salesreps.
                g_header_rec.salesrep_id(i) := fnd_profile.VALUE('ONT_DEFAULT_PERSON_ID');
            END IF;
        ELSE
            g_header_rec.salesrep_id(i) := fnd_profile.VALUE('ONT_DEFAULT_PERSON_ID');
        END IF;

        -- To get sales channel code
        IF lc_sales_channel IS NOT NULL
        THEN
            g_header_rec.sales_channel_code(i) := sales_channel(lc_sales_channel);

            IF g_header_rec.sales_channel_code(i) IS NULL
            THEN
                set_header_error(i);
                g_header_rec.sales_channel(i) := lc_sales_channel;
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg :=    'SALES_CHANNEL_CODE NOT FOUND FOR SALES CHANNEL : '
                              || lc_sales_channel;
                fnd_message.set_name('XXOM',
                                     'XX_OM_FAIL_SALESC_DERIVATION');
                fnd_message.set_token('ATTRIBUTE1',
                                      lc_sales_channel);
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;
        ELSE
            g_header_rec.sales_channel_code(i) := NULL;
        END IF;

        -- To get customer_id
        IF lc_customer_ref IS NULL
        THEN
            -- It could be store order
            g_header_rec.sold_to_org_id(i) := NULL;

            IF g_header_rec.paid_at_store_no(i) IS NULL
            THEN
                -- Need to give error if POS order but missing store location
                set_header_error(i);
                g_header_rec.sold_to_org_id(i) := NULL;
                g_header_rec.sold_to_org(i) := lc_customer_ref;
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg :=    'SOLD_TO_ORG_ID NOT FOUND FOR ORIG_SYS_CUSTOMER_ID : '
                              || lc_customer_ref;
                fnd_message.set_name('XXOM',
                                     'XX_OM_MISSING_CUST_REF');
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            ELSE
                -- Format the customer reference as stored in OSR table in hz_orig_sys_references
                lc_orig_sys_customer_ref :=
                       LPAD(g_header_rec.paid_at_store_no(i),
                            6,
                            '0')
                    || get_store_country(g_header_rec.paid_at_store_no(i));
                lc_orig_sys := 'RMS';                                                              -- For store customer
                lb_store_customer := TRUE;
            END IF;
        ELSE
            -- Format the customer reference as stored in OSR table in hz_orig_sys_references
            lc_orig_sys_customer_ref :=    lc_customer_ref
                                        || '-00001-A0';
            lc_orig_sys := 'A0';                                                   -- OSR for legacy converted customers
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Customer Ref is :'
                             || lc_orig_sys_customer_ref);
        END IF;

        -- Get the Sold_to_Org_Id (Customer Account) for the customer reference
        IF lc_orig_sys_customer_ref IS NOT NULL
        THEN
            IF lb_store_customer
            THEN
                -- Check if the customer already exists in the cache
                IF g_sold_to_org_id.EXISTS(lc_orig_sys_customer_ref)
                THEN
                    g_header_rec.sold_to_org_id(i) := g_sold_to_org_id(lc_orig_sys_customer_ref);
                END IF;
            END IF;

            IF g_header_rec.sold_to_org_id(i) IS NULL
            THEN
                 -- Call the cross reference API from CDH to get sold_to_org_id
                 -- commenting out the standard API and using custom API to improve performance
                /* HZ_ORIG_SYSTEM_REF_PUB.get_owner_table_id(
                                    p_orig_system => lc_orig_sys,
                                    p_orig_system_reference => lc_orig_sys_customer_ref,
                                    p_owner_table_name => 'HZ_CUST_ACCOUNTS',
                                    x_owner_table_id => g_header_rec.sold_to_org_id(i),
                                    x_return_status =>  lc_return_status );
                */
                get_owner_table_id(p_orig_system                => lc_orig_sys,
                                   p_orig_system_reference      => lc_orig_sys_customer_ref,
                                   p_owner_table                => 'HZ_CUST_ACCOUNTS',
                                   x_owner_table_id             => g_header_rec.sold_to_org_id(i),
                                   x_return_status              => lc_return_status);

                -- Check if it is PRO CARD Order
                IF lc_order_source = 'U' AND g_header_rec.sold_to_org_id(i) IS NULL
                THEN
                    -- Need to treat it as POS order
                    lb_store_customer := TRUE;
                    lc_orig_sys := 'RMS';
                    lc_orig_sys_customer_ref :=
                           LPAD(g_header_rec.paid_at_store_no(i),
                                6,
                                '0')
                        || get_store_country(g_header_rec.paid_at_store_no(i));
                    lc_order_source := 'P';
                    g_header_rec.order_source_id(i) := order_source(p_order_source    => lc_order_source
					                                               ,p_app_id          => g_header_rec.app_id(i)
																   );
                    lc_orig_sys_ship_address_ref := NULL;

                    -- Check the store customer cache
                    IF g_sold_to_org_id.EXISTS(lc_orig_sys_customer_ref)
                    THEN
                        g_header_rec.sold_to_org_id(i) := g_sold_to_org_id(lc_orig_sys_customer_ref);
                    ELSE
                        -- Call the cross reference API from CDH to get sold_to_org_id
                        -- commenting out the standard API and using custom API to improve performance
                        /*HZ_ORIG_SYSTEM_REF_PUB.get_owner_table_id(
                                    p_orig_system => lc_orig_sys,
                                    p_orig_system_reference => lc_orig_sys_customer_ref,
                                    p_owner_table_name => 'HZ_CUST_ACCOUNTS',
                                    x_owner_table_id => g_header_rec.sold_to_org_id(i),
                                    x_return_status =>  lc_return_status );
                        */
                        get_owner_table_id(p_orig_system                => lc_orig_sys,
                                           p_orig_system_reference      => lc_orig_sys_customer_ref,
                                           p_owner_table                => 'HZ_CUST_ACCOUNTS',
                                           x_owner_table_id             => g_header_rec.sold_to_org_id(i),
                                           x_return_status              => lc_return_status);
                    END IF;
                END IF;

                IF g_header_rec.sold_to_org_id(i) IS NULL AND(lc_return_status <> fnd_api.g_ret_sts_success)
                THEN
                    set_header_error(i);
                    g_header_rec.sold_to_org(i) := lc_orig_sys_customer_ref;

                    IF NOT lb_store_customer
                    THEN
                        g_header_rec.ship_to_org(i) :=    lc_customer_ref
                                                       || '-'
                                                       || lc_orig_sys_ship_address_ref
                                                       || '-A0';
                    ELSE
                        g_header_rec.ship_to_org(i) := NULL;
                    END IF;

                    set_msg_context(p_entity_code      => 'HEADER');
                    lc_err_msg :=    'SOLD_TO_ORG_ID NOT FOUND FOR ORIG_SYS_CUSTOMER_ID : '
                                  || lc_orig_sys_customer_ref;
                    fnd_message.set_name('XXOM',
                                         'XX_OM_FAIL_CUSTACCT_DERIVATION');
                    fnd_message.set_token('ATTRIBUTE1',
                                          lc_orig_sys_customer_ref);
                    oe_bulk_msg_pub.ADD;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(lc_err_msg,
                                         1);
                    END IF;
                ELSE
                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(   'The Customer Account Found: '
                                         || g_header_rec.sold_to_org_id(i));
                    END IF;
                END IF;

                -- Set the value in Store customer Cache
                IF lb_store_customer AND g_header_rec.sold_to_org_id(i) IS NOT NULL
                THEN
                    g_sold_to_org_id(lc_orig_sys_customer_ref) := g_header_rec.sold_to_org_id(i);
                END IF;
            END IF;

            -- Get the party name to be stored in as customer name on the order.
            IF g_header_rec.sold_to_org_id(i) IS NOT NULL
            THEN
                -- If store customer and party name exists in CACHE
                IF lb_store_customer AND g_party_name.EXISTS(lc_orig_sys_customer_ref)
                THEN
                    g_header_rec.legacy_cust_name(i) := g_party_name(lc_orig_sys_customer_ref);
                ELSE
                    BEGIN
                        SELECT party_name
                        INTO   g_header_rec.legacy_cust_name(i)
                        FROM   hz_cust_accounts hca,
                               hz_parties hp
                        WHERE  hca.cust_account_id = g_header_rec.sold_to_org_id(i) AND hca.party_id = hp.party_id;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            g_header_rec.legacy_cust_name(i) := NULL;
                    END;

                    -- Set the value in Cache only for store customer
                    IF lb_store_customer
                    THEN
                        g_party_name(lc_orig_sys_customer_ref) := g_header_rec.legacy_cust_name(i);
                    END IF;
                END IF;                                                                          -- IF lb_store_customer
            END IF;                                                      -- IF g_header_rec.sold_to_org_id(i) IS NOT NUL
        END IF;                                                               -- IF lc_orig_sys_customer_ref IS NOT NULL

        -- Get sold to contact id using the reference
        IF lc_sold_to_contact IS NOT NULL AND g_header_rec.sold_to_org_id(i) IS NOT NULL
        THEN
            -- commenting out the standard API and using custom API to improve performance
            /*HZ_ORIG_SYSTEM_REF_PUB.get_owner_table_id(p_orig_system => 'A0',
                                   p_orig_system_reference => lc_sold_to_contact,
                                   p_owner_table_name =>'HZ_CUST_ACCOUNT_ROLES',
                                   x_owner_table_id => g_header_rec.sold_to_contact_id(i),
                                   x_return_status =>  lc_return_status);
            */
            get_owner_table_id(p_orig_system                => 'A0',
                               p_orig_system_reference      => lc_sold_to_contact,
                               p_owner_table                => 'HZ_CUST_ACCOUNT_ROLES',
                               x_owner_table_id             => g_header_rec.sold_to_contact_id(i),
                               x_return_status              => lc_return_status);

            IF (lc_return_status <> fnd_api.g_ret_sts_success)
            THEN
                --Set_Header_Error(i);
                g_header_rec.sold_to_contact_id(i) := NULL;
                --g_header_rec.sold_to_contact(i) := lc_sold_to_contact;
                set_msg_context(p_entity_code       => 'HEADER',
                                p_warning_flag      => TRUE);
                lc_err_msg :=    'SOLD_TO_CONTACT_ID NOT FOUND FOR SOLD TO CONTACT : '
                              || lc_sold_to_contact;
                fnd_message.set_name('XXOM',
                                     'XX_OM_FAIL_CONTACT_DERIVATION');
                fnd_message.set_token('ATTRIBUTE1',
                                      lc_sold_to_contact);
                fnd_message.set_token('ATTRIBUTE2',
                                      g_header_rec.orig_sys_document_ref(i));
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            ELSE
                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD
                                 (   'Successfully derived the sold_to_contact, now trying to validate against account'
                                  || g_header_rec.sold_to_contact_id(i));
                END IF;

                -- Validate if the Sold_To_Contact is a valid contact for the derived sold_to_org_id
                BEGIN
                    SELECT status
                    INTO   lc_status
                    FROM   hz_cust_account_roles
                    WHERE  cust_account_role_id = g_header_rec.sold_to_contact_id(i)
                    AND    cust_account_id = g_header_rec.sold_to_org_id(i)
                    AND    status = 'A';
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        -- Not a valid contact or contact does not exist for the account.
                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD(' Contact does not exists for the account or it is inactive ');
                        END IF;

                        set_msg_context(p_entity_code       => 'HEADER',
                                        p_warning_flag      => TRUE);
                        fnd_message.set_name('XXOM',
                                             'XX_OM_INVALID_CONTACT_WARNING');
                        fnd_message.set_token('ATTRIBUTE1',
                                              g_header_rec.sold_to_contact_id(i));
                        fnd_message.set_token('ATTRIBUTE2',
                                              g_header_rec.sold_to_org_id(i));
                        fnd_message.set_token('ATTRIBUTE3',
                                              g_header_rec.orig_sys_document_ref(i));
                        oe_bulk_msg_pub.ADD;
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
            IF g_header_rec.deposit_amount(i) > 0
            THEN
                -- Check if the Payment Term is already fetched for DEPOSIT
                g_header_rec.payment_term_id(i) := g_deposit_term_id;
            ELSE
                -- Get the payment term from Customer Account setup
                g_header_rec.payment_term_id(i) := payment_term(g_header_rec.sold_to_org_id(i));
            END IF;

            IF g_header_rec.payment_term_id(i) IS NULL
            THEN
                set_header_error(i);
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg :=    'PAYMENT_TERM_ID NOT FOUND FOR Customer ID : '
                              || g_header_rec.sold_to_org_id(i);
                fnd_message.set_name('XXOM',
                                     'XX_OM_FAIL_PAYTERM_DERIVATION');
                fnd_message.set_token('ATTRIBUTE1',
                                      g_header_rec.sold_to_org_id(i));
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;
        ELSE
            g_header_rec.payment_term_id(i) := NULL;
        END IF;

        -- Get Accounting Rule Id
        IF NOT g_accounting_rule_id.EXISTS(g_header_rec.order_type_id(i))
        THEN
            BEGIN
                SELECT accounting_rule_id, 
                       invoicing_rule_id
                INTO   g_accounting_rule_id(g_header_rec.order_type_id(i)),
                       g_header_rec.invoicing_rule_id(i)
                FROM   oe_order_types_v
                WHERE  order_type_id = g_header_rec.order_type_id(i);

                g_header_rec.accounting_rule_id(i) := g_accounting_rule_id(g_header_rec.order_type_id(i));

             EXCEPTION
                WHEN OTHERS
                THEN
                    g_header_rec.accounting_rule_id(i) := NULL;
            END;
        ELSE
            g_header_rec.accounting_rule_id(i) := g_accounting_rule_id(g_header_rec.order_type_id(i));
        END IF;

        IF g_header_rec.sold_to_org_id(i) IS NOT NULL
        THEN
            -- To get ship_to for store customers, or SPC Card purchase or Pro Card purchase */
            IF    lb_store_customer
               OR ((lc_order_source = 'S' OR lc_order_source = 'U') AND lc_orig_sys_ship_address_ref IS NULL)
            THEN
                -- For store customers, SAS feed will not be sending us the shipto and billto
                -- references. We will use the default BillTo and ShipTo for them
                get_def_shipto(p_cust_account_id      => g_header_rec.sold_to_org_id(i),
                               x_ship_to_org_id       => g_header_rec.ship_to_org_id(i));

                IF g_header_rec.ship_to_org_id(i) IS NULL
                THEN
                    set_header_error(i);
                    set_msg_context(p_entity_code      => 'HEADER');
                    lc_err_msg :=    'No Ship To found for the store customer : '
                                  || g_header_rec.sold_to_org_id(i);
                    fnd_message.set_name('XXOM',
                                         'XX_OM_NO_DEF_SHIPTO');
                    fnd_message.set_token('ATTRIBUTE',
                                          lc_orig_sys_customer_ref);
                    oe_bulk_msg_pub.ADD;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(lc_err_msg,
                                         1);
                    END IF;
                END IF;

                get_def_billto(p_cust_account_id      => g_header_rec.sold_to_org_id(i),
                               x_bill_to_org_id       => g_header_rec.invoice_to_org_id(i));

                IF g_header_rec.invoice_to_org_id(i) IS NULL
                THEN
                    set_header_error(i);
                    set_msg_context(p_entity_code      => 'HEADER');
                    lc_err_msg :=    'No Bill To found for the store customer : '
                                  || g_header_rec.sold_to_org_id(i);
                    fnd_message.set_name('XXOM',
                                         'XX_OM_NO_DEF_BILLTO');
                    fnd_message.set_token('ATTRIBUTE',
                                          lc_orig_sys_customer_ref);
                    oe_bulk_msg_pub.ADD;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(lc_err_msg,
                                         1);
                    END IF;
                END IF;
            ELSE                  -- For non-store customers e.g. AOPS orders and SPC/PRO card orders with ship sequence
                lc_orig_sys_ship_address_ref :=    lc_customer_ref
                                                || '-'
                                                || lc_orig_sys_ship_address_ref
                                                || '-A0';

                /* Rel 11.2 SDR Single Payment Change */
                IF g_header_rec.deposit_amount(i) > 0 AND lc_order_source = 'P'
                THEN
                    lc_orig_sys_ship_address_ref :=    lc_customer_ref
                                                    || '-'
                                                    || '00001'
                                                    || '-A0';
                END IF;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'Ship REf2 '
                                     || lc_orig_sys_ship_address_ref);
                    oe_debug_pub.ADD(   'Sold To Org Is '
                                     || g_header_rec.sold_to_org_id(i));
                    oe_debug_pub.ADD(   'Ordered Date IS '
                                     || g_header_rec.ordered_date(i));
                    oe_debug_pub.ADD(   'Orig Sys Doc Ref '
                                     || g_header_rec.orig_sys_document_ref(i));
                END IF;

                IF NVL(ln_freight_customer_ref,
                       0) <> 0 AND g_header_rec.legacy_order_type(i) = 'X'
                THEN
                    lc_orig_sys_ship_address_ref :=    ln_freight_customer_ref
                                                    || '-00001-A0';

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(   'Freight Forwarders Ship Ref :'
                                         || lc_orig_sys_ship_address_ref);
                    END IF;
                END IF;

                derive_ship_to(p_orig_sys_document_ref      => g_header_rec.orig_sys_document_ref(i),
                               p_sold_to_org_id             => g_header_rec.sold_to_org_id(i),
                               p_order_source_id            => '',
                               p_orig_sys_ship_ref          => lc_orig_sys_ship_address_ref,
                               p_ordered_date               => g_header_rec.ordered_date(i),
                               p_address_line1              => lc_ship_address1,
                               p_address_line2              => lc_ship_address2,
                               p_city                       => lc_ship_city,
                               p_state                      => lc_ship_state,
                               p_country                    => lc_ship_country,
                               p_province                   => '',
                               p_postal_code                => lc_ship_zip,
                               p_order_source               => lc_order_source,
                               x_ship_to_org_id             => g_header_rec.ship_to_org_id(i),
                               x_invoice_to_org_id          => g_header_rec.invoice_to_org_id(i),
                               x_ship_to_geocode            => g_header_rec.ship_to_geocode(i));

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'Ship_to_org_id :'
                                     || g_header_rec.ship_to_org_id(i));
                    oe_debug_pub.ADD(   'Invoice_to_org_id :'
                                     || g_header_rec.invoice_to_org_id(i));
                    oe_debug_pub.ADD(   'Ship_to_geocode :'
                                     || g_header_rec.ship_to_geocode(i));
                END IF;

                IF g_header_rec.ship_to_org_id(i) IS NULL
                THEN
                    set_header_error(i);
                    set_msg_context(p_entity_code      => 'HEADER');
                    g_header_rec.ship_to_org(i) := lc_orig_sys_ship_address_ref;
                    lc_err_msg :=    'Not able to find the ShipTo for : '
                                  || lc_orig_sys_ship_address_ref;
                    fnd_message.set_name('XXOM',
                                         'XX_OM_FAIL_SHIPTO_DERIVATION');
                    fnd_message.set_token('ATTRIBUTE',
                                          lc_orig_sys_ship_address_ref);
                    oe_bulk_msg_pub.ADD;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(lc_err_msg,
                                         1);
                    END IF;
                END IF;

                -- If no default billTo setup for the shipto then use the Primary BillTo on the order
                IF g_header_rec.invoice_to_org_id(i) IS NULL
                THEN
                    -- Get Primary BillTo for the customer account
                    get_def_billto(p_cust_account_id      => g_header_rec.sold_to_org_id(i),
                                   x_bill_to_org_id       => g_header_rec.invoice_to_org_id(i));

                    IF g_header_rec.invoice_to_org_id(i) IS NULL
                    THEN
                        set_header_error(i);
                        set_msg_context(p_entity_code      => 'HEADER');
                        lc_err_msg :=    'No Bill To found for the customer : '
                                      || g_header_rec.sold_to_org_id(i);
                        fnd_message.set_name('XXOM',
                                             'XX_OM_NO_DEF_BILLTO');
                        fnd_message.set_token('ATTRIBUTE',
                                              lc_orig_sys_customer_ref);
                        oe_bulk_msg_pub.ADD;

                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD(lc_err_msg,
                                             1);
                        END IF;
                    END IF;
                END IF;
            END IF;                                                                           -- for non-store customers
        ELSE                                                                           -- g_header_rec.sold_to_org_id(i)
            g_header_rec.ship_to_org_id(i) := NULL;
            g_header_rec.invoice_to_org_id(i) := NULL;
            g_header_rec.ship_to_geocode(i) := NULL;
        END IF;

        -- For SPC and PRO card orders, get the Soft Header Info and Actual ShipTo address
        IF     lc_order_source IN('S', 'U')
           AND g_header_rec.sold_to_org_id(i) IS NOT NULL
           AND g_header_rec.ship_to_org_id(i) IS NOT NULL
           AND g_header_rec.invoice_to_org_id(i) IS NOT NULL
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
                SELECT address1,
                       address2,
                       city,
                       state,
                       country,
                       postal_code,
                       county
                INTO   g_header_rec.ship_to_address1(i),
                       g_header_rec.ship_to_address2(i),
                       g_header_rec.ship_to_city(i),
                       g_header_rec.ship_to_state(i),
                       g_header_rec.ship_to_country(i),
                       g_header_rec.ship_to_zip(i),
                       g_header_rec.ship_to_county(i)
                FROM   hz_cust_site_uses_all site,
                       hz_party_sites party_site,
                       hz_locations loc,
                       hz_cust_acct_sites_all acct_site
                WHERE  site.site_use_id = g_header_rec.ship_to_org_id(i)
                AND    acct_site.cust_account_id = g_header_rec.sold_to_org_id(i)
                AND    site.site_use_code = 'SHIP_TO'
                AND    site.org_id = g_org_id
                AND    site.cust_acct_site_id = acct_site.cust_acct_site_id
                AND    acct_site.party_site_id = party_site.party_site_id
                AND    party_site.location_id = loc.location_id;
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'Failed to get either the soft header or shipto address for '
                                      || g_header_rec.orig_sys_document_ref(i));
            END;
        END IF;

        -- Get the Ship_Method_Code for Header record
        IF g_header_rec.delivery_method(i) IS NOT NULL
        THEN
            g_header_rec.shipping_method_code(i) := get_ship_method(g_header_rec.delivery_method(i));

            IF g_header_rec.shipping_method_code(i) IS NULL
            THEN
                set_header_error(i);
                g_header_rec.shipping_method(i) := g_header_rec.delivery_method(i);
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg :=    'No Shipping Method found for : '
                              || g_header_rec.delivery_method(i);
                fnd_message.set_name('XXOM',
                                     'XX_OM_NO_SHIP_METHOD');
                fnd_message.set_token('ATTRIBUTE',
                                      g_header_rec.delivery_method(i));
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;
        END IF;

        -- Read Tax Exemption Details
        IF g_header_rec.tax_exempt_number(i) IS NOT NULL
        THEN
            g_header_rec.tax_exempt_reason(i) := 'EXEMPT';
            g_header_rec.tax_exempt_flag(i) := 'E';
        ELSE
            g_header_rec.tax_exempt_reason(i) := NULL;
            g_header_rec.tax_exempt_flag(i) := 'S';
        END IF;

        -- If the order is for TAX CREDIT ONLY orders then it will not have any line records.
        -- We will need to create one line record with dummy item = 'TAX REFUND'.
        IF SUBSTR(g_header_rec.return_act_cat_code(i),
                  1,
                  2) = 'ST'
        THEN
            -- Create an order line with dummy item for TAX REFUND
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD('This is a TAX REFUND ORDER',
                                 1);
            END IF;

            create_tax_refund_line(p_hdr_idx        => i,
                                   p_order_rec      => p_order_rec);
        END IF;

        /* Added the below validation for testing orders with common dates for all waves in a cycle by passing it by system param Modified by NB */
        IF lc_test_date = 'Y'
        THEN
            --G_header_rec.ordered_date(i) := G_header_rec.ordered_date(i);
            g_header_rec.ordered_date(i) :=
                NVL(TO_DATE(oe_sys_parameters.VALUE('XX_OM_ORDERED_DATE',
                                                    g_org_id),
                            'YYYY/MM/DD HH24:MI:SS'),
                    g_header_rec.ordered_date(i));
            g_header_rec.ship_date(i) :=
                NVL(TO_DATE(oe_sys_parameters.VALUE('XX_OM_SHIP_DATE',
                                                    g_org_id),
                            'YYYY/MM/DD HH24:MI:SS'),
                    g_header_rec.ship_date(i));
            g_header_rec.sas_sale_date(i) :=
                NVL(TO_DATE(oe_sys_parameters.VALUE('XX_OM_SHIP_DATE',
                                                    g_org_id),
                            'YYYY/MM/DD HH24:MI:SS'),
                    g_header_rec.sas_sale_date(i));
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Order Type is '
                             || g_header_rec.order_type_id(i));
            oe_debug_pub.ADD(   'Change Seq is '
                             || g_header_rec.change_sequence(i));
            oe_debug_pub.ADD(   'Order Category is '
                             || g_header_rec.order_category(i));
            oe_debug_pub.ADD(   'Return Reason is '
                             || g_header_rec.return_reason(i));
            oe_debug_pub.ADD(   'Request_id '
                             || g_request_id);
            oe_debug_pub.ADD(   'Order Source is '
                             || g_header_rec.order_source_id(i));
            oe_debug_pub.ADD(   'Price List Id is  '
                             || g_header_rec.price_list_id(i));
            oe_debug_pub.ADD(   'Shipping Method is  '
                             || g_header_rec.shipping_method_code(i));
            oe_debug_pub.ADD(   'Salesrep is  '
                             || g_header_rec.salesrep_id(i));
            oe_debug_pub.ADD(   'Sale Channel is  '
                             || g_header_rec.sales_channel_code(i));
            oe_debug_pub.ADD(   'Warehouse is  '
                             || g_header_rec.ship_from_org_id(i));
            oe_debug_pub.ADD(   'Ship To id is  '
                             || g_header_rec.ship_to_org_id(i));
            oe_debug_pub.ADD(   'Ship To Org is  '
                             || g_header_rec.ship_to_org(i));
            oe_debug_pub.ADD(   'Invoice To Org is  '
                             || g_header_rec.invoice_to_org(i));
            oe_debug_pub.ADD(   'Invoice To Org Id is  '
                             || g_header_rec.invoice_to_org_id(i));
            oe_debug_pub.ADD(   'Sold To Org Id is  '
                             || g_header_rec.sold_to_org_id(i));
            oe_debug_pub.ADD(   'Sold To Org is  '
                             || g_header_rec.sold_to_org(i));
            oe_debug_pub.ADD(   'Paid At Store ID is '
                             || g_header_rec.paid_at_store_id(i));
            oe_debug_pub.ADD(   'Paid At Store No is '
                             || g_header_rec.paid_at_store_no(i));
            oe_debug_pub.ADD(   'Payment Term ID is '
                             || g_header_rec.payment_term_id(i));
            oe_debug_pub.ADD(   'Gift Flag is '
                             || g_header_rec.gift_flag(i));
            oe_debug_pub.ADD(   'Error Flag is '
                             || g_header_rec.error_flag(i));
            oe_debug_pub.ADD(   'G_header_rec.ordered_date '
                             || g_header_rec.ordered_date(i));
            oe_debug_pub.ADD(   'G_header_rec.ship_date '
                             || g_header_rec.ship_date(i));
            oe_debug_pub.ADD(   'G_header_rec.sas_sale_date '
                             || g_header_rec.sas_sale_date(i));
        END IF;

        -- Increment the global header counter
        g_header_counter :=   g_header_counter
                            + 1;
        -- Return success
        x_return_status := 'S';
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed to process Header '
                              || g_header_rec.orig_sys_document_ref(i));
            fnd_file.put_line(fnd_file.LOG,
                                 'The error is '
                              || SQLERRM);
            -- Need to clear this BAD order
            clear_bad_orders('HEADER',
                             g_header_rec.orig_sys_document_ref(i));
            x_return_status := 'U';
    END process_header;

    PROCEDURE process_line(
        p_order_rec      IN             order_rec_type,
        p_batch_id       IN             NUMBER,
        x_return_status  OUT NOCOPY     VARCHAR2)
    IS
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
        i                        NUMBER;
        ln_hdr_ind               NUMBER;
        lc_item                  VARCHAR2(7);
        ln_item                  NUMBER;
        lc_err_msg               VARCHAR2(200);
        lc_source_type_code      VARCHAR2(50);
        ln_line_count            NUMBER;
        lc_customer_item         VARCHAR2(50);
        lc_order_qty_sign        VARCHAR2(1);
        lc_return_attribute2     VARCHAR2(50);
        ln_debug_level  CONSTANT NUMBER        := oe_debug_pub.g_debug_level;
        ln_item_id               NUMBER;
        ln_bundle_id             NUMBER;
        ln_header_id             NUMBER;
        ln_line_id               NUMBER;
        ln_orig_sell_price       NUMBER;
        ln_orig_ord_qty          NUMBER;
        lc_order_source          VARCHAR2(80);
        l_int_customer           NUMBER        := 0;
        ln_mps_retail            NUMBER;
    BEGIN
        x_return_status := 'S';
        -- Line number counter per order
        g_line_nbr_counter :=   g_line_nbr_counter
                              + 1;
        i :=   g_line_rec.orig_sys_document_ref.COUNT
             + 1;
        ln_hdr_ind := g_header_rec.orig_sys_document_ref.COUNT;
        lc_order_qty_sign := SUBSTR(p_order_rec.file_line,
                                    40,
                                    1);

        IF g_header_rec.order_category(ln_hdr_ind) = 'ORDER'
        THEN
            g_batch_counter :=   g_batch_counter
                               + 1;
            g_line_rec.request_id(i) := g_request_id;
            g_order_line_tax_ctr :=   g_order_line_tax_ctr
                                    + 1;
        ELSE
            IF lc_order_qty_sign = '-'
            THEN
                g_rma_line_tax_ctr :=   g_rma_line_tax_ctr
                                      + 1;
            ELSE
                g_order_line_tax_ctr :=   g_order_line_tax_ctr
                                        + 1;
            END IF;

            g_line_rec.request_id(i) := NULL;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Entering Line Processing'
                             || ln_hdr_ind);
            oe_debug_pub.ADD(   'Line Count is '
                             || i);
            oe_debug_pub.ADD(   'G_Order_Line_Counter is '
                             || g_order_line_tax_ctr);
            oe_debug_pub.ADD(   'G_RMA_Line_Tax_ctr is '
                             || g_rma_line_tax_ctr);
            oe_debug_pub.ADD(   'Tax Value as header is '
                             || g_header_rec.tax_value(ln_hdr_ind));
        END IF;

        IF g_line_id.EXISTS(g_line_id_seq_ctr)
        THEN
            g_line_rec.line_id(i) := g_line_id(g_line_id_seq_ctr);
            g_line_id_seq_ctr :=   g_line_id_seq_ctr
                                 + 1;
        ELSE
            -- Get the value from Sequence
            SELECT oe_order_lines_s.NEXTVAL
            INTO   g_line_rec.line_id(i)
            FROM   DUAL;
        END IF;

        g_line_rec.orig_sys_document_ref(i) := g_header_rec.orig_sys_document_ref(ln_hdr_ind);
        g_line_rec.orig_sys_line_ref(i) := SUBSTR(p_order_rec.file_line,
                                                  23,
                                                  5);
        g_line_rec.order_source_id(i) := g_header_rec.order_source_id(ln_hdr_ind);
        g_line_rec.change_sequence(i) := g_header_rec.change_sequence(ln_hdr_ind);
        g_line_rec.line_number(i) := g_line_nbr_counter;                              --G_line_rec.orig_sys_line_ref(i);

        -- For first line of an order
        IF g_line_nbr_counter = 1
        THEN
            g_header_rec.start_line_index(ln_hdr_ind) := i;
        END IF;

        -- Set Tax value on first return line of order if tax value < 0
        -- Set Tax value on first outbound line of order is tax value >= 0
        /* passing tax code as 'Location' for lines which has a value. modified by NB */
        IF g_order_line_tax_ctr = 1 AND g_header_rec.tax_value(ln_hdr_ind) >= 0
        THEN
            g_line_rec.tax_value(i) := g_header_rec.tax_value(ln_hdr_ind);
            g_line_rec.canada_pst(i) := g_header_rec.pst_tax_value(ln_hdr_ind);
            g_line_rec.tax_code(i) := 'Location';
            -- Increment the counter so that it does not assign it again
            g_order_line_tax_ctr :=   g_order_line_tax_ctr
                                    + 1;
        ELSIF g_rma_line_tax_ctr = 1 AND g_header_rec.tax_value(ln_hdr_ind) < 0
        THEN
            g_line_rec.tax_value(i) :=   -1
                                       * g_header_rec.tax_value(ln_hdr_ind);
            g_line_rec.canada_pst(i) :=   -1
                                        * g_header_rec.pst_tax_value(ln_hdr_ind);
            g_line_rec.tax_code(i) := 'Location';
            -- Increment the counter so that it does not assign it again
            g_rma_line_tax_ctr :=   g_rma_line_tax_ctr
                                  + 1;
        ELSE
            g_line_rec.tax_value(i) := 0;
            g_line_rec.canada_pst(i) := 0;
            g_line_rec.tax_code(i) := NULL;
        END IF;

        ln_item := LTRIM(SUBSTR(p_order_rec.file_line,
                                33,
                                7));

        IF ln_item <= 99999
        THEN
            lc_item := LPAD(ln_item,
                            6,
                            '0');
        ELSE
            lc_item := ln_item;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Start Line Index is :'
                             || g_header_rec.start_line_index(ln_hdr_ind));
            oe_debug_pub.ADD(   'Item Read from file is :'
                             || lc_item);
        END IF;

        -- Raj added for getting MPS retail price
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'MPS Flag :'
                             || g_header_rec.atr_order_flag(ln_hdr_ind));
            oe_debug_pub.ADD(   'Serial_no  :'
                             || g_header_rec.device_serial_num(ln_hdr_ind));
            oe_debug_pub.ADD(   'Order Number  :'
                             || g_header_rec.orig_sys_document_ref(ln_hdr_ind));
            oe_debug_pub.ADD(   'Item  :'
                             || lc_item);
        END IF;

        IF g_header_rec.atr_order_flag(ln_hdr_ind) = 'MPS'
        THEN
            -- Raj added on 11/4/13 for MPS return reversal
            IF lc_order_qty_sign = '-'
            THEN
                -- Get original order retail
                BEGIN
                    SELECT ox.mps_toner_retail
                    INTO   ln_mps_retail
                    FROM   oe_order_headers_all oh,
                           oe_order_lines_all ol,
                           xx_om_line_attributes_all ox
                    WHERE  ox.line_id = ol.line_id
                    AND    ol.header_id = oh.header_id
                    AND    ol.orig_sys_document_ref = g_header_rec.return_orig_sys_doc_ref(ln_hdr_ind)
                    AND    ol.ordered_item = lc_item;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             ' No Retail price found for original order:'
                                          || g_header_rec.return_orig_sys_doc_ref(ln_hdr_ind));
                END;
            ELSE
                ln_mps_retail :=
                    get_mps_retail(g_header_rec.device_serial_num(ln_hdr_ind),
                                   g_header_rec.orig_sys_document_ref(ln_hdr_ind),
                                   lc_item);
            END IF;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'MPS Retail :'
                             || ln_mps_retail);
        END IF;

        g_line_rec.mps_toner_retail(i) := ln_mps_retail;
-------------------------------------------Raj
        g_line_rec.schedule_ship_date(i) := NULL;                                  --g_header_rec.ship_date(ln_hdr_ind);
        g_line_rec.actual_ship_date(i) := NULL;
        g_line_rec.sas_sale_date(i) := g_header_rec.sas_sale_date(ln_hdr_ind);
        g_line_rec.aops_ship_date(i) := g_header_rec.ship_date(ln_hdr_ind);
        g_line_rec.salesrep_id(i) := g_header_rec.salesrep_id(ln_hdr_ind);
        g_line_rec.ordered_quantity(i) := SUBSTR(p_order_rec.file_line,
                                                 41,
                                                 5);
        g_line_rec.order_quantity_uom(i) := SUBSTR(p_order_rec.file_line,
                                                   187,
                                                   2);
        g_line_rec.shipped_quantity(i) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                       47,
                                                       5));

        -- If the shipped quantity is coming in as 0 , for credit only returns, then set it to NULL.
        IF g_line_rec.shipped_quantity(i) = 0
        THEN
            g_line_rec.shipped_quantity(i) := NULL;
        END IF;

        g_line_rec.sold_to_org_id(i) := g_header_rec.sold_to_org_id(ln_hdr_ind);
        g_line_rec.ship_from_org_id(i) := g_header_rec.ship_from_org_id(ln_hdr_ind);
        g_line_rec.ship_to_org_id(i) := g_header_rec.ship_to_org_id(ln_hdr_ind);
        g_line_rec.invoice_to_org_id(i) := g_header_rec.invoice_to_org_id(ln_hdr_ind);
        g_line_rec.sold_to_contact_id(i) := g_header_rec.sold_to_contact_id(ln_hdr_ind);
        g_line_rec.drop_ship_flag(i) := g_header_rec.drop_ship_flag(ln_hdr_ind);
        g_line_rec.price_list_id(i) := g_header_rec.price_list_id(ln_hdr_ind);

        -- Changing following code to avoid rounding errors. 08/15/2008
        -- Use the extended amount to derive the unit price
        -- G_line_rec.unit_list_price(i)       := SUBSTR(p_order_rec.file_line, 70, 10);
        -- G_line_rec.unit_selling_price(i)    := SUBSTR(p_order_rec.file_line, 70, 10);
        IF NVL(NVL(g_line_rec.shipped_quantity(i),
                   g_line_rec.ordered_quantity(i)),
               0) = 0
        THEN
            g_line_rec.unit_list_price(i) := SUBSTR(p_order_rec.file_line,
                                                    92,
                                                    10);
            set_header_error(ln_hdr_ind);
            set_msg_context(p_entity_code      => 'HEADER',
                            p_line_ref         => g_line_rec.orig_sys_line_ref(i));
            lc_err_msg := 'Ordered and Shipped Quantity is zero ';
            fnd_message.set_name('XXOM',
                                 'XX_OM_ORD_SHIP_QTY');
            fnd_message.set_token('ATTRIBUTE1',
                                     g_line_rec.orig_sys_document_ref(i)
                                  || ' - '
                                  || g_line_rec.orig_sys_line_ref(i));
            oe_bulk_msg_pub.ADD;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(lc_err_msg,
                                 1);
            END IF;
        ELSE
            g_line_rec.unit_list_price(i) :=
                  SUBSTR(p_order_rec.file_line,
                         92,
                         10)
                / NVL(g_line_rec.shipped_quantity(i),
                      g_line_rec.ordered_quantity(i));
        END IF;

        g_line_rec.unit_selling_price(i) := g_line_rec.unit_list_price(i);
        g_line_rec.tax_date(i) := g_header_rec.ordered_date(ln_hdr_ind);
       -- g_line_rec.shipping_method_code(i) := g_header_rec.shipping_method_code(ln_hdr_ind);
        g_line_rec.customer_po_number(i) := g_header_rec.customer_po_number(ln_hdr_ind);
        g_line_rec.shipping_instructions(i) := g_header_rec.shipping_instructions(ln_hdr_ind);
        lc_customer_item := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                               107,
                                               20)));
        g_line_rec.ret_ref_header_id(i) := NULL;
        g_line_rec.ret_ref_line_id(i) := NULL;
        g_line_rec.return_context(i) := NULL;
        g_line_rec.return_attribute1(i) := NULL;
        g_line_rec.return_attribute2(i) := NULL;
        g_line_rec.org_order_creation_date(i) := NULL;
        g_line_rec.desk_top_no(i) := g_header_rec.desk_top_no(ln_hdr_ind);
        g_line_rec.release_number(i) := g_header_rec.release_number(ln_hdr_ind);
        -- Always populate return action category code for all lines under order category of  Mixed / Return.
        g_line_rec.return_act_cat_code(i) := g_header_rec.return_act_cat_code(ln_hdr_ind);
        g_line_rec.tax_exempt_flag(i) := g_header_rec.tax_exempt_flag(ln_hdr_ind);
        g_line_rec.tax_exempt_number(i) := g_header_rec.tax_exempt_number(ln_hdr_ind);
        g_line_rec.tax_exempt_reason(i) := g_header_rec.tax_exempt_reason(ln_hdr_ind);
        -- Read the data warehouse attributes
        g_line_rec.price_cd(i) := g_header_rec.price_cd(ln_hdr_ind);
        g_line_rec.price_change_reason_cd(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                                            289,
                                                            5));
        -- modified on 14-mar-2009 by NB changed 2 to 5 characters read
        g_line_rec.price_prefix_cd(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                                     294,
                                                     5));
        g_line_rec.commisionable_ind(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                                       288,
                                                       1));
        g_line_rec.unit_orig_selling_price(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                                             299,
                                                             11));

        -- Read customer line number
        g_line_rec.customer_line_number(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                                 283,
                                                                 5)));
        g_line_rec.core_type_indicator(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                                             310,
                                                             4));
        IF lc_order_qty_sign = '-'
        THEN
            g_line_rec.line_category_code(i) := 'RETURN';
            g_line_rec.schedule_status_code(i) := NULL;
            g_line_rec.calc_arrival_date(i) := g_header_rec.ship_date(ln_hdr_ind);
            g_line_rec.org_order_creation_date(i) := g_header_rec.org_order_creation_date(ln_hdr_ind);
            g_line_rec.return_reason_code(i) := g_header_rec.return_reason(ln_hdr_ind);
            g_header_rec.order_total(ln_hdr_ind) :=
                  g_header_rec.order_total(ln_hdr_ind)
                + (  g_line_rec.unit_selling_price(i)
                   * NVL(g_line_rec.shipped_quantity(i),
                         g_line_rec.ordered_quantity(i))
                   * -1);
        ELSE
            g_line_rec.line_category_code(i) := 'ORDER';

            IF g_header_rec.order_category(ln_hdr_ind) <> 'ORDER'
            THEN
                g_line_rec.schedule_status_code(i) := NULL;
            ELSE
                g_line_rec.schedule_status_code(i) := NULL;                                              --'SCHEDULED';
            END IF;

            -- Once rules are derived we will add logic to calculate the schedule_arrival_date
            g_line_rec.calc_arrival_date(i) := g_header_rec.ship_date(ln_hdr_ind);
            g_line_rec.org_order_creation_date(i) := NULL;
            g_line_rec.return_reason_code(i) := NULL;
            g_header_rec.order_total(ln_hdr_ind) :=
                  g_header_rec.order_total(ln_hdr_ind)
                + (  g_line_rec.unit_selling_price(i)
                   * NVL(g_line_rec.shipped_quantity(i),
                         g_line_rec.ordered_quantity(i)));
        END IF;

        -- oe_debug_pub.add('The order total is ' || G_Header_Rec.order_total(ln_hdr_ind));
        g_line_rec.vendor_product_code(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                                147,
                                                                20)));
        g_line_rec.wholesaler_item(i) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                      127,
                                                      20));
        g_line_rec.legacy_list_price(i) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                        59,
                                                        10));
        g_line_rec.contract_details(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                             167,
                                                             20)));
        g_line_rec.taxable_flag(i) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                   189,
                                                   1));
        g_line_rec.sku_dept(i) := LTRIM(SUBSTR(p_order_rec.file_line,
                                               190,
                                               3));

        -- Raj added on 10/8 for COGs liability account
        IF g_header_rec.atr_order_flag(ln_hdr_ind) = 'MPS'
        THEN
            g_line_rec.item_source(i) := 'MPS';
        ELSE
            g_line_rec.item_source(i) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                      193,
                                                      2));
        END IF;

        -------
        g_line_rec.average_cost(i) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                   207,
                                                   10));
        g_line_rec.po_cost(i) := LTRIM(SUBSTR(p_order_rec.file_line,
                                              196,
                                              10));
        g_line_rec.back_ordered_qty(i) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                       53,
                                                       5));
        /*Defect:1744 --NB */
        g_line_rec.line_comments(i) :=
            RTRIM(   LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                        336,
                                        245)))
                 || ' '
                 || LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                     634,
                                     245)))
                  );
        -- NO more copy from header. Read the value from line record
        g_line_rec.cust_dept_no(i) := SUBSTR(p_order_rec.file_line,
                                             581,
                                             20);
        g_line_rec.cust_dept_description(i) := SUBSTR(p_order_rec.file_line,
                                                      601,
                                                      25);


        -- Intitalized tax rate and tax amount as per defect f ver 25.0 
         g_line_rec.line_tax_rate(i)   := NULL;  
         g_line_rec.line_tax_amount(i) := NULL;
         g_line_rec.kit_sku(i)         := NULL;
         g_line_rec.kit_qty(i)         := NULL;
         g_line_rec.kit_vpc(i)         := NULL;
         g_line_rec.kit_dept(i)        := NULL;
         g_line_rec.kit_seqnum(i)      := NULL;
         g_line_rec.kit_seqnum(i)      := NULL;


     /*     Commented   as per defect 36885 ver 25.0
     -- Added for Line level tax.          

    --    g_line_rec.line_tax_rate(i)   := SUBSTR(p_order_rec.file_line,
    --                                          634,
    --                                          7);   

    --    g_line_rec.line_tax_amount(i) := SUBSTR(p_order_rec.file_line,
    --                                          641,
    --                                          9);  
       */
        -- Need to read from file..
        g_line_rec.item_comments(i) := NULL;
        g_line_rec.payment_term_id(i) := g_header_rec.payment_term_id(ln_hdr_ind);

        IF g_line_rec.line_category_code(i) = 'RETURN'
        THEN
            g_line_rec.return_reference_no(i) := g_header_rec.return_orig_sys_doc_ref(ln_hdr_ind);
            g_line_rec.return_ref_line_no(i) := SUBSTR(p_order_rec.file_line,
                                                       102,
                                                       5);
        ELSE
            g_line_rec.return_reference_no(i) := NULL;
            g_line_rec.return_ref_line_no(i) := NULL;
        END IF;

        -- Once Bob sends the entered product code uncomment the below line

        g_line_rec.user_item_description(i) := NULL;
        ln_bundle_id := NULL;
        g_line_rec.config_code(i) := NULL;
        g_line_rec.upc_code(i) := NULL;
        g_line_rec.price_type(i) := NULL;
        g_line_rec.external_sku(i) := NULL;

        IF UPPER(g_header_rec.order_source_cd(ln_hdr_ind)) NOT IN ('P','S','U')
        THEN 
        g_line_rec.user_item_description(i) := RTRIM(SUBSTR(p_order_rec.file_line,
                                                            218,
                                                            20));

        ln_bundle_id := TO_NUMBER(LTRIM(SUBSTR(p_order_rec.file_line,
                                               238,
                                               10)));
        g_line_rec.config_code(i) := RTRIM(SUBSTR(p_order_rec.file_line,
                                                  248,
                                                  20));
        ELSIF g_header_rec.order_source_cd(ln_hdr_ind) IN ('P','S','U')
        THEN 
           g_line_rec.upc_code(i)    := TRIM(SUBSTR(p_order_rec.file_line,218,15));
       --  g_line_rec.price_type(i)  := TRIM(SUBSTR(p_order_rec.file_line,233,1));
       --  g_line_rec.external_sku(i):= TRIM(SUBSTR(p_order_rec.file_line,234,8));
        END IF;                                                   

        -- Made changes to support to RCC AOPS order
        g_line_rec.price_type(i):= TRIM(SUBSTR(p_order_rec.file_line,314,1));
        g_line_rec.external_sku(i):= TRIM(SUBSTR(p_order_rec.file_line,315,8));

        g_line_rec.line_type_id(i) := NULL;
        g_line_rec.ordered_date(i) := g_header_rec.ordered_date(ln_hdr_ind);
        g_line_rec.inventory_item(i) := NULL;
        g_line_rec.customer_item_name(i) := NULL;

        g_line_rec.gsa_flag(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                     268,
                                                     1)));                                                 --Added By NB
        g_line_rec.orig_selling_price(i) := NULL;

        IF ln_bundle_id = 0
        THEN
            g_line_rec.ext_top_model_line_id(i) := g_line_rec.line_id(i);
            g_line_rec.ext_link_to_line_id(i) := g_line_rec.line_id(i);
            g_curr_top_line_id := g_line_rec.line_id(i);
        ELSIF ln_bundle_id > 0
        THEN
            g_line_rec.ext_top_model_line_id(i) := g_curr_top_line_id;
            g_line_rec.ext_link_to_line_id(i) := g_curr_top_line_id;
        ELSE
            g_line_rec.ext_top_model_line_id(i) := NULL;
            g_line_rec.ext_link_to_line_id(i) := NULL;
        END IF;

        oe_debug_pub.ADD('8 ');
        g_line_rec.waca_item_ctr_num(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                                       269,
                                                       12));
        g_line_rec.consignment_bank_code(i) := TRIM(SUBSTR(p_order_rec.file_line,
                                                           281,
                                                           2));

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Tax Value is '
                             || g_line_rec.tax_value(i));
            oe_debug_pub.ADD(   'Tax Value PST is '
                             || g_line_rec.canada_pst(i));
            oe_debug_pub.ADD(   'Tax Code is '
                             || g_line_rec.tax_code(i));
            oe_debug_pub.ADD(   'Customer Item is '
                             || lc_customer_item);
            oe_debug_pub.ADD(   'orig_sys_document_ref = '
                             || g_line_rec.orig_sys_document_ref(i));
            oe_debug_pub.ADD(   'orig_sys_line_ref = '
                             || g_line_rec.orig_sys_line_ref(i));
            oe_debug_pub.ADD(   'order_source_id = '
                             || g_line_rec.order_source_id(i));
            oe_debug_pub.ADD(   'change_sequence = '
                             || g_line_rec.change_sequence(i));
            oe_debug_pub.ADD(   'line_number = '
                             || g_line_rec.line_number(i));
            oe_debug_pub.ADD(   'lc_order_qty_sign = '
                             || lc_order_qty_sign);
            oe_debug_pub.ADD(   'ln_item = '
                             || ln_item);
            oe_debug_pub.ADD(   'schedule_ship_date = '
                             || g_line_rec.schedule_ship_date(i));
            oe_debug_pub.ADD(   'actual_ship_date = '
                             || g_line_rec.actual_ship_date(i));
            oe_debug_pub.ADD(   'salesrep_id = '
                             || g_line_rec.salesrep_id(i));
            oe_debug_pub.ADD(   'ordered_quantity = '
                             || g_line_rec.ordered_quantity(i));
            oe_debug_pub.ADD(   'shipped_quantity = '
                             || g_line_rec.shipped_quantity(i));
            oe_debug_pub.ADD(   'sold_to_org_id = '
                             || g_line_rec.sold_to_org_id(i));
            oe_debug_pub.ADD(   'ship_from_org_id = '
                             || g_line_rec.ship_from_org_id(i));
            oe_debug_pub.ADD(   'ship_to_org_id = '
                             || g_line_rec.ship_to_org_id(i));
            oe_debug_pub.ADD(   'invoice_to_org_id = '
                             || g_line_rec.invoice_to_org_id(i));
            oe_debug_pub.ADD(   'sold_to_contact_id = '
                             || g_line_rec.sold_to_contact_id(i));
            oe_debug_pub.ADD(   'drop_ship_flag = '
                             || g_line_rec.drop_ship_flag(i));
            oe_debug_pub.ADD(   'price_list_id(i) = '
                             || g_line_rec.price_list_id(i));
            oe_debug_pub.ADD(   'unit_list_price = '
                             || g_line_rec.unit_list_price(i));
            oe_debug_pub.ADD(   'unit_selling_price = '
                             || g_line_rec.unit_selling_price(i));
            oe_debug_pub.ADD(   'tax_date = '
                             || g_line_rec.tax_date(i));
--            oe_debug_pub.ADD(   'shipping_method_code = '
--                             || g_line_rec.shipping_method_code(i));
            oe_debug_pub.ADD(   'line_number = '
                             || g_line_rec.line_number(i));
            oe_debug_pub.ADD(   'Return Reason Code = '
                             || g_line_rec.return_reason_code(i));
            oe_debug_pub.ADD(   'customer_po_number(i) = '
                             || g_line_rec.customer_po_number(i));
            oe_debug_pub.ADD(   'shipping_instructions = '
                             || g_line_rec.shipping_instructions(i));
            oe_debug_pub.ADD(   'lc_customer_item = '
                             || lc_customer_item);
            oe_debug_pub.ADD(   'G_line_rec.line_category_code(i) = '
                             || g_line_rec.line_category_code(i));
            oe_debug_pub.ADD(   'Return Ref no :'
                             || g_line_rec.return_reference_no(i),
                             1);
            oe_debug_pub.ADD(   'Return Ref Line no :'
                             || g_line_rec.return_ref_line_no(i),
                             1);
            oe_debug_pub.ADD(   'User Item Description :'
                             || g_line_rec.user_item_description(i),
                             1);
            oe_debug_pub.ADD(   'Bundle ID '
                             || ln_bundle_id);
            oe_debug_pub.ADD(   'Ext top model id : '
                             || g_line_rec.ext_top_model_line_id(i),
                             1);
            oe_debug_pub.ADD(   'Ext Link To Line id : '
                             || g_line_rec.ext_link_to_line_id(i),
                             1);
            oe_debug_pub.ADD(   'Config Code : '
                             || g_line_rec.config_code(i),
                             1);
            oe_debug_pub.ADD(   'Core Type Indicator : '
                             || g_line_rec.core_type_indicator(i),
                             1);
            oe_debug_pub.ADD(   'UPC CODE : '
                             || g_line_rec.upc_code(i),
                             1);
            oe_debug_pub.ADD(   'Price Type: '
                             || g_line_rec.price_type(i),
                             1);
            oe_debug_pub.ADD(   'External SKU : '
                             || g_line_rec.external_sku(i),
                             1);     
           -- Commented as per defect 36885 ver 25.0                             
           /* oe_debug_pub.ADD(   'Line TAX Amount : '
                             || g_line_rec.line_tax_amount(i),
                             1);  
            oe_debug_pub.ADD(   'Line Tax Rate : '
                             || g_line_rec.line_Tax_rate(i),
                             1);  */
        END IF;

        -- Validate Item and Warehouse/Store
        validate_item_warehouse(p_hdr_idx       => ln_hdr_ind,
                                p_line_idx      => i,
                                p_item          => lc_item);

        IF lc_customer_item IS NOT NULL
        THEN
            g_line_rec.customer_item_id(i) :=
                                            customer_item_id(lc_customer_item,
                                                             g_header_rec.sold_to_org_id(ln_hdr_ind));
            g_line_rec.customer_item_id_type(i) := NULL;                                                       --'CUST';

            IF g_line_rec.customer_item_id(i) IS NULL
            THEN
                g_line_rec.customer_item_name(i) := lc_customer_item;
            END IF;
        ELSE
            g_line_rec.customer_item_id(i) := NULL;
            g_line_rec.customer_item_id_type(i) := NULL;
            g_line_rec.customer_item_name(i) := lc_customer_item;
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
        --Modified by NB for R11.2
        lc_order_source := get_ord_source_name(p_order_source_id      => g_line_rec.order_source_id(i));

        --Added to check whether they are Internal or External Customers in Oracle
        BEGIN
            SELECT COUNT(1)
            INTO   l_int_customer
            FROM   hz_orig_sys_references
            WHERE  owner_table_id = g_header_rec.sold_to_org_id(ln_hdr_ind)
            AND    owner_table_name = 'HZ_CUST_ACCOUNTS'
            AND    orig_system = 'RMS';
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  ' No Data Found To Process:::');
        END;

        -- Simple line type assignments
        --Debug for 16903
        IF ln_debug_level > 0
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'If External/Internal then 0/1  l_int_customer is  : '
                              || l_int_customer);

        END IF;

        IF lc_order_qty_sign = '+'
        THEN
            --Code modification done to introduce the condition for External Customers and order_source as POE  Defect#16903

            IF lc_order_source = 'POE' AND l_int_customer = 0
            THEN
              g_line_rec.line_type_id(i) := oe_sys_parameters.VALUE('D-SL',
                                                                    g_org_id);

                IF g_header_rec.deposit_amount(ln_hdr_ind) > 0
                THEN
                    g_line_rec.line_type_id(i) := oe_sys_parameters.VALUE('D-SL',
                                                                          g_org_id);
                END IF;
            ELSIF lc_order_source = 'POE' AND l_int_customer <> 0
            THEN
                g_line_rec.line_type_id(i) := oe_sys_parameters.VALUE('D-PSL',
                                                                      g_org_id);
            --This part is distinctly for AOPS Orders
            ELSE


               IF g_header_rec.rcc_transaction(ln_hdr_ind) = 'Y'
               THEN 
                 g_line_rec.line_type_id(i) := oe_sys_parameters.VALUE('D-PSL-RCC',
                                                                       g_org_id);
			   ELSIF g_header_rec.appid_base_ordertype(ln_hdr_ind)='Y'    -- added for the defect#44139
               THEN
                    g_line_rec.line_type_id(i) := oe_sys_parameters.VALUE(g_header_rec.appid_linetype_value(ln_hdr_ind),g_org_id);													   
               ELSE
			          g_line_rec.line_type_id(i) := oe_sys_parameters.VALUE('D-SL',
                                                                       g_org_id);
				END IF;
            END IF;
        ELSE

             -- CH# ver20.0 34951 Start -- Added additional condition for Customer

            --IF lc_order_source = 'POE'
           -- THEN
               -- g_line_rec.line_type_id(i) := oe_sys_parameters.VALUE('D-PRL',
                                                                  --    g_org_id);

           IF lc_order_source = 'POE' AND l_int_customer = 0  
            Then
            G_Line_Rec.Line_Type_Id(i) := Oe_Sys_Parameters.Value('D-RL',
                                                                      G_Org_Id);
            ELSIF lc_order_source = 'POE' AND l_int_customer <> 0
            THEN
                G_Line_Rec.Line_Type_Id(i):= Oe_Sys_Parameters.Value('D-PRL',
                                                                      G_Org_Id);
            -- CH# 34951 End -- 
            ELSE

              IF g_header_rec.rcc_transaction(ln_hdr_ind) = 'Y'
              THEN 
                g_line_rec.line_type_id(i) := oe_sys_parameters.VALUE('D-PRL-RCC',
                                                                      g_org_id);
		      ELSE
			          g_line_rec.line_type_id(i) := oe_sys_parameters.VALUE('D-RL',
                                                                      g_org_id);
                END IF;
            END IF;

        END IF;


        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Line_type ID : '
                             || g_line_rec.line_type_id(i));
        END IF;

        -- Since Line Type is a required field for order check if it has got derived
        IF g_line_rec.line_type_id(i) IS NULL
        THEN
            set_header_error(ln_hdr_ind);
            set_msg_context(p_entity_code      => 'HEADER',
                            p_line_ref         => g_line_rec.orig_sys_line_ref(i));
            lc_err_msg := 'Failed to derive Line Type For the line ';
            fnd_message.set_name('XXOM',
                                 'XX_OM_FAILED_LINE_TYPE');
            oe_bulk_msg_pub.ADD;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(lc_err_msg,
                                 1);
            END IF;
        END IF;

        IF     g_line_rec.line_category_code(i) = 'RETURN'
           AND g_line_rec.return_reference_no(i) IS NOT NULL
           AND g_line_rec.return_ref_line_no(i) IS NOT NULL
        THEN
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD('This return has reference',
                                 1);
            END IF;

            ln_header_id := NULL;
            ln_line_id := NULL;
            ln_orig_sell_price := NULL;
            ln_orig_ord_qty := NULL;
            get_return_attributes(g_line_rec.return_reference_no(i),
                                  g_line_rec.return_ref_line_no(i),
                                  NULL,
                                  g_line_rec.sold_to_org_id(i),
                                  ln_header_id,
                                  ln_line_id,
                                  ln_orig_sell_price,
                                  ln_orig_ord_qty);

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Ref Header Id is  '
                                 || ln_header_id,
                                 1);
                oe_debug_pub.ADD(   'Ref Line Id is  '
                                 || ln_line_id,
                                 1);
                oe_debug_pub.ADD(   'Orig Sell Price is '
                                 || ln_orig_sell_price,
                                 1);
                oe_debug_pub.ADD(   'Orig Ord Qty is '
                                 || ln_orig_ord_qty,
                                 1);
            END IF;

            -- Store the original sell price for this return line.
            g_line_rec.orig_selling_price(i) := ln_orig_sell_price;
            g_line_rec.ret_ref_header_id(i) := ln_header_id;
            g_line_rec.ret_ref_line_id(i) := ln_line_id;
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

        IF g_header_rec.invoicing_rule_id(ln_hdr_ind) IS NOT NULL
        THEN
          BEGIN
            SELECT add_months(sysdate,od_contract_length)
            INTO g_line_rec.service_end_date(i)
            FROM xx_rms_mv_ssb
            WHERE item =  g_line_rec.inventory_item(i);

            EXCEPTION
              WHEN OTHERS 
              THEN 
                g_line_rec.service_end_date(i) := null;
            END;
        END IF;


        -- Print all derived attributes
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Line Type = '
                             || g_line_rec.line_type_id(i));
            oe_debug_pub.ADD(   'Item = '
                             || g_line_rec.inventory_item_id(i));
            oe_debug_pub.ADD(   'Item = '
                             || g_line_rec.inventory_item(i));
            oe_debug_pub.ADD(   'Cust Item = '
                             || g_line_rec.customer_item_id(i));
            oe_debug_pub.ADD(   'Error Flag is '
                             || g_header_rec.error_flag(ln_hdr_ind));
            oe_debug_pub.ADD(   'Service End date '
                             || g_line_rec.service_end_date(i));
        END IF;

        -- Increment the global Line counter used in determining batch size
        g_line_counter :=   g_line_counter
                          + 1;
        x_return_status := 'S';
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed to process line record '
                              || g_line_rec.orig_sys_line_ref(i)
                              || ' for order '
                              || g_header_rec.orig_sys_document_ref(ln_hdr_ind)
                              || '-'
                              || g_line_rec.orig_sys_line_ref(i));
            fnd_file.put_line(fnd_file.LOG,
                                 'The error is '
                              || SQLERRM);
            -- Need to clear this BAD order
            clear_bad_orders('LINE',
                             g_line_rec.orig_sys_document_ref(i));
            x_return_status := 'U';
    END process_line;


   PROCEDURE process_tender(
       p_order_rec      IN             order_rec_type,
       p_batch_id       IN             NUMBER,
       x_return_status  OUT NOCOPY     VARCHAR2)
   IS

-- +===================================================================+
-- | Name  : process_tender                                            |
-- | Description      : This Procedure will read the tender line from  |
-- |                    file validate , derive and insert into         |
-- |                    xx_om_tender_attr_iface_all                    |
-- |                                                                   |
-- |                                                                   |
-- | Paramenters        p_order_rec IN order_rec_type                  |
-- |                    p_batch_id  IN batch_id                        |
-- +===================================================================+

   i                     INTEGER;
   lc_pay_seq            VARCHAR2(3);
   ln_hdr_ind            NUMBER;
   ln_debug_level  CONSTANT NUMBER        := oe_debug_pub.g_debug_level;

   BEGIN

      -- Set the header record indicator.

      ln_hdr_ind := g_header_rec.orig_sys_document_ref.count;

      --Read from file the tender related attributes.    
      lc_pay_seq := SUBSTR(p_order_rec.file_line, 33,  3);

       i:= g_tender_rec.orig_sys_document_ref.COUNT+1;

      g_tender_rec.orig_sys_document_ref(i) := g_header_rec.orig_sys_document_ref(ln_hdr_ind); 
      g_tender_rec.orig_sys_payment_ref(i)  := lc_pay_seq;
      g_tender_rec.order_source_id(i)       := g_header_rec.order_source_id(ln_hdr_ind); 
      g_tender_rec.routing_line1(i)         := TRIM(SUBSTR(p_order_rec.file_line, 33,  20));
      g_tender_rec.routing_line2(i)         := TRIM(SUBSTR(p_order_rec.file_line, 53,  20));
      g_tender_rec.routing_line3(i)         := TRIM(SUBSTR(p_order_rec.file_line, 73,  20));
      g_tender_rec.routing_line4(i)         := TRIM(SUBSTR(p_order_rec.file_line, 93,  17));
      g_tender_rec.batch_id(i)  := p_batch_id;      

      IF ln_debug_level > 0
      THEN

         oe_debug_pub.ADD(   'TEST orig_sys_document_ref : '
                             || g_tender_rec.orig_sys_document_ref(i),
                             1);

         oe_debug_pub.ADD(   ' TEST orig_sys_payment_ref : '
                             || g_tender_rec.orig_sys_payment_ref(i) ,
                             1);
         oe_debug_pub.ADD(   'Source Id: '
                             || g_tender_rec.order_source_id(i),
                             1);                             
         oe_debug_pub.ADD(   'Rounting Line1 : '
                             || g_tender_rec.routing_line1(i),
                             1);
         oe_debug_pub.ADD(   'Rounting Line2 : '
                             || g_tender_rec.routing_line2(i),
                             1);
         oe_debug_pub.ADD(   'Rounting Line3 : '
                             || g_tender_rec.routing_line3(i),
                             1);
         oe_debug_pub.ADD(   'Rounting Line4 : '
                             || g_tender_rec.routing_line4(i),
                             1);
         oe_debug_pub.ADD(   'TEST Batch Id : '
                             || g_tender_rec.batch_id(i),
                             1);                             
        END IF;


    END Process_Tender;    
    PROCEDURE process_payment(
        p_order_rec      IN             order_rec_type,
        p_batch_id       IN             NUMBER,
        p_pay_amt        IN OUT NOCOPY  NUMBER,
        x_return_status  OUT NOCOPY     VARCHAR2)
    IS
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
        i                        BINARY_INTEGER;
        lc_pay_type              VARCHAR2(10);
        ln_sold_to_org_id        NUMBER;
        ln_payment_number        NUMBER         := 0;
        lc_err_msg               VARCHAR2(1000);
        ln_hdr_ind               NUMBER;
        lc_payment_type_code     VARCHAR2(30);
        lc_cc_code               VARCHAR2(80);
        lc_identifier            VARCHAR2(80);
        lc_cc_name               VARCHAR2(80);
        lc_pay_sign              VARCHAR2(1);
        ln_pay_amount            NUMBER;
        ln_receipt_method_id     NUMBER;
        ld_exp_date              DATE;
        ln_debug_level  CONSTANT NUMBER         := oe_debug_pub.g_debug_level;
        --lr_pub_key            RAW(25);
        --lr_cc_act             RAW(128);
        lc_pay_seq               VARCHAR2(3);
        lc_key_name              VARCHAR2(25);
        lc_cc_number_enc         VARCHAR2(128);
        lc_cc_number_dec         VARCHAR2(80);
        lc_cc_number_cust_enc    VARCHAR2(128);
        lc_cc_mask               VARCHAR2(20);
        lc_cc_entry              VARCHAR2(30);
        lc_cvv_resp              VARCHAR2(1);
        lc_avs_resp              VARCHAR2(1);
        lc_auth_entry_mode       VARCHAR2(1);
        ln_length                NUMBER         := 16;
        ln_pay_amt               NUMBER;
        lc_cash_back             VARCHAR2(10);                                                         --NB for DEPO CB
    BEGIN
        x_return_status := 'S';

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('Entering Process_Payment');
        END IF;

        ln_hdr_ind := g_header_rec.orig_sys_document_ref.COUNT;
        lc_pay_seq := SUBSTR(p_order_rec.file_line,
                             33,
                             3);
        lc_pay_type := SUBSTR(p_order_rec.file_line,
                              36,
                              2);
        lc_pay_sign := SUBSTR(p_order_rec.file_line,
                              38,
                              1);
        lc_cash_back := SUBSTR(p_order_rec.file_line,
                               281,
                               2);                                                                      --NB for DEPO CB

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Pay Type '
                             || lc_pay_type);
            oe_debug_pub.ADD(   'Pay Sign: '
                             || lc_pay_sign);
            oe_debug_pub.ADD(   'Cash Back IND: '
                             || lc_cash_back);
        END IF;

        -- Read the Payment amount
        ln_pay_amount := SUBSTR(p_order_rec.file_line,
                                39,
                                10);

        IF lc_pay_type IS NULL
        THEN
            set_msg_context(p_entity_code      => 'HEADER_PAYMENT');
            set_header_error(ln_hdr_ind);
            lc_err_msg := 'PAYMENT METHOD Missing  ';
            fnd_message.set_name('XXOM',
                                 'XX_OM_MISSING_ATTRIBUTE');
            fnd_message.set_token('ATTRIBUTE',
                                  'Tender Type');
            oe_bulk_msg_pub.ADD;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(lc_err_msg,
                                 1);
            END IF;
        END IF;

        -- Check if paying by debit card
        IF lc_pay_type = '16' AND lc_pay_sign = '+'
        THEN
            g_has_debit_card := TRUE;
        ELSIF lc_pay_type = '01' AND lc_pay_sign = '-' AND g_has_debit_card OR lc_cash_back = 'CB'      --NB for DEPO CB
        THEN
            -- It is a CASH back Transaction and we will need to create a Line record.
            IF lc_cash_back = 'CB'
            THEN                                                                          --NB for DEPO CB Defect 17015
                p_pay_amt :=(  g_header_rec.order_total(ln_hdr_ind)
                             + ln_pay_amount);

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'PAYMENT AMOUNT for DEPO CASH BACK ORD : '
                                     || p_pay_amt);
                END IF;
            END IF;

            create_cashback_line(p_hdr_idx      => ln_hdr_ind,
                                 p_amount       => ln_pay_amount);
            RETURN;
        END IF;

        -- Capture the payment total for the order
        -- p_pay_amt := p_pay_amt + ((lc_pay_sign)||ln_pay_amount);
        p_pay_amt :=   ln_pay_amt
                     + (   (lc_pay_sign)
                        || ln_pay_amount);

        -- If the payment record is Account Billing or OD house account then Skip payment record creation

        IF lc_pay_type = 'AB' OR lc_pay_type = '20' OR lc_pay_type = 'RC'
        THEN
            -- Need to skip the payment record creation
            GOTO skip_payment;
        END IF;

        IF lc_pay_type IS NOT NULL
        THEN
            get_pay_method(p_payment_instrument      => lc_pay_type,
                           p_payment_type_code       => lc_payment_type_code,
                           p_credit_card_code        => lc_cc_code);

            IF lc_payment_type_code IS NULL
            THEN
                set_msg_context(p_entity_code      => 'HEADER_PAYMENT');
                set_header_error(ln_hdr_ind);
                lc_payment_type_code := lc_pay_type;
                lc_err_msg :=    'INVALID PAYMENT METHOD :'
                              || lc_pay_type;
                fnd_message.set_name('XXOM',
                                     'XX_OM_FAIL_PAYMTD_DERIVATION');
                fnd_message.set_token('ATTRIBUTE1',
                                      lc_pay_type);
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;
        END IF;

        IF g_header_rec.legacy_cust_name(ln_hdr_ind) IS NULL
        THEN
            lc_cc_name := credit_card_name(g_header_rec.sold_to_org_id(ln_hdr_ind));
        ELSE
            lc_cc_name := g_header_rec.legacy_cust_name(ln_hdr_ind);
        END IF;

        -- Get the receipt method for the tender type
        ln_receipt_method_id := get_receipt_method(lc_pay_type,
                                                   g_org_id,
                                                   g_header_rec.paid_at_store_no(ln_hdr_ind));

        -- For retun refund check there is no receipt method setup by AR. So it is OK to have null value for
        -- return refund payment record.
        IF ln_receipt_method_id IS NULL AND g_header_rec.order_category(ln_hdr_ind) = 'ORDER' AND lc_pay_type <> '11'
        THEN
            set_msg_context(p_entity_code      => 'HEADER_PAYMENT');
            set_header_error(ln_hdr_ind);
            lc_err_msg := 'Could not derive Receipt Method for the payment instrument';
            fnd_message.set_name('XXOM',
                                 'XX_OM_NO_RECEIPT_METHOD');
            fnd_message.set_token('ATTRIBUTE1',
                                  lc_pay_type);
            oe_bulk_msg_pub.ADD;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(lc_err_msg,
                                 1);
            END IF;
        END IF;

        -- Read the CC exp date first
        BEGIN
            ld_exp_date := TO_DATE(LTRIM(SUBSTR(p_order_rec.file_line,
                                                69,
                                                4)),
                                   'MMYY');
        EXCEPTION
            WHEN OTHERS
            THEN
                ld_exp_date := NULL;
                set_header_error(ln_hdr_ind);
                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg :=    'Error reading CC Exp Date'
                              || SUBSTR(p_order_rec.file_line,
                                        69,
                                        4);
                fnd_message.set_name('XXOM',
                                     'XX_OM_READ_ERROR');
                fnd_message.set_token('ATTRIBUTE1',
                                      'CC Exp Date');
                fnd_message.set_token('ATTRIBUTE2',
                                      SUBSTR(p_order_rec.file_line,
                                             69,
                                             4));
                fnd_message.set_token('ATTRIBUTE3',
                                      'MMYY');
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
        END;

        -- Read Credit Card Details..
        lc_key_name := TRIM(SUBSTR(p_order_rec.file_line,
                                   174,
                                   25));
        lc_cc_number_enc := TRIM(SUBSTR(p_order_rec.file_line,
                                        199,
                                        48));
        lc_cc_mask := TRIM(SUBSTR(p_order_rec.file_line,
                                  49,
                                  20));

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Key Name'
                             || lc_key_name,
                             1);
            --oe_debug_pub.add('CC Num' || lc_cc_number_enc, 1);
            oe_debug_pub.ADD(   'CC Mask'
                             || lc_cc_mask,
                             1);
        END IF;

        IF lc_cc_number_enc IS NULL AND lc_cc_mask IS NOT NULL AND lc_payment_type_code = 'CREDIT_CARD'
        THEN
            lc_cc_number_enc := lc_cc_mask;
        END IF;

        lc_err_msg := NULL;

        IF lc_cc_number_enc IS NOT NULL
        THEN
            IF xx_om_hvop_util_pkg.g_use_test_cc = 'N'
            THEN
                DBMS_SESSION.set_context(namespace      => 'XX_OM_SAS_CONTEXT',
                                         ATTRIBUTE      => 'TYPE',
                                         VALUE          => 'OM');

                -- Use the CrediZt card read from the file
                xx_od_security_key_pkg.decrypt(p_module             => 'HVOP',
                                               p_key_label          => lc_key_name,
                                               p_encrypted_val      => lc_cc_number_enc,
                                               p_format             => 'EBCDIC',
                                               x_decrypted_val      => lc_cc_number_dec,
                                               x_error_message      => lc_err_msg);


            ELSE
                -- Use the first 6 and last 4 of the CC mask and generate a TEST credit card
                IF lc_pay_type = '26'
                THEN
                    ln_length := 15;
                END IF;

                lc_cc_number_dec :=
                          xx_om_hvop_util_pkg.get_test_cc(SUBSTR(lc_cc_mask,
                                                                 1,
                                                                 6),
                                                          SUBSTR(lc_cc_mask,
                                                                 7,
                                                                 4),
                                                          ln_length);

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'Test CC number is '
                                     || lc_cc_number_dec);
                END IF;
            END IF;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'CC Num'
                                 || lc_cc_number_dec,
                                 1);
                oe_debug_pub.ADD(   'CC Num length'
                                 || LENGTH(lc_cc_number_dec),
                                 1);
                oe_debug_pub.ADD(   'Error Message'
                                 || lc_err_msg,
                                 1);
            END IF;

            IF lc_cc_number_dec IS NULL OR lc_err_msg IS NOT NULL
            THEN
                set_header_error(ln_hdr_ind);

              -- commented below code to pass back correct error message.
              --  g_payment_rec.credit_card_number(i) :=    lc_key_name
              --                                         || ':'
              --                                         || lc_cc_number_enc;


                set_msg_context(p_entity_code      => 'HEADER');
                lc_err_msg :=
                         SUBSTR(   'Error Decrypting credit card number'
                                || lc_cc_number_enc
                                || ' '
                                || lc_err_msg,
                                1,
                                1000);
                fnd_message.set_name('XXOM',
                                     'XX_OM_CC_DECRYPT_ERROR');
                fnd_message.set_token('ATTRIBUTE1',
                                      lc_err_msg);
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            ELSE
                IF    SUBSTR(lc_cc_number_dec,
                             1,
                             6)
                   || SUBSTR(lc_cc_number_dec,
                             -4,
                             4) <> lc_cc_mask
                THEN
                    set_header_error(ln_hdr_ind);
                    set_msg_context(p_entity_code      => 'HEADER');
                    lc_err_msg :=
                           'Decrypted Credit card number :'
                        || SUBSTR(lc_cc_number_dec,
                                  1,
                                  6)
                        || SUBSTR(lc_cc_number_dec,
                                  -4,
                                  4)
                        || ' does not match mask value '
                        || lc_cc_mask;
                    fnd_message.set_name('XXOM',
                                         'XX_OM_CC_MASK_MISMATCH');
                    fnd_message.set_token('ATTRIBUTE1',
                                             SUBSTR(lc_cc_number_dec,
                                                    1,
                                                    6)
                                          || SUBSTR(lc_cc_number_dec,
                                                    -4,
                                                    4));
                    fnd_message.set_token('ATTRIBUTE2',
                                          lc_cc_mask);
                    oe_bulk_msg_pub.ADD;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(lc_err_msg,
                                         1);
                    END IF;
                ELSE
                    -- Get the encrypted value from custom key
                    --  lc_cc_number_dec := Get_Secure_Card_Number(lc_cc_number_dec);

                    get_secure_card_number(p_cc_number                => lc_cc_number_dec,
                                           x_cc_number_encrypted      => lc_cc_number_cust_enc,
                                           x_identifier               => lc_identifier,
                                           x_error_message            => lc_err_msg);

                    oe_debug_pub.ADD(   'Oracle cust enc cc num is '
                                     || lc_cc_number_cust_enc);

                    IF lc_cc_number_cust_enc IS NULL OR lc_identifier IS NULL OR lc_err_msg IS NOT NULL
                    THEN
                        set_header_error(ln_hdr_ind);
                        g_payment_rec.credit_card_number(i) :=    lc_key_name
                                                               || ':'
                                                               || lc_cc_number_enc;
                        set_msg_context(p_entity_code      => 'HEADER');
                        lc_err_msg := SUBSTR(   'Error Encrypting credit card number '
                                             || lc_err_msg,
                                             1,
                                             1000);
                        fnd_message.set_name('XXOM',
                                             'XX_OM_CC_DECRYPT_ERROR');
                        fnd_message.set_token('ATTRIBUTE1',
                                              lc_err_msg);
                        oe_bulk_msg_pub.ADD;

                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD(lc_err_msg,
                                             1);
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;

        --IF G_header_rec.order_category(ln_hdr_ind) = 'ORDER' THEN
        IF lc_pay_sign = '+'
        THEN
            oe_debug_pub.ADD('Start reading Payment Record 2');
            i :=   g_payment_rec.orig_sys_document_ref.COUNT
                 + 1;
            g_payment_rec.payment_type_code(i) := lc_payment_type_code;
            g_payment_rec.receipt_method_id(i) := ln_receipt_method_id;
            g_payment_rec.orig_sys_document_ref(i) := g_header_rec.orig_sys_document_ref(ln_hdr_ind);
            g_payment_rec.sold_to_org_id(i) := g_header_rec.sold_to_org_id(ln_hdr_ind);
            g_payment_rec.order_source_id(i) := g_header_rec.order_source_id(ln_hdr_ind);
            g_payment_rec.orig_sys_payment_ref(i) := lc_pay_seq;
            g_payment_rec.prepaid_amount(i) := NULL;
            g_payment_rec.payment_amount(i) := ln_pay_amount;
            g_payment_rec.payment_set_id(i) := NULL;
            g_payment_rec.credit_card_number(i) := NULL;                                         --R12 lc_cc_number_dec;
            g_payment_rec.credit_card_number_enc(i) := lc_cc_number_cust_enc;
            g_payment_rec.IDENTIFIER(i) := lc_identifier;

            IF lc_cc_number_enc IS NOT NULL
            THEN
                g_payment_rec.credit_card_expiration_date(i) := ld_exp_date;

                IF ld_exp_date IS NULL
                THEN
                    set_msg_context(p_entity_code      => 'HEADER_PAYMENT');
                    set_header_error(ln_hdr_ind);
                    lc_err_msg := 'CC EXP DATE IS MISSING';
                    fnd_message.set_name('XXOM',
                                         'XX_OM_MISSING_ATTRIBUTE');
                    fnd_message.set_token('ATTRIBUTE',
                                          'Credit Card EXP date');
                    oe_bulk_msg_pub.ADD;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(lc_err_msg,
                                         1);
                    END IF;
                END IF;

                g_payment_rec.credit_card_code(i) := lc_cc_code;

                IF lc_cc_code IS NULL
                THEN
                    set_msg_context(p_entity_code      => 'HEADER_PAYMENT');
                    set_header_error(ln_hdr_ind);
                    lc_err_msg := 'Credit Card code IS MISSING';
                    fnd_message.set_name('XXOM',
                                         'XX_OM_MISSING_ATTRIBUTE');
                    fnd_message.set_token('ATTRIBUTE',
                                          'Credit Card Code');
                    oe_bulk_msg_pub.ADD;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(lc_err_msg,
                                         1);
                    END IF;
                END IF;

                g_payment_rec.credit_card_approval_code(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                                                 75,
                                                                                 6)));

                -- Ignore the validation for Debit Cards, OD CHARGE and SPS
                IF g_payment_rec.credit_card_approval_code(i) IS NULL AND lc_pay_type NOT IN(16)
                THEN
                    g_payment_rec.credit_card_approval_code(i) := '999999';
                END IF;

                BEGIN
                    g_payment_rec.credit_card_approval_date(i) :=
                                                    TO_DATE(LTRIM(SUBSTR(p_order_rec.file_line,
                                                                         81,
                                                                         10)),
                                                            'YYYY-MM-DD');
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        g_payment_rec.credit_card_approval_date(i) := NULL;
                        set_header_error(ln_hdr_ind);
                        set_msg_context(p_entity_code      => 'HEADER');
                        lc_err_msg :=    'Error reading CC Approval Date'
                                      || SUBSTR(p_order_rec.file_line,
                                                81,
                                                10);
                        fnd_message.set_name('XXOM',
                                             'XX_OM_READ_ERROR');
                        fnd_message.set_token('ATTRIBUTE1',
                                              'CC Approval Date');
                        fnd_message.set_token('ATTRIBUTE2',
                                              SUBSTR(p_order_rec.file_line,
                                                     81,
                                                     10));
                        fnd_message.set_token('ATTRIBUTE3',
                                              'YYYY-MM-DD');
                        oe_bulk_msg_pub.ADD;

                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD(lc_err_msg,
                                             1);
                        END IF;
                END;

                -- Ignore the validation for Debit Cards, OD CHARGE and SPS
                IF g_payment_rec.credit_card_approval_date(i) IS NULL AND lc_pay_type NOT IN(16)
                THEN
                    g_payment_rec.credit_card_approval_date(i) := g_header_rec.ordered_date(ln_hdr_ind);
                END IF;
            ELSE
                g_payment_rec.credit_card_number(i) := NULL;
                g_payment_rec.credit_card_expiration_date(i) := NULL;
                g_payment_rec.credit_card_code(i) := NULL;
                g_payment_rec.credit_card_approval_code(i) := NULL;
                g_payment_rec.credit_card_approval_date(i) := NULL;
                g_payment_rec.credit_card_number_enc(i) := NULL;
                g_payment_rec.IDENTIFIER(i) := NULL;
                g_payment_rec.attribute3(i) := NULL;
                g_payment_rec.attribute14(i) := NULL;
                g_payment_rec.attribute2(i)  := NULL;
            END IF;

            g_payment_rec.check_number(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                                91,
                                                                20)));
            g_payment_rec.payment_number(i) := lc_pay_seq;
            g_payment_rec.attribute6(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                              111,
                                                              1)));
            g_payment_rec.attribute7(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                              112,
                                                              11)));
            g_payment_rec.attribute8(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                              123,
                                                              50)));
            g_payment_rec.attribute9(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                              173,
                                                              1)));
            g_payment_rec.credit_card_holder_name(i) := lc_cc_name;
            g_payment_rec.attribute10(i) := lc_cc_mask;
            g_payment_rec.attribute11(i) := lc_pay_type;
            g_payment_rec.attribute15(i) := NULL;
            -- Read the Debit Card Approval reference number
            g_payment_rec.attribute12(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                               247,
                                                               30)));
            -- Adding the code to capture CC entry mode (keyed or swiped), CVV response code and AVS response code
            lc_cc_entry := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                              277,
                                              1)));
            lc_cvv_resp := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                              278,
                                              1)));
            lc_avs_resp := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                              279,
                                              1)));
            lc_auth_entry_mode := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                     280,
                                                     1)));
            g_payment_rec.attribute13(i) :=
                                       lc_cc_entry
                                    || ':'
                                    || lc_cvv_resp
                                    || ':'
                                    || lc_avs_resp
                                    || ':'
                                    || lc_auth_entry_mode;

            -- Adding the code to capture the Tokenization and EMV fields for defect -34103

            g_payment_rec.attribute3(i)  :=  LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,283,1)));         -- Token flag
            g_payment_rec.attribute14(i) :=  SUBSTR(p_order_rec.file_line,284,1)||'.'||   -- EMV card
                                             SUBSTR(p_order_rec.file_line,285,2)||'.'||   -- EMV Terminal
                                             SUBSTR(p_order_rec.file_line,287,1)||'.'||   -- EMV Transaction
                                             SUBSTR(p_order_rec.file_line,288,1)||'.'||   -- EMV Offline
                                             SUBSTR(p_order_rec.file_line,289,1)||'.'||   -- EMV Fallback
                                             SUBSTR(p_order_rec.file_line,290,10) ;       -- EMV TVR
            g_payment_rec.attribute2(i) :=  LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,300,1)))||'.'||   -- Wallet type
                                            LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,301,3)));
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'lc_pay_type = '
                                 || lc_pay_type);
                oe_debug_pub.ADD(   'receipt_method = '
                                 || g_payment_rec.receipt_method_id(i));
                oe_debug_pub.ADD(   'orig_sys_document_ref = '
                                 || g_payment_rec.orig_sys_document_ref(i));
                oe_debug_pub.ADD(   'order_source_id = '
                                 || g_payment_rec.order_source_id(i));
                oe_debug_pub.ADD(   'orig_sys_payment_ref = '
                                 || g_payment_rec.orig_sys_payment_ref(i));
                oe_debug_pub.ADD(   'prepaid amount = '
                                 || g_payment_rec.prepaid_amount(i));
                oe_debug_pub.ADD(   'lc_cc_number = '
                                 || g_payment_rec.credit_card_number(i));
                oe_debug_pub.ADD(   'lc_cc_number_enc = '
                                 || g_payment_rec.credit_card_number_enc(i));
                oe_debug_pub.ADD(   'lc_identifier = '
                                 || g_payment_rec.IDENTIFIER(i));
                oe_debug_pub.ADD(   'credit_card_expiration_date = '
                                 || g_payment_rec.credit_card_expiration_date(i));
                oe_debug_pub.ADD(   'credit_card_approval_code = '
                                 || g_payment_rec.credit_card_approval_code(i));
                oe_debug_pub.ADD(   'credit_card_approval_date = '
                                 || g_payment_rec.credit_card_approval_date(i));
                oe_debug_pub.ADD(   'check_number = '
                                 || g_payment_rec.check_number(i));
                oe_debug_pub.ADD(   'attribute6 = '
                                 || g_payment_rec.attribute6(i));
                oe_debug_pub.ADD(   'attribute7 = '
                                 || g_payment_rec.attribute7(i));
                oe_debug_pub.ADD(   'attribute8 = '
                                 || g_payment_rec.attribute8(i));
                oe_debug_pub.ADD(   'attribute9 = '
                                 || g_payment_rec.attribute9(i));
                oe_debug_pub.ADD(   'attribute10 = '
                                 || g_payment_rec.attribute10(i));
                oe_debug_pub.ADD(   'attribute11 = '
                                 || g_payment_rec.attribute11(i));
                oe_debug_pub.ADD(   'attribute12 = '
                                 || g_payment_rec.attribute12(i));
                oe_debug_pub.ADD(   'attribute13 = '
                                 || g_payment_rec.attribute13(i));
                oe_debug_pub.ADD(   'credit_card_holder_name = '
                                 || g_payment_rec.credit_card_holder_name(i));
                oe_debug_pub.ADD(   'Error Flag is '
                                 || g_header_rec.error_flag(ln_hdr_ind));
                oe_debug_pub.ADD(   'attribute3 = '
                                 || g_payment_rec.attribute3(i));
                oe_debug_pub.ADD(   'attribute14 = '
                                 || g_payment_rec.attribute14(i));
                oe_debug_pub.ADD(   'attribute2 = '
                                 || g_payment_rec.attribute2(i));

            END IF;
        ELSE                                                      -- If Sign is -ve then it is return tender info record
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD('Start reading Payment Record for Return tender ');
            END IF;

            i :=   g_return_tender_rec.orig_sys_document_ref.COUNT
                 + 1;
            g_return_tender_rec.payment_type_code(i) := lc_payment_type_code;
            g_return_tender_rec.orig_sys_document_ref(i) := g_header_rec.orig_sys_document_ref(ln_hdr_ind);
            g_return_tender_rec.receipt_method_id(i) := ln_receipt_method_id;
            g_return_tender_rec.order_source_id(i) := g_header_rec.order_source_id(ln_hdr_ind);
            g_return_tender_rec.orig_sys_payment_ref(i) := lc_pay_seq;
            g_return_tender_rec.payment_number(i) := lc_pay_seq;
            g_return_tender_rec.credit_card_code(i) := lc_cc_code;
            g_return_tender_rec.credit_card_number(i) := lc_cc_number_cust_enc;
            g_return_tender_rec.IDENTIFIER(i) := lc_identifier;


            IF lc_cc_number_enc IS NOT NULL
            THEN
                g_return_tender_rec.credit_card_expiration_date(i) := ld_exp_date;

                IF ld_exp_date IS NULL
                THEN
                    set_msg_context(p_entity_code      => 'HEADER_PAYMENT');
                    set_header_error(ln_hdr_ind);
                    lc_err_msg := 'CC EXP DATE IS MISSING';
                    fnd_message.set_name('XXOM',
                                         'XX_OM_MISSING_ATTRIBUTE');
                    fnd_message.set_token('ATTRIBUTE',
                                          'Credit Card EXP date');
                    oe_bulk_msg_pub.ADD;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(lc_err_msg,
                                         1);
                    END IF;
                END IF;

                IF lc_cc_code IS NULL
                THEN
                    set_msg_context(p_entity_code      => 'HEADER_PAYMENT');
                    set_header_error(ln_hdr_ind);
                    lc_err_msg := 'Credit Card code IS MISSING';
                    fnd_message.set_name('XXOM',
                                         'XX_OM_MISSING_ATTRIBUTE');
                    fnd_message.set_token('ATTRIBUTE',
                                          'Credit Card Code');
                    oe_bulk_msg_pub.ADD;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(lc_err_msg,
                                         1);
                    END IF;
                END IF;
            ELSE
                g_return_tender_rec.credit_card_number(i) := NULL;
                g_return_tender_rec.credit_card_expiration_date(i) := NULL;
            END IF;

            g_return_tender_rec.credit_amount(i) := ln_pay_amount;
            g_return_tender_rec.sold_to_org_id(i) := g_header_rec.sold_to_org_id(ln_hdr_ind);
            g_return_tender_rec.cc_auth_manual(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                                        111,
                                                                        1)));
            g_return_tender_rec.merchant_nbr(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                                      112,
                                                                      11)));
            g_return_tender_rec.cc_auth_ps2000(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                                        123,
                                                                        50)));
            g_return_tender_rec.allied_ind(i) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                                    173,
                                                                    1)));
            g_return_tender_rec.credit_card_holder_name(i) := lc_cc_name;
            g_return_tender_rec.cc_mask_number(i) := lc_cc_mask;
            g_return_tender_rec.od_payment_type(i) := lc_pay_type;

            g_return_tender_rec.token_flag(i)         :=  LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,283,1)));   -- Token flag
            g_return_tender_rec.emv_card(i)           :=  SUBSTR(p_order_rec.file_line,284,1);   -- EMV card
            g_return_tender_rec.emv_terminal(i)       :=  SUBSTR(p_order_rec.file_line,285,2);   -- EMV Terminal
            g_return_tender_rec.emv_transaction(i)    :=  SUBSTR(p_order_rec.file_line,287,1);   -- EMV Transaction
            g_return_tender_rec.emv_offline(i)        :=  SUBSTR(p_order_rec.file_line,288,1);   -- EMV Offline
            g_return_tender_rec.emv_fallback(i)       :=  SUBSTR(p_order_rec.file_line,289,1);   -- EMV Fallback
            g_return_tender_rec.emv_tvr(i)            :=  SUBSTR(p_order_rec.file_line,290,10);  -- EMV TVR
            g_return_tender_rec.wallet_type(i)        :=  SUBSTR(p_order_rec.file_line,300,1);   -- Wallet type
            g_return_tender_rec.wallet_id(i)          :=  SUBSTR(p_order_rec.file_line,301,3);   -- Wallet id

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Return tender orig_sys_document_ref = '
                                 || g_return_tender_rec.orig_sys_document_ref(i));
                oe_debug_pub.ADD(   'payment_type_code = '
                                 || g_return_tender_rec.payment_type_code(i));
                oe_debug_pub.ADD(   'order_source_id = '
                                 || g_return_tender_rec.order_source_id(i));
                oe_debug_pub.ADD(   'orig_sys_payment_ref = '
                                 || g_return_tender_rec.orig_sys_payment_ref(i));
                oe_debug_pub.ADD(   'payment_amount = '
                                 || g_return_tender_rec.credit_amount(i));
                oe_debug_pub.ADD(   'lc_cc_number = '
                                 || g_return_tender_rec.credit_card_number(i));
                oe_debug_pub.ADD(   'lc_identifier = '
                                 || g_return_tender_rec.IDENTIFIER(i));
                oe_debug_pub.ADD(   'credit_card_expiration_date = '
                                 || g_return_tender_rec.credit_card_expiration_date(i));
                oe_debug_pub.ADD(   'credit_card_holder_name = '
                                 || g_return_tender_rec.credit_card_holder_name(i));
                oe_debug_pub.ADD(   'cc_auth_manual = '
                                 || g_return_tender_rec.cc_auth_manual(i));
                oe_debug_pub.ADD(   'merchant_nbr = '
                                 || g_return_tender_rec.merchant_nbr(i));
                oe_debug_pub.ADD(   'cc_auth_ps2000 = '
                                 || g_return_tender_rec.cc_auth_ps2000(i));
                oe_debug_pub.ADD(   'allied_ind = '
                                 || g_return_tender_rec.allied_ind(i));

                oe_debug_pub.ADD(   'token_flag = '
                                 || g_return_tender_rec.token_flag(i));
                oe_debug_pub.ADD(   'emv_card = '
                                 || g_return_tender_rec.emv_card(i));
                oe_debug_pub.ADD(   'emv_terminal = '
                                 || g_return_tender_rec.emv_terminal(i));
                oe_debug_pub.ADD(   'emv_transaction = '
                                 || g_return_tender_rec.emv_transaction(i));
                oe_debug_pub.ADD(   'emv_offline = '
                                 || g_return_tender_rec.emv_offline(i));
                oe_debug_pub.ADD(   'emv_fallback = '
                                 || g_return_tender_rec.emv_fallback(i));
                oe_debug_pub.ADD(   'emv_tvr = '
                                 || g_return_tender_rec.emv_tvr(i));
                oe_debug_pub.ADD(   'wallet type = '
                                 || g_return_tender_rec.wallet_type(i));
                oe_debug_pub.ADD(   'wallet id = '
                                 || g_return_tender_rec.wallet_id(i));


            END IF;
        END IF;

        <<skip_payment>>
        x_return_status := 'S';

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Error Flag is '
                             || g_header_rec.error_flag(ln_hdr_ind));
            oe_debug_pub.ADD('Exiting Process Payment ');
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed to process Payment :'
                              || lc_pay_seq
                              || ' for order '
                              || g_header_rec.orig_sys_document_ref(ln_hdr_ind));
            fnd_file.put_line(fnd_file.LOG,
                                 'The error is '
                              || SQLERRM);
            -- Need to clear this BAD order
            clear_bad_orders('PAYMENT',
                             g_header_rec.orig_sys_document_ref(ln_hdr_ind));
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
    PROCEDURE init_line_record(
        p_line_idx       IN  BINARY_INTEGER,
        p_hdr_idx        IN  BINARY_INTEGER,
        p_rec_type       IN  VARCHAR2,
        p_line_category  IN  VARCHAR2)
    IS
        ln_debug_level  CONSTANT NUMBER := oe_debug_pub.g_debug_level;
    BEGIN
        g_line_rec.orig_sys_document_ref(p_line_idx) := g_header_rec.orig_sys_document_ref(p_hdr_idx);
        g_line_rec.payment_term_id(p_line_idx) := g_header_rec.payment_term_id(p_hdr_idx);
        g_line_rec.order_source_id(p_line_idx) := g_header_rec.order_source_id(p_hdr_idx);
        g_line_rec.ordered_date(p_line_idx) := g_header_rec.ordered_date(p_hdr_idx);
        g_line_rec.change_sequence(p_line_idx) := g_header_rec.change_sequence(p_hdr_idx);
        g_line_rec.tax_exempt_flag(p_line_idx) := g_header_rec.tax_exempt_flag(p_hdr_idx);
        g_line_rec.tax_exempt_number(p_line_idx) := g_header_rec.tax_exempt_number(p_hdr_idx);
        g_line_rec.tax_exempt_reason(p_line_idx) := g_header_rec.tax_exempt_reason(p_hdr_idx);
        g_line_rec.request_id(p_line_idx) := NULL;
        g_line_rec.ret_ref_header_id(p_line_idx) := NULL;
        g_line_rec.ret_ref_line_id(p_line_idx) := NULL;
        g_line_rec.line_number(p_line_idx) := g_line_nbr_counter;
        g_line_rec.schedule_ship_date(p_line_idx) := NULL;
        g_line_rec.actual_ship_date(p_line_idx) := NULL;
        g_line_rec.schedule_arrival_date(p_line_idx) := NULL;
        g_line_rec.actual_arrival_date(p_line_idx) := NULL;
        g_line_rec.ordered_quantity(p_line_idx) := 1;
        g_line_rec.order_quantity_uom(p_line_idx) := 'EA';
        g_line_rec.shipped_quantity(p_line_idx) := NULL;
        g_line_rec.sold_to_org_id(p_line_idx) := g_header_rec.sold_to_org_id(p_hdr_idx);
        g_line_rec.ship_to_org_id(p_line_idx) := g_header_rec.ship_to_org_id(p_hdr_idx);
        g_line_rec.ship_from_org_id(p_line_idx) := g_header_rec.ship_from_org_id(p_hdr_idx);
        g_line_rec.invoice_to_org_id(p_line_idx) := g_header_rec.invoice_to_org_id(p_hdr_idx);
        g_line_rec.sold_to_contact_id(p_line_idx) := g_header_rec.sold_to_contact_id(p_hdr_idx);
        g_line_rec.drop_ship_flag(p_line_idx) := NULL;
        g_line_rec.price_list_id(p_line_idx) := g_header_rec.price_list_id(p_hdr_idx);
        g_line_rec.tax_date(p_line_idx) := g_header_rec.ordered_date(p_hdr_idx);
        g_line_rec.tax_value(p_line_idx) := NULL;
        g_line_rec.tax_code(p_line_idx) := NULL;
        --g_line_rec.shipping_method_code(p_line_idx) := NULL;
        g_line_rec.salesrep_id(p_line_idx) := g_header_rec.salesrep_id(p_hdr_idx);
        g_line_rec.customer_po_number(p_line_idx) := g_header_rec.customer_po_number(p_hdr_idx);
        g_line_rec.operation_code(p_line_idx) := 'CREATE';
        g_line_rec.shipping_instructions(p_line_idx) := NULL;
        g_line_rec.return_context(p_line_idx) := NULL;
        g_line_rec.return_attribute1(p_line_idx) := NULL;
        g_line_rec.return_attribute2(p_line_idx) := NULL;
        g_line_rec.customer_item_name(p_line_idx) := NULL;
        g_line_rec.customer_item_id(p_line_idx) := NULL;
        g_line_rec.customer_item_id_type(p_line_idx) := NULL;
        g_line_rec.tot_tax_value(p_line_idx) := NULL;
        g_line_rec.customer_line_number(p_line_idx) := NULL;
        g_line_rec.org_order_creation_date(p_line_idx) := NULL;
        g_line_rec.return_act_cat_code(p_line_idx) := NULL;
        g_line_rec.legacy_list_price(p_line_idx) := NULL;
        g_line_rec.vendor_product_code(p_line_idx) := NULL;
        g_line_rec.contract_details(p_line_idx) := NULL;
        g_line_rec.item_comments(p_line_idx) := NULL;
        g_line_rec.line_comments(p_line_idx) := NULL;
        g_line_rec.taxable_flag(p_line_idx) := NULL;
        g_line_rec.sku_dept(p_line_idx) := NULL;
        g_line_rec.item_source(p_line_idx) := NULL;
        g_line_rec.average_cost(p_line_idx) := NULL;
        g_line_rec.po_cost(p_line_idx) := NULL;
        g_line_rec.canada_pst(p_line_idx) := NULL;
        g_line_rec.return_reference_no(p_line_idx) := NULL;
        g_line_rec.back_ordered_qty(p_line_idx) := NULL;
        g_line_rec.return_ref_line_no(p_line_idx) := NULL;
        g_line_rec.wholesaler_item(p_line_idx) := NULL;
        g_line_rec.user_item_description(p_line_idx) := NULL;
        g_line_rec.ext_top_model_line_id(p_line_idx) := NULL;
        g_line_rec.ext_link_to_line_id(p_line_idx) := NULL;
        g_line_rec.config_code(p_line_idx) := NULL;
        g_line_rec.calc_arrival_date(p_line_idx) := NULL;
        g_line_rec.aops_ship_date(p_line_idx) := NULL;
        g_line_rec.sas_sale_date(p_line_idx) := g_header_rec.sas_sale_date(p_hdr_idx);
        g_line_rec.cust_dept_no(p_line_idx) := g_header_rec.cust_dept_no(p_hdr_idx);
        g_line_rec.cust_dept_description(p_line_idx) := g_header_rec.cust_dept_description(p_hdr_idx);
        g_line_rec.desk_top_no(p_line_idx) := g_header_rec.desk_top_no(p_hdr_idx);
        g_line_rec.release_number(p_line_idx) := g_header_rec.release_number(p_hdr_idx);
        g_line_rec.gsa_flag(p_line_idx) := NULL;
        g_line_rec.waca_item_ctr_num(p_line_idx) := NULL;
        g_line_rec.consignment_bank_code(p_line_idx) := NULL;
        g_line_rec.price_cd(p_line_idx) := NULL;
        g_line_rec.price_change_reason_cd(p_line_idx) := NULL;
        g_line_rec.price_prefix_cd(p_line_idx) := NULL;
        g_line_rec.commisionable_ind(p_line_idx) := NULL;
        g_line_rec.inventory_item_id(p_line_idx) := NULL;
        g_line_rec.inventory_item(p_line_idx) := NULL;
        g_line_rec.unit_orig_selling_price(p_line_idx) := NULL;
        g_line_rec.mps_toner_retail(p_line_idx) := NULL;
        g_line_rec.core_type_indicator(p_line_idx) := NULL;
        g_line_rec.line_tax_amount(p_line_idx) := NULL;
        g_line_rec.line_tax_rate(p_line_idx) := NULL;
        g_line_rec.kit_sku(p_line_idx) := NULL;
        g_line_rec.kit_qty(p_line_idx) := NULL;
        g_line_rec.kit_vpc(p_line_idx) := NULL;
        g_line_rec.kit_dept(p_line_idx) := NULL;
        g_line_rec.kit_seqnum(p_line_idx) := NULL;
        g_line_rec.service_end_date(p_line_idx) := NULL;

        IF g_header_rec.order_category(p_hdr_idx) = 'ORDER'
        THEN
            g_line_rec.request_id(p_line_idx) := g_request_id;
            g_batch_counter :=   g_batch_counter
                               + 1;
            g_order_line_tax_ctr :=   g_order_line_tax_ctr
                                    + 1;
        ELSE
            IF p_line_category = 'RETURN'
            THEN
                g_rma_line_tax_ctr :=   g_rma_line_tax_ctr
                                      + 1;
            ELSE
                g_order_line_tax_ctr :=   g_order_line_tax_ctr
                                        + 1;
            END IF;

            g_line_rec.request_id(p_line_idx) := NULL;
        END IF;

        IF g_line_id.EXISTS(g_line_id_seq_ctr)
        THEN
            g_line_rec.line_id(p_line_idx) := g_line_id(g_line_id_seq_ctr);

            SELECT    p_rec_type
                   || '-'
                   || xx_om_nonsku_line_s.NEXTVAL
            INTO   g_line_rec.orig_sys_line_ref(p_line_idx)
            FROM   DUAL;

            g_line_id_seq_ctr :=   g_line_id_seq_ctr
                                 + 1;
        ELSE
            SELECT oe_order_lines_s.NEXTVAL,
                      p_rec_type
                   || '-'
                   || xx_om_nonsku_line_s.NEXTVAL
            INTO   g_line_rec.line_id(p_line_idx),
                   g_line_rec.orig_sys_line_ref(p_line_idx)
            FROM   DUAL;
        END IF;

        -- For first line of an order
        IF g_line_nbr_counter = 1
        THEN
            g_header_rec.start_line_index(p_hdr_idx) := p_line_idx;
        END IF;

        -- Set Tax value on first return line of order if tax value < 0
        -- Set Tax value on first outbound line of order is tax value >= 0
         /* passing tax code as 'Location' for lines which has a value. modified by NB */
        IF g_order_line_tax_ctr = 1 AND g_header_rec.tax_value(p_hdr_idx) >= 0
        THEN
            g_line_rec.tax_value(p_line_idx) := g_header_rec.tax_value(p_hdr_idx);
            g_line_rec.canada_pst(p_line_idx) := g_header_rec.pst_tax_value(p_hdr_idx);
            g_line_rec.tax_code(p_line_idx) := 'Location';
            -- Increment the counter so that it does not assign it again
            g_order_line_tax_ctr :=   g_order_line_tax_ctr
                                    + 1;
        ELSIF g_rma_line_tax_ctr = 1 AND g_header_rec.tax_value(p_hdr_idx) < 0
        THEN
            g_line_rec.tax_value(p_line_idx) :=   -1
                                                * g_header_rec.tax_value(p_hdr_idx);
            g_line_rec.canada_pst(p_line_idx) :=   -1
                                                 * g_header_rec.pst_tax_value(p_hdr_idx);
            g_line_rec.tax_code(p_line_idx) := 'Location';
            -- Increment the counter so that it does not assign it again
            g_rma_line_tax_ctr :=   g_rma_line_tax_ctr
                                  + 1;
        ELSE
            g_line_rec.tax_value(p_line_idx) := 0;
            g_line_rec.canada_pst(p_line_idx) := 0;
            g_line_rec.tax_code(p_line_idx) := NULL;
        END IF;


        g_line_rec.upc_code(p_line_idx) := NULL ; 
        g_line_rec.price_type(p_line_idx) := NULL;
        g_line_rec.external_sku(p_line_idx) := NULL ;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Start Line Index is :'
                             || g_header_rec.start_line_index(p_hdr_idx));
        END IF;

        -- Get and Validate Item and Warehouse/Store
        validate_item_warehouse(p_hdr_idx          => p_hdr_idx,
                                p_line_idx         => p_line_idx,
                                p_nonsku_flag      => 'Y',
                                p_item             => p_rec_type);
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed in Init line record for '
                              || g_line_rec.orig_sys_line_ref(p_line_idx)
                              || ' for order '
                              || g_header_rec.orig_sys_document_ref(p_hdr_idx));
            fnd_file.put_line(fnd_file.LOG,
                                 'The error is '
                              || SQLERRM);
            RAISE fnd_api.g_exc_unexpected_error;
    END init_line_record;

    PROCEDURE create_tax_refund_line(
        p_hdr_idx    IN  BINARY_INTEGER,
        p_order_rec  IN  order_rec_type)
    IS
        lb_line_idx              BINARY_INTEGER;
        ln_debug_level  CONSTANT NUMBER         := oe_debug_pub.g_debug_level;
        lc_order_source          VARCHAR2(80);
    BEGIN
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Entering Create_Tax_Refund_Line'
                             || p_hdr_idx,
                             1);
        END IF;

        -- Line number counter per order
        g_line_nbr_counter :=   g_line_nbr_counter
                              + 1;
        -- Get the next Line Index
        lb_line_idx :=   g_line_rec.orig_sys_document_ref.COUNT
                       + 1;
        -- Replacing 'ST' with 'TRF' for tax refund item has ST is been used for wholesaler discount NB
        init_line_record(p_line_idx           => lb_line_idx,
                         p_hdr_idx            => p_hdr_idx,
                         p_rec_type           => 'TRF',
                         p_line_category      => 'RETURN');
        --MODIFIED BY NB fOR R11.2
        g_line_rec.order_source_id(lb_line_idx) := g_header_rec.order_source_id(p_hdr_idx);
        lc_order_source := get_ord_source_name(p_order_source_id      => g_line_rec.order_source_id(lb_line_idx));

        IF lc_order_source = 'POE'
        THEN
            g_line_rec.line_type_id(lb_line_idx) := oe_sys_parameters.VALUE('D-PRL',
                                                                            g_org_id);
        ELSE
          IF g_header_rec.rcc_transaction(p_hdr_idx) = 'Y' -- changes made per 36081
          THEN
            g_line_rec.line_type_id(lb_line_idx) := oe_sys_parameters.VALUE('D-PRL-RCC',
                                                                  g_org_id);
          ELSE
		    g_line_rec.line_type_id(lb_line_idx) := oe_sys_parameters.VALUE('D-RL',
                                                                            g_org_id);
			END IF;
        END IF;

        g_line_rec.return_reason_code(lb_line_idx) := g_header_rec.return_reason(p_hdr_idx);
        g_line_rec.line_category_code(lb_line_idx) := 'RETURN';
        g_line_rec.return_act_cat_code(lb_line_idx) := g_header_rec.return_act_cat_code(p_hdr_idx);
        g_line_rec.org_order_creation_date(lb_line_idx) := g_header_rec.org_order_creation_date(p_hdr_idx);
        g_line_rec.return_reference_no(lb_line_idx) := g_header_rec.return_orig_sys_doc_ref(p_hdr_idx);
        g_line_rec.schedule_status_code(lb_line_idx) := NULL;
        -- Need to set the price to zero. The tax value will be populated with the correct value.

        -- Need to set the price to zero. The tax value will be populated with the correct value.
        g_line_rec.unit_list_price(lb_line_idx) := 0;                           -- substr(p_order_rec.file_line,269,10);
        g_line_rec.unit_selling_price(lb_line_idx) := 0;                     -- G_Line_Rec.unit_list_price(lb_line_idx);
        -- Populate the reference info on the line.
        get_return_header(p_ref_order_number      => g_header_rec.return_orig_sys_doc_ref(p_hdr_idx),
                          p_sold_to_org_id        => g_header_rec.sold_to_org_id(p_hdr_idx),
                          x_header_id             => g_line_rec.ret_ref_header_id(lb_line_idx));

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'After getting the header reference :'
                             || g_line_rec.ret_ref_header_id(lb_line_idx),
                             1);
        END IF;

        -- Increment the global Line counter used in determining batch size
        g_line_counter :=   g_line_counter
                          + 1;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Exiting Create_Tax_Refund_Line'
                             || p_hdr_idx,
                             1);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed to process Tax Refund Line record for order '
                              || g_header_rec.orig_sys_document_ref(p_hdr_idx));
            fnd_file.put_line(fnd_file.LOG,
                                 'The error is '
                              || SQLERRM);
            RAISE fnd_api.g_exc_unexpected_error;
    END create_tax_refund_line;

-- +===================================================================+
-- | Name  : Create_kit_Line                                           |
-- | Description      : This Procedure will create kit line  line      |
-- |                                                                   |
-- | Parameters:        p_Hdr_Idx IN Header Index                      |
-- |                    p_amount  IN Line Amount                       |
-- +===================================================================+
    PROCEDURE create_kit_line
    IS

    lc_order_source          VARCHAR2(80);
    ln_kit_item_id           mtl_system_items_b.inventory_item_id%TYPE := NULL;
    ln_max_line_number       oe_order_lines_all.line_number%TYPE       := NULL;
    ln_debug_level           CONSTANT NUMBER      := oe_debug_pub.g_debug_level;
    lb_order_idx             BINARY_INTEGER;

    CURSOR cur_kit_header
    IS
    SELECT 
      xohi.order_source_id order_source_id,
      xohi.orig_sys_document_ref orig_sys_document_ref,
      ohi.org_id org_id,
      ohi.sold_to_org_id  sold_to_org_id,
      ohi.ship_from_org_id ship_from_org_id,
      ohi.ship_to_org_id ship_to_org_id,
      ohi.invoice_to_org_id invoice_to_org_id,
      ohi.drop_ship_flag drop_ship_flag,
      ohi.price_list_id price_list_id,
      ohi.ordered_Date ordered_date, 
      ohi.payment_term_id payment_term_id,
      ohi.shipping_method_code shipping_method_code,
      ohi.salesrep_id salesrep_id,
      ohi.customer_po_number customer_po_number,
      ohi.created_by created_by,
      ohi.creation_date creation_date,
      ohi.last_updated_by last_updated_by,
      ohi.last_update_date last_update_date,
      ohi.tax_exempt_reason_code tax_exempt_reason,
      ohi.tax_exempt_number,
      ohi.tax_exempt_flag,
      ohi.return_reason_code,
      xohi.release_no release_number,
      xohi.desk_top_no desk_top_no,
      ohi.shipping_instructions,
      ohi.ordered_date request_date
    FROM xx_om_headers_attr_iface_all xohi,
         oe_headers_iface_all ohi
    WHERE xohi.bill_level = 'K'
    AND xohi.orig_sys_document_ref = ohi.orig_sys_document_ref
    --and order_category  ='ORDER'  
    AND xohi.imp_file_name =  g_file_name 
    --AND ohi.error_flag IS NULL
    AND NOT EXISTS (SELECT 1 
                    FROM xx_om_lines_attr_iface_all b
                    WHERE xohi.orig_sys_document_ref = b.orig_sys_document_ref
                    AND kit_parent = 'Y');

    CURSOR cur_kit_line(p_orig_sys_document_ref IN xx_om_lines_attr_iface_all.orig_sys_document_ref%TYPE)
    IS 
    SELECT DISTINCT a.kit_sku, a.kit_qty,a.kit_seqnum, a.kit_sku_dept, a.kit_vend_product_code,b.line_type_id , b.line_category_code,
         a.aops_ship_date,a.sas_sale_date, a.calc_arrival_date
    FROM xx_om_lines_attr_iface_all a,
         oe_lines_iface_all b
    WHERE a.orig_sys_document_ref = p_orig_sys_document_ref
    AND a.orig_sys_document_ref = b.orig_sys_document_ref
    AND a.orig_sys_line_ref     = b.orig_sys_line_ref
    AND KIT_SKU is NOT NULL ;

    lc_line_rec            xx_om_sacct_conc_pkg.line_rec_type;
    ln_master_organization_id  NUMBER;

    BEGIN
      IF ln_debug_level > 0
      THEN
        oe_debug_pub.ADD(   'Before creating the kit line ..');
      END IF;

      ln_master_organization_id := oe_sys_parameters.VALUE('MASTER_ORGANIZATION_ID',
                                                             g_org_id);

      -- Update the BILL Level to 'D' if its a return order .. 

      Update xx_om_headers_attr_iface_all a
      SET Bill_level = 'D'
      WHERE bill_level ='K'
      AND imp_file_name =  g_file_name  
      AND exists ( SELECT 1 
                   FROM oe_lines_iface_all b
                   WHERE a.orig_sys_document_ref = b.orig_sys_document_ref
                   AND line_category_code = 'RETURN');

      IF ln_debug_level > 0
      THEN
        oe_debug_pub.ADD( SQL%ROWCOUNT ||' return orders updated from bill level K to D ');
      END IF;

      FOR cur_kit_header_rec IN cur_kit_header
      LOOP 
        BEGIN 
          lc_line_rec        := NULL;
          ln_max_line_number := NULL;
          ln_kit_item_id     := NULL;
          lb_order_idx       := NULL;
          -- get the max_line_number for given order .
          SELECT MAX(line_number)
          INTO ln_max_line_number
          FROM OE_LINES_IFACE_ALL
          WHERE orig_sys_document_ref = cur_kit_header_rec.orig_sys_document_ref;

          IF ln_debug_level > 0
          THEN
            oe_debug_pub.ADD(   'Max Line Number for kit line :'||ln_max_line_number);
          END IF;

          FOR cur_kit_line_rec IN cur_kit_line(p_orig_sys_document_ref => cur_kit_header_rec.orig_sys_document_ref)
          LOOP
            ln_max_line_number := ln_max_line_number + 1;
			ln_kit_item_id := NULL; 
            -- get KIT Item id
            fnd_file.put_line(fnd_file.log, 'KIT SKU:'||TRIM(cur_kit_line_rec.kit_sku) ||' org id :'||ln_master_organization_id);
           BEGIN
    		 SELECT inventory_item_id
             INTO  ln_kit_item_id
             FROM mtl_system_items_b
             WHERE segment1 = TRIM(cur_kit_line_rec.kit_sku)
             AND organization_id = ln_master_organization_id;
	   EXCEPTION
               WHEN NO_DATA_FOUND
	       THEN
                    ln_kit_item_id := NULL;
           END; 				   

            -- check PO line number is same for all the lines for given KIT
            BEGIN           
              SELECT b.customer_line_number
              INTO lc_line_rec.customer_line_number(1)
              FROM xx_om_lines_attr_iface_all a,
                   oe_lines_iface_all b
              WHERE b.orig_sys_document_ref = cur_kit_header_rec.orig_sys_document_ref
              AND a.orig_sys_document_ref = b.orig_sys_document_ref
              AND kit_sku = cur_kit_line_rec.kit_sku
              AND kit_seqnum = cur_kit_line_rec.kit_seqnum
              GROUP by customer_line_number;
            EXCEPTION
              WHEN OTHERS
              THEN 
                lc_line_rec.customer_line_number(1) := NULL;
            END;
            -- set values
            lc_line_rec.order_source_id(1)         := cur_kit_header_rec.order_source_id;
            lc_line_rec.orig_sys_document_Ref(1)   := cur_kit_header_rec.orig_sys_document_ref;
            lc_line_rec.org_id(1)                  := cur_kit_header_rec.org_id;
            lc_line_rec.sold_to_org_id(1)          := cur_kit_header_rec.sold_to_org_id;
            lc_line_rec.ship_from_org_id(1)        := cur_kit_header_rec.ship_from_org_id;
            lc_line_rec.ship_to_org_id(1)          := cur_kit_header_rec.ship_to_org_id;
            lc_line_rec.invoice_to_org_id(1)       := cur_kit_header_rec.invoice_to_org_id;
            lc_line_rec.drop_ship_flag(1)          := cur_kit_header_rec.drop_ship_flag;
            lc_line_rec.price_list_id(1)           := cur_kit_header_rec.price_list_id;
            lc_line_rec.tax_date(1)                := cur_kit_header_rec.ordered_Date;
            lc_line_rec.payment_Term_id(1)         := cur_kit_header_rec.payment_term_id;
            lc_line_rec.shipping_method_code(1)    := cur_kit_header_rec.shipping_method_code;
            lc_line_rec.salesrep_id(1)             := cur_kit_header_rec.salesrep_id;
            lc_line_rec.customer_po_number(1)      := cur_kit_header_rec.customer_po_number;
            lc_line_rec.created_by(1)              := cur_kit_header_rec.created_by;
            lc_line_rec.creation_date(1)           := cur_kit_header_rec.creation_date;
            lc_line_rec.last_updated_by(1)         := cur_kit_header_rec.last_updated_by;
            lc_line_rec.last_update_date(1)        := cur_kit_header_rec.last_update_date;
            lc_line_rec.tax_exempt_flag(1)         := cur_kit_header_rec.tax_exempt_flag;
            lc_line_rec.tax_exempt_number(1)       := cur_kit_header_rec.tax_exempt_number;
          --lc_line_rec.tax_exempt_reason(1)       := cur_kit_header_rec.tax_exempt_reason;
          --lc_line_rec.return_reason_code(1)      := cur_kit_header_rec.return_reason;
            lc_line_rec.shipping_instructions(1)   := cur_kit_header_rec.shipping_instructions;
            lc_line_rec.orig_sys_line_ref(1)       := 'KT-'||RPAD(ln_max_line_number,5,0);
            lc_line_rec.line_number(1)             := ln_max_line_number;
          --lc_line_rec.line_id(1)                 := NULL;
            lc_line_rec.line_type_id(1)            := cur_kit_line_rec.line_type_id;
            lc_line_rec.inventory_item_id(1)       := ln_kit_item_id;
            lc_line_rec.ordered_quantity(1)        := cur_kit_line_rec.kit_qty;
            lc_line_rec.order_quantity_uom(1)      := 'EA';
            lc_line_rec.shipped_quantity(1)        := cur_kit_line_rec.kit_qty;
            lc_line_rec.unit_list_price(1)         := 0;
            lc_line_rec.unit_Selling_price(1)      := 0;
            lc_line_rec.tax_code(1)                := null;
            lc_line_rec.tax_value(1)               := 0;
            lc_line_rec.operation_code(1)          := 'INSERT';
            lc_line_rec.line_category_code(1)      := cur_kit_line_rec.line_category_code; --'ORDER';
            lc_line_rec.calculate_price_flag(1)    := 'N';
            lc_line_rec.kit_seqnum(1)              := cur_kit_line_rec.kit_seqnum;
            lc_line_rec.kit_parent(1)              := 'Y';
            lc_line_rec.sku_dept(1)                := cur_kit_line_rec.kit_sku_dept;
            lc_line_rec.vendor_product_code(1)     := cur_kit_line_rec.kit_vend_product_code;          
            lc_line_rec.item_source(1)             := 'OD';
            lc_line_rec.aops_ship_date(1)          := cur_kit_line_rec.aops_ship_date;          
            lc_line_rec.sas_sale_date(1)           := cur_kit_line_rec.sas_sale_date;
            lc_line_rec.calc_arrival_date(1)       := cur_kit_line_rec.calc_arrival_date;

            SELECT oe_order_lines_s.NEXTVAL
            INTO   lc_line_rec.line_id(1)
            FROM DUAL;

            -- Insert record into oe_lines_iface_all
           INSERT INTO oe_lines_iface_all
             (orig_sys_document_ref,
              order_source_id,
              org_id,
              orig_sys_line_ref,
              line_number,
              line_type_id,
              inventory_item_id,
--              inventory_item,
--            schedule_ship_date,
--            actual_shipment_date,
              salesrep_id,
              ordered_quantity,
              order_quantity_uom,
              shipped_quantity,
              sold_to_org_id,
              ship_from_org_id,
              ship_to_org_id,
              invoice_to_org_id,
              drop_ship_flag,
              price_list_id,
              unit_list_price,
              unit_selling_price,
              calculate_price_flag,
              tax_code,
              tax_value,
              tax_date,
              shipping_method_code,
              return_reason_code,
              customer_po_number,
              operation_code,
              error_flag,
              shipping_instructions,
              line_category_code,
              request_id,
              line_id,
              payment_term_id,
              request_date,
--              schedule_status_code,
              tax_exempt_flag,
              tax_exempt_number,
              tax_exempt_reason_code,
              customer_line_number,
              creation_date,
              created_by,
              last_update_date,
              last_updated_by 
                )
           VALUES(
             lc_line_rec.orig_sys_document_ref(1),
             lc_line_rec.order_source_id(1),
             lc_line_rec.org_id(1),
             lc_line_rec.orig_sys_line_ref(1),
             lc_line_rec.line_number(1),
             lc_line_rec.line_type_id(1),
             lc_line_rec.inventory_item_id(1),
--             lc_line_rec.inventory_item(1),
--             lc_line_rec.schedule_ship_date(1),
--             lc_line_rec.actual_ship_date(1),
             lc_line_rec.salesrep_id(1),
             lc_line_rec.ordered_quantity(1),
             lc_line_rec.order_quantity_uom(1),
             lc_line_rec.shipped_quantity(1),
             lc_line_rec.sold_to_org_id(1),
             lc_line_rec.ship_from_org_id(1),
             lc_line_rec.ship_to_org_id(1),
             lc_line_rec.invoice_to_org_id(1),
             lc_line_rec.drop_ship_flag(1),
             lc_line_rec.price_list_id(1),
             lc_line_rec.unit_list_price(1),
             lc_line_rec.unit_selling_price(1),
             lc_line_rec.calculate_price_flag(1) ,
             lc_line_rec.tax_code(1),
             lc_line_rec.tax_value(1),
             lc_line_rec.tax_date(1),
             lc_line_rec.shipping_method_code(1),
             cur_kit_header_rec.return_reason_code,
             lc_line_rec.customer_po_number(1),
             lc_line_rec.operation_code(1),
             'N',
             lc_line_rec.shipping_instructions(1),
             lc_line_rec.line_category_code(1),
             g_request_id,
             lc_line_rec.line_id(1),
             lc_line_rec.payment_term_id(1),
             cur_kit_header_rec.request_date,
--             lc_line_rec.schedule_status_code(1),
             lc_line_rec.tax_exempt_flag(1),
             lc_line_rec.tax_exempt_number(1),
             cur_kit_header_rec.tax_exempt_reason,
             lc_line_rec.customer_line_number(1),
             lc_line_rec.creation_date(1),
             lc_line_rec.created_by(1),
             lc_line_rec.last_update_date(1),
             lc_line_rec.last_updated_by(1)
                );

          -- check cost_center_dept is same for all the lines for given KIT
          BEGIN           
            SELECT cost_center_dept 
            INTO lc_line_rec.cust_dept_no(1)
            FROM xx_om_lines_attr_iface_all
            WHERE orig_sys_document_ref = cur_kit_header_rec.orig_sys_document_ref
            AND kit_sku = cur_kit_line_rec.kit_sku
            AND kit_seqnum = cur_kit_line_rec.kit_seqnum
            GROUP by cost_center_dept;
          EXCEPTION
            WHEN OTHERS
            THEN 
              lc_line_rec.cust_dept_no(1) := NULL;
          END;

          -- check cust_COMMENTS is same for all the lines for given KIT
          /*  BEGIN           
              SELECT cust_comments
              INTO lc_line_rec.cust_comments(1)
              FROM xx_om_lines_attr_iface_all
              WHERE orig_sys_document_ref = cur_kit_header_rec.orig_sys_document_ref
              AND kit_sku = cur_kit_line_rec.kit_sku
              AND kit_seqnum = cur_kit_line_rec.kit_seqnum
              GROUP by cust_comments;
            EXCEPTION
              WHEN OTHERS
              THEN 
                lc_line_rec.cust_comments(1) := NULL;
            END;
              */
           /* -- check item_note is same for all the lines for given KIT
            BEGIN           
              SELECT item_note
              INTO lc_line_rec.item_note(1)
              FROM xx_om_lines_attr_iface_all
              WHERE orig_sys_document_ref = cur_kit_header_rec.orig_sys_document_ref
              AND kit_sku = cur_kit_line_rec.kit_sku
              AND kit_seqnum = cur_kit_line_rec.kit_seqnum
              GROUP by item_note;
            EXCEPTION
              WHEN OTHERS
              THEN 
                lc_line_rec.item_note(1) := NULL;
            END; */

            -- check contract_details is same for all the lines for given KIT
            BEGIN           
              SELECT contract_details
              INTO lc_line_rec.contract_details(1)
              FROM xx_om_lines_attr_iface_all
              WHERE orig_sys_document_ref = cur_kit_header_rec.orig_sys_document_ref
              AND kit_sku = cur_kit_line_rec.kit_sku
              AND kit_seqnum = cur_kit_line_rec.kit_seqnum
              GROUP by contract_details;
            EXCEPTION
              WHEN OTHERS
              THEN 
                lc_line_rec.contract_details(1) := NULL;
            END;

            -- check contract_details is same for all the lines for given KIT
            BEGIN           
              SELECT line_comments
              INTO lc_line_rec.line_comments(1)
              FROM xx_om_lines_attr_iface_all
              WHERE orig_sys_document_ref = cur_kit_header_rec.orig_sys_document_ref
              AND kit_sku = cur_kit_line_rec.kit_sku
              AND kit_seqnum = cur_kit_line_rec.kit_seqnum
              GROUP by line_comments;
            EXCEPTION
              WHEN OTHERS
              THEN 
                lc_line_rec.line_comments(1) := NULL;
            END;

            -- check taxable_flag is same for all the lines for given KIT
            BEGIN           
              SELECT taxable_flag
              INTO lc_line_rec.taxable_flag(1)
              FROM xx_om_lines_attr_iface_all
              WHERE orig_sys_document_ref = cur_kit_header_rec.orig_sys_document_ref
              AND kit_sku = cur_kit_line_rec.kit_sku
              AND kit_seqnum = cur_kit_line_rec.kit_seqnum
              GROUP by taxable_flag;
            EXCEPTION
              WHEN OTHERS
              THEN 
                lc_line_rec.taxable_flag(1) := NULL;
            END;

            -- check gsa_flag is same for all the lines for given KIT
            BEGIN           
              SELECT gsa_flag
              INTO lc_line_rec.gsa_flag(1)
              FROM xx_om_lines_attr_iface_all
              WHERE orig_sys_document_ref = cur_kit_header_rec.orig_sys_document_ref
              AND kit_sku = cur_kit_line_rec.kit_sku
              AND kit_seqnum = cur_kit_line_rec.kit_seqnum
              GROUP by gsa_flag;
            EXCEPTION
              WHEN OTHERS
              THEN 
                lc_line_rec.gsa_flag(1) := NULL;
            END;

            -- check cust_dept_description is same for all the lines for given KIT
            BEGIN           
              SELECT cust_dept_description
              INTO lc_line_rec.cust_dept_description(1)
              FROM xx_om_lines_attr_iface_all
              WHERE orig_sys_document_ref = cur_kit_header_rec.orig_sys_document_ref
              AND kit_sku = cur_kit_line_rec.kit_sku
              AND kit_seqnum = cur_kit_line_rec.kit_seqnum
              GROUP by cust_dept_description;
            EXCEPTION
              WHEN OTHERS
              THEN 
                lc_line_rec.cust_dept_description(1) := NULL;
            END;

            INSERT INTO xx_om_lines_attr_iface_all
               (orig_sys_document_ref,
                order_source_id,
                request_id,
                vendor_product_code,
                orig_sys_line_ref,
                org_id,
                contract_details,
               -- item_comments,
                line_comments,
                taxable_flag,
                creation_date,
                created_by,
                last_update_date,
                last_updated_by,
                cost_center_dept,
                desktop_del_addr,
                gsa_flag,
                cust_dept_description,
                --unit_orig_selling_price,
                --upc_code,
                --price_type,
                --external_sku,
                release_num,
                kit_parent,
                kit_seqnum,
                sku_dept,
                item_source,
                aops_ship_date,
                sas_sale_date,
                calc_arrival_date)
              VALUES(
                lc_line_rec.orig_sys_document_ref(1),
                lc_line_rec.order_source_id(1),
                g_request_id,
                lc_line_rec.vendor_product_code(1),
                lc_line_rec.orig_sys_line_ref(1),
                lc_line_rec.org_id(1),
                lc_line_rec.contract_details(1),
                --lc_line_rec.item_comments(1),
                lc_line_rec.line_comments(1),
                lc_line_rec.taxable_flag(1),
                lc_line_rec.creation_date(1),
                lc_line_rec.created_by(1),
                lc_line_rec.last_update_date(1),
                lc_line_rec.last_updated_by(1),
                lc_line_rec.cust_dept_no(1),
                cur_kit_header_rec.desk_top_no, --lc_line_rec.desktop_del_addr(1),
                lc_line_rec.gsa_flag(1),
                lc_line_rec.cust_dept_description(1),
                --lc_line_rec.unit_orig_selling_price(1),
                --lc_line_rec.upc_code(1),
                --lc_line_rec.price_type(1),
                --lc_line_rec.external_sku(1),
                cur_kit_header_rec.release_number,
                lc_line_rec.kit_parent(1),
                lc_line_rec.kit_seqnum(1),
                lc_line_rec.sku_dept(1),
                lc_line_rec.item_source(1),
                lc_line_rec.aops_ship_date(1),
                lc_line_rec.sas_sale_date(1),
                lc_line_rec.calc_arrival_date(1));

          END LOOP; -- line loop
       EXCEPTION
         WHEN OTHERS 
         THEN
           fnd_file.put_line(fnd_file.log, 'Failed to Create the KIT Line for Order :'|| cur_kit_header_rec.orig_sys_document_ref);
           fnd_file.put_line(fnd_file.log, ' the error is :'|| SQLERRM);

           -- Loop over header table to figure out which line this tax belongs to
		   FOR j IN 1..g_header_rec.orig_sys_document_ref.count
           LOOP
             IF cur_kit_header_rec.orig_sys_document_ref = g_header_rec.orig_sys_document_ref(j)
             THEN 
               IF ln_debug_level > 0
               THEN
                oe_debug_pub.ADD(   'Match Found for Order '|| g_header_rec.orig_sys_document_ref(j));
               END IF;
               lb_order_idx := j;
              EXIT;
             END IF;

          END LOOP;
          fnd_file.put_line(fnd_file.log, 'lb_order_idx :'||lb_order_idx);
          fnd_file.put_line(fnd_file.log, 'Cursor orig_sys_document_ref value :'||cur_kit_header_rec.orig_sys_document_ref);
          IF lb_order_idx IS NOT NULL
          THEN 
            clear_bad_orders('LINE',g_header_rec.orig_sys_document_ref(lb_order_idx));
          END IF;
           --   x_return_status := 'U';
       END; 
     END LOOP; -- header loop

     IF ln_debug_level > 0
     THEN
       oe_debug_pub.ADD('After creating the create kit line');
     END IF;
   EXCEPTION
     WHEN OTHERS
     THEN
       fnd_file.put_line(fnd_file.LOG,
                       'Failed to create the KIT Line record for order ');
       fnd_file.put_line(fnd_file.LOG,
                        'The error is '
                         || SQLERRM);
       RAISE fnd_api.g_exc_unexpected_error;
  END create_kit_line;

-- +===================================================================+
-- | Name  : Create_CashBack_Line                                      |
-- | Description      : This Procedure will create cash-back line      |
-- |                                                                   |
-- | Parameters:        p_Hdr_Idx IN Header Index                      |
-- |                    p_amount  IN Line Amount                       |
-- +===================================================================+
    PROCEDURE create_cashback_line(
        p_hdr_idx  IN  BINARY_INTEGER,
        p_amount   IN  NUMBER)
    IS
        lb_line_idx              BINARY_INTEGER;
        ln_debug_level  CONSTANT NUMBER         := oe_debug_pub.g_debug_level;
        lc_order_source          VARCHAR2(80);
    BEGIN
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Before processing CashBack Line'
                             || p_amount);
        END IF;

        g_line_nbr_counter :=   g_line_nbr_counter
                              + 1;
        -- Get the current Line Index
        lb_line_idx :=   g_line_rec.orig_sys_document_ref.COUNT
                       + 1;
        g_line_rec.line_category_code(lb_line_idx) := 'ORDER';
        -- Initialize and set the line record
        init_line_record(p_line_idx           => lb_line_idx,
                         p_hdr_idx            => p_hdr_idx,
                         p_rec_type           => 'CASHBK',
                         p_line_category      => 'ORDER');
        -- Need to charge customer for the fee/ del charge
        --MODIFIED BY NB fOR R11.2
        g_line_rec.order_source_id(lb_line_idx) := g_header_rec.order_source_id(p_hdr_idx);
        lc_order_source := get_ord_source_name(p_order_source_id      => g_line_rec.order_source_id(lb_line_idx));

        IF lc_order_source = 'POE'
        THEN
            g_line_rec.line_type_id(lb_line_idx) := oe_sys_parameters.VALUE('D-PSL',
                                                                            g_org_id);

            IF g_header_rec.deposit_amount(p_hdr_idx) > 0
            THEN
                g_line_rec.line_type_id(lb_line_idx) := oe_sys_parameters.VALUE('D-SL',
                                                                                g_org_id);
            END IF;
        ELSE
          IF g_header_rec.rcc_transaction(p_hdr_idx) = 'Y'  -- Added per 36081
          THEN
            g_line_rec.line_type_id(lb_line_idx) := oe_sys_parameters.VALUE('D-PSL-RCC',
                                                                  g_org_id);
          ELSE
		    g_line_rec.line_type_id(lb_line_idx) := oe_sys_parameters.VALUE('D-SL',
                                                                            g_org_id);
		  END IF;
        END IF;

        g_line_rec.line_category_code(lb_line_idx) := 'ORDER';
        g_line_rec.return_reason_code(lb_line_idx) := NULL;
        g_line_rec.org_order_creation_date(lb_line_idx) := NULL;
        g_line_rec.schedule_status_code(lb_line_idx) := NULL;
        g_line_rec.unit_list_price(lb_line_idx) := p_amount;
        g_line_rec.unit_selling_price(lb_line_idx) := p_amount;
        g_line_rec.taxable_flag(lb_line_idx) := 'N';
        -- Add the cash back amount to Order Total
        g_header_rec.order_total(p_hdr_idx) :=   g_header_rec.order_total(p_hdr_idx)
                                               + p_amount;
        g_cashback_total :=   g_cashback_total
                            + p_amount;
        -- Increment the global Line counter used in determining batch size
        g_line_counter :=   g_line_counter
                          + 1;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('After processing CashBack Line');
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed to process Cash Back line '
                              || g_line_rec.orig_sys_line_ref(lb_line_idx)
                              || ' for order '
                              || g_header_rec.orig_sys_document_ref(p_hdr_idx));
            fnd_file.put_line(fnd_file.LOG,
                                 'The error is '
                              || SUBSTR(SQLERRM,
                                        1,
                                        200));
            RAISE fnd_api.g_exc_unexpected_error;
    END create_cashback_line;

-- Added procedure  process_line_tax as per defect 36885 ver 25.0   

-- +===================================================================+
-- | Name  : process_line_tax                                          |
-- | Description      : This Procedure will read the line  level tax   |
-- |                     from file validate , derive and insert into   |
-- |                    xx_om_lines_attr_iface_all tbl                 |
-- |                                                                   |
-- | Parameters:        p_order_rec IN order_rec_type                  |
-- |                    p_batch_id  IN batch_id                        |
-- +===================================================================+
PROCEDURE process_line_tax(
           p_order_rec      IN             order_rec_type,
           p_batch_id       IN             NUMBER,
           x_return_status  OUT NOCOPY     VARCHAR2)
IS   
 lc_line_nbr              VARCHAR2(5);
 lb_tax_idx               BINARY_INTEGER;
 lb_hdr_idx               BINARY_INTEGER;
 lb_line_idx              BINARY_INTEGER;
 lb_curr_line_idx         BINARY_INTEGER;
 ln_debug_level 	  CONSTANT NUMBER         := oe_debug_pub.g_debug_level;
 ln_kit_sku               NUMBER;
 lc_kit_sku               VARCHAR2(7);


 BEGIN
   x_return_status := 'S';

   IF ln_debug_level > 0
   THEN
     oe_debug_pub.ADD('Entering Process Line Tax');
   END IF;

   lc_line_nbr := SUBSTR(p_order_rec.file_line,
                         33,
                         5);
   lb_tax_idx :=   g_line_tax_rec.orig_sys_document_ref.COUNT
                       + 1;
   lb_hdr_idx := g_header_rec.orig_sys_document_ref.COUNT;
   lb_curr_line_idx := g_line_rec.orig_sys_document_ref.COUNT;

   IF ln_debug_level > 0
   THEN
     oe_debug_pub.ADD('lc_line_nbr value'||lc_line_nbr);
     oe_debug_pub.ADD('lb_curr_line_idx value'||lb_curr_line_idx);
     oe_debug_pub.ADD('lb_tax_idx value'||lb_tax_idx);
   END IF;

   -- Check if the discount applies to whole order

   IF lc_line_nbr = '00000'
   THEN

     fnd_file.put_line(fnd_file.LOG,'Found line tax record with missing line reference for order:'
                               || g_header_rec.orig_sys_document_ref(lb_hdr_idx));

     -- Need to put it on First Line of the order

     lb_line_idx := g_header_rec.start_line_index(lb_hdr_idx);
          -- We will need to mark the order for error
     set_header_error(lb_hdr_idx);
     set_msg_context(p_entity_code      => 'HEADER');
   END IF;

   -- Get the line tax rate and line tax amount 
---Below code added for reading Credit memo issue   
   g_line_tax_rec.line_tax_rate(lb_tax_idx) := SUBSTR(p_order_rec.file_line,
                                                                         38,
                                                                          7);
   g_line_tax_rec.line_tax_amount(lb_tax_idx) := ltrim(SUBSTR(p_order_rec.file_line,
                                                                           45,
																		   9),'+');

---Below lines are commented for reading Credit memo issue			
 /*
   g_line_tax_rec.line_tax_amount(lb_tax_idx) := SUBSTR(p_order_rec.file_line,
                                                                           46,
                                                                            9);	
******/																			

   ln_kit_sku := LTRIM(SUBSTR(p_order_rec.file_line,
                              54,
                              7)); 
   IF ln_kit_SKU <= 99999
   THEN
     lc_kit_sku := LPAD(ln_kit_sku,
                         6,
                         '0');
   ELSE
     lc_kit_sku := ln_kit_sku;
   END IF;

   g_line_tax_rec.kit_sku(lb_tax_idx) := lc_kit_sku;

   g_line_tax_rec.kit_qty(lb_tax_idx) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                                    61,
                                                                    6)); 

   g_line_tax_rec.kit_vpc(lb_tax_idx) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                                    67,
                                                                    20)); 

   g_line_tax_rec.kit_dept(lb_tax_idx) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                                    87,
                                                                    3)); 
   g_line_tax_rec.kit_seqnum(lb_tax_idx) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                                    90,
                                                                    5)); 

   IF ln_debug_level > 0
   THEN
     oe_debug_pub.ADD(   'Line Nbr is  :'|| lc_line_nbr);
     oe_debug_pub.ADD(   'Tax Rate Value  :' || g_line_tax_rec.line_tax_rate(lb_tax_idx));
     oe_debug_pub.ADD(   'Tax Amount Value :'|| g_line_tax_rec.line_tax_amount(lb_tax_idx));
     oe_debug_pub.ADD(   'Kit SKU :'|| g_line_tax_rec.kit_sku(lb_tax_idx));
     oe_debug_pub.ADD(   'kit qty :'|| g_line_tax_rec.kit_qty(lb_tax_idx));
     oe_debug_pub.ADD(   'kit vpc :'|| g_line_tax_rec.kit_vpc(lb_tax_idx));
     oe_debug_pub.ADD(   'kit Dept :'|| g_line_tax_rec.kit_dept(lb_tax_idx));
     oe_debug_pub.ADD(   'kit Seqnum :'|| g_line_tax_rec.kit_seqnum(lb_tax_idx));
   END IF;

   -- Find the line index for the tax records.
   IF lc_line_nbr <> '00000'
   THEN
     -- Loop over line table to figure out which line this tax belongs to
     FOR j IN g_header_rec.start_line_index(lb_hdr_idx) .. lb_curr_line_idx
     LOOP
       IF lc_line_nbr = g_line_rec.orig_sys_line_ref(j)
       THEN
         IF ln_debug_level > 0
         THEN
           oe_debug_pub.ADD(   'Match Found for tax line ref '|| lc_line_nbr);
         END IF;
         lb_line_idx := j;
         EXIT;
       END IF;
     END LOOP;

     IF lb_line_idx IS NULL
     THEN
       -- Give error that tax record doesn't point to correct line
       oe_debug_pub.ADD(   'Tax record does not point to correct line :'|| lc_line_nbr);
     END IF;
   END IF;

   IF ln_debug_level > 0
   THEN
     oe_debug_pub.ADD(   'Line index for Tax record is : '|| lb_line_idx);
   END IF;

   g_line_rec.line_tax_rate(lb_line_idx)   := NVL(g_line_rec.line_tax_rate(lb_line_idx),0)+g_line_tax_rec.line_tax_rate(lb_tax_idx);
   g_line_rec.line_tax_amount(lb_line_idx) := NVL(g_line_rec.line_tax_amount(lb_line_idx),0)+g_line_tax_rec.line_tax_amount(lb_tax_idx);    
   g_line_rec.kit_sku(lb_line_idx)         := g_line_tax_rec.kit_sku(lb_tax_idx);  --NVL(g_line_rec.kit_sku(lb_line_idx),0)+g_line_tax_rec.kit_sku(lb_tax_idx);  
   g_line_rec.kit_qty(lb_line_idx)         := g_line_tax_rec.kit_qty(lb_tax_idx);  --NVL(g_line_rec.kit_qty(lb_line_idx),0)+g_line_tax_rec.kit_qty(lb_tax_idx);  
   g_line_rec.kit_vpc(lb_line_idx)         := g_line_tax_rec.kit_vpc(lb_tax_idx);  --NVL(g_line_rec.kit_vpc(lb_line_idx),0)+g_line_tax_rec.kit_vpc(lb_tax_idx);  
   g_line_rec.kit_dept(lb_line_idx)        := g_line_tax_rec.kit_dept(lb_tax_idx);  --NVL(g_line_rec.kit_dept(lb_line_idx),0)+g_line_tax_rec.kit_dept(lb_tax_idx);  
   g_line_rec.kit_seqnum(lb_line_idx)      := g_line_tax_rec.kit_seqnum(lb_tax_idx);  --NVL(g_line_rec.kit_seqnum(lb_line_idx),0)+g_line_tax_rec.kit_seqnum(lb_tax_idx);  

   IF ln_debug_level > 0
   THEN
     oe_debug_pub.ADD(   'Line Level Tax Rate Value:'|| g_line_rec.line_tax_rate(lb_line_idx));
     oe_debug_pub.ADD(   'Line Level Tax Amount Value :'|| g_line_rec.line_tax_amount(lb_line_idx));
     oe_debug_pub.ADD(   'Line Level Kit SKU :'||g_line_rec.kit_sku(lb_line_idx));
     oe_debug_pub.ADD(   'Line Level Kit QTY :'||g_line_rec.kit_qty(lb_line_idx));
     oe_debug_pub.ADD(   'Line Level Kit VPC :'||g_line_rec.kit_vpc(lb_line_idx));
     oe_debug_pub.ADD(   'Line Level Kit DEPT :'||g_line_rec.kit_dept(lb_line_idx));
     oe_debug_pub.ADD(   'Line Level Kit SEQNUM :'||g_line_rec.kit_seqnum(lb_line_idx));
   END IF;

EXCEPTION
  WHEN OTHERS THEN
  IF ln_debug_level > 0
  THEN
  oe_debug_pub.ADD( 'Error in the Procedure : process_line_tax ' || SQLERRM);   
            -- Need to clear this BAD order
            clear_bad_orders('LINE',
                             g_header_rec.orig_sys_document_ref(lb_hdr_idx));
            x_return_status := 'U';
  END IF;
 END process_line_tax;

-- +===================================================================+
-- | Name  : process_Adjustments                                       |
-- | Description      : This Procedure will read the Adjustment line   |
-- |                     from file validate , derive and insert into   |
-- |                    oe_price_adjs_iface_all tbl                    |
-- |                                                                   |
-- | Parameters:        p_order_rec IN order_rec_type                  |
-- |                    p_batch_id  IN batch_id                        |
-- +===================================================================+
    PROCEDURE process_adjustments(
        p_order_rec      IN             order_rec_type,
        p_batch_id       IN             NUMBER,
        x_return_status  OUT NOCOPY     VARCHAR2)
    IS
        lc_rec_type              VARCHAR2(2);
        --lb_line_nbr         BINARY_INTEGER;
        lc_line_nbr              VARCHAR2(5);
        lb_adj_idx               BINARY_INTEGER;
        lb_hdr_idx               BINARY_INTEGER;
        lb_line_idx              BINARY_INTEGER;
        lb_curr_line_idx         BINARY_INTEGER;
        lc_list_name             VARCHAR2(100);
        lc_adj_sign              VARCHAR2(1);
        ln_debug_level  CONSTANT NUMBER         := oe_debug_pub.g_debug_level;
        ln_header_id             NUMBER;
        ln_line_id               NUMBER;
        ln_orig_ord_qty          NUMBER;
        ln_orig_sell_price       NUMBER;
        lc_order_source          VARCHAR2(80);
    BEGIN
        x_return_status := 'S';

        -- Check if it is a discount/coupon record
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('Entering Process Adjustments');
        END IF;

        lc_rec_type := SUBSTR(p_order_rec.file_line,
                              108,
                              2);
        lc_line_nbr := SUBSTR(p_order_rec.file_line,
                              33,
                              5);
        lb_adj_idx :=   g_line_adj_rec.orig_sys_document_ref.COUNT
                      + 1;
        lb_hdr_idx := g_header_rec.orig_sys_document_ref.COUNT;
        lb_curr_line_idx := g_line_rec.orig_sys_document_ref.COUNT;

        -- Check if the discount applies to whole order
        IF lc_line_nbr = '00000'
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Found discount record with missing line reference for order:'
                              || g_header_rec.orig_sys_document_ref(lb_hdr_idx));

            -- Check if the display distribution is NULL
            IF TO_NUMBER(SUBSTR(p_order_rec.file_line,
                                98,
                                10)) = 0
            THEN
                -- Ignore this discount record and proceed with order creation
                GOTO end_of_adj;
            END IF;

            -- Need to put it on First Line of the order
            lb_line_idx := g_header_rec.start_line_index(lb_hdr_idx);
            -- We will need to mark the order for error
            set_header_error(lb_hdr_idx);
            set_msg_context(p_entity_code      => 'HEADER');
            fnd_message.set_name('XXOM',
                                 'XX_OM_DIS_MISSING_LINE_REF');
            fnd_message.set_token('ATTRIBUTE1',
                                  g_line_adj_rec.orig_sys_discount_ref(lb_adj_idx));
            oe_bulk_msg_pub.ADD;
        END IF;

        -- Get the Adjustment reference number
        g_line_adj_rec.orig_sys_discount_ref(lb_adj_idx) := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,
                                                                               56,
                                                                               30)));

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Rec Type is :'
                             || lc_rec_type);
            oe_debug_pub.ADD(   'Line Nbr is  :'
                             || lc_line_nbr);
            oe_debug_pub.ADD(   'Adjustment Index is  :'
                             || lb_adj_idx);
            oe_debug_pub.ADD(   'Line Curr Line Index is :'
                             || lb_curr_line_idx);
        END IF;

        IF lc_rec_type IN('AD', 'TD', '00', '10', '20', '21', '22', '30', '50')
        THEN
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD('Processing Discount ');
            END IF;

            -- Get the List Header Id and List Line Id for discount/coupon records.
            IF g_list_header_id IS NULL
            THEN
                -- Get the list header id from system parameter
                g_list_header_id := oe_sys_parameters.VALUE('XX_OM_SAS_DISCOUNT_LIST',
                                                            g_org_id);

                -- This dummy discount list will only hold one record..
                SELECT list_line_id
                INTO   g_list_line_id
                FROM   qp_list_lines
                WHERE  list_header_id = g_list_header_id AND ROWNUM = 1;
            END IF;

            -- Find the line index for the adjustment record.
            IF lc_line_nbr <> '00000'
            THEN
                -- Loop over line table to figure out which line this discount belongs to
                FOR j IN g_header_rec.start_line_index(lb_hdr_idx) .. lb_curr_line_idx
                LOOP
                    IF lc_line_nbr = g_line_rec.orig_sys_line_ref(j)
                    THEN
                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD(   'Match Found for ADJ line ref '
                                             || lc_line_nbr);
                        END IF;

                        lb_line_idx := j;
                        EXIT;
                    END IF;
                END LOOP;

                IF lb_line_idx IS NULL
                THEN
                    -- Give error that adj record doesn't point to correct line
                    oe_debug_pub.ADD(   'ADJ record does not point to correct line :'
                                     || lc_line_nbr);
                END IF;
            END IF;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Line index for adj record is : '
                                 || lb_line_idx);
            END IF;

            g_line_adj_rec.orig_sys_document_ref(lb_adj_idx) := g_header_rec.orig_sys_document_ref(lb_hdr_idx);
            g_line_adj_rec.order_source_id(lb_adj_idx) := g_header_rec.order_source_id(lb_hdr_idx);
            g_line_adj_rec.orig_sys_line_ref(lb_adj_idx) := SUBSTR(p_order_rec.file_line,
                                                                   33,
                                                                   5);
            g_line_adj_rec.sold_to_org_id(lb_adj_idx) := g_header_rec.sold_to_org_id(lb_hdr_idx);
            g_line_adj_rec.list_header_id(lb_adj_idx) := g_list_header_id;
            g_line_adj_rec.list_line_id(lb_adj_idx) := g_list_line_id;
            g_line_adj_rec.list_line_type_code(lb_adj_idx) := 'DIS';
            g_line_adj_rec.operand(lb_adj_idx) := SUBSTR(p_order_rec.file_line,
                                                         98,
                                                         10);
            g_line_adj_rec.pricing_phase_id(lb_adj_idx) := 2;
            g_line_adj_rec.adjusted_amount(lb_adj_idx) :=
                  -1
                * g_line_adj_rec.operand(lb_adj_idx)
                / NVL(g_line_rec.shipped_quantity(lb_line_idx),
                      g_line_rec.ordered_quantity(lb_line_idx));
            g_line_adj_rec.operation_code(lb_adj_idx) := 'CREATE';
            g_line_adj_rec.CONTEXT(lb_adj_idx) := 'SALES_ACCT';
            g_line_adj_rec.attribute6(lb_adj_idx) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                                  38,
                                                                  9));
            g_line_adj_rec.attribute7(lb_adj_idx) := LTRIM(SUBSTR(p_order_rec.file_line,
                                                                  54,
                                                                  1));
            g_line_adj_rec.attribute8(lb_adj_idx) := lc_rec_type;    --G_Line_Adj_Rec.orig_sys_discount_ref(lb_adj_idx);

            -- For COUPON type discounts, populate the owner information .
            IF lc_rec_type = '10'
            THEN
                -- Changed to populate the text instead of the owner id as requested by AR
                IF LTRIM(SUBSTR(p_order_rec.file_line,
                                55,
                                1)) IN('1', '3', '4', '6')
                THEN
                    g_line_adj_rec.attribute9(lb_adj_idx) := 'ADVERTISING';
                ELSE
                    g_line_adj_rec.attribute9(lb_adj_idx) := 'MERCHANDISING';
                END IF;
            ELSE
                g_line_adj_rec.attribute9(lb_adj_idx) := NULL;
            END IF;

            g_line_adj_rec.attribute10(lb_adj_idx) := TO_NUMBER(SUBSTR(p_order_rec.file_line,
                                                                       87,
                                                                       10));
            g_line_adj_rec.change_sequence(lb_adj_idx) := g_header_rec.change_sequence(lb_hdr_idx);

            IF g_header_rec.order_category(lb_hdr_idx) = 'ORDER'
            THEN
                g_line_adj_rec.request_id(lb_adj_idx) := g_request_id;
            ELSE
                g_line_adj_rec.request_id(lb_adj_idx) := NULL;
            END IF;

            -- Set the Unit Selling Price on the Line Record
            g_line_rec.unit_selling_price(lb_line_idx) :=
                                    g_line_rec.unit_selling_price(lb_line_idx)
                                  + g_line_adj_rec.adjusted_amount(lb_adj_idx);

            -- Adjust the Order Total based on adjustment to unit selling price
            IF g_line_rec.line_category_code(lb_line_idx) = 'RETURN'
            THEN
                g_header_rec.order_total(lb_hdr_idx) :=
                      g_header_rec.order_total(lb_hdr_idx)
                    + (  g_line_adj_rec.adjusted_amount(lb_adj_idx)
                       * NVL(g_line_rec.shipped_quantity(lb_line_idx),
                             g_line_rec.ordered_quantity(lb_line_idx))
                       * -1);
            ELSE
                g_header_rec.order_total(lb_hdr_idx) :=
                      g_header_rec.order_total(lb_hdr_idx)
                    +   g_line_adj_rec.adjusted_amount(lb_adj_idx)
                      * NVL(g_line_rec.shipped_quantity(lb_line_idx),
                            g_line_rec.ordered_quantity(lb_line_idx));
            END IF;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'lc_rec_type = '
                                 || lc_rec_type);
                oe_debug_pub.ADD(   'lc_line_nbr = '
                                 || lc_line_nbr);
                oe_debug_pub.ADD(   'orig_sys_document_ref = '
                                 || g_line_adj_rec.orig_sys_document_ref(lb_adj_idx));
                oe_debug_pub.ADD(   'order_source_id = '
                                 || g_line_adj_rec.order_source_id(lb_adj_idx));
                oe_debug_pub.ADD(   'orig_sys_line_ref = '
                                 || g_line_adj_rec.orig_sys_line_ref(lb_adj_idx));
                oe_debug_pub.ADD(   'orig_sys_discount_ref = '
                                 || g_line_adj_rec.orig_sys_discount_ref(lb_adj_idx));
                oe_debug_pub.ADD(   'sold_to_org_id = '
                                 || g_line_adj_rec.sold_to_org_id(lb_adj_idx));
                oe_debug_pub.ADD(   'list_header_id = '
                                 || g_line_adj_rec.list_header_id(lb_adj_idx));
                oe_debug_pub.ADD(   'list_line_id = '
                                 || g_line_adj_rec.list_line_id(lb_adj_idx));
                oe_debug_pub.ADD(   'list_line_type_code = '
                                 || g_line_adj_rec.list_line_type_code(lb_adj_idx));
                oe_debug_pub.ADD(   'operand = '
                                 || g_line_adj_rec.operand(lb_adj_idx));
                oe_debug_pub.ADD(   'pricing_phase_id = '
                                 || g_line_adj_rec.pricing_phase_id(lb_adj_idx));
                oe_debug_pub.ADD(   'adjusted_amount = '
                                 || g_line_adj_rec.adjusted_amount(lb_adj_idx));
                oe_debug_pub.ADD(   'operation_code = '
                                 || g_line_adj_rec.operation_code(lb_adj_idx));
                oe_debug_pub.ADD(   'context = '
                                 || g_line_adj_rec.CONTEXT(lb_adj_idx));
                oe_debug_pub.ADD(   'attribute6 = '
                                 || g_line_adj_rec.attribute6(lb_adj_idx));
                oe_debug_pub.ADD(   'attribute7 = '
                                 || g_line_adj_rec.attribute7(lb_adj_idx));
                oe_debug_pub.ADD(   'attribute8 = '
                                 || g_line_adj_rec.attribute8(lb_adj_idx));
                oe_debug_pub.ADD(   'attribute9 = '
                                 || g_line_adj_rec.attribute9(lb_adj_idx));
                oe_debug_pub.ADD(   'attribute10 = '
                                 || g_line_adj_rec.attribute10(lb_adj_idx));
                oe_debug_pub.ADD(   'Error Flag is '
                                 || g_header_rec.error_flag(lb_hdr_idx));
                oe_debug_pub.ADD(   ' ADJ The order total is '
                                 || g_header_rec.order_total(lb_hdr_idx));
                oe_debug_pub.ADD(   ' Line Ship Qty is '
                                 || g_line_rec.shipped_quantity(lb_line_idx));
                oe_debug_pub.ADD(   ' adjusted amount is '
                                 || g_line_adj_rec.adjusted_amount(lb_adj_idx));
                oe_debug_pub.ADD(   ' operand amount is '
                                 || g_line_adj_rec.operand(lb_adj_idx));
            END IF;
        ELSE
            g_line_nbr_counter :=   g_line_nbr_counter
                                  + 1;
            -- Get the current Line Index
            lb_line_idx :=   g_line_rec.orig_sys_document_ref.COUNT
                           + 1;
            -- For Delivery Charges, Fees etc we will need to create line record.
            lc_adj_sign := SUBSTR(p_order_rec.file_line,
                                  97,
                                  1);

            IF lc_adj_sign = '-'
            THEN
                g_line_rec.line_category_code(lb_line_idx) := 'RETURN';
            ELSE
                g_line_rec.line_category_code(lb_line_idx) := 'ORDER';
            END IF;

            -- Initialize and set the line record
            init_line_record(p_line_idx           => lb_line_idx,
                             p_hdr_idx            => lb_hdr_idx,
                             p_rec_type           => lc_rec_type,
                             p_line_category      => g_line_rec.line_category_code(lb_line_idx));
            g_line_rec.return_act_cat_code(lb_line_idx) := g_header_rec.return_act_cat_code(lb_hdr_idx);
            g_line_rec.unit_list_price(lb_line_idx) := SUBSTR(p_order_rec.file_line,
                                                              98,
                                                              10);
            g_line_rec.unit_selling_price(lb_line_idx) := g_line_rec.unit_list_price(lb_line_idx);
            -- If the non-sku is 'SP or 'UN' Then put the correct orig_sys_line_ref on the line record

            --IF lc_rec_type IN ('SP','UN','SD') THEN
            --G_Line_Rec.orig_sys_line_ref(lb_line_idx) := substr(p_order_rec.file_line,33,5);
            g_line_rec.sas_sale_date(lb_line_idx) := g_header_rec.sas_sale_date(lb_hdr_idx);
            g_line_rec.aops_ship_date(lb_line_idx) := g_header_rec.ship_date(lb_hdr_idx);
            g_line_rec.calc_arrival_date(lb_line_idx) := g_header_rec.ship_date(lb_hdr_idx);
            --END IF;

            -- Read the COST amounts from file for NON-SKU items
            g_line_rec.average_cost(lb_line_idx) := NVL(TRIM(SUBSTR(p_order_rec.file_line,
                                                                    111,
                                                                    11)),
                                                        0);
            g_line_rec.po_cost(lb_line_idx) := g_line_rec.average_cost(lb_line_idx);
            -- MFC 11-mar-2009 QC13608 use the passed taxable ind for the adjustment
            g_line_rec.taxable_flag(lb_line_idx) := NVL(SUBSTR(p_order_rec.file_line,
                                                               110,
                                                               1),
                                                        'Y');
            --MODIFIED BY NB fOR R11.2
            g_line_rec.order_source_id(lb_line_idx) := g_header_rec.order_source_id(lb_hdr_idx);
            lc_order_source := get_ord_source_name(p_order_source_id      => g_line_rec.order_source_id(lb_line_idx));

            IF lc_adj_sign = '-'
            THEN
                IF lc_order_source = 'POE'
                THEN
                    g_line_rec.line_type_id(lb_line_idx) := oe_sys_parameters.VALUE('D-PRL',
                                                                                    g_org_id);
                ELSE          
                  -- For AOPS and AOPS RCC orders 
                  IF g_header_rec.rcc_transaction(lb_hdr_idx) = 'Y'
                  THEN 
                   g_line_rec.line_type_id(lb_line_idx) := oe_sys_parameters.VALUE('D-PRL-RCC',
                                                                                    g_org_id);
                   ELSE
				     g_line_rec.line_type_id(lb_line_idx) := oe_sys_parameters.VALUE('D-RL',
                                                                                      g_org_id);
					END IF;
                END IF;

                g_line_rec.return_reason_code(lb_line_idx) := NVL(g_header_rec.return_reason(lb_hdr_idx),
                                                                  '00');
                g_line_rec.line_category_code(lb_line_idx) := 'RETURN';
                g_line_rec.org_order_creation_date(lb_line_idx) := g_header_rec.org_order_creation_date(lb_hdr_idx);
                g_line_rec.return_reference_no(lb_line_idx) := g_header_rec.return_orig_sys_doc_ref(lb_hdr_idx);
                g_line_rec.schedule_status_code(lb_line_idx) := NULL;
                g_header_rec.order_total(lb_hdr_idx) :=
                                       g_header_rec.order_total(lb_hdr_idx)
                                     +   g_line_rec.unit_selling_price(lb_line_idx)
                                       * -1;

                -- Get Return Ref Line ID for NON SKU items
                IF g_line_rec.return_reference_no(lb_line_idx) IS NOT NULL
                THEN
                    ln_header_id := NULL;
                    ln_line_id := NULL;
                    ln_orig_sell_price := NULL;
                    ln_orig_ord_qty := NULL;
                    get_return_attributes(g_line_rec.return_reference_no(lb_line_idx),
                                          NULL,
                                          g_line_rec.inventory_item_id(lb_line_idx),
                                          g_line_rec.sold_to_org_id(lb_line_idx),
                                          ln_header_id                       --G_Line_Rec.return_attribute1(lb_line_idx)
                                                      ,
                                          ln_line_id                         --G_Line_Rec.return_attribute2(lb_line_idx)
                                                    ,
                                          ln_orig_ord_qty,
                                          ln_orig_sell_price);
                    g_line_rec.ret_ref_header_id(lb_line_idx) := ln_header_id;
                    g_line_rec.ret_ref_line_id(lb_line_idx) := ln_line_id;
                END IF;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'G_line_rec.inventory_item_id:= '
                                     || g_line_rec.inventory_item_id(lb_line_idx));
                    oe_debug_pub.ADD(   'return order reference:='
                                     || g_line_rec.return_reference_no(lb_line_idx));
                    oe_debug_pub.ADD(   'Return Header id:= '
                                     || g_line_rec.ret_ref_header_id(lb_line_idx));
                    oe_debug_pub.ADD(   'Return Line id:= '
                                     || g_line_rec.ret_ref_line_id(lb_line_idx));
                END IF;
            ELSE
                --MODIFIED BY NB fOR R11.2
                -- Need to charge customer for the fee/ del charge
                IF lc_order_source = 'POE'
                THEN
                    g_line_rec.line_type_id(lb_line_idx) := oe_sys_parameters.VALUE('D-PSL',
                                                                                    g_org_id);

                    IF g_header_rec.deposit_amount(lb_hdr_idx) > 0
                    THEN
                        g_line_rec.line_type_id(lb_line_idx) := oe_sys_parameters.VALUE('D-SL',
                                                                                        g_org_id);
                    END IF;
                ELSE
                   -- FOR AOPS and AOPS RCC Orders .
                  IF g_header_rec.rcc_transaction(lb_hdr_idx) = 'Y'
                  THEN 
                    g_line_rec.line_type_id(lb_line_idx) := oe_sys_parameters.VALUE('D-PSL-RCC',
                                                                                     g_org_id);
                  ELSE
				    g_line_rec.line_type_id(lb_line_idx) := oe_sys_parameters.VALUE('D-SL',
                                                                                     g_org_id);
				  END IF; 
               END IF;

                g_line_rec.line_category_code(lb_line_idx) := 'ORDER';
                g_line_rec.return_reason_code(lb_line_idx) := NULL;
                g_line_rec.org_order_creation_date(lb_line_idx) := NULL;
                g_line_rec.return_reference_no(lb_line_idx) := NULL;
                g_line_rec.schedule_status_code(lb_line_idx) := NULL;
                g_header_rec.order_total(lb_hdr_idx) :=
                                          g_header_rec.order_total(lb_hdr_idx)
                                        + g_line_rec.unit_selling_price(lb_line_idx);
            END IF;

            -- oe_debug_pub.add('ADJ - LINE The order total is ' || G_Header_Rec.order_total(lb_hdr_idx));

            -- Increment the global Line counter used in determining batch size
            g_line_counter :=   g_line_counter
                              + 1;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Orig Sys Line Ref is '
                                 || g_line_rec.orig_sys_line_ref(lb_line_idx));
                oe_debug_pub.ADD(   'Error Flag is '
                                 || g_header_rec.error_flag(lb_hdr_idx));
            END IF;
        END IF;

        <<end_of_adj>>
        x_return_status := 'S';
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed in processing adjustment record for order '
                              || g_header_rec.orig_sys_document_ref(lb_hdr_idx));
            fnd_file.put_line(fnd_file.LOG,
                                 'Line Nmber for adjustment record is '
                              || lc_line_nbr);
            fnd_file.put_line(fnd_file.LOG,
                                 'The error is '
                              || SQLERRM);
            -- Need to clear this BAD order
            clear_bad_orders('ADJUSTMENT',
                             g_header_rec.orig_sys_document_ref(lb_hdr_idx));
            x_return_status := 'U';
    END process_adjustments;

    PROCEDURE get_def_shipto(
        p_cust_account_id  IN             NUMBER,
        x_ship_to_org_id   OUT NOCOPY     NUMBER)
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
        FROM   hz_cust_site_uses_all site_use,
               hz_cust_acct_sites_all addr
        WHERE  addr.cust_account_id = p_cust_account_id
        AND    addr.cust_acct_site_id = site_use.cust_acct_site_id
        AND    site_use.site_use_code = 'SHIP_TO'
        AND    site_use.org_id = g_org_id
        AND    site_use.primary_flag = 'Y'
        AND    site_use.status = 'A';
    EXCEPTION
        WHEN OTHERS
        THEN
            x_ship_to_org_id := NULL;
    END;

    PROCEDURE get_def_billto(
        p_cust_account_id  IN             NUMBER,
        x_bill_to_org_id   OUT NOCOPY     NUMBER)
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
        FROM   hz_cust_accounts_all acct,
               hz_cust_site_uses_all site_use,
               hz_cust_acct_sites_all addr
        WHERE  acct.cust_account_id = p_cust_account_id
        AND    acct.cust_account_id = addr.cust_account_id
        AND    addr.cust_acct_site_id = site_use.cust_acct_site_id
        AND    site_use.site_use_code = 'BILL_TO'
        AND    site_use.org_id = g_org_id
        AND    site_use.primary_flag = 'Y'
        AND    site_use.status = 'A'
        AND    addr.bill_to_flag = 'P'                                                                    -- 16-Mar-2009
        AND    addr.status = 'A';                                                                         -- 16-Mar-2009
    EXCEPTION
        WHEN OTHERS
        THEN
            x_bill_to_org_id := NULL;
            fnd_file.put_line(fnd_file.LOG,
                                 'WHEN OTHERS IN Get_Def_Billto ::'
                              || SUBSTR(SQLERRM,
                                        1,
                                        200));
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
    PROCEDURE derive_ship_to(
        p_sold_to_org_id         IN             NUMBER,
        p_orig_sys_document_ref  IN             VARCHAR2,
        p_order_source_id        IN             NUMBER,
        p_orig_sys_ship_ref      IN             VARCHAR2,
        p_ordered_date           IN             DATE,
        p_address_line1          IN             VARCHAR2,
        p_address_line2          IN             VARCHAR2,
        p_city                   IN             VARCHAR2,
        p_postal_code            IN             VARCHAR2,
        p_state                  IN             VARCHAR2,
        p_country                IN             VARCHAR2,
        p_province               IN             VARCHAR2,
        p_order_source           IN             VARCHAR2,
        x_ship_to_org_id         IN OUT NOCOPY  NUMBER,
        x_invoice_to_org_id      IN OUT NOCOPY  NUMBER,
        x_ship_to_geocode        IN OUT NOCOPY  VARCHAR2)
    IS
        ln_debug_level  CONSTANT NUMBER                                 := oe_debug_pub.g_debug_level;
        lc_match                 VARCHAR2(10);
        ln_ship_to_id            NUMBER;
        ln_invoice_to_id         NUMBER;
        lc_postal_code           VARCHAR2(60);
        lc_geocode               VARCHAR2(30);
        ln_invoice_to_org_id     NUMBER;
        l_orig_sys_ref_tbl       t_vchar50;
        lb_create_new_shipto     BOOLEAN                                := FALSE;
        lc_hvop_shipto_ref       VARCHAR2(50);
        lc_last_ref              VARCHAR2(50);
        lc_return_status         VARCHAR2(1);
        ln_hvop_ref_count        NUMBER;
        lc_country               VARCHAR2(30);
        lc_amz_cust_no           VARCHAR2(30);
        l_request                xx_twe_geocode_util.geocode_request_t;
        l_response               xx_twe_geocode_util.geocode_response_t;
    BEGIN
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('Inside Derive Ship To ');
            oe_debug_pub.ADD(   'Ship Ref '
                             || p_orig_sys_ship_ref);
            oe_debug_pub.ADD(   'Ordered date '
                             || p_ordered_date);
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
            INTO   ln_ship_to_id,
                   ln_invoice_to_id,
                   lc_postal_code,
                   lc_geocode
            FROM   hz_orig_sys_references osr,
                   hz_cust_site_uses_all site_use,
                   hz_locations loc,
                   hz_party_sites site,
                   hz_cust_acct_sites acct_site
            WHERE  osr.orig_system = 'A0'
            AND    osr.owner_table_name = 'HZ_CUST_SITE_USES_ALL'
            AND    osr.orig_system_reference =    p_orig_sys_ship_ref
                                               || '-SHIP_TO'
            AND    osr.status = 'A'
            AND    osr.owner_table_id = site_use.site_use_id
            AND    site_use.site_use_code = 'SHIP_TO'
            AND    site_use.org_id = g_org_id
            AND    site_use.cust_acct_site_id = acct_site.cust_acct_site_id
            AND    acct_site.party_site_id = site.party_site_id
            AND    site.location_id = loc.location_id;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                oe_debug_pub.ADD('No data found for the ShipTo reference from legacy');

                -- If it is the SPC or PRO card customer then we derive the default Ship-To
                IF p_order_source IN('S', 'U')
                THEN
                    get_def_shipto(p_cust_account_id      => p_sold_to_org_id,
                                   x_ship_to_org_id       => ln_ship_to_id);
                END IF;

                -- IF can not derive the ship to then return
                IF ln_ship_to_id IS NULL
                THEN
                    RETURN;
                END IF;
        END;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Ship To  reference found :'
                             || ln_ship_to_id);
        END IF;

        x_ship_to_org_id := ln_ship_to_id;

    -- IF amazon order then
/*    IF p_order_source = 'A' THEN

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
*/
        IF ln_invoice_to_id IS NULL
        THEN
            -- Get the default Primary Bill To for the customer account
            get_def_billto(p_sold_to_org_id,
                           ln_invoice_to_id);
        END IF;

        x_invoice_to_org_id := ln_invoice_to_id;

        -- If SPC or PRO card orders then they are true POS orders and no need to populate the geocode on them
        IF p_order_source IN('U', 'S')
        THEN
            x_ship_to_geocode := NULL;
            GOTO ship_to_end;
        END IF;

        -- Check if the Ship_To postal code from AOPS order  matches with the one on the HZ_LOCATIONS
        IF NVL(p_postal_code,
               ' ') = NVL(lc_postal_code,
                          ' ')
        THEN
            -- Use the Geocode returned from HZ_LOCATIONS
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(' Match found so using the geocode from HZ_LOCATIONS ');
            END IF;

            x_ship_to_geocode := lc_geocode;
        ELSE
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(' No match found hence calling the TWE API ');
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

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   ' Geocode '
                                     || l_response.geocode);
                --    oe_debug_pub.add(' Status  ' || l_response.status.result||' : '||l_response.status.code||' : '||l_response.status.description);
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    l_response.geocode := NULL;
                    oe_debug_pub.ADD('In Others Calling XX_TWE_GEOCODE_UTIL API');
            END;

            -- Check the return values
            IF NVL(l_response.geocode,
                   '') = ''
            THEN
                x_ship_to_geocode := NULL;
            ELSE
                x_ship_to_geocode := l_response.geocode;
            END IF;
        END IF;

        <<ship_to_end>>
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   ' Geocode '
                             || x_ship_to_geocode);
            oe_debug_pub.ADD(   ' Shipto  '
                             || x_ship_to_org_id);
            oe_debug_pub.ADD(   ' BillTo  '
                             || x_invoice_to_org_id);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            oe_debug_pub.ADD('In Others for Derive ShipTo');
            oe_debug_pub.ADD(   'Error :'
                             || SUBSTR(SQLERRM,
                                       1,
                                       80));
            x_ship_to_org_id := NULL;
            x_invoice_to_org_id := NULL;
            x_ship_to_geocode := NULL;
    END derive_ship_to;

    FUNCTION order_source(
         p_order_source    IN  VARCHAR2
		,p_app_id          IN  VARCHAR2)
		RETURN VARCHAR2
    IS
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
	    IF p_app_id IS NOT NULL
		THEN
		 BEGIN
		    SELECT attribute6
            INTO   g_order_source(p_order_source)
            FROM   fnd_lookup_values
            WHERE  lookup_type = 'OD_ORDER_SOURCE' 
			  AND  lookup_code = '0'||UPPER(p_order_source)
			  AND  attribute7  = p_app_id;

	     EXCEPTION
         WHEN NO_DATA_FOUND
         THEN 
            BEGIN
			  SELECT   attribute6
                INTO   g_order_source(p_order_source)
                FROM   fnd_lookup_values
               WHERE  lookup_type = 'OD_ORDER_SOURCE' AND lookup_code = UPPER(p_order_source);
			EXCEPTION
            WHEN OTHERS
            THEN
			   RETURN NULL;
            END;  			
         END;
	    ELSE		
        IF NOT g_order_source.EXISTS(p_order_source)
        THEN
            SELECT attribute6
            INTO   g_order_source(p_order_source)
            FROM   fnd_lookup_values
            WHERE  lookup_type = 'OD_ORDER_SOURCE' AND lookup_code = UPPER(p_order_source);
        END IF;
        END IF;
        RETURN(g_order_source(p_order_source));
    EXCEPTION
        WHEN OTHERS
        THEN
		    RETURN NULL;
    END order_source;

    FUNCTION get_salesrep_for_legacyrep(
        p_org_id      IN  NUMBER,
        p_sales_rep   IN  VARCHAR2,
        p_as_of_date  IN  DATE DEFAULT SYSDATE)
        RETURN NUMBER
    IS
        ln_debug_level  CONSTANT NUMBER                     := oe_debug_pub.g_debug_level;

        CURSOR lcu_get_salesrep(
            p_salesrep  VARCHAR2,
            p_orgid     NUMBER)
        IS
            SELECT DISTINCT jrs1.salesrep_id spid1,
                            jrs1.start_date_active start_dt1,
                            jrs1.end_date_active end_dt1,
                            jrs2.salesrep_id spid2,
                            jrs2.start_date_active start_dt2,
                            jrs2.end_date_active end_dt2,
                            jrs3.salesrep_id spid3,
                            jrs3.start_date_active start_dt3,
                            jrs3.end_date_active end_dt3,
                            jrs4.salesrep_id spid4,
                            jrs4.start_date_active start_dt4,
                            jrs4.end_date_active end_dt4,
                            jrs5.salesrep_id spid5,
                            jrs5.start_date_active start_dt5,
                            jrs5.end_date_active end_dt5,
                            jrs6.salesrep_id spid6,
                            jrs6.start_date_active start_dt6,
                            jrs6.end_date_active end_dt6
            FROM            jtf_rs_salesreps jrs1,
                            jtf_rs_resource_extns_vl jrr1,
                            jtf_rs_group_mbr_role_vl jrg,
                            jtf_rs_role_relations jrr,
                            jtf_rs_salesreps jrs2,
                            jtf_rs_resource_extns_vl jrr2,
                            jtf_rs_salesreps jrs3,
                            jtf_rs_resource_extns_vl jrr3,
                            jtf_rs_salesreps jrs4,
                            jtf_rs_resource_extns_vl jrr4,
                            jtf_rs_salesreps jrs5,
                            jtf_rs_resource_extns_vl jrr5,
                            jtf_rs_salesreps jrs6,
                            jtf_rs_resource_extns_vl jrr6
            WHERE           jrr.attribute15 = p_salesrep
            AND             jrr.role_resource_type = 'RS_GROUP_MEMBER'
            -- AND p_as_of_date BETWEEN jrr.start_date_active and NVL(jrr.end_date_active,(p_as_of_date+1))
            AND             jrr.role_relate_id = jrg.role_relate_id
            AND             jrg.resource_id = jrs1.resource_id
            AND             jrs1.org_id(+) = p_orgid
            AND             jrr1.resource_id = jrs1.resource_id
            AND             jrr2.source_id(+) = jrr1.source_mgr_id
            AND             jrs2.org_id(+) = p_orgid
            AND             jrs2.resource_id(+) = jrr2.resource_id
            AND             jrr3.source_id(+) = jrr2.source_mgr_id
            AND             jrs3.org_id(+) = p_orgid
            AND             jrs3.resource_id(+) = jrr3.resource_id
            AND             jrr4.source_id(+) = jrr3.source_mgr_id
            AND             jrs4.org_id(+) = p_orgid
            AND             jrs4.resource_id(+) = jrr4.resource_id
            AND             jrr5.source_id(+) = jrr4.source_mgr_id
            AND             jrs5.org_id(+) = p_orgid
            AND             jrs5.resource_id(+) = jrr5.resource_id
            AND             jrr6.source_id(+) = jrr5.source_mgr_id
            AND             jrs6.org_id(+) = p_orgid
            AND             jrs6.resource_id(+) = jrr6.resource_id;

        ln_salesrep_id           NUMBER;
        l_hierarchy_rec          lcu_get_salesrep%ROWTYPE;
    BEGIN
        IF NOT g_sales_rep.EXISTS(p_sales_rep)
        THEN
            -- Get the active salesrep associated with the legacy rep as of the passed date
            OPEN lcu_get_salesrep(p_sales_rep,
                                  p_org_id);

            FETCH lcu_get_salesrep
            INTO  l_hierarchy_rec;

            CLOSE lcu_get_salesrep;

            IF p_as_of_date BETWEEN l_hierarchy_rec.start_dt1 AND NVL(l_hierarchy_rec.end_dt1,
                                                                        p_as_of_date
                                                                      + 1)
            THEN
                ln_salesrep_id := l_hierarchy_rec.spid1;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'spid1 : '
                                     || ln_salesrep_id);
                END IF;
            ELSIF p_as_of_date BETWEEN l_hierarchy_rec.start_dt2 AND NVL(l_hierarchy_rec.end_dt2,
                                                                           p_as_of_date
                                                                         + 1)
            THEN
                ln_salesrep_id := l_hierarchy_rec.spid2;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'spid2 : '
                                     || ln_salesrep_id);
                END IF;
            ELSIF p_as_of_date BETWEEN l_hierarchy_rec.start_dt3 AND NVL(l_hierarchy_rec.end_dt3,
                                                                           p_as_of_date
                                                                         + 1)
            THEN
                ln_salesrep_id := l_hierarchy_rec.spid3;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'spid3 : '
                                     || ln_salesrep_id);
                END IF;
/*
            ELSIF p_as_of_date BETWEEN l_hierarchy_rec.start_dt4 AND NVL(l_hierarchy_rec.end_dt4, p_as_of_date + 1) THEN
                ln_salesrep_id := l_hierarchy_rec.spid4;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add('spid4 : '||ln_salesrep_id);
                END IF;
            ELSIF p_as_of_date BETWEEN l_hierarchy_rec.start_dt5 AND NVL(l_hierarchy_rec.end_dt5, p_as_of_date + 1) THEN
                ln_salesrep_id := l_hierarchy_rec.spid5;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add('spid5 : '||ln_salesrep_id);
                END IF;
            ELSIF p_as_of_date BETWEEN l_hierarchy_rec.start_dt6 AND NVL(l_hierarchy_rec.end_dt6, p_as_of_date + 1) THEN
                ln_salesrep_id := l_hierarchy_rec.spid6;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.add('spid6 : '||ln_salesrep_id);
                END IF;
*/
            ELSE
                ln_salesrep_id := fnd_profile.VALUE('ONT_DEFAULT_PERSON_ID');

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'Default spid : '
                                     || ln_salesrep_id);
                END IF;
            END IF;

            g_sales_rep(p_sales_rep) := ln_salesrep_id;
        END IF;

        RETURN(g_sales_rep(p_sales_rep));
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN(NULL);
    END get_salesrep_for_legacyrep;

    FUNCTION sales_rep(
        p_sales_rep  IN  VARCHAR2)
        RETURN NUMBER
    IS
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
        IF NOT g_sales_rep.EXISTS(p_sales_rep)
        THEN
            SELECT jrs.salesrep_id
            INTO   g_sales_rep(p_sales_rep)
            FROM   jtf_rs_defresroles_vl jrdv,
                   jtf_rs_salesreps jrs,
                   xxtps_sp_mapping mp
            WHERE  jrdv.role_resource_id = jrs.resource_id
            AND    jrs.org_id = g_org_id
            AND    mp.sp_id_orig = p_sales_rep
            AND    jrdv.attribute15 = mp.sp_id_new
            AND    NVL(jrs.end_date_active,
                       SYSDATE) >= SYSDATE
            AND    ROWNUM = 1;
        END IF;

        RETURN(g_sales_rep(p_sales_rep));
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END sales_rep;

    FUNCTION get_ship_method(
        p_ship_method  IN  VARCHAR2)
        RETURN VARCHAR2
    IS
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
        IF NOT g_ship_method.EXISTS(p_ship_method)
        THEN
            SELECT ship.lookup_code
            INTO   g_ship_method(p_ship_method)
            FROM   oe_ship_methods_v ship,
                   fnd_lookup_values lkp
            WHERE  lkp.attribute6 = ship.lookup_code
            AND    lkp.lookup_code = p_ship_method
            AND    lkp.lookup_type = 'OD_SHIP_METHODS';
        END IF;

        RETURN(g_ship_method(p_ship_method));
    EXCEPTION
        WHEN OTHERS
        THEN
            oe_debug_pub.ADD(   'Not able to get the ship method '
                             || SUBSTR(SQLERRM,
                                       1,
                                       90));
            RETURN NULL;
    END get_ship_method;

    FUNCTION get_ret_actcatreason_code(
        p_code  IN  VARCHAR2)
        RETURN VARCHAR2
    IS
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
        IF NOT g_ret_actcatreason.EXISTS(p_code)
        THEN
            SELECT lkp.lookup_code
            INTO   g_ret_actcatreason(p_code)
            FROM   fnd_lookup_values lkp
            WHERE  lkp.lookup_code = p_code AND lkp.lookup_type = 'OD_GMIL_REASON_KEY';
        END IF;

        RETURN(g_ret_actcatreason(p_code));
    EXCEPTION
        WHEN OTHERS
        THEN
            oe_debug_pub.ADD(   '4UNEXPECTED ERROR: '
                             || SQLERRM);
            RETURN NULL;
    END get_ret_actcatreason_code;

    FUNCTION sales_channel(
        p_sales_channel  IN  VARCHAR2)
        RETURN VARCHAR2
    IS
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
        IF NOT g_sales_channel.EXISTS(p_sales_channel)
        THEN
            SELECT lookup_code
            INTO   g_sales_channel(p_sales_channel)
            FROM   oe_lookups
            WHERE  lookup_type = 'SALES_CHANNEL' AND lookup_code = p_sales_channel;
        END IF;

        RETURN(g_sales_channel(p_sales_channel));
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END sales_channel;

    FUNCTION return_reason(
        p_return_reason  IN  VARCHAR2)
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
        IF NOT g_return_reason.EXISTS(p_return_reason)
        THEN
            SELECT lookup_code
            INTO   g_return_reason(p_return_reason)
            FROM   oe_ar_lookups_v
            WHERE  lookup_type = 'CREDIT_MEMO_REASON' AND UPPER(lookup_code) = UPPER(p_return_reason);
        END IF;

        RETURN(g_return_reason(p_return_reason));
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN(NULL);
    END return_reason;

    FUNCTION payment_term(
        p_sold_to_org_id  IN  NUMBER)
        RETURN NUMBER
    IS
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
        INTO   ln_payment_term_id
        FROM   hz_customer_profiles
        WHERE  cust_account_id = p_sold_to_org_id AND site_use_id IS NULL;

        RETURN ln_payment_term_id;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END payment_term;

    FUNCTION get_organization_id(
        p_org_no  IN  VARCHAR2)
        RETURN NUMBER
    IS
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
        IF NOT g_org_rec.organization_id.EXISTS(p_org_no)
        THEN
            load_org_details(p_org_no);
        END IF;

        RETURN(g_org_rec.organization_id(p_org_no));
    EXCEPTION
        WHEN OTHERS
        THEN
            oe_debug_pub.ADD(   'Error in Getting Org ID: '
                             || SQLERRM);
            RETURN NULL;
    END get_organization_id;

    FUNCTION get_org_code(
        p_org_id  IN  NUMBER)
        RETURN VARCHAR2
    IS
-- +===================================================================+
-- | Name  : Get_org_code                                              |
-- | Description     : To derive opu country by passing                |
-- |                   org id                                          |
-- |                                                                   |
-- | Parameters     : p_org_id  IN -> pass opu id                      |
-- |                                                                   |
-- | Return         : opu country                                      |
-- +===================================================================+
        lc_ou_country  VARCHAR2(10);
    BEGIN
        SELECT SUBSTR(NAME,
                      (  INSTR(NAME,
                               '_',
                               1,
                               1)
                       + 1),
                      2) NAME
        INTO   lc_ou_country
        FROM   hr_operating_units
        WHERE  organization_id = p_org_id;

        RETURN lc_ou_country;
    EXCEPTION
        WHEN OTHERS
        THEN
            oe_debug_pub.ADD(   'Error in Getting operating unit name: '
                             || SQLERRM);
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
    FUNCTION get_store_id(
        p_org_no  IN  VARCHAR2)
        RETURN NUMBER
    IS
    BEGIN
        IF NOT g_org_rec.organization_id.EXISTS(p_org_no)
        THEN
            load_org_details(p_org_no);
        END IF;

        IF SUBSTR(g_org_rec.organization_type(p_org_no),
                  1,
                  5) = 'STORE'
        THEN
            RETURN(g_org_rec.organization_id(p_org_no));
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            oe_debug_pub.ADD(   'Error in GEtting Store ID : '
                             || SQLERRM);
            RETURN NULL;
    END get_store_id;

-- +===================================================================+
-- | Name  : Get_store_Country                                         |
-- | Description     : To derive store country by passing              |
-- |                   store location                                  |
-- |                                                                   |
-- | Parameters     : p_STORE_no  IN -> pass store location            |
-- |                                                                   |
-- | Return         : Country code                                     |
-- +===================================================================+
    FUNCTION get_store_country(
        p_store_no  IN  VARCHAR2)
        RETURN VARCHAR2
    IS
    BEGIN
        IF NOT g_org_rec.organization_id.EXISTS(p_store_no)
        THEN
            load_org_details(p_store_no);
        END IF;

        RETURN(g_org_rec.country_code(p_store_no));
    EXCEPTION
        WHEN OTHERS
        THEN
            oe_debug_pub.ADD(   'ERROR in getting country code: '
                             || SQLERRM);
            RETURN NULL;
    END get_store_country;

-- +===================================================================+
-- | Name  : Get_owner_table_id                                        |
-- | Description : To derive customer id and contact id                |
-- |                                                                   |
-- | Parameters  : p_orig_system  IN -> pass orig system               |
-- |             : p_orig_system_reference IN pass orig reference      |
-- |             : p_owner_table IN pass owner table name              |
-- |                                                                   |
-- | Return      : owner table id and status                           |
-- +===================================================================+
    PROCEDURE get_owner_table_id(
        p_orig_system            IN             VARCHAR2,
        p_orig_system_reference  IN             VARCHAR2,
        p_owner_table            IN             VARCHAR2,
        x_owner_table_id         OUT NOCOPY     NUMBER,
        x_return_status          OUT NOCOPY     VARCHAR2)
    IS
    BEGIN
        SELECT owner_table_id
        INTO   x_owner_table_id
        FROM   hz_orig_sys_references
        WHERE  orig_system = p_orig_system
        AND    orig_system_reference = p_orig_system_reference
        AND    owner_table_name = p_owner_table
        AND    status = 'A';

        IF x_owner_table_id IS NOT NULL
        THEN
            x_return_status := fnd_api.g_ret_sts_success;
        ELSE
            x_return_status := fnd_api.g_ret_sts_error;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_owner_table_id := NULL;
            x_return_status := fnd_api.g_ret_sts_error;
    END;

-- +===================================================================+
-- | Name  : Get_UOM_Code                                              |
-- | Description : To derive item UOM(EBS) by passing legacy UOM code  |
-- |                                                                   |
-- | Parameters  : p_legacy_uom  IN -> pass legacy UOM code            |
-- |                                                                   |
-- | Return      : UOM Code                                            |
-- +===================================================================+
    FUNCTION get_uom_code(
        p_legacy_uom  IN  VARCHAR2)
        RETURN VARCHAR2
    IS
    BEGIN
        IF g_uom_code.EXISTS(p_legacy_uom)
        THEN
            RETURN g_uom_code(p_legacy_uom);
        ELSE
            SELECT uom_code
            INTO   g_uom_code(p_legacy_uom)
            FROM   mtl_units_of_measure_vl
            WHERE  attribute1 = p_legacy_uom AND ROWNUM = 1;

            RETURN g_uom_code(p_legacy_uom);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            oe_debug_pub.ADD(   'ERROR in getting UOM code: '
                             || SQLERRM);
            RETURN NULL;
    END get_uom_code;

-- +===================================================================+
-- | Name  : Load_Org_Details                                          |
-- | Description : Local procedure to load org details                 |
-- |                                                                   |
-- | Parameters  : p_org_no  IN -> pass inv/store location no          |
-- |                                                                   |
-- | Return      : None                                                |
-- +===================================================================+
    PROCEDURE load_org_details(
        p_org_no  IN  VARCHAR2)
    IS
    BEGIN
        SELECT organization_id,
               attribute5,
               org.NAME,
               org.TYPE
        INTO   g_org_rec.organization_id(p_org_no),
               g_org_rec.country_code(p_org_no),
               g_org_rec.organization_name(p_org_no),
               g_org_rec.organization_type(p_org_no)
        FROM   hr_all_organization_units org
        WHERE  attribute1 = p_org_no;
    EXCEPTION
        WHEN OTHERS
        THEN
            oe_debug_pub.ADD(   'Error in loading Org Details: '
                             || SQLERRM);
    END load_org_details;

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
    PROCEDURE get_return_attributes(
        p_ref_order_number  IN             VARCHAR2,
        p_ref_line          IN             VARCHAR2,
        p_ref_item_id       IN             NUMBER,
        p_sold_to_org_id    IN             NUMBER,
        x_header_id         OUT NOCOPY     NUMBER,
        x_line_id           OUT NOCOPY     NUMBER,
        x_orig_sell_price   OUT NOCOPY     NUMBER,
        x_orig_ord_qty      OUT NOCOPY     NUMBER)
    IS
        ln_debug_level  CONSTANT NUMBER := oe_debug_pub.g_debug_level;
    BEGIN
        IF p_ref_line IS NOT NULL AND p_ref_item_id IS NULL
        THEN
            SELECT header_id,
                   line_id,
                   ordered_quantity,
                   unit_selling_price
            INTO   x_header_id,
                   x_line_id,
                   x_orig_ord_qty,
                   x_orig_sell_price
            FROM   oe_order_lines_all
            WHERE  orig_sys_document_ref = p_ref_order_number
            AND    orig_sys_line_ref = p_ref_line
            AND    sold_to_org_id = p_sold_to_org_id;
        ELSE
            SELECT header_id,
                   line_id,
                   ordered_quantity,
                   unit_selling_price
            INTO   x_header_id,
                   x_line_id,
                   x_orig_ord_qty,
                   x_orig_sell_price
            FROM   oe_order_lines_all
            WHERE  header_id = (SELECT header_id
                                FROM   oe_order_headers_all
                                WHERE  orig_sys_document_ref = p_ref_order_number)
            AND    inventory_item_id = p_ref_item_id
            AND    sold_to_org_id = p_sold_to_org_id
            AND    ROWNUM = 1;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_header_id := NULL;
            x_line_id := NULL;
            x_orig_ord_qty := NULL;
            x_orig_sell_price := NULL;
    END get_return_attributes;

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
    PROCEDURE get_return_header(
        p_ref_order_number  IN             VARCHAR2,
        p_sold_to_org_id    IN             NUMBER,
        x_header_id         OUT NOCOPY     NUMBER)
    IS
    BEGIN
        SELECT header_id
        INTO   x_header_id
        FROM   oe_order_headers_all
        WHERE  orig_sys_document_ref = p_ref_order_number AND sold_to_org_id = p_sold_to_org_id AND ROWNUM = 1;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_header_id := NULL;
    END get_return_header;

    FUNCTION customer_item_id(
        p_cust_item    IN  VARCHAR2,
        p_customer_id  IN  NUMBER)
        RETURN NUMBER
    IS
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
        ln_cust_item_id  NUMBER;
    BEGIN
        SELECT customer_item_id
        INTO   ln_cust_item_id
        FROM   mtl_customer_items
        WHERE  customer_item_number = p_cust_item AND customer_id = p_customer_id;

        RETURN ln_cust_item_id;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN(NULL);
    END customer_item_id;

    FUNCTION get_inventory_item_id(
        p_item  IN  VARCHAR2)
        RETURN NUMBER
    IS
-- +===================================================================+
-- | Name  : get_inventory_item_id                                     |
-- | Description     : To derive inventory_item_id  by passing         |
-- |                   legacy item number                              |
-- |                                                                   |
-- | Parameters     : p_item  IN -> pass sku number                    |
-- |                                                                   |
-- | Return         : inventory_item_id                                |
-- +===================================================================+
        ln_master_organization_id  NUMBER;
        ln_inventory_item_id       NUMBER;
    BEGIN
        ln_master_organization_id := oe_sys_parameters.VALUE('MASTER_ORGANIZATION_ID',
                                                             g_org_id);

        SELECT inventory_item_id
        INTO   ln_inventory_item_id
        FROM   mtl_system_items_b
        WHERE  organization_id = ln_master_organization_id AND segment1 = p_item;

        RETURN ln_inventory_item_id;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END get_inventory_item_id;

    PROCEDURE get_pay_method(
        p_payment_instrument  IN             VARCHAR2,
        p_payment_type_code   IN OUT NOCOPY  VARCHAR2,
        p_credit_card_code    IN OUT NOCOPY  VARCHAR2)
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
        IF NOT g_pay_method_code.EXISTS(p_payment_instrument)
        THEN
            SELECT attribute7,
                   attribute6
            INTO   g_pay_method_code(p_payment_instrument),
                   g_cc_code(p_payment_instrument)
            FROM   fnd_lookup_values
            WHERE  lookup_type = 'OD_PAYMENT_TYPES' AND lookup_code = p_payment_instrument;
        END IF;

        p_payment_type_code := g_pay_method_code(p_payment_instrument);
        p_credit_card_code := g_cc_code(p_payment_instrument);
    EXCEPTION
        WHEN OTHERS
        THEN
            p_payment_type_code := NULL;
            p_credit_card_code := NULL;
    END get_pay_method;

    FUNCTION get_receipt_method(
        p_pay_method_code  IN  VARCHAR2,
        p_org_id           IN  NUMBER,
        p_store_no         IN  VARCHAR2)
        RETURN VARCHAR2
    IS
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
        ln_receipt_method_id  NUMBER;
        lc_cash_name          VARCHAR2(20);
    BEGIN
        IF g_ou_country IS NULL
        THEN
            -- Get the OU Name
            SELECT SUBSTR(NAME,
                          (  INSTR(NAME,
                                   '_',
                                   1,
                                   1)
                           + 1),
                          2) NAME
            INTO   g_ou_country
            FROM   hr_operating_units
            WHERE  organization_id = g_org_id;
        END IF;

        IF p_pay_method_code IN('01', '51', '81', '10', '31', '80')
        THEN
            lc_cash_name :=    g_ou_country
                            || '_OM_CASH_'
                            || LPAD(p_store_no,
                                    6,
                                    '0');

            SELECT receipt_method_id
            INTO   ln_receipt_method_id
            FROM   ar_receipt_methods
            WHERE  NAME = lc_cash_name;
        ELSE
            ln_receipt_method_id := oe_sys_parameters.VALUE(p_pay_method_code,
                                                            g_org_id);
        END IF;

        RETURN ln_receipt_method_id;
    EXCEPTION
        WHEN OTHERS
        THEN
            oe_debug_pub.ADD(   'NO_DATA_FOUND in receipt_method_code: '
                             || p_store_no);
            RETURN NULL;
    END get_receipt_method;

    FUNCTION credit_card_name(
        p_sold_to_org_id  IN  NUMBER)
        RETURN VARCHAR2
    IS
-- +===================================================================+
-- | Name  : credit_card_name                                          |
-- | Description     : To derive credit_card_name  by passing          |
-- |                   customer id                                     |
-- |                                                                   |
-- | Parameters     : p_sold_to_org_id  IN -> pass customer id         |
-- |                                                                   |
-- | Return         : credit_card_name                                 |
-- +===================================================================+
        lc_cc_name  VARCHAR2(80);
    BEGIN
        SELECT party_name
        INTO   lc_cc_name
        FROM   hz_parties p,
               hz_cust_accounts a
        WHERE  a.cust_account_id = p_sold_to_org_id AND a.party_id = p.party_id;

        RETURN lc_cc_name;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END credit_card_name;

    PROCEDURE set_header_error(
        p_header_index  IN  BINARY_INTEGER)
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
    END set_header_error;

    PROCEDURE clear_table_memory
    IS
-- +===================================================================+
-- | Name  : Clear_Table_Memory                                        |
-- | Description      : This Procedure will clear the cache i.e delete |
-- |                    data from temporay tables for every 500 records|
-- |                                                                   |
-- +===================================================================+
    BEGIN
        g_header_rec.orig_sys_document_ref.DELETE;
        g_header_rec.order_source_id.DELETE;
        g_header_rec.change_sequence.DELETE;
        g_header_rec.order_category.DELETE;
        g_header_rec.org_id.DELETE;
        g_header_rec.ordered_date.DELETE;
        g_header_rec.order_type_id.DELETE;
        g_header_rec.legacy_order_type.DELETE;
        g_header_rec.price_list_id.DELETE;
        g_header_rec.transactional_curr_code.DELETE;
        g_header_rec.salesrep_id.DELETE;
        g_header_rec.sales_channel_code.DELETE;
        g_header_rec.shipping_method_code.DELETE;
        g_header_rec.shipping_instructions.DELETE;
        g_header_rec.customer_po_number.DELETE;
        g_header_rec.sold_to_org_id.DELETE;
        g_header_rec.ship_from_org_id.DELETE;
        g_header_rec.invoice_to_org_id.DELETE;
        g_header_rec.sold_to_contact_id.DELETE;
        g_header_rec.ship_to_org_id.DELETE;
        g_header_rec.ship_to_org.DELETE;
        g_header_rec.ship_from_org.DELETE;
        g_header_rec.sold_to_org.DELETE;
        g_header_rec.invoice_to_org.DELETE;
        g_header_rec.drop_ship_flag.DELETE;
        g_header_rec.booked_flag.DELETE;
        g_header_rec.operation_code.DELETE;
        g_header_rec.error_flag.DELETE;
        g_header_rec.ready_flag.DELETE;
        g_header_rec.payment_term_id.DELETE;
        g_header_rec.tax_value.DELETE;
        g_header_rec.customer_po_line_num.DELETE;
        g_header_rec.category_code.DELETE;
        g_header_rec.ship_date.DELETE;
        g_header_rec.return_reason.DELETE;
        g_header_rec.pst_tax_value.DELETE;
        g_header_rec.return_orig_sys_doc_ref.DELETE;
        g_header_rec.created_by.DELETE;
        g_header_rec.creation_date.DELETE;
        g_header_rec.last_update_date.DELETE;
        g_header_rec.last_updated_by.DELETE;
        g_header_rec.batch_id.DELETE;
        g_header_rec.request_id.DELETE;
/* Header Attributes  */
        g_header_rec.created_by_store_id.DELETE;
        g_header_rec.paid_at_store_id.DELETE;
        g_header_rec.paid_at_store_no.DELETE;
        g_header_rec.spc_card_number.DELETE;
        g_header_rec.placement_method_code.DELETE;
        g_header_rec.advantage_card_number.DELETE;
        g_header_rec.created_by_id.DELETE;
        g_header_rec.delivery_code.DELETE;
        g_header_rec.tran_number.DELETE;
        g_header_rec.aops_geo_code.DELETE;
        g_header_rec.tax_exempt_amount.DELETE;
        g_header_rec.delivery_method.DELETE;
        g_header_rec.release_number.DELETE;
        g_header_rec.cust_dept_no.DELETE;
        g_header_rec.desk_top_no.DELETE;
        g_header_rec.comments.DELETE;
        g_header_rec.start_line_index.DELETE;
        g_header_rec.accounting_rule_id.DELETE;
        g_header_rec.invoicing_rule_id.DELETE;
        g_header_rec.sold_to_contact.DELETE;
        g_header_rec.header_id.DELETE;
        g_header_rec.org_order_creation_date.DELETE;
        g_header_rec.return_act_cat_code.DELETE;
        g_header_rec.salesrep.DELETE;
        g_header_rec.order_source.DELETE;
        g_header_rec.sales_channel.DELETE;
        g_header_rec.shipping_method.DELETE;
        g_header_rec.deposit_amount.DELETE;
        g_header_rec.gift_flag.DELETE;
        g_header_rec.sas_sale_date.DELETE;
        g_header_rec.legacy_cust_name.DELETE;
        g_header_rec.inv_loc_no.DELETE;
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
        g_header_rec.ship_to_name.DELETE;
        g_header_rec.bill_to_name.DELETE;
        g_header_rec.cust_contact_name.DELETE;
        g_header_rec.cust_pref_phone.DELETE;
        g_header_rec.cust_pref_phextn.DELETE;
        g_header_rec.cust_pref_email.DELETE;
        g_header_rec.deposit_hold_flag.DELETE;
        g_header_rec.ineligible_for_hvop.DELETE;
        g_header_rec.tax_rate.DELETE;
        g_header_rec.order_number.DELETE;
        g_header_rec.is_reference_return.DELETE;
        g_header_rec.order_total.DELETE;
        g_header_rec.commisionable_ind.DELETE;
        g_header_rec.order_action_code.DELETE;
        g_header_rec.order_start_time.DELETE;
        g_header_rec.order_end_time.DELETE;
        g_header_rec.order_taxable_cd.DELETE;
        g_header_rec.override_delivery_chg_cd.DELETE;
        g_header_rec.price_cd.DELETE;
        g_header_rec.ship_to_geocode.DELETE;
        g_header_rec.cust_dept_description.DELETE;
        g_header_rec.sr_number.DELETE;
        g_header_rec.atr_order_flag.DELETE;
        g_header_rec.device_serial_num.DELETE;
        g_header_rec.app_id.DELETE;                                                                    --Added for 13.3
        g_header_rec.external_transaction_number.DELETE; 					       --Added for Amz mpl    
        g_header_rec.freight_tax_amount.DELETE;                                                        --Added for line lvl tax
        g_header_rec.freight_tax_rate.DELETE;                                                          --Added for line lvl tax
        g_header_rec.bill_level.DELETE;                                                                --Added for kitting
        g_header_rec.bill_override_flag.DELETE;                                                        --Added for kitting
        g_header_rec.bill_complete_flag.DELETE;                                                        --Added for BC
        g_header_rec.parent_order_number.DELETE;                                                       --Added for BC
        g_header_rec.cost_center_split.DELETE;                                                         --Added for BC

/* line Record */
        g_line_rec.orig_sys_document_ref.DELETE;
        g_line_rec.order_source_id.DELETE;
        g_line_rec.change_sequence.DELETE;
        g_line_rec.org_id.DELETE;
        g_line_rec.orig_sys_line_ref.DELETE;
        g_line_rec.ordered_date.DELETE;
        g_line_rec.line_number.DELETE;
        g_line_rec.line_type_id.DELETE;
        g_line_rec.inventory_item_id.DELETE;
        g_line_rec.inventory_item.DELETE;
        g_line_rec.source_type_code.DELETE;
        g_line_rec.schedule_ship_date.DELETE;
        g_line_rec.actual_ship_date.DELETE;
        g_line_rec.schedule_arrival_date.DELETE;
        g_line_rec.actual_arrival_date.DELETE;
        g_line_rec.ordered_quantity.DELETE;
        g_line_rec.order_quantity_uom.DELETE;
        g_line_rec.shipped_quantity.DELETE;
        g_line_rec.sold_to_org_id.DELETE;
        g_line_rec.ship_from_org_id.DELETE;
        g_line_rec.ship_to_org_id.DELETE;
        g_line_rec.invoice_to_org_id.DELETE;
        g_line_rec.ship_to_contact_id.DELETE;
        g_line_rec.sold_to_contact_id.DELETE;
        g_line_rec.invoice_to_contact_id.DELETE;
        g_line_rec.drop_ship_flag.DELETE;
        g_line_rec.price_list_id.DELETE;
        g_line_rec.unit_list_price.DELETE;
        g_line_rec.unit_selling_price.DELETE;
        g_line_rec.calculate_price_flag.DELETE;
        g_line_rec.tax_code.DELETE;
        g_line_rec.tax_date.DELETE;
        g_line_rec.tax_value.DELETE;
        --g_line_rec.shipping_method_code.DELETE;
        g_line_rec.salesrep_id.DELETE;
        g_line_rec.return_reason_code.DELETE;
        g_line_rec.customer_po_number.DELETE;
        g_line_rec.operation_code.DELETE;
        g_line_rec.error_flag.DELETE;
        g_line_rec.shipping_instructions.DELETE;
        g_line_rec.return_context.DELETE;
        g_line_rec.return_attribute1.DELETE;
        g_line_rec.return_attribute2.DELETE;
        g_line_rec.customer_item_name.DELETE;
        g_line_rec.customer_item_id.DELETE;
        g_line_rec.customer_item_id_type.DELETE;
        g_line_rec.line_category_code.DELETE;
        g_line_rec.tot_tax_value.DELETE;
        g_line_rec.customer_line_number.DELETE;
        g_line_rec.created_by.DELETE;
        g_line_rec.creation_date.DELETE;
        g_line_rec.last_update_date.DELETE;
        g_line_rec.last_updated_by.DELETE;
        g_line_rec.request_id.DELETE;
        g_line_rec.batch_id.DELETE;
        g_line_rec.legacy_list_price.DELETE;
        g_line_rec.vendor_product_code.DELETE;
        g_line_rec.contract_details.DELETE;
        g_line_rec.item_comments.DELETE;
        g_line_rec.line_comments.DELETE;
        g_line_rec.taxable_flag.DELETE;
        g_line_rec.sku_dept.DELETE;
        g_line_rec.item_source.DELETE;
        g_line_rec.average_cost.DELETE;
        g_line_rec.po_cost.DELETE;
        g_line_rec.canada_pst.DELETE;
        g_line_rec.return_act_cat_code.DELETE;
        g_line_rec.return_reference_no.DELETE;
        g_line_rec.back_ordered_qty.DELETE;
        g_line_rec.return_ref_line_no.DELETE;
        g_line_rec.org_order_creation_date.DELETE;
        g_line_rec.wholesaler_item.DELETE;
        g_line_rec.header_id.DELETE;
        g_line_rec.line_id.DELETE;
        g_line_rec.payment_term_id.DELETE;
        g_line_rec.inventory_item.DELETE;
        g_line_rec.schedule_status_code.DELETE;
        g_line_rec.user_item_description.DELETE;
        g_line_rec.config_code.DELETE;
        g_line_rec.ext_top_model_line_id.DELETE;
        g_line_rec.ext_link_to_line_id.DELETE;
        g_line_rec.sas_sale_date.DELETE;
        g_line_rec.aops_ship_date.DELETE;
        g_line_rec.calc_arrival_date.DELETE;
        g_line_rec.ret_ref_header_id.DELETE;
        g_line_rec.ret_ref_line_id.DELETE;
        g_line_rec.release_number.DELETE;
        g_line_rec.cust_dept_no.DELETE;
        g_line_rec.cust_dept_description.DELETE;
        g_line_rec.desk_top_no.DELETE;
        g_line_rec.tax_exempt_flag.DELETE;
        g_line_rec.tax_exempt_number.DELETE;
        g_line_rec.tax_exempt_reason.DELETE;
        g_line_rec.gsa_flag.DELETE;                                                                       --Added by NB
        g_line_rec.consignment_bank_code.DELETE;
        g_line_rec.waca_item_ctr_num.DELETE;
        g_line_rec.orig_selling_price.DELETE;
        g_line_rec.price_cd.DELETE;
        g_line_rec.price_change_reason_cd.DELETE;
        g_line_rec.price_prefix_cd.DELETE;
        g_line_rec.commisionable_ind.DELETE;
        g_line_rec.unit_orig_selling_price.DELETE;
        g_line_rec.mps_toner_retail.DELETE;
        g_line_rec.upc_code.DELETE;
        g_line_rec.price_type.DELETE;        
        g_line_rec.external_sku.DELETE;
        g_line_rec.line_tax_amount.DELETE;
        g_line_rec.line_tax_rate.DELETE;
        g_line_rec.kit_sku.DELETE;
        g_line_rec.kit_qty.DELETE;
        g_line_rec.kit_vpc.DELETE;
        g_line_rec.kit_dept.DELETE;
        g_line_rec.kit_seqnum.DELETE;
        g_line_rec.service_end_date.DELETE;

/* Discount Record */
        g_line_adj_rec.orig_sys_document_ref.DELETE;
        g_line_adj_rec.order_source_id.DELETE;
        g_line_adj_rec.org_id.DELETE;
        g_line_adj_rec.orig_sys_line_ref.DELETE;
        g_line_adj_rec.orig_sys_discount_ref.DELETE;
        g_line_adj_rec.sold_to_org_id.DELETE;
        g_line_adj_rec.change_sequence.DELETE;
        g_line_adj_rec.automatic_flag.DELETE;
        g_line_adj_rec.list_header_id.DELETE;
        g_line_adj_rec.list_line_id.DELETE;
        g_line_adj_rec.list_line_type_code.DELETE;
        g_line_adj_rec.applied_flag.DELETE;
        g_line_adj_rec.operand.DELETE;
        g_line_adj_rec.arithmetic_operator.DELETE;
        g_line_adj_rec.pricing_phase_id.DELETE;
        g_line_adj_rec.adjusted_amount.DELETE;
        g_line_adj_rec.inc_in_sales_performance.DELETE;
        g_line_adj_rec.operation_code.DELETE;
        g_line_adj_rec.error_flag.DELETE;
        g_line_adj_rec.request_id.DELETE;
        g_line_adj_rec.CONTEXT.DELETE;
        g_line_adj_rec.attribute6.DELETE;
        g_line_adj_rec.attribute7.DELETE;
        g_line_adj_rec.attribute8.DELETE;
        g_line_adj_rec.attribute9.DELETE;
        g_line_adj_rec.attribute10.DELETE;
/* payment record */
        g_payment_rec.orig_sys_document_ref.DELETE;
        g_payment_rec.order_source_id.DELETE;
        g_payment_rec.orig_sys_payment_ref.DELETE;
        g_payment_rec.org_id.DELETE;
        g_payment_rec.payment_type_code.DELETE;
        g_payment_rec.payment_collection_event.DELETE;
        g_payment_rec.prepaid_amount.DELETE;
        g_payment_rec.credit_card_number.DELETE;
        g_payment_rec.credit_card_number_enc.DELETE;
        g_payment_rec.IDENTIFIER.DELETE;
        g_payment_rec.credit_card_holder_name.DELETE;
        g_payment_rec.credit_card_expiration_date.DELETE;
        g_payment_rec.credit_card_code.DELETE;
        g_payment_rec.credit_card_approval_code.DELETE;
        g_payment_rec.credit_card_approval_date.DELETE;
        g_payment_rec.check_number.DELETE;
        g_payment_rec.payment_amount.DELETE;
        g_payment_rec.operation_code.DELETE;
        g_payment_rec.error_flag.DELETE;
        g_payment_rec.receipt_method_id.DELETE;
        g_payment_rec.payment_number.DELETE;
        g_payment_rec.attribute6.DELETE;
        g_payment_rec.attribute7.DELETE;
        g_payment_rec.attribute8.DELETE;
        g_payment_rec.attribute9.DELETE;
        g_payment_rec.attribute10.DELETE;
        g_payment_rec.sold_to_org_id.DELETE;
        g_payment_rec.attribute11.DELETE;
        g_payment_rec.attribute12.DELETE;
        g_payment_rec.attribute13.DELETE;
        g_payment_rec.attribute15.DELETE;
        g_payment_rec.payment_set_id.DELETE;
        g_payment_rec.attribute3.DELETE;
        g_payment_rec.attribute14.DELETE;
        g_payment_rec.attribute2.DELETE;

/* tender record */
        g_return_tender_rec.orig_sys_document_ref.DELETE;
        g_return_tender_rec.orig_sys_payment_ref.DELETE;
        g_return_tender_rec.order_source_id.DELETE;
        g_return_tender_rec.payment_number.DELETE;
        g_return_tender_rec.payment_type_code.DELETE;
        g_return_tender_rec.credit_card_code.DELETE;
        g_return_tender_rec.credit_card_number.DELETE;
        g_return_tender_rec.IDENTIFIER.DELETE;
        g_return_tender_rec.credit_card_holder_name.DELETE;
        g_return_tender_rec.credit_card_expiration_date.DELETE;
        g_return_tender_rec.credit_amount.DELETE;
        g_return_tender_rec.request_id.DELETE;
        g_return_tender_rec.sold_to_org_id.DELETE;
        g_return_tender_rec.cc_auth_manual.DELETE;
        g_return_tender_rec.merchant_nbr.DELETE;
        g_return_tender_rec.cc_auth_ps2000.DELETE;
        g_return_tender_rec.allied_ind.DELETE;
        g_return_tender_rec.sold_to_org_id.DELETE;
        g_return_tender_rec.receipt_method_id.DELETE;
        g_return_tender_rec.cc_mask_number.DELETE;
        g_return_tender_rec.od_payment_type.DELETE;
        g_return_tender_rec.token_flag.DELETE;
        g_return_tender_rec.emv_card.DELETE;
        g_return_tender_rec.emv_terminal.DELETE;
        g_return_tender_rec.emv_transaction.DELETE;
        g_return_tender_rec.emv_offline.DELETE;
        g_return_tender_rec.emv_fallback.DELETE;
        g_return_tender_rec.emv_tvr.DELETE;
        g_return_tender_rec.wallet_type.DELETE;
        g_return_tender_rec.wallet_id.DELETE;

/* tender record related to record 41*/   
        g_tender_rec.Orig_Sys_Document_Ref.Delete;
        g_tender_rec.Orig_Sys_Payment_Ref.Delete;
        g_tender_rec.Order_Source_Id.Delete;
        g_tender_rec.routing_line1.DELETE;
        g_tender_rec.Routing_Line2.Delete;
        g_tender_rec.Routing_Line3.Delete;
        g_tender_rec.Routing_Line4.Delete;
        g_tender_rec.batch_id.Delete;  -- added by ag

    Exception
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed in deleting global records :'
                              || SUBSTR(SQLERRM,
                                        1,
                                        80));
    END clear_table_memory;

    PROCEDURE insert_data
    IS
-- +===================================================================+
-- | Name  : Insert_Data                                               |
-- | Description      : This Procedure will insert into Interface      |
-- |                    tables                                         |
-- |                                                                   |
-- +===================================================================+
    BEGIN
        oe_debug_pub.ADD('Before Inserting data into headers');

        BEGIN
            FORALL i_hed IN g_header_rec.orig_sys_document_ref.FIRST .. g_header_rec.orig_sys_document_ref.LAST
                INSERT INTO oe_headers_iface_all
                            (orig_sys_document_ref,
                             order_source_id,
                             org_id,
                             change_sequence,
                             order_category,
                             ordered_date,
                             order_type_id,
                             price_list_id,
                             transactional_curr_code,
                             salesrep_id,
                             sales_channel_code,
                             shipping_method_code,
                             shipping_instructions,
                             customer_po_number,
                             sold_to_org_id,
                             ship_from_org_id,
                             invoice_to_org_id,
                             sold_to_contact_id,
                             ship_to_org_id,
                             ship_to_org,
                             ship_from_org,
                             sold_to_org,
                             invoice_to_org,
                             drop_ship_flag,
                             booked_flag,
                             operation_code,
                             error_flag,
                             ready_flag,
                             created_by,
                             creation_date,
                             last_update_date,
                             last_updated_by,
                             last_update_login,
                             request_id,
                             batch_id,
                             accounting_rule_id,
                             sold_to_contact,
                             payment_term_id,
                             salesrep,
                             order_source,
                             sales_channel,
                             shipping_method,
                             order_number,
                             tax_exempt_flag,
                             tax_exempt_number,
                             tax_exempt_reason_code,
                             ineligible_for_hvop)
                     VALUES (g_header_rec.orig_sys_document_ref(i_hed),
                             g_header_rec.order_source_id(i_hed),
                             g_org_id,
                             g_header_rec.change_sequence(i_hed),
                             g_header_rec.order_category(i_hed),
                             g_header_rec.ordered_date(i_hed),
                             g_header_rec.order_type_id(i_hed),
                             g_header_rec.price_list_id(i_hed),
                             g_header_rec.transactional_curr_code(i_hed),
                             g_header_rec.salesrep_id(i_hed),
                             g_header_rec.sales_channel_code(i_hed),
                             g_header_rec.shipping_method_code(i_hed),
                             g_header_rec.shipping_instructions(i_hed),
                             g_header_rec.customer_po_number(i_hed),
                             g_header_rec.sold_to_org_id(i_hed),
                             g_header_rec.ship_from_org_id(i_hed),
                             g_header_rec.invoice_to_org_id(i_hed),
                             g_header_rec.sold_to_contact_id(i_hed),
                             g_header_rec.ship_to_org_id(i_hed),
                             g_header_rec.ship_to_org(i_hed),
                             g_header_rec.ship_from_org(i_hed),
                             g_header_rec.sold_to_org(i_hed),
                             g_header_rec.invoice_to_org(i_hed),
                             g_header_rec.drop_ship_flag(i_hed),
                             g_header_rec.booked_flag(i_hed),
                             'INSERT',
                             g_header_rec.error_flag(i_hed),
                             'Y',
                             fnd_global.user_id,
                             SYSDATE,
                             SYSDATE,
                             fnd_global.user_id,
                             NULL,
                             g_header_rec.request_id(i_hed),
                             g_header_rec.batch_id(i_hed),
                             g_header_rec.accounting_rule_id(i_hed),
                             g_header_rec.sold_to_contact(i_hed),
                             g_header_rec.payment_term_id(i_hed),
                             g_header_rec.salesrep(i_hed),
                             g_header_rec.order_source(i_hed),
                             g_header_rec.sales_channel(i_hed),
                             g_header_rec.shipping_method(i_hed),
                             g_header_rec.order_number(i_hed),
                             g_header_rec.tax_exempt_flag(i_hed),
                             g_header_rec.tax_exempt_number(i_hed),
                             g_header_rec.tax_exempt_reason(i_hed),
                             g_header_rec.ineligible_for_hvop(i_hed));
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Failed in inserting Header records :'
                                  || SUBSTR(SQLERRM,
                                            1,
                                            80));
                RAISE fnd_api.g_exc_error;
        END;

        oe_debug_pub.ADD('Before Inserting data into headers attr');

        BEGIN
            FORALL i_hed IN g_header_rec.orig_sys_document_ref.FIRST .. g_header_rec.orig_sys_document_ref.LAST
                INSERT INTO xx_om_headers_attr_iface_all
                            (orig_sys_document_ref,
                             order_source_id,
                             created_by_store_id,
                             paid_at_store_id,
                             paid_at_store_no,
                             spc_card_number,
                             placement_method_code,
                             advantage_card_number,
                             created_by_id,
                             delivery_code,
                             delivery_method,
                             release_no,
                             cust_dept_no,
                             desk_top_no,
                             comments,
                             creation_date,
                             created_by,
                             last_update_date,
                             last_updated_by,
                             request_id,
                             batch_id,
                             gift_flag,
                             orig_cust_name,
                             od_order_type,
                             ship_to_sequence,
                             ship_to_address1,
                             ship_to_address2,
                             ship_to_city,
                             ship_to_state,
                             ship_to_country,
                             ship_to_county,
                             ship_to_zip,
                             ship_to_name,
                             bill_to_name,
                             cust_contact_name,
                             cust_pref_phone,
                             cust_pref_phextn,
                             cust_pref_email,
                             imp_file_name,
                             tax_rate,
                             order_total,
                             commisionable_ind,
                             order_action_code,
                             order_start_time,
                             order_end_time,
                             order_taxable_cd,
                             override_delivery_chg_cd,
                             ship_to_geocode,
                             cust_dept_description,
                             tran_number,
                             aops_geo_code,
                             tax_exempt_amount,
                             sr_number,
                             atr_order_flag,
                             device_serial_num,
                             app_id,
                             external_transaction_number,
                             freight_tax_rate,
                             freight_tax_amount,
                             bill_level,
                             bill_override_flag,
                             bill_comp_flag,
                             parent_order_num,
                             cost_center_split)
                     VALUES (g_header_rec.orig_sys_document_ref(i_hed),
                             g_header_rec.order_source_id(i_hed),
                             g_header_rec.created_by_store_id(i_hed),
                             g_header_rec.paid_at_store_id(i_hed),
                             g_header_rec.paid_at_store_no(i_hed),
                             g_header_rec.spc_card_number(i_hed),
                             g_header_rec.placement_method_code(i_hed),
                             g_header_rec.advantage_card_number(i_hed),
                             g_header_rec.created_by_id(i_hed),
                             g_header_rec.delivery_code(i_hed),
                             g_header_rec.delivery_method(i_hed),
                             g_header_rec.release_number(i_hed),
                             g_header_rec.cust_dept_no(i_hed),
                             g_header_rec.desk_top_no(i_hed),
                             g_header_rec.comments(i_hed),
                             SYSDATE,
                             fnd_global.user_id,
                             SYSDATE,
                             fnd_global.user_id,
                             g_header_rec.request_id(i_hed),
                             g_header_rec.batch_id(i_hed),
                             g_header_rec.gift_flag(i_hed),
                             g_header_rec.legacy_cust_name(i_hed),
                             g_header_rec.legacy_order_type(i_hed),
                             g_header_rec.ship_to_sequence(i_hed),
                             g_header_rec.ship_to_address1(i_hed),
                             g_header_rec.ship_to_address2(i_hed),
                             g_header_rec.ship_to_city(i_hed),
                             g_header_rec.ship_to_state(i_hed),
                             g_header_rec.ship_to_country(i_hed),
                             g_header_rec.ship_to_county(i_hed),
                             g_header_rec.ship_to_zip(i_hed),
                             g_header_rec.ship_to_name(i_hed),
                             g_header_rec.bill_to_name(i_hed),
                             g_header_rec.cust_contact_name(i_hed),
                             g_header_rec.cust_pref_phone(i_hed),
                             g_header_rec.cust_pref_phextn(i_hed),
                             g_header_rec.cust_pref_email(i_hed),
                             g_file_name,
                             g_header_rec.tax_rate(i_hed),
                             g_header_rec.order_total(i_hed),
                             g_header_rec.commisionable_ind(i_hed),
                             g_header_rec.order_action_code(i_hed),
                             g_header_rec.order_start_time(i_hed),
                             g_header_rec.order_end_time(i_hed),
                             g_header_rec.order_taxable_cd(i_hed),
                             g_header_rec.override_delivery_chg_cd(i_hed),
                             g_header_rec.ship_to_geocode(i_hed),
                             g_header_rec.cust_dept_description(i_hed),
                             g_header_rec.tran_number(i_hed),
                             g_header_rec.aops_geo_code(i_hed),
                             g_header_rec.tax_exempt_amount(i_hed),
                             g_header_rec.sr_number(i_hed),
                             g_header_rec.atr_order_flag(i_hed),
                             g_header_rec.device_serial_num(i_hed),
                             g_header_rec.app_id(i_hed),
                             g_header_rec.external_transaction_number(i_hed),
                             g_header_rec.freight_tax_rate(i_hed),
                             g_header_rec.freight_tax_amount(i_hed),
                             g_header_rec.bill_level(i_hed),
                             g_header_rec.bill_override_flag(i_hed),
                             g_header_rec.bill_complete_flag(i_hed),
                             g_header_rec.parent_order_number(i_hed),
                             g_header_rec.cost_center_split(i_hed));
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Failed in inserting Header Attribute records :'
                                  || SUBSTR(SQLERRM,
                                            1,
                                            80));
                RAISE fnd_api.g_exc_error;
        END;

        oe_debug_pub.ADD('Before Inserting data into lines');

        BEGIN
            FORALL i_lin IN g_line_rec.orig_sys_document_ref.FIRST .. g_line_rec.orig_sys_document_ref.LAST
                INSERT INTO oe_lines_iface_all
                            (orig_sys_document_ref,
                             order_source_id,
                             change_sequence,
                             org_id,
                             orig_sys_line_ref,
                             line_number,
                             line_type_id,
                             inventory_item_id,
                             inventory_item
                            --, source_type_code
                             ,
                             schedule_ship_date,
                             actual_shipment_date,
                             salesrep_id,
                             ordered_quantity,
                             order_quantity_uom,
                             shipped_quantity,
                             sold_to_org_id,
                             ship_from_org_id,
                             ship_to_org_id,
                             invoice_to_org_id,
                             drop_ship_flag,
                             price_list_id,
                             unit_list_price,
                             unit_selling_price,
                             calculate_price_flag,
                             tax_code,
                             tax_value,
                             tax_date,
                 --            shipping_method_code,
                             return_reason_code,
                             customer_po_number,
                             operation_code,
                             error_flag,
                             shipping_instructions,
                             return_context,
                             return_attribute1,
                             return_attribute2,
                             customer_item_id,
                             customer_item_id_type,
                             line_category_code,
                             creation_date,
                             created_by,
                             last_update_date,
                             last_updated_by,
                             request_id,
                             line_id,
                             payment_term_id,
                             request_date,
                             schedule_status_code,
                             customer_item_name,
                             user_item_description,
                             tax_exempt_flag,
                             tax_exempt_number,
                             tax_exempt_reason_code,
                             customer_line_number,
                             attribute3,
                             service_start_date,
                             service_end_date)
                     VALUES (g_line_rec.orig_sys_document_ref(i_lin),
                             g_line_rec.order_source_id(i_lin),
                             g_line_rec.change_sequence(i_lin),
                             g_org_id,
                             g_line_rec.orig_sys_line_ref(i_lin),
                             g_line_rec.line_number(i_lin),
                             g_line_rec.line_type_id(i_lin),
                             g_line_rec.inventory_item_id(i_lin),
                             g_line_rec.inventory_item(i_lin)
                                                             --, G_line_rec.source_type_code(i_lin)
                ,
                             g_line_rec.schedule_ship_date(i_lin),
                             g_line_rec.actual_ship_date(i_lin),
                             g_line_rec.salesrep_id(i_lin),
                             g_line_rec.ordered_quantity(i_lin),
                             g_line_rec.order_quantity_uom(i_lin),
                             g_line_rec.shipped_quantity(i_lin),
                             g_line_rec.sold_to_org_id(i_lin),
                             g_line_rec.ship_from_org_id(i_lin),
                             g_line_rec.ship_to_org_id(i_lin),
                             g_line_rec.invoice_to_org_id(i_lin),
                             g_line_rec.drop_ship_flag(i_lin),
                             g_line_rec.price_list_id(i_lin),
                             g_line_rec.unit_list_price(i_lin),
                             g_line_rec.unit_selling_price(i_lin),
                             'N',
                             NULL
                                 -- , G_line_rec.tax_code(i_lin) -- commented out as per prakesh mail for testing
                ,
                             g_line_rec.tax_value(i_lin),
                             g_line_rec.tax_date(i_lin),
                           --  g_line_rec.shipping_method_code(i_lin),
                             g_line_rec.return_reason_code(i_lin),
                             g_line_rec.customer_po_number(i_lin),
                             'INSERT',
                             'N',
                             g_line_rec.shipping_instructions(i_lin),
                             g_line_rec.return_context(i_lin),
                             g_line_rec.return_attribute1(i_lin),
                             g_line_rec.return_attribute2(i_lin),
                             g_line_rec.customer_item_id(i_lin),
                             g_line_rec.customer_item_id_type(i_lin),
                             g_line_rec.line_category_code(i_lin),
                             SYSDATE,
                             fnd_global.user_id,
                             SYSDATE,
                             fnd_global.user_id,
                             g_request_id,
                             g_line_rec.line_id(i_lin),
                             g_line_rec.payment_term_id(i_lin),
                             g_line_rec.ordered_date(i_lin),
                             g_line_rec.schedule_status_code(i_lin),
                             g_line_rec.customer_item_id(i_lin),
                             g_line_rec.user_item_description(i_lin),
                             g_line_rec.tax_exempt_flag(i_lin),
                             g_line_rec.tax_exempt_number(i_lin),
                             g_line_rec.tax_exempt_reason(i_lin),
                             g_line_rec.customer_line_number(i_lin),
                             g_line_rec.core_type_indicator(i_lin),
                             g_line_rec.ordered_date(i_lin),
                             g_line_rec.service_end_date(i_lin)
                             );
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Failed in inserting Line records :'
                                  || SUBSTR(SQLERRM,
                                            1,
                                            80));
                RAISE fnd_api.g_exc_error;
        END;

        oe_debug_pub.ADD('Before Inserting data into lines attr');

        BEGIN
            FORALL i_lin IN g_line_rec.orig_sys_document_ref.FIRST .. g_line_rec.orig_sys_document_ref.LAST
                INSERT INTO xx_om_lines_attr_iface_all
                            (orig_sys_document_ref,
                             order_source_id,
                             request_id,
                             vendor_product_code,
                             average_cost,
                             po_cost,
                             canada_pst,
                             return_act_cat_code,
                             ret_orig_order_num,
                             back_ordered_qty,
                             ret_orig_order_line_num,
                             ret_orig_order_date,
                             wholesaler_item,
                             orig_sys_line_ref,
                             legacy_list_price,
                             org_id,
                             contract_details,
                             item_comments,
                             line_comments,
                             taxable_flag,
                             sku_dept,
                             item_source,
                             config_code,
                             ext_top_model_line_id,
                             ext_link_to_line_id,
                             aops_ship_date,
                             sas_sale_date,
                             calc_arrival_date,
                             creation_date,
                             created_by,
                             last_update_date,
                             last_updated_by,
                             ret_ref_header_id,
                             ret_ref_line_id,
                             release_num,
                             cost_center_dept,
                             desktop_del_addr,
                             gsa_flag                                                                      --Added by NB
                                     ,
                             waca_item_ctr_num,
                             consignment_bank_code,
                             price_cd,
                             price_change_reason_cd,
                             price_prefix_cd,
                             commisionable_ind,
                             cust_dept_description,
                             unit_orig_selling_price,
                             mps_toner_retail,
                             upc_code,
                             price_type,
                             external_sku,
                             tax_rate,
                             tax_amount,
                             kit_sku,
                             kit_qty,
                             kit_vend_product_code,
                             kit_sku_dept,
                             kit_seqnum
                             )
                     VALUES (g_line_rec.orig_sys_document_ref(i_lin),
                             g_line_rec.order_source_id(i_lin),
                             g_request_id,
                             g_line_rec.vendor_product_code(i_lin),
                             g_line_rec.average_cost(i_lin),
                             g_line_rec.po_cost(i_lin),
                             g_line_rec.canada_pst(i_lin),
                             g_line_rec.return_act_cat_code(i_lin),
                             g_line_rec.return_reference_no(i_lin),
                             g_line_rec.back_ordered_qty(i_lin),
                             g_line_rec.return_ref_line_no(i_lin),
                             g_line_rec.org_order_creation_date(i_lin),
                             g_line_rec.wholesaler_item(i_lin),
                             g_line_rec.orig_sys_line_ref(i_lin),
                             g_line_rec.legacy_list_price(i_lin),
                             g_org_id,
                             g_line_rec.contract_details(i_lin),
                             g_line_rec.item_comments(i_lin),
                             g_line_rec.line_comments(i_lin)
                                                            -- commented out for Defect 7025 09/27/10 by NB
                ,
                             g_line_rec.taxable_flag(i_lin),
                             g_line_rec.sku_dept(i_lin),
                             g_line_rec.item_source(i_lin),
                             g_line_rec.config_code(i_lin),
                             g_line_rec.ext_top_model_line_id(i_lin),
                             g_line_rec.ext_link_to_line_id(i_lin),
                             g_line_rec.aops_ship_date(i_lin),
                             g_line_rec.sas_sale_date(i_lin),
                             g_line_rec.calc_arrival_date(i_lin),
                             SYSDATE,
                             fnd_global.user_id,
                             SYSDATE,
                             fnd_global.user_id,
                             g_line_rec.ret_ref_header_id(i_lin),
                             g_line_rec.ret_ref_line_id(i_lin),
                             g_line_rec.release_number(i_lin),
                             g_line_rec.cust_dept_no(i_lin),
                             g_line_rec.desk_top_no(i_lin),
                             g_line_rec.gsa_flag(i_lin)                                                    --Added By NB
                                                       ,
                             g_line_rec.waca_item_ctr_num(i_lin),
                             g_line_rec.consignment_bank_code(i_lin),
                             g_line_rec.price_cd(i_lin),
                             g_line_rec.price_change_reason_cd(i_lin),
                             g_line_rec.price_prefix_cd(i_lin),
                             g_line_rec.commisionable_ind(i_lin),
                             g_line_rec.cust_dept_description(i_lin),
                             g_line_rec.unit_orig_selling_price(i_lin),
                             g_line_rec.mps_toner_retail(i_lin),
                             g_line_rec.upc_code(i_lin),
                             g_line_rec.price_type(i_lin),
                             g_line_rec.external_sku (i_lin),
                             g_line_rec.line_tax_rate(i_lin),
                             g_line_rec.line_tax_amount (i_lin),
                             g_line_rec.kit_sku(i_lin),
                             g_line_rec.kit_qty(i_lin),
                             g_line_rec.kit_vpc(i_lin),
                             g_line_rec.kit_dept(i_lin),
                             g_line_rec.kit_seqnum(i_lin)

                             );
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Failed in inserting Line Attr records :'
                                  || SUBSTR(SQLERRM,
                                            1,
                                            80));
                RAISE fnd_api.g_exc_error;
        END;

        oe_debug_pub.ADD('Before Calling the KIT Line Process');

        BEGIN
          create_kit_line;
        EXCEPTION 
          WHEN OTHERS 
          THEN 
            fnd_file.put_line(fnd_file.LOG,
                                     'Failed in inserting/creating the KIT Line records :'
                                  || SUBSTR(SQLERRM,
                                            1,
                                            80));
                RAISE fnd_api.g_exc_error;
        END;

        oe_debug_pub.ADD('Before Inserting data into price adjs');

        BEGIN
            FORALL i_dis IN g_line_adj_rec.orig_sys_document_ref.FIRST .. g_line_adj_rec.orig_sys_document_ref.LAST
                INSERT INTO oe_price_adjs_iface_all
                            (orig_sys_document_ref,
                             order_source_id,
                             change_sequence,
                             org_id,
                             orig_sys_line_ref,
                             orig_sys_discount_ref,
                             sold_to_org_id,
                             automatic_flag,
                             list_header_id,
                             list_line_id,
                             list_line_type_code,
                             applied_flag,
                             operand,
                             arithmetic_operator,
                             pricing_phase_id,
                             adjusted_amount,
                             inc_in_sales_performance,
                             request_id,
                             operation_code,
                             CONTEXT,
                             attribute6,
                             attribute7,
                             attribute8,
                             attribute9,
                             attribute10,
                             created_by,
                             creation_date,
                             last_update_date,
                             last_updated_by,
                             operand_per_pqty,
                             adjusted_amount_per_pqty)
                     VALUES (g_line_adj_rec.orig_sys_document_ref(i_dis),
                             g_line_adj_rec.order_source_id(i_dis),
                             g_line_adj_rec.change_sequence(i_dis),
                             g_org_id,
                             g_line_adj_rec.orig_sys_line_ref(i_dis),
                             g_line_adj_rec.orig_sys_discount_ref(i_dis),
                             g_line_adj_rec.sold_to_org_id(i_dis),
                             'N',
                             g_line_adj_rec.list_header_id(i_dis),
                             g_line_adj_rec.list_line_id(i_dis),
                             'DIS',
                             'Y',
                             g_line_adj_rec.operand(i_dis),
                             'LUMPSUM',
                             g_line_adj_rec.pricing_phase_id(i_dis),
                             g_line_adj_rec.adjusted_amount(i_dis),
                             'Y',
                             g_request_id,
                             'INSERT',
                             'SALES_ACCT',
                             g_line_adj_rec.attribute6(i_dis),
                             g_line_adj_rec.attribute7(i_dis),
                             g_line_adj_rec.attribute8(i_dis),
                             g_line_adj_rec.attribute9(i_dis),
                             g_line_adj_rec.attribute10(i_dis),
                             fnd_global.user_id,
                             SYSDATE,
                             SYSDATE,
                             fnd_global.user_id,
                             g_line_adj_rec.operand(i_dis),
                             g_line_adj_rec.adjusted_amount(i_dis));
            oe_debug_pub.ADD('Before Inserting data into Payments');
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Failed in inserting Adjustments records :'
                                  || SUBSTR(SQLERRM,
                                            1,
                                            80));
                RAISE fnd_api.g_exc_error;
        END;

        BEGIN
            FORALL i_pay IN g_payment_rec.orig_sys_document_ref.FIRST .. g_payment_rec.orig_sys_document_ref.LAST
                INSERT INTO oe_payments_iface_all
                            (orig_sys_document_ref,
                             order_source_id,
                             orig_sys_payment_ref,
                             org_id,
                             payment_type_code,
                             payment_collection_event,
                             prepaid_amount,
                             credit_card_number,
                             credit_card_holder_name,
                             credit_card_expiration_date,
                             credit_card_code,
                             credit_card_approval_code,
                             credit_card_approval_date,
                             check_number,
                             payment_amount,
                             operation_code,
                             error_flag,
                             receipt_method_id,
                             payment_number,
                             created_by,
                             creation_date,
                             last_update_date,
                             last_updated_by,
                             request_id,
                             CONTEXT,
                             attribute4,
                             attribute5,
                             attribute6,
                             attribute7,
                             attribute8,
                             attribute9,
                             attribute10,
                             attribute11,
                             attribute12,
                             attribute13,
                             attribute15,
                             sold_to_org_id,
                             payment_set_id,
                             attribute3,
                             attribute14,
                             attribute2)
                     VALUES (   g_payment_rec.orig_sys_document_ref(i_pay)
                             || '-BYPASS',
                             g_payment_rec.order_source_id(i_pay),
                             g_payment_rec.orig_sys_payment_ref(i_pay),
                             g_org_id,
                             g_payment_rec.payment_type_code(i_pay),
                             'PREPAY',
                             g_payment_rec.prepaid_amount(i_pay),
                             NULL,                                       -- R12 g_payment_rec.credit_card_number(i_pay),
                             g_payment_rec.credit_card_holder_name(i_pay),
                             g_payment_rec.credit_card_expiration_date(i_pay),
                             g_payment_rec.credit_card_code(i_pay),
                             g_payment_rec.credit_card_approval_code(i_pay),
                             g_payment_rec.credit_card_approval_date(i_pay),
                             g_payment_rec.check_number(i_pay),
                             g_payment_rec.payment_amount(i_pay),
                             'INSERT',
                             'N',
                             g_payment_rec.receipt_method_id(i_pay),
                             g_payment_rec.payment_number(i_pay),
                             fnd_global.user_id,
                             SYSDATE,
                             SYSDATE,
                             fnd_global.user_id,
                             g_request_id,
                             'SALES_ACCT_HVOP',
                             g_payment_rec.credit_card_number_enc(i_pay),
                             g_payment_rec.IDENTIFIER(i_pay),
                             g_payment_rec.attribute6(i_pay),
                             g_payment_rec.attribute7(i_pay),
                             g_payment_rec.attribute8(i_pay),
                             g_payment_rec.attribute9(i_pay),
                             g_payment_rec.attribute10(i_pay),
                             g_payment_rec.attribute11(i_pay),
                             g_payment_rec.attribute12(i_pay),
                             g_payment_rec.attribute13(i_pay),
                             g_payment_rec.attribute15(i_pay),
                             g_payment_rec.sold_to_org_id(i_pay),
                             g_payment_rec.payment_set_id(i_pay),
                             g_payment_rec.attribute3(i_pay),
                             g_payment_rec.attribute14(i_pay),
                             g_payment_rec.attribute2(i_pay)
                              );
            oe_debug_pub.ADD('Before Inserting data into Return tenders');
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Failed in Payment records :'
                                  || SUBSTR(SQLERRM,
                                            1,
                                            80));
                RAISE fnd_api.g_exc_error;
        END;

        BEGIN
            FORALL i_pay IN g_return_tender_rec.orig_sys_document_ref.FIRST .. g_return_tender_rec.orig_sys_document_ref.LAST
                INSERT INTO xx_om_ret_tenders_iface_all
                            (orig_sys_document_ref,
                             order_source_id,
                             orig_sys_payment_ref,
                             payment_number,
                             request_id,
                             payment_type_code,
                             credit_card_code,
                             credit_card_number,
                             credit_card_holder_name,
                             credit_card_expiration_date,
                             credit_amount,
                             org_id,
                             sold_to_org_id,
                             created_by,
                             creation_date,
                             last_update_date,
                             last_updated_by,
                             cc_auth_manual,
                             merchant_number,
                             cc_auth_ps2000,
                             allied_ind,
                             receipt_method_id,
                             cc_mask_number,
                             od_payment_type,
                             IDENTIFIER,
                             token_flag,
                             emv_card,
                             emv_terminal,
                             emv_transaction,
                             emv_offline,
                             emv_fallback,
                             emv_tvr,
                             wallet_type,
                             wallet_id)
                     VALUES (g_return_tender_rec.orig_sys_document_ref(i_pay),
                             g_return_tender_rec.order_source_id(i_pay),
                             g_return_tender_rec.orig_sys_payment_ref(i_pay),
                             g_return_tender_rec.payment_number(i_pay),
                             g_request_id,
                             g_return_tender_rec.payment_type_code(i_pay),
                             g_return_tender_rec.credit_card_code(i_pay),
                             g_return_tender_rec.credit_card_number(i_pay),
                             g_return_tender_rec.credit_card_holder_name(i_pay),
                             g_return_tender_rec.credit_card_expiration_date(i_pay),
                             g_return_tender_rec.credit_amount(i_pay),
                             g_org_id,
                             g_return_tender_rec.sold_to_org_id(i_pay),
                             fnd_global.user_id,
                             SYSDATE,
                             SYSDATE,
                             fnd_global.user_id,
                             g_return_tender_rec.cc_auth_manual(i_pay),
                             g_return_tender_rec.merchant_nbr(i_pay),
                             g_return_tender_rec.cc_auth_ps2000(i_pay),
                             g_return_tender_rec.allied_ind(i_pay),
                             g_return_tender_rec.receipt_method_id(i_pay),
                             g_return_tender_rec.cc_mask_number(i_pay),
                             g_return_tender_rec.od_payment_type(i_pay),
                             g_return_tender_rec.IDENTIFIER(i_pay),
                             g_return_tender_rec.token_flag(i_pay),
                             g_return_tender_rec.emv_card(i_pay),
                             g_return_tender_rec.emv_terminal(i_pay),
                             g_return_tender_rec.emv_transaction(i_pay),
                             g_return_tender_rec.emv_offline(i_pay),
                             g_return_tender_rec.emv_fallback(i_pay),
                             g_return_tender_rec.emv_tvr(i_pay),
                             g_return_tender_rec.wallet_type(i_pay),
                             g_return_tender_rec.wallet_id(i_pay)
                             );
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Failed in inserting Return Tenders records :'
                                  || SUBSTR(SQLERRM,
                                            1,
                                            80));
                RAISE fnd_api.g_exc_error;
        END;

        oe_debug_pub.ADD('End of Inserting data into Return tenders');

        BEGIN

        oe_debug_pub.ADD('Before Inserting data into xx_om_tender_attr_iface_all');

            FORALL i_tend IN g_tender_rec.orig_sys_document_ref.FIRST .. g_tender_rec.orig_sys_document_ref.LAST

                INSERT INTO xx_om_tender_attr_iface_all
                            ( orig_sys_document_ref
                            , order_source_id
                            , orig_sys_payment_ref
                            , routing_line1
                            , routing_line2
                            , routing_line3 
                            , routing_line4
                            , batch_id
                            , request_id
                            , org_id
                            , created_by
                            , creation_date
                            , last_update_date
                            , last_updated_by)
                      VALUES( g_tender_rec.orig_sys_document_ref(i_tend)
                            , g_tender_rec.order_source_id(i_tend)
                            , g_tender_rec.orig_sys_payment_ref(i_tend)
                            , g_tender_rec.routing_line1(i_tend)
                            , g_tender_rec.routing_line2(i_tend)
                            , g_tender_rec.routing_line3(i_tend)
                            , g_tender_rec.routing_line4(i_tend)
                            , g_tender_rec.batch_id(i_tend)
                            , g_request_id
                            , g_org_id
                            , FND_GLOBAL.USER_ID
                            , SYSDATE
                            , Sysdate
                            , FND_GLOBAL.USER_ID);  

        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Failed in inserting Tender records :'
                                  || SUBSTR(SQLERRM,
                                            1,
                                            80));
                RAISE fnd_api.g_exc_error;
        END;

        oe_debug_pub.ADD('End of Inserting data into tenders');

    END insert_data;

    PROCEDURE set_msg_context(
        p_entity_code   IN  VARCHAR2,
        p_warning_flag  IN  BOOLEAN DEFAULT FALSE,
        p_line_ref      IN  VARCHAR2 DEFAULT NULL)
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
        l_hdr_ind           BINARY_INTEGER := g_header_rec.orig_sys_document_ref.COUNT;
        l_orig_sys_doc_ref  VARCHAR2(80);
    BEGIN
        IF p_warning_flag
        THEN
            l_orig_sys_doc_ref := NULL;
        ELSE
            l_orig_sys_doc_ref := g_header_rec.orig_sys_document_ref(l_hdr_ind);
        END IF;

        oe_bulk_msg_pub.set_msg_context(p_entity_code                     => p_entity_code,
                                        p_entity_ref                      => NULL,
                                        p_entity_id                       => NULL,
                                        p_header_id                       => NULL,
                                        p_line_id                         => NULL,
                                        p_order_source_id                 => g_header_rec.order_source_id(l_hdr_ind),
                                        p_orig_sys_document_ref           => l_orig_sys_doc_ref,
                                        p_orig_sys_document_line_ref      => p_line_ref,
                                        p_orig_sys_shipment_ref           => NULL,
                                        p_change_sequence                 => NULL,
                                        p_source_document_type_id         => NULL,
                                        p_source_document_id              => NULL,
                                        p_source_document_line_id         => NULL,
                                        p_attribute_code                  => NULL,
                                        p_constraint_id                   => NULL);
    END set_msg_context;

    PROCEDURE insert_mismatch_amount_msgs
    IS
-- +====================================================================+
-- | Name  : insert_mismatch_amount_msgs                                |
-- | Description      : This Procedure will check the tot ord amt and   |
-- |                    payment amt mismatch                            |
-- |                                                                    |
-- +====================================================================+
        ln_msg_id  NUMBER;
    BEGIN
        fnd_file.put_line(fnd_file.LOG,
                          'Entering insert_mismatch_amount_msgs ');
        FORALL i IN g_ord_tot_mismatch_rec.orig_sys_document_ref.FIRST .. g_ord_tot_mismatch_rec.orig_sys_document_ref.LAST
            INSERT INTO oe_processing_msgs
                        (transaction_id,
                         request_id,
                         original_sys_document_ref,
                         order_source_id,
                         created_by,
                         creation_date,
                         last_updated_by,
                         last_update_date,
                         MESSAGE_TEXT,
                         program_application_id)
                 VALUES (oe_msg_id_s.NEXTVAL,
                         g_request_id,
                         g_ord_tot_mismatch_rec.orig_sys_document_ref(i),
                         g_ord_tot_mismatch_rec.order_source_id(i),
                         fnd_global.user_id,
                         SYSDATE,
                         fnd_global.user_id,
                         SYSDATE,
                         g_ord_tot_mismatch_rec.MESSAGE(i),
                         660);
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed in inserting Mismatch records :'
                              || SUBSTR(SQLERRM,
                                        1,
                                        80));
            RAISE fnd_api.g_exc_error;
    END insert_mismatch_amount_msgs;

    PROCEDURE set_header_id
    IS
-- +====================================================================+
-- | Name  : set_header_id                                              |
-- | Description      : This Procedure will set the header_id i.e.      |
-- |                    sequence number                                 |
-- |                                                                    |
-- +====================================================================+
        ln_order_source_id        t_num;
        lc_orig_sys_document_ref  t_v80;
    BEGIN
        -- High volume import assumes that global headers table
        -- populated by oe_bulk_process_header.load_headers will have
        -- header records sorted in the ascending order for BOTH header_id
        -- and for (order_source_id,orig_sys_ref) combination.
        -- So order by order_source_id, orig_sys_ref when assigning
        -- header_id from the sequence. If it is not ordered thus, header_ids
        -- will be in random order in the global table and workflows/pricing
        -- for orders may be skipped.
        SELECT   order_source_id,
                 orig_sys_document_ref
        BULK COLLECT INTO ln_order_source_id,
                  lc_orig_sys_document_ref
        FROM     oe_headers_iface_all
        WHERE    request_id = g_request_id AND order_category = 'ORDER' AND NVL(ineligible_for_hvop,
                                                                                'N') = 'N'
        ORDER BY order_source_id,
                 orig_sys_document_ref,
                 change_sequence;

        -- Now bulk update the header_ids
        FORALL i IN 1 .. ln_order_source_id.COUNT
            UPDATE oe_headers_iface_all
            SET header_id = oe_order_headers_s.NEXTVAL
            WHERE  order_source_id = ln_order_source_id(i)
            AND    orig_sys_document_ref = lc_orig_sys_document_ref(i)
            AND    request_id = g_request_id;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Failed in updating header_ids :'
                              || SUBSTR(SQLERRM,
                                        1,
                                        80));
            RAISE fnd_api.g_exc_error;
    END set_header_id;

-- +====================================================================+
-- | Name  : VALIDATE_ITEM_WAREHOUSE                                    |
-- | Description      : This procedure will be used by HVOP to validate |
-- | the combination of item/warehouse is valid or not.                 |
-- +====================================================================+
    PROCEDURE validate_item_warehouse(
        p_hdr_idx      IN  BINARY_INTEGER,
        p_line_idx     IN  BINARY_INTEGER,
        p_nonsku_flag  IN  VARCHAR2 DEFAULT 'N',
        p_item         IN  VARCHAR2)
    IS
        ln_item_id               NUMBER;
        ln_debug_level  CONSTANT NUMBER        := oe_debug_pub.g_debug_level;
        lc_err_msg               VARCHAR2(200);
    BEGIN
        IF p_item IS NULL
        THEN
            set_header_error(p_hdr_idx);
            set_msg_context(p_entity_code      => 'HEADER',
                            p_line_ref         => g_line_rec.orig_sys_line_ref(p_line_idx));
            lc_err_msg := 'Item Missing : ';
            fnd_message.set_name('XXOM',
                                 'XX_OM_MISSING_ATTRIBUTE');
            fnd_message.set_token('ATTRIBUTE',
                                  'SKU Id');
            oe_bulk_msg_pub.ADD;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(lc_err_msg,
                                 1);
            END IF;

            g_line_rec.inventory_item_id(p_line_idx) := NULL;
        ELSE
            -- IF NON SKU item then get the inventory_item_id from fnd_lookup_values
            IF p_nonsku_flag = 'Y'
            THEN
                -- Get Inventory Item
                BEGIN
                    SELECT attribute6
                    INTO   g_line_rec.inventory_item_id(p_line_idx)
                    FROM   fnd_lookup_values
                    WHERE  lookup_type = 'OD_FEES_ITEMS' AND lookup_code = p_item;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        g_line_rec.inventory_item_id(p_line_idx) := NULL;
                END;
            ELSE
                g_line_rec.inventory_item_id(p_line_idx) := get_inventory_item_id(p_item);
            END IF;

            IF g_line_rec.inventory_item_id(p_line_idx) IS NOT NULL
               AND g_line_rec.ship_from_org_id(p_line_idx) IS NOT NULL
            THEN
                BEGIN
                    SELECT inventory_item_id
                    INTO   ln_item_id
                    FROM   mtl_system_items_b
                    WHERE  inventory_item_id = g_line_rec.inventory_item_id(p_line_idx)
                    AND    organization_id = g_line_rec.ship_from_org_id(p_line_idx);
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        set_header_error(p_hdr_idx);
                        set_msg_context(p_entity_code      => 'HEADER',
                                        p_line_ref         => g_line_rec.orig_sys_line_ref(p_line_idx));
                        lc_err_msg :=
                               'Item : '
                            || p_item
                            || 'Not Assigned to Warehouse/Store : '
                            || g_line_rec.ship_from_org_id(p_line_idx);
                        fnd_message.set_name('XXOM',
                                             'XX_OM_INVALID_ITEM_WAREHOUSE');
                        fnd_message.set_token('ATTRIBUTE1',
                                              p_item);
                        fnd_message.set_token('ATTRIBUTE2',
                                              g_org_rec.organization_name(g_header_rec.inv_loc_no(p_hdr_idx)));
                        oe_bulk_msg_pub.ADD;

                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD(lc_err_msg,
                                             1);
                        END IF;
                END;
            END IF;

            -- If failed to derive the item then give error
            IF g_line_rec.inventory_item_id(p_line_idx) IS NULL
            THEN
                g_line_rec.inventory_item(p_line_idx) := p_item;
                set_header_error(p_hdr_idx);
                set_msg_context(p_entity_code      => 'HEADER',
                                p_line_ref         => g_line_rec.orig_sys_line_ref(p_line_idx));
                lc_err_msg :=    'ITEM NOT FOUND FOR  : '
                              || p_item;
                fnd_message.set_name('XXOM',
                                     'XX_OM_FAIL_SKU_DERIVATION');
                fnd_message.set_token('ATTRIBUTE',
                                      p_item);
                oe_bulk_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(lc_err_msg,
                                     1);
                END IF;
            END IF;                                               -- IF G_line_rec.inventory_item_id(p_line_idx) IS NULL
        END IF;                                                                                     -- IF p_item IS NULL
    END validate_item_warehouse;

-- +=======================================================================+
-- | Name  : CLEAR_BAD_ORDERS                                              |
-- | Description      : This procedure will be used by HVOP to clear the   |
-- | data from pl-sql global tables for orders that failed with unexpected |
-- | errors.                                                               |
-- +=======================================================================+
    PROCEDURE clear_bad_orders(
        p_error_entity           IN  VARCHAR2,
        p_orig_sys_document_ref  IN  VARCHAR2)
    IS
        i                        BINARY_INTEGER;
        ln_debug_level  CONSTANT NUMBER         := oe_debug_pub.g_debug_level;
    BEGIN
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Entering the CLEAR_BAD_ORDERS :'
                             || p_error_entity
                             || ' :'
                             || p_orig_sys_document_ref);
        END IF;

        -- Add the BAD order message to message stack
        set_msg_context(p_entity_code      => 'HEADER');
        fnd_message.set_name('XXOM',
                             'XX_OM_FAIL_TO_READ_ORDER');
        fnd_message.set_token('ATTRIBUTE',
                              p_orig_sys_document_ref);
        oe_bulk_msg_pub.ADD;

        -- Check if it is a header record that caused the unexpected error
        IF p_error_entity = 'HEADER'
        THEN
            GOTO skip_to_header;
        END IF;

        -- We need to check all other ENTITY tables for the failed orig_sys_doc ref

        -- Check for the order lines for this BAD order
        i := g_line_rec.orig_sys_document_ref.LAST;

        IF i > 0
        THEN
            WHILE g_line_rec.orig_sys_document_ref(i) = p_orig_sys_document_ref
            LOOP
                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'Found bad line to delete :'
                                     || i);
                END IF;

                -- Delete the Line record
                delete_line_rec(i);

                IF p_error_entity <> 'LINE'
                THEN
                    -- Decrement the line counter
                    g_line_counter :=   g_line_counter
                                      - 1;
                END IF;

                i :=   i
                     - 1;

                IF i = 0
                THEN
                    EXIT;
                END IF;
            END LOOP;
        END IF;

        oe_debug_pub.ADD(   'After line delete :'
                         || i);
        -- Check for the Price adjustments for this BAD order
        i := g_line_adj_rec.orig_sys_document_ref.LAST;

        IF i > 0
        THEN
            WHILE g_line_adj_rec.orig_sys_document_ref(i) = p_orig_sys_document_ref
            LOOP
                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'Found bad Adjustment to delete :'
                                     || i);
                END IF;

                -- Delete the Adjustment record
                delete_adj_rec(i);
                i :=   i
                     - 1;

                IF i = 0
                THEN
                    EXIT;
                END IF;
            END LOOP;
        END IF;

        oe_debug_pub.ADD(   'After ADJ delete :'
                         || i);
        -- Check for the Tenders  for this BAD order
        i := g_payment_rec.orig_sys_document_ref.LAST;

        IF i > 0
        THEN
            WHILE g_payment_rec.orig_sys_document_ref(i) = p_orig_sys_document_ref
            LOOP
                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'Found bad Payment to delete :'
                                     || i);
                END IF;

                -- Delete the Payment record
                delete_payment_rec(i);
                i :=   i
                     - 1;

                IF i = 0
                THEN
                    EXIT;
                END IF;
            END LOOP;
        END IF;

        oe_debug_pub.ADD(   'After payment rec delete :'
                         || i);
        i := g_return_tender_rec.orig_sys_document_ref.LAST;

        IF i > 0
        THEN
            WHILE g_return_tender_rec.orig_sys_document_ref(i) = p_orig_sys_document_ref
            LOOP
                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'Found bad Return Tender to delete :'
                                     || i);
                END IF;

                -- Delete the return tender record
                delete_ret_tender_rec(i);
                i :=   i
                     - 1;

                IF i = 0
                THEN
                    EXIT;
                END IF;
            END LOOP;
        END IF;

        oe_debug_pub.ADD(   'After return tender rec delete :'
                         || i);
        i := g_tender_rec.orig_sys_document_ref.LAST;

        IF i > 0
        THEN
            WHILE g_tender_rec.orig_sys_document_ref(i) = p_orig_sys_document_ref
            LOOP
                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'Found bad Tender to delete :'
                                     || i);
                END IF;

                -- Delete the tender record
                delete_tender_rec(i);
                i :=   i
                     - 1;

                IF i = 0
                THEN
                    EXIT;
                END IF;
            END LOOP;
        END IF;

        oe_debug_pub.ADD(   'After tender rec delete :'
                         || i);

        -- decrement the header counter
        g_header_counter :=   g_header_counter
                            - 1;

        <<skip_to_header>>
        -- Now clear the header record
        i := g_header_rec.orig_sys_document_ref.LAST;

        IF g_header_rec.orig_sys_document_ref(i) = p_orig_sys_document_ref
        THEN
            -- Delete the header record
            delete_header_rec(i);
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Header Count is :'
                             || g_header_rec.orig_sys_document_ref.COUNT);
            oe_debug_pub.ADD('Exiting CLEAR_BAD_ORDERS:');
        END IF;
    END clear_bad_orders;

    PROCEDURE write_to_file(
        p_order_tbl  IN  order_tbl_type)
    IS
        lf_handle     UTL_FILE.file_type;
        lc_file_path  VARCHAR2(100)      := fnd_profile.VALUE('XX_OM_SAS_FILE_DIR');
        lc_record     VARCHAR2(330);
        lc_context    VARCHAR2(32);
    BEGIN
        -- Check if the file is OPEN
        lf_handle := UTL_FILE.fopen(lc_file_path,
                                       g_file_name
                                    || '.unp',
                                    'A');

        -- Start reading the p_order_tbl
        FOR k IN 1 .. p_order_tbl.COUNT
        LOOP
            IF p_order_tbl(k).record_type = '10'
            THEN
                lc_record := SUBSTR(p_order_tbl(k).file_line,
                                    1,
                                    330);
                lc_context := SUBSTR(lc_record,
                                     1,
                                     32);

                IF lc_record IS NOT NULL
                THEN
                    -- Write it to the file
                    UTL_FILE.put_line(lf_handle,
                                      lc_record,
                                      FALSE);
                END IF;

                -- check if it has 11 record
                lc_record := SUBSTR(p_order_tbl(k).file_line,
                                    331,
                                    298);

                IF lc_record IS NOT NULL
                THEN
                    -- Write it to the file
                    UTL_FILE.put_line(lf_handle,
                                         SUBSTR(lc_context,
                                                1,
                                                21)
                                      || '1'
                                      || SUBSTR(lc_context,
                                                23,
                                                10)
                                      || lc_record,
                                      FALSE);
                END IF;

                -- check if it has 12 record
                lc_record := SUBSTR(p_order_tbl(k).file_line,
                                    629,
                                    298);

                IF lc_record IS NOT NULL
                THEN
                    -- Write it to the file
                    UTL_FILE.put_line(lf_handle,
                                         SUBSTR(lc_context,
                                                1,
                                                21)
                                      || '2'
                                      || SUBSTR(lc_context,
                                                23,
                                                10)
                                      || lc_record,
                                      FALSE);
                END IF;

                -- Added by NB for Rel12.3 changes are we are getting 13 record if it fails we have to capture this record.
                -- check if it has 13 record
                lc_record := SUBSTR(p_order_tbl(k).file_line,
                                    927,
                                    298);

                IF lc_record IS NOT NULL
                THEN
                    -- Write it to the file
                    UTL_FILE.put_line(lf_handle,
                                         SUBSTR(lc_context,
                                                1,
                                                21)
                                      || '2'
                                      || SUBSTR(lc_context,
                                                23,
                                                10)
                                      || lc_record,
                                      FALSE);
                END IF;
            ELSIF p_order_tbl(k).record_type = '20'
            THEN
                lc_record := SUBSTR(p_order_tbl(k).file_line,
                                    1,
                                    330);
                lc_context := SUBSTR(lc_record,
                                     1,
                                     32);

                IF lc_record IS NOT NULL
                THEN
                    -- Write it to the file
                    UTL_FILE.put_line(lf_handle,
                                      lc_record,
                                      FALSE);
                END IF;

                -- check if it has 21 record
                lc_record := SUBSTR(p_order_tbl(k).file_line,
                                    331,
                                    298);

                IF lc_record IS NOT NULL
                THEN
                    -- Write it to the file
                    UTL_FILE.put_line(lf_handle,
                                         SUBSTR(lc_context,
                                                1,
                                                21)
                                      || '1'
                                      || SUBSTR(lc_context,
                                                23,
                                                10)
                                      || lc_record,
                                      FALSE);
                END IF;
            ELSIF p_order_tbl(k).record_type IN('40','41','30')
            THEN
                lc_record := SUBSTR(p_order_tbl(k).file_line,
                                    1,
                                    330);

                IF lc_record IS NOT NULL
                THEN
                    -- Write it to the file
                    UTL_FILE.put_line(lf_handle,
                                      lc_record,
                                      FALSE);
                END IF;
            END IF;
        END LOOP;

        UTL_FILE.fflush(lf_handle);
        UTL_FILE.fclose(lf_handle);
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Error While writing Order Record to file '
                              || g_file_name
                              || '.unp'
                              || SQLERRM);
            NULL;
    END write_to_file;

    FUNCTION get_ord_source_name(
        p_order_source_id  IN  NUMBER)
        RETURN VARCHAR2
    IS
-- +===================================================================+
-- | Name  : Get_ord_source_name                                       |
-- | Description     : To derive order_source_name by passing order    |
-- |                   source id                                       |
-- |                                                                   |
-- | Parameters     : p_order_source_id  IN -> pass order source id    |
-- |                                                                   |
-- | Return         : order_source_name                                |
-- +===================================================================+
        lc_order_source_name  VARCHAR2(80);
    BEGIN
        SELECT NAME
        INTO   lc_order_source_name
        FROM   oe_order_sources
        WHERE  order_source_id = p_order_source_id;

        RETURN(lc_order_source_name);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END get_ord_source_name;

-- +===================================================================+
-- | Name  : get_serial_no_for_atr                                     |
-- | Description     : To derive serial_no count by passing po number  |
-- |                   for customer type 'C'                           |
-- |                                                                   |
-- | Parameters     : p_order_source_id  IN -> pass order source id    |
-- |                                                                   |
-- | Return         : order_source_name                                |
-- +===================================================================+
    FUNCTION get_serial_no_for_atr(
        p_serial_no     VARCHAR2,
        p_order_number  VARCHAR2,
        p_ordered_date  DATE)
        RETURN NUMBER
    IS
        ln_serial_count  NUMBER := 0;
    BEGIN
        -- Raj modified the program type on 8/15/13
        SELECT DECODE(program_type,
                      'ATR', 1,
                      'MPS', 2,
                      'Call In',  2,
                      'MPS-Hold', 2,                      
                      0) cnt
        INTO   ln_serial_count
        FROM   xx_cs_mps_device_b
        WHERE  serial_no = p_serial_no;

        --UPDATE toner order number and date
        IF ln_serial_count > 0
        THEN
            UPDATE xx_cs_mps_device_details
            SET toner_order_number = SUBSTR(p_order_number,
                                            1,
                                            9),
                toner_order_date = p_ordered_date
            WHERE  serial_no = p_serial_no AND NVL(toner_order_number,
                                                   '-99') = '-99' AND NVL(request_number,
                                                                          '-99') = '-99';
        END IF;

        RETURN ln_serial_count;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN(0);
        WHEN OTHERS
        THEN
            RETURN(0);
    END get_serial_no_for_atr;

-- +===================================================================+
-- | Name  : get_mps_retail                                            |
-- | Description     : To derive MPS retail cost for passing serialno  |
-- |                   and item                                        |
-- |                                                                   |
-- | Parameters     : p_serial_no  IN -> pass order source id          |
-- |                                                                   |
-- | Return         : MPS Retail                                       |
-- +===================================================================+
    FUNCTION get_mps_retail(
        p_serial_no     VARCHAR2,
        p_order_number  VARCHAR2,
        p_item          VARCHAR2)
        RETURN NUMBER
    IS
        ln_retail_cost  NUMBER;
        lc_color_label  VARCHAR2(50);
    BEGIN
        BEGIN
            SELECT toner_order_total,
                   supplies_label
            INTO   ln_retail_cost,
                   lc_color_label
            FROM   xx_cs_mps_device_details
            WHERE  serial_no = p_serial_no
            AND    toner_order_number = SUBSTR(p_order_number,
                                               1,
                                               9)
            AND    p_item =
                       DECODE(p_item,
                              sku_option_1, sku_option_1,
                              sku_option_2, sku_option_2,
                              sku_option_3, sku_option_3);
        EXCEPTION
            WHEN OTHERS
            THEN
                ln_retail_cost := NULL;
        END;

        IF ln_retail_cost = 0
        THEN
            ln_retail_cost := 0.01;
        END IF;

        RETURN ln_retail_cost;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN(NULL);
        WHEN OTHERS
        THEN
            RETURN(NULL);
    END get_mps_retail;
-- +===================================================================+
-- | Name  : is_appid_need_ordertype                                   |
-- | Description     : To derive Order type translations for APP ID    |
-- |                                                                   |
-- |                                                                   |
-- | Parameters     : p_app_id      IN  -> pass app_id                 |
-- |                  p_param_value OUT -> retusn Header Order type    |
-- |                  p_ltype_value OUT -> retusn line Order type      |
-- |                                                                   |
-- | Return         : True or false                                    |
-- +===================================================================+
FUNCTION is_appid_need_ordertype (p_app_id       IN   VARCHAR2
                                 ,p_order_source IN   VARCHAR2 
                                  ,x_otype_value  OUT  VARCHAR2
                                  ,x_ltype_value  OUT  VARCHAR2
								 )
RETURN BOOLEAN									
IS
BEGIN
     SELECT target_value1
           ,target_value2
       INTO x_otype_value
           ,x_ltype_value 
       FROM xx_fin_translatedefinition xft,
            xx_fin_translatevalues val
      WHERE xft.Translate_Id     = Val.Translate_Id
        AND xft.Translation_Name = 'XX_OD_HVOP_APPID_ORDERTYP'
        AND source_value1        = p_app_id
		AND DECODE(source_value2,NULL,'1',source_value2) = DECODE(p_order_source,null,'1',p_order_source);          

	oe_debug_pub.ADD(   ' In is_appid_need_ordertype procedure ');
    oe_debug_pub.ADD(   ' x_otype_value : '|| x_otype_value);
	oe_debug_pub.ADD(   ' x_ltype_value : '|| x_ltype_value);

	RETURN TRUE;	
EXCEPTION
WHEN NO_DATA_FOUND
THEN
	oe_debug_pub.ADD( 'No Data found exception in is_appid_need_ordertype function '||SQLERRM);
	RETURN FALSE;
WHEN OTHERS
THEN 
    oe_debug_pub.ADD( 'exception in is_appid_need_ordertype function '||SQLERRM);
    RETURN FALSE;
END is_appid_need_ordertype;	
END XX_OM_SACCT_CONC_PKG;
/
