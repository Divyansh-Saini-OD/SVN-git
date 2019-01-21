create or replace PACKAGE XX_FIN_ESP_MONITOR_PKG AS
-- +=====================================================================================================+
-- |  Office Depot - Project Simplify                                                                    |
-- |  Providge Consulting                                                                                |
-- +=====================================================================================================+
-- |  RICE:                                                                                              |
-- |                                                                                                     |
-- |  Name:  XX_FIN_ESP_MONITOR_PKG                                                                      |
-- |                                                                                                     |
-- |  Description:  This package will monitor ESP Batch jobs and send email alerts for failures          |
-- |                                                                                                     |
-- |                                                                                                     |
-- |  Change Record:                                                                                     |
-- +=====================================================================================================+
-- | Version     Date         Author               Remarks                                               |
-- | =========   ===========  =============        ======================================================|
-- | 1.0         16-DEC-2011  R.Strauss            Initial version                                       |
-- +=====================================================================================================+
PROCEDURE MONITOR_ESP_BATCH(errbuf       OUT NOCOPY VARCHAR2,
                            retcode      OUT NOCOPY NUMBER,
                            p_email_addr IN         VARCHAR2);
END XX_FIN_ESP_MONITOR_PKG ;
/