SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_IBY_SECURE_HTTP

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_IBY_SECURE_HTTP
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Transmitting the settlement file thru Secure HTTP   |
-- | RICE ID     :                                                     |
-- | Description : Transmitting the generated settlement file          |
-- |                    thru Secure HTTP to AJB                        |
-- |                                                                   |
-- |                                                                   |
-- |Change ecord:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======  ===========  ==================    =======================|
-- |1.0      04-FEB-2007  Gowri Shankar         Initial version        |
-- |                                                                   |
-- +===================================================================+

-- +===================================================================+
-- | Name : TRANSMIT                                                   |
-- | Description : To tranmit the file thru Secure HTTP                |
-- | Parameters :  p_file_path, p_file_name                            |
-- | Returns    :  x_status_code, x_reason                             |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE TRANSMIT    (
                             p_file_path             IN  VARCHAR2
                            ,p_file_name             IN  VARCHAR2
                            ,x_status_code           OUT VARCHAR2
                            ,x_reason                OUT VARCHAR2
                           )
    IS

        lf_out_file               UTL_FILE.FILE_TYPE;
        lf_in_file                UTL_FILE.FILE_TYPE;
        ln_chunk_size             BINARY_INTEGER := 32767;
        lc_data_buffer            VARCHAR2(32767) := NULL;
        lh_req                    UTL_HTTP.REQ;
        lh_resp                   UTL_HTTP.RESP;
        lc_line_type              VARCHAR2(1000);
        lc_pre_cc_data            VARCHAR2(32767) := NULL;       
        lc_post_cc_data           VARCHAR2(32767) := NULL;
        lc_encrypt_cc_data        VARCHAR2(1000) := NULL;
        lc_decrypt_cc_data        VARCHAR2(1000) := NULL;
        lc_decrypt_error_msg      VARCHAR2(4000) := NULL;
        lc_read_http_data         LONG;
        lc_http_url               VARCHAR2(4000) := NULL;
        lc_http_ssl               VARCHAR2(4000) := NULL;
        lc_http_version           VARCHAR2(4000) := NULL;
        lc_http_user_agent        VARCHAR2(4000) := NULL;
        lc_http_cache_ctrl        VARCHAR2(4000) := NULL;
        lc_http_trn_encode        VARCHAR2(4000) := NULL;
        lc_wallet_location        VARCHAR2(4000) := NULL;
        lc_wallet_passwd          VARCHAR2(4000) := NULL;

        lc_errr_loc               VARCHAR2(4000) := NULL;
        lc_errr_debug             VARCHAR2(4000) := NULL;
        lp_http_errcode           PLS_INTEGER;
        lc_http_errmesg           VARCHAR2(4000);

    BEGIN

        x_status_code := NULL;

        lc_errr_loc   := 'Getting the Translation for the HTTPURL';
        lc_errr_debug := '';

        SELECT XFTV.target_value1
        INTO   lc_http_url
        FROM   xx_fin_translatevalues XFTV
              ,xx_fin_translatedefinition XFTD
        WHERE  XFTV.translate_id    = XFTD.translate_id
        AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
        AND    XFTV.source_value1 = 'HTTPURL'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';

        lc_errr_loc   := 'Getting the Translation for the HTTPSSLFlag';
        lc_errr_debug := '';

        SELECT XFTV.target_value1
        INTO   lc_http_ssl
        FROM   xx_fin_translatevalues XFTV
              ,xx_fin_translatedefinition XFTD
        WHERE  XFTV.translate_id    = XFTD.translate_id
        AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
        AND    XFTV.source_value1 = 'HTTPSSLFlag'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';

        lc_errr_loc   := 'Getting the Translation for the HTTPVersion';
        lc_errr_debug := '';


        SELECT XFTV.target_value1
        INTO   lc_http_version
        FROM   xx_fin_translatevalues XFTV
              ,xx_fin_translatedefinition XFTD
        WHERE  XFTV.translate_id    = XFTD.translate_id
        AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
        AND    XFTV.source_value1 = 'HTTPVersion'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';

        lc_errr_loc   := 'Getting the Translation for the HTTPUserAgent';
        lc_errr_debug := '';

        SELECT XFTV.target_value1
        INTO   lc_http_user_agent
        FROM   xx_fin_translatevalues XFTV
              ,xx_fin_translatedefinition XFTD
        WHERE  XFTV.translate_id    = XFTD.translate_id
        AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
        AND    XFTV.source_value1 = 'HTTPUserAgent'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';

        lc_errr_loc   := 'Getting the Translation for the HTTPCacheControl';
        lc_errr_debug := '';

        SELECT XFTV.target_value1
        INTO   lc_http_cache_ctrl
        FROM   xx_fin_translatevalues XFTV
              ,xx_fin_translatedefinition XFTD
        WHERE  XFTV.translate_id    = XFTD.translate_id
        AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
        AND    XFTV.source_value1 = 'HTTPCacheControl'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';

        lc_errr_loc   := 'Getting the Translation for the HTTPTransferEncoding';
        lc_errr_debug := '';

        SELECT XFTV.target_value1
        INTO   lc_http_trn_encode
        FROM   xx_fin_translatevalues XFTV
              ,xx_fin_translatedefinition XFTD
        WHERE  XFTV.translate_id    = XFTD.translate_id
        AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
        AND    XFTV.source_value1 = 'HTTPTransferEncoding'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';

        lc_errr_loc   := 'Getting the Translation for the HTTPWalletLoc';
        lc_errr_debug := '';

        SELECT XFTV.target_value1
        INTO   lc_wallet_location
        FROM   xx_fin_translatevalues XFTV
              ,xx_fin_translatedefinition XFTD
        WHERE  XFTV.translate_id    = XFTD.translate_id
        AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
        AND    XFTV.source_value1 = 'HTTPWalletLoc'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';

        lc_errr_loc   := 'Getting the Translation for the HTTPWalletPasswd';
        lc_errr_debug := '';

        SELECT XFTV.target_value1
        INTO   lc_wallet_passwd
        FROM   xx_fin_translatevalues XFTV
              ,xx_fin_translatedefinition XFTD
        WHERE  XFTV.translate_id    = XFTD.translate_id
        AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
        AND    XFTV.source_value1 = 'HTTPWalletPasswd'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';

        lc_http_url := lc_http_url||'/file?cmd=ft'||'&'||'name='||p_file_name||'&'||'filter=odsettle';

        BEGIN

            UTL_HTTP.SET_RESPONSE_ERROR_CHECK(enable => TRUE );
            UTL_HTTP.SET_DETAILED_EXCP_SUPPORT(enable => TRUE );

            IF NVL(lc_http_ssl, 'N') = 'Y' THEN
                UTL_HTTP.SET_WALLET(lc_wallet_location,lc_wallet_passwd);
            END IF;

            lh_req := UTL_HTTP.BEGIN_REQUEST(url => lc_http_url, method => 'PUT', http_version => lc_http_version);

            UTL_HTTP.SET_PERSISTENT_CONN_SUPPORT(TRUE);

            UTL_HTTP.SET_HEADER(r => lh_req, name => 'user-agent', value => lc_http_user_agent);

            UTL_HTTP.SET_HEADER(r => lh_req, name => 'Cache-Control', value => lc_http_cache_ctrl);
            UTL_HTTP.SET_HEADER(r => lh_req, name => 'Transfer-Encoding', value => lc_http_trn_encode);

            lf_out_file := UTL_FILE.FOPEN(p_file_path, p_file_name, 'R',ln_chunk_size);
            --lf_in_file := UTL_FILE.FOPEN (p_file_path, p_file_name||'.OUT','w',ln_chunk_size);

            BEGIN

                LOOP

                    lc_data_buffer := NULL;
                    UTL_FILE.GET_LINE(lf_out_file, lc_data_buffer);
				

                    lc_line_type := SUBSTR(SUBSTR(lc_data_buffer,1, INSTR(lc_data_buffer,',',1,1)-1),-4,4);

                    IF (lc_line_type = ' 101') THEN
 
                        lc_pre_cc_data   := SUBSTR(lc_data_buffer,1,INSTR(lc_data_buffer,',',1,12));
                        lc_post_cc_data  := SUBSTR(lc_data_buffer,INSTR(lc_data_buffer,',',1,13));
					
                        lc_encrypt_cc_data := SUBSTR(lc_data_buffer,INSTR(lc_data_buffer,',',1,12)+1,INSTR(lc_data_buffer,',',1,13)-1);

                        lc_errr_loc   := 'Calling the Credit Card Decryption API';

                        xx_od_security_key_pkg.decrypt
                                (X_DECRYPTED_VAL => lc_decrypt_cc_data, 
                                 X_ERROR_MESSAGE => lc_decrypt_error_msg,
                                 P_MODULE => 'AJB',
                                 P_KEY_LABEL => ' ',
                                 P_ALGORITHM => '3DES',
                                 P_ENCRYPTED_VAL => lc_encrypt_cc_data,
                                 P_FORMAT => 'BASE64');

                        lc_data_buffer    := lc_pre_cc_data || lc_decrypt_cc_data ||lc_post_cc_data;
                    
                    END IF;

                    --UTL_FILE.PUT_LINE(lf_in_file, lc_data_buffer);
                    UTL_HTTP.WRITE_LINE(lh_req, lc_data_buffer);

                END LOOP;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    --For the End of the File
                    NULL;

            END;

            UTL_FILE.FCLOSE(lf_out_file);
            --UTL_FILE.FCLOSE(lf_in_file);
            lh_resp := UTL_HTTP.GET_RESPONSE(r => lh_req);

            --x_status_code := lh_resp.status_code;
            --x_reason      := lh_resp.reason_phrase;

            IF lh_resp.status_code <> 204 THEN

                UTL_HTTP.READ_TEXT(r => lh_resp, data => lc_read_http_data, len => NULL);

            END IF;


            IF lh_resp.private_hndl IS NOT NULL THEN

                UTL_HTTP.END_RESPONSE(lh_resp);

            END IF;

            IF lh_req.private_hndl IS NOT NULL THEN

                UTL_HTTP.END_REQUEST(lh_req);

            END IF;

        EXCEPTION WHEN OTHERS THEN
            lp_http_errcode := UTL_HTTP.GET_DETAILED_SQLCODE;
            lc_http_errmesg := UTL_HTTP.GET_DETAILED_SQLERRM;
            x_status_code  := '2';
            x_reason       := 'Error at: '||lc_errr_loc||' Error Message : '||SQLERRM||' '||' HTTPERCD: '||lp_http_errcode||' HTTPERMSG: '||lc_http_errmesg;

        END;

    EXCEPTION
    WHEN OTHERS THEN
            x_status_code  := '2';
            x_reason       := 'Error at: '||lc_errr_loc||' Error Message: '||SQLERRM;

    END TRANSMIT;

END XX_IBY_SECURE_HTTP;
/
SHOW ERR