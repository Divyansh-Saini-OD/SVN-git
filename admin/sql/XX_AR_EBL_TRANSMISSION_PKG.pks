create or replace
PACKAGE XX_AR_EBL_TRANSMISSION_PKG AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- +====================================================================================================+
-- | Name        : XX_AR_EBL_TRANSMISSION_PKG                                                           |
-- | Description : Package spec for eBilling transmission / resend via eMail                            |
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


-- ===========================================================================
-- Procedure to send email to specified recipients with attachments.
--  This is called from custom iReceivables Statements page (StatementsPG).
--   file id list is for comma sepparated pointers to rows in XX_AR_EBL_FILE.
--   email address list is comma or semicolon delimited list of recipients.
--   rename zip ext flag will cause any .zip extension to be renamed _zip
--   Status is returned in x_error (blank if no error).
-- ===========================================================================
  PROCEDURE SEND_ONE_EMAIL (
    p_file_id_list             IN VARCHAR2,
    p_email_address_list       IN VARCHAR2,
    p_rename_zip_ext_flag      IN VARCHAR2,
    x_error                   OUT VARCHAR2
  );
  
  PROCEDURE SEND_CD_NOTIFICATIONS (
    Errbuf                 OUT NOCOPY VARCHAR2
   ,Retcode                OUT NOCOPY VARCHAR2
  );
  
  PROCEDURE SEND_FTP_NOTIFICATIONS (
    Errbuf                 OUT NOCOPY VARCHAR2
   ,Retcode                OUT NOCOPY VARCHAR2
  );

  PROCEDURE TRANSMIT_EMAIL_P (
    Errbuf                 OUT NOCOPY VARCHAR2
   ,Retcode                OUT NOCOPY VARCHAR2
  );
  
  PROCEDURE TRANSMIT_EMAIL_C (
    Errbuf            OUT NOCOPY VARCHAR2
   ,Retcode           OUT NOCOPY VARCHAR2
   ,p_thread_id       IN NUMBER
   ,p_thread_count    IN NUMBER
   ,p_smtp_server     IN VARCHAR2
   ,p_smtp_port       IN PLS_INTEGER
   ,p_from_name       IN VARCHAR2
  );
  
  PROCEDURE SET_TOOBIG_TRANSMISSIONS_EMAIL;
  
  PROCEDURE SET_TOOBIG_TRANSMISSIONS_FTP;

  
  PROCEDURE TRANSMISSIONS_TO_FTP (
    x_cursor         OUT SYS_REFCURSOR
  );
  PROCEDURE SHOW_TRANSMISSIONS_TO_FTP;

  
  PROCEDURE FILES_TO_FTP (
    p_transmission_id  IN NUMBER
   ,x_cursor          OUT SYS_REFCURSOR
  );
  PROCEDURE SHOW_FILES_TO_FTP;  


  PROCEDURE TRANSMISSIONS_TO_WRITE_TO_CD (
    x_cursor          OUT SYS_REFCURSOR
  );
  PROCEDURE SHOW_TRANSMISSIONS_TO_WRITE_CD;


  PROCEDURE FILES_TO_WRITE_TO_CD (
    p_transmission_id  IN NUMBER  
   ,x_cursor          OUT SYS_REFCURSOR
  );
  PROCEDURE SHOW_FILES_TO_WRITE_CD;


  PROCEDURE FTP_PATHS (
    x_cursor         OUT SYS_REFCURSOR
   ,x_org_id         OUT VARCHAR2
  );
  PROCEDURE SHOW_FTP_PATHS;

  
  PROCEDURE FTP_CONFIG (
    p_host           OUT VARCHAR2
   ,p_port           OUT VARCHAR2
   ,p_user           OUT VARCHAR2
  );


  PROCEDURE FTP_STAGED_PUSH_CUST_DOCS (
    x_cursor         OUT SYS_REFCURSOR
  );


  PROCEDURE FTP_STAGED_PULL_ACCOUNTS (
    x_cursor         OUT SYS_REFCURSOR
  );


  PROCEDURE UPDATE_FTP_PUSH_STATUS (
    p_account_number HZ_CUST_ACCOUNTS_ALL.account_number%TYPE
   ,p_status         XX_AR_EBL_TRANSMISSION.status%TYPE
   ,p_status_detail  XX_AR_EBL_TRANSMISSION.status_detail%TYPE
  );

  PROCEDURE ARCHIVE_N_PURGE_FILES (
    Errbuf            OUT NOCOPY VARCHAR2
   ,Retcode           OUT NOCOPY VARCHAR2
  );
  
  PROCEDURE FETCH_ARCHIVED_BLOB_INTO_GT (
    p_file_id         IN NUMBER
  );

  PROCEDURE GET_FILE_DATA_CURSOR (
    p_file_id         IN NUMBER
   ,x_cursor         OUT SYS_REFCURSOR
  );
  
  PROCEDURE GET_ORG_ID (
    x_org_id         OUT VARCHAR2
  );


END XX_AR_EBL_TRANSMISSION_PKG;

/
