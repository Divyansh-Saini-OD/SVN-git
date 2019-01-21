SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_COPY_STORE_SITE_USES
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_COPY_STORE_SITE_USES                                |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Copies Store site uses to dummy internal customer and      |
-- |               Copies the location values from hz_cust_site_uses_all      |
-- |               to po_location_associations_all                            |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      18-Feb-2008 Sreedhar Mohan         Initial Version               |
-- |                                                                          |
-- +==========================================================================+
AS
  PROCEDURE MAIN(
    p_errbuf                OUT NOCOPY VARCHAR2,
    p_retcode               OUT NOCOPY VARCHAR2,
    p_us_party_name         IN         VARCHAR2,
    p_ca_party_name         IN         VARCHAR2,
    p_us_org_name           IN         VARCHAR2,
    p_ca_org_name           IN         VARCHAR2
   );
END XX_CDH_COPY_STORE_SITE_USES;
/

SHOW ERRORS;
