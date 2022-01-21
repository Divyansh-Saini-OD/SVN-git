CREATE OR REPLACE PACKAGE XX_AR_VPS_CORE_OPEN_TRXS_PKG
AS
-- +===========================================================================+
-- |                  Office Depot                                             |
-- +===========================================================================+
-- |Description : Package to Extract VPS CORE Open Transactions                | 
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                  Remarks                |
-- |=======    ===========     =============            ====================== |
-- | 1.0       30-JAN-2020     Havish Kasina            Initial draft version  |
-- +===========================================================================+
  PROCEDURE get_core_trxs( p_errbuf       OUT     VARCHAR2,
                           p_retcode      OUT     VARCHAR2,
                           p_debug        IN      VARCHAR2
                         );
END XX_AR_VPS_CORE_OPEN_TRXS_PKG;
/
SHOW ERRORS;