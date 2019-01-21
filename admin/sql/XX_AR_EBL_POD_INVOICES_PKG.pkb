CREATE OR REPLACE PACKAGE BODY XX_AR_EBL_POD_INVOICES_PKG
AS
  ---+============================================================================================+
  ---|                              Office Depot - Project Simplify                               |
  ---|                                   Capgemini Technologies                                   |
  ---+============================================================================================+
  ---|    Application     : AR                                                                    |
  ---|                                                                                            |
  ---|    Name            : XX_AR_EBL_POD_INVOICES_PKG.pkb                                        |
  ---|                                                                                            |
  ---|    Description     : Extract POD information for eligible transactions                     |
  ---|                                                                                            |
  ---|                                                                                            |
  ---|                                                                                            |
  ---|    Change Record                                                                           |
  ---|    ---------------------------------                                                       |
  ---|    Version         DATE              AUTHOR             DESCRIPTION                        |
  ---|    ------------    ----------------- ---------------    ---------------------              |
  ---|    1.0             12-Oct-2018       Aarthi             Initial Version - NAIT - 66520     |
  ---+============================================================================================+
  --+=============================================================================================+
  ---|    Name : POD_EXTRACT                                                                      |
  ---|    Description    : The POD_EXTRACT proc will perform the following                        |
  ---|                                                                                            |
  ---|                    1. Fetch all the eligible transactions for POD Flag enabled customers   |
  ---|                    2. Connect to DTS system via REST Service URL and fetch                 |
  ---|                       the corresponding POD images for the eligible orders                 |
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+
PROCEDURE POD_EXTRACT(
    x_errbuf OUT NOCOPY  VARCHAR2,
    x_retcode OUT NOCOPY NUMBER )
AS
  
  CURSOR lcu_eligible_trans
  IS
    SELECT DISTINCT batch_id
	  FROM XX_AR_EBL_POD_ORD_STG;
   	 	   
  ln_user_id               NUMBER          := NVL(FND_PROFILE.VALUE('USER_ID'), -1);
  ln_login_id              NUMBER          := NVL(FND_PROFILE.VALUE('LOGIN_ID'),-1);
  ln_batch_size            NUMBER          := NVL(FND_PROFILE.VALUE('XX_AR_EBL_POD_BATCH_SIZE'),2500);
  ln_pod_request_id        NUMBER;
  ln_conc_request_id       NUMBER          := NVL(FND_GLOBAL.CONC_REQUEST_ID,-1);
  lc_error_message         VARCHAR2(3600)  := NULL;
  lc_user_exception_msg    VARCHAR2(3600)  := NULL;
  lc_name                  VARCHAR2(2000)  := NULL;
  ln_count                 NUMBER          := 0;
  ln_error_chk_cnt         NUMBER          := 0;
  le_insert_error          EXCEPTION;
  le_wallet_location_error EXCEPTION;
  le_dts_srvc_cred_error   EXCEPTION;
  le_dts_srvc_url_error    EXCEPTION;
  lc_req_data              VARCHAR2(30);
  ln_request_id            NUMBER;
  ln_chd_req_cnt           NUMBER          := 0;
  
BEGIN
  --Get value of global variable. It is null initially.
  lc_req_data   := fnd_conc_global.request_data;
   
 -- If equals to 'END', exit the program with return code '0'. 
  IF lc_req_data ='END' THEN
      RETURN;
  END IF;
  
  FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
  FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
  BEGIN
    BEGIN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.xx_ar_ebl_pod_ord_stg';
    EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.log,'Exception in Truncate statement: ' || SQLERRM);
    END;
	
	INSERT INTO xx_ar_ebl_pod_ord_stg
  		    (customer_trx_id ,
			order_number    ,
			order_number_param   ,
			order_header_id ,
			account_name ,
			cust_account_id ,
			batch_id,
			request_id,
			created_by,
			creation_date,
			last_updated_by,
			last_update_date,
			last_update_login)
		   (SELECT RCT.customer_trx_id ,
				   RCT.trx_number,
				   SUBSTR(RCT.trx_number,1, LENGTH(RCT.trx_number)-3)
				   ||'-'
				   ||SUBSTR(RCT.trx_number, -3),
				   RCT.attribute14 ,
				   'ebiz' account_name,
				   HCP.cust_account_id cust_account_id,
				   CEIL(ROWNUM/ln_batch_size),
				   ln_conc_request_id,
				   ln_user_id,
				   SYSDATE ,
				   ln_user_id ,
				   SYSDATE ,
				   ln_login_id
			  FROM ra_customer_trx RCT,
				   hz_customer_profiles HCP,
				   (SELECT DISTINCT cust_account_id
                               FROM xx_cdh_cust_acct_ext_b
                              WHERE c_ext_attr16            = 'COMPLETE'
                                AND d_ext_attr1              <= TRUNC(SYSDATE)
                                AND NVL(d_ext_attr2,SYSDATE) >= TRUNC(SYSDATE)
                                AND c_ext_attr2               = 'Y'
                   ) PAYDOC_CUST
			 WHERE 1 = 1
			   AND RCT.complete_flag = 'Y'
			   AND (RCT.attribute15 IS NULL
				OR RCT.attribute15   <> 'P')
			   AND HCP.site_use_id  IS NULL
			   AND HCP.status        = 'A'
			   AND HCP.attribute6   IN ('Y','P')
			   AND HCP.cust_account_id = RCT.bill_to_customer_id
			   AND PAYDOC_CUST.cust_account_id = HCP.cust_account_id
			   AND NOT EXISTS
				  (SELECT 1
					 FROM xx_ar_ebl_pod_dtl XAEPD
					WHERE XAEPD.customer_trx_id   = RCT.customer_trx_id
				   )
		    );
  COMMIT;
  
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception while inserting data into the staging table: '||SQLERRM);
  END;  
  
  FOR fetch_elig_trans_rec IN lcu_eligible_trans
  LOOP
    ln_request_id   :=  fnd_request.submit_request 
	                                (application      => 'xxfin',
                                     program          => 'XXAREBLPODCHILD',
                                     sub_request      => TRUE,
                                     argument1        => fetch_elig_trans_rec.batch_id
                                    );					 
    IF ln_request_id <> 0 THEN
       fnd_file.put_line(fnd_file.log,'Successfully submitted request ' || ln_request_id);
	   ln_chd_req_cnt := ln_chd_req_cnt + 1;
	   COMMIT;
    ELSE
       fnd_file.put_line(fnd_file.log,'Error while submitting request ' || fnd_message.get);
    END IF;
  END LOOP;
  
  IF ln_chd_req_cnt  > 0 THEN
	-- Set parent program status as 'PAUSED' and set global variable value to 'END'   
	fnd_conc_global.set_req_globals(conc_status => 'PAUSED'
									,request_data => 'END');
  ELSE
    FND_FILE.PUT_LINE(FND_FILE.LOG,'No records to process.');
    RETURN;
  END IF;
 
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception in the parent program ' || sqlerrm);
  x_retcode := 2;
END POD_EXTRACT;
--+===============================================================================================+
---|    Name : POPULATE_POD_ERRORS                                                              |
---|    Description    : The POPULATE_POD_ERRORS proc will perform the following                |
---|                                                                                            |
---|                    1. Populate the errors for response code 200 with no POD                |
---|                    2. Populate the non-200 response codes with errors as appropriate       |
---|                                                                                            |
---|    Parameters :                                                                            |
--+=============================================================================================+
PROCEDURE POPULATE_POD_ERRORS
  (
    p_response_data   IN CLOB,
    p_response_code   IN NUMBER,
    p_error_message   IN VARCHAR2,
    p_user_exception  IN VARCHAR2,
    p_order_number    IN VARCHAR2,
    p_customer_trx_id IN NUMBER,
    p_cust_acc_name   IN VARCHAR2,
    p_transaction_id  IN VARCHAR2,
    p_request_id      IN NUMBER,
    p_user_id         IN NUMBER
  )
AS
BEGIN
    INSERT
    INTO xx_ar_ebl_pod_errors
      (
        pod_error_request_id,
        response_data,
        consumer_name,
        consumertransactionid,
        order_number,
        customer_trx_id,
        response_status_code ,
        response_error_msg ,
        response_exception_msg ,
        request_id,
        created_by,
        creation_date,
        last_updated_by,
        last_update_date
      )
      VALUES
      (
        xx_ar_ebl_pod_errors_s.NEXTVAL,
        p_response_data ,
        p_cust_acc_name,
        p_transaction_id,
        p_order_number,
        p_customer_trx_id,
        p_response_code,
        p_error_message, 
        p_user_exception,
        p_request_id,
        p_user_id,
        SYSDATE ,
        p_user_id ,
        SYSDATE
      );
EXCEPTION
WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error during insert into xx_ar_ebl_pod_errors for order_number : '||p_order_number ||' and error is: '||SQLERRM);
END POPULATE_POD_ERRORS;
--+=============================================================================================+
---|    Name : CONVERT_CLOB_TO_BLOB                                                             |
---|    Description    : The CONVERT_CLOB_TO_BLOB function will perform the following           |
---|                                                                                            |
---|                    1. This function will take the proofOfDelivery from JSON response       |
---|                       as an input and convert it into a blob image.                        |
---|                                                                                            |
---|    Parameters :                                                                            |
--+=============================================================================================+
PROCEDURE CONVERT_CLOB_TO_BLOB
  (
    p_pod_clob_resp    IN CLOB,
	p_pod_blob        OUT BLOB,
	p_user_exception  OUT VARCHAR2
  ) 
IS
    ln_offset INTEGER;
    lc_buffer_varchar VARCHAR2(32000);
    lc_buffer_raw RAW(32000);
    ln_buffer_size BINARY_INTEGER := 32000;
BEGIN
--
  IF p_pod_clob_resp IS NULL THEN
    p_user_exception := 'POD Clob is empty.';
  ELSE
-- 
    DBMS_LOB.CREATETEMPORARY(p_pod_blob, TRUE);
    ln_offset := 1;
    FOR i IN 1..CEIL(DBMS_LOB.GETLENGTH(p_pod_clob_resp) / ln_buffer_size)
    LOOP
      DBMS_LOB.READ(p_pod_clob_resp, ln_buffer_size, ln_offset, lc_buffer_varchar);
      lc_buffer_raw := UTL_ENCODE.BASE64_DECODE(UTL_RAW.CAST_TO_RAW(lc_buffer_varchar));
      DBMS_LOB.WRITEAPPEND(p_pod_blob, UTL_RAW.LENGTH(lc_buffer_raw), lc_buffer_raw);
      ln_offset := ln_offset + ln_buffer_size;
    END LOOP;
  --RETURN lc_blob;
  END IF;
EXCEPTION
WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error during converting POD Clob to Blob and error is: '||SQLERRM);
	p_user_exception := 'Error: Converting POD Clob to Blob. '||SQLERRM;
    p_pod_blob := EMPTY_BLOB;
END CONVERT_CLOB_TO_BLOB;
--+=============================================================================================+
---|    Name : POD_EXTRACT_CHILD                                                                |
---|    Description    : The POD_EXTRACT_CHILD function will perform the following              |
---|                                                                                            |
---|                    1. This procedure will process child programs for batches               |
---|                                                                                            |
---|    Parameters :                                                                            |
--+=============================================================================================+
PROCEDURE POD_EXTRACT_CHILD
  (
    x_errbuf   OUT NOCOPY  VARCHAR2,
    x_retcode  OUT NOCOPY NUMBER, 
	p_batch_id IN NUMBER	
  ) 
IS
  CURSOR lcu_eligible_trans_child(ln_batch_id NUMBER)
  IS
    SELECT customer_trx_id,
           order_number,
           order_number_param,
           order_header_id,
           account_name,
		   cust_account_id
	  FROM XX_AR_EBL_POD_ORD_STG
	 WHERE batch_id = ln_batch_id;
	 
  lc_request               UTL_HTTP.REQ;
  lc_response              UTL_HTTP.RESP;
  ln_batch_id              NUMBER := 0;
  lc_buff                  VARCHAR2(10000);
  lc_clob_buff             CLOB;
  lc_pod_response          CLOB;
  lc_pod_blob_image        BLOB;
  lc_dts_srv_url_trnsln    VARCHAR2(32000) := NULL;
  lc_dts_service_url       VARCHAR2(32000) := NULL;
  lc_username              VARCHAR2(60)    := NULL;
  lc_password              VARCHAR2(60)    := NULL;
  ln_subscription_id       NUMBER          := 0;
  lc_param                 VARCHAR2(500)   := NULL;
  lc_wallet_location       VARCHAR2(256)   := NULL;
  lc_password_auth         VARCHAR2(256)   := NULL;
  ln_user_id               NUMBER          := NVL(FND_PROFILE.VALUE('USER_ID'), -1);
  ln_login_id              NUMBER          := NVL(FND_PROFILE.VALUE('LOGIN_ID'),-1);
  ln_pod_request_id        NUMBER;
  ln_conc_request_id       NUMBER          := NVL(FND_GLOBAL.CONC_REQUEST_ID,-1);
  lc_order_status          VARCHAR2(30)    := NULL;
  lc_error_message         VARCHAR2(3600)  := NULL;
  lc_user_exception_msg    VARCHAR2(3600)  := NULL;
  lc_name                  VARCHAR2(2000)  := NULL;
  ln_count                 NUMBER          := 0;
  ln_error_chk_cnt         NUMBER          := 0;
  le_insert_error          EXCEPTION;
  le_wallet_location_error EXCEPTION;
  le_dts_srvc_cred_error   EXCEPTION;
  le_dts_srvc_url_error    EXCEPTION;
  lc_transaction_code      VARCHAR2(60)    := 'c66f342d-98da';
	
BEGIN
  --FND_FILE.PUT_LINE(FND_FILE.LOG,'Fetching Wallet Location from translation XX_FIN_IREC_TOKEN_PARAMS ');
  BEGIN
    SELECT target_value1 ,
           target_value2
      INTO lc_wallet_location ,
           lc_password_auth
      FROM xx_fin_translatevalues XFT,
           xx_fin_translatedefinition XFTD
     WHERE 1=1
       AND XFTD.translate_id    = XFT.translate_id
       AND XFTD.translation_name='XX_FIN_IREC_TOKEN_PARAMS'
       AND XFT.source_value1    = 'WALLET_LOCATION'
       AND XFT.enabled_flag     = 'Y'
       AND SYSDATE BETWEEN XFT.start_date_active AND NVL(XFT.end_date_active, SYSDATE+1);
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception while fetching the wallet location from translation XX_FIN_IREC_TOKEN_PARAMS: '||SQLERRM);
    lc_wallet_location := NULL;
    lc_password_auth   := NULL;
    RAISE le_wallet_location_error;
  END;
  
  FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_wallet_location: '||lc_wallet_location);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_password: '||lc_password_auth);
  
  
  BEGIN
    UTL_HTTP.SET_WALLET(lc_wallet_location,lc_password_auth);
    /* request that exceptions are raised for error Status Codes */
    UTL_HTTP.SET_RESPONSE_ERROR_CHECK ( enable => true );
    /* allow testing for exceptions like UTL_HTTP.Http_Server_Error */
    UTL_HTTP.SET_DETAILED_EXCP_SUPPORT ( enable => true );
  EXCEPTION
  WHEN UTL_HTTP.BAD_URL THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error while setting the wallet location : Bad URL : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
    RAISE le_wallet_location_error;
  WHEN UTL_HTTP.BAD_ARGUMENT THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error while setting the wallet location : Bad Argument : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
    RAISE le_wallet_location_error;
  WHEN UTL_HTTP.HTTP_CLIENT_ERROR THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error while setting the wallet location : HTTP Client Error : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
    RAISE le_wallet_location_error;
  WHEN UTL_HTTP.HTTP_SERVER_ERROR THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error while setting the wallet location : HTTP Server Error : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
    RAISE le_wallet_location_error;
  WHEN UTL_HTTP.ILLEGAL_CALL THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error while setting the wallet location : Illegal Call : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
    RAISE le_wallet_location_error;
  WHEN UTL_HTTP.INIT_FAILED THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error while setting the wallet location : Init Failed : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
    RAISE le_wallet_location_error;
  WHEN UTL_HTTP.PROTOCOL_ERROR THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error while setting the wallet location : Protocol Error : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
    RAISE le_wallet_location_error;
  WHEN UTL_HTTP.REQUEST_FAILED THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error while setting the wallet location : Request Failed : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
    RAISE le_wallet_location_error;
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error while setting the wallet location   : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
    RAISE le_wallet_location_error;
  END;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Fetching login credentials from translation XX_AR_EBL_REST_SERVICE_DT ');
  BEGIN	
    SELECT target_value1 ,
           target_value2 ,
           target_value3
      INTO lc_dts_srv_url_trnsln,
           lc_username ,
           lc_password
      FROM xx_fin_translatevalues XFT,
           xx_fin_translatedefinition XFTD
     WHERE 1=1
       AND XFTD.translate_id    = XFT.translate_id
       AND XFTD.translation_name='XX_AR_EBL_REST_SERVICE_DT'
       AND XFT.source_value1    = 'DTS_REST_SERVICE'
       AND XFT.enabled_flag     = 'Y'
       AND SYSDATE BETWEEN XFT.start_date_active AND NVL(XFT.end_date_active, SYSDATE+1);
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception while fetching the details from translation XX_AR_EBL_REST_SERVICE_DT: '||SQLERRM);
	lc_dts_srv_url_trnsln := NULL;
    lc_username      := NULL;
    lc_password      := NULL;
	RAISE le_dts_srvc_cred_error;
  END;
  
  FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_dts_srv_url_trnsln: '||lc_dts_srv_url_trnsln);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_username: '||lc_username);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_password: '||lc_password_auth);
  
  ln_batch_id := p_batch_id;
  FOR fetch_elig_trans_rec IN lcu_eligible_trans_child(ln_batch_id)
  LOOP
    --Setting the parameters
    ln_pod_request_id     := NULL;
	lc_error_message      := NULL;
	lc_user_exception_msg := NULL;
    lc_param              := NULL;
	lc_order_status       := NULL;
	ln_error_chk_cnt      := 0;
	lc_pod_response       := EMPTY_CLOB;
	lc_pod_blob_image     := EMPTY_BLOB;
    lc_param              := CHR(063)||'orderNumber='||fetch_elig_trans_rec.order_number_param||CHR(038)||'consumerName=ebiz'||CHR(038)||'transactionID=c66f342d-98da';
    lc_dts_service_url    := lc_dts_srv_url_trnsln || lc_param;
	ln_count              := ln_count+1;
    BEGIN
	    BEGIN
		  --Setting of http headers 
		  lc_request := UTL_HTTP.BEGIN_REQUEST(lc_dts_service_url, 'GET',' HTTP/1.1');
		  UTL_HTTP.SET_HEADER(lc_request, 'content-type', 'application/json');
		  UTL_HTTP.SET_HEADER(lc_request, 'Authorization', 'Basic ' || UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_ENCODE(UTL_RAW.CAST_TO_RAW(lc_username||':'||lc_password))));
		  lc_response := UTL_HTTP.GET_RESPONSE(lc_request);
		  COMMIT;
		EXCEPTION
		WHEN UTL_HTTP.BAD_URL THEN
		  UTL_HTTP.END_RESPONSE(lc_response);
		  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error while setting the DTS http request : Bad URL : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
		  lc_user_exception_msg := 'BAD_URL:'||UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM;
		  RAISE le_dts_srvc_url_error;
		WHEN UTL_HTTP.BAD_ARGUMENT THEN
		  UTL_HTTP.end_response(lc_response);
		  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error while setting the DTS http request : Bad Argument : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
		  lc_user_exception_msg := 'BAD_ARGUMENT:'||UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM;
		  RAISE le_dts_srvc_url_error;
		WHEN UTL_HTTP.HTTP_CLIENT_ERROR THEN
		  UTL_HTTP.END_RESPONSE(lc_response);
		  FND_FILE.PUT_LINE(FND_FILE.LOG,' Error while setting the DTS http request : HTTP Client Error : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
		  lc_user_exception_msg := 'HTTP_CLIENT_ERROR:'||UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM;
		  RAISE le_dts_srvc_url_error;
		WHEN UTL_HTTP.HTTP_SERVER_ERROR THEN
		  UTL_HTTP.END_RESPONSE(lc_response);
		  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error while setting the DTS http request : HTTP Server Error : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
		  lc_user_exception_msg := 'HTTP_SERVER_ERROR:'||UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM;
		  RAISE le_dts_srvc_url_error;
		WHEN UTL_HTTP.ILLEGAL_CALL THEN
		  UTL_HTTP.END_RESPONSE(lc_response);
		  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error while setting the DTS http request : Illegal Call : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
		  lc_user_exception_msg := 'ILLEGAL_CALL:'||UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM;
		  RAISE le_dts_srvc_url_error;
		WHEN UTL_HTTP.INIT_FAILED THEN
		  UTL_HTTP.END_RESPONSE(lc_response);
		  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error while setting the DTS http request : Init Failed : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
		  lc_user_exception_msg := 'INIT_FAILED:'||UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM;
		  RAISE le_dts_srvc_url_error;
		WHEN UTL_HTTP.PROTOCOL_ERROR THEN
		  UTL_HTTP.END_RESPONSE(lc_response);
		  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error while setting the DTS http request : Protocol Error : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
		  lc_user_exception_msg := 'PROTOCOL_ERROR:'||UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM;
		  RAISE le_dts_srvc_url_error;
		WHEN UTL_HTTP.REQUEST_FAILED THEN
		  UTL_HTTP.END_RESPONSE(lc_response);
		  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Error while setting the DTS http request : Request Failed : ' || UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM);
		  lc_user_exception_msg := 'REQUEST_FAILED:'||UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM;
		  RAISE le_dts_srvc_url_error;
		WHEN OTHERS THEN
		  UTL_HTTP.END_RESPONSE(lc_response);
		  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while setting the DTS http request : '||SQLERRM);
		  lc_user_exception_msg := 'Other Error:'||UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM;
		  RAISE le_dts_srvc_url_error;
		END;
		IF lc_response.status_code = 200 THEN 
		  BEGIN
			-- Reading the JSON response
			BEGIN
			  lc_clob_buff := EMPTY_CLOB;
			  LOOP
				UTL_HTTP.read_text(lc_response, lc_buff, LENGTH(lc_buff));
				lc_clob_buff := lc_clob_buff || lc_buff;
			  END LOOP;
			  UTL_HTTP.END_RESPONSE(lc_response);
			EXCEPTION
			WHEN UTL_HTTP.END_OF_BODY THEN
			  UTL_HTTP.END_RESPONSE(lc_response);
			WHEN OTHERS THEN
			  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception raised while reading response text: '||SQLERRM);
			  UTL_HTTP.END_RESPONSE(lc_response);
			  lc_user_exception_msg := 'Exception raised while reading response text: '||SQLERRM;
			  RAISE le_insert_error;
			END;
			BEGIN
			  SELECT xx_ar_ebl_pod_int_s.NEXTVAL 
				INTO ln_pod_request_id 
				FROM DUAL;
			EXCEPTION
			WHEN NO_DATA_FOUND THEN
			  FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data fetched for xx_ar_ebl_pod_int_s.NEXTVAL :  '||SQLERRM);
			  RAISE le_insert_error;
			WHEN OTHERS THEN
			  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error during fetching the sequence xx_ar_ebl_pod_int_s : '||SQLERRM);
			  RAISE le_insert_error;
			END;
			BEGIN
			  INSERT
			  INTO xx_ar_ebl_pod_int
				(
				  pod_request_id,
				  response_data,
				  consumer_name,
				  cust_account_id,
				  consumertransactionid,
				  order_number,
				  customer_trx_id,
				  request_id,
				  created_by,
				  creation_date,
				  last_updated_by,
				  last_update_date,
				  last_update_login
				)
				VALUES
				(
				  ln_pod_request_id,
				  lc_clob_buff ,
				  fetch_elig_trans_rec.account_name,
				  fetch_elig_trans_rec.cust_account_id,
				  lc_transaction_code,
				  fetch_elig_trans_rec.order_number,
				  fetch_elig_trans_rec.customer_trx_id,
				  ln_conc_request_id,
				  ln_user_id,
				  SYSDATE ,
				  ln_user_id ,
				  SYSDATE ,
				  ln_login_id
				);
			EXCEPTION
			WHEN OTHERS THEN
			  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error during insert into XX_AR_EBL_POD_INT : '||SQLERRM);
			  lc_user_exception_msg := 'Error while inserting data into XX_AR_EBL_POD_INT table ';
			  RAISE le_insert_error;
			END;
			
			BEGIN
			  SELECT xaepi.response_data.getOrderShipmentStatusResponse.orderShipmentStatus.ErrorMessage,
					 --xaepi.response_data.getOrderShipmentStatusResponse.orderShipmentStatus.proofOfDelivery,
					 REGEXP_SUBSTR(xaepi.response_data, '\s*"*(proofOfDelivery)"*\s*:\s*"(.*)"', 1, 1, 'im', 2),
					 xaepi.response_data.getOrderShipmentStatusResponse.orderShipmentStatus.shipmentStatus.statusCode
				INTO lc_error_message,
					 lc_pod_response,
					 lc_order_status
				FROM xx_ar_ebl_pod_int xaepi
			   WHERE pod_request_id = ln_pod_request_id;
			EXCEPTION
			WHEN NO_DATA_FOUND THEN
			  FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found while fetching the Error Message and POD info from Clob : '||SQLERRM);
			  lc_user_exception_msg := 'No Data Found while fetching the Error Message and POD info from Clob ';
			  RAISE le_insert_error;
			WHEN OTHERS THEN
			  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while fetching the Error Message and POD info from Clob : '||SQLERRM);
			  lc_user_exception_msg := 'Error while fetching the Error Message and POD info from Clob ';
			  RAISE le_insert_error;
			END;
			
			IF lc_order_status IN ('50', '51', '52', '07' ) OR (lc_order_status = '02' AND lc_pod_response != EMPTY_CLOB) THEN
			  
			  IF lc_pod_response != EMPTY_CLOB THEN 
				 convert_clob_to_blob(lc_pod_response,lc_pod_blob_image,lc_user_exception_msg);
			  ELSE
				 lc_pod_blob_image := NULL;
			  END IF;

			  BEGIN
				INSERT
				INTO xx_ar_ebl_pod_dtl
				  (
					pod_request_id,
					order_header_id,
					customer_trx_id,
					cust_account_id,
					shipment_status_code,
					shipment_status_desc,
					region_number,
					route_id,
					carrier_name,
					delivery_date,
					comments,
					consignee,
					destination,
					carton_id,
					tracking_number,
					shipping_event_status,
					shipping_time,
					pod_image,
					error_message,
					request_id,
					created_by,
					creation_date,
					last_updated_by,
					last_update_date,
					last_update_login
				  )
				  (SELECT pod_request_id,
						  fetch_elig_trans_rec.order_header_id,
						  fetch_elig_trans_rec.customer_trx_id,
						  fetch_elig_trans_rec.cust_account_id,
						  xaepi.response_data.getOrderShipmentStatusResponse.orderShipmentStatus.shipmentStatus.statusCode,
						  xaepi.response_data.getOrderShipmentStatusResponse.orderShipmentStatus.shipmentStatus.statusDescription,
						  xaepi.response_data.getOrderShipmentStatusResponse.orderShipmentStatus.regionNumber,
						  xaepi.response_data.getOrderShipmentStatusResponse.orderShipmentStatus.routeID,
						  xaepi.response_data.getOrderShipmentStatusResponse.orderShipmentStatus.carrierName,
						  cast( to_timestamp_tz(xaepi.response_data.getOrderShipmentStatusResponse.orderShipmentStatus.deliveryDate,'YYYY-MM-DD"T"HH24:MI:SS.FF3TZR') as date),
						  xaepi.response_data.getOrderShipmentStatusResponse.orderShipmentStatus.comments,
						  xaepi.response_data.getOrderShipmentStatusResponse.orderShipmentStatus.consignee,
						  xaepi.response_data.getOrderShipmentStatusResponse.orderShipmentStatus.destination,
						  REGEXP_SUBSTR(xaepi.response_data, '\s*"*(cartonid)"*\s*:\s*"(.*)"', 1, 1, 'im', 2),
						  REGEXP_SUBSTR(xaepi.response_data, '\s*"*(trackingNumber)"*\s*:\s*"(.*)"', 1, 1, 'im', 2),
						  REGEXP_SUBSTR(xaepi.response_data, '\s*"*(shippingEventStatus)"*\s*:\s*"(.*)"', 1, 1, 'im', 2),
						  TO_DATE(SUBSTR(REGEXP_SUBSTR(xaepi.response_data, '\s*"*(shippingEventTime)"*\s*:\s*"(.*)"', 1, 1, 'im', 2),1,10),'yyyy-mm-dd'),
						  lc_pod_blob_image,
						  xaepi.response_data.getOrderShipmentStatusResponse.orderShipmentStatus.ErrorMessage,
						  ln_conc_request_id,
						  ln_user_id,
						  SYSDATE ,
						  ln_user_id,
						  SYSDATE,
						  ln_login_id
					 FROM XX_AR_EBL_POD_INT xaepi
					WHERE pod_request_id = ln_pod_request_id
				  );
			  EXCEPTION
			  WHEN OTHERS THEN
				FND_FILE.PUT_LINE(FND_FILE.LOG,'Error during insert into XX_AR_EBL_POD_DTL : '||SQLERRM ||' for Order:' ||fetch_elig_trans_rec.order_number);
				lc_user_exception_msg := 'Error while inserting data into XX_AR_EBL_POD_DTL table ';
				RAISE le_insert_error;
			  END;
			ELSE
			  populate_pod_errors( lc_clob_buff, 
								   lc_response.status_code, 
								   lc_error_message, 
								   'POD not available yet', 
								   fetch_elig_trans_rec.order_number, 
								   fetch_elig_trans_rec.customer_trx_id , 
								   fetch_elig_trans_rec.account_name, 
								   lc_transaction_code , 
								   ln_conc_request_id, 
								   ln_user_id 
								  );
			END IF;
		  EXCEPTION
		  WHEN le_insert_error THEN
			populate_pod_errors( lc_clob_buff, 
								 lc_response.status_code, 
								 lc_error_message, 
								 lc_user_exception_msg , 
								 fetch_elig_trans_rec.order_number , 
								 fetch_elig_trans_rec.customer_trx_id , 
								 fetch_elig_trans_rec.account_name, 
								 lc_transaction_code , 
								 ln_conc_request_id, 
								 ln_user_id );
		  END;
		ELSE
		  /* Capturing the non-valid responses in the error table */
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Response : '||lc_response.status_code ||' for Order: '||fetch_elig_trans_rec.order_number);
		  lc_user_exception_msg := 'Non 200 response. Response : '||lc_response.status_code;
		  BEGIN
			lc_clob_buff := EMPTY_CLOB;
			LOOP
			  UTL_HTTP.READ_TEXT(lc_response, lc_buff, LENGTH(lc_buff));
			  lc_clob_buff := lc_clob_buff || lc_buff;
			END LOOP;
			UTL_HTTP.END_RESPONSE(lc_response);
		  EXCEPTION
		  WHEN UTL_HTTP.END_OF_BODY THEN
			UTL_HTTP.END_RESPONSE(lc_response);
		  WHEN OTHERS THEN
			FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception raised while reading text when response status code is non 200: '||SQLERRM);
			UTL_HTTP.END_RESPONSE(lc_response);
		  END;
		  IF lc_response.status_code    = 500 THEN
			lc_user_exception_msg      := 'The server has encountered a situation it doesnt know how to handle.';
		  ELSIF lc_response.status_code = 202 THEN
			lc_user_exception_msg      := 'The request has been received but not yet acted upon.';
		  END IF;
		  BEGIN
			populate_pod_errors( lc_clob_buff, 
								 lc_response.status_code, 
								 lc_error_message, 
								 lc_user_exception_msg, 
								 fetch_elig_trans_rec.order_number , 
								 fetch_elig_trans_rec.customer_trx_id , 
								 fetch_elig_trans_rec.account_name, 
								 lc_transaction_code , 
								 ln_conc_request_id, 
								 ln_user_id );
		  EXCEPTION
		  WHEN OTHERS THEN
			FND_FILE.PUT_LINE(FND_FILE.LOG,'Error during call of populate_pod_errors for order number: '||fetch_elig_trans_rec.order_number||'.Error is: '||SQLERRM);
		  END;
		END IF;
	EXCEPTION
	WHEN le_dts_srvc_url_error THEN
	 populate_pod_errors( NULL, lc_response.status_code, UTL_HTTP.GET_DETAILED_SQLCODE || UTL_HTTP.GET_DETAILED_SQLERRM, lc_user_exception_msg , fetch_elig_trans_rec.order_number , fetch_elig_trans_rec.customer_trx_id , fetch_elig_trans_rec.account_name, lc_transaction_code , ln_conc_request_id, ln_user_id ); 
    END;
  END LOOP;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total orders for which POD was attempted :'||ln_count);
  COMMIT;
  BEGIN
    DELETE FROM xx_ar_ebl_pod_int
	  WHERE pod_request_id NOT IN (SELECT pod_request_id 
	                                 FROM xx_ar_ebl_pod_dtl 
									WHERE request_id =ln_conc_request_id )
	    AND request_id =ln_conc_request_id;
	
    FND_FILE.PUT_LINE(FND_FILE.LOG,'No of records deleted.' || SQL%ROWCOUNT);	
	COMMIT;	
  EXCEPTION
  WHEN OTHERS THEN
	FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception while deleting records from the XX_AR_EBL_POD_INT table.' || sqlerrm);
  END;
EXCEPTION
WHEN le_wallet_location_error THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_wallet_location: '||lc_wallet_location);
     FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_password: '||lc_password_auth);
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Wallet Location is not set. No further processing.');
     x_retcode := 2;
WHEN le_dts_srvc_cred_error THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'DTS webservice access credentials not available. No further processing.');
     FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_username: '||lc_username);
     FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_password: '||lc_password_auth);    
     x_retcode := 2;
WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error during processing child request: '||SQLERRM);
END POD_EXTRACT_CHILD;
  --+=============================================================================================+
  ---|    Name : DISPLAY_INVOICE_NUMBER                                                           |
  ---|    Description    : The DISPLAY_INVOICE_NUMBER function will perform the following         |
  ---|                                                                                            |
  ---|                    1. This function will take the Invoice Number from ra_customer_trx_all  |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+
  FUNCTION DISPLAY_INVOICE_NUM(
    p_customer_trx_id IN NUMBER
	)
	RETURN VARCHAR2
	AS
    lc_invoice_number VARCHAR2(50) := NULL;
  BEGIN
    
   SELECT RCT.trx_number
     INTO lc_invoice_number
     FROM xx_ar_ebl_pod_dtl XAEPD,
	      ra_customer_trx_all RCT
    WHERE XAEPD.customer_trx_id = p_customer_trx_id
	  AND RCT.customer_trx_id = XAEPD.customer_trx_id;
	RETURN lc_invoice_number;  
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found while fetching the Error Message and POD info from Clob : '||SQLERRM);
      lc_invoice_number := NULL;
	  RETURN lc_invoice_number;
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while fetching the Error Message and POD info from Clob : '||SQLERRM);
      lc_invoice_number := NULL;
	  RETURN lc_invoice_number;    
   END DISPLAY_INVOICE_NUM;
---+=============================================================================================+
---|    Name : DISPLAY_POD                                                                      |
---|    Description    : The DISPLAY_POD function will perform the following                    |
---|                                                                                            |
---|                    1. This function will take the proofOfDelivery from JSON response       |
---|                       as an input and convert it into a blob image.                        |                 
---|                                                                                            |
---|    Parameters :                                                                            |
--+=============================================================================================+
FUNCTION DISPLAY_POD(
    p_customer_trx_id IN NUMBER,
	p_cust_doc_id 	  IN NUMBER
	)
 RETURN CLOB
	AS
    lc_pod_response CLOB := EMPTY_CLOB;
 BEGIN
	 SELECT --XAEPI.response_data.getOrderShipmentStatusResponse.orderShipmentStatus.proofOfDelivery
	        REGEXP_SUBSTR(xaepi.response_data, '\s*"*(proofOfDelivery)"*\s*:\s*"(.*)"', 1, 1, 'im', 2)
	   INTO lc_pod_response
	   FROM xx_ar_ebl_pod_int XAEPI,
			hz_customer_profiles HCP
	  WHERE XAEPI.customer_trx_id = p_customer_trx_id 
	    AND HCP.site_use_id  IS NULL
	    AND HCP.status        = 'A'
	    AND HCP.attribute6 in ('Y','P')
	    AND HCP.cust_account_id = XAEPI.cust_account_id
	    AND xx_ar_ebl_pod_invoices_pkg.get_pay_doc_flag(p_cust_doc_id) = 'Y'; --condition to check paydoc
	RETURN lc_pod_response;
EXCEPTION
WHEN NO_DATA_FOUND THEN
	  FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found while fetching the Error Message and POD info from Clob : '||SQLERRM);
	  lc_pod_response := NULL;
	  RETURN lc_pod_response;
WHEN OTHERS THEN
	  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while fetching the Error Message and POD info from Clob : '||SQLERRM);
	  lc_pod_response  := NULL;
	  RETURN lc_pod_response;    
END DISPLAY_POD;
  --+=============================================================================================+
  ---|    Name : DISPLAY_POD_CONSIGNEE                                                            |
  ---|    Description    : The DISPLAY_POD_CONSIGNEE function will perform the following          |
  ---|                                                                                            |
  ---|                    1. This function will take the proofOfDelivery from JSON response       |
  ---|                       as an input and convert it into a blob image.                        |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+
FUNCTION DISPLAY_POD_CONSIGNEE(
    p_customer_trx_id IN NUMBER,
	p_cust_doc_id 	  IN NUMBER)
    RETURN VARCHAR2
	AS
    lc_pod_consignee VARCHAR2(64) := NULL;
BEGIN
    
    SELECT XAEPD.consignee
      INTO lc_pod_consignee
      FROM xx_ar_ebl_pod_dtl XAEPD, 
	       hz_customer_profiles HCP
     WHERE XAEPD.customer_trx_id = p_customer_trx_id
       AND HCP.site_use_id        IS NULL
       AND HCP.status              = 'A'
       AND HCP.attribute6         IN ('Y','P')
       AND HCP.cust_account_id     = XAEPD.cust_account_id
	   AND xx_ar_ebl_pod_invoices_pkg.get_pay_doc_flag(p_cust_doc_id) = 'Y'; --condition to check paydoc
	  
    RETURN lc_pod_consignee;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found while fetching the Error Message and POD consignee info from Clob : '||SQLERRM);
  lc_pod_consignee := NULL;
  RETURN lc_pod_consignee;
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while fetching the Error Message and POD consignee info from Clob : '||SQLERRM);
  lc_pod_consignee := NULL;
  RETURN lc_pod_consignee;
    
END DISPLAY_POD_CONSIGNEE;
  --+=============================================================================================+
  ---|    Name : DISPLAY_POD_SHIP_STATUS                                                          |
  ---|    Description    : The DISPLAY_POD_STATUSDESC function will perform the following         |
  ---|                                                                                            |
  ---|                    1. This function will take the proofOfDelivery from JSON response       |
  ---|                       as an input and convert it into a blob image.                        |               
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+
FUNCTION DISPLAY_POD_SHIP_STATUS(
    p_customer_trx_id IN NUMBER,
	p_cust_doc_id 	  IN NUMBER )
    RETURN VARCHAR2
	AS
    lc_pod_ship_status VARCHAR2(60) := NULL;
BEGIN
    SELECT XAEPD.shipment_status_desc
      INTO lc_pod_ship_status
      FROM xx_ar_ebl_pod_dtl XAEPD, 
	       hz_customer_profiles HCP
     WHERE XAEPD.customer_trx_id = p_customer_trx_id
       AND HCP.site_use_id        IS NULL
       AND HCP.status              = 'A'
       AND HCP.attribute6         IN ('Y','P')
       AND HCP.cust_account_id     = XAEPD.cust_account_id
	   AND xx_ar_ebl_pod_invoices_pkg.get_pay_doc_flag(p_cust_doc_id) = 'Y'; --condition to check paydoc
	   
	RETURN lc_pod_ship_status;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found while fetching the POD Shipment status description info from Clob : '||SQLERRM);
  lc_pod_ship_status := NULL;
  RETURN lc_pod_ship_status;
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while fetching the POD Shipment status description info from Clob : '||SQLERRM);
  lc_pod_ship_status := NULL;
   RETURN lc_pod_ship_status;
   
END DISPLAY_POD_SHIP_STATUS;
  --+=============================================================================================+
  ---|    Name : DISPLAY_POD_DELIVERY_DATE                                                        |
  ---|    Description    : The DISPLAY_POD_STATUSDESC function will perform the following         |
  ---|                                                                                            |
  ---|                    1. This function will take the proofOfDelivery from JSON response       |
  ---|                       as an input and convert it into a blob image.                        |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+
FUNCTION DISPLAY_POD_DELIVERY_DATE(
    p_customer_trx_id IN NUMBER,
	p_cust_doc_id 	  IN NUMBER   )
    RETURN DATE
	AS
    lc_pod_delivery_date DATE := NULL;
BEGIN
    
   SELECT XAEPD.delivery_date
     INTO lc_pod_delivery_date
     FROM xx_ar_ebl_pod_dtl XAEPD, 
	      hz_customer_profiles HCP
    WHERE XAEPD.customer_trx_id = p_customer_trx_id
      AND HCP.site_use_id        IS NULL
      AND HCP.status              = 'A'
      AND HCP.attribute6         IN ('Y','P')
      AND HCP.cust_account_id     = XAEPD.cust_account_id
	  AND xx_ar_ebl_pod_invoices_pkg.get_pay_doc_flag(p_cust_doc_id) = 'Y'; --condition to check paydoc
	  
	RETURN lc_pod_delivery_date;  
EXCEPTION
WHEN NO_DATA_FOUND THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found while fetching the Error Message and POD info from Clob : '||SQLERRM);
  lc_pod_delivery_date := NULL;
  RETURN lc_pod_delivery_date;
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while fetching the Error Message and POD info from Clob : '||SQLERRM);
  lc_pod_delivery_date := NULL;
  RETURN lc_pod_delivery_date;
    
END DISPLAY_POD_DELIVERY_DATE;
  --+=============================================================================================+
  ---|    Name : CHECK_POD                                                                        |
  ---|    Description    : The CHECK_POD function will perform the following                      |
  ---|                                                                                            |
  ---|                    1. This function is to check whether the given customer is pod customer |
  ---|                       or not.                                                              |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+
 FUNCTION CHECK_POD(
    p_cust_account_id IN NUMBER )
    RETURN NUMBER
	AS	
	ln_pod_cnt NUMBER :=0; 
	BEGIN	
	 ln_pod_cnt := 0;				
		SELECT COUNT(1) 
		  INTO ln_pod_cnt
		  FROM hz_customer_profiles HCP
		 WHERE HCP.cust_account_id = p_cust_account_id	
		   AND HCP.site_use_id        IS NULL
		   AND HCP.status              = 'A'
		   AND HCP.attribute6         IN ('Y','P');
		   
		   RETURN(ln_pod_cnt);		   
	EXCEPTION	
	WHEN OTHERS	THEN
	FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while returning ln_pod_cnt in CHECK_POD : '||SQLERRM);
	ln_pod_cnt := 0;
	RETURN(ln_pod_cnt);
	END CHECK_POD;
  
  --+=============================================================================================+
  ---|    Name : GET_POD_MSG                                                                        |
  ---|    Description    : The MSG function will perform the following                            |
  ---|                                                                                            |
  ---|                    1. This function is to check whether the  will get message for POD      |
  ---|                       or not.                                                              |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+	
  
  
  FUNCTION GET_POD_MSG (p_cust_account_id IN NUMBER , p_customer_trx_id IN NUMBER , p_cust_doc_id IN NUMBER )   
    RETURN VARCHAR2 
    As	
    lc_pod_blurb_msg VARCHAR2(1000):= NULL;
    ln_pod_cnt       NUMBER :=0; 
	ln_pod_tab_cnt   NUMBER :=0; 
	ln_pay_doc       NUMBER :=0; 
	Begin	
      
	 ln_pod_cnt      := 0;	
	 ln_pod_tab_cnt	 := 0;
	 ln_pay_doc      := 0; 
		
		SELECT COUNT(1) 
		INTO ln_pod_cnt
		FROM hz_customer_profiles HCP
		WHERE HCP.cust_account_id = p_cust_account_id	
		AND HCP.site_use_id        IS NULL
		AND Hcp.Status              = 'A'
		AND HCP.attribute6         IN ('Y','P');
		   
		   
		SELECT COUNT(1)
		INTO ln_pod_tab_cnt
		FROM Xx_Ar_Ebl_Pod_Dtl
		WHERE 1                   =1
		AND Customer_Trx_Id       = p_customer_trx_id
		AND( Pod_Image           IS NOT NULL
		OR Delivery_Date         IS NOT NULL		
		OR consignee             IS NOT NULL); 	   
		
		
		SELECT COUNT(1)
		INTO ln_pay_doc
		FROM xx_cdh_cust_acct_ext_b
		WHERE n_ext_attr2 = p_cust_doc_id
		AND c_ext_attr2 = 'Y' 
		AND c_ext_attr16 = 'COMPLETE';
		
		  
    IF ln_pod_cnt >= 1 AND ln_pod_tab_cnt = 0 AND ln_pay_doc = 1 THEN 
	    lc_pod_blurb_msg:= 'Delivery Details Not Available.';
    ELSE 
     lc_pod_blurb_msg := NULL;
    END IF;
    

	RETURN(lc_pod_blurb_msg);		   
   
	EXCEPTION	
	WHEN OTHERS	THEN
	Fnd_File.Put_Line(Fnd_File.Log,'Error while returning l_pod_blurb_msg in GET_POD_MSG : '||Sqlerrm);
	lc_pod_blurb_msg := NULL;
	RETURN(lc_pod_blurb_msg);
  
  END GET_POD_MSG;
  
  --+=============================================================================================+
  ---|    Name : getbase64String                                                                  |
  ---|    Description    : The MSG function will perform the following                            |
  ---|                                                                                            |
  ---|                    1. This function is to check whether the  will get message for POD      |
  ---|                       or not.                                                              |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+	
  
  --RDF reports function 
  FUNCTION getbase64String(
      p_blob BLOB )
    RETURN CLOB
  IS
    l_result CLOB;
  BEGIN
    dbms_lob.createtemporary(lob_loc => l_result, CACHE => FALSE, dur => 0);
    wf_mail_util.encodeblob ( p_blob, l_result);
    RETURN ( l_result );
   EXCEPTION	
	WHEN OTHERS	THEN
	Fnd_File.Put_Line(Fnd_File.Log,'Error while returning getbase64String in POD image : '||Sqlerrm);
	l_result := NULL;
	RETURN(l_result);	
  END getbase64String;
  
 --+=============================================================================================+
  ---|    Name : GET_PAY_DOC_FLAG                                                                        |
  ---|    Description    : The MSG function will perform the following                            |
  ---|                                                                                            |
  ---|                    1. This function is to check whether the  will get message for POD      |
  ---|                       or not.                                                              |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+	  
  
FUNCTION GET_PAY_DOC_FLAG (p_cust_doc_id IN NUMBER )     
RETURN VARCHAR2 
IS 
ln_pay_doc       NUMBER      :=  0;
lc_paydoc_flag   VARCHAR2(1) := 'N';
BEGIN 

      SELECT COUNT(1)
		INTO ln_pay_doc
		FROM xx_cdh_cust_acct_ext_b
	   WHERE n_ext_attr2 = p_cust_doc_id
		 AND c_ext_attr2 = 'Y' 
		 AND c_ext_attr16 = 'COMPLETE';
		
		IF ln_pay_doc = 1 THEN 
		lc_paydoc_flag := 'Y'; 
		ELSE 
        lc_paydoc_flag := 'N'; 
		END IF;
		
		RETURN(lc_paydoc_flag);
		
EXCEPTION WHEN OTHERS THEN 
Fnd_File.Put_Line(Fnd_File.Log,'Error while returning l_pod_blurb_msg in GET_PAY_DOC_FLAG : '||Sqlerrm);
	lc_paydoc_flag := 'N'; 
	RETURN(lc_paydoc_flag);
END; 

--+=============================================================================================+
  ---|    Name : RESIZE_IMAGE                                                                 	  |
  ---|    Description    : The resize_image function will perform the following               	  |
  ---|                                                                                            |
  ---|                    This function is to check whether POD image larger size  and it will    |
  -- | 					 resize pod image 														  |
  ---|                       		                                                              |                 
  ---|                                                                                            |
  ---|    Parameters :   p_customer_trx_id                                                        |
  --+=============================================================================================+	
FUNCTION RESIZE_IMAGE (p_customer_trx_id IN NUMBER)
   RETURN BLOB
IS
l_imagedata     BLOB;
l_sizedimage    BLOB;

BEGIN

  SELECT pod_image
    INTO l_imagedata
    FROM XX_AR_EBL_POD_DTL
   WHERE customer_trx_id = p_customer_trx_id
     AND LENGTH(pod_image) > 12000;
		 
  DBMS_LOB.CREATETEMPORARY(l_sizedimage, FALSE, DBMS_LOB.CALL);

  ORDSYS.ORDIMAGE.PROCESSCOPY(l_imagedata, 'maxScale=115 115', l_sizedimage);

  RETURN l_sizedimage;
  
EXCEPTION 
WHEN OTHERS THEN
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while returning re size image in RESIZE_IMAGE : '||SQLERRM);
 l_sizedimage:=NULL;
 RETURN (l_sizedimage);
END RESIZE_IMAGE;

 
END XX_AR_EBL_POD_INVOICES_PKG;
/
SHOW ERRORS;