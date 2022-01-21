CREATE OR REPLACE PACKAGE XX_CE_LOCKBOX_RECON_PKG AS 
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Providge Consulting                                  |
-- +=================================================================================+
-- | Name       : XXCELOCKBOXRECON.pks                                               |
-- | Description: Cash Management Lockbox Reconciliation E1297-Extension             |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |DRAFT 1A  10-JUL-2007  Sunayan Mohanty    Initial draft version                  |
-- |1.0       03-AUG-2007  Sunayan Mohanty    Incorporated all the review comments   |
-- +=================================================================================+
-- | Name        : RECON_PROCESS                                                     |
-- | Description : This procedure will be used to process the                        |
-- |               Cash Management lockbox deposit and AR receipt                    |
-- |                                                                                 |
-- | Parameters  : p_run_from_date   IN DATE                                         |
-- |               p_run_to_date     IN DATE                                         |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- +=================================================================================+

PROCEDURE  recon_process 
                        (x_errbuf           OUT NOCOPY VARCHAR2
                        ,x_retcode          OUT NOCOPY NUMBER
                        ,p_run_from_date    IN         VARCHAR2
                        ,p_run_to_date      IN         VARCHAR2
                        ,p_email_id         IN         VARCHAR2   DEFAULT NULL
                        );


END XX_CE_LOCKBOX_RECON_PKG;
/
SHOW ERROR;
EXIT;

-- -------------------------------------------------------------------
-- End of Script                                                   
-- -------------------------------------------------------------------

