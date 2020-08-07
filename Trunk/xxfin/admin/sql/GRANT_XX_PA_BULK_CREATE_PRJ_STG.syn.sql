-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- | Name :XXFIN.XX_PA_BULK_CREATE_PRJ_STG                                        |
-- | Description :   Script to grant on XX_PA_BULK_CREATE_PRJ_STG table	       |
-- |  Rice ID : E3067                                                          |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                  Remarks                |
-- |=======    ==========     =============             ====================== |
-- |DRAFT 1.0 26-Aug-2013     Archana N.      		     Initial draft version |
-- |                                                                	       |
-- +===========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
WHENEVER SQLERROR CONTINUE

--+=====================================================================+
--+               GRANT TABLE XXFIN.XX_PA_BULK_CREATE_PRJ_STG           +
--+=====================================================================+

GRANT SELECT ON xxfin.XX_PA_BULK_CREATE_PRJ_STG TO XXFIN_SELECT_GROUP;

SHOW ERROR