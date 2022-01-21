SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CS_MPS_ORDER_PKG AS
-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  : XX_CS_MPS_ORDER_PKG.pks                                                              |
-- | Description  : This package contains procedures related to Service Contracts creation        |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        02-OCT-2012   Bapuji Nanapaneni  Initial version                                   |
-- |                                                                                              |
-- +==============================================================================================+

PROCEDURE CREATE_ORDER( x_return_status  IN OUT NOCOPY VARCHAR2
                      , x_return_mesg    IN OUT NOCOPY VARCHAR2
                      , p_sr_number      IN VARCHAR2
                      ); 
  -- +=====================================================================+
  -- | Name  : CREATE_ORDER                                                |
  -- | Description      : This Procedure will create Record in OM IFACE TBL|
  -- |                                                                     |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        x_return_status IN OUT VARCHAR2 Return status    |
  -- |                    x_return_msg    IN OUT VARCHAR2 Return Message   |
  -- +=====================================================================+
END XX_CS_MPS_ORDER_PKG;
/
SHOW ERRORS PACKAGE XX_CS_MPS_ORDER_PKG;