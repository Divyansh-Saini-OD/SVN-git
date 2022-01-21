CREATE OR REPLACE PACKAGE XX_AR_LATE_LBOX_ALERT_PKG AS

-- +===================================================================+
-- | Name  : XX_AR_LATE_LBOX_ALERT_PKG.CHECK_LBOX_STATUS               |
-- | Description      : This Procedure will send an email if any       |
-- |                    lockbox due today, has yet to be received      |
-- |                                                                   |
-- | Parameters      email distribution list                           |
-- +===================================================================+

PROCEDURE CHECK_LBOX_STATUS(errbuf             OUT NOCOPY VARCHAR2,
                            retcode            OUT NOCOPY NUMBER,
                            p_email_dl         IN         VARCHAR2);

END XX_AR_LATE_LBOX_ALERT_PKG;
/
