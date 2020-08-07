SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating Package Body XX_COM_MONITOR_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_COM_MONITOR_PKG
 IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       Wipro Technologies                          |
-- +===================================================================+
-- | Name  : XX_COM_MONITOR_PKG                                        |
-- | Description      :  This PKG will be used to fetch the concurrent |
-- |                     program details                               |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 11-SEP-2008  Gokila           Initial draft version       |
-- |DRAFT 1B 16-SEP-2008  Gokila           Added new procedure         |
-- |                                       REQUESTOR_EMAIL_ALERT to    |
-- |                                       fetch the concurrent request|
-- |                                       submitted by the requestor. |
-- |DRAFT 1C 22-SEP-2008  Gokila           1.Added mail group parameter|
-- |                                       to send mail to the         |
-- |                                       particular mail group       |
-- |                                       selected.                   |
-- |                                       2.Added condition to display|
-- |                                       the row in different colors |
-- |                                       according to the status of  |
-- |                                       the program.                |
-- |                                       3.Added ORDER BY caluse in  |
-- |                                       in all the cursor query     |
-- +===================================================================+
-- +===================================================================+
-- | Name : EMAIL_ALERT                                                |
-- | Description : Procedure to fetch the records matching the given   |
-- |               conditions and call the mailer                      |
-- | This procedure will be the executable of Concurrent               |
-- | program : OD: Email Program Alert                                 |
-- |                                                                   |
-- | Parameters : x_error_buff                                         |
-- |              x_ret_code                                           |
-- |              p_prog_appn                                          |
-- |              p_hour_detail                                        |
-- |              p_mail_group                                         |
-- |              p_log_file                                           |
-- |              p_output_file                                        |
-- |              p_hour_default                                       |
-- |              p_log_file_default                                   |
-- |              p_output_file_default                                |
-- +===================================================================+
 PROCEDURE EMAIL_ALERT(x_error_buff               OUT  VARCHAR2
                       ,x_ret_code                OUT  NUMBER
                       ,p_prog_appn               IN   VARCHAR2
                       ,p_hour_detail             IN   NUMBER
                       ,p_mail_group              IN   VARCHAR2
                       ,p_log_file                IN   VARCHAR2
                       ,p_output_file             IN   VARCHAR2
                       ,p_hour_default            IN   NUMBER
                       ,p_log_file_default        IN   VARCHAR2
                       ,p_output_file_default     IN   VARCHAR2
                       ,p_attachment_size         IN NUMBER
                       );

-- +===================================================================+
-- | Name : REQUESTOR_EMAIL_ALERT                                      |
-- | Description : Procedure to fetch the records for the particular   |
-- |               requestor and matching the given conditions and call|
-- |               the mailer                                          |
-- | This procedure will be the executable of Concurrent               |
-- | program : OD: Email Program Alert                                 |
-- |                                                                   |
-- | Parameters : x_error_buff                                         |
-- |              x_ret_code                                           |
-- |              p_req_name                                           |
-- |              p_prog_appn                                          |
-- |              p_hour_detail                                        |
-- |              p_mail_group                                         |
-- |              p_log_file                                           |
-- |              p_output_file                                        |
-- |              p_cutoff_time                                        |
-- |              p_prog_status                                        |
-- |              p_hour_default                                       |
-- |              p_log_file_default                                   |
-- |              p_output_file_default                                |
-- +===================================================================+
 PROCEDURE REQUESTOR_EMAIL_ALERT(x_error_buff               OUT  VARCHAR2
                                 ,x_ret_code                OUT  NUMBER
                                 ,p_req_name                IN   VARCHAR2
                                 ,p_prog_appn               IN   VARCHAR2
                                 ,p_hour_detail             IN   NUMBER
                                 ,p_mail_group              IN   VARCHAR2
                                 ,p_log_file                IN   VARCHAR2
                                 ,p_output_file             IN   VARCHAR2
                                 ,p_cutoff_time             IN   VARCHAR2
                                 ,p_prog_status             IN   VARCHAR2
                                 ,p_hour_default            IN   NUMBER
                                 ,p_log_file_default        IN   VARCHAR2
                                 ,p_output_file_default     IN   VARCHAR2
                                 ,p_exclude_mailer          IN   VARCHAR2
                                 ,p_attachment_size         IN NUMBER
                                 );

 END XX_COM_MONITOR_PKG;
/