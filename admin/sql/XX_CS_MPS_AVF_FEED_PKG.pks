SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_cs_mps_avf_feed_pkg AS
-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  : XX_CS_MPS_AVF_FEED_PKG.pks                                                           |
-- | Description  : This package contains procedures related to MPS FEED to update contract       |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        15-AUG-2012   Bapuji Nanapaneni  Initial version                                   |
-- |                                                                                              |
-- +==============================================================================================+
  gc_ind VARCHAR2(5) := ',';
  -- +=====================================================================+
  -- | Name  : send_feed                                                   |
  -- | Description      : This Procedure will create feed to send to MPS   |
  -- |                    analyst                                          |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_file_name        IN VARCHAR2 file_name         |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                                                                     |
  -- +=====================================================================+
  PROCEDURE send_feed( p_file_name      IN  VARCHAR2
                     , x_return_status  OUT VARCHAR2
                     , x_return_mesg    OUT VARCHAR2
                     );
  -- +=====================================================================+
  -- | Name  : send_feed                                                   |
  -- | Description      : This Procedure will create feed to receive to MPS|
  -- |                    analyst                                          |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_file_name        IN VARCHAR2 file_name         |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                                                                     |
  -- +=====================================================================+
  PROCEDURE receive_feed( p_file_name      IN  VARCHAR2
                        , x_return_status  OUT VARCHAR2
                        , x_return_mesg    OUT VARCHAR2
                        );
                     
  
END xx_cs_mps_avf_feed_pkg;
/
SHOW ERRORS PACKAGE xx_cs_mps_avf_feed_pkg;