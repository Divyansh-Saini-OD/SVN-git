CREATE OR REPLACE PACKAGE XX_AR_VPS_STMT_BKUP_EMAIL_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	     :  XX_AR_VPS_STMT_BKUP_EMAIL_PKG                                               |
-- |  RICE ID 	 :  I3108                                          			                    |
-- |  Description:                                                                          	|
-- |                                                           				                    |        
-- +============================================================================================+
-- | Version     Date          Author              Remarks                                      |
-- | =========   ===========   =============       =============================================|
-- | 1.0         18-JUL-2018   Havish Kasina       Initial version                              |
-- +============================================================================================+

  ----------------------- Customizable Section -----------------------
  -- Customize the SMTP host, port and your domain name below.
 smtp_host   VARCHAR2(256) := FND_PROFILE.VALUE('XX_COMN_SMTP_MAIL_SERVER');
  
  smtp_port   PLS_INTEGER   := 25;
  smtp_domain VARCHAR2(256) := 'officedepot.com';
  -- Customize the signature that will appear in the email's MIME header.
  -- Useful for versioning.
  MAILER_ID   CONSTANT VARCHAR2(256) := 'Mailer by Oracle UTL_SMTP';
  --------------------- End Customizable Section ---------------------
  -- A unique string that demarcates boundaries of parts in a multi-part email
  -- The string should not appear inside the body of any part of the email.
  -- Customize this if needed or generate this randomly dynamically.
  BOUNDARY        CONSTANT VARCHAR2(256) := '-----7D81B75CCC90D2974F7A1CBD';
  FIRST_BOUNDARY  CONSTANT VARCHAR2(256) := '--' || BOUNDARY || utl_tcp.CRLF;
  LAST_BOUNDARY   CONSTANT VARCHAR2(256) := '--' || BOUNDARY || '--' ||
                                              utl_tcp.CRLF;
  -- A MIME type that denotes multi-part email (MIME) messages.
  MULTIPART_MIME_TYPE CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary="'||
                                                  BOUNDARY || '"';
  MAX_BASE64_LINE_WIDTH CONSTANT PLS_INTEGER   := 76 / 4 * 3;
  -- A simple email API for sending email in plain text in a single call.
  -- The format of an email address is one of these:
  --   someone@some-domain
  --   "Someone at some domain" <someone@some-domain>
  --   Someone at some domain <someone@some-domain>
  -- The recipients is a list of email addresses  separated by
  -- either a "," or a ";"
  
-- +===============================================================================================+
-- |  Name	 : process_documents                                                                   |                 	
-- |  Description: This procedure is to get all the VPS Vendor Details                             |
-- ================================================================================================|
							  
PROCEDURE process_documents( p_errbuf         OUT  VARCHAR2
                            ,p_retcode        OUT  VARCHAR2   
                            ,p_debug          IN   VARCHAR2
							);

END XX_AR_VPS_STMT_BKUP_EMAIL_PKG;
/
SHOW ERRORS;