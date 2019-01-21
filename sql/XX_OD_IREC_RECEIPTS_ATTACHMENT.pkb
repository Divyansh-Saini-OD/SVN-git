{\rtf1\ansi\ansicpg1252\deff0\deflang1033{\fonttbl{\f0\fswiss\fcharset0 Arial;}}
{\*\generator Msftedit 5.41.21.2500;}\viewkind4\uc1\pard\f0\fs20 create or replace\par
PACKAGE BODY XX_OD_IREC_RECEIPTS_ATTACHMENT AS\par
\par
PROCEDURE  attach_file(p_file_name IN varchar2,p_cash_receipt_id IN Number, p_return_status OUT varchar2)\par
     IS\par
  v_entity_name   VARCHAR2 (30) := 'AR_CASH_RECEIPTS';\par
  v_media_id      NUMBER  ;\par
  v_category_id   NUMBER;\par
  v_seq_num       NUMBER;\par
  v_datatype_id   NUMBER;\par
  p_entity_id     NUMBER        := p_cash_receipt_id;--45678320;\par
  p_document_desc VARCHAR2 (120) := 'TEST';\par
  --p_file_name     VARCHAR2 (100) := p_file_name;--'text.pdf';\par
  b_file BFILE;\par
  b_lob BLOB;\par
  --p_return_status varchar2(10) := 'FAIL';\par
BEGIN\par
  --FND_GLOBAL.APPS_INITIALIZE(1200246,50890,222);\par
  \par
  --DBMS_APPLICATION_INFO.set_client_info (404);\par
  SELECT FND_LOBS_S.NEXTVAL into v_media_id FROM dual;\par
      \par
     BEGIN \par
             SELECT category_id\par
              INTO v_category_id\par
              FROM fnd_document_categories_tl\par
              WHERE user_name = 'Miscellaneous';\par
              EXCEPTION\par
              WHEN OTHERS THEN\par
              DBMS_OUTPUT.put_line  (  '11'||  SQLERRM  )\par
              ;\par
     END;\par
     \par
     BEGIN\par
            SELECT datatype_id\par
            INTO v_datatype_id\par
            FROM fnd_document_datatypes\par
            WHERE NAME   = 'FILE'\par
            AND LANGUAGE = 'US';\par
            EXCEPTION\par
            WHEN OTHERS THEN\par
            DBMS_OUTPUT.put_line  (  '12'||  SQLERRM  )\par
            ;\par
     END;\par
     \par
     BEGIN\par
            SELECT (NVL (MAX (seq_num), 0) + 10)\par
            INTO v_seq_num\par
            FROM fnd_attached_documents\par
            WHERE entity_name = v_entity_name\par
            AND pk1_value     = TO_CHAR (p_entity_id);\par
            EXCEPTION\par
            WHEN OTHERS THEN\par
            DBMS_OUTPUT.put_line  (  '13'||  SQLERRM  )\par
            ;\par
     END;\par
  \par
  \par
     INSERT\par
        INTO fnd_lobs\par
          (\par
            file_id,\par
            file_name,\par
            file_content_type,\par
            file_data,\par
            upload_date,\par
            expiration_date,\par
            program_name,\par
            program_tag,\par
            LANGUAGE,\par
            oracle_charset,\par
            file_format\par
          )\par
        VALUES\par
          (\par
            v_media_id,\par
            p_file_name,\par
            'application/pdf',\par
            EMPTY_BLOB (),\par
            SYSDATE,\par
            NULL,\par
            'FNDATTCH',\par
            '',\par
            'US',\par
            'UTF8',\par
            'BINARY'\par
          )\par
        RETURN file_data  INTO b_lob;\par
  \par
  --b_file := BFILENAME  (    'DEV_TEMP', p_file_name  )  ;\par
  b_file := BFILENAME  (    'HTML_TOP', p_file_name  )  ;\par
  \par
  DBMS_LOB.OPEN  (    b_file, DBMS_LOB.file_readonly  )  ;\par
  DBMS_LOB.loadfromfile  (  b_lob, b_file, DBMS_LOB.getlength (b_file)  )  ;\par
  DBMS_LOB.CLOSE  (    b_file  )  ;\par
  \par
  DBMS_OUTPUT.PUT_LINE (v_category_id||' ' ||v_datatype_id||' ' ||v_media_id||' ' ||v_entity_name||' ' || p_file_name || v_seq_num);\par
  \par
  fnd_webattch.add_attachment \par
\tab\tab   (\tab   seq_num\tab\tab => v_seq_num, \par
\tab\tab\tab   category_id\tab\tab => v_category_id, \par
\tab\tab\tab   document_description\tab => p_document_desc,\par
\tab\tab\tab   datatype_id\tab\tab => v_datatype_id, \par
\tab\tab\tab   text\tab\tab\tab => NULL, \par
\tab\tab\tab   file_name\tab\tab => p_file_name,\par
\tab\tab\tab   url\tab\tab\tab => NULL, \par
\tab\tab\tab   function_name\tab\tab => NULL, \par
\tab\tab\tab   entity_name\tab\tab => v_entity_name, \par
\tab\tab\tab   pk1_value\tab\tab => TO_CHAR (p_entity_id),\par
\tab\tab\tab   pk2_value\tab\tab => NULL,\par
\tab\tab\tab   pk3_value\tab\tab => NULL,\par
\tab\tab\tab   pk4_value\tab\tab => NULL,\par
\tab\tab\tab   pk5_value\tab\tab => NULL, \par
\tab\tab\tab   media_id\tab\tab => v_media_id,\par
\tab\tab\tab   user_id\tab\tab => 1200246 \par
\tab\tab   );\par
  p_return_status := 'SUCCESS';\par
  --COMMIT;\par
COMMIT;\par
\par
EXCEPTION\par
WHEN OTHERS THEN\par
  p_return_status := 'FAIL';\par
  DBMS_OUTPUT.PUT_LINE(    SQLERRM  );\par
END;\par
\par
PROCEDURE CALL_ACH_EPAY_WEBSERVICE(\par
    p_businessId              IN NUMBER,\par
    p_login                   IN VARCHAR2,\par
    p_password                IN VARCHAR2,\par
    p_product                 IN VARCHAR2,\par
    p_bankAccountType         IN VARCHAR2,\par
    p_routingNumber           IN VARCHAR2,\par
    p_bankAccountNumber       IN VARCHAR2,\par
    p_accountHolderName       IN VARCHAR2,\par
    p_accountAddress1         IN VARCHAR2,\par
    p_accountAddress2         IN VARCHAR2,\par
    p_accountCity             IN VARCHAR2,\par
    p_accountState            IN VARCHAR2,\par
    p_accountPostalCode       IN VARCHAR2,\par
    p_accountCountryCode      IN VARCHAR2,\par
    p_nachaStandardEntryClass IN VARCHAR2,\par
    p_individualIdentifier    IN VARCHAR2,\par
    p_companyName             IN VARCHAR2,\par
    p_creditDebitIndicator    IN VARCHAR2,\par
    p_requestedPaymentDate    IN VARCHAR2,\par
    p_billingAccountNumber    IN VARCHAR2,\par
    p_remitAmount             IN VARCHAR2,\par
    p_remitFee                IN VARCHAR2,\par
    p_feeWaiverReason         IN VARCHAR2,\par
    p_transactionCode         IN VARCHAR2,\par
    p_emailAddress            IN VARCHAR2,\par
    p_remitFieldValue         IN VARCHAR2,\par
    p_messageCode OUT NUMBER,\par
    p_messageText OUT VARCHAR2,\par
    p_confirmation_number out VARCHAR2,\par
    p_status out varchar2)\par
AS\par
\tab soap_request      VARCHAR2(30000);\par
\tab soap_respond      VARCHAR2(30000);\par
\tab l_response_temp   VARCHAR2(128);\par
\tab l_response_text   VARCHAR2(128);\par
\tab l_result_XML_node VARCHAR2(128);\par
\tab http_req utl_http.req;\par
\tab http_resp utl_http.resp;\par
\tab Resp Xmltype;\par
\tab i              INTEGER;\par
\tab l_resultStatus VARCHAR2(100);\par
\tab ln_message_text1 number;\par
\tab ln_message_text2 number;\par
\tab ln_message_code1 number;\par
\tab ln_message_code2 number;\par
\tab lv_hostname      varchar2(200);\par
\tab lv_hosturl      varchar2(200);\par
\tab lv_businessId  xx_fin_translatevalues.target_value1%Type;\par
\tab lv_login        xx_fin_translatevalues.target_value1%Type;\par
\tab lv_password     xx_fin_translatevalues.target_value1%Type;\par
\tab lv_nachaStandardEntryClass     xx_fin_translatevalues.target_value1%Type;\par
\tab LV_PRODUCT     XX_FIN_TRANSLATEVALUES.TARGET_VALUE1%TYPE;\par
  lv_emailaddress fnd_user.email_address%TYPE;\par
\par
\tab v_ns_map    varchar2(200) := 'xmlns:env="http://schemas.xmlsoap.org/soap/envelope/", xmlns="http://www.officedepot.com/connect/bankpaymentresponse1"';\par
\tab v_xpath     varchar2(200) := '/env:Envelope/env:Body/ns1:bank-payment-response/message';\par
\tab v_ticket_no varchar2(30);\par
\tab V_SUMMARY   VARCHAR2(30);  \par
  lv_customer_number HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE;\par
  lv_country_code HZ_PARTIES.COUNTRY%Type;\par
  LV_ADDRESS1     HZ_PARTIES.ADDRESS1%TYPE;\par
  LV_ADDRESS2     HZ_PARTIES.ADDRESS2%TYPE;\par
  LV_CITY         HZ_PARTIES.CITY%TYPE;\par
  LV_POSTAL_CODE  HZ_PARTIES.POSTAL_CODE%TYPE;\par
  lv_state        HZ_PARTIES.STATE%Type;\par
  \par
BEGIN\par
  BEGIN\par
\par
\tab SELECT /*XFTV.source_value1, XFTV.source_value2,*/ XFTV.target_value1\par
\tab INTO lv_businessId\par
\tab FROM xx_fin_translatevalues XFTV ,\par
\tab   xx_fin_translatedefinition XFTD\par
\tab WHERE XFTV.translate_id   = XFTD.translate_id\par
\tab AND XFTD.translation_name = 'ACH_ECHECK_DETAILS'\par
\tab and xftv.source_value1 = 'Businessid'\par
\tab /*and xftv.source_value1 = 'login'\par
\tab and xftv.source_value1 = 'password'\par
\tab and xftv.source_value1 = 'nachaStandardEntryClass'\par
\tab and xftv.source_value1 = 'product'\par
\tab */\par
\tab AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)\par
\tab AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)\par
\tab AND XFTV.enabled_flag = 'Y'\par
\tab AND XFTD.enabled_flag = 'Y'; \par
\par
\tab SELECT XFTV.target_value1\par
\tab INTO lv_login\par
\tab FROM xx_fin_translatevalues XFTV ,\par
\tab   xx_fin_translatedefinition XFTD\par
\tab WHERE XFTV.translate_id   = XFTD.translate_id\par
\tab AND XFTD.translation_name = 'ACH_ECHECK_DETAILS'\par
\tab and xftv.source_value1 = 'login'\par
\tab AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)\par
\tab AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)\par
\tab AND XFTV.enabled_flag = 'Y'\par
\tab AND XFTD.enabled_flag = 'Y'; \par
\par
\tab SELECT XFTV.target_value1\par
\tab INTO lv_password\par
\tab FROM xx_fin_translatevalues XFTV ,\par
\tab   xx_fin_translatedefinition XFTD\par
\tab WHERE XFTV.translate_id   = XFTD.translate_id\par
\tab AND XFTD.translation_name = 'ACH_ECHECK_DETAILS'\par
\tab and xftv.source_value1 = 'password'\par
\tab AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)\par
\tab AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)\par
\tab AND XFTV.enabled_flag = 'Y'\par
\tab AND XFTD.enabled_flag = 'Y';  \par
\par
\tab SELECT XFTV.target_value1\par
\tab INTO lv_nachaStandardEntryClass\par
\tab FROM xx_fin_translatevalues XFTV ,\par
\tab   xx_fin_translatedefinition XFTD\par
\tab WHERE XFTV.translate_id   = XFTD.translate_id\par
\tab AND XFTD.translation_name = 'ACH_ECHECK_DETAILS'\par
\tab and xftv.source_value1 = 'nachaStandardEntryClass'\par
\tab AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)\par
\tab AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)\par
\tab AND XFTV.enabled_flag = 'Y'\par
\tab AND XFTD.enabled_flag = 'Y'; \par
\par
\tab SELECT XFTV.target_value1\par
\tab INTO lv_product\par
\tab FROM xx_fin_translatevalues XFTV ,\par
\tab   xx_fin_translatedefinition XFTD\par
\tab WHERE XFTV.translate_id   = XFTD.translate_id\par
\tab AND XFTD.translation_name = 'ACH_ECHECK_DETAILS'\par
\tab and xftv.source_value1 = 'product'\par
  and xftv.source_value2 = p_product--'OD (US) iReceivables External' --Need to pass dynamic to do\par
\tab AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)\par
\tab AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)\par
\tab AND XFTV.enabled_flag = 'Y'\par
\tab AND XFTD.enabled_flag = 'Y';\par
\par
  SELECT EMAIL_ADDRESS \par
  into lv_emailaddress\par
  from fnd_user where user_id = p_emailAddress;\par
  \par
  SELECT CUSTOMER_NUMBER \par
  INTO lv_customer_number\par
  FROM AR_CUSTOMERS\par
  WHERE CUSTOMER_ID = p_billingAccountNumber;\par
\par
  SELECT HZCA.ACCOUNT_NUMBER, HZP.COUNTRY, HZP.ADDRESS1, HZP.ADDRESS2, HZP.CITY, HZP.POSTAL_CODE, HZP.STATE\par
  INTO lv_customer_number, lv_country_code, lv_address1, lv_address2, lv_city, lv_postal_code, lv_state\par
  FROM\par
  HZ_CUST_ACCOUNTS HZCA,\par
  HZ_PARTIES HZP\par
  WHERE HZCA.CUST_ACCOUNT_ID =p_billingAccountNumber\par
  and hzp.party_id = hzca.party_id;\par
\par
    /*\par
    soap_request:= '\par
    <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">\par
    <SOAP-ENV:Body>\par
    <ns1:process xmlns:ns1="http://xmlns.oracle.com/BEWorkDayOracleErrorReportUtility" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">\par
    <input xsi:type="xsd:string">us</input>\par
    </ns1:process>\par
    </SOAP-ENV:Body>\par
    </SOAP-ENV:Envelope>\par
    ';\par
    */\par
\tab soap_request:= ' \par
\tab <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">  \par
  \par
  <soap:Header>\par
\tab <wsse:Security \tab xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">\par
  <wsse:UsernameToken>\par
  <wsse:Username>development</wsse:Username>\par
  <wsse:Password>development123</wsse:Password>\par
  </wsse:UsernameToken>\par
  </wsse:Security>\par
  </soap:Header>\par
\par
\tab <soap:Body xmlns:ns1="http://www.princetonecom.com/connect/bankpaymentrequest1">    \par
\tab <ns1:bank-payment-request>    \par
\tab <ns1:identity>        \par
\tab <ns1:business-id>'||lv_businessId||'</ns1:business-id>        \par
\tab <ns1:login>'||lv_login||'</ns1:login>        \par
\tab <ns1:password>'||lv_password||'</ns1:password>    \par
\tab </ns1:identity>    \par
\par
\tab <ns1:bank-account>        \par
\tab <ns1:bank-account-type>'||p_bankAccountType||'</ns1:bank-account-type>        \par
\tab <ns1:routing-number>'||p_routingNumber||'</ns1:routing-number>        \par
\tab <ns1:bank-account-number>'||p_bankAccountNumber||'</ns1:bank-account-number>        \par
\tab <ns1:account-holder-name>'||p_accountHolderName||'</ns1:account-holder-name>        \par
\tab <ns1:account-address-1>'||lv_address1||'</ns1:account-address-1>        \par
\tab <ns1:account-city>'||lv_city||'</ns1:account-city>        \par
\tab <ns1:account-state>'||lv_state||'</ns1:account-state>        \par
\tab <ns1:account-postal-code>'||lv_postal_code||'</ns1:account-postal-code>        \par
\tab <ns1:account-country-code>'||lv_country_code||'</ns1:account-country-code>    \par
\tab </ns1:bank-account>    \par
\tab <ns1:nacha-standard-entry-class>'||lv_nachaStandardEntryClass||'</ns1:nacha-standard-entry-class>\par
\tab <ns1:individual-identifier>'||p_individualIdentifier||'</ns1:individual-identifier>    \par
\tab <ns1:credit-debit-indicator>'||p_creditDebitIndicator||'</ns1:credit-debit-indicator>    \par
\tab <ns1:requested-payment-date>'||p_requestedPaymentDate||'</ns1:requested-payment-date>    \par
\tab <ns1:remittance>        \par
\tab <ns1:billing-account>            \par
\tab <ns1:billing-account-number>'||lv_customer_number||'</ns1:billing-account-number>            \par
\tab <!-- <ns1:billing-division-id>null</ns1:billing-division-id> -->\par
\tab </ns1:billing-account>        \par
\tab <ns1:remit-amount>'||p_remitAmount||'</ns1:remit-amount>        \par
\tab <ns1:remit-fee>'||p_remitFee||'</ns1:remit-fee>        \par
\tab <!--\par
  <ns1:payment-remit-field>    \par
\tab <ns1:value>'||p_remitFieldValue||'</ns1:value>        \par
\tab </ns1:payment-remit-field>    \par
  <ns1:payment-remit-field>    \par
\tab <ns1:value>12341</ns1:value>      \par
\tab </ns1:payment-remit-field>  \par
  -->\par
\tab </ns1:remittance>    \par
\tab <ns1:product>'||lv_product||'</ns1:product>    \par
\tab <ns1:transaction-code>'||p_transactionCode||'</ns1:transaction-code>    \par
\tab <ns1:email-address>'||lv_emailaddress||'</ns1:email-address>    \par
\tab </ns1:bank-payment-request> \par
\tab </soap:Body>\par
\tab </soap:Envelope>\par
\tab ';\par
\par
\tab SELECT name \par
\tab into lv_hostname\par
\tab FROM   v$database;\par
  \par
\tab if (lv_hostname = 'GSIDEV01')\par
\tab then \par
\tab lv_hosturl := 'soadev01';\par
\tab end if;\par
  \par
  if (lv_hostname = 'GSISIT01')\par
\tab then \par
\tab lv_hosturl := 'sit01';\par
\tab end if;\par
  \par
  if (lv_hostname = 'GSIUATGB')\par
\tab then \par
\tab lv_hosturl := 'uat01';\par
\tab end if;\par
  \par
  if (lv_hostname = 'GSIPRFGB')\par
\tab then \par
\tab lv_hosturl := 'prf01';\par
\tab end if;\par
 \par
  if (lv_hostname = 'GSIPRDGB')\par
\tab then \par
\tab lv_hosturl := 'prd01';\par
\tab end if;  \par
\par
\tab begin\par
\tab     Http_Req:= Utl_Http.Begin_Request ( --'http://172.20.4.118:80/orabpel/default/BEWorkDayOracleErrorReportUtility'\par
\tab     --'http://soadev01.na.odcorp.net/soa-infra/services/finance_rt/CreateBankACHPaymentReqABCImpl/CreateBankACHPayment' , 'POST' , 'HTTP/1.1' );\par
\tab     'http://'||lv_hosturl||'.na.odcorp.net/soa-infra/services/finance_rt/CreateBankACHPaymentsReqABCImpl/createbankachpaymentsreqabcimplprocess_client_ep' , 'POST' , 'HTTP/1.1' );\par
       \par
\tab     utl_http.set_header(http_req, 'Content-Type', 'text/xml'); -- since we are dealing with plain text in XML documents\par
\tab     utl_http.set_header(http_req, 'Content-Length', LENGTH(soap_request));\par
\tab     utl_http.set_header(http_req, 'SOAPAction', ''); -- required to specify this is a SOAP communication\par
\tab     utl_http.write_text(http_req, soap_request);\par
\tab     Http_Resp:= Utl_Http.Get_Response(Http_Req);\par
\tab     utl_http.read_text(http_resp, soap_respond);\par
\tab     utl_http.end_response(http_resp);\par
\tab     resp:= XMLType.createXML(soap_respond);\par
\tab     \par
\tab DBMS_OUTPUT.put_line(soap_respond);\par
\tab     \par
\tab  /*    */\par
\tab    DBMS_OUTPUT.put_line('Response> status_code: "' || Http_Resp.status_code || '"');\par
\tab     IF(Http_Resp.status_code = 200) THEN -- Create XML type from response text         l_resp_xml := XMLType.createXML(l_clob_response);\par
\tab       -- Clean SOAP header         SELECT EXTRACT(l_resp_xml, 'Envelope/Body/node()', l_NAMESPACE_SOAP) INTO l_resp_xml FROM dual;\par
\tab       -- Extract City         l_result_XML_node := 'GetCityForecastByZIPResponse/GetCityForecastByZIPResult/';\par
\tab       --         SELECT EXTRACTVALUE(l_resp_xml, l_result_XML_node || 'City[1]', 'xmlns="http://ws.cdyne.com/WeatherWS/"') INTO l_response_city FROM dual;\par
\tab       --         SELECT EXTRACTVALUE(l_resp_xml, l_result_XML_node || 'ForecastResult[1]/Forecast[1]/Date[1]', 'xmlns="http://ws.cdyne.com/WeatherWS/"') INTO l_response_date FROM dual;\par
\tab       SELECT EXTRACTVALUE(Resp, l_result_XML_node\par
\tab\tab || '//message/message-code', 'xmlns="http://www.princetonecom.com/connect/bankpaymentresponse1"'\par
\tab\tab  )  --'xmlns="http://www.officedepot.com/connect/bankpaymentresponse1"')\par
\tab       INTO p_messageCode\par
\tab       FROM dual;\par
\tab       \par
\tab       SELECT EXTRACTVALUE(Resp, l_result_XML_node\par
\tab\tab || '//message/message-text', 'xmlns="http://www.princetonecom.com/connect/bankpaymentresponse1"'\par
\tab\tab  )  --'xmlns="http://www.officedepot.com/connect/bankpaymentresponse1"')\par
\tab       INTO p_messageText\par
\tab       FROM dual;\par
\tab       \par
\tab       SELECT EXTRACTVALUE(Resp, l_result_XML_node\par
\tab\tab || '//confirmation-number', 'xmlns="http://www.princetonecom.com/connect/bankpaymentresponse1"'\par
\tab\tab  )  --'xmlns="http://www.officedepot.com/connect/bankpaymentresponse1"')\par
\tab       INTO p_confirmation_number\par
\tab       FROM dual;      \par
\tab       \par
\tab       \par
\tab     END IF;\par
\tab     dbms_output.put_line('p_messageCode='||p_messageCode||'   p_messageText='||p_messageText||'   p_confirmation_number='||p_confirmation_number);\par
\par
\par
\tab  /* \par
\tab    SELECT extractValue(Resp, v_xpath || '/message-code', v_ns_map)\par
\tab\tab , extractValue(Resp, v_xpath || '/message-text', v_ns_map)\par
\tab    INTO v_ticket_no, v_summary\par
\tab    FROM dual;\par
\tab   \par
\tab    dbms_output.put_line('message-code = '||v_ticket_no);\par
\tab    dbms_output.put_line('message-text = '||v_summary);    \par
\tab     /*\par
\tab     l_resultStatus := resp.extract('//message-code','xmlns="http://www.officedepot.com/connect/bankpaymentresponse1"').getStringVal();\par
\tab     dbms_output.put_line('Result Satus : '||l_resultStatus);\par
\tab     FOR r_resp IN\par
\tab     (SELECT extractvalue( column_value, '//message-code', 'xmlns="http://www.officedepot.com/connect/bankpaymentresponse1"' ) id ,\par
\tab       extractvalue( column_value, '//message-text', 'xmlns="http://www.officedepot.com/connect/bankpaymentresponse1"' ) descr\par
\tab     FROM TABLE( xmlsequence( xmltype( soap_respond ).extract( '//bank-payment-response', 'xmlns="http://www.officedepot.com/connect/bankpaymentresponse1"' ) ) )\par
\tab     )\par
\tab     LOOP\par
\tab       dbms_output.put_line( r_resp.id || ' ' || r_resp.descr );\par
\tab     END LOOP;\par
\tab     */\par
\tab     p_status := 'SUCCESS';\par
\tab     end;--soap-env host url\par
\tab     EXCEPTION \par
\tab     WHEN OTHERS THEN\par
\tab     p_status := 'FAILURE';\par
      p_messageText:= SQLERRM;\par
    \par
  END;\par
END;\par
\par
END XX_OD_IREC_RECEIPTS_ATTACHMENT;\par
}
 