SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_cdh_credit_change_pkg AUTHID CURRENT_USER

-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                    Oracle NAIO Consulting Organization                   |
-- +==========================================================================+
-- | Name        : XX_CDH_CREDIT_CHANGE_PKG                                   |
-- | Rice ID     : E0266_RoleRestrictionsMerges                               |
-- | Description : Custom Package called from the Workflow Engine. Contains a |
-- |               procedure Set_Notification that is called to determine the |
-- |               attributes for the Performer and the Message Details.      |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |Draft 1a 12-Jul-2007 Prem Kumar             Initial draft version         |
-- |Draft 1b 30-Aug-2007 Vidhya Valantina T                                   |
-- |1.0      XX-Aug-2007 Vidhya Valantina T     Baselined after review        |
-- |                                                                          |
-- +==========================================================================+

AS

    PROCEDURE Set_Notification ( itemtype  IN         VARCHAR2
                                ,itemkey   IN         VARCHAR2
                                ,actid     IN         NUMBER
                                ,funcmode  IN         VARCHAR2
                                ,resultout OUT NOCOPY VARCHAR2 );

END xx_cdh_credit_change_pkg;
/

SHOW ERRORS;
