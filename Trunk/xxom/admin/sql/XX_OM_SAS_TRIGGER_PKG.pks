SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_OM_SAS_TRIGGER_PKG AS

-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_OM_SAS_TRIGGER_PKG                                           |
-- | Description      : This Program will trigger HVOP runs based on the     |
-- |                    Trigger file received from SAS                       |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    05-JUN-2007   Manish Chavan     Initial code                  |
-- +=========================================================================+


g_org_id       CONSTANT NUMBER := FND_PROFILE.VALUE('ORG_ID');

PROCEDURE SUBMIT_HVOP( x_retcode          OUT NOCOPY NUMBER
                      , x_errbuf           OUT NOCOPY VARCHAR2
                      , p_trigger_fname    IN VARCHAR2 
                      , p_batch_size       IN NUMBER DEFAULT 1500
                      , p_debug_level      IN NUMBER DEFAULT 0
                      );

END XX_OM_SAS_TRIGGER_PKG;
/
SHOW ERRORS PACKAGE XX_OM_SAS_TRIGGER_PKG;
EXIT;
