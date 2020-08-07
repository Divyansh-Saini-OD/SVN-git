-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- | Name :XXFIN.XX_PA_MASS_ADJUST_UPLD_HIST                                     |
-- | Description :   Script to grant on XX_PA_MASS_ADJUST_UPLD_HIST table	       |
-- |  Rice ID : E3072, defect # 23811                                          |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                  Remarks                |
-- |=======    ==========     =============             ====================== |
-- |DRAFT 1.0 10-Oct-2013     Archana N.      		     Initial draft version |
-- |                                                                	       |
-- +===========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
WHENEVER SQLERROR CONTINUE

--+=====================================================================+
--+               GRANT TABLE XXFIN.XX_PA_MASS_ADJUST_UPLD_HIST           +
--+=====================================================================+

GRANT SELECT ON xxfin.XX_PA_MASS_ADJUST_UPLD_HIST TO XXFIN_SELECT_GROUP;

SHOW ERROR