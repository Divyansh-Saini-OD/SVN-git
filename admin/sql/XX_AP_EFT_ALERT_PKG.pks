create or replace PACKAGE XX_AP_EFT_ALERT_PKG AS
-- +=====================================================================================================+
-- |  Office Depot - Project Simplify                                                                    |
-- |  Providge Consulting                                                                                |
-- +=====================================================================================================+
-- |  RICE:                                                                                              |
-- |                                                                                                     |
-- |  Name:  XX_AP_EFT_ALERT_PKG                                                                         |
-- |                                                                                                     |
-- |  Description:  This package will examine the AP batch confirmation status and send email alert      |
-- |                if batches are not confirmed by execution time                                       |
-- |                                                                                                     |
-- |  Change Record:                                                                                     |
-- +=====================================================================================================+
-- | Version     Date         Author               Remarks                                               |
-- | =========   ===========  =============        ======================================================|
-- | 1.0         16-DEC-2011  R.Strauss            Initial version                                       |
-- +=====================================================================================================+
PROCEDURE CHECK_EFT_CONFIRM(errbuf       OUT NOCOPY VARCHAR2,
                            retcode      OUT NOCOPY NUMBER,
                            p_days       IN  NUMBER,
                            p_email_addr IN  VARCHAR2);
END XX_AP_EFT_ALERT_PKG ;
/