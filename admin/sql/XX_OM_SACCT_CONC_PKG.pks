create or replace PACKAGE      xx_om_sacct_conc_pkg
AS                                                                             
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                  Office Depot                                             |
-- +===========================================================================+
-- | Name  : XX_OM_SACCT_CONC_PKG (XXOMSAIMPS.PKS)                             |
-- | Rice ID: I1272                                                            |
-- | Description      : This Program will load all sales orders from           |
-- |                    Legacy System(SACCT) into EBIZ                         |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version Date        Author            Remarks                              |
-- |======= =========== ================= =====================================|
-- |DRAFT1A 06-APR-2007 Bapuji Nanapaneni Initial draft version                |
-- |   1.0  21-JUN-2007                   Modified the code to                 |
-- |                                      add user_item_description            |
-- |   1.1  22-JUN-2007 Manish Chavan     Added code to identify store         |
-- |                                      customer by Store No:Country         |
-- |                                      Added function to convert UOM        |
-- |   1.2  31-JUL-2007 Manish Chavan     Changed data type for G_Sales_Rep    |
-- |   1.3  11-SEP-2007 Bapuji Nanapaneni Added gsa_flag to line record        |
-- |   1.4  17-Feb-2010 Bapuji Nanapaneni Added get_salesrep_for_legacyrep     |
-- |   1.5  07-FEB-2011 Bapuji Nanapaneni Added order_receipt_type record and  |
-- |                                      Get_ord_source_name for Rel 11.2     |
-- |   1.6  27-JUL-2011 Bapuji Nanapaneni Added SR_number for Rel 11.4         |
-- |   1.7  25-APR-2012 Ray Strauss       Added order_source_cd   and          |
-- |                                      g_im_pay_term_id                     |
-- |   1.8  19-JUN-2012 Bapuji N          updated file line to 1400 bytes for  |
-- |                                      adding  record 13                    |
-- |   1.9  28-OCT-2012 Bapuji N           Added ATR Flag for header record    |
-- |   2.0  25-JAN-2013 Bapuji N          Added device Serial Num for HDR REC  |
-- |   2.1  24-MAY-2013 Bapuji N          Added app_id to header rec           |
-- |   2.2  28-Aug-2013 Edson M           Added new encryption solution        |
-- |   2.3  19-NOV-2013 Raj J             Added MPS Retail to LINE rec         |
-- |                                      Retrofitted R12                      |
-- |   3.0  04-Feb-2013 Edson M.          Changes for Defect 27883             |
-- |   3.1  14-May-2014 Edson M.          Core indicator changes               |
-- |   4.0  25-Jun-2014 Vivek S.          RCC changes                          |
-- |   5.0  07-JUL-2014 Arun G            added rcc_Transaction_type flag      |
-- |   6.0  02-JAN-2015 Avinash Baddam    Added external_transaction_number    |
-- |                                      to header record. mpl_order_id in    |
-- |					  ORDT	                               |
-- |   7.0  15-Apr-2015 Arun Gannarapu    Tokenization/EMV changes             |
-- |   8.0  22-SEP-2015 Arun Gannarapu    Made changes to Line level tax       |
-- |                                      Defect 35944                         |
-- |   9.0  08-JAN-2016 Anoop Salim       Added procedure to capture line      |
-- |				 	 level tax Defect 36885                |
-- |  10.0  18-FEb-2016 Arun Gannarapu    Made changes to masterpass 37172     |
-- |  11.0  06-Jun-2016 Arun Gannarapu    Made changes for kitting   37676     |
-- |  12.0  28-Jul-2017 Venkata Battu     Made changes for Biz Project         |  
-- |  13.0  18-Jan-2018 Arun G            Made changes for TECZONE Defect#44139|  
-- |  14.0  14-Nov-2018 Arun G            Made changes for Bill complete       |
-- |  15.0  28-NOV-2019 Arun G            Made changes for Service contracts   |
-- |  16.0  05-SEP-2019 Arun G            Made changes for Card on File        |
-- |  17.0  15-OCT-2019 Arun G            Made changes for Tariff phase 2      |
-- +===========================================================================+
-- +===========================================================================+

    -----------------------------------------------------------------
-- DATA TYPES (RECORD/TABLE TYPES)
-----------------------------------------------------------------

    --Convert all to index by binary_integer;
    TYPE t_date IS TABLE OF DATE
        INDEX BY BINARY_INTEGER;

    TYPE t_num IS TABLE OF NUMBER
        INDEX BY BINARY_INTEGER;

    TYPE t_num_2 IS TABLE OF NUMBER(10, 2)
        INDEX BY BINARY_INTEGER;

    TYPE t_v1 IS TABLE OF VARCHAR2(01)
        INDEX BY BINARY_INTEGER;

    TYPE t_v2 IS TABLE OF VARCHAR2(02)
        INDEX BY BINARY_INTEGER;

    TYPE t_v3 IS TABLE OF VARCHAR2(03)
        INDEX BY BINARY_INTEGER;

    TYPE t_v4 IS TABLE OF VARCHAR2(04)
        INDEX BY BINARY_INTEGER;

    TYPE t_v5 IS TABLE OF VARCHAR2(05)
        INDEX BY BINARY_INTEGER;

    TYPE t_v8 IS TABLE OF VARCHAR2(08)
        INDEX BY BINARY_INTEGER;

    TYPE t_v10 IS TABLE OF VARCHAR2(10)
        INDEX BY BINARY_INTEGER;

    TYPE t_v11 IS TABLE OF VARCHAR2(11)
        INDEX BY BINARY_INTEGER;

    TYPE t_v15 IS TABLE OF VARCHAR2(15)
        INDEX BY BINARY_INTEGER;

    TYPE t_v20 IS TABLE OF VARCHAR2(20)
    INDEX BY BINARY_INTEGER;

    TYPE t_v25 IS TABLE OF VARCHAR2(25)
        INDEX BY BINARY_INTEGER;

    TYPE t_v30 IS TABLE OF VARCHAR2(30)
        INDEX BY BINARY_INTEGER;

    TYPE t_v40 IS TABLE OF VARCHAR2(40)
        INDEX BY BINARY_INTEGER;

    TYPE t_v50 IS TABLE OF VARCHAR2(50)
        INDEX BY BINARY_INTEGER;

    TYPE t_v60 IS TABLE OF VARCHAR2(60)
        INDEX BY BINARY_INTEGER;

    TYPE t_v80 IS TABLE OF VARCHAR2(80)
        INDEX BY BINARY_INTEGER;

    TYPE t_v100 IS TABLE OF VARCHAR2(100)
        INDEX BY BINARY_INTEGER;

    TYPE t_v150 IS TABLE OF VARCHAR2(150)
        INDEX BY BINARY_INTEGER;

    TYPE t_v240 IS TABLE OF VARCHAR2(240)
        INDEX BY BINARY_INTEGER;

    TYPE t_v250 IS TABLE OF VARCHAR2(250)
        INDEX BY BINARY_INTEGER;

    TYPE t_v360 IS TABLE OF VARCHAR2(360)
        INDEX BY BINARY_INTEGER;

    TYPE t_v1000 IS TABLE OF VARCHAR2(1000)
        INDEX BY BINARY_INTEGER;

    TYPE t_v2000 IS TABLE OF VARCHAR2(2000)
        INDEX BY BINARY_INTEGER;

    TYPE t_bi IS TABLE OF BINARY_INTEGER
        INDEX BY BINARY_INTEGER;

    TYPE t_v50_iv50 IS TABLE OF VARCHAR2(50)
        INDEX BY VARCHAR2(50);

    TYPE t_v7_ib IS TABLE OF VARCHAR2(7)
        INDEX BY BINARY_INTEGER;

    TYPE t_v30_iv30 IS TABLE OF VARCHAR2(30)
        INDEX BY VARCHAR2(30);

    TYPE t_v80_iv30 IS TABLE OF VARCHAR2(80)
        INDEX BY VARCHAR2(30);

    TYPE t_num_iv30 IS TABLE OF NUMBER
        INDEX BY VARCHAR2(30);

    TYPE t_v3_iv2 IS TABLE OF VARCHAR2(3)
        INDEX BY VARCHAR2(2);

    TYPE t_v240_iv30 IS TABLE OF VARCHAR2(240)
        INDEX BY VARCHAR2(30);

    TYPE t_num_iv10 IS TABLE OF NUMBER
        INDEX BY VARCHAR2(10);

-- Define Store rec type that will hold organization_id and country code
    TYPE org_rec_type IS RECORD(
        organization_id    t_num_iv30,
        country_code       t_v30_iv30,
        organization_name  t_v240_iv30,
        organization_type  t_v30_iv30
    );

-- Define all batch globals
    g_batch_counter               BINARY_INTEGER;
    g_org_id             CONSTANT NUMBER                    := fnd_profile.VALUE('ORG_ID');
    g_list_header_id              NUMBER;
    g_list_line_id                NUMBER;
    g_request_id                  NUMBER;
    g_batch_id                    NUMBER;
    g_accounting_rule_id          t_num;
    g_header_counter              BINARY_INTEGER            := 0;
    g_line_counter                BINARY_INTEGER            := 0;
    g_header_count                BINARY_INTEGER            := 0;
    g_line_count                  BINARY_INTEGER            := 0;
    g_adj_count                   BINARY_INTEGER            := 0;
    g_payment_count               BINARY_INTEGER            := 0;
    g_header_tot_amt              NUMBER                    := 0;
    g_acct_order_tot              NUMBER                    := 0;
    g_tax_tot_amt                 NUMBER                    := 0;
    g_line_tot_amt                NUMBER                    := 0;
    g_adj_tot_amt                 NUMBER                    := 0;
    g_payment_tot_amt             NUMBER                    := 0;
    g_cashback_total              NUMBER                    := 0;
    g_im_pay_term_id              NUMBER;
    g_process_date                DATE;
    g_line_nbr_counter            BINARY_INTEGER;
    g_order_line_tax_ctr          BINARY_INTEGER;
    g_rma_line_tax_ctr            BINARY_INTEGER;
    g_curr_top_line_id            NUMBER;
    g_ou_country                  VARCHAR2(3);
--Session global to set the BULK mode
    g_mode                        VARCHAR2(10);
-- Payment Term for deposit orders
    g_deposit_term_id             NUMBER;
    g_has_debit_card              BOOLEAN;
    g_file_name                   VARCHAR2(80);
    g_error_count                 BINARY_INTEGER;
    g_file_run_count              BINARY_INTEGER;
-- Define Globals for local cache
    g_pay_method_code             t_v30_iv30;
    g_cc_code                     t_v80_iv30;
    g_payment_term                t_num;
    g_return_reason               t_v30_iv30;
    g_sales_channel               t_v50_iv50;
    g_sales_rep                   t_num_iv10;
    g_order_source                t_v50_iv50;
    g_ship_method                 t_v30_iv30;
    g_ret_actcatreason            t_v30_iv30;
    g_uom_code                    t_v3_iv2;
    g_org_rec                     org_rec_type;
-- Line Number Sequence global
    g_line_id                     t_num;
    g_line_id_seq_ctr             BINARY_INTEGER;
-- Global to store the sold_to_org_id for a store customer
    g_sold_to_org_id              t_num_iv30;
    g_party_name                  t_v80_iv30;


    TYPE ord_tot_mismatch_rec_type IS RECORD(
        orig_sys_document_ref  t_v50,
        order_source_id        t_num,
        MESSAGE                t_v240
    );

    g_ord_tot_mismatch_rec        ord_tot_mismatch_rec_type;

    TYPE header_match_rec IS RECORD(
        orig_sys_document_ref  t_v50,
        header_id              t_num,
        order_source_id        t_num,
        curr_code              t_v30,
        hold_id                t_num,
        hold_source_id         t_num,
        order_hold_id          t_num,
        sold_to_org_id         t_num,
        invoice_to_org_id      t_num,
        order_number           t_num,
        ship_from_org_id       t_num
    );

-----------------------------------------------------------------
-- HEADER RECORD
-----------------------------------------------------------------
    TYPE header_rec_type IS RECORD(
        orig_sys_document_ref     t_v50,
        order_source_id           t_num,
        change_sequence           t_v50,
        order_category            t_v50,
        org_id                    t_num,
        ordered_date              t_date,
        order_type_id             t_num,
        legacy_order_type         t_v1,
        price_list_id             t_num,
        transactional_curr_code   t_v3,
        salesrep_id               t_num,
        sales_channel_code        t_v30,
        shipping_method_code      t_v30,
        shipping_instructions     t_v2000,
        customer_po_number        t_v50,
        sold_to_org_id            t_num,
        ship_from_org_id          t_num,
        invoice_to_org_id         t_num,
        sold_to_contact_id        t_num,
        ship_to_org_id            t_num,
        ship_to_org               t_v360,
        ship_from_org             t_v360,
        sold_to_org               t_v360,
        invoice_to_org            t_v240,
        drop_ship_flag            t_v1,
        booked_flag               t_v1,
        operation_code            t_v30,
        error_flag                t_v1,
        ready_flag                t_v1,
        payment_term_id           t_num,
        tax_value                 t_num_2,
        customer_po_line_num      t_v50,
        category_code             t_v30,
        ship_date                 t_date,
        sas_sale_date             t_date,
        return_reason             t_v30,
        pst_tax_value             t_num_2,
        return_orig_sys_doc_ref   t_v50,
        created_by                t_num,
        creation_date             t_date,
        last_update_date          t_date,
        last_updated_by           t_num,
        batch_id                  t_num,
        request_id                t_num,
        created_by_store_id       t_num,
        paid_at_store_id          t_num,
        spc_card_number           t_v240,
        placement_method_code     t_v30,
        advantage_card_number     t_v240,
        created_by_id             t_v30,
        delivery_code             t_v30,
        delivery_method           t_v30,
        release_number            t_v240,
        cust_dept_no              t_v240,
        cust_dept_description     t_v30,
        desk_top_no               t_v240,
        comments                  t_v240,
        start_line_index          t_bi,
        paid_at_store_no          t_v50,
        accounting_rule_id        t_num,
        sold_to_contact           t_v360,
        header_id                 t_num,
        org_order_creation_date   t_date,
        return_act_cat_code       t_v100,
        salesrep                  t_v240,
        order_source              t_v240,
        sales_channel             t_v80,
        shipping_method           t_v80,
        deposit_amount            t_num,
        gift_flag                 t_v1,
        legacy_cust_name          t_v360,
        inv_loc_no                t_v50,
        ship_to_sequence          t_v5,
        ship_to_address1          t_v240,
        ship_to_address2          t_v240,
        ship_to_city              t_v60,
        ship_to_state             t_v60,
        ship_to_country           t_v60,
        ship_to_zip               t_v60,
        ship_to_county            t_v60,
        order_number              t_num,
        tax_exempt_number         t_v80,
        tax_exempt_flag           t_v1,
        tax_exempt_reason         t_v30,
        pos_txn_number            t_v30,
        ship_to_name              t_v100,
        bill_to_name              t_v100,
        cust_contact_name         t_v360,
        cust_pref_phone           t_v50,
        cust_pref_phextn          t_v50,
        gsa_flag                  t_v1,
        deposit_hold_flag         t_v1,
        ineligible_for_hvop       t_v1,
        tax_rate                  t_num,
        is_reference_return       t_v1,
        order_total               t_num,
        commisionable_ind         t_v1,
        order_action_code         t_v30,
        order_start_time          t_date,
        order_end_time            t_date,
        order_taxable_cd          t_v30,
        override_delivery_chg_cd  t_v30,
        price_cd                  t_v1,
        ship_to_geocode           t_v30,
        tran_number               t_v60,
        aops_geo_code             t_v30,
        tax_exempt_amount         t_num,
        sr_number                 t_v30,                                                    /* Added for 11.4 Release */
        order_source_cd           t_v1,
        cust_pref_email           t_v100,                                                   /* Added for 12.3 Release */
        atr_order_flag            t_v30,                                                   /* Added for 12.5 Release */
        device_serial_num         t_v30,                                                   /* Added for 13.1 Release */
        app_id                    t_v30,                                                    /* Added for 13.3 Release */
        rcc_transaction           t_v1,                                                     /* Added for RCC release */
        external_transaction_number  t_v100,						                        /* Added for AMZ Recon */
        freight_tax_rate           t_num,                                                 /* Added for Line Level tax */
        freight_tax_amount         t_num,                                                 /* Added for Line Level tax */
        bill_level                 t_v1,                                                  /* Added for Kitting */
        bill_override_flag         t_v1,                                                  /* Added for kitting */
        appid_ordertype_value      t_v30,                                                 
        appid_linetype_value       t_v30,
        appid_base_ordertype       t_v1,
        bill_complete_flag         t_v1,
        parent_order_number        t_v30,
        cost_center_split          t_v1,
        invoicing_rule_id          t_num
    );

/* Global Record  Declaration for Header */
    g_header_rec                  header_rec_type;

-----------------------------------------------------------------
-- LINE RECORD
-----------------------------------------------------------------
    TYPE line_rec_type IS RECORD(
        orig_sys_document_ref    t_v50,
        order_source_id          t_num,
        change_sequence          t_v50,
        org_id                   t_num,
        orig_sys_line_ref        t_v50,
        ordered_date             t_date,
        line_number              t_num,
        line_type_id             t_num,
        inventory_item_id        t_num,
        source_type_code         t_v30,
        schedule_ship_date       t_date,
        actual_ship_date         t_date,
        schedule_arrival_date    t_date,
        actual_arrival_date      t_date,
        ordered_quantity         t_num,
        order_quantity_uom       t_v3,
        shipped_quantity         t_num,
        sold_to_org_id           t_num,
        ship_from_org_id         t_num,
        ship_to_org_id           t_num,
        invoice_to_org_id        t_num,
        ship_to_contact_id       t_num,
        sold_to_contact_id       t_num,
        invoice_to_contact_id    t_num,
        drop_ship_flag           t_v1,
        price_list_id            t_num,
        unit_list_price          t_num,
        unit_selling_price       t_num,
        calculate_price_flag     t_v1,
        tax_code                 t_v50,
        tax_date                 t_date,
        tax_value                t_num,
        shipping_method_code     t_v30,
        salesrep_id              t_num,
        return_reason_code       t_v30,
        customer_po_number       t_v50,
        release_number           t_v240,
        cust_dept_no             t_v240,
        cust_dept_description    t_v30,
        desk_top_no              t_v240,
        operation_code           t_v30,
        error_flag               t_v1,
        shipping_instructions    t_v2000,
        return_context           t_v30,
        return_attribute1        t_v240,
        return_attribute2        t_v240,
        customer_item_name       t_v2000,
        customer_item_id         t_num,
        customer_item_id_type    t_v30,
        line_category_code       t_v30,
        tot_tax_value            t_num_2,
        customer_line_number     t_v50,
        created_by               t_num,
        creation_date            t_date,
        last_update_date         t_date,
        last_updated_by          t_num,
        request_id               t_num,
        batch_id                 t_num,
        legacy_list_price        t_num_2,
        vendor_product_code      t_v240,
        contract_details         t_v240,
        item_comments            t_v240,
        line_comments            t_v2000,
        taxable_flag             t_v1,
        sku_dept                 t_v240,
        item_source              t_v240,
        average_cost             t_num,
        po_cost                  t_num,
        canada_pst               t_v50,
        return_act_cat_code      t_v100,
        return_reference_no      t_v50,
        return_ref_line_no       t_v50,
        back_ordered_qty         t_num,
        org_order_creation_date  t_date,
        wholesaler_item          t_v240,
        header_id                t_num,
        line_id                  t_num,
        payment_term_id          t_num,
        inventory_item           t_v2000,
        schedule_status_code     t_v30,
        user_item_description    t_v240,
        config_code              t_v30,
        ext_top_model_line_id    t_num,
        ext_link_to_line_id      t_num,
        sas_sale_date            t_date,
        aops_ship_date           t_date,
        calc_arrival_date        t_date,
        ret_ref_header_id        t_num,
        ret_ref_line_id          t_num,
        tax_exempt_number        t_v80,
        tax_exempt_flag          t_v1,
        tax_exempt_reason        t_v30,
        gsa_flag                 t_v1,                                                                    --Added By NB
        consignment_bank_code    t_v2,
        waca_item_ctr_num        t_v30,
        orig_selling_price       t_num,
        price_cd                 t_v1,
        price_change_reason_cd   t_v30,
        price_prefix_cd          t_v30,
        commisionable_ind        t_v1,
        unit_orig_selling_price  t_num,
        mps_toner_retail         t_num,
        core_type_indicator      t_v240,
        upc_code                 t_v15,
        price_type               t_v1,
        external_sku             t_v8,
        line_tax_rate            t_num, 
        line_tax_amount          t_num,
        kit_sku                  t_v50,
        kit_qty                  t_num,
        kit_vpc                  t_v50,
        kit_dept                 t_v50,
        kit_seqnum               t_num,
        kit_parent               t_v1,
        service_end_date         t_date,
        service_start_date       t_date,
        accounting_rule_id       t_num,
        invoicing_rule_id        t_num,
        fee_reference_line_num   t_num
    );

/* Global Record Declaration for  Line */
    g_line_rec                    line_rec_type;

-----------------------------------------------------------------
-- LINE ADJUSTMENTS RECORD
-----------------------------------------------------------------
    TYPE line_adj_rec_type IS RECORD(
        orig_sys_document_ref     t_v50,
        order_source_id           t_num,
        org_id                    t_num,
        orig_sys_line_ref         t_v50,
        orig_sys_discount_ref     t_v50,
        sold_to_org_id            t_num,
        change_sequence           t_v50,
        automatic_flag            t_v1,
        list_header_id            t_num,
        list_line_id              t_num,
        list_line_type_code       t_v30,
        applied_flag              t_v1,
        operand                   t_num,
        arithmetic_operator       t_v30,
        pricing_phase_id          t_num,
        adjusted_amount           t_num,
        inc_in_sales_performance  t_v1,
        operation_code            t_v30,
        error_flag                t_v1,
        request_id                t_num,
        CONTEXT                   t_v30,
        attribute6                t_v240,
        attribute7                t_v240,
        attribute8                t_v240,
        attribute9                t_v240,
        attribute10               t_v240
    );

/* Global Record Declaration   Line Adjustments*/
    g_line_adj_rec                line_adj_rec_type;

-- Added as per defect 36885 Ver 9.0 
-----------------------------------------------------------------
-- LINE TAX RECORD
-----------------------------------------------------------------    
   TYPE line_tax_rec_type IS RECORD(
           orig_sys_document_ref     t_v50,
           line_tax_rate             t_num,
           line_tax_amount           t_num,
           kit_sku                   t_v50,
           kit_qty                   t_num,
           kit_vpc                   t_v50,
           kit_dept                  t_v50,
           kit_seqnum                t_num
    ); 

/*   Global Record Declaration for  Line tax */ 
   g_line_tax_rec                line_tax_rec_type;

-----------------------------------------------------------------
-- PAYMENTS RECORD
-----------------------------------------------------------------
    TYPE payment_rec_type IS RECORD(
        orig_sys_document_ref        t_v50,
        order_source_id              t_num,
        orig_sys_payment_ref         t_v50,
        org_id                       t_num,
        payment_type_code            t_v30,
        payment_collection_event     t_v30,
        prepaid_amount               t_num,
        credit_card_number           t_v80,
        credit_card_holder_name      t_v80,
        credit_card_expiration_date  t_date,
        credit_card_code             t_v80,
        credit_card_approval_code    t_v80,
        credit_card_approval_date    t_date,
        check_number                 t_v80,
        payment_amount               t_num,
        operation_code               t_v30,
        error_flag                   t_v1,
        receipt_method_id            t_num,
        payment_number               t_num,
        CONTEXT                      t_v30,
        credit_card_number_enc       t_v240,
        IDENTIFIER                   t_v240,
        attribute6                   t_v240,
        attribute7                   t_v240,
        attribute8                   t_v240,
        attribute9                   t_v240,
        attribute10                  t_v240,
        attribute11                  t_v240,
        attribute12                  t_v240,
        attribute13                  t_v240,
        attribute15                  t_v240,
        sold_to_org_id               t_num,
        sold_to_org                  t_v240,
        transaction_number           t_v30,
        payment_set_id               t_num,
        header_id                    t_num,
        payment_level_code           t_v30,
        order_curr_code              t_v30,
        invoice_to_org_id            t_num,
        order_number                 t_num,
        avail_balance                t_num,
        currency_code                t_v30,
        store_location               t_v10,
        tangible_id                  t_v80,
        paid_at_store_id             t_num,
        ship_from_org_id             t_num,
        receipt_date                 t_date,
        cc_entry_mode                t_v1,
        cvv_resp_code                t_v1,
        avs_resp_code                t_v1,
        auth_entry_mode              t_v1,
        i1025_status                 t_v30,
        single_pay_ind               t_v1,
        trxn_extension_id            t_num,
        attribute3                   t_v240,
        attribute14                  t_v240,
        attribute2                   t_v240
    );

/* Payment Global Record Declaration */
    g_payment_rec                 payment_rec_type;

-----------------------------------------------------------------
-- Tender RECORD
-----------------------------------------------------------------
    TYPE return_tender_rec_type IS RECORD(
        orig_sys_document_ref        t_v50,
        orig_sys_payment_ref         t_v50,
        order_source_id              t_num,
        payment_number               t_num,
        payment_type_code            t_v30,
        credit_card_code             t_v80,
        credit_card_number           t_v80,
        credit_card_holder_name      t_v360,
        credit_card_expiration_date  t_date,
        credit_amount                t_num,
        request_id                   t_num,
        sold_to_org_id               t_num,
        cc_auth_manual               t_v1,
        merchant_nbr                 t_v11,
        cc_auth_ps2000               t_v50,
        allied_ind                   t_v1,
        receipt_method_id            t_num,
        cc_mask_number               t_v30,
        od_payment_type              t_v2,
        IDENTIFIER                   t_v240,
        token_flag                   t_v1,
        emv_card                     t_v1,
        emv_terminal                 t_v2,
        emv_transaction              t_v1, 
        emv_offline                  t_v1,
        emv_fallback                 t_v1,  
        emv_tvr                      t_v10,
        wallet_type                  t_v2,
        wallet_id                    t_v30,
        credit_card_approval_code    t_v30
    );

/* Tender Global Record Declaration */
    g_return_tender_rec           return_tender_rec_type;

-----------------------------------------------------------------
-- Tender RECORD related to record 41
-----------------------------------------------------------------

   TYPE tender_rec_type IS RECORD(		
	orig_sys_document_ref        t_v50,	
	orig_sys_payment_ref         t_v50,
	order_source_id              t_num, 
      --request_id                   t_num, 
        batch_id                     t_num,
	routing_line1               t_v20,
	routing_line2               t_v20, 
	routing_line3               t_v20,
	routing_line4               t_v20

   );

/* Tender Global Record Declaration for Record41*/
    g_tender_rec                 tender_rec_type;

---------------------------------------------------------------
-- Sales Credits RECORD
-----------------------------------------------------------------
    TYPE sale_credits_rec_type IS RECORD(
        orig_sys_document_ref     t_v50,
        order_source_id           t_num,
        change_sequence_code      t_v50,
        org_id                    t_num,
        orig_sys_credit_ref       t_v50,
        salesrep_id               t_num,
        sales_credit_type_id      t_num,
        quota_flag                t_v1,
        PERCENT                   t_num,
        operation_code            t_v30,
        sales_group_id            t_num,
        sold_to_org_id            t_num,
        request_id                t_num,
        sales_group_updated_flag  t_v1
    );

/* Tender Global Record Declaration */
    g_sale_credits_rec            sale_credits_rec_type;

/* Record Type Declaration */
    TYPE order_rec_type IS RECORD(
        record_type  VARCHAR2(5),
        file_line    VARCHAR2(1400)
    );

    g_rec_type                    order_rec_type;

    TYPE order_tbl_type IS TABLE OF order_rec_type
        INDEX BY BINARY_INTEGER;

/* RECODR TYPE DECLARATION FOR HEADER INFO TO CHILD */
    TYPE header_to_child_type IS RECORD(
        orig_sys_document_ref  t_v50,
        order_source_id        t_num,
        sold_to_org_id         t_num
    );

    g_header_to_child             header_to_child_type;

/* RECORD TYPE DECLARATION FOR ORDER RECEIPT DETAILS */
    TYPE order_receipt_type IS RECORD(
        order_payment_id             t_num,
        order_number                 t_num,
        orig_sys_document_ref        t_v50,
        orig_sys_payment_ref         t_v50,
        payment_number               t_num,
        header_id                    t_num,
        currency_code                t_v15,
        order_source                 t_v240,
        order_type                   t_v240,
        cash_receipt_id              t_num,
        receipt_number               t_v30,
        customer_id                  t_num,
        store_number                 t_v30,
        payment_type_code            t_v30,
        credit_card_code             t_v80,
        IDENTIFIER                   t_v240,
        credit_card_number           t_v80,
        credit_card_holder_name      t_v80,
        credit_card_expiration_date  t_date,
        payment_amount               t_num,
        receipt_method_id            t_num,
        cc_auth_manual               t_v240,
        merchant_number              t_v240,
        cc_auth_ps2000               t_v240,
        allied_ind                   t_v240,
        payment_set_id               t_num,
        process_code                 t_v80,
        cc_mask_number               t_v240,
        od_payment_type              t_v30,
        check_number                 t_num,
        org_id                       t_num,
        request_id                   t_num,
        imp_file_name                t_v80,
        creation_date                t_date,
        created_by                   t_num,
        last_update_date             t_date,
        last_updated_by              t_num,
        last_update_login            t_num,
        remitted                     t_v1,
        MATCHED                      t_v1,
        ship_from                    t_v30,
        receipt_status               t_v50,
        customer_receipt_reference   t_v80,
        credit_card_approval_code    t_v30,
        credit_card_approval_date    t_date,
        customer_site_billto_id      t_num,
        receipt_date                 t_date,
        sale_type                    t_v30,
        additional_auth_codes        t_v240,
        process_date                 t_date,
        single_pay_ind               t_v1,
        cleared_date                 t_date,
        mpl_order_id		     t_v100,
        token_flag                   t_v1,
        emv_card                     t_v1,
        emv_terminal                 t_v2,
        emv_transaction              t_v1, 
        emv_offline                  t_v1,
        emv_fallback                 t_v1,  
        emv_tvr                      t_v10,
        wallet_type                  t_v2,
        wallet_id                    t_v30
    );

/* receipt dtl Global Record Declaration */
    g_order_receipt_rec           order_receipt_type;

/* RECORD TYPE DECLARATION FOR DEPOSIT DETAILS */
    TYPE legacy_dep_dtls_type IS RECORD(
        transaction_number     t_v80,
        order_source_id        t_num,
        orig_sys_document_ref  t_v80,
        order_total            t_num,
        single_pay_ind         t_v1
    );

    g_legacy_dep_dtls_rec         legacy_dep_dtls_type;

-- +=====================================================================+
-- | Name  : Process_Child                                               |
-- | Description     : The Process Child is called by Upload Data        |
-- |                   Multiple Childs request are submitted depend on   |
-- |                   p_file_count                                      |
-- |                   Each order is read order by order from flat file  |
-- |                   and stored in file_line rec type                  |
-- |                  process header reads header info , process line    |
-- |                  reads line info process adjustments reads          |
-- |                  adjustments and process_payments reads payment info|
-- |                                                                     |
-- | Parameters      : p_file_name   IN -> SAS file name                 |
-- |                   P_debug_level IN -> Debug Level i.e 0 to 5        |
-- |                   P_batch_size  IN -> Size of Batch ex. 1500        |
-- |                   x_return_status     OUT                           |
-- +=====================================================================+
    PROCEDURE process_child(
        p_file_name      IN             VARCHAR2,
        p_debug_level    IN             NUMBER,
        p_batch_size     IN             NUMBER,
        x_return_status  OUT NOCOPY     VARCHAR2);

-- +===================================================================+
-- | Name  : get_def_shipto                                            |
-- | Description     : To get ship to org id by passing customer id    |
-- |                                                                   |
-- | Parameters      : p_cust_account_id   IN -> pass customer_id      |
-- |                   x_ship_to_org_id   OUT -> get ship_to_org_id    |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE get_def_shipto(
        p_cust_account_id  IN             NUMBER,
        x_ship_to_org_id   OUT NOCOPY     NUMBER);

-- +===================================================================+
-- | Name  : get_def_billto                                            |
-- | Description     : To get bill to org id by passing customer id    |
-- |                                                                   |
-- | Parameters      : p_cust_account_id   IN -> pass customer_id      |
-- |                   x_bill_to_org_id   OUT -> get bill_to_org_id    |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE get_def_billto(
        p_cust_account_id  IN             NUMBER,
        x_bill_to_org_id   OUT NOCOPY     NUMBER);

    g_created_by_module  CONSTANT VARCHAR2(30)              := 'XXOM_HVOP_ADD_SHIPTO';

    TYPE t_vchar50 IS TABLE OF VARCHAR2(50)
        INDEX BY BINARY_INTEGER;

-- +===================================================================+
-- | Name  : derive_ship_to                                            |
-- | Description     : To derive ship_to_org_id for each legacy order  |
-- |                   IF multiple ship_to_org_id's are found we pass  |
-- |                   the address and validated                       |
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
-- |                  x_ship_to_org_id    OUT -> get ship_to_org_id    |
-- |                  x_invoice_to_org_id OUT -> get invoice_to_org_id |
-- |                  x_ship_to_geocode   OUT -> get ship_to_geocode   |
-- |                                                                   |
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
        x_ship_to_geocode        IN OUT NOCOPY  VARCHAR2);

-- +===================================================================+
-- | Name  : Upload_data                                               |
-- | Description     : The Upload_data procedure is the main procedure |
-- |                   depend on no of file count it generate that many|
-- |                   child concurrent programs                       |
-- |                                                                   |
-- | Parameters      : p_file_name   IN -> DEFAULT 'SAS'               |
-- |                   P_debug_level IN -> Debug Level i.e 0 to 5      |
-- |                   P_batch_size  IN -> Size of Batch ex. 1500      |
-- |                   p_file_sequence_num IN -> seq no                |
-- |                   p_file_count        IN -> No of file to process |
-- |                                             i.e 1 to 20           |
-- |                   p_file_date         IN -> DEFAULT SYSDATE       |
-- |                   p_feed_number       IN -> No of feed  1 to 5    |
-- |                   x_retcode           OUT                         |
-- |                   x_errbuf            OUT                         |
-- +===================================================================+
    PROCEDURE upload_data(
        x_retcode      OUT NOCOPY     NUMBER,
        x_errbuf       OUT NOCOPY     VARCHAR2,
        p_file_name    IN             VARCHAR2,
        p_debug_level  IN             NUMBER DEFAULT 0,
        p_batch_size   IN             NUMBER DEFAULT 1200);

-- +===================================================================+
-- | Name  : Get_Pay_Method                                            |
-- | Description      : This Procedure is called to get pay method     |
-- |                    code, and credit card code                     |
-- |                                                                   |
-- | Parameters:        p_payment_instrument IN pass pay instrument    |
-- |                    p_payment_type_code OUT Return payment_code    |
-- |                    p_credit_card_code  OUT Return credit_card_code|
-- +===================================================================+
    PROCEDURE get_pay_method(
        p_payment_instrument  IN             VARCHAR2,
        p_payment_type_code   IN OUT NOCOPY  VARCHAR2,
        p_credit_card_code    IN OUT NOCOPY  VARCHAR2);

/* FOR HEADERS */
-- +=========================================================================+
-- | Name  : order_source                                                    |
-- | Description     : To derive order_source_id by passing order            |
-- |                   source                                                |
-- |                                                                         |
-- | Parameters     : p_order_source   IN -> pass order source               |
-- |                  p_app_id         IN -> Pass App ID                     |
-- |                                                                         |
-- |                                                                         |
-- | Return         : order_source_id                                        |
-- +=========================================================================+
    FUNCTION order_source(
         p_order_source    IN   VARCHAR2
		,p_app_id          IN   VARCHAR2
	    )
        RETURN VARCHAR2;

-- +===================================================================+
-- | Name  : sales_rep                                                 |
-- | Description     : To derive salesrep_id by passing salesrep       |
-- |                                                                   |
-- |                                                                   |
-- | Parameters     : p_sales_rep  IN -> pass salesrep                 |
-- |                                                                   |
-- | Return         : sales_rep_id                                     |
-- +===================================================================+
    FUNCTION sales_rep(
        p_sales_rep  IN  VARCHAR2)
        RETURN NUMBER;

-- +===================================================================+
-- | Name  : sales_rep                                                 |
-- | Description     : To derive salesrep_id by passing salesrep       |
-- |                                                                   |
-- |                                                                   |
-- | Parameters      : p_org_id IN -> pass operating unit              |
-- |                 : p_sales_rep IN -> pass salesrep                 |
-- |                 : p_as_of_date IN -> pass sysdate                 |
-- |                                                                   |
-- | Return         : sales_rep_id                                     |
-- +===================================================================+
    FUNCTION get_salesrep_for_legacyrep(
        p_org_id      IN  NUMBER,
        p_sales_rep   IN  VARCHAR2,
        p_as_of_date  IN  DATE DEFAULT SYSDATE)
        RETURN NUMBER;

-- +===================================================================+
-- | Name  : sales_channel                                             |
-- | Description     : To validate sales_channel_code by passing       |
-- |                   sales channel                                   |
-- |                                                                   |
-- | Parameters     : p_sales_channel  IN -> pass sales channel        |
-- |                                                                   |
-- | Return         : sales_channel_code                               |
-- +===================================================================+
    FUNCTION sales_channel(
        p_sales_channel  IN  VARCHAR2)
        RETURN VARCHAR2;

-- +===================================================================+
-- | Name  : payment_term                                              |
-- | Description     : To derive payment_term_id by passing            |
-- |                   customer_id                                     |
-- |                                                                   |
-- | Parameters     : p_sold_to_org_id  IN -> pass customer id         |
-- |                                                                   |
-- | Return         : payment_term_id                                  |
-- +===================================================================+
    FUNCTION payment_term(
        p_sold_to_org_id  IN  NUMBER)
        RETURN NUMBER;

-- +===================================================================+
-- | Name  : Get_Organization_id                                       |
-- | Description     : To derive organization_id by passing            |
-- |                   store location                                  |
-- |                                                                   |
-- | Parameters     : p_org_no  IN -> pass org location no             |
-- |                                                                   |
-- | Return         : store_id for KFF DFF                             |
-- +===================================================================+
    FUNCTION get_organization_id(
        p_org_no  IN  VARCHAR2)
        RETURN NUMBER;

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
        RETURN NUMBER;

-- +===================================================================+
-- | Name  : Get_store_Country                                         |
-- | Description     : To derive store country by passing              |
-- |                   store location                                  |
-- |                                                                   |
-- | Parameters     : p_store_no  IN -> pass store location            |
-- |                                                                   |
-- | Return         : Country code                                     |
-- +===================================================================+
    FUNCTION get_store_country(
        p_store_no  IN  VARCHAR2)
        RETURN VARCHAR2;

-- +===================================================================+
-- | Name  : return_reason                                             |
-- | Description     : To derive return_reason_code by passing         |
-- |                   return reason                                   |
-- |                                                                   |
-- | Parameters     : p_return_reason  IN -> pass return reason        |
-- |                                                                   |
-- | Return         : return_reason_code                               |
-- +===================================================================+
    FUNCTION return_reason(
        p_return_reason  IN  VARCHAR2)
        RETURN VARCHAR2;

-- +===================================================================+
-- | Name  : get_ship_method                                           |
-- | Description     : To derive ship_method_code by passing           |
-- |                   delivery code                                   |
-- |                                                                   |
-- | Parameters     : p_ship_method  IN -> pass delivery code          |
-- |                                                                   |
-- | Return         : ship_method_code                                 |
-- +===================================================================+
    FUNCTION get_ship_method(
        p_ship_method  IN  VARCHAR2)
        RETURN VARCHAR2;

-- +===================================================================+
-- | Name  : Get_Ret_ActCatReason_Code                                 |
-- | Description     : To  derive return_act_cat_code by passing       |
-- |                   action,category,reason                          |
-- |                                                                   |
-- | Parameters     : p_code  IN -> pass code                          |
-- |                                                                   |
-- | Return         : account_category_code                            |
-- +===================================================================+
    FUNCTION get_ret_actcatreason_code(
        p_code  IN  VARCHAR2)
        RETURN VARCHAR2;

/* FOR LINES */
-- +===================================================================+
-- | Name  : get_inventory_item_id                                     |
-- | Description     : To derive inventory_item_id  by passing         |
-- |                   legacy item number                              |
-- |                                                                   |
-- | Parameters     : p_item  IN -> pass sku number                    |
-- |                                                                   |
-- | Return         : inventory_item_id                                |
-- +===================================================================+
    FUNCTION get_inventory_item_id(
        p_item  IN  VARCHAR2)
        RETURN NUMBER;

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
    FUNCTION customer_item_id(
        p_cust_item    IN  VARCHAR2,
        p_customer_id  IN  NUMBER)
        RETURN NUMBER;

/*FOR PAYMENTS */
-- +===================================================================+
-- | Name  : Get_receipt_method                                        |
-- | Description     : To derive receipt_method_id  by passing         |
-- |                   legacy payment_method_code, org_id, current     |
-- |                    header index                                   |
-- | Parameters     : p_pay_method_code  IN -> pass pay method code    |
-- |                  p_org_id           IN -> operating unit id       |
-- |                  p_Store_No         IN -> Store No                |
-- |                                                                   |
-- | Return         : receipt_method_id                                |
-- +===================================================================+
    FUNCTION get_receipt_method(
        p_pay_method_code  IN  VARCHAR2,
        p_org_id           IN  NUMBER,
        p_store_no         IN  VARCHAR2)
        RETURN VARCHAR2;

-- +===================================================================+
-- | Name  : credit_card_name                                          |
-- | Description     : To derive credit_card_name  by passing          |
-- |                   customer id                                     |
-- |                                                                   |
-- | Parameters     : p_sold_to_org_id  IN -> pass customer id         |
-- |                                                                   |
-- | Return         : credit_card_name                                 |
-- +===================================================================+
    FUNCTION credit_card_name(
        p_sold_to_org_id  IN  NUMBER)
        RETURN VARCHAR2;

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
        RETURN VARCHAR2;

-- +===================================================================+
-- | Name  : Get_ord_source_name                                       |
-- | Description : To derive order source name by passing source id    |
-- |                                                                   |
-- | Parameters  : p_order_source_id  IN -> pass order source id       |
-- |                                                                   |
-- | Return      : Order source Name                                   |
-- +===================================================================+
    FUNCTION get_ord_source_name(
        p_order_source_id  IN  NUMBER
		)
        RETURN VARCHAR2;
-- +===================================================================+
-- | Name  : is_appid_need_ordertype                                   |
-- | Description     : To derive Order type translations for APP ID    |
-- |                   Added for Defect#44139                          |
-- |                                                                   |
-- | Parameters     : p_app_id      IN  -> pass app_id                 |
-- |                  p_otye_value OUT -> retusn Header Order type     |
-- |                  p_ltype_value OUT -> retusn line Order type      |
-- |                                                                   |
-- | Return         : True or false                                    |
-- +===================================================================+
FUNCTION is_appid_need_ordertype(p_app_id       IN   VARCHAR2
                                 ,p_order_source IN  VARCHAR2
                                 ,x_otype_value  OUT  VARCHAR2
                                , x_ltype_value  OUT  VARCHAR2
									)
RETURN BOOLEAN;									
END xx_om_sacct_conc_pkg;
/