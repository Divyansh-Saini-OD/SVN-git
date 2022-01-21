-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | SQL Script to create                                                     |
-- |                                                                          |
-- |                      INDEXES: XX_AP_SUPPLIER_SITES_N2                    |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date          Author               Remarks                      |
-- |=======   ==========    ================     =============================|
-- | V1.0     01-Oct-2013   Avinash Baddam       I1358 - R12 Upgrade Retrofit.|
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

CREATE INDEX "XXFIN"."XX_AP_SUPPLIER_SITES_N2" ON "AP"."AP_SUPPLIER_SITES_ALL"
 (nvl(ltrim(attribute9,'0'),to_char(vendor_site_id)))
TABLESPACE "XXOD_TS_DATA";

SHOW ERROR