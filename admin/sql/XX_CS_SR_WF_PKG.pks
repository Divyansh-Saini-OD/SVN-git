SET VERIFY        OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

 -- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  	: XX_CS_SR_WF_PKG                                      |
-- | Description: added Group owner to Process                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       24-APR-07   Raj Jagarlamudi  Initial draft version       |
-- +===================================================================+

CREATE OR REPLACE
PACKAGE XX_CS_SR_WF_PKG AS


  PROCEDURE Set_Notif_Performer( itemtype      VARCHAR2,
                               	   itemkey       VARCHAR2,
                                   actid         NUMBER,
                                   funmode       VARCHAR2,
                                   result    OUT NOCOPY VARCHAR2 );
                                   
  PROCEDURE Check_Owner   ( itemtype      VARCHAR2,
                               	   itemkey       VARCHAR2,
                                   actid         NUMBER,
                                   funmode       VARCHAR2,
                                   result    OUT NOCOPY VARCHAR2 );

END XX_CS_SR_WF_PKG;
/

SHOW ERRORS;
EXIT;
