CREATE OR REPLACE PACKAGE BODY xx_ar_prepay_receipt_pkg
-- +=========================================================================
-- ===+
-- |                  Office Depot - Project Simplify
-- |
-- |                        Office Depot Organization
-- |
-- +=========================================================================
-- ===+
-- | Name             :  XX_AR_PREPAY_RECEIPT_PKG.pkb
-- |
-- | RICE ID          : E3080
-- |
-- |
-- |
-- | Description      :  This package will create Prepayment Receipt based on
-- |
-- |                     Order Header Id.
-- |
-- |
-- |
-- |Change Record:
-- |
-- |===============
-- |
-- |Version Date        Author            Remarks
-- |
-- |======= =========== =============     ================
-- |
-- |DRAFT1A 08-JUN-13   Gayathri K       Created as part of QC#23068
-- |
-- |
-- |
-- |RETRFIT 05-MAR-14   S. Perlas        Retrofit for R12
-- |        27-OCT-15   Vasu Raparla     Removed Schema References for R12.2
-- +=========================================================================
-- ===+
AS
-- +=========================================================================
-- ===+
-- | Name             :  XX_AR_PREPAY_RECEIPT_PROC
-- |
-- |
-- |
-- | Description      :  This procedure will create AR Receipt (with
-- Prepayment |
-- |                     Application) based on the data present in
-- oe_payments  |
-- |                     and oe_order_headers_all tables.
-- |
-- | Parameters       :  p_header_id        IN ->  Order Header ID for which
-- |
-- |                     prepayment receipt needs to be created.
-- |
-- |                  :  p_return_status    OUT->         S=Success, F=
-- Failure  |
-- |
-- |
-- +=========================================================================
-- ===+
    PROCEDURE xx_ar_prepay_receipt_proc(
        p_header_id      IN      NUMBER,
        p_return_status  OUT     VARCHAR2)
    AS
        CURSOR lcu_payments
        IS
            SELECT   ooh.header_id,
                     op.payment_type_code,
                     op.credit_card_code,
                     op.credit_card_number,
                     op.credit_card_holder_name,
                     op.credit_card_expiration_date,
                     op.credit_card_approval_code,
                     op.credit_card_approval_date,
                     op.check_number,
                     op.prepaid_amount,
                     op.payment_amount,
                     op.orig_sys_payment_ref,
                     op.payment_number,
                     op.receipt_method_id,
                     ooh.transactional_curr_code,
                     ooh.sold_to_org_id,
                     ooh.invoice_to_org_id,
                     op.payment_set_id,
                     ooh.order_number,
                     op.CONTEXT,
                     op.attribute6,
                     op.attribute7,
                     op.attribute8,
                     op.attribute9,
                     op.attribute10,
                     op.attribute11,
                     op.attribute12,
                     op.attribute13,
                     op.attribute15,
                     ooh.ship_from_org_id,
                     xoha.paid_at_store_id,
                     ooh.orig_sys_document_ref,
                     op.tangible_id,
                     ooh.ordered_date receipt_date,
                     op.attribute4 credit_card_number_enc,   -- PART OF RETROFIT SINON
                     op.attribute5 IDENTIFIER   -- PART OF RETROFIT SINON
            FROM     oe_payments op, oe_order_headers_all ooh, xx_om_header_attributes_all xoha
            WHERE    ooh.header_id = op.header_id
            AND      xoha.header_id = ooh.header_id
            AND      op.attribute15 IS NULL
            AND      ooh.org_id = g_org_id
            AND      ooh.header_id = p_header_id
            ORDER BY ooh.header_id, op.payment_number;

        TYPE t_pay_tab IS TABLE OF lcu_payments%ROWTYPE
            INDEX BY PLS_INTEGER;

        l_pay_tab                      t_pay_tab;
        ln_user                        NUMBER                                               := NULL;
        lc_timestamp                   VARCHAR2(30)                                         := NULL;
        lc_print_header                VARCHAR2(300)                                        := NULL;
        lc_print_line                  VARCHAR2(300)                                        := NULL;
        ln_ps_id                       NUMBER;
        ln_cr_id                       NUMBER;
        ln_trx_id                      NUMBER;
        lc_tan_id                      VARCHAR2(100);
        l_xx_cr_pay_pgm_name           VARCHAR2(30)                                         := 'XXTBD';
        ln_msg_count                   NUMBER;
        lc_status                      VARCHAR2(1);
        lc_return_status               VARCHAR2(1);
        lc_msg_data                    VARCHAR2(2000);
        ln_rec_appl_id                 NUMBER;
        ln_remittance_bank_account_id  NUMBER;
        ln_payment_server_order_num    NUMBER;
        ln_sec_application_ref_id      NUMBER;
        ln_curr_pay_set_id             NUMBER;
        ln_app_ref_id                  NUMBER;
        lc_pay_response_error_code     VARCHAR2(80);
        lc_approval_code               VARCHAR2(120);
        lc_app_ref_num                 VARCHAR2(80);
        ln_receipt_number              ar_cash_receipts.receipt_number%TYPE;
        ln_cash_receipt_id             ar_cash_receipts.cash_receipt_id%TYPE;
        lc_receipt_comments            ar_cash_receipts.comments%TYPE;
        lc_customer_receipt_reference  ar_cash_receipts.customer_receipt_reference%TYPE;
        lc_app_customer_reference      ar_receivable_applications.customer_reference%TYPE;
        lc_app_comments                ar_receivable_applications.comments%TYPE;
        lc_order_source                oe_order_sources.NAME%TYPE;
        l_auth_attr_rec                xx_ar_cash_receipts_ext%ROWTYPE;
        l_app_attribute_rec            ar_receipt_api_pub.attribute_rec_type;
        l_attribute_rec                ar_receipt_api_pub.attribute_rec_type;
    BEGIN
        SELECT TO_CHAR(SYSDATE,
                       'DD-MON-YYYY HH24:MI:SS')
        INTO   lc_timestamp
        FROM   DUAL;

        -- g_user_id is passed as a global variable
        ln_user := g_user_id;
        fnd_file.put_line(fnd_file.LOG,
                          'Begining of XX_AR_PREPAY_RECEIPT Procedure');
        fnd_file.put_line(fnd_file.LOG,
                             'Parameter P_header_id: '
                          || p_header_id);
        fnd_file.put_line(fnd_file.LOG,
                             'Processing starts at :  '
                          || lc_timestamp);

        OPEN lcu_payments;

        FETCH lcu_payments
        BULK COLLECT INTO l_pay_tab;

        CLOSE lcu_payments;

        IF (l_pay_tab.COUNT > 0)
        THEN
            lc_print_header :=
                   RPAD('ORDER_NUMBER',
                        20,
                        ' ')
                || RPAD('RECEIPT_DATE',
                        20,
                        ' ')
                || RPAD('RECEIPT_AMOUNT',
                        20,
                        ' ')
                || RPAD('RECEIPT_NUMBER',
                        20,
                        ' ')
                || RPAD('CASH_RECEIPT_ID',
                        20,
                        ' ')
                || RPAD('PAYMENT_SET_ID',
                        20,
                        ' ')
                || RPAD('API STATUS',
                        15,
                        ' ')
                || RPAD('RETURN STATUS',
                        15,
                        ' ')
                || RPAD('MSG_COUNT',
                        15,
                        ' ')
                || RPAD('MSG_DATA',
                        120,
                        ' ');

            FOR i_index IN l_pay_tab.FIRST .. l_pay_tab.LAST
            LOOP
                -- Resetting variables
                lc_status := NULL;
                ln_msg_count := NULL;
                lc_msg_data := NULL;
                ln_ps_id := NULL;
                ln_cr_id := NULL;
                ln_trx_id := NULL;
                lc_tan_id := NULL;
                ln_rec_appl_id := NULL;
                ln_remittance_bank_account_id := NULL;
                ln_payment_server_order_num := NULL;
                ln_sec_application_ref_id := NULL;
                ln_curr_pay_set_id := NULL;
                ln_app_ref_id := NULL;
                lc_pay_response_error_code := NULL;
                lc_approval_code := NULL;
                lc_app_ref_num := NULL;
                ln_receipt_number := NULL;
                ln_cash_receipt_id := NULL;
                lc_receipt_comments := NULL;
                lc_customer_receipt_reference := NULL;
                lc_app_customer_reference := NULL;
                lc_app_comments := NULL;
                lc_order_source := NULL;
                l_auth_attr_rec := NULL;
                l_app_attribute_rec := NULL;
                l_attribute_rec := NULL;

                BEGIN
                    -- Setting Receipt Attributes
                    fnd_file.put_line(fnd_file.LOG,
                                      'Calling XX_AR_PREPAYMENTS_PKG.SET_RECEIPT_ATTR_REFERENCES');
                    xx_ar_prepayments_pkg.set_receipt_attr_references
                                                   (p_receipt_context =>                 'SALES_ACCT',
                                                    p_orig_sys_document_ref =>           l_pay_tab(i_index).orig_sys_document_ref,
                                                    p_receipt_method_id =>               l_pay_tab(i_index).receipt_method_id,
                                                    p_payment_type_code =>               l_pay_tab(i_index).payment_type_code,
                                                    p_check_number =>                    l_pay_tab(i_index).check_number,
                                                    p_paid_at_store_id =>                l_pay_tab(i_index).paid_at_store_id,
                                                    p_ship_from_org_id =>                l_pay_tab(i_index).ship_from_org_id,
                                                    p_cc_auth_manual =>                  l_pay_tab(i_index).attribute6,
                                                    p_cc_auth_ps2000 =>                  l_pay_tab(i_index).attribute8,
                                                    p_merchant_number =>                 l_pay_tab(i_index).attribute7,
                                                    p_od_payment_type =>                 l_pay_tab(i_index).attribute11,
                                                    p_debit_card_approval_ref =>         l_pay_tab(i_index).attribute12,
                                                    p_cc_mask_number =>                  l_pay_tab(i_index).attribute10,
                                                    p_payment_amount =>                  l_pay_tab(i_index).payment_amount,
                                                    p_called_from =>                     'HVOP',
                                                    p_additional_auth_codes =>           l_pay_tab(i_index).attribute13,
                                                    x_receipt_number =>                  ln_receipt_number,
                                                    x_receipt_comments =>                lc_receipt_comments,
                                                    x_customer_receipt_reference =>      lc_customer_receipt_reference,
                                                    x_attribute_rec =>                   l_attribute_rec,
                                                    x_app_customer_reference =>          lc_app_customer_reference,
                                                    x_app_comments =>                    lc_app_comments,
                                                    x_app_attribute_rec =>               l_app_attribute_rec,
                                                    x_receipt_ext_attributes =>          l_auth_attr_rec);
                    -- Creating Prepayment Receipt
                    fnd_file.put_line(fnd_file.LOG,
                                      'Calling XX_AR_PREPAYMENTS_PKG.CREATE_PREPAYMENT');

                    /* USE THIS RETROFTTED VERSION CODE BELOW */
                    xx_ar_prepayments_pkg.create_prepayment
                                                        (p_api_version =>                       1.0,
                                                         p_init_msg_list =>                     fnd_api.g_false,
                                                         p_commit =>                            fnd_api.g_false,
                                                         p_validation_level =>                  fnd_api.g_valid_level_full,
                                                         x_return_status =>                     lc_return_status,
                                                         x_msg_count =>                         ln_msg_count,
                                                         x_msg_data =>                          lc_msg_data,
                                                         p_print_debug =>                       fnd_api.g_false,
                                                         p_receipt_method_id =>                 l_pay_tab(i_index).receipt_method_id,
                                                         p_payment_type_code =>                 NULL,
                                                         p_currency_code =>                     l_pay_tab(i_index).transactional_curr_code,
                                                         p_amount =>                            l_pay_tab(i_index).payment_amount,
                                                         p_payment_number =>                    l_pay_tab(i_index).payment_number,
                                                         p_sas_sale_date =>                     l_pay_tab(i_index).receipt_date,
                                                         p_receipt_date =>                      NULL,
                                                         p_gl_date =>                           NULL,
                                                         p_customer_id =>                       l_pay_tab(i_index).sold_to_org_id,
                                                         p_customer_site_use_id =>              l_pay_tab(i_index).invoice_to_org_id,
                                                         p_customer_bank_account_id =>          NULL,
                                                         p_customer_receipt_reference =>        lc_customer_receipt_reference,
                                                         p_remittance_bank_account_id =>        NULL,
                                                         p_called_from =>                       'HVOP',
                                                         p_attribute_rec =>                     l_attribute_rec,
                                                         p_receipt_comments =>                  lc_receipt_comments,
                                                         p_application_ref_type =>              'OM',
                                                         p_application_ref_id =>                ln_app_ref_id,
                                                         p_application_ref_num =>               lc_app_ref_num,
                                                         p_secondary_application_ref_id =>      ln_sec_application_ref_id,
                                                         p_apply_date =>                        NULL,
                                                         p_apply_gl_date =>                     NULL,
                                                         p_amount_applied =>                    NULL,
                                                         p_app_attribute_rec =>                 l_app_attribute_rec,
                                                         p_app_comments =>                      lc_app_comments,
                                                         x_payment_set_id =>                    ln_ps_id,
                                                         x_cash_receipt_id =>                   ln_cr_id,
                                                         x_receipt_number =>                    ln_receipt_number,
                                                         p_receipt_ext_attributes =>            l_auth_attr_rec);
                          --p_app_customer_reference            => lc_app_customer_reference,
                          --p_credit_card_code                  => l_pay_tab(i_index).credit_card_code,
                          --p_credit_card_number                => l_pay_tab(i_index).credit_card_number,
                          --p_credit_card_holder_name           => l_pay_tab(i_index).credit_card_holder_name,
                          --p_credit_card_expiration_date       => l_pay_tab(i_index).credit_card_expiration_date,
                          --p_credit_card_approval_code         => l_pay_tab(i_index).credit_card_approval_code,
                          --p_credit_card_approval_date         => l_pay_tab(i_index).credit_card_approval_date,
                          --x_payment_server_order_num          => lc_tan_id,
                          --x_payment_response_error_code       => lc_pay_response_error_code,
                          --p_trxn_extension_id                 => ln_trxn_extension_id,
                          --p_credit_card_number_enc            => l_pay_tab(i_index).credit_card_number_enc,
                          --p_identifier                        => l_pay_tab(i_index).IDENTIFIER);
                    /* USE THIS RETROFTTED VERSION CODE ABOVE */
                    fnd_file.put_line(fnd_file.LOG,
                                         'API Return Status : '
                                      || lc_return_status);

                    -- If API Return Status is S
                    IF lc_return_status = 'S'
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                          'Updating XX_AR_ORDER_RECEIPT_DTL');

                        UPDATE xx_ar_order_receipt_dtl
                        SET last_update_date = SYSDATE,
                            last_updated_by = ln_user,
                            cash_receipt_id = ln_cr_id,
                            receipt_number = ln_receipt_number,
                            payment_set_id = ln_ps_id
                        WHERE  header_id = l_pay_tab(i_index).header_id;

                        fnd_file.put_line(fnd_file.LOG,
                                          'Updating OE_PAYMENTS');

                        UPDATE oe_payments
                        SET last_update_date = SYSDATE,
                            last_updated_by = ln_user,
                            attribute15 = ln_cr_id,
                            payment_set_id = ln_ps_id,
                            tangible_id = lc_tan_id
                        WHERE  header_id = l_pay_tab(i_index).header_id;

                        fnd_file.put_line(fnd_file.LOG,
                                          'Updating AR_RECEIVABLE_APPLICATIONS_ALL');

                        UPDATE /*+ INDEX(ar_receivable_applications_all
            ar_receivable_applications_n1) */ar_receivable_applications_all
                        SET last_update_date = SYSDATE,
                            last_updated_by = ln_user,
                            payment_set_id = ln_ps_id,
                            application_ref_num = l_pay_tab(i_index).order_number,
                            application_ref_id = l_pay_tab(i_index).header_id
                        WHERE  display = 'Y'
                        AND    cash_receipt_id = ln_cr_id
                        AND    applied_payment_schedule_id = -7;

                        lc_status := 'S';
                        fnd_file.put_line(fnd_file.LOG,
                                             'After Update Status : '
                                          || lc_status);
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        lc_status := lc_status;
                        lc_msg_data :=
                               lc_msg_data
                            || ' | API Return Status : '
                            || lc_return_status
                            || ' | After Update Status : '
                            || lc_status
                            || ' | '
                            || SQLERRM;
                        fnd_file.put_line(fnd_file.LOG,
                                             'EXCEPTION |:'
                                          || SQLERRM);
                        xx_com_error_log_pub.log_error(p_program_type =>                'CONCURRENT PROGRAM',
                                                       p_program_name =>                l_xx_cr_pay_pgm_name,
                                                       p_module_name =>                 'AR',
                                                       p_error_location =>              'Error while creating receipts - API',
                                                       p_error_message_count =>         1,
                                                       p_error_message_code =>          'E',
                                                       p_error_message =>               lc_msg_data,
                                                       p_error_message_severity =>      'Major',
                                                       p_notify_flag =>                 'N',
                                                       p_object_type =>                 'Creating Prepayment Receipts');
                END;

                lc_print_line :=
                       RPAD(l_pay_tab(i_index).order_number,
                            20,
                            ' ')
                    || RPAD(l_pay_tab(i_index).receipt_date,
                            20,
                            ' ')
                    || RPAD(l_pay_tab(i_index).payment_amount,
                            20,
                            ' ')
                    || RPAD(ln_receipt_number,
                            20,
                            ' ')
                    || RPAD(ln_cr_id,
                            20,
                            ' ')
                    || RPAD(ln_ps_id,
                            20,
                            ' ')
                    || RPAD(lc_return_status,
                            15,
                            ' ')
                    || RPAD(lc_status,
                            15,
                            ' ')
                    || RPAD(ln_msg_count,
                            15,
                            ' ')
                    || RPAD(SUBSTR(lc_msg_data,
                                   1,
                                   120),
                            120,
                            ' ');

                IF lc_status = 'S'
                THEN
                    p_return_status := lc_status;
                    COMMIT;
                    fnd_file.put_line(fnd_file.LOG,
                                      'Executed COMMIT');
                    fnd_file.put_line(fnd_file.LOG,
                                      lc_print_header);
                    fnd_file.put_line(fnd_file.LOG,
                                      lc_print_line);
                END IF;
            END LOOP;
        END IF;

        SELECT TO_CHAR(SYSDATE,
                       'DD-MON-YYYY HH24:MI:SS')
        INTO   lc_timestamp
        FROM   DUAL;

        fnd_file.put_line(fnd_file.LOG,
                             'Processing ends at   :  '
                          || lc_timestamp);
        fnd_file.put_line(fnd_file.LOG,
                          'End of XX_CREATE_PREPAY_RECEIPT Procedure');
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'EXCEPTION |:'
                              || SQLERRM);
            xx_com_error_log_pub.log_error(p_program_type =>                'CONCURRENT PROGRAM',
                                           p_program_name =>                l_xx_cr_pay_pgm_name,
                                           p_module_name =>                 'AR',
                                           p_error_location =>              'Error while creating receipts - Main',
                                           p_error_message_count =>         1,
                                           p_error_message_code =>          'E',
                                           p_error_message =>                  'ERROR | '
                                                                            || SQLERRM,
                                           p_error_message_severity =>      'Major',
                                           p_notify_flag =>                 'N',
                                           p_object_type =>                 'Creating Prepayment Receipts');
    END xx_ar_prepay_receipt_proc;
END xx_ar_prepay_receipt_pkg;
/