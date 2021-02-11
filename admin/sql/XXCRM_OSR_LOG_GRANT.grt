SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | SQL Script to create                                                     |
-- |                                                                          |
-- |TABLE: XXCRM_OSR_LOG                                                      |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date          Author               Remarks                      |
-- |=======   ==========    ================     =============================|
-- | V1.0     27-JAN-2021   Manjush              Initial version              |
-- |                                                                          |
-- +==========================================================================+

   
CREATE OR REPLACE PUBLIC SYNONYM XXCRM_OSR_LOG FOR XXCRM.XXCRM_OSR_LOG;

GRANT SELECT ON XXCRM_OSR_LOG TO "ERP_SYSTEM_TABLE_SELECT_ROLE";

GRANT ALL ON XXCRM_OSR_LOG TO "APPS";