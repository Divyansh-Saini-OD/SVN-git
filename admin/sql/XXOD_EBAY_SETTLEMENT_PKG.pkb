CREATE OR REPLACE PACKAGE BODY XXOD_EBAY_SETTLEMENT_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name          : XXOD_EBAY_SETTLEMENT_PKG                                                  |
  -- |  Description   : Package body to consume Ebay REST finance APIs for settlement process     |
  -- |  Change Record :                                                                           |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         23-Sep-2020  Mayur Palsokar   Initial version                                  |
  -- +============================================================================================+
  -- +============================================================================================+
  -- |  Global variables                                                                          |
  -- +============================================================================================+
  
  GC_AUTH_URL         VARCHAR2(150) := 'https://api.ebay.com/identity/v1/oauth2/token';
  GC_CONTENT_TYPE     VARCHAR2(150) := 'application/x-www-form-urlencoded';
  GC_FIN_BASE_URL     VARCHAR2(150) := 'https://apiz.ebay.com';
  GC_FIN_SCOPE        VARCHAR2(150) := 'https://api.ebay.com/oauth/api_scope/sell.finances';
  GC_FUL_BASE_URL     VARCHAR2(150) := 'https://api.ebay.com';
  GC_FUL_SCOPE        VARCHAR2(150) := 'https://api.ebay.com/oauth/api_scope/sell.fulfillment';
  GC_FUL_CONTENT_TYPE VARCHAR2(150) := 'application/json';
  GC_DEBUG_FLAG       VARCHAR2(5)   := 'N';
  
  -- +============================================================================================+
  -- |  Procedure    : XXOD_GET_AUTH_INFO                                                         |
  -- |  Description : Get authorization code and redirect URI                                     |
  -- +============================================================================================+
PROCEDURE XXOD_GET_AUTH_INFO(
    P_AUTH_CODE OUT VARCHAR2,
    P_REDIRECT_URI OUT VARCHAR2)
IS
  L_AUTH_URL     VARCHAR2(4000);
  L_AUTH_CODE    VARCHAR2(4000);
  L_REDIRECT_URI VARCHAR2(500);
  
BEGIN
  -- Get AUTH URL value from Translation values
  SELECT XFTV.TARGET_VALUE6,
    XFTV.TARGET_VALUE22
  INTO L_REDIRECT_URI,
    L_AUTH_URL
  FROM XX_FIN_TRANSLATEDEFINITION XFTD,
    XX_FIN_TRANSLATEVALUES XFTV
  WHERE 1               =1
  AND XFTD.TRANSLATE_ID = XFTV.TRANSLATE_ID
  AND XFTD.ENABLED_FLAG = 'Y'
  AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)
  AND XFTD.TRANSLATION_NAME = 'OD_SETTLEMENT_PROCESSES'
  AND XFTV.SOURCE_VALUE1    = 'NEW_EBAY_MPL';
  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GET_AUTH_INFO:', 'L_AUTH_URL '||L_AUTH_URL);
  
  -- Get Auth Code from AUTH URL
  SELECT SUBSTR(SUBSTR(L_AUTH_URL,1,INSTR(L_AUTH_URL,'expires_in',1,1)-2), INSTR(SUBSTR(L_AUTH_URL,1,INSTR(L_AUTH_URL,'expires_in',1,1)-2), '=true') + 11)
  INTO L_AUTH_CODE
  FROM DUAL;
  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GET_AUTH_INFO:', 'L_AUTH_CODE '||L_AUTH_CODE);
  
  -- Set output variables
  P_AUTH_CODE    := L_AUTH_CODE;
  P_REDIRECT_URI := L_REDIRECT_URI;

EXCEPTION
WHEN OTHERS THEN
  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GET_AUTH_INFO:', 'Main EXCEPTION '||SQLERRM);
END XXOD_GET_AUTH_INFO;

-- +============================================================================================+
-- |  Function    : XXOD_GET_AUTH_STRING                                                        |
-- |  Description : Get authorization string                                                    |
-- +============================================================================================+

FUNCTION XXOD_GET_AUTH_STRING
  RETURN VARCHAR2
IS
  L_AUTH_ENCODED_STR VARCHAR2(500);

BEGIN

  -- Get and encode auth string from transaction values
  SELECT REPLACE(UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_ENCODE(UTL_RAW.CAST_TO_RAW(REPLACE(UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_DECODE(UTL_RAW.CAST_TO_RAW(XFTV.TARGET_VALUE2))), CHR(13)
    || CHR(10), '')
    ||':'
    || REPLACE(UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_DECODE(UTL_RAW.CAST_TO_RAW(XFTV.TARGET_VALUE3))), CHR(13)
    || CHR(10), '')))), CHR(13)
    || CHR(10), '')
  INTO L_AUTH_ENCODED_STR
  FROM XX_FIN_TRANSLATEDEFINITION XFTD,
    XX_FIN_TRANSLATEVALUES XFTV
  WHERE 1               =1
  AND XFTD.TRANSLATE_ID = XFTV.TRANSLATE_ID
  AND XFTD.ENABLED_FLAG = 'Y'
  AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)
  AND XFTD.TRANSLATION_NAME = 'OD_SETTLEMENT_PROCESSES'
  AND XFTV.SOURCE_VALUE1    = 'NEW_EBAY_MPL';
  
  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GET_AUTH_STRING:', 'L_AUTH_ENCODED_STR '||L_AUTH_ENCODED_STR);
  
  RETURN L_AUTH_ENCODED_STR;
  
EXCEPTION
WHEN OTHERS THEN
  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GET_AUTH_STRING:', 'EXCEPTION'||SQLERRM);
END XXOD_GET_AUTH_STRING;

-- +============================================================================================+
-- |  Procedure   : XXOD_GENERATE_REFRESH_TOKEN                                                      |
-- |  Description : Exchanging the authorization code for a User access token                   |
-- +============================================================================================+

PROCEDURE XXOD_GENERATE_REFRESH_TOKEN(
    X_ERRBUF OUT VARCHAR2,
    X_RETCODE OUT NUMBER)
IS
  L_REQ UTL_HTTP.REQ;
  L_RES UTL_HTTP.RESP;
  L_API_RES CLOB;
  LC_CONTENT       VARCHAR2(4000);
  LC_REFRESH_TOKEN VARCHAR2(4000);
  L_AUTH_CODE      VARCHAR2(4000);
  L_AUTH_STRING    VARCHAR2(500);
  L_REDIRECT_URI   VARCHAR2(500);
  L_WALLET_PATH    VARCHAR2(300);
  L_WALLET_PWD     VARCHAR2(50);

BEGIN
  -- Get Auth code and redirect URI
  XXOD_GET_AUTH_INFO(L_AUTH_CODE, L_REDIRECT_URI);
  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GENERATE_REFRESH_TOKEN:', 'L_AUTH_CODE '||L_AUTH_CODE);
  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GENERATE_REFRESH_TOKEN:', 'L_REDIRECT_URI '||L_REDIRECT_URI);
 
  -- Get client creds
  L_AUTH_STRING := XXOD_GET_AUTH_STRING;
  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GENERATE_REFRESH_TOKEN:', 'L_AUTH_STRING '||L_AUTH_STRING);
 
  -- Set Wallet
  SELECT XFTV.TARGET_VALUE4,
    XFTV.TARGET_VALUE5
  INTO L_WALLET_PATH,
    L_WALLET_PWD
  FROM XX_FIN_TRANSLATEDEFINITION XFTD,
    XX_FIN_TRANSLATEVALUES XFTV
  WHERE 1               =1
  AND XFTD.TRANSLATE_ID = XFTV.TRANSLATE_ID
  AND XFTD.ENABLED_FLAG = 'Y'
  AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)
  AND XFTD.TRANSLATION_NAME = 'OD_SETTLEMENT_PROCESSES'
  AND XFTV.SOURCE_VALUE1    = 'NEW_EBAY_MPL';
  
  UTL_HTTP.SET_WALLET(L_WALLET_PATH, L_WALLET_PWD);
  
  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GENERATE_REFRESH_TOKEN:', 'L_WALLET_PATH '||L_WALLET_PATH);
 
  -- Call Auth API
  LC_CONTENT := 'grant_type=authorization_code'||chr(38)||'redirect_uri='||L_REDIRECT_URI||chr(38)||'code='||L_AUTH_CODE;
  L_REQ      := UTL_HTTP.BEGIN_REQUEST(GC_AUTH_URL, 'POST',' HTTP/1.1');
  UTL_HTTP.SET_HEADER(L_REQ, 'Authorization', 'Basic '||L_AUTH_STRING);
  UTL_HTTP.SET_HEADER(L_REQ, 'Content-Type', GC_CONTENT_TYPE);
  UTL_HTTP.SET_HEADER(L_REQ, 'Content-Length', LENGTH(LC_CONTENT));
  UTL_HTTP.WRITE_TEXT(L_REQ, LC_CONTENT);
  L_RES := UTL_HTTP.GET_RESPONSE(L_REQ);

  BEGIN
    LOOP
      UTL_HTTP.READ_LINE(L_RES, L_API_RES);
      DBMS_OUTPUT.PUT_LINE(L_API_RES);
    END LOOP;
    UTL_HTTP.END_RESPONSE(L_RES);
  EXCEPTION
  WHEN UTL_HTTP.END_OF_BODY THEN
    UTL_HTTP.END_RESPONSE(L_RES);
  WHEN UTL_HTTP.TOO_MANY_REQUESTS THEN
    UTL_HTTP.END_RESPONSE(L_RES);
  END;

  BEGIN
    SELECT REFRESH_TOKEN
    INTO LC_REFRESH_TOKEN
    FROM DUAL,
      JSON_TABLE (L_API_RES,'$' COLUMNS (REFRESH_TOKEN VARCHAR2 (4000) PATH '$.refresh_token'));

    UPDATE XX_FIN_TRANSLATEVALUES XFTV
    SET XFTV.TARGET_VALUE23 = LC_REFRESH_TOKEN,
      XFTV.TARGET_VALUE25   = TO_CHAR(SYSDATE + 47304000/(60*60*24), 'DD-MON-YY HH24:MI:SS')
    WHERE 1                 = 1
    AND XFTV.SOURCE_VALUE1  = 'NEW_EBAY_MPL'
    AND EXISTS
      (SELECT 1
      FROM XX_FIN_TRANSLATEDEFINITION XFTD
      WHERE XFTD.TRANSLATE_ID = XFTV.TRANSLATE_ID
      AND XFTD.ENABLED_FLAG   ='Y'
      AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)
      AND XFTD.TRANSLATION_NAME ='OD_SETTLEMENT_PROCESSES'
      );
    COMMIT;

  EXCEPTION
  WHEN OTHERS THEN
    WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GENERATE_REFRESH_TOKEN update', 'EXCEPTION '||SQLERRM);
  END;

EXCEPTION
WHEN OTHERS THEN
  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GENERATE_REFRESH_TOKEN:', 'EXCEPTION'||SQLERRM);
END XXOD_GENERATE_REFRESH_TOKEN;

-- +============================================================================================+
-- |  Function    : XXOD_GET_ACCESS_TOKEN                                                       |
-- |  Description : get user access token using refresh token                                   |
-- +============================================================================================+

FUNCTION XXOD_GET_ACCESS_TOKEN(
    P_SCOPE       IN VARCHAR2,
    P_AUTH_STRING IN VARCHAR2)
  RETURN VARCHAR2
IS
  L_REQ UTL_HTTP.REQ;
  L_RES UTL_HTTP.RESP;
  L_API_RES CLOB;
  L_ACCESS_TOKEN  VARCHAR2 (4000);
  LC_CONTENT      VARCHAR2(4000);
  L_REFRESH_TOKEN VARCHAR2 (4000);
  L_AUTH_STRING   VARCHAR2 (500):= P_AUTH_STRING;
  L_WALLET_PATH   VARCHAR2(300);
  L_WALLET_PWD    VARCHAR2(50);

BEGIN

WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GET_ACCESS_TOKEN:', 'Begin');
 
  SELECT XFTV.TARGET_VALUE23,
    XFTV.TARGET_VALUE4,
    XFTV.TARGET_VALUE5
  INTO L_REFRESH_TOKEN,
    L_WALLET_PATH,
    L_WALLET_PWD
  FROM XX_FIN_TRANSLATEDEFINITION XFTD,
    XX_FIN_TRANSLATEVALUES XFTV
  WHERE 1               =1
  AND XFTD.TRANSLATE_ID = XFTV.TRANSLATE_ID
  AND XFTD.ENABLED_FLAG = 'Y'
  AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE)
  AND XFTD.TRANSLATION_NAME = 'OD_SETTLEMENT_PROCESSES'
  AND XFTV.SOURCE_VALUE1    = 'NEW_EBAY_MPL';

  -- Set Wallet
  UTL_HTTP.SET_WALLET(L_WALLET_PATH, L_WALLET_PWD);
  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GET_ACCESS_TOKEN:', 'L_WALLET_PATH '||L_WALLET_PATH);

  -- Call Auth API
  LC_CONTENT := 'grant_type=refresh_token'||chr(38)||'refresh_token='||L_REFRESH_TOKEN||chr(38)||'scope='||P_SCOPE;
  L_REQ      := UTL_HTTP.BEGIN_REQUEST(GC_AUTH_URL, 'POST',' HTTP/1.1');
  UTL_HTTP.SET_HEADER(L_REQ, 'Authorization', 'Basic '||L_AUTH_STRING);
  UTL_HTTP.SET_HEADER(L_REQ, 'Content-Type', GC_CONTENT_TYPE);
  UTL_HTTP.SET_HEADER(L_REQ, 'Content-Length', LENGTH(LC_CONTENT));
  UTL_HTTP.WRITE_TEXT(L_REQ, LC_CONTENT);
  L_RES := UTL_HTTP.GET_RESPONSE(L_REQ);

  BEGIN
    LOOP
      UTL_HTTP.READ_LINE(L_RES, L_API_RES);
      DBMS_OUTPUT.PUT_LINE(L_API_RES);
    END LOOP;
    UTL_HTTP.END_RESPONSE(L_RES);
  EXCEPTION
  WHEN UTL_HTTP.END_OF_BODY THEN
    UTL_HTTP.END_RESPONSE(L_RES);
  WHEN UTL_HTTP.TOO_MANY_REQUESTS THEN
    UTL_HTTP.END_RESPONSE(L_RES);
  END;

  SELECT ACCESS_TOKEN
  INTO L_ACCESS_TOKEN
  FROM DUAL,
    JSON_TABLE (L_API_RES,'$' COLUMNS (ACCESS_TOKEN VARCHAR2 (4000) PATH '$.access_token'));
  RETURN L_ACCESS_TOKEN;

EXCEPTION
WHEN OTHERS THEN
  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GET_ACCESS_TOKEN:', 'EXCEPTION');
END XXOD_GET_ACCESS_TOKEN;

-- +============================================================================================+
-- |  Procedure    : XXOD_GET_TRANSACTIONS                                                       |
-- |  Description : Get transactions                                                            |
-- +============================================================================================+

PROCEDURE XXOD_GET_TRANSACTIONS(
    P_ACCESS_TOKEN IN VARCHAR2)
IS
  L_REQ UTL_HTTP.REQ;
  L_RES UTL_HTTP.RESP;
  L_LIMIT            NUMBER       :=200;
  LC_TRANSACTION_EP  VARCHAR2(50) := '/sell/finances/v1/transaction?limit='||l_limit;
  LC_TRANSACTION_URL VARCHAR2(100);
  LCLOB_BUFFER CLOB;
  LC_BUFFER CLOB;
  L_TOTAL_TRANS VARCHAR2(10);
  L_NEXT_PAGE   VARCHAR2(200);
  L_LOOP_COUNT  VARCHAR2(10);

BEGIN

  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GET_TRANSACTIONS:', 'Begin');

  -- Delete existing json records
  DELETE FROM XXOD_EBAY_MPL_TRANS_RES;

  LC_TRANSACTION_URL := GC_FIN_BASE_URL||LC_TRANSACTION_EP;
  L_REQ              := UTL_HTTP.BEGIN_REQUEST(LC_TRANSACTION_URL, 'GET',' HTTP/1.1');
  UTL_HTTP.SET_HEADER(L_REQ, 'Authorization','Bearer '||P_ACCESS_TOKEN);
  UTL_HTTP.SET_HEADER(L_REQ, 'X-EBAY-C-MARKETPLACE-ID', 'EBAY_US');
  L_RES := UTL_HTTP.GET_RESPONSE(L_REQ);

  BEGIN
    LCLOB_BUFFER := EMPTY_CLOB;
    LOOP
      UTL_HTTP.READ_TEXT(L_RES, LC_BUFFER, LENGTH(LC_BUFFER));
      LCLOB_BUFFER := LCLOB_BUFFER || LC_BUFFER;
    END LOOP;
    UTL_HTTP.END_RESPONSE(L_RES);
  EXCEPTION
  WHEN UTL_HTTP.END_OF_BODY THEN
    UTL_HTTP.END_RESPONSE(L_RES);
  END;

  -- Insert transactions api upto 200 transactions in table
  INSERT
  INTO XXOD_EBAY_MPL_TRANS_RES VALUES
    (
      LCLOB_BUFFER
    );

  -- to check if more transactions exists
  SELECT TOTAL_TRANS,
    NEXT_PAGE
  INTO L_TOTAL_TRANS,
    L_NEXT_PAGE
  FROM JSON_TABLE(LCLOB_BUFFER, '$' COLUMNS( TOTAL_TRANS VARCHAR2(10) PATH ' $.total', NEXT_PAGE VARCHAR2(200) PATH ' $.next' ) );
 
   L_LOOP_COUNT := CEIL(L_TOTAL_TRANS/L_LIMIT);

  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GET_TRANSACTIONS:', 'L_LOOP_COUNT '||L_LOOP_COUNT);

  -- load transactions > 200 in table
  IF L_LOOP_COUNT > 1 THEN
    FOR I IN 2..L_LOOP_COUNT
    LOOP
      LC_TRANSACTION_URL := l_next_page;
      L_REQ              := UTL_HTTP.BEGIN_REQUEST(LC_TRANSACTION_URL, 'GET',' HTTP/1.1');
      UTL_HTTP.SET_PERSISTENT_CONN_SUPPORT(TRUE);
      UTL_HTTP.SET_HEADER(L_REQ, 'Authorization','Bearer '||P_ACCESS_TOKEN);
      UTL_HTTP.SET_HEADER(L_REQ, 'X-EBAY-C-MARKETPLACE-ID', 'EBAY_US');
      L_RES := UTL_HTTP.GET_RESPONSE(L_REQ);
      BEGIN
        LCLOB_BUFFER := EMPTY_CLOB;
        LOOP
          UTL_HTTP.READ_TEXT(L_RES, LC_BUFFER, LENGTH(LC_BUFFER));
          LCLOB_BUFFER := LCLOB_BUFFER || LC_BUFFER;
        END LOOP;
        UTL_HTTP.END_RESPONSE(L_RES);
      EXCEPTION
      WHEN UTL_HTTP.END_OF_BODY THEN
        UTL_HTTP.END_RESPONSE(L_RES);
      END;
      INSERT INTO XXOD_EBAY_MPL_TRANS_RES VALUES
        (LCLOB_BUFFER
        );
      SELECT TOTAL_TRANS,
        NEXT_PAGE
      INTO L_TOTAL_TRANS,
        L_NEXT_PAGE
      FROM JSON_TABLE(LCLOB_BUFFER, '$' COLUMNS( TOTAL_TRANS VARCHAR2(10) PATH ' $.total', NEXT_PAGE VARCHAR2(200) PATH ' $.next' ) );
    END LOOP;
  END IF;

EXCEPTION
WHEN OTHERS THEN
  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GET_TRANSACTIONS:', 'EXCEPTION '||SQLERRM);
END XXOD_GET_TRANSACTIONS;

-- +============================================================================================+
-- |  Procedure   : XXOD_GET_ORDERS                                                             |
-- |  Description : Get Orders                                                                  |
-- +============================================================================================+

PROCEDURE XXOD_GET_ORDERS(
    P_ACCESS_TOKEN IN VARCHAR2)
IS
  L_REQ UTL_HTTP.REQ;
  L_RES UTL_HTTP.RESP;
  L_LIMIT       NUMBER       :=1000;
  LC_ORDERS_EP  VARCHAR2(50) := '/sell/fulfillment/v1/order?limit='||L_LIMIT;
  LC_ORDERS_URL VARCHAR2(100);
  LCLOB_BUFFER CLOB;
  LC_BUFFER CLOB;
  L_TOTAL_TRANS      VARCHAR2(10);
  L_NEXT_PAGE        VARCHAR2(200);
  L_LOOP_COUNT       VARCHAR2(10);
  LC_TRANSACTION_URL VARCHAR2(100);

BEGIN

  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GET_ORDERS:', 'Begin ');
  
-- Delete existing records for Order JSON 
  DELETE FROM XXOD_EBAY_MPL_ORDER_RES;
 
  LC_ORDERS_URL := GC_FUL_BASE_URL||LC_ORDERS_EP;
  L_REQ         := UTL_HTTP.BEGIN_REQUEST(LC_ORDERS_URL, 'GET',' HTTP/1.1');
  UTL_HTTP.SET_HEADER(L_REQ, 'Authorization','Bearer '||P_ACCESS_TOKEN);
  UTL_HTTP.SET_HEADER(L_REQ, 'Accept', GC_FUL_CONTENT_TYPE);
  UTL_HTTP.SET_HEADER(L_REQ, 'Content-Type',GC_FUL_CONTENT_TYPE);
  L_RES := UTL_HTTP.GET_RESPONSE(L_REQ);
 
 BEGIN
    LCLOB_BUFFER := EMPTY_CLOB;
    LOOP
      UTL_HTTP.READ_TEXT(L_RES, LC_BUFFER, LENGTH(LC_BUFFER));
      LCLOB_BUFFER := LCLOB_BUFFER || LC_BUFFER;
    END LOOP;
    UTL_HTTP.END_RESPONSE(L_RES);
  EXCEPTION
  WHEN UTL_HTTP.END_OF_BODY THEN
    UTL_HTTP.END_RESPONSE(L_RES);
  WHEN UTL_HTTP.TOO_MANY_REQUESTS THEN
    UTL_HTTP.END_RESPONSE(L_RES);
  END;

  INSERT INTO XXOD_EBAY_MPL_ORDER_RES VALUES
    (LCLOB_BUFFER);

  SELECT TOTAL_TRANS,
    NEXT_PAGE
  INTO L_TOTAL_TRANS,
    L_NEXT_PAGE
  FROM JSON_TABLE(LCLOB_BUFFER, '$' COLUMNS( TOTAL_TRANS VARCHAR2(10) PATH ' $.total', NEXT_PAGE VARCHAR2(200) PATH ' $.next' ) );
 
 L_LOOP_COUNT   := CEIL(L_TOTAL_TRANS/L_LIMIT);
 
   WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GET_ORDERS:', 'L_LOOP_COUNT '||L_LOOP_COUNT);
  
  IF L_LOOP_COUNT > 1 THEN
    FOR I IN 2..L_LOOP_COUNT
    LOOP
      LC_TRANSACTION_URL := l_next_page;
      L_REQ              := UTL_HTTP.BEGIN_REQUEST(LC_TRANSACTION_URL, 'GET',' HTTP/1.1');
      UTL_HTTP.SET_PERSISTENT_CONN_SUPPORT(TRUE);
      UTL_HTTP.SET_HEADER(L_REQ, 'Authorization','Bearer '||P_ACCESS_TOKEN);
      UTL_HTTP.SET_HEADER(L_REQ, 'X-EBAY-C-MARKETPLACE-ID', 'EBAY_US');
      L_RES := UTL_HTTP.GET_RESPONSE(L_REQ);
      BEGIN
        LCLOB_BUFFER := EMPTY_CLOB;
        LOOP
          UTL_HTTP.READ_TEXT(L_RES, LC_BUFFER, LENGTH(LC_BUFFER));
          LCLOB_BUFFER := LCLOB_BUFFER || LC_BUFFER;
        END LOOP;
        UTL_HTTP.END_RESPONSE(L_RES);
      EXCEPTION
      WHEN UTL_HTTP.END_OF_BODY THEN
        UTL_HTTP.END_RESPONSE(L_RES);
      END;
  
  INSERT INTO XXOD_EBAY_MPL_ORDER_RES VALUES
        (LCLOB_BUFFER
        );
      SELECT TOTAL_TRANS,
        NEXT_PAGE
      INTO L_TOTAL_TRANS,
        L_NEXT_PAGE
      FROM JSON_TABLE(LCLOB_BUFFER, '$' COLUMNS( TOTAL_TRANS VARCHAR2(10) PATH ' $.total', NEXT_PAGE VARCHAR2(200) PATH ' $.next' ) );
    END LOOP;
  END IF;

EXCEPTION
WHEN OTHERS THEN
  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_GET_ORDERS:', 'EXCEPTION '||SQLERRM);
END XXOD_GET_ORDERS;

-- +============================================================================================+
-- |  Procedure   : XXOD_LOAD_SETTLEMENT_DATA                                                   |
-- |  Description : Load transactions and Orders data in table                                  |
-- +============================================================================================+

PROCEDURE XXOD_LOAD_SETTLEMENT_DATA
IS
  CURSOR C_TRANSACTIONS
  IS
    SELECT TRANSACTIONID,
      ORDERID,
      PAYOUTID,
      TRANSACTIONTYPE,
      MARKETPLACEFEES_VALUE,
      TRANSACTIONDATE,
      TRANSACTIONSTATUS
    FROM XXOD_EBAY_MPL_TRANS_RES,
      JSON_TABLE ( TRANSACTION_JSON ,'$.transactions[*]' COLUMNS ( TRANSACTIONID VARCHAR2 ( 100 ) PATH '$.transactionId', ORDERID VARCHAR2 ( 100 ) PATH '$.orderId', PAYOUTID VARCHAR2 ( 100 ) PATH '$.payoutId', TRANSACTIONTYPE VARCHAR2 ( 100 ) PATH '$.transactionType', TRANSACTIONDATE VARCHAR2 ( 100 ) PATH '$.transactionDate', NESTED path '$.orderLineItems[*]' COLUMNS ( NESTED path '$.marketplaceFees[*]' COLUMNS( MARKETPLACEFEES_VALUE VARCHAR2 ( 100 ) PATH '$.amount.value' ) ), TRANSACTIONSTATUS VARCHAR2 ( 100 ) PATH '$.transactionStatus'))
    WHERE 1               = 1
    AND TRANSACTIONSTATUS = 'PAYOUT'
    AND NOT EXISTS
      (SELECT 1
      FROM XX_CE_MARKETPLACE_PRE_STG
      WHERE 1        = 1
      AND ATTRIBUTE1 = PAYOUTID
	  AND PROCESS_NAME = 'EBAY_MPL_NEW'
      )
  ORDER BY PAYOUTID,
    TRANSACTIONID DESC;

  CURSOR C_ORDERS(P_ORDERID VARCHAR2)
  IS
    SELECT ORDERID,
      LEGACYORDERID,
      PAYSUM_PAYMETHOD,
      PAYSUM_PAYMENTSTATUS,
      LINEITEMS_SKU,
      LINEITEMS_TITLE,
      LINEITEMS_LINEITEMCOST_VALUE,
      LINEITEMS_QUANTITY,
      LINEITEMS_DELIVERYCOST_VALUE,
      LINEITEMS_TAXTYPE,
      LINEITEMS_EBAYREMITTAXES_VALUE
    FROM XXOD_EBAY_MPL_ORDER_RES,
      JSON_TABLE (ORDER_JSON ,'$.orders[*]' COLUMNS ( ORDERID VARCHAR2 ( 100 ) PATH '$.orderId', LEGACYORDERID VARCHAR2 ( 100 ) PATH '$.legacyOrderId', PAYSUM_PAYMETHOD VARCHAR2 ( 100 ) PATH '$.paymentSummary.payments.paymentMethod', PAYSUM_PAYMENTSTATUS VARCHAR2 ( 100 ) PATH '$.paymentSummary.payments.paymentStatus', NESTED path '$.lineItems[*]' COLUMNS ( LINEITEMS_SKU VARCHAR2 ( 100 ) PATH '$.sku', LINEITEMS_TITLE VARCHAR2 ( 100 ) PATH '$.title', LINEITEMS_LINEITEMCOST_VALUE VARCHAR2 ( 100 ) PATH '$.lineItemCost.value', LINEITEMS_QUANTITY VARCHAR2 ( 100 ) PATH '$.quantity', LINEITEMS_DELIVERYCOST_VALUE VARCHAR2 ( 100 ) PATH '$.deliveryCost.shippingCost.value', LINEITEMS_TAXTYPE VARCHAR2 ( 100 ) PATH '$.ebayCollectAndRemitTaxes.taxType', LINEITEMS_EBAYREMITTAXES_VALUE VARCHAR2 ( 100 ) PATH '$.ebayCollectAndRemitTaxes.amount.value' ) ))
    WHERE 1     = 1
    AND ORDERID = P_ORDERID
    AND NOT EXISTS
      (SELECT 1
      FROM XX_CE_MARKETPLACE_PRE_STG
      WHERE 1        = 1
      AND ATTRIBUTE3 = ORDERID
	  AND PROCESS_NAME = 'EBAY_MPL_NEW'
      )
  ORDER BY ORDERID;

BEGIN

  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_LOAD_SETTLEMENT_DATA:', 'Begin');

  FOR T IN C_TRANSACTIONS
  LOOP
    FOR O IN C_ORDERS(T.ORDERID)
    LOOP
      INSERT
      INTO XX_CE_MARKETPLACE_PRE_STG
        (
          REC_ID,
          PROCESS_NAME,
          FILENAME,
          FILE_TYPE,
          PROCESS_FLAG,
          -- Transaction response
          ATTRIBUTE1, -- PAYOUTID
          ATTRIBUTE2, -- TRANSACTIONID
          ATTRIBUTE3, -- ORDERID
          ATTRIBUTE4, -- TRANSACTIONTYPE
          ATTRIBUTE5, -- TRANSACTIONDATE
          ATTRIBUTE6, -- MARKETPLACEFEES_VALUE
          ATTRIBUTE7, -- TRANSACTIONSTATUS
          -- Orders response
          ATTRIBUTE8,  -- LEGACYORDERID
          ATTRIBUTE9,  -- PAYSUM_PAYMETHOD
          ATTRIBUTE10, -- PAYSUM_PAYMENTSTATUS
          ATTRIBUTE11, -- LINEITEMS_SKU
          ATTRIBUTE12, -- LINEITEMS_TITLE
          ATTRIBUTE13, -- LINEITEMS_LINEITEMCOST_VALUE
          ATTRIBUTE14, -- LINEITEMS_QUANTITY
          ATTRIBUTE15, -- LINEITEMS_DELIVERYCOST_VALUE
          ATTRIBUTE16, -- LINEITEMS_TAXTYPE
          ATTRIBUTE17, -- LINEITEMS_EBAYREMITTAXES_VALUE
          -- Who columns
          ATTRIBUTE18, -- Created By
          ATTRIBUTE19, -- Creation Date
          ATTRIBUTE20, -- Last Updated By
          ATTRIBUTE21, -- Last Update Date
          ATTRIBUTE22  -- Last Update Login
        )
        VALUES
        (
          XXOD_EBAY_MPL_SEQ.NEXTVAL,
          'EBAY_MPL_NEW',
          T.PAYOUTID,
          'EBAY_FINANCE_API',
          'N',
          T.PAYOUTID,
          T.TRANSACTIONID,
          T.ORDERID,
          T.TRANSACTIONTYPE,
          T.TRANSACTIONDATE,
          T.MARKETPLACEFEES_VALUE,
          T.TRANSACTIONSTATUS,
          O.LEGACYORDERID,
          O.PAYSUM_PAYMETHOD,
          O.PAYSUM_PAYMENTSTATUS,
          O.LINEITEMS_SKU,
          O.LINEITEMS_TITLE,
          O.LINEITEMS_LINEITEMCOST_VALUE,
          O.LINEITEMS_QUANTITY,
          O.LINEITEMS_DELIVERYCOST_VALUE,
          O.LINEITEMS_TAXTYPE,
          O.LINEITEMS_EBAYREMITTAXES_VALUE,
          FND_PROFILE.VALUE('USER_ID'),
          SYSDATE,
          FND_PROFILE.VALUE('USER_ID'),
          SYSDATE,
          FND_PROFILE.VALUE('LOGIN_ID')
        );
      COMMIT;
    END LOOP;
  END LOOP;

EXCEPTION
WHEN OTHERS THEN
  WRITE_LOG(GC_DEBUG_FLAG, 'XXOD_LOAD_SETTLEMENT_DATA:', 'EXCEPTION');
END XXOD_LOAD_SETTLEMENT_DATA;

-- +============================================================================================+
-- |  Procedure   : WRITE_LOG                                                                   |
-- |  Description : Load payouts and transactions data in table                                 |
-- +============================================================================================+

PROCEDURE WRITE_LOG
  (
    P_DISPLAY_FLG IN VARCHAR2 ,
    P_LOCATION    IN VARCHAR2 DEFAULT NULL ,
    P_STATEMENT   IN VARCHAR2 DEFAULT NULL
  )
AS
BEGIN
  IF P_DISPLAY_FLG = 'Y' THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' '||P_LOCATION||': '||P_STATEMENT);
  END IF;
END WRITE_LOG;

-- +============================================================================================+
-- |  Procedure   : MAIN                                                                        |
-- |  Description : Load payouts and transactions data in table                                 |
-- +============================================================================================+

PROCEDURE MAIN
IS
  LC_AUTH_TOKEN       VARCHAR2(4000);
  LC_AUTH_STRING      VARCHAR2(500);
  LC_REDIRECT_URI     VARCHAR2(500);
  LC_ACCESS_TOKEN_FIN VARCHAR2(4000);
  LC_ACCESS_TOKEN_FUL VARCHAR2(4000);
  LC_TRANSACTIONS_RES CLOB;
  LC_ORDERS_RES CLOB;
BEGIN
  WRITE_LOG(GC_DEBUG_FLAG, '--------------------------------', '---------------------------------');
  WRITE_LOG(GC_DEBUG_FLAG, 'MAIN:', 'Starts here');
  WRITE_LOG(GC_DEBUG_FLAG, '--------------------------------', '---------------------------------');

  WRITE_LOG(GC_DEBUG_FLAG, 'Calling: ', 'XXOD_GET_AUTH_STRING');
  LC_AUTH_STRING:= XXOD_GET_AUTH_STRING;
  WRITE_LOG(GC_DEBUG_FLAG, 'LC_AUTH_STRING: ', 'LC_AUTH_STRING');

  WRITE_LOG(GC_DEBUG_FLAG, 'Calling:', 'XXOD_GET_ACCESS_TOKEN for Transactions API');
  LC_ACCESS_TOKEN_FIN := XXOD_GET_ACCESS_TOKEN(GC_FIN_SCOPE, LC_AUTH_STRING);

  WRITE_LOG(GC_DEBUG_FLAG, 'Calling:', 'XXOD_GET_TRANSACTIONS');
  XXOD_GET_TRANSACTIONS(LC_ACCESS_TOKEN_FIN);

  WRITE_LOG(GC_DEBUG_FLAG, 'Calling:', 'XXOD_GET_ACCESS_TOKEN for Orders API');
  LC_ACCESS_TOKEN_FUL := XXOD_GET_ACCESS_TOKEN(GC_FUL_SCOPE, LC_AUTH_STRING);

  WRITE_LOG(GC_DEBUG_FLAG, 'Calling:', 'XXOD_GET_ORDERS');
  XXOD_GET_ORDERS(LC_ACCESS_TOKEN_FUL);

  WRITE_LOG(GC_DEBUG_FLAG, 'Calling:', 'XXOD_LOAD_SETTLEMENT_DATA');
  XXOD_LOAD_SETTLEMENT_DATA;

  WRITE_LOG(GC_DEBUG_FLAG, '--------------------------------', '---------------------------------');
  WRITE_LOG(GC_DEBUG_FLAG, 'MAIN:', 'Ends here');
  WRITE_LOG(GC_DEBUG_FLAG, '--------------------------------', '---------------------------------');

EXCEPTION
WHEN OTHERS THEN
  WRITE_LOG(GC_DEBUG_FLAG, 'Main:', 'EXCEPTION');
END MAIN;

END XXOD_EBAY_SETTLEMENT_PKG;

/
SHOW ERRORS;