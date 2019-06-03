create or replace 
PACKAGE xx_int_err_notificatn_pkg
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
-- |DRAFT 1A   16-MAR-2015   Saritha  M       Initial draft version   |
-- |                                                                   |
-- |1.5        04-MAR-2018   VENKATESHWAR PANDUGA ITEM ERROR REPORT SHOULD SHOW ALL   |
-- |            |                                    RMS-EBS ITEM Interface Error for the Defect # 44629       |
-- |            |
-- +===================================================================+
TYPE SPLIT_TBL  IS TABLE OF VARCHAR2(32767);
 Function split
   (
      p_list            in      varchar2,
      P_DEL             IN      VARCHAR2 
   ) return SPLIT_TBL pipelined;
   PROCEDURE int_interface (
      retcode        OUT   NUMBER,
      errbuf         OUT   VARCHAR2
   );

--   PROCEDURE INT_ERROR_MAIL_MSG (
--      P_MASTER_DATA        IN      VARCHAR2,
--      P_CHILD_ITEM_CODE    IN       clob, 
--      p_email_list         IN       VARCHAR2,
--      x_mail_sent_status   OUT      VARCHAR2
--   );
    PROCEDURE send_mail_prc (
      p_sender      IN   VARCHAR2,
      p_recipient   IN   VARCHAR2,
      p_subject     IN   VARCHAR2,
      p_message     IN   CLOB,
      attachlist    IN   VARCHAR2,                            -- default null,
      DIRECTORY     IN   VARCHAR2                               --default null
   ) ;
END xx_int_err_notificatn_pkg;
/
