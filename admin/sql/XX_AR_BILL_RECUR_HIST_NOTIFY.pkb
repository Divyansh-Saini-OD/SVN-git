CREATE OR REPLACE PACKAGE BODY xx_ar_bill_recur_hist_notify
AS
-- +==================================================================================================+
-- |  Office Depot                                                                                    |
-- +==================================================================================================+
-- |  Name:  XX_AR_BILL_RECUR_HIST_NOTIFY                                                             |
-- |                                                                                                  |
-- |  Description:  This package body is for billing history notification                             |
-- |                                                                                                  |
-- |  Change Record:                                                                                  |
-- +==================================================================================================+
-- | Version     Date         Author              Remarks                                             |
-- | =========   ===========  =============       ====================================================|
-- | 1.0         28-FEB-2018  Sahithi Kunuru      Initial version                                     |
-- | 1.1         27-MAR-2018  Dinesh Nagapuri     Added Payload Structure to handle multiple lines    |
-- +==================================================================================================+
    PROCEDURE history_notify(
        errbuff  OUT  VARCHAR2,
        retcode  OUT  VARCHAR2)
    IS
        l_req_payload               VARCHAR2(10000);
        l_req_payload_hrd           VARCHAR2(10000);
        l_req_payload_lines         VARCHAR2(10000);
        l_req_payload_det           VARCHAR2(10000);
        request                     UTL_HTTP.req;
        response                    UTL_HTTP.resp;
        n                           NUMBER;
        buff                        VARCHAR2(10000);
        clob_buff                   CLOB;
        l_url                       VARCHAR2(4000);
        l_input_payload             VARCHAR2(32000);
        l_username                  VARCHAR2(60);
        l_subscription_password     VARCHAR2(60);
        l_payload_id                NUMBER;
        l_tax_line_amount           VARCHAR2(15);
        l_item_unit_price           NUMBER;
        l_item_unit_total           NUMBER;
        lv_cust_address1            hz_locations.address1%TYPE                  := NULL;
        lv_cust_address2            hz_locations.address2%TYPE                  := NULL;
        lv_cust_city                hz_locations.city%TYPE                      := NULL;
        lv_cust_state               hz_locations.state%TYPE                     := NULL;
        lv_cust_postal_code         hz_locations.postal_code%TYPE               := NULL;
        lv_cust_country             hz_locations.country%TYPE                   := NULL;
        lv_email_address            hz_contact_points.email_address%TYPE        := NULL;
        l_db_link                   xx_fin_translatevalues.target_value1%TYPE   := NULL;
        lv_fax_number               VARCHAR2(30)                                := NULL;
        lv_phone_number             VARCHAR2(30)                                := NULL;
        l_invoice_date              VARCHAR2(30)                                := NULL;
        l_invoice_time              VARCHAR2(30)                                := NULL;
        l_wallet_location           VARCHAR2(256)                               := NULL;
        l_password                  VARCHAR2(256)                               := NULL;
        l_cc_decrypted              VARCHAR2(256)                               := NULL;
        l_cc_decrypt_error          VARCHAR2(256)                               := NULL;
        l_last4                     VARCHAR2(30)                                := NULL;
        l_item_cost_qry             VARCHAR2(240)                               := NULL;
        l_bill_history_service_url  VARCHAR2(1000)                              := NULL;
        gn_login_id                 NUMBER;
        l_total_amount              NUMBER;
        l_count                     NUMBER;

        CURSOR cur_bill_history
        IS
            SELECT   xac.bill_to_osr account_orig_system_reference,
                     xac.contract_id,
                     xac.initial_order_number,
                     xac.bill_to_customer_name,
                     xac.payment_type,
                     xac.payment_identifier,
                     xac.card_type,
                     xac.card_token,
                     xac.contract_number,
                     xac.card_encryption_label,
                     xac.contract_billing_freq,
                     xac.total_contract_amount,
                     TO_CHAR(xac.card_expiration_date,
                             'YYMM') card_expiration_date,
					TO_CHAR(xac.contract_start_date,
                             'YYYY-MM-DD') contract_start_date,
                     TO_CHAR(xac.contract_end_date,
                             'YYYY-MM-DD') contract_end_date,
                     xas.settlement_cc_mask,
                     xas.billing_sequence_number,
                     xas.invoice_number,
                     TO_CHAR(xas.billing_date,
                             'DD-MON-YYYY') billing_date,
                     TO_CHAR(xas.billing_date,
                             'HH24:MI:SS') billing_time,
                     NVL(xas.tax_amount,
                         0) tax_amount,
                     TO_CHAR(xas.service_period_start_date,
                             'dd-MON-yyyy hh24:mi:ss') service_period_start_date,
                     TO_CHAR(xas.service_period_end_date,
                             'dd-MON-yyyy hh24:mi:ss') service_period_end_date,
                     TO_CHAR(xas.next_billing_date,
                             'dd-MON-yyyy') next_billing_date,
                     COUNT(1) e_total
            FROM     xx_ar_contracts xac, xx_ar_subscriptions xas
            WHERE    1 = 1
            AND      xas.contract_id = xac.contract_id
            AND      xas.billing_sequence_number > 1
            AND      xas.auth_completed_flag = 'Y'
            AND      NVL(history_sent_flag,
                         'N') IN('N', 'E')
            GROUP BY xac.bill_to_osr,
                     xac.contract_id,
                     xac.initial_order_number,
                     xac.bill_to_customer_name,
                     xac.payment_type,
                     xac.payment_identifier,
                     xac.card_type,
                     xac.card_token,
                     xac.contract_number,
                     xac.card_encryption_label,
                     xac.contract_billing_freq,
                     xac.total_contract_amount,
                     card_expiration_date,
					 xac.contract_start_date,
					 xac.contract_end_date,
                     xas.settlement_cc_mask,
                     xas.billing_sequence_number,
                     xas.invoice_number,
                     billing_date,
                     TO_CHAR(xas.billing_date,
                             'HH24:MI:SS'),
                     tax_amount,
                     service_period_start_date,
                     service_period_end_date,
                     next_billing_date;

        CURSOR cur_bill_history_lines(
            p_contract_id              NUMBER,
            p_billing_sequence_number  NUMBER)
        IS
            SELECT   xacl.initial_order_line,
                     xacl.item_name,
                     xacl.item_description,
                     xacl.quantity,
                     xas.contract_line_amount sub_total,
                     xas.contract_id,
                     xacl.contract_line_number,
                     xas.total_contract_amount,
                     xas.uom_code,
                     xas.billing_sequence_number,
                     xas.invoice_number,
                     xas.receipt_number
            FROM     xx_ar_contract_lines xacl, xx_ar_subscriptions xas
            WHERE    1 = 1
            AND      xacl.contract_line_number = xas.contract_line_number
            AND      xas.contract_id = xacl.contract_id
            AND      xas.billing_sequence_number = p_billing_sequence_number
            AND      xas.contract_id = p_contract_id
            AND      xas.billing_sequence_number > 1
            AND      xas.auth_completed_flag = 'Y'
            AND      NVL(history_sent_flag,
                         'N') IN('N', 'E')
            ORDER BY xacl.contract_line_number;
    BEGIN
        fnd_file.put_line(fnd_file.LOG,
                          'xx_ar_bill_recur_hist_notify.history_notify starts --');
        gn_login_id := fnd_global.login_id;

        BEGIN
            SELECT target_value1,
                   target_value2
            INTO   l_wallet_location,
                   l_password
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_FIN_IREC_TOKEN_PARAMS'
            AND    vals.source_value1 = 'WALLET_LOCATION'
            AND    vals.enabled_flag = 'Y'
            AND    defn.enabled_flag = 'Y'
            AND    SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active,
                                                                    SYSDATE
                                                                  + 1)
            AND    SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active,
                                                                    SYSDATE
                                                                  + 1);
        EXCEPTION
            WHEN OTHERS
            THEN
                l_wallet_location := NULL;
                l_password := NULL;
                retcode := 2;
                errbuff := 'Error in getting Wallet Location from Translation';
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
        END;

        BEGIN
            SELECT target_value1,
                   target_value2,
                   target_value3
            INTO   l_bill_history_service_url,
                   l_username,
                   l_subscription_password
            FROM   xx_fin_translatevalues vals, xx_fin_translatedefinition defn
            WHERE  1 = 1
            AND    defn.translate_id = vals.translate_id
            AND    defn.translation_name = 'XX_AR_SUBSCRIPTIONS'
            AND    source_value1 = 'BILL_HISTORY_SERVICE'
            AND    vals.enabled_flag = 'Y'
            AND    defn.enabled_flag = 'Y'
            AND    SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active,
                                                                    SYSDATE
                                                                  + 1)
            AND    SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active,
                                                                    SYSDATE
                                                                  + 1);
        EXCEPTION
            WHEN OTHERS
            THEN
                l_username := NULL;
                l_subscription_password := NULL;
                retcode := 2;
                errbuff :=    'Error in getting user credentials: '
                           || SQLERRM;
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
        END;
        -- Checking if Service is up.
        xx_ar_subscriptions_pkg.pre_validate_service (
                                errbuff         =>    errbuff,
                                retcode         =>    retcode,
                                p_auth_url         =>    l_bill_history_service_url,
                                p_wallet_loc     =>    l_wallet_location);
        IF (retcode = 2) THEN
            RETURN;
        END IF;
        FOR rec_bill_history IN cur_bill_history
        LOOP
            l_item_unit_total := NULL;
            l_last4 := NULL;
            lv_cust_address1 := NULL;
            lv_cust_address2 := NULL;
            lv_cust_city := NULL;
            lv_cust_state := NULL;
            lv_cust_postal_code := NULL;
            lv_cust_country := NULL;
            lv_email_address := NULL;
            lv_fax_number := NULL;
            lv_phone_number := NULL;
            l_invoice_date := NULL;
            l_invoice_time := NULL;
            l_total_amount := 0;
			l_count        :=0;
            l_req_payload := NULL;
            l_req_payload_hrd := NULL;
            l_req_payload_lines := NULL;
            l_req_payload_det := NULL;

            BEGIN
                SELECT TO_CHAR(trx_date,
                               'DD-MON-YYYY') l_invoice_date,
                       TO_CHAR(trx_date,
                               'HH24:MI:SS') l_invoice_time
                INTO   l_invoice_date,
                       l_invoice_time
                FROM   ra_customer_trx_all
                WHERE  org_id = fnd_profile.VALUE('org_id')
                AND    trx_number = rec_bill_history.invoice_number;
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         'Exception raised while fetching Invoice Date - '
                                      || SQLERRM);
                    l_invoice_date := NULL;
                    l_invoice_time := NULL;
            END;

            BEGIN
                SELECT hl.address1,
                       hl.address2,
                       hl.city,
                       hl.state,
                       hl.postal_code,
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
                WHERE  hcs.cust_acct_site_id =
                             xx_ar_subscriptions_pkg.get_customer_site(rec_bill_history.initial_order_number,
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
                    lv_email_address := NULL;
                    lv_fax_number := NULL;
                    lv_phone_number := NULL;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Exception raised while fetching customer address for contract: '
                                      || rec_bill_history.contract_number
                                      || ' - '
                                      || SQLERRM);
            END;

            fnd_file.put_line(fnd_file.LOG,
                              '--Start getting Clear HVT--');
            fnd_file.put_line(fnd_file.LOG,
                                 'card_token: '
                              || rec_bill_history.card_token);
            fnd_file.put_line(fnd_file.LOG,
                                 'card_encryption_label: '
                              || rec_bill_history.card_encryption_label);
            l_last4 := LPAD(SUBSTR(rec_bill_history.settlement_cc_mask,
                                   -4),
                            10,
                            'x');
            l_req_payload_hrd :=
                   '{
                     "billingHistoryRequest": {
                     "transactionHeader": {
                         "consumerName": "'
                             || rec_bill_history.bill_to_customer_name
                             || '",
                         "consumerTransactionId":"'
                             || rec_bill_history.contract_number
                             || '-'
                             || rec_bill_history.initial_order_number
                             || '-'
                             || rec_bill_history.billing_sequence_number
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
                             || rec_bill_history.bill_to_customer_name
                             || '",
                         "middleName": "",
                         "lastName": "",
                         "accountNumber": "",
                         "loyaltyNumber": "",
                         "paymentDetails": {
                             "paymentType": "'
                             || rec_bill_history.payment_type
                             || '",
                             "paymentCard": {
                                 "billingAddress": {
                                     "name": "'
                             || rec_bill_history.bill_to_customer_name
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
                             "billingAgreementId": "",
                             "walletId": "'
                             || rec_bill_history.payment_identifier
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
                     "invoice": {
                         "invoiceNumber": "'
                             || rec_bill_history.invoice_number
                             || '",
                         "orderNumber":  "'
                             || rec_bill_history.initial_order_number
                             || '",
                         "serviceContractNumber": "'
                             || rec_bill_history.contract_number
                             || '",
                         "billingDate": "'
                             || rec_bill_history.billing_date
                             || '",
                         "billingTime": "'
                             || rec_bill_history.billing_time
                             || '",
                         "invoiceDate": "'
                             || l_invoice_date
                             || '",
                         "invoiceTime": "'
                             || l_invoice_time
                             || '",
                         "invoiceStatus": "OK",
                         "servicePeriodStartDate": "'
                             || rec_bill_history.service_period_start_date
                             || '",
                         "servicePeriodEndDate": "'
                             || rec_bill_history.service_period_end_date
                             || '",
                         "nextBillingDate": "'
                             || rec_bill_history.next_billing_date
                             || '"
                         ,"invoiceLines": {
		             	  "invoiceLine":
		             	  [
                           ';
            l_count := rec_bill_history.e_total;

            FOR rec_bill_history_lines IN cur_bill_history_lines(rec_bill_history.contract_id,
                                                                 rec_bill_history.billing_sequence_number)
            LOOP
                l_item_unit_total :=rec_bill_history_lines.total_contract_amount
                      * rec_bill_history_lines.quantity
                    + NVL(rec_bill_history.tax_amount,
                          0);
                l_req_payload_lines :=
                       l_req_payload_lines
                             || '{
                             "orderLineNumber": "'
                             || rec_bill_history_lines.initial_order_line
                             || '",
                             "contractLineNumber": "'
                             || rec_bill_history_lines.contract_line_number
                             || '",
                             "lineTypeName": "Subscription",
                             "itemName": "'
                             || rec_bill_history_lines.item_description
                             || '",
                             "itemNumber": "'
                             || rec_bill_history_lines.item_name
                             || '",
                             "contractStartDate": "'
                             || rec_bill_history.contract_start_date
                             || '",
                             "contractEndDate": "'
                             || rec_bill_history.contract_end_date
                             || '",
                             "unitOfMeasure": "'
                             || rec_bill_history_lines.uom_code
                             || '",
                             "quantity": "'
                             || rec_bill_history_lines.quantity
                             || '",
                             "billingFrequency": "'
                             || rec_bill_history.contract_billing_freq
                             || '",
                             "unitPrice": "'
                             || rec_bill_history_lines.sub_total
                             || '",
                             "tax": "'
                             || rec_bill_history.tax_amount
                             || '",
                             "unitTotal": "'
                             || l_item_unit_total
                             || '"
                }
            ';
                l_count :=   l_count
                           - 1;

                IF l_count >= 1
                THEN
                    l_req_payload_lines :=    l_req_payload_lines
                                           || ',';
                END IF;

                l_total_amount :=   l_total_amount
                                  + l_item_unit_total;
            END LOOP;

            l_req_payload_det :=
                                ']},
                             "tenders": {
                                 "cardType": "'
                             || rec_bill_history.card_type
                             || '",
                                 "amount": "'
                             || l_total_amount
                             || '",
                                 "cardnumber": "'
                             || l_last4
                             || '"
                }
            },
        "skipAuthorization": "true"
      }
   }';
            l_req_payload :=    l_req_payload_hrd
                             || ''
                             || l_req_payload_lines
                             || ''
                             || l_req_payload_det;
            fnd_file.put_line(fnd_file.LOG,
                                 'l_req_payload: '
                              || l_req_payload);

            IF l_wallet_location IS NOT NULL
            THEN
                UTL_HTTP.set_wallet(l_wallet_location,
                                    l_password);
            END IF;

            BEGIN
                UTL_HTTP.set_response_error_check(FALSE);
                request := UTL_HTTP.begin_request(l_bill_history_service_url,
                                                  'POST',
                                                  'HTTP/1.2');
                UTL_HTTP.set_header(request,
                                    'user-agent',
                                    'mozilla/5.0');
                UTL_HTTP.set_header(request,
                                    'content-type',
                                    'application/json');
                UTL_HTTP.set_header(request,
                                    'Content-Length',
                                    LENGTH(l_req_payload) );
                UTL_HTTP.set_header
                    (request,
                     'Authorization',
                        'Basic '
                     || UTL_RAW.cast_to_varchar2
                                               (UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(   l_username
                                                                                             || ':'
                                                                                             || l_subscription_password) ) ) );
                UTL_HTTP.write_text(request,
                                    l_req_payload);
                response := UTL_HTTP.get_response(request);
            EXCEPTION
                WHEN OTHERS
                THEN
                    errbuff :=    'Unexpected Error Raised during HTTP connection -SQLERRM: '
                               || SQLERRM;
                    fnd_file.put_line(fnd_file.LOG,
                                         'Unexpected Error Raised during HTTP connection -SQLERRM: '
                                      || SQLERRM);

                    UPDATE xx_ar_subscriptions
                    SET history_sent_flag = 'E',
                        last_update_date = SYSDATE,
                        last_updated_by = gn_login_id
                    WHERE  1 = 1
                    AND    contract_id = rec_bill_history.contract_id
                    AND    billing_sequence_number = rec_bill_history.billing_sequence_number;

                    COMMIT;
            END;

            fnd_file.put_line(fnd_file.LOG,
                                 'HTTP response status code: '
                              || response.status_code);

            IF response.status_code IN(200, 201)
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
                                             'buff: '
                                          || clob_buff);
                    END LOOP;

                    UTL_HTTP.end_response(response);
                EXCEPTION
                    WHEN UTL_HTTP.end_of_body
                    THEN
                        UTL_HTTP.end_response(response);
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line(fnd_file.LOG,
                                          SQLERRM);
                        fnd_file.put_line(fnd_file.LOG,
                                          DBMS_UTILITY.format_error_backtrace);
                        UTL_HTTP.end_response(response);
                END;

                UPDATE xx_ar_subscriptions
                SET history_sent_flag = 'Y',
                    history_sent_date = SYSDATE,
                    last_update_date = SYSDATE,
                    last_updated_by = gn_login_id
                WHERE  1 = 1
                AND    contract_id = rec_bill_history.contract_id
                AND    billing_sequence_number = rec_bill_history.billing_sequence_number;

                BEGIN
                    INSERT INTO xx_ar_subscription_payloads
                                (payload_id,
                                 SOURCE,
                                 contract_number,
                                 billing_sequence_number,
                                 response_data,
                                 creation_date,
                                 created_by,
                                 last_update_date,
                                 last_updated_by,
                                 input_payload)
                    VALUES      (l_payload_id,
                                 'BILLING HISTORY',
                                 rec_bill_history.contract_number,
                                 rec_bill_history.billing_sequence_number,
                                 clob_buff,
                                 SYSDATE,
                                 fnd_global.user_id,
                                 SYSDATE,
                                 fnd_global.user_id,
                                 l_req_payload);
                    l_req_payload := NULL;
                    fnd_file.put_line(fnd_file.LOG,
                                         'After inserting into XX_AR_SUBSCRIPTION_PAYLOADS: '
                                      || SQL%ROWCOUNT);
                    COMMIT;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        errbuff :=    'Exception in inserting into XX_AR_SUBSCRIPTION_PAYLOADS. '
                                   || SQLERRM;
                        fnd_file.put_line(fnd_file.LOG,
                                          errbuff);
                END;
            ELSE
                UPDATE xx_ar_subscriptions
                SET history_sent_flag = 'E',
                    last_update_date = SYSDATE,
                    last_updated_by = gn_login_id
                WHERE  1 = 1
                AND    contract_id = rec_bill_history.contract_id
                AND    billing_sequence_number = rec_bill_history.billing_sequence_number;

                errbuff :=
                           errbuff
                        || ' - '
                        || 'Billing History process fails with response code: '
                        || response.status_code;
                fnd_file.put_line(fnd_file.LOG,
                                  errbuff);
                UTL_HTTP.end_response(response);
                fnd_file.put_line(fnd_file.LOG,
                                  'ERROR');
                COMMIT;
            END IF;
        END LOOP;

        fnd_file.put_line(fnd_file.LOG,
                          '--Script end--');
    EXCEPTION
        WHEN OTHERS
        THEN
            errbuff :=    'Unhandled exception in history_notify: '
                       || SQLERRM;
            fnd_file.put_line(fnd_file.LOG,
                              errbuff);
    END history_notify;
END xx_ar_bill_recur_hist_notify;
/