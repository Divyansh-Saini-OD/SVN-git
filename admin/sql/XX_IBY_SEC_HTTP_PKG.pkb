SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_IBY_SEC_HTTP_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_IBY_SEC_HTTP_PKG
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
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======  ===========  ==================    =======================|
-- |1.0      13-FEB-2007  Gowri Shankar         Initial version        |
-- |1.1      14-FEB-2007  Gowri Shankar         Defect 4606            |
-- |1.2      14-FEB-2007  Gowri Shankar         Defect 5118            |
-- |1.3      27-FEB-2008  Aravind A.            Defect 4870            |
-- |1.4      06-MAR-2008  SubbaRao B            Defect 4870            |
-- |1.4      24-JUL-2009  SubbaRao B            Passing Key Value if CC|
-- |                                           DECRYT not returning NUM|
-- |                                            Defect #1099           |
-- |1.5      09-APR-2010  Aravind A.            PRD Defect 4587        |
-- |1.6      18-SEP-2013  Veronica M           Modified for R12 Upgrade|
-- |                                           Retrofit                |
-- |1.7      14-AUG-2015  Harvinder Rakhra     Decrypting the Tokenized|
--                                             Credit Card Number      |
-- +===================================================================+

-- +===================================================================+
-- | Name        : TRANSFER                                            |
-- | Description : To tranmit the file thru Secure HTTP                |
-- | Parameters  :  p_file_path, p_file_name                           |
-- | Returns     :  x_error_buf, x_ret_code                            |
-- |                                                                   |
-- +===================================================================+

  PROCEDURE TRANSFER    (
                          x_error_buf             OUT VARCHAR2
                         ,x_ret_code              OUT NUMBER
                         ,p_file_path             IN  VARCHAR2
                         ,p_file_name             IN  VARCHAR2
                         )
  IS

    lf_out_file                   UTL_FILE.FILE_TYPE;
    lf_in_file                    UTL_FILE.FILE_TYPE;
    ln_chunk_size                 BINARY_INTEGER  := 32767;
    lc_data_buffer                VARCHAR2(32767) := NULL;
    lh_req                        UTL_HTTP.REQ;
    lh_resp                       UTL_HTTP.RESP;
    lc_line_type                  VARCHAR2(1000);
    lc_pre_cc_data                VARCHAR2(32767) := NULL;
    lc_post_cc_data               VARCHAR2(32767) := NULL;
    lc_encrypt_cc_data            VARCHAR2(1000)  := NULL;
    lc_encrypt_cc_data_non_pos    VARCHAR2(1000)  := NULL;  --Added for the defect 5118
    lc_encrypt_cc_data_pos        VARCHAR2(1000)  := NULL;  --Added for the defect 5118
    lc_decrypt_cc_data            VARCHAR2(1000)  := NULL;
    lc_decrypt_error_msg          VARCHAR2(4000)  := NULL;
    lc_read_http_data             LONG := NULL;
    lc_http_url                   VARCHAR2(4000)  := NULL;
    lc_http_ssl                   VARCHAR2(4000)  := NULL;
    lc_http_version               VARCHAR2(4000)  := NULL;
    lc_http_user_agent            VARCHAR2(4000)  := NULL;
    lc_http_cache_ctrl            VARCHAR2(4000)  := NULL;
    lc_http_trn_encode            VARCHAR2(4000)  := NULL;
    lc_wallet_location            VARCHAR2(4000)  := NULL;
    lc_wallet_passwd              VARCHAR2(4000)  := NULL;

    lc_errr_loc                   VARCHAR2(4000)  := NULL;
    lc_errr_debug                 VARCHAR2(4000)  := NULL;
    lp_http_errcode               PLS_INTEGER;
    lc_http_errmesg               VARCHAR2(4000);
    lc_ajb_file_archival_path     xx_fin_translatevalues.target_value1%TYPE ; --Added for 4606
    ln_conc_request_id            fnd_concurrent_requests.request_id%TYPE;
    lc_source_path_name           all_directories.directory_path%TYPE;
    EX_CC_DECRYPT                 EXCEPTION;
    lc_cc_decrypt_error           VARCHAR2(1) := 'N';
    lc_key_label                  xx_iby_batch_trxns.attribute8%TYPE    DEFAULT NULL;

    --Fixed defect 4870

    TYPE data_buffer_typ IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
    lt_data_buffer                data_buffer_typ;
    lp_tab_count                  PLS_INTEGER;
    lp_count                      PLS_INTEGER;

   BEGIN

      x_ret_code := '0';

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Name :' ||p_file_name);

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Getting the Translation value for HTTPURL');  --Added for the Defect 4606

      lc_errr_loc   := 'Getting the Translation for the HTTPURL';
      lc_errr_debug := '';

      SELECT XFTV.target_value1
      INTO   lc_http_url
      FROM   xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
      WHERE  XFTV.translate_id     = XFTD.translate_id
      AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
      AND    XFTV.source_value1 = 'HTTPURL'
      AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
      AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
      AND    XFTV.enabled_flag = 'Y'
      AND    XFTD.enabled_flag = 'Y';

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Getting the Translation value for HTTPSSLFlag');  --Added for the Defect 4606

      lc_errr_loc   := 'Getting the Translation for the HTTPSSLFlag';
      lc_errr_debug := '';

      SELECT XFTV.target_value1
      INTO   lc_http_ssl
      FROM   xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
      WHERE  XFTV.translate_id     = XFTD.translate_id
      AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
      AND    XFTV.source_value1 = 'HTTPSSLFlag'
      AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
      AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
      AND    XFTV.enabled_flag = 'Y'
      AND    XFTD.enabled_flag = 'Y';

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Getting the Translation value for HTTPVersion');  --Added for the Defect 4606

      lc_errr_loc   := 'Getting the Translation for the HTTPVersion';
      lc_errr_debug := '';

      SELECT XFTV.target_value1
      INTO   lc_http_version
      FROM   xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
      WHERE  XFTV.translate_id     = XFTD.translate_id
      AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
      AND    XFTV.source_value1 = 'HTTPVersion'
      AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
      AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
      AND    XFTV.enabled_flag = 'Y'
      AND    XFTD.enabled_flag = 'Y';

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Getting the Translation value for HTTPUserAgent');  --Added for the Defect 4606

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

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Getting the Translation value for HTTPCacheControl');  --Added for the Defect 4606

      lc_errr_loc   := 'Getting the Translation for the HTTPCacheControl';
      lc_errr_debug := '';

      SELECT XFTV.target_value1
      INTO   lc_http_cache_ctrl
      FROM   xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
      WHERE  XFTV.translate_id     = XFTD.translate_id
      AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
      AND    XFTV.source_value1 = 'HTTPCacheControl'
      AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
      AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
      AND    XFTV.enabled_flag = 'Y'
      AND    XFTD.enabled_flag = 'Y';

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Getting the Translation value for HTTPTransferEncoding');  --Added for the Defect 4606

      lc_errr_loc   := 'Getting the Translation for the HTTPTransferEncoding';
      lc_errr_debug := '';

      SELECT XFTV.target_value1
      INTO   lc_http_trn_encode
      FROM   xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
      WHERE  XFTV.translate_id     = XFTD.translate_id
      AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
      AND    XFTV.source_value1 = 'HTTPTransferEncoding'
      AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
      AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
      AND    XFTV.enabled_flag = 'Y'
      AND    XFTD.enabled_flag = 'Y';

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Getting the Translation value for HTTPWalletLoc');  --Added for the Defect 4606

      lc_errr_loc   := 'Getting the Translation for the HTTPWalletLoc';
      lc_errr_debug := '';

      SELECT XFTV.target_value1
      INTO   lc_wallet_location
      FROM   xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
      WHERE  XFTV.translate_id     = XFTD.translate_id
      AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
      AND    XFTV.source_value1 = 'HTTPWalletLoc'
      AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
      AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
      AND    XFTV.enabled_flag = 'Y'
      AND    XFTD.enabled_flag = 'Y';

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Getting the Translation value for HTTPWalletPasswd');  --Added for the Defect 4606

      lc_errr_loc   := 'Getting the Translation for the HTTPWalletPasswd';
      lc_errr_debug := '';

      SELECT XFTV.target_value1
      INTO   lc_wallet_passwd
      FROM   xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
      WHERE  XFTV.translate_id     = XFTD.translate_id
      AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
      AND    XFTV.source_value1 = 'HTTPWalletPasswd'
      AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
      AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
      AND    XFTV.enabled_flag = 'Y'
      AND    XFTD.enabled_flag = 'Y';

      /*Start of Addition for the Defect 4606, to archive the settlement after the successful transmission to AJB*/

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Getting the Translation value for AJB_SETTLEMENT_ARCHIVE_PATH');  --Added for the Defect 4606

      lc_errr_loc := 'Getting the Translation Value for AJB_SETTLEMENT_ARCHIVE_PATH';
      lc_errr_debug := '';

      SELECT XFTV.target_value1
      INTO   lc_ajb_file_archival_path
      FROM   xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
      WHERE  XFTV.translate_id    = XFTD.translate_id
      AND    XFTD.translation_name = 'FTP_DETAILS_AJB'
      AND    XFTV.source_value1 = 'AJB_SETTLEMENT_ARCHIVE_PATH'
      AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
      AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
      AND    XFTV.enabled_flag = 'Y'
      AND    XFTD.enabled_flag = 'Y';

      /*End of Addition for the Defect 4606, to archive the settlement after the successful transmission to AJB*/

     lc_errr_loc := 'Getting the Physical path of the Source File Path, for the file writing';
     lc_errr_debug := '';

     SELECT AD.directory_path 
     INTO   lc_source_path_name
     FROM   all_directories AD 
     WHERE  AD.directory_name = p_file_path;

     FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Path :' ||lc_source_path_name);

     lc_http_url := lc_http_url||'/file?cmd=ft'||'&'||'name='||p_file_name||'&'||'filter=odsettle';

     FND_FILE.PUT_LINE(FND_FILE.LOG, 'URL Generated: '||lc_http_url);  --Added for the Defect 4606

     FND_FILE.PUT_LINE(FND_FILE.LOG, 'Opening the Data file for Reading');  --Added for the Defect 4606

     lc_errr_loc := 'Opening the Data file for Reading';
     lc_errr_debug := '';

     lf_out_file := UTL_FILE.FOPEN(p_file_path, p_file_name, 'R',ln_chunk_size);
     --lf_in_file := UTL_FILE.FOPEN (p_file_path, p_file_name||'.OUT','w',ln_chunk_size);

     BEGIN

        lt_data_buffer.delete;  --Addded for the Defect 4870
        lp_tab_count := 0;      --Addded for the Defect 4870

        BEGIN

           LOOP

              lc_data_buffer := NULL;

              UTL_FILE.GET_LINE(lf_out_file, lc_data_buffer);

              lc_errr_debug := lc_data_buffer;

              lc_line_type := SUBSTR(SUBSTR(lc_data_buffer,1, INSTR(lc_data_buffer,',',1,1)-1),-4,4);

              IF (lc_line_type = ' 101') THEN

              /*Start of Addition for the Defect 5118*/

                 lc_encrypt_cc_data_non_pos := SUBSTR(lc_data_buffer,INSTR(lc_data_buffer,',',1,12)+1,INSTR(lc_data_buffer,',',1,13)-INSTR(lc_data_buffer,',',1,12)-1);

                 lc_encrypt_cc_data_pos := SUBSTR(lc_data_buffer,INSTR(lc_data_buffer,',',1,14)+1,INSTR(lc_data_buffer,',',1,15)-INSTR(lc_data_buffer,',',1,14)-1);

                 IF (lc_encrypt_cc_data_non_pos IS NOT NULL) THEN

                    lc_encrypt_cc_data := lc_encrypt_cc_data_non_pos;
                    lc_pre_cc_data     := SUBSTR(lc_data_buffer,1,INSTR(lc_data_buffer,',',1,12));
                    lc_post_cc_data    := SUBSTR(lc_data_buffer,INSTR(lc_data_buffer,',',1,13));

                 ELSE

                    lc_encrypt_cc_data := SUBSTR(lc_encrypt_cc_data_pos,1,INSTR(lc_encrypt_cc_data_pos,'=',-1,1)-1);
                    lc_pre_cc_data     := SUBSTR(lc_data_buffer,1,INSTR(lc_data_buffer,',',1,14));
                    lc_post_cc_data    := SUBSTR(lc_encrypt_cc_data_pos,INSTR(lc_encrypt_cc_data_pos,'=',-1,1))||SUBSTR(lc_data_buffer,INSTR(lc_data_buffer,',',1,15));

                 END IF;

                 --Added fr defect 4587
                 lc_key_label := SUBSTR(lc_post_cc_data,INSTR(lc_post_cc_data,',',-1)+1);

              /*End of Addition for the Defect 5118*/
			  
           -- Added by Veronica for R12 upgrade Retrofit START    
	        DBMS_SESSION.set_context(namespace      => 'XX_IBY_TRANS_CONTEXT',
                                     ATTRIBUTE      => 'TYPE',
                                     VALUE          => 'EBS');
           -- Added by Veronica for R12 upgrade Retrofit END   									 

                 lc_errr_loc   := 'Calling the Credit Card Decryption API';

                 XX_OD_SECURITY_KEY_PKG.DECRYPT (
                                                 X_DECRYPTED_VAL => lc_decrypt_cc_data
                                                ,X_ERROR_MESSAGE => lc_decrypt_error_msg
                                                ,P_MODULE        => 'AJB'
                                                --,P_KEY_LABEL     => NULL             --Commented for 4587
                                                ,P_KEY_LABEL     => lc_key_label       --Added for 4587
                                                ,P_ALGORITHM     => '3DES'
                                                ,P_ENCRYPTED_VAL => lc_encrypt_cc_data
                                                ,P_FORMAT        => 'BASE64'
                                                );

                 IF ( (lc_decrypt_error_msg IS NOT NULL) OR (lc_decrypt_cc_data IS NULL)) THEN

                    lc_cc_decrypt_error := 'Y';
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Message: '||lc_decrypt_error_msg);
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Settlement Data: '||lc_data_buffer);

                 END IF;

 /* Commented for defect 4587, this exception is no longer needed
 -- Code fix for the Prod Issue Passing Key Value if CC DECRYT not returning number value
                 BEGIN

                    lc_decrypt_cc_data := TO_NUMBER (lc_decrypt_cc_data);

                 EXCEPTION WHEN VALUE_ERROR THEN

                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Message VALUE_ERROR:'
                                       ||lc_decrypt_error_msg||' - '||SQLERRM);
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Settlement Data: '||lc_data_buffer);

                    XX_OD_SECURITY_KEY_PKG.DECRYPT (
                           X_DECRYPTED_VAL => lc_decrypt_cc_data
                          ,X_ERROR_MESSAGE => lc_decrypt_error_msg
                          ,P_MODULE        => 'AJB'
                          ,P_KEY_LABEL     => 'AJB20090326A'
                          ,P_ALGORITHM     => '3DES'
                          ,P_ENCRYPTED_VAL => lc_encrypt_cc_data
                          ,P_FORMAT        => 'BASE64'
                          );

                   IF ( (lc_decrypt_error_msg IS NOT NULL) OR (lc_decrypt_cc_data IS NULL)) THEN

                      lc_cc_decrypt_error := 'Y';
                      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Message: '||lc_decrypt_error_msg);
                      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Settlement Data: '||lc_data_buffer);

                   END IF;

               END;
 -- Code fix for the Prod Issue Passing Key Value if CC DECRYT not returning number value
 */

                 --Added for 4587, strip off the key label from data to AJB
                 lc_post_cc_data := SUBSTR(lc_post_cc_data,1,INSTR(lc_post_cc_data,',',-1)-1);

                 lc_data_buffer    := lc_pre_cc_data || lc_decrypt_cc_data ||lc_post_cc_data;
				 
                --Version 1.7. Added to add the same decrypted value for Token Number stored in the field ixreserved33
                 lc_data_buffer    := REPLACE (lc_data_buffer, lc_encrypt_cc_data, lc_decrypt_cc_data);

              END IF;

              IF (lc_cc_decrypt_error = 'N') THEN

                 --UTL_FILE.PUT_LINE(lf_in_file, lc_data_buffer);
                 --UTL_HTTP.WRITE_LINE(lh_req, lc_data_buffer);  --Commented for Defect 4870
                 lt_data_buffer(lp_tab_count) := lc_data_buffer; --Added for the defect 4870

                 lp_tab_count := lp_tab_count + 1;  --Added for the defect 4870

              END IF;

            END LOOP;

         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           --For the End of the File
         NULL;

         END;

         lc_errr_debug := NULL;

         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Closing the file after Reading');  --Added for the Defect 4606

         lc_errr_loc := 'Closing the file after Reading';
         lc_errr_debug := '';

         UTL_FILE.FCLOSE(lf_out_file);
       --UTL_FILE.FCLOSE(lf_in_file);

         IF (lc_cc_decrypt_error = 'Y') THEN

            RAISE EX_CC_DECRYPT;

         END IF;

         UTL_HTTP.SET_RESPONSE_ERROR_CHECK(enable => TRUE );
         UTL_HTTP.SET_DETAILED_EXCP_SUPPORT(enable => TRUE );

         IF NVL(lc_http_ssl, 'N') = 'Y' THEN

            lc_errr_loc := 'Setting the Wallet';
            lc_errr_debug := '';

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Setting the Wallet');  --Added for the Defect 4606

            UTL_HTTP.SET_WALLET(
                               lc_wallet_location
                               ,lc_wallet_passwd
                               );

         END IF;

         FND_FILE.PUT_LINE(FND_FILE.LOG, 'HTTP Begin Request');  --Added for the Defect 4606

         lc_errr_loc := 'HTTP Begin Request';
         lc_errr_debug := '';

         lh_req := UTL_HTTP.BEGIN_REQUEST(
                                          url          => lc_http_url
                                         ,method       => 'PUT'
                                         ,http_version => lc_http_version);

         UTL_HTTP.SET_PERSISTENT_CONN_SUPPORT(TRUE);

         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Setting the HTTP Header');  --Added for the Defect 4606

         lc_errr_loc := 'Setting the HTTP Header';
         lc_errr_debug := '';

         UTL_HTTP.SET_HEADER(
                             r     => lh_req
                            ,name  => 'user-agent'
                            ,value => lc_http_user_agent
                             );

         UTL_HTTP.SET_HEADER(
                             r      => lh_req
                            ,name   => 'Cache-Control'
                            ,value => lc_http_cache_ctrl
                            );

         UTL_HTTP.SET_HEADER(
                             r     => lh_req
                            ,name  => 'Transfer-Encoding'
                            ,value => lc_http_trn_encode
                            ); 

          --Start of fix for defect 4870
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'No: of Settlement Records(Including Header and Trailer): '
                                         ||lt_data_buffer.COUNT);

         IF(lt_data_buffer.COUNT > 0) THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Opening the PLSQL table to send the Settlement file thru HTTP');

            FOR lp_count IN lt_data_buffer.FIRST .. lt_data_buffer.LAST

            LOOP

            UTL_HTTP.WRITE_LINE(lh_req, lt_data_buffer(lp_count));

            END LOOP;

         END IF;

         lt_data_buffer.delete;
        --End of fix for defect 4870

         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Getting the Response from the HTTP request');  --Added for the Defect 4606

         lc_errr_loc := 'Getting the Response from the HTTP request';

         lh_resp := UTL_HTTP.GET_RESPONSE(r => lh_req);

         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Response Status Code: '||lh_resp.status_code);  --Added for the Defect 4606

         IF (lh_resp.status_code <> '204') THEN

            UTL_HTTP.READ_TEXT(
                              r    => lh_resp
                             ,data => lc_read_http_data
                             ,len => NULL);

         END IF;

          --Start of the Addition for the Defect 4606, to handle the Response Codes

         IF (lh_resp.status_code = '201') THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,'File has been successfully sent');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Response message: '||lc_read_http_data); 

       --Calling the Common File Copy Program, to move the AJB settlement file to the Archival directory

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Submitting the Program to Arcive the Settlement file');  --Added for the Defect 4606

            lc_errr_loc   := 'Submitting the Program to Arcive the Settlement file';
            lc_errr_debug := '';

            ln_conc_request_id := fnd_request.submit_request (
                                  'XXFIN'
                                 ,'XXCOMFILCOPY'
                                 ,''
                                 ,''
                                 ,FALSE
                                 ,lc_source_path_name||'/'||p_file_name        --Source File Name
                                 ,lc_ajb_file_archival_path||'/'||p_file_name  --Dest File Name
                                 ,''
                                 ,''
                                 ,'Y');                      --Deleting the Source File

            COMMIT;

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Request id of the Common File copy program: '||ln_conc_request_id);  --Added for the Defect 4606

         ELSIF (lh_resp.status_code = '204') THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Failure in File Tranmisission, please check the below Response message');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Response message: No Content'); 
            x_ret_code      := '2';
            x_error_buf     := 'Failure in File Tranmisission';

        ELSE

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Failure in File Tranmisission, please check the below Response message');
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Response message: '||lc_read_http_data);
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Partial File has been transmitted'); 
            x_ret_code      := '2';
            x_error_buf     := 'Failure in File Tranmisission';

        END IF;

          -- End of the Addition for the Defect 4606, to handle the Response Codes

        IF lh_resp.private_hndl IS NOT NULL THEN

           UTL_HTTP.END_RESPONSE(lh_resp);

         END IF;

         IF lh_req.private_hndl IS NOT NULL THEN

            UTL_HTTP.END_REQUEST(lh_req);

         END IF;

      EXCEPTION
      WHEN EX_CC_DECRYPT THEN

        x_ret_code  := '2';
        x_error_buf := 'Failure in the Credit Card Decryption API';
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Message: '||x_error_buf);

       /* IF lh_req.private_hndl IS NOT NULL THEN  -- Commented for the Defect 4870

          UTL_HTTP.END_REQUEST(lh_req);

        END IF;*/

      WHEN OTHERS THEN

        lp_http_errcode := UTL_HTTP.GET_DETAILED_SQLCODE;
        lc_http_errmesg := UTL_HTTP.GET_DETAILED_SQLERRM;

        x_ret_code      := '2';
        x_error_buf     := 'Error at: '||lc_errr_loc||' Error Debug: '||lc_errr_debug||
                           ' Error Message : '||SQLERRM||' '||' HTTPERCD: '||
                           lp_http_errcode||' HTTPERMSG: '||lc_http_errmesg;

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Message: '||x_error_buf);  --Added for the Defect 4606

        IF lh_req.private_hndl IS NOT NULL THEN

           UTL_HTTP.END_REQUEST(lh_req);

        END IF;

      END;

   EXCEPTION
   WHEN OTHERS THEN
      x_ret_code     := '2';
      x_error_buf    := 'Error at: '||lc_errr_loc||' Error Debug: '||lc_errr_debug
                        ||' Error Message: '||SQLERRM;
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Message: '||x_error_buf);  --Added for the Defect 4606

   END TRANSFER;

END XX_IBY_SEC_HTTP_PKG;
/
SHOW ERR