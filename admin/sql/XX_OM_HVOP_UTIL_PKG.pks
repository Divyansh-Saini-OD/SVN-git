SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_OM_HVOP_UTIL_PKG AS

TYPE T_V100 IS TABLE OF VARCHAR2(100)  INDEX BY BINARY_INTEGER;
TYPE T_NUM  IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;

-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : SEND_NOTIFICATION                                               |
-- | Description      : This API will send email notification on errors      |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    15-OCT-2007   Manish Chavan     Initial code                  |
-- +=========================================================================+

-- Define Globals
G_USE_TEST_CC    VARCHAR2(1);

-- Send notifications in email for unexpected errors
PROCEDURE SEND_NOTIFICATION(p_subject IN VARCHAR2, p_text IN VARCHAR2);

-- Get the TEST Credit Cards
FUNCTION GET_TEST_CC( p_first6 IN VARCHAR2
                    , p_last4  IN VARCHAR2
                    , p_length IN NUMBER) RETURN VARCHAR2;

END XX_OM_HVOP_UTIL_PKG;
/
SHOW ERRORS PACKAGE XX_OM_HVOP_UTIL_PKG;
EXIT;
