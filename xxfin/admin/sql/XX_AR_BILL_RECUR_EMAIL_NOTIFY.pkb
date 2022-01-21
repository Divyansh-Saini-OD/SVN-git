create or replace PACKAGE BODY XX_AR_BILL_RECUR_EMAIL_NOTIFY
AS
  -- +====================================================================+
  -- |  Office Depot                                                      |
  -- +====================================================================+
  -- |  Name:  XX_AR_BILL_RECUR_HIST_NOTIFY                               |
  -- |                                                                    |
  -- |  Description:  This package body is for billing email notification |
  -- |                                                                    |
  -- |  Change Record:                                                    |
  -- +====================================================================+
  -- | Version     Date         Author              Remarks               |
  -- | =========   ===========  =============       ======================|
  -- | 1.0         28-FEB-2018  Sahithi Kunuru      Initial version       |
  -- | 1.1         03-MAR-2018  Sreedhar Mohan      Added Payload         |
  -- +====================================================================+
                                                                          
 PROCEDURE email_notify(errbuff OUT VARCHAR2
                       ,retcode OUT VARCHAR2)
 IS

      l_req_payload varchar2(10000);

      request UTL_HTTP.REQ;
      response UTL_HTTP.RESP;
      n NUMBER;
      buff VARCHAR2(10000);
      clob_buff CLOB;

      l_wallet_location     VARCHAR2(256)   := NULL;
      l_password            VARCHAR2(256)   := NULL;
      l_url                 VARCHAR2(4000);
      l_input_payload       varchar2(32000);

      BILL_NOTIFY_SERVICE_URL varchar2(1000) := null;

      l_username   varchar2(60);
      l_subscription_password varchar2(60);
      l_subscription_id number;
      l_tax_line_amount varchar2(15);

      l_cc_decrypted         VARCHAR2(256) := null;
      l_cc_decrypt_error     VARCHAR2(256) := null;
      l_last4                VARCHAR2(30) := null;
      l_email_failed_counter NUMBER := 0;
      l_email_sent_counter   NUMBER := 0;
      l_invoice_status       VARCHAR2(30) := null;
      l_payload_id           NUMBER := 0;
      
      l_failure_message      VARCHAR2(256) := null;

      cursor c1 is
      SELECT
        sum(xas.contract_line_amount) sub_total ,
        to_char(xas.billing_date,'dd-MON-yyyy hh24:mi:ss') billing_date ,
        xas.contract_id ,
        xas.contract_number ,
        xas.contract_name ,
        xas.payment_terms ,
        SUM(nvl(xas.tax_amount, 0)) tax_amount ,
        xac.bill_to_osr account_orig_system_reference ,
        xac.initial_order_number,
        xas.billing_sequence_number,
        xac.contract_major_version,
        xas.invoice_number,
        xas.receipt_number,
        xac.bill_to_customer_name,
        xac.bill_to_cust_account_number,
        xac.bill_to_osr,
        xac.loyalty_member_number,
        xac.customer_email,
        to_char(xas.next_billing_date,'dd-MON-yyyy hh24:mi:ss') next_billing_date,
        to_char(xas.service_period_start_date,'dd-MON-yyyy hh24:mi:ss') service_period_start_date,
        to_char(xas.service_period_end_date,'dd-MON-yyyy hh24:mi:ss') service_period_end_date,
        xac.payment_type,
        xac.payment_identifier,
        xac.card_type,
        xac.card_token,
        xac.card_encryption_label,
        to_char(xac.card_expiration_date,'dd-MON-yyyy hh24:mi:ss') card_expiration_date,
        xas.SETTLEMENT_CC_MASK,
        xas.auth_completed_flag,
        xas.authorization_error
      FROM xx_ar_subscriptions xas ,
        xx_ar_contracts xac
      WHERE 1=1
      AND xas.contract_id                   = xac.contract_id
      AND auth_completed_flag               IN ('Y', 'E')
      AND email_sent_flag                   IN ('N', 'E')
      and billing_sequence_number           > 1 -- Review this
      group by
        xas.billing_date ,
        xas.contract_id ,
        xas.contract_number ,
        xas.contract_name ,
        xas.payment_terms ,
        xac.bill_to_osr  ,
        xac.initial_order_number,
        xas.billing_sequence_number,
        xac.contract_major_version,
        xas.invoice_number,
        xas.receipt_number,
        xac.bill_to_customer_name,
        xac.bill_to_cust_account_number,
        xac.bill_to_osr,
        xac.loyalty_member_number,
        xac.customer_email,
        xas.next_billing_date,
        xas.service_period_start_date,
        xas.service_period_end_date,
        xac.payment_type,
        xac.payment_identifier,
        xac.card_type,
        xac.card_token,
        xac.card_encryption_label,
        xac.card_expiration_date,
        xas.SETTLEMENT_CC_MASK,
        xas.auth_completed_flag,
        xas.authorization_error
      ;


 BEGIN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'xx_ar_bill_recur_email_notify.email_notify start');
  BEGIN
		SELECT
           TARGET_VALUE1
          ,TARGET_VALUE2
        INTO
          l_wallet_location
         ,l_password
        FROM xx_fin_translatevalues vals
              ,xx_fin_translatedefinition defn
        WHERE 1=1
        AND   defn.TRANSLATE_ID = vals.TRANSLATE_ID
        AND   defn.TRANSLATION_NAME='XX_FIN_IREC_TOKEN_PARAMS'
        AND SOURCE_VALUE1 = 'WALLET_LOCATION'
        AND vals.enabled_flag    = 'Y'
        AND defn.enabled_flag    = 'Y'
		    AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE+1)
		    AND SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE+1);

      EXCEPTION
        WHEN OTHERS THEN
        l_wallet_location := NULL;
        l_password := NULL;
        RETCODE:=2;
        errbuff:='Error in getting Wallet Location from Translation';
        fnd_file.put_line (fnd_file.LOG,errbuff);
        RETURN;
      END;

      --FND_FILE.PUT_LINE(FND_FILE.LOG,'--l_wallet_location: ' || l_wallet_location || 'l_password :' || l_password);

      BEGIN
        SELECT  target_value1, target_value2, target_value3
          INTO  bill_notify_service_url, l_username,l_subscription_password
          FROM  xx_fin_translatevalues vals
              ,xx_fin_translatedefinition defn
         WHERE 1=1
           AND DEFN.TRANSLATE_ID=vals.TRANSLATE_ID
           AND DEFN.TRANSLATION_NAME = 'XX_AR_SUBSCRIPTIONS'
           AND SOURCE_VALUE1 = 'BILL_EMAIL_SERVICE'
           AND vals.enabled_flag    = 'Y'
		   AND defn.enabled_flag    = 'Y'
		   AND SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE+1)
		   AND SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE+1);
      EXCEPTION WHEN OTHERS THEN
        RETCODE:=2;
        errbuff:='username and pwd for BILL_EMAIL_SERVICE not found';
        fnd_file.put_line (fnd_file.LOG,errbuff);
        RETURN;
      END;

	   -- Checking if Service is up.
        xx_ar_subscriptions_pkg.pre_validate_service (
                                errbuff         =>    errbuff,
                                retcode         =>    retcode,
                                p_auth_url      =>    bill_notify_service_url,
                                p_wallet_loc    =>    l_wallet_location);
        IF (retcode = 2) THEN
            RETURN;
        END IF;

      FOR i_rec IN C1

      LOOP
        l_last4 := null;
        IF i_rec.card_type <> 'PAYPAL' THEN        
          IF i_rec.SETTLEMENT_CC_MASK IS NOT NULL THEN
            l_last4 := 'xxxxxx' || lpad(substr(i_rec.SETTLEMENT_CC_MASK,-4),10,'x');
          ELSE
            l_last4 := 'BAD CARD';
          END IF;
        END IF;
        
        IF i_rec.auth_completed_flag = 'E' THEN
          l_invoice_status := 'FAILED'; 
          l_failure_message := i_rec.authorization_error;
        ELSE
          l_invoice_status := 'SUCCESS';
          l_failure_message := null;
        END IF;        
        --FND_FILE.PUT_LINE(FND_FILE.LOG, 'l_last4: ' || l_last4);

        l_req_payload := '{
          "billingStatusEmailRequest": {
              "transactionHeader": {
                  "consumer": {
                      "consumerName": "' || i_rec.bill_to_customer_name || '"
                  },
                  "transactionId": "' || i_rec.contract_number || '-' || i_rec.initial_order_number || '-' || i_rec.billing_sequence_number || '",
                  "timeReceived": null
              },
              "customer": {
                  "firstName": "' || i_rec.bill_to_customer_name || '",
                  "middleName": null,
                  "lastName": "",
                  "accountNumber": "' || i_rec.bill_to_osr || '",
                  "loyaltyNumber": "' || i_rec.loyalty_member_number || '",
                  "contact": {
                      "email": "' || i_rec.customer_email || '",
                      "phoneNumber": "",
                      "faxNumber": ""
                  }
              },
              "invoice": {
                  "invoiceNumber": "' || i_rec.invoice_number || '",
                  "orderNumber": "' || i_rec.initial_order_number || '",
                  "serviceContractNumber": "' || i_rec.contract_number || '",
                  "billingDate": "' || i_rec.billing_date || '",
                  "billingTime": "",
                  "invoiceDate": "' || i_rec.billing_date || '",
                  "invoiceTime": "",
                  "invoiceStatus": "' || l_invoice_status || '",
                  "FailureMessage": "' || l_failure_message || '",
                  "nextInvoiceDate": "' || i_rec.next_billing_date || '",
                  "servicePeriodStartDate": "' || i_rec.service_period_start_date || '",
                  "servicePeriodEndDate": "' || i_rec.service_period_end_date || '",
                  "totals": {
                      "subTotal": "' || to_char(i_rec.sub_total) || '",
                      "tax": "' || to_char(i_rec.tax_amount) || '",
                      "delivery": "String",
                      "discount": "String",
                      "misc": "String",
                      "total": "' || to_char(i_rec.sub_total)  || '"
                  },
                  "tenders": {
                      "tenderLineNumber": "1",
                      "paymentType": "' || i_rec.payment_type || '",
                      "cardType": "' || i_rec.card_type || '",
                      "amount": "' || to_char(i_rec.sub_total) || '",
                      "cardnumber": "' || l_last4 || '",
                      "expirationDate": "' || i_rec.card_expiration_date || '",
                      "walletId": "",
                      "billingAgreementId": "' || i_rec.payment_identifier || '"
                  }
              },
              "storeNumber": ""
          }
      }';

      FND_FILE.PUT_LINE(FND_FILE.LOG,'l_req_payload: ' || l_req_payload);
      --FND_FILE.PUT_LINE(FND_FILE.LOG,'l_username:'||l_username);
      --FND_FILE.PUT_LINE(FND_FILE.LOG,'l_subscription_password:'||l_subscription_password);

      IF l_wallet_location IS NOT NULL THEN
        UTL_HTTP.SET_WALLET(l_wallet_location,l_password);
      END IF;

      UTL_HTTP.SET_RESPONSE_ERROR_CHECK(FALSE);


      request := utl_http.begin_request(BILL_NOTIFY_SERVICE_URL, 'POST',' HTTP/1.1');
      utl_http.set_header(request, 'user-agent', 'mozilla/5.0');
      utl_http.set_header(request, 'content-type', 'application/json');
      utl_http.set_header(request, 'Content-Length', length(l_req_payload));

      --utl_http.set_header(request, 'Authorization', 'Basic U1ZDLUJJWkJPWFdTOnN2YzRiaXpib3h3cw==');
      utl_http.set_header(request, 'Authorization', 'Basic ' || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw(l_username||':'||l_subscription_password))));
      utl_http.write_text(request, l_req_payload);

      response := UTL_HTTP.GET_RESPONSE(request);

      commit;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'HTTP response status code: ' || response.status_code || ', contract_number: ' || i_rec.contract_number);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'HTTP response: ' || response.status_code || ', contract_number: ' || i_rec.contract_number);

      IF response.status_code = 200 THEN

        l_email_sent_counter := l_email_sent_counter + 1;

        update xx_ar_subscriptions
        set    email_sent_flag = 'Y',
	           email_sent_date = sysdate,
			   last_update_date = SYSDATE,
			   last_updated_by  = fnd_global.login_id
        where  contract_number = i_rec.contract_number
        and    billing_sequence_number = i_rec.billing_sequence_number;

        commit;

      ELSE

        l_email_failed_counter := l_email_failed_counter + 1;

        update xx_ar_subscriptions
        set    email_sent_flag = 'E',
  			   last_update_date = SYSDATE,
			   last_updated_by  = fnd_global.login_id
        where  contract_number = i_rec.contract_number
        and    billing_sequence_number = i_rec.billing_sequence_number;

        commit;

      END IF;

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
                       i_rec.contract_number,
                       i_rec.billing_sequence_number,
                       null,
                       'EMAIL SERVICE',
                       clob_buff,
                       SYSDATE,
                       fnd_global.user_id,
                       SYSDATE,
                       fnd_global.user_id,
                       l_req_payload
                       );

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

      END;

      UTL_HTTP.END_RESPONSE(response);

   END LOOP;

   FND_FILE.PUT_LINE(FND_FILE.LOG,'End executing EMAIL service');

   IF(l_email_failed_counter > 0) THEN
     errbuff := 'ERROR in executing EMAIL service. Email failed ' || l_email_failed_counter || ' times. Please check the log';
     FND_FILE.PUT_LINE(FND_FILE.LOG, errbuff);
     retcode := 1;
   ELSE
     retcode := 0;
   END IF;

   FND_FILE.PUT_LINE(FND_FILE.LOG,'EMAIL service executed successfully ' || l_email_sent_counter || ' times.');
   FND_FILE.PUT_LINE(FND_FILE.LOG,'EMAIL service failed ' || l_email_failed_counter || ' times.');

   EXCEPTION
        WHEN OTHERS THEN
          RETCODE:=2;
          errbuff:='UNEXPECTED ERROR in executing EMAIL service: ' || SQLERRM;
          fnd_file.put_line (fnd_file.LOG,errbuff);
          RETURN;
   END email_notify;

END XX_AR_BILL_RECUR_EMAIL_NOTIFY;
/
