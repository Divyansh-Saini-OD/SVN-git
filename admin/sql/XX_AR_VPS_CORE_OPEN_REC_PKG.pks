CREATE OR REPLACE PACKAGE XX_AR_VPS_CORE_OPEN_REC_PKG
AS
-- +===========================================================================+
-- |                  Office Depot                                             |
-- +===========================================================================+
-- |Description : Package to Extract VPS CORE Open Receipts                | 
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                  Remarks                |
-- |=======    ===========     =============            ====================== |
-- | 1.0       14-Feb-2020     Shreyas Thorat           Initial draft version  |
-- +===========================================================================+
  PROCEDURE get_core_rec( p_errbuf       OUT     VARCHAR2,
                           p_retcode      OUT     VARCHAR2,
                           p_debug        IN      VARCHAR2
                         );
END XX_AR_VPS_CORE_OPEN_REC_PKG;
/
SHOW ERRORS;