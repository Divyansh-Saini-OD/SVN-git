SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
SET SCAN OFF

PROMPT Creating Package Body XX_AR_EBL_TRANSMISSION_PKG

PROMPT Program exits if the creation is not successful
REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile:~PROD:~PATH:~FILE

WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;


create or replace 
PACKAGE BODY XX_AR_EBL_TRANSMISSION_PKG AS

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
-- |1.0       05-Feb-2010 Bushrod Thomas     Initial draft version.      	                            |
-- |1.1       06-Jan-2010 Nilanjana Shome    Modified for the defect 9474	                            |
-- |1.2       19-Mar-2018 Thilak CG          Added for the defect 44331 	                            |
-- |1.3       23-May-2018 Thilak CG          Added for the defect NAIT-27146                            |
-- |2.0       22-Apr-2019 Aarthi             Modified for NAIT-91483. Merging the PDF outputs for       |
-- |                                         BC Customers with Paydoc as Consolidated PDF Billing Docs. |
-- |                                         Added procedures TRANSMIT_BC_MERGE_PDF and                 |
-- |                                         TRANSMIT_MERGE_PDF_EMAIL                                   | 
-- |2.1       24-Apr-2019 Visu               Modified for NAIT-91484.                                   |
-- |                                         Bill Complete Batch Email(Add all the pdf bills            |
-- |                                         as attachments in one email)                               |
-- |                                         Modified procedure TRANSMIT_EMAIL_C                        |
-- |2.2       05-Aug-2019 Aarthi             Modified for prod defect NAIT-101938, merge file not       |
-- |                                         generated when there are more than 80 files to merge       |                               
-- +====================================================================================================+
*/

-- ===========================================================================
-- procedure for printing to the output
-- ===========================================================================
PROCEDURE put_out_line
( p_buffer     IN      VARCHAR2      DEFAULT ' ' )
IS
BEGIN
  -- if in concurrent program, print to output file
  IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
    FND_FILE.put_line(FND_FILE.OUTPUT,NVL(p_buffer,' '));
  -- else print to DBMS_OUTPUT
  ELSE
    DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
  END IF;
END put_out_line;


-- ===========================================================================
-- procedure for printing to the log
-- ===========================================================================
PROCEDURE put_log_line
( p_buffer     IN      VARCHAR2      DEFAULT ' ' )
IS
BEGIN
  -- if in concurrent program, print to log file
  IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
    FND_FILE.put_line(FND_FILE.LOG,NVL(p_buffer,' '));
  -- else print to DBMS_OUTPUT
  ELSE
    DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
  END IF;
END put_log_line;

-- ===========================================================================
-- procedure for logging errors
-- ===========================================================================
PROCEDURE PUT_ERR_LINE (
  p_error_message IN VARCHAR2 := ' '
 ,p_attribute1   IN VARCHAR2 := null
 ,p_attribute2   IN VARCHAR2 := null
 ,p_attribute3   IN VARCHAR2 := null
) IS
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error(p_module_name   => 'ARI'
                                ,p_program_name  => 'XX_AR_EBL_TRANSMISSION_PKG'
                                ,p_attribute1    => p_attribute1
                                ,p_attribute2    => p_attribute2
                                ,p_attribute3    => p_attribute3
                                ,p_attribute4    => fnd_global.user_name
                                ,p_error_message => p_error_message
                                ,p_created_by    => fnd_global.user_id);
END PUT_ERR_LINE;


-- ===========================================================================
-- function to return token-bound message text from fnd_new_messages
-- ===========================================================================
FUNCTION GET_MESSAGE (
   p_message_name   IN VARCHAR2
  ,p_token1_name    IN VARCHAR2 := NULL
  ,p_token1_value   IN VARCHAR2 := NULL
  ,p_token2_name    IN VARCHAR2 := NULL
  ,p_token2_value   IN VARCHAR2 := NULL
  ,p_token3_name    IN VARCHAR2 := NULL
  ,p_token3_value   IN VARCHAR2 := NULL
  ,p_token4_name    IN VARCHAR2 := NULL
  ,p_token4_value   IN VARCHAR2 := NULL

) RETURN VARCHAR2
IS
BEGIN
  FND_MESSAGE.CLEAR;
  FND_MESSAGE.SET_NAME('XXFIN','AR_EBL_' || p_message_name);
  IF p_token1_name IS NOT NULL THEN
    FND_MESSAGE.SET_TOKEN(p_token1_name,p_token1_value);
  END IF;
  IF p_token2_name IS NOT NULL THEN
    FND_MESSAGE.SET_TOKEN(p_token2_name,p_token2_value);
  END IF;
  IF p_token3_name IS NOT NULL THEN
    FND_MESSAGE.SET_TOKEN(p_token3_name,p_token3_value);
  END IF;
  IF p_token4_name IS NOT NULL THEN
    FND_MESSAGE.SET_TOKEN(p_token4_name,p_token4_value);
  END IF;
  RETURN FND_MESSAGE.GET();
END;

-- ===========================================================================
-- generic function that is used to separate a delimited string into an
--   array of string values
-- ===========================================================================
FUNCTION explode
( p_string         IN   VARCHAR2   ,
  p_delimiter      IN   VARCHAR2   DEFAULT ',' )
RETURN STRINGARRAY
IS
  n_index          NUMBER             DEFAULT 0;
  n_pos            NUMBER             DEFAULT 0;
  n_hold_pos       NUMBER             DEFAULT 1;

  a_return_tab     STRINGARRAY   DEFAULT STRINGARRAY();
BEGIN
  LOOP
    n_pos := INSTR(p_string,p_delimiter,n_hold_pos);

    IF n_pos > 0 THEN
      a_return_tab.EXTEND;
      n_index := n_index + 1;
      a_return_tab(n_index) := LTRIM(SUBSTR(p_string,n_hold_pos,n_pos-n_hold_pos));

    ELSE
      a_return_tab.EXTEND;
      n_index := n_index + 1;
      a_return_tab(n_index) := LTRIM(SUBSTR(p_string,n_hold_pos));
      EXIT;

    END IF;

    n_hold_pos := n_pos+1;
  END LOOP;

  RETURN a_return_tab;

END explode;


PROCEDURE get_translations(
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
END;


PROCEDURE get_translations(
  p_translation_name IN VARCHAR2
 ,p_source_value1    IN VARCHAR2
 ,x_target_value1    IN OUT NOCOPY VARCHAR2
 ,x_target_value2    IN OUT NOCOPY VARCHAR2
 ,x_target_value3    IN OUT NOCOPY VARCHAR2
 ,x_target_value4    IN OUT NOCOPY VARCHAR2
 ,x_target_value5    IN OUT NOCOPY VARCHAR2
 ,x_target_value6    IN OUT NOCOPY VARCHAR2
 ,x_target_value7    IN OUT NOCOPY VARCHAR2
 ,x_target_value8    IN OUT NOCOPY VARCHAR2
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
   ,x_target_value7    => x_target_value7
   ,x_target_value8    => x_target_value8
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
END;

PROCEDURE get_translation(
  p_translation_name IN VARCHAR2
 ,p_source_value1    IN VARCHAR2
 ,p_source_value2    IN VARCHAR2
 ,x_target_value1    IN OUT NOCOPY VARCHAR2
)
IS
  ls_target_value1  VARCHAR2(240);
  ls_target_value2  VARCHAR2(240);
  ls_target_value3  VARCHAR2(240);
  ls_target_value4  VARCHAR2(240);
  ls_target_value5  VARCHAR2(240);
  ls_target_value6  VARCHAR2(240);
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
   ,p_source_value2    => p_source_value2
   ,x_target_value1    => x_target_value1
   ,x_target_value2    => ls_target_value2
   ,x_target_value3    => ls_target_value3
   ,x_target_value4    => ls_target_value4
   ,x_target_value5    => ls_target_value5
   ,x_target_value6    => ls_target_value6
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
END;

PROCEDURE get_logo_details(
  p_logo_name IN VARCHAR2
 ,x_logo_url         IN OUT NOCOPY VARCHAR2
 ,x_hyperlink        IN OUT NOCOPY VARCHAR2
 ,x_alt              IN OUT NOCOPY VARCHAR2
)
IS
  ls_target_value4  VARCHAR2(240);
  ls_target_value5  VARCHAR2(240);
  ls_target_value6  VARCHAR2(240);
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
    p_translation_name => 'AR_EBL_LOGOS'
   ,p_source_value1    => p_logo_name
   ,x_target_value1    => x_logo_url
   ,x_target_value2    => x_hyperlink
   ,x_target_value3    => x_alt
   ,x_target_value4    => ls_target_value4
   ,x_target_value5    => ls_target_value5
   ,x_target_value6    => ls_target_value6
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
END;


-- ===========================================================================
-- resend procedure to email specified recipients with attachments
-- ===========================================================================
PROCEDURE SEND_ONE_EMAIL (
    p_file_id_list              IN VARCHAR2,
    p_email_address_list        IN VARCHAR2,
    p_rename_zip_ext_flag       IN VARCHAR2,
    x_error                    OUT VARCHAR2
) IS
  conn utl_smtp.connection;
  smtp_svr VARCHAR2(240); -- := 'USCHMSX28.na.odcorp.net';
  from_name VARCHAR2(240);-- := 'no-reply@officedepot.com';
  v_smtp_server_port PLS_INTEGER; -- := 25;
  subject VARCHAR2(240); --  := 'Your requested statements';
  subject_ext VARCHAR2(240);
  message VARCHAR2(240); -- := 'Thank you for choosing Office Depot to take care of your business!';
  message_html VARCHAR2(1000); -- := '<html><head><title>Requested Statements from Office Depot</title></head><body><img src=http://static.www.odcdn.com/images/us/od/brand.gif><br><br><br>The statements you requested are attached.<br><br>Thank you for choosing <b>Office Depot</b> to take care of your business!</body></html>';
  message_html_ext VARCHAR2(240);
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
  a_file_id_array          STRINGARRAY   DEFAULT STRINGARRAY();
  file_id_in NUMBER;
  v_aops_customer_number XX_AR_EBL_FILE.aops_customer_number%TYPE;

  CURSOR attachment(p_file_id NUMBER) IS
    SELECT CASE p_rename_zip_ext_flag WHEN 'Y' THEN REPLACE(REPLACE(file_name,'.zip','_zip'),'.ZIP','_ZIP') ELSE file_name END filename, file_data filedata
    FROM XX_AR_EBL_FILE WHERE file_id=p_file_id AND file_data IS NOT NULL
    UNION ALL
    SELECT CASE p_rename_zip_ext_flag WHEN 'Y' THEN REPLACE(REPLACE(file_name,'.zip','_zip'),'.ZIP','_ZIP') ELSE file_name END filename, file_data filedata
    FROM XX_AR_EBL_FILE_GT WHERE file_id=p_file_id AND file_data IS NOT NULL;

BEGIN
  x_error := '';
  a_file_id_array := explode(p_file_id_list, ',');
  IF (a_file_id_array.COUNT<=0) THEN
    x_error:='No files listed';
    RETURN;
  END IF;

  get_translations('AR_EBL_EMAIL_CONFIG','RESEND',smtp_svr, v_smtp_server_port, from_name, subject, message, message_html,message_html_ext, subject_ext );

	SELECT aops_customer_number INTO v_aops_customer_number
		FROM XX_AR_EBL_FILE
	WHERE file_id IN ( SELECT /*+ CARDINALITY (A,1) */ *
					FROM TABLE(cast (a_file_id_array  AS STRINGARRAY) ) A ) AND aops_customer_number IS NOT NULL AND rownum=1;


  IF v_aops_customer_number IS NOT NULL THEN

      subject := REPLACE(subject,'&AOPSNUMBER',v_aops_customer_number);

  ELSE

	subject := subject_ext;

  END IF;

   message_html := message_html||message_html_ext;

  v_reply := utl_smtp.open_connection( smtp_svr, v_smtp_server_port, conn );
  v_reply := utl_smtp.helo( conn, smtp_svr );
  v_reply := utl_smtp.mail( conn, from_name );

  -- logic to send e-mail to multiple To'd users separated by ';'
  v_temp := REPLACE(REPLACE(p_email_address_list,' ',''),',',';');
  IF (instr(v_temp,';') = 0) OR (instr(v_temp,';') < LENGTH(v_temp)) THEN
    v_temp := v_temp||';';
  END IF;
  v_pos := 1;
  WHILE (instr(v_temp,';',v_pos) > 0) LOOP
    v_name := substr(v_temp, v_pos, instr(substr(v_temp, v_pos),';')-1);
    v_pos := v_pos + instr(substr(v_temp, v_pos),';');
    v_reply := utl_smtp.rcpt(conn, v_name);
  END LOOP;

/*
  -- logic to send e-mail to Cc'd users separated by ';'
  v_temp := REPLACE(REPLACE(cc_name,' ',''),',',';');
  IF (instr(v_temp,';') = 0) OR (instr(v_temp,';') < LENGTH(v_temp)) THEN
    v_temp := v_temp||';';
  END IF;
  v_pos := 1;
  WHILE (instr(v_temp,';',v_pos) > 0) LOOP
    v_name := substr(v_temp, v_pos, instr(substr(v_temp, v_pos),';')-1);
    v_pos := v_pos + instr(substr(v_temp, v_pos),';');
    v_reply := utl_smtp.rcpt(conn, v_name);
  END LOOP;
*/

  v_reply_code := to_char(v_reply.code);
  IF v_reply.code <> 250 THEN
    utl_smtp.quit( conn );
    RETURN;
  END IF;

  msg := 'Return-Path: '||from_name|| utl_tcp.CRLF ||
         'Date: '||TO_CHAR( SYSDATE, 'mm/dd/yyyy hh24:mi:ss' )|| utl_tcp.CRLF ||
         'From: '||from_name|| utl_tcp.CRLF ||
         'Subject: '|| subject || utl_tcp.CRLF ||
         'To: '|| REPLACE(REPLACE(p_email_address_list,' ',''),',',';') || utl_tcp.CRLF ||
--         'Cc: '|| cc_name || utl_tcp.CRLF ||
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

  utl_smtp.open_data(conn);
  utl_smtp.write_data( conn, msg );

  FOR i_index IN a_file_id_array.FIRST..a_file_id_array.LAST LOOP
    file_id_in := TO_NUMBER(a_file_id_array(i_index));

    IF file_id_in>0 THEN
      FETCH_ARCHIVED_BLOB_INTO_GT(file_id_in);
    END IF;

    FOR curs_rec IN attachment(file_id_in) LOOP BEGIN

      utl_smtp.write_data( conn, '--MIME.Bound' || utl_tcp.CRLF);
      utl_smtp.write_data( conn, 'Content-Type: application/octet-stream; name="' || curs_rec.filename || '"' || utl_tcp.CRLF);
--    utl_smtp.write_data( conn, 'Content-Type: application/pdf; name="' || curs_rec.filename || '"' || utl_tcp.CRLF);
      utl_smtp.write_data( conn, 'Content-Disposition: attachment; filename="' || curs_rec.filename || '"' || utl_tcp.CRLF);
      utl_smtp.write_data( conn, 'Content-Transfer-Encoding: base64' || utl_tcp.CRLF );
      utl_smtp.write_data( conn, utl_tcp.CRLF );

      v_length := dbms_lob.getlength(curs_rec.filedata);

      --reset the offset
      v_offset := 1;
      v_buffer_size := 57; -- this is set to actual amt read by dbms_lob.read, so must reset from value of last attachment's partial read at end of blob.
      WHILE v_offset <= v_length LOOP
        dbms_lob.read( curs_rec.filedata, v_buffer_size, v_offset, v_raw );
        utl_smtp.write_raw_data( conn, utl_encode.base64_encode(v_raw) );
        utl_smtp.write_data( conn, utl_tcp.CRLF );
        v_offset := v_offset + v_buffer_size;
      END LOOP;
      utl_smtp.write_data( conn, utl_tcp.CRLF );

      EXCEPTION
        WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
          utl_smtp.quit( conn );
          x_error := 'UTL_SMTP Error';
          RAISE;
        WHEN OTHERS THEN
          utl_smtp.quit( conn );
          x_error := 'Other Error';
          RAISE;
      END;
    END LOOP;
  END LOOP;

  utl_smtp.write_data( conn, '--MIME.Bound--'); -- End MIME mail

  utl_smtp.write_data( conn, utl_tcp.crlf );
  utl_smtp.close_data( conn );
  utl_smtp.quit( conn );

END SEND_ONE_EMAIL;


-- This is used to send an email with no attachment, such as for CD nofication
PROCEDURE SEND_SIMPLE_EMAIL (
   p_smtp_svr  IN VARCHAR2
  ,p_smtp_port IN PLS_INTEGER
  ,p_send_from IN VARCHAR2
  ,p_send_to   IN VARCHAR2
  ,p_subject   IN VARCHAR2
  ,p_message   IN VARCHAR2
) IS
  conn utl_smtp.connection;
  v_reply utl_smtp.reply;
  v_reply_code VARCHAR2(100);
  v_temp VARCHAR2(4000) := '';
  v_name VARCHAR2(4000) := '';
  v_pos NUMBER := 1;
BEGIN

  v_reply := utl_smtp.open_connection( p_smtp_svr, p_smtp_port, conn );
  v_reply := utl_smtp.helo( conn, p_smtp_svr );
  v_reply := utl_smtp.mail( conn, p_send_from );

  -- logic to send e-mail to multiple To'd users separated by ';'
  v_temp := REPLACE(REPLACE(p_send_to,' ',''),',',';');
  IF (instr(v_temp,';') = 0) OR (instr(v_temp,';') < LENGTH(v_temp)) THEN
    v_temp := v_temp||';';
  END IF;
  v_pos := 1;
  WHILE (instr(v_temp,';',v_pos) > 0) LOOP
    v_name := substr(v_temp, v_pos, instr(substr(v_temp, v_pos),';')-1);
    v_pos := v_pos + instr(substr(v_temp, v_pos),';');
    v_reply := utl_smtp.rcpt(conn, v_name);
  END LOOP;

/*
  -- logic to send e-mail to Cc'd users separated by ';'
  v_temp := REPLACE(REPLACE(p_cc_list,' ',''),',',';');
  IF (instr(v_temp,';') = 0) OR (instr(v_temp,';') < LENGTH(v_temp)) THEN
    v_temp := v_temp||';';
  END IF;
  v_pos := 1;
  WHILE (instr(v_temp,';',v_pos) > 0) LOOP
    v_name := substr(v_temp, v_pos, instr(substr(v_temp, v_pos),';')-1);
    v_pos := v_pos + instr(substr(v_temp, v_pos),';');
    v_reply := utl_smtp.rcpt(conn, v_name);
  END LOOP;
*/

  v_reply_code := to_char(v_reply.code);
  IF v_reply.code <> 250 THEN
    utl_smtp.quit( conn );
    RAISE_APPLICATION_ERROR(-20734, 'SMTP reply code: ' || v_reply.code);
  END IF;

  utl_smtp.open_data(conn);
  utl_smtp.write_data( conn, 'Return-Path: '|| p_send_from || utl_tcp.CRLF || 'Date: '||TO_CHAR( SYSDATE, 'mm/dd/yyyy hh24:mi:ss' )|| utl_tcp.CRLF ||
                             'From: '|| p_send_from || utl_tcp.CRLF || 'Subject: '|| p_subject || utl_tcp.CRLF ||
                             'To: '|| REPLACE(REPLACE(p_send_to,' ',''),',',';') || utl_tcp.CRLF ||
--                             'Cc: '|| p_cc_list || utl_tcp.CRLF ||
                             'MIME-Version: 1.0'|| utl_tcp.CRLF || 'Content-Type: text/plain; '|| utl_tcp.CRLF ||
                             'Content-Transfer_Encoding: 7bit'|| utl_tcp.CRLF || utl_tcp.CRLF || p_message || utl_tcp.CRLF || utl_tcp.CRLF );
  utl_smtp.close_data( conn );
  utl_smtp.quit( conn );

END SEND_SIMPLE_EMAIL;



-- This is used to send an email with no attachment, but multipart/alternative for both text and html messages (e.g., for FTP notifications)
PROCEDURE SEND_MULTI_ALT_EMAIL (
   p_smtp_svr      IN VARCHAR2
  ,p_smtp_port     IN PLS_INTEGER
  ,p_send_from     IN VARCHAR2
  ,p_send_to       IN VARCHAR2
  ,p_cc_list       IN VARCHAR2
  ,p_subject       IN VARCHAR2
  ,p_message_text  IN VARCHAR2
  ,p_message_html  IN VARCHAR2
  ,x_status_detail IN OUT VARCHAR2
) IS
  conn utl_smtp.connection;
  v_reply utl_smtp.reply;
  v_reply_code VARCHAR2(100);
  v_temp VARCHAR2(4000) := '';
  v_name VARCHAR2(4000) := '';
  v_pos NUMBER := 1;
  s_send_to_good_addresses VARCHAR2(2000) := null;
  s_send_cc_to_good_addresses VARCHAR2(2000) := null;
  s_bad_list VARCHAR2(2000) := null;
BEGIN

  v_reply := utl_smtp.open_connection( p_smtp_svr, p_smtp_port, conn );
  v_reply := utl_smtp.helo( conn, p_smtp_svr );
  v_reply := utl_smtp.mail( conn, p_send_from );

  -- logic to send e-mail to multiple To'd users separated by ';'
  v_temp := REPLACE(REPLACE(p_send_to,' ',''),',',';');
  IF (instr(v_temp,';') = 0) OR (instr(v_temp,';') < LENGTH(v_temp)) THEN
    v_temp := v_temp||';';
  END IF;
  v_pos := 1;
  WHILE (instr(v_temp,';',v_pos) > 0) LOOP
    v_name := substr(v_temp, v_pos, instr(substr(v_temp, v_pos),';')-1);
    v_pos := v_pos + instr(substr(v_temp, v_pos),';');
    IF INSTR(v_name,'@')<2 OR INSTR(v_name,'.')<4 THEN
        IF s_bad_list IS NULL THEN
            s_bad_list := v_name;
        ELSE
            s_bad_list := s_bad_list || ';' || v_name;
        END IF;
    ELSE
        v_reply := utl_smtp.rcpt(conn, v_name);

        v_reply_code := to_char(v_reply.code);
        IF v_reply.code = 250 THEN
            IF s_send_to_good_addresses IS NULL THEN
                s_send_to_good_addresses := v_name;
            ELSE
                s_send_to_good_addresses := s_send_to_good_addresses || ';' || v_name;
            END IF;
        ELSE
            IF s_bad_list IS NULL THEN
                s_bad_list := v_name;
            ELSE
                s_bad_list := s_bad_list || ';' || v_name;
            END IF;
            s_bad_list := s_bad_list || '(' || v_reply.code || ')';
        END IF;
    END IF;
  END LOOP;


  -- logic to send e-mail to Cc'd users separated by ';'
  v_temp := REPLACE(REPLACE(p_cc_list,' ',''),',',';');
  IF (instr(v_temp,';') = 0) OR (instr(v_temp,';') < LENGTH(v_temp)) THEN
    v_temp := v_temp||';';
  END IF;
  v_pos := 1;
  WHILE (instr(v_temp,';',v_pos) > 0) LOOP
    v_name := substr(v_temp, v_pos, instr(substr(v_temp, v_pos),';')-1);
    v_pos := v_pos + instr(substr(v_temp, v_pos),';');
    IF INSTR(v_name,'@')<2 OR INSTR(v_name,'.')<4 THEN
        IF s_bad_list IS NULL THEN
            s_bad_list := v_name;
        ELSE
            s_bad_list := s_bad_list || ';' || v_name;
        END IF;
    ELSE
        v_reply := utl_smtp.rcpt(conn, v_name);

        v_reply_code := to_char(v_reply.code);
        IF v_reply.code = 250 THEN
            IF s_send_cc_to_good_addresses IS NULL THEN
                s_send_cc_to_good_addresses := v_name;
            ELSE
                s_send_cc_to_good_addresses := s_send_cc_to_good_addresses || ';' || v_name;
            END IF;
        ELSE
            IF s_bad_list IS NULL THEN
                s_bad_list := v_name;
            ELSE
                s_bad_list := s_bad_list || ';' || v_name;
            END IF;
            s_bad_list := s_bad_list || '(' || v_reply.code || ')';
        END IF;
    END IF;
  END LOOP;


  x_status_detail := s_send_to_good_addresses;
  IF x_status_detail IS NOT NULL AND s_send_cc_to_good_addresses IS NOT NULL THEN
      x_status_detail := x_status_detail || ';';
  END IF;
  x_status_detail := x_status_detail || s_send_cc_to_good_addresses;

  IF s_bad_list IS NOT NULL THEN
      IF x_status_detail IS NOT NULL THEN
          x_status_detail := x_status_detail || ';';
      END IF;
      x_status_detail := x_status_detail || 'BAD:' || s_bad_list;
  END IF;

  IF s_send_to_good_addresses IS NULL AND s_send_cc_to_good_addresses IS NULL THEN
      utl_smtp.quit(conn);
      RETURN;
  END IF;


  utl_smtp.open_data(conn);
  utl_smtp.write_data( conn, 'Return-Path: '|| p_send_from || utl_tcp.CRLF || 'Date: '||TO_CHAR( SYSDATE, 'mm/dd/yyyy hh24:mi:ss' )|| utl_tcp.CRLF ||
                             'From: '|| p_send_from || utl_tcp.CRLF || 'Subject: '|| p_subject || utl_tcp.CRLF ||
                             'To: '|| REPLACE(REPLACE(s_send_to_good_addresses,' ',''),',',';') || utl_tcp.CRLF ||
                             'Cc: '|| s_send_cc_to_good_addresses || utl_tcp.CRLF ||
                             'MIME-Version: 1.0'|| utl_tcp.CRLF || 'Content-Type: multipart/alternative; boundary="MIME.Bound"'|| utl_tcp.CRLF || utl_tcp.CRLF ||
                             '--MIME.Bound' || utl_tcp.CRLF ||
                             'Content-Type: text/plain; '|| utl_tcp.CRLF ||
                             'Content-Transfer_Encoding: 7bit'|| utl_tcp.CRLF || utl_tcp.CRLF ||
                             p_message_text || utl_tcp.CRLF || utl_tcp.CRLF ||
                             '--MIME.Bound' || utl_tcp.CRLF ||
                             'Content-Type: text/html;'|| utl_tcp.CRLF ||
                             'Content-Transfer_Encoding: 7bit'|| utl_tcp.CRLF || utl_tcp.CRLF ||
                             p_message_html || utl_tcp.CRLF ||
                             '--MIME.Bound--' || utl_tcp.CRLF);
  utl_smtp.close_data( conn );
  utl_smtp.quit( conn );

END SEND_MULTI_ALT_EMAIL;



PROCEDURE SEND_CD_NOTIFICATIONS (
    Errbuf                 OUT NOCOPY VARCHAR2
   ,Retcode                OUT NOCOPY VARCHAR2
)
IS
  ls_smtp_server          VARCHAR2(240);
  ls_from_name            VARCHAR2(240);
  ls_send_to              VARCHAR2(240);
  ls_subject              VARCHAR2(240);
  ls_message_html         VARCHAR2(240);
  ls_message              VARCHAR2(4000);
  ln_smtp_server_port     PLS_INTEGER;
  ln_no_older_than_n_days NUMBER;
  ls_instance             VARCHAR2(10);
BEGIN
  get_translations('AR_EBL_EMAIL_CONFIG','RESEND',ls_smtp_server, ln_smtp_server_port, ls_from_name, ls_subject, ls_message, ls_message_html);
  get_translation('AR_EBL_CONFIG','NOTIFY_CD','SEND_TO',ls_send_to);
  get_translation('AR_EBL_CONFIG','NOTIFY_CD','NO_OLDER_THAN_N_DAYS',ln_no_older_than_n_days);
  IF ln_no_older_than_n_days IS NULL THEN
     ln_no_older_than_n_days := 3;
  END IF;
  SELECT SUBSTR(LOWER(name),4,9) INTO ls_instance FROM V$DATABASE WHERE ROWNUM=1;

  FOR lr IN (SELECT DISTINCT TO_CHAR(T.billing_dt,'YYYY-MM-DD') || '\' || A.account_number path, A.account_number, A.account_name, D.cd_send_to_address,
                             D.comments, NVL(L.meaning,'Invalid') ebill_associate, CASE WHEN T.status='SENDBYCD' THEN 'OVERSIZE File' ELSE 'File' END notif_type
               FROM XX_AR_EBL_TRANSMISSION T
               JOIN HZ_CUST_ACCOUNTS_ALL A
                 ON T.customer_id=A.cust_account_id
               JOIN XX_CDH_EBL_TRANSMISSION_DTL D
                 ON T.customer_doc_id=D.cust_doc_id
               JOIN XX_CDH_EBL_MAIN M
                 ON M.cust_doc_id=T.customer_doc_id
    LEFT OUTER JOIN FND_LOOKUP_VALUES L
                 ON M.ebill_associate=L.lookup_code
              WHERE T.billing_dt>SYSDATE-ln_no_older_than_n_days  -- for index/performance
                AND T.notification_sent_dt IS NULL
                AND (   (T.status='SENTBYCD')
                     OR (T.status='SENT'     AND T.transmission_type='CD'))
                AND T.org_id=FND_GLOBAL.org_id
                AND L.lookup_type='XXOD_EBL_ASSOCIATE'
                AND L.enabled_flag='Y'
                AND SYSDATE BETWEEN NVL(L.start_date_active,SYSDATE) AND NVL(L.end_date_active,SYSDATE)) LOOP
    BEGIN
      ls_subject := TRIM(GET_MESSAGE('CD_NOTIF_SUBJECT','ACCOUNT_NUMBER', lr.account_number, 'TYPE', lr.notif_type, 'ASSOCIATE', lr.ebill_associate));
      ls_message := GET_MESSAGE('CD_NOTIF_BODY', 'INSTANCE', ls_instance, 'FOLDER', lr.path , 'ADDRESS', lr.cd_send_to_address, 'COMMENTS', lr.comments);

      PUT_LOG_LINE('eMailing CD notification for account ' || lr.account_number || ': ' || lr.account_name);
      PUT_LOG_LINE('  ' || lr.notif_type || ' path: ' || lr.path || '    associate: ' || lr.ebill_associate);
      SEND_SIMPLE_EMAIL(ls_smtp_server, ln_smtp_server_port, ls_from_name, ls_send_to, ls_subject, ls_message);

      UPDATE (SELECT T.*
                FROM XX_AR_EBL_TRANSMISSION T
                JOIN HZ_CUST_ACCOUNTS_ALL A
                  ON T.customer_id=A.cust_account_id
               WHERE T.billing_dt>SYSDATE-ln_no_older_than_n_days
                 AND T.org_id=FND_GLOBAL.org_id
                 AND T.notification_sent_dt is null
                 AND (T.status='SENTBYCD' OR (T.status='SENT' AND T.transmission_type='CD'))
                 AND TO_CHAR(T.billing_dt,'YYYY-MM-DD') || '\' || A.account_number = lr.path) T
         SET T.notification_sent_to=lr.ebill_associate
            ,T.notification_sent_dt=SYSDATE
            ,T.last_updated_by=fnd_global.user_id
            ,T.last_update_date=SYSDATE
            ,T.last_update_login=fnd_global.login_id;

      COMMIT;

    EXCEPTION WHEN OTHERS THEN
      PUT_LOG_LINE('Error in send_cd_notifications: ' || SQLERRM || ' ls_smtp_server:' || ls_smtp_server || ' path: ' || lr.path || ' ebill_associate: ' || lr.ebill_associate);
      PUT_ERR_LINE('Error in send_cd_notifications: ' || SQLERRM, ls_smtp_server, lr.path, lr.ebill_associate);
    END;
  END LOOP;
END SEND_CD_NOTIFICATIONS;


PROCEDURE SEND_FTP_NOTIFICATIONS (
    Errbuf                 OUT NOCOPY VARCHAR2
   ,Retcode                OUT NOCOPY VARCHAR2
)
IS
  ls_smtp_server          VARCHAR2(240);
  ls_from_name            VARCHAR2(240);
  ls_send_to              VARCHAR2(240);
  ls_subject              VARCHAR2(240);
  ls_message_text         VARCHAR2(4000);
  ls_message_html         VARCHAR2(4000);
  ln_smtp_server_port     PLS_INTEGER;
  ls_logo_url             VARCHAR2(240);
  ls_hyperlink            VARCHAR2(240);
  ls_alt                  VARCHAR2(240);
  ln_no_older_than_n_days NUMBER;
  ls_status_detail        VARCHAR2(2000);
  ln_pos                  NUMBER;
BEGIN
  get_translations('AR_EBL_EMAIL_CONFIG','RESEND',ls_smtp_server, ln_smtp_server_port, ls_from_name, ls_subject, ls_message_text, ls_message_html);
  get_translation('AR_EBL_CONFIG','NOTIFY_FTP','NO_OLDER_THAN_N_DAYS',ln_no_older_than_n_days);
  IF ln_no_older_than_n_days IS NULL THEN
     ln_no_older_than_n_days := 3;
  END IF;

  FOR lr IN
            (SELECT DISTINCT A.account_number, SUBSTR(A.orig_system_reference,1,8) aops_number, A.account_name,
                    D.ftp_cust_contact_email, D.ftp_cc_emails, D.ftp_email_sub, NVL(D.ftp_destination_folder,'your Office Depot FTP account folder') ftp_destination_folder, T.billing_dt_from, T.billing_dt,
                    CASE WHEN T.zero_byte_flag='Y' THEN D.ftp_zero_byte_notification_txt ELSE D.ftp_email_content END ftp_email_text
               FROM XX_AR_EBL_TRANSMISSION T
               JOIN HZ_CUST_ACCOUNTS_ALL A
                 ON T.customer_id=A.cust_account_id
               JOIN XX_CDH_EBL_TRANSMISSION_DTL D
                 ON T.customer_doc_id=D.cust_doc_id
               JOIN XX_CDH_EBL_MAIN M
                 ON M.cust_doc_id=T.customer_doc_id
              WHERE T.billing_dt>SYSDATE-ln_no_older_than_n_days  -- for index/performance
                AND T.org_id=FND_GLOBAL.org_id
                AND T.notification_sent_dt IS NULL
                AND T.status='SENT'
                AND T.transmission_type='FTP'
                AND D.ftp_notify_customer='Y') LOOP
    BEGIN
      ls_subject := REPLACE(REPLACE(lr.ftp_email_sub,'&DATEFROM',TO_CHAR(lr.billing_dt_from, 'MM/DD/RRRR')),'&DATETO',TO_CHAR(lr.billing_dt, 'MM/DD/RRRR'));

      ls_message_html := '';
      get_logo_details('OFFICEDEPOT', ls_logo_url, ls_hyperlink, ls_alt);
      IF ls_logo_url IS NOT NULL THEN
        IF ls_hyperlink IS NOT NULL THEN
          ls_message_html := ls_message_html || '<a href="' || ls_hyperlink || '"><img border=0 src="' || ls_logo_url || '" alt="' || ls_alt || '"></a><br><br>';
        ELSE
          ls_message_html := ls_message_html || '<img border=0 src="' || ls_logo_url || '" alt="' || ls_alt || '"><br><br>';
        END IF;
      END IF;

      ls_message_text := REPLACE(REPLACE(lr.ftp_email_text,'&DATEFROM',TO_CHAR(lr.billing_dt_from, 'MM/DD/RRRR')),'&DATETO',TO_CHAR(lr.billing_dt, 'MM/DD/RRRR'));
      ls_message_text := REPLACE(REPLACE(REPLACE(ls_message_text,'&ACCOUNTNUMBER',lr.account_number),'&ACCOUNTNAME',lr.account_name),'&AOPSNUMBER',lr.aops_number);
      ls_message_text := REPLACE(ls_message_text,'&FOLDERNAME',lr.ftp_destination_folder);
      ls_message_html := ls_message_html || ls_message_text;
      ls_message_text := REPLACE(REPLACE(ls_message_text, '<br>', utl_tcp.CRLF), '<BR>', utl_tcp.CRLF);
      ls_message_html := ls_message_html || '</body></html>';

      PUT_LOG_LINE('eMailing account ' || lr.account_number || ': ' || lr.account_name);
      SEND_MULTI_ALT_EMAIL(ls_smtp_server,ln_smtp_server_port,ls_from_name,lr.ftp_cust_contact_email,lr.ftp_cc_emails,ls_subject,ls_message_text,ls_message_html,ls_status_detail);

      ln_pos := INSTR(ls_status_detail,'BAD:');
      IF ln_pos=1 THEN
          PUT_LOG_LINE('  Unable to send email notification-- ' || ls_status_detail); -- transmission not updated so will retry until window passes (i.e., sysdate-ln_no_older_than_n_days)
      ELSE
          IF ln_pos=0 THEN
              PUT_LOG_LINE('  eMail sent to-- ' || ls_status_detail);
          ELSE
              PUT_LOG_LINE('  Partial notification sent-- ' || ls_status_detail);
          END IF;

          UPDATE (SELECT T.*
                    FROM XX_AR_EBL_TRANSMISSION T
                    JOIN XX_CDH_EBL_TRANSMISSION_DTL D
                      ON T.customer_doc_id=D.cust_doc_id
                   WHERE T.billing_dt>SYSDATE-ln_no_older_than_n_days
                     AND T.org_id=FND_GLOBAL.org_id
                     AND T.notification_sent_dt is null
                     AND T.status='SENT'
                     AND T.transmission_type='FTP'
                     AND D.ftp_notify_customer='Y'
                     AND NVL(D.ftp_destination_folder,lr.ftp_destination_folder)=lr.ftp_destination_folder
                     AND NVL(D.ftp_cust_contact_email,'~')=NVL(lr.ftp_cust_contact_email,'~')
                     AND NVL(D.ftp_cc_emails,'~')=NVL(lr.ftp_cc_emails,'~')) T
            SET T.notification_sent_to=SUBSTR(ls_status_detail,1,240)
               ,T.notification_sent_dt=SYSDATE
               ,T.last_updated_by=fnd_global.user_id
               ,T.last_update_date=SYSDATE
               ,T.last_update_login=fnd_global.login_id;

         COMMIT;
      END IF;

    EXCEPTION WHEN OTHERS THEN
      PUT_LOG_LINE('Error in send_ftp_notifications: ' || SQLERRM || ' ls_smtp_server:' || ls_smtp_server || ' account_number:' || lr.account_number);
      PUT_ERR_LINE('Error in send_ftp_notifications: ' || SQLERRM, ls_smtp_server, lr.account_number);
    END;
  END LOOP;
END SEND_FTP_NOTIFICATIONS;



PROCEDURE CHECK_CHILD_REQUEST (
   p_request_id  IN OUT  NOCOPY  NUMBER
) IS
  call_status     boolean;
  rphase          varchar2(80);
  rstatus         varchar2(80);
  dphase          varchar2(30);
  dstatus         varchar2(30);
  message         varchar2(240);
BEGIN
  call_status := FND_CONCURRENT.get_request_status(
                        p_request_id,
                        '',
                        '',
                        rphase,
                        rstatus,
                        dphase,
                        dstatus,
                        message);
  IF ((dphase = 'COMPLETE') and (dstatus = 'NORMAL')) THEN
      put_log_line( 'child request id: ' || p_request_id || ' completed successfully');
  ELSE
      put_log_line( 'child request id: ' || p_request_id || ' did not complete successfully');
  END IF;
END CHECK_CHILD_REQUEST;


-- This is main transmission email delivery procedure to send an email to customer with all files for a particular transmission_id attached
PROCEDURE TRANSMIT_EMAIL (
    p_transmission_id IN XX_AR_EBL_TRANSMISSION.transmission_id%TYPE
   ,p_trans_ids       IN VARCHAR2
   ,p_smtp_server     IN VARCHAR2
   ,p_smtp_port       IN PLS_INTEGER
   ,p_from_name       IN VARCHAR2
   ,p_send_to         IN VARCHAR2
   ,p_subject         IN VARCHAR2
   ,p_message_html    IN VARCHAR2
   ,p_message_text    IN VARCHAR2
   ,p_send_zips       IN VARCHAR2
   ,x_status_detail   IN OUT VARCHAR2
)
IS
  conn utl_smtp.connection;
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
  a_file_id_array          STRINGARRAY   DEFAULT STRINGARRAY();
  file_id_in NUMBER;
  s_send_to_good_addresses XX_AR_EBL_TRANSMISSION.dest_email_addr%TYPE := NULL;
  lc_file_name             XX_AR_EBL_FILE.file_name%TYPE;
  lc_file_data             XX_AR_EBL_FILE.file_data%TYPE;
  ls_trans_values          VARCHAR2(10000);
  TYPE lcu_file_data       IS REF CURSOR;
  get_file_data            lcu_file_data;  
BEGIN

--  put_log_line('trying to send-- server:' || p_smtp_server || ' port:' || p_smtp_port || ' from:' || p_from_name || ' to:' || p_send_to || ' zips:' || p_send_zips);
--  put_log_line('                 subject: ' || p_subject);
--  put_log_line('                 text: ' || p_message_text);
--  put_log_line('                 html: ' || p_message_html);

  v_reply := utl_smtp.open_connection( p_smtp_server, p_smtp_port, conn );
  v_reply := utl_smtp.helo( conn, p_smtp_server );
  v_reply := utl_smtp.mail( conn, p_from_name );

  -- logic to send e-mail to multiple To'd users separated by ';'
  v_temp := REPLACE(REPLACE(p_send_to,' ',''),',',';');
  IF (instr(v_temp,';') = 0) OR (instr(v_temp,';') < LENGTH(v_temp)) THEN
    v_temp := v_temp||';';
  END IF;
  v_pos := 1;
  WHILE (instr(v_temp,';',v_pos) > 0) LOOP
    v_name := substr(v_temp, v_pos, instr(substr(v_temp, v_pos),';')-1);
    v_pos := v_pos + instr(substr(v_temp, v_pos),';');

-- Commented for the defect 9474
/*  IF INSTR(v_name,'@')<2 OR INSTR(v_name,'.')<4 THEN
    x_status_detail := x_status_detail || 'Bad email address: ' || v_name || '; ';
    ELSE */
     v_reply := utl_smtp.rcpt(conn, v_name);

        v_reply_code := to_char(v_reply.code);
        IF v_reply.code = 250 THEN
            IF s_send_to_good_addresses IS NULL THEN
                s_send_to_good_addresses := v_name;
            ELSE
                s_send_to_good_addresses := s_send_to_good_addresses || ';' || v_name;
            END IF;
        ELSE
            x_status_detail := x_status_detail || 'Unable to send to ' || v_name || '(code' || v_reply.code || '); ';
        END IF;
    --END IF; -- Commented for the defect 9474
  END LOOP;

  IF s_send_to_good_addresses IS NULL THEN
    utl_smtp.quit( conn );
    RAISE_APPLICATION_ERROR(-20735, 'Unable to add any recipients; check addresses: "' || p_send_to || '"  ' || x_status_detail);
  END IF;

  msg := 'Return-Path: '|| p_from_name|| utl_tcp.CRLF ||
         'Date: '|| TO_CHAR(systimestamp,'Dy, DD Mon YYYY HH24:MI:SS TZHTZM')|| utl_tcp.CRLF ||  --Changed for defect 8196
         'From: '|| p_from_name|| utl_tcp.CRLF ||
         'Subject: '|| p_subject || utl_tcp.CRLF ||
         'To: '|| s_send_to_good_addresses || utl_tcp.CRLF ||
--         'Cc: '|| cc_name || utl_tcp.CRLF ||
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
         p_message_text || utl_tcp.CRLF ||
         utl_tcp.CRLF ||
         '--MIME.Bound2' || utl_tcp.CRLF ||
         'Content-Type: text/html;'|| utl_tcp.CRLF ||
         'Content-Transfer_Encoding: 7bit'|| utl_tcp.CRLF ||
         utl_tcp.CRLF ||
         p_message_html || utl_tcp.CRLF ||
         '--MIME.Bound2--' || utl_tcp.CRLF ||
         utl_tcp.CRLF;

  utl_smtp.open_data(conn);
  utl_smtp.write_data( conn, msg );

   --Commented for Defect#NAIT-27146 by Thilak CG on 21-MAY-2018	 
   /* FOR lr IN (SELECT file_name, file_data
               FROM XX_AR_EBL_FILE
              WHERE transmission_id IN (NVL(p_transmission_id,p_trans_ids))
                AND ((p_send_zips='Y' AND file_type='ZIP')
                 OR (NVL(p_send_zips,'N')='N' AND file_type<>'ZIP'))) LOOP */
				 
    --Added for Defect#NAIT-27146 by Thilak CG on 21-MAY-2018	
    ls_trans_values := NULL; 	
    IF p_transmission_id IS NOT NULL 
    THEN
	ls_trans_values := p_transmission_id;
	ELSE
	ls_trans_values := p_trans_ids;
    END IF;	
   
    OPEN get_file_data FOR 'SELECT file_name, file_data
                              FROM XX_AR_EBL_FILE
                             WHERE transmission_id IN '|| '('||ls_trans_values||')'||
                             ' AND (('''||p_send_zips||'''=''Y'' AND file_type=''ZIP'')
                                OR (NVL('''||p_send_zips||''',''N'')=''N'' AND file_type<>''ZIP''))';				 
    LOOP
    FETCH get_file_data INTO lc_file_name,lc_file_data;
    EXIT WHEN get_file_data%NOTFOUND;
    -- End
 	BEGIN				 
      FND_FILE.put_line(FND_FILE.LOG,'File Name:'||lc_file_name);
      utl_smtp.write_data( conn, '--MIME.Bound' || utl_tcp.CRLF);
      utl_smtp.write_data( conn, 'Content-Type: application/octet-stream; name="' || lc_file_name || '"' || utl_tcp.CRLF);
      utl_smtp.write_data( conn, 'Content-Disposition: attachment; filename="'    || lc_file_name || '"' || utl_tcp.CRLF);
      utl_smtp.write_data( conn, 'Content-Transfer-Encoding: base64' || utl_tcp.CRLF );
      utl_smtp.write_data( conn, utl_tcp.CRLF );

      v_length := dbms_lob.getlength(lc_file_data);

      --reset the offset
      v_offset := 1;
      v_buffer_size := 57; -- this is set to actual amt read by dbms_lob.read, so must reset from value of last attachment's partial read at end of blob.
      WHILE v_offset <= v_length LOOP
        dbms_lob.read( lc_file_data, v_buffer_size, v_offset, v_raw );
        utl_smtp.write_raw_data( conn, utl_encode.base64_encode(v_raw) );
        utl_smtp.write_data( conn, utl_tcp.CRLF );
        v_offset := v_offset + v_buffer_size;
      END LOOP;
      utl_smtp.write_data( conn, utl_tcp.CRLF );

      EXCEPTION
        WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
          utl_smtp.quit( conn );
          RAISE_APPLICATION_ERROR(-20736, 'UTL_SMTP transient or permanent error. ' || SQLERRM);
        WHEN OTHERS THEN
          utl_smtp.quit( conn );
          RAISE_APPLICATION_ERROR(-20737, 'UTL_SMTP other error. ' || SQLERRM);
      END;
  END LOOP;
  CLOSE get_file_data;
  
  utl_smtp.write_data( conn, '--MIME.Bound--'); -- End MIME mail
  utl_smtp.write_data( conn, utl_tcp.crlf );
  utl_smtp.close_data( conn );
  utl_smtp.quit( conn );
END TRANSMIT_EMAIL;


PROCEDURE TRANSMIT_EMAIL_C (
    Errbuf            OUT NOCOPY VARCHAR2
   ,Retcode           OUT NOCOPY VARCHAR2
   ,p_thread_id       IN NUMBER
   ,p_thread_count    IN NUMBER
   ,p_smtp_server     IN VARCHAR2
   ,p_smtp_port       IN PLS_INTEGER
   ,p_from_name       IN VARCHAR2
)
IS
  ls_error_message      VARCHAR2(4000);
  ls_subject            VARCHAR2(300);
  ls_message_html       VARCHAR2(14000) := '<html><head></head><body>';
  ls_message_text       VARCHAR2(14000);
  ln_thread_id          NUMBER := p_thread_id-1; -- switch to zero-based thread id for use in mod function
  ls_logo_url           VARCHAR2(240);
  ls_hyperlink          VARCHAR2(240);
  ls_alt                VARCHAR2(240);
  ls_ps_text            VARCHAR2(240);
  ls_ps_html            VARCHAR2(240);
  ls_status_detail      VARCHAR2(4000);
  ls_trans_ids          VARCHAR2(5000);
  ls_update_trans_ids   VARCHAR2(5000);
  ls_dest_email_addr    VARCHAR2(5000);	
  ls_zip_required       VARCHAR2(5000);
  ls_upd_trans_status   VARCHAR2(32767);
  ls_upd_trans_error    VARCHAR2(32767);
  ls_parent_email_addr  VARCHAR2(9000);
  ln_trans_id           NUMBER;
  ls_max_size_file         VARCHAR2(240) := NULL;
  ls_max_size_transmission VARCHAR2(240) := NULL;
  ln_max_size_file         NUMBER        := NULL;
  ln_max_size_transmission NUMBER        := NULL;
  ln_total_file_length     NUMBER        := NULL;
  ls_send_toobig_notif  VARCHAR2(240);
  ls_subject_toobig     VARCHAR2(240);
  ls_message_toobig     VARCHAR2(4000);
  ls_billing_dt         VARCHAR2(300);
  ls_billing_dt_from    VARCHAR2(300);
  ls_account_number     VARCHAR2(240);
  ls_file_names         VARCHAR2(5000);
  TYPE lcu_parent_docs  IS REF CURSOR;
  get_parent_docs       lcu_parent_docs;
  TYPE lcu_parent_ind   IS REF CURSOR;
  get_parent_ind        lcu_parent_ind;
  TYPE lcu_file_length  IS REF CURSOR;
  get_file_length       lcu_file_length;  
  
BEGIN
  put_log_line(p_thread_id || ' of ' || p_thread_count || ' smtp_server=' || p_smtp_server || ' port=' || p_smtp_port || ' from_name=' || p_from_name);

  get_translation('AR_EBL_CONFIG','TRANSMIT_EMAIL','PS_TEXT',ls_ps_text);
  get_translation('AR_EBL_CONFIG','TRANSMIT_EMAIL','PS_HTML',ls_ps_html);
  
  
  IF p_thread_id <= 1 THEN 
   TRANSMIT_BC_MERGE_PDF( p_smtp_server ,p_smtp_port ,p_from_name);
  END IF;

  --Added for NAIT-91484 by Visu CG on 24-APR-2018	 
  --Bill Complete Batch Email(Add all the pdf bills as attachments in one email)
  --Data selection criteria: Bill complete customer, Delivery method: PDF, Transmission type : Email, File processing id 02
   IF p_thread_id <= 1 THEN 
     get_translation('AR_EBL_CONFIG','TRANSMIT_EMAIL','MAX_SIZE_FILE_IN_BYTES'        ,ls_max_size_file);
     get_translation('AR_EBL_CONFIG','TRANSMIT_EMAIL','MAX_SIZE_TRANSMISSION_IN_BYTES',ls_max_size_transmission);
     ln_max_size_file         := TO_NUMBER(ls_max_size_file);
     ln_max_size_transmission := TO_NUMBER(ls_max_size_transmission);

    FOR lcbr IN (SELECT DISTINCT T.customer_id, M.cust_doc_id 
                FROM XX_AR_EBL_TRANSMISSION T
                JOIN XX_CDH_EBL_MAIN M
                  ON T.customer_doc_id=M.cust_doc_id
				 WHERE T.status='SEND' AND T.transmission_type='EMAIL'
                 AND T.org_id=FND_GLOBAL.org_id
                 AND M.file_processing_method = '02' -- One Order per File. Multiple Files in a Transmission
				 AND EXISTS (SELECT 1 FROM XX_CDH_CUST_ACCT_EXT_B 
								     WHERE n_ext_attr2 = T.customer_doc_id 
									   AND cust_account_id = T.customer_id
								       AND c_ext_attr1     = 'Consolidated Bill' --Document_Type
								       AND c_ext_attr2     = 'Y'                 -- paydoc indicator
								  	   AND c_ext_attr3     = 'ePDF'              -- Delivery method epdf)	
                            )												
			     AND EXISTS (SELECT 1 FROM HZ_CUSTOMER_PROFILES 
				                     WHERE cust_account_id = T.customer_id
									   AND cons_inv_flag   = 'Y'
								  	   AND attribute6 IN ('Y','B')
								  	   AND site_use_id IS NULL
						    )
				 AND 0=(SELECT COUNT(1)
				          FROM XX_AR_EBL_FILE F
			             WHERE F.transmission_id=T.transmission_id
			  	           AND NVL(F.status,'X')<>'RENDERED')
			     AND 0<(SELECT COUNT(1)
			   		      FROM XX_AR_EBL_FILE F
					     WHERE F.transmission_id=T.transmission_id
						   AND NVL(F.status,'X')='RENDERED')) LOOP
  -- Loop through transmission ids of given customer
       ls_trans_ids         := NULL;	
       ls_update_trans_ids  := NULL;
       ls_dest_email_addr   := NULL;	
	   ln_total_file_length := NULL;
       ls_send_toobig_notif  := NULL;
       ls_subject_toobig     := NULL;
       ls_message_toobig     := NULL;
       ls_billing_dt         := NULL;
       ls_billing_dt_from    := NULL;
       ls_account_number     := NULL;
       ls_file_names         := NULL;

    FOR lcmr IN (SELECT X.* FROM (SELECT DISTINCT T.transmission_id, T.dest_email_addr, T.billing_dt_from, T.billing_dt,
                                     D.email_subject, D.email_std_message, D.email_custom_message, D.email_signature,
                                     D.email_std_disclaimer, D.email_logo_required, D.email_logo_file_name, M.zip_required,
                                     H.account_number, H.account_name, SUBSTR(H.orig_system_reference,1,8) aops_number,
									 E.file_name
                                FROM XX_AR_EBL_TRANSMISSION T
                                JOIN XX_CDH_EBL_TRANSMISSION_DTL D
                                  ON T.customer_doc_id=D.cust_doc_id
                                JOIN XX_CDH_EBL_MAIN M
                                  ON T.customer_doc_id=M.cust_doc_id
                                JOIN HZ_CUST_ACCOUNTS_ALL H
                                  ON T.customer_id=H.cust_account_id
                                JOIN HZ_CUSTOMER_PROFILES P
                                  ON P.cust_account_id   = H.cust_account_id
								JOIN XX_AR_EBL_FILE E
								  ON E.transmission_id = T.transmission_id
                               WHERE T.status='SEND' AND T.transmission_type='EMAIL'
							     AND T.customer_id=lcbr.customer_id
                                 AND T.org_id=FND_GLOBAL.org_id
                                 AND P.cons_inv_flag    = 'Y'
				                 AND P.attribute6   IN ('Y','B')
								 AND P.site_use_id IS NULL
								 AND M.ebill_transmission_type = 'EMAIL'
								 AND M.file_processing_method = '02' -- One Order per File. Multiple Files in a Transmission
								 AND EXISTS (SELECT 1 FROM XX_CDH_CUST_ACCT_EXT_B 
											  WHERE n_ext_attr2 = T.customer_doc_id 
												AND cust_account_id = lcbr.customer_id
												AND cust_account_id = H.cust_account_id
												AND c_ext_attr1     = 'Consolidated Bill' --Document_Type
												AND c_ext_attr2     = 'Y'                 -- paydoc indicator
												AND c_ext_attr3     = 'ePDF'              -- Delivery method epdf
												)) X
								WHERE 0=(SELECT COUNT(1)
										   FROM XX_AR_EBL_FILE F
										  WHERE F.transmission_id=X.transmission_id
											AND NVL(F.status,'X')<>'RENDERED')
								  AND 0<(SELECT COUNT(1)
										   FROM XX_AR_EBL_FILE F
										  WHERE F.transmission_id=X.transmission_id
											AND NVL(F.status,'X')='RENDERED')) LOOP
       ls_zip_required     := NULL;	  
       ls_message_html     := '';
       ls_status_detail    := '';
       
       put_log_line(' ');
       put_log_line('Sending transmission ' || lcmr.transmission_id || ' for account ' || lcmr.account_number || ': ' || lcmr.account_name);
       put_log_line('  to "' || lcmr.dest_email_addr || '"');
       
       ls_subject := REPLACE(REPLACE(lcmr.email_subject,'&DATEFROM',TO_CHAR(lcmr.billing_dt_from, 'MM/DD/RRRR')),'&DATETO',TO_CHAR(lcmr.billing_dt, 'MM/DD/RRRR'));
       ls_subject := REPLACE(ls_subject,'&AOPSNUMBER',lcmr.aops_number);

      IF lcmr.email_logo_required='Y' AND lcmr.email_logo_file_name IS NOT NULL THEN
        get_logo_details(lcmr.email_logo_file_name, ls_logo_url, ls_hyperlink, ls_alt);
        IF ls_logo_url IS NOT NULL THEN
          IF ls_hyperlink IS NOT NULL THEN
            ls_message_html := ls_message_html || '<a href="' || ls_hyperlink || '"><img border=0 src="' || ls_logo_url || '" alt="' || ls_alt || '"></a><br><br>';
          ELSE
            ls_message_html := ls_message_html || '<img border=0 src="' || ls_logo_url || '" alt="' || ls_alt || '"><br><br>';
          END IF;
        END IF;
      END IF;

      ls_message_text := REPLACE(REPLACE(lcmr.email_std_message,'&DATEFROM',TO_CHAR(lcmr.billing_dt_from, 'MM/DD/RRRR')),'&DATETO',TO_CHAR(lcmr.billing_dt, 'MM/DD/RRRR'));
      ls_message_text := REPLACE(REPLACE(REPLACE(ls_message_text,'&ACCOUNTNUMBER',lcmr.account_number),'&ACCOUNTNAME',lcmr.account_name),'&AOPSNUMBER',lcmr.aops_number);
      ls_message_html := ls_message_html || ls_message_text;

      ls_message_text := REPLACE(REPLACE(ls_message_text || utl_tcp.CRLF || utl_tcp.CRLF ||
                                         lcmr.email_custom_message || utl_tcp.CRLF || utl_tcp.CRLF ||
                                         lcmr.email_signature || utl_tcp.CRLF || utl_tcp.CRLF ||
                                         ls_ps_text || utl_tcp.CRLF || utl_tcp.CRLF ||
                                         lcmr.email_std_disclaimer, '<br>', utl_tcp.CRLF), '<BR>', utl_tcp.CRLF);

      ls_message_html := ls_message_html         || '<br><br>' ||
                         lcmr.email_custom_message || '<br><br>' ||
                         lcmr.email_signature      || '<br><br>' ||
                         ls_ps_html              || '<br><br>' ||
                         lcmr.email_std_disclaimer || '</body></html>';

      ls_trans_ids := ls_trans_ids || lcmr.transmission_id || ',';
      ls_dest_email_addr := ls_dest_email_addr || lcmr.dest_email_addr || ';';
      ls_zip_required := lcmr.zip_required;
	  ls_file_names := ls_file_names||lcmr.file_name|| ',';
	  ls_billing_dt := TO_CHAR(lcmr.billing_dt, 'MM/DD/RRRR');
      ls_account_number := lcmr.account_number;
	  ls_billing_dt_from := TO_CHAR(lcmr.billing_dt_from, 'MM/DD/RRRR');

    END LOOP;
	
     ls_trans_ids := SUBSTR(ls_trans_ids,1,LENGTH(ls_trans_ids)-1);
	 FND_FILE.put_line(FND_FILE.LOG,'Bill complete batch email Transmission IDs:'||ls_trans_ids);
     ls_dest_email_addr := SUBSTR(ls_dest_email_addr,1,LENGTH(ls_dest_email_addr)-1);
	 FND_FILE.put_line(FND_FILE.LOG,'Bill complete batch email Transmission Email IDs:'||ls_dest_email_addr);		
	 ls_update_trans_ids := '('||ls_trans_ids||')';

		OPEN get_file_length FOR 'SELECT TO_NUMBER(SUM(dbms_lob.getlength(file_data)))
								  FROM XX_AR_EBL_FILE
								 WHERE transmission_id IN '|| ls_update_trans_ids;				 
		LOOP
		FETCH get_file_length INTO ln_total_file_length;
		EXIT WHEN get_file_length%NOTFOUND;
		END LOOP;
		CLOSE get_file_length;
		put_log_line('  --Total file length sum : ' || ln_total_file_length);

	 -- End Loop through transmission ids of given customer
     IF (((ln_total_file_length IS NOT NULL) AND (ln_total_file_length <= ln_max_size_file))
	 AND ((ln_total_file_length IS NOT NULL) AND (ln_total_file_length <= ln_max_size_transmission)))
	 THEN
	 BEGIN
	 -- If the total length of all the files is with in the maximum file sized allowed, then call tranmsit_email to send email to customer
	 -- else call 
      TRANSMIT_EMAIL(NULL, ls_trans_ids, p_smtp_server, p_smtp_port, p_from_name, ls_dest_email_addr, ls_subject, ls_message_html, ls_message_text, ls_zip_required, ls_status_detail);
      ls_upd_trans_status := 'UPDATE XX_AR_EBL_TRANSMISSION SET status=''SENT'', transmission_dt=SYSDATE, last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id, status_detail='''||ls_status_detail
	                          ||''' WHERE transmission_id IN '||ls_update_trans_ids;
							 
	  EXECUTE IMMEDIATE ls_upd_trans_status;
      COMMIT;
      put_log_line('  -- Mail Sent ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH:MI:SS AM'));
      IF ls_status_detail IS NOT NULL THEN
          put_log_line('     ' || ls_status_detail);
      END IF;
     EXCEPTION WHEN OTHERS THEN
      ls_error_message := SQLERRM;
      ls_upd_trans_error := 'UPDATE XX_AR_EBL_TRANSMISSION SET status=''ERROR'', status_detail='''||ls_error_message||''', last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id'
                            ||' WHERE transmission_id IN '||ls_update_trans_ids;
					
      EXECUTE IMMEDIATE ls_upd_trans_error; 							
      COMMIT;
      put_log_line('  -- Bill complete batch email Errored: ' || ls_error_message);
     END;
	 ELSIF (((ln_total_file_length IS NOT NULL) AND (ln_total_file_length > ln_max_size_file)) -- total file length else condition
       AND ((ln_total_file_length IS NOT NULL) AND (ln_total_file_length > ln_max_size_transmission)))	 
	 THEN
		ls_subject_toobig := 'OVERSIZE Bill Complete Batch Email for Account '||ls_account_number||' and Cust Doc Id '||lcbr.cust_doc_id||' for the period ' || ls_billing_dt_from||' to '||ls_billing_dt;
		get_translation('AR_EBL_CONFIG','NOTIFY_CD','SEND_TO',ls_send_toobig_notif);
			
		ls_file_names := SUBSTR(ls_file_names,1,LENGTH(ls_file_names)-1);

		ls_message_toobig := GET_MESSAGE('BILL_BATCH_EMAIL', 'CUSTOMER',ls_account_number, 'CUSTDOCID', lcbr.cust_doc_id , 'BILLDATE', ls_billing_dt, 'FILENAMES', ls_file_names);
		SEND_SIMPLE_EMAIL(p_smtp_server, p_smtp_port, p_from_name, ls_send_toobig_notif, ls_subject_toobig, ls_message_toobig);
	 END IF; -- Total file length if condition 
    END LOOP;
  END IF;
  --Bill Complete Batch Email(Add all the pdf bills as attachments in one email)
  --End for Defect#NAIT-91484 by Visu CG on 24-APR-2018
  
  --Added for Defect#NAIT-27146 by Thilak CG on 21-MAY-2018	 
  --Parent customer distinct loop
  -- Direct Customer docs
  FOR lcr IN (SELECT DISTINCT T.customer_id, M.parent_doc_id 
                FROM XX_AR_EBL_TRANSMISSION T
                JOIN XX_CDH_EBL_MAIN M
                  ON T.customer_doc_id=M.cust_doc_id
				 AND M.parent_doc_id IS NOT NULL
               WHERE T.status='SEND' AND T.transmission_type='EMAIL'
                 AND T.org_id=FND_GLOBAL.org_id
				 AND EXISTS (SELECT 1 FROM XX_CDH_CUST_ACCT_EXT_B 
				              WHERE n_ext_attr2 = T.customer_doc_id
 							    AND c_ext_attr7 = 'Y')				 
			     AND 0=(SELECT COUNT(1)
				          FROM XX_AR_EBL_FILE F
			             WHERE F.transmission_id=T.transmission_id
			  	           AND NVL(F.status,'X')<>'RENDERED')
			     AND 0<(SELECT COUNT(1)
			   		      FROM XX_AR_EBL_FILE F
					     WHERE F.transmission_id=T.transmission_id
						   AND NVL(F.status,'X')='RENDERED')) LOOP
  ls_trans_ids := NULL;	
  ls_update_trans_ids := NULL;
  ls_dest_email_addr := NULL;	
  ls_zip_required := NULL;	  
  --Loop to send multiple docs in a mail for parent and child cust docs
  FOR lmr IN (SELECT X.* FROM (SELECT DISTINCT M.parent_doc_id, T.transmission_id, T.dest_email_addr, T.billing_dt_from, T.billing_dt,
                                     D.email_subject, D.email_std_message, D.email_custom_message, D.email_signature,
                                     D.email_std_disclaimer, D.email_logo_required, D.email_logo_file_name, M.zip_required,
                                     H.account_number, H.account_name, SUBSTR(H.orig_system_reference,1,8) aops_number
                                FROM XX_AR_EBL_TRANSMISSION T
                                JOIN XX_CDH_EBL_TRANSMISSION_DTL D
                                  ON T.customer_doc_id=D.cust_doc_id
                                JOIN XX_CDH_EBL_MAIN M
                                  ON T.customer_doc_id=M.cust_doc_id
								 AND M.parent_doc_id IS NOT NULL
								 AND M.parent_doc_id = lcr.parent_doc_id
                                JOIN HZ_CUST_ACCOUNTS_ALL H
                                  ON T.customer_id=H.cust_account_id
                               WHERE T.status='SEND' AND T.transmission_type='EMAIL'
							     AND T.customer_id=lcr.customer_id
                                 AND T.org_id=FND_GLOBAL.org_id
								 AND EXISTS (SELECT 1 FROM XX_CDH_CUST_ACCT_EXT_B 
											  WHERE n_ext_attr2 = T.customer_doc_id 
												AND cust_account_id = lcr.customer_id 
												AND c_ext_attr7 = 'Y')) X
								WHERE 0=(SELECT COUNT(1)
										   FROM XX_AR_EBL_FILE F
										  WHERE F.transmission_id=X.transmission_id
											AND NVL(F.status,'X')<>'RENDERED')
								  AND 0<(SELECT COUNT(1)
										   FROM XX_AR_EBL_FILE F
										  WHERE F.transmission_id=X.transmission_id
											AND NVL(F.status,'X')='RENDERED')) LOOP BEGIN									
    
      put_log_line(' ');
      put_log_line('Sending transmission ' || lmr.transmission_id || ' for account ' || lmr.account_number || ': ' || lmr.account_name);
      put_log_line('  to "' || lmr.dest_email_addr || '"');
	  
      ls_message_html := '';
      ls_status_detail := '';

      ls_subject := REPLACE(REPLACE(lmr.email_subject,'&DATEFROM',TO_CHAR(lmr.billing_dt_from, 'MM/DD/RRRR')),'&DATETO',TO_CHAR(lmr.billing_dt, 'MM/DD/RRRR'));
      ls_subject := REPLACE(ls_subject,'&AOPSNUMBER',lmr.aops_number);


      IF lmr.email_logo_required='Y' AND lmr.email_logo_file_name IS NOT NULL THEN
        get_logo_details(lmr.email_logo_file_name, ls_logo_url, ls_hyperlink, ls_alt);
        IF ls_logo_url IS NOT NULL THEN
          IF ls_hyperlink IS NOT NULL THEN
            ls_message_html := ls_message_html || '<a href="' || ls_hyperlink || '"><img border=0 src="' || ls_logo_url || '" alt="' || ls_alt || '"></a><br><br>';
          ELSE
            ls_message_html := ls_message_html || '<img border=0 src="' || ls_logo_url || '" alt="' || ls_alt || '"><br><br>';
          END IF;
        END IF;
      END IF;
      ls_message_text := REPLACE(REPLACE(lmr.email_std_message,'&DATEFROM',TO_CHAR(lmr.billing_dt_from, 'MM/DD/RRRR')),'&DATETO',TO_CHAR(lmr.billing_dt, 'MM/DD/RRRR'));
      ls_message_text := REPLACE(REPLACE(REPLACE(ls_message_text,'&ACCOUNTNUMBER',lmr.account_number),'&ACCOUNTNAME',lmr.account_name),'&AOPSNUMBER',lmr.aops_number);
      ls_message_html := ls_message_html || ls_message_text;

      ls_message_text := REPLACE(REPLACE(ls_message_text || utl_tcp.CRLF || utl_tcp.CRLF ||
                                         lmr.email_custom_message || utl_tcp.CRLF || utl_tcp.CRLF ||
                                         lmr.email_signature || utl_tcp.CRLF || utl_tcp.CRLF ||
                                         ls_ps_text || utl_tcp.CRLF || utl_tcp.CRLF ||
                                         lmr.email_std_disclaimer, '<br>', utl_tcp.CRLF), '<BR>', utl_tcp.CRLF);

      ls_message_html := ls_message_html         || '<br><br>' ||
                         lmr.email_custom_message || '<br><br>' ||
                         lmr.email_signature      || '<br><br>' ||
                         ls_ps_html              || '<br><br>' ||
                         lmr.email_std_disclaimer || '</body></html>';
						
		ln_trans_id := NULL;
		ls_parent_email_addr := NULL;
		OPEN get_parent_docs FOR SELECT XAE.transmission_id, XAE.dest_email_addr
								  FROM XX_AR_EBL_TRANSMISSION XAE
								 WHERE XAE.status='SEND' AND XAE.transmission_type='EMAIL'
								   AND XAE.customer_id = lcr.customer_id
								   AND XAE.customer_doc_id = lmr.parent_doc_id
								   AND 0 = (SELECT COUNT(1)
											FROM XX_AR_EBL_FILE F
										   WHERE F.transmission_id=XAE.transmission_id
											 AND NVL(F.status,'X')<>'RENDERED')
								   AND 0 < (SELECT COUNT(1)
											FROM XX_AR_EBL_FILE F
										   WHERE F.transmission_id=XAE.transmission_id
											 AND NVL(F.status,'X')='RENDERED');				 
		LOOP
		FETCH get_parent_docs INTO ln_trans_id, ls_parent_email_addr;
		EXIT WHEN get_parent_docs%NOTFOUND;
		  ls_trans_ids := ls_trans_ids || lmr.transmission_id || ',' || ln_trans_id || ',';
		  IF ls_parent_email_addr != lmr.dest_email_addr AND ls_parent_email_addr IS NOT NULL
		  THEN
		  ls_dest_email_addr := ls_dest_email_addr || lmr.dest_email_addr || ';' || ls_parent_email_addr || ';';
		  ELSE
		  ls_dest_email_addr := ls_dest_email_addr || lmr.dest_email_addr || ';';
		  END IF;
		END LOOP;
		CLOSE get_parent_docs;
		
		IF ln_trans_id IS NULL
		THEN	
		  ls_trans_ids := ls_trans_ids || lmr.transmission_id || ',';
		  ls_dest_email_addr := ls_dest_email_addr || lmr.dest_email_addr || ';';
		END IF;
	
	 ls_zip_required := lmr.zip_required;
     EXCEPTION WHEN OTHERS THEN
      ls_error_message := SQLERRM;
      put_log_line('  -- errored: ' || ls_error_message);
     END;
    END LOOP; 
   
     ls_trans_ids := SUBSTR(ls_trans_ids,1,LENGTH(ls_trans_ids)-1);
	 FND_FILE.put_line(FND_FILE.LOG,'Direct Multi Docs Transmission IDs:'||ls_trans_ids);
     ls_dest_email_addr := SUBSTR(ls_dest_email_addr,1,LENGTH(ls_dest_email_addr)-1);
	 FND_FILE.put_line(FND_FILE.LOG,'Direct Multi Docs Transmission Email IDs:'||ls_dest_email_addr);	 
	 ls_update_trans_ids := '('||ls_trans_ids||')';
     BEGIN
      TRANSMIT_EMAIL(NULL, ls_trans_ids, p_smtp_server, p_smtp_port, p_from_name, ls_dest_email_addr, ls_subject, ls_message_html, ls_message_text, ls_zip_required, ls_status_detail);
      ls_upd_trans_status := 'UPDATE XX_AR_EBL_TRANSMISSION SET status=''SENT'', transmission_dt=SYSDATE, last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id, status_detail='''||ls_status_detail
	                          ||''' WHERE transmission_id IN '||ls_update_trans_ids;
							 
	  EXECUTE IMMEDIATE ls_upd_trans_status;
      COMMIT;
      put_log_line('  -- Mail Sent ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH:MI:SS AM'));
      IF ls_status_detail IS NOT NULL THEN
          put_log_line('     ' || ls_status_detail);
      END IF;
     EXCEPTION WHEN OTHERS THEN
      ls_error_message := SQLERRM;
      ls_upd_trans_error := 'UPDATE XX_AR_EBL_TRANSMISSION SET status=''ERROR'', status_detail='''||ls_error_message||''', last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id'
                            ||' WHERE transmission_id IN '||ls_update_trans_ids;
					
      EXECUTE IMMEDIATE ls_upd_trans_error; 							
      COMMIT;
      put_log_line('  -- Direct Errored: ' || ls_error_message);
     END;
  END LOOP; -- End Direct Customer Loop
  
  --Parent customer distinct loop
  --Indirect Customer docs
  FOR lcir IN (SELECT DISTINCT T.customer_id
                FROM XX_AR_EBL_TRANSMISSION T
                JOIN XX_CDH_EBL_MAIN M
                  ON T.customer_doc_id=M.cust_doc_id
				 AND M.parent_doc_id IS NOT NULL
               WHERE T.status='SEND' AND T.transmission_type='EMAIL'
                 AND T.org_id=FND_GLOBAL.org_id
				 AND EXISTS (SELECT 1 FROM XX_CDH_CUST_ACCT_EXT_B 
				              WHERE n_ext_attr2 = T.customer_doc_id
 							    AND c_ext_attr7 = 'N')				 
			     AND 0=(SELECT COUNT(1)
				          FROM XX_AR_EBL_FILE F
			             WHERE F.transmission_id=T.transmission_id
			  	           AND NVL(F.status,'X')<>'RENDERED')
			     AND 0<(SELECT COUNT(1)
			   		      FROM XX_AR_EBL_FILE F
					     WHERE F.transmission_id=T.transmission_id
						   AND NVL(F.status,'X')='RENDERED')) LOOP
						   
  --Loop to send multiple docs in a mail for parent and child cust docs
  FOR lmir IN (SELECT X.* FROM (SELECT DISTINCT M.parent_doc_id, T.cust_acct_site_id, T.transmission_id, T.dest_email_addr, T.billing_dt_from, T.billing_dt,
                                     D.email_subject, D.email_std_message, D.email_custom_message, D.email_signature,
                                     D.email_std_disclaimer, D.email_logo_required, D.email_logo_file_name, M.zip_required,
                                     H.account_number, H.account_name, SUBSTR(H.orig_system_reference,1,8) aops_number
                                FROM XX_AR_EBL_TRANSMISSION T
                                JOIN XX_CDH_EBL_TRANSMISSION_DTL D
                                  ON T.customer_doc_id=D.cust_doc_id
                                JOIN XX_CDH_EBL_MAIN M
                                  ON T.customer_doc_id=M.cust_doc_id
								 AND M.parent_doc_id IS NOT NULL
                                JOIN HZ_CUST_ACCOUNTS_ALL H
                                  ON T.customer_id=H.cust_account_id
                               WHERE T.status='SEND' AND T.transmission_type='EMAIL'
							     AND T.customer_id=lcir.customer_id
                                 AND T.org_id=FND_GLOBAL.org_id
								 AND EXISTS (SELECT 1 FROM XX_CDH_CUST_ACCT_EXT_B 
											  WHERE n_ext_attr2 = T.customer_doc_id 
												AND cust_account_id = lcir.customer_id
												AND c_ext_attr7 = 'N')) X
								WHERE 0=(SELECT COUNT(1)
										   FROM XX_AR_EBL_FILE F
										  WHERE F.transmission_id=X.transmission_id
											AND NVL(F.status,'X')<>'RENDERED')
								  AND 0<(SELECT COUNT(1)
										   FROM XX_AR_EBL_FILE F
										  WHERE F.transmission_id=X.transmission_id
											AND NVL(F.status,'X')='RENDERED')) LOOP BEGIN									
    
      put_log_line(' ');
      put_log_line('Sending transmission ' || lmir.transmission_id || ' for account ' || lmir.account_number || ': ' || lmir.account_name);
      put_log_line('  to "' || lmir.dest_email_addr || '"');
	  
      ls_message_html := '';
      ls_status_detail := '';
	  ls_trans_ids := NULL;	
	  ls_update_trans_ids := NULL;
	  ls_dest_email_addr := NULL;	
	  ls_zip_required := NULL;
	  
      ls_subject := REPLACE(REPLACE(lmir.email_subject,'&DATEFROM',TO_CHAR(lmir.billing_dt_from, 'MM/DD/RRRR')),'&DATETO',TO_CHAR(lmir.billing_dt, 'MM/DD/RRRR'));
      ls_subject := REPLACE(ls_subject,'&AOPSNUMBER',lmir.aops_number);


      IF lmir.email_logo_required='Y' AND lmir.email_logo_file_name IS NOT NULL THEN
        get_logo_details(lmir.email_logo_file_name, ls_logo_url, ls_hyperlink, ls_alt);
        IF ls_logo_url IS NOT NULL THEN
          IF ls_hyperlink IS NOT NULL THEN
            ls_message_html := ls_message_html || '<a href="' || ls_hyperlink || '"><img border=0 src="' || ls_logo_url || '" alt="' || ls_alt || '"></a><br><br>';
          ELSE
            ls_message_html := ls_message_html || '<img border=0 src="' || ls_logo_url || '" alt="' || ls_alt || '"><br><br>';
          END IF;
        END IF;
      END IF;
      ls_message_text := REPLACE(REPLACE(lmir.email_std_message,'&DATEFROM',TO_CHAR(lmir.billing_dt_from, 'MM/DD/RRRR')),'&DATETO',TO_CHAR(lmir.billing_dt, 'MM/DD/RRRR'));
      ls_message_text := REPLACE(REPLACE(REPLACE(ls_message_text,'&ACCOUNTNUMBER',lmir.account_number),'&ACCOUNTNAME',lmir.account_name),'&AOPSNUMBER',lmir.aops_number);
      ls_message_html := ls_message_html || ls_message_text;

      ls_message_text := REPLACE(REPLACE(ls_message_text || utl_tcp.CRLF || utl_tcp.CRLF ||
                                         lmir.email_custom_message || utl_tcp.CRLF || utl_tcp.CRLF ||
                                         lmir.email_signature || utl_tcp.CRLF || utl_tcp.CRLF ||
                                         ls_ps_text || utl_tcp.CRLF || utl_tcp.CRLF ||
                                         lmir.email_std_disclaimer, '<br>', utl_tcp.CRLF), '<BR>', utl_tcp.CRLF);

      ls_message_html := ls_message_html         || '<br><br>' ||
                         lmir.email_custom_message || '<br><br>' ||
                         lmir.email_signature      || '<br><br>' ||
                         ls_ps_html              || '<br><br>' ||
                         lmir.email_std_disclaimer || '</body></html>';
						
		ln_trans_id := NULL;
		ls_parent_email_addr := NULL;
		OPEN get_parent_ind FOR SELECT XAE.transmission_id, XAE.dest_email_addr
								  FROM XX_AR_EBL_TRANSMISSION XAE
								 WHERE XAE.status='SEND' AND XAE.transmission_type='EMAIL'
								   AND XAE.customer_id = lcir.customer_id
								   AND XAE.customer_doc_id = lmir.parent_doc_id
								   AND XAE.dest_email_addr = lmir.dest_email_addr
								   AND XAE.cust_acct_site_id = lmir.cust_acct_site_id
								   AND 0 = (SELECT COUNT(1)
											FROM XX_AR_EBL_FILE F
										   WHERE F.transmission_id=XAE.transmission_id
											 AND NVL(F.status,'X')<>'RENDERED')
								   AND 0 < (SELECT COUNT(1)
											FROM XX_AR_EBL_FILE F
										   WHERE F.transmission_id=XAE.transmission_id
											 AND NVL(F.status,'X')='RENDERED');			 
		LOOP
		FETCH get_parent_ind INTO ln_trans_id, ls_parent_email_addr;
		EXIT WHEN get_parent_ind%NOTFOUND;
		  ls_trans_ids := ls_trans_ids || lmir.transmission_id || ',' || ln_trans_id || ',';
		  ls_dest_email_addr := ls_dest_email_addr || lmir.dest_email_addr || ';'; 
		END LOOP;
        CLOSE get_parent_ind;
		
		IF ln_trans_id IS NULL
		THEN	  
		  ls_trans_ids := ls_trans_ids || lmir.transmission_id || ',';
		  ls_dest_email_addr := ls_dest_email_addr || lmir.dest_email_addr || ';';
		END IF;	  
		  
	 ls_zip_required := lmir.zip_required;
	 EXCEPTION WHEN OTHERS THEN
	  ls_error_message := SQLERRM;
	  put_log_line('  -- Errored Indirect: ' || ls_error_message);
	 END;
	
     ls_trans_ids := SUBSTR(ls_trans_ids,1,LENGTH(ls_trans_ids)-1);
	 FND_FILE.put_line(FND_FILE.LOG,'Indirect Multi Docs Transmission IDs:'||ls_trans_ids);
     ls_dest_email_addr := SUBSTR(ls_dest_email_addr,1,LENGTH(ls_dest_email_addr)-1);
	 FND_FILE.put_line(FND_FILE.LOG,'Indirect Multi Docs Transmission Email IDs:'||ls_dest_email_addr);	 
	 ls_update_trans_ids := '('||ls_trans_ids||')';
     BEGIN
      TRANSMIT_EMAIL(NULL, ls_trans_ids, p_smtp_server, p_smtp_port, p_from_name, ls_dest_email_addr, ls_subject, ls_message_html, ls_message_text, ls_zip_required, ls_status_detail);
      ls_upd_trans_status := 'UPDATE XX_AR_EBL_TRANSMISSION SET status=''SENT'', transmission_dt=SYSDATE, last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id, status_detail='''||ls_status_detail
	                          ||''' WHERE transmission_id IN '||ls_update_trans_ids;
							 
	  EXECUTE IMMEDIATE ls_upd_trans_status;
      COMMIT;
      put_log_line('  -- Mail Sent ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH:MI:SS AM'));
      IF ls_status_detail IS NOT NULL THEN
          put_log_line('     ' || ls_status_detail);
      END IF;
     EXCEPTION WHEN OTHERS THEN
      ls_error_message := SQLERRM;
      ls_upd_trans_error := 'UPDATE XX_AR_EBL_TRANSMISSION SET status=''ERROR'', status_detail='''||ls_error_message||''', last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id'
                            ||' WHERE transmission_id IN '||ls_update_trans_ids;
					
      EXECUTE IMMEDIATE ls_upd_trans_error; 							
      COMMIT;
      put_log_line('  -- Indirect Errored: ' || ls_error_message);
     END;	
    END LOOP; 
   END LOOP; 
   -- End Indirect Customer Loop  
   -- End of Merge cust docs loop Defect#NAIT-27146

  /* Commented for Defect#NAIT-27146 by Thilak CG on 21-MAY-2018
  FOR lr IN (SELECT X.* FROM (SELECT T.transmission_id, T.dest_email_addr, T.billing_dt_from, T.billing_dt,
                                     D.email_subject, D.email_std_message, D.email_custom_message, D.email_signature,
                                     D.email_std_disclaimer, D.email_logo_required, D.email_logo_file_name, M.zip_required,
                                     H.account_number, H.account_name, SUBSTR(H.orig_system_reference,1,8) aops_number
                                FROM XX_AR_EBL_TRANSMISSION T
                                JOIN XX_CDH_EBL_TRANSMISSION_DTL D
                                  ON T.customer_doc_id=D.cust_doc_id
                                JOIN XX_CDH_EBL_MAIN M
                                  ON T.customer_doc_id=M.cust_doc_id
                                JOIN HZ_CUST_ACCOUNTS_ALL H
                                  ON T.customer_id=H.cust_account_id
                               WHERE T.status='SEND' AND T.transmission_type='EMAIL'
                                 AND MOD(transmission_id,p_thread_count)=ln_thread_id
                                 AND T.org_id=FND_GLOBAL.org_id) X
                        WHERE 0=(SELECT COUNT(1)
                                   FROM XX_AR_EBL_FILE F
                                  WHERE F.transmission_id=X.transmission_id
                                    AND NVL(F.status,'X')<>'RENDERED')
                          AND 0<(SELECT COUNT(1)
                                   FROM XX_AR_EBL_FILE F
                                  WHERE F.transmission_id=X.transmission_id
                                    AND NVL(F.status,'X')='RENDERED')) LOOP BEGIN
  --End*/									
									
  --Added for Defect#NAIT-27146 by Thilak CG on 21-MAY-2018		
  FOR lr IN (SELECT X.* FROM (SELECT T.transmission_id, T.dest_email_addr, T.billing_dt_from, T.billing_dt,
                                     D.email_subject, D.email_std_message, D.email_custom_message, D.email_signature,
                                     D.email_std_disclaimer, D.email_logo_required, D.email_logo_file_name, M.zip_required,
                                     H.account_number, H.account_name, SUBSTR(H.orig_system_reference,1,8) aops_number
                                FROM XX_AR_EBL_TRANSMISSION T
                                JOIN XX_CDH_EBL_TRANSMISSION_DTL D
                                  ON T.customer_doc_id=D.cust_doc_id
                                JOIN XX_CDH_EBL_MAIN M
                                  ON T.customer_doc_id=M.cust_doc_id
								 AND M.parent_doc_id IS NULL
                                JOIN HZ_CUST_ACCOUNTS_ALL H
                                  ON T.customer_id=H.cust_account_id
                               WHERE T.status='SEND' AND T.transmission_type='EMAIL'
							     AND MOD(transmission_id,p_thread_count)=ln_thread_id
                                 AND T.org_id=FND_GLOBAL.org_id) X
								WHERE 0=(SELECT COUNT(1)
										   FROM XX_AR_EBL_FILE F
										  WHERE F.transmission_id=X.transmission_id
											AND NVL(F.status,'X')<>'RENDERED')
								  AND 0<(SELECT COUNT(1)
										   FROM XX_AR_EBL_FILE F
										  WHERE F.transmission_id=X.transmission_id
											AND NVL(F.status,'X')='RENDERED')) LOOP BEGIN									
   --End
   
      put_log_line(' ');
      put_log_line('Sending transmission ' || lr.transmission_id || ' for account ' || lr.account_number || ': ' || lr.account_name);
      put_log_line('  to "' || lr.dest_email_addr || '"');

      ls_message_html := '';
      ls_status_detail := '';

      -- CR833 eBilling enhancement
      ls_subject := REPLACE(REPLACE(lr.email_subject,'&DATEFROM',TO_CHAR(lr.billing_dt_from, 'MM/DD/RRRR')),'&DATETO',TO_CHAR(lr.billing_dt, 'MM/DD/RRRR'));
      ls_subject := REPLACE(ls_subject,'&AOPSNUMBER',lr.aops_number);


      IF lr.email_logo_required='Y' AND lr.email_logo_file_name IS NOT NULL THEN
        get_logo_details(lr.email_logo_file_name, ls_logo_url, ls_hyperlink, ls_alt);
        IF ls_logo_url IS NOT NULL THEN
          IF ls_hyperlink IS NOT NULL THEN
            ls_message_html := ls_message_html || '<a href="' || ls_hyperlink || '"><img border=0 src="' || ls_logo_url || '" alt="' || ls_alt || '"></a><br><br>';
          ELSE
            ls_message_html := ls_message_html || '<img border=0 src="' || ls_logo_url || '" alt="' || ls_alt || '"><br><br>';
          END IF;
        END IF;
      END IF;
      ls_message_text := REPLACE(REPLACE(lr.email_std_message,'&DATEFROM',TO_CHAR(lr.billing_dt_from, 'MM/DD/RRRR')),'&DATETO',TO_CHAR(lr.billing_dt, 'MM/DD/RRRR'));
      ls_message_text := REPLACE(REPLACE(REPLACE(ls_message_text,'&ACCOUNTNUMBER',lr.account_number),'&ACCOUNTNAME',lr.account_name),'&AOPSNUMBER',lr.aops_number);
      ls_message_html := ls_message_html || ls_message_text;

      ls_message_text := REPLACE(REPLACE(ls_message_text || utl_tcp.CRLF || utl_tcp.CRLF ||
                                         lr.email_custom_message || utl_tcp.CRLF || utl_tcp.CRLF ||
                                         lr.email_signature || utl_tcp.CRLF || utl_tcp.CRLF ||
                                         ls_ps_text || utl_tcp.CRLF || utl_tcp.CRLF ||
                                         lr.email_std_disclaimer, '<br>', utl_tcp.CRLF), '<BR>', utl_tcp.CRLF);

      ls_message_html := ls_message_html         || '<br><br>' ||
                         lr.email_custom_message || '<br><br>' ||
                         lr.email_signature      || '<br><br>' ||
                         ls_ps_html              || '<br><br>' ||
                         lr.email_std_disclaimer || '</body></html>';

      TRANSMIT_EMAIL(lr.transmission_id, NULL, p_smtp_server, p_smtp_port, p_from_name, lr.dest_email_addr, ls_subject, ls_message_html, ls_message_text, lr.zip_required, ls_status_detail);
      UPDATE XX_AR_EBL_TRANSMISSION SET status='SENT', transmission_dt=SYSDATE, last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id, status_detail=ls_status_detail
      WHERE transmission_id=lr.transmission_id;

      COMMIT;
      put_log_line('  -- sent ' || TO_CHAR(SYSDATE,'DD-MON-RRRR HH:MI:SS AM'));
      IF ls_status_detail IS NOT NULL THEN
          put_log_line('     ' || ls_status_detail);
      END IF;
    EXCEPTION WHEN OTHERS THEN
      ls_error_message := SQLERRM;
      UPDATE XX_AR_EBL_TRANSMISSION SET status='ERROR', status_detail=ls_error_message, last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id
      WHERE transmission_id=lr.transmission_id;

      COMMIT;
      put_log_line('  -- errored: ' || ls_error_message);
    END;
  END LOOP;
END TRANSMIT_EMAIL_C;

PROCEDURE TRANSMIT_EMAIL_P (
    Errbuf            OUT NOCOPY VARCHAR2
   ,Retcode           OUT NOCOPY VARCHAR2
)
IS
  ln_thread_count     NUMBER;
  ls_smtp_server      VARCHAR2(240);
  ln_smtp_server_port PLS_INTEGER;
  ls_from_name        VARCHAR2(240);
  ls_subject          VARCHAR2(240);
  ls_message          VARCHAR2(240);
  ls_message_html     VARCHAR2(240);
  n_conc_request_id   NUMBER := NULL;
  ls_req_data         VARCHAR2(240);
  ln_request_id       NUMBER;        -- parent request id
  cnt_warnings        INTEGER := 0;
  cnt_errors          INTEGER := 0;
  request_status      BOOLEAN;
BEGIN
  ls_req_data := fnd_conc_global.request_data;
  ln_request_id := fnd_global.conc_request_id;

  IF ls_req_data IS NOT NULL THEN
    put_log_line( ' Back at beginning after spawing ' || ls_req_data || ' threads.');
    ln_thread_count := ls_req_data;

    IF ln_thread_count > 0 THEN
      put_log_line ( 'Checking child threads...');

      -- Check all child requests to see how they finished...
      FOR child_request_rec IN (SELECT request_id, status_code
                                  FROM fnd_concurrent_requests
                                 WHERE parent_request_id = ln_request_id) LOOP
         check_child_request(child_request_rec.request_id);
        IF ( child_request_rec.status_code = 'G' OR child_request_rec.status_code = 'X'
          OR child_request_rec.status_code ='D' OR child_request_rec.status_code ='T'  ) THEN
            cnt_warnings := cnt_warnings + 1;
        ELSIF ( child_request_rec.status_code = 'E' ) THEN
            cnt_errors := cnt_errors + 1;
        END IF;
      END LOOP; -- FOR child_request_rec

      IF cnt_errors > 0 THEN
        put_log_line( 'Setting completion status to ERROR.');
        request_status := fnd_concurrent.set_completion_status('ERROR', '');
      ELSIF cnt_warnings > 0 THEN
        put_log_line( 'Setting completion status to WARNING.');
        request_status := fnd_concurrent.set_completion_status('WARNING', '');
      ELSE
        put_log_line( 'Setting completion status to NORMAL.');
        request_status := fnd_concurrent.set_completion_status('NORMAL', '');
      END IF;
    END IF;

    RETURN; -- end of parent
  END IF;

  put_log_line('Flagging oversize transmissions...');
  SET_TOOBIG_TRANSMISSIONS_EMAIL;
  COMMIT;

  get_translations('AR_EBL_EMAIL_CONFIG','RESEND',ls_smtp_server, ln_smtp_server_port, ls_from_name, ls_subject, ls_message, ls_message_html);
  get_translation('AR_EBL_CONFIG','TRANSMIT_EMAIL','N_THREADS',ln_thread_count);

  put_log_line('Spawning ' || ln_thread_count || ' thread(s)...');

  FOR i IN 1..ln_thread_count LOOP
    put_log_line('thread: ' || i);
--  TRANSMIT_EMAIL_C(Errbuf,Retcode, i, ln_thread_count, ls_smtp_server, ln_smtp_server_port, ls_from_name);

    n_conc_request_id :=
      FND_REQUEST.submit_request
      ( application    => 'XXFIN'                      -- application short name
       ,program        => 'XX_AR_EBL_TRANSMIT_EMAIL_C' -- concurrent program name
       ,sub_request    => TRUE                         -- is this a sub-request?
       ,argument1      => i                            -- thread_id
       ,argument2      => ln_thread_count
       ,argument3      => ls_smtp_server
       ,argument4      => ln_smtp_server_port
       ,argument5      => ls_from_name);

    -- ===========================================================================
    -- if request was successful
    -- ===========================================================================
    IF (n_conc_request_id > 0) THEN
      -- ===========================================================================
      -- if a child request, then update it for concurrent mgr to process
      -- ===========================================================================
/*    -- Instead of doing the following Update, use FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status => 'PAUSED', request_data => to_char(ln_thread_count)) -- See below
      -- This program will then restart when the child programs are done, so if fnd_conc_global.request_data is NOT NULL at start of proc, check child statuses and end.
      -- If either this Update, or the set_req_globals approach, is not done, the child programs will hang in Invalid, No Manager status.

        UPDATE fnd_concurrent_requests
           SET phase_code = 'P',
               status_code = 'I'
         WHERE request_id = n_conc_request_id;
*/
      -- ===========================================================================
      -- must commit work so that the concurrent manager polls the request
      -- ===========================================================================
      COMMIT;

      put_log_line( ' Concurrent Request ID: ' || n_conc_request_id || '.' );

    -- ===========================================================================
    -- else errors have occured for request
    -- ===========================================================================
    ELSE
      -- ===========================================================================
      -- retrieve and raise any errors
      -- ===========================================================================
      FND_MESSAGE.raise_error;
    END IF;

  END LOOP;

  FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status => 'PAUSED', request_data => to_char(ln_thread_count));

END TRANSMIT_EMAIL_P;


PROCEDURE SET_TOOBIG_TRANSMISSIONS(
  p_transmission_type VARCHAR2
)
IS
  ls_max_size_file         VARCHAR2(240) := NULL;
  ls_max_size_transmission VARCHAR2(240) := NULL;
  ln_max_size_file         NUMBER        := NULL;
  ln_max_size_transmission NUMBER        := NULL;
BEGIN
  get_translation('AR_EBL_CONFIG','TRANSMIT_' || p_transmission_type,'MAX_SIZE_FILE_IN_BYTES'        ,ls_max_size_file);
  get_translation('AR_EBL_CONFIG','TRANSMIT_' || p_transmission_type,'MAX_SIZE_TRANSMISSION_IN_BYTES',ls_max_size_transmission);

  ln_max_size_file         := TO_NUMBER(ls_max_size_file);
  ln_max_size_transmission := TO_NUMBER(ls_max_size_transmission);

  -- max sizes are specified in bytes at translation level for fine control, but in MB at cust doc level for ease.
  -- 1 MB is 1048576 bytes, but we're going to multiply by 1000000 instead to give some wiggle room for the email body.

  UPDATE XX_AR_EBL_TRANSMISSION
     SET status='TOOBIG', last_updated_by=FND_GLOBAL.user_id, last_update_date=SYSDATE, last_update_login=FND_GLOBAL.login_id
   WHERE transmission_id IN (
         SELECT /*+ index(T XX_AR_EBL_TRANSMISSION_N2) index(M XX_CDH_EBL_MAIN__UIDX01) */  T.transmission_id
           FROM XX_AR_EBL_TRANSMISSION T
           JOIN XX_CDH_EBL_MAIN M
             ON T.customer_doc_id=M.cust_doc_id
          WHERE T.transmission_type=p_transmission_type and T.status='SEND'
            AND T.org_id=FND_GLOBAL.org_id
            AND (   (M.max_file_size  IS NOT NULL AND EXISTS (SELECT 1 FROM XX_AR_EBL_FILE F WHERE F.transmission_id=T.transmission_id AND DBMS_LOB.GETLENGTH(F.file_data) > M.max_file_size*1000000))
                 OR (ln_max_size_file IS NOT NULL AND EXISTS (SELECT 1 FROM XX_AR_EBL_FILE F WHERE F.transmission_id=T.transmission_id AND DBMS_LOB.GETLENGTH(F.file_data) > ln_max_size_file)))
          UNION

         SELECT /*+ index(T XX_AR_EBL_TRANSMISSION_N2) index(M XX_CDH_EBL_MAIN__UIDX01) */ T.transmission_id
           FROM XX_AR_EBL_TRANSMISSION T
           JOIN XX_CDH_EBL_MAIN M
             ON T.customer_doc_id=M.cust_doc_id
          WHERE T.transmission_type=p_transmission_type and T.status='SEND'
            AND T.org_id=FND_GLOBAL.org_id
            AND (   (M.max_transmission_size IS NOT NULL AND M.max_transmission_size*1000000<(SELECT SUM(DBMS_LOB.GETLENGTH(F.file_data))
                                                                                                FROM XX_AR_EBL_FILE F
                                                                                               WHERE T.transmission_id=F.transmission_id
                                                                                                 AND ((NVL(M.zip_required,'N')='Y' AND F.file_type='ZIP') OR (NVL(M.zip_required,'N')<>'Y' AND F.file_type<>'ZIP'))))

                 OR (ln_max_size_transmission IS NOT NULL AND ln_max_size_transmission<(SELECT SUM(DBMS_LOB.GETLENGTH(F.file_data))
                                                                                        FROM XX_AR_EBL_FILE F
                                                                                       WHERE T.transmission_id=F.transmission_id
                                                                                         AND ((NVL(M.zip_required,'N')='Y' AND F.file_type='ZIP') OR (NVL(M.zip_required,'N')<>'Y' AND F.file_type<>'ZIP'))))));


END SET_TOOBIG_TRANSMISSIONS;


PROCEDURE SET_TOOBIG_TRANSMISSIONS_EMAIL
IS
BEGIN
  SET_TOOBIG_TRANSMISSIONS('EMAIL');
END SET_TOOBIG_TRANSMISSIONS_EMAIL;


PROCEDURE SET_TOOBIG_TRANSMISSIONS_FTP
IS
BEGIN
  SET_TOOBIG_TRANSMISSIONS('FTP');
END SET_TOOBIG_TRANSMISSIONS_FTP;


PROCEDURE TRANSMISSIONS_TO_WRITE_TO_CD (
  x_cursor          OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN x_cursor FOR

    SELECT X.transmission_id,X.path,X.status,X.transmission_type
      FROM (SELECT T.transmission_id,
                   TO_CHAR(T.billing_dt,'RRRR-MM-DD') || '/' || T.account_number PATH,
                   T.status,
                   T.transmission_type,
                   (SELECT COUNT(1) FROM XX_AR_EBL_FILE F WHERE F.transmission_id=T.transmission_id AND NVL(F.status,'X')<>'RENDERED') not_ready_count
              FROM XX_AR_EBL_TRANSMISSION T
             WHERE T.status='TOOBIG' OR T.status='SEND'
               AND T.org_id=FND_GLOBAL.org_id) X
     WHERE (X.status='TOOBIG' OR X.transmission_type='CD')
       AND not_ready_count=0
     ORDER BY transmission_id;
END TRANSMISSIONS_TO_WRITE_TO_CD;

PROCEDURE SHOW_TRANSMISSIONS_TO_WRITE_CD
IS
    lc_transmissions     SYS_REFCURSOR;
    ln_transmission_id   NUMBER;
    ls_path              VARCHAR2(240);
    ls_status            VARCHAR2(100);
    ls_transmission_type VARCHAR2(100);
BEGIN
    TRANSMISSIONS_TO_WRITE_TO_CD(lc_transmissions);
    LOOP
      FETCH lc_transmissions INTO ln_transmission_id, ls_path, ls_status, ls_transmission_type;
      EXIT WHEN lc_transmissions%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE('transmission ' || ln_transmission_id || '   path: ' || ls_path || '   status: ' || ls_status || '   transmission_type: ' || ls_transmission_type);
    END LOOP;
    CLOSE lc_transmissions;
END SHOW_TRANSMISSIONS_TO_WRITE_CD;


PROCEDURE FILES_TO_WRITE_TO_CD (
  p_transmission_id  IN NUMBER
 ,x_cursor          OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN x_cursor FOR

  SELECT F.file_id
    FROM XX_AR_EBL_FILE F
    JOIN XX_AR_EBL_TRANSMISSION T
      ON F.transmission_id=T.transmission_id
    JOIN XX_CDH_EBL_MAIN M
      ON T.customer_doc_id=M.cust_doc_id
   WHERE F.transmission_id=p_transmission_id
     AND (   (M.zip_required='Y' AND F.file_type='ZIP')
          OR M.zip_required<>'Y')
   ORDER BY F.file_name;
END FILES_TO_WRITE_TO_CD;


PROCEDURE SHOW_FILES_TO_WRITE_CD
IS
    lc_transmissions     SYS_REFCURSOR;
    lc_files             SYS_REFCURSOR;
    ln_transmission_id   NUMBER;
    ln_file_id           NUMBER;
    ls_path              VARCHAR2(240);
    ls_status            VARCHAR2(100);
    ls_transmission_type VARCHAR2(100);
BEGIN
    TRANSMISSIONS_TO_WRITE_TO_CD(lc_transmissions);
    LOOP
      FETCH lc_transmissions INTO ln_transmission_id, ls_path, ls_status, ls_transmission_type;
      EXIT WHEN lc_transmissions%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE('transmission ' || ln_transmission_id || '   path: ' || ls_path || '   status: ' || ls_status || '   transmission_type: ' || ls_transmission_type);

      FILES_TO_WRITE_TO_CD(ln_transmission_id,lc_files);
      LOOP
        FETCH lc_files INTO ln_file_id;
        EXIT WHEN lc_files%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('  file_id: ' || ln_file_id);
      END LOOP;

    END LOOP;
    CLOSE lc_transmissions;
END SHOW_FILES_TO_WRITE_CD;


PROCEDURE TRANSMISSIONS_TO_FTP (
   x_cursor          OUT SYS_REFCURSOR
  ) IS
BEGIN
    OPEN x_cursor FOR

    SELECT X.transmission_id,lower(X.ftp_direction) ftp_direction, X.account_number, X.cust_doc_id
      FROM (SELECT T.transmission_id, D.ftp_direction, T.account_number, D.cust_doc_id
                  ,(SELECT COUNT(1) FROM XX_AR_EBL_FILE F 
				     WHERE F.transmission_id=T.transmission_id 
					   AND NVL(F.status,'X')<>'RENDERED' AND F.file_type <> 'STUB') not_ready_count -- File_type condition added for Defect#44331 by Thilak CG on  19-MAR-2018
              FROM XX_AR_EBL_TRANSMISSION T
              JOIN XX_CDH_EBL_TRANSMISSION_DTL D
                ON T.customer_doc_id=D.cust_doc_id
             WHERE T.status='SEND' AND transmission_type='FTP'
               AND T.org_id=FND_GLOBAL.org_id) X
     WHERE not_ready_count=0;
END TRANSMISSIONS_TO_FTP;

PROCEDURE SHOW_TRANSMISSIONS_TO_FTP
IS
    lc_transmissions   SYS_REFCURSOR;
    ln_transmission_id NUMBER;
    ls_ftp_direction   VARCHAR2(10);
    ls_account_number  VARCHAR2(30);
    ln_cust_doc_id     NUMBER;
BEGIN
    TRANSMISSIONS_TO_FTP(lc_transmissions);
    LOOP
      FETCH lc_transmissions INTO ln_transmission_id, ls_ftp_direction, ls_account_number, ln_cust_doc_id;
      EXIT WHEN lc_transmissions%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE('transmission ' || ln_transmission_id || '   ftp_direction: ' || ls_ftp_direction || '   account_number: ' || ls_account_number || '   cust_doc_id: ' || ln_cust_doc_id);
    END LOOP;
    CLOSE lc_transmissions;
END SHOW_TRANSMISSIONS_TO_FTP;



PROCEDURE FILES_TO_FTP (
    p_transmission_id  IN NUMBER
   ,x_cursor          OUT SYS_REFCURSOR
) IS
BEGIN
  OPEN x_cursor FOR

  SELECT F.file_id, F.file_name, F.file_data
    FROM XX_AR_EBL_FILE F
    JOIN XX_AR_EBL_TRANSMISSION T
      ON T.transmission_id=F.transmission_id
    JOIN XX_CDH_EBL_MAIN M
      ON T.customer_doc_id=M.cust_doc_id
   WHERE T.transmission_id=p_transmission_id
     AND (   (M.zip_required='Y' AND file_type='ZIP')
          OR M.zip_required<>'Y');
END FILES_TO_FTP;

PROCEDURE SHOW_FILES_TO_FTP
IS
    lc_transmissions   SYS_REFCURSOR;
    lc_files           SYS_REFCURSOR;
    ln_transmission_id NUMBER;
    ls_ftp_direction   VARCHAR2(10);
    ls_account_number  VARCHAR2(30);
    ln_cust_doc_id     NUMBER;
    ln_file_id         XX_AR_EBL_FILE.file_id%TYPE;
    ls_file_name       XX_AR_EBL_FILE.file_name%TYPE;
    lb_file_data       XX_AR_EBL_FILE.file_data%TYPE;
BEGIN
    TRANSMISSIONS_TO_FTP(lc_transmissions);
    LOOP
      FETCH lc_transmissions INTO ln_transmission_id, ls_ftp_direction, ls_account_number, ln_cust_doc_id;
      EXIT WHEN lc_transmissions%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE('transmission ' || ln_transmission_id || '   ftp_direction: ' || ls_ftp_direction || '   account_number: ' || ls_account_number || '   cust_doc_id: ' || ln_cust_doc_id);

      FILES_TO_FTP(ln_transmission_id,lc_files);
      LOOP
        FETCH lc_files INTO ln_file_id,ls_file_name,lb_file_data;
        EXIT WHEN lc_files%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('  file_id ' || ln_file_id || ' --> ' || ls_file_name);
      END LOOP;
      CLOSE lc_files;
    END LOOP;
    CLOSE lc_transmissions;
END SHOW_FILES_TO_FTP;


PROCEDURE FTP_PATHS (
  x_cursor          OUT SYS_REFCURSOR
 ,x_org_id          OUT VARCHAR2
)
IS
BEGIN
  x_org_id := FND_GLOBAL.org_id;

  OPEN x_cursor FOR

    SELECT X.account_number || ' ' || D.cust_doc_id || ' ' || NVL(TRIM(D.ftp_destination_folder),'./') line
      FROM XX_CDH_EBL_MAIN M
      JOIN XX_CDH_EBL_TRANSMISSION_DTL D
        ON M.cust_doc_id=D.cust_doc_id
      JOIN (SELECT DISTINCT T.customer_doc_id, T.account_number FROM XX_AR_EBL_TRANSMISSION T WHERE (status='STAGED' or status='SEND') AND transmission_type='FTP' AND T.org_id=FND_GLOBAL.org_id) X
        ON M.cust_doc_id=X.customer_doc_id
     WHERE D.ftp_direction='PUSH'
    ORDER BY line;
END FTP_PATHS;

PROCEDURE SHOW_FTP_PATHS
IS
    lc_paths   SYS_REFCURSOR;
    ls_line    VARCHAR2(1000);
    ls_org_id  VARCHAR2(100);
BEGIN
    FTP_PATHS(lc_paths, ls_org_id);
    DBMS_OUTPUT.PUT_LINE('ORG: ' || ls_org_id);
    LOOP
      FETCH lc_paths INTO ls_line;
      EXIT WHEN lc_paths%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(ls_line);
    END LOOP;
    CLOSE lc_paths;
END SHOW_FTP_PATHS;


PROCEDURE FTP_CONFIG (
    p_host           OUT VARCHAR2
   ,p_port           OUT VARCHAR2
   ,p_user           OUT VARCHAR2
  )
IS
  ls_x VARCHAR2(240);
  ls_y VARCHAR2(240);
  ls_z VARCHAR2(240);
BEGIN
   get_translations('AR_EBL_FTP_CONFIG','TRANSMIT',p_host, p_port, p_user, ls_x, ls_y, ls_z);
END FTP_CONFIG;


PROCEDURE FTP_STAGED_PUSH_CUST_DOCS (
    x_cursor         OUT SYS_REFCURSOR
  )
IS
BEGIN
  OPEN x_cursor FOR

  SELECT DISTINCT T.customer_doc_id, H.account_number, H.account_name
    FROM XX_AR_EBL_TRANSMISSION T
    JOIN HZ_CUST_ACCOUNTS_ALL H
      ON T.customer_id=H.cust_account_id
    JOIN XX_CDH_EBL_TRANSMISSION_DTL D
      ON T.customer_doc_id=D.cust_doc_id
   WHERE T.status='STAGED'
     AND T.org_id=FND_GLOBAL.org_id
     AND D.ftp_direction='PUSH'
  ORDER BY T.customer_doc_id;
END FTP_STAGED_PUSH_CUST_DOCS;


PROCEDURE FTP_STAGED_PULL_ACCOUNTS (
    x_cursor         OUT SYS_REFCURSOR
  )
IS
BEGIN
  OPEN x_cursor FOR

  SELECT DISTINCT H.account_number, H.account_name
    FROM XX_AR_EBL_TRANSMISSION T
    JOIN HZ_CUST_ACCOUNTS_ALL H
      ON T.customer_id=H.cust_account_id
    JOIN XX_CDH_EBL_TRANSMISSION_DTL D
      ON T.customer_doc_id=D.cust_doc_id
   WHERE T.status='STAGED'
     AND T.org_id=FND_GLOBAL.org_id
     AND D.ftp_direction='PULL'
  ORDER BY H.account_number;
END FTP_STAGED_PULL_ACCOUNTS;


PROCEDURE UPDATE_FTP_PUSH_STATUS (
    p_account_number HZ_CUST_ACCOUNTS_ALL.account_number%TYPE
   ,p_status         XX_AR_EBL_TRANSMISSION.status%TYPE
   ,p_status_detail  XX_AR_EBL_TRANSMISSION.status_detail%TYPE
)
IS
BEGIN
  UPDATE (SELECT T.*
            FROM XX_AR_EBL_TRANSMISSION T
            JOIN HZ_CUST_ACCOUNTS_ALL A
              ON T.customer_id=A.cust_account_id
            JOIN XX_CDH_EBL_TRANSMISSION_DTL D
              ON T.customer_doc_id=D.cust_doc_id
           WHERE T.transmission_type='FTP'
             AND T.status='STAGED'
             AND T.org_id=FND_GLOBAL.org_id
             AND D.ftp_direction='PULL'
             AND A.account_number=p_account_number) T
     SET T.status=p_status
        ,T.status_detail=p_status_detail
        ,T.transmission_dt=(CASE WHEN p_status='SENT' THEN SYSDATE ELSE NULL END)
        ,T.last_updated_by=fnd_global.user_id
        ,T.last_update_date=SYSDATE
        ,T.last_update_login=fnd_global.login_id;
END UPDATE_FTP_PUSH_STATUS;


PROCEDURE ARCHIVE_N_PURGE_FILES (
    Errbuf            OUT NOCOPY VARCHAR2
   ,Retcode           OUT NOCOPY VARCHAR2
)
IS
  ln_org_id number := FND_GLOBAL.org_id;
BEGIN
/* -- Do not delete zip rows, in case re-rendering is needed; just purge file_data
  DELETE
    FROM XX_AR_EBL_FILE
   WHERE file_id IN (SELECT F.file_id
                       FROM XX_AR_EBL_FILE F
                       JOIN XX_AR_EBL_TRANSMISSION T
                         ON T.transmission_id=F.transmission_id
                      WHERE (T.status='SENT' OR T.status='SENDBYCD')
                        AND T.org_id=ln_org_id
                        AND F.status='RENDERED'
                        AND F.file_type='ZIP');
*/
  UPDATE XX_AR_EBL_FILE
     SET status='PURGED',file_data=NULL,file_length=NULL
   WHERE file_id IN (SELECT F.file_id
                       FROM XX_AR_EBL_FILE F
                       JOIN XX_AR_EBL_TRANSMISSION T
                         ON T.transmission_id=F.transmission_id
                      WHERE (T.status='SENT' OR T.status='SENDBYCD')
                        AND T.org_id=ln_org_id
                        AND F.status='RENDERED'
                        AND F.file_type='ZIP');

  put_log_line('Purged file_data of ' || SQL%ROWCOUNT || ' ZIP rows from XX_AR_EBL_FILE.');

  UPDATE (SELECT F.status
          FROM XX_AR_EBL_FILE F
          JOIN XX_AR_EBL_TRANSMISSION T
            ON T.transmission_id=F.transmission_id
         WHERE (T.status='SENT' OR T.status='SENDBYCD')
           AND T.org_id=ln_org_id
           AND F.status='RENDERED')
   SET status='ARCHIVE';

  put_log_line('Updated status to ARCHIVE on ' || SQL%ROWCOUNT || ' XX_AR_EBL_FILE rows.');

  -- Update archive first, in case file was re-rendered
  UPDATE XX_AR_EBL_FILE_BLOB_ARCHIVE A
     SET file_data=(SELECT F.file_data FROM XX_AR_EBL_FILE F WHERE F.file_id=A.file_id AND F.org_id=ln_org_id)
   WHERE EXISTS (SELECT 1 FROM XX_AR_EBL_FILE F WHERE F.status='ARCHIVE' AND A.file_id=F.file_id AND F.org_id=ln_org_id);

  put_log_line('Updated ' || SQL%ROWCOUNT || ' rows in XX_AR_EBL_FILE_BLOB_ARCHIVE.' );

  INSERT
    INTO XX_AR_EBL_FILE_BLOB_ARCHIVE (file_id, file_data)
  SELECT F.file_id,F.file_data
    FROM XX_AR_EBL_FILE F
   WHERE F.status='ARCHIVE'
     AND F.org_id=ln_org_id
     AND NOT EXISTS (SELECT A.file_id FROM XX_AR_EBL_FILE_BLOB_ARCHIVE A WHERE A.file_id=F.file_id);

  put_log_line('Inserted ' || SQL%ROWCOUNT || ' rows into XX_AR_EBL_FILE_BLOB_ARCHIVE.' );

  UPDATE XX_AR_EBL_FILE F
     SET status='PURGE_BLOB'
   WHERE file_id IN (SELECT F.file_id
                       FROM XX_AR_EBL_FILE F
                       JOIN XX_AR_EBL_FILE_BLOB_ARCHIVE A
                         ON F.file_id=A.file_id
                      WHERE F.status='ARCHIVE'
                        AND F.org_id=ln_org_id);

  put_log_line('Status updated to PURGE_BLOB on ' || SQL%ROWCOUNT || ' XX_AR_EBL_FILE rows.');

  UPDATE XX_AR_EBL_FILE
     SET status='ARCHIVED',file_data=NULL,file_length=dbms_lob.getlength(file_data)
   WHERE status='PURGE_BLOB'
     AND org_id=ln_org_id;

  put_log_line('Updated status to ARCHIVED and file_data to null on ' || SQL%ROWCOUNT || ' XX_AR_EBL_FILE rows.');

END ARCHIVE_N_PURGE_FILES;



PROCEDURE FETCH_ARCHIVED_BLOB_INTO_GT (
    p_file_id         IN NUMBER
)
IS
  s_file_name   XX_AR_EBL_FILE.file_name%TYPE;
  n_file_length XX_AR_EBL_FILE.file_length%TYPE;
  n_count       NUMBER;
BEGIN
  SELECT F.file_name,F.file_length INTO s_file_name,n_file_length FROM XX_AR_EBL_FILE F WHERE F.file_id=p_file_id;

  IF n_file_length IS NOT NULL THEN -- archived
    SELECT COUNT(1) INTO n_count FROM XX_AR_EBL_FILE_GT GT WHERE GT.file_id=p_file_id;

    IF n_count=0 THEN
      INSERT INTO XX_AR_EBL_FILE_GT (file_id,file_name,file_data)
      SELECT A.file_id,s_file_name,A.file_data FROM XX_AR_EBL_FILE_BLOB_ARCHIVE A WHERE A.file_id=p_file_id;
    END IF;
  END IF;
END FETCH_ARCHIVED_BLOB_INTO_GT;

PROCEDURE GET_FILE_DATA_CURSOR (
    p_file_id        IN  NUMBER
   ,x_cursor         OUT SYS_REFCURSOR
) IS
BEGIN
  FETCH_ARCHIVED_BLOB_INTO_GT(p_file_id);

  OPEN x_cursor FOR
  SELECT file_name,file_data FROM XX_AR_EBL_FILE WHERE file_id=p_file_id AND file_length IS NULL UNION ALL SELECT file_name,file_data FROM XX_AR_EBL_FILE_GT WHERE file_id=p_file_id;

END GET_FILE_DATA_CURSOR;


PROCEDURE GET_ORG_ID (
    x_org_id         OUT VARCHAR2
) IS
BEGIN
    SELECT FND_GLOBAL.org_id INTO x_org_id FROM DUAL;
END;

PROCEDURE TRANSMIT_BC_MERGE_PDF (
    p_smtp_server     IN VARCHAR2
   ,p_smtp_port       IN PLS_INTEGER
   ,p_from_name       IN VARCHAR2
)
IS
  ls_error_message      VARCHAR2(4000);
  ls_subject            VARCHAR2(300);
  ls_message_html       VARCHAR2(14000) := '<html><head></head><body>';
  ls_message_text       varchar2(14000);
  ls_logo_url           VARCHAR2(240);
  ls_hyperlink          VARCHAR2(240);
  ls_alt                VARCHAR2(240);
  ls_ps_text            VARCHAR2(240);
  ls_ps_html            VARCHAR2(240);
  ls_status_detail      VARCHAR2(4000);
  ls_dest_email_addr    VARCHAR2(5000);             
  ls_zip_required       VARCHAR2(5000);
  ls_upd_trans_error    VARCHAR2(32767);
  ls_parent_email_addr  VARCHAR2(9000);
  ls_file_names         VARCHAR2(5000);  
  ls_merge_file_name    VARCHAR2(500);
  ln_request_id         NUMBER;
  src_file              BFILE;
  dst_file              BLOB;
  lgh_file              BINARY_INTEGER;
  ln_merge_file_id      NUMBER;
  lc_phase              VARCHAR2(50);
  lc_status             VARCHAR2(50);
  lc_dev_phase          VARCHAR2(50);
  lc_dev_status         VARCHAR2(50);
  lc_message            VARCHAR2(50);
  l_req_return_status   BOOLEAN;
  ln_user_id            NUMBER          := NVL(FND_PROFILE.VALUE('USER_ID'), -1);
  ln_login_id           NUMBER          := NVL(FND_PROFILE.VALUE('LOGIN_ID'),-1);
  ln_conc_request_id    NUMBER          := NVL(FND_GLOBAL.CONC_REQUEST_ID,-1);
  ld_billing_dt         DATE;
  lc_aops_cust_number   VARCHAR2(30);
  ls_max_size_file      VARCHAR2(240) := NULL;
  ls_max_size_transmission     VARCHAR2(240) := NULL;
  ln_max_size_file      NUMBER        := NULL;
  ln_max_size_transmission     NUMBER        := NULL;
  ln_merge_file_created VARCHAR2(1) := NULL;
  ls_file_too_big       VARCHAR2(1) := NULL;
  ls_send_toobig_notif  VARCHAR2(240);
  ls_subject_toobig     VARCHAR2(240);
  ls_message_toobig     VARCHAR2(4000);
  lc_account_number     VARCHAR2(240);
  
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Start of TRANSMIT_BC_MERGE_PDF proc ');
  get_translation('AR_EBL_CONFIG','TRANSMIT_EMAIL','PS_TEXT',ls_ps_text);
  get_translation('AR_EBL_CONFIG','TRANSMIT_EMAIL','PS_HTML',ls_ps_html);
  
  get_translation('AR_EBL_CONFIG','TRANSMIT_EMAIL','MAX_SIZE_FILE_IN_BYTES',ls_max_size_file);
  get_translation('AR_EBL_CONFIG','TRANSMIT_EMAIL','MAX_SIZE_TRANSMISSION_IN_BYTES',ls_max_size_transmission);
  
  get_translation('AR_EBL_CONFIG','NOTIFY_CD','SEND_TO',ls_send_toobig_notif);

  ln_max_size_file         := TO_NUMBER(ls_max_size_file);
  ln_max_size_transmission := TO_NUMBER(ls_max_size_transmission);

  
  FOR lcr in (SELECT DISTINCT t.customer_id,m.cust_doc_id
                FROM xx_ar_ebl_transmission t,
                     xx_cdh_ebl_main m
               WHERE T.customer_doc_id=M.cust_doc_id
                 --AND M.parent_doc_id IS NOT NULL
                 AND T.status='SEND' 
                 AND T.transmission_type='EMAIL'
                 AND M.file_processing_method = '03'
                 AND T.org_id=FND_GLOBAL.org_id
                 AND EXISTS (SELECT 1 
				               FROM XX_CDH_CUST_ACCT_EXT_B 
                              WHERE n_ext_attr2 = T.customer_doc_id
                                AND c_ext_attr3 = 'ePDF'
								AND c_ext_attr1 = 'Consolidated Bill'
								AND c_ext_attr2 = 'Y'
                             -- AND c_ext_attr7 = 'Y' --direct or indirect
						   )                                                               
               AND 0=(SELECT COUNT(1)
                        FROM XX_AR_EBL_FILE F
                       WHERE F.transmission_id=T.transmission_id
                         AND NVL(F.status,'X')<>'RENDERED')
               AND 0<(SELECT COUNT(1)
                        FROM XX_AR_EBL_FILE F
                       WHERE F.transmission_id=T.transmission_id
                         AND NVL(F.status,'X')='RENDERED'
                         AND NVL(F.paydoc_flag,'X') = 'Y')
			   AND EXISTS (SELECT 1 
						    FROM HZ_CUSTOMER_PROFILES HCP
						   WHERE HCP.cust_account_id = M.cust_account_id 
							 AND HCP.site_use_id IS NULL
							 AND HCP.attribute6 IN ('B','Y')
						  )                               
             ) 
	LOOP
	  FND_FILE.put_line(FND_FILE.LOG,' Processing for Customer  '||lcr.customer_id);
	  ls_dest_email_addr   := NULL;            
	  ls_file_names        := NULL;  
	  ls_merge_file_name   := NULL;
	  ln_request_id        :=0;
	  dst_file             := EMPTY_BLOB();
	  lgh_file             := 0;
	  lc_phase             := NULL;
	  lc_status            := NULL;
	  lc_dev_phase         := NULL;
	  lc_dev_status        := NULL;
	  lc_message           := NULL;
	  l_req_return_status  := NULL;
	  ld_billing_dt        := NULL;
      lc_aops_cust_number  := NULL;
	  ln_merge_file_created := NULL;
	  ls_file_too_big      := NULL;
	  lc_account_number    := NULL;
	  
	  -- Finding the sequence to create merge file name
		BEGIN

			SELECT XX_AR_EBL_MERGE_PDF_BC_FILE_S.nextval
			  INTO ln_merge_file_id
			  FROM DUAL;
	  
		EXCEPTION
			WHEN OTHERS THEN
			  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error during fetching the sequence value : '||SQLERRM);
			  ln_merge_file_id := 1;
		END;
		
		BEGIN
			SELECT billing_dt,aops_customer_number,account_number 
		      INTO ld_billing_dt, lc_aops_cust_number, lc_account_number
			  FROM (SELECT billing_dt,aops_customer_number,account_number
			         FROM xx_ar_ebl_file XAEF
			WHERE cust_account_id = lcr.customer_id
			  AND cust_doc_id = lcr.cust_doc_id
			  AND paydoc_flag = 'Y'
			  AND file_type = 'PDF'
			  AND status = 'RENDERED'
			  AND EXISTS
			 (SELECT 1
				FROM XX_AR_EBL_TRANSMISSION XAET
			   WHERE status = 'SEND'
				 AND customer_doc_id = XAEF.cust_doc_id
				 AND XAET.transmission_id = XAEF.transmission_id)
				ORDER BY billing_dt)
			 WHERE ROWNUM = 1;
		EXCEPTION
			WHEN OTHERS THEN
			  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error during fetching billing date and aops number for cust doc id  : '||lcr.cust_doc_id||' Error: '||SQLERRM);
			  ln_merge_file_id := 1;
		END;

	  ls_merge_file_name := lc_aops_cust_number||'_'||lcr.cust_doc_id||'_'||ld_billing_dt||'_'||ln_merge_file_id||'.PDF';
	  
	  FND_FILE.put_line(FND_FILE.LOG,'Merge file name to be created is '||ls_merge_file_name||' for cust doc id '||lcr.cust_doc_id);

	  --
	  --Submitting Concurrent Request
	  --
	  ln_request_id := fnd_request.submit_request ( 
								application   => 'XXFIN', 
								program       => 'XXAREBLPDFMERGE',
								start_time    => sysdate, 
								sub_request   => FALSE
							   ,argument1     => ls_merge_file_name
							   ,argument2     => lcr.customer_id
							   ,argument3     => lcr.cust_doc_id);						   

	  COMMIT;
	  FND_FILE.put_line(FND_FILE.LOG,'ln_request_id '||ln_request_id ||'submitted for cust doc id '||lcr.cust_doc_id);
	  --working till here
	  IF ln_request_id = 0 THEN
		FND_FILE.put_line(FND_FILE.LOG,'Request Not Submitted due to "' || fnd_message.get || '". Cust doc id:'||lcr.cust_doc_id);
	  ELSE
		FND_FILE.put_line(FND_FILE.LOG,'The Program PROGRAM_1 submitted successfully – Request id :' || ln_request_id||'. Cust doc id:'||lcr.cust_doc_id);
	  END IF;
	  IF ln_request_id > 0 THEN
		LOOP
	 --
		  --To make process execution to wait for 1st program to complete
		  --
			 l_req_return_status :=
				fnd_concurrent.wait_for_request (request_id      => ln_request_id
												,INTERVAL        => 5 --interval Number of seconds to wait between checks
												,max_wait        => 60 --Maximum number of seconds to wait for the request completion
												 -- out arguments
												,phase           => lc_phase
												,STATUS          => lc_status
												,dev_phase       => lc_dev_phase
												,dev_status      => lc_dev_status
												,message         => lc_message
												);						
		  EXIT
		  WHEN UPPER (lc_phase) = 'COMPLETED' OR UPPER (lc_status) IN ('CANCELLED', 'ERROR', 'TERMINATED');
		END LOOP;
		--
		--
		IF UPPER (lc_phase) = 'COMPLETED' AND UPPER (lc_status) = 'ERROR' THEN
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'XXAREBLPDFMERGE completed in error while processing cust doc id:'||lcr.cust_doc_id||'.Oracle request id: '||ln_request_id ||' '||SQLERRM);
		ELSIF UPPER (lc_phase) = 'COMPLETED' AND UPPER (lc_status) = 'NORMAL' THEN
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'XXAREBLPDFMERGE request successful for request id: ' || ln_request_id||'. Cust doc id:'||lcr.cust_doc_id);
		ELSE
		  FND_FILE.put_line(FND_FILE.LOG,'XXAREBLPDFMERGE request failed while processing cust doc id:'||lcr.cust_doc_id||'. Oracle request id: ' || ln_request_id ||' '||SQLERRM);
		END IF;
	  END IF;
  
  
  -- below code working too
  
   src_file    :=  BFILENAME('XXFIN_MERGE_PDF_BC', ls_merge_file_name);
   
   IF (dbms_lob.fileexists(src_file) = 1 ) THEN
      
	   BEGIN
		  INSERT 
		    INTO xx_ar_ebl_merge_pdf_bc_file 
		         (merge_file_id, 
				  cust_account_id,
				  cust_doc_id,
				  merge_file_name,
				  merge_file_data,
				  request_id,
				  created_by,
				  creation_date,
				  last_updated_by,
				  last_update_date,
				  last_update_login)
		   VALUES (ln_merge_file_id,
		           lcr.customer_id,
				   lcr.cust_doc_id,
				   ls_merge_file_name,
				   empty_BLOB(),
				   ln_conc_request_id,
				   ln_user_id,
				   SYSDATE ,
				   ln_user_id ,
				   SYSDATE ,
				   ln_login_id);
		   COMMIT;
	   EXCEPTION
	   WHEN OTHERS THEN
	     FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while inserting record for cust doc id:'||lcr.cust_doc_id||' into XX_AR_EBL_MERGE_PDF_BC_FILE table  : '||Sqlerrm);
	   END;
	  
	   BEGIN	   
		   UPDATE xx_ar_ebl_merge_pdf_bc_file
			  SET merge_file_data  = EMPTY_BLOB()
			WHERE merge_file_id = ln_merge_file_id
			   RETURNING merge_file_data INTO dst_file;			   
	   EXCEPTION
	   WHEN OTHERS THEN
	     FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while updating merge file data for cust doc id:'||lcr.cust_doc_id||' in XX_AR_EBL_MERGE_PDF_BC_FILE table  : '||Sqlerrm);
	   END;
       
       FND_FILE.PUT_LINE(FND_FILE.LOG,'File processing has started for the merge file. Cust doc id:'||lcr.cust_doc_id);
	   DBMS_LOB.FILEOPEN(src_file, dbms_lob.file_readonly);
	   lgh_file := DBMS_LOB.GETLENGTH(src_file);
       DBMS_LOB.LOADFROMFILE(dst_file, src_file, lgh_file);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Updating the Original file into the table');
	   
	   BEGIN
		   UPDATE xx_ar_ebl_merge_pdf_bc_file
		   SET    merge_file_data    = dst_file
				 ,status             = 'COMPLETE'
		   WHERE  merge_file_id = ln_merge_file_id;
		   
		   ln_merge_file_created := 'Y';
	   
	   EXCEPTION
	   WHEN OTHERS THEN
	     FND_FILE.PUT_LINE(FND_FILE.LOG,'Error during updating merge file data. Cust doc id:'||lcr.cust_doc_id||' and merge_file_id '||ln_merge_file_id||'error:'||SQLERRM);
	   END;
	   
       FND_FILE.PUT_LINE(FND_FILE.LOG,'The file is being closed');
       DBMS_LOB.FILECLOSE(src_file);
       
	   COMMIT;
	   
	   /*Update TOO BIG transactions*/
	   
       -- max sizes are specified in bytes at translation level for fine control, but in MB at cust doc level for ease.
       -- 1 MB is 1048576 bytes, but we're going to multiply by 1000000 instead to give some wiggle room for the email body.
       BEGIN	  
		  UPDATE xx_ar_ebl_merge_pdf_bc_file
			 SET status='TOOBIG', 
			     error_message = 'TOOBIG',
				 last_updated_by=FND_GLOBAL.user_id, 
				 last_update_date=SYSDATE, 
				 last_update_login=FND_GLOBAL.login_id
		   WHERE merge_file_id = ln_merge_file_id
			 AND EXISTS (
				 SELECT 1
				   FROM XX_CDH_EBL_MAIN M
				  WHERE M.cust_doc_id = lcr.cust_doc_id
					AND (   (M.max_file_size  IS NOT NULL 
							AND EXISTS (SELECT 1 
										  FROM XX_AR_EBL_MERGE_PDF_BC_FILE F 
										 WHERE F.merge_file_id=ln_merge_file_id
										   AND DBMS_LOB.GETLENGTH(F.MERGE_FILE_DATA) > M.max_file_size*1000000)
										)
						 OR (ln_max_size_file IS NOT NULL 
						 AND EXISTS (SELECT 1 
										  FROM XX_AR_EBL_MERGE_PDF_BC_FILE F 
										 WHERE F.merge_file_id=ln_merge_file_id
										   AND DBMS_LOB.GETLENGTH(F.MERGE_FILE_DATA) > ln_max_size_file)))
				  UNION
				 SELECT 1
				   FROM XX_CDH_EBL_MAIN M
				  WHERE M.cust_doc_id = lcr.cust_doc_id
					AND (   (M.max_transmission_size IS NOT NULL 
							 AND M.max_transmission_size*1000000<(SELECT SUM(DBMS_LOB.GETLENGTH(F.MERGE_FILE_DATA))
																	FROM XX_AR_EBL_MERGE_PDF_BC_FILE F 
																   WHERE F.merge_file_id=ln_merge_file_id
																 ))

						 OR (ln_max_size_transmission IS NOT NULL AND ln_max_size_transmission<(SELECT DBMS_LOB.GETLENGTH(F.MERGE_FILE_DATA)
																	FROM XX_AR_EBL_MERGE_PDF_BC_FILE F 
																   WHERE F.merge_file_id=ln_merge_file_id
																 ))));
			IF SQL%ROWCOUNT > 0 THEN
			   ls_file_too_big := 'Y';
			   FND_FILE.PUT_LINE(FND_FILE.LOG,'Merge File Too BIG for Cust doc id:'||lcr.cust_doc_id||' and merge_file_id '||ln_merge_file_id);
			END IF;   
	   EXCEPTION
	   WHEN OTHERS THEN
	     FND_FILE.PUT_LINE(FND_FILE.LOG,'Error during updating Too BIG data. Cust doc id:'||lcr.cust_doc_id||' and merge_file_id '||ln_merge_file_id||'error:'||SQLERRM);
	   END;
	 /* End of check for too big transactions */
	 
	 ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Merge File Doesnot exist/Not created for customer account '||lcr.customer_id||'AOPS Number'
				   ||lc_aops_cust_number||' and cust doc id '||lcr.cust_doc_id);
		 ln_merge_file_created := 'N';
	 END IF;
     
	 IF ln_merge_file_created = 'Y' THEN
     
		 FOR lmr IN (SELECT X.* FROM ( SELECT  DISTINCT T.dest_email_addr, T.billing_dt_from, T.billing_dt,
														 D.email_subject, D.email_std_message, D.email_custom_message, D.email_signature,
														 D.email_std_disclaimer, D.email_logo_required, D.email_logo_file_name, M.zip_required,
														 H.account_number, H.account_name, SUBSTR(H.orig_system_reference,1,8) aops_number
													FROM XX_AR_EBL_TRANSMISSION T
													JOIN XX_CDH_EBL_TRANSMISSION_DTL D
													  ON T.customer_doc_id=D.cust_doc_id
													JOIN XX_CDH_EBL_MAIN M
													  ON T.customer_doc_id=M.cust_doc_id
													  AND M.file_processing_method = '03'
													  JOIN HZ_CUST_ACCOUNTS_ALL H
													  ON T.customer_id=H.cust_account_id
												   WHERE T.status='SEND' AND T.transmission_type='EMAIL'
													 and t.customer_id=lcr.customer_id
													 and m.cust_doc_id = lcr.cust_doc_id
													 AND T.org_id=FND_GLOBAL.org_id
													 AND EXISTS (SELECT 1 FROM XX_CDH_CUST_ACCT_EXT_B 
																   WHERE n_ext_attr2 = T.customer_doc_id 
																	 AND cust_account_id = lcr.customer_id 
																	 AND c_ext_attr3 = 'ePDF'
																	 --AND c_ext_attr7 = 'Y' --direct flag Y or N
																)) X
								 ) 
		 LOOP 
		 BEGIN                                                                                                                                   
		 
		  FND_FILE.put_line(FND_FILE.LOG,'Sending Merge transmission ' || --lmr.transmission_id || 
		  ' for account ' || lmr.account_number || ': ' || lmr.account_name ||'  to "' || lmr.dest_email_addr || '"'||' and Cust Doc Id: ' ||lcr.cust_doc_id);
		  ls_message_html := '';
		  ls_status_detail := '';
		  ls_dest_email_addr := lmr.dest_email_addr||';'||ls_dest_email_addr;
		  
		  FND_FILE.put_line(FND_FILE.LOG,'ls_dest_email_addr '||ls_dest_email_addr);

		  ls_subject := REPLACE(REPLACE(lmr.email_subject,'&DATEFROM',TO_CHAR(lmr.billing_dt_from, 'MM/DD/RRRR')),'&DATETO',TO_CHAR(lmr.billing_dt, 'MM/DD/RRRR'));
		  ls_subject := REPLACE(ls_subject,'&AOPSNUMBER',lmr.aops_number);
		  ls_subject := REPLACE(ls_subject,'Your Electronic Billing','Your Merged Electronic Billing');


		  IF lmr.email_logo_required='Y' AND lmr.email_logo_file_name IS NOT NULL THEN
			get_logo_details(lmr.email_logo_file_name, ls_logo_url, ls_hyperlink, ls_alt);
			IF ls_logo_url IS NOT NULL THEN
			  IF ls_hyperlink IS NOT NULL THEN
				ls_message_html := ls_message_html || '<a href="' || ls_hyperlink || '"><img border=0 src="' || ls_logo_url || '" alt="' || ls_alt || '"></a><br><br>';
			  ELSE
				ls_message_html := ls_message_html || '<img border=0 src="' || ls_logo_url || '" alt="' || ls_alt || '"><br><br>';
			  END IF;
			END IF;
		  END IF;
		  ls_message_text := REPLACE(REPLACE(lmr.email_std_message,'&DATEFROM',TO_CHAR(lmr.billing_dt_from, 'MM/DD/RRRR')),'&DATETO',TO_CHAR(lmr.billing_dt, 'MM/DD/RRRR'));
		  ls_message_text := REPLACE(REPLACE(REPLACE(ls_message_text,'&ACCOUNTNUMBER',lmr.account_number),'&ACCOUNTNAME',lmr.account_name),'&AOPSNUMBER',lmr.aops_number);
		  ls_message_html := ls_message_html || ls_message_text;

		  ls_message_text := REPLACE(REPLACE(ls_message_text || utl_tcp.CRLF || utl_tcp.CRLF ||
											 lmr.email_custom_message || utl_tcp.CRLF || utl_tcp.CRLF ||
											 lmr.email_signature || utl_tcp.CRLF || utl_tcp.CRLF ||
											 ls_ps_text || utl_tcp.CRLF || utl_tcp.CRLF ||
											 lmr.email_std_disclaimer, '<br>', utl_tcp.CRLF), '<BR>', utl_tcp.CRLF);

		  ls_message_html := ls_message_html         || '<br><br>' ||
							 lmr.email_custom_message || '<br><br>' ||
							 lmr.email_signature      || '<br><br>' ||
							 ls_ps_html              || '<br><br>' ||
							 lmr.email_std_disclaimer || '</body></html>';
																									
		  ls_zip_required := lmr.zip_required;
		  
		  ls_subject_toobig := 'OVERSIZE Merge File for Account '||lmr.account_number||' and Cust Doc Id '||lcr.cust_doc_id||' for the period ' || TO_CHAR(lmr.billing_dt_from, 'MM/DD/RRRR')||' to '||TO_CHAR(lmr.billing_dt, 'MM/DD/RRRR');
          ls_message_toobig := GET_MESSAGE('TOOBIG_MERGE_PDF', 'CUSTOMER',lmr.account_number, 'CUSTDOCID', lcr.cust_doc_id , 'BILLDATE', TO_CHAR(lmr.billing_dt, 'MM/DD/RRRR'), 'MERGEFILENAME',ls_merge_file_name );

		 EXCEPTION WHEN OTHERS THEN
		  ls_error_message := SQLERRM;
		  FND_FILE.put_line(FND_FILE.LOG,'  -- errored for Cust Doc ID '||lcr.cust_doc_id ||' and the error is: '||ls_error_message);
		 END;
		END LOOP; 
	   
		 ls_dest_email_addr := SUBSTR(ls_dest_email_addr,1,LENGTH(ls_dest_email_addr)-1);
		 -- Begin Modification for NAIT-101938 Smush functionality
		 IF LENGTH(ls_dest_email_addr) > 2000 
	     THEN 
          ls_dest_email_addr := SUBSTR(ls_dest_email_addr,1,2000);	 
	     END IF;
		 -- End Modification for NAIT-101938 Smush functionality
		 BEGIN
		  IF nvl(ls_file_too_big,'N') = 'Y' THEN
		    SEND_SIMPLE_EMAIL(p_smtp_server, p_smtp_port, p_from_name, ls_send_toobig_notif, ls_subject_toobig, ls_message_toobig);
		  ELSE
		     TRANSMIT_MERGE_PDF_EMAIL(ln_merge_file_id, p_smtp_server, p_smtp_port, p_from_name, ls_dest_email_addr, ls_subject, ls_message_html, ls_message_text, ls_zip_required, ls_status_detail);
		  END IF;
		  FND_FILE.put_line(FND_FILE.LOG,'After calling mail program');  
		  IF ls_status_detail IS NOT NULL THEN
			  FND_FILE.put_line(FND_FILE.LOG,'Error while sending mail:     ' || ls_status_detail||' for Cust Doc ID '||lcr.cust_doc_id);
			  BEGIN
			   UPDATE xx_ar_ebl_merge_pdf_bc_file
			   SET    transmission_dt    = SYSDATE
					 ,status             = 'MAIL_SEND_ERROR'
					 ,status_detail      =  ls_status_detail
					 ,dest_email_addr    =  ls_dest_email_addr
					 ,billing_dt         =  ld_billing_dt
			   WHERE  merge_file_id = ln_merge_file_id;
			   
				UPDATE XX_AR_EBL_TRANSMISSION 
				   SET status            = 'ERROR', 
					   transmission_dt   = SYSDATE, 
					   last_updated_by   = fnd_global.user_id, 
					   last_update_date  = SYSDATE, 
					   last_update_login = fnd_global.login_id, 
					   status_detail     = ls_status_detail
				 WHERE customer_id     = lcr.customer_id
				   AND customer_doc_id = lcr.cust_doc_id;		   
			  EXCEPTION
			  WHEN OTHERS THEN
				 FND_FILE.PUT_LINE(FND_FILE.LOG,'Error during updating details in merge pdf table for merge_file_id '||ln_merge_file_id||'error:'||SQLERRM);
			  END;
		  ELSE
			  FND_FILE.put_line(FND_FILE.LOG,'Merge Mail Sent for Cust Doc ID  '||lcr.cust_doc_id);
			  BEGIN
			   UPDATE xx_ar_ebl_merge_pdf_bc_file
			   SET    transmission_dt    = SYSDATE
					 ,status             = 'MAIL_SENT'
					 ,dest_email_addr    =  ls_dest_email_addr
					 ,billing_dt         =  ld_billing_dt
			   WHERE  merge_file_id = ln_merge_file_id;

				UPDATE XX_AR_EBL_TRANSMISSION 
				   SET status            = 'SENT', 
					   transmission_dt   = SYSDATE, 
					   last_updated_by   = fnd_global.user_id, 
					   last_update_date  = SYSDATE, 
					   last_update_login = fnd_global.login_id, 
					   status_detail     = ls_status_detail
				 WHERE customer_id     = lcr.customer_id
				   AND customer_doc_id = lcr.cust_doc_id;		   
			   
			  EXCEPTION
			  WHEN OTHERS THEN
				 FND_FILE.PUT_LINE(FND_FILE.LOG,'Error during updating details in merge pdf table for merge_file_id '||ln_merge_file_id||'error:'||SQLERRM);
			  END;
		  END IF;
		 EXCEPTION WHEN OTHERS THEN
		  ls_error_message := SQLERRM;
		  ls_upd_trans_error := 'UPDATE XX_AR_EBL_MERGE_PDF_BC_FILE SET status=''ERROR'', error_message='''||ls_error_message||''', last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id'
								||' WHERE merge_file_id IN '||ln_merge_file_id;
																					
		  EXECUTE IMMEDIATE ls_upd_trans_error;                                                                                                     
		  COMMIT;
		  dbms_output.put_line('  -- Direct Errored: ' || ls_error_message);
		 END;
	 END IF;
	 
COMMIT;	 
END LOOP;
EXCEPTION
WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error during processing procedure TRANSMIT_BC_MERGE_PDF: '||SQLERRM);
END TRANSMIT_BC_MERGE_PDF;

-- This is main transmission email delivery procedure to send an email to customer with all files for a particular transmission_id attached
PROCEDURE TRANSMIT_MERGE_PDF_EMAIL (
    p_merge_file_id   IN NUMBER
   ,p_smtp_server     IN VARCHAR2
   ,p_smtp_port       IN PLS_INTEGER
   ,p_from_name       IN VARCHAR2
   ,p_send_to         IN VARCHAR2
   ,p_subject         IN VARCHAR2
   ,p_message_html    IN VARCHAR2
   ,p_message_text    IN VARCHAR2
   ,p_send_zips       IN VARCHAR2
   ,x_status_detail   IN OUT VARCHAR2
)
IS
  conn utl_smtp.connection;
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
  a_file_id_array          STRINGARRAY   DEFAULT STRINGARRAY();
  file_id_in NUMBER;
  s_send_to_good_addresses XX_AR_EBL_TRANSMISSION.dest_email_addr%TYPE := NULL;
  lc_file_name             XX_AR_EBL_FILE.file_name%TYPE;
  lc_file_data             XX_AR_EBL_FILE.file_data%TYPE;
  ls_trans_values          VARCHAR2(10000);
  TYPE lcu_file_data       IS REF CURSOR;
  get_file_data            lcu_file_data;  
BEGIN

  v_reply := utl_smtp.open_connection( p_smtp_server, p_smtp_port, conn );
  v_reply := utl_smtp.helo( conn, p_smtp_server );
  v_reply := utl_smtp.mail( conn, p_from_name );

  -- logic to send e-mail to multiple To'd users separated by ';'
  v_temp := REPLACE(REPLACE(p_send_to,' ',''),',',';');
  IF (instr(v_temp,';') = 0) OR (instr(v_temp,';') < LENGTH(v_temp)) THEN
    v_temp := v_temp||';';
  END IF;
  v_pos := 1;
  WHILE (instr(v_temp,';',v_pos) > 0) LOOP
    v_name := substr(v_temp, v_pos, instr(substr(v_temp, v_pos),';')-1);
    v_pos := v_pos + instr(substr(v_temp, v_pos),';');

    v_reply := utl_smtp.rcpt(conn, v_name);

    v_reply_code := to_char(v_reply.code);
	IF v_reply.code = 250 THEN
		IF s_send_to_good_addresses IS NULL THEN
			s_send_to_good_addresses := v_name;
		ELSE
			s_send_to_good_addresses := s_send_to_good_addresses || ';' || v_name;
		END IF;
	ELSE
		x_status_detail := x_status_detail || 'Unable to send to ' || v_name || '(code' || v_reply.code || '); ';
	END IF;
  END LOOP;

  IF s_send_to_good_addresses IS NULL THEN
    utl_smtp.quit( conn );
    RAISE_APPLICATION_ERROR(-20735, 'Unable to add any recipients; check addresses: "' || p_send_to || '"  ' || x_status_detail);
  END IF;

  msg := 'Return-Path: '|| p_from_name|| utl_tcp.CRLF ||
         'Date: '|| TO_CHAR(systimestamp,'Dy, DD Mon YYYY HH24:MI:SS TZHTZM')|| utl_tcp.CRLF ||  --Changed for defect 8196
         'From: '|| p_from_name|| utl_tcp.CRLF ||
         'Subject: '|| p_subject || utl_tcp.CRLF ||
         'To: '|| s_send_to_good_addresses || utl_tcp.CRLF ||
--         'Cc: '|| cc_name || utl_tcp.CRLF ||
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
         p_message_text || utl_tcp.CRLF ||
         utl_tcp.CRLF ||
         '--MIME.Bound2' || utl_tcp.CRLF ||
         'Content-Type: text/html;'|| utl_tcp.CRLF ||
         'Content-Transfer_Encoding: 7bit'|| utl_tcp.CRLF ||
         utl_tcp.CRLF ||
         p_message_html || utl_tcp.CRLF ||
         '--MIME.Bound2--' || utl_tcp.CRLF ||
         utl_tcp.CRLF;

    utl_smtp.open_data(conn);
    utl_smtp.write_data( conn, msg );

    ls_trans_values := NULL; 	
    BEGIN
	 SELECT merge_file_name, merge_file_data
      INTO lc_file_name,lc_file_data
      from xx_ar_ebl_merge_pdf_bc_file
     WHERE merge_file_id = p_merge_file_id;
	EXCEPTION
        WHEN OTHERS THEN
		  FND_FILE.put_line(FND_FILE.LOG,'Error while fetching merge file data for emailing for merge file id '||p_merge_file_id||'Error:'|| SQLERRM);
          RAISE_APPLICATION_ERROR(-20737, 'Error while fetching merge file data for emailing ' || SQLERRM);
    END; 
    -- End
 	BEGIN				 
      FND_FILE.put_line(FND_FILE.LOG,'File Name:'||lc_file_name);
      utl_smtp.write_data( conn, '--MIME.Bound' || utl_tcp.CRLF);
      utl_smtp.write_data( conn, 'Content-Type: application/octet-stream; name="' || lc_file_name || '"' || utl_tcp.CRLF);
      utl_smtp.write_data( conn, 'Content-Disposition: attachment; filename="'    || lc_file_name || '"' || utl_tcp.CRLF);
      utl_smtp.write_data( conn, 'Content-Transfer-Encoding: base64' || utl_tcp.CRLF );
      utl_smtp.write_data( conn, utl_tcp.CRLF );

      v_length := dbms_lob.getlength(lc_file_data);

      --reset the offset
      v_offset := 1;
      v_buffer_size := 57; -- this is set to actual amt read by dbms_lob.read, so must reset from value of last attachment's partial read at end of blob.
      WHILE v_offset <= v_length LOOP
        dbms_lob.read( lc_file_data, v_buffer_size, v_offset, v_raw );
        utl_smtp.write_raw_data( conn, utl_encode.base64_encode(v_raw) );
        utl_smtp.write_data( conn, utl_tcp.CRLF );
        v_offset := v_offset + v_buffer_size;
      END LOOP;
      utl_smtp.write_data( conn, utl_tcp.CRLF );

      EXCEPTION
        WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
          utl_smtp.quit( conn );
          RAISE_APPLICATION_ERROR(-20736, 'UTL_SMTP transient or permanent error. ' || SQLERRM);
        WHEN OTHERS THEN
          utl_smtp.quit( conn );
          RAISE_APPLICATION_ERROR(-20737, 'UTL_SMTP other error. ' || SQLERRM);
      END;
  
  utl_smtp.write_data( conn, '--MIME.Bound--'); -- End MIME mail
  utl_smtp.write_data( conn, utl_tcp.crlf );
  utl_smtp.close_data( conn );
  utl_smtp.quit( conn );
END TRANSMIT_MERGE_PDF_EMAIL;

END XX_AR_EBL_TRANSMISSION_PKG;
/

SHOW ERROR;
EXIT;