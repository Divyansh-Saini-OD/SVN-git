create or replace
PACKAGE BODY xx_cs_tds_ap_invoice_pkg
-- +=============================================================================================+
-- |                       Oracle GSD  (India)                                                   |
-- |                        Hyderabad  India                                                     |
-- +=============================================================================================+
-- | Name         : XX_CS_TDS_AP_INVOICE_PKG.pkb                                                 |
-- | Description  : This package is used to insert the records into the Payables Interface tables|
-- |                                                                                             |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version      Date          Author           Remarks                                          |
-- |=======   ==========   ===============      =================================================|
-- |V1.0      20-Jul-2011  Jagadeesh/S Tirumala Initial draft version                            |
-- |V1.1      12-Aug-2011  S Tirumala           Hardcoded Source,Attribute7 to  'US_OD_TDS_EDI'  |
-- |                                            and LINE_TYPE_LOOKUP_CODE column to 'ITEM'       |
-- |V1.2      12-Aug-2011  Gaurav Agarwal       Commented code for not passing ac ct date , ship |
-- |                                            ment number and pa_qunatity                      |
-- |V1.3      16-Aug-2011  S Tirumala           Added validations to check Invoice Num,Invoice   |
-- |                                            line count, Valid PO                             |
-- |                                                                                             |
-- |V1.4      23-JAN-2012  Raj Jagarlamudi      added null value to Unit Price                   |
-- |          13-JUN-2013  Raj                  Remove PO schema name with R12                   |
-- |V1.5      22-Jan-16    Vasu raparla         Removed Schema References for R.12.2             |
-- +=============================================================================================+
AS
    PROCEDURE log_exception (
        p_object_id            IN   VARCHAR2
      , p_error_location       IN   VARCHAR2
      , p_error_message_code   IN   VARCHAR2
      , p_error_msg            IN   VARCHAR2
    )
    IS
    BEGIN
        xx_com_error_log_pub.log_error
             (p_return_code                  => fnd_api.g_ret_sts_error
            , p_msg_count                    => 1
            , p_application_name             => 'XX_CRM'
            , p_program_type                 => 'Custom Messages'
            , p_program_name                 => 'XX_CS_TDS_AP_INVOICE_PKG'
            , p_object_id                    => p_object_id
            , p_module_name                  => 'AP'
            , p_error_location               => p_error_location
            , p_error_message_code           => p_error_message_code
            , p_error_message                => p_error_msg
            , p_error_message_severity       => 'MAJOR'
            , p_error_status                 => 'ACTIVE'
            , p_created_by                   => gn_user_id
            , p_last_updated_by              => gn_user_id
            , p_last_update_login            => gn_login_id
             );
    END log_exception;

    PROCEDURE insert_proc (
        p_header_rec   IN       xx_cs_tds_ap_inv_rec
      , p_lines_tab    IN       xx_cs_tds_ap_inv_lines_tbl
      , x_status       OUT      VARCHAR2
      , x_msg_data     OUT      VARCHAR2
    )
    IS
        ln_invoice_id            NUMBER;
        ln_po_header_id          NUMBER;
        ln_vendor_id             NUMBER;
        ln_vendor_site_id        NUMBER;
        ln_org_id                NUMBER;
        lv_vendor_site_code      VARCHAR2 (50);
        ln_terms_id              NUMBER;
        lv_payment_method_code   VARCHAR2 (50);
        lv_pay_group_code        VARCHAR2 (50);
        ln_accts_pay_ccid        NUMBER;
        lv_exc_rate_type         VARCHAR2 (50);
        lv_currency_code         VARCHAR2 (10);
        ln_po_line_id            NUMBER;
        ln_invoice_line_id       NUMBER;
        ln_user_id               NUMBER;
        ln_unit_price            NUMBER;
        ln_quantity              NUMBER;
        ln_item_id               NUMBER;
        lv_item_desc             VARCHAR2 (200);
        ln_line_loc_id           NUMBER;
        lv_tax_name              VARCHAR2 (50);
        lv_final_match_flag      VARCHAR2 (1);
        ln_ship_to_loc_id        NUMBER;
        ln_distribution_id       NUMBER;
        ln_amount                NUMBER;
        lv_val_rec_var           VARCHAR2 (1);
        ln_po_line_count         NUMBER;
        --lr_header_rec            xx_cs_tds_ap_inv_rec;
        --lt_lines_tab             xx_cs_tds_ap_inv_lines_tbl;
        ld_transaction_date      DATE;
        lv_closed_code           VARCHAR2 (100);

        CURSOR cur_chk_inv_num (
            p_invoice_num   IN   VARCHAR2
          , p_vendor_id     IN   NUMBER
        )
        IS
            SELECT 'X'
            FROM   ap_invoices_all aia
            WHERE  aia.invoice_num = p_invoice_num
            AND    vendor_id = p_vendor_id;
    BEGIN
        --lr_header_rec := p_header_rec;
        --lt_lines_tab := p_lines_tab;

        -- V1.3
        IF p_lines_tab.COUNT = 0
        THEN
            x_status := fnd_api.g_ret_sts_error;
            x_msg_data := x_msg_data ||
                   'Invoice has no Invoice Lines: '
                || p_header_rec.invoice_num;
            DBMS_OUTPUT.put_line ('x_msg_data:'
                                  || x_msg_data);
            log_exception
                (p_object_id                => p_header_rec.invoice_num
               , p_error_location           => 'XX_CS_TDS_AP_INVOICE_PKG.INSERT_PROC'
               , p_error_message_code       => 'XX_CS_SR01_ERR_LOG'
               , p_error_msg                => x_msg_data
                );
        END IF;
        -- Derive Invoice Header Details
        BEGIN
            SELECT po_header_id
                 , vendor_id
                 , vendor_site_id
                 , org_id
                 , currency_code
                 , closed_code
            INTO   ln_po_header_id
                 , ln_vendor_id
                 , ln_vendor_site_id
                 , ln_org_id
                 , lv_currency_code
                 , lv_closed_code
            FROM   po_headers_all
            WHERE  segment1 = p_header_rec.po_number;


            IF ( lv_closed_code IN ( 'FINALLY CLOSED',
                                     'CLOSED',
                                     'CLOSED FOR INVOICE',
                                     'CLOSED FOR RECEIVING',
                                     'CANCELLED') )THEN
                x_status := fnd_api.g_ret_sts_error;
                x_msg_data := x_msg_data ||
                       'Purchase Order Status: '||lv_closed_code||' For Purchase Order '
                    || p_header_rec.po_number;

                --DBMS_OUTPUT.put_line ('x_msg_data:' || x_msg_data);
                log_exception
                    (p_object_id                => p_header_rec.invoice_num
                   , p_error_location           => 'XX_CS_TDS_AP_INVOICE_PKG.INSERT_PROC'
                   , p_error_message_code       => 'XX_CS_SR15_ERR_LOG'
                   , p_error_msg                => x_msg_data
                    );
            END IF;
        --DBMS_OUTPUT.put_line ('ln_po_header_id:' || ln_po_header_id);
        --DBMS_OUTPUT.put_line ('ln_vendor_id' || ln_vendor_id);
        --DBMS_OUTPUT.put_line ('ln_vendor_site_id' || ln_vendor_site_id);
        --DBMS_OUTPUT.put_line ('ln_org_id' || ln_org_id);
        --DBMS_OUTPUT.put_line ('lv_currency_code' || lv_currency_code);
        EXCEPTION
            WHEN OTHERS
            THEN
                x_status := fnd_api.g_ret_sts_error;
                x_msg_data := x_msg_data ||
                       'Purchase Order does not Exist: '
                    || p_header_rec.po_number
                    || ' - Exception Raised: '
                    || SQLERRM;
                --DBMS_OUTPUT.put_line ('x_msg_data:' || x_msg_data);
                log_exception
                    (p_object_id                => p_header_rec.invoice_num
                   , p_error_location           => 'XX_CS_TDS_AP_INVOICE_PKG.INSERT_PROC'
                   , p_error_message_code       => 'XX_CS_SR02_ERR_LOG'
                   , p_error_msg                => x_msg_data
                    );
        END;

        -- V1.3
        BEGIN
            SELECT COUNT (*)
            INTO   ln_po_line_count
            FROM   po_lines_all
            WHERE  po_header_id = ln_po_header_id;

            IF (ln_po_line_count < p_lines_tab.COUNT)
            THEN
                x_status := fnd_api.g_ret_sts_error;
                x_msg_data := x_msg_data ||
                       'Invoice Lines are greater than PO Lines for Purchase Order Number: '
                    || p_header_rec.po_number;
                --DBMS_OUTPUT.put_line ('x_msg_data:' || x_msg_data);
                log_exception
                    (p_object_id                => p_header_rec.invoice_num
                   , p_error_location           => 'XX_CS_TDS_AP_INVOICE_PKG.INSERT_PROC'
                   , p_error_message_code       => 'XX_CS_SR03_ERR_LOG'
                   , p_error_msg                => x_msg_data
                    );
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                x_status := fnd_api.g_ret_sts_error;
                x_msg_data := x_msg_data ||
                       'Error while Getting PO Line Count: '
                    || p_header_rec.po_number
                    || ' - Exception Raised: '
                    || SQLERRM;
                --DBMS_OUTPUT.put_line ('x_msg_data:' || x_msg_data);
                log_exception
                    (p_object_id                => p_header_rec.invoice_num
                   , p_error_location           => 'XX_CS_TDS_AP_INVOICE_PKG.INSERT_PROC'
                   , p_error_message_code       => 'XX_CS_SR04_ERR_LOG'
                   , p_error_msg                => x_msg_data
                    );
        END;

        BEGIN
            SELECT vendor_site_code
                 , terms_id
                 , payment_method_lookup_code
                 , pay_group_lookup_code
                 , accts_pay_code_combination_id
            INTO   lv_vendor_site_code
                 , ln_terms_id
                 , lv_payment_method_code
                 , lv_pay_group_code
                 , ln_accts_pay_ccid
            FROM   po_vendor_sites_all
            WHERE  vendor_site_id = ln_vendor_site_id
            AND    vendor_id = ln_vendor_id;
        --DBMS_OUTPUT.put_line ('lv_vendor_site_code:' || lv_vendor_site_code);
        --DBMS_OUTPUT.put_line ('ln_terms_id:' || ln_terms_id);
        --DBMS_OUTPUT.put_line ('lv_payment_method_code:' || lv_payment_method_code);
        --DBMS_OUTPUT.put_line ('lv_pay_group_code:' || lv_pay_group_code);
        --DBMS_OUTPUT.put_line ('ln_accts_pay_ccid:' || ln_accts_pay_ccid);
        EXCEPTION
            WHEN OTHERS
            THEN
                x_status := fnd_api.g_ret_sts_error;
                x_msg_data := x_msg_data ||
                       'Error in finding in Vendor Site details: '
                    || SQLERRM;
                --DBMS_OUTPUT.put_line ('x_msg_data:' || x_msg_data);
                log_exception
                    (p_object_id                => p_header_rec.invoice_num
                   , p_error_location           => 'XX_CS_TDS_AP_INVOICE_PKG.INSERT_PROC'
                   , p_error_message_code       => 'XX_CS_SR05_ERR_LOG'
                   , p_error_msg                => x_msg_data
                    );
        END;

        -- V1.3
        BEGIN
            OPEN cur_chk_inv_num (p_header_rec.invoice_num
                                , ln_vendor_id);

            FETCH cur_chk_inv_num
            INTO  lv_val_rec_var;

            CLOSE cur_chk_inv_num;

            IF lv_val_rec_var = 'X'
            THEN
                x_status := fnd_api.g_ret_sts_error;
                x_msg_data := x_msg_data ||
                       'Duplicate Invoice Number: '
                    || p_header_rec.invoice_num;
                --DBMS_OUTPUT.put_line ('x_msg_data:' || x_msg_data);
                log_exception
                    (p_object_id                => p_header_rec.invoice_num
                   , p_error_location           => 'XX_CS_TDS_AP_INVOICE_PKG.INSERT_PROC'
                   , p_error_message_code       => 'XX_CS_SR06_ERR_LOG'
                   , p_error_msg                => x_msg_data
                    );
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                x_status := fnd_api.g_ret_sts_error;
                x_msg_data := x_msg_data ||
                       'Error While validating Invoice with Vendor: '
                    || SQLERRM;
                --DBMS_OUTPUT.put_line ('x_msg_data:' || x_msg_data);
                log_exception
                    (p_object_id                => p_header_rec.invoice_num
                   , p_error_location           => 'XX_CS_TDS_AP_INVOICE_PKG.INSERT_PROC'
                   , p_error_message_code       => 'XX_CS_SR07_ERR_LOG'
                   , p_error_msg                => x_msg_data
                    );
        END;

        BEGIN
            SELECT default_exchange_rate_type
            INTO   lv_exc_rate_type
            FROM   ap_system_parameters_all
            WHERE  org_id = ln_org_id;
        --DBMS_OUTPUT.put_line ('lv_exc_rate_type:' || lv_exc_rate_type);
        EXCEPTION
            WHEN OTHERS
            THEN
                x_status := fnd_api.g_ret_sts_error;
                x_msg_data := x_msg_data ||
                       'Error in finding in exchange rate type: '
                    || SQLERRM;
                --DBMS_OUTPUT.put_line ('x_msg_data:' || x_msg_data);
                log_exception
                    (p_object_id                => p_header_rec.invoice_num
                   , p_error_location           => 'XX_CS_TDS_AP_INVOICE_PKG.INSERT_PROC'
                   , p_error_message_code       => 'XX_CS_SR08_ERR_LOG'
                   , p_error_msg                => x_msg_data
                    );
        END;

        BEGIN
            SELECT MAX (transaction_date)
            INTO   ld_transaction_date
            FROM   rcv_transactions
            WHERE  po_header_id = ln_po_header_id
            AND    transaction_type = 'RECEIVE';
        --DBMS_OUTPUT.put_line ('ld_transaction_date:' || ld_transaction_date);
        EXCEPTION
            WHEN OTHERS
            THEN
                x_status := fnd_api.g_ret_sts_error;
                x_msg_data := x_msg_data ||
                       'Error in finding in Receipt Date of Purchase Order: '
                    || SQLERRM;
                --DBMS_OUTPUT.put_line ('x_msg_data:' || x_msg_data);
                log_exception
                    (p_object_id                => p_header_rec.invoice_num
                   , p_error_location           => 'XX_CS_TDS_AP_INVOICE_PKG.INSERT_PROC'
                   , p_error_message_code       => 'XX_CS_SR09_ERR_LOG'
                   , p_error_msg                => x_msg_data
                    );
        END;

        IF NVL (x_status, fnd_api.g_ret_sts_success) <>
                                     fnd_api.g_ret_sts_error
        THEN
            BEGIN
                -- Insert into Header interface table
                SELECT ap_invoices_interface_s.NEXTVAL
                INTO   ln_invoice_id
                FROM   DUAL;

                --DBMS_OUTPUT.put_line ('ln_invoice_id' || ln_invoice_id);
                INSERT INTO ap_invoices_interface
                            (invoice_id
                           , invoice_num
                           , po_number
                           , vendor_id
                           , vendor_num
                           , vendor_name
                           , vendor_site_id
                           , vendor_site_code
                           , invoice_amount
                           , org_id
                           , SOURCE
                           , goods_received_date
                           , invoice_date
                           , invoice_type_lookup_code
                           , description
                           , invoice_currency_code
                           , terms_id
                           , terms_name
                           , doc_category_code
                           , payment_method_lookup_code
                           , pay_group_lookup_code
                           , accts_pay_code_combination_id
                           , GROUP_ID
                           , status
                           , exchange_rate_type
                           , attribute7
                           , creation_date
                           , created_by
                           , last_update_date
                           , last_updated_by
                            )
                     VALUES (ln_invoice_id
                           , p_header_rec.invoice_num
                           , p_header_rec.po_number
                           , ln_vendor_id
                           , NULL
                           , NULL
                           , ln_vendor_site_id
                           , lv_vendor_site_code
                           , p_header_rec.invoice_amount
                           , ln_org_id
                           , 'US_OD_TDS_EDI'
                                 -- Added By S Tirumala V1.1
                           , ld_transaction_date
                           , p_header_rec.invoice_date
                           , p_header_rec.invoice_type_lookup_code
                                                    -- check
                           , 'PO ' || p_header_rec.po_number
                           , lv_currency_code
                           , ln_terms_id
                           , NULL
                           , NULL
                           , lv_payment_method_code
                           , lv_pay_group_code
                           , ln_accts_pay_ccid
                           , NULL
                           , NULL                  --- check
                           , lv_exc_rate_type
                           , 'US_OD_TDS_EDI'
                                 -- Added By S Tirumala V1.1
                           , SYSDATE
                           , gn_user_id
                           , SYSDATE
                           , gn_user_id
                            );
            --DBMS_OUTPUT.put_line ('Inserted Into ap_invoices_interface');
            EXCEPTION
                WHEN OTHERS
                THEN
                    x_status := fnd_api.g_ret_sts_error;
                    x_msg_data := x_msg_data ||
                           'Error in inserting into ap_invoices_interface: '
                        || SQLERRM;
                    --DBMS_OUTPUT.put_line ('x_msg_data:' || x_msg_data);
                    log_exception
                        (p_object_id                => p_header_rec.invoice_num
                       , p_error_location           => 'XX_CS_TDS_AP_INVOICE_PKG.INSERT_PROC'
                       , p_error_message_code       => 'XX_CS_SR10_ERR_LOG'
                       , p_error_msg                => x_msg_data
                        );
            END;
        END IF;

        --DBMS_OUTPUT.put_line ('Before Lines');

        -- Derive Line values
        FOR i IN p_lines_tab.FIRST .. p_lines_tab.LAST
        LOOP
            BEGIN
                SELECT po_line_id
                     , unit_price
                     , NVL (quantity, 1)
                     , item_id
                     , item_description
                INTO   ln_po_line_id
                     , ln_unit_price
                     , ln_quantity
                     , ln_item_id
                     , lv_item_desc
                FROM   po_lines_all pol
                WHERE  po_header_id = ln_po_header_id
                AND    line_num =
                              p_lines_tab (i).po_line_number;

                ln_amount := ln_unit_price * ln_quantity;
                                            -- check on this
            --DBMS_OUTPUT.put_line ('ln_po_line_id' || ln_po_line_id);
            --DBMS_OUTPUT.put_line ('ln_unit_price' || ln_unit_price);
            --DBMS_OUTPUT.put_line ('ln_quantity' || ln_quantity);
            --DBMS_OUTPUT.put_line ('ln_item_id' || ln_item_id);
            --DBMS_OUTPUT.put_line ('lv_item_desc' || lv_item_desc);
            EXCEPTION
                WHEN OTHERS
                THEN
                    x_status := fnd_api.g_ret_sts_error;
                    x_msg_data := x_msg_data ||
                           'Error in finding po line detail: '
                        || SQLERRM;
                    --DBMS_OUTPUT.put_line ('x_msg_data:' || x_msg_data);
                    log_exception
                        (p_object_id                => p_header_rec.invoice_num
                       , p_error_location           => 'XX_CS_TDS_AP_INVOICE_PKG.INSERT_PROC'
                       , p_error_message_code       => 'XX_CS_SR11_ERR_LOG'
                       , p_error_msg                => x_msg_data
                        );
            END;

            BEGIN
                SELECT line_location_id
                     , tax_name
                     , final_match_flag
                     , ship_to_location_id
                INTO   ln_line_loc_id
                     , lv_tax_name
                     , lv_final_match_flag
                     , ln_ship_to_loc_id
                  --is tax name and tax code are same or not
                FROM   po_line_locations_all
                WHERE  po_line_id = ln_po_line_id
                AND    ROWNUM = 1;
            --DBMS_OUTPUT.put_line ('ln_line_loc_id:' || ln_line_loc_id);
            --DBMS_OUTPUT.put_line ('lv_tax_name:' || lv_tax_name);
            --DBMS_OUTPUT.put_line ('lv_final_match_flag:' || lv_final_match_flag);
            --DBMS_OUTPUT.put_line ('ln_ship_to_loc_id:' || ln_ship_to_loc_id);
            EXCEPTION
                WHEN OTHERS
                THEN
                    x_status := fnd_api.g_ret_sts_error;
                    x_msg_data := x_msg_data ||
                           'Error in finding po line location detail: '
                        || SQLERRM;
                    --DBMS_OUTPUT.put_line ('x_msg_data:' || x_msg_data);
                    log_exception
                        (p_object_id                => p_header_rec.invoice_num
                       , p_error_location           => 'XX_CS_TDS_AP_INVOICE_PKG.INSERT_PROC'
                       , p_error_message_code       => 'XX_CS_SR12_ERR_LOG'
                       , p_error_msg                => x_msg_data
                        );
            END;

            IF NVL (x_status, fnd_api.g_ret_sts_success) <>
                                     fnd_api.g_ret_sts_error
            THEN
                SELECT ap_invoice_lines_interface_s.NEXTVAL
                INTO   ln_invoice_line_id
                FROM   DUAL;

                --DBMS_OUTPUT.put_line ('ln_invoice_line_id' || ln_invoice_line_id);
                BEGIN
                    -- Insert into Line Interface table
                    INSERT INTO ap_invoice_lines_interface
                                (invoice_id
                               , invoice_line_id
                               , line_number
                               , line_type_lookup_code
                               , amount
                               -- , accounting_date     --V1.2
                    ,            dist_code_combination_id
                               , release_num
                               , po_number
                               , po_line_number
                               -- , po_shipment_num     --V1.2
                    ,            project_id
                               , task_id
                               , expenditure_type
                               , expenditure_item_date
                               , expenditure_organization_id
                               --, pa_quantity       --V1.2
                    ,            quantity_invoiced
                               , tax_code
                               , unit_price
                               , description
                               , match_option
                               , final_match_flag
                               , inventory_item_id
                               , item_description
                               , creation_date
                               , created_by
                               , last_update_date
                               , last_updated_by
                                )
                         VALUES (ln_invoice_id
                               , ln_invoice_line_id
                               , p_lines_tab (i).line_number
                               , 'ITEM'
                                 -- Added By S Tirumala V1.1
                               , p_lines_tab (i).amount
                               --  , p_lines_tab (i).accounting_date    --V1.2
                    ,            p_lines_tab (i).dist_code_combination_id
                               , p_lines_tab (i).release_num
                               , p_lines_tab (i).po_number
                               , p_lines_tab (i).po_line_number
                               -- , p_lines_tab (i).po_shipment_num    --V1.2
                    ,            p_lines_tab (i).project_id
                               , p_lines_tab (i).task_id
                               , p_lines_tab (i).expenditure_type
                               , p_lines_tab (i).expenditure_item_date
                               , p_lines_tab (i).expenditure_organization_id
                               --, p_lines_tab (i).pa_quantity     --V1.2
                    ,            p_lines_tab (i).quantity_invoiced
                               , lv_tax_name
                               , NULL --ln_unit_price -- Raj -- modified on 1/23
                               --p_lines_tab (i).unit_price -- Commented by Sreenivas as a code change 24 Aug.
                               , p_lines_tab (i).description
                               , 'P'
                               , lv_final_match_flag
                               , ln_item_id
                               , lv_item_desc
                               , SYSDATE
                               , gn_user_id
                               , SYSDATE
                               , gn_user_id
                                );
                --DBMS_OUTPUT.put_line ('Inserted INTO ap_invoice_lines_interface');
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        x_status := fnd_api.g_ret_sts_error;
                        x_msg_data := x_msg_data ||
                               'Error in inserting into ap_invoice_lines_interface: '
                            || SQLERRM;
                        --DBMS_OUTPUT.put_line ('x_msg_data:' || x_msg_data);
                        log_exception
                            (p_object_id                => p_header_rec.invoice_num
                           , p_error_location           => 'XX_CS_TDS_AP_INVOICE_PKG.INSERT_PROC'
                           , p_error_message_code       => 'XX_CS_SR13_ERR_LOG'
                           , p_error_msg                => x_msg_data
                            );
                END;
            END IF;
        END LOOP;

        IF (NVL (x_status, 'S') <> fnd_api.g_ret_sts_error)
        THEN
            x_status := 'S';
            COMMIT;
        ELSE
            ROLLBACK;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_msg_data := x_msg_data ||
                    'Error in insert procedure ' || SQLERRM;
            x_status := fnd_api.g_ret_sts_error;
            ROLLBACK;
            log_exception
                (p_object_id                => p_header_rec.invoice_num
               , p_error_location           => 'XX_CS_TDS_AP_INVOICE_PKG.INSERT_PROC'
               , p_error_message_code       => 'XX_CS_SR14_ERR_LOG'
               , p_error_msg                => x_msg_data
                );
    END insert_proc;
END xx_cs_tds_ap_invoice_pkg;
/
show errors;
exit;