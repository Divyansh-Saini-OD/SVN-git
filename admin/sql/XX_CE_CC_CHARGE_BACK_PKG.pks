SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Specification xx_ce_cc_charge_back_pkg
PROMPT Program exits if the creation is not successful


create or replace
PACKAGE xx_ce_cc_charge_back_pkg
AS
-- +===================================================================================+
-- |                            Office Depot - Project Simplify                        |
-- +===================================================================================+
-- | Name       : XX_CE_CC_CHARGE_BACK_PKG.PKS                                         |
-- | Description: Cash Management AJB Creditcard Charge Back Program                   |
-- | CM: E2080 (CR898) - OD: CM AJB Credit Card Chageback's                            |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record                                                                      |
-- |==============                                                                     |
-- |Version   Date         Authors              Remarks                                |
-- |========  ===========  ===============      ============================           |
-- |Draft 1A  31-Mar-2011  Ritch Hartman        Intial Draft Version - Defect 10856    |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- +===================================================================================+

   PROCEDURE process_charge_backs (
      x_errbuf    OUT NOCOPY   VARCHAR2
    , x_retcode   OUT NOCOPY   NUMBER
    , p_provider_code IN VARCHAR2
    , p_bank_rec_id   IN VARCHAR2
   );
   
END xx_ce_cc_charge_back_pkg;
/
show err;