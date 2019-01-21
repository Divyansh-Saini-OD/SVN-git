SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_AP_RB_VENDOR_LOAD_PKG AS

-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_AP_RB_VENDOR_LOAD_PKG                                        |
-- | Description      : This Program will load vendors to iface table from   |
-- |                    stagging table                                       |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    14-FEB-2012   Bapuji Nanapaneni Initial code                  |
-- +=========================================================================+


PROCEDURE LOAD_VENDORS( x_retcode          OUT NOCOPY NUMBER
                      , x_errbuf           OUT NOCOPY VARCHAR2
                      , p_email            IN         VARCHAR2
                      );

FUNCTION find_special_chars(p_string IN VARCHAR2) RETURN VARCHAR2;
END XX_AP_RB_VENDOR_LOAD_PKG;
/
SHOW ERRORS PACKAGE XX_AP_RB_VENDOR_LOAD_PKG;
--EXIT;


