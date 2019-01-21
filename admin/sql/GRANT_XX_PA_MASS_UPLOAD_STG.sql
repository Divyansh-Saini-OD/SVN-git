-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- | Name :XXFIN.XX_PA_MASS_UPLOAD_STG                                         |
-- | Description :   Script to grant on XX_PA_MASS_UPLOAD_STG  table		   |
-- |  Rice ID : E3062                                                          |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                  Remarks                |
-- |=======    ==========     =============             ====================== |
-- | DRAFT 1.0 03-JUL-2013    Yamuna S.       			Initial draft version   |
-- |                                                    Defect#22906           |
-- +===========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
WHENEVER SQLERROR CONTINUE

--+=====================================================================+
--+               GRANT TABLE XXFIN.XX_PA_MASS_UPLOAD_STG               +
--+=====================================================================+

GRANT SELECT ON xxfin.XX_PA_MASS_UPLOAD_STG  TO XXFIN_SELECT_GROUP;

SHOW ERROR