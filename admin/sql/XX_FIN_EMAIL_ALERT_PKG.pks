create or replace
PACKAGE XX_FIN_EMAIL_ALERT_PKG
 IS
 -- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       Wipro Technologies                          |
-- +===================================================================+
-- | Name  : XX_FIN_HTTP_PKG                                           |
-- | Description      :  This PKG will be used to fetch the concurrent |
-- |                     program details                               |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 11-SEP-2008  Gokila           Initial draft version       |
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
                       );
 END XX_FIN_EMAIL_ALERT_PKG;
/