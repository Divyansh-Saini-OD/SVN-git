create or replace
PACKAGE      xx_cdh_bpel_sync_alert_pkg
AS
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- +====================================================================================+
-- | Name        :  xx_cdh_bpel_sync_alert_pkg.pks                                      |
-- | Description :  Checks the last update time for the dummy entity. This package raise|
-- |                an Email alert if the time difference between the last update time  |
-- |                and the system time is more than the expected time                  |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date        Author             Remarks                                    |
-- |========  =========== ================== ===========================================|
-- |DRAFT 1a  18-Aug-2008 Kathirvel          Initial draft version                      |
-- |          23-Jul-2009 Kalyan             Added procedures for Sales Rep Retry       | 
-- |                                         Functionality.                             |
-- +=====================================================================================+

PROCEDURE xx_cdh_raise_alert_proc(
                 x_errbuf	     OUT NOCOPY    VARCHAR2
               , x_retcode	     OUT NOCOPY    VARCHAR2
               , p_mail_server	     IN            VARCHAR2
               , p_mail_from	     IN            VARCHAR2
               , p_from_title	     IN            VARCHAR2
               , p_subject	     IN            VARCHAR2
               , p_page_flag         IN            VARCHAR2
               , p_check_minutes     IN            NUMBER);

PROCEDURE xx_cdh_send_email_proc(
                                            p_mail_server	IN            VARCHAR2
                                          , p_mail_from		IN            VARCHAR2
                                          , p_from_title	IN            VARCHAR2
                                          , p_subject		IN            VARCHAR2
					  , p_page_flag         IN            VARCHAR2
					  , p_entity_name       IN            VARCHAR2
					  , p_osr		IN            VARCHAR2
					  , x_return_status     OUT  NOCOPY   VARCHAR2
					  , x_error_message     OUT  NOCOPY   VARCHAR2
                                          );
PROCEDURE email_rep_errors (
      x_errbuf       OUT   NOCOPY VARCHAR2,
      x_retcode      OUT   NUMBER
   );
   
PROCEDURE store_rep_asmnts (
      x_errbuf       OUT   NOCOPY VARCHAR2,
      x_retcode      OUT   NUMBER
   );
   
PROCEDURE raise_rep_error_event (
      x_errbuf       OUT   NOCOPY VARCHAR2,
      x_retcode      OUT   NUMBER,
      p_datetime     IN    VARCHAR2
   );
   
PROCEDURE schedule_rep_event_cp (
      x_errbuf       OUT   NOCOPY VARCHAR2,
      x_retcode      OUT   NUMBER,
      p_datetime     IN    DATE
   );   
END xx_cdh_bpel_sync_alert_pkg;
/
SHOW ERRORS