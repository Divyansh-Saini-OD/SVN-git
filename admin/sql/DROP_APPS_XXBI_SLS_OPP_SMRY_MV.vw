-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- | Name        : XXCRM.XXBI_SLS_OPP_SMRY_MV                                  |
-- | Description : Dropping the materialized view to rebuild the view with     |
-- |               additional column(Store Number).                            |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                  Remarks                |
-- |=======    ==========     =============             ====================== |
-- | DRAFT 1.0 21-DEC-2010    Gokila Tamilselvam        Initial draft versio   |
-- |                                                                           |
-- +===========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

DROP MATERIALIZED VIEW APPS.XXBI_SLS_OPP_SMRY_MV;

SHOW ERROR