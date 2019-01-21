SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name             : XXARHZPARTIES.grt                                  |
-- | Description      : Giving grant for HZ_PARTIES TO XXCRM               |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date          Author           Remarks                        |
-- |-------  -----------   ---------------  -------------------------------|
-- |Draft 1a 28-Mar-2008   Abhradip Ghosh   Initial Draft Version          |
-- +=======================================================================+

-----------------------------------------------
-- Grant for HZ_PARTIES TO XXCRM             --
-----------------------------------------------

GRANT ALL ON AR.HZ_PARTIES TO XXCRM;

SHOW ERRORS;
