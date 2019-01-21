-- +===========================================================================+
-- |                  Office Depot -                                           |
-- +===========================================================================+
-- | Name :XX_TWE_GRANT)TABLE                                                  |
-- | Description :   Script to grant on XXTWE_TAX_PARTNER table                |
-- |  Rice ID :                                                                |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                  Remarks                |
-- |=======    ==========     =============             ====================== |
-- | DRAFT 1.0 25-SEP-2014    Sinon P.                 Initial draft version   |
-- +===========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
WHENEVER SQLERROR CONTINUE

--+=====================================================================+
--+               GRANT TABLE XXTWE_TAX_PARTNER                         +
--+=====================================================================+

GRANT SELECT ON xxfin.XXTWE_TAX_PARTNER TO APPS;

CREATE SYNONYM apps.XXTWE_TAX_PARTNER FOR xxfin.XXTWE_TAX_PARTNER;

SHOW ERROR
