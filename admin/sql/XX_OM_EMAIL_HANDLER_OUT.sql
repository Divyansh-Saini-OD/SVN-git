create or replace PACKAGE XX_OM_EMAIL_HANDLER_OUT AS

 FUNCTION begin_mail(sender IN VARCHAR2,
		 recipients IN VARCHAR2,
		 subject IN VARCHAR2,
		 mime_type IN VARCHAR2 DEFAULT 'text/plain',
		 priority IN PLS_INTEGER DEFAULT NULL)
		 RETURN utl_smtp.connection; 

 PROCEDURE write_text(conn IN OUT NOCOPY utl_smtp.connection,
		 message IN VARCHAR2);
 FUNCTION begin_session RETURN utl_smtp.connection IS
 conn utl_smtp.connection;
 BEGIN
 -- open SMTP connection
	 conn := utl_smtp.open_connection(smtp_host, smtp_port);
	 utl_smtp.helo(conn, smtp_domain);
	 RETURN conn;
 END;

 PROCEDURE end_mail(conn IN OUT NOCOPY utl_smtp.connection) IS
 BEGIN
	 end_mail_in_session(conn);
	 end_session(conn);
 END end_mail;

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
--	 utl_smtp.mail(conn, get_address(my_sender));
	 utl_smtp.mail(conn, my_sender);
	 -- Specify recipient(s) of the email.
	 WHILE (my_recipients IS NOT NULL) LOOP
		-- utl_smtp.rcpt(conn, get_address(my_recipients));
		   utl_smtp.rcpt(conn, my_recipients);
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

 


 PROCEDURE simple_mail(sender IN VARCHAR2,
		 recipients IN VARCHAR2,
		 subject IN VARCHAR2,
		 message IN VARCHAR2);

END XX_OM_EMAIL_HANDLER_OUT;
/