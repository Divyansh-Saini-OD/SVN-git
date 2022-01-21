CREATE OR REPLACE
PACKAGE BODY XX_IBY_PAYMENT_ADAPTER_PUB AS
/* $Header: ibyppadb.pls 115.120 2005/10/14 22:07:27 rameshsh ship $ */


     -- *** Declaring global datatypes and variables ***
     G_PKG_NAME CONSTANT VARCHAR2(30) := 'IBY_PAYMENT_ADAPTER_PUB';

     g_validation_level CONSTANT NUMBER  := FND_API.G_VALID_LEVEL_FULL;


------------------------------------------------------------------------------------
   /* UTILITY PROCEDURE #1: UNPACK_RESULTS_URL
      PARSER Procedure to take in given l_string in html file format,
      parse l_string, and store the Name-Value pairs in l_names and l_values.
      For example, if OapfPrice Name-Value pairs exist in l_string, it would be
      stored as l_names(i) := 'OapfPrice' and l_values(i) := '17.00'.

      NOTE: This procedure logic is exactly similar to the iPayment 3i version
            of procedure with minor enhancements and bug fixes.
   */
------------------------------------------------------------------------------------
   PROCEDURE unpack_results_url(p_string     IN  VARCHAR2,
                                x_names      OUT NOCOPY v240_tbl_type,
                                x_values     OUT NOCOPY v240_tbl_type,
                                x_status     OUT NOCOPY NUMBER,
                                x_errcode    OUT NOCOPY NUMBER,
                                x_errmessage OUT NOCOPY VARCHAR2
                                ) IS

    l_length    NUMBER(15)    := LENGTH(p_string) + 1;
    l_count     NUMBER(15)    := 0;
    l_index     NUMBER(15)    := 1;
    l_char      VARCHAR2(1)    := '';
    l_word      VARCHAR2(2400)  := '';
    l_name      BOOLEAN       := TRUE;
    l_local_nls VARCHAR2(200);
    l_remote_nls VARCHAR2(200);
   BEGIN

     iby_debug_pub.add(debug_msg => 'Enter', debug_level => FND_LOG.LEVEL_PROCEDURE,
          module => G_DEBUG_MODULE || '.unpack_results');

     -- Initialize status, errcode, errmessage to Success.
     x_status := 0;
     x_errcode := 0;
     x_errmessage := 'Success';

     l_local_nls := iby_utility_pvt.get_local_nls();

     -- verify what HTTP response format is returned by the server
     -- NOTE: Since ECServlet is not supposed to return in this format,
     -- this condition should not be encountered.
     l_count := instr(p_string,'</H2>');
     IF l_count > 0 THEN
        l_count := l_count + 5;
     END IF;

     --Fixing Bug from OM: 1104438
     --Suggested improvement to this: Search for the first alphanumeric
     --character [a-zA-Z0-9] encountered in this string.set l_count to that position.
     l_count := INSTR(p_string, 'Oapf');
     --End of Bug Fix 1104438

     WHILE l_count < l_length LOOP

        IF (l_name) AND (substr(p_string,l_count,1) = ':') THEN

           x_names(l_index) := substr( (ltrim(rtrim(l_word))), 1, 240 );
           l_name := FALSE;
           l_word := '';
           l_count := l_count + 1;
        
        ELSIF (l_name) THEN

           l_char := substr(p_string,l_count,1);
           l_word := l_word||l_char;
           l_count := l_count + 1;
        ELSIF upper(substr(p_string,l_count,4)) = '<BR>' THEN

           x_values(l_index) := substr( (ltrim(rtrim(l_word))), 1, 240 );
	   --
	   -- remember the NLS Lang parameter for below decoding
	   IF (x_names(l_index) = 'OapfNlsLang') THEN

		l_remote_nls := x_values(l_index);
	   END IF;

           l_name := TRUE;
           l_word := '';
           l_index := l_index + 1;
           l_count := l_count + 4;
        ELSE
           l_char := substr(p_string,l_count,1);
           l_word := l_word||l_char;
           l_count := l_count + 1;
        END IF;

        /*--Note: Can Add this to extra ensure that
        --additional white spaces get trimmed.
        x_names(l_count) := LTRIM(RTRIM(x_names(l_count) ));
        x_values(l_count) := LTRIM(RTRIM(x_values(l_count) )); */

     END LOOP;

     -- do URL decoding if on the output values if possible
     --

     --dbms_output.put_line('unpack::local nls: ' || l_local_nls);
     --dbms_output.put_line('unpack::remote nls: ' || l_remote_nls);

     /*
     IF ((l_remote_nls IS NOT NULL) AND (l_local_nls IS NOT NULL)) THEN
	FOR i in 1..x_values.COUNT LOOP
	   x_values(i) := iby_netutils_pvt.decode_url_chars(x_values(i),l_local_nls,l_remote_nls);
	END LOOP;
     END IF;
    */

     iby_debug_pub.add(debug_msg => 'Exit', debug_level => FND_LOG.LEVEL_PROCEDURE,
          module => G_DEBUG_MODULE || '.unpack_results');

   EXCEPTION
      WHEN OTHERS THEN
         /* Return a status of -1 to the calling API to indicate
            errors in unpacking html body results.  */
         --dbms_output.put_line('error in unpacking procedure');
     	 x_status := -1;
         x_errcode := to_char(SQLCODE);
         x_errmessage := SQLERRM;
   END unpack_results_url;


   /* UTILITY PROCEDURE #1.4: TRXN_STATUS_SUCCESS

      Returns true if and only if the given transaction
      status indicates a success.

    */
   FUNCTION trxn_status_success( p_trxn_status NUMBER )
   RETURN BOOLEAN
   IS
   BEGIN
	IF (p_trxn_status IS NULL) THEN
	  iby_debug_pub.add(debug_msg => 'ECApp servlet trxn status is NULL!',
              debug_level => FND_LOG.LEVEL_UNEXPECTED,
              module => G_DEBUG_MODULE || '.trxn_status_success');
	  RETURN FALSE;
	ELSIF ((XX_IBY_PAYMENT_ADAPTER_PUB.C_TRXN_STATUS_SUCCESS = p_trxn_status) OR
               (XX_IBY_PAYMENT_ADAPTER_PUB.C_TRXN_STATUS_INFO = p_trxn_status) OR
               (XX_IBY_PAYMENT_ADAPTER_PUB.C_TRXN_STATUS_WARNING = p_trxn_status)
              )
        THEN
	  RETURN TRUE;
	ELSE
	  RETURN FALSE;
	END IF;
   END trxn_status_success;

--------------------------------------------------------------------------------------------
   /* UTILITY PROCEDURE #2: CHECK_MANDATORY
      Procedure to take in given URL string: p_url,
                                     name-value pair strings: p_name, p_value
      Check if p_value is NOT NULL. If not NULL, then append p_name=p_value to p_url.
      If p_value is NULL, then an exception is raised and passed to the
      calling program.
      NOTE: This procedure checks only for MANDATORY INPUT parameters.
      Decision on which should be mandatory is decided by the business logic.

      NLS ARGS (used to encode the parameters that go into the URL):

	    p_local_nls -  the NLS value of the local system (as pulled
                            from DB)
            p_remote_nls - the NLS value for the remote system

   */
--------------------------------------------------------------------------------------------
  PROCEDURE check_mandatory (p_name    IN     VARCHAR2,
                             p_value   IN     VARCHAR2,
                             p_url     IN OUT NOCOPY VARCHAR2,
			     p_local_nls IN VARCHAR2 DEFAULT NULL,
			     p_remote_nls IN VARCHAR2 DEFAULT NULL
                             ) IS
    l_url VARCHAR2(2000) := p_url;
  BEGIN
    /* Logic:
    1. Check if value is null. if null, then raise exception to pass to ECApp;
    3. If not null, then append to URL.
    */

    IF (p_value is NULL) THEN
       --Note: Reused an existing IBY message and token.
       FND_MESSAGE.SET_NAME('IBY', 'IBY_0004');
       FND_MESSAGE.SET_TOKEN('FIELD', p_name);
       FND_MSG_PUB.Add;

       -- jleybovi [10/24/00]
       --
       -- should return an expected error exception here as missing input is
       -- considered a "normal" error
       --
       --RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
       RAISE FND_API.G_EXC_ERROR;
    ELSE
       --Append this <name>=<value> to the input URL
       p_url := p_url||p_name||'='||
                iby_netutils_pvt.escape_url_chars(p_value,p_local_nls,p_remote_nls)||'&';
    END IF;

--    ??? who installed the exception catch below???
--    keep it for the time being as it allows a better error message, code
--    to be returned than by aborting within PL/SQL
--      [jlebovi 11/29/2001]
  EXCEPTION
/*
    WHEN iby_netutils_pvt.encoding_error THEN
      --
      -- catch any of the conversion errors that may
      -- have occured here
      --
      FND_MESSAGE.SET_NAME('IBY', 'IBY_204011');
      FND_MESSAGE.SET_TOKEN('FIELD', 'NLS_LANG');
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
*/
    WHEN OTHERS THEN
      p_url := l_url;

  END check_mandatory;
--------------------------------------------------------------------------------------------
   /* UTILITY PROCEDURE #3: CHECK_OPTIONAL
      Procedure to take in given URL string: p_url,
                                     name-value pair strings: p_name, p_value
      Check if p_value is NOT NULL, If NOT NULL, append p_name=p_value to p_url.
      Otherwise, if p_value is NULL, then p_url is unchanged.
      NOTE: This procedure checks only for OPTIONAL INPUT parameters and does not
      validate MANDATORY INPUT parameters.

      NLS ARGS (used to encode the parameters that go into the URL):

	    p_local_nls -  the NLS value of the local system (as pulled
                            from DB)
            p_remote_nls - the NLS value for the remote system

   */
--------------------------------------------------------------------------------------------
  PROCEDURE check_optional (p_name  IN     VARCHAR2,
                            p_value IN     VARCHAR2,
                            p_url   IN OUT NOCOPY VARCHAR2,
			    p_local_nls IN VARCHAR2 DEFAULT NULL,
			    p_remote_nls IN VARCHAR2 DEFAULT NULL
                            ) IS
    l_url VARCHAR2(2000) := p_url;
  BEGIN

    /* Logic:
    1. check value if null.
       if null then don't do anything.
    2. If not null, then append to URL.
    */

    IF (p_value IS NULL) THEN
       p_url := l_url;
    ELSE
       --Append this <name>=<value> to the input URL
       p_url := p_url||p_name||'='||
                iby_netutils_pvt.escape_url_chars(p_value,p_local_nls,p_remote_nls)||'&';
    END IF;

  EXCEPTION
/*
    WHEN iby_netutils_pvt.encoding_error THEN
      --
      -- catch any of the conversion errors that may
      -- have occured here
      --
      FND_MESSAGE.SET_NAME('IBY', 'IBY_204011');
      FND_MESSAGE.SET_TOKEN('FIELD', 'NLS_LANG');
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
*/
    WHEN OTHERS THEN
      p_url := l_url;

  END check_optional;
--------------------------------------------------------------------------------------------
   /* UTILITY PROCEDURE #4: SHOW_INPUT_DEBUG
      Procedure to take in given Final Input URL string (p_string)
      and print out the string in chunks.
   */
--------------------------------------------------------------------------------------------
  PROCEDURE show_input_debug (p_string IN VARCHAR2) IS
    j NUMBER := 0;
  BEGIN
    -- Use For Debugging
    --dbms_output.put_line('---------------------');
    --dbms_output.put_line('FINAL INPUT URL IS : ');
    --dbms_output.put_line('---------------------');
    j := 0;
    WHILE ( j < (length(p_string) + 1) )
    LOOP
     --dbms_output.put('   ');
     --dbms_output.put(substr(p_string,1+(90*j),90) );
     --dbms_output.new_line;
       j := j+1;
    END LOOP;
    --dbms_output.put_line('---------------------');

  EXCEPTION
    WHEN OTHERS THEN
      --dbms_output.put_line('Error in displaying debug strings output: procedure show_input_debug');
      NULL;
  END show_input_debug;
--------------------------------------------------------------------------------------------
   /* UTILITY PROCEDURE #5: SHOW_OUTPUT_DEBUG
      Procedure to take in given HTML body response string (p_string)
      and print out the string in chunks.
   */
--------------------------------------------------------------------------------------------
  PROCEDURE show_output_debug (p_string IN VARCHAR2) IS
    j NUMBER := 0;
  BEGIN
    -- Use For Debugging
    -- dbms_output.put_line('---------------------');
    -- dbms_output.put_line('HTML BODY RESPONSE STRING IS : ');
    -- dbms_output.put_line('---------------------');
    j := 0;
    WHILE ( j < (length(p_string) + 1) )
    LOOP
       -- dbms_output.put('   ');
       -- dbms_output.put(substr(p_string,1+(90*j),90) );
       -- dbms_output.new_line;
       j := j+1;
    END LOOP;
    -- dbms_output.put_line('---------------------');

  EXCEPTION
    WHEN OTHERS THEN
      --dbms_output.put_line('Error in displaying input URL output: Procedure show_output_debug');
      NULL;
  END show_output_debug;
--------------------------------------------------------------------------------------------
   /* UTILITY PROCEDURE #5: SHOW_OUTPUT_DEBUG
      Procedure to take in given HTML body response string (p_string)
      and print out long strings in smaller chunks to
      bypass buffer size constraints.
   */
--------------------------------------------------------------------------------------------
  PROCEDURE show_table_debug (p_table IN v240_tbl_type) IS
    i NUMBER := 0;
  BEGIN
     --Use For Debugging
     --dbms_output.put_line('Table Count = '||to_char(p_table.COUNT) );
     FOR i IN 1..p_table.COUNT
     LOOP
        --dbms_output.put('   ');
        --dbms_output.put_line('Element.'||to_char(i)||' = '||p_table(i) );
        NULL;
     END LOOP;
     --dbms_output.put_line('---------------------');
  EXCEPTION
    WHEN OTHERS THEN
      --dbms_output.put_line('Error in displaying table output: Procedure show_table_debug');
      NULL;
  END show_table_debug;
--------------------------------------------------------------------------------------------
   /* UTILITY FUNCTION #1: IS_RISKINFO_REC_MISSING
      Function to check if the optional/missing parameter RiskInfo_rec
      has been passed or not in the OraPmtReq API.
   */
--------------------------------------------------------------------------------------------
  FUNCTION Is_RiskInfo_rec_Missing (riskinfo_rec IN Riskinfo_rec_type)
  RETURN BOOLEAN IS
  BEGIN
    IF (riskinfo_rec.Formula_Name <> FND_API.G_MISS_CHAR) THEN
       RETURN FALSE;
    ELSIF (riskinfo_rec.ShipToBillTo_Flag <> FND_API.G_MISS_CHAR) THEN
       RETURN FALSE;
    ELSIF (riskinfo_rec.Time_Of_Purchase  <> FND_API.G_MISS_CHAR) THEN
       RETURN FALSE;
    ELSIF (riskinfo_rec.Customer_Acct_Num <> FND_API.G_MISS_CHAR) THEN
       RETURN FALSE;
    -- ELSIF (riskinfo_rec.Org_ID  <> FND_API.G_MISS_NUM) THEN
    --   RETURN FALSE;
    ELSE
       RETURN TRUE;
    END IF;
  END Is_RiskInfo_rec_Missing;


--------------------------------------------------------------------------------------------
   /* UTILITY FUNCTION #1: cipher_url
      Removes sensitive data (e.g. credit card #'s) from the
      given ECAPP URL string before it is written to log.
   */
--------------------------------------------------------------------------------------------
  FUNCTION cipher_url (p_url IN VARCHAR2)
  RETURN VARCHAR
  IS
        l_name_start NUMBER;
        l_val_start NUMBER;
        l_val_end NUMBER;
  BEGIN
        l_name_start := INSTR(p_url,'OapfPmtInstrID');
        IF (l_name_start <1) THEN
          RETURN p_url;
        END IF;

        l_val_start := INSTR(p_url,'=',l_name_start);
        IF (l_val_start <1) THEN
          RETURN p_url;
        END IF;

        l_val_end := instr(p_url,'&',l_val_start);
        IF (l_val_end <1) THEN
          l_val_end := length(p_url);
        END IF;

        RETURN substr(p_url,1,l_val_start) || substr(p_url,l_val_end);
  END cipher_url;

--------------------------------------------------------------------------------------------
   /* UTILITY PROCEDURE #6: GET_BASEURL
      Procedure to retrieve the iPayment ECAPP BASE URL
   */
--------------------------------------------------------------------------------------------
  PROCEDURE get_baseurl(x_baseurl OUT NOCOPY VARCHAR2)
  IS
    -- Local variable to hold the property name for the URL.
    p_temp_var       	VARCHAR2(2);

  BEGIN

    iby_debug_pub.add(debug_msg => 'Enter', debug_level => FND_LOG.LEVEL_PROCEDURE,
          module => G_DEBUG_MODULE || '.get_baseurl');

    iby_utility_pvt.get_property(XX_IBY_PAYMENT_ADAPTER_PUB.C_ECAPP_URL_PROP_NAME,x_baseurl);

    --Start of Customization

	SELECT substr(x_baseurl,1,instr(x_baseurl,'/',-1)) ||'oramipp_ods'
    INTO   x_baseurl
    FROM dual;

    --End od Customization

    --dbms_output.put_line('x_return_status = '|| x_return_status);
    --Raising Exception to handle errors if value is missing
      IF ((x_baseurl IS NULL) OR (trim(x_baseurl) = '')) THEN
          FND_MESSAGE.SET_NAME('IBY', 'IBY_204406');
          FND_MSG_PUB.Add;
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;

    --appending '?' if not already present in the url
      p_temp_var := SUBSTR(x_baseurl, -1);

      IF( p_temp_var <> '?' ) THEN
        x_baseurl := x_baseurl || '?';
      END IF;

      iby_debug_pub.add(debug_msg => 'base url=' || x_baseurl,
          debug_level => FND_LOG.LEVEL_STATEMENT,
          module => G_DEBUG_MODULE || '.get_baseurl');

      iby_debug_pub.add(debug_msg => 'Exit',
          debug_level => FND_LOG.LEVEL_PROCEDURE,
          module => G_DEBUG_MODULE || '.get_baseurl');

  END get_baseurl;


--------------------------------------------------------------------------------------------
   /* UTILITY PROCEDURE #7: SEND_REQUEST
      Procedure to call HTTP_UTIL.SEND_REQUEST and handle exceptions thrown by it
   */
--------------------------------------------------------------------------------------------
  PROCEDURE send_request(x_url     IN OUT NOCOPY VARCHAR2,
                         x_htmldoc OUT NOCOPY VARCHAR2
                        ) IS
        l_wallet_location VARCHAR2(3000);
        l_wallet_password VARCHAR2(200);
        l_hash_string VARCHAR2(30000) :='';
        l_sec_cred NUMBER;
        l_index NUMBER := 0;
 BEGIN
	-- Send http request to the payment server.
	iby_debug_pub.add(debug_msg => 'Enter',
          debug_level => FND_LOG.LEVEL_PROCEDURE,
          module => G_DEBUG_MODULE || '.send_request');

	iby_utility_pvt.get_property(iby_security_pkg.C_SHARED_WALLET_LOC_PROP_NAME,l_wallet_location);

        --
        -- using a SSO password-less wallet
        l_wallet_password := NULL;

        IF (NOT (TRIM(l_wallet_location) IS NULL)) THEN
          l_wallet_location := iby_netutils_pvt.path_to_url(l_wallet_location);
        END IF;

	iby_debug_pub.add(debug_msg => 'Input url = '|| cipher_url(x_url),
          debug_level => FND_LOG.LEVEL_STATEMENT,
          module => G_DEBUG_MODULE || '.send_request');

--show_input_debug(cipher_url(x_url));

        l_index := instr(x_url,'?');
        IF ( (l_index>0) AND (l_index<length(x_url)) ) THEN
            l_hash_string := substr(x_url,l_index+1);
            x_url := x_url || '&';
        END IF;

        iby_security_pkg.store_credential(l_hash_string,l_sec_cred);
        x_url := x_url || 'OapfSecurityToken=' || l_sec_cred;

	IF (SUBSTR(x_url,1,6)='https:') THEN
            x_htmldoc := UTL_HTTP.REQUEST(url=>x_url,wallet_path=>l_wallet_location, wallet_password=>l_wallet_password);
	ELSE
            x_htmldoc := UTL_HTTP.REQUEST(x_url);
        END IF;

	iby_debug_pub.add(debug_msg => 'Exit',
          debug_level => FND_LOG.LEVEL_PROCEDURE,
          module => G_DEBUG_MODULE || '.send_request');

--dbms_output.put_line('Input url = '|| x_url);

  EXCEPTION
      WHEN UTL_HTTP.REQUEST_FAILED THEN

--FND_MSG_PUB.Add_Exc_Msg(p_error_text => SQLCODE||':-:'||SQLERRM);
	 FND_MESSAGE.SET_NAME('IBY', 'IBY_0001');
	 FND_MSG_PUB.Add;
         -- x_return_status := 3 ;
         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

  END send_request;
--------------------------------------------------------------------------------------------
                       ---*** APIS START BELOW ---***
--------------------------------------------------------------------------------------------
			--1. OraPmtReq
	-- Start of comments
	--   API name        : OraPmtReq
	--   Type            : Public
	--   Pre-reqs        : None
	--   Function        : Handles new Payment requests from E-Commerce applications.
	--   Parameters      :
	--     IN            : p_api_version       IN    NUMBER              Required
        --  		       p_init_msg_list     IN    VARCHAR2            Optional
        --                     p_commit            IN    VARCHAR2            Optional
        --                     p_validation_level  IN    NUMBER              Optional
        --                     p_ecapp_id          IN    NUMBER              Required
        --                     p_payee_id_rec      IN    Payee_rec_type      Required
        --                     p_payer_id_rec      IN    Payer_rec_type      Optional
        --                     p_pmtinstr_rec      IN    PmtInstr_rec_type   Required
        --                     p_tangible_rec      IN    Tangible_rec_type   Required
        --                     p_pmtreqtrxn_rec    IN    PmtReqTrxn_rec_type Required
        --                     p_riskinfo_rec      IN    RiskInfo_rec_type   Optional
	--   Version :
	--     Current version      1.0
	--     Previous version     1.0
	--     Initial version      1.0
	-- End of comments
--------------------------------------------------------------------------------------------
  PROCEDURE OraPmtReq (	p_api_version		IN	NUMBER,
			p_init_msg_list		IN	VARCHAR2  := FND_API.G_FALSE,
			p_commit		IN	VARCHAR2  := FND_API.G_FALSE,
			p_validation_level	IN	NUMBER  := FND_API.G_VALID_LEVEL_FULL,
			p_ecapp_id 		IN 	NUMBER,
			p_payee_rec 		IN	Payee_rec_type,
			p_payer_rec  	        IN	Payer_rec_type,
			p_pmtinstr_rec 	        IN	PmtInstr_rec_type,
			p_tangible_rec	 	IN	Tangible_rec_type,
			p_pmtreqtrxn_rec 	IN	PmtReqTrxn_rec_type,
			p_riskinfo_rec		IN	RiskInfo_rec_type
						:= XX_IBY_PAYMENT_ADAPTER_PUB.G_MISS_RISKINFO_REC,
			x_return_status		OUT NOCOPY VARCHAR2,
			x_msg_count		OUT NOCOPY NUMBER,
			x_msg_data		OUT NOCOPY VARCHAR2,
			x_reqresp_rec		OUT NOCOPY ReqResp_rec_type
			) IS


        l_get_baseurl   VARCHAR2(2000);
        --The following 3 variables are meant for output of
        --get_baseurl procedure.
        l_status_url    VARCHAR2(2000);
        l_msg_count_url NUMBER := 0;
        l_msg_data_url  VARCHAR2(2000);

        l_api_name      CONSTANT  VARCHAR2(30) := 'OraPmtReq';
        l_oapf_action   CONSTANT  VARCHAR2(30) := 'oraPmtReq';
        l_api_version   CONSTANT  NUMBER := 1.0;

        l_url           VARCHAR2(30000) ;
        l_html          VARCHAR2(30000) ;
        l_names         v240_tbl_type;
        l_values        v240_tbl_type;

        --The following 3 variables are meant for output of
        --unpack_results_url procedure.
        l_status        NUMBER := 0;
        l_errcode       NUMBER := 0;
        l_errmessage    VARCHAR2(2000) := 'Success';

	-- remember if address parameters have been output so that they do not
	-- appear twice
	l_addrinfo_set 	BOOLEAN := FALSE;

	-- for NLS bug fix #1692300 - 4/3/2001 jleybovi
	--
	l_db_nls	p_pmtreqtrxn_rec.NLS_LANG%TYPE := NULL;
	l_ecapp_nls	p_pmtreqtrxn_rec.NLS_LANG%TYPE := NULL;

	v_trxnTimestamp	DATE	:= NULL;

        --Defining a local variable to hold the payment instrument type.
        l_pmtinstr_type VARCHAR2(200);
        CURSOR pmtreq_csr(ci_pmtinstrid NUMBER)
               IS
               SELECT instrtype
               FROM   IBY_INSTR_HOLDER_V
               WHERE  (instrid = ci_pmtinstrid);

  BEGIN

	iby_debug_pub.add(debug_msg => 'Enter',
          debug_level => FND_LOG.LEVEL_PROCEDURE,
          module => G_DEBUG_MODULE || '.OraPmtReq');

        -- Standard Start of API savepoint
        --SAVEPOINT OraPmtReq_PUB;

        /* ***** Performing Validations, Initializations
	         for Standard IN, OUT Parameters ***** */

	-- Standard call to check for call compatibility.
    	IF NOT FND_API.Compatible_API_Call ( l_api_version,
                                             p_api_version,
                                             l_api_name,
                                             G_PKG_NAME )
        THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        -- Initialize message list if p_init_msg_list is set to TRUE.
        IF FND_API.to_Boolean( p_init_msg_list ) THEN
           FND_MSG_PUB.initialize;
        END IF;

        -- Verifying if validation level is FULL, which is expected for PUBLIC APIs.
        IF (p_validation_level <> g_validation_level) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204401_VAL_LEVEL_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --  Initialize API return status to success
        x_return_status := FND_API.G_RET_STS_SUCCESS;

        -- START OF BODY OF API

        get_baseurl(l_get_baseurl);
        -- dbms_output.put_line('l_get_baseurl= ' || l_get_baseurl);
        -- dbms_output.put_line('l_status_url= ' || l_status_url);
        -- dbms_output.put_line('l_msg_count_url= ' || l_msg_count_url);
        -- dbms_output.put_line('l_msg_data_url= ' || l_msg_data_url);

        -- Construct the full URL to send to the ECServlet.
        l_url := l_get_baseurl;

	l_db_nls := iby_utility_pvt.get_local_nls();
	l_ecapp_nls := p_pmtreqtrxn_rec.NLS_LANG;

        -- dbms_output.put_line('db NLS val is: ' || l_db_nls);
        -- dbms_output.put_line('ecapp NLS val is: ' || l_ecapp_nls);

        --MANDATORY INPUT PARAMETERS
        check_mandatory('OapfAction', l_oapf_action, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfECAppId', to_char(p_ecapp_id), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfStoreId', p_payee_rec.Payee_ID, l_url, l_db_nls, l_ecapp_nls);

        -- the mode has to be mandatory as per the specifications
        check_mandatory('OapfMode', p_pmtreqtrxn_rec.PmtMode, l_url, l_db_nls, l_ecapp_nls);

        --Tangible related mandatory input
        check_mandatory('OapfOrderId', p_tangible_rec.Tangible_ID, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfPrice', FND_NUMBER.NUMBER_TO_CANONICAL(p_tangible_rec.Tangible_Amount), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfCurr', p_tangible_rec.Currency_Code, l_url, l_db_nls, l_ecapp_nls);

        --Determine the Payment Instrument type that is used.
        IF (p_pmtinstr_rec.CreditCardInstr.CC_Num IS NOT NULL) THEN
           l_pmtinstr_type := 'CREDITCARD';
        ELSIF (p_pmtinstr_rec.PurchaseCardInstr.PC_Num IS NOT NULL) THEN
           l_pmtinstr_type := 'PURCHASECARD';
	ELSIF ((p_pmtinstr_rec.DualPaymentInstr.PmtInstr_ID IS NOT NULL)) THEN
           -- Dual Payment Instrument found.
	   l_pmtinstr_type := 'DUALPAYMENTINSTR';
        ELSIF ((p_pmtinstr_rec.DebitCardInstr.DC_Num IS NOT NULL) AND
                (p_pmtinstr_rec.DebitCardInstr.DC_SUBTYPE='PINLESS') ) THEN
           -- Pinless Debit Card found.
	   l_pmtinstr_type := 'PINLESSDEBITCARD';

        END IF;
        --ELSIF (p_pmtinstr_rec.BankAcctInstr.BankAcct_Num IS NOT NULL) THEN
        --l_pmtinstr_type := 'BANKACCOUNT';
        --END IF;


        --CONDITIONALLY MANDATORY INPUT PARAMETERS

        --1. Instrument related conditionally mandatory input
        --a. CreditCard instrument related conditionally mandatory input
        IF (l_pmtinstr_type = 'CREDITCARD') THEN

           -- Assign the value for 'OapfPmtInstrType' to 'CREDITCARD' and append to URL.
           check_optional('OapfPmtInstrType', 'CREDITCARD', l_url, l_db_nls, l_ecapp_nls);

           check_mandatory('OapfAuthType', UPPER(p_pmtreqtrxn_rec.Auth_Type), l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrID',
             iby_creditcard_pkg.Get_Secured_Card_Number(p_pmtinstr_rec.CreditCardInstr.CC_Num),
             l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrExp', to_char(p_pmtinstr_rec.CreditCardInstr.CC_ExpDate, 'YYYY-MM-DD'), l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCVV2', p_pmtreqtrxn_rec.CVV2, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCCType', p_pmtinstr_rec.CreditCardInstr.CC_Type, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCustName', p_pmtinstr_rec.CreditCardInstr.CC_HolderName, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfFIName', p_pmtinstr_rec.CreditCardInstr.FIName, l_url, l_db_nls, l_ecapp_nls);

	   check_optional('OapfEmail', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Email, l_url, l_db_nls, l_ecapp_nls);
	   check_optional('OapfPhone', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Phone, l_url, l_db_nls, l_ecapp_nls);

           --Address related Conditional Mandatory Input Parameters
           IF (p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Address1 IS NOT NULL)
           OR (p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.City  IS NOT NULL)
           OR (p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.State IS NOT NULL)
           OR (p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.PostalCode IS NOT NULL) THEN

	      l_addrinfo_set:=TRUE;

              check_optional('OapfAddr1', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Address1, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfCity', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.City, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfState', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.State, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfPostalCode', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.PostalCode, l_url, l_db_nls, l_ecapp_nls);
           END IF;

        --b. PurchaseCard instrument related conditionally mandatory input
        ELSIF (l_pmtinstr_type = 'PURCHASECARD') THEN

           -- Assign the value for 'OapfPmtInstrType' to 'PURCHASECARD' and append to URL.
           check_optional('OapfPmtInstrType', 'PURCHASECARD', l_url, l_db_nls, l_ecapp_nls);

           check_mandatory('OapfAuthType', UPPER(p_pmtreqtrxn_rec.Auth_Type), l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrID',
             iby_creditcard_pkg.Get_Secured_Card_Number(p_pmtinstr_rec.PurchaseCardInstr.PC_Num),
             l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrExp', to_char(p_pmtinstr_rec.PurchaseCardInstr.PC_ExpDate, 'YYYY-MM-DD'), l_url, l_db_nls, l_ecapp_nls);

           check_optional('OapfCVV2', p_pmtreqtrxn_rec.CVV2, l_url, l_db_nls, l_ecapp_nls);

           check_mandatory('OapfCardSubType', p_pmtinstr_rec.PurchaseCardInstr.PC_Subtype, l_url, l_db_nls, l_ecapp_nls);

           check_optional('OapfCCType', p_pmtinstr_rec.PurchaseCardInstr.PC_Type, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCustName', p_pmtinstr_rec.PurchaseCardInstr.PC_HolderName, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfFIName', p_pmtinstr_rec.PurchaseCardInstr.FIName, l_url, l_db_nls, l_ecapp_nls);

	   check_optional('OapfEmail', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Email, l_url, l_db_nls, l_ecapp_nls);
	   check_optional('OapfPhone', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Phone, l_url, l_db_nls, l_ecapp_nls);

           --Address related Conditional Mandatory Input Parameters
           IF (p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Address1 IS NOT NULL)
           OR (p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.City  IS NOT NULL)
           OR (p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.State IS NOT NULL)
           OR (p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.PostalCode IS NOT NULL) THEN

	      l_addrinfo_set:=TRUE;

              check_optional('OapfAddr1', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Address1, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfCity', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.City, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfState', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.State, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfPostalCode', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.PostalCode, l_url, l_db_nls, l_ecapp_nls);
           END IF;

          -- Pinless debit card support
          ELSIF (l_pmtinstr_type = 'PINLESSDEBITCARD') THEN

           -- Assign the value for 'OapfPmtInstrType' to 'PINLESSDEBITCARD' and append to URL.
           check_optional('OapfPmtInstrType', 'PINLESSDEBITCARD', l_url, l_db_nls, l_ecapp_nls);

           check_mandatory('OapfAuthType', UPPER(p_pmtreqtrxn_rec.Auth_Type), l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrID', p_pmtinstr_rec.DebitCardInstr.DC_Num, l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrExp', to_char(p_pmtinstr_rec.DebitCardInstr.DC_ExpDate, 'YYYY-MM-DD'), l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCCType', p_pmtinstr_rec.DebitCardInstr.DC_Type, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCustName', p_pmtinstr_rec.DebitCardInstr.DC_HolderName, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfFIName', p_pmtinstr_rec.DebitCardInstr.FIName, l_url, l_db_nls, l_ecapp_nls);

	   check_optional('OapfEmail', p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.Email, l_url, l_db_nls, l_ecapp_nls);
	   check_optional('OapfPhone', p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.Phone, l_url, l_db_nls, l_ecapp_nls);

           --Address related Conditional Mandatory Input Parameters
           IF (p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.Address1 IS NOT NULL)
           OR (p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.City  IS NOT NULL)
           OR (p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.State IS NOT NULL)
           OR (p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.PostalCode IS NOT NULL) THEN

	      l_addrinfo_set:=TRUE;

              check_optional('OapfAddr1', p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.Address1, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfCity', p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.City, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfState', p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.State, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfPostalCode', p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.PostalCode, l_url, l_db_nls, l_ecapp_nls);
           END IF;

        /* NOT SUPPORTING BANKACCOUNT OPERATION FOR 11i
        ELSIF (l_pmtinstr_type = 'BANKACCOUNT') THEN
           --c. BankAccount instrument related conditionally mandatory input

           -- Assign the value for 'OapfPmtInstrType' to 'BANKACCOUNT' and append to URL.
           check_optional('OapfPmtInstrType', 'BANKACCOUNT', l_url, l_db_nls, l_ecapp_nls);

           check_mandatory('OapfBankId', p_pmtinstr_rec.BankAcctInstr.Bank_ID, l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrID', p_pmtinstr_rec.BankAcctInstr.BankAcct_Num, l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfAcctType', p_pmtinstr_rec.BankAcctInstr.BankAcct_Type, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfBranchId', p_pmtinstr_rec.BankAcctInstr.Branch_ID, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfFIName', p_pmtinstr_rec.BankAcctInstr.FIName, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCustName', p_pmtinstr_rec.BankAcctInstr.BankAcct_HolderName, l_url, l_db_nls, l_ecapp_nls);
         */
         ELSIF (l_pmtinstr_type = 'DUALPAYMENTINSTR') THEN

	   check_mandatory('OapfPmtRegId', to_char(p_pmtinstr_rec.DualPaymentInstr.PmtInstr_ID), l_url, l_db_nls, l_ecapp_nls);
           --Query DB to get the PmtInstrType from Instrument Registration ID, pass to ECServlet.
           OPEN pmtreq_csr(p_pmtinstr_rec.DualPaymentInstr.PmtInstr_ID);
            FETCH pmtreq_csr
             INTO l_pmtinstr_type;


            IF (pmtreq_csr%ROWCOUNT = 0) THEN
              FND_MESSAGE.SET_NAME('IBY', 'IBY_204404_CURSOR_ERROR');
              FND_MSG_PUB.Add;
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            END IF;

            CLOSE pmtreq_csr;
            --dbms_output.put_line('after closing cursor');

           check_mandatory('OapfPmtInstrType', l_pmtinstr_type, l_url, l_db_nls, l_ecapp_nls);

           check_optional('OapfBnfPmtRegId', to_char(p_pmtinstr_rec.DualPaymentInstr.BnfPmtInstr_ID), l_url, l_db_nls, l_ecapp_nls);

           /*
            * These three are used in direct debit transactions
            * sent to some payment sustems (e.g., Citibank).
            */
           check_optional('OapfCustAccountId',
               to_char(p_pmtreqtrxn_rec.CustAccountId),
               l_url, l_db_nls, l_ecapp_nls);

           check_optional('OapfAcctSiteUseId',
               to_char(p_pmtreqtrxn_rec.AcctSiteUseId),
               l_url, l_db_nls, l_ecapp_nls);

           check_optional('OapfAcctSiteId',
               to_char(p_pmtreqtrxn_rec.AcctSiteId),
               l_url, l_db_nls, l_ecapp_nls);

	   IF (p_pmtinstr_rec.DualPaymentInstr.BnfPmtInstr_ID is NOT NULL) THEN
	      -- Fetching Payment Instrument type from database
	      OPEN pmtreq_csr(p_pmtinstr_rec.DualPaymentInstr.BnfPmtInstr_ID);
                FETCH pmtreq_csr
                INTO l_pmtinstr_type;

              IF (pmtreq_csr%ROWCOUNT = 0) THEN
                FND_MESSAGE.SET_NAME('IBY', 'IBY_204404_CURSOR_ERROR');
                FND_MSG_PUB.Add;
                RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
              END IF;
              CLOSE pmtreq_csr;
              --dbms_output.put_line('after closing cursor');

	      check_optional('OapfBnfPmtInstrType', l_pmtinstr_type, l_url, l_db_nls, l_ecapp_nls);

	   END IF;
        ELSE
           --d. REGISTERED INSTRUMENT RELATED CONDITIONALLY MANDATORY INPUT
           check_mandatory('OapfPmtRegId', to_char(p_pmtinstr_rec.PmtInstr_ID), l_url, l_db_nls, l_ecapp_nls);

           --Query DB to get the PmtInstrType from Instrument Registration ID, pass to ECServlet.
             OPEN pmtreq_csr(p_pmtinstr_rec.PmtInstr_ID);
            FETCH pmtreq_csr
             INTO l_pmtinstr_type;

            IF (pmtreq_csr%ROWCOUNT = 0) THEN
              FND_MESSAGE.SET_NAME('IBY', 'IBY_204404_CURSOR_ERROR');
              FND_MSG_PUB.Add;
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            END IF;

            CLOSE pmtreq_csr;

            check_mandatory('OapfPmtInstrType', l_pmtinstr_type, l_url, l_db_nls, l_ecapp_nls);
            IF (( l_pmtinstr_type = 'CREDITCARD')
               OR ( l_pmtinstr_type = 'PURCHASECARD')
               OR (l_pmtinstr_type='PINLESSDEBITCARD'))    THEN
               check_mandatory('OapfAuthType', UPPER(p_pmtreqtrxn_rec.Auth_Type), l_url, l_db_nls, l_ecapp_nls);
            ELSIF (l_pmtinstr_type='BANKACCOUNT') THEN
               -- ACH.  Added to pass the new AuthType VERIFY in the case of ONLINE ACH verification
               check_optional('OapfAuthType', UPPER(p_pmtreqtrxn_rec.Auth_Type), l_url, l_db_nls, l_ecapp_nls);
            END IF;

        END IF;

        --2. Payment Mode related Conditional Mandatory Input Parameters
        IF (p_pmtreqtrxn_rec.PmtMode = 'OFFLINE') THEN
           check_mandatory('OapfSchedDate', to_char(p_pmtreqtrxn_rec.Settlement_Date, 'YYYY-MM-DD'), l_url, l_db_nls, l_ecapp_nls);

           -- Bug #1248563
           --check if CheckFlag is supplied, if not, use 'TRUE' default
           IF p_pmtreqtrxn_rec.Check_Flag IS NULL THEN
              check_optional('OapfCheckFlag', 'TRUE', l_url, l_db_nls, l_ecapp_nls);
           ELSE
              check_optional('OapfCheckFlag', p_pmtreqtrxn_rec.Check_Flag, l_url, l_db_nls, l_ecapp_nls);
           END IF;
           --check_mandatory('OapfCheckFlag', p_pmtreqtrxn_rec.Check_Flag, l_url, l_db_nls, l_ecapp_nls);
           -- End of Bug #1248563
        END IF;

        --3. Address related Conditional Mandatory Input Parameters

	-- there seems to be a bug here as address parameters are appended to the URL twice:
	-- both here and then above when payment instrument specific parameters are output;
	-- perhaps there is a logical reason for this, so instead of removing this section
	-- simply do not enter it if address parameters already added to URL
	--
	-- jleybovi [1/25/2001]
	--
	--
	IF (NOT l_addrinfo_set) THEN

         -- Credit Card
	 --
            check_optional('OapfAddr1', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Address1, l_url, l_db_nls, l_ecapp_nls);
            check_optional('OapfCity', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.City, l_url, l_db_nls, l_ecapp_nls);
            check_optional('OapfState', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.State, l_url, l_db_nls, l_ecapp_nls);
            check_optional('OapfPostalCode', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.PostalCode, l_url, l_db_nls, l_ecapp_nls);

         -- Purchase card
	 --
            check_optional('OapfAddr1', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Address1, l_url, l_db_nls, l_ecapp_nls);
            check_optional('OapfCity', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.City, l_url, l_db_nls, l_ecapp_nls);
            check_optional('OapfState', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.State, l_url, l_db_nls, l_ecapp_nls);
            check_optional('OapfPostalCode', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.PostalCode, l_url, l_db_nls, l_ecapp_nls);

          -- Pinless debit card
              check_optional('OapfAddr1', p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.Address1, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfCity', p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.City, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfState', p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.State, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfPostalCode', p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.PostalCode, l_url, l_db_nls, l_ecapp_nls);

	-- end if for address set switch
	END IF;

        --OPTIONAL INPUT PARAMETERS

        --Instrument related optional input
        check_optional('OapfInstrName', p_pmtinstr_rec.PmtInstr_ShortName, l_url, l_db_nls, l_ecapp_nls);

        --Newly Added for ECServlet requirements (12/16/99)
        check_optional('OapfRetry', p_pmtreqtrxn_rec.Retry_Flag, l_url, l_db_nls, l_ecapp_nls);

	--Add Voice auth flag and AuthCode, if present

-- dbms_output.put_line('p_pmtreqtrxn_rec.VoiceAuthFlag is:'||p_pmtreqtrxn_rec.VoiceAuthFlag);

        IF (NVL(p_pmtreqtrxn_rec.VoiceAuthFlag, 'N') = 'Y') THEN
          check_mandatory('OapfVoiceAuthFlag',
                          p_pmtreqtrxn_rec.VoiceAuthFlag, l_url, l_db_nls, l_ecapp_nls);
          check_mandatory('OapfAuthCode', p_pmtreqtrxn_rec.AuthCode, l_url, l_db_nls, l_ecapp_nls);
-- dbms_output.put_line('include date of voice auth');

          check_mandatory('OapfDateOfVoiceAuth',TO_CHAR(p_pmtreqtrxn_rec.DateOfVoiceAuthorization, 'YYYY-MM-DD'), l_url,
                           l_db_nls, l_ecapp_nls);
        END IF;



        --Tangible related optional input
        check_optional('OapfMemo', p_tangible_rec.Memo, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfAcctNumber', p_tangible_rec.Acct_Num, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfRefNumber', p_tangible_rec.RefInfo, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfOrderMedium', p_tangible_rec.OrderMedium, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfEftAuthMethod', p_tangible_rec.EFTAuthMethod, l_url, l_db_nls, l_ecapp_nls);

        --Payer related optional input
        check_optional('OapfPayerId', p_payer_rec.Payer_ID, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfPayerName', p_payer_rec.Payer_Name, l_url, l_db_nls, l_ecapp_nls);

        IF ( l_pmtinstr_type = 'CREDITCARD') THEN
          check_optional('OapfAddr2',p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Address2, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfAddr3',p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Address3, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfCnty', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.County, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfCntry', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Country, l_url, l_db_nls, l_ecapp_nls);
        ELSIF ( l_pmtinstr_type = 'PURCHASECARD') THEN
          check_optional('OapfAddr2',p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Address2, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfAddr3',p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Address3, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfCnty', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.County, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfCntry', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Country, l_url, l_db_nls, l_ecapp_nls);
       ELSIF (l_pmtinstr_type = 'PINLESSDEBITCARD') THEN
              check_optional('OapfAddr2', p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.Address1, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfAddr3', p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.Address2, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfCnty', p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.County, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfCntry', p_pmtinstr_rec.DebitCardInstr.DC_BillingAddr.Country, l_url, l_db_nls, l_ecapp_nls);
        END IF;

        check_optional('OapfNlsLang', p_pmtreqtrxn_rec.NLS_LANG, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfOrgId', to_char(p_pmtreqtrxn_rec.Org_ID), l_url, l_db_nls, l_ecapp_nls);

        --Purchase Card related optional input
        check_optional('OapfPONum', to_char(p_pmtreqtrxn_rec.PONum), l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfTaxAmount', to_char(p_pmtreqtrxn_rec.TaxAmount), l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfShipToZip', p_pmtreqtrxn_rec.ShipToZip, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfShipFromZip', p_pmtreqtrxn_rec.ShipFromZip, l_url, l_db_nls, l_ecapp_nls);

        -- Optional flag to indicate whether to do risk analysis or not
        check_optional('OapfAnalyzeRisk', p_pmtreqtrxn_rec.AnalyzeRisk, l_url, l_db_nls, l_ecapp_nls);

        -- RISK INFO OBJECT INPUT PARAMETERS

           -- Check all Risk related inputs only if Formula_Name is specified.
           IF (p_riskinfo_rec.Formula_Name <> FND_API.G_MISS_CHAR)
              AND (p_riskinfo_rec.Formula_Name IS NOT NULL) THEN
              check_optional('OapfFormulaName', p_riskinfo_rec.Formula_Name, l_url, l_db_nls, l_ecapp_nls);
           -- check_optional is not checking for FND_API.G_MISS_CHAR
           IF (p_riskinfo_rec.ShipToBillTo_Flag <> FND_API.G_MISS_CHAR)   THEN
              check_optional('OapfShipToBillToFlag', p_riskinfo_rec.ShipToBillTo_Flag, l_url, l_db_nls, l_ecapp_nls);
           END IF;
           -- check_optional is not checking for FND_API.G_MISS_CHAR
           IF (p_riskinfo_rec.Time_Of_Purchase <> FND_API.G_MISS_CHAR)   THEN
              check_optional('OapfTimeOfPurchase', p_riskinfo_rec.Time_Of_Purchase, l_url, l_db_nls, l_ecapp_nls);
           END IF;

              --NOTE: Customer_Acct_Num and Org_ID are together Mandatory
              --if AR risk factors are to be used.
              IF ( (p_riskinfo_rec.Customer_Acct_Num IS NOT NULL)
                    AND (p_riskinfo_rec.Customer_Acct_Num <> FND_API.G_MISS_CHAR) )
                 -- OR ( (p_riskinfo_rec.Org_ID IS NOT NULL)
                 --      AND (p_riskinfo_rec.Org_ID <> FND_API.G_MISS_NUM) )
              THEN
                 -- check_mandatory('OapfOrgId', to_char(p_riskinfo_rec.Org_ID), l_url, l_db_nls, l_ecapp_nls);
                 check_mandatory('OapfCustAccountNum', p_riskinfo_rec.Customer_Acct_Num, l_url, l_db_nls, l_ecapp_nls);
              END IF;
           END IF;

	IF (p_pmtreqtrxn_rec.RetailData.IsRetail='Y') THEN
	  check_optional('OapfIsRetail','true',l_url,l_db_nls,l_ecapp_nls);
	  check_optional('OapfPOSEntryMode',p_pmtreqtrxn_rec.RetailData.POSEntryMode,l_url,l_db_nls,l_ecapp_nls);
	  check_optional('OapfPOSCapability',p_pmtreqtrxn_rec.RetailData.POSCapability,l_url,l_db_nls,l_ecapp_nls);
	  check_optional('OapfPOSAuthSource',p_pmtreqtrxn_rec.RetailData.POSAuthSource,l_url,l_db_nls,l_ecapp_nls);
	  check_optional('OapfPOSCardIdMethod',p_pmtreqtrxn_rec.RetailData.POSCardIdMethod,l_url,l_db_nls,l_ecapp_nls);
	  check_optional('OapfPOSSwipeData',p_pmtreqtrxn_rec.RetailData.POSSwipeData,l_url,l_db_nls,l_ecapp_nls);
	END IF;

        check_optional('OapfTrxnRef', p_pmtreqtrxn_rec.TrxnRef, l_url, l_db_nls, l_ecapp_nls);

        -- Remove ampersand from the last input parameter.
	l_url := RTRIM(l_url,'&');

	-- no longer needed as escape_url_chars() does this
	--
	-- ^^^^ Replace blank characters with + sign.^^^^
	--l_url := REPLACE(l_url,' ','+');

--show_input_debug(l_url);

	-- Send http request to the payment server
	--l_html := UTL_HTTP.REQUEST(l_url);
--dbms_output.put_line('send request ');
--dbms_output.put_line('l_url is:'||substr(l_url,1, 50));

-- dbms_output.put_line('l_html is:'||substr(l_html, 1, 50));
	SEND_REQUEST(l_url, l_html);
        -- show_output_debug(l_html);

	-- Unpack the results
	UNPACK_RESULTS_URL(l_html,l_names,l_values, l_status, l_errcode, l_errmessage);

--show_table_debug(l_names);
--show_table_debug(l_values);

        --Raising Exception to handle errors in unpacking resulting html file.
        IF (l_status = -1) THEN
	   iby_debug_pub.add(debug_msg => 'Unpack status error; HTML resp. invalid!',
              debug_level => FND_LOG.LEVEL_UNEXPECTED,
              module => G_DEBUG_MODULE || '.OraPmtReq');
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204403_HTML_UNPACK_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --Raising Exception to handle Servlet related errors.
        IF (l_names.COUNT = 0) THEN
	   iby_debug_pub.add(debug_msg => 'HTML response names count=0',
              debug_level => FND_LOG.LEVEL_UNEXPECTED,
              module => G_DEBUG_MODULE || '.OraPmtReq');
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204402_JSERVLET_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

	/* Retrieve name-value pairs stored in l_names and l_values, and assign
	   them to the output record: x_reqresp_rec.
	*/

	iby_debug_pub.add(debug_msg => 'Setting fields from unpacked response',
              debug_level => FND_LOG.LEVEL_STATEMENT,
              module => G_DEBUG_MODULE || '.OraPmtReq');


	FOR i IN 1..l_names.COUNT LOOP
            --Payment Server Related Generic Response
	    IF l_names(i) = 'OapfStatus' THEN
	       x_reqresp_rec.Response.Status := TO_NUMBER(l_values(i));
	       iby_debug_pub.add(debug_msg => 'Response status=' || x_reqresp_rec.Response.Status,
                debug_level => FND_LOG.LEVEL_STATEMENT,
                module => G_DEBUG_MODULE || '.OraPmtReq');
	    ELSIF l_names(i) = 'OapfCode' THEN
	       x_reqresp_rec.Response.ErrCode := l_values(i);
	       iby_debug_pub.add(debug_msg => 'Response code=' || x_reqresp_rec.Response.ErrCode,
                debug_level => FND_LOG.LEVEL_STATEMENT,
                module => G_DEBUG_MODULE || '.OraPmtReq');
	    ELSIF l_names(i) = 'OapfCause' THEN
	       x_reqresp_rec.Response.ErrMessage := l_values(i);
	       iby_debug_pub.add(debug_msg => 'Response message=' || x_reqresp_rec.Response.ErrMessage,
                debug_level => FND_LOG.LEVEL_STATEMENT,
                module => G_DEBUG_MODULE || '.OraPmtReq');
	    ELSIF l_names(i) = 'OapfNlsLang' THEN
	       x_reqresp_rec.Response.NLS_LANG := l_values(i);

            --Payment Operation Related Response
	    ELSIF l_names(i) = 'OapfTransactionId' THEN
	       x_reqresp_rec.Trxn_ID := TO_NUMBER(l_values(i));
	    ELSIF l_names(i) = 'OapfTrxnType' THEN
	       x_reqresp_rec.Trxn_Type := TO_NUMBER(l_values(i));
	    ELSIF l_names(i) = 'OapfTrxnDate' THEN
	       x_reqresp_rec.Trxn_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');
	    --
	    -- if timestamp parameter is returned then use it instead of
	    -- the less precise trxn date parameter as some applications
	    -- require it (see bug #1649833)
	    --
	    -- nature of this loop, however, requires it to be stored in a
	    -- local variable and then later put into the response record
	    --
	    -- jleybovi [02/20/2001]
	    --
	    ELSIF l_names(i) = 'OapfTimestamp' THEN
	       v_trxnTimestamp := TO_DATE(l_values(i),'YYYYMMDDHH24MISS');
	    ELSIF l_names(i) = 'OapfAuthcode' THEN
	       x_reqresp_rec.AuthCode := l_values(i);
	    ELSIF l_names(i) = 'OapfAVScode' THEN
	       x_reqresp_rec.AVScode := l_values(i);
            ELSIF l_names(i) = 'OapfCVV2Result' THEN
               x_reqresp_rec.CVV2Result := l_values(i);
	    ELSIF l_names(i) = 'OapfPmtInstrType' THEN
	       x_reqresp_rec.PmtInstr_Type := l_values(i);
	    ELSIF l_names(i) = 'OapfRefcode' THEN
	       x_reqresp_rec.RefCode := l_values(i);
	    ELSIF l_names(i) = 'OapfAcquirer' THEN
	       x_reqresp_rec.Acquirer := l_values(i);
	    ELSIF l_names(i) = 'OapfVpsBatchId' THEN
	       x_reqresp_rec.VpsBatch_ID := l_values(i);
	    ELSIF l_names(i) = 'OapfAuxMsg' THEN
	       x_reqresp_rec.AuxMsg := l_values(i);
	    ELSIF l_names(i) = 'OapfErrLocation' THEN
	       x_reqresp_rec.ErrorLocation := TO_NUMBER(l_values(i));
	    ELSIF l_names(i) = 'OapfVendErrCode' THEN
	       x_reqresp_rec.BEPErrCode := l_values(i);
	    ELSIF l_names(i) = 'OapfVendErrmsg' THEN
	       x_reqresp_rec.BEPErrMessage := l_values(i);

            --OFFLINE Payment Mode Related Response
            ELSIF l_names(i) = 'OapfEarliestSettlementDate' THEN
               x_reqresp_rec.OffLineResp.EarliestSettlement_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');
            ELSIF l_names(i) = 'OapfSchedDate' THEN
               x_reqresp_rec.OffLineResp.Scheduled_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');

            --RISK Related Response
            ELSIF l_names(i) = 'OapfRiskStatus' THEN
               x_reqresp_rec.RiskResponse.Status := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfRiskErrorCode' THEN
              x_reqresp_rec.RiskResponse.ErrCode := l_values(i);
            ELSIF l_names(i) = 'OapfRiskErrorMsg' THEN
              x_reqresp_rec.RiskResponse.ErrMessage := l_values(i);
            ELSIF l_names(i) = 'OapfRiskAdditionalErrorMsg' THEN
              x_reqresp_rec.RiskResponse.Additional_ErrMessage := l_values(i);
            ELSIF l_names(i) = 'OapfRiskScore' THEN
              x_reqresp_rec.RiskResponse.Risk_Score := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfRiskThresholdVal' THEN
              x_reqresp_rec.RiskResponse.Risk_Threshold_Val := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfRiskyFlag' THEN
              x_reqresp_rec.RiskResponse.Risky_Flag := l_values(i);

	    END IF;

            --If there is some risk response, ECApp can look
            --into the riskresp object for risk response details.
            IF (x_reqresp_rec.RiskResponse.Status IS NOT NULL) THEN
               x_reqresp_rec.RiskRespIncluded := 'YES';
            ELSE
               x_reqresp_rec.RiskRespIncluded := 'NO';
            END IF;

	END LOOP;

	-- use the more accurate time stamp parameter if returned
	--
	IF NOT (v_trxnTimestamp IS NULL) THEN
	   x_reqresp_rec.Trxn_Date := v_trxnTimestamp;
	END IF;

        -- Setting API return status to 'U' if iPayment response status is not 0.
        IF (NOT trxn_status_success(x_reqresp_rec.Response.Status)) THEN
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        END IF;

        -- END OF BODY OF API

        -- Use for Debugging
        --dbms_output.put_line('after successfully mapping results');

        -- Standard check of p_commit.
	/*
        IF FND_API.To_Boolean( p_commit ) THEN
           COMMIT WORK;
        END IF;
	*/

        -- Standard call to get message count and if count is 1, get message info.
        FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
			            p_data   =>   x_msg_data
        			  );

	iby_debug_pub.add(debug_msg => 'x_return_status=' || x_return_status,
              debug_level => FND_LOG.LEVEL_STATEMENT,
              module => G_DEBUG_MODULE || '.OraPmtReq');
	iby_debug_pub.add(debug_msg => 'req response status=' || x_reqresp_rec.Response.Status,
              debug_level => FND_LOG.LEVEL_STATEMENT,
              module => G_DEBUG_MODULE || '.OraPmtReq');

	iby_debug_pub.add(debug_msg => 'Exit',
              debug_level => FND_LOG.LEVEL_PROCEDURE,
              module => G_DEBUG_MODULE || '.OraPmtReq');

   EXCEPTION

      WHEN FND_API.G_EXC_ERROR THEN

	iby_debug_pub.add(debug_msg => 'In G_EXC_ERROR Exception',
              debug_level => FND_LOG.LEVEL_ERROR,
              module => G_DEBUG_MODULE || '.OraPmtReq');
         --ROLLBACK TO OraPmtReq_PUB;
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

	iby_debug_pub.add(debug_msg => 'In G_EXC_UNEXPECTED_ERROR Exception',
              debug_level => FND_LOG.LEVEL_UNEXPECTED,
              module => G_DEBUG_MODULE || '.OraPmtReq');
         --ROLLBACK TO OraPmtReq_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN OTHERS THEN

	iby_debug_pub.add(debug_msg => 'In OTHERS Exception',
              debug_level => FND_LOG.LEVEL_UNEXPECTED,
              module => G_DEBUG_MODULE || '.OraPmtReq');
         --ROLLBACK TO OraPmtReq_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_api_name);
         END IF;

         FND_MSG_PUB.Count_And_Get ( p_count  =>  x_msg_count,
                                     p_data   =>  x_msg_data
                                   );

      iby_debug_pub.add(debug_msg => 'x_return_status=' || x_return_status,
              debug_level => FND_LOG.LEVEL_UNEXPECTED,
              module => G_DEBUG_MODULE || '.OraPmtReq');
      iby_debug_pub.add(debug_msg => 'Exit Exception',
              debug_level => FND_LOG.LEVEL_UNEXPECTED,
              module => G_DEBUG_MODULE || '.OraPmtReq');

   END OraPmtReq;

--------------------------------------------------------------------------------------------
				--2. OraPmtMod
        -- Start of comments
        --   API name        : OraPmtMod
        --   Type            : Public
        --   Pre-reqs        : Previous Payment Request.
        --   Function        : Handles Modifications to existing Payment Request
        --                     Transactions in case of Scheduled (OFFLINE) payments.
        --   Parameters      :
        --    IN             : p_api_version       IN    NUMBER              Required
        --                     p_init_msg_list     IN    VARCHAR2            Optional
        --                     p_commit            IN    VARCHAR2            Optional
        --                     p_validation_level  IN    NUMBER              Optional
        --                     p_ecapp_id          IN    NUMBER              Required
        --                     p_payee_id_rec      IN    Payee_rec_type      Required
        --                     p_payer_id_rec      IN    Payer_rec_type      Optional
        --                     p_pmtinstr_rec      IN    PmtInstr_rec_type   Required
        --                     p_tangible_rec      IN    Tangible_rec_type   Required
        --                     p_ModTrxn_rec       IN    ModTrxn_rec_type    Required
        --   Version :
        --      Current version      1.0
        --      Previous version     1.0
        --      Initial version      1.0
        -- End of comments
--------------------------------------------------------------------------------------------
  PROCEDURE OraPmtMod ( p_api_version		IN	NUMBER,
			p_init_msg_list		IN	VARCHAR2  := FND_API.G_FALSE,
			p_commit		IN	VARCHAR2  := FND_API.G_FALSE,
			p_validation_level	IN	NUMBER  := FND_API.G_VALID_LEVEL_FULL,
			p_ecapp_id 		IN 	NUMBER,
			p_payee_rec 		IN	Payee_rec_type,
			p_payer_rec 		IN	Payer_rec_type,
			p_pmtinstr_rec 	        IN	PmtInstr_rec_type,
			p_tangible_rec 		IN	Tangible_rec_type,
			p_ModTrxn_rec 	        IN	ModTrxn_rec_type,
			x_return_status		OUT NOCOPY VARCHAR2,
			x_msg_count		OUT NOCOPY NUMBER,
			x_msg_data		OUT NOCOPY VARCHAR2,
			x_modresp_rec		OUT NOCOPY ModResp_rec_type
		      ) IS

        --l_get_baseurl   VARCHAR2(2000) :=
        --  'http://alchen-sun.us.oracle.com:80/jservlets/11i/oracle.apps.iby.ecservlet.ECServlet?';
        --l_get_baseurl   VARCHAR2(2000) := FND_PROFILE.VALUE('IPAYMENT_BASEURL');

        l_get_baseurl   VARCHAR2(2000);
        --The following 3 variables are meant for output of
        --get_baseurl procedure.
        l_status_url    VARCHAR2(2000);
        l_msg_count_url NUMBER := 0;
        l_msg_data_url  VARCHAR2(2000);

        l_api_name     CONSTANT  VARCHAR2(30) := 'OraPmtMod';
        l_oapf_action  CONSTANT  VARCHAR2(30) := 'oraPmtMod';
        l_api_version  CONSTANT  NUMBER := 1.0;

        TYPE l_v240_tbl IS TABLE of VARCHAR2(240) INDEX BY BINARY_INTEGER;
        l_url           VARCHAR2(4000) ;
        l_html          VARCHAR2(7000) ;
        l_names         v240_tbl_type;
        l_values        v240_tbl_type;

        --The following 3 variables are meant for unpack_results_url procedure.
        l_status       NUMBER := 0;
        l_errcode      NUMBER := 0;
        l_errmessage   VARCHAR2(2000) := 'Success';

	-- for NLS bug fix #1692300 - 4/3/2001 jleybovi
	--
	l_db_nls	x_modresp_rec.Response.NLS_LANG%TYPE := null;
	l_ecapp_nls	x_modresp_rec.Response.NLS_LANG%TYPE := NULL;

        --Defining a local variable to hold the payment instrument type.
        l_pmtinstr_type VARCHAR2(200);
        CURSOR modreq_csr IS
               SELECT instrtype
               FROM   IBY_INSTR_HOLDER_V
               WHERE  instrid = p_pmtinstr_rec.PmtInstr_ID;


  BEGIN
        -- Standard Start of API savepoint
        --SAVEPOINT  OraPmtMod_PUB;

        /* ***** Performing Validations, Initializations
	         for Standard IN, OUT Parameters ***** */

        -- Standard call to check for call compatibility.
        IF NOT FND_API.Compatible_API_Call ( l_api_version,
                                             p_api_version,
                                             l_api_name,
                                             G_PKG_NAME )
        THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        -- Initialize message list if p_init_msg_list is set to TRUE.
        IF FND_API.to_Boolean( p_init_msg_list ) THEN
           FND_MSG_PUB.initialize;
        END IF;

        -- Verifying if validation level is FULL, which is expected for PUBLIC APIs.
        IF (p_validation_level <> g_validation_level) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204401_VAL_LEVEL_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --  Initialize API return status to success
        x_return_status := FND_API.G_RET_STS_SUCCESS;

        -- START OF BODY OF API

        get_baseurl(l_get_baseurl);

        -- Construct the full URL to send to the ECServlet.
        l_url := l_get_baseurl;

	l_db_nls := iby_utility_pvt.get_local_nls();
	l_ecapp_nls := NULL; -- not passed in this api??

        --MANDATORY INPUT PARAMETERS
        check_mandatory('OapfAction', l_oapf_action, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfECAppId', to_char(p_ecapp_id), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfStoreId', p_payee_rec.Payee_ID, l_url, l_db_nls, l_ecapp_nls);

        /*
        --check if mode is supplied, if not use 'OFFLINE' default
        IF p_modtrxn_rec.PmtMode IS NULL THEN
           check_optional('OapfMode', 'OFFLINE', l_url, l_db_nls, l_ecapp_nls);
        ELSE
           check_optional('OapfMode', p_modtrxn_rec.PmtMode, l_url, l_db_nls, l_ecapp_nls);
        END IF;
	*/
        -- the mode has to be mandatory as per the specifications
        check_mandatory('OapfMode', p_modtrxn_rec.PmtMode, l_url, l_db_nls, l_ecapp_nls);

        --Tangible related mandatory input
        check_mandatory('OapfOrderId', p_tangible_rec.Tangible_ID, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfPrice', FND_NUMBER.NUMBER_TO_CANONICAL(p_tangible_rec.Tangible_Amount), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfCurr', p_tangible_rec.Currency_Code, l_url, l_db_nls, l_ecapp_nls);

        check_mandatory('OapfTransactionId', to_char(p_modtrxn_rec.Trxn_ID), l_url, l_db_nls, l_ecapp_nls);

        --Determine the Payment Instrument type that is used.
        IF (p_pmtinstr_rec.CreditCardInstr.CC_Num IS NOT NULL) THEN
           l_pmtinstr_type := 'CREDITCARD';
        ELSIF (p_pmtinstr_rec.PurchaseCardInstr.PC_Num IS NOT NULL) THEN
           l_pmtinstr_type := 'PURCHASECARD';
        --ELSIF (p_pmtinstr_rec.BankAcctInstr.BankAcct_Num IS NOT NULL) THEN
        --l_pmtinstr_type := 'BANKACCOUNT';
        END IF;

        --CONDITIONALLY MANDATORY INPUT PARAMETERS

        --1. Instrument related conditionally mandatory input
        --a. CreditCard instrument related conditionally mandatory input

        IF (l_pmtinstr_type = 'CREDITCARD') THEN

           -- Assign the value for 'OapfPmtInstrType' to 'CREDITCARD' and append to URL.
           check_optional('OapfPmtInstrType', 'CREDITCARD', l_url, l_db_nls, l_ecapp_nls);

           check_mandatory('OapfAuthType', UPPER(p_modtrxn_rec.Auth_Type), l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrID',
             iby_creditcard_pkg.Get_Secured_Card_Number(p_pmtinstr_rec.CreditCardInstr.CC_Num),
             l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrExp', to_char(p_pmtinstr_rec.CreditCardInstr.CC_ExpDate, 'YYYY-MM-DD'), l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCCType', p_pmtinstr_rec.CreditCardInstr.CC_Type, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCustName', p_pmtinstr_rec.CreditCardInstr.CC_HolderName, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfFIName', p_pmtinstr_rec.CreditCardInstr.FIName, l_url, l_db_nls, l_ecapp_nls);

           --Address related Conditional Mandatory Input Parameters
           IF (p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Address1 IS NOT NULL)
           OR (p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.City  IS NOT NULL)
           OR (p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.State IS NOT NULL)
           OR (p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.PostalCode IS NOT NULL) THEN

              check_optional('OapfAddr1', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Address1, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfCity', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.City, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfState', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.State, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfPostalCode', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.PostalCode, l_url, l_db_nls, l_ecapp_nls);
           END IF;
        --b. PurchaseCard instrument related conditionally mandatory input
        ELSIF (l_pmtinstr_type = 'PURCHASECARD') THEN

           -- Assign the value for 'OapfPmtInstrType' to 'PURCHASECARD' and append to URL.
           check_optional('OapfPmtInstrType', 'PURCHASECARD', l_url, l_db_nls, l_ecapp_nls);

           check_mandatory('OapfAuthType', UPPER(p_modtrxn_rec.Auth_Type), l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrID',
             iby_creditcard_pkg.Get_Secured_Card_Number(p_pmtinstr_rec.PurchaseCardInstr.PC_Num),
             l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrExp', to_char(p_pmtinstr_rec.PurchaseCardInstr.PC_ExpDate, 'YYYY-MM-DD'), l_url, l_db_nls, l_ecapp_nls);

           check_mandatory('OapfCardSubType', p_pmtinstr_rec.PurchaseCardInstr.PC_Subtype, l_url, l_db_nls, l_ecapp_nls);

           check_optional('OapfCCType', p_pmtinstr_rec.PurchaseCardInstr.PC_Type, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCustName', p_pmtinstr_rec.PurchaseCardInstr.PC_HolderName, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfFIName', p_pmtinstr_rec.PurchaseCardInstr.FIName, l_url, l_db_nls, l_ecapp_nls);

           --Address related Conditional Mandatory Input Parameters
           IF (p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Address1 IS NOT NULL)
           OR (p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.City  IS NOT NULL)
           OR (p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.State IS NOT NULL)
           OR (p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.PostalCode IS NOT NULL) THEN

              check_optional('OapfAddr1', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Address1, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfCity', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.City, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfState', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.State, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfPostalCode', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.PostalCode, l_url, l_db_nls, l_ecapp_nls);
           END IF;
        /* NOT SUPPORTING BANKACCOUNT OPERATION FOR 11i

          ELSIF (l_pmtinstr_type = 'BANKACCOUNT') THEN
             --b. BankAccount instrument related conditionally mandatory input

             -- Assign the value for 'OapfPmtInstrType' to 'BANKACCOUNT' and append to URL.
             check_optional('OapfPmtInstrType', 'BANKACCOUNT', l_url, l_db_nls, l_ecapp_nls);

             check_mandatory('OapfBankId', p_pmtinstr_rec.BankAcctInstr.Bank_ID, l_url, l_db_nls, l_ecapp_nls);
             check_mandatory('OapfPmtInstrID', p_pmtinstr_rec.BankAcctInstr.BankAcct_Num, l_url, l_db_nls, l_ecapp_nls);
             check_mandatory('OapfAcctType', p_pmtinstr_rec.BankAcctInstr.BankAcct_Type, l_url, l_db_nls, l_ecapp_nls);
             check_optional('OapfBranchId', p_pmtinstr_rec.BankAcctInstr.Branch_ID, l_url, l_db_nls, l_ecapp_nls);
             check_optional('OapfFIName', p_pmtinstr_rec.BankAcctInstr.FIName, l_url, l_db_nls, l_ecapp_nls);
       */

          ELSE
             --a. registered instrument related conditionally mandatory input
             check_mandatory('OapfPmtRegId', to_char(p_pmtinstr_rec.PmtInstr_ID), l_url, l_db_nls, l_ecapp_nls);

             --NOTE*: Need a DB table/view to query DB from PmtInstr_ID and get PmtInstrType from DB.
             -- check_optional('OapfPmtInstrType', 'CREDITCARD', l_url, l_db_nls, l_ecapp_nls);

--dbms_output.put_line('Before opening cursor');
           --Query DB to get the PmtInstrType from Instrument Registration ID, pass to ECServlet.
             OPEN modreq_csr;
            FETCH modreq_csr
             INTO l_pmtinstr_type;

            IF (modreq_csr%ROWCOUNT = 0) THEN
              FND_MESSAGE.SET_NAME('IBY', 'IBY_204404_CURSOR_ERROR');
              FND_MSG_PUB.Add;
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            END IF;

            CLOSE modreq_csr;
--dbms_output.put_line('after closing cursor');

            check_mandatory('OapfPmtInstrType', l_pmtinstr_type, l_url, l_db_nls, l_ecapp_nls);

            IF ( l_pmtinstr_type = 'CREDITCARD')
               OR ( l_pmtinstr_type = 'PURCHASECARD') THEN
               check_mandatory('OapfAuthType', UPPER(p_modtrxn_rec.Auth_Type), l_url, l_db_nls, l_ecapp_nls);
            END IF;

          END IF;

        --2. Payment Mode related Conditional Mandatory Input Parameters
        IF (p_modtrxn_rec.PmtMode = 'OFFLINE') THEN
           check_mandatory('OapfSchedDate', to_char(p_modtrxn_rec.Settlement_Date, 'YYYY-MM-DD'), l_url, l_db_nls, l_ecapp_nls);
           -- Bug #1248563
           --check if CheckFlag is supplied, if not, use 'TRUE' default
           IF p_modtrxn_rec.Check_Flag IS NULL THEN
              check_optional('OapfCheckFlag', 'TRUE', l_url, l_db_nls, l_ecapp_nls);
           ELSE
              check_optional('OapfCheckFlag', p_modtrxn_rec.Check_Flag, l_url, l_db_nls, l_ecapp_nls);
           END IF;
           --check_mandatory('OapfCheckFlag', p_modtrxn_rec.Check_Flag, l_url, l_db_nls, l_ecapp_nls);
           -- End of Bug #1248563
        END IF;


        --OPTIONAL INPUT PARAMETERS
        check_optional('OapfPayerId', p_payer_rec.Payer_ID, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfPayerName', p_payer_rec.Payer_Name, l_url, l_db_nls, l_ecapp_nls);

        --Tangible related optional input
        check_optional('OapfMemo', p_tangible_rec.Memo, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfAcctNumber', p_tangible_rec.Acct_Num, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfRefNumber', p_tangible_rec.RefInfo, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfOrderMedium', p_tangible_rec.OrderMedium, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfEftAuthMethod', p_tangible_rec.EFTAuthMethod, l_url, l_db_nls, l_ecapp_nls);

        IF ( l_pmtinstr_type = 'CREDITCARD') THEN
          check_optional('OapfAddr2',p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Address2, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfAddr3',p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Address3, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfCnty', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.County, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfCntry', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Country, l_url, l_db_nls, l_ecapp_nls);
        ELSIF ( l_pmtinstr_type = 'PURCHASECARD') THEN
          check_optional('OapfAddr2',p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Address2, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfAddr3',p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Address3, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfCnty', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.County, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfCntry', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Country, l_url, l_db_nls, l_ecapp_nls);
        END IF;

        --Purchase Card related optional input
        check_optional('OapfPONum', to_char(p_modtrxn_rec.PONum), l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfTaxAmount', to_char(p_modtrxn_rec.TaxAmount), l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfShipToZip', p_modtrxn_rec.ShipToZip, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfShipFromZip', p_modtrxn_rec.ShipFromZip, l_url, l_db_nls, l_ecapp_nls);

        -- Remove ampersand from the last input parameter.
	l_url := RTRIM(l_url,'&');

	-- done in the escape_url_chars() method
        -- ^^^^ Replace blank characters with + sign. ^^^^
        --l_url := REPLACE(l_url,' ','+');


        -- Send http request to the payment server.
        --l_html := UTL_HTTP.REQUEST(l_url);
	SEND_REQUEST(l_url, l_html);

	-- show_output_debug(l_html);

        -- Unpack the results
	UNPACK_RESULTS_URL(l_html,l_names,l_values, l_status, l_errcode, l_errmessage);

        --Raising Exception to handle errors in unpacking resulting html file.
        IF (l_status = -1) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204403_HTML_UNPACK_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --Raising Exception to handle Servlet related errors.
        IF (l_names.COUNT = 0) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204402_JSERVLET_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        /* Retrieve name-value pairs stored in l_names and l_values, and assign
           them to the output record: x_modresp_rec.
        */
        FOR i IN 1..l_names.COUNT LOOP

            IF l_names(i) = 'OapfStatus' THEN
               x_modresp_rec.Response.Status := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfCode' THEN
               x_modresp_rec.Response.ErrCode := l_values(i);
            ELSIF l_names(i) = 'OapfCause' THEN
               x_modresp_rec.Response.ErrMessage := l_values(i);
            ELSIF l_names(i) = 'OapfNlsLang' THEN
               x_modresp_rec.Response.NLS_LANG := l_values(i);
            ELSIF l_names(i) = 'OapfTransactionId' THEN
               x_modresp_rec.Trxn_ID := TO_NUMBER(l_values(i));
            END IF;

        END LOOP;

        -- Setting API return status to 'U' if iPayment response status is not 0.
        IF (NOT trxn_status_success(x_modresp_rec.Response.Status)) THEN
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        END IF;

        -- END OF BODY OF API

        -- Standard check of p_commit.
	/*
        IF FND_API.To_Boolean( p_commit ) THEN
           COMMIT WORK;
        END IF;
	*/

        -- Standard call to get message count and if count is 1, get message info.
        FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                    p_data   =>   x_msg_data
                                  );
   EXCEPTION


      WHEN FND_API.G_EXC_ERROR THEN
         --ROLLBACK TO OraPmtMod_PUB;
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         --ROLLBACK TO OraPmtMod_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN OTHERS THEN
         --ROLLBACK TO OraPmtMod_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_api_name);
         END IF;

         FND_MSG_PUB.Count_And_Get ( p_count  =>  x_msg_count,
                                     p_data   =>  x_msg_data
                                   );

  END OraPmtMod;

--------------------------------------------------------------------------------------------
		--3. OraPmtCanc
        -- Start of comments
        --   API name        : OraPmtCanc
        --   Type            : Public
        --   Pre-reqs        : None
        --   Function        : Handles cancellations of off-line Payments.
        --   Parameters      :
        --     IN            : p_api_version       IN    NUMBER              Required
        --                     p_init_msg_list     IN    VARCHAR2            Optional
        --                     p_commit            IN    VARCHAR2            Optional
        --                     p_validation_level  IN    NUMBER              Optional
        --                     p_ecapp_id          IN    NUMBER              Required
        --                     p_canctrxn_rec      IN    CancelTrxn_rec_type Required
        --  Version :
        --    Current version      1.0
        --    Previous version     1.0
        --    Initial version      1.0
        -- End of comments
--------------------------------------------------------------------------------------------
  PROCEDURE OraPmtCanc ( p_api_version		IN	NUMBER,
			 p_init_msg_list	IN	VARCHAR2  := FND_API.G_FALSE,
			 p_commit		IN	VARCHAR2  := FND_API.G_FALSE,
			 p_validation_level	IN	NUMBER  := FND_API.G_VALID_LEVEL_FULL,
			 p_ecapp_id		IN	NUMBER,
			 p_canctrxn_rec		IN	CancelTrxn_rec_type,
			 x_return_status	OUT NOCOPY VARCHAR2,
			 x_msg_count		OUT NOCOPY NUMBER,
			 x_msg_data		OUT NOCOPY VARCHAR2,
			 x_cancresp_rec		OUT NOCOPY CancelResp_rec_type
		       ) IS

        --l_get_baseurl   VARCHAR2(2000) :=
        --  'http://alchen-sun.us.oracle.com:80/jservlets/11i/oracle.apps.iby.ecservlet.ECServlet?';
        --l_get_baseurl   VARCHAR2(2000) := FND_PROFILE.VALUE('IPAYMENT_BASEURL');

        l_get_baseurl   VARCHAR2(2000);
        --The following 3 variables are meant for output of
        --get_baseurl procedure.
        l_status_url    VARCHAR2(2000);
        l_msg_count_url NUMBER := 0;
        l_msg_data_url  VARCHAR2(2000);

        l_api_name     CONSTANT  VARCHAR2(30) := 'OraPmtCanc';
        l_oapf_action  CONSTANT  VARCHAR2(30) := 'oraPmtCanc';
        l_api_version  CONSTANT  NUMBER := 1.0;

        TYPE l_v240_tbl IS TABLE of VARCHAR2(240) INDEX BY BINARY_INTEGER;
        l_url           VARCHAR2(4000) ;
        l_html          VARCHAR2(7000) ;
        l_names         v240_tbl_type;
        l_values        v240_tbl_type;

	-- for NLS bug fix #1692300 - 4/3/2001 jleybovi
	--
	l_db_nls	p_canctrxn_rec.NLS_LANG%TYPE := NULL;
	l_ecapp_nls     p_canctrxn_rec.NLS_LANG%TYPE := NULL;

        --The following 3 variables are meant for unpack_results_url procedure.
        l_status       NUMBER := 0;
        l_errcode      NUMBER := 0;
        l_errmessage   VARCHAR2(2000) := 'Success';

        l_pmtinstr_type   VARCHAR2(80); --for querying up instrument type from DB.
        --NOTE* : **** IF INSTRTYPE IS NULL, this is assumed to be 'CREDITCARD' for release 11i ****.

        CURSOR pmtcanc_csr IS
               SELECT NVL(instrtype, 'CREDITCARD')
               FROM   IBY_PAYMENTS_V
               WHERE  transactionid = p_canctrxn_rec.Trxn_ID;

  BEGIN
        -- Standard Start of API savepoint
        --SAVEPOINT  OraPmtCanc_PUB;

        /* ***** Performing Validations, Initializations
	         for Standard IN, OUT Parameters ***** */

        -- Standard call to check for call compatibility.
        IF NOT FND_API.Compatible_API_Call ( l_api_version,
                                             p_api_version,
                                             l_api_name,
                                             G_PKG_NAME )
        THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        -- Initialize message list if p_init_msg_list is set to TRUE.
        IF FND_API.to_Boolean( p_init_msg_list ) THEN
           FND_MSG_PUB.initialize;
        END IF;

        -- Verifying if validation level is FULL, which is expected for PUBLIC APIs.
        IF (p_validation_level <> g_validation_level) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204401_VAL_LEVEL_ERROR');
           FND_MSG_PUB.Add;
           RAISE  FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --  Initialize API return status to success
        x_return_status := FND_API.G_RET_STS_SUCCESS;

        -- START OF BODY OF API

        get_baseurl(l_get_baseurl);

        -- Construct the full URL to send to the ECServlet.
        l_url := l_get_baseurl;

	l_db_nls := iby_utility_pvt.get_local_nls();
	l_ecapp_nls := p_canctrxn_rec.NLS_LANG;

        --Mandatory Input Parameters
        check_mandatory('OapfAction', l_oapf_action, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfMode', 'OFFLINE', l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfECAppId', to_char(p_ecapp_id), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfTransactionId', to_char(p_canctrxn_rec.Trxn_ID), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfReqType', p_canctrxn_rec.Req_Type, l_url, l_db_nls, l_ecapp_nls);

        --Optional Input Parameters
        check_optional('OapfNlsLang', p_canctrxn_rec.NLS_LANG, l_url, l_db_nls, l_ecapp_nls);

--dbms_output.put_line('Before opening cursor');

        --NOTE*: Query DB to get the PmtInstrType from TransactionID
        --to pass to ECServlet.
          OPEN pmtcanc_csr;
         FETCH pmtcanc_csr
          INTO l_pmtinstr_type;

         IF (pmtcanc_csr%ROWCOUNT = 0) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204404_CURSOR_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
         END IF;

         CLOSE pmtcanc_csr;
--dbms_output.put_line('after closing cursor');

        check_mandatory('OapfPmtInstrType', l_pmtinstr_type, l_url, l_db_nls, l_ecapp_nls);

        -- Remove ampersand from the last input parameter.
	l_url := RTRIM(l_url,'&');

	-- No longer needed; escape_url_chars does this
        -- ^^^ Replace blank characters with + sign.  ^^^
	--l_url := REPLACE(l_url,' ','+');

--show_input_debug(l_url);

        -- Send http request to the payment server.
        --l_html := UTL_HTTP.REQUEST(l_url);
	SEND_REQUEST(l_url, l_html);

--show_output_debug(l_html);

        -- Unpack the results
	UNPACK_RESULTS_URL(l_html,l_names,l_values, l_status, l_errcode, l_errmessage);

        --Raising Exception to handle errors in unpacking resulting html file.
        IF (l_status = -1) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204403_HTML_UNPACK_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --Raising Exception to handle Servlet related errors.
        IF (l_names.COUNT = 0) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204402_JSERVLET_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

--show_table_debug(l_names);
--show_table_debug(l_values);

        /* Retrieve name-value pairs stored in l_names and l_values, and assign
           them to the output record: x_cancresp_rec.
        */

        FOR i IN 1..l_names.COUNT LOOP

            --PAYMENT SERVER GENERIC RESPONSE.
            IF l_names(i) = 'OapfStatus' THEN
               x_cancresp_rec.Response.Status := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfCode' THEN
               x_cancresp_rec.Response.ErrCode := l_values(i);
            ELSIF l_names(i) = 'OapfCause' THEN
               x_cancresp_rec.Response.ErrMessage := l_values(i);
            ELSIF l_names(i) = 'OapfNlsLang' THEN
               x_cancresp_rec.Response.NLS_LANG := l_values(i);

            -- CANCEL OPERATION SPECIFIC RESPONSE
            ELSIF l_names(i) = 'OapfTransactionId' THEN
               x_cancresp_rec.Trxn_ID := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfErrLocation' THEN
               x_cancresp_rec.ErrorLocation := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfVendErrCode' THEN
               x_cancresp_rec.BEPErrCode := l_values(i);
            ELSIF l_names(i) = 'OapfVendErrmsg' THEN
               x_cancresp_rec.BEPErrMessage := l_values(i);
            END IF;

        END LOOP;

        -- Setting API return status to 'U' if iPayment response status is not 0.
        IF (NOT trxn_status_success(x_cancresp_rec.Response.Status)) THEN
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        END IF;

        -- END OF BODY OF API

        -- Standard check of p_commit.
	/*
        IF FND_API.To_Boolean( p_commit ) THEN
           COMMIT WORK;
        END IF;
	*/

        -- Standard call to get message count and if count is 1, get message info.
        FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                    p_data   =>   x_msg_data
                                  );
   EXCEPTION
      WHEN FND_API.G_EXC_ERROR THEN
         --ROLLBACK TO OraPmtCanc_PUB;
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         --ROLLBACK TO OraPmtCanc_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN OTHERS THEN
         --ROLLBACK TO OraPmtCanc_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_api_name);
         END IF;

         FND_MSG_PUB.Count_And_Get ( p_count  =>  x_msg_count,
                                     p_data   =>  x_msg_data
                                   );

  END OraPmtCanc;

--------------------------------------------------------------------------------------------
		--4. OraPmtQryTrxn
        -- Start of comments
        --   API name        : OraPmtQryTrxn
        --   Type            : Public
        --   Pre-reqs        : None
        --   Function        : Provides an interface for querying payment
	--                     transactions details.
        --   Parameters      :
        --     IN            : p_api_version       IN    NUMBER              Required
        --                     p_init_msg_list     IN    VARCHAR2            Optional
        --                     p_commit            IN    VARCHAR2            Optional
        --                     p_validation_level  IN    NUMBER              Optional
        --                     p_ecapp_id          IN    NUMBER              Required
        --                     p_querytrxn_rec     IN    QueryTrxn_rec_type  Required
        --   Version :
        --     Current version      1.0
        --     Previous version     1.0
        --     Initial version      1.0
        -- End of comments
--------------------------------------------------------------------------------------------
  PROCEDURE OraPmtQryTrxn ( p_api_version	   IN	NUMBER,
			    p_init_msg_list	   IN	VARCHAR2  := FND_API.G_FALSE,
			    p_commit		   IN	VARCHAR2  := FND_API.G_FALSE,
			    p_validation_level	   IN	NUMBER  := FND_API.G_VALID_LEVEL_FULL,
			    p_ecapp_id		   IN 	NUMBER,
			    p_querytrxn_rec 	   IN	QueryTrxn_rec_type,
			    x_return_status	   OUT NOCOPY VARCHAR2,
			    x_msg_count	           OUT NOCOPY NUMBER,
			    x_msg_data		   OUT NOCOPY VARCHAR2,
			    x_qrytrxnrespsum_rec   OUT NOCOPY QryTrxnRespSum_rec_type,
			    x_qrytrxnrespdet_tbl   OUT NOCOPY QryTrxnRespDet_tbl_type
			  ) IS

        --l_get_baseurl   VARCHAR2(2000) :=
        --  'http://alchen-sun.us.oracle.com:80/jservlets/11i/oracle.apps.iby.ecservlet.ECServlet?';
        --l_get_baseurl   VARCHAR2(2000) := FND_PROFILE.VALUE('IPAYMENT_BASEURL');

        l_get_baseurl   VARCHAR2(2000);
        --The following 3 variables are meant for output of
        --get_baseurl procedure.
        l_status_url    VARCHAR2(2000);
        l_msg_count_url NUMBER := 0;
        l_msg_data_url  VARCHAR2(2000);


        l_api_name     CONSTANT  VARCHAR2(30) := 'OraPmtQryTrxn';
        l_oapf_action  CONSTANT  VARCHAR2(30) := 'oraPmtQryTrxn';
        l_api_version  CONSTANT  NUMBER := 1.0;

        TYPE l_v240_tbl IS TABLE of VARCHAR2(240) INDEX BY BINARY_INTEGER;
        l_url           VARCHAR2(4000) ;
        l_html          VARCHAR2(7000) ;
        l_names         v240_tbl_type;
        l_values        v240_tbl_type;

        --The following 3 variables are meant for unpack_results_url procedure.
        l_status       NUMBER := 0;
        l_errcode      NUMBER := 0;
        l_errmessage   VARCHAR2(2000) := 'Success';

	-- for NLS bug fix #1692300 - 4/3/2001 jleybovi
	--
	l_db_nls       p_querytrxn_rec.NLS_LANG%TYPE := NULL;
	l_ecapp_nls    p_querytrxn_rec.NLS_LANG%TYPE := NULL;

        --Local variable to handle detail response table of records index
        l_index	       NUMBER := 0;
        i	       NUMBER := 0;

        l_pmtinstr_type   VARCHAR2(80); --for querying up instrument type from DB.
        CURSOR pmtqrytrxn_csr IS
               SELECT NVL(instrtype, 'CREDITCARD')
               FROM   IBY_PAYMENTS_V
               WHERE  transactionid = p_querytrxn_rec.Trxn_ID;

  BEGIN
        -- Standard Start of API savepoint
        --SAVEPOINT  OraPmtQryTrxn_PUB;

        /* ***** Performing Validations, Initializations
	         for Standard IN, OUT Parameters ***** */

        -- Standard call to check for call compatibility.
        IF NOT FND_API.Compatible_API_Call ( l_api_version,
                                             p_api_version,
                                             l_api_name,
                                             G_PKG_NAME )
        THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        -- Initialize message list if p_init_msg_list is set to TRUE.
        IF FND_API.to_Boolean( p_init_msg_list ) THEN
           FND_MSG_PUB.initialize;
        END IF;

        -- Verifying if validation level is FULL, which is expected for PUBLIC APIs.
        IF (p_validation_level <> g_validation_level) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204401_VAL_LEVEL_ERROR');
           FND_MSG_PUB.Add;
           RAISE  FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;


        -- Initialize API return status to success
        x_return_status := FND_API.G_RET_STS_SUCCESS;

        -- START OF BODY OF API

        get_baseurl(l_get_baseurl);

        -- Construct the full URL to send to the ECServlet.
        l_url := l_get_baseurl;

	l_db_nls := iby_utility_pvt.get_local_nls();
	l_ecapp_nls := p_querytrxn_rec.NLS_LANG;

        --Mandatory Input Parameters
        check_mandatory('OapfAction', l_oapf_action, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfECAppId', to_char(p_ecapp_id), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfTransactionId', to_char(p_querytrxn_rec.Trxn_ID), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfHistory', p_querytrxn_rec.History_Flag, l_url, l_db_nls, l_ecapp_nls);

        --For this API Mode has to be ONLINE only.
        check_mandatory('OapfMode', 'ONLINE', l_url, l_db_nls, l_ecapp_nls);

--dbms_output.put_line('Before opening cursor');

        --NOTE*: Query DB to get the PmtInstrType from TransactionID
        --to pass to ECServlet.

          OPEN pmtqrytrxn_csr;
         FETCH pmtqrytrxn_csr
          INTO l_pmtinstr_type;

         IF (pmtqrytrxn_csr%ROWCOUNT = 0) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204404_CURSOR_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
         END IF;

         CLOSE pmtqrytrxn_csr;
--dbms_output.put_line('after closing cursor');
--dbms_output.put_line('l_pmtinstrtyp = '|| l_pmtinstr_type);

        check_mandatory('OapfPmtInstrType', l_pmtinstr_type, l_url, l_db_nls, l_ecapp_nls);

        --Optional Input Parameters
        check_optional('OapfNlsLang', p_querytrxn_rec.NLS_LANG, l_url, l_db_nls, l_ecapp_nls);

        -- Remove ampersand from the last input parameter.
	l_url := RTRIM(l_url,'&');

	-- escape_url_chars() alread does this
	--
        -- ^^^ Replace blank characters with + sign. ^^^
	--l_url := REPLACE(l_url,' ','+');

--show_input_debug(l_url);

        -- Send http request to the payment server.
        -- l_html := UTL_HTTP.REQUEST(l_url);
	SEND_REQUEST(l_url, l_html);
--show_output_debug(l_html);

        -- Unpack the results
	UNPACK_RESULTS_URL(l_html,l_names,l_values, l_status, l_errcode, l_errmessage);

        --Raising Exception to handle errors in unpacking resulting html file.
        IF (l_status = -1) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204403_HTML_UNPACK_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --Raising Exception to handle Servlet related errors.
        IF (l_names.COUNT = 0) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204402_JSERVLET_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

--show_table_debug(l_names);
--show_table_debug(l_values);

        /* Retrieve name-value pairs stored in l_names and l_values, and map
           them to the output record, table: x_qrytrxnrespsum_rec, x_qrytrxnrespdet_tbl
        */

        FOR i IN 1..l_names.COUNT LOOP

            --MAPPING SUMMARY RESPONSE RECORD
            IF l_names(i) = 'OapfStatus' THEN
               x_qrytrxnrespsum_rec.Response.Status := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfCode' THEN
               x_qrytrxnrespsum_rec.Response.ErrCode := l_values(i);
            ELSIF l_names(i) = 'OapfCause' THEN
               x_qrytrxnrespsum_rec.Response.ErrMessage := l_values(i);
            ELSIF l_names(i) = 'OapfNlsLang' THEN
               x_qrytrxnrespsum_rec.Response.NLS_LANG := l_values(i);
            ELSIF l_names(i) = 'OapfErrLocation' THEN
               x_qrytrxnrespsum_rec.ErrorLocation := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfVendErrCode' THEN
               x_qrytrxnrespsum_rec.BEPErrCode := l_values(i);
            ELSIF l_names(i) = 'OapfVendErrmsg' THEN
               x_qrytrxnrespsum_rec.BEPErrMessage := l_values(i);

            --MAPPING DETAIL RESPONSE TABLE OF RECORDS
            ELSIF INSTR(l_names(i) , 'OapfQryStatus-') <> 0 THEN
	       l_index := TO_NUMBER(LTRIM(l_names(i), 'OapfQryStatus-'));
               x_qrytrxnrespdet_tbl(l_index).Status := TO_NUMBER(l_values(i));
            ELSIF INSTR(l_names(i) , 'OapfTransactionId-') <>0 THEN
	       l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfTransactionId-') );
               x_qrytrxnrespdet_tbl(l_index).Trxn_ID := TO_NUMBER(l_values(i));
            ELSIF INSTR(l_names(i) , 'OapfTrxnType-') <> 0 THEN
	       l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfTrxnType-') );
               x_qrytrxnrespdet_tbl(l_index).Trxn_Type := TO_NUMBER(l_values(i));

            ELSIF INSTR(l_names(i) , 'OapfTrxnDate-') <> 0 THEN
	       l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfTrxnDate-') );
               x_qrytrxnrespdet_tbl(l_index).Trxn_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');
            ELSIF INSTR(l_names(i) , 'OapfPmtInstrType-') <> 0 THEN
	       l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfPmtInstrType-') );
               x_qrytrxnrespdet_tbl(l_index).PmtInstr_Type := l_values(i);
            ELSIF INSTR(l_names(i) , 'OapfQryPrice-') <> 0 THEN
	       l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfQryPrice-') );
               x_qrytrxnrespdet_tbl(l_index).Price := FND_NUMBER.CANONICAL_TO_NUMBER(l_values(i));
            ELSIF INSTR(l_names(i) , 'OapfQryCurr-') <> 0 THEN
	       l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfQryCurr-') );
               x_qrytrxnrespdet_tbl(l_index).Currency := l_values(i);
            ELSIF INSTR(l_names(i) , 'OapfAuthcode-') <> 0 THEN
	       l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfAuthcode-') );
               x_qrytrxnrespdet_tbl(l_index).Authcode := l_values(i);

            ELSIF INSTR(l_names(i) , 'OapfRefcode-') <> 0 THEN
	       l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfRefcode-') );
               x_qrytrxnrespdet_tbl(l_index).Refcode := l_values(i);
            ELSIF INSTR(l_names(i) , 'OapfAVScode-') <> 0 THEN
	       l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfAVScode-') );
               x_qrytrxnrespdet_tbl(l_index).AVScode := l_values(i);
            ELSIF INSTR(l_names(i) , 'OapfAcquirer-') <> 0 THEN
	       l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfAcquirer-') );
               x_qrytrxnrespdet_tbl(l_index).Acquirer := l_values(i);
            ELSIF INSTR(l_names(i) , 'OapfVpsBatchId-') <> 0 THEN
	       l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfVpsBatchId-') );
               x_qrytrxnrespdet_tbl(l_index).VpsBatch_ID := l_values(i);

            ELSIF INSTR(l_names(i) , 'OapfAuxMsg-') <> 0 THEN
	       l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfAuxMsg-') );
               x_qrytrxnrespdet_tbl(l_index).AuxMsg := l_values(i);
            ELSIF INSTR(l_names(i) , 'OapfErrLocation-') <> 0 THEN
	       l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfErrLocation-') );
               x_qrytrxnrespdet_tbl(l_index).ErrorLocation := TO_NUMBER(l_values(i));
            ELSIF INSTR(l_names(i) , 'OapfVendErrCode-') <> 0 THEN
	       l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfVendErrCode-') );
               x_qrytrxnrespdet_tbl(l_index).BEPErrCode := l_values(i);
            ELSIF INSTR(l_names(i) , 'OapfVendErrmsg-') <> 0 THEN
	       l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfVendErrmsg-') );
               x_qrytrxnrespdet_tbl(l_index).BEPErrMessage := l_values(i);
            END IF;

        END LOOP;

        -- Setting API return status to 'U' if iPayment response status is not 0.
        IF (NOT trxn_status_success(x_qrytrxnrespsum_rec.Response.Status)) THEN
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        END IF;

        -- END OF BODY OF API


        -- Standard check of p_commit.
	/*
        IF FND_API.To_Boolean( p_commit ) THEN
           COMMIT WORK;
        END IF;
	*/

        -- Standard call to get message count and if count is 1, get message info.
        FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                    p_data   =>   x_msg_data
                                  );
   EXCEPTION
      WHEN FND_API.G_EXC_ERROR THEN
         --ROLLBACK TO OraPmtQryTrxn_PUB;
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         --ROLLBACK TO OraPmtQryTrxn_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN OTHERS THEN
         --ROLLBACK TO OraPmtQryTrxn_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_api_name);
         END IF;

         FND_MSG_PUB.Count_And_Get ( p_count  =>  x_msg_count,
                                     p_data   =>  x_msg_data
                                   );

  END OraPmtQryTrxn;

--------------------------------------------------------------------------------------------
		--5. OraPmtCapture
        -- Start of comments
        --   API name        : OraPmtCapture
        --   Type            : Public
        --   Pre-reqs        : None
        --   Function        : Handles capture of funds from Payer accounts for authorized
        --                        Payment Requests in case of CreditCard instruments.
        --   Parameters      :
        --     IN            : p_api_version       IN    NUMBER               Required
        --                     p_init_msg_list     IN    VARCHAR2             Optional
        --                     p_commit            IN    VARCHAR2             Optional
        --                     p_validation_level  IN    NUMBER               Optional
        --                     p_ecapp_id          IN    NUMBER               Required
        --                     p_capturetrxn_rec   IN    CaptureTrxn_rec_type Required
        --   Version :
        --     Current version      1.0
        --     Previous version     1.0
        --     Initial version      1.0
        -- End of comments
--------------------------------------------------------------------------------------------
  PROCEDURE OraPmtCapture ( p_api_version	IN	NUMBER,
			    p_init_msg_list	IN	VARCHAR2  := FND_API.G_FALSE,
			    p_commit		IN	VARCHAR2  := FND_API.G_FALSE,
			    p_validation_level	IN	NUMBER  := FND_API.G_VALID_LEVEL_FULL,
			    p_ecapp_id 		IN	NUMBER,
			    p_capturetrxn_rec 	IN	CaptureTrxn_rec_type,
			    x_return_status	OUT NOCOPY VARCHAR2,
			    x_msg_count		OUT NOCOPY NUMBER,
			    x_msg_data		OUT NOCOPY VARCHAR2,
			    x_capresp_rec	OUT NOCOPY CaptureResp_rec_type
            	          ) IS

        --l_get_baseurl   VARCHAR2(2000) :=
        --  'http://alchen-sun.us.oracle.com:80/jservlets/11i/oracle.apps.iby.ecservlet.ECServlet?';
        --l_get_baseurl   VARCHAR2(2000) := FND_PROFILE.VALUE('IPAYMENT_BASEURL');

        l_get_baseurl   VARCHAR2(2000);
        --The following 3 variables are meant for output of
        --get_baseurl procedure.
        l_status_url    VARCHAR2(2000);
        l_msg_count_url NUMBER := 0;
        l_msg_data_url  VARCHAR2(2000);


        l_api_name     CONSTANT  VARCHAR2(30) := 'OraPmtCapture';
        l_oapf_action  CONSTANT  VARCHAR2(30) := 'oraPmtCapture';
        l_api_version  CONSTANT  NUMBER := 1.0;

        TYPE l_v240_tbl IS TABLE of VARCHAR2(240) INDEX BY BINARY_INTEGER;
        l_url           VARCHAR2(4000) ;
        l_html          VARCHAR2(7000) ;
        l_names         v240_tbl_type;
        l_values        v240_tbl_type;

        --The following 3 variables are meant for unpack_results_url procedure.
        l_status       NUMBER := 0;
        l_errcode      NUMBER := 0;
        l_errmessage   VARCHAR2(2000) := 'Success';

	-- for NLS bug fix #1692300 - 4/3/2001 jleybovi
	--
	l_db_nls       p_capturetrxn_rec.NLS_LANG%TYPE := NULL;
	l_ecapp_nls    p_capturetrxn_rec.NLS_LANG%TYPE := NULL;

   BEGIN
        -- Standard Start of API savepoint
        --SAVEPOINT  OraPmtCapture_PUB;

        /* ***** Performing Validations, Initializations
	         for Standard IN, OUT Parameters ***** */

        -- Standard call to check for call compatibility.
        IF NOT FND_API.Compatible_API_Call ( l_api_version,
                                             p_api_version,
                                             l_api_name,
                                             G_PKG_NAME )
        THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        -- Initialize message list if p_init_msg_list is set to TRUE.
        IF FND_API.to_Boolean( p_init_msg_list ) THEN
           FND_MSG_PUB.initialize;
        END IF;

        -- Verifying if validation level is FULL, which is expected for PUBLIC APIs.
        IF (p_validation_level <> g_validation_level) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204401_VAL_LEVEL_ERROR');
           FND_MSG_PUB.Add;
           RAISE  FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --  Initialize API return status to success
        x_return_status := FND_API.G_RET_STS_SUCCESS;

        -- START OF BODY OF API

        get_baseurl(l_get_baseurl);

        -- Construct the full URL to send to the ECServlet.
	l_url := l_get_baseurl;

	l_db_nls := iby_utility_pvt.get_local_nls();
	l_ecapp_nls := p_capturetrxn_rec.NLS_LANG;

        --1. MANDATORY INPUT PARAMETERS
        check_mandatory('OapfAction', l_oapf_action, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfECAppId', to_char(p_ecapp_id), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfTransactionId', to_char(p_capturetrxn_rec.Trxn_ID), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfPrice', FND_NUMBER.NUMBER_TO_CANONICAL(p_capturetrxn_rec.Price), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfCurr', p_capturetrxn_rec.Currency, l_url, l_db_nls, l_ecapp_nls);

        /*
        --check if mode is supplied, if not use 'ONLINE' default
        IF p_capturetrxn_rec.PmtMode IS NULL THEN
          check_optional('OapfMode', 'ONLINE', l_url, l_db_nls, l_ecapp_nls);
        ELSE
          check_optional('OapfMode', p_capturetrxn_rec.PmtMode, l_url, l_db_nls, l_ecapp_nls);
        END IF;
        */
        -- the mode has to be mandatory as per the specifications
        check_mandatory('OapfMode', p_capturetrxn_rec.PmtMode, l_url, l_db_nls, l_ecapp_nls);

        --2. Payment Mode related Conditional Mandatory Input Parameters
        IF (p_capturetrxn_rec.PmtMode = 'OFFLINE') THEN
           check_mandatory('OapfSchedDate', to_char(p_capturetrxn_rec.Settlement_Date, 'YYYY-MM-DD'), l_url, l_db_nls, l_ecapp_nls);
        END IF;

        --OPTIONAL INPUT PARAMETERS
        check_optional('OapfNlsLang', p_capturetrxn_rec.NLS_LANG, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfTrxnRef', p_capturetrxn_rec.TrxnRef, l_url, l_db_nls, l_ecapp_nls);
        -- Remove ampersand from the last input parameter.
	l_url := RTRIM(l_url,'&');

	-- escape_ulr_chars() does this now
	--
	-- ^^^ Replace blank characters with + sign. ^^^
	--l_url := REPLACE(l_url,' ','+');

--show_input_debug(l_url);
 --dbms_output.put_line(l_url);
	--  Send HTTP request to ipayment servlet
	--l_html := UTL_HTTP.REQUEST(l_url);
	SEND_REQUEST(l_url, l_html);

 --dbms_output.put_line(l_html);

--show_output_debug(l_html);

	-- Parse the resulting HTML page body
	UNPACK_RESULTS_URL(l_html,l_names,l_values, l_status, l_errcode, l_errmessage);


        --Raising Exception to handle errors in unpacking resulting html file.
        IF (l_status = -1) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204403_HTML_UNPACK_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --Raising Exception to handle Servlet related errors.
        IF (l_names.COUNT = 0) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204402_JSERVLET_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

	-- Assign output parameters to output record x_capresp_rec
	FOR i IN 1..l_names.COUNT LOOP

            --Payment Server GENERIC Response
	    IF l_names(i) = 'OapfStatus' THEN
               x_capresp_rec.Response.Status := TO_NUMBER(l_values(i));
	    ELSIF l_names(i) = 'OapfCode' THEN
	       x_capresp_rec.Response.ErrCode := l_values(i);
	    ELSIF l_names(i) = 'OapfCause' THEN
	       x_capresp_rec.Response.ErrMessage := l_values(i);
	    ELSIF l_names(i) = 'OapfNlsLang' THEN
	       x_capresp_rec.Response.NLS_LANG := l_values(i);

            --CAPTURE Operation Related Response
	    ELSIF l_names(i) = 'OapfTransactionId' THEN
	       x_capresp_rec.Trxn_ID := TO_NUMBER(l_values(i));
	    ELSIF l_names(i) = 'OapfTrxnType' THEN
	       x_capresp_rec.Trxn_Type := TO_NUMBER(l_values(i));
	    ELSIF l_names(i) = 'OapfTrxnDate' THEN
	       x_capresp_rec.Trxn_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');
	    ELSIF l_names(i) = 'OapfPmtInstrType' THEN
	       x_capresp_rec.PmtInstr_Type := l_values(i);
	    ELSIF l_names(i) = 'OapfRefcode' THEN
	       x_capresp_rec.Refcode := l_values(i);
	    ELSIF l_names(i) = 'OapfErrLocation' THEN
	       x_capresp_rec.ErrorLocation := l_values(i);
	    ELSIF l_names(i) = 'OapfVendErrCode' THEN
	       x_capresp_rec.BEPErrCode := l_values(i);
	    ELSIF l_names(i) = 'OapfVendErrmsg' THEN
	       x_capresp_rec.BEPErrmessage := l_values(i);

            --OFFLINE Payment Mode Related Response
            ELSIF l_names(i) = 'OapfEarliestSettlementDate' THEN
               x_capresp_rec.OffLineResp.EarliestSettlement_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');
            ELSIF l_names(i) = 'OapfSchedDate' THEN
               x_capresp_rec.OffLineResp.Scheduled_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');
	    END IF;

	END LOOP;

        -- Setting API return status to 'U' if iPayment response status is not 0.
        IF (NOT trxn_status_success(x_capresp_rec.Response.Status)) THEN
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        END IF;

        -- END OF BODY OF API

        -- Standard check of p_commit.
	/*
        IF FND_API.To_Boolean( p_commit ) THEN
           COMMIT WORK;
        END IF;
	*/

        -- Standard call to get message count and if count is 1, get message info.
        FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                    p_data   =>   x_msg_data
                                  );
   EXCEPTION
      WHEN FND_API.G_EXC_ERROR THEN
         --ROLLBACK TO OraPmtCapture_PUB;
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         --ROLLBACK TO OraPmtCapture_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN OTHERS THEN
         --ROLLBACK TO OraPmtCapture_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_api_name);
         END IF;

         FND_MSG_PUB.Count_And_Get ( p_count  =>  x_msg_count,
                                     p_data   =>  x_msg_data
                                   );

   END OraPmtCapture;

--------------------------------------------------------------------------------------------
		--6. OraPmtReturn
        -- Start of comments
        --   API name        : OraPmtReturn
        --   Type            : Public
        --   Pre-reqs        : None
        --   Function        : Handles return of funds to Payer accounts for
        --                        existing Payment request transactions.
        --   Parameters      :
        --     IN            : p_api_version       IN    NUMBER              Required
        --                     p_init_msg_list     IN    VARCHAR2            Optional
        --                     p_commit            IN    VARCHAR2            Optional
        --                     p_validation_level  IN    NUMBER              Optional
        --                     p_ecapp_id          IN    NUMBER              Required
        --                     p_returntrxn_rec    IN    ReturnTrxn_rec_type Required
        --   Version :
        --     Current version      1.0
        --     Previous version     1.0
        --     Initial version      1.0
        -- End of comments
--------------------------------------------------------------------------------------------
  PROCEDURE OraPmtReturn ( p_api_version	IN	NUMBER,
			   p_init_msg_list	IN	VARCHAR2  := FND_API.G_FALSE,
			   p_commit		IN	VARCHAR2 := FND_API.G_FALSE,
			   p_validation_level	IN	NUMBER  := FND_API.G_VALID_LEVEL_FULL,
			   p_ecapp_id 		IN	NUMBER,
			   p_returntrxn_rec 	IN	ReturnTrxn_rec_type,
			   x_return_status	OUT NOCOPY VARCHAR2,
			   x_msg_count		OUT NOCOPY NUMBER,
			   x_msg_data		OUT NOCOPY VARCHAR2,
			   x_retresp_rec	OUT NOCOPY ReturnResp_rec_type
  			 ) IS

        --l_get_baseurl   VARCHAR2(2000) :=
        --  'http://alchen-sun.us.oracle.com:80/jservlets/11i/oracle.apps.iby.ecservlet.ECServlet?';
        --l_get_baseurl   VARCHAR2(2000) := FND_PROFILE.VALUE('IPAYMENT_BASEURL');

        l_get_baseurl   VARCHAR2(2000);
        --The following 3 variables are meant for output of
        --get_baseurl procedure.
        l_status_url    VARCHAR2(2000);
        l_msg_count_url NUMBER := 0;
        l_msg_data_url  VARCHAR2(2000);

        l_api_name     CONSTANT  VARCHAR2(30) := 'OraPmtReturn';
        l_oapf_action  CONSTANT  VARCHAR2(30) := 'oraPmtReturn';
        l_api_version  CONSTANT  NUMBER := 1.0;

        TYPE l_v240_tbl IS TABLE of VARCHAR2(240) INDEX BY BINARY_INTEGER;
        l_url           VARCHAR2(4000) ;
        l_html          VARCHAR2(7000) ;
        l_names         v240_tbl_type;
        l_values        v240_tbl_type;

        --The following 3 variables are meant for unpack_results_url procedure.
        l_status       NUMBER := 0;
        l_errcode      NUMBER := 0;
        l_errmessage   VARCHAR2(2000) := 'Success';

	-- for NLS bug fix #1692300 - 4/3/2001 jleybovi
	--
	l_db_nls       p_returntrxn_rec.NLS_LANG%TYPE := NULL;
	l_ecapp_nls    p_returntrxn_rec.NLS_LANG%TYPE := NULL;
        l_pmtinstr_type   VARCHAR2(80);

   CURSOR pmtreturn_csr IS
               SELECT NVL(instrtype, 'CREDITCARD')
               FROM   IBY_trxn_summaries_all
               WHERE  transactionid = p_returntrxn_rec.Trxn_ID
               and rownum=1;

   BEGIN
        -- Standard Start of API savepoint
        --SAVEPOINT  OraPmtReturn_PUB;

        /* ***** Performing Validations, Initializations
	         for Standard IN, OUT Parameters ***** */

        -- Standard call to check for call compatibility.
        IF NOT FND_API.Compatible_API_Call ( l_api_version,
                                             p_api_version,
                                             l_api_name,
                                             G_PKG_NAME )
        THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        -- Initialize message list if p_init_msg_list is set to TRUE.
        IF FND_API.to_Boolean( p_init_msg_list ) THEN
           FND_MSG_PUB.initialize;
        END IF;

        -- Verifying if validation level is FULL, which is expected for PUBLIC APIs.
        IF (p_validation_level <> g_validation_level) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204401_VAL_LEVEL_ERROR');
           FND_MSG_PUB.Add;
           RAISE  FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;


        --  Initialize API return status to success
        x_return_status := FND_API.G_RET_STS_SUCCESS;

        -- START OF BODY OF API

        get_baseurl(l_get_baseurl);

        -- Construct the full URL to send to the ECServlet.
        l_url := l_get_baseurl;

	l_db_nls := iby_utility_pvt.get_local_nls();
	l_ecapp_nls := p_returntrxn_rec.NLS_LANG;

--NOTE*: Query DB to get the PmtInstrType from TransactionID
        --to pass to ECServlet.
          OPEN pmtreturn_csr;
         FETCH pmtreturn_csr
          INTO l_pmtinstr_type;

         IF (pmtreturn_csr%ROWCOUNT = 0) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204404_CURSOR_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
         END IF;

         CLOSE pmtreturn_csr;
--dbms_output.put_line('after closing cursor');

        check_mandatory('OapfPmtInstrType', l_pmtinstr_type, l_url, l_db_nls, l_ecapp_nls);

        --Mandatory Input Parameters
        check_mandatory('OapfAction', l_oapf_action, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfECAppId', to_char(p_ecapp_id), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfTransactionId',  to_char(p_returntrxn_rec.Trxn_ID), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfPrice', FND_NUMBER.NUMBER_TO_CANONICAL(p_returntrxn_rec.Price), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfCurr', p_returntrxn_rec.Currency, l_url, l_db_nls, l_ecapp_nls);

        /*
        --check if mode is supplied, if not, use 'ONLINE' default
        IF p_returntrxn_rec.PmtMode IS NULL THEN
           check_optional('OapfMode', 'ONLINE', l_url, l_db_nls, l_ecapp_nls);
        ELSE
           check_optional('OapfMode', p_returntrxn_rec.PmtMode, l_url, l_db_nls, l_ecapp_nls);
        END IF;
	*/
        -- the mode has to be mandatory as per the specifications
        check_mandatory('OapfMode', p_returntrxn_rec.PmtMode, l_url, l_db_nls, l_ecapp_nls);

        --Payment Mode related Conditional Mandatory Input Parameters
        IF (p_returntrxn_rec.PmtMode = 'OFFLINE') THEN
           check_mandatory('OapfSchedDate', to_char(p_returntrxn_rec.Settlement_Date, 'YYYY-MM-DD'), l_url, l_db_nls, l_ecapp_nls);
        END IF;

        --Optional Input Parameters
        check_optional('OapfNlsLang', p_returntrxn_rec.NLS_LANG, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfTrxnRef', p_returntrxn_rec.TrxnRef, l_url, l_db_nls, l_ecapp_nls);

        -- Remove ampersand from the last input parameter.
	l_url := RTRIM(l_url,'&');

	-- already done by escape_url_chars()
	--
	-- ^^^Replace blank characters with + sign.^^^
        --l_url := REPLACE(l_url,' ','+');

        --  Send HTTP request to ipayment servlet
        -- l_html := UTL_HTTP.REQUEST(l_url);
	SEND_REQUEST(l_url, l_html);

        -- Parse the resulting HTML page
	UNPACK_RESULTS_URL(l_html,l_names,l_values, l_status, l_errcode, l_errmessage);

        --Raising Exception to handle errors in unpacking resulting html file.
        IF (l_status = -1) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204403_HTML_UNPACK_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --Raising Exception to handle Servlet related errors.
        IF (l_names.COUNT = 0) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204402_JSERVLET_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        -- Assign output parameters to output record x_retresp_rec
        FOR i IN 1..l_names.COUNT LOOP

            --Payment Server GENERIC Response
	    IF l_names(i) = 'OapfStatus' THEN
               x_retresp_rec.Response.Status := TO_NUMBER(l_values(i));
	    ELSIF l_names(i) = 'OapfCode' THEN
	       x_retresp_rec.Response.ErrCode := l_values(i);
	    ELSIF l_names(i) = 'OapfCause' THEN
	       x_retresp_rec.Response.ErrMessage := l_values(i);
	    ELSIF l_names(i) = 'OapfNlsLang' THEN
	       x_retresp_rec.Response.NLS_LANG := l_values(i);

            --RETURN Operation Related Response
	    ELSIF l_names(i) = 'OapfTransactionId' THEN
	       x_retresp_rec.Trxn_ID := TO_NUMBER(l_values(i));
	    ELSIF l_names(i) = 'OapfTrxnType' THEN
	       x_retresp_rec.Trxn_Type := TO_NUMBER(l_values(i));
	    ELSIF l_names(i) = 'OapfTrxnDate' THEN
	       x_retresp_rec.Trxn_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');
	    ELSIF l_names(i) = 'OapfPmtInstrType' THEN
	       x_retresp_rec.PmtInstr_Type := l_values(i);
	    ELSIF l_names(i) = 'OapfRefcode' THEN
	       x_retresp_rec.Refcode := l_values(i);
	    ELSIF l_names(i) = 'OapfErrLocation' THEN
	       x_retresp_rec.ErrorLocation := l_values(i);
	    ELSIF l_names(i) = 'OapfVendErrCode' THEN
	       x_retresp_rec.BEPErrCode := l_values(i);
	    ELSIF l_names(i) = 'OapfVendErrmsg' THEN
	       x_retresp_rec.BEPErrmessage := l_values(i);

            --OFFLINE Payment Mode Related Response
            ELSIF l_names(i) = 'OapfEarliestSettlementDate' THEN
               x_retresp_rec.OffLineResp.EarliestSettlement_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');
            ELSIF l_names(i) = 'OapfSchedDate' THEN
               x_retresp_rec.OffLineResp.Scheduled_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');
	    END IF;
        END LOOP;

        -- Setting API return status to 'U' if iPayment response status is not 0.
        IF (NOT trxn_status_success(x_retresp_rec.Response.Status)) THEN
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        END IF;

        -- END OF BODY OF API

        -- Standard check of p_commit.
	/*
        IF FND_API.To_Boolean( p_commit ) THEN
           COMMIT WORK;
        END IF;
	*/

        -- Standard call to get message count and if count is 1, get message info.
        FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                    p_data   =>   x_msg_data
                                  );
   EXCEPTION
      WHEN FND_API.G_EXC_ERROR THEN
         --ROLLBACK TO OraPmtReturn_PUB;
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         --ROLLBACK TO OraPmtReturn_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN OTHERS THEN
         --ROLLBACK TO OraPmtReturn_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_api_name);
         END IF;

         FND_MSG_PUB.Count_And_Get ( p_count  =>  x_msg_count,
                                     p_data   =>  x_msg_data
                                   );

   END OraPmtReturn;

--------------------------------------------------------------------------------------------
		       --7. OraPmtVoid
        -- Start of comments
        --   API name        : OraPmtVoid
        --   Type            : Public
        --   Pre-reqs        : None
        --   Function        : Handles Void Operations for existing Payment transactions.
        --                     Can be performed on Capture and Return operation for all
        --                     BEPs on Authorization operation for some BEPs.
        --   Parameters      :
        --     IN            : p_api_version       IN    NUMBER              Required
        --                     p_init_msg_list     IN    VARCHAR2            Optional
        --                     p_commit            IN    VARCHAR2            Optional
        --                     p_validation_level  IN    NUMBER              Optional
        --                     p_ecapp_id          IN    NUMBER              Required
        --                     p_voidtrxn_rec      IN    VoidTrxn_rec_type   Required
        --   Version :
        --     Current version      1.0
        --     Previous version     1.0
        --     Initial version      1.0
        -- End of comments
--------------------------------------------------------------------------------------------
  PROCEDURE OraPmtVoid ( p_api_version		IN	NUMBER,
			 p_init_msg_list	IN	VARCHAR2  := FND_API.G_FALSE,
			 p_commit		IN	VARCHAR2 := FND_API.G_FALSE,
			 p_validation_level	IN	NUMBER  := FND_API.G_VALID_LEVEL_FULL,
			 p_ecapp_id		IN	NUMBER,
			 p_voidtrxn_rec 	IN	VoidTrxn_rec_type,
			 x_return_status	OUT NOCOPY VARCHAR2,
			 x_msg_count		OUT NOCOPY NUMBER,
			 x_msg_data		OUT NOCOPY VARCHAR2,
			 x_voidresp_rec	        OUT NOCOPY VoidResp_rec_type
		       ) IS

        --l_get_baseurl   VARCHAR2(2000) :=
        --  'http://alchen-sun.us.oracle.com:80/jservlets/11i/oracle.apps.iby.ecservlet.ECServlet?';
        --l_get_baseurl   VARCHAR2(2000) := FND_PROFILE.VALUE('IPAYMENT_BASEURL');

        l_get_baseurl   VARCHAR2(2000);
        --The following 3 variables are meant for output of
        --get_baseurl procedure.
        l_status_url    VARCHAR2(2000);
        l_msg_count_url NUMBER := 0;
        l_msg_data_url  VARCHAR2(2000);

        l_api_name     CONSTANT  VARCHAR2(30) := 'OraPmtVoid';
        l_oapf_action  CONSTANT  VARCHAR2(30) := 'oraPmtVoid';
        l_api_version  CONSTANT  NUMBER := 1.0;

        TYPE l_v240_tbl IS TABLE of VARCHAR2(240) INDEX BY BINARY_INTEGER;
        l_url           VARCHAR2(4000) ;
        l_html          VARCHAR2(7000) ;
        l_names         v240_tbl_type;
        l_values        v240_tbl_type;

        --The following 3 variables are meant for unpack_results_url procedure.
        l_status       NUMBER := 0;
        l_errcode      NUMBER := 0;
        l_errmessage   VARCHAR2(2000) := 'Success';

	-- for NLS bug fix #1692300 - 4/3/2001 jleybovi
	--
	l_db_nls       p_voidtrxn_rec.NLS_LANG%TYPE := NULL;
	l_ecapp_nls    p_voidtrxn_rec.NLS_LANG%TYPE := NULL;

	v_trxnTimestamp	DATE := NULL;
   BEGIN
        -- Standard Start of API savepoint
        --SAVEPOINT  OraPmtVoid_PUB;

        /* ***** Performing Validations, Initializations
	         for Standard IN, OUT Parameters ***** */

        -- Standard call to check for call compatibility.
        IF NOT FND_API.Compatible_API_Call ( l_api_version,
                                             p_api_version,
                                             l_api_name,
                                             G_PKG_NAME )
        THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        -- Initialize message list if p_init_msg_list is set to TRUE.
        IF FND_API.to_Boolean( p_init_msg_list ) THEN
           FND_MSG_PUB.initialize;
        END IF;

        -- Verifying if validation level is FULL, which is expected for PUBLIC APIs.
        IF (p_validation_level <> g_validation_level) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204401_VAL_LEVEL_ERROR');
           FND_MSG_PUB.Add;
           RAISE  FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --  Initialize API return status to success
        x_return_status := FND_API.G_RET_STS_SUCCESS;

        -- START OF BODY OF API

        get_baseurl(l_get_baseurl);

        -- Construct the full URL to send to the ECServlet.
        l_url := l_get_baseurl;

	l_db_nls := iby_utility_pvt.get_local_nls();
	l_ecapp_nls := p_voidtrxn_rec.NLS_LANG;

        --Mandatory Input Parameters
        check_mandatory('OapfAction', l_oapf_action, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfECAppId', to_char(p_ecapp_id), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfTransactionId', to_char(p_voidtrxn_rec.Trxn_ID), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfTrxnType', to_char(p_voidtrxn_rec.Trxn_Type), l_url, l_db_nls, l_ecapp_nls);

	/*
        --check if mode is supplied, if not use 'ONLINE' default
        IF p_voidtrxn_rec.PmtMode IS NULL THEN
           check_optional('OapfMode', 'ONLINE', l_url, l_db_nls, l_ecapp_nls);
        ELSE
           check_optional('OapfMode', p_voidtrxn_rec.PmtMode, l_url, l_db_nls, l_ecapp_nls);
        END IF;
	*/
        -- the mode has to be mandatory as per the specifications
        check_mandatory('OapfMode', p_voidtrxn_rec.PmtMode, l_url, l_db_nls, l_ecapp_nls);

        --Payment Mode related Conditional Mandatory Input Parameters
        IF (p_voidtrxn_rec.PmtMode = 'OFFLINE') THEN
           check_mandatory('OapfSchedDate', to_char(p_voidtrxn_rec.Settlement_Date, 'YYYY-MM-DD'), l_url, l_db_nls, l_ecapp_nls);
        END IF;

        --Optional Input Parameters
        check_optional('OapfNlsLang', p_voidtrxn_rec.NLS_LANG, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfTrxnRef', p_voidtrxn_rec.TrxnRef, l_url, l_db_nls, l_ecapp_nls);

        -- Remove ampersand from the last input parameter.
	l_url := RTRIM(l_url,'&');

	-- done by escape_url_chars()
	--
	-- ^^^ Replace blank characters with + sign. ^^^
	-- l_url := REPLACE(l_url,' ','+');

--dbms_output.put_line('before utl_http call');
--show_input_debug(l_url);

        --  Send HTTP request to ipayment servlet
        -- l_html := UTL_HTTP.REQUEST(l_url);
	SEND_REQUEST(l_url, l_html);

--dbms_output.put_line('after utl_http call');
--show_output_debug(l_html);

        -- Parse the resulting HTML page
	UNPACK_RESULTS_URL(l_html,l_names,l_values, l_status, l_errcode, l_errmessage);

--show_table_debug(l_names);
--show_table_debug(l_values);

        --Raising Exception to handle errors in unpacking resulting html file.
        IF (l_status = -1) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204403_HTML_UNPACK_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --Raising Exception to handle Servlet related errors.
        IF (l_names.COUNT = 0) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204402_JSERVLET_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

--dbms_output.put_line('after successful unpacking');

        -- Assign output parameters to output record x_retresp_rec
        FOR i IN 1..l_names.COUNT LOOP

            --Payment Server Related Generic Response
            IF l_names(i) = 'OapfStatus' THEN
               x_voidresp_rec.Response.Status := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfCode' THEN
               x_voidresp_rec.Response.ErrCode := l_values(i);
            ELSIF l_names(i) = 'OapfCause' THEN
               x_voidresp_rec.Response.ErrMessage := l_values(i);
            ELSIF l_names(i) = 'OapfNlsLang' THEN
               x_voidresp_rec.Response.NLS_LANG := l_values(i);

            --VOID Operation Specific Response
            ELSIF l_names(i) = 'OapfTransactionId' THEN
               x_voidresp_rec.Trxn_ID := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfTrxnType' THEN
               x_voidresp_rec.Trxn_Type := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfTrxnDate' THEN
	       x_voidresp_rec.Trxn_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');
	    --
	    -- for bug #1649833 to return a more accurate trxn
	    -- date use the 'OapfTimestamp' parameter if present
	    --

	    ELSIF l_names(i) = 'OapfTimestamp' THEN
	       v_trxnTimestamp := TO_DATE(l_values(i),'YYYYMMDDHH24MISS');

	    --
            ELSIF l_names(i) = 'OapfPmtInstrType' THEN
               x_voidresp_rec.PmtInstr_Type := l_values(i);
            ELSIF l_names(i) = 'OapfRefcode' THEN
               x_voidresp_rec.Refcode := l_values(i);
            ELSIF l_names(i) = 'OapfErrLocation' THEN
               x_voidresp_rec.ErrorLocation := l_values(i);
            ELSIF l_names(i) = 'OapfVendErrCode' THEN
               x_voidresp_rec.BEPErrCode := l_values(i);
            ELSIF l_names(i) = 'OapfVendErrmsg' THEN
               x_voidresp_rec.BEPErrMessage := l_values(i);

            --OFFLINE Payment Mode Related Response
            ELSIF l_names(i) = 'OapfEarliestSettlementDate' THEN
               x_voidresp_rec.OffLineResp.EarliestSettlement_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');
            ELSIF l_names(i) = 'OapfSchedDate' THEN
               x_voidresp_rec.OffLineResp.Scheduled_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');

            END IF;
        END LOOP;

	-- use the more accurate time stampe parameter if returned
	--

	IF NOT (v_trxnTimestamp IS NULL) THEN
	   x_voidresp_rec.Trxn_Date := v_trxnTimestamp;
	END IF;

        -- Setting API return status to 'U' if iPayment response status is not 0.
        IF (NOT trxn_status_success(x_voidresp_rec.Response.Status)) THEN
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        END IF;

        -- END OF BODY OF API


        -- Standard check of p_commit.
	/*
        IF FND_API.To_Boolean( p_commit ) THEN
           COMMIT WORK;
        END IF;
	*/

        -- Standard call to get message count and if count is 1, get message info.
        FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                    p_data   =>   x_msg_data
                                  );
   EXCEPTION
      WHEN FND_API.G_EXC_ERROR THEN
         --ROLLBACK TO OraPmtVoid_PUB;
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         --ROLLBACK TO OraPmtVoid_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN OTHERS THEN
         --ROLLBACK TO OraPmtVoid_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_api_name);
         END IF;

         FND_MSG_PUB.Count_And_Get ( p_count  =>  x_msg_count,
                                     p_data   =>  x_msg_data
                                   );

   END OraPmtVoid;

--------------------------------------------------------------------------------------------
		--8. OraPmtCredit
        -- Start of comments
        --   API name        : OraPmtCredit
        --   Type            : Public
        --   Pre-reqs        : None
        --   Function        : Handles Credit transaction operations such as making
        --                     credit payments/discounts to payer accounts.
        --   Parameters      :
        --     IN            : p_api_version       IN    NUMBER              Required
        --                     p_init_msg_list     IN    VARCHAR2            Optional
        --                     p_commit            IN    VARCHAR2            Optional
        --                     p_validation_level  IN    NUMBER              Optional
        --                     p_ecapp_id          IN    NUMBER              Required
        --                     p_payee_rec         IN    Payee_rec_type      Required
        --                     p_pmtinstr_rec      IN    PmtInstr_rec_type   Required
        --                     p_tangible_rec      IN    Tangible_rec_type   Required
        --                     p_credittrxn_rec    IN    CreditTrxn_rec_type Required
        --   Version :
        --     Current version      1.0
        --     Previous version     1.0
        --     Initial version      1.0
        -- End of comments
--------------------------------------------------------------------------------------------
  PROCEDURE OraPmtCredit ( p_api_version	IN	NUMBER,
			   p_init_msg_list	IN	VARCHAR2  := FND_API.G_FALSE,
			   p_commit		IN	VARCHAR2 := FND_API.G_FALSE,
			   p_validation_level	IN	NUMBER  := FND_API.G_VALID_LEVEL_FULL,
			   p_ecapp_id 		IN	NUMBER,
                           p_payee_rec          IN      Payee_rec_type,
                           p_pmtinstr_rec       IN      PmtInstr_rec_type,
                           p_tangible_rec       IN      Tangible_rec_type,
			   p_credittrxn_rec 	IN	CreditTrxn_rec_type,
			   x_return_status	OUT NOCOPY VARCHAR2,
			   x_msg_count		OUT NOCOPY NUMBER,
			   x_msg_data		OUT NOCOPY VARCHAR2,
			   x_creditresp_rec	OUT NOCOPY CreditResp_rec_type
			 ) IS

        --l_get_baseurl   VARCHAR2(2000) :=
        --  'http://alchen-sun.us.oracle.com:80/jservlets/11i/oracle.apps.iby.ecservlet.ECServlet?';
        --l_get_baseurl   VARCHAR2(2000) := FND_PROFILE.VALUE('IPAYMENT_BASEURL');

        l_get_baseurl   VARCHAR2(2000);
        --The following 3 variables are meant for output of
        --get_baseurl procedure.
        l_status_url    VARCHAR2(2000);
        l_msg_count_url NUMBER := 0;
        l_msg_data_url  VARCHAR2(2000);

        l_api_name     CONSTANT  VARCHAR2(30) := 'OraPmtCredit';
        l_oapf_action  CONSTANT  VARCHAR2(30) := 'oraPmtCredit';
        l_api_version  CONSTANT  NUMBER := 1.0;

        TYPE l_v240_tbl IS TABLE of VARCHAR2(240) INDEX BY BINARY_INTEGER;
        l_url           VARCHAR2(4000) ;
        l_html          VARCHAR2(7000) ;
        l_names         v240_tbl_type;
        l_values        v240_tbl_type;

        --The following 3 variables are meant for unpack_results_url procedure.
        l_status       NUMBER := 0;
        l_errcode      NUMBER := 0;
        l_errmessage   VARCHAR2(2000) := 'Success';

	-- for NLS bug fix #1692300 - 4/3/2001 jleybovi
	--
	l_db_nls       p_credittrxn_rec.NLS_LANG%TYPE := NULL;
	l_ecapp_nls    p_credittrxn_rec.NLS_LANG%TYPE := NULL;

        --Defining a local variable to hold the payment instrument type.
        l_pmtinstr_type VARCHAR2(200);
        CURSOR pmtcredit_csr IS
               SELECT instrtype
               FROM   IBY_INSTR_HOLDER_V
               WHERE  instrid = p_pmtinstr_rec.PmtInstr_ID;

   BEGIN
        -- Standard Start of API savepoint
        --SAVEPOINT  OraPmtCredit_PUB;

        /* ***** Performing Validations, Initializations
	         for Standard IN, OUT Parameters ***** */

        -- Standard call to check for call compatibility.
        IF NOT FND_API.Compatible_API_Call ( l_api_version,
                                             p_api_version,
                                             l_api_name,
                                             G_PKG_NAME )
        THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        -- Initialize message list if p_init_msg_list is set to TRUE.
        IF FND_API.to_Boolean( p_init_msg_list ) THEN
           FND_MSG_PUB.initialize;
        END IF;

        -- Verifying if validation level is FULL, which is expected for PUBLIC APIs.
        IF (p_validation_level <> g_validation_level) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204401_VAL_LEVEL_ERROR');
           FND_MSG_PUB.Add;
           RAISE  FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --  Initialize API return status to success
        x_return_status := FND_API.G_RET_STS_SUCCESS;


        -- START OF BODY OF API

        get_baseurl(l_get_baseurl);

        -- Construct the full URL to send to the ECServlet.
        l_url := l_get_baseurl;

	l_db_nls := iby_utility_pvt.get_local_nls();
	l_ecapp_nls := p_credittrxn_rec.NLS_LANG;

        --1. MANDATORY INPUT PARAMETERS
        check_mandatory('OapfAction', l_oapf_action, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfECAppId', to_char(p_ecapp_id), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfStoreId', p_payee_rec.Payee_ID, l_url, l_db_nls, l_ecapp_nls);

	/*
        --check if mode is supplied, if not, use 'ONLINE' default
        IF p_credittrxn_rec.PmtMode IS NULL THEN
           check_optional('OapfMode', 'ONLINE', l_url, l_db_nls, l_ecapp_nls);
        ELSE
           check_optional('OapfMode', p_credittrxn_rec.PmtMode, l_url, l_db_nls, l_ecapp_nls);
        END IF;
	*/
        -- the mode has to be mandatory as per the specifications
        check_mandatory('OapfMode', p_credittrxn_rec.PmtMode, l_url, l_db_nls, l_ecapp_nls);

        --Tangible Related Mandatory Input
        check_mandatory('OapfOrderId', p_tangible_rec.Tangible_ID, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfPrice', FND_NUMBER.NUMBER_TO_CANONICAL(p_tangible_rec.Tangible_Amount), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfCurr', p_tangible_rec.Currency_Code, l_url, l_db_nls, l_ecapp_nls);



        --Determine the Payment Instrument type that is used.
        IF (p_pmtinstr_rec.CreditCardInstr.CC_Num IS NOT NULL) THEN
           l_pmtinstr_type := 'CREDITCARD';
        ELSIF (p_pmtinstr_rec.PurchaseCardInstr.PC_Num IS NOT NULL) THEN
           l_pmtinstr_type := 'PURCHASECARD';
 	      --ELSE
        --ELSIF (p_pmtinstr_rec.BankAcctInstr.BankAcct_Num IS NOT NULL) THEN
        --l_pmtinstr_type := 'BANKACCOUNT';
        --/* NOTE *: REJECT BANK ACCOUNT INSTRUMENT FOR CREDIT OPERATION */
        --FND_MESSAGE.SET_NAME('IBY', 'IBY_204405_INVALID_INSTR_ERROR');
        --FND_MSG_PUB.Add;
        --RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --CONDITIONALLY MANDATORY INPUT PARAMETERS

        --2. CONDITIONALLY MANDATORY INPUT PARAMETERS

        --Payment Mode related Conditional Mandatory Input Parameters
        IF (p_credittrxn_rec.PmtMode = 'OFFLINE') THEN
           check_mandatory('OapfSchedDate', to_char(p_credittrxn_rec.Settlement_Date, 'YYYY-MM-DD'), l_url, l_db_nls, l_ecapp_nls);
        END IF;

        --1. Instrument related conditionally mandatory input
        --a. CreditCard instrument related conditionally mandatory input
        IF (l_pmtinstr_type = 'CREDITCARD') THEN

           -- Assign the value for 'OapfPmtInstrType' to 'CREDITCARD' and append to URL.
           check_optional('OapfPmtInstrType', 'CREDITCARD', l_url, l_db_nls, l_ecapp_nls);

           check_mandatory('OapfPmtInstrID',
             iby_creditcard_pkg.Get_Secured_Card_Number(p_pmtinstr_rec.CreditCardInstr.CC_Num),
             l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrExp', to_char(p_pmtinstr_rec.CreditCardInstr.CC_ExpDate, 'YYYY-MM-DD'), l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCCType', p_pmtinstr_rec.CreditCardInstr.CC_Type, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCustName', p_pmtinstr_rec.CreditCardInstr.CC_HolderName, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfFIName', p_pmtinstr_rec.CreditCardInstr.FIName, l_url, l_db_nls, l_ecapp_nls);

           --Address related Conditional Mandatory Input Parameters
           IF (p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Address1 IS NOT NULL)
           OR (p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.City  IS NOT NULL)
           OR (p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.State IS NOT NULL)
           OR (p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.PostalCode IS NOT NULL) THEN

              check_optional('OapfAddr1', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Address1, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfCity', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.City, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfState', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.State, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfPostalCode', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.PostalCode, l_url, l_db_nls, l_ecapp_nls);
           END IF;

        --b. PurchaseCard instrument related conditionally mandatory input
        ELSIF (l_pmtinstr_type = 'PURCHASECARD') THEN

           -- Assign the value for 'OapfPmtInstrType' to 'PURCHASECARD' and append to URL.
           check_optional('OapfPmtInstrType', 'PURCHASECARD', l_url, l_db_nls, l_ecapp_nls);

           check_mandatory('OapfPmtInstrID',
             iby_creditcard_pkg.Get_Secured_Card_Number(p_pmtinstr_rec.PurchaseCardInstr.PC_Num),
             l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrExp', to_char(p_pmtinstr_rec.PurchaseCardInstr.PC_ExpDate, 'YYYY-MM-DD'), l_url, l_db_nls, l_ecapp_nls);

           check_mandatory('OapfCardSubType', p_pmtinstr_rec.PurchaseCardInstr.PC_Subtype, l_url, l_db_nls, l_ecapp_nls);

           check_optional('OapfCCType', p_pmtinstr_rec.PurchaseCardInstr.PC_Type, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCustName', p_pmtinstr_rec.PurchaseCardInstr.PC_HolderName, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfFIName', p_pmtinstr_rec.PurchaseCardInstr.FIName, l_url, l_db_nls, l_ecapp_nls);

           --Address related Conditional Mandatory Input Parameters
           IF (p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Address1 IS NOT NULL)
           OR (p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.City  IS NOT NULL)
           OR (p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.State IS NOT NULL)
           OR (p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.PostalCode IS NOT NULL) THEN

              check_optional('OapfAddr1', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Address1, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfCity', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.City, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfState', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.State, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfPostalCode', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.PostalCode, l_url, l_db_nls, l_ecapp_nls);
        END IF;

        /* NOT SUPPORTING BANKACCOUNT OPERATION FOR 11i
        ELSIF (l_pmtinstr_type = 'BANKACCOUNT') THEN
           --b. BankAccount instrument related conditionally mandatory input

           -- Assign the value for 'OapfPmtInstrType' to 'BANKACCOUNT' and append to URL.
           check_optional('OapfPmtInstrType', 'BANKACCOUNT', l_url, l_db_nls, l_ecapp_nls);

           check_mandatory('OapfBankId', p_pmtinstr_rec.BankAcctInstr.Bank_ID, l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrID', p_pmtinstr_rec.BankAcctInstr.BankAcct_Num, l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfAcctType', p_pmtinstr_rec.BankAcctInstr.BankAcct_Type, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfBranchId', p_pmtinstr_rec.BankAcctInstr.Branch_ID, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfFIName', p_pmtinstr_rec.BankAcctInstr.FIName, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCustName', p_pmtinstr_rec.BankAcctInstr.BankAcct_HolderName, l_url, l_db_nls, l_ecapp_nls);
        */

        ELSE
           --a. REGISTERED INSTRUMENT RELATED CONDITIONALLY MANDATORY INPUT
           check_mandatory('OapfPmtRegId', to_char(p_pmtinstr_rec.PmtInstr_ID), l_url, l_db_nls, l_ecapp_nls);

--dbms_output.put_line('Before opening cursor');
           --Query DB to get the PmtInstrType from Instrument Registration ID, pass to ECServlet.
             OPEN pmtcredit_csr;
            FETCH pmtcredit_csr
             INTO l_pmtinstr_type;

            IF (pmtcredit_csr%ROWCOUNT = 0) THEN
              FND_MESSAGE.SET_NAME('IBY', 'IBY_204404_CURSOR_ERROR');
              FND_MSG_PUB.Add;
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            END IF;

            CLOSE pmtcredit_csr;
--dbms_output.put_line('after closing cursor');
            check_mandatory('OapfPmtInstrType', l_pmtinstr_type, l_url, l_db_nls, l_ecapp_nls);

        END IF;

        --3. Address related Conditional Mandatory Input Parameters

        -- Credit Card
	--
            check_optional('OapfAddr1', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Address1, l_url, l_db_nls, l_ecapp_nls);
            check_optional('OapfCity', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.City, l_url, l_db_nls, l_ecapp_nls);
            check_optional('OapfState', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.State, l_url, l_db_nls, l_ecapp_nls);
            check_optional('OapfPostalCode', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.PostalCode, l_url, l_db_nls, l_ecapp_nls);

        -- Purchase card
	--
            check_optional('OapfAddr1', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Address1, l_url, l_db_nls, l_ecapp_nls);
            check_optional('OapfCity', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.City, l_url, l_db_nls, l_ecapp_nls);
            check_optional('OapfState', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.State, l_url, l_db_nls, l_ecapp_nls);
            check_optional('OapfPostalCode', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.PostalCode, l_url, l_db_nls, l_ecapp_nls);


        --OPTIONAL INPUT PARAMETERS

        --Instrument related optional input
        check_optional('OapfInstrName', p_pmtinstr_rec.PmtInstr_ShortName, l_url, l_db_nls, l_ecapp_nls);

        --Tangible related optional input
        check_optional('OapfRefNumber', p_tangible_rec.RefInfo, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfMemo', p_tangible_rec.Memo, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfAcctNumber', p_tangible_rec.Acct_Num, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfOrderMedium', p_tangible_rec.OrderMedium, l_url, l_db_nls, l_ecapp_nls);
        -- no need to pass the EFTAuthMethod in the Credit API.  It is not called for ACH transactions

        --Address related optional input
        IF ( l_pmtinstr_type = 'CREDITCARD') THEN
          check_optional('OapfAddr2',p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Address2, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfAddr3',p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Address3, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfCnty', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.County, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfCntry', p_pmtinstr_rec.CreditCardInstr.CC_BillingAddr.Country, l_url, l_db_nls, l_ecapp_nls);
        ELSIF ( l_pmtinstr_type = 'PURCHASECARD') THEN
          check_optional('OapfAddr2',p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Address2, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfAddr3',p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Address3, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfCnty', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.County, l_url, l_db_nls, l_ecapp_nls);
          check_optional('OapfCntry', p_pmtinstr_rec.PurchaseCardInstr.PC_BillingAddr.Country, l_url, l_db_nls, l_ecapp_nls);
        END IF;

        check_optional('OapfRetry', p_credittrxn_rec.Retry_Flag, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfOrgId', to_char(p_credittrxn_rec.Org_ID), l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfNlsLang', p_credittrxn_rec.NLS_LANG, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfTrxnRef', p_credittrxn_rec.TrxnRef, l_url, l_db_nls, l_ecapp_nls);

        -- Remove ampersand from the last input parameter.
	l_url := RTRIM(l_url,'&');

	-- already done in escape_url_chars
	--
	-- ^^^ Replace blank characters with + sign. ^^^
	-- l_url := REPLACE(l_url,' ','+');
--show_input_debug(l_url);

        --  Send HTTP request to ipayment servlet
        -- l_html := UTL_HTTP.REQUEST(l_url);
	SEND_REQUEST(l_url, l_html);

--show_output_debug(l_html);

        -- Parse the resulting HTML page
	UNPACK_RESULTS_URL(l_html,l_names,l_values, l_status, l_errcode, l_errmessage);

        --Raising Exception to handle errors in unpacking resulting html file.
        IF (l_status = -1) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204403_HTML_UNPACK_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --Raising Exception to handle Servlet related errors.
        IF (l_names.COUNT = 0) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204402_JSERVLET_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

--show_table_debug(l_names);
--show_table_debug(l_values);

        -- Assign output parameters to output record x_creditresp_rec
        FOR i IN 1..l_names.COUNT LOOP

            --Payment Server Related Generic Response
            IF l_names(i) = 'OapfStatus' THEN
               x_creditresp_rec.Response.Status := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfCode' THEN
               x_creditresp_rec.Response.ErrCode := l_values(i);
            ELSIF l_names(i) = 'OapfCause' THEN
               x_creditresp_rec.Response.ErrMessage := l_values(i);
            ELSIF l_names(i) = 'OapfNlsLang' THEN
               x_creditresp_rec.Response.NLS_LANG := l_values(i);

            --Credit Operation Related Response
            ELSIF l_names(i) = 'OapfTransactionId' THEN
               x_creditresp_rec.Trxn_ID := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfTrxnType' THEN
               x_creditresp_rec.Trxn_Type := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfTrxnDate' THEN
               x_creditresp_rec.Trxn_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');
            ELSIF l_names(i) = 'OapfPmtInstrType' THEN
               x_creditresp_rec.PmtInstr_Type := l_values(i);
            ELSIF l_names(i) = 'OapfRefCode' THEN
               x_creditresp_rec.Refcode := l_values(i);
            ELSIF l_names(i) = 'OapfErrLocation' THEN
               x_creditresp_rec.ErrorLocation := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfVendErrCode' THEN
               x_creditresp_rec.BEPErrCode := l_values(i);
            ELSIF l_names(i) = 'OapfVendErrmsg' THEN
               x_creditresp_rec.BEPErrMessage := l_values(i);

            --OFFLINE Payment Mode Related Response
            ELSIF l_names(i) = 'OapfEarliestSettlementDate' THEN
               x_creditresp_rec.OffLineResp.EarliestSettlement_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');
            ELSIF l_names(i) = 'OapfSchedDate' THEN
               x_creditresp_rec.OffLineResp.Scheduled_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');

            END IF;
        END LOOP;

        -- Setting API return status to 'U' if iPayment response status is not 0.
        IF (NOT trxn_status_success(x_creditresp_rec.Response.Status)) THEN
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        END IF;

        -- END OF BODY OF API

        -- Standard check of p_commit.
	/*
        IF FND_API.To_Boolean( p_commit ) THEN
           COMMIT WORK;
        END IF;
	*/

        -- Standard call to get message count and if count is 1, get message info.
        FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                    p_data   =>   x_msg_data
                                  );
   EXCEPTION
      WHEN FND_API.G_EXC_ERROR THEN
         --ROLLBACK TO OraPmtCredit_PUB;
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         --ROLLBACK TO OraPmtCredit_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN OTHERS THEN
         --ROLLBACK TO OraPmtCredit_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_api_name);
         END IF;

         FND_MSG_PUB.Count_And_Get ( p_count  =>  x_msg_count,
                                     p_data   =>  x_msg_data
                                   );

   END OraPmtCredit;

--------------------------------------------------------------------------------------------
		--9. OraPmtInq
        -- Start of comments
        --   API name        : OraPmtInq
        --   Type            : Public
        --   Pre-reqs        : None
        --   Function        : Provides high-level payment information such as Payee,
        --                     Payer, Instrument, and Tangible related information.
        --   Parameters      :
        --     IN            : p_api_version       IN    NUMBER       Required
        --                     p_init_msg_list     IN    VARCHAR2     Optional
        --                     p_commit            IN    VARCHAR2     Optional
        --                     p_validation_level  IN    NUMBER       Optional
        --                     p_ecapp_id          IN    NUMBER       Required
        --                     p_tid               IN    NUMBER       Required
        --   Version :
        --     Current version      1.0
        --     Previous version     1.0
        --     Initial version      1.0
        -- End of comments
--------------------------------------------------------------------------------------------
  PROCEDURE OraPmtInq ( p_api_version		IN	NUMBER,
			p_init_msg_list		IN	VARCHAR2  := FND_API.G_FALSE,
			p_commit	        IN	VARCHAR2 := FND_API.G_FALSE,
			p_validation_level	IN	NUMBER  := FND_API.G_VALID_LEVEL_FULL,
			p_ecapp_id		IN	NUMBER,
			p_tid			IN	NUMBER,
			x_return_status		OUT NOCOPY VARCHAR2,
			x_msg_count		OUT NOCOPY NUMBER,
			x_msg_data		OUT NOCOPY VARCHAR2,
			x_inqresp_rec		OUT NOCOPY InqResp_rec_type
		      ) IS


        l_api_name     CONSTANT  VARCHAR2(30) := 'OraPmtInq';
        l_oapf_action  CONSTANT  VARCHAR2(30) := 'oraPmtInq';
        l_api_version  CONSTANT  NUMBER := 1.0;

        TYPE l_v240_tbl IS TABLE of VARCHAR2(240) INDEX BY BINARY_INTEGER;
        l_url           VARCHAR2(4000) ;
        l_html          VARCHAR2(7000) ;
        l_names         v240_tbl_type;
        l_values        v240_tbl_type;


        CURSOR pmtinq_csr IS
        	SELECT payeeid,
               	       payerid,
                       payerinstrid,
               	       tangibleid,
               	       amount,
               	       currencyNameCode,
               	       acctNo,
               	       refInfo,
               	       memo
          	 FROM  IBY_PAYMENTS_V
         	WHERE  ecappid = p_ecapp_id
           	  AND  transactionid = p_tid
             ORDER BY  payeeid, payerid, tangibleid;

   BEGIN

        -- Standard Start of API savepoint
        --SAVEPOINT  OraPmtInq_PUB;

        /* ***** Performing Validations, Initializations
	         for Standard IN, OUT Parameters ***** */

        -- Standard call to check for call compatibility.
        IF NOT FND_API.Compatible_API_Call ( l_api_version,
                                             p_api_version,
                                             l_api_name,
                                             G_PKG_NAME )
        THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        -- Initialize message list if p_init_msg_list is set to TRUE.
        IF FND_API.to_Boolean( p_init_msg_list ) THEN
           FND_MSG_PUB.initialize;
        END IF;

        -- Verifying if validation level is FULL, which is expected for PUBLIC APIs.
        IF (p_validation_level <> g_validation_level) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204401_VAL_LEVEL_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --  Initialize API return status to success
        x_return_status := FND_API.G_RET_STS_SUCCESS;

        -- START OF BODY OF API

--dbms_output.put_line('Before opening cursor');

          OPEN pmtinq_csr;
         FETCH pmtinq_csr
          INTO x_inqresp_rec.Payee.Payee_ID,
               x_inqresp_rec.Payer.Payer_ID,
               x_inqresp_rec.PmtInstr.PmtInstr_ID,
               x_inqresp_rec.Tangible.Tangible_ID,
               x_inqresp_rec.Tangible.Tangible_Amount,
               x_inqresp_rec.Tangible.Currency_Code,
               x_inqresp_rec.Tangible.Acct_Num,
               x_inqresp_rec.Tangible.RefInfo,
               x_inqresp_rec.Tangible.Memo;

         IF (pmtinq_csr%ROWCOUNT = 0) THEN
           x_inqresp_rec.Response.Status := 3;
           -- NOTE: Response.ErrCode, Response.ErrMessage are not populated
           -- since that would imply hardcoding the message text here (NLS issues)
           -- Instead it is sent to the API message list.
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204404_CURSOR_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
         END IF;

         CLOSE pmtinq_csr;

--dbms_output.put_line('after closing cursor');

        x_inqresp_rec.Response.Status := 0;
        -- END OF BODY OF API


        -- Standard check of p_commit.
	/*
        IF FND_API.To_Boolean( p_commit ) THEN
           COMMIT WORK;
        END IF;
	*/

        -- Standard call to get message count and if count is 1, get message info.
        FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                    p_data   =>   x_msg_data
                                  );
   EXCEPTION
      WHEN FND_API.G_EXC_ERROR THEN
         --ROLLBACK TO OraPmtInq_PUB;
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         --ROLLBACK TO OraPmtInq_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN OTHERS THEN
         --ROLLBACK TO OraPmtInq_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_api_name);
         END IF;

         FND_MSG_PUB.Count_And_Get ( p_count  =>  x_msg_count,
                                     p_data   =>  x_msg_data
                                   );

   END OraPmtInq;

--------------------------------------------------------------------------------------------
		--10. OraPmtCloseBatch
        -- Start of comments
        --   API name        : OraPmtCloseBatch
        --   Type            : Public
        --   Pre-reqs        : None
        --   Function        : Closes the existing current batch of transactions and
        --                     opens a new batch.  The operaions that can be included
        --                     are Capture, Return, and Credit. This operation is
        --                     mandatory for terminal-based merchants.
        --   Parameters      :
        --     IN            : p_api_version       IN    NUMBER              Required
        --                     p_init_msg_list     IN    VARCHAR2            Optional
        --                     p_commit            IN    VARCHAR2            Optional
        --                     p_validation_level  IN    NUMBER              Optional
        --                     p_ecapp_id          IN    NUMBER              Required
        --                     p_batchtrxn_rec     IN    BatchTrxn_rec_type  Required
        --   Version :
        --     Current version      1.0
        --     Previous version     1.0
        --     Initial version      1.0
        -- End of comments
--------------------------------------------------------------------------------------------
  PROCEDURE OraPmtCloseBatch ( p_api_version	         IN	NUMBER,
		  	       p_init_msg_list	         IN	VARCHAR2  := FND_API.G_FALSE,
			       p_commit		         IN	VARCHAR2  := FND_API.G_FALSE,
			       p_validation_level        IN     NUMBER  := FND_API.G_VALID_LEVEL_FULL,
			       p_ecapp_id		 IN	NUMBER,
			       p_batchtrxn_rec	         IN	BatchTrxn_rec_type,
			       x_return_status	       OUT NOCOPY VARCHAR2,
			       x_msg_count	       OUT NOCOPY NUMBER,
			       x_msg_data	       OUT NOCOPY VARCHAR2,
			       x_closebatchrespsum_rec OUT NOCOPY BatchRespSum_rec_type,
			       x_closebatchrespdet_tbl OUT NOCOPY BatchRespDet_tbl_type
			     ) IS

        --l_get_baseurl   VARCHAR2(2000) :=
        --  'http://alchen-sun.us.oracle.com:80/jservlets/11i/oracle.apps.iby.ecservlet.ECServlet?';
        --l_get_baseurl   VARCHAR2(2000) := FND_PROFILE.VALUE('IPAYMENT_BASEURL');

        l_get_baseurl   VARCHAR2(2000);
        --The following 3 variables are meant for output of
        --get_baseurl procedure.
        l_status_url    VARCHAR2(2000);
        l_msg_count_url NUMBER := 0;
        l_msg_data_url  VARCHAR2(2000);

        l_api_name     CONSTANT  VARCHAR2(30) := 'OraPmtCloseBatch';
        l_oapf_action  CONSTANT  VARCHAR2(30) := 'oraPmtCloseBatch';
        l_api_version  CONSTANT  NUMBER := 1.0;

        TYPE l_v240_tbl IS TABLE of VARCHAR2(240) INDEX BY BINARY_INTEGER;
        l_url           VARCHAR2(4000) ;
        l_html          VARCHAR2(7000) ;
        l_names         v240_tbl_type;
        l_values        v240_tbl_type;

        --The following 3 variables are meant for unpack_results_url procedure.
        l_status       NUMBER := 0;
        l_errcode      NUMBER := 0;
        l_errmessage   VARCHAR2(2000) := 'Success';

        --Local variable to handle detail response table of records index
        l_index	       NUMBER := 0;

	-- for NLS bug fix #1692300 - 4/3/2001 jleybovi
	--
	l_db_nls	p_batchtrxn_rec.NLS_LANG%TYPE := NULL;
	l_ecapp_nls	p_batchtrxn_rec.NLS_LANG%TYPE := NULL;

   BEGIN

        -- Standard Start of API savepoint
        --SAVEPOINT  OraPmtCloseBatch_PUB;

        /* ***** Performing Validations, Initializations
	         for Standard IN, OUT Parameters ***** */

        -- Standard call to check for call compatibility.
        IF NOT FND_API.Compatible_API_Call ( l_api_version,
                                             p_api_version,
                                             l_api_name,
                                             G_PKG_NAME )
        THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        -- Initialize message list if p_init_msg_list is set to TRUE.
        IF FND_API.to_Boolean( p_init_msg_list ) THEN
           FND_MSG_PUB.initialize;
        END IF;

        -- Verifying if validation level is FULL, which is expected for PUBLIC APIs.
        IF (p_validation_level <> g_validation_level) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204401_VAL_LEVEL_ERROR');
           FND_MSG_PUB.Add;
           RAISE  FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;


        --  Initialize API return status to success
        x_return_status := FND_API.G_RET_STS_SUCCESS;

        -- START OF BODY OF API

        get_baseurl(l_get_baseurl);

        -- Construct the full URL to send to the ECServlet.
        l_url := l_get_baseurl;

	l_db_nls := iby_utility_pvt.get_local_nls();
	l_ecapp_nls:= p_batchtrxn_rec.NLS_LANG;

        --1. MANDATORY INPUT PARAMETERS

        check_mandatory('OapfAction', l_oapf_action, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfECAppId', to_char(p_ecapp_id), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfStoreId', p_batchtrxn_rec.Payee_ID, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfMerchBatchId', p_batchtrxn_rec.MerchBatch_ID, l_url, l_db_nls, l_ecapp_nls);
	--
	-- fix for bug # 2129295
	--
	check_mandatory('OapfBEPSuffix', p_batchtrxn_rec.BEP_Suffix, l_url, l_db_nls, l_ecapp_nls);
	check_mandatory('OapfBEPAccount', p_batchtrxn_rec.BEP_Account, l_url, l_db_nls, l_ecapp_nls);

	/*
        --check if mode is supplied, if not use 'ONLINE' default
        IF p_batchtrxn_rec.PmtMode IS NULL THEN
           check_optional('OapfMode', 'ONLINE', l_url, l_db_nls, l_ecapp_nls);
        ELSE
           check_optional('OapfMode', p_batchtrxn_rec.PmtMode, l_url, l_db_nls, l_ecapp_nls);
        END IF;
	*/
        -- the mode has to be mandatory as per the specifications
        check_mandatory('OapfMode', p_batchtrxn_rec.PmtMode, l_url, l_db_nls, l_ecapp_nls);

        --2. Payment Mode related Conditionally Mandatory Input Parameters
        IF (p_batchtrxn_rec.PmtMode = 'OFFLINE') THEN
           check_mandatory('OapfSchedDate', to_char(p_batchtrxn_rec.Settlement_Date, 'YYYY-MM-DD'), l_url, l_db_nls, l_ecapp_nls);
        END IF;

        --3. OPTIONAL INPUT PARAMETERS

        check_optional('OapfPmtType', p_batchtrxn_rec.PmtType, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfPmtInstrType',p_batchtrxn_rec.PmtInstrType,l_url,l_db_nls,l_ecapp_nls);
        check_optional('OapfNlsLang', p_batchtrxn_rec.NLS_LANG, l_url, l_db_nls, l_ecapp_nls);

        -- Remove ampersand from the last input parameter.
	l_url := RTRIM(l_url,'&');

	-- now done in escape_url_chars()
	--
        -- ^^^^ Replace blank characters with + sign. ^^^
	-- l_url := REPLACE(l_url,' ','+');

--dbms_output.put_line('before utl_http call');
--show_input_debug(l_url);

        -- Send http request to the payment server.
        -- l_html := UTL_HTTP.REQUEST(l_url);
    
	SEND_REQUEST(l_url, l_html);     

--dbms_output.put_line('after utl_http call');
--show_output_debug(l_html);

        -- Unpack the results
	--l_html := '<H2>Results</H2>OapfStatus: 0<BR>';

	UNPACK_RESULTS_URL(l_html,l_names,l_values, l_status, l_errcode, l_errmessage);

        --Raising Exception to handle errors in unpacking resulting html file.
        IF (l_status = -1) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204403_HTML_UNPACK_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --Raising Exception to handle Servlet related errors.
        IF (l_names.COUNT = 0) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204402_JSERVLET_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

--show_table_debug(l_names);
--show_table_debug(l_values);

        /* Retrieve name-value pairs stored in l_names and l_values, and assign
           them to the output table of records:  x_closebatchrespdet_tbl
        */

        FOR i IN 1..l_names.COUNT LOOP

            -- MAPPING NAME-VALUE PAIRS TO CLOSEBATCH SUMMARY RESPONSE RECORD

            -- Payment Server generic response.
            IF l_names(i) = 'OapfStatus' THEN

               x_closebatchrespsum_rec.Response.Status := TO_NUMBER(l_values(i));
		
            ELSIF l_names(i) = 'OapfCode' THEN
               x_closebatchrespsum_rec.Response.ErrCode := l_values(i);
            ELSIF l_names(i) = 'OapfCause' THEN
               x_closebatchrespsum_rec.Response.ErrMessage := l_values(i);
            ELSIF l_names(i) = 'OapfNlsLang' THEN
               x_closebatchrespsum_rec.Response.NLS_LANG := l_values(i);

            -- OFFLINE PAYMENT MODE SPECIFIC RESPONSE
            ELSIF l_names(i) = 'OapfEarliestSettlementDate' THEN
               x_closebatchrespsum_rec.OffLineResp.EarliestSettlement_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');
            ELSIF l_names(i) = 'OapfSchedDate' THEN
               x_closebatchrespsum_rec.OffLineResp.Scheduled_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');

            -- OTHER SUMMARY RECORD RESPONSE OBJECTS
            ELSIF l_names(i) = 'OapfNumTrxns' THEN
               x_closebatchrespsum_rec.NumTrxns := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfMerchBatchId' THEN
               x_closebatchrespsum_rec.MerchBatch_ID := l_values(i);
            ELSIF l_names(i) = 'OapfBatchState' THEN
               x_closebatchrespsum_rec.BatchState := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfBatchDate' THEN
               x_closebatchrespsum_rec.BatchDate := TO_DATE(l_values(i), 'YYYY-MM-DD');
            ELSIF l_names(i) = 'OapfStoreId' THEN
               x_closebatchrespsum_rec.Payee_ID := l_values(i);
            ELSIF l_names(i) = 'OapfCreditAmount' THEN
               x_closebatchrespsum_rec.Credit_Amount := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfSalesAmount' THEN
               x_closebatchrespsum_rec.Sales_Amount := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfBatchTotal' THEN
               x_closebatchrespsum_rec.Batch_Total := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfCurr' THEN
               x_closebatchrespsum_rec.Currency := l_values(i);
            ELSIF l_names(i) = 'OapfVpsBatchID' THEN
               x_closebatchrespsum_rec.VpsBatch_ID := l_values(i);
            ELSIF l_names(i) = 'OapfGwBatchID' THEN
               x_closebatchrespsum_rec.GWBatch_ID := l_values(i);

            ELSIF l_names(i) = 'OapfErrLocation' THEN
               x_closebatchrespsum_rec.ErrorLocation := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfVendErrCode' THEN
               x_closebatchrespsum_rec.BEPErrCode := l_values(i);
            ELSIF l_names(i) = 'OapfVendErrmsg' THEN
               x_closebatchrespsum_rec.BEPErrMessage := l_values(i);

           -- MAPPING NAME-VALUE PAIRS TO CLOSEBATCH DETAIL RESPONSE TABLE OF RECORDS
            ELSIF INSTR(l_names(i), 'OapfTransactionId-') <> 0 THEN
               l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfTransactionId-') );
               x_closebatchrespdet_tbl(l_index).Trxn_ID := TO_NUMBER(l_values(i));
            ELSIF INSTR(l_names(i), 'OapfTrxnType-') <> 0 THEN
               l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfTrxnType-') );
               x_closebatchrespdet_tbl(l_index).Trxn_Type := TO_NUMBER(l_values(i));
            ELSIF INSTR(l_names(i), 'OapfTrxnDate-') <> 0 THEN
               l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfTrxnDate-') );
               x_closebatchrespdet_tbl(l_index).Trxn_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');

            ELSIF INSTR(l_names(i), 'OapfStatus-') <> 0 THEN
               l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfStatus-') );
               x_closebatchrespdet_tbl(l_index).Status := TO_NUMBER(l_values(i));
            ELSIF INSTR(l_names(i), 'OapfBatchErrLocation-') <> 0 THEN
               l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfBatchErrLocation-') );
               x_closebatchrespdet_tbl(l_index).ErrorLocation := TO_NUMBER(l_values(i));
            ELSIF INSTR(l_names(i), 'OapfBatchErrCode-') <> 0 THEN
               l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfBatchErrCode-') );
               x_closebatchrespdet_tbl(l_index).BEPErrCode := l_values(i);
            ELSIF INSTR(l_names(i), 'OapfBatchErrmsg-') <> 0 THEN
               l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfBatchErrmsg-') );
               x_closebatchrespdet_tbl(l_index).BEPErrMessage := l_values(i);
            ELSIF INSTR(l_names(i), 'OapfNlsLang-') <> 0 THEN
               l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfNlsLang-') );
               x_closebatchrespdet_tbl(l_index).NLS_LANG := l_values(i);

            END IF;

        END LOOP;

        -- Setting API return status to 'U' if iPayment response status is not 0.
        IF (NOT trxn_status_success(x_closebatchrespsum_rec.Response.Status)) THEN
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        END IF;

        -- END OF BODY OF API

        -- Standard check of p_commit.
	/*
        IF FND_API.To_Boolean( p_commit ) THEN
           COMMIT WORK;
        END IF;
	*/

        -- Standard call to get message count and if count is 1, get message info.
        FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                    p_data   =>   x_msg_data
                                  );
   EXCEPTION
      WHEN FND_API.G_EXC_ERROR THEN
         --ROLLBACK TO OraPmtCloseBatch_PUB;
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         --ROLLBACK TO OraPmtCloseBatch_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN OTHERS THEN
         --ROLLBACK TO OraPmtCloseBatch_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_api_name);
         END IF;

         FND_MSG_PUB.Count_And_Get ( p_count  =>  x_msg_count,
                                     p_data   =>  x_msg_data
                                   );

   END OraPmtCloseBatch;

--------------------------------------------------------------------------------------------
		--11. OraPmtQueryBatch
        -- Start of comments
        --   API name        : OraPmtQueryBatch
        --   Type            : Public
        --   Pre-reqs        : None
        --   Function        : Provides an interface to query the status of any previous
        --                     batch of transactions.
        --   Parameters      :
        --     IN            : p_api_version       IN    NUMBER              Required
        --                     p_init_msg_list     IN    VARCHAR2            Optional
        --                     p_commit            IN    VARCHAR2            Optional
        --                     p_validation_level  IN    NUMBER              Optional
        --                     p_ecapp_id          IN    NUMBER              Required
        --                     p_batchtrxn_rec     IN    BatchTrxn_rec_type  Required
        --   Version :
        --     Current version      1.0
        --     Previous version     1.0
        --     Initial version      1.0
        -- End of comments
--------------------------------------------------------------------------------------------
  PROCEDURE OraPmtQueryBatch ( p_api_version	    IN	  NUMBER,
			    p_init_msg_list	    IN	  VARCHAR2  := FND_API.G_FALSE,
			    p_commit		    IN	  VARCHAR2  := FND_API.G_FALSE,
			    p_validation_level	    IN	  NUMBER  := FND_API.G_VALID_LEVEL_FULL,
			    p_ecapp_id		    IN	  NUMBER,
			    p_batchtrxn_rec	    IN	  BatchTrxn_rec_type,
			    x_return_status	    OUT NOCOPY VARCHAR2,
			    x_msg_count             OUT NOCOPY NUMBER,
			    x_msg_data	            OUT NOCOPY VARCHAR2,
			    x_qrybatchrespsum_rec   OUT NOCOPY BatchRespSum_rec_type,
			    x_qrybatchrespdet_tbl   OUT NOCOPY BatchRespDet_tbl_type
			  ) IS

        --l_get_baseurl   VARCHAR2(2000) :=
        --  'http://alchen-sun.us.oracle.com:80/jservlets/11i/oracle.apps.iby.ecservlet.ECServlet?';
        --l_get_baseurl   VARCHAR2(2000) := FND_PROFILE.VALUE('IPAYMENT_BASEURL');

        l_get_baseurl   VARCHAR2(2000);
        --The following 3 variables are meant for output of
        --get_baseurl procedure.
        l_status_url    VARCHAR2(2000);
        l_msg_count_url NUMBER := 0;
        l_msg_data_url  VARCHAR2(2000);

        l_api_name     CONSTANT  VARCHAR2(30) := 'OraPmtQueryBatch';
        l_oapf_action  CONSTANT  VARCHAR2(30) := 'oraPmtQueryBatch';
        l_api_version  CONSTANT  NUMBER := 1.0;

        TYPE l_v240_tbl IS TABLE of VARCHAR2(240) INDEX BY BINARY_INTEGER;
        l_url           VARCHAR2(4000) ;
        l_html          VARCHAR2(7000) ;
        l_names         v240_tbl_type;
        l_values        v240_tbl_type;

        --The following 3 variables are meant for unpack_results_url procedure.
        l_status       NUMBER := 0;
        l_errcode      NUMBER := 0;
        l_errmessage   VARCHAR2(2000) := 'Success';

        --Local variable to handle detail response table of records index
        l_index	       NUMBER := 0;

	-- for NLS bug fix #1692300 - 4/3/2001 jleybovi
	--
	l_db_nls       p_batchtrxn_rec.NLS_LANG%TYPE := NULL;
	l_ecapp_nls    p_batchtrxn_rec.NLS_LANG%TYPE := NULL;

   BEGIN

        -- Standard Start of API savepoint
        --SAVEPOINT  OraPmtQueryBatch_PUB;

        /* ***** Performing Validations, Initializations
	         for Standard IN, OUT Parameters ***** */

        -- Standard call to check for call compatibility.
        IF NOT FND_API.Compatible_API_Call ( l_api_version,
                                             p_api_version,
                                             l_api_name,
                                             G_PKG_NAME )
        THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        -- Initialize message list if p_init_msg_list is set to TRUE.
        IF FND_API.to_Boolean( p_init_msg_list ) THEN
           FND_MSG_PUB.initialize;
        END IF;

        -- Verifying if validation level is FULL, which is expected for PUBLIC APIs.
        IF (p_validation_level <> g_validation_level) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204401_VAL_LEVEL_ERROR');
           FND_MSG_PUB.Add;
           RAISE  FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --  Initialize API return status to success
        x_return_status := FND_API.G_RET_STS_SUCCESS;


        -- START OF BODY OF API

        get_baseurl(l_get_baseurl);

        -- Construct the full URL to send to the ECServlet.
        l_url := l_get_baseurl;

	l_db_nls := iby_utility_pvt.get_local_nls();
	l_ecapp_nls := p_batchtrxn_rec.NLS_LANG;

        --Mandatory Input Parameters
        check_mandatory('OapfAction', l_oapf_action, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfECAppId', to_char(p_ecapp_id), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfStoreId', p_batchtrxn_rec.Payee_ID, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfMerchBatchId', p_batchtrxn_rec.MerchBatch_ID, l_url, l_db_nls, l_ecapp_nls);
	--
	-- fix for bug # 2129295
	--
	check_mandatory('OapfBEPSuffix', p_batchtrxn_rec.BEP_Suffix, l_url, l_db_nls, l_ecapp_nls);
	check_mandatory('OapfBEPAccount', p_batchtrxn_rec.BEP_Account, l_url, l_db_nls, l_ecapp_nls);

	/*
        --check if mode is supplied, if not use 'ONLINE' default
        IF p_batchtrxn_rec.PmtMode IS NULL THEN
           check_optional('OapfMode', 'ONLINE', l_url, l_db_nls, l_ecapp_nls);
        ELSE
           check_optional('OapfMode', p_batchtrxn_rec.PmtMode, l_url, l_db_nls, l_ecapp_nls);
        END IF;
	*/
        -- the mode has to be mandatory as per the specifications
        check_mandatory('OapfMode', p_batchtrxn_rec.PmtMode, l_url, l_db_nls, l_ecapp_nls);

        --Optional Input Parameters
        check_optional('OapfPmtType', p_batchtrxn_rec.PmtType, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfPmtInstrType',p_batchtrxn_rec.PmtInstrType,l_url,l_db_nls,l_ecapp_nls);
        check_optional('OapfNlsLang', p_batchtrxn_rec.NLS_LANG, l_url, l_db_nls, l_ecapp_nls);

        -- Remove ampersand from the last input parameter.
	l_url := RTRIM(l_url,'&');

	-- escape_url_chars does this now
	--
        -- ^^^ Replace blank characters with + sign. ^^^
        --l_url := REPLACE(l_url,' ','+');

--show_input_debug(l_url);

        -- Send http request to the payment server.
        -- l_html := UTL_HTTP.REQUEST(l_url);
	SEND_REQUEST(l_url, l_html);

--show_output_debug(l_html);

        -- Unpack the results
	UNPACK_RESULTS_URL(l_html,l_names,l_values, l_status, l_errcode, l_errmessage);

        --Raising Exception to handle errors in unpacking resulting html file.
        IF (l_status = -1) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204403_HTML_UNPACK_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --Raising Exception to handle Servlet related errors.
        IF (l_names.COUNT = 0) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204402_JSERVLET_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

--show_table_debug(l_names);
--show_table_debug(l_values);

        /* Retrieve name-value pairs stored in l_names and l_values, and assign
           them to the output table of records: x_qrybatchrespdet_tbl
        */

        FOR i IN 1..l_names.COUNT LOOP

            -- Mapping Name-Value Pairs to QueryBatch summary response record
            -- Payment Server generic response.
            IF l_names(i) = 'OapfStatus' THEN
               x_qrybatchrespsum_rec.Response.Status := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfCode' THEN
               x_qrybatchrespsum_rec.Response.ErrCode := l_values(i);
            ELSIF l_names(i) = 'OapfCause' THEN
               x_qrybatchrespsum_rec.Response.ErrMessage := l_values(i);
            ELSIF l_names(i) = 'OapfNlsLang' THEN
               x_qrybatchrespsum_rec.Response.NLS_LANG := l_values(i);

            -- OTHER SUMMARY RECORD RESPONSE OBJECTS
            ELSIF l_names(i) = 'OapfNumTrxns' THEN
               x_qrybatchrespsum_rec.NumTrxns := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfMerchBatchId' THEN
               x_qrybatchrespsum_rec.MerchBatch_ID := l_values(i);
            ELSIF l_names(i) = 'OapfBatchState' THEN
               x_qrybatchrespsum_rec.BatchState := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfBatchDate' THEN
               x_qrybatchrespsum_rec.BatchDate := TO_DATE(l_values(i), 'YYYY-MM-DD');
            ELSIF l_names(i) = 'OapfStoreId' THEN
               x_qrybatchrespsum_rec.Payee_ID := l_values(i);
            ELSIF l_names(i) = 'OapfCreditAmount' THEN
               x_qrybatchrespsum_rec.Credit_Amount := FND_NUMBER.CANONICAL_TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfSalesAmount' THEN
               x_qrybatchrespsum_rec.Sales_Amount := FND_NUMBER.CANONICAL_TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfBatchTotal' THEN
               x_qrybatchrespsum_rec.Batch_Total := FND_NUMBER.CANONICAL_TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfCurr' THEN
               x_qrybatchrespsum_rec.Currency := l_values(i);
            ELSIF l_names(i) = 'OapfVpsBatchID' THEN
               x_qrybatchrespsum_rec.VpsBatch_ID := l_values(i);
            ELSIF l_names(i) = 'OapfGwBatchID' THEN
               x_qrybatchrespsum_rec.GWBatch_ID := l_values(i);

            ELSIF l_names(i) = 'OapfErrLocation' THEN
               x_qrybatchrespsum_rec.ErrorLocation := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfVendErrCode' THEN
               x_qrybatchrespsum_rec.BEPErrCode := l_values(i);
            ELSIF l_names(i) = 'OapfVendErrmsg' THEN
               x_qrybatchrespsum_rec.BEPErrMessage := l_values(i);

           -- MAPPING NAME-VALUE PAIRS TO CLOSEBATCH DETAIL RESPONSE TABLE OF RECORDS
            ELSIF INSTR(l_names(i), 'OapfTransactionId-') <> 0 THEN
               l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfTransactionId-') );
               x_qrybatchrespdet_tbl(l_index).Trxn_ID := TO_NUMBER(l_values(i));
            ELSIF INSTR(l_names(i), 'OapfTrxnType-') <> 0 THEN
               l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfTrxnType-') );
               x_qrybatchrespdet_tbl(l_index).Trxn_Type := TO_NUMBER(l_values(i));
            ELSIF INSTR(l_names(i), 'OapfTrxnDate-') <> 0 THEN
               l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfTrxnDate-') );
               x_qrybatchrespdet_tbl(l_index).Trxn_Date := TO_DATE(l_values(i), 'YYYY-MM-DD');

            ELSIF INSTR(l_names(i), 'OapfStatus-') <> 0 THEN
               l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfStatus-') );
               x_qrybatchrespdet_tbl(l_index).Status := TO_NUMBER(l_values(i));
            ELSIF INSTR(l_names(i), 'OapfBatchErrLocation-') <> 0 THEN
               l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfBatchErrLocation-') );
               x_qrybatchrespdet_tbl(l_index).ErrorLocation := TO_NUMBER(l_values(i));
            ELSIF INSTR(l_names(i), 'OapfBatchErrCode-') <> 0 THEN
               l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfBatchErrCode-') );
               x_qrybatchrespdet_tbl(l_index).BEPErrCode := l_values(i);
            ELSIF INSTR(l_names(i), 'OapfBatchErrmsg-') <> 0 THEN
               l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfBatchErrmsg-') );
               x_qrybatchrespdet_tbl(l_index).BEPErrMessage := l_values(i);
            ELSIF INSTR(l_names(i), 'OapfNlsLang-') <> 0 THEN
               l_index := TO_NUMBER( LTRIM(l_names(i), 'OapfNlsLang-') );
               x_qrybatchrespdet_tbl(l_index).NLS_LANG := l_values(i);

            END IF;

        END LOOP;

        -- Setting API return status to 'U' if iPayment response status is not 0.
        IF (NOT trxn_status_success(x_qrybatchrespsum_rec.Response.Status)) THEN
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        END IF;

        -- END OF BODY OF API


        -- Standard check of p_commit.
	/*
        IF FND_API.To_Boolean( p_commit ) THEN
           COMMIT WORK;
        END IF;
	*/

        -- Standard call to get message count and if count is 1, get message info.
        FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                    p_data   =>   x_msg_data
                                  );
   EXCEPTION
      WHEN FND_API.G_EXC_ERROR THEN
         --ROLLBACK TO OraPmtQueryBatch_PUB;
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         --ROLLBACK TO OraPmtQueryBatch_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN OTHERS THEN
         --ROLLBACK TO OraPmtQueryBatch_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_api_name);
         END IF;

         FND_MSG_PUB.Count_And_Get ( p_count  =>  x_msg_count,
                                     p_data   =>  x_msg_data
                                   );

   END OraPmtQueryBatch;
--------------------------------------------------------------------------------------------

			--12. OraPmtReq
	-- Start of comments
	--   API name        : OraPmtReq
	--   Type            : Public
	--   Pre-reqs        : None
	--   Function        : Handles new Payment requests from E-Commerce applications without Risk Input Parameter.
	--   Parameters      :
	--     IN            : p_api_version       IN    NUMBER              Required
        --  		       p_init_msg_list     IN    VARCHAR2            Optional
        --                     p_commit            IN    VARCHAR2            Optional
        --                     p_validation_level  IN    NUMBER              Optional
        --                     p_ecapp_id          IN    NUMBER              Required
        --                     p_payee_id_rec      IN    Payee_rec_type      Required
        --                     p_payer_id_rec      IN    Payer_rec_type      Optional
        --                     p_pmtinstr_rec      IN    PmtInstr_rec_type   Required
        --                     p_tangible_rec      IN    Tangible_rec_type   Required
        --                     p_pmtreqtrxn_rec    IN    PmtReqTrxn_rec_type Required
	--   Version :
	--     Current version      1.0
	--     Previous version     1.0
	--     Initial version      1.0
	-- End of comments
--------------------------------------------------------------------------------------------
  PROCEDURE OraPmtReq (	p_api_version		IN	NUMBER,
			p_init_msg_list		IN	VARCHAR2  := FND_API.G_FALSE,
			p_commit		IN	VARCHAR2  := FND_API.G_FALSE,
			p_validation_level	IN	NUMBER  := FND_API.G_VALID_LEVEL_FULL,
			p_ecapp_id 		IN 	NUMBER,
			p_payee_rec 		IN	Payee_rec_type,
			p_payer_rec  	        IN	Payer_rec_type,
			p_pmtinstr_rec 	        IN	PmtInstr_rec_type,
			p_tangible_rec	 	IN	Tangible_rec_type,
			p_pmtreqtrxn_rec 	IN	PmtReqTrxn_rec_type,
                        x_return_status         OUT NOCOPY VARCHAR2,
                        x_msg_count             OUT NOCOPY NUMBER,
                        x_msg_data              OUT NOCOPY VARCHAR2,
                        x_reqresp_rec           OUT NOCOPY ReqResp_rec_type
			) IS

   --Initialize all Risk Info related Parameters to default NULL values
   p_riskinfo_rec XX_IBY_PAYMENT_ADAPTER_PUB.RiskInfo_rec_type;

   BEGIN
     --Call OraPmtReq with the Risk input parameters.
     XX_IBY_PAYMENT_ADAPTER_PUB.OraPmtReq( p_api_version,
                                        p_init_msg_list,
                                        p_commit,
                                        p_validation_level,
                                        p_ecapp_id ,
                                        p_payee_rec,
                                        p_payer_rec,
                                        p_pmtinstr_rec,
                                        p_tangible_rec,
                                        p_pmtreqtrxn_rec,
                                        p_riskinfo_rec,
                                        x_return_status,
                                        x_msg_count ,
                                        x_msg_data  ,
                                        x_reqresp_rec
                                        );
   END OraPmtReq;
--------------------------------------------------------------------------------------------
        --13. OraRiskEval
        -- Start of comments
        --   API name        : OraRiskEval
        --   Type            : Public
        --   Pre-reqs        :
        --   Function        : Evaluate Risk with no AVS
        --   Parameters      :
        --   IN              : p_api_version       IN    NUMBER              Required
        --                     p_init_msg_list     IN    VARCHAR2            Optional
        --                     p_commit            IN    VARCHAR2            Optional
        --                     p_validation_level  IN    NUMBER              Optional
        --                     p_ecapp_id          IN    NUMBER              Required
	--		       p_payment_risk_info IN	PaymentRiskInfo_rec_type	Required
        --   Version :
        --      Current version      1.0
        --      Previous version     1.0
        --      Initial version      1.0
        -- End of comments
--------------------------------------------------------------------------------------------


  PROCEDURE OraRiskEval (  p_api_version           IN      NUMBER,
        p_init_msg_list         IN	VARCHAR2  := FND_API.G_FALSE,
        p_commit                IN	VARCHAR2  := FND_API.G_FALSE,
        p_validation_level      IN	NUMBER  := FND_API.G_VALID_LEVEL_FULL,
        p_ecapp_id              IN      NUMBER,
	p_payment_risk_info	IN	PaymentRiskInfo_rec_type,
        x_return_status         OUT NOCOPY VARCHAR2,
        x_msg_count             OUT NOCOPY NUMBER,
        x_msg_data              OUT NOCOPY VARCHAR2,
        x_risk_resp             OUT NOCOPY RiskResp_rec_type
		        ) IS

       l_get_baseurl   VARCHAR2(2000);
        --The following 3 variables are meant for output of
        --get_baseurl procedure.
        l_status_url    VARCHAR2(2000);
        l_msg_count_url NUMBER := 0;
        l_msg_data_url  VARCHAR2(2000);

        l_api_name     CONSTANT  VARCHAR2(30) := 'OraRiskEval';
        l_oapf_action  CONSTANT  VARCHAR2(30) := 'oraRiskEval';
        l_api_version  CONSTANT  NUMBER := 1.0;

        l_url           VARCHAR2(7000) ;
        l_html          VARCHAR2(7000) ;
        l_names         v240_tbl_type;
        l_values        v240_tbl_type;

        --The following 3 variables are meant for unpack_results_url procedure.
        l_status       NUMBER := 0;
        l_errcode      NUMBER := 0;
        l_errmessage   VARCHAR2(2000) := 'Success';

        l_pmtinstr_type VARCHAR2(200);

	-- for NLS bug fix #1692300 - 4/3/2001 jleybovi
	--
	l_db_nls	VARCHAR2(80) := NULL;
	l_ecapp_nls	VARCHAR2(80) := NULL;

   BEGIN

       -- Standard Start of API savepoint
       --SAVEPOINT  OraRiskEval_PUB;


        /* ***** Performing Validations, Initializations
               for Standard IN, OUT Parameters ***** */

        -- Standard call to check for call compatibility.
        IF NOT FND_API.Compatible_API_Call ( l_api_version,
                                             p_api_version,
                                             l_api_name,
                                             G_PKG_NAME )
        THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        -- Initialize message list if p_init_msg_list is set to TRUE.
        IF FND_API.to_Boolean( p_init_msg_list ) THEN
           FND_MSG_PUB.initialize;
        END IF;

        -- Verifying if validation level is FULL, which is expected for PUBLIC APIs.
        IF (p_validation_level <> g_validation_level) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204401_VAL_LEVEL_ERROR');
           FND_MSG_PUB.Add;
           RAISE  FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;


        --  Initialize API return status to success
        x_return_status := FND_API.G_RET_STS_SUCCESS;


        -- START OF BODY OF API

        get_baseurl(l_get_baseurl);

        -- Construct the full URL to send to the ECServlet.
        l_url := l_get_baseurl;

	l_db_nls := iby_utility_pvt.get_local_nls();

	--Mandatory Input Parameters
        check_mandatory('AVSRiskApi', 'false', l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfAction', l_oapf_action, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfECAppId', to_char(p_ecapp_id), l_url, l_db_nls, l_ecapp_nls);

        check_mandatory('OapfStoreId', p_payment_risk_info.Payee_ID, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfPrice', FND_NUMBER.NUMBER_TO_CANONICAL(p_payment_risk_info.Amount), l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfCurr', p_payment_risk_info.Currency_Code, l_url, l_db_nls, l_ecapp_nls);


        --Determine the Payment Instrument type that is used.
        IF (p_payment_risk_info.PmtInstr.CreditCardInstr.CC_Num IS NOT NULL) THEN
           l_pmtinstr_type := 'CREDITCARD';
        ELSIF (p_payment_risk_info.PmtInstr.PurchaseCardInstr.PC_Num IS NOT NULL) THEN
           l_pmtinstr_type := 'PURCHASECARD';
        --ELSIF (p_payment_risk_info.PmtInstr.BankAcctInstr.BankAcct_Num IS NOT NULL) THEN
        --l_pmtinstr_type := 'BANKACCOUNT';
        END IF;

        --CONDITIONALLY MANDATORY INPUT PARAMETERS

        --1. Instrument related conditionally mandatory input
        --a. CreditCard instrument related conditionally mandatory input

        IF (l_pmtinstr_type = 'CREDITCARD') THEN

           -- Assign the value for 'OapfPmtInstrType' to 'CREDITCARD' and append to URL.
           check_optional('OapfPmtInstrType', 'CREDITCARD', l_url, l_db_nls, l_ecapp_nls);

--           check_mandatory('OapfAuthType', UPPER(p_payment_risk_info.PmtInstr.Auth_Type), l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrID',
             iby_creditcard_pkg.Get_Secured_Card_Number(p_payment_risk_info.PmtInstr.CreditCardInstr.CC_Num),
             l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrExp', to_char(p_payment_risk_info.PmtInstr.CreditCardInstr.CC_ExpDate, 'YYYY-MM-DD'), l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCCType', p_payment_risk_info.PmtInstr.CreditCardInstr.CC_Type, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCustName', p_payment_risk_info.PmtInstr.CreditCardInstr.CC_HolderName, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfFIName', p_payment_risk_info.PmtInstr.CreditCardInstr.FIName, l_url, l_db_nls, l_ecapp_nls);

           --Address related Conditional Mandatory Input Parameters
           IF (p_payment_risk_info.PmtInstr.CreditCardInstr.CC_BillingAddr.Address1 IS NOT NULL)
           OR (p_payment_risk_info.PmtInstr.CreditCardInstr.CC_BillingAddr.City  IS NOT NULL)
           OR (p_payment_risk_info.PmtInstr.CreditCardInstr.CC_BillingAddr.State IS NOT NULL)
           OR (p_payment_risk_info.PmtInstr.CreditCardInstr.CC_BillingAddr.PostalCode IS NOT NULL) THEN

              check_optional('OapfAddr1', p_payment_risk_info.PmtInstr.CreditCardInstr.CC_BillingAddr.Address1, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfCity', p_payment_risk_info.PmtInstr.CreditCardInstr.CC_BillingAddr.City, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfState', p_payment_risk_info.PmtInstr.CreditCardInstr.CC_BillingAddr.State, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfPostalCode', p_payment_risk_info.PmtInstr.CreditCardInstr.CC_BillingAddr.PostalCode, l_url, l_db_nls, l_ecapp_nls);
           END IF;

        --b. PurchaseCard instrument related conditionally mandatory input
        ELSIF (l_pmtinstr_type = 'PURCHASECARD') THEN

           -- Assign the value for 'OapfPmtInstrType' to 'PURCHASECARD' and append to URL.
           check_optional('OapfPmtInstrType', 'PURCHASECARD', l_url, l_db_nls, l_ecapp_nls);

--           check_mandatory('OapfAuthType', UPPER(p_pmtreqtrxn_rec.Auth_Type), l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrID',
             iby_creditcard_pkg.Get_Secured_Card_Number(p_payment_risk_info.PmtInstr.PurchaseCardInstr.PC_Num),
             l_url, l_db_nls, l_ecapp_nls);
           check_mandatory('OapfPmtInstrExp', to_char(p_payment_risk_info.PmtInstr.PurchaseCardInstr.PC_ExpDate, 'YYYY-MM-DD'), l_url, l_db_nls, l_ecapp_nls);

           check_mandatory('OapfCardSubType', p_payment_risk_info.PmtInstr.PurchaseCardInstr.PC_Subtype, l_url, l_db_nls, l_ecapp_nls);

           check_optional('OapfCCType', p_payment_risk_info.PmtInstr.PurchaseCardInstr.PC_Type, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfCustName', p_payment_risk_info.PmtInstr.PurchaseCardInstr.PC_HolderName, l_url, l_db_nls, l_ecapp_nls);
           check_optional('OapfFIName', p_payment_risk_info.PmtInstr.PurchaseCardInstr.FIName, l_url, l_db_nls, l_ecapp_nls);

           --Address related Conditional Mandatory Input Parameters
           IF (p_payment_risk_info.PmtInstr.PurchaseCardInstr.PC_BillingAddr.Address1 IS NOT NULL)
           OR (p_payment_risk_info.PmtInstr.PurchaseCardInstr.PC_BillingAddr.City  IS NOT NULL)
           OR (p_payment_risk_info.PmtInstr.PurchaseCardInstr.PC_BillingAddr.State IS NOT NULL)
           OR (p_payment_risk_info.PmtInstr.PurchaseCardInstr.PC_BillingAddr.PostalCode IS NOT NULL) THEN

              check_optional('OapfAddr1', p_payment_risk_info.PmtInstr.PurchaseCardInstr.PC_BillingAddr.Address1, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfCity', p_payment_risk_info.PmtInstr.PurchaseCardInstr.PC_BillingAddr.City, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfState', p_payment_risk_info.PmtInstr.PurchaseCardInstr.PC_BillingAddr.State, l_url, l_db_nls, l_ecapp_nls);
              check_optional('OapfPostalCode', p_payment_risk_info.PmtInstr.PurchaseCardInstr.PC_BillingAddr.PostalCode, l_url, l_db_nls, l_ecapp_nls);
           END IF;

        /* NOT SUPPORTING BANKACCOUNT OPERATION FOR 11i
          ELSIF (l_pmtinstr_type = 'BANKACCOUNT') THEN
             --b. BankAccount instrument related conditionally mandatory input

             -- Assign the value for 'OapfPmtInstrType' to 'BANKACCOUNT' and append to URL.
             check_optional('OapfPmtInstrType', 'BANKACCOUNT', l_url, l_db_nls, l_ecapp_nls);

             check_mandatory('OapfBankId', p_payment_risk_info.PmtInstr.BankAcctInstr.Bank_ID, l_url, l_db_nls, l_ecapp_nls);

             check_mandatory('OapfPmtInstrID', p_payment_risk_info.PmtInstr.BankAcctInstr.BankAcct_Num, l_url, l_db_nls, l_ecapp_nls);
             check_mandatory('OapfAcctType', p_payment_risk_info.PmtInstr.BankAcctInstr.BankAcct_Type, l_url, l_db_nls, l_ecapp_nls);
             check_optional('OapfBranchId', p_payment_risk_info.PmtInstr.BankAcctInstr.Branch_ID, l_url, l_db_nls, l_ecapp_nls);
             check_optional('OapfFIName', p_payment_risk_info.PmtInstr.BankAcctInstr.FIName, l_url, l_db_nls, l_ecapp_nls);
         */

          ELSE
             --a. registered instrument related conditionally mandatory input
             check_mandatory('OapfPmtRegId', to_char(p_payment_risk_info.PmtInstr.PmtInstr_ID), l_url, l_db_nls, l_ecapp_nls);

             --NOTE*: Need a DB table/view to query DB from PmtInstr_ID and get PmtInstrType from DB.
             check_optional('OapfPmtInstrType', 'CREDITCARD', l_url, l_db_nls, l_ecapp_nls);
--             check_mandatory('OapfAuthType', UPPER(p_payment_risk_info.PmtInstr.Auth_Type), l_url, l_db_nls, l_ecapp_nls);

          END IF;

        --OPTIONAL INPUT PARAMETERS
        check_optional('OapfPayerId', p_payment_risk_info.Payer_ID, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfFormulaName', p_payment_risk_info.Formula_Name, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfShipToBillToFlag', p_payment_risk_info.ShipToBillTo_Flag, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfCustAccountNum', p_payment_risk_info.Customer_Acct_Num, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfAVSCode', p_payment_risk_info.AVSCode, l_url, l_db_nls, l_ecapp_nls);
        check_optional('OapfTimeOfPurchase', p_payment_risk_info.Time_Of_Purchase, l_url, l_db_nls, l_ecapp_nls);

        -- Remove ampersand from the last input parameter.
        l_url := RTRIM(l_url,'&');

	-- done in escape_url_chars
	--
        -- ^^^ Replace blank characters with + sign. ^^^
        --l_url := REPLACE(l_url,' ','+');


 	-- show_input_debug(l_url);

        -- Send http request to the payment server
        --l_html := UTL_HTTP.REQUEST(l_url);
        SEND_REQUEST(l_url, l_html);


        -- show_output_debug(l_html);

        -- Unpack the results
        UNPACK_RESULTS_URL(l_html,l_names,l_values, l_status, l_errcode, l_errmessage);

	--show_table_debug(l_names);
	--show_table_debug(l_values);

        --Raising Exception to handle errors in unpacking resulting html file.
        IF (l_status = -1) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204403_HTML_UNPACK_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --Raising Exception to handle Servlet related errors.
        IF (l_names.COUNT = 0) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204402_JSERVLET_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        FOR i IN 1..l_names.COUNT LOOP
            --Payment Server Related Generic Response
            IF l_names(i) = 'OapfStatus' THEN
               x_risk_resp.Status := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfRiskScore' THEN
               x_risk_resp.Risk_Score := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfRiskThresholdVal' THEN
               x_risk_resp.Risk_Threshold_Val := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfCode' THEN
               x_risk_resp.ErrCode := l_values(i);
            ELSIF l_names(i) = 'OapfCause' THEN
               x_risk_resp.ErrMessage := l_values(i);
            ELSIF l_names(i) = 'OapfAuxMsg' THEN
               x_risk_resp.Additional_ErrMessage := l_values(i);
            ELSIF l_names(i) = 'OapfRiskyFlag' THEN
               x_risk_resp.Risky_Flag := l_values(i);
            ELSIF l_names(i) = 'OapfAVSCodeFlag' THEN
               x_risk_resp.AVSCode_Flag := l_values(i);
            END IF;

       END LOOP;

        -- Setting API return status to 'U' if EvalRisk response status is not 0.
        IF (NOT trxn_status_success(x_risk_resp.Status)) THEN
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
	END IF;

        -- END OF BODY OF API

        -- Standard check of p_commit.
	/*
        IF FND_API.To_Boolean( p_commit ) THEN
           COMMIT WORK;
        END IF;
	*/

        -- Standard call to get message count and if count is 1, get message info.
        FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                    p_data   =>   x_msg_data
                                  );
   EXCEPTION

      WHEN FND_API.G_EXC_ERROR THEN
         --ROLLBACK TO OraRiskEval_PUB;
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         --ROLLBACK TO OraRiskEval_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );

      WHEN OTHERS THEN
         --ROLLBACK TO OraRiskEval_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_api_name);
         END IF;

         FND_MSG_PUB.Count_And_Get ( p_count  =>  x_msg_count,
                                     p_data   =>  x_msg_data
                                   );


   END OraRiskEval;


--------------------------------------------------------------------------------------------

        --14. OraRiskEval ( Overloaded )
        -- Start of comments
        --   API name        : OraRiskEval
        --   Type            : Public
        --   Pre-reqs        :
        --   Function        : Evaluate Risk with AVS
        --   Parameters      :
        --   IN             : p_api_version       IN    NUMBER              Required
        --                     p_init_msg_list     IN    VARCHAR2            Optional
        --                     p_commit            IN    VARCHAR2            Optional
        --                     p_validation_level  IN    NUMBER              Optional
        --                     p_ecapp_id          IN    NUMBER              Required
        --                     p_avs_risk_info IN   AVSRiskInfo_rec_type        Required
        --   Version :
        --      Current version      1.0
        --      Previous version     1.0
        --      Initial version      1.0
        -- End of comments

--------------------------------------------------------------------------------------------
  PROCEDURE OraRiskEval (  p_api_version           IN      NUMBER,
        p_init_msg_list         IN	VARCHAR2  := FND_API.G_FALSE,
        p_commit                IN	VARCHAR2  := FND_API.G_FALSE,
        p_validation_level      IN	NUMBER  := FND_API.G_VALID_LEVEL_FULL,
        p_ecapp_id              IN      NUMBER,
	p_avs_risk_info		IN	AVSRiskInfo_rec_type,
        x_return_status         OUT NOCOPY VARCHAR2,
        x_msg_count             OUT NOCOPY NUMBER,
        x_msg_data              OUT NOCOPY VARCHAR2,
        x_risk_resp             OUT NOCOPY RiskResp_rec_type
		        ) IS

       l_get_baseurl   VARCHAR2(2000);
        --The following 3 variables are meant for output of
        --get_baseurl procedure.
        l_status_url    VARCHAR2(2000);
        l_msg_count_url NUMBER := 0;
        l_msg_data_url  VARCHAR2(2000);

        l_api_name     CONSTANT  VARCHAR2(30) := 'OraRiskEval';
        l_oapf_action  CONSTANT  VARCHAR2(30) := 'oraRiskEval';
        l_api_version  CONSTANT  NUMBER := 1.0;

        l_url           VARCHAR2(2000) ;
        l_html          VARCHAR2(7000) ;
        l_names         v240_tbl_type;
        l_values        v240_tbl_type;

        --The following 3 variables are meant for unpack_results_url procedure.
        l_status       NUMBER := 0;
        l_errcode      NUMBER := 0;
        l_errmessage   VARCHAR2(2000) := 'Success';

	-- for NLS bug fix #1692300 - 4/3/2001 jleybovi
	--
	l_db_nls       VARCHAR2(80) := NULL;
	l_ecapp_nls    VARCHAR2(80) := NULL;

   BEGIN

       -- Standard Start of API savepoint
       --SAVEPOINT  OraRiskEval_PUB;


        /* ***** Performing Validations, Initializations
               for Standard IN, OUT Parameters ***** */

        -- Standard call to check for call compatibility.
        IF NOT FND_API.Compatible_API_Call ( l_api_version,
                                             p_api_version,
                                             l_api_name,
                                             G_PKG_NAME )
        THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        -- Initialize message list if p_init_msg_list is set to TRUE.
        IF FND_API.to_Boolean( p_init_msg_list ) THEN
           FND_MSG_PUB.initialize;
        END IF;

        -- Verifying if validation level is FULL, which is expected for PUBLIC APIs.
        IF (p_validation_level <> g_validation_level) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204401_VAL_LEVEL_ERROR');
           FND_MSG_PUB.Add;
           RAISE  FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;


        --  Initialize API return status to success
        x_return_status := FND_API.G_RET_STS_SUCCESS;


        -- START OF BODY OF API

        get_baseurl(l_get_baseurl);

        -- Construct the full URL to send to the ECServlet.
        l_url := l_get_baseurl;

	l_db_nls := iby_utility_pvt.get_local_nls();

	--Mandatory Input Parameters
        check_mandatory('AVSRiskApi', 'true', l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfAction', l_oapf_action, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfECAppId', to_char(p_ecapp_id), l_url, l_db_nls, l_ecapp_nls);

        check_mandatory('OapfStoreId', p_avs_risk_info.Payee_ID, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfPrevRiskScore', p_avs_risk_info.Previous_Risk_Score, l_url, l_db_nls, l_ecapp_nls);
        check_mandatory('OapfAVSCode', p_avs_risk_info.AVSCode, l_url, l_db_nls, l_ecapp_nls);

        --OPTIONAL INPUT PARAMETERS
        check_optional('OapfFormulaName', p_avs_risk_info.Formula_Name, l_url, l_db_nls, l_ecapp_nls);

        -- Remove ampersand from the last input parameter.
        l_url := RTRIM(l_url,'&');

	-- already done by escape_url_chars()
	--
        -- ^^^ Replace blank characters with + sign. ^^^
        -- l_url := REPLACE(l_url,' ','+');


	--show_input_debug(l_url);

        -- Send http request to the payment server
        --l_html := UTL_HTTP.REQUEST(l_url);
        SEND_REQUEST(l_url, l_html);


        -- show_output_debug(l_html);

        -- Unpack the results
        UNPACK_RESULTS_URL(l_html,l_names,l_values, l_status, l_errcode, l_errmessage);

	--show_table_debug(l_names);
	--show_table_debug(l_values);

        --Raising Exception to handle errors in unpacking resulting html file.
        IF (l_status = -1) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204403_HTML_UNPACK_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        --Raising Exception to handle Servlet related errors.
        IF (l_names.COUNT = 0) THEN
           FND_MESSAGE.SET_NAME('IBY', 'IBY_204402_JSERVLET_ERROR');
           FND_MSG_PUB.Add;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

        FOR i IN 1..l_names.COUNT LOOP
            --Payment Server Related Generic Response
            IF l_names(i) = 'OapfStatus' THEN
               x_risk_resp.Status := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfRiskScore' THEN
               x_risk_resp.Risk_Score := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfRiskThresholdVal' THEN
               x_risk_resp.Risk_Threshold_Val := TO_NUMBER(l_values(i));
            ELSIF l_names(i) = 'OapfCode' THEN
               x_risk_resp.ErrCode := l_values(i);
            ELSIF l_names(i) = 'OapfCause' THEN
               x_risk_resp.ErrMessage := l_values(i);
            ELSIF l_names(i) = 'OapfAuxMsg' THEN
               x_risk_resp.Additional_ErrMessage := l_values(i);
            ELSIF l_names(i) = 'OapfRiskyFlag' THEN
               x_risk_resp.Risky_Flag := l_values(i);
            ELSIF l_names(i) = 'OapfAVSCodeFlag' THEN
               x_risk_resp.AVSCode_Flag := l_values(i);

            END IF;

       END LOOP;

        -- Setting API return status to 'U' if EvalRisk response status is not 0.
        IF (NOT trxn_status_success(x_risk_resp.Status)) THEN
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
	END IF;

        -- END OF BODY OF API

        -- Standard check of p_commit.
	/*
        IF FND_API.To_Boolean( p_commit ) THEN
           COMMIT WORK;
        END IF;
	*/

        -- Standard call to get message count and if count is 1, get message info.
        FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                    p_data   =>   x_msg_data
                                  );
   EXCEPTION


      WHEN FND_API.G_EXC_ERROR THEN
         --ROLLBACK TO OraRiskEval_PUB;
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         --ROLLBACK TO OraRiskEval_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );

      WHEN OTHERS THEN
         --ROLLBACK TO OraRiskEval_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_api_name, SQLCODE||':'||SQLERRM);
         END IF;

         FND_MSG_PUB.Count_And_Get ( p_count  =>  x_msg_count,
                                     p_data   =>  x_msg_data
                                   );


   END OraRiskEval;

--------------------------------------------------------------------------------------------
		--15. OraCCBatchCapture
        -- Start of comments
        --   API name        : OraCCBatchCapture
        --   Type            : Public
        --   Pre-reqs        : None
        --   Function        : Handles batch capture of funds from Payer accounts for authorized
        --                        Payment Requests in case of CreditCard instruments.
        --   Parameters      :
        --     IN            : p_api_version          IN    NUMBER               Required
        --                     p_init_msg_list        IN    VARCHAR2             Optional
        --                     p_commit               IN    VARCHAR2             Optional
        --                     p_validation_level     IN    NUMBER               Optional
        --                     p_ecapp_id             IN    NUMBER               Required
        --                     p_capturetrxn_rec_tbl  IN    CaptureTrxn_tbl      Required
        --   Version :
        --     Current version      1.0
        --     Previous version     1.0
        --     Initial version      1.0
        -- End of comments

  PROCEDURE OraCCBatchCapture (  p_api_version           IN       NUMBER,
                                 p_init_msg_list         IN       VARCHAR2  := FND_API.G_FALSE,
                                 p_commit                IN       VARCHAR2  := FND_API.G_FALSE,
                                 p_validation_level      IN       NUMBER  := FND_API.G_VALID_LEVEL_FULL,
                                 p_ecapp_id              IN       NUMBER,
                                 p_capturetrxn_rec_tbl   IN       CaptureTrxn_tbl,
                                 x_return_status         OUT NOCOPY VARCHAR2,
                                 x_msg_count             OUT NOCOPY NUMBER,
                                 x_msg_data              OUT NOCOPY VARCHAR2,
                                 x_capresp_rec_tbl       OUT NOCOPY CaptureResp_tbl
  ) IS

   l_get_baseurl   VARCHAR2(2000);
   --The following 3 variables are meant for output of
   --get_baseurl procedure.
   l_status_url    VARCHAR2(2000);
   l_msg_count_url NUMBER := 0;
   l_msg_data_url  VARCHAR2(2000);

   l_api_name     CONSTANT  VARCHAR2(30) := 'OraCCBatchCapture';
   l_oapf_action  CONSTANT  VARCHAR2(30) := 'oraCCBatch';
   l_api_version  CONSTANT  NUMBER := 1.0;

   l_url           VARCHAR2(4000);
   l_html          VARCHAR2(32000);
   l_names         v240_tbl_type;
   l_values        v240_tbl_type;
   l_ret_name      VARCHAR2(1000);
   l_ret_value     VARCHAR2(1000);
   l_ret_index     NUMBER;
   l_ret_pos       NUMBER;
   l_http_body     boolean := false;

   --The following 3 variables are meant for unpack_results_url procedure.
   l_status       NUMBER := 0;
   l_errcode      NUMBER := 0;
   l_errmessage   VARCHAR2(2000) := 'Success';

	l_db_nls       VARCHAR2(80) := NULL;
	l_ecapp_nls    VARCHAR2(80) := NULL;

   l_position     NUMBER := 0;
   l_host         VARCHAR2(4000);
   l_port         VARCHAR2(80) := NULL;
   l_post_info    VARCHAR2(2000);

   l_conn         UTL_TCP.CONNECTION;  -- TCP/IP connection to the Web server
   l_ret_val      PLS_INTEGER;
   l_curr_index   NUMBER;
   l_index        NUMBER := 0;
   l_temp_buff    VARCHAR2(2000) := NULL;
   l_content_len  NUMBER := 0;

	l_batch_status	NUMBER := NULL;
	l_batch_msg	VARCHAR2(2000);

   BEGIN

      iby_debug_pub.add('Enter',FND_LOG.LEVEL_PROCEDURE,
          G_DEBUG_MODULE || '.OraCCBatchCapture');

      /* ***** Performing Validations, Initializations
	      for Standard IN, OUT Parameters ***** */
      -- Standard call to check for call compatibility.
      IF NOT FND_API.Compatible_API_Call ( l_api_version,
                                          p_api_version,
                                          l_api_name,
                                          G_PKG_NAME )
      THEN
        FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
        FND_MSG_PUB.Add;
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;

      -- Initialize message list if p_init_msg_list is set to TRUE.
      IF FND_API.to_Boolean( p_init_msg_list ) THEN
        FND_MSG_PUB.initialize;
      END IF;

      -- Verifying if validation level is FULL, which is expected for PUBLIC APIs.
      IF (p_validation_level <> g_validation_level) THEN
        FND_MESSAGE.SET_NAME('IBY', 'IBY_204401_VAL_LEVEL_ERROR');
        FND_MSG_PUB.Add;
        RAISE  FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;

      iby_debug_pub.add('Batch size = ' || p_capturetrxn_rec_tbl.count,
          FND_LOG.LEVEL_STATEMENT,
          G_DEBUG_MODULE || '.OraCCBatchCapture');
      --
      -- Verifying if the batch size exceeded max.
      -- The batch size has exceeded the max limit size.
      IF (p_capturetrxn_rec_tbl.count > C_MAX_CC_BATCH_SIZE) THEN
        FND_MESSAGE.SET_NAME('IBY', 'IBY_204407_VAL_ERROR');
        FND_MSG_PUB.Add;
        RAISE  FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;

      --  Initialize API return status to success
      x_return_status := FND_API.G_RET_STS_SUCCESS;

      -- START OF BODY OF API

      get_baseurl(l_get_baseurl);
      -- Construct the full URL to send to the ECServlet.
      l_url := l_get_baseurl;
      iby_debug_pub.add('iPaymentURL = ' || l_url,
          FND_LOG.LEVEL_STATEMENT,
          G_DEBUG_MODULE || '.OraCCBatchCapture');

      l_db_nls := iby_utility_pvt.get_local_nls();

      -- 1. MANDATORY INPUT PARAMETERS
      check_mandatory('OapfAction', l_oapf_action, l_url, l_db_nls, l_ecapp_nls);

      -- Remove ampersand from the last input parameter.
      l_url := RTRIM(l_url,'&');

      l_position := INSTR(lower(l_url),lower('http://'));
      --remove the 'http://'
      IF (l_position > 0) THEN
         l_url := SUBSTR(l_url,8);
      ELSE
        l_position := INSTR(lower(l_url),lower('https://'));
        --remove the 'https://'
        IF (l_position > 0) THEN
           l_url := SUBSTR(l_url,9);
        END IF;
      END IF;

      -- get the host address
      l_position := INSTR(l_url,':');
      IF (l_position > 0) THEN
        l_host := SUBSTR(l_url,1,l_position-1);
        --remove the 'the host + :' from the URL
        l_url := SUBSTR(l_url,l_position+1);
      ELSE
        l_position := INSTR(l_url,'/');
        IF (l_position > 0) THEN
          l_host := SUBSTR(l_url,1,l_position-1);
          --remove the 'the host' from the URL
          l_url := SUBSTR(l_url,l_position);
        END IF;
      END IF;

      -- get the port number
      l_position := INSTR(l_url,'/');
      IF (l_position > 0) THEN
        l_port := SUBSTR(l_url,1,l_position-1);
      END IF;
      IF (l_port is NULL) THEN
        l_port := '80';
      END IF;

      --remove the port number from the URL
      l_post_info := SUBSTR(l_url,l_position);
      l_post_info := 'POST ' || l_post_info || ' HTTP/1.0';
--dbms_output.put_line('l_post_info = ' || l_post_info);

      iby_debug_pub.add('l_host = ' || l_host,
          FND_LOG.LEVEL_STATEMENT,
          G_DEBUG_MODULE || '.OraCCBatchCapture');
      iby_debug_pub.add('l_port = ' || l_port,
          FND_LOG.LEVEL_STATEMENT,
          G_DEBUG_MODULE || '.OraCCBatchCapture');

      -- open connection
      l_conn := utl_tcp.open_connection(remote_host => l_host,
                                   remote_port => l_port);

      iby_debug_pub.add('opened socket to EC Servlet',
          FND_LOG.LEVEL_STATEMENT,
          G_DEBUG_MODULE || '.OraCCBatchCapture');

      l_ret_val := utl_tcp.write_line(l_conn, l_post_info);
      l_ret_val := utl_tcp.write_line(l_conn,'Accept: text/plain');
      l_ret_val := utl_tcp.write_line(l_conn,'Content-type: text/plain');

      -- calcuate the content length
      l_content_len := 0;
      l_temp_buff := 'OapfBatchType=oraPmtCapture';
      l_content_len := l_content_len + length(l_temp_buff) + 2;
      l_temp_buff := 'OapfBatchSize='||p_capturetrxn_rec_tbl.count;
      l_content_len := l_content_len + length(l_temp_buff) + 2;
      l_curr_index :=  p_capturetrxn_rec_tbl.first;
      l_index := 0;

      WHILE (l_curr_index <= p_capturetrxn_rec_tbl.last) LOOP

         l_temp_buff := 'OapfPrice-'||l_index||'='||FND_NUMBER.NUMBER_TO_CANONICAL(p_capturetrxn_rec_tbl(l_curr_index).Price);
         l_content_len := l_content_len + length(l_temp_buff) + 2;
         l_temp_buff := 'OapfECAppId-'||l_index||'='||p_ecapp_id;
         l_content_len := l_content_len + length(l_temp_buff) + 2;
         l_temp_buff := 'OapfTransactionId-'||l_index||'='||p_capturetrxn_rec_tbl(l_curr_index).Trxn_Id;
         l_content_len := l_content_len + length(l_temp_buff) + 2;
         l_temp_buff := 'OapfCurr-'||l_index||'='||p_capturetrxn_rec_tbl(l_curr_index).Currency;
         l_content_len := l_content_len + length(l_temp_buff) + 2;
         l_temp_buff := 'OapfMode-'||l_index||'='||p_capturetrxn_rec_tbl(l_curr_index).PmtMode;
         l_content_len := l_content_len + length(l_temp_buff) + 2;

         IF (p_capturetrxn_rec_tbl(l_curr_index).NLS_LANG IS NOT NULL) THEN
            l_temp_buff := 'OapfNlsLang-'||l_index||'='||p_capturetrxn_rec_tbl(l_curr_index).NLS_LANG;
            l_content_len := l_content_len + length(l_temp_buff) + 2;
         END IF;
         IF (p_capturetrxn_rec_tbl(l_curr_index).PmtMode = 'OFFLINE') THEN
            l_temp_buff := 'OapfSchedDate-'||l_index||'='||to_char(p_capturetrxn_rec_tbl(l_curr_index).Settlement_Date, 'YYYY-MM-DD');
            l_content_len := l_content_len + length(l_temp_buff) + 2;
         END IF;
         l_index := l_index + 1;
         l_curr_index := p_capturetrxn_rec_tbl.next(l_curr_index);

      END LOOP;

      iby_debug_pub.add('l_content_len = ' || l_content_len,
          FND_LOG.LEVEL_STATEMENT,
          G_DEBUG_MODULE || '.OraCCBatchCapture');

      l_ret_val := utl_tcp.write_line(l_conn,'Content-length: '||l_content_len);
      l_ret_val := utl_tcp.write_line(l_conn);
      l_ret_val := utl_tcp.write_line(l_conn,'OapfBatchType=oraPmtCapture');
      l_ret_val := utl_tcp.write_line(l_conn,'OapfBatchSize='||p_capturetrxn_rec_tbl.count);

      -- Transmits a text line to a service on an open connection.
      -- The newline character sequence will be appended to the message before it is transmitted.
      l_curr_index :=  p_capturetrxn_rec_tbl.first;
      l_index := 0;

      WHILE (l_curr_index <= p_capturetrxn_rec_tbl.last) LOOP

         l_ret_val := utl_tcp.write_line(l_conn,'OapfPrice-'||l_index||'='||FND_NUMBER.NUMBER_TO_CANONICAL(p_capturetrxn_rec_tbl(l_curr_index).Price));
         l_ret_val := utl_tcp.write_line(l_conn,'OapfECAppId-'||l_index||'='||p_ecapp_id);
         l_ret_val := utl_tcp.write_line(l_conn,'OapfTransactionId-'||l_index||'='||p_capturetrxn_rec_tbl(l_curr_index).Trxn_Id);
         --save the trxn_id for return value.
         x_capresp_rec_tbl(l_index).Trxn_ID := p_capturetrxn_rec_tbl(l_curr_index).Trxn_Id;
         l_ret_val := utl_tcp.write_line(l_conn,'OapfCurr-'||l_index||'='||p_capturetrxn_rec_tbl(l_curr_index).Currency);
         l_ret_val := utl_tcp.write_line(l_conn,'OapfMode-'||l_index||'='||p_capturetrxn_rec_tbl(l_curr_index).PmtMode);
         IF (p_capturetrxn_rec_tbl(l_curr_index).NLS_LANG IS NOT NULL) THEN
            l_ret_val := utl_tcp.write_line(l_conn,'OapfNlsLang-'||l_index||'='||p_capturetrxn_rec_tbl(l_curr_index).NLS_LANG);
         END IF;
         IF (p_capturetrxn_rec_tbl(l_curr_index).PmtMode = 'OFFLINE') THEN
            l_ret_val := utl_tcp.write_line(l_conn,'OapfSchedDate-'||l_index||'='||to_char(p_capturetrxn_rec_tbl(l_curr_index).Settlement_Date, 'YYYY-MM-DD'));
         END IF;
         l_index := l_index + 1;
         l_curr_index := p_capturetrxn_rec_tbl.next(l_curr_index);

      END LOOP;

      l_ret_val := utl_tcp.write_line(l_conn);
      l_http_body := false;

      BEGIN LOOP
         -- read result
         l_html := substr(utl_tcp.get_line(l_conn,TRUE),1,3000);
         l_position := instr(l_html,'</H2>');

--dbms_output.put_line('l_html body = ' || substr(l_html,1,200));

         --we only want the html body here
         IF ((l_position > 0) OR (l_http_body)) THEN

            l_http_body := true;
            l_position := instr(l_html,'Oapf');

            IF l_position > 0 THEN
               --add the <BR> to the end, b/c the UNPACK_RESULTS_URL expected to be there.
--               l_html := l_html || '<BR>';
               UNPACK_RESULTS_URL(l_html,l_names,l_values, l_status, l_errcode, l_errmessage);
               --Raising Exception to handle errors in unpacking resulting html file.
               IF (l_status = -1) THEN

		 iby_debug_pub.add('error unpacking results',
                    FND_LOG.LEVEL_UNEXPECTED,
                    G_DEBUG_MODULE || '.OraCCBatchCapture');

                 FND_MESSAGE.SET_NAME('IBY', 'IBY_204403_HTML_UNPACK_ERROR');
                 FND_MSG_PUB.Add;
                 RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
               END IF;

               --Raising Exception to handle Servlet related errors.
               IF (l_names.COUNT = 0) THEN

		 iby_debug_pub.add('servlet errors; no names returned',
                    FND_LOG.LEVEL_UNEXPECTED,
                    G_DEBUG_MODULE || '.OraCCBatchCapture');

                 FND_MESSAGE.SET_NAME('IBY', 'IBY_204402_JSERVLET_ERROR');
                 FND_MSG_PUB.Add;
                 RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
               END IF;
	            -- Assign output parameters to output record x_capresp_rec_tbl
	            FOR i IN 1..l_names.COUNT LOOP
                  l_ret_pos := instr(l_names(i),'-');
                  IF (l_ret_pos > 0) THEN
                     l_ret_name := SUBSTR(l_names(i),1,l_ret_pos-1);
                     l_ret_index := TO_NUMBER(SUBSTR(l_names(i),l_ret_pos+1));
                     l_ret_value := l_values(i);

                     --Payment Server GENERIC Response
                     IF l_ret_name = 'OapfStatus' THEN
                        x_capresp_rec_tbl(l_ret_index).Status := TO_NUMBER(l_ret_value);
                        iby_debug_pub.add('status #'||l_ret_index||'='||x_capresp_rec_tbl(l_ret_index).Status,
                              FND_LOG.LEVEL_STATEMENT,
                              G_DEBUG_MODULE || '.OraCCBatchCapture');
                     ELSIF l_ret_name = 'OapfCode' THEN
                        x_capresp_rec_tbl(l_ret_index).ErrCode := l_ret_value;
                        iby_debug_pub.add('code #'||l_ret_index||'='||x_capresp_rec_tbl(l_ret_index).ErrCode,
                              FND_LOG.LEVEL_STATEMENT,
                              G_DEBUG_MODULE || '.OraCCBatchCapture');
                     ELSIF l_ret_name = 'OapfCause' THEN
                        x_capresp_rec_tbl(l_ret_index).ErrMessage := l_ret_value;
                        iby_debug_pub.add('casue #'||l_ret_index||'='||x_capresp_rec_tbl(l_ret_index).ErrMessage,
                              FND_LOG.LEVEL_STATEMENT,
                              G_DEBUG_MODULE || '.OraCCBatchCapture');
                     ELSIF l_ret_name = 'OapfNlsLang' THEN
                        x_capresp_rec_tbl(l_ret_index).NLS_LANG := l_ret_value;

                     --CAPTURE Operation Related Response
                     ELSIF l_ret_name = 'OapfTransactionId' THEN
                        x_capresp_rec_tbl(l_ret_index).Trxn_ID := TO_NUMBER(l_ret_value);
                     ELSIF l_ret_name = 'OapfTrxnType' THEN
                        x_capresp_rec_tbl(l_ret_index).Trxn_Type := TO_NUMBER(l_ret_value);
                     ELSIF l_ret_name = 'OapfTrxnDate' THEN
                        x_capresp_rec_tbl(l_ret_index).Trxn_Date := TO_DATE(l_ret_value, 'YYYY-MM-DD');
                     ELSIF l_ret_name = 'OapfPmtInstrType' THEN
                        x_capresp_rec_tbl(l_ret_index).PmtInstr_Type := l_ret_value;
                     ELSIF l_ret_name = 'OapfRefcode' THEN
                        x_capresp_rec_tbl(l_ret_index).Refcode := l_ret_value;
                     ELSIF l_ret_name = 'OapfErrLocation' THEN
                        x_capresp_rec_tbl(l_ret_index).ErrorLocation := l_ret_value;
                     ELSIF l_ret_name = 'OapfVendErrCode' THEN
                        x_capresp_rec_tbl(l_ret_index).BEPErrCode := l_ret_value;
                     ELSIF l_ret_name = 'OapfVendErrmsg' THEN
                        x_capresp_rec_tbl(l_ret_index).BEPErrmessage := l_ret_value;

                     --OFFLINE Payment Mode Related Response
                     ELSIF l_ret_name = 'OapfEarliestSettlementDate' THEN
                        x_capresp_rec_tbl(l_ret_index).EarliestSettlement_Date := TO_DATE(l_ret_value, 'YYYY-MM-DD');
                     ELSIF l_ret_name = 'OapfSchedDate' THEN
                        x_capresp_rec_tbl(l_ret_index).Scheduled_Date := TO_DATE(l_ret_value, 'YYYY-MM-DD');
                     END IF;
		  --
		  -- this should be the value of the batch status itself;
		  -- if the batch failed then so has the API call; note
		  -- that it is always considered a batch success if the batch
		  -- is successfully submitted, even if every single trxn
		  -- within it failed for one reason or another
		  --
                  ELSIF l_names(i) = 'OapfStatus' THEN
		     iby_debug_pub.add('trxn status='||l_values(i),
                              FND_LOG.LEVEL_STATEMENT,
                              G_DEBUG_MODULE || '.OraCCBatchCapture');
		     l_batch_status := TO_NUMBER(l_values(i));
		  ELSIF l_names(i) = 'OapfCause' THEN
		     iby_debug_pub.add('batch err msg='||l_values(i),
                              FND_LOG.LEVEL_STATEMENT,
                              G_DEBUG_MODULE || '.OraCCBatchCapture');
		     l_batch_msg := l_values(i);
                  END IF;

	            END LOOP;
            END IF;
         END IF;
       END LOOP;
      EXCEPTION
       WHEN utl_tcp.end_of_input THEN
         NULL; -- end of input
      END;
      utl_tcp.close_connection(l_conn);

      -- Setting API return status to 'U' if response status is not 0.
      IF (NOT trxn_status_success(l_batch_status)) THEN

	x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
	--
	-- if the batch failed an error message should have been
	-- returned
	--
	IF (NOT l_batch_msg IS NULL) THEN
--FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME,l_api_name,l_batch_msg);
	  --
	  -- setting dummy message so that the results
	  -- from the EC Servlet/Java engine can be returned
	  -- verbatim
	  --
	  FND_MESSAGE.SET_NAME('IBY', 'IBY_9999');
	  FND_MESSAGE.SET_TOKEN('MESSAGE_TEXT', l_batch_msg);
	  FND_MSG_PUB.ADD;
	ELSE
	  -- no error message; assuming a complete communication
	  -- failure where the iPayment URL is bad but the webserver
	  -- is up and returns a parseable error page
	  --
	  FND_MESSAGE.SET_NAME('IBY', 'IBY_0001');
	  FND_MSG_PUB.Add;
	END IF;

      END IF;


      -- Standard call to get message count and if count is 1, get message info.
      FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
				  p_data   =>   x_msg_data
				);

      iby_debug_pub.add('Exit',
          FND_LOG.LEVEL_PROCEDURE,
          G_DEBUG_MODULE || '.OraCCBatchCapture');

   EXCEPTION
      WHEN FND_API.G_EXC_ERROR THEN

	 iby_debug_pub.add('In Expected Error',
              FND_LOG.LEVEL_ERROR,
              G_DEBUG_MODULE || '.OraCCBatchCapture');
         --ROLLBACK TO OraCCBatchCapture_PUB;
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

	 iby_debug_pub.add('In Unexpected Error',
              FND_LOG.LEVEL_UNEXPECTED,
              G_DEBUG_MODULE || '.OraCCBatchCapture');
         --ROLLBACK TO OraCCBatchCapture_PUB;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN OTHERS THEN

	 iby_debug_pub.add('In Others Exception',
              FND_LOG.LEVEL_UNEXPECTED,
              G_DEBUG_MODULE || '.OraCCBatchCapture');
	 iby_debug_pub.add('Exception code='||SQLCODE,
              FND_LOG.LEVEL_UNEXPECTED,
              G_DEBUG_MODULE || '.OraCCBatchCapture');
	 iby_debug_pub.add('Exception message='||SQLERRM,
              FND_LOG.LEVEL_UNEXPECTED,
              G_DEBUG_MODULE || '.OraCCBatchCapture');

         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_api_name, SQLCODE||':'||SQLERRM);
         END IF;

         FND_MSG_PUB.Count_And_Get ( p_count  =>  x_msg_count,
                                     p_data   =>  x_msg_data
                                   );


   END OraCCBatchCapture;
--------------------------------------------------------------------------------------------
END XX_IBY_PAYMENT_ADAPTER_PUB;

