create or replace package XX_GL_UNPOSTED_JRS IS

P_SEND_EMAIL VARCHAR2(10);
P_SMTP_SERVER VARCHAR2(100);-- := FND_PROFILE.VALUE('XX_PA_PB_MAIL_HOST');
P_MAIL_FROM VARCHAR2(100);-- := 'noreply@officedepot.com';
gc_email_from VARCHAR2(100) := 'noreply@officedepot.com';
--TYPE g_batch_tab IS TABLE OF NUMBER;
FUNCTION after_report RETURN BOOLEAN;

PROCEDURE od_send_approval_mail(p_batch_ids IN NUMBER,p_sep IN VARCHAR2 DEFAULT ',');
END XX_GL_UNPOSTED_JRS;
/