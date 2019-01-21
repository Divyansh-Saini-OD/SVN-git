SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_UPD_LOC_ASSOCIATIONS
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_UPD_LOC_ASSOCIATIONS                                |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Copies the location values from hz_cust_site_uses_all      |
-- |               to po_location_associations_all                            |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      11-Oct-2007 Sreedhar Mohan         Initial Version               |
-- |                                                                          |
-- +==========================================================================+
AS
  PROCEDURE MAIN(
                  p_errbuf   OUT NOCOPY VARCHAR2,
                  p_retcode  OUT NOCOPY VARCHAR2
                );
                
  PROCEDURE UPD_LOC_ASSOCIATIONS (
                                  p_errbuf   OUT NOCOPY VARCHAR2,
                                  p_retcode  OUT NOCOPY VARCHAR2,
                                  p_location IN         VARCHAR2
                                );
                                
END XX_CDH_UPD_LOC_ASSOCIATIONS;
/

SHOW ERRORS;
