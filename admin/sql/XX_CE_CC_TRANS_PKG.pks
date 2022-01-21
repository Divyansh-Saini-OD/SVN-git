create or replace
PACKAGE xx_ce_cc_trans_pkg
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                                                                                 |
-- +=================================================================================+
-- | Name       : xx_ce_cc_trans_pkg.pks                                             |
-- | Description: E2082 OD: CE CreditCard Transaction Journals                       |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |  1.0     2011-04-27   Joe Klein          New package.  Copied 996 and 998       |
-- |                                          code from E1310 package                |
-- |                                          XX_CE_AJB_CC_RECON_PKG                 |
-- |                                          Make appropriate changes for E2082     |
-- |                                          and SDR project.                       |
-- |                                                                                 |
-- +=================================================================================+

   PROCEDURE process_trans_journals (
      x_errbuf    OUT NOCOPY   VARCHAR2
    , x_retcode   OUT NOCOPY   NUMBER
    , p_provider_code IN VARCHAR2
    , p_bank_rec_id   IN VARCHAR2
   );
   
END xx_ce_cc_trans_pkg;


/