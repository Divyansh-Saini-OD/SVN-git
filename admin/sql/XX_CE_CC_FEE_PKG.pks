SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Specification xx_ce_cc_fee_pkg
PROMPT Program exits if the creation is not successful


CREATE OR REPLACE PACKAGE xx_ce_cc_fee_pkg
AS
-- +===================================================================================+
-- |                            Oracle Consulting                                      |
-- +===================================================================================+
-- | Name       : XX_CE_CC_FEE_PKG.pls                                                   |
-- | Description: Cash Management AJB Creditcard Fee Journals Program                  |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record                                                                      |
-- |==============                                                                     |
-- |Version   Date         Authors              Remarks                                |
-- |========  ===========  ===============      ============================           |
-- |Draft 1A  04-Mar-2011  Sreenivasa Tirumala  Intial Draft Version                   |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- +===================================================================================+

   PROCEDURE create_fee_journal (
      x_errbuf    OUT NOCOPY   VARCHAR2
    , x_retcode   OUT NOCOPY   NUMBER
    , p_provider_code IN VARCHAR2
    , p_bank_rec_id   IN VARCHAR2
   );
   
END xx_ce_cc_fee_pkg;
/
show err;