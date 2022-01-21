

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_ATP_BROWSE_INSTALL.sql                            |
-- | Description: Office Depot - Custom ATP                                    |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ====================================|
-- |Draft 1A 02-jan-2008  Roy Gomes        Initial draft version               |
-- |                                                                           |
-- +===========================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    ON
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Creating ATP Browse packages......
PROMPT

-- WHENEVER SQLERROR EXIT 1

@@XX_MSC_SOURCING_QUERY_QTY_PKG.pks
@@XX_MSC_SOURCING_QUERY_QTY_PKG.pkb

                                        
PROMPT
PROMPT Exiting....
PROMPT

-- WHENEVER SQLERROR CONTINUE

SET FEEDBACK ON

--EXIT;
