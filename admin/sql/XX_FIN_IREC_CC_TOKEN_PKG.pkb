create or replace PACKAGE BODY XX_FIN_IREC_CC_TOKEN_PKG
-- +===========================================================================+
-- |                  Office Depot - Office Max Integration Project            |
-- +===========================================================================+
-- | Name        : XX_FIN_IREC_CC_TOKEN_PKG                                    |
-- | RICE        : E1294                                                       |
-- |                                                                           |
-- | Description :                                                             |
-- | This package helps is to execute AJB request call and retrieve token      |
-- | from Response.                                                            |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author            Remarks                             |
-- |======== =========== =============     ====================================|
-- |DRAFT 1  20-MAY-2015 Sreedhar Mohan    Initial draft version               |
-- |      2  20-NOV-2015 Vasu Raparla      Modified for Defect 35910           |
-- |      3  20-May-2016 Suresh Naragam    Changes done for SSL/TSL Upgrade    |
-- |                                       (defect#37222, 37644)               |
-- |1.0      26-Aug-2016 Sridevi K         Changes for Vantiv                  |
-- |1.1      20-JUL-2020 Divyansh Saini    Added procedure for ECOMM           |
-- |                                       tokenization for NAIT-129669        |
-- +===========================================================================+
IS
    FUNCTION mask_account_number(p_value IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
    
      RETURN lpad(substr(p_value,-4),length(p_value),'*');
    EXCEPTION
      WHEN OTHERS THEN
        RETURN null;
    END mask_account_number;

    FUNCTION VALIDATE_TOKEN (
         P_TOKEN                IN VARCHAR2
        ) RETURN VARCHAR2
    IS

    ln_token      NUMBER(16)  := null;
    lc_token_flag VARCHAR2(1) := 'N';

    BEGIN

      lc_token_flag := 'N';
      
      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
         fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.VALIDATE_TOKEN', 'VALIDATE_TOKEN(+)' );
      END IF;    

      ln_token := to_number(P_TOKEN);
      lc_token_flag := 'Y';

      IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
         fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.VALIDATE_TOKEN', 'lc_token_flag: ' || lc_token_flag );
         fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.VALIDATE_TOKEN', 'VALIDATE_TOKEN(-)' );
      END IF;    

      return lc_token_flag;

    EXCEPTION
      WHEN OTHERS THEN
        lc_token_flag := 'N';
        --IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
           fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.VALIDATE_TOKEN', 'Exception in converting the token to number, lc_token_flag:' || lc_token_flag || ', : sqlerrm' || sqlerrm );
        --END IF;    
        return lc_token_flag;
    END VALIDATE_TOKEN;    

    PROCEDURE GET_TOKEN (
         P_ERROR_MSG            IN OUT NOCOPY VARCHAR2
        ,P_ERROR_CODE           IN OUT NOCOPY VARCHAR2
        ,P_OapfAction           IN VARCHAR2 DEFAULT NULL
        ,P_OapfTransactionId    IN VARCHAR2 DEFAULT NULL
        ,P_OapfNlsLang          IN VARCHAR2 DEFAULT NULL
        ,P_OapfPmtInstrID       IN VARCHAR2 
        ,P_OapfPmtFactorFlag    IN VARCHAR2 DEFAULT NULL
        ,P_OapfPmtInstrExp      IN DATE 
        ,P_OapfOrgType          IN VARCHAR2 DEFAULT NULL
        ,P_OapfTrxnRef          IN VARCHAR2 DEFAULT NULL
        ,P_OapfPmtInstrDBID     IN VARCHAR2 DEFAULT NULL
        ,P_OapfPmtChannelCode   IN VARCHAR2 DEFAULT NULL
        ,P_OapfAuthType         IN VARCHAR2 DEFAULT NULL
        ,P_OapfTrxnmid          IN VARCHAR2 DEFAULT NULL
        ,P_OapfStoreId          IN VARCHAR2 DEFAULT NULL
        ,P_OapfPrice            IN VARCHAR2 DEFAULT NULL
        ,P_OapfOrderId          IN VARCHAR2 DEFAULT NULL
        ,P_OapfCurr             IN VARCHAR2 DEFAULT NULL
        ,P_OapfRetry            IN VARCHAR2 DEFAULT NULL
        ,P_OapfCVV2             IN VARCHAR2 DEFAULT NULL
        ,X_TOKEN               OUT VARCHAR2        
        ,X_TOKEN_FLAG          OUT VARCHAR2        
    )                                       
    IS
    
      l_ajb_url             VARCHAR2(4000) := NULL;
      l_ajb_url_for_log     VARCHAR2(4000) := NULL;
      l_servlet_url         VARCHAR2(1000)  := NULL;
      l_OapfAction          VARCHAR2(256)   := NULL;
      l_OapfTransactionId   VARCHAR2(256)   := NULL;
      l_OapfNlsLang         VARCHAR2(256)   := NULL;
      l_OapfPmtInstrID      VARCHAR2(256)   := NULL; --16 digits
      l_OapfPmtFactorFlag   VARCHAR2(256)   := NULL;
      l_OapfPmtInstrExp     VARCHAR2(256)   := NULL; --Exp Date
      l_OapfOrgType         VARCHAR2(256)   := NULL;
      l_OapfTrxnRef         VARCHAR2(256)   := NULL;
      l_OapfPmtInstrDBID    VARCHAR2(256)   := NULL;
      l_OapfPmtChannelCode  VARCHAR2(256)   := NULL;
      l_OapfAuthType        VARCHAR2(256)   := NULL;
      l_OapfTrxnmid         VARCHAR2(256)   := NULL;
      l_OapfStoreId         VARCHAR2(256)   := NULL;
      l_OapfPrice           VARCHAR2(256)   := NULL;
      l_OapfOrderId         VARCHAR2(256)   := NULL;
      l_OapfCurr            VARCHAR2(256)   := NULL;
      l_OapfRetry           VARCHAR2(256)   := NULL;
      l_OapfCVV2            VARCHAR2(256)   := NULL;
      l_OdReqToken          VARCHAR2(256)   := NULL;
      l_wallet_location     VARCHAR2(256)   := NULL;
      l_password            VARCHAR2(256)   := NULL;
        
      P_DATA_TYPE           VARCHAR2(256)  := 'TEXT/XML';
      P_PROXY_IN            VARCHAR2(256)  := NULL;
      P_NO_PROXY_DOMAINS_IN VARCHAR2(256)  := NULL;
      P_USERNAME_IN         VARCHAR2(256)  := NULL;
      P_PASSWORD_IN         VARCHAR2(256)  := NULL;

      L_HTTP_REQ            UTL_HTTP.REQ;
      L_HTTP_RESP           UTL_HTTP.RESP;
      L_MY_SCHEME           VARCHAR2(256);
      L_MY_REALM            VARCHAR2(256);
      L_MY_PROXY            BOOLEAN;
      L_VALUE               VARCHAR2(32767) := NULL;
      L_AJB_RESPONSE_STRING VARCHAR2(1000) := NULL;
      L_TOKEN               VARCHAR2(30)   := NULL;  --16 digits
      L_TOKEN_FLAG          VARCHAR2(1)    := NULL;  
      l_exp_month           varchar2(2) := null;
      l_exp_year            varchar2(4) := null;
      
      l_encoded_date        varchar2(30);

      l_err_response        VARCHAR2(256);
      l_action_code         VARCHAR2(15);
      l_iso_resp_code       VARCHAR2(30);

      l_wrong_hvt           EXCEPTION;
      l_hvt_exception       EXCEPTION;
      
      AJB_TIMEOUT_EXCEPTION EXCEPTION;

      BEGIN
        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
           fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'GET_TOKEN(+)' );
        END IF;    
        
        SELECT 
           TARGET_VALUE1
          ,TARGET_VALUE2
          ,TARGET_VALUE3
          ,TARGET_VALUE4
          ,TARGET_VALUE5
          ,TARGET_VALUE6
          ,TARGET_VALUE7
          ,TARGET_VALUE8
          ,TARGET_VALUE9
          ,TARGET_VALUE10
          ,TARGET_VALUE11
          ,TARGET_VALUE12
          ,TARGET_VALUE13
          ,TARGET_VALUE14
          ,TARGET_VALUE15
          ,TARGET_VALUE16
          ,TARGET_VALUE17
          ,TARGET_VALUE18
          ,TARGET_VALUE19
          ,TARGET_VALUE20
          into
           l_servlet_url
          ,l_OapfAction
          ,l_OapfTransactionId
          ,l_OapfNlsLang
          ,l_OapfPmtInstrID
          ,l_OapfPmtFactorFlag
          ,l_OapfPmtInstrExp
          ,l_OapfOrgType
          ,l_OapfTrxnRef
          ,l_OapfPmtInstrDBID
          ,l_OapfPmtChannelCode
          ,l_OapfAuthType
          ,l_OapfTrxnmid
          ,l_OapfStoreId
          ,l_OapfPrice
          ,l_OapfOrderId
          ,l_OapfCurr
          ,l_OapfRetry
          ,l_OapfCVV2
          ,l_OdReqToken
        FROM XX_FIN_TRANSLATEVALUES     VAL,
             XX_FIN_TRANSLATEDEFINITION DEF
        WHERE 1=1
        and   DEF.TRANSLATE_ID = VAL.TRANSLATE_ID
        and   DEF.TRANSLATION_NAME='XX_FIN_IREC_TOKEN_PARAMS'
        and   VAL.SOURCE_VALUE1 = 'AJB_URL'     
        and   VAL.ENABLED_FLAG = 'Y'
        and   SYSDATE between VAL.START_DATE_ACTIVE and nvl(VAL.END_DATE_ACTIVE, SYSDATE+1)
        ; 

        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
           fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'P_OapfPmtInstrExp: ' || P_OapfPmtInstrExp );
        END IF;    

        select to_char(P_OapfPmtInstrExp,'MM'), to_char(P_OapfPmtInstrExp,'RR')
        into  l_exp_month, l_exp_year
        from dual;

        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
           fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'P_OapfPmtInstrExp: ' || P_OapfPmtInstrExp );
        END IF;    
        
        l_encoded_date := l_exp_month || '%2F' || l_exp_year;

        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
           fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'l_encoded_date: ' || l_encoded_date );
        END IF;    
        
        l_ajb_url :=   l_servlet_url         ||    
                       l_OapfAction          || P_OapfAction           || 
                       l_OapfTransactionId   || P_OapfTransactionId    || 
                       l_OapfNlsLang         || P_OapfNlsLang          || 
                       l_OapfPmtInstrID      || P_OapfPmtInstrID       ||  --add cc number here
                       l_OapfPmtFactorFlag   || P_OapfPmtFactorFlag    || 
                       l_OapfPmtInstrExp     || l_encoded_date         ||  --add exp date here
                       l_OapfOrgType         || P_OapfOrgType          || 
                       l_OapfTrxnRef         || P_OapfTrxnRef          || 
                       l_OapfPmtInstrDBID    || P_OapfPmtInstrDBID     || 
                       l_OapfPmtChannelCode  || P_OapfPmtChannelCode   || 
                       l_OapfAuthType        || P_OapfAuthType         || 
                       l_OapfTrxnmid         || P_OapfTrxnmid          || 
                       l_OapfStoreId         || P_OapfStoreId          || 
                       l_OapfPrice           || P_OapfPrice            || 
                       l_OapfOrderId         || P_OapfOrderId          || 
                       l_OapfCurr            || P_OapfCurr             || 
                       l_OapfRetry           || P_OapfRetry            || 
                       l_OapfCVV2            || P_OapfCVV2             || 
                       l_OdReqToken      
                       ;
        l_ajb_url_for_log := 
                       l_servlet_url         ||    
                       l_OapfAction          || P_OapfAction           || 
                       l_OapfTransactionId   || P_OapfTransactionId    || 
                       l_OapfNlsLang         || P_OapfNlsLang          || 
                       l_OapfPmtInstrID      || mask_account_number(P_OapfPmtInstrID) ||  --add cc number here
                       l_OapfPmtFactorFlag   || P_OapfPmtFactorFlag    || 
                       l_OapfPmtInstrExp     || l_encoded_date         ||  --add exp date here
                       l_OapfOrgType         || P_OapfOrgType          || 
                       l_OapfTrxnRef         || P_OapfTrxnRef          || 
                       l_OapfPmtInstrDBID    || P_OapfPmtInstrDBID     || 
                       l_OapfPmtChannelCode  || P_OapfPmtChannelCode   || 
                       l_OapfAuthType        || P_OapfAuthType         || 
                       l_OapfTrxnmid         || P_OapfTrxnmid          || 
                       l_OapfStoreId         || P_OapfStoreId          || 
                       l_OapfPrice           || P_OapfPrice            || 
                       l_OapfOrderId         || P_OapfOrderId          || 
                       l_OapfCurr            || P_OapfCurr             || 
                       l_OapfRetry           || P_OapfRetry            || 
                       l_OapfCVV2            || P_OapfCVV2             || 
                       l_OdReqToken      
                       ;
    
        --UTL_HTTP.SET_RESPONSE_ERROR_CHECK(enable => TRUE );
        --UTL_HTTP.SET_DETAILED_EXCP_SUPPORT(enable => TRUE );
        --UTL_HTTP.SET_WALLET('file:/app/ebs/ctgsixxxxx/xxfin/ewallet','ipay1234');
        -- Changes for SSL/TSL Upgrade Start
        BEGIN
          SELECT 
             TARGET_VALUE1
            ,TARGET_VALUE2
            into
            l_wallet_location
           ,l_password
          FROM XX_FIN_TRANSLATEVALUES     VAL,
               XX_FIN_TRANSLATEDEFINITION DEF
          WHERE 1=1
          and   DEF.TRANSLATE_ID = VAL.TRANSLATE_ID
          and   DEF.TRANSLATION_NAME='XX_FIN_IREC_TOKEN_PARAMS'
          and   VAL.SOURCE_VALUE1 = 'WALLET_LOCATION'     
          and   VAL.ENABLED_FLAG = 'Y'
          and   SYSDATE between VAL.START_DATE_ACTIVE and nvl(VAL.END_DATE_ACTIVE, SYSDATE+1); 
        EXCEPTION WHEN OTHERS THEN
          fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'Wallet Location Not Found' );
          l_wallet_location := NULL;
          l_password := NULL;
        END;
        IF l_wallet_location IS NOT NULL THEN
          UTL_HTTP.SET_WALLET(l_wallet_location,l_password);
        END IF;
        -- Changes for SSL/TSL Upgrade End
        -- Begin the post request
        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
           fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'before begin_request, l_ajb_url: ' || l_ajb_url_for_log );
        END IF;    

        l_http_req := utl_http.begin_request (l_ajb_url, 'POST', 'HTTP/1.1');

        UTL_HTTP.SET_PERSISTENT_CONN_SUPPORT(TRUE);
        UTL_HTTP.SET_TRANSFER_TIMEOUT (60);

        -- Process the request and get the response.
        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
           fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'before utl_http.get_response' );
        END IF;    

        BEGIN
          
          l_http_resp := utl_http.get_response (l_http_req);
          
          l_ajb_response_string := '';
          l_token := '';
          
          LOOP
            utl_http.read_line(l_http_resp, l_value, TRUE);

            IF( instr(l_value,'Response from AJB =>') > 0 ) THEN

              IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                 fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'l_value:' || l_value );
              END IF;

              l_ajb_response_string := substrb(l_value,instr(l_value,'Response from AJB =>')+length('Response from AJB =>'),length(l_value));
              --l_token := substr(l_value,instr(l_value ,',',1,32)+1  ,length(P_OapfPmtInstrID));
              --l_token := substr(l_value,instr(l_value ,',',1,32)+1  ,16);
              l_action_code    := substr(l_value,instr(l_value ,',',1,3)+1  ,instr(l_value ,',',1,4) - (instr(l_value ,',',1,3)+1));
              l_token          := substr(l_value,instr(l_value ,',',1,32)+1  ,instr(l_value ,',',1,33) - (instr(l_value ,',',1,32)+1));
              l_err_response   := substr(l_value,instr(l_value ,',',1,37)+1  ,instr(l_value ,',',1,38) - (instr(l_value ,',',1,37)+1));
              l_iso_resp_code  := substr(l_value,instr(l_value ,',',1,52)+1  ,instr(l_value ,',',1,53) - (instr(l_value ,',',1,52)+1));
              EXIT;

            END IF;
          END LOOP; 
          
          IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
            fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'l_ajb_response_string:' || l_ajb_response_string );
            fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'l_token:' || l_token );
            fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'l_err_response:' || l_err_response );
            fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'l_action_code:' || l_action_code );
            fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'l_iso_resp_code:' || l_iso_resp_code );
          END IF; 
         
          if (l_action_code != '0') then
            if ( l_action_code = '2' ) then
               if ( (P_OapfPmtInstrID = l_token) or (length(l_token) = 19)) then
                 RAISE l_wrong_hvt; 
               end if;
            else
              RAISE l_hvt_exception;
            end if;       
          end if;
          
        EXCEPTION
          WHEN l_wrong_hvt THEN
            p_error_msg := 'Payment Process Failed: ' ||  l_err_response;
            p_error_code := 3;
            RETURN;
          WHEN l_hvt_exception THEN
            p_error_msg := 'Payment Process Failed: ' ||  l_err_response;
            p_error_code := 3;
            RETURN;
          WHEN OTHERS THEN
            p_error_msg := substrb('No Response from AJB' || utl_tcp.crlf  ||utl_tcp.crlf ||'URL used :'||l_ajb_url_for_log|| utl_tcp.crlf  ||utl_tcp.crlf ||
                                  'Response :'||l_ajb_response_string,1,999);
            p_error_code := 3;
            --IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
               fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'Exception in getting the token - ' || sqlerrm );
            --END IF;    
        END;


        l_token_flag := validate_token ( l_token);
        if (l_token_flag = 'N') then
          p_error_msg := l_token;
          p_error_code := 3;
        end if;
        x_token := l_token;
        x_token_flag := l_token_flag;

        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
           fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'l_token_flag:' || l_token_flag );
        END IF;    
        
        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
           fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'after utl_http.get_response, status code: ' || l_http_resp.status_code || ',reason phrase: ' || l_http_resp.reason_phrase );
        END IF;    

        -- Look for client-side error and report it.
        if (l_http_resp.status_code >= 400) and (l_http_resp.status_code <= 499) then
            -- Detect whether the page is password protected,
            -- and we didn't supply the right authorization.
            -- Note the use of utl_http.HTTP_UNAUTHORIZED, a predefined
            -- utl_http package global variable
            if (l_http_resp.status_code = utl_http.HTTP_UNAUTHORIZED) then

              utl_http.get_authentication( l_http_resp, l_my_scheme, l_my_realm, l_my_proxy);

              if (l_my_proxy) then
                    
                p_error_msg := substrb('Web proxy server is protected. Please supply the required ' || l_my_scheme || ' authentication username/password for realm ' || l_my_realm || ' for the proxy server.',1,199);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                   fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'Web proxy server is protected. Please supply the required ' || l_my_scheme || ' authentication username/password for realm ' || l_my_realm || ' for the proxy server.' );
                END IF;

              else

                p_error_msg := substrb('Web page is protected. Please supply the required ' || l_my_scheme || ' authentication username/password for realm ' || l_my_realm || ' for the proxy server.',1,199);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                   fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'Web page ' || l_ajb_url_for_log || ' is protected. Please supplied the required ' ||l_my_scheme || ' authentication username/password for realm ' || l_my_realm ||' for the Web page.' );
                END IF;
              end if;
            else

              p_error_msg := substrb('Please Check the URL.'|| utl_tcp.crlf  ||utl_tcp.crlf ||'URL used :'||l_ajb_url_for_log|| utl_tcp.crlf  ||utl_tcp.crlf ||
                                  'Response :'||l_ajb_response_string,1,999);

              IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                 fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'Check the URL...' );
              END IF;

            end if;
            utl_http.end_response(l_http_resp);
            return;

        -- Look for server-side error and report it.
        elsif (l_http_resp.status_code >= 500) and (l_http_resp.status_code <= 599) then
            p_error_msg := 'Check if the Web site is up.';
            utl_http.end_response(l_http_resp);
            return;
        end if;
        utl_http.end_response (l_http_resp);
        
        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
           fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'get_token(-)' );
        END IF;

    EXCEPTION
        WHEN utl_http.end_of_body THEN
          p_error_msg := substrb(substr(sqlerrm,1,150) || utl_tcp.crlf  ||utl_tcp.crlf ||'URL used :'||l_ajb_url_for_log|| utl_tcp.crlf  ||utl_tcp.crlf ||
                                  'Response :'||l_ajb_response_string,1,999);
          utl_http.end_response(l_http_resp);    
        WHEN OTHERS THEN
            fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN', 'Exception in getting the token - ' || sqlerrm );
             p_error_msg := substrb(substr(sqlerrm,1,150) || utl_tcp.crlf  ||utl_tcp.crlf ||'URL used :'||l_ajb_url_for_log|| utl_tcp.crlf  ||utl_tcp.crlf ||
                                  'Response :'||l_ajb_response_string,1,999);
            RAISE;
    END GET_TOKEN;

/*========================================================================
 | PUBLIC function GET_TOKEN_ECOMM
 |
 | DESCRIPTION
 |      Get token values from Ecomm webservice.
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_account_number   IN      varchar2
 |      p_expiration_date   IN      varchar2
 |
 | RETURNS
 |      x_token 
 |      x_token_flag 
 |      x_error_msg 
 |      x_error_code  
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 22-JUL-2020           Divyansh Saini      Created
 |
 *=======================================================================*/	
	
PROCEDURE GET_TOKEN_ECOMM(p_account_number   IN              VARCHAR2,
                          p_expiration_date  IN              VARCHAR2,
                          x_token            OUT NOCOPY      VARCHAR2,
                          x_token_flag       OUT NOCOPY      VARCHAR2,
                          x_error_msg        IN OUT NOCOPY   VARCHAR2,
                          x_error_code       IN OUT NOCOPY   VARCHAR2
) IS

  L_HTTP_REQ         UTL_HTTP.REQ;
  L_HTTP_RESP        UTL_HTTP.RESP;
  l_ecomm_url        VARCHAR2(2000);
  lclob_buffer       CLOB;
  L_MY_SCHEME           VARCHAR2(256);
  L_MY_REALM            VARCHAR2(256);
  L_MY_PROXY            BOOLEAN;
  lc_buffer          VARCHAR2(10000);
  lv_payload         VARCHAR2(2000);
  l_wallet_location  VARCHAR2(2000);
  l_password         VARCHAR2(100);
  lv_ecomm_url       VARCHAR2(2000);
  lv_status          VARCHAR2(10) := 'S';
  l_action_code     NUMBER;
  lb_error    VARCHAR2(20);
  l_err_response   VARCHAR2(2000);
  ln_token    NUMBER;
  lv_response VARCHAR2(2000);
  l_wrong_hvt EXCEPTION;
  L_HVT_EXCEPTION EXCEPTION;
  l_token_flag VARCHAR2(2);
  ln_trxn_id NUMBER;
BEGIN
    IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
        fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'Start GET_TOKEN_ECOMM ');
    END IF;
  --
  --Create Payload
  --
    SELECT '{"payPageRegistrationID":"'||p_account_number||'","reference":"","source":""}'
      INTO lv_payload
      FROM DUAL;
    --
    --get sequence
    --
    SELECT xx_ar_irec_cc_token_payloads_s.nextval INTO ln_trxn_id FROM DUAL;
     --
     -- Getting the wallet details
    BEGIN
      SELECT 
         TARGET_VALUE1
        ,TARGET_VALUE2
        into
        l_wallet_location
       ,l_password
      FROM XX_FIN_TRANSLATEVALUES     VAL,
           XX_FIN_TRANSLATEDEFINITION DEF
      WHERE 1=1
      and   DEF.TRANSLATE_ID = VAL.TRANSLATE_ID
      and   DEF.TRANSLATION_NAME='XX_FIN_IREC_TOKEN_PARAMS'
      and   VAL.SOURCE_VALUE1 = 'WALLET_LOCATION'     
      and   VAL.ENABLED_FLAG = 'Y'
      and   SYSDATE between VAL.START_DATE_ACTIVE and nvl(VAL.END_DATE_ACTIVE, SYSDATE+1); 
    EXCEPTION WHEN OTHERS THEN
      fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'Wallet Location Not Found' );
      l_wallet_location := NULL;
      l_password := NULL;
    END;
  --
  --Set wallet
  --
    IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
        fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'l_wallet_location '||l_wallet_location);
        fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'l_password '||l_password);
    END IF;
    IF l_wallet_location IS NOT NULL THEN
      UTL_HTTP.SET_WALLET(l_wallet_location,l_password);
    END IF;
  --
  --Get Ecomm URL
  --
    BEGIN
      SELECT 
         TARGET_VALUE1
        into
        lv_ecomm_url
      FROM XX_FIN_TRANSLATEVALUES     VAL,
           XX_FIN_TRANSLATEDEFINITION DEF
      WHERE 1=1
      and   DEF.TRANSLATE_ID = VAL.TRANSLATE_ID
      and   DEF.TRANSLATION_NAME='XX_FIN_IREC_TOKEN_PARAMS'
      and   VAL.SOURCE_VALUE1 = 'ECOMM_TOKEN_URL'     
      and   VAL.ENABLED_FLAG = 'Y'
      and   SYSDATE between VAL.START_DATE_ACTIVE and nvl(VAL.END_DATE_ACTIVE, SYSDATE+1); 
    EXCEPTION WHEN OTHERS THEN
      fnd_log.STRING (fnd_log.level_statement, 'XX_EAI_AUTHORIZATION.GET_TOKEN_ECOMM', 'Url Not Found' );
      lv_ecomm_url := NULL;
    END;
    IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
        fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'lv_ecomm_url '||lv_ecomm_url);
        fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', ' Begin request');
    END IF;
    l_http_req := utl_http.begin_request (lv_ecomm_url, 'POST', 'HTTP/1.1');
    UTL_HTTP.SET_PERSISTENT_CONN_SUPPORT(TRUE);
    UTL_HTTP.SET_TRANSFER_TIMEOUT (60);
    UTL_HTTP.set_header(l_http_req, 'user-agent', 'mozilla/4.0');
    UTL_HTTP.set_header(l_http_req, 'content-type', 'application/json');
    UTL_HTTP.set_header(l_http_req, 'Content-Length', LENGTH(lv_payload));
    UTL_HTTP.write_text(l_http_req, lv_payload);
    l_http_resp := utl_http.get_response (l_http_req);
    BEGIN
      lclob_buffer := EMPTY_CLOB;
      LOOP
        UTL_HTTP.read_text(l_http_resp, lc_buffer, LENGTH(lc_buffer));
        lclob_buffer := lclob_buffer || lc_buffer;
      END LOOP;
      UTL_HTTP.end_response(l_http_resp);
    EXCEPTION
    WHEN UTL_HTTP.end_of_body THEN
      UTL_HTTP.end_response(l_http_resp);
    END;
    
    IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
        fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'fetch values from response ');
    END IF;
      BEGIN
         SELECT *
           INTO l_action_code,lb_error,l_err_response,ln_token,lv_response
           FROM json_table(lclob_buffer
         ,'$'
         COLUMNS (
         code       NUMBER(10) PATH '$.statusCode',  
         hasError   VARCHAR2(2000 CHAR) PATH '$.hasErrorResponse',  
         reason   VARCHAR2(2000 CHAR) PATH '$.responseObject.reason',  
         token   NUMBER(20) PATH '$.responseObject.token',  
         responseCode VARCHAR2(2000 CHAR) PATH  '$.responseObject.responseCode' 
         ));
      EXCEPTION WHEN OTHERS THEN
         fnd_log.STRING (fnd_log.level_statement, 'XX_EAI_AUTHORIZATION.BUILD_RESPONSE', 'error while parsing response' );
      END;

    IF ln_token IS NOT NULL THEN
        SELECT replace(lclob_buffer,ln_token,'****************')
          INTO lclob_buffer
          FROM DUAL;
    END IF;
    --
    --Insert Payload Details
    --
    INSERT
    INTO xx_ar_irec_cc_token_payloads VALUES
    (
      ln_trxn_id,
      p_account_number,
      p_expiration_date,
      lv_payload,
      lclob_buffer,
      sysdate,
      fnd_global.user_id,
      sysdate,
      fnd_global.user_id,
      fnd_global.login_id,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      decode(lb_error,'false','Y','N')
    );

      BEGIN
         IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
            fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'lclob_buffer:' || lclob_buffer );
            fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'ln_token:' || ln_token );
            fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'l_err_response:' || l_err_response );
            fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'l_action_code:' || l_action_code );
--            fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'l_iso_resp_code:' || l_iso_resp_code );
          END IF; 
         
          if (l_action_code != '200') then
            if ( l_action_code = '2' ) then
               if ( (p_account_number = ln_token) or (length(ln_token) = 19)) then
                 RAISE l_wrong_hvt; 
               end if;
            else
              RAISE l_hvt_exception;
            end if;       
          end if;
          
        EXCEPTION
          WHEN l_wrong_hvt THEN
            x_error_msg := 'Payment Process Failed: ' ||  l_err_response;
            x_error_code := 3;
            RETURN;
          WHEN l_hvt_exception THEN
            x_error_msg := 'Payment Process Failed: ' ||  l_err_response;
            x_error_code := 3;
            RETURN;
          WHEN OTHERS THEN
            x_error_msg := substrb('No Response from AJB' || utl_tcp.crlf  ||utl_tcp.crlf ||'URL used :'||l_ecomm_url|| utl_tcp.crlf  ||utl_tcp.crlf ||
                                  'Response :'||lclob_buffer,1,999);
            x_error_code := 3;
            --IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
               fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'Exception in getting the token - ' || sqlerrm );
            --END IF;    
        END;


        l_token_flag := validate_token ( ln_token);
        if (l_token_flag = 'N') then
          x_error_msg := ln_token;
          x_error_code := 3;
        end if;
        fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'ln_token:' || ln_token );
        fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'l_token_flag:' || l_token_flag );
        x_token := ln_token;
        x_token_flag := l_token_flag;

        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
           fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'l_token_flag:' || l_token_flag );
        END IF;    
        
        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
           fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'after utl_http.get_response, status code: ' || l_http_resp.status_code || ',reason phrase: ' || l_http_resp.reason_phrase );
        END IF;    

        -- Look for client-side error and report it.
        if (l_http_resp.status_code >= 400) and (l_http_resp.status_code <= 499) then
            -- Detect whether the page is password protected,
            -- and we didn't supply the right authorization.
            -- Note the use of utl_http.HTTP_UNAUTHORIZED, a predefined
            -- utl_http package global variable
            if (l_http_resp.status_code = utl_http.HTTP_UNAUTHORIZED) then

              utl_http.get_authentication( l_http_resp, l_my_scheme, l_my_realm, l_my_proxy);

              if (l_my_proxy) then
                    
                x_error_msg := substrb('Web proxy server is protected. Please supply the required ' || l_my_scheme || ' authentication username/password for realm ' || l_my_realm || ' for the proxy server.',1,199);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                   fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'Web proxy server is protected. Please supply the required ' || l_my_scheme || ' authentication username/password for realm ' || l_my_realm || ' for the proxy server.' );
                END IF;

              else

                x_error_msg := substrb('Web page is protected. Please supply the required ' || l_my_scheme || ' authentication username/password for realm ' || l_my_realm || ' for the proxy server.',1,199);

                IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                   fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'Web page ' || l_ecomm_url || ' is protected. Please supplied the required ' ||l_my_scheme || ' authentication username/password for realm ' || l_my_realm ||' for the Web page.' );
                END IF;
              end if;
            else

              x_error_msg := substrb('Please Check the URL.'|| utl_tcp.crlf  ||utl_tcp.crlf ||'URL used :'||l_ecomm_url|| utl_tcp.crlf  ||utl_tcp.crlf ||
                                  'Response :'||lclob_buffer,1,999);

              IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
                 fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'Check the URL...' );
              END IF;

            end if;
            utl_http.end_response(l_http_resp);
            return;

        -- Look for server-side error and report it.
        elsif (l_http_resp.status_code >= 500) and (l_http_resp.status_code <= 599) then
            x_error_msg := 'Check if the Web site is up.';
            utl_http.end_response(l_http_resp);
            return;
        end if;
        utl_http.end_response (l_http_resp);
        
        IF (fnd_log.level_statement >= fnd_log.g_current_runtime_level) THEN
           fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'GET_TOKEN_ECOMM(-)' );
        END IF;

    EXCEPTION
        WHEN utl_http.end_of_body THEN
          x_error_msg := substrb(substr(sqlerrm,1,150) || utl_tcp.crlf  ||utl_tcp.crlf ||'URL used :'||l_ecomm_url|| utl_tcp.crlf  ||utl_tcp.crlf ||
                                  'Response :'||lclob_buffer,1,999);
          utl_http.end_response(l_http_resp);    
        WHEN OTHERS THEN
            fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_IREC_CC_TOKEN_PKG.GET_TOKEN_ECOMM', 'Exception in getting the token - ' || sqlerrm );
             x_error_msg := substrb(substr(sqlerrm,1,150) || utl_tcp.crlf  ||utl_tcp.crlf ||'URL used :'||l_ecomm_url|| utl_tcp.crlf  ||utl_tcp.crlf ||
                                  'Response :'||lclob_buffer,1,999);
            RAISE;
    END GET_TOKEN_ECOMM;
end XX_FIN_IREC_CC_TOKEN_PKG;
/