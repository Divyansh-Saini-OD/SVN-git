CREATE OR REPLACE
PACKAGE XX_ORG_ERROR_NOTIFY_PKG
AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- +===================================================================+
  -- | Name  : XX_ORG_ERROR_NOTIFY_PKG.PKS                               |
  -- | Description      : Package Specification                          |
  -- |                                                                   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  |
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   14-APR-2015   Saikiran  S       Initial draft version   |
  -- |                                                                   |
  -- +===================================================================+
  PROCEDURE org_interface(
      retcode OUT NUMBER,
      errbuf OUT VARCHAR2,
      p_days IN NUMBER);
  PROCEDURE int_error_mail_msg(
      P_count  IN NUMBER,
      p_string IN CLOB,
      x_mail_sent_status OUT VARCHAR2,
      x_email_list OUT VARCHAR2);
END XX_ORG_ERROR_NOTIFY_PKG;
/
EXIT;