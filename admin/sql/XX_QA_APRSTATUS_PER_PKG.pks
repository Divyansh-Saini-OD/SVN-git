SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_QA_APRSTATUS_PER_PKG AUTHID CURRENT_USER
AS 
-- +==============================================================================+
-- |                  Office Depot - Project Simplify                             |
-- +==============================================================================+
-- | Name       : XX_QA_APRSTATUS_PER_PKG                                         |
-- | Description: This package checks if the user has the ability to approve the  |
-- |              collection plan 						  |
-- |                                                                              |
-- |Change Record:                                                                |
-- |==============                                                                |
-- |Version   Date         Author           Remarks                               |
-- |=======   ==========   ===============  ======================================|
-- |1.0       04-MAR-2009  Paddy Sanjeevi   Initial version                       |
-- +==============================================================================+

FUNCTION IS_ELIGIBLE_TO_APPROVE RETURN VARCHAR2 ;

END XX_QA_APRSTATUS_PER_PKG;
/

SHOW ERRORS;

EXIT;
