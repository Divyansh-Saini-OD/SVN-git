create or replace PACKAGE XX_OM_EMAIL_HANDLER_OUT IS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XX_OM_EMAIL_HANDLER_OUT.PKS                               |
-- | Description      : Package Specification                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   16-AUG-2009   Bala          Initial draft version       |
-- |1.1        21-APR-2015   Sai Kiran     Changes made as part of Defect# 34204|
-- +===================================================================+


 ----------------------- Customizable Section -----------------------

 -- Customize the SMTP host, port and your domain name below.
 smtp_host VARCHAR2(256) := 'localhost';
 smtp_port PLS_INTEGER := 25;
 --CH ID#34204 Start --Changes made to pick SMPT Domain from profile.
 --smtp_domain VARCHAR2(256) := 'USCHMSX83.na.odcorp.net';
   smtp_domain VARCHAR2(256) := fnd_profile.value('XX_COMN_SMTP_MAIL_SERVER');
  --CH ID#34204 End

 -- Customize the signature that will appear in the email's MIME header.
 -- Useful for versioning.
 MAILER_ID CONSTANT VARCHAR2(256) := 'Mailer by Oracle UTL_SMTP for HVOP team';

 --------------------- End Customizable Section ---------------------

 -- A unique string that demarcates boundaries of parts in a multi-part email
 -- The string should not appear inside the body of any part of the email.
 -- Customize this if needed or generate this randomly dynamically.
 BOUNDARY CONSTANT VARCHAR2(256) := '-----7D81B75CCC90D2974F7A1CBD';

 FIRST_BOUNDARY CONSTANT VARCHAR2(256) := '--' || BOUNDARY || utl_tcp.CRLF;
 LAST_BOUNDARY CONSTANT VARCHAR2(256) := '--' || BOUNDARY || '--' ||
 utl_tcp.CRLF;

 -- A MIME type that denotes multi-part email (MIME) messages.
 MULTIPART_MIME_TYPE CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary="'||
 BOUNDARY || '"';
 MAX_BASE64_LINE_WIDTH CONSTANT PLS_INTEGER := 76 / 4 * 3;
 
 
 PROCEDURE simple_mail(sender IN VARCHAR2,
		 recipients IN VARCHAR2,
		 subject IN VARCHAR2,
		 message IN VARCHAR2);

 
 PROCEDURE mime_mail(sender IN VARCHAR2,
		 recipients IN VARCHAR2,
		 subject IN VARCHAR2,
     mime_type IN VARCHAR2,
		 message IN CLOB);

 -- Extended email API to send email in HTML or plain text with no size limit.
 -- First, begin the email by begin_mail(). Then, call write_text() repeatedly
 -- to send email in ASCII piece-by-piece. Or, call write_mb_text() to send
 -- email in non-ASCII or multi-byte character set. End the email with
 -- end_mail().
 FUNCTION begin_mail(sender IN VARCHAR2,
		 recipients IN VARCHAR2,
		 subject IN VARCHAR2,
		 mime_type IN VARCHAR2 DEFAULT 'text/plain',
		 priority IN PLS_INTEGER DEFAULT NULL)
		 RETURN utl_smtp.connection;

 -- Write email body in ASCII
 PROCEDURE write_text(conn IN OUT NOCOPY utl_smtp.connection,
		 message IN VARCHAR2);

 -- Write email body in non-ASCII (including multi-byte). The email body
 -- will be sent in the database character set.
 PROCEDURE write_mb_text(conn IN OUT NOCOPY utl_smtp.connection,
			 message IN VARCHAR2);

 -- Write email body in binary
 PROCEDURE write_raw(conn IN OUT NOCOPY utl_smtp.connection,
		 message IN RAW);

 -- APIs to send email with attachments. Attachments are sent by sending
 -- emails in "multipart/mixed" MIME format. Specify that MIME format when
 -- beginning an email with begin_mail().

 -- End the email.
 PROCEDURE end_mail(conn IN OUT NOCOPY utl_smtp.connection);

 -- Extended email API to send multiple emails in a session for better
 -- performance. First, begin an email session with begin_session.
 -- Then, begin each email with a session by calling begin_mail_in_session
 -- instead of begin_mail. End the email with end_mail_in_session instead
 -- of end_mail. End the email session by end_session.
 FUNCTION begin_session RETURN utl_smtp.connection;

 -- Begin an email in a session.
 PROCEDURE begin_mail_in_session(conn IN OUT NOCOPY utl_smtp.connection,
				 sender IN VARCHAR2,
				 recipients IN VARCHAR2,
				 subject IN VARCHAR2,
				 mime_type IN VARCHAR2 DEFAULT 'text/plain',
				 priority IN PLS_INTEGER DEFAULT NULL);

 -- End an email in a session.
 PROCEDURE end_mail_in_session(conn IN OUT NOCOPY utl_smtp.connection);

 -- End an email session.
 PROCEDURE end_session(conn IN OUT NOCOPY utl_smtp.connection);

END XX_OM_EMAIL_HANDLER_OUT;
/
exit;