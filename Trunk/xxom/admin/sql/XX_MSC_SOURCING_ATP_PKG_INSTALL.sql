

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_ATP_PKG_INSTALL.sql                               |
-- | Description: Office Depot - Custom ATP                                    |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ====================================|
-- |Draft 1A 21-jun-2007  Roy Gomes        Initial draft version               |
-- |v1.1     01-oct-2007  Roy Gomes        Included procedures for External ATP|
-- |v1.2     13-nov-2007  Roy Gomes        Base Scheduling                     |
-- |                                                                           |
-- +===========================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    ON
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Creating ATP packages......
PROMPT

-- WHENEVER SQLERROR EXIT 1

@@XX_MSC_SOURCING_ORDER_FLOW_PKG.pks
@@XX_MSC_SOURCING_ORDER_FLOW_PKG.pkb
@@XX_MSC_SOURCING_UTIL_PKG.pks
@@XX_MSC_SOURCING_UTIL_PKG.pkb
@@XX_MSC_SOURCING_PARAMS_PKG.pks
@@XX_MSC_SOURCING_PARAMS_PKG.pkb
@@XX_MSC_SOURCING_DATE_CALC_PKG.pks
@@XX_MSC_SOURCING_DATE_CALC_PKG.pkb
@@XX_MSC_SOURCING_SR_ORG_PKG.pks
@@XX_MSC_SOURCING_SR_ORG_PKG.pkb
@@XX_MSC_SOURCING_PREPROCESS_PKG.pks
@@XX_MSC_SOURCING_PREPROCESS_PKG.pkb
@@XX_MSC_SOURCING_BASE_ATP_PKG.pks
@@XX_MSC_SOURCING_BASE_ATP_PKG.pkb
@@XX_MSC_SOURCING_ALT_ATP_PKG.pks
@@XX_MSC_SOURCING_ALT_ATP_PKG.pkb
@@XX_MSC_SOURCING_VENDOR_ATP_PKG.pks
@@XX_MSC_SOURCING_VENDOR_ATP_PKG.pkb
@@XX_MSC_SOURCING_CUSTOM_ATP_PKG.pks
@@XX_MSC_SOURCING_CUSTOM_ATP_PKG.pkb
@@XX_MSC_SOURCING_SESSION_PKG.pks
@@XX_MSC_ATP_CUSTOM_PKG.pkb
                                        
PROMPT
PROMPT Exiting....
PROMPT

-- WHENEVER SQLERROR CONTINUE

SET FEEDBACK ON

--EXIT;
