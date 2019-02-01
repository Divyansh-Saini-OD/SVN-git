create or replace 
PACKAGE xx_open_po_report_pkg
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |           
-- +===================================================================+
-- | Name  : xx_open_po_report_pkg.PKS                                   |
-- | Description      : Package Spec                                |
-- | This API will be used to send email notification OD Open 3 Way 
-- |Unreceived Standard POs and BPA Releases                                                                  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |
-- |1.0       14-NOV-2018   Veera Reddy  Automation of OPEN PO Report  |
-- |                        to notify the Requestors to Receive the PO |
-- +===================================================================+
TYPE SPLIT_TBL  IS TABLE OF VARCHAR2(32767);
 Function split
   (
      p_list            in      varchar2,
      P_DEL             IN      VARCHAR2 
   ) return SPLIT_TBL pipelined;
--open_po_report
   PROCEDURE open_po_report_procedure (
      retcode        OUT   NUMBER,
      errbuf         OUT   VARCHAR2,
      P_number_of_days in NUMBER
   );

      PROCEDURE send_mail_prc (
      p_sender      IN   VARCHAR2,
      p_recipient   IN   VARCHAR2,
      p_subject     IN   VARCHAR2,
      p_message     IN   CLOB,
      attachlist    IN   VARCHAR2,                            -- default null,
      DIRECTORY     IN   VARCHAR2                               --default null
   ) ;
   
   end xx_open_po_report_pkg;
   /
   