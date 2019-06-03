create or replace 
PACKAGE XX_ORG_IMP_ERR_NOTI_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  : XXINTERRORNOTIFYPKG.PKS                                   |
-- | Description      : Package Specification                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   25-NOV-2014   Saritha  M       Initial draft version   |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE org_interface (
      retcode        OUT   NUMBER,
      errbuf         OUT   VARCHAR2,
      p_email_list in varchar2
   );

   PROCEDURE int_error_mail_msg (
      p_org_name        IN       VARCHAR2,
      p_loc_name    IN       CLOB,
      p_email_list         IN       VARCHAR2,
      x_mail_sent_status   OUT      VARCHAR2
   );
END XX_ORG_IMP_ERR_NOTI_PKG;