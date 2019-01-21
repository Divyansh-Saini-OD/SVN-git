CREATE OR REPLACE PACKAGE xx_ar_arcs_sl_extract_pkg
AS
-- +============================================================================================+
-- |                      Office Depot - Project Simplify                                       |
-- +============================================================================================+
-- |  Name              :  XX_AR_ARCS_SL_EXTRACT_PKG                                            |
-- |  Description       :  R7043- Package Spec to extract AR Subledger Accounting Information   |
-- |  Change Record     :                                                                       |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         012918       Dinesh Nagapuri  Initial version                                  |
-- +============================================================================================+
    PROCEDURE subledger_arcs_extract(
        p_errbuf       OUT     VARCHAR2,
        p_retcode      OUT     VARCHAR2,
        p_period_name  IN      VARCHAR2,
        p_debug        IN      VARCHAR2);
END xx_ar_arcs_sl_extract_pkg;
/