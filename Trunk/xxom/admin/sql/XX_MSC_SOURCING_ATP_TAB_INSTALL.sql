

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_ATP_TAB_PKG_INSTALL.sql                           |
-- | Description: Office Depot - Custom ATP                                    |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ====================================|
-- |Draft 1A 01-oct-2007  Roy Gomes        Initial draft version               |
-- |                                                                           |
-- +===========================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    ON
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Creating ATP custom tables......
PROMPT

--WHENEVER SQLERROR EXIT 1

@@XX_MSC_SOURCING_VENDOR_CALS.tab
                                        
PROMPT
PROMPT Exiting....
PROMPT

--WHENEVER SQLERROR CONTINUE

SET FEEDBACK ON

--EXIT;
