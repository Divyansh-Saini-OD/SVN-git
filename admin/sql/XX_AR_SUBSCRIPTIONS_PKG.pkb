create or replace PACKAGE BODY xx_ar_subscriptions_pkg
AS
-- +===============================================================================+
-- |  Office Depot                                                                 |
-- +===============================================================================+
-- |  Name:  XX_AR_SUBSCRIPTIONS_PKG                                               |
-- |                                                                               |
-- |  Description:  This package body is to process subscription billing           |
-- |                                                                               |
-- |  Change Record:                                                               |
-- +===============================================================================+
-- | Version     Date         Author              Remarks                          |
-- | =========   ===========  =============       =================================|
-- | 1.0         11-DEC-2017  Sreedhar Mohan      Initial version                  |
-- | 2.0         03-JAN-2018  Jai Shankar Kumar   Changed incorporated as per MD70 |
-- | 3.0         07-MAR-2018  Sahithi Kunnuru     Modified PACKAGE                 |
-- +===============================================================================+
    PROCEDURE gl_account_string(
        errbuff          OUT     VARCHAR2,
        retcode          OUT     VARCHAR2,
        p_contract       IN      VARCHAR2,
        p_contract_line  IN      NUMBER,
        p_billing_seq    IN      NUMBER,
        p_order_number   IN      VARCHAR2,
        p_rev_account    IN      VARCHAR2,
        p_acc_class      IN      VARCHAR2,
        x_company        OUT     VARCHAR2,
        x_costcenter     OUT     VARCHAR2,
        x_account        OUT     VARCHAR2,
        x_location       OUT     VARCHAR2,
        x_intercompany   OUT     VARCHAR2,
        x_lob            OUT     VARCHAR2,
        x_future         OUT     VARCHAR2,
        x_ccid           OUT     VARCHAR2);

    PROCEDURE process_invoices(
        errbuff  OUT  VARCHAR2,
        retcode  OUT  VARCHAR2);

    PROCEDURE get_tax_line_amount(
        errbuff          OUT     VARCHAR2,
        retcode          OUT     NUMBER,
        p_contract_id    IN      NUMBER,
        p_contract_line  IN      NUMBER,
        p_billing_seq    IN      NUMBER,
        p_request_id_in  IN      NUMBER);

    PROCEDURE update_staging(
        errbuff       OUT     VARCHAR2,
        retcode       OUT     NUMBER,
        p_contract    IN      NUMBER,
        p_request_id  IN      NUMBER);

    PROCEDURE process_authorization(
        errbuff                    OUT     VARCHAR2,
        retcode                    OUT     NUMBER,
        p_auth_message             OUT     VARCHAR2,
        p_response_code            OUT     VARCHAR2,
        p_contract_id              IN      NUMBER,
        p_billing_sequence_number  IN      NUMBER);

    PROCEDURE create_receipts(
        errbuff                    OUT     VARCHAR2,
        retcode                    OUT     VARCHAR2,
        p_account_number           IN      VARCHAR2,
        p_rcpt_method_name         IN      VARCHAR2,
        p_receipt_amount           IN      VARCHAR2,
        p_org_id                   IN      NUMBER,
        p_cust_trx                 IN      NUMBER,
        p_contract_id              IN      NUMBER,
        p_billing_sequence_number  IN      NUMBER,
        x_receipt_id               OUT     NUMBER);

    PROCEDURE insert_ordt_details(
        errbuff                    OUT     VARCHAR2,
        retcode                    OUT     VARCHAR2,
        p_contract_number          IN      NUMBER,
        p_billing_sequence_number  IN      NUMBER,
        p_org_id_in                IN      NUMBER);

    PROCEDURE backfill_seq1_data(
        errbuff     OUT     VARCHAR2,
        retcode     OUT     VARCHAR2,
        p_contract  IN      VARCHAR2);

    PROCEDURE populate_error(
        p_contract_id           IN  NUMBER,
        p_contract_number       IN  VARCHAR2,
        p_contract_line_number  IN  VARCHAR2,
        p_billing_sequence      IN  VARCHAR2,
        p_module                IN  VARCHAR2,
        p_error_msg             IN  VARCHAR2);

    PROCEDURE get_plcc_cc_type(
        errbuff      OUT     VARCHAR2,
        retcode      OUT     VARCHAR2,
        p_bin        IN      VARCHAR2,
        p_plcc_type  OUT     VARCHAR2);

    PROCEDURE get_plcc_cc_type(
        errbuff      OUT     VARCHAR2,
        retcode      OUT     VARCHAR2,
        p_bin        IN      VARCHAR2,
        p_plcc_type  OUT     VARCHAR2)
    IS
        l_target_value1  xx_fin_translatevalues.source_value1%TYPE   := NULL;
    BEGIN
        BEGIN
            SELECT target_value1
            INTO   l_target_value1
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBS_SCM_PLCC_TYPE'
            AND    vals.source_value1 = p_bin;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                l_target_value1 := NULL;
                fnd_file.put_line(fnd_file.LOG,
                                  'NO data found while fetching PLCC type');
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'Unexpected error while fetching PLCC type');
                --l_target_value1 := NULL;
                retcode := 2;
        END;

        IF l_target_value1 IS NULL
        THEN
            BEGIN
                SELECT target_value1
                INTO   l_target_value1
                FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
                WHERE  1 = 1
                AND    defn.translate_id = vals.translate_id
                AND    defn.translation_name = 'XX_AR_SUBS_SCM_PLCC_TYPE'
                AND    vals.source_value1 = 'DEFAULT';
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                      'NO data found while fetching PLCC type');
                    --l_target_value1 := NULL;
                    retcode := 2;
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                      'Unexpected error while fetching PLCC type');
                    --l_target_value1 := NULL;
                    retcode := 2;
            END;
        END IF;

        p_plcc_type := l_target_value1;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'No Credit Card Type Exist of PLCC decrypt value : '
                              || p_bin);
            p_plcc_type := NULL;
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Unhandled Exception raised while getting Card Type for PLCC decrypt value: '
                              || p_bin
                              || ' - '
                              || SQLERRM);
            p_plcc_type := NULL;
    END get_plcc_cc_type;

    PROCEDURE pre_validate_service(
        errbuff      OUT     VARCHAR2,
        retcode      OUT     VARCHAR2,
        p_auth_url   IN      VARCHAR2,
        p_wallet_loc IN     VARCHAR2)
    IS
        l_service_txt varchar2(32267);
    BEGIN
        SELECT utl_http.request(p_auth_url
                                ,NULL
                                ,p_wallet_loc
                                )
        INTO l_service_txt
        FROM dual;
        fnd_file.put_line(fnd_file.LOG,'Pre Validate Serice Responce l_service_txt : ' ||l_service_txt);
    EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Exception Raised during pre_validate_service : ' || SQLERRM);
        errbuff    :=    'Exception Raised during pre_validate_service : ' || SQLERRM;
        retcode    := 2;
    END pre_validate_service;

    PROCEDURE process_re_authorization(
        errbuff  OUT  VARCHAR2,
        retcode  OUT  NUMBER)
    IS
        request                   UTL_HTTP.req;
        response                  UTL_HTTP.resp;
        n                         NUMBER;
        buff                      VARCHAR2(10000);
        clob_buff                 CLOB;
        lv_input_payload          VARCHAR2(32000)                                  := NULL;
        lv_auth_service_url       xx_fin_translatevalues.target_value1%TYPE        := NULL;
        lv_wallet_location        xx_fin_translatevalues.target_value1%TYPE        := NULL;
        lv_password               xx_fin_translatevalues.target_value2%TYPE        := NULL;
        lv_username               xx_fin_translatevalues.target_value2%TYPE        := NULL;
        lv_subscription_password  xx_fin_translatevalues.target_value3%TYPE        := NULL;
        lv_cust_address1          hz_locations.address1%TYPE                       := NULL;
        lv_cust_address2          hz_locations.address2%TYPE                       := NULL;
        lv_cust_city              hz_locations.city%TYPE                           := NULL;
        lv_cust_state             hz_locations.state%TYPE                          := NULL;
        lv_cust_postal_code       hz_locations.postal_code%TYPE                    := NULL;
        lv_cust_country           hz_locations.country%TYPE                        := NULL;
        lv_email_address          hz_contact_points.email_address%TYPE             := NULL;
        lv_fax_number             VARCHAR2(30)                                     := NULL;
        lv_phone_number           VARCHAR2(30)                                     := NULL;
        l_payload_id              NUMBER                                           := 0;
        l_auth_code               VARCHAR2(30)                                     := NULL;
        l_cc_decrypted            VARCHAR2(256)                                    := NULL;
        l_cc_decrypt_error        VARCHAR2(256);
        lv_transactionid          VARCHAR2(60)                                     := NULL;
        lv_transactiondatetime    VARCHAR2(60)                                     := NULL;
        lv_transaction_code       VARCHAR2(60)                                     := NULL;
        lv_transaction_message    VARCHAR2(256)                                    := NULL;
        lv_auth_status            VARCHAR2(60)                                     := NULL;
        lv_auth_message           VARCHAR2(256)                                    := NULL;
        lv_avs_code               VARCHAR2(60)                                     := NULL;
        lv_auth_code              VARCHAR2(60)                                     := NULL;
        x_cc_number_encrypted     VARCHAR2(60);
        x_error_message           VARCHAR2(256);
        x_identifier              VARCHAR2(30);
        lv_receipt_method         xx_fin_translatevalues.target_value1%TYPE        := NULL;
        ln_receipt_id             ar_cash_receipts_all.receipt_number%TYPE;
        l_invoice_amount          ra_customer_trx_lines_all.extended_amount%TYPE   := 0;
        l_cust_trx_id             ra_customer_trx_lines_all.customer_trx_id%TYPE;
        l_security_error          VARCHAR2(256);

        CURSOR c_inv_details
        IS
            SELECT   (SELECT account_name
                      FROM   hz_cust_accounts_all
                      WHERE  cust_account_id = xx_ar_subscriptions_pkg.get_customer(xac.initial_order_number,
                                                                                    'BILL_TO') ) customer_name,
                     (SELECT account_number
                      FROM   hz_cust_accounts_all
                      WHERE  cust_account_id = xx_ar_subscriptions_pkg.get_customer(xac.initial_order_number,
                                                                                    'BILL_TO') ) customer_number,
                     xac.payment_type,
                     xac.store_number,
                     xac.card_token,
                     xac.card_encryption_label,
                     TO_CHAR(xac.card_expiration_date,
                             'YYMM') card_expiration_date,
                     SUM(xas.contract_line_amount) contract_amount,
                     SUM(xas.total_contract_amount) total_contract_amount,
                     xac.card_type,
                     xas.invoice_number,
                     xac.contract_number,
                     xac.initial_order_number,
                     xac.bill_to_osr,
                     xas.card_id,
                     xas.contact_person_email,
                     xas.contact_person_phone,
                     xas.contact_person_fax,
                     xas.contract_id,
                     decode(xac.card_type,
                                            'PAYPAL', xac.payment_identifier
                                            ,null
                           ) billingAgreementId,
                     decode(xac.card_type,
                                            'PAYPAL', null
                                            ,xac.payment_identifier
                           ) wallet_id,
                     xas.billing_sequence_number,
                     xas.program_id,
                     xacl.contract_line_number
            FROM     xx_ar_subscriptions xas, xx_ar_contract_lines xacl, xx_ar_contracts xac
            WHERE    1 = 1
            AND      xas.contract_id = xacl.contract_id
            AND      xacl.contract_line_number = xas.contract_line_number
            AND      xas.contract_id = xac.contract_id
            AND      xas.auth_completed_flag in ('E', 'U')
            AND      invoice_created_flag = 'Y'
            GROUP BY xac.initial_order_number,
                     xac.payment_type,
                     xac.store_number,
                     xac.card_token,
                     xac.card_encryption_label,
                     xac.card_expiration_date,
                     xac.card_type,
                     xas.invoice_number,
                     xac.contract_number,
                     xac.initial_order_number,
                     xac.bill_to_osr,
                     xas.card_id,
                     xas.contact_person_email,
                     xas.contact_person_phone,
                     xas.contact_person_fax,
                     xas.contract_id,
                     xac.payment_identifier,
                     xas.billing_sequence_number,
                     xas.program_id,
                     xacl.contract_line_number;
    BEGIN
        mo_global.set_policy_context('S',
                                     fnd_profile.VALUE('org_id') );

        -- Start fetching receipt method by JAI_CG
        BEGIN
            SELECT vals.target_value1
            INTO   lv_receipt_method
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 LIKE 'RECEIPT_METHOD';

            fnd_file.put_line(fnd_file.LOG,
                                 'Receipt method fetched is: '
                              || lv_receipt_method);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                errbuff := 'Translation values not defined for receipt method. ';
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                                      'Translation values not defined for receipt method: '
                                   || lv_receipt_method);
                END IF;
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Exception raised while fetching the receipt method: '
                                  || SQLCODE
                                  || ' : '
                                  || SQLERRM);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                                      'Exception raised while fetching the receipt method: '
                                   || SQLCODE
                                   || ' : '
                                   || SQLERRM);
                END IF;
        END;

        BEGIN
            SELECT target_value1
            INTO   lv_auth_service_url
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 = 'AUTH_SERVICE';
        EXCEPTION
            WHEN OTHERS
            THEN
                retcode := 2;
                errbuff := 'Error in getting AUTH_SERVICE Service URL from Translation';
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                RETURN;
        END;

        fnd_file.put_line(fnd_file.LOG,
                             '--AUTH_SERVICE_URL: '
                          || lv_auth_service_url);

        BEGIN
            SELECT target_value1,
                   target_value2
            INTO   lv_wallet_location,
                   lv_password
            FROM   xx_fin_translatevalues val, xx_fin_translatedefinition def
            WHERE  1 = 1
            AND    def.translate_id = val.translate_id
            AND    def.translation_name = 'XX_FIN_IREC_TOKEN_PARAMS'
            AND    val.source_value1 = 'WALLET_LOCATION'
            AND    val.enabled_flag = 'Y'
            AND    SYSDATE BETWEEN val.start_date_active AND NVL(val.end_date_active,
                                                                   SYSDATE
                                                                 + 1);
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_wallet_location := NULL;
                lv_password := NULL;
                retcode := 2;
                errbuff :=    errbuff
                           || ' - '
                           || 'Error in getting Wallet Location from Translation';
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                RETURN;
        END;

        fnd_file.put_line(fnd_file.LOG,
                             '--lv_wallet_location: '
                          || lv_wallet_location
                          || 'lv_password :'
                          || lv_password);

        BEGIN
            SELECT target_value2,
                   target_value3
            INTO   lv_username,
                   lv_subscription_password
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 = 'AUTH_SERVICE'
            AND    vals.enabled_flag = 'Y'
            AND    SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active,
                                                                    SYSDATE
                                                                  + 1);
        EXCEPTION
            WHEN OTHERS
            THEN
                errbuff :=    errbuff
                           || ' - '
                           || 'Error in getting user crdentials. ';
                fnd_file.put_line(fnd_file.LOG,
                                  'lv_username Not Found');
        END;

        pre_validate_service (    errbuff =>      errbuff,
                                retcode =>      retcode,
                                p_auth_url =>    lv_auth_service_url,
                                p_wallet_loc =>    lv_wallet_location);

        IF (retcode = 2) THEN
          RETURN;
        END IF;

        IF lv_wallet_location IS NOT NULL
        THEN
            UTL_HTTP.set_wallet(lv_wallet_location,
                                lv_password);
        END IF;

        UTL_HTTP.set_response_error_check(FALSE);

        -- End
        FOR v_inv_details IN c_inv_details
        LOOP
            l_cc_decrypted := NULL;
            l_cc_decrypt_error := NULL;
            x_cc_number_encrypted := NULL;
            x_error_message := NULL;
            x_identifier := NULL;
            l_security_error := NULL;

            BEGIN
              IF (v_inv_details.card_type <> 'PAYPAL') THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'Before setting the context--');

                DBMS_SESSION.set_context(namespace =>      'XX_AR_SUBSCRIPTION_CONTEXT',
                                         ATTRIBUTE =>      'TYPE',
                                         VALUE =>          'OM');   --'EBS' Version 1.3
                fnd_file.put_line(fnd_file.LOG,
                                  'After setting the context, and before calling key package--');
                xx_od_security_key_pkg.decrypt(p_module =>             'HVOP',
                                               p_key_label =>          v_inv_details.card_encryption_label,
                                               p_encrypted_val =>      v_inv_details.card_token,
                                               p_format =>             'EBCDIC',
                                               x_decrypted_val =>      l_cc_decrypted,
                                               x_error_message =>      l_cc_decrypt_error);
                fnd_file.put_line(fnd_file.LOG,
                                     'clear token: '
                                  || l_cc_decrypted);
                fnd_file.put_line(fnd_file.LOG,
                                     'clear token error: '
                                  || l_cc_decrypt_error);

                IF l_cc_decrypted IS NOT NULL
                THEN
                    xx_od_security_key_pkg.encrypt_outlabel(p_module =>             'AJB',
                                                            p_key_label =>          NULL,
                                                            p_algorithm =>          '3DES',
                                                            p_decrypted_val =>      l_cc_decrypted,
                                                            x_encrypted_val =>      x_cc_number_encrypted,
                                                            x_error_message =>      x_error_message,
                                                            x_key_label =>          x_identifier);
                    fnd_file.put_line(fnd_file.LOG,
                                         'Encrypted token number: '
                                      || x_cc_number_encrypted);
                    fnd_file.put_line(fnd_file.LOG,
                                         'Encrypted token error: '
                                      || x_error_message);
                    fnd_file.put_line(fnd_file.LOG,
                                         'Encrypted token identifier: '
                                      || x_identifier);
                END IF;
              END IF; --end of if payment_type <> 'PAYPAL'
            EXCEPTION
                WHEN OTHERS
                THEN
                    l_cc_decrypted := NULL;   --v_inv_details.clear_token;
                    l_security_error :=
                                  SUBSTR(   'Decrypt: '
                                         || l_cc_decrypt_error
                                         || '- Encrypt: '
                                         || x_error_message,
                                         1,
                                         256);
                    l_cc_decrypt_error :=    'Exception raised while calling XX_OD_SECURITY_KEY_PKG.DECRYPT : '
                                          || SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                         'l_security_error: '
                                      || l_security_error);
                    errbuff :=    errbuff
                               || ' - '
                               || l_cc_decrypt_error;
                    retcode := 2;
                    fnd_file.put_line(fnd_file.LOG,
                                      l_cc_decrypt_error);
                    populate_error(p_contract_id =>               v_inv_details.contract_id,
                                   p_contract_number =>           v_inv_details.contract_number,
                                   p_contract_line_number =>      v_inv_details.contract_line_number,
                                   p_billing_sequence =>          v_inv_details.billing_sequence_number,
                                   p_module =>                    'Process_re_Authorization',
                                   p_error_msg =>                 errbuff);
            END;

            IF (       v_inv_details.card_type = 'PAYPAL'
                  OR ( x_cc_number_encrypted IS NOT NULL
                       AND x_identifier IS NOT NULL
                      )
                )
            THEN
            
                --Update the subscription table with decrypted cc_mask value
                UPDATE xx_ar_subscriptions
                SET 
                    settlement_card = x_cc_number_encrypted,
                    settlement_label = x_identifier,
                    settlement_cc_mask =
                                SUBSTR(l_cc_decrypted,
                                       1,
                                       6)
                             || SUBSTR(l_cc_decrypted,
                                         LENGTH(l_cc_decrypted)
                                       - 4,
                                       4),
                    last_update_date = SYSDATE
                WHERE  contract_id = v_inv_details.contract_id
                AND    billing_sequence_number = v_inv_details.billing_sequence_number;    

               COMMIT;                
            
                BEGIN
                    SELECT hl.address1,
                           hl.address2,
                           hl.city,
                           hl.state,
                           SUBSTRB(postal_code,
                                   1,
                                   5),
                           hl.country,
                           (SELECT email_address
                            FROM   hz_contact_points hcp
                            WHERE  hcp.owner_table_name = 'HZ_PARTIES'
                            AND    hcp.contact_point_type = 'EMAIL'
                            AND    hcp.owner_table_id = hps.party_id),
                           (SELECT    hcp.phone_country_code
                                   || '-'
                                   || hcp.phone_area_code
                                   || '-'
                                   || hcp.phone_number
                            FROM   hz_contact_points hcp
                            WHERE  hcp.owner_table_name = 'HZ_PARTIES'
                            AND    hcp.contact_point_type = 'FAX'
                            AND    hcp.owner_table_id = hps.party_id),
                           (SELECT    hcp.phone_country_code
                                   || '-'
                                   || hcp.phone_area_code
                                   || '-'
                                   || hcp.phone_number
                            FROM   hz_contact_points hcp
                            WHERE  hcp.owner_table_name = 'HZ_PARTIES'
                            AND    hcp.contact_point_type = 'PHONE'
                            AND    hcp.owner_table_id = hps.party_id)
                    INTO   lv_cust_address1,
                           lv_cust_address2,
                           lv_cust_city,
                           lv_cust_state,
                           lv_cust_postal_code,
                           lv_cust_country,
                           lv_email_address,
                           lv_fax_number,
                           lv_phone_number
                    FROM   hz_cust_acct_sites_all hcs, hz_party_sites hps, hz_locations hl
                    WHERE  hcs.cust_acct_site_id = get_customer_site(v_inv_details.initial_order_number,
                                                                     'BILL_TO')
                    AND    hps.party_site_id = hcs.party_site_id
                    AND    hps.location_id = hl.location_id;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        lv_cust_address1 := NULL;
                        lv_cust_address2 := NULL;
                        lv_cust_city := NULL;
                        lv_cust_state := NULL;
                        lv_cust_postal_code := NULL;
                        lv_cust_country := NULL;
                        fnd_file.put_line(fnd_file.LOG,
                                             'Exception raised while fetching customer address for contract id: '
                                          || v_inv_details.contract_id
                                          || ' - '
                                          || SQLERRM);
                END;

                BEGIN
                    SELECT    '{
                "paymentAuthorizationRequest": {
                "transactionHeader": {
                "consumerName": "'
                           || v_inv_details.customer_name
                           || '",
                "consumerTransactionId": "'
                           || v_inv_details.contract_number
                           || '-'
                           || TO_CHAR(SYSDATE,
                                      'DDMONYYYYHH24MISS')
                           || '",
                "consumerTransactionDateTime":"'
                           || TO_CHAR(SYSDATE,
                                      'YYYY-MM-DD')
                           || 'T'
                           || TO_CHAR(SYSDATE,
                                      'HH24:MI:SS')
                           || '"
                },
                "customer": {
                "firstName": "'
                           || v_inv_details.customer_name
                           || '",
                "middleName": "",
                "lastName": "",
                "paymentDetails": {
                "paymentType": "'
                           || v_inv_details.payment_type
                           || '",
                "paymentCard": {
                "cardHighValueToken": "'
                           || l_cc_decrypted
                           || '",
                "expirationDate": "'
                           || v_inv_details.card_expiration_date
                           || '",
                "amount": "'
                           || v_inv_details.contract_amount
                           || '",
                "cardType": "'
                           || v_inv_details.card_type
                           || '",
                "applicationTransactionNumber": "'
                           || v_inv_details.invoice_number
                           || '",
                "billingAddress": {
                "name": "'
                           || v_inv_details.customer_name
                           || '",
                "address": {
                "address1": "'
                           || lv_cust_address1
                           || '",
                "address2": "'
                           || lv_cust_address2
                           || '",
                "city": "'
                           || lv_cust_city
                           || '",
                "state": "'
                           || lv_cust_state
                           || '",
                "postalCode": "'
                           || lv_cust_postal_code
                           || '",
                "country": "'
                           || lv_cust_country
                           || '"
                }
                }
                },
                "billingAgreementId": "'|| v_inv_details.billingAgreementId || '",
                "walletId": "'
                           || v_inv_details.wallet_id
                           || '"
                },
                "contact": {
                "email": "'
                           || lv_email_address
                           || '",
                "phoneNumber": "'
                           || lv_phone_number
                           || '",
                "faxNumber": "'
                           || lv_fax_number
                           || '"
                }
                },
                "storeNumber": "'
                           || v_inv_details.store_number
                           || '"
                }
                }
                '
                    INTO   lv_input_payload
                    FROM   DUAL;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        lv_input_payload := NULL;
                        errbuff :=    errbuff
                                   || ' - '
                                   || 'Exception raised during get_tax_line routine. '
                                   || SQLERRM;
                        fnd_file.put_line(fnd_file.LOG,
                                          errbuff);
                        populate_error(p_contract_id =>               v_inv_details.contract_id,
                                       p_contract_number =>           v_inv_details.contract_number,
                                       p_contract_line_number =>      v_inv_details.contract_line_number,
                                       p_billing_sequence =>          v_inv_details.billing_sequence_number,
                                       p_module =>                    'Process_Re_Authorization',
                                       p_error_msg =>                 errbuff);
                END;

                fnd_file.put_line(fnd_file.LOG,
                                     'Contract_Number: ' || v_inv_details.contract_number
                                     || ', Billing_Sequence_Number: ' || v_inv_details.billing_sequence_number
                                     || ', lv_input_payload: ' || lv_input_payload);

                BEGIN
                    request := UTL_HTTP.begin_request(lv_auth_service_url,
                                                      'POST',
                                                      ' HTTP/1.1');
                    UTL_HTTP.set_header(request,
                                        'user-agent',
                                        'mozilla/4.0');
                    UTL_HTTP.set_header(request,
                                        'content-type',
                                        'application/json');
                    UTL_HTTP.set_header(request,
                                        'Content-Length',
                                        LENGTH(lv_input_payload) );
                    UTL_HTTP.set_header
                        (request,
                         'Authorization',
                            'Basic '
                         || UTL_RAW.cast_to_varchar2
                                              (UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(   lv_username
                                                                                            || ':'
                                                                                            || lv_subscription_password) ) ) );
                    UTL_HTTP.write_text(request,
                                        lv_input_payload);
                    response := UTL_HTTP.get_response(request);
                    COMMIT;
                    fnd_file.put_line(fnd_file.LOG,
                                         'HTTP response status code: '
                                      || response.status_code);
                EXCEPTION
                    WHEN UTL_HTTP.end_of_body
                    THEN
                        errbuff :=    'Exception Raised-UTL_HTTP.end_of_body-SQLERRM: '
                                   || SQLERRM;
                        fnd_file.put_line(fnd_file.LOG,
                                             'Exception Raised-UTL_HTTP.end_of_body-SQLERRM: '
                                          || SQLERRM);
                        UTL_HTTP.end_response(response);
                        populate_error(p_contract_id =>               v_inv_details.contract_id,
                                       p_contract_number =>           v_inv_details.contract_number,
                                       p_contract_line_number =>      v_inv_details.contract_line_number,
                                       p_billing_sequence =>          v_inv_details.billing_sequence_number,
                                       p_module =>                    'Process_Re_Authorization',
                                       p_error_msg =>                 errbuff);

                        UPDATE xx_ar_subscriptions
                        SET auth_completed_flag = 'U',
                            authorization_error = errbuff,
                            last_update_date = SYSDATE
                        WHERE  contract_number = v_inv_details.contract_number
                        AND    billing_sequence_number = v_inv_details.billing_sequence_number
                        AND    contract_line_number = v_inv_details.contract_line_number;

                        COMMIT;
                    WHEN OTHERS
                    THEN
                        errbuff :=    'Unexpected Error Raised during HTTP connection -SQLERRM: '
                                   || SQLERRM;
                        fnd_file.put_line(fnd_file.LOG,
                                             'Unexpected Error Raised during HTTP connection -SQLERRM: '
                                          || SQLERRM);
                        populate_error(p_contract_id =>               v_inv_details.contract_id,
                                       p_contract_number =>           v_inv_details.contract_number,
                                       p_contract_line_number =>      v_inv_details.contract_line_number,
                                       p_billing_sequence =>          v_inv_details.billing_sequence_number,
                                       p_module =>                    'Process_Re_Authorization',
                                       p_error_msg =>                 errbuff);

                        UPDATE xx_ar_subscriptions
                        SET auth_completed_flag = 'U',
                            last_update_date = SYSDATE,
                            authorization_error = errbuff
                        WHERE  contract_number = v_inv_details.contract_number
                        AND    billing_sequence_number = v_inv_details.billing_sequence_number
                        AND    contract_line_number = v_inv_details.contract_line_number;

                        COMMIT;
                END;

                IF     response.status_code in (200, 400, 401, 403, 404, 406, 410, 429, 500, 502, 503, 504)
                   --AND l_cc_decrypted IS NOT NULL
                THEN
                    BEGIN
                        SELECT rct.customer_trx_id
                        INTO   l_cust_trx_id
                        FROM   ra_customer_trx_all rct, xx_ar_subscriptions xas
                        WHERE  xas.contract_id = v_inv_details.contract_id
                        AND    rct.trx_number = xas.invoice_number
                        AND    rct.org_id = fnd_profile.VALUE('org_id')
                        AND    xas.auth_completed_flag in ('E', 'U')
                        AND    ROWNUM = 1;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            fnd_file.put_line(fnd_file.LOG,
                                                 'Exception raised while fetching invoice id for contract: '
                                              || v_inv_details.contract_number);
                    END;

                    l_payload_id := xx_ar_subscription_payloads_s.NEXTVAL;

                    BEGIN
                        clob_buff := EMPTY_CLOB;

                        LOOP
                            UTL_HTTP.read_text(response,
                                               buff,
                                               LENGTH(buff) );
                            clob_buff :=    clob_buff
                                         || buff;
                            fnd_file.put_line(fnd_file.LOG,
                                                 'In loop : '
                                              || clob_buff);
                        END LOOP;

                        UTL_HTTP.end_response(response);
                    EXCEPTION
                        WHEN UTL_HTTP.end_of_body
                        THEN
                            UTL_HTTP.end_response(response);
                        WHEN OTHERS
                        THEN
                            errbuff :=    errbuff
                                       || ' - '
                                       || 'Exception raised while reading text. ';
                            fnd_file.put_line(fnd_file.LOG,
                                              errbuff);
                            UTL_HTTP.end_response(response);
                            populate_error(p_contract_id =>               v_inv_details.contract_id,
                                           p_contract_number =>           v_inv_details.contract_number,
                                           p_contract_line_number =>      v_inv_details.contract_line_number,
                                           p_billing_sequence =>          v_inv_details.billing_sequence_number,
                                           p_module =>                    'Process_re_Authorization',
                                           p_error_msg =>                 errbuff);
                    END;

                    BEGIN
                        fnd_file.put_line(fnd_file.LOG,
                                          'Before inserting into XX_AR_SUBSCRIPTION_PAYLOADS: ');

                        INSERT INTO xx_ar_subscription_payloads
                                    (payload_id,
                                     contract_number,
                                     billing_sequence_number,
                                     contract_line_number,
                                     SOURCE,
                                     response_data,
                                     creation_date,
                                     created_by,
                                     last_update_date,
                                     last_updated_by,
                                     input_payload)
                        VALUES      (l_payload_id,
                                     v_inv_details.contract_number,
                                     v_inv_details.billing_sequence_number,
                                     v_inv_details.contract_line_number,
                                     'AUTH CALL',
                                     clob_buff,
                                     SYSDATE,
                                     fnd_global.user_id,
                                     SYSDATE,
                                     fnd_global.user_id,
                                     lv_input_payload);

                        lv_input_payload := NULL;
                        fnd_file.put_line(fnd_file.LOG,
                                             'After inserting into XX_AR_SUBSCRIPTION_PAYLOADS: '
                                          || SQL%ROWCOUNT);
                        COMMIT;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            errbuff :=    errbuff
                                       || ' - '
                                       || 'Exception in inserting into XX_AR_SUBSCRIPTION_PAYLOADS. ';
                            fnd_file.put_line(fnd_file.LOG,
                                                 'Exception in inserting into XX_AR_SUBSCRIPTION_PAYLOADS: '
                                              || SQLERRM);
                            populate_error(p_contract_id =>               v_inv_details.contract_id,
                                           p_contract_number =>           v_inv_details.contract_number,
                                           p_contract_line_number =>      v_inv_details.contract_line_number,
                                           p_billing_sequence =>          v_inv_details.billing_sequence_number,
                                           p_module =>                    'Process_re_Authorization',
                                           p_error_msg =>                 errbuff);
                    END;
                ELSE
                    UPDATE xx_ar_subscriptions
                    SET auth_completed_flag = 'U',
                        authorization_error =    'Authorization process fails with response code: '
                                              || response.status_code,
                        last_update_date = SYSDATE
                    WHERE  contract_id = v_inv_details.contract_id
                    AND    billing_sequence_number = v_inv_details.billing_sequence_number;

                    errbuff :=
                             errbuff
                          || ' - '
                          || 'Authorization process fails with response code: '
                          || response.status_code;
                    fnd_file.put_line(fnd_file.LOG,
                                      errbuff);
                    UTL_HTTP.end_response(response);
                END IF;

                --Get Authorization Code
                BEGIN
                    SELECT jt0.transactionid,
                           jt0.transactiondatetime,
                           jt1.transaction_code,
                           jt1.transaction_message,
                           jt2.auth_status,
                           jt2.auth_message,
                           jt2.avs_code,
                           jt2.auth_code
                    INTO   lv_transactionid,
                           lv_transactiondatetime,
                           lv_transaction_code,
                           lv_transaction_message,
                           lv_auth_status,
                           lv_auth_message,
                           lv_avs_code,
                           lv_auth_code
                    FROM   xx_ar_subscription_payloads auth_response,
                           JSON_TABLE ( auth_response.response_data, '$.paymentAuthorizationResponse.transactionHeader' COLUMNS ( "TransactionId"    VARCHAR2(60) PATH '$.consumerTransactionId' ,"TransactionDateTime" VARCHAR2(30) PATH '$.consumerTransactionDateTime' )) "JT0" ,
                           JSON_TABLE ( auth_response.response_data, '$.paymentAuthorizationResponse.transactionStatus' COLUMNS ( "TRANSACTION_CODE" VARCHAR2(60) PATH '$.code' ,"TRANSACTION_MESSAGE" VARCHAR2(256) PATH '$.message' )) "JT1" ,
                           JSON_TABLE ( auth_response.response_data, '$.paymentAuthorizationResponse.authorizationResult' COLUMNS ( "AUTH_STATUS"    VARCHAR2(60) PATH '$.code' ,"AUTH_MESSAGE" VARCHAR2(256) PATH '$.message' ,"AVS_CODE" VARCHAR2(60) PATH '$.avsCode', "AUTH_CODE" VARCHAR2(60) PATH '$.authCode' )) "JT2"
                    WHERE  auth_response.payload_id = l_payload_id;
                EXCEPTION
                    WHEN OTHERS
                    THEN

                        SELECT jt0.transactionid,
                               jt0.transactiondatetime,
                               jt1.transaction_code,
                               jt1.transaction_message
                        INTO   lv_transactionid,
                               lv_transactiondatetime,
                               lv_transaction_code,
                               lv_transaction_message
                        FROM   xx_ar_subscription_payloads auth_response,
                               JSON_TABLE ( auth_response.response_data, '$.paymentAuthorizationResponse.transactionHeader' COLUMNS ( "TransactionId"    VARCHAR2(60) PATH '$.consumerTransactionId' ,"TransactionDateTime" VARCHAR2(30) PATH '$.consumerTransactionDateTime' )) "JT0" ,
                               JSON_TABLE ( auth_response.response_data, '$.paymentAuthorizationResponse.transactionStatus' COLUMNS ( "TRANSACTION_CODE" VARCHAR2(60) PATH '$.code' ,"TRANSACTION_MESSAGE" VARCHAR2(256) PATH '$.message' )) "JT1" 
                        WHERE  auth_response.payload_id = l_payload_id;
                    
                    
                        UPDATE xx_ar_subscriptions
                        SET authorization_code = substr(lv_transaction_code,1,15),
                            auth_datetime = lv_transactiondatetime,
                            auth_transactionid = lv_transactionid,
                            auth_transaction_message = lv_transaction_message,
                            auth_completed_flag = 'U',
                            last_update_date = SYSDATE
                        WHERE  contract_id = v_inv_details.contract_id
                        AND    billing_sequence_number = v_inv_details.billing_sequence_number;                  

                        COMMIT;
                        CONTINUE;
                        errbuff :=    'Exception in Process Re Authorization: '
                                   || SQLERRM;
                        fnd_file.put_line(fnd_file.LOG,
                                          errbuff);
                END;

                fnd_file.put_line(fnd_file.LOG,
                                     'Authorization status for contract id: '
                                  || v_inv_details.contract_id
                                  || ' - is: '
                                  || lv_auth_message);

                --Verifying or Checking if Authorization Transaction Action Code is '0'
                IF lv_auth_status = '0'
                THEN
                    UPDATE xx_ar_subscriptions
                    SET authorization_code = lv_transaction_code,
                        auth_datetime = lv_transactiondatetime,
                        auth_transactionid = lv_transactionid,
                        auth_transaction_message = lv_transaction_message,
                        auth_status = lv_auth_status,
                        auth_message = lv_auth_message,
                        auth_avs_code = lv_avs_code,
                        auth_code = lv_auth_code,
                        auth_completed_flag = 'Y',
                        email_sent_flag = 'N',
                        last_update_date = SYSDATE
                    WHERE  contract_id = v_inv_details.contract_id
                    AND    billing_sequence_number = v_inv_details.billing_sequence_number;

                    COMMIT;
                    -- Create receipt for re-authorized contracts
                    fnd_file.put_line(fnd_file.LOG,
                                         'Create receipt for re-authorized contracts id: '
                                      || v_inv_details.contract_id);
                    fnd_file.put_line(fnd_file.LOG,
                                         'Launching create receipt for customer: '
                                      || v_inv_details.customer_number
                                      || ' amount: '
                                      || v_inv_details.total_contract_amount
                                      || ' trx id: '
                                      || l_cust_trx_id);

                    IF l_cust_trx_id IS NOT NULL
                    THEN
                        BEGIN
                            SELECT SUM(extended_amount)
                            INTO   l_invoice_amount
                            FROM   ra_customer_trx_lines_all
                            WHERE  customer_trx_id = l_cust_trx_id
                            AND    org_id = fnd_profile.VALUE('org_id');

                            create_receipts(errbuff =>                        errbuff,
                                            retcode =>                        retcode,
                                            p_account_number =>               v_inv_details.customer_number,
                                            p_rcpt_method_name =>             lv_receipt_method,
                                            p_receipt_amount =>               v_inv_details.total_contract_amount,
                                            p_org_id =>                       fnd_profile.VALUE('org_id'),
                                            p_cust_trx =>                     l_cust_trx_id,
                                            p_contract_id =>                  v_inv_details.contract_id,
                                            p_billing_sequence_number =>      v_inv_details.billing_sequence_number,
                                            x_receipt_id =>                   ln_receipt_id);
                        EXCEPTION
                            WHEN NO_DATA_FOUND
                            THEN
                                errbuff :=    'Could Not Get Extended Amount Before Creating Receipt: '
                                           || SQLERRM;
                            WHEN OTHERS
                            THEN
                                errbuff :=    'Exception Before Creating Receipt: '
                                           || SQLERRM;
                        END;
                    END IF;

                    -- Start populating Order Receipt Table by JAI_CG
                    insert_ordt_details(errbuff =>                        errbuff,
                                        retcode =>                        retcode,
                                        p_contract_number =>              v_inv_details.contract_number,
                                        p_billing_sequence_number =>      v_inv_details.billing_sequence_number,
                                        p_org_id_in =>                    fnd_profile.VALUE('org_id') );

                    IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                    THEN
                        fnd_log.STRING(fnd_log.level_statement,
                                       'XX_AR_SUBSCRIPTIONS_PKG.process_re-aithorization',
                                       'After insert_ordt_details');
                    END IF;
                ELSE
                    UPDATE xx_ar_subscriptions
                    SET auth_completed_flag = 'E',
                        email_sent_flag = 'N',
                        authorization_error = lv_auth_message,
                        last_update_date = SYSDATE
                    WHERE  contract_id = v_inv_details.contract_id
                    AND    billing_sequence_number = v_inv_details.billing_sequence_number;
                END IF;
            ELSE
                UPDATE xx_ar_subscriptions
                SET auth_completed_flag = 'U',
                    authorization_error = l_security_error,
                    last_update_date = SYSDATE
                WHERE  contract_id = v_inv_details.contract_id
                AND    billing_sequence_number = v_inv_details.billing_sequence_number;
            END IF;

            COMMIT;
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            errbuff :=    'Unhandled exception raised during Process Re Authorization: '
                       || SQLERRM;
    END process_re_authorization;

    --procedure to update xx_ar_subscriptions table with invoice_number,receipt_number and order_payment_id for billing_sequence_number=1
    PROCEDURE backfill_seq1_data(
        errbuff     OUT     VARCHAR2,
        retcode     OUT     VARCHAR2,
        p_contract  IN      VARCHAR2)
    IS
        l_error_flag        VARCHAR2(2);
        l_error_msg         VARCHAR2(2000);
        l_trx_number        ra_customer_trx_all.trx_number%TYPE;
        l_receipt_number    ar_cash_receipts_all.receipt_number%TYPE;
        l_order_payment_id  xx_ar_order_receipt_dtl.order_payment_id%TYPE;
        l_cash_receipt_id   ar_cash_receipts_all.cash_receipt_id%TYPE;
        l_customer_trx_id   ra_customer_trx_all.customer_trx_id%TYPE;

        CURSOR cur_subscriptions
        IS
            SELECT xas.contract_id,
                   xas.contract_number,
                   xas.contract_line_number,
                   xac.initial_order_number,
                   xas.billing_sequence_number,
                   xas.subscriptions_id
            FROM   xx_ar_subscriptions xas, xx_ar_contracts xac
            WHERE  1 = 1
            AND    xas.invoice_interfaced_flag = 'N'
            AND    xas.contract_id = xac.contract_id
            AND    xas.contract_number = NVL(p_contract,
                                             xas.contract_number)
            AND    TRUNC(xas.billing_date) <= TRUNC(SYSDATE)
            AND    xas.billing_sequence_number = 1;
    BEGIN
        FOR rec_subscriptions IN cur_subscriptions
        LOOP
            l_error_flag := 'N';
            l_error_msg := NULL;
            l_trx_number := NULL;
            l_receipt_number := NULL;
            l_order_payment_id := NULL;
            l_cash_receipt_id := NULL;
            l_customer_trx_id := NULL;

            --FETCHING INVOICE NUMBER
            BEGIN
                SELECT trx_number,
                       customer_trx_id
                INTO   l_trx_number,
                       l_customer_trx_id
                FROM   ra_customer_trx_all
                WHERE  trx_number = rec_subscriptions.initial_order_number;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    l_error_flag := 'Y';
                    l_error_msg :=
                           'No data found while feching trx_number for initial_order_number: '
                        || rec_subscriptions.initial_order_number;
                    fnd_file.put_line(fnd_file.LOG,
                                      l_error_msg);
                WHEN OTHERS
                THEN
                    l_error_flag := 'Y';
                    l_error_msg :=
                           'Unexpected error while feching trx_number for initial_order_number: '
                        || rec_subscriptions.initial_order_number
                        || ' '
                        || SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                      l_error_msg);
            END;

            --FETCHING CASH_RECEIPT_ID
            BEGIN
                SELECT cash_receipt_id
                INTO   l_cash_receipt_id
                FROM   ar_receivable_applications_all
                WHERE  applied_customer_trx_id = l_customer_trx_id;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    l_error_flag := 'Y';
                    l_error_msg :=
                           l_error_msg
                        || ' '
                        || 'No data found while feching cash_receipt_id for initial_order_number: '
                        || rec_subscriptions.initial_order_number;
                    fnd_file.put_line(fnd_file.LOG,
                                      l_error_msg);
                WHEN OTHERS
                THEN
                    l_error_flag := 'Y';
                    l_error_msg :=
                           l_error_msg
                        || ' '
                        || 'Unexpected error while feching cash_receipt_id for initial_order_number: '
                        || rec_subscriptions.initial_order_number
                        || ' '
                        || SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                      l_error_msg);
            END;

            --FETCHING RECEIPT NUMBER
            BEGIN
                SELECT receipt_number
                INTO   l_receipt_number
                FROM   ar_cash_receipts_all
                WHERE  cash_receipt_id = l_cash_receipt_id;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    l_error_flag := 'Y';
                    l_error_msg :=
                           l_error_msg
                        || ' '
                        || 'No data found while feching receipt_number for initial_order_number: '
                        || rec_subscriptions.initial_order_number;
                    fnd_file.put_line(fnd_file.LOG,
                                      l_error_msg);
                WHEN OTHERS
                THEN
                    l_error_flag := 'Y';
                    l_error_msg :=
                           l_error_msg
                        || ' '
                        || 'Unexpected error while feching receipt_number for initial_order_number: '
                        || rec_subscriptions.initial_order_number
                        || ' '
                        || SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                      l_error_msg);
            END;

            --FETCHING ORDER PAYMENT ID
            BEGIN
                SELECT order_payment_id
                INTO   l_order_payment_id
                FROM   xx_ar_order_receipt_dtl
                WHERE  cash_receipt_id = l_cash_receipt_id;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    l_error_flag := 'Y';
                    l_error_msg :=
                           l_error_msg
                        || ' '
                        || 'No data found while feching order_payment_id for initial_order_number: '
                        || rec_subscriptions.initial_order_number;
                    fnd_file.put_line(fnd_file.LOG,
                                      l_error_msg);
                WHEN OTHERS
                THEN
                    l_error_flag := 'Y';
                    l_error_msg :=
                           l_error_msg
                        || ' '
                        || 'Unexpected error while feching order_payment_id for initial_order_number: '
                        || rec_subscriptions.initial_order_number
                        || ' '
                        || SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                      l_error_msg);
            END;

            --UPDATE XX_AR_SUBSCRIPTIONS
            IF l_error_flag = 'Y'
            THEN
                UPDATE xx_ar_subscriptions
                SET subscription_error = l_error_msg,
                    last_update_date = SYSDATE
                WHERE  subscriptions_id = rec_subscriptions.subscriptions_id;
            ELSE
                UPDATE xx_ar_subscriptions
                SET invoice_number = l_trx_number,
                    receipt_number = l_receipt_number,
                    order_payment_id = l_order_payment_id,
                    invoice_created_flag = 'Y',
                    invoice_interfaced_flag = 'Y',
                    receipt_created_flag = 'Y',
                    ordt_staged_flag = 'Y',
                    auth_completed_flag = 'Y',
                    email_sent_flag = 'Y',
                    history_sent_flag = 'Y',
                    last_update_date = SYSDATE
                WHERE  subscriptions_id = rec_subscriptions.subscriptions_id;
            END IF;

            COMMIT;
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            retcode := 2;
            errbuff :=
                   'Unexpected Error in xx_ar_subscription_pkg.backfill_data: '
                || DBMS_UTILITY.format_error_backtrace
                || SQLERRM;
            fnd_file.put_line(fnd_file.LOG,
                              errbuff);
    END backfill_seq1_data;

    PROCEDURE populate_error(
        p_contract_id           IN  NUMBER,
        p_contract_number       IN  VARCHAR2,
        p_contract_line_number  IN  VARCHAR2,
        p_billing_sequence      IN  VARCHAR2,
        p_module                IN  VARCHAR2,
        p_error_msg             IN  VARCHAR2)
    IS
    BEGIN
        INSERT INTO xx_ar_subscriptions_error
                    (contract_id,
                     contract_number,
                     contract_line_number,
                     billing_sequence_number,
                     error_module,
                     error_message,
                     creation_date)
        VALUES      (p_contract_id,
                     p_contract_number,
                     p_contract_line_number,
                     p_billing_sequence,
                     p_module,
                     p_error_msg,
                     SYSDATE);

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Unexpected Error in xx_ar_subscription_pkg.populate_error: '
                              || DBMS_UTILITY.format_error_backtrace
                              || SQLERRM);
    END populate_error;

    PROCEDURE import_contracts(
        errbuff  OUT  VARCHAR2,
        retcode  OUT  VARCHAR2)
    IS
--------------------------------------------------
-- Cursor Declaration
--------------------------------------------------
        CURSOR cur_contracts_header(
            p_program_id_in  NUMBER)
        IS
            SELECT xac.*
            FROM   xx_ar_contracts_gtt xac
            WHERE  xac.program_id = p_program_id_in
            AND    xac.contract_line_number = 1;

        CURSOR cur_contract_line(
            p_contract_in    NUMBER,
            p_program_id_in  NUMBER)
        IS
            SELECT xac.*
            FROM   xx_ar_contracts_gtt xac
            WHERE  xac.program_id = p_program_id_in
            AND    xac.contract_id = p_contract_in;

        -- Start variable declaration by JAI_CG
        l_con_retcode          NUMBER                                      := 0;
        l_con_errbuf           VARCHAR2(5000)                              := NULL;
        lv_con_short_name_in   VARCHAR2(10)                                := 'XXFIN';
        lv_con_program_in      VARCHAR2(100)                               := 'XX_AR_CONTRACTS_PRG';
        lv_con_description_in  VARCHAR2(100)                               := 'OD: AR Contracts Loader Program';
        lv_con_file_loc        VARCHAR2(240)                               := '$XXFIN_DATA/inbound';
        lv_control_file        VARCHAR2(240)                               := 'XX_AR_CONTRACTS_CTL.ctl';
        lv_con_request_id      NUMBER;
        lv_con_complete_bln    BOOLEAN;
        lv_con_phase_txt       VARCHAR2(20);
        lv_con_status_txt      VARCHAR2(20);
        lv_con_dev_phase_txt   VARCHAR2(20);
        lv_con_dev_status_txt  VARCHAR2(20);
        lv_con_message_txt     VARCHAR2(200);
        ln_con_header_count    NUMBER                                      := 0;
        ln_con_line_count      NUMBER                                      := 0;
        ln_con_record_count    NUMBER                                      := 0;
        ln_contract_amount     NUMBER                                      := 0;
        l_store_number         xx_fin_translatevalues.target_value1%TYPE   := NULL;
    -- End variable declaration by JAI_CG
    BEGIN
        fnd_file.put_line(fnd_file.LOG,
                          '***************************************');   -- Added by JAI_CG
        fnd_file.put_line(fnd_file.LOG,
                          'Starting import_contracts routine. ');
        fnd_file.put_line(fnd_file.LOG,
                          '***************************************');

        -- Fetching store number
        BEGIN
            SELECT vals.target_value1
            INTO   l_store_number
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 = 'SUBSCRIPTIONS_PMT_STORE_NUMBER';

            fnd_file.put_line(fnd_file.LOG,
                                 'Store Number fetched is: '
                              || l_store_number);

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
                fnd_log.STRING(fnd_log.level_statement,
                               'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                  'Store Number fetched is: '
                               || l_store_number);
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                errbuff := 'Translation values not defined for Store Number. ';
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                   'Translation values not defined for store number. ');
                END IF;
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Exception raised while fetching the receipt method: '
                                  || SQLCODE
                                  || ' : '
                                  || SQLERRM);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                      'Exception raised while fetching the receipt method: '
                                   || SQLCODE
                                   || ' : '
                                   || SQLERRM);
                END IF;
        END;

        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
        THEN
            fnd_log.STRING(fnd_log.level_statement,
                           'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                           'Starting import_contracts routine. ');
        END IF;

        -- Start fetching Data file detail by JAI_CG
        BEGIN
            lv_con_request_id :=
                fnd_request.submit_request(application =>      lv_con_short_name_in,
                                           program =>          lv_con_program_in,
                                           description =>      lv_con_description_in,
                                           start_time =>       TO_CHAR(SYSDATE,
                                                                       'YYYY-MM-DD HH24:MI:SS'),
                                           sub_request =>      FALSE
                                                                    --argument1 => lv_con_file_loc ,
                                                                    --argument2 => p_contract_file_name_in ,
                                                                    --argument3 => lv_control_file
                                          );
            COMMIT;

            IF lv_con_request_id = 0
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  '************************************************');
                fnd_file.put_line(fnd_file.LOG,
                                     'Conc. Program  failed to submit :'
                                  || lv_con_description_in);
                fnd_file.put_line(fnd_file.LOG,
                                  '************************************************');

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                      'Conc. Program  failed to submit :'
                                   || lv_con_description_in);
                END IF;

                retcode := 2;
            ELSE
                fnd_file.put_line(fnd_file.LOG,
                                  '************************************************');
                fnd_file.put_line(fnd_file.LOG,
                                     'Program is successfully Submitted , Request Id :'
                                  || lv_con_request_id);
                fnd_file.put_line(fnd_file.LOG,
                                  '************************************************');

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                      'Program is successfully Submitted , Request Id :'
                                   || lv_con_request_id);
                END IF;

                lv_con_complete_bln :=
                    fnd_concurrent.wait_for_request(request_id =>      lv_con_request_id,
                                                    phase =>           lv_con_phase_txt,
                                                    status =>          lv_con_status_txt,
                                                    dev_phase =>       lv_con_dev_phase_txt,
                                                    dev_status =>      lv_con_dev_status_txt,
                                                    MESSAGE =>         lv_con_message_txt);

                IF     UPPER(lv_con_dev_status_txt) = 'NORMAL'
                   AND UPPER(lv_con_dev_phase_txt) = 'COMPLETE'
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'OD: AR Subscriptions Payment Import successful for the Request Id: '
                                      || lv_con_request_id
                                      || '. ');

                    IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                    THEN
                        fnd_log.STRING(fnd_log.level_statement,
                                       'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                          'OD: AR Subscriptions Payment Import successful for the Request Id: '
                                       || lv_con_request_id
                                       || '. ');
                    END IF;

                    UPDATE xx_ar_contracts_gtt
                    SET program_id = lv_con_request_id,
                        creation_date = SYSDATE,
                        last_update_date = SYSDATE,
                        created_by = fnd_global.user_id,
                        last_updated_by = fnd_global.user_id,
                        last_update_login = fnd_global.login_id
                    WHERE  program_id IS NULL;

                    COMMIT;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Staging table has been updated with request_id. '
                                      || lv_con_request_id);

                    IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                    THEN
                        fnd_log.STRING(fnd_log.level_statement,
                                       'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                          'Staging table has been updated with request_id. '
                                       || lv_con_request_id);
                    END IF;
                ELSE
                    fnd_file.put_line(fnd_file.LOG,
                                      'SQL Loader Program does not completed normally. ');

                    IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                    THEN
                        fnd_log.STRING(fnd_log.level_statement,
                                       'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                       'SQL Loader Program does not completed normally. ');
                    END IF;

                    retcode := 2;
                END IF;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                errbuff :=    'Exception In Submit Conc. Program :'
                           || '-'
                           || SQLERRM;
                fnd_file.put_line(fnd_file.LOG,
                                  '**********************************************');
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                fnd_file.put_line(fnd_file.LOG,
                                  '**********************************************');

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                      'Exception - '
                                   || errbuff);
                END IF;

                retcode := 2;   -- Terminate the program
        END;

        -- End submitting Data Loader by JAI_CG
        BEGIN
            -- Start populating contract tables
            FOR rec_contracts_header IN cur_contracts_header(lv_con_request_id)
            LOOP
                BEGIN
                    SELECT SUM(xac.total_amount)
                    INTO   ln_contract_amount
                    FROM   xx_ar_contracts_gtt xac
                    WHERE  program_id = lv_con_request_id
                    AND    contract_id = rec_contracts_header.contract_id;

                    -- Updating header record is it exists in the table
                    UPDATE xx_ar_contracts
                    SET contract_id = rec_contracts_header.contract_id,
                        contract_number = rec_contracts_header.contract_number,
                        contract_name = rec_contracts_header.contract_name,
                        contract_status = rec_contracts_header.contract_status,
                        contract_major_version = rec_contracts_header.contract_major_version,
                        contract_start_date = rec_contracts_header.contract_start_date,
                        contract_end_date = rec_contracts_header.contract_end_date,
                        contract_billing_freq = rec_contracts_header.contract_billing_freq,
                        bill_to_cust_account_number = rec_contracts_header.bill_cust_account_number,
                        bill_to_customer_name = rec_contracts_header.bill_cust_name,
                        bill_to_osr = rec_contracts_header.bill_to_osr,
                        customer_email = rec_contracts_header.customer_email,
                        initial_order_number = rec_contracts_header.initial_order_number,
                        store_number = LPAD(NVL(rec_contracts_header.store_number,
                                                l_store_number),
                                            6,
                                            '0'),   --rec_contracts_header.store_number ,
                        payment_type = rec_contracts_header.payment_type,
                        card_type = rec_contracts_header.card_type,
                        card_tokenenized_flag = rec_contracts_header.card_tokenized_flag,
                        card_token = rec_contracts_header.card_token,
                        card_encryption_hash = rec_contracts_header.card_encryption_hash,
                        card_holder_name = rec_contracts_header.card_holder_name,
                        card_expiration_date = rec_contracts_header.card_expiration_date,
                        card_encryption_label = rec_contracts_header.card_encryption_label,
                        ref_associate_number = rec_contracts_header.ref_associate_number,
                        sales_representative = rec_contracts_header.sales_representative,
                        loyalty_member_number = rec_contracts_header.loyalty_member_number,
                        total_contract_amount = ln_contract_amount,
                        payment_term = rec_contracts_header.payment_term,
                        last_update_date = SYSDATE,   -- rec_contracts_header.last_update_date,
                        last_updated_by = rec_contracts_header.last_updated_by,
                        last_update_login = rec_contracts_header.last_update_login,
                        program_id = rec_contracts_header.program_id,
                        payment_identifier = rec_contracts_header.payment_identifier
                    WHERE  contract_id = rec_contracts_header.contract_id
                    AND    contract_number = rec_contracts_header.contract_number;

                    IF (SQL%ROWCOUNT <> 0)
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'XX_AR_CONTRACTS got updated for contract number: '
                                          || rec_contracts_header.contract_number);

                        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                        THEN
                            fnd_log.STRING(fnd_log.level_statement,
                                           'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                              'XX_AR_CONTRACTS got updated for contract number: '
                                           || rec_contracts_header.contract_number);
                        END IF;
                    ELSE
                        INSERT INTO xx_ar_contracts
                                    (contract_id,
                                     contract_number,
                                     contract_name,
                                     contract_status,
                                     contract_major_version,
                                     contract_start_date,
                                     contract_end_date,
                                     contract_billing_freq,
                                     bill_to_cust_account_number,
                                     bill_to_customer_name,
                                     bill_to_osr,
                                     customer_email,
                                     initial_order_number,
                                     store_number,
                                     payment_type,
                                     card_type,
                                     card_tokenenized_flag,
                                     card_token,
                                     card_encryption_hash,
                                     card_holder_name,
                                     card_expiration_date,
                                     card_encryption_label,
                                     ref_associate_number,
                                     sales_representative,
                                     loyalty_member_number,
                                     total_contract_amount,
                                     payment_term,
                                     creation_date,
                                     last_update_date,
                                     created_by,
                                     last_updated_by,
                                     last_update_login,
                                     program_id,
                                     payment_identifier
                                     )
                        VALUES      (rec_contracts_header.contract_id,
                                     rec_contracts_header.contract_number,
                                     rec_contracts_header.contract_name,
                                     rec_contracts_header.contract_status,
                                     rec_contracts_header.contract_major_version,
                                     rec_contracts_header.contract_start_date,
                                     rec_contracts_header.contract_end_date,
                                     rec_contracts_header.contract_billing_freq,
                                     rec_contracts_header.bill_cust_account_number,
                                     rec_contracts_header.bill_cust_name,
                                     rec_contracts_header.bill_to_osr,
                                     rec_contracts_header.customer_email,
                                     rec_contracts_header.initial_order_number,
                                     LPAD(NVL(rec_contracts_header.store_number,
                                              l_store_number),
                                          6,
                                          '0'),   --rec_contracts_header.store_number ,
                                     rec_contracts_header.payment_type,
                                     rec_contracts_header.card_type,
                                     rec_contracts_header.card_tokenized_flag,
                                     rec_contracts_header.card_token,
                                     rec_contracts_header.card_encryption_hash,
                                     rec_contracts_header.card_holder_name,
                                     rec_contracts_header.card_expiration_date,
                                     rec_contracts_header.card_encryption_label,
                                     rec_contracts_header.ref_associate_number,
                                     rec_contracts_header.sales_representative,
                                     rec_contracts_header.loyalty_member_number,
                                     ln_contract_amount,
                                     rec_contracts_header.payment_term,
                                     rec_contracts_header.creation_date,
                                     SYSDATE,   --rec_contracts_header.last_update_date,
                                     rec_contracts_header.created_by,
                                     rec_contracts_header.last_updated_by,
                                     rec_contracts_header.last_update_login,
                                     rec_contracts_header.program_id,
                                     rec_contracts_header.payment_identifier
                                     );
                    END IF;

                    ln_con_header_count :=   ln_con_header_count
                                           + 1;

                    FOR rec_contract_line IN cur_contract_line(rec_contracts_header.contract_id,
                                                               rec_contracts_header.program_id)
                    LOOP
                        BEGIN
                            -- Updating line records if exists
                            UPDATE xx_ar_contract_lines
                            SET contract_id = rec_contract_line.contract_id,
                                contract_line_number = rec_contract_line.contract_line_number,
                                initial_order_line = rec_contract_line.initial_order_line,
                                item_name = rec_contract_line.item_name,
                                item_description = rec_contract_line.item_description,
                                quantity = rec_contract_line.quantity,
                                contract_line_start_date = rec_contract_line.contract_line_start_date,
                                contract_line_end_date = rec_contract_line.contract_line_end_date,
                                contract_line_billing_freq = rec_contract_line.contract_line_billing_freq,
                                payment_term = rec_contract_line.payment_term,
                                uom_code = rec_contract_line.uom_code,
                                contract_line_amount = rec_contract_line.total_amount,
                                program = rec_contract_line.program,
                                cancellation_date = rec_contract_line.cancellation_date,
                                last_update_date = SYSDATE,   --rec_contract_line.last_update_date,
                                last_updated_by = rec_contract_line.last_updated_by,
                                last_update_login = rec_contract_line.last_update_login,
                                program_id = rec_contract_line.program_id
                            WHERE  contract_id = rec_contract_line.contract_id
                            AND    contract_line_number = rec_contract_line.contract_line_number
                            AND    contract_line_billing_freq = rec_contract_line.contract_line_billing_freq;

                            IF (SQL%ROWCOUNT <> 0)
                            THEN
                                fnd_file.put_line(fnd_file.LOG,
                                                     'XX_AR_CONTRACT_LINES got updated for contract id: '
                                                  || rec_contract_line.contract_id
                                                  || ' and line number: '
                                                  || rec_contract_line.contract_line_number);

                                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                                THEN
                                    fnd_log.STRING(fnd_log.level_statement,
                                                   'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                                      'XX_AR_CONTRACT_LINES got updated for contract id: '
                                                   || rec_contract_line.contract_id
                                                   || ' and line number: '
                                                   || rec_contract_line.contract_line_number);
                                END IF;
                            ELSE
                                INSERT INTO xx_ar_contract_lines
                                            (contract_id,
                                             contract_line_number,
                                             initial_order_line,
                                             item_name,
                                             item_description,
                                             quantity,
                                             contract_line_start_date,
                                             contract_line_end_date,
                                             contract_line_billing_freq,
                                             payment_term,
                                             uom_code,
                                             contract_line_amount,
                                             program,
                                             cancellation_date,
                                             creation_date,
                                             last_update_date,
                                             created_by,
                                             last_updated_by,
                                             last_update_login,
                                             program_id)
                                VALUES      (rec_contract_line.contract_id,
                                             rec_contract_line.contract_line_number,
                                             rec_contract_line.initial_order_line,
                                             rec_contract_line.item_name,
                                             rec_contract_line.item_description,
                                             rec_contract_line.quantity,
                                             rec_contract_line.contract_line_start_date,
                                             rec_contract_line.contract_line_end_date,
                                             rec_contract_line.contract_line_billing_freq,
                                             rec_contract_line.payment_term,
                                             rec_contract_line.uom_code,
                                             rec_contract_line.total_amount,
                                             rec_contract_line.program,
                                             rec_contract_line.cancellation_date,
                                             rec_contract_line.creation_date,
                                             SYSDATE,   --rec_contract_line.last_update_date,
                                             rec_contract_line.created_by,
                                             rec_contract_line.last_updated_by,
                                             rec_contract_line.last_update_login,
                                             rec_contract_line.program_id);
                            END IF;

                            ln_con_line_count :=   ln_con_line_count
                                                 + 1;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                errbuff :=
                                       'Exception raised while populating xx_ar_contract_lines for contract Id: '
                                    || rec_contracts_header.contract_id
                                    || ' and line: '
                                    || rec_contract_line.contract_line_number
                                    || ' - '
                                    || SQLERRM;
                                fnd_file.put_line(fnd_file.LOG,
                                                  errbuff);

                                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                                THEN
                                    fnd_log.STRING(fnd_log.level_statement,
                                                   'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                                   errbuff);
                                END IF;

                                EXIT;
                        END;
                    END LOOP;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        errbuff :=
                               'Exception raised while populating XX_AR_CONTRACTS for contract Id: '
                            || rec_contracts_header.contract_id
                            || ' - '
                            || SQLERRM;
                        fnd_file.put_line(fnd_file.LOG,
                                          errbuff);

                        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                        THEN
                            fnd_log.STRING(fnd_log.level_statement,
                                           'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                           errbuff);
                        END IF;

                        EXIT;
                END;
            END LOOP;

            IF NVL(ln_con_header_count,
                   0) = 0
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'No valid records are imported for processing. ');

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                   'No valid records are imported for processing. ');
                END IF;
            ELSE
                fnd_file.put_line(fnd_file.LOG,
                                     'Count of records populated on xx_ar_contracts is: '
                                  || ln_con_header_count);
                fnd_file.put_line(fnd_file.LOG,
                                     'Count of records populated on xx_ar_contract_lines is: '
                                  || ln_con_line_count);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                      'Count of records populated on xx_ar_contracts is: '
                                   || ln_con_header_count);
                END IF;

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                      'Count of records populated on xx_ar_contract_lines is: '
                                   || ln_con_line_count);
                END IF;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                errbuff :=    'Unhandled exception raised while inserting records in Contracts table: '
                           || SQLERRM;
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                   errbuff);
                END IF;
        END;

        -- Start truncating table
        BEGIN
            SELECT COUNT(*)
            INTO   ln_con_record_count
            FROM   xx_ar_contracts_gtt
            WHERE  program_id = lv_con_request_id;

            IF ln_con_record_count = ln_con_line_count
            THEN
                fnd_file.put_line
                        (fnd_file.LOG,
                         'All records are inserted in Contracts table and hence truncating XX_AR_CONTRACTS_GTT table. ');

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING
                        (fnd_log.level_statement,
                         'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                         'All records are inserted in Contracts table and hence truncating XX_AR_CONTRACTS_GTT table. ');
                END IF;

                DELETE      xx_ar_contracts_gtt;

                COMMIT;
            ELSE
                fnd_file.put_line(fnd_file.LOG,
                                  'All records are not inserted in Contracts table. ');

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                   'All records are not inserted in Contracts table. ');
                END IF;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                errbuff :=
                       'Unhandled exception raised while checking if all records are inserted in contracts tables. '
                    || SQLERRM;
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                                   errbuff);
                END IF;
        END;
    EXCEPTION
        WHEN OTHERS
        THEN
            errbuff :=
                   'Unexpected Error in XX_AR_CONTRACTS_PKG.import_contracts: '
                || DBMS_UTILITY.format_error_backtrace
                || SQLERRM;
            fnd_file.put_line(fnd_file.LOG,
                              errbuff);

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
                fnd_log.STRING(fnd_log.level_statement,
                               'XX_AR_SUBSCRIPTIONS_PKG.import_contracts',
                               errbuff);
            END IF;
    END import_contracts;

    PROCEDURE import_rec_bills(
        errbuff  OUT  VARCHAR2,
        retcode  OUT  VARCHAR2)
    IS
--------------------------------------------------
-- Cursor Declaration
--------------------------------------------------
        CURSOR cur_rec_bill(
            p_program_id_in  NUMBER)
        IS
            SELECT *
            FROM   xx_ar_subscriptions_gtt
            WHERE  program_id = p_program_id_in;

        -- Start variable declaration by JAI_CG
        lv_appl_short_name_in    VARCHAR2(10)                                := 'XXFIN';
        lv_program_in            VARCHAR2(100)                               := 'XX_AR_SUBSCRIPTIONS_PRG';
        lv_description_in        VARCHAR2(100)                        := 'OD: AR Process Recurring Subscriptions Loader';
        lv_file_loc              xx_fin_translatevalues.target_value1%TYPE   := '$XXFIN_DATA/inbound';
        lv_request_id_num        NUMBER                                      := 0;
        lv_request_complete_bln  BOOLEAN;
        lv_phase_txt             VARCHAR2(20);
        lv_status_txt            VARCHAR2(20);
        lv_dev_phase_txt         VARCHAR2(20);
        lv_dev_status_txt        VARCHAR2(20);
        lv_message_txt           VARCHAR2(200);
        ln_record_count          NUMBER                                      := 0;
        ln_staging_count         NUMBER                                      := 0;
        l_order_number           VARCHAR2(120)                               := NULL;
    -- End variable declaration by JAI_CG
    BEGIN
        fnd_file.put_line(fnd_file.LOG,
                          '***************************************');   -- Added by JAI_CG
        fnd_file.put_line(fnd_file.LOG,
                          'Starting import_rec_bills routine. ');
        fnd_file.put_line(fnd_file.LOG,
                          '***************************************');

        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
        THEN
            fnd_log.STRING(fnd_log.level_statement,
                           'XX_AR_SUBSCRIPTIONS_PKG.import_rec_bills',
                           'Starting import_rec_bills. ');
        END IF;

        BEGIN
            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
                fnd_log.STRING(fnd_log.level_statement,
                               'XX_AR_SUBSCRIPTIONS_PKG.import_rec_bills',
                                  'Before Submitting Concurrent_program:'
                               || lv_program_in);
            END IF;

            lv_request_id_num :=
                fnd_request.submit_request(application =>      lv_appl_short_name_in,
                                           program =>          lv_program_in,
                                           description =>      lv_description_in,
                                           start_time =>       TO_CHAR(SYSDATE,
                                                                       'YYYY-MM-DD HH24:MI:SS'),
                                           sub_request =>      FALSE
                                                                    --argument1 => lv_file_loc ,
                                                                    --argument2 => lv_file_name
                                          );

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
                fnd_log.STRING(fnd_log.level_statement,
                               'XX_AR_SUBSCRIPTIONS_PKG.import_rec_bills',
                                  'After Submitting Concurrent_program:'
                               || lv_program_in);
            END IF;

            COMMIT;

            IF lv_request_id_num = 0
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  '************************************************');
                fnd_file.put_line(fnd_file.LOG,
                                     'Conc. Program  failed to submit :'
                                  || lv_description_in);
                fnd_file.put_line(fnd_file.LOG,
                                  '************************************************');

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_rec_bills',
                                      'Conc. Program  failed to submit :'
                                   || lv_description_in);
                END IF;

                --l_loader_success := 'N';
                retcode := 2;
            ELSE
                fnd_file.put_line(fnd_file.LOG,
                                  '************************************************');
                fnd_file.put_line(fnd_file.LOG,
                                     'Program is successfully Submitted , Request Id :'
                                  || lv_request_id_num);
                fnd_file.put_line(fnd_file.LOG,
                                  '************************************************');

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_rec_bills',
                                      'Program is successfully Submitted , Request Id :'
                                   || lv_request_id_num);
                END IF;

                lv_request_complete_bln :=
                    fnd_concurrent.wait_for_request(request_id =>      lv_request_id_num,
                                                    phase =>           lv_phase_txt,
                                                    status =>          lv_status_txt,
                                                    dev_phase =>       lv_dev_phase_txt,
                                                    dev_status =>      lv_dev_status_txt,
                                                    MESSAGE =>         lv_message_txt);

                IF     UPPER(lv_dev_status_txt) = 'NORMAL'
                   AND UPPER(lv_dev_phase_txt) = 'COMPLETE'
                THEN
                    fnd_file.put_line
                            (fnd_file.LOG,
                                'OD: AR Process Recurring Subscriptions Loader program successful for the Request Id: '
                             || lv_request_id_num
                             || '. ');

                    IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                    THEN
                        fnd_log.STRING
                            (fnd_log.level_statement,
                             'XX_AR_SUBSCRIPTIONS_PKG.import_rec_bills',
                                'OD: AR Process Recurring Subscriptions Loader program successful for the Request Id: '
                             || lv_request_id_num
                             || '. ');
                    END IF;

                    UPDATE xx_ar_subscriptions_gtt
                    SET program_id = lv_request_id_num,
                        creation_date = SYSDATE,
                        last_update_date = SYSDATE,
                        created_by = fnd_global.user_id,
                        last_updated_by = fnd_global.user_id,
                        last_update_login = fnd_global.login_id
                    WHERE  program_id IS NULL
                    AND    invoice_interfaced_flag = 'N';

                    COMMIT;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Staging table has been updated with request_id. '
                                      || lv_request_id_num);
                ELSE
                    fnd_file.put_line(fnd_file.LOG,
                                      'SQL Loader Program does not completed normally. ');
                    --l_loader_success := 'N';
                    retcode := 2;
                END IF;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  '**********************************************');
                fnd_file.put_line(fnd_file.LOG,
                                     'Exception In Submit Conc. Program :'
                                  || '-'
                                  || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                  '**********************************************');
                --l_loader_success := 'N';
                retcode := 2;   -- Terminate the program
        END;

        BEGIN
            -- Start populating contract tables
            FOR rec_rec_bill IN cur_rec_bill(lv_request_id_num)
            LOOP
                ln_record_count :=   ln_record_count
                                   + 1;

                -- Updating initial order number in staging table
                BEGIN
                    SELECT xac.initial_order_number
                    INTO   l_order_number
                    FROM   xx_ar_contracts xac, xx_ar_subscriptions_gtt xas
                    WHERE  xac.contract_id = xas.contract_id
                    AND    xas.contract_number = rec_rec_bill.contract_number
                    AND    contract_line_number = rec_rec_bill.contract_line_number
                    AND    billing_sequence_number = rec_rec_bill.billing_sequence_number;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        l_order_number := NULL;
                        errbuff :=
                               'Exception raised while fetching Initial Order: '
                            || DBMS_UTILITY.format_error_backtrace
                            || SQLERRM;
                        fnd_file.put_line(fnd_file.LOG,
                                          errbuff);

                        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                        THEN
                            fnd_log.STRING(fnd_log.level_statement,
                                           'XX_AR_SUBSCRIPTIONS_PKG.import_rec_bills',
                                           errbuff);
                        END IF;
                END;

                BEGIN
                    UPDATE xx_ar_subscriptions
                    SET subscriptions_id = rec_rec_bill.subscriptions_id,
                        contract_id = rec_rec_bill.contract_id,
                        contract_name = rec_rec_bill.contract_name,
                        billing_date = rec_rec_bill.billing_date,
                        contract_line_amount = rec_rec_bill.contract_line_amount,
                        payment_terms = rec_rec_bill.payment_terms,
                        uom_code = rec_rec_bill.uom_code,
                        service_period_start_date = rec_rec_bill.service_period_start_date,
                        service_period_end_date = rec_rec_bill.service_period_end_date,
                        next_billing_date = rec_rec_bill.next_billing_date,
                        invoice_interfaced_flag = rec_rec_bill.invoice_interfaced_flag,
                        initial_order_number = l_order_number,
                        last_update_date = SYSDATE,   --rec_rec_bill.last_update_date,
                        last_updated_by = rec_rec_bill.last_updated_by,
                        last_update_login = rec_rec_bill.last_update_login,
                        program_id = rec_rec_bill.program_id,
                        auth_completed_flag = 'N',
                        invoice_number = NULL,
                        receipt_number = NULL,
                        invoice_created_flag = 'N',
                        receipt_created_flag = 'N',
                        total_contract_amount = NULL,
                        tax_amount = NULL,
                        authorization_code = NULL,
                        auth_transactionid = NULL,
                        auth_transaction_message = NULL,
                        auth_status = NULL,
                        auth_message = NULL,
                        auth_avs_code = NULL,
                        auth_datetime = NULL,
                        email_sent_flag = 'N',
                        history_sent_flag = 'N',
                        ordt_staged_flag = 'N'
                    WHERE  contract_number = rec_rec_bill.contract_number
                    AND    contract_line_number = rec_rec_bill.contract_line_number
                    AND    billing_sequence_number = rec_rec_bill.billing_sequence_number;

                    IF (SQL%ROWCOUNT <> 0)
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'XX_AR_SUBSCRIPTIONS got updated for contract number: '
                                          || rec_rec_bill.contract_number);

                        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                        THEN
                            fnd_log.STRING(fnd_log.level_statement,
                                           'XX_AR_SUBSCRIPTIONS_PKG.import_rec_bills',
                                              'XX_AR_SUBSCRIPTIONS got updated for contract number: '
                                           || rec_rec_bill.contract_number);
                        END IF;
                    ELSE
                        INSERT INTO xx_ar_subscriptions
                                    (subscriptions_id,
                                     contract_id,
                                     contract_number,
                                     contract_name,
                                     contract_line_number,
                                     billing_date,
                                     contract_line_amount,
                                     billing_sequence_number,
                                     payment_terms,
                                     uom_code,
                                     service_period_start_date,
                                     service_period_end_date,
                                     next_billing_date,
                                     invoice_interfaced_flag,
                                     initial_order_number,
                                     creation_date,
                                     last_update_date,
                                     created_by,
                                     last_updated_by,
                                     last_update_login,
                                     program_id,
                                     email_sent_flag,
                                     history_sent_flag,
                                     ordt_staged_flag,
                                     invoice_created_flag,
                                     receipt_created_flag,
                                     auth_completed_flag)
                        VALUES      (rec_rec_bill.subscriptions_id,
                                     rec_rec_bill.contract_id,
                                     rec_rec_bill.contract_number,
                                     rec_rec_bill.contract_name,
                                     rec_rec_bill.contract_line_number,
                                     rec_rec_bill.billing_date,
                                     rec_rec_bill.contract_line_amount,
                                     rec_rec_bill.billing_sequence_number,
                                     rec_rec_bill.payment_terms,
                                     rec_rec_bill.uom_code,
                                     rec_rec_bill.service_period_start_date,
                                     rec_rec_bill.service_period_end_date,
                                     rec_rec_bill.next_billing_date,
                                     rec_rec_bill.invoice_interfaced_flag,
                                     l_order_number,
                                     rec_rec_bill.creation_date,
                                     SYSDATE,   --rec_rec_bill.last_update_date,
                                     rec_rec_bill.created_by,
                                     rec_rec_bill.last_updated_by,
                                     rec_rec_bill.last_update_login,
                                     rec_rec_bill.program_id,
                                     'N',
                                     'N',
                                     'N',
                                     'N',
                                     'N',
                                     'N');
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        errbuff :=
                               'Exception raised while populating XX_AR_SUBSCRIPTIONS for contract Id: '
                            || rec_rec_bill.contract_id
                            || ' - '
                            || SQLERRM;
                        fnd_file.put_line(fnd_file.LOG,
                                          errbuff);

                        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                        THEN
                            fnd_log.STRING(fnd_log.level_statement,
                                           'XX_AR_SUBSCRIPTIONS_PKG.import_rec_bills',
                                           errbuff);
                        END IF;

                        EXIT;
                END;

                COMMIT;
                -- Updating total contract amount for subscriptions
                update_staging(errbuff =>           errbuff,
                               retcode =>           retcode,
                               p_contract =>        rec_rec_bill.contract_number,
                               p_request_id =>      rec_rec_bill.program_id);
            END LOOP;

            IF NVL(ln_record_count,
                   0) = 0
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'No valid records are imported for processing. ');

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_rec_bills',
                                   'No valid records are imported for processing. ');
                END IF;
            ELSE
                fnd_file.put_line(fnd_file.LOG,
                                     'Count of records populated on xx_ar_subscriptions is: '
                                  || ln_record_count);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_rec_bills',
                                      'Count of records populated on xx_ar_subscriptions is: '
                                   || ln_record_count);
                END IF;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                errbuff :=    'Unhandled exception raised while inserting records in subscriptions table: '
                           || SQLERRM;
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_rec_bills',
                                   errbuff);
                END IF;
        END;

        -- Start truncating table
        BEGIN
            SELECT COUNT(*)
            INTO   ln_staging_count
            FROM   xx_ar_subscriptions_gtt
            WHERE  program_id = lv_request_id_num;

            fnd_file.put_line(fnd_file.LOG,
                                 'ln_record_count: '
                              || ln_record_count
                              || ' - ln_staging_count: '
                              || ln_staging_count);

            IF ln_record_count = ln_staging_count
            THEN
                fnd_file.put_line
                    (fnd_file.LOG,
                     'All records are inserted in Subscriptions table and hence truncating XX_AR_SUBSCRIPTIONS_GTT table. ');

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING
                        (fnd_log.level_statement,
                         'XX_AR_SUBSCRIPTIONS_PKG.import_rec_bills',
                         'All records are inserted in Subscriptions table
                                                       and hence truncating XX_AR_SUBSCRIPTIONS_GTT table. ');
                END IF;

                DELETE      xx_ar_subscriptions_gtt;

                COMMIT;
            ELSE
                fnd_file.put_line(fnd_file.LOG,
                                  'All records are not inserted in XX_AR_SUBSCRIPTIONS_GTT table. ');

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_rec_bills',
                                   'All records are not inserted in XX_AR_SUBSCRIPTIONS_GTT table. ');
                END IF;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                errbuff :=
                       'Unhandled exception raised while checking if all records are inserted in contracts tables. '
                    || SQLERRM;
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.import_rec_bills',
                                   errbuff);
                END IF;
        END;
    EXCEPTION
        WHEN OTHERS
        THEN
            errbuff :=
                   'Unexpected Error in XX_AR_CONTRACTS_PKG.import_rec_bills: '
                || DBMS_UTILITY.format_error_backtrace
                || SQLERRM;
            fnd_file.put_line(fnd_file.LOG,
                              errbuff);

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
                fnd_log.STRING(fnd_log.level_statement,
                               'XX_AR_SUBSCRIPTIONS_PKG.import_rec_bills',
                               errbuff);
            END IF;
    END import_rec_bills;

    PROCEDURE gl_account_string(
        errbuff          OUT     VARCHAR2,
        retcode          OUT     VARCHAR2,
        p_contract       IN      VARCHAR2,
        p_contract_line  IN      NUMBER,
        p_billing_seq    IN      NUMBER,
        p_order_number   IN      VARCHAR2,
        p_rev_account    IN      VARCHAR2,
        p_acc_class      IN      VARCHAR2,
        x_company        OUT     VARCHAR2,
        x_costcenter     OUT     VARCHAR2,
        x_account        OUT     VARCHAR2,
        x_location       OUT     VARCHAR2,
        x_intercompany   OUT     VARCHAR2,
        x_lob            OUT     VARCHAR2,
        x_future         OUT     VARCHAR2,
        x_ccid           OUT     VARCHAR2)
    IS
        gt_tbl_ora_segments     fnd_flex_ext.segmentarray;
        ln_ship_from_org_id     oe_order_lines_all.ship_from_org_id%TYPE               := NULL;
        lc_embed_ship_to_state  xx_om_header_attributes_all.ship_to_state%TYPE         := NULL;
        lc_tax_loc              hr_lookups.meaning%TYPE                                := NULL;
        lc_store_loc            VARCHAR2(30)                                           := 'STORE%';
        lc_ora_company          gl_code_combinations.segment1%TYPE;
        lc_ora_cost_center      gl_code_combinations.segment2%TYPE                     := '00000';
        lc_ora_account          gl_code_combinations.segment3%TYPE;
        lc_ora_location         gl_code_combinations.segment4%TYPE;
        lc_sys_ora_location     gl_code_combinations.segment4%TYPE                     := NULL;   -- Declared variable for Defect #2569 V 2.92
        lc_ora_intercompany     gl_code_combinations.segment5%TYPE                     := '0000';
        lc_ora_lob              gl_code_combinations.segment6%TYPE                     := '10';
        lc_ora_future           gl_code_combinations.segment7%TYPE                     := '000000';
        ln_ccid                 NUMBER;
        ln_order_source_id      NUMBER;
        ln_created_by_store_id  xx_om_header_attributes_all.created_by_store_id%TYPE;
        lc_country_value        xx_fin_translatevalues.source_value1%TYPE              := NULL;
        lc_ou_name              hr_operating_units.NAME%TYPE                           := NULL;
        lc_sys_account          VARCHAR2(120);
        lc_sys_location         VARCHAR2(120);
        lc_delivery_code        xx_om_header_attributes_all.delivery_code%TYPE;
        lc_order_type           xx_om_header_attributes_all.od_order_type%TYPE;
        lc_tax_state            VARCHAR2(2)                                            := NULL;
        lc_ship_from_state      hr_locations_all.region_1%TYPE;
        lc_ship_to_state        hz_locations.state%TYPE;
        ln_poe_order_source_id  NUMBER;
        ln_spc_order_source_id  NUMBER;
        ln_pro_order_source_id  NUMBER;
        lc_gl_acc_start1        xx_fin_translatevalues.source_value1%TYPE;
        lc_gl_acc_start2        xx_fin_translatevalues.source_value2%TYPE;
        lc_gl_acc_start3        xx_fin_translatevalues.source_value3%TYPE;
        lc_gl_acc_start4        xx_fin_translatevalues.source_value4%TYPE;
        lc_gl_acc_start5        xx_fin_translatevalues.source_value5%TYPE;
        lc_gl_acc_start6        xx_fin_translatevalues.source_value6%TYPE;
        lc_gl_acc_start7        xx_fin_translatevalues.source_value7%TYPE;
        lc_gl_acc_start9        xx_fin_translatevalues.source_value8%TYPE;
        lc_cc1                  xx_fin_translatevalues.target_value1%TYPE;
        lc_cc2                  xx_fin_translatevalues.target_value2%TYPE;
        lc_cc3                  xx_fin_translatevalues.target_value3%TYPE;
        lc_cc4                  xx_fin_translatevalues.target_value4%TYPE;
        lc_cc5                  xx_fin_translatevalues.target_value5%TYPE;
        lc_cc6                  xx_fin_translatevalues.target_value6%TYPE;
        lc_cc7                  xx_fin_translatevalues.target_value7%TYPE;
        lc_cc9                  xx_fin_translatevalues.target_value8%TYPE;
        lc_concat_segments      VARCHAR2(2000);
        lc_ccid_enabled_flag    VARCHAR2(1);
        lb_return               BOOLEAN;
        lc_ccid_exist_flag      VARCHAR2(1);
        ln_user_id              NUMBER;
        ln_resp_id              NUMBER;
        ln_resp_appl_id         NUMBER;
        lc_sob_name             xx_fin_translatevalues.target_value1%TYPE              := NULL;
        ln_sob_id               gl_ledgers.ledger_id%TYPE;
        ln_coa_id               gl_ledgers.chart_of_accounts_id%TYPE;
        ln_tot_segments         NUMBER(1)                                              := 7;
    BEGIN
        BEGIN
            SELECT ool.ship_from_org_id,
                   xxoh.created_by_store_id,
                   xxoh.od_order_type,
                   xxoh.delivery_code,
                   ooh.order_source_id,
                   xxoh.ship_to_state
            INTO   ln_ship_from_org_id,
                   ln_created_by_store_id,
                   lc_order_type,
                   lc_delivery_code,
                   ln_order_source_id,
                   lc_embed_ship_to_state
            FROM   xx_ar_subscriptions xas,
                   xx_ar_contracts xac,
                   oe_order_headers_all ooh,
                   oe_order_lines_all ool,
                   xx_om_header_attributes_all xxoh
            WHERE  xas.contract_id = xac.contract_id
            AND    xas.contract_number = p_contract
            AND    xas.billing_sequence_number = p_billing_seq
            AND    xas.contract_line_number = p_contract_line   --1
            AND    xac.initial_order_number = ooh.orig_sys_document_ref
            AND    ooh.header_id = ool.header_id
            AND    ooh.org_id = ool.org_id
            AND    xxoh.header_id = ooh.header_id
            AND    ROWNUM = 1;
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Exception raised while fetching Ship From Org for contract: '
                                  || p_contract
                                  || ' - '
                                  || SQLERRM);
        END;

        BEGIN
            SELECT SUBSTR(hla.location_code,
                          1,
                          6),
                   DECODE(hla.country,
                          'US', hla.region_2,
                          hla.region_1),
                   hl.meaning
            INTO   lc_sloc,
                   lc_ship_from_state,
                   lc_sloc_type
            FROM   hr_lookups hl, hr_locations_all hla, hr_all_organization_units haou
            WHERE  haou.TYPE = hl.lookup_code
            AND    haou.location_id = hla.location_id
            AND    haou.organization_id = ln_ship_from_org_id
            AND    hl.lookup_type = 'ORG_TYPE'
            AND    hl.enabled_flag = 'Y';
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Exception raised while fetching Location for contract: '
                                  || p_contract
                                  || ' - '
                                  || SQLERRM);
        END;

        BEGIN
            SELECT SUBSTR(hla.location_code,
                          1,
                          6),
                   hl.meaning
            INTO   lc_oloc,
                   lc_oloc_type
            FROM   hr_lookups hl, hr_locations_all hla, hr_all_organization_units haou
            WHERE  haou.TYPE = hl.lookup_code
            AND    haou.location_id = hla.location_id
            AND    haou.organization_id = ln_created_by_store_id
            AND    hl.lookup_type = 'ORG_TYPE'
            AND    hl.enabled_flag = 'Y';
        EXCEPTION
            WHEN OTHERS
            THEN
                lc_oloc := NULL;
                lc_oloc_type := NULL;
                fnd_file.put_line(fnd_file.LOG,
                                     'Exception raised while fetching Store Location for contract: '
                                  || p_contract
                                  || ' - '
                                  || SQLERRM);
        END;

        SELECT hca.attribute18
        INTO   lc_customer_type   -- CONTRACT
        FROM   hz_cust_accounts_all hca
        WHERE  hca.cust_account_id = get_customer(p_order_number,
                                                  'BILL_TO');

        fnd_file.put_line(fnd_file.LOG,
                             'lc_customer_type: '
                          || lc_customer_type);

        -- Start Account Derivation
        BEGIN
            fnd_file.put_line(fnd_file.LOG,
                              'Deriving the Account Segment and Location from System Options');

            SELECT val.source_value1,
                   hou.NAME
            INTO   lc_country_value,
                   lc_ou_name
            FROM   xx_fin_translatedefinition def, xx_fin_translatevalues val, hr_operating_units hou
            WHERE  def.translate_id = val.translate_id
            AND    def.translation_name = 'OD_COUNTRY_DEFAULTS'
            AND    val.target_value2 = hou.NAME
            AND    hou.organization_id = fnd_profile.VALUE('ORG_ID');

            SELECT val.target_value1,
                   gll.ledger_id,
                   gll.chart_of_accounts_id
            INTO   lc_sob_name,
                   ln_sob_id,
                   ln_coa_id
            FROM   xx_fin_translatedefinition def, xx_fin_translatevalues val, gl_ledgers gll
            WHERE  def.translate_id = val.translate_id
            AND    def.translation_name = 'OD_COUNTRY_DEFAULTS'
            AND    val.source_value1 = lc_country_value
            AND    gll.short_name = val.target_value1;

            SELECT segment3,
                   segment4
            INTO   lc_sys_account,
                   lc_sys_location
            FROM   gl_code_combinations gcc,
                   ar_system_parameters_all asp   -- Changed for R12 Retrofit ar_system_parameters ASP
            WHERE  gcc.code_combination_id = asp.location_tax_account
            AND    set_of_books_id = ln_sob_id
            AND    asp.attribute_category = lc_country_value;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'NO_DATA_FOUND: Unable to derive Account Segment and Location from System Options');
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'EXCEPTION: Unable to derive Account Segmentfrom System Options for Tax Line'
                                  || SQLERRM);
        END;

        fnd_file.put_line(fnd_file.LOG,
                             'lc_ora_account for: '
                          || p_rev_account);

        IF p_acc_class = 'REV'
        THEN
            lc_ora_account := p_rev_account;
            fnd_file.put_line(fnd_file.LOG,
                                 'lc_ora_account for Revenue is: '
                              || p_rev_account);
        ELSIF p_acc_class = 'TAX'
        THEN
            lc_ora_cost_center := '00000';
            lc_ora_lob := '90';

            BEGIN
                SELECT segment3
                INTO   lc_ora_account
                FROM   gl_code_combinations gcc,
                       ar_system_parameters_all asp   -- Changed for R12 Retrofit ar_system_parameters ASP
                WHERE  gcc.code_combination_id = asp.location_tax_account
                AND    set_of_books_id = ln_sob_id
                AND    asp.attribute_category = lc_country_value;
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'Exception raised while fetching lc_ora_account: '
                                      || SQLERRM);
            END;

            fnd_file.put_line(fnd_file.LOG,
                                 'lc_ora_account: '
                              || lc_ora_account
                              || ' for SOB: '
                              || ln_sob_id
                              || ' and country: '
                              || lc_country_value);
        END IF;

        IF     NVL(lc_oloc_type,
                   1) LIKE lc_store_loc
           AND lc_sloc_type LIKE lc_store_loc
        THEN
            --Code added for defect 3287. replaced the above sql with the below two lines.
            SELECT ffv.attribute1
            INTO   lc_ora_company
            FROM   fnd_flex_values ffv, fnd_flex_value_sets ffvs
            WHERE  ffv.flex_value_set_id = ffvs.flex_value_set_id
            AND    ffvs.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
            AND    ffv.flex_value =(LTRIM(RTRIM(lc_oloc) ) );

            --lc_ora_company  := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(LTRIM(RTRIM(lc_oloc)));
            lc_ora_location := LTRIM(RTRIM(lc_oloc) );
            x_company := lc_ora_company;
            x_costcenter := lc_ora_cost_center;
            x_account := lc_ora_account;
            x_location := lc_ora_location;
            x_intercompany := lc_ora_intercompany;
            x_lob := lc_ora_lob;
            x_future := lc_ora_future;
        ELSIF     NVL(lc_oloc_type,
                      1) LIKE lc_store_loc
              AND lc_sloc_type NOT LIKE lc_store_loc
        THEN
            --Code added for defect 3287. replaced the above sql with the below two lines.
            SELECT ffv.attribute1
            INTO   lc_ora_company
            FROM   fnd_flex_values ffv, fnd_flex_value_sets ffvs
            WHERE  ffv.flex_value_set_id = ffvs.flex_value_set_id
            AND    ffvs.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
            AND    ffv.flex_value =(LTRIM(RTRIM(lc_oloc) ) );

            --lc_ora_company  := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(LTRIM(RTRIM(lc_oloc)));
            lc_ora_location := LTRIM(RTRIM(lc_oloc) );
            x_company := lc_ora_company;
            x_costcenter := lc_ora_cost_center;
            x_account := lc_ora_account;
            x_location := lc_ora_location;
            x_intercompany := lc_ora_intercompany;
            x_lob := lc_ora_lob;
            x_future := lc_ora_future;
        ELSIF     NVL(lc_oloc_type,
                      1) NOT LIKE lc_store_loc
              AND lc_sloc_type LIKE lc_store_loc
        THEN
            --Code added for defect 3287. replaced the above sql with the below two lines.
            SELECT ffv.attribute1
            INTO   lc_ora_company
            FROM   fnd_flex_values ffv, fnd_flex_value_sets ffvs
            WHERE  ffv.flex_value_set_id = ffvs.flex_value_set_id
            AND    ffvs.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
            AND    ffv.flex_value =(LTRIM(RTRIM(lc_sloc) ) );

            --lc_ora_company  := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(LTRIM(RTRIM(lc_sloc)));
            lc_ora_location := LTRIM(RTRIM(lc_sloc) );
            x_company := lc_ora_company;
            x_costcenter := lc_ora_cost_center;
            x_account := lc_ora_account;
            x_location := lc_ora_location;
            x_intercompany := lc_ora_intercompany;
            x_lob := lc_ora_lob;
            x_future := lc_ora_future;
        ELSIF     NVL(lc_oloc_type,
                      1) NOT LIKE lc_store_loc
              AND lc_sloc_type NOT LIKE lc_store_loc
        THEN
            --Code added for defect 3287. replaced the above sql with the below two lines.
            SELECT ffv.attribute1
            INTO   lc_ora_company
            FROM   fnd_flex_values ffv, fnd_flex_value_sets ffvs
            WHERE  ffv.flex_value_set_id = ffvs.flex_value_set_id
            AND    ffvs.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
            AND    ffv.flex_value =(LTRIM(RTRIM(lc_sloc) ) );

            --lc_ora_company  := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(LTRIM(RTRIM(lc_sloc))); -- 1001
            lc_ora_location := LTRIM(RTRIM(lc_sloc) );   -- 001165
            DBMS_OUTPUT.put_line(   'lc_ora_company: '
                                 || lc_ora_company
                                 || ' - '
                                 || lc_ora_location);

            -- Modified to check the Uppercase of Customer Type on 12-13-07
            IF UPPER(lc_customer_type) = 'DIRECT'
            THEN
                SELECT ffvv.flex_value
                INTO   lc_ora_lob   -- 50
                FROM   fnd_flex_value_sets ffvs, fnd_flex_values_vl ffvv
                WHERE  ffvs.flex_value_set_name = 'OD_GL_GLOBAL_LOB'
                AND    ffvs.flex_value_set_id = ffvv.flex_value_set_id
                AND    UPPER(ffvv.description) = UPPER(lc_customer_type);
            ELSIF UPPER(lc_customer_type) = 'CONTRACT'
            THEN
                SELECT ffvv.flex_value
                INTO   lc_ora_lob   -- 40
                FROM   fnd_flex_value_sets ffvs, fnd_flex_values_vl ffvv
                WHERE  ffvs.flex_value_set_name = 'OD_GL_GLOBAL_LOB'
                AND    ffvs.flex_value_set_id = ffvv.flex_value_set_id
                AND    UPPER(ffvv.description) = UPPER(lc_customer_type);
            END IF;

            x_company := lc_ora_company;
            x_costcenter := lc_ora_cost_center;
            x_account := lc_ora_account;
            x_location := lc_ora_location;
            x_intercompany := lc_ora_intercompany;
            x_lob := lc_ora_lob;
            x_future := lc_ora_future;
            fnd_file.put_line(fnd_file.output,
                                 'Account Segments : '
                              || x_company
                              || '-'
                              || x_costcenter
                              || '-'
                              || x_account
                              || '-'
                              || x_location
                              || '-'
                              || x_intercompany
                              || '-'
                              || x_lob
                              || '-'
                              || x_future);
        END IF;

        SELECT oos1.order_source_id,
               oos3.order_source_id
        INTO   ln_poe_order_source_id,   -- 2015
               ln_pro_order_source_id   -- 1027
        FROM   xx_fin_translatevalues xftv,
               xx_fin_translatedefinition xftd,
               oe_order_sources oos1,
               oe_order_sources oos3
        WHERE  xftv.translate_id = xftd.translate_id
        AND    xftd.translation_name = 'OD_AR_BILLING_SOURCE_EXCL'
        AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    oos1.NAME = xftv.source_value2
        AND    oos3.NAME = xftv.source_value4
        AND    xftv.enabled_flag = 'Y'
        AND    xftd.enabled_flag = 'Y';

        SELECT order_source_id
        INTO   ln_spc_order_source_id
        FROM   oe_order_sources
        WHERE  NAME = 'SPC';

        IF p_acc_class = 'TAX'
        THEN
            IF lc_order_type = 'X'
            THEN
                lc_tax_state := lc_ship_to_state;
            ELSIF    lc_delivery_code = 'P'
                  OR ln_order_source_id IN(ln_poe_order_source_id, ln_spc_order_source_id, ln_pro_order_source_id)
            THEN
                SELECT DECODE(hla.country,
                              'US', hla.region_2,
                              hla.region_1)
                INTO   lc_ship_from_state
                FROM   hr_lookups hl, hr_locations_all hla, hr_all_organization_units haou
                WHERE  haou.TYPE = hl.lookup_code
                AND    haou.location_id = hla.location_id
                AND    haou.organization_id = ln_ship_from_org_id
                AND    hl.lookup_type = 'ORG_TYPE'
                AND    hl.enabled_flag = 'Y';

                lc_tax_state := lc_ship_from_state;
            ELSE
                lc_tax_state := lc_embed_ship_to_state;
            END IF;

            IF lc_tax_state IS NOT NULL
            THEN
                BEGIN
                    SELECT ffv.flex_value
                    INTO   lc_tax_loc
                    FROM   fnd_flex_values ffv, fnd_flex_value_sets ffvs
                    WHERE  ffv.flex_value_set_id = ffvs.flex_value_set_id
                    AND    ffvs.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
                    AND    ffv.flex_value LIKE '8%'
                    AND    ffv.attribute4 = lc_tax_state;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line(fnd_file.output,
                                          'Unable to find SEGMENT4 for Tax Location. ');
                        populate_error(p_contract_id =>               NULL,
                                       p_contract_number =>           p_contract,
                                       p_contract_line_number =>      p_contract_line,
                                       p_billing_sequence =>          p_billing_seq,
                                       p_module =>                    'gl_account_string',
                                       p_error_msg =>                 'Unable to find SEGMENT4 for Tax Location. ');
                END;
            ELSE
                fnd_file.put_line(fnd_file.output,
                                  'Deriving the Segment3 and Location from System Options for Sales Order : ');
            END IF;

            IF lc_sys_ora_location IS NOT NULL
            THEN
                lc_ora_location := lc_sys_ora_location;
            ELSE
                lc_ora_location := LTRIM(RTRIM(lc_tax_loc) );   -- Needs Investigation
            END IF;

            lc_ora_cost_center := '00000';
            lc_ora_lob := '90';
        END IF;

        -- Substituting the hard code of the Cost Center and account with translation values.
        SELECT source_value1,
               source_value2,
               source_value3,
               source_value4,
               source_value5,
               source_value6,
               source_value7,
               source_value8,
               target_value1,
               target_value2,
               target_value3,
               target_value4,
               target_value5,
               target_value6,
               target_value7,
               target_value8
        INTO   lc_gl_acc_start1,
               lc_gl_acc_start2,
               lc_gl_acc_start3,
               lc_gl_acc_start4,
               lc_gl_acc_start5,
               lc_gl_acc_start6,
               lc_gl_acc_start7,
               lc_gl_acc_start9,
               lc_cc1,
               lc_cc2,
               lc_cc3,
               lc_cc4,
               lc_cc5,
               lc_cc6,
               lc_cc7,
               lc_cc9
        FROM   xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
        WHERE  xftd.translate_id = xftv.translate_id
        AND    xftd.translation_name = 'GL_E0080_DEFAULT_CC'
        AND    xftd.enabled_flag = 'Y'
        AND    xftv.enabled_flag = 'Y';

        IF SUBSTR(lc_ora_account,
                  1,
                  1) = lc_gl_acc_start1
        THEN
            lc_ora_cost_center := lc_cc1;
        ELSIF SUBSTR(lc_ora_account,
                     1,
                     1) = lc_gl_acc_start2
        THEN
            lc_ora_cost_center := lc_cc2;
        ELSIF SUBSTR(lc_ora_account,
                     1,
                     1) = lc_gl_acc_start3
        THEN
            lc_ora_cost_center := lc_cc3;
        ELSIF SUBSTR(lc_ora_account,
                     1,
                     1) = lc_gl_acc_start4
        THEN
            lc_ora_cost_center := lc_cc4;
        ELSIF SUBSTR(lc_ora_account,
                     1,
                     1) = lc_gl_acc_start5
        THEN
            lc_ora_cost_center := lc_cc5;
        ELSIF SUBSTR(lc_ora_account,
                     1,
                     1) = lc_gl_acc_start6
        THEN
            lc_ora_cost_center := lc_cc6;
        ELSIF SUBSTR(lc_ora_account,
                     1,
                     1) = lc_gl_acc_start7
        THEN
            lc_ora_cost_center := lc_cc7;
        ELSIF SUBSTR(lc_ora_account,
                     1,
                     1) = lc_gl_acc_start9
        THEN
            lc_ora_cost_center := lc_cc9;
        END IF;

        IF     lc_ora_company IS NOT NULL
           AND lc_ora_cost_center IS NOT NULL
           AND lc_ora_account IS NOT NULL
           AND lc_ora_location IS NOT NULL
           AND lc_ora_intercompany IS NOT NULL
           AND lc_ora_lob IS NOT NULL
           AND lc_ora_future IS NOT NULL
        THEN
            lc_concat_segments :=
                   lc_ora_company
                || '.'
                || lc_ora_cost_center
                || '.'
                || lc_ora_account
                || '.'
                || lc_ora_location
                || '.'
                || lc_ora_intercompany
                || '.'
                || lc_ora_lob
                || '.'
                || lc_ora_future;
            fnd_file.put_line(fnd_file.LOG,
                                 'lc_concat_segments : '
                              || lc_concat_segments);

            BEGIN
                SELECT gcc.code_combination_id,
                       gcc.enabled_flag
                INTO   ln_ccid,
                       lc_ccid_enabled_flag
                FROM   gl_code_combinations gcc, gl_ledgers gll   --Changed for R12 Retrofit gl_sets_of_books     GSB
                WHERE  gcc.segment1 = lc_ora_company
                AND    gcc.segment2 = lc_ora_cost_center
                AND    gcc.segment3 = lc_ora_account
                AND    gcc.segment4 = lc_ora_location
                AND    gcc.segment5 = lc_ora_intercompany
                AND    gcc.segment6 = lc_ora_lob
                AND    gcc.segment7 = lc_ora_future
                AND    gcc.chart_of_accounts_id = gll.chart_of_accounts_id
                AND    gll.ledger_id = fnd_profile.VALUE('GL_SET_OF_BKS_ID');   --Changed for R12 Retrofit GSB.set_of_books_id = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');

                lc_ccid_exist_flag := 'Y';

                IF lc_ccid_enabled_flag <> 'Y'
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'Account Combination is not enabled for Oracle Segment : '
                                      || lc_concat_segments);
                ELSE
                    fnd_file.put_line(fnd_file.LOG,
                                         'Derived '
                                      || p_acc_class
                                      || ' Oracle Segment : '
                                      || lc_concat_segments);
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    lc_ccid_exist_flag := 'N';
            END;

            IF lc_ccid_exist_flag = 'N'
            THEN
                ln_user_id := fnd_global.user_id;
                ln_resp_id := fnd_global.resp_id;
                ln_resp_appl_id := fnd_global.resp_appl_id;
                lb_return :=
                    fnd_flex_keyval.validate_segs(operation =>             'CHECK_COMBINATION',
                                                  appl_short_name =>       'SQLGL',
                                                  key_flex_code =>         'GL#',
                                                  structure_number =>      ln_coa_id,
                                                  concat_segments =>       lc_concat_segments);

                IF lb_return = FALSE
                THEN
                    errbuff :=
                           errbuff
                        || 'GL Cross Validation Rule does not allow to create CCID for Oracle Segments:'
                        || lc_concat_segments;
                    fnd_file.put_line(fnd_file.LOG,
                                      'GL Cross Validation Rule does not allow to create CCID for Oracle Segments');
                ELSE
                    gt_tbl_ora_segments(1) := lc_ora_company;
                    gt_tbl_ora_segments(2) := lc_ora_cost_center;
                    gt_tbl_ora_segments(3) := lc_ora_account;
                    gt_tbl_ora_segments(4) := lc_ora_location;
                    gt_tbl_ora_segments(5) := lc_ora_intercompany;
                    gt_tbl_ora_segments(6) := lc_ora_lob;
                    gt_tbl_ora_segments(7) := lc_ora_future;
                    lb_return :=
                        fnd_flex_ext.get_combination_id(application_short_name =>      'SQLGL',
                                                        key_flex_code =>               'GL#',
                                                        structure_number =>            ln_coa_id,
                                                        validation_date =>             SYSDATE,
                                                        n_segments =>                  ln_tot_segments,
                                                        segments =>                    gt_tbl_ora_segments,
                                                        combination_id =>              ln_ccid);
                    fnd_file.put_line(fnd_file.LOG,
                                         'Account Combination created for '
                                      || p_acc_class
                                      || ' Oracle Segment : '
                                      || lc_concat_segments);
                END IF;

                x_ccid := ln_ccid;
            ELSE
                errbuff := 'To get CCID, all the Oracle segments are required';
            END IF;
        END IF;

        x_company := lc_ora_company;
        x_costcenter := lc_ora_cost_center;
        x_account := lc_ora_account;
        x_location := lc_ora_location;
        x_intercompany := lc_ora_intercompany;
        x_lob := lc_ora_lob;
        x_future := lc_ora_future;
        x_ccid := ln_ccid;
        lc_concat_segments :=
               lc_ora_company
            || '.'
            || lc_ora_cost_center
            || '.'
            || lc_ora_account
            || '.'
            || lc_ora_location
            || '.'
            || lc_ora_intercompany
            || '.'
            || lc_ora_lob
            || '.'
            || lc_ora_future;
        fnd_file.put_line(fnd_file.LOG,
                             'Final  : '
                          || lc_concat_segments);
    EXCEPTION
        WHEN OTHERS
        THEN
            errbuff :=    'Exception raised during gl_account_string: '
                       || SQLERRM;
            fnd_file.put_line(fnd_file.LOG,
                              errbuff);
            populate_error(p_contract_id =>               NULL,
                           p_contract_number =>           p_contract,
                           p_contract_line_number =>      p_contract_line,
                           p_billing_sequence =>          p_billing_seq,
                           p_module =>                    'gl_account_string',
                           p_error_msg =>                 errbuff);
    END gl_account_string;

    PROCEDURE get_tax_line_amount(
        errbuff          OUT     VARCHAR2,
        retcode          OUT     NUMBER,
        p_contract_id    IN      NUMBER,
        p_contract_line  IN      NUMBER,
        p_billing_seq    IN      NUMBER,
        p_request_id_in  IN      NUMBER)
    IS
        request                   UTL_HTTP.req;
        response                  UTL_HTTP.resp;
        n                         NUMBER;
        buff                      VARCHAR2(10000);
        clob_buff                 CLOB;
        lv_input_payload          VARCHAR2(32000)                             := NULL;   --added by Sridhar B.
        ln_tax_line_amount        NUMBER                                      := NULL;
        lv_tax_service_url        xx_fin_translatevalues.target_value1%TYPE   := NULL;
        lv_wallet_location        xx_fin_translatevalues.target_value1%TYPE   := NULL;
        lv_password               xx_fin_translatevalues.target_value2%TYPE   := NULL;
        lv_username               xx_fin_translatevalues.target_value2%TYPE   := NULL;
        lv_subscription_password  xx_fin_translatevalues.target_value3%TYPE   := NULL;
        lv_cust_address1          hz_locations.address1%TYPE                  := NULL;
        lv_cust_address2          hz_locations.address2%TYPE                  := NULL;
        lv_cust_city              hz_locations.city%TYPE                      := NULL;
        lv_cust_state             hz_locations.state%TYPE                     := NULL;
        lv_cust_postal_code       hz_locations.postal_code%TYPE               := NULL;
        lv_cust_country           hz_locations.country%TYPE                   := NULL;
        lv_email_address          hz_contact_points.email_address%TYPE        := NULL;
        lv_fax_number             VARCHAR2(30)                                := NULL;
        lv_phone_number           VARCHAR2(30)                                := NULL;
        l_payload_id              NUMBER                                      := 0;
        l_db_link                 VARCHAR2(120)                               := NULL;   --'RMSDEV02.NA.ODCORP.NET'
        l_item_unit_price         NUMBER;
        l_utem_cost_qry           VARCHAR2(240)                               := NULL;
        ln_random_num             NUMBER                                      := 0;
        l_order_type              oe_transaction_types_tl.NAME%TYPE           := NULL;
        l_order_source            oe_order_sources.NAME%TYPE                  := NULL;

        --Added Cursor by Sridhar B.
        CURSOR c_inv_details
        IS
            SELECT (SELECT account_name
                    FROM   hz_cust_accounts_all
                    WHERE  cust_account_id = xx_ar_subscriptions_pkg.get_customer(xac.initial_order_number,
                                                                                  'BILL_TO') ) customer_name,
                   xac.bill_to_osr,
                   xac.card_token,
                   TO_CHAR(xac.card_expiration_date,
                           'YYMM') card_expiration_date,
                   xac.card_type,
                   xas.invoice_number,
                   xas.contact_person_email,
                   xas.contact_person_phone,
                   xas.contact_person_fax,
                   xac.initial_order_number,
                   xacl.initial_order_line,
                   xacl.item_name service_item_number,
                   xacl.item_description,
                   xacl.quantity,
                   xas.contract_id,
                   xas.program_id,
                   xas.contract_line_amount contract_amount,
                   xacl.contract_line_number,
                   xas.contract_number,
                   xas.billing_sequence_number
            FROM   xx_ar_subscriptions xas, xx_ar_contract_lines xacl, xx_ar_contracts xac
            WHERE  1 = 1
            AND    xas.contract_id = p_contract_id
            AND    xas.contract_id = xacl.contract_id
            AND    xacl.contract_line_number = xas.contract_line_number
            AND    xas.contract_id = xac.contract_id
            AND    xas.program_id = p_request_id_in
            AND    xas.contract_line_number = p_contract_line
            AND    xas.billing_sequence_number = p_billing_seq;
    BEGIN
        BEGIN
            SELECT target_value1
            INTO   lv_tax_service_url
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 = 'TAX_SERVICE';
        EXCEPTION
            WHEN OTHERS
            THEN
                retcode := 2;
                errbuff := 'Error in getting Backup interface Service URL from Translation';
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                populate_error(p_contract_id =>               p_contract_id,
                               p_contract_number =>           NULL,
                               p_contract_line_number =>      p_contract_line,
                               p_billing_sequence =>          p_billing_seq,
                               p_module =>                    'get_tax_line_amount',
                               p_error_msg =>                 errbuff);
                RETURN;
        END;

        fnd_file.put_line(fnd_file.LOG,
                             '--TAX_SERVICE_URL: '
                          || lv_tax_service_url);

        BEGIN
            SELECT target_value1,
                   target_value2
            INTO   lv_wallet_location,
                   lv_password
            FROM   xx_fin_translatevalues val, xx_fin_translatedefinition def
            WHERE  1 = 1
            AND    def.translate_id = val.translate_id
            AND    def.translation_name = 'XX_FIN_IREC_TOKEN_PARAMS'
            AND    val.source_value1 = 'WALLET_LOCATION'
            AND    val.enabled_flag = 'Y'
            AND    SYSDATE BETWEEN val.start_date_active AND NVL(val.end_date_active,
                                                                   SYSDATE
                                                                 + 1);
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_wallet_location := NULL;
                lv_password := NULL;
                retcode := 2;
                errbuff := 'Error in getting Wallet Location from Translation';
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                populate_error(p_contract_id =>               p_contract_id,
                               p_contract_number =>           NULL,
                               p_contract_line_number =>      p_contract_line,
                               p_billing_sequence =>          p_billing_seq,
                               p_module =>                    'get_tax_line_amount',
                               p_error_msg =>                 errbuff);
                RETURN;
        END;

        fnd_file.put_line(fnd_file.LOG,
                             '--lv_wallet_location: '
                          || lv_wallet_location
                          || 'lv_password :'
                          || lv_password);

        BEGIN
            SELECT target_value2,
                   target_value3
            INTO   lv_username,
                   lv_subscription_password
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 = 'TAX_SERVICE'
            AND    vals.enabled_flag = 'Y'
            AND    SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active,
                                                                    SYSDATE
                                                                  + 1);
        EXCEPTION
            WHEN OTHERS
            THEN
                errbuff := 'lv_username Not Found in translations: XX_AR_SUBSCRIPTIONS. ';
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                populate_error(p_contract_id =>               p_contract_id,
                               p_contract_number =>           NULL,
                               p_contract_line_number =>      p_contract_line,
                               p_billing_sequence =>          p_billing_seq,
                               p_module =>                    'get_tax_line_amount',
                               p_error_msg =>                 errbuff);
        END;

        fnd_file.put_line(fnd_file.LOG,
                             'lv_username:'
                          || lv_username);
        fnd_file.put_line(fnd_file.LOG,
                             'lv_subscription_password:'
                          || lv_subscription_password);

        IF lv_wallet_location IS NOT NULL
        THEN
            UTL_HTTP.set_wallet(lv_wallet_location,
                                lv_password);
        END IF;

        UTL_HTTP.set_response_error_check(FALSE);

        -- End
        FOR v_inv_details IN c_inv_details
        LOOP
            BEGIN
                SELECT target_value1
                INTO   l_db_link
                FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
                WHERE  1 = 1
                AND    defn.translate_id = vals.translate_id
                AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
                AND    source_value1 = 'RMS_DB_LINK';

                l_utem_cost_qry :=
                           'SELECT cost FROM MV_SSB@'
                        || l_db_link
                        || ' WHERE item = '
                        || v_inv_details.service_item_number;

                EXECUTE IMMEDIATE l_utem_cost_qry
                INTO              l_item_unit_price;
            --EXECUTE IMMEDIATE 'SELECT cost INTO l_item_unit_Price FROM MV_SSB@'||l_db_link||' WHERE item = '||v_inv_details.service_item_number;
            EXCEPTION
                WHEN OTHERS
                THEN
                    errbuff :=
                           'Exception raised while fetching item cost for item: '
                        || v_inv_details.service_item_number
                        || ' - '
                        || SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                      errbuff);
                    populate_error(p_contract_id =>               p_contract_id,
                                   p_contract_number =>           v_inv_details.contract_number,
                                   p_contract_line_number =>      p_contract_line,
                                   p_billing_sequence =>          p_billing_seq,
                                   p_module =>                    'get_tax_line_amount',
                                   p_error_msg =>                 errbuff);
            END;

            BEGIN
                SELECT hl.address1,
                       hl.address2,
                       hl.city,
                       hl.state,
                       SUBSTRB(hl.postal_code,
                               1,
                               5),
                       hl.country,
                       (SELECT email_address
                        FROM   hz_contact_points hcp
                        WHERE  hcp.owner_table_name = 'HZ_PARTIES'
                        AND    hcp.contact_point_type = 'EMAIL'
                        AND    hcp.owner_table_id = hps.party_id),
                       (SELECT    hcp.phone_country_code
                               || '-'
                               || hcp.phone_area_code
                               || '-'
                               || hcp.phone_number
                        FROM   hz_contact_points hcp
                        WHERE  hcp.owner_table_name = 'HZ_PARTIES'
                        AND    hcp.contact_point_type = 'FAX'
                        AND    hcp.owner_table_id = hps.party_id),
                       (SELECT    hcp.phone_country_code
                               || '-'
                               || hcp.phone_area_code
                               || '-'
                               || hcp.phone_number
                        FROM   hz_contact_points hcp
                        WHERE  hcp.owner_table_name = 'HZ_PARTIES'
                        AND    hcp.contact_point_type = 'PHONE'
                        AND    hcp.owner_table_id = hps.party_id)
                INTO   lv_cust_address1,
                       lv_cust_address2,
                       lv_cust_city,
                       lv_cust_state,
                       lv_cust_postal_code,
                       lv_cust_country,
                       lv_email_address,
                       lv_fax_number,
                       lv_phone_number
                FROM   hz_cust_acct_sites_all hcs, hz_party_sites hps, hz_locations hl
                WHERE  hcs.cust_acct_site_id = get_customer_site(v_inv_details.initial_order_number,
                                                                 'BILL_TO')
                AND    hps.party_site_id = hcs.party_site_id
                AND    hps.location_id = hl.location_id;
            EXCEPTION
                WHEN OTHERS
                THEN
                    lv_cust_address1 := NULL;
                    lv_cust_address2 := NULL;
                    lv_cust_city := NULL;
                    lv_cust_state := NULL;
                    lv_cust_postal_code := NULL;
                    lv_cust_country := NULL;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Exception raised while fetching customer address fro contract id: '
                                      || p_contract_id
                                      || ' - '
                                      || SQLERRM);
            END;

            -- Fetching Order TYPE
            BEGIN
                SELECT ott.NAME
                --, TO_CHAR(ordered_date,'MM/DD/YYYY')
                INTO   l_order_type
                --, l_ordered_date
                FROM   oe_order_headers_all ooh, oe_transaction_types_tl ott
                WHERE  ooh.order_number = v_inv_details.initial_order_number   --'907709514001'
                AND    ooh.order_type_id = ott.transaction_type_id
                AND    ott.LANGUAGE = 'US';
            EXCEPTION
                WHEN OTHERS
                THEN
                    l_order_type := NULL;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Exception raised while fetching Type for order: '
                                      || v_inv_details.initial_order_number
                                      || ' - '
                                      || SQLERRM);
            END;

            -- Fetching order source
            BEGIN
                SELECT oos.NAME
                INTO   l_order_source
                FROM   oe_order_headers_all ooh, oe_order_sources oos
                WHERE  ooh.order_number = v_inv_details.initial_order_number   --'907709514001'
                AND    ooh.order_source_id = oos.order_source_id;
            EXCEPTION
                WHEN OTHERS
                THEN
                    l_order_type := NULL;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Exception raised while fetching Source for order: '
                                      || v_inv_details.initial_order_number
                                      || ' - '
                                      || SQLERRM);
            END;

            BEGIN
                SELECT ROUND(DBMS_RANDOM.VALUE(1,
                                               100),
                             0)
                INTO   ln_random_num
                FROM   DUAL;

                SELECT    '{
  "taxCalculatorRequest": {
    "transactionHeader": {
      "consumerName": "BIZBOX",
      "consumerTransactionId":  "d7007ddb-87gh-48x23-CC8d-'
                       || TO_CHAR(SYSDATE,
                                  'YYYYMMDD')
                       || ''
                       || ln_random_num
                       || '",
      "consumerTransactionDateTime": "'
                       || TO_CHAR(SYSDATE,
                                  'YYYY-MM-DD')
                       || 'T'
                       || TO_CHAR(SYSDATE,
                                  'HH24:MI:SS')
                       || '"
                 },
    "customer": {
      "firstName": "'
                       || v_inv_details.customer_name
                       || '",
      "middleName": "",
      "lastName": "",
      "PaymentDetails": {
        "paymentcard": {
          "cardHighValueToken": "4445221886590007",
          "expirationDate": "1812",
          "cardType": "VISA",
          "amount": "1.00",
          "applicationTransactionNumber": "45632170844",
          "billingAddress": {
            "name": "'
                       || v_inv_details.customer_name
                       || '",
            "address": {
                 "address1": "'
                       || lv_cust_address1
                       || '",
                 "address2": "'
                       || lv_cust_address2
                       || '",
                 "city": "'
                       || lv_cust_city
                       || '",
                 "state": "'
                       || lv_cust_state
                       || '",
                 "postalCode": "'
                       || lv_cust_postal_code
                       || '",
                 "country": "'
                       || lv_cust_country
                       || '"
                 }
                 },
          "shippingAddress": {
                 "name": "'
                       || v_inv_details.customer_name
                       || '",
                 "address": {
                 "address1": "'
                       || lv_cust_address1
                       || '",
                 "address2": "'
                       || lv_cust_address2
                       || '",
                 "city": "'
                       || lv_cust_city
                       || '",
                 "state": "'
                       || lv_cust_state
                       || '",
                 "postalCode": "'
                       || lv_cust_postal_code
                       || '",
                 "country": "'
                       || lv_cust_country
                       || '"
                 }
                 }
                 }
                 },
      "contact": {
                 "email": "'
                       || lv_email_address
                       || '",
                 "phoneNumber": "'
                       || lv_phone_number
                       || '",
                 "faxNumber": "'
                       || lv_fax_number
                       || '"
                 }
                 },
    "order": {
                 "orderType": "Quote",
                 "orderSource": "EBIZ",
                 "orderDate": "'
                       || TO_CHAR(SYSDATE,
                                  'MM/DD/YYYY')
                       || '",
      "orderDetail": {
        "Item": [
          {
            "lineNumber": "1",
            "sku": "267807",
            "quantity": "1",
            "unitPrice": "1.00",
            "description": "test sku 1"
            "comments": "comments"
          }
        ]
      }
    }
  }
}'
                INTO   lv_input_payload
                FROM   DUAL;

                fnd_file.put_line(fnd_file.LOG,
                                     'lv_input_payload: '
                                  || lv_input_payload);
            --dbms_output.put_line('lv_input_payload: ' || lv_input_payload);
            EXCEPTION
                WHEN OTHERS
                THEN
                    errbuff :=    'Exception raised while formatting tax payload: '
                               || SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                      errbuff);
                    populate_error(p_contract_id =>               p_contract_id,
                                   p_contract_number =>           v_inv_details.contract_number,
                                   p_contract_line_number =>      p_contract_line,
                                   p_billing_sequence =>          p_billing_seq,
                                   p_module =>                    'get_tax_line_amount',
                                   p_error_msg =>                 errbuff);
            END;
        END LOOP;

        BEGIN
            --Added below  logic by Sridhar B
            request := UTL_HTTP.begin_request(lv_tax_service_url,
                                              'POST',
                                              ' HTTP/1.1');
            UTL_HTTP.set_header(request,
                                'user-agent',
                                'mozilla/4.0');
            UTL_HTTP.set_header(request,
                                'content-type',
                                'application/json');
            UTL_HTTP.set_header(request,
                                'Content-Length',
                                LENGTH(lv_input_payload) );
            UTL_HTTP.set_header
                   (request,
                    'Authorization',
                       'Basic '
                    || UTL_RAW.cast_to_varchar2
                                              (UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(   lv_username
                                                                                            || ':'
                                                                                            || lv_subscription_password) ) ) );
            UTL_HTTP.write_text(request,
                                lv_input_payload);
            response := UTL_HTTP.get_response(request);
            COMMIT;
            fnd_file.put_line(fnd_file.LOG,
                                 'HTTP response status code: '
                              || response.status_code);
        EXCEPTION
            /*WHEN UTL_HTTP.end_of_body
            THEN
                errbuff := 'Exception Raised-UTL_HTTP.end_of_body-SQLERRM: '||SQLERRM;
                fnd_file.put_line(fnd_file.LOG,
                                'Exception Raised-UTL_HTTP.end_of_body-SQLERRM: '
                            || SQLERRM);
                UTL_HTTP.end_response(response);
                populate_error(p_contract_id =>               p_contract_id,
                                   p_contract_number =>           v_inv_details.contract_number,
                                   p_contract_line_number =>      p_contract_line,
                                   p_billing_sequence =>          p_billing_seq,
                                   p_module =>                    'get_tax_line_amount',
                                   p_error_msg =>                 errbuff);*/
            WHEN OTHERS
            THEN
                errbuff :=    'Unexpected Error Raised during HTTP connection -SQLERRM: '
                           || SQLERRM;
                fnd_file.put_line(fnd_file.LOG,
                                     'Unexpected Error Raised during HTTP connection -SQLERRM: '
                                  || SQLERRM);
                populate_error(p_contract_id =>               p_contract_id,
                               p_contract_number =>           NULL,
                               p_contract_line_number =>      p_contract_line,
                               p_billing_sequence =>          p_billing_seq,
                               p_module =>                    'get_tax_line_amount',
                               p_error_msg =>                 errbuff);
        END;

        IF response.status_code in (200, 400, 401, 403, 404, 406, 410, 429, 500, 502, 503, 504)
        THEN
            l_payload_id := xx_ar_subscription_payloads_s.NEXTVAL;

            BEGIN
                clob_buff := EMPTY_CLOB;

                LOOP
                    UTL_HTTP.read_text(response,
                                       buff,
                                       LENGTH(buff) );
                    clob_buff :=    clob_buff
                                 || buff;
                END LOOP;

                UTL_HTTP.end_response(response);
            EXCEPTION
                WHEN UTL_HTTP.end_of_body
                THEN
                    UTL_HTTP.end_response(response);
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'Exception raised while reading text: '
                                      || SQLERRM);
                    UTL_HTTP.end_response(response);
            END;

            BEGIN
                fnd_file.put_line(fnd_file.LOG,
                                     'Before inserting into xx_ar_subscription_payloads, l_payload_id: '
                                  || l_payload_id);

                INSERT INTO xx_ar_subscription_payloads
                            (payload_id,
                             contract_number,
                             billing_sequence_number,
                             contract_line_number,
                             SOURCE,
                             response_data,
                             creation_date,
                             created_by,
                             last_update_date,
                             last_updated_by,
                             input_payload)
                VALUES      (l_payload_id,
                             NULL,
                             p_billing_seq,
                             p_contract_line,
                             'AUTH CALL',
                             clob_buff,
                             SYSDATE,
                             fnd_global.user_id,
                             SYSDATE,
                             fnd_global.user_id,
                             lv_input_payload);

                fnd_file.put_line(fnd_file.LOG,
                                     'After inserting into xx_ar_subscription_payloads: '
                                  || SQL%ROWCOUNT);
                COMMIT;
            EXCEPTION
                WHEN OTHERS
                THEN
                    errbuff :=    'Exception in inserting into xx_ar_subscription_payloads: '
                               || SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                      errbuff);
                    populate_error(p_contract_id =>               p_contract_id,
                                   p_contract_number =>           NULL,
                                   p_contract_line_number =>      p_contract_line,
                                   p_billing_sequence =>          p_billing_seq,
                                   p_module =>                    'get_tax_line_amount',
                                   p_error_msg =>                 errbuff);
            END;
        ELSE
            fnd_file.put_line(fnd_file.LOG,
                              'Error. ');
            errbuff := 'ERROR';
            UTL_HTTP.end_response(response);
        END IF;

        --Get Tax_line_amount
        BEGIN
            SELECT TO_NUMBER(jt.tax_line_amount)
            INTO   ln_tax_amount
            FROM   xx_ar_subscription_payloads tax_response,
                   JSON_TABLE ( tax_response.response_data, '$.taxCalculatorResponse.orderTotals' COLUMNS ( "tax_line_amount" VARCHAR2(15) PATH '$.tax' )) "JT"
            WHERE  tax_response.payload_id = l_payload_id;

            fnd_file.put_line(fnd_file.LOG,
                                 'Tax amount calculated for contract id: '
                              || p_contract_id
                              || ', l_payload_id: '
                              || l_payload_id
                              || ' - is: '
                              || ln_tax_amount);
        EXCEPTION
            WHEN OTHERS
            THEN
                errbuff :=    'Exception in Retrieving Tax_line_Amount: '
                           || SQLERRM;
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                populate_error(p_contract_id =>               p_contract_id,
                               p_contract_number =>           NULL,
                               p_contract_line_number =>      p_contract_line,
                               p_billing_sequence =>          p_billing_seq,
                               p_module =>                    'get_tax_line_amount',
                               p_error_msg =>                 errbuff);
        END;

        fnd_file.put_line(fnd_file.LOG,
                             'ln_tax_line_amount: '
                          || ln_tax_amount);
    EXCEPTION
        WHEN OTHERS
        THEN
            errbuff :=    'Unhandled Exception in tax calculation: '
                       || SQLERRM;
            fnd_file.put_line(fnd_file.LOG,
                              errbuff);
            populate_error(p_contract_id =>               p_contract_id,
                           p_contract_number =>           NULL,
                           p_contract_line_number =>      p_contract_line,
                           p_billing_sequence =>          p_billing_seq,
                           p_module =>                    'get_tax_line_amount',
                           p_error_msg =>                 errbuff);
    END get_tax_line_amount;

    PROCEDURE update_staging(
        errbuff       OUT     VARCHAR2,
        retcode       OUT     NUMBER,
        p_contract    IN      NUMBER,
        p_request_id  IN      NUMBER)
    IS
        CURSOR cur_subscriptions
        IS
            SELECT *
            FROM   xx_ar_subscriptions
            WHERE  program_id = p_request_id
            AND    contract_number = NVL(p_contract,
                                         contract_number)
            AND    billing_sequence_number > 1
            AND    NVL(invoice_interfaced_flag,
                       'N') <> 'Y';

        l_errbufff       VARCHAR2(256)                                      := NULL;
        l_retcode        NUMBER                                             := 0;
        l_contract_id    xx_ar_subscriptions.contract_id%TYPE;
        l_contract_line  xx_ar_subscriptions.contract_line_number%TYPE;
        l_billing_seq    xx_ar_subscriptions.billing_sequence_number%TYPE;
        l_enable_tax     VARCHAR2(1)                                        := 'N';
    BEGIN
        fnd_file.put_line(fnd_file.LOG,
                             'Launching update_staging routine for contract: '
                          || p_contract
                          || ' and request id: '
                          || p_request_id);

        BEGIN
            SELECT target_value1
            INTO   l_enable_tax
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 = 'ENABLE_TAX';

            fnd_file.put_line(fnd_file.LOG,
                                 'l_enable_tax is: '
                              || l_enable_tax);
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Exception raised while fetching l_db_link - '
                                  || SQLERRM);
        END;

        --rownum=1 because tax is calculated on one ship_to address on 1 line for a contract
        SELECT contract_id,
               contract_line_number,
               billing_sequence_number
        INTO   l_contract_id,
               l_contract_line,
               l_billing_seq
        FROM   xx_ar_subscriptions
        WHERE  program_id = p_request_id
        AND    contract_number = NVL(p_contract,
                                     contract_number)
        AND    billing_sequence_number > 1
        AND    NVL(invoice_interfaced_flag,
                   'N') <> 'Y'
        AND    ROWNUM = 1;

        IF (l_enable_tax = 'Y')
        THEN
            get_tax_line_amount(errbuff =>              l_errbufff,
                                retcode =>              l_retcode,
                                p_contract_id =>        l_contract_id,
                                p_contract_line =>      l_contract_line,
                                p_billing_seq =>        l_billing_seq,
                                p_request_id_in =>      p_request_id);

            FOR rec_subscriptions IN cur_subscriptions
            LOOP
                IF NVL(ln_tax_amount,
                       0) <> 0
                THEN
                    UPDATE xx_ar_subscriptions
                    SET tax_amount = ROUND( (  contract_line_amount
                                             * NVL(ln_tax_amount,
                                                   0) ),
                                           2),
                        total_contract_amount =
                                          contract_line_amount
                                        + ROUND( (  contract_line_amount
                                                  * NVL(ln_tax_amount,
                                                        0) ),
                                                2),
                        last_update_date = SYSDATE
                    WHERE  program_id = p_request_id
                    AND    contract_id = rec_subscriptions.contract_id
                    AND    contract_line_number = rec_subscriptions.contract_line_number
                    AND    billing_sequence_number = rec_subscriptions.billing_sequence_number;

                    COMMIT;
                END IF;
            END LOOP;
        ELSE
            FOR rec_subscriptions IN cur_subscriptions
            LOOP
                UPDATE xx_ar_subscriptions
                SET tax_amount = 0,
                    total_contract_amount = contract_line_amount,
                    last_update_date = SYSDATE
                WHERE  program_id = p_request_id
                AND    contract_id = rec_subscriptions.contract_id
                AND    contract_line_number = rec_subscriptions.contract_line_number
                AND    billing_sequence_number = rec_subscriptions.billing_sequence_number;

                COMMIT;
            END LOOP;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            --retcode := 2;
            errbuff :=    'Exception raised during update_staging routine: '
                       || SQLERRM;
            fnd_file.put_line(fnd_file.LOG,
                              errbuff);
    END update_staging;

    PROCEDURE populate_interface(
        errbuff     OUT     VARCHAR2,
        retcode     OUT     VARCHAR2,
        p_contract  IN      VARCHAR2)
    IS
        ln_inv_item_id               mtl_system_items_b.inventory_item_id%TYPE;
        ln_item_cost                 cst_item_costs.item_cost%TYPE;
        ln_inv_org_id                hr_all_organization_units.organization_id%TYPE;
        lv_contract_id               xx_ar_subscriptions.contract_id%TYPE               := NULL;
        ln_trx_number                ra_interface_lines_all.trx_number%TYPE             := NULL;
        lv_interfacing_error         VARCHAR2(256)                                      := NULL;
        ln_program_id                NUMBER                                             := 0;
        lc_rev_account               VARCHAR2(256)                                      := NULL;
        lc_cogs_value2               VARCHAR2(256)                                      := NULL;
        lc_inv_value3                VARCHAR2(256)                                      := NULL;
        lc_cons_value4               VARCHAR2(256)                                      := NULL;
        lc_avg_cost                  NUMBER;
        l_header_id                  NUMBER                                             := 0;
        l_orig_sys_document_ref      VARCHAR2(60)                                       := NULL;
        lc_so_attribute              VARCHAR2(150)                                      := NULL;
        ln_contract_line_num         NUMBER                                             := NULL;
        ln_billing_seq               NUMBER                                             := NULL;
        l_cogs_generated             VARCHAR2(1)                                        := NULL;
        l_rev_comp                   gl_code_combinations.segment1%TYPE                 := NULL;
        l_rev_cc                     gl_code_combinations.segment2%TYPE                 := NULL;
        l_rev_acct                   gl_code_combinations.segment3%TYPE                 := NULL;
        l_rev_loc                    gl_code_combinations.segment4%TYPE                 := NULL;
        l_rev_inter                  gl_code_combinations.segment5%TYPE                 := NULL;
        l_rev_lob                    gl_code_combinations.segment6%TYPE                 := NULL;
        l_rev_future                 gl_code_combinations.segment7%TYPE                 := NULL;
        l_rev_ccid                   gl_code_combinations.code_combination_id%TYPE      := NULL;
        l_tax_comp                   gl_code_combinations.segment1%TYPE                 := NULL;
        l_tax_cc                     gl_code_combinations.segment2%TYPE                 := NULL;
        l_tax_acct                   gl_code_combinations.segment3%TYPE                 := NULL;
        l_tax_loc                    gl_code_combinations.segment4%TYPE                 := NULL;
        l_tax_inter                  gl_code_combinations.segment5%TYPE                 := NULL;
        l_tax_lob                    gl_code_combinations.segment6%TYPE                 := NULL;
        l_tax_future                 gl_code_combinations.segment7%TYPE                 := NULL;
        l_tax_ccid                   gl_code_combinations.code_combination_id%TYPE      := NULL;
        l_item_cost                  NUMBER                                             := 0;
        l_db_link                    VARCHAR2(120)                                      := NULL;
        l_utem_cost_qry              VARCHAR2(256)                                      := NULL;
        l_enable_tax                 VARCHAR2(1)                                        := 'N';
        ln_bill_to_osr               VARCHAR2(60)                                       := NULL;
        l_contract_number            xx_ar_subscriptions.contract_number%TYPE;
        l_contract_version           xx_ar_contracts.contract_major_version%TYPE;
        l_contract_line_number       xx_ar_subscriptions.contract_line_number%TYPE;
        l_billing_sequence_number    xx_ar_subscriptions.billing_sequence_number%TYPE;
        l_trx_line                   NUMBER                                             := 0;
        l_trx_type                   VARCHAR2(60)                                       := NULL;
        l_trx_source                 VARCHAR2(60)                                       := NULL;
        l_memo_line                  VARCHAR2(60)                                       := NULL;
        l_interface_line_id          NUMBER                                             := 0;
        l_error_flag                 VARCHAR2(2)                                        := 'N';
        l_uom_code                   mtl_system_items.primary_uom_code%TYPE;
        l_invoice_interfaced_flag    VARCHAR2(1)                                        := 'N';
        l_invalid                    VARCHAR2(1)                                        := 'N';
        l_invalid_interface_line_id  ra_interface_lines_all.interface_line_id%TYPE;

        CURSOR cur_subscriptions
        IS
            SELECT xacl.item_name,
                   xacl.item_description,
                   xas.billing_date,
                   xas.contract_id,
                   xas.contract_number,
                   xas.contract_name,
                   xas.payment_terms,
                   xas.contract_line_amount billing_amount,
                   xas.tax_amount,
                   xac.bill_to_osr account_orig_system_reference,
                   xas.uom_code,
                   xac.initial_order_number,
                   xas.billing_sequence_number,
                   xac.contract_major_version,
                   (SELECT unit_of_measure
                    FROM   mtl_units_of_measure
                    WHERE  uom_code = xas.uom_code) uom_name,
                   xx_ar_subscriptions_pkg.get_customer(xac.initial_order_number,
                                                        'BILL_TO') cust_account_id,
                   xx_ar_subscriptions_pkg.get_customer_site(xac.initial_order_number,
                                                             'BILL_TO') cust_acct_site_id,
                   xas.program_id,
                   xas.contract_line_number,
                   xacl.initial_order_line,
                   xas.quantity
            FROM   xx_ar_subscriptions xas, xx_ar_contract_lines xacl, xx_ar_contracts xac
            WHERE  1 = 1
            AND    xas.invoice_interfaced_flag IN('N', 'E')
            AND    xas.contract_id = xacl.contract_id
            AND    xacl.contract_line_number = xas.contract_line_number
            AND    xas.contract_id = xac.contract_id
            AND    xas.contract_number = NVL(p_contract,
                                             xas.contract_number)
            AND    xas.billing_sequence_number > 1
            AND    TRUNC(xas.billing_date) <= TRUNC(SYSDATE);

        CURSOR c_invalid_contract_lines
        IS
            SELECT xas.invoice_interfaced_flag,
                   xas.contract_number,
                   xas.billing_sequence_number,
                   xas.contract_line_number,
                   xas.invoice_number,
                   xas.initial_order_number
            FROM   xx_ar_subscriptions xas
            WHERE  xas.contract_number = NVL(p_contract,
                                             xas.contract_number)
            AND    xas.billing_sequence_number > 1
            AND    TRUNC(xas.billing_date) <= TRUNC(SYSDATE)
            AND    xas.invoice_interfaced_flag IN('N', 'E', 'P');

        CURSOR cur_subscriptions_tax
        IS
            SELECT   xas.billing_date,
                     SUM(xas.tax_amount) tax_amount,
                     xas.contract_id,
                     xas.contract_number,
                     xas.contract_name,
                     xac.bill_to_osr account_orig_system_reference,
                     xx_ar_subscriptions_pkg.get_customer(xac.initial_order_number,
                                                          'BILL_TO') cust_account_id,
                     xx_ar_subscriptions_pkg.get_customer_site(xac.initial_order_number,
                                                               'BILL_TO') cust_acct_site_id,
                     xac.initial_order_number,
                     xas.program_id,
                     xas.billing_sequence_number,
                     xas.contract_line_number
            FROM     xx_ar_subscriptions xas, xx_ar_contracts xac
            WHERE    1 = 1
            AND      xas.contract_id = xac.contract_id
            AND      invoice_interfaced_flag = 'P'
            AND      xas.contract_number = NVL(p_contract,
                                               xas.contract_number)
            AND      xas.billing_sequence_number > 1
            AND      TRUNC(xas.billing_date) <= TRUNC(SYSDATE)
            GROUP BY xas.billing_date,
                     xas.contract_id,
                     xas.contract_number,
                     xas.contract_name,
                     xac.bill_to_osr,
                     xac.initial_order_number,
                     xas.program_id,
                     xas.billing_sequence_number,
                     xas.contract_line_number;
    BEGIN
        fnd_file.put_line(fnd_file.LOG,
                          '********************************');
        fnd_file.put_line(fnd_file.LOG,
                          'Start populating interface table');

        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
        THEN
            fnd_log.STRING(fnd_log.level_statement,
                           'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                           'Before populate_interface');
        END IF;

        -- Update contracts with Billing Sequence 1
        backfill_seq1_data(errbuff,
                           retcode,
                           p_contract);

        --fetching db link
        BEGIN
            SELECT target_value1
            INTO   l_db_link
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 = 'RMS_DB_LINK';

            fnd_file.put_line(fnd_file.LOG,
                                 'l_db_link is: '
                              || l_db_link);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                errbuff := 'No data found while fetching l_db_link ';
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
            WHEN OTHERS
            THEN
                errbuff :=    'Exception raised while fetching l_db_link - '
                           || SQLERRM;
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
        END;

        --To get whether Subscription billing Tax is enabled
        BEGIN
            SELECT target_value1
            INTO   l_enable_tax
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 = 'ENABLE_TAX';

            fnd_file.put_line(fnd_file.LOG,
                                 'l_enable_tax is: '
                              || l_enable_tax);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                errbuff := 'No data found while fetching l_enable_tax';
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
            WHEN OTHERS
            THEN
                errbuff :=    'Exception raised while fetching l_enable_tax - '
                           || SQLERRM;
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
        END;

        -- Start fetching Transaction Type by JAI_CG
        BEGIN
            SELECT vals.target_value1
            INTO   l_trx_type
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 LIKE 'TRANSACTION_TYPE';   -- US_SERVICE_AOPS_OD

            fnd_file.put_line(fnd_file.LOG,
                                 'Transaction type fetched is: '
                              || l_trx_type);   -- Added by JAI_CG

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
                fnd_log.STRING(fnd_log.level_statement,
                               'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                                  'Transaction type fetched is: '
                               || l_trx_type);
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                errbuff := 'Tramslation value for Transaction Type is not defined';
                fnd_file.put_line(fnd_file.LOG,
                                  'TRANSACTION_TYPE Translation Not Found in OD_SUBSCRIPTION_TRANSLATION');   -- Added by JAI_CG

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                                   'TRANSACTION_TYPE Translation Not Found in OD_SUBSCRIPTION_TRANSLATION');
                END IF;
            WHEN OTHERS
            THEN
                errbuff := 'Unexpected error while fecthing translation value for Transaction Type';
                fnd_file.put_line
                    (fnd_file.LOG,
                     'Unexpected error while fecthing translation value for Transaction Type in OD_SUBSCRIPTION_TRANSLATION');   -- Added by JAI_CG

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING
                        (fnd_log.level_statement,
                         'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                         'Unexpected error while fecthing translation value for Transaction Type in OD_SUBSCRIPTION_TRANSLATION');
                END IF;
        END;

        -- Start fetching Transaction Source by JAI_CG
        BEGIN
            SELECT vals.target_value1
            INTO   l_trx_source
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 LIKE 'TRANSACTION_SOURCE';   -- SUBSCRIPTION_BILLING_US

            fnd_file.put_line(fnd_file.LOG,
                                 'Transaction source fetched is: '
                              || l_trx_source);   -- Added by JAI_CG

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
                fnd_log.STRING(fnd_log.level_statement,
                               'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                                  'Transaction source fetched is: '
                               || l_trx_source);
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                errbuff := 'Tramslation value for Transaction source is not defined';
                fnd_file.put_line(fnd_file.LOG,
                                  'TRANSACTION_SOURCE Translation Not Found in OD_SUBSCRIPTION_TRANSLATION');   -- Added by JAI_CG

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                                   'TRANSACTION_SOURCE Translation Not Found in OD_SUBSCRIPTION_TRANSLATION');
                END IF;
            WHEN OTHERS
            THEN
                errbuff := 'Unexpected error while fecthing translation value for Transaction source';
                fnd_file.put_line
                    (fnd_file.LOG,
                     'Unexpected error while fecthing translation value for Transaction source in OD_SUBSCRIPTION_TRANSLATION');   -- Added by JAI_CG

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING
                        (fnd_log.level_statement,
                         'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                         'Unexpected error while fecthing translation value for Transaction source in OD_SUBSCRIPTION_TRANSLATION');
                END IF;
        END;

        -- Start fetching Memo Line Name by JAI_CG
        BEGIN
            SELECT vals.target_value1
            INTO   l_memo_line
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 = 'MEMO_LINE';

            fnd_file.put_line(fnd_file.LOG,
                                 'Memo Line fetched is: '
                              || l_memo_line);   -- Added by JAI_CG

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
                fnd_log.STRING(fnd_log.level_statement,
                               'XX_AR_SUBSCRIPTIONS_PKG.validate_data',
                                  'Memo Line fetched is: '
                               || l_memo_line);
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                errbuff := 'Memo Line Translation Not Found in OD_SUBSCRIPTION_TRANSLATION';
                fnd_file.put_line(fnd_file.LOG,
                                  'Memo Line Translation Not Found in OD_SUBSCRIPTION_TRANSLATION');   -- Added by JAI_CG

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.validate_data',
                                   'Memo Line Translation Not Found in OD_SUBSCRIPTION_TRANSLATION');
                END IF;
            WHEN OTHERS
            THEN
                errbuff := 'Unexpected error while fecthing Memo Line Translation in OD_SUBSCRIPTION_TRANSLATION';
                fnd_file.put_line
                                (fnd_file.LOG,
                                 'Unexpected error while fecthing Memo Line Translation in OD_SUBSCRIPTION_TRANSLATION');   -- Added by JAI_CG

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING
                                (fnd_log.level_statement,
                                 'XX_AR_SUBSCRIPTIONS_PKG.validate_data',
                                 'Unexpected error while fecthing Memo Line Translation in OD_SUBSCRIPTION_TRANSLATION');
                END IF;
        END;

        FOR rec_subscriptions IN cur_subscriptions
        LOOP
            l_error_flag := 'N';
            l_uom_code := NULL;
            lv_interfacing_error := NULL;
            fnd_file.put_line(fnd_file.LOG,
                              'Opening loop for cur_subscriptions in populate_interface. ');
            l_item_cost := 0;

            BEGIN
                l_utem_cost_qry :=
                                'SELECT cost FROM MV_SSB@'
                             || l_db_link
                             || ' WHERE item = '
                             || rec_subscriptions.item_name;

                EXECUTE IMMEDIATE l_utem_cost_qry
                INTO              l_item_cost;

                --Updating item_cost to subscriptions table
                IF l_item_cost IS NOT null AND l_item_cost > 0 THEN 
                
                  UPDATE xx_ar_subscriptions
                  SET item_unit_cost = l_item_cost,
                      last_update_date = SYSDATE
                  WHERE  contract_number = rec_subscriptions.contract_number
                  AND    contract_line_number = rec_subscriptions.contract_line_number
                  AND    billing_sequence_number = rec_subscriptions.billing_sequence_number
                  ; 
                  
                END IF;
                
                COMMIT;
                           
                fnd_file.put_line(fnd_file.LOG,
                                     'Item cost derived is: '
                                  || l_item_cost);
            EXCEPTION
                WHEN OTHERS
                THEN
                    l_error_flag := 'Y';
                    errbuff :=
                           'Exception raised while fetching item cost for item: '
                        || rec_subscriptions.item_name
                        || ' - '
                        || SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                      errbuff);
                    populate_error(p_contract_id =>               rec_subscriptions.contract_id,
                                   p_contract_number =>           rec_subscriptions.contract_number,
                                   p_contract_line_number =>      rec_subscriptions.contract_line_number,
                                   p_billing_sequence =>          rec_subscriptions.billing_sequence_number,
                                   p_module =>                    'Populate_Interface',
                                   p_error_msg =>                 errbuff);
            END;

            ------------------------------Inventory Item Validation-------------------------------------------------------------
            -- Start item validation by JAI_CG
            BEGIN
                ln_inv_item_id := NULL;
                ln_item_cost := NULL;
                ln_inv_org_id := NULL;

                SELECT msi.inventory_item_id,
                       mp.organization_id,
                       msi.item_type,
                       primary_uom_code
                INTO   ln_inv_item_id,
                       ln_inv_org_id,
                       lc_item_type,
                       l_uom_code
                FROM   mtl_system_items msi, mtl_parameters mp
                WHERE  msi.segment1 = rec_subscriptions.item_name
                AND    msi.organization_id = mp.organization_id
                AND    mp.organization_id = mp.master_organization_id;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    l_error_flag := 'Y';
                    --lv_interfacing_error := 'Inventory Item validation failed. But hard-coded ';
                    lv_interfacing_error := NULL;
                    fnd_file.put_line(fnd_file.LOG,
                                         'inventory_item_id not found for item: '
                                      || rec_subscriptions.item_description);
                WHEN OTHERS
                THEN
                    l_error_flag := 'Y';
                    errbuff :=
                           'inventory_item_id Unexpected Error for item: '
                        || rec_subscriptions.item_description
                        || ' - '
                        || SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                      errbuff);
                    populate_error(p_contract_id =>               rec_subscriptions.contract_id,
                                   p_contract_number =>           rec_subscriptions.contract_number,
                                   p_contract_line_number =>      rec_subscriptions.contract_line_number,
                                   p_billing_sequence =>          rec_subscriptions.billing_sequence_number,
                                   p_module =>                    'Populate_Interface',
                                   p_error_msg =>                 errbuff);
            END;

            fnd_file.put_line(fnd_file.LOG,
                                 'ln_inv_item_id: '
                              || ln_inv_item_id);

            --comparing uom_code of bill_seq = 1 and other bill seq values
            IF l_uom_code = rec_subscriptions.uom_code
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'UOM code is matched');
            ELSE
                l_error_flag := 'Y';
                errbuff :=
                       'UOM code is not matched for contract_id: '
                    || rec_subscriptions.contract_id
                    || ' and contract_line_number: '
                    || rec_subscriptions.contract_line_number;
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                populate_error(p_contract_id =>               rec_subscriptions.contract_id,
                               p_contract_number =>           rec_subscriptions.contract_number,
                               p_contract_line_number =>      rec_subscriptions.contract_line_number,
                               p_billing_sequence =>          rec_subscriptions.billing_sequence_number,
                               p_module =>                    'validate_data',
                               p_error_msg =>                 errbuff);
            END IF;

            -- End item validation by JAI_CG
            BEGIN
                lc_dept := NULL;

                SELECT mc.segment3
                INTO   lc_dept   -- 75
                FROM   mtl_item_categories mic, mtl_categories_b mc, mtl_category_sets mcs
                WHERE  mic.category_set_id = mcs.category_set_id
                AND    mic.category_id = mc.category_id
                AND    mic.inventory_item_id = ln_inv_item_id   --6077361
                AND    mic.organization_id = ln_inv_org_id   --441
                AND    mcs.category_set_name = 'Inventory';
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    l_error_flag := 'Y';
                    fnd_file.put_line(fnd_file.LOG,
                                         'Department not found for item: '
                                      || rec_subscriptions.item_name);
                WHEN OTHERS
                THEN
                    l_error_flag := 'Y';
                    errbuff :=
                           'Exception raised while fetching department for item: '
                        || rec_subscriptions.item_name
                        || ' - '
                        || SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                      errbuff);
                    populate_error(p_contract_id =>               rec_subscriptions.contract_id,
                                   p_contract_number =>           rec_subscriptions.contract_number,
                                   p_contract_line_number =>      rec_subscriptions.contract_line_number,
                                   p_billing_sequence =>          rec_subscriptions.billing_sequence_number,
                                   p_module =>                    'Populate_Interface',
                                   p_error_msg =>                 errbuff);
            END;

            BEGIN
                lc_rev_account := NULL;
                lc_cogs_value2 := NULL;
                lc_inv_value3 := NULL;
                lc_cons_value4 := NULL;

                SELECT xft.target_value1,
                       xft.target_value2,
                       xft.target_value3,
                       xft.target_value4
                INTO   lc_rev_account,
                       lc_cogs_value2,
                       lc_inv_value3,
                       lc_cons_value4
                FROM   xx_fin_translatevalues xft, xx_fin_translatedefinition xfd
                WHERE  xft.translate_id = xfd.translate_id
                AND    (xft.source_value1 IS NULL)
                AND    (xft.source_value2 = lc_item_type)
                AND    (xft.source_value3 = lc_dept)
                AND    xft.enabled_flag = 'Y'
                AND    (    xft.start_date_active <= SYSDATE
                        AND (   xft.end_date_active >= SYSDATE
                             OR xft.end_date_active IS NULL) )
                AND    xfd.translation_name = 'SALES ACCOUNTING MATRIX'
                AND    xfd.enabled_flag = 'Y'
                AND    (    xfd.start_date_active <= SYSDATE
                        AND (   xfd.end_date_active >= SYSDATE
                             OR xfd.end_date_active IS NULL) );
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    l_error_flag := 'Y';
                    fnd_file.put_line(fnd_file.LOG,
                                         'COGs not found for item: '
                                      || rec_subscriptions.item_name);
                WHEN OTHERS
                THEN
                    l_error_flag := 'Y';
                    errbuff :=
                           'Exception raised while fetching COGs for item: '
                        || rec_subscriptions.item_name
                        || ' - '
                        || SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                      errbuff);
                    populate_error(p_contract_id =>               rec_subscriptions.contract_id,
                                   p_contract_number =>           rec_subscriptions.contract_number,
                                   p_contract_line_number =>      rec_subscriptions.contract_line_number,
                                   p_billing_sequence =>          rec_subscriptions.billing_sequence_number,
                                   p_module =>                    'Populate_Interface',
                                   p_error_msg =>                 errbuff);
            END;

            -- Fetching item source
            BEGIN
                lc_item_source := NULL;
                lc_source_type_code := NULL;
                lc_consignment := NULL;

                SELECT xxol.item_source,
                       oel.source_type_code,
                       xxol.consignment_bank_code
                INTO   lc_item_source,
                       lc_source_type_code,
                       lc_consignment
                FROM   oe_order_headers_all oeh,
                       xx_om_header_attributes_all xxoh,
                       oe_order_lines_all oel,
                       xx_om_line_attributes_all xxol
                WHERE  oeh.orig_sys_document_ref = rec_subscriptions.initial_order_number
                AND    xxoh.header_id = oeh.header_id
                AND    oel.header_id = oeh.header_id
                AND    oel.line_number = rec_subscriptions.initial_order_line
                AND    xxol.line_id = oel.line_id;
            EXCEPTION
                WHEN OTHERS
                THEN
                    lc_item_source := NULL;
                    lc_source_type_code := NULL;
                    lc_consignment := NULL;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Exception raised while fetching source for order: '
                                      || rec_subscriptions.initial_order_number
                                      || ' - '
                                      || SQLERRM);
            END;

            -- Fetching Transaction Type
            BEGIN
                lc_trx_type := NULL;

                SELECT rctt.cust_trx_type_id
                INTO   lc_trx_type
                FROM   ra_cust_trx_types_all rctt, hr_operating_units hou
                WHERE  1 = 1
                AND    rctt.NAME = l_trx_type
                AND    rctt.org_id = hou.organization_id
                AND    hou.NAME = 'OU_US';
            EXCEPTION
                WHEN OTHERS
                THEN
                    lc_trx_type := NULL;
                    fnd_file.put_line(fnd_file.LOG,
                                      'Exception raised while fetching Transaction Type. ');
            END;

            IF NVL(rec_subscriptions.cust_account_id,
                   0) = 0
            THEN
                l_error_flag := 'Y';
                lv_interfacing_error :=    lv_interfacing_error
                                        || ' - '
                                        || 'Bill To OSR validation failed';
                errbuff :=    'Bill To OSR validation failed for contract: '
                           || rec_subscriptions.contract_name;
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                populate_error(p_contract_id =>               rec_subscriptions.contract_id,
                               p_contract_number =>           rec_subscriptions.contract_number,
                               p_contract_line_number =>      rec_subscriptions.contract_line_number,
                               p_billing_sequence =>          rec_subscriptions.billing_sequence_number,
                               p_module =>                    'Populate_Interface',
                               p_error_msg =>                 errbuff);
            END IF;

            IF lv_interfacing_error IS NOT NULL
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Staging data validation failed with message: '
                                  || lv_interfacing_error);

                UPDATE xx_ar_subscriptions
                SET invoice_interfaced_flag = 'E',
                    invoice_interfacing_error = lv_interfacing_error,
                    last_update_date = SYSDATE
                WHERE  contract_id = rec_subscriptions.contract_id
                AND    billing_sequence_number = rec_subscriptions.billing_sequence_number
                AND    NVL(auth_completed_flag,
                           'N') <> 'Y';
            ELSE
                IF     rec_subscriptions.contract_id = lv_contract_id
                   AND rec_subscriptions.program_id = ln_program_id
                THEN
                    ln_trx_number := xx_artrx_subscriptions_s.CURRVAL;
                    l_trx_line :=   l_trx_line
                                  + 1;
                ELSE
                    ln_trx_number := xx_artrx_subscriptions_s.NEXTVAL;
                    l_trx_line := 1;
                END IF;

                --Get Order Header_Id, orig_sys_document_ref from oe_order_headers_all
                BEGIN
                    l_header_id := NULL;
                    l_orig_sys_document_ref := NULL;

                    SELECT header_id,
                           orig_sys_document_ref
                    INTO   l_header_id,
                           l_orig_sys_document_ref
                    FROM   oe_order_headers_all
                    WHERE  order_number = rec_subscriptions.initial_order_number;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        l_error_flag := 'Y';
                        errbuff := 'Failed to get order header_id and orig_sys_document_ref from initial_order_number';
                        fnd_file.put_line(fnd_file.LOG,
                                          errbuff);
                        populate_error(p_contract_id =>               rec_subscriptions.contract_id,
                                       p_contract_number =>           rec_subscriptions.contract_number,
                                       p_contract_line_number =>      rec_subscriptions.contract_line_number,
                                       p_billing_sequence =>          rec_subscriptions.billing_sequence_number,
                                       p_module =>                    'Populate_Interface',
                                       p_error_msg =>                 errbuff);
                END;

                -- Assigning sales order attribute for Distribution DFF
                BEGIN
                    lc_so_attribute := NULL;
                    l_cogs_generated := NULL;

                    SELECT DISTINCT attribute11,
                                    attribute6
                    INTO            lc_so_attribute,
                                    l_cogs_generated
                    FROM            ra_cust_trx_line_gl_dist_all
                    WHERE           account_class = 'REV'
                    AND             customer_trx_line_id IN(
                                        SELECT customer_trx_line_id
                                        FROM   ra_customer_trx_lines_all
                                        WHERE  1 = 1
                                        AND    line_number = rec_subscriptions.initial_order_line
                                        AND    customer_trx_id =
                                                             (SELECT customer_trx_id
                                                              FROM   ra_customer_trx_all
                                                              WHERE  trx_number = rec_subscriptions.initial_order_number) );
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        l_error_flag := 'Y';
                        errbuff :=
                               'Exception raised while fetching attributes from initial_order_number:'
                            || rec_subscriptions.initial_order_number
                            || SQLERRM;
                        fnd_file.put_line(fnd_file.LOG,
                                             errbuff
                                          || SQLERRM);
                        populate_error(p_contract_id =>               rec_subscriptions.contract_id,
                                       p_contract_number =>           rec_subscriptions.contract_number,
                                       p_contract_line_number =>      rec_subscriptions.contract_line_number,
                                       p_billing_sequence =>          rec_subscriptions.billing_sequence_number,
                                       p_module =>                    'Populate_Interface',
                                       p_error_msg =>                 errbuff);
                END;

                fnd_file.put_line(fnd_file.LOG,
                                  'Inserting data into Interface Table. ');

                -- Fetch bill to OSR
                BEGIN
                    ln_bill_to_osr := NULL;

                    SELECT orig_system_reference
                    INTO   ln_bill_to_osr
                    FROM   hz_orig_sys_references
                    WHERE  orig_system = 'A0'
                    AND    owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
                    AND    status = 'A'
                    AND    owner_table_id = rec_subscriptions.cust_acct_site_id;   --1111289799
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        ln_bill_to_osr := NULL;
                        fnd_file.put_line(fnd_file.LOG,
                                             'Exception raised while fetching bill_to_osr: '
                                          || SQLERRM);
                END;

                IF l_error_flag = 'N'
                THEN
                    BEGIN
                        l_interface_line_id := ra_customer_trx_lines_s.NEXTVAL;

                        INSERT INTO ra_interface_lines_all
                                    (interface_line_id,
                                     trx_date,
                                     trx_number,
                                     batch_source_name,
                                     cust_trx_type_name,
                                     amount,
                                     description,
                                     line_type,
                                     currency_code,
                                     conversion_type,
                                     conversion_rate,
                                     header_attribute_category,
                                     header_attribute1,
                                     last_update_date,
                                     last_updated_by,
                                     creation_date,
                                     created_by,
                                     last_update_login,
                                     term_name,
                                     conversion_date,
                                     orig_system_bill_customer_ref,
                                     orig_system_bill_address_ref,
                                     orig_system_ship_customer_ref,
                                     orig_system_ship_address_ref,
                                     gl_date,
                                     memo_line_name,
                                     inventory_item_id,
                                     interface_line_attribute6,
                                     uom_code,
                                     --uom_name ,
                                     orig_system_bill_customer_id,
                                     orig_system_ship_customer_id,
                                     orig_system_sold_customer_id,
                                     orig_system_bill_address_id,
                                     orig_system_ship_address_id,
                                     taxable_flag,
                                     line_number,
                                     header_attribute13   -- to populate Invoice DFF
                                                       ,
                                     header_attribute14   -- to populate Invoice DFF
                                                       ,
                                     header_attribute15   -- to populate Invoice DFF
                                                       ,
                                     quantity,
                                     unit_selling_price,
                                     unit_standard_price,
                                     interface_line_context,
                                     interface_line_attribute1,
                                     interface_line_attribute2,
                                     interface_line_attribute3,
                                     interface_line_attribute4,
                                     interface_line_attribute5,
                                     warehouse_id)
                        VALUES      (l_interface_line_id,
                                     SYSDATE   --TO_DATE (i.BILLING_DATE,'DD-MON-YYYY HH:MI:SS')
                                            ,
                                     ln_trx_number   --XX_ARTRX_SUBSCRIPTIONS_S.NEXTVAL -- Sequence for Trx Number added by JAI_CG
                                                  ,
                                     l_trx_source   --'SALES_ACCT_US'
                                                 ,
                                     l_trx_type,
                                     rec_subscriptions.billing_amount,
                                        'Subscription Billing For Contract - '
                                     || rec_subscriptions.contract_number
                                     || '-'
                                     || rec_subscriptions.billing_sequence_number,
                                     'LINE',
                                     'USD',
                                     'User',
                                     1
                                      --,'US_SUBSCRITIONS' -- Derive Header Attribute Category. Commented by JAI_CG
                        ,
                                     'SALES_ACCT',
                                     rec_subscriptions.initial_order_number,   --|| '-' || rec_subscriptions.billing_sequence_number ,
                                     SYSDATE,
                                     fnd_global.user_id,
                                     SYSDATE,
                                     fnd_global.user_id,
                                     fnd_global.login_id,
                                     rec_subscriptions.payment_terms,
                                     SYSDATE,
                                     ln_bill_to_osr   --'11225340-00001-A0' --i.ACCOUNT_ORIG_SYSTEM_REFERENCE
                                                   ,
                                     ln_bill_to_osr,
                                     ln_bill_to_osr,
                                     ln_bill_to_osr
                                                   --,TO_DATE (rec_subscriptions.BILLING_DATE,'DD-MON-YYYY HH:MI:SS')
                        ,
                                     SYSDATE,
                                     l_memo_line,
                                     ln_inv_item_id,
                                     l_item_cost,
                                     rec_subscriptions.uom_code,
                                     rec_subscriptions.cust_account_id,
                                     rec_subscriptions.cust_account_id,
                                     rec_subscriptions.cust_account_id,
                                     rec_subscriptions.cust_acct_site_id,
                                     rec_subscriptions.cust_acct_site_id,
                                     'N',
                                     l_trx_line,
                                     l_orig_sys_document_ref   --Orig system Order Reference: ATTRIBUTE13
                                                            ,
                                     l_header_id   --Order Header: ATTRIBUTE14
                                                ,
                                     'N'   --for Invoice DFF Billing Extension: ATTRIBUTE15
                                        ,
                                     rec_subscriptions.quantity,
                                     rec_subscriptions.billing_amount,
                                     l_item_cost,
                                     'RECURRING BILLING',
                                        rec_subscriptions.initial_order_number
                                     || '-'
                                     || rec_subscriptions.billing_sequence_number,
                                     rec_subscriptions.contract_major_version,
                                     rec_subscriptions.contract_line_number,
                                     rec_subscriptions.billing_sequence_number,
                                     rec_subscriptions.contract_number,
                                     ln_inv_org_id);

                        l_contract_number := rec_subscriptions.contract_number;
                        l_contract_version := rec_subscriptions.contract_major_version;
                        l_contract_line_number := rec_subscriptions.contract_line_number;
                        l_billing_sequence_number := rec_subscriptions.billing_sequence_number;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            errbuff :=    'Exception raised while populating interface line: '
                                       || SQLERRM;
                            fnd_file.put_line(fnd_file.LOG,
                                              errbuff);
                            populate_error(p_contract_id =>               rec_subscriptions.contract_id,
                                           p_contract_number =>           rec_subscriptions.contract_number,
                                           p_contract_line_number =>      rec_subscriptions.contract_line_number,
                                           p_billing_sequence =>          rec_subscriptions.billing_sequence_number,
                                           p_module =>                    'Populate_Interface',
                                           p_error_msg =>                 errbuff);
                    END;

                    -- Fetch REV account
                    gl_account_string(errbuff =>              errbuff,
                                      retcode =>              retcode
                                                                     --, p_request_id => p_request_id
                    ,
                                      p_contract =>           rec_subscriptions.contract_number,
                                      p_contract_line =>      rec_subscriptions.contract_line_number,
                                      p_billing_seq =>        rec_subscriptions.billing_sequence_number,
                                      p_order_number =>       rec_subscriptions.initial_order_number,
                                      p_rev_account =>        lc_rev_account,
                                      p_acc_class =>          'REV',
                                      x_company =>            l_rev_comp,
                                      x_costcenter =>         l_rev_cc,
                                      x_account =>            l_rev_acct,
                                      x_location =>           l_rev_loc,
                                      x_intercompany =>       l_rev_inter,
                                      x_lob =>                l_rev_lob,
                                      x_future =>             l_rev_future,
                                      x_ccid =>               l_rev_ccid);

                    BEGIN
                        INSERT INTO ra_interface_distributions_all
                                    (interface_line_id,
                                     interface_line_context,
                                     interface_line_attribute1,
                                     interface_line_attribute2,
                                     interface_line_attribute3,
                                     interface_line_attribute4,
                                     interface_line_attribute5,
                                     account_class,
                                     code_combination_id,
                                     segment1,
                                     segment2,
                                     segment3,
                                     segment4,
                                     segment5,
                                     segment6,
                                     segment7,
                                     org_id,
                                     PERCENT,
                                     attribute_category,
                                     attribute6,
                                     attribute7,
                                     attribute8,
                                     attribute9,
                                     attribute10   --requirment for defect 2426
                                                ,
                                     attribute11   --requirment for defect 7082
                                                ,
                                     created_by,
                                     creation_date,
                                     last_updated_by,
                                     last_update_date,
                                     last_update_login,
                                     request_id)
                        VALUES      (l_interface_line_id,
                                     'RECURRING BILLING',
                                        rec_subscriptions.initial_order_number
                                     || '-'
                                     || rec_subscriptions.billing_sequence_number,
                                     rec_subscriptions.contract_major_version,
                                     rec_subscriptions.contract_line_number,
                                     rec_subscriptions.billing_sequence_number,
                                     rec_subscriptions.contract_number,
                                     'REV',
                                     l_rev_ccid   --563889
                                               ,
                                     l_rev_comp   --'1001'
                                               ,
                                     l_rev_cc   --'00000'
                                             ,
                                     l_rev_acct   --'41101000'
                                               ,
                                     l_rev_loc   --'001099'
                                              ,
                                     l_rev_inter   --'0000'
                                                ,
                                     l_rev_lob   --'50'
                                              ,
                                     l_rev_future   --'000000'
                                                 ,
                                     fnd_profile.VALUE('ORG_ID'),
                                     100,
                                     'SALES_ACCT',
                                     l_cogs_generated   --'Y'
                                                     ,
                                     lc_cogs_value2,
                                     lc_inv_value3,
                                     l_item_cost   /***Changed by Sreedhar ***/
                                                ,
                                     lc_cons_value4,
                                     lc_so_attribute,
                                     fnd_profile.VALUE('USER_ID'),
                                     SYSDATE,
                                     fnd_profile.VALUE('USER_ID'),
                                     SYSDATE,
                                     fnd_profile.VALUE('LOGIN_ID'),
                                     rec_subscriptions.program_id);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            errbuff :=    'Exception raised while populating interface distribution: '
                                       || SQLERRM;
                            fnd_file.put_line(fnd_file.LOG,
                                              errbuff);
                            populate_error(p_contract_id =>               rec_subscriptions.contract_id,
                                           p_contract_number =>           rec_subscriptions.contract_number,
                                           p_contract_line_number =>      rec_subscriptions.contract_line_number,
                                           p_billing_sequence =>          rec_subscriptions.billing_sequence_number,
                                           p_module =>                    'Populate_Interface',
                                           p_error_msg =>                 errbuff);
                    END;

                    UPDATE xx_ar_subscriptions
                    SET invoice_number = xx_artrx_subscriptions_s.CURRVAL,
                        invoice_interfaced_flag = 'P',
                        last_update_date = SYSDATE
                    WHERE  1 = 1   --program_id            = p_request_id
                    AND    contract_number = rec_subscriptions.contract_number
                    AND    contract_id = rec_subscriptions.contract_id
                    AND    contract_line_number = rec_subscriptions.contract_line_number
                    AND    billing_sequence_number = rec_subscriptions.billing_sequence_number;

                    -- Updating global variable to NULL
                    lc_customer_type := NULL;
                    lc_trx_type := NULL;
                    lc_oloc := NULL;
                    lc_sloc := NULL;
                    lc_oloc_type := NULL;
                    lc_sloc_type := NULL;
                    lc_item_source := NULL;
                    lc_source_type_code := NULL;
                    lc_dept := NULL;
                    lc_item_type := NULL;
                    lc_consignment := NULL;
                    ln_tax_amount := 0;
                    lv_contract_id := rec_subscriptions.contract_id;
                    ln_program_id := rec_subscriptions.program_id;
                    ln_trx_number := NULL;
                ELSE
                    fnd_file.put_line(fnd_file.LOG,
                                      'Staging data validation failed with message: ');

                    UPDATE xx_ar_subscriptions
                    SET invoice_interfaced_flag = 'E',
                        last_update_date = SYSDATE
                    WHERE  contract_id = rec_subscriptions.contract_id
                    AND    billing_sequence_number = rec_subscriptions.billing_sequence_number
                    AND    contract_line_number = rec_subscriptions.contract_line_number;
                END IF;
            END IF;
        END LOOP;

        FOR rec_invalid_contract_lines IN c_invalid_contract_lines
        LOOP
            l_invoice_interfaced_flag:='N';
            l_invalid_interface_line_id:=NULL;
            BEGIN
                SELECT invoice_interfaced_flag
                INTO   l_invoice_interfaced_flag
                FROM   xx_ar_subscriptions xas
                WHERE  xas.contract_number = rec_invalid_contract_lines.contract_number
                AND    xas.contract_line_number = rec_invalid_contract_lines.contract_line_number
                AND    xas.billing_sequence_number = rec_invalid_contract_lines.billing_sequence_number;
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'Exception raised while fetching l_invoice_interfaced_flag: '
                                      || SQLERRM);
            END;

            BEGIN
                SELECT interface_line_id
                INTO   l_invalid_interface_line_id
                FROM   ra_interface_lines_all ril
                WHERE  1 = 1
                AND    ril.interface_line_context = 'RECURRING BILLING'
                AND    ril.interface_line_attribute1 =
                              rec_invalid_contract_lines.initial_order_number
                           || '-'
                           || rec_invalid_contract_lines.billing_sequence_number
                AND    ril.interface_line_attribute3 = rec_invalid_contract_lines.contract_line_number;
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'Exception raised while fetching l_invalid_interface_line_id: '
                                      || SQLERRM);
            END;

            IF (l_invoice_interfaced_flag = 'E')
            THEN
                --l_invalid = 'Y';
                DELETE FROM ra_interface_lines_all
                WHERE       interface_line_id = l_invalid_interface_line_id;

                DELETE FROM ra_interface_distributions_all
                WHERE       interface_line_id = l_invalid_interface_line_id;

                UPDATE xx_ar_subscriptions
                SET invoice_number = NULL,
                    invoice_interfaced_flag = 'E',
                    last_update_date = SYSDATE
                WHERE  contract_number = rec_invalid_contract_lines.contract_number
                AND    billing_sequence_number = rec_invalid_contract_lines.billing_sequence_number;

                COMMIT;
            END IF;
        END LOOP;

        FOR rec_subscriptions_tax IN cur_subscriptions_tax
        LOOP
            IF NVL(rec_subscriptions_tax.tax_amount,
                   0) <> 0
            THEN
                SELECT contract_line_number,
                       billing_sequence_number
                INTO   ln_contract_line_num,
                       ln_billing_seq
                FROM   xx_ar_subscriptions
                WHERE  program_id = rec_subscriptions_tax.program_id
                AND    contract_id = rec_subscriptions_tax.contract_id
                AND    billing_sequence_number = rec_subscriptions_tax.billing_sequence_number
                AND    NVL(auth_completed_flag,
                           'N') <> 'Y'
                AND    ROWNUM = 1;

                -- Fetch bill to OSR
                BEGIN
                    SELECT orig_system_reference
                    INTO   ln_bill_to_osr
                    FROM   hz_orig_sys_references
                    WHERE  orig_system = 'A0'
                    AND    owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
                    AND    status = 'A'
                    AND    owner_table_id = rec_subscriptions_tax.cust_acct_site_id;   --1111289799
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        ln_bill_to_osr := NULL;
                        fnd_file.put_line(fnd_file.LOG,
                                             'Exception raised while fetching bill_to_osr: '
                                          || SQLERRM);
                END;

                IF (l_enable_tax = 'Y')
                THEN
                    BEGIN
                        INSERT INTO ra_interface_lines_all
                                    (link_to_line_id,
                                     interface_line_id,
                                     trx_date,
                                     batch_source_name,
                                     cust_trx_type_name,
                                     amount,
                                     description,
                                     line_type,
                                     currency_code,
                                     conversion_type,
                                     conversion_rate,
                                     header_attribute_category,
                                     last_update_date,
                                     last_updated_by,
                                     creation_date,
                                     created_by,
                                     last_update_login,
                                     interface_line_context,
                                     interface_line_attribute1,
                                     interface_line_attribute2,
                                     interface_line_attribute3,
                                     interface_line_attribute4,
                                     interface_line_attribute5,
                                     conversion_date,
                                     orig_system_bill_customer_ref,
                                     orig_system_bill_address_ref,
                                     orig_system_ship_customer_ref,
                                     orig_system_ship_address_ref,
                                     gl_date,
                                     memo_line_name,
                                     orig_system_bill_customer_id,
                                     orig_system_ship_customer_id,
                                     orig_system_sold_customer_id,
                                     orig_system_bill_address_id,
                                     orig_system_ship_address_id,
                                     link_to_line_context,
                                     link_to_line_attribute1,
                                     link_to_line_attribute2,
                                     link_to_line_attribute3,
                                     link_to_line_attribute4,
                                     link_to_line_attribute5,
                                     tax_code,
                                     tax_rate_code)
                        VALUES      (ra_customer_trx_lines_s.CURRVAL,
                                     ra_customer_trx_lines_s.NEXTVAL,
                                     SYSDATE   --TO_DATE (i.BILLING_DATE,'DD-MON-YYYY HH:MI:SS')  -- Added by JAI_CG
                                            ,
                                     l_trx_source,
                                     l_trx_type,
                                     rec_subscriptions_tax.tax_amount,
                                        'SUBSCRITION BILLING FOR '
                                     || l_contract_number
                                     || l_billing_sequence_number,
                                     'TAX',
                                     'USD',
                                     'User',
                                     1
                                      --,'US_SUBSCRITIONS' -- Derive Header Attribute Category. Commented by JAI_CG
                        ,
                                     'SALES_ACCT'   -- Dummy category added by JAI_CG
                                                 ,
                                     SYSDATE,
                                     fnd_global.user_id,
                                     SYSDATE,
                                     fnd_global.user_id,
                                     fnd_global.login_id,
                                     'RECURRING BILLING',
                                        rec_subscriptions_tax.initial_order_number
                                     || '-'
                                     || l_billing_sequence_number
                                     || '-TAX',
                                        l_contract_version
                                     || '-TAX',
                                        l_contract_line_number
                                     || '-TAX',
                                        l_billing_sequence_number
                                     || '-TAX',
                                        l_contract_number
                                     || '-TAX',
                                     SYSDATE,
                                     ln_bill_to_osr   --'11225340-00001-A0' --i.ACCOUNT_ORIG_SYSTEM_REFERENCE
                                                   ,
                                     ln_bill_to_osr,
                                     ln_bill_to_osr,
                                     ln_bill_to_osr,
                                     SYSDATE,
                                     l_memo_line,
                                     rec_subscriptions_tax.cust_account_id,
                                     rec_subscriptions_tax.cust_account_id,
                                     rec_subscriptions_tax.cust_account_id,
                                     rec_subscriptions_tax.cust_acct_site_id,
                                     rec_subscriptions_tax.cust_acct_site_id,
                                     'RECURRING BILLING',
                                        rec_subscriptions_tax.initial_order_number
                                     || '-'
                                     || l_billing_sequence_number,
                                     l_contract_version,
                                     l_contract_line_number,
                                     l_billing_sequence_number,
                                     l_contract_number,
                                     'SALES',   --'VAT' ,
                                     'SALES'   --'STD'
                                            );
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            errbuff :=    'Exception raised while populating interface tax: '
                                       || SQLERRM;
                            fnd_file.put_line(fnd_file.LOG,
                                              errbuff);
                            populate_error(p_contract_id =>               rec_subscriptions_tax.contract_id,
                                           p_contract_number =>           rec_subscriptions_tax.contract_number,
                                           p_contract_line_number =>      rec_subscriptions_tax.contract_line_number,
                                           p_billing_sequence =>          rec_subscriptions_tax.billing_sequence_number,
                                           p_module =>                    'Populate_Interface',
                                           p_error_msg =>                 errbuff);
                    END;

                    -- Fetch TAX account
                    gl_account_string
                                   (errbuff =>              errbuff,
                                    retcode =>              retcode
                                                                   --, p_request_id => p_request_id
                    ,
                                    p_contract =>           rec_subscriptions_tax.contract_number,
                                    p_contract_line =>      ln_contract_line_num   --rec_subscriptions_tax.contract_line_number
                                                                                ,
                                    p_billing_seq =>        ln_billing_seq,
                                    p_order_number =>       rec_subscriptions_tax.initial_order_number,
                                    p_rev_account =>        lc_rev_account,
                                    p_acc_class =>          'TAX',
                                    x_company =>            l_tax_comp,
                                    x_costcenter =>         l_tax_cc,
                                    x_account =>            l_tax_acct,
                                    x_location =>           l_tax_loc,
                                    x_intercompany =>       l_tax_inter,
                                    x_lob =>                l_tax_lob,
                                    x_future =>             l_tax_future,
                                    x_ccid =>               l_tax_ccid);

                    BEGIN
                        INSERT INTO ra_interface_distributions_all
                                    (interface_line_context,
                                     interface_line_attribute1,
                                     interface_line_attribute2,
                                     interface_line_attribute3,
                                     account_class,
                                     code_combination_id,
                                     segment1,
                                     segment2,
                                     segment3,
                                     segment4,
                                     segment5,
                                     segment6,
                                     segment7,
                                     org_id,
                                     PERCENT,
                                     created_by,
                                     creation_date,
                                     last_updated_by,
                                     last_update_date,
                                     last_update_login,
                                     request_id)
                        VALUES      (   --,'SUBSCRIPTIONS INVOICES'  -- Create DFF on Transaction. Commented by JAI_CG
                                     'CONVERSION'   -- Dummy context added by JAI_CG
                                                 ,
                                        rec_subscriptions_tax.program_id
                                     || '-TAX',
                                        rec_subscriptions_tax.contract_number
                                     || '-'
                                     || ln_contract_line_num
                                     || '-'
                                     || ln_billing_seq
                                     || '-TAX',
                                        rec_subscriptions_tax.contract_name
                                     || '-TAX',
                                     'TAX',
                                     l_tax_ccid,
                                     l_tax_comp,
                                     l_tax_cc,
                                     l_tax_acct,
                                     l_tax_loc,
                                     l_tax_inter,
                                     l_tax_lob,
                                     l_tax_future,
                                     fnd_profile.VALUE('ORG_ID'),
                                     100,
                                     fnd_profile.VALUE('USER_ID'),
                                     SYSDATE,
                                     fnd_profile.VALUE('USER_ID'),
                                     SYSDATE,
                                     fnd_profile.VALUE('LOGIN_ID'),
                                     rec_subscriptions_tax.program_id);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            errbuff :=    'Exception raised while populating interface tax distribution: '
                                       || SQLERRM;
                            fnd_file.put_line(fnd_file.LOG,
                                              errbuff);
                            populate_error(p_contract_id =>               rec_subscriptions_tax.contract_id,
                                           p_contract_number =>           rec_subscriptions_tax.contract_number,
                                           p_contract_line_number =>      rec_subscriptions_tax.contract_line_number,
                                           p_billing_sequence =>          rec_subscriptions_tax.billing_sequence_number,
                                           p_module =>                    'Populate_Interface',
                                           p_error_msg =>                 errbuff);
                    END;
                END IF;   -- for l_enable_tax
            END IF;
        END LOOP;

        -- Updating invoice_interfaced_flag
        UPDATE xx_ar_subscriptions
        SET invoice_interfaced_flag = 'Y',
            last_update_date = SYSDATE
        WHERE  invoice_interfaced_flag = 'P';
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Unexpected Error in XX_AR_SUBSCRIPTION_PKG.populate_interface: '
                              || DBMS_UTILITY.format_error_backtrace
                              || SQLERRM);
            errbuff :=
                   'Unexpected Error in XX_AR_SUBSCRIPTION_PKG.populate_interface: '
                || DBMS_UTILITY.format_error_backtrace
                || SQLERRM;
            retcode := 2;
    END populate_interface;

    PROCEDURE process_authorization(
        errbuff                    OUT     VARCHAR2,
        retcode                    OUT     NUMBER,
        p_auth_message             OUT     VARCHAR2,
        p_response_code            OUT     VARCHAR2,
        p_contract_id              IN      NUMBER,
        p_billing_sequence_number  IN      NUMBER)
    IS
        request                   UTL_HTTP.req;
        response                  UTL_HTTP.resp;
        n                         NUMBER;
        buff                      VARCHAR2(10000);
        clob_buff                 CLOB;
        lv_input_payload          VARCHAR2(32000)                             := NULL;
        ln_tax_line_amount        NUMBER                                      := NULL;
        lv_auth_service_url       xx_fin_translatevalues.target_value1%TYPE   := NULL;
        lv_wallet_location        xx_fin_translatevalues.target_value1%TYPE   := NULL;
        lv_password               xx_fin_translatevalues.target_value2%TYPE   := NULL;
        lv_username               xx_fin_translatevalues.target_value2%TYPE   := NULL;
        lv_subscription_password  xx_fin_translatevalues.target_value3%TYPE   := NULL;
        lv_cust_address1          hz_locations.address1%TYPE                  := NULL;
        lv_cust_address2          hz_locations.address2%TYPE                  := NULL;
        lv_cust_city              hz_locations.city%TYPE                      := NULL;
        lv_cust_state             hz_locations.state%TYPE                     := NULL;
        lv_cust_postal_code       hz_locations.postal_code%TYPE               := NULL;
        lv_cust_country           hz_locations.country%TYPE                   := NULL;
        lv_email_address          hz_contact_points.email_address%TYPE        := NULL;
        lv_fax_number             VARCHAR2(30)                                := NULL;
        lv_phone_number           VARCHAR2(30)                                := NULL;
        l_payload_id              NUMBER                                      := 0;
        l_auth_code               VARCHAR2(30)                                := NULL;
        l_cc_decrypted            VARCHAR2(256)                               := NULL;
        l_cc_decrypt_error        VARCHAR2(256);
        lv_transactionid          VARCHAR2(60)                                := NULL;
        lv_transactiondatetime    VARCHAR2(60)                                := NULL;
        lv_transaction_code       VARCHAR2(60)                                := NULL;
        lv_transaction_message    VARCHAR2(256)                               := NULL;
        lv_auth_status            VARCHAR2(60)                                := NULL;
        lv_auth_message           VARCHAR2(256)                               := NULL;
        lv_avs_code               VARCHAR2(60)                                := NULL;
        lv_auth_code              VARCHAR2(60)                                := NULL;
        ln_random_num             NUMBER                                      := 0;
--     l_clear_token         varchar2(60);
        x_cc_number_encrypted     VARCHAR2(60);
        x_error_message           VARCHAR2(256);
        x_identifier              VARCHAR2(30);
        -- l_cc_decrypted         VARCHAR2(256) := null;
        -- l_cc_decrypt_error     VARCHAR2(256);
        -- x_cc_number_encrypted varchar2(60);
        -- x_error_message       varchar2(256);
        -- x_identifier          varchAR2(30);
        l_security_error          VARCHAR2(256);

        CURSOR c_inv_details
        IS
            SELECT   (SELECT account_name
                      FROM   hz_cust_accounts_all
                      WHERE  cust_account_id = xx_ar_subscriptions_pkg.get_customer(xac.initial_order_number,
                                                                                    'BILL_TO') ) customer_name,
                     xac.payment_type,
                     xac.store_number,
                     xac.card_token,
                     xac.card_encryption_label,
                     TO_CHAR(xac.card_expiration_date,
                             'YYMM') card_expiration_date,
                     SUM(xas.contract_line_amount) contract_amount,
                     xac.card_type,
                     --xac.clear_token ,
                     xas.invoice_number,
                     xac.contract_number,
                     xac.initial_order_number,
                     xac.bill_to_osr,
                     xas.card_id,
                     xas.contact_person_email,
                     xas.contact_person_phone,
                     xas.contact_person_fax,
                     xas.contract_id,
                     decode(xac.card_type,
                                            'PAYPAL', xac.payment_identifier
                                            ,null
                           ) billingAgreementId,
                     decode(xac.card_type,
                                            'PAYPAL', null
                                            ,xac.payment_identifier
                           ) wallet_id,
                     xas.program_id,
                     xas.billing_sequence_number,
                     xas.contract_line_number
            FROM     xx_ar_subscriptions xas, xx_ar_contract_lines xacl, xx_ar_contracts xac
            WHERE    1 = 1
            AND      xas.contract_id = p_contract_id
            AND      xas.contract_id = xacl.contract_id
            AND      xacl.contract_line_number = xas.contract_line_number
            AND      xas.contract_id = xac.contract_id
            AND      xas.billing_sequence_number = p_billing_sequence_number
            AND      xas.auth_completed_flag in ('N', 'U')
            GROUP BY xac.initial_order_number,
                     xac.payment_type,
                     xac.store_number,
                     xac.card_token,
                     xac.card_encryption_label,
                     xac.card_expiration_date,
                     xac.card_type,
                     --xac.clear_token ,
                     xas.invoice_number,
                     xac.contract_number,
                     xac.initial_order_number,
                     xac.bill_to_osr,
                     xas.card_id,
                     xas.contact_person_email,
                     xas.contact_person_phone,
                     xas.contact_person_fax,
                     xas.contract_id,
                     xac.payment_identifier,
                     xas.program_id,
                     xas.billing_sequence_number,
                     xas.contract_line_number;
    BEGIN
        BEGIN
            SELECT target_value1
            INTO   lv_auth_service_url
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 = 'AUTH_SERVICE';
        EXCEPTION
            WHEN OTHERS
            THEN
                retcode := 2;
                errbuff := 'Error in getting AUTH_SERVICE Service URL from Translation';
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                RETURN;
        END;

        fnd_file.put_line(fnd_file.LOG,
                             '--AUTH_SERVICE_URL: '
                          || lv_auth_service_url);

        BEGIN
            SELECT target_value1,
                   target_value2
            INTO   lv_wallet_location,
                   lv_password
            FROM   xx_fin_translatevalues val, xx_fin_translatedefinition def
            WHERE  1 = 1
            AND    def.translate_id = val.translate_id
            AND    def.translation_name = 'XX_FIN_IREC_TOKEN_PARAMS'
            AND    val.source_value1 = 'WALLET_LOCATION'
            AND    val.enabled_flag = 'Y'
            AND    SYSDATE BETWEEN val.start_date_active AND NVL(val.end_date_active,
                                                                   SYSDATE
                                                                 + 1);
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_wallet_location := NULL;
                lv_password := NULL;
                retcode := 2;
                errbuff :=    errbuff
                           || ' - '
                           || 'Error in getting Wallet Location from Translation';
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                RETURN;
        END;

        BEGIN
            SELECT target_value2,
                   target_value3
            INTO   lv_username,
                   lv_subscription_password
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 = 'AUTH_SERVICE'
            AND    vals.enabled_flag = 'Y'
            AND    SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active,
                                                                    SYSDATE
                                                                  + 1);
        EXCEPTION
            WHEN OTHERS
            THEN
                errbuff :=    errbuff
                           || ' - '
                           || 'Error in getting user crdentials. ';
                fnd_file.put_line(fnd_file.LOG,
                                  'lv_username Not Found');
        END;

        fnd_file.put_line(fnd_file.LOG,
                             'lv_username:'
                          || lv_username);
        fnd_file.put_line(fnd_file.LOG,
                             'lv_subscription_password:'
                          || lv_subscription_password);

        --dbms_output.put_line('lv_username:'||lv_username);
        --dbms_output.put_line('lv_subscription_password:'||lv_subscription_password);
        IF lv_wallet_location IS NOT NULL
        THEN
            UTL_HTTP.set_wallet(lv_wallet_location,
                                lv_password);
        END IF;

        UTL_HTTP.set_response_error_check(FALSE);

        -- End
        FOR v_inv_details IN c_inv_details
        LOOP
            l_cc_decrypted := NULL;
            l_cc_decrypt_error := NULL;
            x_cc_number_encrypted := NULL;
            x_error_message := NULL;
            x_identifier := NULL;
            l_security_error := NULL;

            BEGIN

              IF (v_inv_details.card_type <> 'PAYPAL') THEN

                fnd_file.put_line(fnd_file.LOG,
                                  'Before setting the context--');
                DBMS_SESSION.set_context(namespace =>      'XX_AR_SUBSCRIPTION_CONTEXT',
                                         ATTRIBUTE =>      'TYPE',
                                         VALUE =>          'OM');   --'EBS' Version 1.3
                fnd_file.put_line(fnd_file.LOG,
                                  'After setting the context, and before calling key package--');
                xx_od_security_key_pkg.decrypt(p_module =>             'HVOP',
                                               p_key_label =>          v_inv_details.card_encryption_label,
                                               p_encrypted_val =>      v_inv_details.card_token,
                                               p_format =>             'EBCDIC',
                                               x_decrypted_val =>      l_cc_decrypted,
                                               x_error_message =>      l_cc_decrypt_error);
                fnd_file.put_line(fnd_file.LOG,
                                     'clear token: '
                                  || l_cc_decrypted);
                fnd_file.put_line(fnd_file.LOG,
                                     'clear token error: '
                                  || l_cc_decrypt_error);

                IF (l_cc_decrypted IS NOT NULL)
                THEN
                    xx_od_security_key_pkg.encrypt_outlabel(p_module =>             'AJB',
                                                            p_key_label =>          NULL,
                                                            p_algorithm =>          '3DES',
                                                            p_decrypted_val =>      l_cc_decrypted,
                                                            x_encrypted_val =>      x_cc_number_encrypted,
                                                            x_error_message =>      x_error_message,
                                                            x_key_label =>          x_identifier);
                    fnd_file.put_line(fnd_file.LOG,
                                         'Encrypted token number: '
                                      || x_cc_number_encrypted);
                    fnd_file.put_line(fnd_file.LOG,
                                         'Encrypted token error: '
                                      || x_error_message);
                    fnd_file.put_line(fnd_file.LOG,
                                         'Encrypted token identifier: '
                                      || x_identifier);
                END IF;
              END IF; --end of if payment_type <> 'PAYPAL'
            EXCEPTION
                WHEN OTHERS
                THEN
                    l_cc_decrypted := NULL;   --v_inv_details.clear_token;
                    l_security_error :=
                                  SUBSTR(   'Decrypt: '
                                         || l_cc_decrypt_error
                                         || '- Encrypt: '
                                         || x_error_message,
                                         1,
                                         256);
                    l_cc_decrypt_error :=    'Exception raised while calling XX_OD_SECURITY_KEY_PKG.DECRYPT : '
                                          || SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                         'l_security_error: '
                                      || l_security_error);
                    errbuff :=    errbuff
                               || ' - '
                               || l_cc_decrypt_error;
                    retcode := 2;
                    fnd_file.put_line(fnd_file.LOG,
                                      l_cc_decrypt_error);
                    populate_error(p_contract_id =>               v_inv_details.contract_id,
                                   p_contract_number =>           v_inv_details.contract_number,
                                   p_contract_line_number =>      v_inv_details.contract_line_number,
                                   p_billing_sequence =>          v_inv_details.billing_sequence_number,
                                   p_module =>                    'Process_Authorization',
                                   p_error_msg =>                 errbuff);
            END;

            IF (       v_inv_details.card_type = 'PAYPAL'
                  OR ( x_cc_number_encrypted IS NOT NULL
                       AND x_identifier IS NOT NULL
                      )
                )
            THEN

                --Update the subscription table with decrypted cc_mask value
                UPDATE xx_ar_subscriptions
                SET 
                    settlement_card = x_cc_number_encrypted,
                    settlement_label = x_identifier,
                    settlement_cc_mask =
                                SUBSTR(l_cc_decrypted,
                                       1,
                                       6)
                             || SUBSTR(l_cc_decrypted,
                                         LENGTH(l_cc_decrypted)
                                       - 4,
                                       4),
                    last_update_date = SYSDATE
                WHERE  contract_id = p_contract_id
                AND    billing_sequence_number = p_billing_sequence_number;
                
                COMMIT;

                BEGIN
                    SELECT hl.address1,
                           hl.address2,
                           hl.city,
                           hl.state,
                           SUBSTRB(hl.postal_code,
                                   1,
                                   5),
                           hl.country,
                           (SELECT email_address
                            FROM   hz_contact_points hcp
                            WHERE  hcp.owner_table_name = 'HZ_PARTIES'
                            AND    hcp.contact_point_type = 'EMAIL'
                            AND    hcp.owner_table_id = hps.party_id),
                           (SELECT    hcp.phone_country_code
                                   || '-'
                                   || hcp.phone_area_code
                                   || '-'
                                   || hcp.phone_number
                            FROM   hz_contact_points hcp
                            WHERE  hcp.owner_table_name = 'HZ_PARTIES'
                            AND    hcp.contact_point_type = 'FAX'
                            AND    hcp.owner_table_id = hps.party_id),
                           (SELECT    hcp.phone_country_code
                                   || '-'
                                   || hcp.phone_area_code
                                   || '-'
                                   || hcp.phone_number
                            FROM   hz_contact_points hcp
                            WHERE  hcp.owner_table_name = 'HZ_PARTIES'
                            AND    hcp.contact_point_type = 'PHONE'
                            AND    hcp.owner_table_id = hps.party_id)
                    INTO   lv_cust_address1,
                           lv_cust_address2,
                           lv_cust_city,
                           lv_cust_state,
                           lv_cust_postal_code,
                           lv_cust_country,
                           lv_email_address,
                           lv_fax_number,
                           lv_phone_number
                    FROM   hz_cust_acct_sites_all hcs, hz_party_sites hps, hz_locations hl
                    WHERE  hcs.cust_acct_site_id = get_customer_site(v_inv_details.initial_order_number,
                                                                     'BILL_TO')
                    AND    hps.party_site_id = hcs.party_site_id
                    AND    hps.location_id = hl.location_id;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        lv_cust_address1 := NULL;
                        lv_cust_address2 := NULL;
                        lv_cust_city := NULL;
                        lv_cust_state := NULL;
                        lv_cust_postal_code := NULL;
                        lv_cust_country := NULL;
                        fnd_file.put_line(fnd_file.LOG,
                                             'Exception raised while fetching customer address for contract id: '
                                          || p_contract_id
                                          || ' - '
                                          || SQLERRM);
                END;

                BEGIN
                    SELECT    '{
                "paymentAuthorizationRequest": {
                "transactionHeader": {
                "consumerName": "'
                           || v_inv_details.customer_name
                           || '",
                "consumerTransactionId": "'
                           || v_inv_details.contract_number
                           || '-'
                           || TO_CHAR(SYSDATE,
                                      'DDMONYYYYHH24MISS')
                           || '",
                "consumerTransactionDateTime":"'
                           || TO_CHAR(SYSDATE,
                                      'YYYY-MM-DD')
                           || 'T'
                           || TO_CHAR(SYSDATE,
                                      'HH24:MI:SS')
                           || '"
                },
                "customer": {
                "firstName": "'
                           || v_inv_details.customer_name
                           || '",
                "middleName": "",
                "lastName": "",
                "paymentDetails": {
                "paymentType": "'
                           || v_inv_details.payment_type
                           || '",
                "paymentCard": {
                "cardHighValueToken": "'
                           || l_cc_decrypted
                           || '",
                "expirationDate": "'
                           || v_inv_details.card_expiration_date
                           || '",
                "amount": "'
                           || v_inv_details.contract_amount
                           || '",
                "cardType": "'
                           || v_inv_details.card_type
                           || '",
                "applicationTransactionNumber": "'
                           || v_inv_details.invoice_number
                           || '",
                "billingAddress": {
                "name": "'
                           || v_inv_details.customer_name
                           || '",
                "address": {
                "address1": "'
                           || lv_cust_address1
                           || '",
                "address2": "'
                           || lv_cust_address2
                           || '",
                "city": "'
                           || lv_cust_city
                           || '",
                "state": "'
                           || lv_cust_state
                           || '",
                "postalCode": "'
                           || lv_cust_postal_code
                           || '",
                "country": "'
                           || lv_cust_country
                           || '"
                }
                }
                },
                "billingAgreementId": "'|| v_inv_details.billingAgreementId || '",
                "walletId": "'
                           || v_inv_details.wallet_id
                           || '"
                },
                "contact": {
                "email": "'
                           || lv_email_address
                           || '",
                "phoneNumber": "'
                           || lv_phone_number
                           || '",
                "faxNumber": "'
                           || lv_fax_number
                           || '"
                }
                },
                "storeNumber": "'
                           || v_inv_details.store_number
                           || '"
                }
                }
                '
                    INTO   lv_input_payload
                    FROM   DUAL;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        errbuff :=    errbuff
                                   || ' - '
                                   || 'Exception raised during get_tax_line routine. '
                                   || SQLERRM;
                        fnd_file.put_line(fnd_file.LOG,
                                          errbuff);
                        populate_error(p_contract_id =>               v_inv_details.contract_id,
                                       p_contract_number =>           v_inv_details.contract_number,
                                       p_contract_line_number =>      v_inv_details.contract_line_number,
                                       p_billing_sequence =>          v_inv_details.billing_sequence_number,
                                       p_module =>                    'Process_Authorization',
                                       p_error_msg =>                 errbuff);
                END;

                --Added below  logic by Sridhar B
                BEGIN
                    request := UTL_HTTP.begin_request(lv_auth_service_url,
                                                      'POST',
                                                      ' HTTP/1.1');
                    UTL_HTTP.set_header(request,
                                        'user-agent',
                                        'mozilla/4.0');
                    UTL_HTTP.set_header(request,
                                        'content-type',
                                        'application/json');
                    UTL_HTTP.set_header(request,
                                        'Content-Length',
                                        LENGTH(lv_input_payload) );
                    UTL_HTTP.set_header
                        (request,
                         'Authorization',
                            'Basic '
                         || UTL_RAW.cast_to_varchar2
                                              (UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(   lv_username
                                                                                            || ':'
                                                                                            || lv_subscription_password) ) ) );
                    UTL_HTTP.write_text(request,
                                        lv_input_payload);
                    response := UTL_HTTP.get_response(request);
                    COMMIT;
                    fnd_file.put_line(fnd_file.LOG,
                                         'HTTP response status code: '
                                      || response.status_code);
                EXCEPTION
                    WHEN UTL_HTTP.end_of_body
                    THEN
                        errbuff :=    'Exception Raised-UTL_HTTP.end_of_body-SQLERRM: '
                                   || SQLERRM;
                        fnd_file.put_line(fnd_file.LOG,
                                             'Exception Raised-UTL_HTTP.end_of_body-SQLERRM: '
                                          || SQLERRM);
                        UTL_HTTP.end_response(response);
                        populate_error(p_contract_id =>               v_inv_details.contract_id,
                                       p_contract_number =>           v_inv_details.contract_number,
                                       p_contract_line_number =>      v_inv_details.contract_line_number,
                                       p_billing_sequence =>          v_inv_details.billing_sequence_number,
                                       p_module =>                    'Process_Authorization',
                                       p_error_msg =>                 errbuff);

                        UPDATE xx_ar_subscriptions
                        SET   auth_completed_flag = 'U'
                            , authorization_error = errbuff
                            , last_update_date = SYSDATE
                        WHERE  contract_number = v_inv_details.contract_number
                        AND    billing_sequence_number = v_inv_details.billing_sequence_number
                        AND    contract_line_number = v_inv_details.contract_line_number;

                        COMMIT;
                    WHEN OTHERS
                    THEN
                        errbuff :=    'Unexpected Error Raised during HTTP connection -SQLERRM: '
                                   || SQLERRM;
                        fnd_file.put_line(fnd_file.LOG,
                                             'Unexpected Error Raised during HTTP connection -SQLERRM: '
                                          || SQLERRM);
                        populate_error(p_contract_id =>               v_inv_details.contract_id,
                                       p_contract_number =>           v_inv_details.contract_number,
                                       p_contract_line_number =>      v_inv_details.contract_line_number,
                                       p_billing_sequence =>          v_inv_details.billing_sequence_number,
                                       p_module =>                    'Process_Authorization',
                                       p_error_msg =>                 errbuff);

                        UPDATE xx_ar_subscriptions
                        SET   auth_completed_flag = 'U'
                            , authorization_error = errbuff
                            , last_update_date = SYSDATE
                        WHERE  contract_number = v_inv_details.contract_number
                        AND    billing_sequence_number = v_inv_details.billing_sequence_number
                        AND    contract_line_number = v_inv_details.contract_line_number;

                        COMMIT;
                END;

                IF     response.status_code in (200, 400, 401, 403, 404, 406, 410, 429, 500, 502, 503, 504)
                   --AND l_cc_decrypted IS NOT NULL
                THEN
                    l_payload_id := xx_ar_subscription_payloads_s.NEXTVAL;

                    BEGIN
                        clob_buff := EMPTY_CLOB;

                        LOOP
                            UTL_HTTP.read_text(response,
                                               buff,
                                               LENGTH(buff) );
                            clob_buff :=    clob_buff
                                         || buff;
                            fnd_file.put_line(fnd_file.LOG,
                                                 'In loop : '
                                              || clob_buff);
                        END LOOP;

                        UTL_HTTP.end_response(response);
                    EXCEPTION
                        WHEN UTL_HTTP.end_of_body
                        THEN
                            UTL_HTTP.end_response(response);
                        WHEN OTHERS
                        THEN
                            errbuff :=    errbuff
                                       || ' - '
                                       || 'Exception raised while reading text. ';
                            fnd_file.put_line(fnd_file.LOG,
                                              errbuff);
                            --dbms_output.put_line('Exception raised while reading text: '||SQLERRM);
                            UTL_HTTP.end_response(response);
                            populate_error(p_contract_id =>               v_inv_details.contract_id,
                                           p_contract_number =>           v_inv_details.contract_number,
                                           p_contract_line_number =>      v_inv_details.contract_line_number,
                                           p_billing_sequence =>          v_inv_details.billing_sequence_number,
                                           p_module =>                    'Process_Authorization',
                                           p_error_msg =>                 errbuff);
                    END;

                    BEGIN
                        fnd_file.put_line(fnd_file.LOG,
                                          'Before inserting into xx_ar_subscription_payloads: ');

                        INSERT INTO xx_ar_subscription_payloads
                                    (payload_id,
                                     contract_number,
                                     billing_sequence_number,
                                     contract_line_number,
                                     SOURCE,
                                     response_data,
                                     creation_date,
                                     created_by,
                                     last_update_date,
                                     last_updated_by,
                                     input_payload)
                        VALUES      (l_payload_id,
                                     v_inv_details.contract_number,
                                     v_inv_details.billing_sequence_number,
                                     v_inv_details.contract_line_number,
                                     'AUTH CALL',
                                     clob_buff,
                                     SYSDATE,
                                     fnd_global.user_id,
                                     SYSDATE,
                                     fnd_global.user_id,
                                     lv_input_payload);

                        fnd_file.put_line(fnd_file.LOG,
                                             'After inserting into xx_ar_subscription_payloads: '
                                          || SQL%ROWCOUNT);
                        COMMIT;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            errbuff :=    errbuff
                                       || ' - '
                                       || 'Exception in inserting into xx_ar_subscription_payloads. ';
                            fnd_file.put_line(fnd_file.LOG,
                                                 'Exception in inserting into xx_ar_subscription_payloads: '
                                              || SQLERRM);
                            populate_error(p_contract_id =>               v_inv_details.contract_id,
                                           p_contract_number =>           v_inv_details.contract_number,
                                           p_contract_line_number =>      v_inv_details.contract_line_number,
                                           p_billing_sequence =>          v_inv_details.billing_sequence_number,
                                           p_module =>                    'Process_Authorization',
                                           p_error_msg =>                 errbuff);
                    END;
                ELSE
                    UPDATE xx_ar_subscriptions
                    SET   auth_completed_flag = 'U'
                        , authorization_error =    'Authorization process fails with response code: '
                                              || response.status_code
                        , last_update_date = SYSDATE
                    WHERE  contract_id = p_contract_id
                    AND    billing_sequence_number = p_billing_sequence_number;

                    errbuff :=
                             errbuff
                          || ' - '
                          || 'Authorization process fails with response code: '
                          || response.status_code;
                    fnd_file.put_line(fnd_file.LOG,
                                      errbuff);
                    UTL_HTTP.end_response(response);
                END IF;

                --Get Authorization Code
                BEGIN
                    SELECT jt.auth_status
                    INTO   p_response_code
                    FROM   xx_ar_subscription_payloads auth_response,
                           JSON_TABLE ( auth_response.response_data, '$.paymentAuthorizationResponse.transactionStatus' COLUMNS ( "AUTH_STATUS" VARCHAR2(30) PATH '$.message' )) "JT"
                    WHERE  auth_response.payload_id = l_payload_id;

                    SELECT jt0.transactionid,
                           jt0.transactiondatetime,
                           jt1.transaction_code,
                           jt1.transaction_message,
                           jt2.auth_status,
                           jt2.auth_message,
                           jt2.avs_code,
                           jt2.auth_code
                    INTO   lv_transactionid,
                           lv_transactiondatetime,
                           lv_transaction_code,
                           lv_transaction_message,
                           lv_auth_status,
                           lv_auth_message,
                           lv_avs_code,
                           lv_auth_code
                    FROM   xx_ar_subscription_payloads auth_response,
                           JSON_TABLE ( auth_response.response_data, '$.paymentAuthorizationResponse.transactionHeader' COLUMNS ( "TransactionId"    VARCHAR2(60) PATH '$.consumerTransactionId' ,"TransactionDateTime" VARCHAR2(30) PATH '$.consumerTransactionDateTime' )) "JT0" ,
                           JSON_TABLE ( auth_response.response_data, '$.paymentAuthorizationResponse.transactionStatus' COLUMNS ( "TRANSACTION_CODE" VARCHAR2(60) PATH '$.code' ,"TRANSACTION_MESSAGE" VARCHAR2(256) PATH '$.message' )) "JT1" ,
                           JSON_TABLE ( auth_response.response_data, '$.paymentAuthorizationResponse.authorizationResult' COLUMNS ( "AUTH_STATUS"    VARCHAR2(60) PATH '$.code' ,"AUTH_MESSAGE" VARCHAR2(256) PATH '$.message' ,"AVS_CODE" VARCHAR2(60) PATH '$.avsCode' ,"AUTH_CODE" VARCHAR2(60) PATH '$.authCode' )) "JT2"
                    WHERE  auth_response.payload_id = l_payload_id;

                    p_response_code := lv_auth_status;
                    p_auth_message := lv_auth_message;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Authorization status and auth_message for contract id: '
                                      || p_contract_id
                                      || ' - is: '
                                      || p_response_code
                                      || ','
                                      || lv_auth_message);

                    IF lv_auth_status = '0'
                    THEN
                        UPDATE xx_ar_subscriptions
                        SET authorization_code = lv_transaction_code,
                            auth_datetime = lv_transactiondatetime,
                            auth_transactionid = lv_transactionid,
                            auth_transaction_message = lv_transaction_message,
                            auth_status = lv_auth_status,
                            auth_message = lv_auth_message,
                            auth_avs_code = lv_avs_code,
                            auth_code = lv_auth_code,
                            auth_completed_flag = 'Y',
                            email_sent_flag = 'N',
                            last_update_date = SYSDATE
                        WHERE  contract_id = p_contract_id
                        AND    billing_sequence_number = p_billing_sequence_number;
                    ELSE
                        UPDATE xx_ar_subscriptions
                        SET auth_completed_flag = 'E',
                            email_sent_flag = 'N',
                            authorization_error = lv_auth_message,
                            last_update_date = SYSDATE
                        WHERE  contract_id = p_contract_id
                        AND    billing_sequence_number = p_billing_sequence_number;
                    END IF;

                    COMMIT;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        errbuff :=    'Exception in Process Authorization: '
                                   || SQLERRM;
                        fnd_file.put_line(fnd_file.LOG,
                                          errbuff);


                        SELECT jt0.transactionid,
                               jt0.transactiondatetime,
                               jt1.transaction_code,
                               jt1.transaction_message
                        INTO   lv_transactionid,
                               lv_transactiondatetime,
                               lv_transaction_code,
                               lv_transaction_message
                        FROM   xx_ar_subscription_payloads auth_response,
                               JSON_TABLE ( auth_response.response_data, '$.paymentAuthorizationResponse.transactionHeader' COLUMNS ( "TransactionId"    VARCHAR2(60) PATH '$.consumerTransactionId' ,"TransactionDateTime" VARCHAR2(30) PATH '$.consumerTransactionDateTime' )) "JT0" ,
                               JSON_TABLE ( auth_response.response_data, '$.paymentAuthorizationResponse.transactionStatus' COLUMNS ( "TRANSACTION_CODE" VARCHAR2(60) PATH '$.code' ,"TRANSACTION_MESSAGE" VARCHAR2(256) PATH '$.message' )) "JT1" 
                        WHERE  auth_response.payload_id = l_payload_id;
                    
                    
                        UPDATE xx_ar_subscriptions
                        SET authorization_code = substr(lv_transaction_code,1,15),
                            auth_datetime = lv_transactiondatetime,
                            auth_transactionid = lv_transactionid,
                            auth_transaction_message = lv_transaction_message,
                            auth_completed_flag = 'U',
                            last_update_date = SYSDATE
                        WHERE  contract_id = p_contract_id
                        AND    billing_sequence_number = p_billing_sequence_number;                  

                        COMMIT;
                        CONTINUE;
                        populate_error(p_contract_id =>               v_inv_details.contract_id,
                                       p_contract_number =>           v_inv_details.contract_number,
                                       p_contract_line_number =>      v_inv_details.contract_line_number,
                                       p_billing_sequence =>          v_inv_details.billing_sequence_number,
                                       p_module =>                    'Process_Authorization',
                                       p_error_msg =>                 errbuff);
                END;
            --fnd_file.put_line (fnd_file.LOG,':l_auth_code ' || l_auth_code);
            ELSE
                UPDATE xx_ar_subscriptions
                SET auth_completed_flag = 'U',
                    authorization_error = l_security_error,
                    last_update_date = SYSDATE
                WHERE  contract_id = p_contract_id
                AND    billing_sequence_number = p_billing_sequence_number;
            END IF;

            COMMIT;
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            errbuff :=    'Unhandled exception raised during Process Authorization: '
                       || SQLERRM;
            populate_error(p_contract_id =>               p_contract_id,
                           p_contract_number =>           NULL,
                           p_contract_line_number =>      NULL,
                           p_billing_sequence =>          p_billing_sequence_number,
                           p_module =>                    'Process_Authorization',
                           p_error_msg =>                 errbuff);
            fnd_file.put_line(fnd_file.LOG,
                                 'Unhandled exception raised during Process Authorization-SQLERRM-'
                              || SQLERRM);
    END process_authorization;

    PROCEDURE process_invoices(
        errbuff  OUT  VARCHAR2,
        retcode  OUT  VARCHAR2
                              --p_trans_type   IN VARCHAR2 ,
                              --p_trans_source IN VARCHAR2 DEFAULT NULL
    )
    IS
        lv_error_flag             VARCHAR2(1);
        lv_org_id                 hr_operating_units.organization_id%TYPE;
        lv_sob_id                 hr_operating_units.set_of_books_id%TYPE;
        lv_batch_source_name      ra_batch_sources_all.NAME%TYPE;
        lv_batch_source_id        ra_batch_sources_all.batch_source_id%TYPE;
        ln_cust_account_id        hz_cust_accounts.cust_account_id%TYPE;
        ln_cust_acct_site_id      hz_cust_acct_sites_all.cust_acct_site_id%TYPE;
        lv_term_id                NUMBER;
        lv_term_name              VARCHAR2(256);
        lv_trx_type_name          VARCHAR2(256);
        lv_trx_type               VARCHAR2(256);
        ln_trx_type_id            NUMBER;
        ln_autoinv_req_id         NUMBER;
        lv_autoinv_complete_bln   BOOLEAN;
        lv_phase_txt              VARCHAR2(20);
        lv_status_txt             VARCHAR2(20);
        lv_dev_phase_txt          VARCHAR2(20);
        lv_dev_status_txt         VARCHAR2(20);
        lv_message_txt            VARCHAR2(200);
        ln_min_interface_line_id  NUMBER                                          := 0;
        ln_batch_source_id        NUMBER                                          := 0;
        lv_invoic_creation_error  VARCHAR2(256)                                   := NULL;
        l_trx_type                xx_fin_translatevalues.target_value1%TYPE       := NULL;
        l_trx_source              xx_fin_translatevalues.target_value1%TYPE       := NULL;

        CURSOR cur_autoinv_error
        IS
            SELECT DECODE(INSTR(ril.interface_line_attribute3,
                                '-TAX'),
                          0, ril.interface_line_attribute3,
                          SUBSTR(ril.interface_line_attribute3,
                                 1,
                                 (  INSTR(ril.interface_line_attribute3,
                                          '-TAX')
                                  - 1) ) ) contract_line_number,
                   DECODE(INSTR(ril.interface_line_attribute4,
                                '-TAX'),
                          0, ril.interface_line_attribute4,
                          SUBSTR(ril.interface_line_attribute4,
                                 1,
                                 (  INSTR(ril.interface_line_attribute4,
                                          '-TAX')
                                  - 1) ) ) contract_bill_seq,
                   DECODE(INSTR(ril.interface_line_attribute5,
                                '-TAX'),
                          0, ril.interface_line_attribute5,
                          SUBSTR(ril.interface_line_attribute5,
                                 1,
                                 (  INSTR(ril.interface_line_attribute5,
                                          '-TAX')
                                  - 1) ) ) contract_number,
                   int_err.interface_line_id,
                   int_err.MESSAGE_TEXT,
                   int_err.invalid_value
            FROM   ra_interface_errors_all int_err, ra_interface_lines_all ril
            WHERE  int_err.interface_line_id = ril.interface_line_id
            AND    ril.interface_line_context = 'RECURRING BILLING'
            AND    TRUNC(ril.creation_date) = TRUNC(SYSDATE)
            UNION ALL
            SELECT DECODE(INSTR(ril.interface_line_attribute3,
                                '-TAX'),
                          0, ril.interface_line_attribute3,
                          SUBSTR(ril.interface_line_attribute3,
                                 1,
                                 (  INSTR(ril.interface_line_attribute3,
                                          '-TAX')
                                  - 1) ) ) contract_line_number,
                   DECODE(INSTR(ril.interface_line_attribute4,
                                '-TAX'),
                          0, ril.interface_line_attribute4,
                          SUBSTR(ril.interface_line_attribute4,
                                 1,
                                 (  INSTR(ril.interface_line_attribute4,
                                          '-TAX')
                                  - 1) ) ) contract_bill_seq,
                   DECODE(INSTR(ril.interface_line_attribute5,
                                '-TAX'),
                          0, ril.interface_line_attribute5,
                          SUBSTR(ril.interface_line_attribute5,
                                 1,
                                 (  INSTR(ril.interface_line_attribute5,
                                          '-TAX')
                                  - 1) ) ) contract_number,
                   int_err.interface_line_id,
                   int_err.MESSAGE_TEXT,
                   int_err.invalid_value
            FROM   ra_interface_errors_all int_err, ra_interface_distributions_all ril
            WHERE  int_err.interface_distribution_id = ril.interface_distribution_id
            AND    ril.interface_line_context = 'RECURRING BILLING'
            AND    TRUNC(ril.creation_date) = TRUNC(SYSDATE)
            AND    NOT EXISTS(
                       SELECT 1
                       FROM   xx_ar_subscriptions_error xasr
                       WHERE  xasr.contract_number =
                                  DECODE(INSTR(ril.interface_line_attribute5,
                                               '-TAX'),
                                         0, ril.interface_line_attribute5,
                                         SUBSTR(ril.interface_line_attribute5,
                                                1,
                                                (  INSTR(ril.interface_line_attribute5,
                                                         '-TAX')
                                                 - 1) ) )
                       AND    xasr.contract_line_number =
                                  DECODE(INSTR(ril.interface_line_attribute3,
                                               '-TAX'),
                                         0, ril.interface_line_attribute3,
                                         SUBSTR(ril.interface_line_attribute3,
                                                1,
                                                (  INSTR(ril.interface_line_attribute3,
                                                         '-TAX')
                                                 - 1) ) )
                       AND    xasr.billing_sequence_number =
                                  DECODE(INSTR(ril.interface_line_attribute4,
                                               '-TAX'),
                                         0, ril.interface_line_attribute4,
                                         SUBSTR(ril.interface_line_attribute4,
                                                1,
                                                (  INSTR(ril.interface_line_attribute4,
                                                         '-TAX')
                                                 - 1) ) )
                       AND    error_message LIKE(   int_err.MESSAGE_TEXT
                                                 || '%') );

        CURSOR cur_subscription_inv(
            p_min_interface_line_id  NUMBER,
            p_trans_source           VARCHAR2)
        IS
            SELECT *
            FROM   ra_interface_lines_all
            WHERE  1 = 1
            AND    interface_line_id >   p_min_interface_line_id
                                       - 1
            AND    batch_source_name = NVL(p_trans_source,
                                           batch_source_name)
            --AND header_attribute_category='US_SUBSCRIPTIONS'  -- Commented by JAI_CG
            AND    header_attribute_category = 'SALES_ACCT'   -- Added by JAI_CG
                                                           ;
    BEGIN
        fnd_file.put_line(fnd_file.LOG,
                          '**********************************');
        fnd_file.put_line(fnd_file.LOG,
                          'Starting Process Invoice routine. ');
        fnd_file.put_line(fnd_file.LOG,
                          '**********************************');

        -- Start fetching Transaction Type by JAI_CG
        BEGIN
            SELECT vals.target_value1
            INTO   l_trx_type
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 LIKE 'TRANSACTION_TYPE';

            fnd_file.put_line(fnd_file.LOG,
                                 'Transaction type fetched is: '
                              || l_trx_type);

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
                fnd_log.STRING(fnd_log.level_statement,
                               'XX_AR_SUBSCRIPTIONS_PKG.process_invoices',
                                  'Transaction type fetched is: '
                               || l_trx_type);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'TRANSACTION_TYPE Translation Not Found in OD_SUBSCRIPTION_TRANSLATION');

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.process_invoices',
                                   'TRANSACTION_TYPE Translation Not Found in OD_SUBSCRIPTION_TRANSLATION');
                END IF;
        END;

        -- Start fetching Transaction Source by JAI_CG
        BEGIN
            SELECT vals.target_value1
            INTO   l_trx_source
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 LIKE 'TRANSACTION_SOURCE';

            fnd_file.put_line(fnd_file.LOG,
                                 'Transaction source fetched is: '
                              || l_trx_source);

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
                fnd_log.STRING(fnd_log.level_statement,
                               'XX_AR_SUBSCRIPTIONS_PKG.process_invoices',
                                  'Transaction source fetched is: '
                               || l_trx_source);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'TRANSACTION_SOURCE Translation Not Found in OD_SUBSCRIPTION_TRANSLATION');   -- Added by JAI_CG

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.process_invoices',
                                   'TRANSACTION_SOURCE Translation Not Found in OD_SUBSCRIPTION_TRANSLATION');
                END IF;
        END;

        --Get Min interface_line_id
        BEGIN
            SELECT MIN(interface_line_id)
            INTO   ln_min_interface_line_id
            FROM   ra_interface_lines_all
            WHERE  batch_source_name = l_trx_source
            AND    cust_trx_type_name = l_trx_type
            AND    TRUNC(creation_date) = TRUNC(SYSDATE);
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_invoic_creation_error := 'ln_mix_interface_line_id Error. ';
                fnd_file.put_line(fnd_file.LOG,
                                     lv_invoic_creation_error
                                  || ' - '
                                  || SQLERRM);
        END;

        fnd_file.put_line(fnd_file.LOG,
                             'Min interface_line_id is: '
                          || ln_min_interface_line_id);

        --ORG ID , SOB
        BEGIN
            SELECT organization_id,
                   set_of_books_id
            INTO   lv_org_id,
                   lv_sob_id
            FROM   hr_operating_units
            WHERE  NAME = 'OU_US';
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Operating Unit Error: '
                                  || SQLERRM);
        END;

        -- Get batch detail
        BEGIN
            SELECT rbs.batch_source_id
            INTO   ln_batch_source_id
            FROM   ra_batch_sources_all rbs
            WHERE  rbs.NAME = l_trx_source   --'CONVERSION_OD' --'SALES_ACCT_US'  -- Added by JAI_CG
            AND    rbs.status = 'A'
            AND    rbs.org_id = lv_org_id;
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_invoic_creation_error :=    'Transaction source validation failed for : '
                                            || l_trx_source;
                fnd_file.put_line(fnd_file.LOG,
                                     lv_invoic_creation_error
                                  || ' - '
                                  || SQLERRM);
        END;

        fnd_file.put_line(fnd_file.LOG,
                             'Batch source id for source: '
                          || l_trx_source
                          || ' is: '
                          || ln_batch_source_id);

------------------------------Cust Trx Type-------------------------------------------------------------
        BEGIN
            lv_trx_type_name := NULL;
            ln_trx_type_id := NULL;
            lv_trx_type := NULL;

            SELECT rctt.NAME,
                   rctt.cust_trx_type_id,
                   rctt.TYPE
            INTO   lv_trx_type_name,
                   ln_trx_type_id,
                   lv_trx_type
            FROM   ra_cust_trx_types_all rctt, hr_operating_units hou
            WHERE  1 = 1
            AND    rctt.NAME = l_trx_type
            AND    rctt.org_id = hou.organization_id
            AND    hou.NAME = 'OU_US';

            fnd_file.put_line(fnd_file.LOG,
                                 'Cust Trx Type: '
                              || lv_trx_type_name
                              || ', cust_trx_type_id:'
                              || ln_trx_type_id
                              || ', trx type:'
                              || lv_trx_type);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_invoic_creation_error :=    'Cust Trx Type No Data Found: '
                                            || l_trx_type;
                fnd_file.put_line(fnd_file.LOG,
                                     lv_invoic_creation_error
                                  || ' - '
                                  || SQLERRM);
            WHEN TOO_MANY_ROWS
            THEN
                lv_invoic_creation_error :=    'Cust Trx Type Too Many Rows: '
                                            || l_trx_type;
                fnd_file.put_line(fnd_file.LOG,
                                     lv_invoic_creation_error
                                  || ' - '
                                  || SQLERRM);
            WHEN OTHERS
            THEN
                lv_invoic_creation_error :=    'Cust Trx Type Unexpected Error : '
                                            || l_trx_type;
                fnd_file.put_line(fnd_file.LOG,
                                     lv_invoic_creation_error
                                  || ' - '
                                  || SQLERRM);
        END;

        FOR i IN cur_subscription_inv(ln_min_interface_line_id,
                                      l_trx_source)
        LOOP
            lv_error_flag := 'N';
            lv_batch_source_name := NULL;
            lv_batch_source_id := NULL;
            ln_cust_account_id := NULL;
            ln_cust_acct_site_id := NULL;
            lv_term_id := NULL;
            lv_term_name := NULL;

------------------------------Validate Terms-------------------------------------------------------------
            IF lv_trx_type <> 'CM'
            THEN
                BEGIN
                    SELECT rt.term_id,
                           rt.NAME
                    INTO   lv_term_id,
                           lv_term_name
                    FROM   hz_cust_profile_classes cpc, ra_terms rt
                    WHERE  cpc.standard_terms = rt.term_id
                    AND    cpc.NAME = 'CREDIT_CARD';
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'Payment Terms No Data Found: '
                                          || i.cust_trx_type_name
                                          || ' - '
                                          || SQLERRM);
                    WHEN TOO_MANY_ROWS
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'Payment Terms Too Many Rows: '
                                          || i.cust_trx_type_name
                                          || ' - '
                                          || SQLERRM);
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'Payment Terms Unexpected Error: '
                                          || i.cust_trx_type_name
                                          || ' - '
                                          || SQLERRM);
                END;
            ELSE
                lv_term_id := NULL;
                lv_term_name := NULL;
            END IF;

            BEGIN
                --fnd_file.put_line(fnd_file.LOG,'Updating interface record for line:' || i.interface_line_id);
                BEGIN
                    UPDATE ra_interface_lines_all
                    SET term_id = lv_term_id,
                        term_name = lv_term_name,
                        org_id = lv_org_id,
                        cust_trx_type_name = lv_trx_type_name,
                        cust_trx_type_id = ln_trx_type_id,
                        set_of_books_id = lv_sob_id,
                        last_update_date = SYSDATE
                    WHERE  interface_line_id = i.interface_line_id;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'Exception raised while updating interface table: '
                                          || SQLERRM);
                END;

                COMMIT;
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'Unexpected Error in validating invoices: '
                                      || SQLERRM);
            END;
        END LOOP;

        -- Kick off Auto Invoice master program
        fnd_file.put_line(fnd_file.LOG,
                             'Kick off Auto Invoice master program for org: '
                          || lv_org_id);

        BEGIN
            ln_autoinv_req_id :=
                fnd_request.submit_request(application =>      'AR',
                                           program =>          'RAXMTR',
                                           description =>      'Autoinvoice Master Program',
                                           start_time =>       SYSDATE,
                                           argument1 =>        1,
                                           argument2 =>        lv_org_id,
                                           argument3 =>        ln_batch_source_id,
                                           argument4 =>        l_trx_source,
                                           argument5 =>        TO_CHAR(TRUNC(SYSDATE),
                                                                       'RRRR/MM/DD HH24:MI:SS'),
                                           argument6 =>        '',
                                           argument7 =>        ln_trx_type_id,
                                           argument8 =>        '',
                                           argument9 =>        '',
                                           argument10 =>       '',
                                           argument11 =>       '',
                                           argument12 =>       '',
                                           argument13 =>       '',
                                           argument14 =>       '',
                                           argument15 =>       '',
                                           argument16 =>       '',
                                           argument17 =>       '',
                                           argument18 =>       '',
                                           argument19 =>       '',
                                           argument20 =>       '',
                                           argument21 =>       '',
                                           argument22 =>       '',
                                           argument23 =>       '',
                                           argument24 =>       '',
                                           argument25 =>       '',
                                           argument26 =>       'Y',
                                           argument27 =>       '',
                                           argument28 =>       CHR(0) );
            COMMIT;

            IF ln_autoinv_req_id = 0
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  '************************************************');
                fnd_file.put_line(fnd_file.LOG,
                                  'Conc. Program  failed to submit Auto Invoice. ');
                fnd_file.put_line(fnd_file.LOG,
                                  '************************************************');
                retcode := 2;
            ELSE
                lv_autoinv_complete_bln :=
                    fnd_concurrent.wait_for_request(request_id =>      ln_autoinv_req_id,
                                                    phase =>           lv_phase_txt,
                                                    status =>          lv_status_txt,
                                                    dev_phase =>       lv_dev_phase_txt,
                                                    dev_status =>      lv_dev_status_txt,
                                                    MESSAGE =>         lv_message_txt);

                IF     UPPER(lv_dev_status_txt) = 'NORMAL'
                   AND UPPER(lv_dev_phase_txt) = 'COMPLETE'
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'Auto Invoice program successful for the Request Id: '
                                      || ln_autoinv_req_id
                                      || ' and Batch Source: '
                                      || l_trx_source
                                      || '. ');
                ELSE
                    fnd_file.put_line(fnd_file.LOG,
                                      'Auto Invoice Program does not completed normally. ');
                    retcode := 2;
                END IF;
            END IF;

            -- Populatin error table
            FOR rec_autoinv_error IN cur_autoinv_error
            LOOP
                populate_error(p_contract_id =>               NULL,
                               p_contract_number =>           rec_autoinv_error.contract_number,
                               p_contract_line_number =>      rec_autoinv_error.contract_line_number,
                               p_billing_sequence =>          rec_autoinv_error.contract_bill_seq,
                               p_module =>                    'process_invoices',
                               p_error_msg =>                    rec_autoinv_error.MESSAGE_TEXT
                                                              || ' - '
                                                              || rec_autoinv_error.invalid_value);
            END LOOP;
        EXCEPTION
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  '**********************************************');
                fnd_file.put_line(fnd_file.LOG,
                                     'Exception In Submit Auto Invoice Program :'
                                  || '-'
                                  || SQLERRM);
                fnd_file.put_line(fnd_file.LOG,
                                  '**********************************************');
                retcode := 2;   -- Terminate the program
        END;
    END process_invoices;

    PROCEDURE create_receipts(
        errbuff                    OUT     VARCHAR2,
        retcode                    OUT     VARCHAR2,
        p_account_number           IN      VARCHAR2,
        p_rcpt_method_name         IN      VARCHAR2,
        p_receipt_amount           IN      VARCHAR2,
        p_org_id                   IN      NUMBER,
        p_cust_trx                 IN      NUMBER,
        p_contract_id              IN      NUMBER,
        p_billing_sequence_number  IN      NUMBER,
        x_receipt_id               OUT     NUMBER)
    IS
        l_return_status         VARCHAR2(1)                                 := NULL;
        l_msg_data              VARCHAR2(2000)                              := NULL;
        l_msg_count             NUMBER                                      := 0;
        l_receipt_count         NUMBER                                      := 0;
        l_receipt_creation_err  VARCHAR2(256)                               := NULL;
        --ln_receipt_id    AR_CASH_RECEIPTS.cash_receipt_id%TYPE;
        l_attrib                ar_receipt_api_pub.attribute_rec_type;
        l_contract_number       xx_ar_subscriptions.contract_number%TYPE    := NULL;
        l_store_number          xx_fin_translatevalues.target_value1%TYPE   := NULL;
        lv_rcpt_created_flg     VARCHAR2(1)                                 := 'N';
        ln_rcpt_number          ar_cash_receipts_all.receipt_number%TYPE    := NULL;
    BEGIN
        -- Fetching receipt attributes
        BEGIN
            SELECT 'SALES_ACCT',
                   xac.store_number,
                   xac.initial_order_number,
                   (SELECT orig_sys_document_ref
                    FROM   oe_order_headers_all
                    WHERE  order_number = xac.initial_order_number),
                   xac.card_type,
                   xac.contract_number
            INTO   l_attrib.attribute_category,
                   l_attrib.attribute1   --l_store_number
                                      ,
                   l_attrib.attribute12   --l_initial_order
                                       ,
                   l_attrib.attribute7   --l_legacy_order
                                      ,
                   l_attrib.attribute14   --l_card_type
                                       ,
                   l_contract_number
            FROM   xx_ar_contracts xac
            WHERE  xac.contract_id = p_contract_id;
        EXCEPTION
            WHEN OTHERS
            THEN
                errbuff :=    'Exception raised while fetching receipt attributes: '
                           || SQLERRM;
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                populate_error(p_contract_id =>               p_contract_id,
                               p_contract_number =>           l_contract_number,
                               p_contract_line_number =>      NULL,
                               p_billing_sequence =>          p_billing_sequence_number,
                               p_module =>                    'create_receipts',
                               p_error_msg =>                 errbuff);
        END;

        --Create Receipt
        BEGIN
            -- Call Api to create receipt
            ar_receipt_api_pub.create_cash
                                      (p_api_version =>                     1.0,
                                       p_init_msg_list =>                   fnd_api.g_true,
                                       p_commit =>                          fnd_api.g_false,
                                       p_validation_level =>                fnd_api.g_valid_level_full,
                                       p_currency_code =>                   'USD',
                                       p_exchange_rate_type =>              NULL,
                                       p_exchange_rate =>                   NULL,
                                       p_exchange_rate_date =>              NULL,
                                       p_amount =>                          p_receipt_amount,
                                       p_receipt_number =>                  NULL   --'Subs-'||XX_ARTRX_SUBSCRIPTIONS_S.nextval --pass null
                                                                                ,
                                       p_receipt_date =>                    SYSDATE,
                                       p_maturity_date =>                   NULL,
                                       p_customer_name =>                   NULL,
                                       p_customer_number =>                 p_account_number,
                                       p_comments =>                        NULL,
                                       p_location =>                        NULL,
                                       p_customer_bank_account_num =>       NULL,
                                       p_customer_bank_account_name =>      NULL,
                                       p_receipt_method_name =>             p_rcpt_method_name,
                                       p_attribute_rec =>                   l_attrib   --'US_OM_CASH_000087',
                                                                                    ,
                                       p_org_id =>                          p_org_id,
                                       p_cr_id =>                           x_receipt_id,
                                       x_return_status =>                   l_return_status,
                                       x_msg_count =>                       l_msg_count,
                                       x_msg_data =>                        l_msg_data);

            IF l_return_status = 'S'
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Receipt Created Successfully, Receipt_id: '
                                  || x_receipt_id);
                l_receipt_count :=   l_receipt_count
                                   + 1;

                BEGIN
                    SELECT acr.receipt_number
                    INTO   ln_rcpt_number
                    FROM   ar_cash_receipts_all acr
                    WHERE  acr.cash_receipt_id = x_receipt_id;

                    lv_rcpt_created_flg := 'Y';
                    fnd_file.put_line(fnd_file.LOG,
                                         'receipt number for ln_receipt_id: '
                                      || x_receipt_id
                                      || ': '
                                      || ln_rcpt_number);
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'No data found while fetching receipt number: '
                                          || DBMS_UTILITY.format_error_backtrace
                                          || SQLERRM);
                        lv_rcpt_created_flg := 'N';
                        ln_rcpt_number := NULL;
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                             'Exception raised while fetching receipt number: '
                                          || DBMS_UTILITY.format_error_backtrace
                                          || SQLERRM);
                        lv_rcpt_created_flg := 'N';
                        ln_rcpt_number := NULL;
                END;

                UPDATE xx_ar_subscriptions xas
                SET xas.receipt_created_flag = lv_rcpt_created_flg,
                    receipt_number = ln_rcpt_number,
                    last_update_date = SYSDATE
                WHERE  1 = 1
                AND    xas.contract_id = p_contract_id
                AND    xas.billing_sequence_number = p_billing_sequence_number
                AND    NVL(invoice_interfaced_flag,
                           'N') = 'Y';
            ELSE
                fnd_file.put_line(fnd_file.LOG,
                                     'Message count '
                                  || l_msg_count);

                IF l_msg_count = 1
                THEN
                    l_msg_data :=    'Error while creating the receipt-'
                                  || l_msg_data;
                    fnd_file.put_line(fnd_file.LOG,
                                      l_msg_data);
                ELSE
                    FOR r IN 1 .. l_msg_count
                    LOOP
                        l_msg_data :=    l_msg_data
                                      || ' ,'
                                      || fnd_msg_pub.get(fnd_msg_pub.g_next,
                                                         fnd_api.g_false);
                        --l_msg_data := fnd_msg_pub.get(fnd_msg_pub.g_next,fnd_api.g_false);
                        fnd_file.put_line(fnd_file.LOG,
                                             'API error while creating receipts : '
                                          || l_msg_data);
                    END LOOP;
                END IF;

                populate_error(p_contract_id =>               p_contract_id,
                               p_contract_number =>           l_contract_number,
                               p_contract_line_number =>      NULL,
                               p_billing_sequence =>          p_billing_sequence_number,
                               p_module =>                    'create_receipts',
                               p_error_msg =>                    l_msg_count
                                                              || ' - '
                                                              || l_msg_data);
            END IF;

            l_receipt_creation_err := SUBSTR(l_msg_data,
                                             1,
                                             256);
        EXCEPTION
            WHEN OTHERS
            THEN
                errbuff :=
                       'Unexpected Error in XX_AR_SUBSCRIPTION_PKG.CREATE_RECEIPTS: '
                    || DBMS_UTILITY.format_error_backtrace
                    || SQLERRM;
                l_receipt_creation_err := errbuff;
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                populate_error(p_contract_id =>               p_contract_id,
                               p_contract_number =>           l_contract_number,
                               p_contract_line_number =>      NULL,
                               p_billing_sequence =>          p_billing_sequence_number,
                               p_module =>                    'create_receipts',
                               p_error_msg =>                 errbuff);
        END;

        --Apply Cash
        BEGIN
            l_receipt_creation_err := SUBSTR(l_msg_data,
                                             1,
                                             256);
            l_msg_count := 0;
            l_msg_data := NULL;
            l_return_status := NULL;

            IF x_receipt_id IS NOT NULL
            THEN
                ar_receipt_api_pub.APPLY(p_api_version =>           1.0,
                                         p_init_msg_list =>         fnd_api.g_true,
                                         p_commit =>                fnd_api.g_false,
                                         p_validation_level =>      fnd_api.g_valid_level_full,
                                         x_return_status =>         l_return_status,
                                         x_msg_count =>             l_msg_count,
                                         x_msg_data =>              l_msg_data,
                                         p_cash_receipt_id =>       x_receipt_id,
                                         p_customer_trx_id =>       p_cust_trx,
                                         p_amount_applied =>        p_receipt_amount,
                                         p_discount =>              NULL,
                                         p_apply_date =>            SYSDATE);

                IF l_return_status = 'S'
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'Invoice Applied Successfully for receipt id: '
                                      || x_receipt_id
                                      || ' and invoice id: '
                                      || p_cust_trx);
                ELSE
                    fnd_file.put_line(fnd_file.LOG,
                                         'Message count '
                                      || l_msg_count);

                    IF l_msg_count = 1
                    THEN
                        l_msg_data :=    'Error while applying cash to the receipt - '
                                      || x_receipt_id || ': ' || l_msg_data;
                        fnd_file.put_line(fnd_file.LOG,
                                          l_msg_data);
                    ELSE
                        FOR r IN 1 .. l_msg_count
                        LOOP

                          l_msg_data :=    l_msg_data
                                        || ' ,'
                                        || fnd_msg_pub.get(fnd_msg_pub.g_next,
                                                           fnd_api.g_false);
                        END LOOP;
                        fnd_file.put_line(fnd_file.LOG,
                                          'API error while Applying Cash to the Receipt : '
                                          || x_receipt_id || ': ' || l_msg_data);
                    END IF;

                    l_receipt_creation_err := SUBSTR(   l_receipt_creation_err
                                                     || ' - '
                                                     || l_msg_data,
                                                     1,
                                                     256);
                    populate_error(p_contract_id =>               p_contract_id,
                                   p_contract_number =>           l_contract_number,
                                   p_contract_line_number =>      NULL,
                                   p_billing_sequence =>          p_billing_sequence_number,
                                   p_module =>                    'create_receipts: apply_cash',
                                   p_error_msg =>                    l_msg_count
                                                                  || ' - '
                                                                  || l_msg_data);
                END IF;
            END IF;

            COMMIT;
        EXCEPTION
            WHEN OTHERS
            THEN
                errbuff :=
                       'Unexpected Error in XX_AR_SUBSCRIPTION_PKG.CREATE_RECEIPTS While APPLY_CASH: '
                    || DBMS_UTILITY.format_error_backtrace
                    || SQLERRM;
                l_receipt_creation_err := SUBSTR(   l_receipt_creation_err
                                                 || ' - '
                                                 || errbuff,
                                                 1,
                                                 256);
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                populate_error(p_contract_id =>               p_contract_id,
                               p_contract_number =>           l_contract_number,
                               p_contract_line_number =>      NULL,
                               p_billing_sequence =>          p_billing_sequence_number,
                               p_module =>                    'create_receipts: apply_cash',
                               p_error_msg =>                 errbuff);
        END;

        errbuff := SUBSTR(l_receipt_creation_err,
                          1,
                          256);
    EXCEPTION
        WHEN OTHERS
        THEN
            errbuff :=
                   'Unexpected Error in XX_AR_SUBSCRIPTION_PKG.CREATE_RECEIPTS: '
                || DBMS_UTILITY.format_error_backtrace
                || SQLERRM;
            fnd_file.put_line(fnd_file.LOG,
                              errbuff);
            populate_error(p_contract_id =>               p_contract_id,
                           p_contract_number =>           l_contract_number,
                           p_contract_line_number =>      NULL,
                           p_billing_sequence =>          p_billing_sequence_number,
                           p_module =>                    'create_receipts',
                           p_error_msg =>                 errbuff);
    END create_receipts;

    PROCEDURE insert_ordt_details(
        errbuff                    OUT     VARCHAR2,
        retcode                    OUT     VARCHAR2,
        p_contract_number          IN      NUMBER,
        p_billing_sequence_number  IN      NUMBER,
        p_org_id_in                IN      NUMBER)
    IS
        CURSOR cur_ordt_update(
            p_org_id  IN  NUMBER)
        IS
            SELECT   NULL order_number,
                     NULL orig_sys_document_ref,
                     NULL orig_sys_payment_ref,
                     1 payment_number,   --for ordt, payment number 1
                     NULL header_id,
                     NULL order_source,
                     NULL order_type,
                     acr.cash_receipt_id,
                     xas.receipt_number,
                     xx_ar_subscriptions_pkg.get_customer(xas.initial_order_number,
                                                          'BILL_TO') customer_id,
                     xac.store_number store_num,   -- LPAD(aou.attribute1, 6, '0')
                     DECODE(xac.payment_type,
                            'CreditCard', 'CREDIT_CARD',
                            'PAYPAL', 'CASH',
                            'PLCC', 'CREDIT_CARD') payment_type_code,
                     --oep.payment_type_code ,
                     xac.card_type credit_card_code,
                     xas.settlement_card card_token,
                     xas.settlement_label card_encryption_label,
                     xac.card_holder_name AS credit_card_holder_name,   --  oep.credit_card_holder_name ,
                     xac.card_expiration_date AS credit_card_expiration_date,
                     SUM(xas.total_contract_amount) payment_amount,
                     NULL cc_auth_manual,
                     NULL merchant_number,
                     NULL cc_auth_ps2000,
                     NULL allied_ind,
                     NULL payment_set_id,
                     xas.settlement_cc_mask cc_mask_number,
                     NULL od_payment_type,
                     NULL check_number,
                     p_org_id_in org_id,
                     NULL imp_file_name,
                     xas.auth_code credit_card_approval_code,
                     TO_DATE(SUBSTR(xas.auth_datetime,
                                    1,
                                    (  INSTR(xas.auth_datetime,
                                             'T')
                                     - 1) ),
                             'YYYY-MM-DD') credit_card_approval_date,
                     NULL additional_auth_codes,

                     --xac.card_encryption_label IDENTIFIER ,
                     'N' emv_card,
                     NULL emv_terminal,
                     'N' emv_transaction,
                     'N' emv_offline,
                     'N' emv_fallback,
                     NULL emv_tvr,
                     DECODE(xac.payment_type,
                            'MasterPass', 'P',
                            NULL) wallet_type,   --decode - if masteropass it is P else null
                     xac.payment_identifier wallet_id,
                     acr.receipt_method_id,
                     'SERVICE-CONTRACTS' process_code,
                     xas.program_id request_id,
                     xas.creation_date,
                     xas.created_by,
                     xas.last_update_date,
                     xas.last_updated_by,
                     DECODE(UPPER(xac.payment_type),
                            'PAYPAL', 'Y',
                            'N') remitted,
                     'N' MATCHED,
                     NULL ship_from,
                     'OPEN' receipt_status,
                     xas.invoice_number customer_receipt_reference,
                     xx_ar_subscriptions_pkg.get_customer_site(xas.initial_order_number,
                                                               'BILL_TO') customer_site_billto_id,
                     acr.receipt_date,
                     'SALE' sale_type,
                     xas.billing_date process_date,
                     xac.contract_number mpl_order_id,
                     'N' single_pay_ind,
                     NVL(xas.currency_code,
                         'USD') currency_code,
                     xas.last_update_login,
                     NULL cleared_date,
                     NULL settlement_error_message,
                     NULL original_cash_receipt_id,
                     decode(xac.payment_type, 'PLCC', 'N', 'PAYPAL', 'N', 'Y') token_flag,
                     xas.contract_id,
                     xas.billing_sequence_number
            FROM     xx_ar_subscriptions xas, xx_ar_contracts xac, ar_cash_receipts_all acr
            WHERE    1 = 1
            AND      acr.receipt_number = xas.receipt_number
            AND      xas.contract_id = xac.contract_id
            AND      xas.auth_completed_flag = 'Y'
            AND      xas.invoice_created_flag = 'Y'
            AND      xas.receipt_created_flag = 'Y'
            AND      xas.billing_sequence_number = p_billing_sequence_number
            AND      xas.contract_number = p_contract_number
            GROUP BY acr.cash_receipt_id,
                     xas.receipt_number,
                     xas.initial_order_number,
                     xac.store_number,   -- LPAD(aou.attribute1, 6, '0')
                     xac.card_type,
                     xas.settlement_card,
                     xas.settlement_label,
                     --xac.card_encryption_label,
                     --xac.card_token, --xac.clear_token credit_card_number, -- Need to validate
                     xac.card_holder_name,   --  oep.credit_card_holder_name ,
                     xac.card_expiration_date,
                     xas.settlement_cc_mask,
                     xas.auth_code,
                     xas.auth_datetime,
                     --xac.card_encryption_label,
                     xac.payment_type,
                     xac.payment_identifier,
                     acr.receipt_method_id,
                     xas.program_id,
                     xas.creation_date,
                     xas.created_by,
                     xas.last_update_date,
                     xas.last_updated_by,
                     xac.payment_type,
                     xas.invoice_number,
                     xas.initial_order_number,
                     acr.receipt_date,
                     xas.billing_date,
                     xac.contract_number,
                     xas.currency_code,
                     xas.last_update_login,
                     xas.contract_id,
                     xas.billing_sequence_number;

        ln_record_count           NUMBER                                          := 0;
        l_xx_ar_order_payment_id  xx_ar_order_receipt_dtl.order_payment_id%TYPE;
        l_card_type               VARCHAR2(20);
        lv_bin                    VARCHAR2(20);
    BEGIN
        FOR rec_ordt_update IN cur_ordt_update(p_org_id_in)
        LOOP
            IF rec_ordt_update.credit_card_code = 'PLCC'
            THEN
                --Assuming cc_mask_number at this stage is always have a value,
                --as we are validating decrypt failues in AUTH and RE-AUTH procs
                lv_bin := SUBSTR(rec_ordt_update.cc_mask_number,
                                 1,
                                 6);
                --calling  get_plcc_cc_type procedure to fetch PLCC card type
                get_plcc_cc_type(errbuff,
                                 retcode,
                                 lv_bin,
                                 l_card_type);
            ELSE
                l_card_type := rec_ordt_update.credit_card_code;
            END IF;

            l_xx_ar_order_payment_id := xx_ar_order_payment_id_s.NEXTVAL;

            INSERT INTO xx_ar_order_receipt_dtl
            VALUES      (l_xx_ar_order_payment_id,
                         rec_ordt_update.order_number,
                         rec_ordt_update.orig_sys_document_ref,
                         rec_ordt_update.orig_sys_payment_ref,
                         rec_ordt_update.payment_number,
                         rec_ordt_update.header_id,
                         rec_ordt_update.order_source,
                         rec_ordt_update.order_type,
                         rec_ordt_update.cash_receipt_id,
                         rec_ordt_update.receipt_number,
                         rec_ordt_update.customer_id,
                         rec_ordt_update.store_num,
                         rec_ordt_update.payment_type_code,
                         l_card_type,   --rec_ordt_update.credit_card_code,
                         rec_ordt_update.card_token,   --x_cc_number_encrypted, --rec_ordt_update.credit_card_number ,
                         rec_ordt_update.credit_card_holder_name,
                         rec_ordt_update.credit_card_expiration_date,
                         rec_ordt_update.payment_amount,
                         rec_ordt_update.receipt_method_id,
                         rec_ordt_update.cc_auth_manual,
                         rec_ordt_update.merchant_number,
                         rec_ordt_update.cc_auth_ps2000,
                         rec_ordt_update.allied_ind,
                         rec_ordt_update.payment_set_id,
                         rec_ordt_update.process_code,
                         rec_ordt_update.cc_mask_number,
                         rec_ordt_update.od_payment_type,
                         rec_ordt_update.check_number,
                         rec_ordt_update.org_id,
                         rec_ordt_update.request_id,
                         rec_ordt_update.imp_file_name,
                         SYSDATE,   --rec_ordt_update.creation_date,
                         rec_ordt_update.created_by,
                         SYSDATE,   --rec_ordt_update.last_update_date,
                         rec_ordt_update.last_updated_by,
                         rec_ordt_update.remitted,
                         rec_ordt_update.MATCHED,
                         rec_ordt_update.ship_from,
                         rec_ordt_update.receipt_status,
                         rec_ordt_update.customer_receipt_reference,
                         rec_ordt_update.credit_card_approval_code,
                         rec_ordt_update.credit_card_approval_date,
                         rec_ordt_update.customer_site_billto_id,
                         rec_ordt_update.receipt_date,
                         rec_ordt_update.sale_type,
                         rec_ordt_update.additional_auth_codes,
                         rec_ordt_update.process_date,
                         rec_ordt_update.single_pay_ind,
                         rec_ordt_update.currency_code,
                         rec_ordt_update.last_update_login,
                         rec_ordt_update.cleared_date,
                         rec_ordt_update.card_encryption_label,
                         rec_ordt_update.settlement_error_message,
                         rec_ordt_update.original_cash_receipt_id,
                         rec_ordt_update.mpl_order_id,
                         NVL(LTRIM(RTRIM(rec_ordt_update.token_flag) ),
                             'N'),
                         NVL(LTRIM(RTRIM(rec_ordt_update.emv_card) ),
                             'N'),
                         LTRIM(RTRIM(rec_ordt_update.emv_terminal) ),
                         NVL(LTRIM(RTRIM(rec_ordt_update.emv_transaction) ),
                             'N'),
                         NVL(LTRIM(RTRIM(rec_ordt_update.emv_offline) ),
                             'N'),
                         NVL(LTRIM(RTRIM(rec_ordt_update.emv_fallback) ),
                             'N'),
                         LTRIM(RTRIM(rec_ordt_update.emv_tvr) ),
                         LTRIM(RTRIM(rec_ordt_update.wallet_type) ),
                         LTRIM(RTRIM(rec_ordt_update.wallet_id) ) );

            ln_record_count :=   ln_record_count
                               + 1;

            IF (SQL%ROWCOUNT > 0)
            THEN
                UPDATE xx_ar_subscriptions
                SET ordt_staged_flag = 'Y',
                    order_payment_id = l_xx_ar_order_payment_id,
                    last_update_date = SYSDATE
                WHERE  contract_id = rec_ordt_update.contract_id
                AND    billing_sequence_number = rec_ordt_update.billing_sequence_number;
            ELSE
                UPDATE xx_ar_subscriptions
                SET ordt_staged_flag = 'E',
                    ordt_staging_error = 'Error While inserting record into ORDT table',
                    last_update_date = SYSDATE
                WHERE  contract_id = rec_ordt_update.contract_id
                AND    billing_sequence_number = rec_ordt_update.billing_sequence_number;
            END IF;

            COMMIT;
        END LOOP;

        fnd_file.put_line(fnd_file.LOG,
                             'Number of records populated in order receipt detail is: '
                          || ln_record_count);
    EXCEPTION
        WHEN OTHERS
        THEN
            errbuff :=    'Unhandled exception raised while populating table: xx_ar_order_receipt_dtl - '
                       || SQLERRM;
            fnd_file.put_line(fnd_file.LOG,
                              errbuff);
    END insert_ordt_details;

    /*==========================================================================
    Name:           get_customer
    Description:    Fetching customer_id from ORIG_SYSTEM_BILL_CUSTOMER_REF
    ===========================================================================*/
    FUNCTION get_customer(
        p_order_number  VARCHAR2,
        p_site_usage    VARCHAR2)
        RETURN NUMBER
    IS
        ln_customer_id  NUMBER := NULL;
    BEGIN
        SELECT sold_to_org_id
        INTO   ln_customer_id
        FROM   oe_order_headers_all
        WHERE  order_number = p_order_number;

        --ln_customer_id := 19669;
        /*SELECT owner_table_id
        INTO ln_customer_id
        FROM hz_orig_sys_references
        WHERE orig_system         ='A0'
        AND orig_system_reference = p_bill_to_osr
        AND owner_table_name      ='HZ_CUST_ACCOUNTS'
        AND status                ='A';*/
        RETURN(ln_customer_id);
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'No customer information available for the account reference: '
                              || p_order_number);
            ln_customer_id := NULL;
            RETURN(ln_customer_id);
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Unhandled Exception raised while calling get_customer: '
                              || p_order_number
                              || ' - '
                              || SQLERRM);
            ln_customer_id := NULL;
            RETURN(ln_customer_id);
    END get_customer;

    /*==========================================================================
    Name:           get_customer_site
    Description:    Fetching customer_site_id from ORIG_SYSTEM_BILL_CUSTOMER_REF
    ===========================================================================*/
    FUNCTION get_customer_site(
        p_order_number  VARCHAR2,
        p_site_usage    VARCHAR2)
        RETURN NUMBER
    IS
        ln_cust_site_id  NUMBER := NULL;
    BEGIN
        IF p_site_usage = 'BILL_TO'
        THEN
            SELECT cs.cust_acct_site_id
            INTO   ln_cust_site_id
            FROM   hz_cust_accounts hca, hz_cust_acct_sites_all cs, hz_cust_site_uses_all su, oe_order_headers_all ooh
            WHERE  hca.cust_account_id = cs.cust_account_id
            AND    cs.cust_acct_site_id = su.cust_acct_site_id
            AND    su.site_use_code = 'BILL_TO'
            AND    su.status = 'A'
            AND    cs.status = 'A'
            AND    su.site_use_id = ooh.invoice_to_org_id
            AND    ooh.order_number = p_order_number;
        ELSE
            SELECT cs.cust_acct_site_id
            INTO   ln_cust_site_id
            FROM   hz_cust_accounts hca, hz_cust_acct_sites_all cs, hz_cust_site_uses_all su, oe_order_headers_all ooh
            WHERE  hca.cust_account_id = cs.cust_account_id
            AND    cs.cust_acct_site_id = su.cust_acct_site_id
            AND    su.site_use_code = 'SHIP_TO'
            AND    su.status = 'A'
            AND    cs.status = 'A'
            AND    su.site_use_id = ooh.ship_to_org_id
            AND    ooh.order_number = p_order_number;
        END IF;

            --ln_cust_site_id := 87507;
        /*SELECT owner_table_id
        INTO ln_cust_site_id
        FROM hz_orig_sys_references
        WHERE orig_system         ='A0'
        AND orig_system_reference = p_bill_to_osr
        AND owner_table_name      ='HZ_CUST_ACCT_SITES_ALL'
        AND status                ='A';*/
        RETURN(ln_cust_site_id);
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'No customer site information available for the account reference: '
                              || p_order_number);
            ln_cust_site_id := NULL;
            RETURN(ln_cust_site_id);
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Unhandled Exception raised while calling get_customer_id: '
                              || p_order_number
                              || ' - '
                              || SQLERRM);
            ln_cust_site_id := NULL;
            RETURN(ln_cust_site_id);
    END get_customer_site;

    PROCEDURE process_subscription(
        errbuff         OUT     VARCHAR2,
        retcode         OUT     VARCHAR2,
        p_contract_num  IN      VARCHAR2)
    IS
        CURSOR cur_invoices
        IS
            SELECT   xas.contract_id,
                     xas.contract_number,
                     xas.contract_name,
                     xas.invoice_number,
                     xas.billing_sequence_number,
                     SUM(xas.total_contract_amount) billing_amount,
                     xac.bill_to_osr account_orig_system_reference,
                     xac.initial_order_number,
                     xas.contract_line_number,
                     xx_ar_subscriptions_pkg.get_customer(xac.initial_order_number,
                                                          'BILL_TO') cust_account_id,
                     (SELECT account_number
                      FROM   hz_cust_accounts_all
                      WHERE  cust_account_id = xx_ar_subscriptions_pkg.get_customer(xac.initial_order_number,
                                                                                    'BILL_TO') ) customer_number
            FROM     xx_ar_subscriptions xas, xx_ar_contract_lines xacl, xx_ar_contracts xac
            WHERE    1 = 1
            AND      xas.contract_id = xacl.contract_id
            AND      xacl.contract_line_number = xas.contract_line_number
            AND      xas.contract_id = xac.contract_id
            AND      xas.contract_number = NVL(p_contract_num,
                                               xas.contract_number)
            AND      ((xas.auth_completed_flag = 'N' AND xas.invoice_created_flag = 'N')
            OR        (xas.auth_completed_flag = 'U' AND xas.invoice_created_flag = 'Y'))
            AND      xas.billing_sequence_number > 1
            GROUP BY xas.contract_id,
                     xas.contract_number,
                     xas.invoice_number,
                     xas.billing_sequence_number,
                     xas.contract_name,
                     xac.bill_to_osr,
                     xac.bill_to_cust_account_number,
                     xac.initial_order_number,
                     xas.contract_line_number;

        -- Start variable declaration by JAI_CG
        lv_receipt_method         xx_fin_translatevalues.target_value1%TYPE;
        ln_receipt_id             ar_cash_receipts_all.cash_receipt_id%TYPE;
        ln_rcpt_number            ar_cash_receipts_all.receipt_number%TYPE;
        ln_cust_account_num       hz_cust_accounts_all.account_number%TYPE;
        lv_trx_number             ra_customer_trx_all.trx_number%TYPE;
        lv_cust_trx_id            ra_customer_trx_all.customer_trx_id%TYPE;
        lv_auth_service_url       xx_fin_translatevalues.target_value1%TYPE   := NULL;
        lv_wallet_location        xx_fin_translatevalues.target_value1%TYPE   := NULL;
        lv_password               xx_fin_translatevalues.target_value2%TYPE   := NULL;
        lv_request_id_num         NUMBER                                      := 0;
        lv_invoice_created_flg    VARCHAR2(1)                                 := NULL;
        lv_rcpt_created_flg       VARCHAR2(1)                                 := NULL;
        l_trx_type                VARCHAR2(60)                                := NULL;
        l_trx_source              VARCHAR2(60)                                := NULL;
        l_memo_line               VARCHAR2(60)                                := NULL;
        l_auth_code               VARCHAR2(256)                               := NULL;
        l_auth_message            VARCHAR2(256)                               := NULL;
        l_receipt_error           VARCHAR2(256)                               := NULL;
        l_auth_error              VARCHAR2(256)                               := NULL;
        lc_rec_bill_flag          VARCHAR2(1)                                 := NULL;
        l_loader_success          VARCHAR2(1)                                 := 'Y';
        ln_trx_number             ra_customer_trx_all.trx_number%TYPE         := NULL;
        ln_temp_trx_number        ra_customer_trx_all.trx_number%TYPE         := NULL;
        l_invoice_amount          NUMBER;
        lv_invoice_interfaced_flg VARCHAR2(1)                                 := NULL;
    -- End variable declaration by JAI_CG
    BEGIN
        fnd_file.put_line(fnd_file.LOG,
                          '***************************************');   -- Added by JAI_CG
        fnd_file.put_line(fnd_file.LOG,
                          'Starting process_subscription routine. ');
        fnd_file.put_line(fnd_file.LOG,
                          '***************************************');

        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
        THEN
            fnd_log.STRING(fnd_log.level_statement,
                           'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                           'Starting process_subscription routine.');
        END IF;

        -- Start setting policy context by JAI_CG
        mo_global.set_policy_context('S',
                                     fnd_profile.VALUE('org_id') );

        -- Start fetching receipt method by JAI_CG
        BEGIN
            SELECT vals.target_value1
            INTO   lv_receipt_method
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 LIKE 'RECEIPT_METHOD';

            fnd_file.put_line(fnd_file.LOG,
                                 'Receipt method fetched is: '
                              || lv_receipt_method);

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
                fnd_log.STRING(fnd_log.level_statement,
                               'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                                  'Receipt method fetched is: '
                               || lv_receipt_method);
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                errbuff := 'Translation values not defined for receipt method. ';
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                                      'Translation values not defined for receipt method: '
                                   || lv_receipt_method);
                END IF;
            WHEN OTHERS
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Exception raised while fetching the receipt method: '
                                  || SQLCODE
                                  || ' : '
                                  || SQLERRM);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                                      'Exception raised while fetching the receipt method: '
                                   || SQLCODE
                                   || ' : '
                                   || SQLERRM);
                END IF;
        END;

        -- End fetching receipt method by JAI_CG
        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
        THEN
            fnd_log.STRING(fnd_log.level_statement,
                           'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                           'After populate_interface and before process_invoices');
        END IF;

        BEGIN
            SELECT target_value1
            INTO   lv_auth_service_url
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 = 'AUTH_SERVICE';
        EXCEPTION
            WHEN OTHERS
            THEN
                retcode := 2;
                errbuff := 'Error in getting AUTH_SERVICE Service URL from Translation';
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                RETURN;
        END;

        fnd_file.put_line(fnd_file.LOG,
                             '--AUTH_SERVICE_URL: '
                          || lv_auth_service_url);

        BEGIN
            SELECT target_value1,
                   target_value2
            INTO   lv_wallet_location,
                   lv_password
            FROM   xx_fin_translatevalues val, xx_fin_translatedefinition def
            WHERE  1 = 1
            AND    def.translate_id = val.translate_id
            AND    def.translation_name = 'XX_FIN_IREC_TOKEN_PARAMS'
            AND    val.source_value1 = 'WALLET_LOCATION'
            AND    val.enabled_flag = 'Y'
            AND    SYSDATE BETWEEN val.start_date_active AND NVL(val.end_date_active,
                                                                   SYSDATE
                                                                 + 1);
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_wallet_location := NULL;
                lv_password := NULL;
                retcode := 2;
                errbuff :=    errbuff
                           || ' - '
                           || 'Error in getting Wallet Location from Translation';
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                RETURN;
        END;

        pre_validate_service (    errbuff =>      errbuff,
                                retcode =>      retcode,
                                p_auth_url =>    lv_auth_service_url,
                                p_wallet_loc =>    lv_wallet_location);

        IF (retcode = 2) THEN
          RETURN;
        END IF;

        -- Start Auto Invoice
        process_invoices(errbuff =>      errbuff,
                         retcode =>      retcode
                                                --, p_trans_type => l_trx_type --'OMX INV_OD'
                                                --, p_trans_source => l_trx_source  --'CONVERSION_OD'
                        );

        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
        THEN
            fnd_log.STRING(fnd_log.level_statement,
                           'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                           'After process_invoices');
        END IF;

        FOR i IN cur_invoices
        LOOP
            -- Start fetching transaction number by JAI_CG
            lv_invoice_created_flg := NULL;
            lv_trx_number := NULL;
            lv_invoice_interfaced_flg := NULL;

            BEGIN
                SELECT rct.trx_number,
                       rct.customer_trx_id
                INTO   lv_trx_number,
                       lv_cust_trx_id
                FROM   ra_customer_trx_all rct
                WHERE  rct.org_id = fnd_profile.VALUE('org_id')
                AND    rct.trx_number = i.invoice_number;

                lv_invoice_created_flg := 'Y';
                lv_invoice_interfaced_flg := 'Y';
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'No data found while fetching invoice number: '
                                      || DBMS_UTILITY.format_error_backtrace
                                      || SQLERRM);
                    lv_invoice_created_flg := 'N';
                    lv_invoice_interfaced_flg := 'E';
                    lv_trx_number := NULL;
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'Exception raised while fetching invoice number: '
                                      || DBMS_UTILITY.format_error_backtrace
                                      || SQLERRM);
                    lv_invoice_created_flg := 'N';
                    lv_invoice_interfaced_flg := 'E';
                    lv_trx_number := NULL;
            END;

            -- End fetching transaction number by JAI_CG
            fnd_file.put_line(fnd_file.LOG,
                                 'Invoice_Created_Flg: '
                              || lv_invoice_created_flg);
            lv_rcpt_created_flg := NULL;
            ln_rcpt_number := NULL;

            IF NVL(lv_invoice_created_flg,
                   'N') = 'Y'
            THEN
                --Call EAI for AUTH
                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                                   'Before process_authorization');
                END IF;

                process_authorization(errbuff =>                        errbuff,
                                      retcode =>                        retcode,
                                      p_response_code =>                l_auth_code,
                                      p_auth_message =>                 l_auth_message,
                                      p_contract_id =>                  i.contract_id,
                                      p_billing_sequence_number =>      i.billing_sequence_number);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                THEN
                    fnd_log.STRING(fnd_log.level_statement,
                                   'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                                   'After process_authorization and before create_receipts');
                END IF;

                -- End Commenting AUTH segment by JAI_CG
                --IF NVL(l_auth_code, 0) = 200 AND
                IF l_auth_code = '0'
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'Launching create receipt for customer: '
                                      || i.customer_number
                                      || ' amount: '
                                      || i.billing_amount
                                      || ' trx id: '
                                      || lv_cust_trx_id);

                    IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                    THEN
                        fnd_log.STRING(fnd_log.level_statement,
                                       'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                                          'Launching create receipt for customer: '
                                       || i.customer_number
                                       || ' amount: '
                                       || i.billing_amount
                                       || ' trx id: '
                                       || lv_cust_trx_id);
                    END IF;

                    SELECT SUM(extended_amount)
                    INTO   l_invoice_amount
                    FROM   ra_customer_trx_lines_all
                    WHERE  customer_trx_id = lv_cust_trx_id
                    AND    org_id = fnd_profile.VALUE('org_id');

                    create_receipts
                        (errbuff =>                        l_receipt_error,
                         retcode =>                        retcode,
                         p_account_number =>               i.customer_number,
                         p_rcpt_method_name =>             lv_receipt_method   -- 'US_OM_CASH_000087'  --
                                                                            ,
                         p_receipt_amount =>               l_invoice_amount   --i.billing_amount -- Contract Line amount plus Tax amount
                                                                           ,
                         p_org_id =>                       fnd_profile.VALUE('org_id'),
                         p_cust_trx =>                     lv_cust_trx_id,
                         p_contract_id =>                  i.contract_id,
                         p_billing_sequence_number =>      i.billing_sequence_number,
                         x_receipt_id =>                   ln_receipt_id);

                    IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
                    THEN
                        fnd_log.STRING(fnd_log.level_statement,
                                       'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                                          'After create_receipts, ln_receipt_id: '
                                       || ln_receipt_id);
                    END IF;
                END IF;
            END IF;

            BEGIN
                fnd_file.put_line(fnd_file.LOG,
                                  'Updating xx_ar_subscriptions. ');

                UPDATE xx_ar_subscriptions xas
                SET xas.invoice_number = lv_trx_number,
                    xas.invoice_created_flag = lv_invoice_created_flg,
                    xas.invoice_interfaced_flag = lv_invoice_interfaced_flg
                WHERE  1 = 1   --xas.program_id            = lv_request_id_num
                AND    xas.contract_id = i.contract_id
                AND    xas.billing_sequence_number = i.billing_sequence_number
                AND    NVL(invoice_interfaced_flag,
                           'N') = 'Y';
            EXCEPTION
                WHEN OTHERS
                THEN
                    errbuff :=
                           'Exception raised while updating xx_ar_subscriptions: '
                        || DBMS_UTILITY.format_error_backtrace
                        || SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                      errbuff);
                    populate_error(p_contract_id =>               i.contract_id,
                                   p_contract_number =>           i.contract_number,
                                   p_contract_line_number =>      i.contract_line_number,
                                   p_billing_sequence =>          i.billing_sequence_number,
                                   p_module =>                    'process_subscriptions',
                                   p_error_msg =>                 errbuff);
            END;

            -- End Updating Staging Flag by JAI_CG
            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
                fnd_log.STRING(fnd_log.level_statement,
                               'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                               'Before insert_ordt_details');
            END IF;

            -- Start populating Order Receipt Table by JAI_CG
            insert_ordt_details(errbuff =>                        errbuff,
                                retcode =>                        retcode,
                                p_contract_number =>              i.contract_number,
                                p_billing_sequence_number =>      i.billing_sequence_number,
                                p_org_id_in =>                    fnd_profile.VALUE('org_id') );

            IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level)
            THEN
                fnd_log.STRING(fnd_log.level_statement,
                               'XX_AR_SUBSCRIPTIONS_PKG.process_subscription',
                               'After insert_ordt_details');
            END IF;
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            errbuff :=
                   'Unexpected Error in XX_AR_SUBSCRIPTION_PKG.process_subscription: '
                || DBMS_UTILITY.format_error_backtrace
                || SQLERRM;
            fnd_file.put_line(fnd_file.LOG,
                              errbuff);
    END process_subscription;
END xx_ar_subscriptions_pkg;
/
