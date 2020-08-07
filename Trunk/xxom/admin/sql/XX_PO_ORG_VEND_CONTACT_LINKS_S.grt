SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name             : XX_PO_ORG_VEND_CONTACT_LINKS_S.grt                    |
-- | Rice ID          : E2009 VendorContact_Maintenance                       |
-- | Description      : This script grants access to the sequence             |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version Date        Author           Remarks                              |
-- |======= =========== ===============  =====================================|
-- |1.0     07-May-2008 Matthew Craig    Initial Version                      |
-- |                                                                          |
-- +==========================================================================+

PROMPT
PROMPT Providing grant on sequence XX_PO_ORG_VEND_CONTACT_LINKS_S
PROMPT

GRANT ALL ON  XXPTP.XX_PO_ORG_VEND_CONTACT_LINKS_S TO APPS;

SHOW ERROR