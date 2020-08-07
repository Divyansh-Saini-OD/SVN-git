-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | SQL Script to create                                                     |
-- |                                                                          |
-- |                      INDEXES: XX_PO_VENDOR_SITES_N1                      |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date          Author               Remarks                      |
-- |=======   ==========    ================     =============================|
-- | V1.0     06-Oct-2007   Sambasiva Reddy D    Initial version              |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- DROP INDEX XX_PO_VENDOR_SITES_N1;

CREATE INDEX XXFIN.XX_PO_VENDOR_SITES_N1 ON PO.PO_VENDOR_SITES_ALL(NVL(SUBSTR(attribute9,4,LENGTH(attribute9)),vendor_site_id));

SHOW ERROR




