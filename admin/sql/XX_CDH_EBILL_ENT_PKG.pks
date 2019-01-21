SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_EBILL_ENT_PKG
-- +=========================================================================================+
-- |                  Office Depot                                                           |
-- +=========================================================================================+
-- | Name        : XX_CDH_EBILL_ENT_PKG                                                      |
-- | Description :                                                                           |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |Draft 1a   15-Oct-2012     Sreedhar Mohan       Initial draft version                    |
-- +=========================================================================================+
AS
  PROCEDURE insert_epdf_entities(
    p_orig_system_reference  IN         VARCHAR2,
    p_cust_account_id        IN         NUMBER,
    x_errbuf                 OUT NOCOPY VARCHAR2,
    x_retcode                OUT NOCOPY VARCHAR2
  );
END XX_CDH_EBILL_ENT_PKG;
/
SHOW ERRORS;
