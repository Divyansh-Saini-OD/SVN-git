create or replace 
PACKAGE BODY      xx_pa_pb_mail IS

-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PA_PB_MAIL.pks                                                    |
-- | Description      : Package spec for CR853 PLM Enhancement Mail Package                  |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========       =============    ========================                    |
-- |1.0        08-Oct-2010      Rama Dwibhashyam  Initial draft version                      |
-- +=========================================================================================+

  -- Return the next email address in the list of email addresses, separated
  -- by either a "," or a ";".  The format of mailbox may be in one of these:
  --   someone@some-domain
  --   "Someone at some domain" <someone@some-domain>
  --   Someone at some domain <someone@some-domain>
  FUNCTION get_address(addr_list IN OUT VARCHAR2) RETURN VARCHAR2 IS
    addr VARCHAR2(256);
    i    pls_integer;
    FUNCTION lookup_unquoted_char(str  IN VARCHAR2,
                  chrs IN VARCHAR2) RETURN pls_integer AS
      c            VARCHAR2(5);
      i            pls_integer;
      len          pls_integer;
      inside_quote BOOLEAN;
    BEGIN
       inside_quote := false;
       i := 1;
       len := length(str);
       WHILE (i <= len) LOOP
     c := substr(str, i, 1);
     IF (inside_quote) THEN
       IF (c = '"') THEN
         inside_quote := false;
       ELSIF (c = '\') THEN
         i := i + 1; -- Skip the quote character
       END IF;
       GOTO next_char;
     END IF;
     IF (c = '"') THEN
       inside_quote := true;
       GOTO next_char;
     END IF;
     IF (instr(chrs, c) >= 1) THEN
        RETURN i;
     END IF;
     <<next_char>>
     i := i + 1;
       END LOOP;
       RETURN 0;
    END;
  BEGIN
    addr_list := ltrim(addr_list);
    i := lookup_unquoted_char(addr_list, ',;');
    IF (i >= 1) THEN
      addr      := substr(addr_list, 1, i - 1);
      addr_list := substr(addr_list, i + 1);
    ELSE
      addr := addr_list;
      addr_list := '';
    END IF;
    i := lookup_unquoted_char(addr, '<');
    IF (i >= 1) THEN
      addr := substr(addr, i + 1);
      i := instr(addr, '>');
      IF (i >= 1) THEN
    addr := substr(addr, 1, i - 1);
      END IF;
    END IF;
    RETURN addr;
  END;
  -- Write a MIME header
  PROCEDURE write_mime_header(conn  IN OUT NOCOPY utl_smtp.connection,
                  name  IN VARCHAR2,
                  value IN VARCHAR2) IS
  BEGIN
    utl_smtp.write_data(conn, name || ': ' || value || utl_tcp.CRLF);
  END;
  -- Mark a message-part boundary.  Set <last> to TRUE for the last boundary.
  PROCEDURE write_boundary(conn  IN OUT NOCOPY utl_smtp.connection,
               last  IN            BOOLEAN DEFAULT FALSE) AS
  BEGIN
    IF (last) THEN
      utl_smtp.write_data(conn, LAST_BOUNDARY);
    ELSE
      utl_smtp.write_data(conn, FIRST_BOUNDARY);
    END IF;
  END;
  ------------------------------------------------------------------------
  PROCEDURE mail(sender     IN VARCHAR2,
         recipients IN VARCHAR2,
         cc_recipients IN VARCHAR2,
         subject    IN VARCHAR2,
         message    IN VARCHAR2) IS
    conn utl_smtp.connection;
  BEGIN
    conn := begin_mail(sender, recipients,cc_recipients, subject);
    write_text(conn, message);
    end_mail(conn);
  END;
  ------------------------------------------------------------------------
  FUNCTION begin_mail(sender     IN VARCHAR2,
              recipients IN VARCHAR2,
              cc_recipients IN VARCHAR2,
              subject    IN VARCHAR2,
              mime_type  IN VARCHAR2    DEFAULT 'text/plain',
              priority   IN PLS_INTEGER DEFAULT NULL)
              RETURN utl_smtp.connection IS
    conn utl_smtp.connection;
  BEGIN
    conn := begin_session;
    begin_mail_in_session(conn, sender, recipients,cc_recipients, subject, mime_type,
      priority);
    RETURN conn;
  END;
  ------------------------------------------------------------------------
  PROCEDURE write_text(conn    IN OUT NOCOPY utl_smtp.connection,
               message IN VARCHAR2) IS
  BEGIN
    utl_smtp.write_data(conn, message);
  END;
  ------------------------------------------------------------------------
  PROCEDURE write_mb_text(conn    IN OUT NOCOPY utl_smtp.connection,
              message IN            VARCHAR2) IS
  BEGIN
    utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw(message));
  END;
  ------------------------------------------------------------------------
  PROCEDURE write_raw(conn    IN OUT NOCOPY utl_smtp.connection,
              message IN RAW) IS
  BEGIN
    utl_smtp.write_raw_data(conn, message);
  END;
  ------------------------------------------------------------------------
  PROCEDURE attach_text(conn         IN OUT NOCOPY utl_smtp.connection,
            data         IN VARCHAR2,
            mime_type    IN VARCHAR2 DEFAULT 'text/plain',
            inline       IN BOOLEAN  DEFAULT TRUE,
            filename     IN VARCHAR2 DEFAULT NULL,
                last         IN BOOLEAN  DEFAULT FALSE) IS
  BEGIN
    begin_attachment(conn, mime_type, inline, filename);
    write_text(conn, data);
    end_attachment(conn, last);
  END;
  ------------------------------------------------------------------------
  PROCEDURE attach_base64(conn         IN OUT NOCOPY utl_smtp.connection,
              data         IN RAW,
              mime_type    IN VARCHAR2 DEFAULT 'application/octet',
              inline       IN BOOLEAN  DEFAULT TRUE,
              filename     IN VARCHAR2 DEFAULT NULL,
              last         IN BOOLEAN  DEFAULT FALSE) IS
    i   PLS_INTEGER;
    len PLS_INTEGER;
  BEGIN
    begin_attachment(conn, mime_type, inline, filename, 'base64');
    -- Split the Base64-encoded attachment into multiple lines
    i   := 1;
    len := utl_raw.length(data);
    WHILE (i < len) LOOP
       IF (i + MAX_BASE64_LINE_WIDTH < len) THEN
     utl_smtp.write_raw_data(conn,
        utl_encode.base64_encode(utl_raw.substr(data, i,
        MAX_BASE64_LINE_WIDTH)));
       ELSE
     utl_smtp.write_raw_data(conn,
       utl_encode.base64_encode(utl_raw.substr(data, i)));
       END IF;
       utl_smtp.write_data(conn, utl_tcp.CRLF);
       i := i + MAX_BASE64_LINE_WIDTH;
    END LOOP;
    end_attachment(conn, last);
  END;
  ------------------------------------------------------------------------
  PROCEDURE begin_attachment(conn         IN OUT NOCOPY utl_smtp.connection,
                 mime_type    IN VARCHAR2 DEFAULT 'text/plain',
                 inline       IN BOOLEAN  DEFAULT TRUE,
                 filename     IN VARCHAR2 DEFAULT NULL,
                 transfer_enc IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    write_boundary(conn);
    write_mime_header(conn, 'Content-Type', mime_type);
    IF (filename IS NOT NULL) THEN
       IF (inline) THEN
      write_mime_header(conn, 'Content-Disposition',
        'inline; filename="'||filename||'"');
       ELSE
      write_mime_header(conn, 'Content-Disposition',
        'attachment; filename="'||filename||'"');
       END IF;
    END IF;
    IF (transfer_enc IS NOT NULL) THEN
      write_mime_header(conn, 'Content-Transfer-Encoding', transfer_enc);
    END IF;
    utl_smtp.write_data(conn, utl_tcp.CRLF);
  END;
  ------------------------------------------------------------------------
  PROCEDURE end_attachment(conn IN OUT NOCOPY utl_smtp.connection,
               last IN BOOLEAN DEFAULT FALSE) IS
  BEGIN
    utl_smtp.write_data(conn, utl_tcp.CRLF);
    IF (last) THEN
      write_boundary(conn, last);
    END IF;
  END;
  ------------------------------------------------------------------------
  PROCEDURE end_mail(conn IN OUT NOCOPY utl_smtp.connection) IS
  BEGIN
    end_mail_in_session(conn);
    end_session(conn);
  END;
  ------------------------------------------------------------------------
  FUNCTION begin_session RETURN utl_smtp.connection IS
    conn utl_smtp.connection;
  BEGIN
    -- open SMTP connection
    conn := utl_smtp.open_connection(smtp_host, smtp_port);
    utl_smtp.helo(conn, smtp_domain);
    RETURN conn;
  END;
  ------------------------------------------------------------------------
  PROCEDURE begin_mail_in_session(conn       IN OUT NOCOPY utl_smtp.connection,
                  sender     IN VARCHAR2,
                  recipients IN VARCHAR2,
                  cc_recipients IN VARCHAR2,
                  subject    IN VARCHAR2,
                  mime_type  IN VARCHAR2  DEFAULT 'text/plain',
                  priority   IN PLS_INTEGER DEFAULT NULL) IS
    my_recipients VARCHAR2(32767) := recipients;
    my_cc_recipients VARCHAR2(32767) := cc_recipients ;
    my_sender     VARCHAR2(32767) := sender;
  BEGIN
    -- Specify sender's address (our server allows bogus address
    -- as long as it is a full email address (xxx@yyy.com).
    utl_smtp.mail(conn, get_address(my_sender));
    -- Specify recipient(s) of the email.
    WHILE (my_recipients IS NOT NULL) LOOP
      utl_smtp.rcpt(conn, get_address(my_recipients));
    END LOOP;
    -- Specify cc recipient(s) of the email.
    WHILE (my_cc_recipients IS NOT NULL) LOOP
      utl_smtp.rcpt(conn, get_address(my_cc_recipients));
    END LOOP;
    -- Start body of email
    utl_smtp.open_data(conn);
    -- Set "From" MIME header
    write_mime_header(conn, 'From', sender);
    -- Set "To" MIME header
    write_mime_header(conn, 'To', recipients);
    -- Set "Cc" MIME header
    write_mime_header(conn, 'Cc', cc_recipients);
    -- Set "Subject" MIME header
    write_mime_header(conn, 'Subject', subject);
    -- Set "Content-Type" MIME header
    write_mime_header(conn, 'Content-Type', mime_type);
    -- Set "X-Mailer" MIME header
    write_mime_header(conn, 'X-Mailer', MAILER_ID);
    -- Set priority:
    --   High      Normal       Low
    --   1     2     3     4     5
    IF (priority IS NOT NULL) THEN
      write_mime_header(conn, 'X-Priority', priority);
    END IF;
    -- Send an empty line to denotes end of MIME headers and
    -- beginning of message body.
    utl_smtp.write_data(conn, utl_tcp.CRLF);
    IF (mime_type LIKE 'multipart/mixed%') THEN
      write_text(conn, 'This is a multi-part message in MIME format.' ||
    utl_tcp.crlf);
    END IF;
  END;
  ------------------------------------------------------------------------
  PROCEDURE end_mail_in_session(conn IN OUT NOCOPY utl_smtp.connection) IS
  BEGIN
    utl_smtp.close_data(conn);
  END;
  ------------------------------------------------------------------------
  PROCEDURE end_session(conn IN OUT NOCOPY utl_smtp.connection) IS
  BEGIN
    utl_smtp.quit(conn);
  END;

PROCEDURE xx_attch_rpt(conn    IN OUT NOCOPY utl_smtp.connection,
		       p_filename IN VARCHAR2)
IS
  fil 			BFILE;
  file_len 		PLS_INTEGER;
  buf 			RAW(2100);
  amt 			BINARY_INTEGER := 672 * 3;  /* ensures proper format;  2016 */
  pos 			PLS_INTEGER := 1; /* pointer for each piece */
  filepos 		PLS_INTEGER := 1; /* pointer for the file */
  v_directory_name 	VARCHAR2(100) := 'XXMER_OUTBOUND';
  v_line 		VARCHAR2(1000);
  mesg 			VARCHAR2(32767);
  mesg_len 		NUMBER;
  crlf 			VARCHAR2(2) := chr(13) || chr(10);
  data 			RAW(2100);
  chunks 		PLS_INTEGER;
  len 			PLS_INTEGER := 1;
  modulo 		PLS_INTEGER;
  pieces 		PLS_INTEGER;
  err_num 		NUMBER;
  err_msg 		VARCHAR2(100);
  v_mime_type_bin 	varchar2(30) := 'application/pdf';
BEGIN
   xx_pa_pb_mail.begin_attachment(
  		  conn => conn,
		  mime_type => 'application/pdf',
	          inline => TRUE,
        	  filename => p_filename,
	          transfer_enc => 'base64');
   fil := BFILENAME(v_directory_name,p_filename);
   file_len := dbms_lob.getlength(fil);
   modulo := mod(file_len, amt);
   pieces := trunc(file_len / amt);
   if (modulo <> 0) then
       pieces := pieces + 1;
   end if;
   dbms_lob.fileopen(fil, dbms_lob.file_readonly);
   dbms_lob.read(fil, amt, filepos, buf);
   data := NULL;
   FOR i IN 1..pieces LOOP
         filepos := i * amt + 1;
         file_len := file_len - amt;
         data := utl_raw.concat(data, buf);
         chunks := trunc(utl_raw.length(data) / xx_pa_pb_mail.MAX_BASE64_LINE_WIDTH);
         IF (i <> pieces) THEN
             chunks := chunks - 1;
         END IF;
         xx_pa_pb_mail.write_raw( conn    => conn,
                                       message => utl_encode.base64_encode(data )
				     );
         data := NULL;
         if (file_len < amt and file_len > 0) then
             amt := file_len;
         end if;
         dbms_lob.read(fil, amt, filepos, buf);
   END LOOP;
   dbms_lob.fileclose(fil);
END xx_attch_rpt;
--
PROCEDURE xx_attch_sqlloader(conn    IN OUT NOCOPY utl_smtp.connection,
		       p_filename IN VARCHAR2)
IS
  fil 			BFILE;
  file_len 		PLS_INTEGER;
  buf 			RAW(2100);
  amt 			BINARY_INTEGER := 672 * 3;  /* ensures proper format;  2016 */
  pos 			PLS_INTEGER := 1; /* pointer for each piece */
  filepos 		PLS_INTEGER := 1; /* pointer for the file */
  v_directory_name 	VARCHAR2(1000) := '/tmp';--app/ebs/itgsidev02/ebs/';--'/app/ebs/itgsidev02/ebs/fs_ne/inst/GSIDEV02_choleba21d/logs/appl/conc/out/';--'XXMER_OUTBOUND';
  v_line 		VARCHAR2(1000);
  mesg 			VARCHAR2(32767);
  mesg_len 		NUMBER;
  crlf 			VARCHAR2(2) := chr(13) || chr(10);
  data 			RAW(2100);
  chunks 		PLS_INTEGER;
  len 			PLS_INTEGER := 1;
  modulo 		PLS_INTEGER;
  pieces 		PLS_INTEGER;
  err_num 		NUMBER;
  err_msg 		VARCHAR2(100);
  v_mime_type_bin 	varchar2(30) := 'application/pdf';
BEGIN
   xx_pa_pb_mail.begin_attachment(
  		  conn => conn,
		  mime_type => 'application/pdf',
	          inline => TRUE,
        	  filename => p_filename,
	          transfer_enc => 'base64');
   fil := BFILENAME(v_directory_name,p_filename);
   file_len := dbms_lob.getlength(fil);
   modulo := mod(file_len, amt);
   pieces := trunc(file_len / amt);
   if (modulo <> 0) then
       pieces := pieces + 1;
   end if;
   dbms_lob.fileopen(fil, dbms_lob.file_readonly);
   dbms_lob.read(fil, amt, filepos, buf);
   data := NULL;
   FOR i IN 1..pieces LOOP
         filepos := i * amt + 1;
         file_len := file_len - amt;
         data := utl_raw.concat(data, buf);
         chunks := trunc(utl_raw.length(data) / xx_pa_pb_mail.MAX_BASE64_LINE_WIDTH);
         IF (i <> pieces) THEN
             chunks := chunks - 1;
         END IF;
         xx_pa_pb_mail.write_raw( conn    => conn,
                                       message => utl_encode.base64_encode(data )
				     );
         data := NULL;
         if (file_len < amt and file_len > 0) then
             amt := file_len;
         end if;
         dbms_lob.read(fil, amt, filepos, buf);
   END LOOP;
   dbms_lob.fileclose(fil);
END xx_attch_sqlloader;


PROCEDURE xx_attach_excel(conn    IN OUT NOCOPY utl_smtp.connection,
		       p_filename IN VARCHAR2)
IS
  pos 			PLS_INTEGER := 1; /* pointer for each piece */
  v_directory_name 	VARCHAR2(100) := 'XXMER_OUTBOUND';
  data 			RAW(2100);
  err_num 		NUMBER;
  err_msg 		VARCHAR2(100);
  v_mime_type_bin 	varchar2(30) := 'application/vnd.ms-excel';

  bfile_handle 	BFILE;
  bfile_len 	NUMBER;
  read_bytes 	NUMBER;
  line 		VARCHAR2 (1000);

BEGIN

   xx_pa_pb_mail.begin_attachment(
  		  conn => conn,
		  mime_type => 'application/vnd.ms-excel',
	          inline => TRUE,
        	  filename => p_filename,
	          transfer_enc => 'base64');

  bfile_handle := BFILENAME(v_directory_name,p_filename);
  bfile_len := DBMS_LOB.getlength (bfile_handle);
  pos := 1;
  DBMS_LOB.OPEN (bfile_handle, DBMS_LOB.lob_readonly);

-- Append the file contents to the end of the message

  LOOP
  -- If it is a binary file, process it 57 bytes at a time,
  -- reading them in with a LOB read, encoding them in BASE64,
  -- and writing out the encoded binary string as raw data

       IF pos + 57 - 1 > bfile_len  THEN
          read_bytes := bfile_len - pos + 1;
       ELSE
          read_bytes := 57;
       END IF;

       DBMS_LOB.READ (bfile_handle, read_bytes, pos, DATA);
        xx_pa_pb_mail.write_raw( conn    => conn,
                                       message => utl_encode.base64_encode(data )
				     );

       pos := pos + 57;

       IF pos > bfile_len THEN
          EXIT;
       END IF;

  END LOOP;
  DBMS_LOB.CLOSE (bfile_handle);
  xx_pa_pb_mail.end_attachment(conn => conn);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    err_num := SQLCODE;
    err_msg := SQLERRM;
    DBMS_OUTPUT.put_line ('Error code ' || err_num || ': ' || err_msg);
END xx_attach_excel;


PROCEDURE xx_email_excel(conn      IN OUT NOCOPY utl_smtp.connection,
                     p_directory IN VARCHAR2,
                     p_filename IN VARCHAR2)
IS

  pos 			PLS_INTEGER := 1; /* pointer for each piece */
  data 			RAW(2100);
  err_num 		NUMBER;
  err_msg 		VARCHAR2(100);
  v_mime_type_bin 	varchar2(30) := 'application/vnd.ms-excel';

  bfile_handle 	BFILE;
  bfile_len 	NUMBER;
  read_bytes 	NUMBER;
  line 		VARCHAR2 (1000);

BEGIN

   xx_pa_pb_mail.begin_attachment(
  		  conn => conn,
		  mime_type => 'application/vnd.ms-excel',
	          inline => TRUE,
        	  filename => p_filename,
	          transfer_enc => 'base64');

  bfile_handle := BFILENAME(p_directory,p_filename);
  bfile_len := DBMS_LOB.getlength (bfile_handle);
  pos := 1;
  DBMS_LOB.OPEN (bfile_handle, DBMS_LOB.lob_readonly);

-- Append the file contents to the end of the message

  LOOP
  -- If it is a binary file, process it 57 bytes at a time,
  -- reading them in with a LOB read, encoding them in BASE64,
  -- and writing out the encoded binary string as raw data

       IF pos + 57 - 1 > bfile_len  THEN
          read_bytes := bfile_len - pos + 1;
       ELSE
          read_bytes := 57;
       END IF;

       DBMS_LOB.READ (bfile_handle, read_bytes, pos, DATA);
        xx_pa_pb_mail.write_raw( conn    => conn,
                                       message => utl_encode.base64_encode(data )
				     );

       pos := pos + 57;

       IF pos > bfile_len THEN
          EXIT;
       END IF;

  END LOOP;
  DBMS_LOB.CLOSE (bfile_handle);
  xx_pa_pb_mail.end_attachment(conn => conn);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    err_num := SQLCODE;
    err_msg := SQLERRM;
    DBMS_OUTPUT.put_line ('Error code ' || err_num || ': ' || err_msg);
END xx_email_excel;

PROCEDURE xx_email_zip(conn      IN OUT NOCOPY utl_smtp.connection,
                     p_directory IN VARCHAR2,
                     p_filename IN VARCHAR2)
IS

  pos 			PLS_INTEGER := 1; /* pointer for each piece */
  data 			RAW(2100);
  err_num 		NUMBER;
  err_msg 		VARCHAR2(100);
  v_mime_type_bin 	varchar2(30) := 'application/vnd.ms-excel';

  bfile_handle 	BFILE;
  bfile_len 	NUMBER;
  read_bytes 	NUMBER;
  line 		VARCHAR2 (1000);

BEGIN

   xx_pa_pb_mail.begin_attachment(
  		  conn => conn,
		  mime_type => 'application/vnd.ms-excel',
	          inline => TRUE,
        	  filename => p_filename,
	          transfer_enc => 'base64');

  bfile_handle := BFILENAME(p_directory,p_filename);
  bfile_len := DBMS_LOB.getlength (bfile_handle);
  pos := 1;
  DBMS_LOB.OPEN (bfile_handle, DBMS_LOB.lob_readonly);

-- Append the file contents to the end of the message

  LOOP
  -- If it is a binary file, process it 57 bytes at a time,
  -- reading them in with a LOB read, encoding them in BASE64,
  -- and writing out the encoded binary string as raw data

       IF pos + 57 - 1 > bfile_len  THEN
          read_bytes := bfile_len - pos + 1;
       ELSE
          read_bytes := 57;
       END IF;

       DBMS_LOB.READ (bfile_handle, read_bytes, pos, DATA);
        xx_pa_pb_mail.write_raw( conn    => conn,
                                       message => utl_encode.base64_encode(data )
				     );

       pos := pos + 57;

       IF pos > bfile_len THEN
          EXIT;
       END IF;

  END LOOP;
  DBMS_LOB.CLOSE (bfile_handle);
  xx_pa_pb_mail.end_attachment(conn => conn);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    err_num := SQLCODE;
    err_msg := SQLERRM;
    DBMS_OUTPUT.put_line ('Error code ' || err_num || ': ' || err_msg);
END xx_email_zip;


PROCEDURE xx_attch_doc(conn    IN OUT NOCOPY utl_smtp.connection,
		       p_filename IN VARCHAR2,
		       p_blob in BLOB,p_mime_type IN VARCHAR2)
IS
i 		number;
len 		number;
BEGIN
  xx_pa_pb_mail.begin_attachment(
  	  conn => conn,
	  mime_type => p_mime_type,
          inline => TRUE,
          filename => p_filename,
          transfer_enc => 'base64');
  i := 1;
  len := DBMS_LOB.getLength(p_blob);
  WHILE (i < len) LOOP
    IF(i + xx_pa_pb_mail.MAX_BASE64_LINE_WIDTH <len)THEN
        UTL_SMTP.Write_Raw_Data (conn,
        UTL_ENCODE.Base64_Encode(DBMS_LOB.Substr(p_blob,xx_pa_pb_mail.MAX_BASE64_LINE_WIDTH, i)));
    ELSE
        UTL_SMTP.Write_Raw_Data (conn,
        UTL_ENCODE.Base64_Encode(DBMS_LOB.Substr(p_blob, (len - i)+1, i)));
    END IF;
    UTL_SMTP.Write_Data(conn, UTL_TCP.CRLF);
    i := i + xx_pa_pb_mail.MAX_BASE64_LINE_WIDTH;
  END LOOP;
END xx_attch_doc;
end;

/