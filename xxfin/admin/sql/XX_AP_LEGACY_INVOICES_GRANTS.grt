-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                                                                          |
-- +==========================================================================+
-- | SQL Script to create Grants for the following tables                     |
-- |                                                                          |
-- |                      TABLE:  XXCNV.AP_INVOICES_LEGACY   	            |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   ================     ==============================|
-- | V1.0     23-AUG-2007  D. Nardo             Initial version               |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON


GRANT SELECT, INSERT, UPDATE, DELETE ON XXFIN.XX_AP_LEGACY_INVOICES TO XXCNV;

SHOW ERROR




