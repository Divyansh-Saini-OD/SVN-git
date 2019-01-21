SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT Creating PACKAGE BODY XX_PO_WF_NOTIFY_FAILURE_ALERT
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE
-- +==================================================================================+
-- |                        Office Depot                                              |
-- +==================================================================================+
-- | Name  : XX_PO_WF_NOTIFY_FAILURE_ALERT                                            |
-- | Description      : This program will send the mail if the PO workflow            |
-- |                    notifications failes to sent a mail                           |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version Date        Author            Remarks                                     |
-- |======= =========== =============== ==============================================|
-- |1.0     31-MAY-2017 Suresh Naragam   Initial draft version                        |
-- +==================================================================================+
  CREATE OR REPLACE PACKAGE xx_po_wf_notify_failure_alert
  AS

    PROCEDURE main_program(x_retcode    OUT NOCOPY  NUMBER,
                           x_errbuf     OUT NOCOPY  VARCHAR2);
						 
    PROCEDURE send_mail(p_notification_count IN     NUMBER,
	                    p_sender             IN     VARCHAR2,
		   			    p_recipient          IN     VARCHAR2,
					    p_cc_recipient       IN     VARCHAR2,
					    p_mail_subject       IN     VARCHAR2,
					    p_mail_body          IN     VARCHAR2,
						p_time_duration      IN     VARCHAR2,
                        p_return_msg         OUT    VARCHAR2);

  END xx_po_wf_notify_failure_alert;
  /
  show errors;