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
   CREATE OR REPLACE PACKAGE BODY xx_po_wf_notify_failure_alert
   AS
     
	 PROCEDURE main_program(x_retcode             OUT NOCOPY  NUMBER,
                            x_errbuf              OUT NOCOPY  VARCHAR2)
	 IS
	   lc_error_msg          VARCHAR2 (4000);
	   lc_message_type       VARCHAR2 (100);
  	   lc_sender             VARCHAR2 (100);
       lc_recipient          VARCHAR2 (250);
       lc_cc_recipient       VARCHAR2 (250);
	   lc_mail_subject		 VARCHAR2 (2000);
       lc_mail_body          VARCHAR2 (2000);
	   ln_time_duration      NUMBER;
	   ln_notification_count NUMBER := 0;
	   ln_no_of_days         NUMBER := 0;
	   ln_count              NUMBER := 0;
	   ln_mail_count         NUMBER := 0;
	   ln_deferred_count     NUMBER := 0;
	 BEGIN
	   BEGIN
		   SELECT xftv.source_value1,
		          xftv.target_value1,
				  xftv.target_value2,
				  xftv.target_value3,
				  xftv.target_value4,
				  xftv.target_value5,
				  xftv.target_value6,
				  xftv.target_value7,
				  xftv.target_value8
		   INTO lc_message_type,
		        lc_sender,
				lc_recipient,
				lc_cc_recipient,
				lc_mail_subject,
				lc_mail_body,
				ln_time_duration,
				ln_notification_count,
				ln_no_of_days
		   FROM xx_fin_translatevalues xftv
			   ,xx_fin_translatedefinition xftd
		   WHERE xftv.translate_id = xftd.translate_id
		   AND xftd.translation_name = 'XX_PO_NOTIFY_WF_FAILURES'
		   AND SYSDATE BETWEEN xftv.start_date_active AND NVL (xftv.end_date_active, SYSDATE + 1)
		   AND SYSDATE BETWEEN xftd.start_date_active AND NVL (xftd.end_date_active, SYSDATE + 1)
		   AND xftv.enabled_flag = 'Y'
		   AND xftd.enabled_flag = 'Y'; 
	   EXCEPTION WHEN OTHERS THEN
	     lc_message_type := NULL;
	     lc_sender := NULL;
		 lc_recipient := NULL;
		 lc_cc_recipient := NULL;
		 lc_mail_subject := NULL;
		 lc_mail_body := NULL;
		 ln_time_duration := NULL;
		 ln_notification_count := 0;
		 ln_no_of_days := 0;
	   END;
	 
	   SELECT count(1) 
	   INTO ln_mail_count
	   FROM wf_notifications
       WHERE message_type = lc_message_type
       AND status = 'OPEN'
       AND mail_status = 'MAIL'
	   AND item_key IS NOT NULL
	   AND begin_date > sysdate - ln_no_of_days
	   AND (sysdate - begin_date) * 24 > ln_time_duration;
	   
	   SELECT count(1) 
	   INTO ln_deferred_count
	   FROM WF_DEFERRED D 
	   WHERE d.corrid = 'APPS:oracle.apps.wf.notification.send'
       AND d.state = 0  -- Checking for 'Ready' Status
	   AND TO_NUMBER((SELECT VALUE  
                      FROM TABLE(d.user_data.parameter_list)  
                      WHERE NAME = 'NOTIFICATION_ID')) IN (SELECT notification_id
								                           FROM WF_NOTIFICATIONS
								                           WHERE message_type = lc_message_type
								                           AND status = 'OPEN'
								                           AND mail_status = 'FAILED'
								                           AND item_key is NOT NULL
								                           AND BEGIN_DATE > sysdate - ln_no_of_days
	                                                       AND (sysdate - begin_date) * 24 > ln_time_duration);
								
	   ln_count := ln_mail_count + ln_deferred_count;
	   
	   fnd_file.put_line(fnd_file.log, 'Number of Notifications in the List :'||ln_count);
	   
	   IF ln_count >= ln_notification_count THEN
	   
		  fnd_file.put_line(fnd_file.log, 'Calling the send_mail Procedure');
		
		  send_mail(p_notification_count => ln_count,
				    p_sender             => lc_sender,
					p_recipient          => lc_recipient,
					p_cc_recipient       => lc_cc_recipient,
					p_mail_subject       => lc_mail_subject,
					p_mail_body          => lc_mail_body,
					p_time_duration      => ln_time_duration,     
					p_return_msg         => lc_error_msg);

          IF lc_error_msg is NOT NULL THEN
		    fnd_file.put_line(fnd_file.log,lc_error_msg);
		    x_retcode := 2;
		  END IF;
	   END IF;
	 EXCEPTION WHEN OTHERS THEN
	   IF lc_error_msg IS NULL THEN
          lc_error_msg := 'Unable to process the program :'||SQLERRM;
       END IF;
       fnd_file.put_line(fnd_file.log,lc_error_msg);
       x_retcode := 2;
	 END main_program;
	 
	 PROCEDURE send_mail(p_notification_count IN     NUMBER,
	                     p_sender             IN     VARCHAR2,
						 p_recipient          IN     VARCHAR2,
						 p_cc_recipient       IN     VARCHAR2,
						 p_mail_subject       IN     VARCHAR2,
						 p_mail_body          IN     VARCHAR2,
						 p_time_duration      IN     VARCHAR2,
                         p_return_msg         OUT    VARCHAR2)
     IS
	   lc_error_msg              VARCHAR2 (4000);
       lc_conn                   UTL_SMTP.connection;
	   lc_mail   			     VARCHAR2 (2000) := NULL;
	   lc_instance_name          VARCHAR2 (10) := NULL;
	 BEGIN
	   lc_error_msg    := NULL;
	   
	   fnd_file.put_line(fnd_file.log,'In Send_Mail ');
	   
	   BEGIN
	     SELECT instance_name
		 into lc_instance_name
		 FROM v$instance;
	   EXCEPTION WHEN OTHERS THEN 
	     lc_instance_name := NULL;
	   END;
	   fnd_file.put_line(fnd_file.log,'Sender :'||p_sender||chr(10)
	                                ||'Recipient :'||p_recipient||chr(10)
									||'cc Recipient :'||p_cc_recipient||chr(10)
									||'Subject :'||p_mail_subject||chr(10)
									||'Mail Body :'||p_mail_body);
	   -- Calling xx_pa_pb_mail procedure to mail
       lc_conn := xx_pa_pb_mail.begin_mail (sender          => p_sender,
                                            recipients      => p_recipient,
                                            cc_recipients   => NULL,
                                            subject         => lc_instance_name||' : '||p_mail_subject
                                           );
	   --Mail Body                                             
       lc_mail := p_notification_count||' '||p_mail_body||' more than '||p_time_duration||' hours';
	   xx_pa_pb_mail.write_text (conn   => lc_conn,
                                 message   => lc_mail);
       --End of mail                                    
       xx_pa_pb_mail.end_mail (conn => lc_conn);
	   fnd_file.put_line(fnd_file.log,'End of Send_Mail Program'); 
	 EXCEPTION WHEN OTHERS THEN
	     lc_error_msg := 'Error while sending the mail' || SQLERRM;
         p_return_msg   := lc_error_msg;
	 END send_mail;
   end xx_po_wf_notify_failure_alert;
   /
   show errors;