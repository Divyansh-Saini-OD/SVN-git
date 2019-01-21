SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name             : XXARHZCODEASSIGNMENTS.grt                          |
-- | Description      : Giving grant for HZ_CODE_ASSIGNMENTS TO XXCRM      |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date          Author           Remarks                        |
-- |-------  -----------   ---------------  -------------------------------|
-- |Draft 1a 28-Mar-2008   Abhradip Ghosh   Initial Draft Version          |
-- +=======================================================================+

---------------------------------------------
-- Grant for HZ_CODE_ASSIGNMENTS TO XXCRM  --
---------------------------------------------

GRANT ALL ON AR.HZ_CODE_ASSIGNMENTS TO XXCRM;

SHOW ERRORS;
