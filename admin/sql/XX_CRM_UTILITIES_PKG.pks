SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_CRM_UTILITIES_PKG
-- +=========================================================================================+
-- |                           Office Depot - Project Simplify                               |
-- |                                Oracle Consulting                                        |
-- +=========================================================================================+
-- | Name        : XX_CRM_UTILITIES_PKG                                                      |
-- | Description : Custom package for data corrections                                       |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ===========     ==================   =========================================|
-- |1.0        23-Jun-2008     Ambarish Mukherjee   Initial version                          |
-- |2.0        21-Oct-2008     Rajeev Kamath        Added Email notification                 |
-- +=========================================================================================+

AS
-- ----------------------------
-- Declaring Global Constants
-- ----------------------------
G_SMTP_HOST             CONSTANT VARCHAR2(256) := 'USCHMSX84.na.odcorp.net';
G_SMTP_PORT             CONSTANT PLS_INTEGER   := 25;
G_SMTP_DOMAIN           CONSTANT VARCHAR2(256) := 'odcorp.net';
G_MAILER_ID             CONSTANT VARCHAR2(256) := 'Mailer by Oracle UTL_SMTP';
G_BOUNDARY              CONSTANT VARCHAR2(256) := '-----7D81B75CCC90D2974F7A1CBD';
G_FIRST_BOUNDARY        CONSTANT VARCHAR2(256) := '--' ||G_BOUNDARY || utl_tcp.CRLF;
G_LAST_BOUNDARY         CONSTANT VARCHAR2(256) := '--' ||G_BOUNDARY || '--' ||utl_tcp.CRLF;
G_MULTIPART_MIME_TYPE   CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary="'||G_BOUNDARY || '"';
G_MAX_BASE64_LINE_WIDTH CONSTANT PLS_INTEGER   := 76 / 4 * 3;
G_PACKAGE_NAME          CONSTANT VARCHAR2(256) := 'XX_CRM_UTILITIES_PKG';
G_PROCEDURE_NAME        CONSTANT VARCHAR2(256) := 'SEND_EMAIL_NOTIF';

-- +===================================================================+
-- | Name        : refresh_mat_view                                    |
-- |                                                                   |
-- | Description : The main procedure to be invoked from the           |
-- |               concurrent program                                  |
-- |                                                                   |
-- | Parameters  : p_view_name                                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE refresh_mat_view
(   x_errbuf            OUT VARCHAR2
   ,x_retcode           OUT VARCHAR2
   ,p_view_name         IN  VARCHAR2
)
;

-- +===================================================================+
-- | Name        : gather_group_stats                                  |
-- |                                                                   |
-- | Description : The main procedure to be invoked from the           |
-- |               concurrent program                                  |
-- |                                                                   |
-- | Parameters  : p_translation_name                                  |
-- |               p_group_name                                        |
-- +===================================================================+
PROCEDURE gather_group_stats
(   x_errbuf            OUT VARCHAR2
   ,x_retcode           OUT VARCHAR2
   ,p_group_name        IN  VARCHAR2
   ,p_estimate_percent  IN  VARCHAR2
   ,p_parallel_degree   IN  VARCHAR2
   ,p_backup            IN  VARCHAR2
   ,p_granularity       IN  VARCHAR2
   ,p_history_mode      IN  VARCHAR2
   ,p_invalidate_cur    IN  VARCHAR2
);

-- +===================================================================+
-- | Name        : gen_vpd_report_sql                                  |
-- |                                                                   |
-- | Description : This function will be used to generate the sql      |
-- |               for the VPD report                                  |
-- |                                                                   |
-- | Parameters  : p_profile_name                                      |
-- |                                                                   |
-- +===================================================================+
p_select          VARCHAR2(4000);
P_PROFILE_NAME    VARCHAR2(120);

FUNCTION gen_vpd_report_sql(
                            p_profile_name     IN VARCHAR2
                           )
RETURN BOOLEAN;

-- +===================================================================+
-- | Name        : get_prof_option_lookup                              |
-- |                                                                   |
-- | Description : This function will be used to get the lookup type   |
-- |               name for a profile option                           |
-- |                                                                   |
-- | Parameters  : p_profile_option_id                                 |
-- |                                                                   |
-- +===================================================================+
FUNCTION get_prof_option_lookup(
                                p_profile_option_id     IN NUMBER
                               )
RETURN VARCHAR2;

-- +===================================================================+
-- | Name        : send_email                                          |
-- |                                                                   |
-- | Description : The main procedure to be invoked from the           |
-- |               concurrent program                                  |
-- |                                                                   |
-- +===================================================================+
PROCEDURE send_email_notif(
                           x_errbuf            OUT NOCOPY VARCHAR2
                           , x_retcode         OUT NOCOPY NUMBER
                           , p_module          IN         VARCHAR2
                           , p_send_mail_lkp   IN         VARCHAR2
                           , p_sender_lkp      IN         VARCHAR2
                           , p_recipients_lkp  IN         VARCHAR2
                           , p_subject_lkp     IN         VARCHAR2
                           , p_body            IN         VARCHAR2
                          );

-- +===================================================================+
-- | Name        : mail                                                |
-- |                                                                   |
-- | Description : The procedure to send email in plain text           |
-- |                                                                   |
-- +===================================================================+
PROCEDURE mail(
               sender     IN VARCHAR2,
               recipients IN VARCHAR2,
               subject    IN VARCHAR2,
               message    IN VARCHAR2
              );

-- +===================================================================+
-- | Name        : begin_mail                                          |
-- |                                                                   |
-- | Description : The function  used to begin mail                    |
-- |                                                                   |
-- +===================================================================+
FUNCTION begin_mail(
                    sender     IN VARCHAR2,
                    recipients IN VARCHAR2,
                    subject    IN VARCHAR2,
                    mime_type  IN VARCHAR2    DEFAULT 'text/plain',
                    priority   IN PLS_INTEGER DEFAULT NULL
                   )
RETURN utl_smtp.connection;

-- +===================================================================+
-- | Name        : write_text                                          |
-- |                                                                   |
-- | Description : The procedure to write email body in ASCII          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE write_text(
                     conn    IN OUT NOCOPY utl_smtp.connection,
                     message IN VARCHAR2
                    );

-- +===================================================================+
-- | Name        : end_mail                                            |
-- |                                                                   |
-- | Description : The procedure to end the email                      |
-- |                                                                   |
-- +===================================================================+
PROCEDURE end_mail(
                   conn IN OUT NOCOPY utl_smtp.connection
                  );

-- +===================================================================+
-- | Name        : begin_session                                       |
-- |                                                                   |
-- | Description : The function to begin a session                     |
-- |                                                                   |
-- +===================================================================+
FUNCTION begin_session RETURN utl_smtp.connection;

-- +===================================================================+
-- | Name        : begin_mail_in_session                               |
-- |                                                                   |
-- | Description : The procedure to begin an email in a session        |
-- |                                                                   |
-- +===================================================================+
PROCEDURE begin_mail_in_session(
                                conn       IN OUT NOCOPY utl_smtp.connection,
                                sender     IN VARCHAR2,
                                recipients IN VARCHAR2,
                                subject    IN VARCHAR2,
                                mime_type  IN VARCHAR2  DEFAULT 'text/plain',
                                priority   IN PLS_INTEGER DEFAULT NULL
                               );

-- +===================================================================+
-- | Name        : end_mail_in_session                                 |
-- |                                                                   |
-- | Description : The procedure to end an email in a session          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE end_mail_in_session(
                              conn IN OUT NOCOPY utl_smtp.connection
                             );

-- +===================================================================+
-- | Name        : end_session                                         |
-- |                                                                   |
-- | Description : The procedure to end an email session               |
-- |                                                                   |
-- +===================================================================+
PROCEDURE end_session(
                      conn IN OUT NOCOPY utl_smtp.connection
                     );

-- +===================================================================+
-- | Name        : send_email                                          |
-- |                                                                   |
-- | Description : The main procedure to be invoked from other         |
-- |               programs                                            |
-- |                                                                   |
-- +===================================================================+
PROCEDURE send_email_notif(
                           p_module            IN         VARCHAR2
                           , p_send_mail_lkp   IN         VARCHAR2
                           , p_sender_lkp      IN         VARCHAR2
                           , p_recipients_lkp  IN         VARCHAR2
                           , p_subject_lkp     IN         VARCHAR2
                           , p_body            IN         VARCHAR2
                           , x_return_status   OUT NOCOPY VARCHAR2
                           , x_msg_count       OUT NOCOPY NUMBER
                           , x_msg_data        OUT NOCOPY VARCHAR2
                          );

END XX_CRM_UTILITIES_PKG;
/
SHOW ERRORS;