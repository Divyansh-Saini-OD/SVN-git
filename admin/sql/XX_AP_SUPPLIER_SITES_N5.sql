-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | SQL Script to create                                                     |
-- |                                                                          |
-- |                      INDEXES: XX_AP_SUPPLIER_SITES_N5                    |
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

CREATE INDEX xxfin.xx_ap_supplier_sites_n5 ON ap.ap_supplier_sites_all(attribute9);