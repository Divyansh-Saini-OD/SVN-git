-- +===========================================================================+
-- |                  Office Depot                                             |
-- +===========================================================================+
-- |Description : Grant XX_GL_ARCS_BALANCES                                    |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                  Remarks                |
-- |=======    ==========     =============             ====================== |
-- | 1.0       11-JUL-18      Antonio Morales           Initial draft version  |
-- +===========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
WHENEVER SQLERROR CONTINUE

GRANT SELECT ON  XXFIN.XX_GL_ARCS_BALANCES TO APPS, U461848;

