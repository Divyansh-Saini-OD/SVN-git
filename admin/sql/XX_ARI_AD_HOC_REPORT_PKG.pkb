create or replace
PACKAGE BODY XX_ARI_AD_HOC_REPORT_PKG AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- +====================================================================================================+
-- | Name        : XX_AR_EBL_TRANSMISSION_PKG                                                           |
-- | Description : Package body for eBilling transmission / resend via eMail                            |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       05-Feb-2010 Bushrod Thomas     Initial draft version.      			 	                        |
-- |                                                                                                    |
-- +====================================================================================================+
*/

  PROCEDURE PUT_OUT_LINE(p_buffer IN VARCHAR2:=' ')
  IS 
  BEGIN
    IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN   -- if in concurrent program, print to output file
      FND_FILE.put_line(FND_FILE.OUTPUT,NVL(p_buffer,' '));
    ELSE   -- else print to DBMS_OUTPUT
      DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
    END IF;
  END PUT_OUT_LINE;


  PROCEDURE PUT_LOG_LINE(p_buffer IN VARCHAR2:=' ')
  IS
  BEGIN
    IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN   -- if in concurrent program, print to log file
      FND_FILE.put_line(FND_FILE.LOG,NVL(p_buffer,' '));
    ELSE   -- else print to DBMS_OUTPUT
      DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
    END IF;
  END PUT_LOG_LINE;


  PROCEDURE PUT_ERR_LINE (
    p_error_message IN VARCHAR2 := ' '
   ,p_attribute1   IN VARCHAR2 := null
   ,p_attribute2   IN VARCHAR2 := null
   ,p_attribute3   IN VARCHAR2 := null
   ,p_attribute4   IN VARCHAR2 := null
  ) IS
  BEGIN
    XX_COM_ERROR_LOG_PUB.log_error(p_module_name => 'ARI'
                                ,p_program_name  => 'XX_ARI_AD_HOC_REPORT'
                                ,p_attribute1    => p_attribute1
                                ,p_attribute2    => p_attribute2
                                ,p_attribute3    => p_attribute3
                                ,p_attribute4    => p_attribute4
                                ,p_attribute5    => fnd_global.user_name                                
                                ,p_error_message => p_error_message
                                ,p_created_by    => fnd_global.user_id);
  END PUT_ERR_LINE;


  PROCEDURE GET_TRANSLATIONS(
    p_translation_name IN VARCHAR2
   ,p_source_value1    IN VARCHAR2
   ,x_target_value1    IN OUT NOCOPY VARCHAR2
   ,x_target_value2    IN OUT NOCOPY VARCHAR2
   ,x_target_value3    IN OUT NOCOPY VARCHAR2
   ,x_target_value4    IN OUT NOCOPY VARCHAR2
   ,x_target_value5    IN OUT NOCOPY VARCHAR2 
   ,x_target_value6    IN OUT NOCOPY VARCHAR2 
  )
  IS
    ls_target_value7  VARCHAR2(240);
    ls_target_value8  VARCHAR2(240);
    ls_target_value9  VARCHAR2(240);
    ls_target_value10 VARCHAR2(240);
    ls_target_value11 VARCHAR2(240);
    ls_target_value12 VARCHAR2(240);
    ls_target_value13 VARCHAR2(240);
    ls_target_value14 VARCHAR2(240);
    ls_target_value15 VARCHAR2(240);
    ls_target_value16 VARCHAR2(240);
    ls_target_value17 VARCHAR2(240);
    ls_target_value18 VARCHAR2(240);
    ls_target_value19 VARCHAR2(240);
    ls_target_value20 VARCHAR2(240);
    ls_error_message  VARCHAR2(240);
  BEGIN
    xx_fin_translate_pkg.xx_fin_translatevalue_proc(
      p_translation_name => p_translation_name
     ,p_source_value1    => p_source_value1
     ,x_target_value1    => x_target_value1
     ,x_target_value2    => x_target_value2
     ,x_target_value3    => x_target_value3
     ,x_target_value4    => x_target_value4
     ,x_target_value5    => x_target_value5
     ,x_target_value6    => x_target_value6
     ,x_target_value7    => ls_target_value7
     ,x_target_value8    => ls_target_value8
     ,x_target_value9    => ls_target_value9
     ,x_target_value10   => ls_target_value10
     ,x_target_value11   => ls_target_value11
     ,x_target_value12   => ls_target_value12
     ,x_target_value13   => ls_target_value13
     ,x_target_value14   => ls_target_value14
     ,x_target_value15   => ls_target_value15
     ,x_target_value16   => ls_target_value16
     ,x_target_value17   => ls_target_value17
     ,x_target_value18   => ls_target_value18
     ,x_target_value19   => ls_target_value19
     ,x_target_value20   => ls_target_value20
     ,x_error_message    => ls_error_message
    );
  END GET_TRANSLATIONS;


  PROCEDURE RUN_ACC_CLOSE_TO_CRD_LIMIT_RPT(
    p_outstanding_amount_low  IN NUMBER
   ,p_outstanding_amount_high IN NUMBER
   ,p_collector_number_low    IN VARCHAR2
   ,p_collector_number_high   IN VARCHAR2
   ,p_customer_class          IN VARCHAR2
   ,p_recipient_email_list    IN VARCHAR2
   ,x_request_id              OUT NUMBER
  ) IS
    ln_conc_request_id NUMBER := 0;
  BEGIN
    x_request_id := 0;
    ln_conc_request_id := FND_REQUEST.submit_request (
                            application => 'XXFIN'
                           ,program     => 'XX_ARI_RUN_PROGRAM'       -- RUN_PROGRAM procedure below is target of this concurrent program
                           ,argument1   => p_recipient_email_list     -- p_email_list_output
                           ,argument2   => NULL                       -- p_email_list_log
                           ,argument3   => 'XXFIN'                    -- application of program to run
                           ,argument4   => 'XXARCRLIMITADHOC'         -- short concurrent program name for "OD: AR Accounts Close To Credit Limit Report"
                           ,argument5   => NULL                       -- p_template_app
                           ,argument6   => NULL                       -- p_template_code
                           ,argument7   => NULL                       -- p_template_language
                           ,argument8   => NULL                       -- p_template_territory
                           ,argument9   => NULL                       -- p_template_output_format
                           ,argument10  => p_outstanding_amount_low   -- prog arg1
                           ,argument11  => p_outstanding_amount_high  -- prog arg2
                           ,argument12  => p_collector_number_low     -- prog arg3
                           ,argument13  => p_collector_number_high    -- prog arg4
                           ,argument14  => p_customer_class           -- prog arg5
                          );

    IF (ln_conc_request_id > 0) THEN
      COMMIT; -- must commit work so that the concurrent manager polls the request
      x_request_id := ln_conc_request_id;
    ELSE
      DBMS_OUTPUT.PUT_LINE(fnd_message.get);
      RAISE_APPLICATION_ERROR(-20735, 'Unable to submit request. ' || FND_MESSAGE.get);
    END IF;
  END RUN_ACC_CLOSE_TO_CRD_LIMIT_RPT;


  FUNCTION EXTERNALLY_SAFE_URL(p_url VARCHAR2)
  RETURN VARCHAR2
  IS
    sURL VARCHAR2(2000);
  BEGIN
    IF (NOT FND_PROFILE.defined('APPS_CGI_AGENT')) THEN -- external iRec server not accessible inside firewall; need to target internal server
      SELECT SUBSTR(V.profile_option_value, 1,  INSTR(V.profile_option_value, '/', 1, 3)-1) || SUBSTR(p_url, INSTR(p_url, '/', 1, 3))
      INTO sURL
      FROM FND_PROFILE_OPTIONS O JOIN FND_PROFILE_OPTION_VALUES V
        ON O.application_id=V.application_id
       AND O.profile_option_id=V.profile_option_id
       AND O.profile_option_name='APPS_WEB_AGENT'
      WHERE level_id=10001 AND level_value=0 AND rownum=1;
    END IF;

    RETURN sURL;
  END EXTERNALLY_SAFE_URL;



  PROCEDURE SEND_URL_AS_EMAIL_ATTACHMENT (
      p_url                  IN VARCHAR2
     ,p_recipient_email_list IN VARCHAR2
     ,p_program              IN VARCHAR2
     ,p_filename             IN VARCHAR2
  )
  AS
      conn utl_smtp.connection;
      smtp_svr VARCHAR2(240);         --  := 'USCHMSX28.na.odcorp.net';
      from_name VARCHAR2(240);        -- := 'no-reply@officedepot.com';
      v_smtp_server_port PLS_INTEGER; -- := 25;
      subject VARCHAR2(240);          -- := 'Your requested report';
      message VARCHAR2(240);          -- := 'Enjoy your file';
      message_html VARCHAR2(240);     -- := 'Enjoy your file, and visit <a href="http://www.officedepot.com">Office Depot</a>';
      msg VARCHAR2(32767);
      v_reply utl_smtp.reply;
      v_reply_code VARCHAR2(100);
      v_temp VARCHAR2(4000) := '';
      v_name VARCHAR2(4000) := '';
      v_pos NUMBER := 1;
      v_raw RAW(57);
      v_length INTEGER := 0;
      v_buffer_size INTEGER := 57;
      v_offset INTEGER := 1;
      s_send_to_good_addresses VARCHAR2(2000);
      l_http_request         UTL_HTTP.req;
      l_http_response        UTL_HTTP.resp;
  BEGIN
    IF LENGTH(p_url)=0 OR LENGTH(p_recipient_email_list)=0 THEN RETURN; END IF;

    GET_TRANSLATIONS('ARI_ADHOC_REPORT_CONFIG',p_program, smtp_svr, v_smtp_server_port, from_name, subject, message, message_html);
    
    v_reply := UTL_SMTP.open_connection(smtp_svr, v_smtp_server_port, conn);
    v_reply := UTL_SMTP.helo(conn, smtp_svr);
    v_reply := UTL_SMTP.mail(conn, from_name);


    v_temp := REPLACE(REPLACE(p_recipient_email_list,' ',''),',',';');      -- logic to send e-mail to multiple To'd users separated by ';'
    IF (instr(v_temp,';') = 0) OR (instr(v_temp,';') < LENGTH(v_temp)) THEN
      v_temp := v_temp||';';
    END IF;
    v_pos := 1;
    WHILE (instr(v_temp,';',v_pos) > 0) LOOP
      v_name := substr(v_temp, v_pos, instr(substr(v_temp, v_pos),';')-1);
      v_pos := v_pos + instr(substr(v_temp, v_pos),';');
      IF INSTR(v_name,'@')>1 AND INSTR(v_name,'.')>3 THEN
          v_reply := utl_smtp.rcpt(conn, v_name);
          v_reply_code := to_char(v_reply.code);
          IF v_reply.code = 250 THEN
              IF s_send_to_good_addresses IS NULL THEN
                  s_send_to_good_addresses := v_name;
              ELSE
                  s_send_to_good_addresses := s_send_to_good_addresses || ';' || v_name;
              END IF;
          END IF;
      END IF;
    END LOOP;

    IF s_send_to_good_addresses IS NULL THEN
        UTL_SMTP.quit(conn);
        RAISE_APPLICATION_ERROR(-20735, 'Unable to add any recipients; check addresses: "' || p_recipient_email_list || '"  ');
    END IF;


    msg := 'Return-Path: '||from_name|| utl_tcp.CRLF ||
           'Sent: '||TO_CHAR( SYSDATE, 'mm/dd/yyyy hh24:mi:ss' )|| utl_tcp.CRLF ||
           'From: '||from_name|| utl_tcp.CRLF ||
           'Subject: '|| subject || utl_tcp.CRLF ||
           'To: '|| s_send_to_good_addresses || utl_tcp.CRLF ||
           --'Cc: '|| cc_name || utl_tcp.CRLF ||
           'MIME-Version: 1.0'|| utl_tcp.CRLF || -- Use MIME mail standard
           'Content-Type: multipart/mixed; boundary="MIME.Bound"'|| utl_tcp.CRLF || --MIME.Bound really should be a randomly generated string
           utl_tcp.CRLF ||
           '--MIME.Bound' || utl_tcp.CRLF ||
           'Content-Type: multipart/alternative; boundary="MIME.Bound2"'|| utl_tcp.CRLF ||
           utl_tcp.CRLF ||
           '--MIME.Bound2' || utl_tcp.CRLF ||
           'Content-Type: text/plain; '|| utl_tcp.CRLF || 
           'Content-Transfer_Encoding: 7bit'|| utl_tcp.CRLF ||
           utl_tcp.CRLF ||
           message || utl_tcp.CRLF ||
           utl_tcp.CRLF ||
           '--MIME.Bound2' || utl_tcp.CRLF ||
           'Content-Type: text/html;'|| utl_tcp.CRLF || 
           'Content-Transfer_Encoding: 7bit'|| utl_tcp.CRLF ||
           utl_tcp.CRLF ||
           message_html || utl_tcp.CRLF ||
           '--MIME.Bound2--' || utl_tcp.CRLF ||
           utl_tcp.CRLF;


    UTL_SMTP.open_data(conn);
    UTL_SMTP.write_data(conn, msg); 

    UTL_SMTP.write_data( conn, '--MIME.Bound' || utl_tcp.CRLF);
    UTL_SMTP.write_data( conn, 'Content-Type: application/octet-stream; name="' || p_filename || '"' || utl_tcp.CRLF);
--  UTL_SMTP.write_data( conn, 'Content-Type: application/pdf; name="' || curs_rec.filename || '"' || utl_tcp.CRLF);
    UTL_SMTP.write_data( conn, 'Content-Disposition: attachment; filename="' || p_filename || '"' || utl_tcp.CRLF);
    UTL_SMTP.write_data( conn, 'Content-Transfer-Encoding: base64' || utl_tcp.CRLF );
    UTL_SMTP.write_data( conn, utl_tcp.CRLF );

    l_http_request  := UTL_HTTP.begin_request(p_url); -- UTL_HTTP.set_transfer_timeout(300); -- this is in seconds.  default is 60
    l_http_response := UTL_HTTP.get_response(l_http_request);
    BEGIN
      LOOP
        v_buffer_size := 57;
        UTL_HTTP.read_raw(l_http_response, v_raw, v_buffer_size);
        UTL_SMTP.write_raw_data(conn, utl_encode.base64_encode(v_raw));
        UTL_SMTP.write_data(conn, utl_tcp.CRLF);
      END LOOP;
    EXCEPTION
      WHEN UTL_HTTP.end_of_body THEN
        UTL_HTTP.end_response(l_http_response);
    END;
    UTL_SMTP.write_data( conn, utl_tcp.CRLF );

    UTL_SMTP.write_data( conn, '--MIME.Bound--'); -- End MIME mail

    UTL_SMTP.write_data( conn, utl_tcp.crlf );
    UTL_SMTP.close_data( conn ); 
    UTL_SMTP.quit( conn );

    EXCEPTION WHEN OTHERS THEN
      PUT_ERR_LINE('Exception in XX_ARI_AD_HOC_REPORT.send_url_as_email_attachment: ' || SQLERRM,fnd_global.user_id,p_url,p_program,p_recipient_email_list);
      UTL_SMTP.quit(conn);
      UTL_HTTP.end_response(l_http_response);

  END SEND_URL_AS_EMAIL_ATTACHMENT;


  PROCEDURE RUN_PROGRAM (
    x_error_buffer          OUT VARCHAR2
   ,x_return_code           OUT NUMBER
   ,p_email_list_output      IN VARCHAR2
   ,p_email_list_log         IN VARCHAR2
   ,p_application            IN VARCHAR2 := NULL
	 ,p_program                IN VARCHAR2 := NULL
   ,p_template_app           XDO_TEMPLATES_B.application_short_name%TYPE
   ,p_template_code          XDO_TEMPLATES_B.template_code%TYPE
   ,p_template_language      XDO_TEMPLATES_B.default_language%TYPE
   ,p_template_territory     XDO_TEMPLATES_B.default_territory%TYPE
   ,p_template_output_format FND_LOOKUPS.lookup_code%TYPE  -- see FND_LOOKUPS where lookup_type='XDO_OUTPUT_TYPE'
   ,p_argument1              IN VARCHAR2 := CHR(0)
   ,p_argument2              IN VARCHAR2 := CHR(0)
   ,p_argument3              IN VARCHAR2 := CHR(0)
   ,p_argument4              IN VARCHAR2 := CHR(0)
   ,p_argument5              IN VARCHAR2 := CHR(0)
   ,p_argument6              IN VARCHAR2 := CHR(0)
   ,p_argument7              IN VARCHAR2 := CHR(0)
   ,p_argument8              IN VARCHAR2 := CHR(0)
   ,p_argument9              IN VARCHAR2 := CHR(0)
   ,p_argument10             IN VARCHAR2 := CHR(0)
   ,p_argument11             IN VARCHAR2 := CHR(0)
   ,p_argument12             IN VARCHAR2 := CHR(0)
   ,p_argument13             IN VARCHAR2 := CHR(0)
   ,p_argument14             IN VARCHAR2 := CHR(0)
   ,p_argument15             IN VARCHAR2 := CHR(0)
   ,p_argument16             IN VARCHAR2 := CHR(0)
   ,p_argument17             IN VARCHAR2 := CHR(0)
   ,p_argument18             IN VARCHAR2 := CHR(0)
   ,p_argument19             IN VARCHAR2 := CHR(0)
   ,p_argument20             IN VARCHAR2 := CHR(0) -- Can add up to 100, if needed
  )
  AS
    ln_conc_request_id            NUMBER := 0;
    sURL                          VARCHAR2(2000);
    v_phase_desc                  VARCHAR2(80)   := NULL;
    v_status_desc                 VARCHAR2(80)   := NULL;
    v_phase_code                  VARCHAR2(30)   := NULL;
    v_status_code                 VARCHAR2(30)   := NULL;
    v_return_msg                  VARCHAR2(4000) := NULL;
    v_tab                         FND_CONCURRENT.REQUESTS_TAB_TYPE;
    ls_template_app               XDO_TEMPLATES_B.application_short_name%TYPE  := p_template_app;
    ls_template_code              XDO_TEMPLATES_B.template_code%TYPE           := p_template_code;
    ls_template_language          XDO_TEMPLATES_B.default_language%TYPE        := p_template_language;
    ls_template_territory         XDO_TEMPLATES_B.default_territory%TYPE       := p_template_territory;
    ls_template_output_format     FND_LOOKUPS.lookup_code%TYPE                 := p_template_output_format;
    ls_template_def_app           XDO_TEMPLATES_B.application_short_name%TYPE;
    ls_template_def_code          XDO_TEMPLATES_B.template_code%TYPE;
    ls_template_def_language      XDO_TEMPLATES_B.default_language%TYPE;
    ls_template_def_territory     XDO_TEMPLATES_B.default_territory%TYPE;
    ls_template_def_output_format FND_LOOKUPS.lookup_code%TYPE                 := 'PDF'; -- see FND_LOOKUPS where lookup_type='XDO_OUTPUT_TYPE'
    ld_sysdate                    DATE := TRUNC(SYSDATE);
    b_success                     BOOLEAN := NULL;
  BEGIN
    IF ls_template_app      IS NULL OR ls_template_code      IS NULL OR
       ls_template_language IS NULL OR ls_template_territory IS NULL
    THEN BEGIN
        SELECT application_short_name,template_code       ,default_language        ,default_territory
          INTO ls_template_def_app   ,ls_template_def_code,ls_template_def_language,ls_template_def_territory
          FROM XDO_TEMPLATES_VL
         WHERE ds_app_short_name = p_application  -- 'XXFIN'
           AND data_source_code  = p_program      -- 'XXAPINVINTAUDIT'
           AND template_status   = 'E'            -- enabled (see FND_LOOKUPS WHERE lookup_type ='XDO_DATA_SOURCE_STATUS')
           AND ld_sysdate BETWEEN start_date AND NVL(end_date,ld_sysdate)
           AND ROWNUM=1; -- Oracle SRS Form FNDRSRUN just defaults the first one using this query, if there are multiple

         ls_template_app           := NVL(ls_template_app          ,ls_template_def_app);
         ls_template_code          := NVL(ls_template_code         ,ls_template_def_code);
         ls_template_language      := NVL(ls_template_language     ,ls_template_def_language);
         ls_template_territory     := NVL(ls_template_territory    ,ls_template_def_territory);
         ls_template_output_format := NVL(ls_template_output_format,ls_template_def_output_format);
       EXCEPTION WHEN NO_DATA_FOUND THEN
         NULL; -- no problem if template layout is not needed
      END;
    END IF;

    IF ls_template_app       IS NOT NULL AND ls_template_code          IS NOT NULL AND ls_template_language IS NOT NULL AND
       ls_template_territory IS NOT NULL AND ls_template_output_format IS NOT NULL
    THEN
        IF ls_template_territory = '00' OR ls_template_language = '00' THEN
            SELECT DECODE(ls_template_language ,'00',LOWER(iso_language),ls_template_language)
                  ,DECODE(ls_template_territory,'00',      iso_territory,ls_template_territory)
              INTO ls_template_language, ls_template_territory
              FROM fnd_languages_vl
             WHERE language_code = FND_GLOBAL.CURRENT_LANGUAGE;
        END IF;

        b_success := FND_REQUEST.add_layout( template_appl_name   => ls_template_app           -- 'XXFIN'
                                            ,template_code        => ls_template_code          -- 'XXAPINVINTAUDIT'
                                            ,template_language    => ls_template_language      -- 'en'
                                            ,template_territory   => ls_template_territory     -- 'US'
                                            ,output_format        => ls_template_output_format -- 'PDF'
                                           );
    END IF;


    ln_conc_request_id := FND_REQUEST.submit_request (
                            application => p_application
                           ,program     => p_program
                           ,argument1   => p_argument1
                           ,argument2   => p_argument2
                           ,argument3   => p_argument3
                           ,argument4   => p_argument4
                           ,argument5   => p_argument5
                           ,argument6   => p_argument6
                           ,argument7   => p_argument7
                           ,argument8   => p_argument8
                           ,argument9   => p_argument9
                           ,argument10  => p_argument10
                           ,argument11  => p_argument11
                           ,argument12  => p_argument12
                           ,argument13  => p_argument13
                           ,argument14  => p_argument14
                           ,argument15  => p_argument15
                           ,argument16  => p_argument16
                           ,argument17  => p_argument17
                           ,argument18  => p_argument18
                           ,argument19  => p_argument19
                           ,argument20  => p_argument20                          
                          );

    IF (ln_conc_request_id > 0) THEN
      COMMIT; -- must commit work so that the concurrent manager polls the request
    ELSE
      FND_MESSAGE.raise_error;
    END IF;

    IF NOT FND_CONCURRENT.wait_for_request
      ( request_id    => ln_conc_request_id,
        interval      => 60,                      -- check every 60 secs
        max_wait      => 60*120,                  -- check for max of 2 hours
        phase         => v_phase_desc,
        status        => v_status_desc,
        dev_phase     => v_phase_code,
        dev_status    => v_status_code,
        message       => v_return_msg
      )
    THEN
      RAISE_APPLICATION_ERROR( -20200, v_return_msg );
    END IF;

    IF (v_status_code <> 'NORMAL') THEN
      RAISE_APPLICATION_ERROR( -20201, 'Concurrent Request completed, but had errors or warnings.' );
    ELSE
      IF p_email_list_output IS NOT NULL THEN
          SEND_URL_AS_EMAIL_ATTACHMENT(
            p_url                  => EXTERNALLY_SAFE_URL(FND_WEBFILE.GET_URL(FND_WEBFILE.REQUEST_OUT, ln_conc_request_id, null, null, 10, null, null, null, null))
           ,p_recipient_email_list => p_email_list_output
           ,p_program              => p_program
           ,p_filename             => p_program || '.' || lower(ls_template_output_format));
      END IF;

      IF p_email_list_log IS NOT NULL THEN
          SEND_URL_AS_EMAIL_ATTACHMENT(
            p_url                  => EXTERNALLY_SAFE_URL(FND_WEBFILE.GET_URL(FND_WEBFILE.REQUEST_LOG, ln_conc_request_id, null, null, 10, null, null, null, null))
           ,p_recipient_email_list => p_email_list_log
           ,p_program              => p_program
           ,p_filename             => p_program || '_log.txt');
      END IF;
    END IF;

  END RUN_PROGRAM;
  
END XX_ARI_AD_HOC_REPORT_PKG;

/