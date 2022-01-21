/* Formatted on 2008/03/20 15:49 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE xx_ce_lockbox_recon_pkg
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Providge Consulting                                  |
-- +=================================================================================+
-- | Name       : XX_CE_LOCKBOX_RECON_PKG.pks                                               |
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
-- |          20-MAR-2008  Deepak Gowda       Resolution of defects 5601, 5601, 5603 |
-- +=================================================================================+
   FUNCTION get_lockbox_num (
      p_bank_account_num  IN  VARCHAR2
    , p_invoice_text      IN  VARCHAR2
    , p_trx_code		  IN  VARCHAR2
   )
      RETURN VARCHAR2;

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
   PROCEDURE recon_process (
      x_errbuf         OUT NOCOPY     VARCHAR2
    , x_retcode        OUT NOCOPY     NUMBER
    , p_run_from_date  IN             VARCHAR2
    , p_run_to_date    IN             VARCHAR2
    , p_email_id       IN             VARCHAR2 DEFAULT NULL
   );
END xx_ce_lockbox_recon_pkg;
/