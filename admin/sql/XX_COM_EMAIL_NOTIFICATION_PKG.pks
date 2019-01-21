create or replace PACKAGE XX_COM_EMAIL_NOTIFICATION_PKG
AS
-- +===================================================================================+
-- |                              Office Depot Inc.                                    |
-- +===================================================================================+
-- | Name             :  XX_COM_EMAIL_NOTIFICATION_PKG                                  |
-- | Description      :  This process handles emailing notifications to concerned teams| 
-- |                     when there is a object failure                                |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date         Author           Remarks                                    |
-- |=======   ==========   =============    ======================                     |
-- | 1.0      28-APR-2016  Manikant Kasu    Initial Version                            |
-- +===================================================================================+

PROCEDURE SEND_NOTIFICATIONS(
                               p_email_identifier  IN VARCHAR2
                              ,p_from              IN VARCHAR2 default null
                              ,p_to                IN VARCHAR2 default null
                              ,p_cc                IN VARCHAR2 default null
                              ,p_bcc               IN VARCHAR2 default null
                              ,p_subject           IN VARCHAR2 default null
                              ,p_body              IN VARCHAR2 default null
                            );

END XX_COM_EMAIL_NOTIFICATION_PKG;
/

SHOW ERRORS;

