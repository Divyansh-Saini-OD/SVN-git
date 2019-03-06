SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace PACKAGE BODY XX_OM_EMAIL_HANDLER_OUT IS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XX_OM_EMAIL_HANDLER_OUT.PKB                                   |
-- | Description      : Package Specification                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   16-AUG-2009   Bala          Initial draft version       |
-- |                                                                   |
-- +===================================================================+

 -- Return the next email address in the list of email addresses, separated
 -- by either a "," or a ";". The format of mailbox may be in one of these:
 -- someone@some-domain
 -- "Someone at some domain" <someone@some-domain>
 -- Someone at some domain <someone@some-domain>
 FUNCTION get_address(addr_list IN OUT VARCHAR2) RETURN VARCHAR2 IS
 addr VARCHAR2(256);
 i pls_integer;
 FUNCTION lookup_unquoted_char(str IN VARCHAR2,
				 chrs IN VARCHAR2) RETURN pls_integer AS
 c VARCHAR2(5);
 i pls_integer;
 len pls_integer;
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
		 addr := substr(addr_list, 1, i - 1);
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
----------------------------------------------------------------------------
 PROCEDURE write_mime_header(conn IN OUT NOCOPY utl_smtp.connection,
			 name IN VARCHAR2,
			 value IN VARCHAR2) IS
 BEGIN
 utl_smtp.write_data(conn, name || ': ' || value || utl_tcp.CRLF);
 END write_mime_header;

------------------------------------------------------------------------------
 -- Mark a message-part boundary. Set <last> to TRUE for the last boundary.
 PROCEDURE write_boundary(conn IN OUT NOCOPY utl_smtp.connection,
			 last IN BOOLEAN DEFAULT FALSE) AS
 BEGIN
	 IF (last) THEN
		 utl_smtp.write_data(conn, LAST_BOUNDARY);
	 ELSE
		 utl_smtp.write_data(conn, FIRST_BOUNDARY);
	 END IF;
 END write_boundary ;
 ------------------------------------------------------------------------
 PROCEDURE simple_mail(sender IN VARCHAR2
			 ,recipients IN VARCHAR2
			 ,subject IN VARCHAR2
			 ,message IN VARCHAR2) IS
 conn utl_smtp.connection;
 BEGIN
	 conn := begin_mail(sender, recipients, subject);
	 write_text(conn, message);
	 end_mail(conn);
 END simple_mail;
 ------------------------------------------------------------------------
 PROCEDURE mime_mail(	sender IN VARCHAR2
		 		,recipients IN VARCHAR2
				,subject IN VARCHAR2
				,mime_type IN VARCHAR2
				,message IN CLOB) IS 
 conn utl_smtp.connection;
 BEGIN
	 conn := begin_mail(sender, recipients, subject, mime_type);
	 write_text(conn, message);
	 end_mail(conn);
 EXCEPTION
	 when others then
	 end_mail(conn);
 END mime_mail;
 ------------------------------------------------------------------------
 FUNCTION begin_mail(sender IN VARCHAR2
				 ,recipients IN VARCHAR2
				 ,subject IN VARCHAR2
				 ,mime_type IN VARCHAR2 DEFAULT 'text/plain'
			       ,priority IN PLS_INTEGER DEFAULT NULL)
				 RETURN utl_smtp.connection IS
 conn utl_smtp.connection;
 BEGIN
	 conn := begin_session;
	 begin_mail_in_session(conn, sender, recipients, subject, mime_type,priority);
	 RETURN conn;
 END ;
 ------------------------------------------------------------------------
 PROCEDURE write_text(conn IN OUT NOCOPY utl_smtp.connection
					 ,message IN VARCHAR2) IS
 BEGIN
	 utl_smtp.write_data(conn, message);
 END write_text;
 ------------------------------------------------------------------------
 PROCEDURE write_mb_text(conn IN OUT NOCOPY utl_smtp.connection
			 		,message IN VARCHAR2) IS
 BEGIN
	 utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw(message));
 END write_mb_text;
 ------------------------------------------------------------------------
 PROCEDURE write_raw(conn IN OUT NOCOPY utl_smtp.connection
					 ,message IN RAW) IS
 BEGIN
	 utl_smtp.write_raw_data(conn, message);
 END write_raw;
 ------------------------------------------------------------------------
 PROCEDURE end_mail(conn IN OUT NOCOPY utl_smtp.connection) IS
 BEGIN
	 end_mail_in_session(conn);
	 end_session(conn);
 END end_mail;
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
 PROCEDURE begin_mail_in_session(conn IN OUT NOCOPY utl_smtp.connection
				 ,sender IN VARCHAR2
				 ,recipients IN VARCHAR2
				 ,subject IN VARCHAR2
				 ,mime_type IN VARCHAR2 DEFAULT 'text/plain'
				 ,priority IN PLS_INTEGER DEFAULT NULL) IS
	 my_recipients VARCHAR2(32767) := recipients;
	 my_sender VARCHAR2(32767) := sender;
 BEGIN
	 -- Specify sender's address (our server allows bogus address
	 -- as long as it is a full email address (xxx@yyy.com).
	 utl_smtp.mail(conn, get_address(my_sender));
	 -- Specify recipient(s) of the email.
	 WHILE (my_recipients IS NOT NULL) LOOP
		 utl_smtp.rcpt(conn, get_address(my_recipients));
	 END LOOP;
	 -- Start body of email
	 utl_smtp.open_data(conn);
	 -- Set "From" MIME header
	 write_mime_header(conn, 'From', sender);
	 -- Set "To" MIME header
	 write_mime_header(conn, 'To', recipients);
	 -- Set "Subject" MIME header
	 write_mime_header(conn, 'Subject', subject);
	 -- Set "Content-Type" MIME header
	 write_mime_header(conn, 'Content-Type', mime_type);
	 -- Set "X-Mailer" MIME header
	 write_mime_header(conn, 'X-Mailer', MAILER_ID);
	 -- Set priority:
	 -- High Normal Low
	 -- 1 2 3 4 5
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
 END begin_mail_in_session;
 ------------------------------------------------------------------------
 PROCEDURE end_mail_in_session(conn IN OUT NOCOPY utl_smtp.connection) IS
 BEGIN
	 utl_smtp.close_data(conn);
 END end_mail_in_session;
 ------------------------------------------------------------------------
 PROCEDURE end_session(conn IN OUT NOCOPY utl_smtp.connection) IS
 BEGIN
 	utl_smtp.quit(conn);
 END end_session;

 ------------------------------------------------------------------------

 PROCEDURE send_mail IS
 l_rowid ROWID;
 l_email_success CHAR(1);
 l_recipient VARCHAR2(500);
 l_environment VARCHAR2(10);
 --l_email_msg VARCHAR2(4000);
  BEGIN
 l_email_success :='Y';
 mime_mail(
 			sender => 'OM_HVOP',
 			recipients => 'bala.edupuganti@officedepot.com',
 			subject => 'HVOP Alert',
 			mime_type => 'text/html',
 			message => 'TEST');
 EXCEPTION
 when others then
 l_email_success :='N';
 mime_mail(	sender => 'OM_HVOP',
 			recipients => l_recipient,
 			subject => 'HVOP ALERT',
 			mime_type => 'text/html',
 			message => substr(SQLERRM, 1, 256));
          
 END send_mail ;
 END XX_OM_EMAIL_HANDLER_OUT; 
 /
 SHOW ERRORS PACKAGE BODY XX_OM_EMAIL_HANDLER_OUT;
 EXIT;

 
